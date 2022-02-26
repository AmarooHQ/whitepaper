#!/usr/bin/env bash

set -e

export _BIN_DIR=$(dirname $0)

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
if [[ -z "$DRY_RUN" ]]; then
  cargo b --release
fi

export RUST_LOG=warn

# Experiment 26: repeat 23 with updates to bonus block
# => fix: replace BadReflAncestor fix with something more intelligent
# Second aux run: DAA=500 (test if reactivity of DAA is responsible for trad better-than-theoretical performance)
# - generate some extra data for high n-chains
export EXP_NUM=26
if [[ ! -z "$EXP_IS_AUX" ]]; then
  export EXP_NUM=${EXP_NUM}aux
fi
# limit which attacker ratios are simulated
export ATK_HR_ONLY=${ATK_HR_ONLY:-}  # set this env var to limit which atk_r (q) params to process
export ATK_DS_CONF_ONLY=${ATK_DS_CONF_ONLY:-}

# run REPEAT_TIMES total loops, where the simulator is run N_TRIALS_PER times for each set of params per loop.
# => the total number of samples per x val is N_TRIALS_PER * REPEAT_TIMES
# => this should be >= 3000 (picked b/c it's not too many but graphs are reasonably smooth)
# status updates are more frequent with larger REPEAT_TIMES
export N_TRIALS_PER=100
export REPEAT_TIMES=90
export RESUME_FROM=1  # subtract (this-1) from REPEAT_TIMES
export REPEAT_TIMES=$(echo "$REPEAT_TIMES-$RESUME_FROM+1" | bc)
if [[ ! -z "$DRY_RUN" ]]; then
  export REPEAT_TIMES=1
  echo "DRY RUN! Have set REPEAT_TIMES=1"
fi

export POR_SIM_HASH=xxh3
export RANDOMLY_DISTRIBUTE_HASHRATES=1
export ATK_USE_DYN_END_TICK=1
export HR_DISTRIB=$(if [[ "1" = "$RANDOMLY_DISTRIBUTE_HASHRATES" ]]; then echo 'RandHR'; else echo 'UniHR'; fi)

export OUT_F_PREFIX=csv/exp_${EXP_NUM}_${HR_DISTRIB}_${POR_SIM_HASH}

# note: the attackers q is multiplied by HR_PER_CHAIN and fractional components are dropped.
# so HR_PER_CHAIN=50 means q can only go up/down in increments of 0.02
export B_PERIOD=75
export HR_PER_CHAIN=75
export DAA2_N_BLOCKS=100
# export DAA2_N_BLOCKS=500

export N_CPUS=$(echo $(grep -c ^processor /proc/cpuinfo)-1 | bc)
# built in bash feature
SECONDS=0

# nchain_arr=( 1 2 30 `seq 21 -2 7` `seq 6 -1 1` )
nchain_arr=( 1 2 60 42 30 `seq 21 -2 7` `seq 6 -1 1` )
# ds_conf_arr=( 1.25 2.5 5 10 20 )
ds_conf_arr=( 1.25 2.5 )

# note: in reality a simplex needs to use WeightedDag and an attacker needs to win via the DoubleSpendWork strategy.
# => no point calculating other combinations (those including WeightedChain or DoubleSpend strat)

echo "Output: ${OUT_F_PREFIX}_(q)_(dswin)_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_(strat)_(chain)_DAA${DAA2_N_BLOCKS}.csv"
read -p "Press enter to continue or ctrl-c to end."
echo "Starting simulation loops..."

export LAST_REPEAT_ELAPSED=0
export LAST_REPEAT_DURATION=0

function write_progress () {
  repeat_i=$1
  strat=$2
  crypto_sys=$3
  atk_r=$4
  ds_conf_base=$5

  elapsed=$SECONDS
  this_repeat=$(echo $elapsed-$LAST_REPEAT_ELAPSED | bc)
  progress_msg=$(python3 $_BIN_DIR/_exp_progress.py $repeat_i $REPEAT_TIMES $LAST_REPEAT_ELAPSED $this_repeat $LAST_REPEAT_DURATION)
  # no point incliduing these if we're not looping thru them
  # Loop: rs:$strat / cs:$crypto_sys /
  export PROGRESS_STR=">> [${progress_msg}] >> q:$atk_r / ds:$ds_conf_base"
  echo -e "$PROGRESS_STR"
}

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  export LAST_REPEAT_DURATION=$(echo $SECONDS-$LAST_REPEAT_ELAPSED | bc)
  export LAST_REPEAT_ELAPSED=$SECONDS

  if [[ -f "./cleanly_stop_sim" ]]; then
    echo "Exiting due to file presence: ./cleanly_stop_sim (delete it to enable running again)"
    date
    echo "About to start: $repeat_i of ${REPEAT_TIMES}. (Note: RESUME_FROM=$RESUME_FROM)"
    echo "Exiting..."
    exit 0
  fi

  for strat in DoubleSpendWork; do # DoubleSpend
    export ATK_STRATEGY=$strat
    for crypto_sys in WeightedDag; do #WeightedChain, LongestChain; do
      export CRYPTO_SYSTEM=$crypto_sys
      for atk_r in 0.40 0.44 0.48; do
        export ATK_RATIO=$atk_r
        if [[ ! -z "$ATK_HR_ONLY" ]] && [[ "$ATK_RATIO" != "$ATK_HR_ONLY" ]]; then
          continue
        fi
        for ds_conf_base in ${ds_conf_arr[@]}; do
          export ATK_DS_CONFS=$ds_conf_base;
          if [[ ! -z "$ATK_DS_CONF_ONLY" ]] && [[ "$ATK_DS_CONFS" != "$ATK_DS_CONF_ONLY" ]]; then
            continue
          fi

          export OUT_FILE=${OUT_F_PREFIX}_q=${ATK_RATIO}_dswin=${ATK_DS_CONFS}_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_${ATK_STRATEGY}_${CRYPTO_SYSTEM}_DAA${DAA2_N_BLOCKS}.csv
          # echo "$OUT_FILE" ; exit 0

          if [[ ! -f $OUT_FILE ]]; then
            cp result-columns.csv $OUT_FILE
            echo "Initialized $OUT_FILE"
          fi
          if [[ ! -z "$DRY_RUN" ]]; then
            echo "Dry run: would write to $OUT_FILE"
            continue;
          fi

          write_progress $repeat_i $strat $crypto_sys $atk_r $ds_conf_base

          # for nchains in 1 2 30 `seq 21 -2 7` `seq 6 -1 1`; do
          for nchains in ${nchain_arr[@]}; do
            if [[ "$ATK_RATIO" = "0.48" ]] && [[ "$nchains" -gt 30 ]]; then
              # skip b/c we're not interested in these datapoints (v expensive)
              continue
            fi

            if [[ ! -z "$EXP_IS_AUX" ]]; then
              export N_CHAINS=1;
              nconfs=$(echo $nchains\*$ds_conf_base | bc)
              export ATK_DS_CONFS=$nconfs;
            else
              export N_CHAINS=$nchains;
            fi
            export SIM_ARGS=$(make print-sim-args);
            for ntrials in `seq 1 ${N_TRIALS_PER}`; do
              echo "$SIM_ARGS"
            done
          done | xargs -P $N_CPUS -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE" | tail -n 1
          # write_progress $repeat_i $strat $crypto_sys $atk_r $ds_conf_base
        done
      done
    done
  done

  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later
  # some padding to help with in progress bash scripts reading the file later

done | tee -a $OUT_F_PREFIX.log





strat_arr=( "DoubleSpendWork" )
chain_arr=( "WeightedDag" )
atk_ratios=( 0.40 0.44 0.48 )
ds_conf_arr=( 5 10 20 )
nchain_arr=( 1 2 30 `seq 21 -2 7` `seq 6 -1 1` )

for strat in ${strat_arr[@]}; do
  for crypto_sys in ${chain_arr[@]}; do
    for atk_r in ${atk_ratios[@]}; do
      for ds_conf_base in ${ds_conf_arr[@]}; do
        for nchains in ${nchain_arr[@]}; do
          echo ">> rs:$strat / cs:$crypto_sys / q:$atk_r / ds:$ds_conf_base / nchains:$nchains" > /dev/null
        done
      done
    done
  done
done









echo ">> done <<"
