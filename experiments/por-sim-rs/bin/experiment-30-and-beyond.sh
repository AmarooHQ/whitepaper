#!/usr/bin/env bash

set -e

export _BIN_DIR=$(dirname $0)

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
if [[ -z "$DRY_RUN" ]]; then
  cargo b --release
fi

export RUST_LOG=warn

export EXP_NUM=${EXP_NUM:-0}
if [[ "0" = "$EXP_NUM" || -z "$EXP_NUM" ]]; then
  echo "Error: pls set EXP_NUM"
  exit 1;
fi
if [[ "1" = "$EXP_IS_AUX" ]]; then
  export EXP_NUM=${EXP_NUM}aux
fi
# limit which attacker ratios are simulated
export ATK_HR_ONLY=${ATK_HR_ONLY:-}  # set this env var to limit which atk_r (q) params to process
export ATK_DS_CONF_ONLY=${ATK_DS_CONF_ONLY:-}
export ATK_NCHAINS_ONLY=${ATK_NCHAINS_ONLY:-}

# run REPEAT_TIMES total loops, where the simulator is run N_TRIALS_PER times for each set of params per loop.
# => the total number of samples per x val is N_TRIALS_PER * REPEAT_TIMES
# => this should be >= 3000 (picked b/c it's not too many but graphs are reasonably smooth)
# status updates are more frequent with larger REPEAT_TIMES
export N_TRIALS_PER=100
export REPEAT_TIMES=${REPEAT_TIMES:-90}
export RESUME_FROM=${RESUME_FROM:-1}  # subtract (this-1) from REPEAT_TIMES
export REPEAT_TIMES=$(echo "$REPEAT_TIMES-$RESUME_FROM+1" | bc)
if [[ ! -z "$DRY_RUN" ]]; then
  export REPEAT_TIMES=1
  echo "DRY RUN! Have set REPEAT_TIMES=1"
fi

export POR_SIM_HASH=xxh3
export RANDOMLY_DISTRIBUTE_HASHRATES=1
export RAND_HR_METHOD=${RAND_HR_METHOD:-TwinUniform}
export ATK_USE_DYN_END_TICK=1
export HR_DISTRIB=$(if [[ "1" = "$RANDOMLY_DISTRIBUTE_HASHRATES" ]]; then echo 'RandHR'; else echo 'UniHR'; fi)

export OUT_F_PREFIX=csv/exp_${EXP_NUM}_${HR_DISTRIB}_${POR_SIM_HASH}

# note: the attackers q is multiplied by HR_PER_CHAIN and fractional components are dropped.
# so HR_PER_CHAIN=50 means q can only go up/down in increments of 0.02
export B_PERIOD=${B_PERIOD:-75}
export HR_PER_CHAIN=${HR_PER_CHAIN:-75}
export DAA2_N_BLOCKS=${DAA2_N_BLOCKS:-100}
export ATK_START_TICK_DEFAULT=$(echo ${B_PERIOD}\*${DAA2_N_BLOCKS}/2 | bc)
export ATK_START_TICK=${ATK_START_TICK:-$ATK_START_TICK_DEFAULT}

export MEASURED_N_CPUS=$(echo $(grep -c ^processor /proc/cpuinfo)-1 | bc)
export N_CPUS=${N_CPUS:-$MEASURED_N_CPUS}
# built in bash feature
SECONDS=0

# nchain_arr=( 1 2 30 `seq 21 -2 7` `seq 6 -1 1` )
# nchain_arr=( 1 2 60 42 30 `seq 21 -2 7` `seq 6 -1 1` )
nchain_arr=( 30 25 `seq 21 -2 7` `seq 6 -1 1` )

export DO_LONG_DS_CONFS=${DO_LONG_DS_CONFS:-}
ds_conf_arr=( 1.0 1.25 1.5 1.75 1.9 2.0 2.25 2.5 2.75 2.9 3.0 5 10 20 )
# ds_conf_arr=( 1.0 1.5 1.75 1.9 2.0 2.25 2.75 2.9 3.0 )  # exclude previously acquired data
if [[ "$DO_LONG_DS_CONFS" = "1" ]]; then
  # extra long DSs for q=0.48
  ds_conf_arr=( 40 80 )
fi

# easier way to manage DS confs -- presets with names:
case "$DS_CONFS_PRESET" in
  very-short-to-very-long)
    ds_conf_arr=(1.0 1.41 2.0 3.0 4 5 6 7 9 15 20 30 45 60 90)
    ;;
  very-short-to-long)
    ds_conf_arr=(1.0 1.41 2.0 3.0 4 5 6 7 9 15 20 30 45 60)
    ;;
  very-short)
    ds_conf_arr=(1.0 1.41 2.0)
    ;;
  one-to-three)
    ds_conf_arr=(1.0 1.41 2.0 3.0)
    ;;
  half-to-three)
    ds_conf_arr=(0.5 0.7 1.0 1.41 2.0 3.0)
    ;;
  just-three)
    ds_conf_arr=( 3.0 )
    ;;
  less-than-one)
    ds_conf_arr=(0.5 0.7)
    ;;
  std-range)
    ds_conf_arr=(2.0 5 10 20)
    ;;
  2-5-10)
    ds_conf_arr=(2.0 5 10)
    ;;
  std+40)
    ds_conf_arr=(2.0 5 10 20 40)
    ;;
  40)
    ds_conf_arr=(40)
    ;;
  20)
    ds_conf_arr=(20)
    ;;
  13)
    ds_conf_arr=(13)
    ;;
  16)
    ds_conf_arr=(16)
    ;;
  13+16)
    ds_conf_arr=(13 16)
    ;;
  std+13+16)
    ds_conf_arr=(2.0 5 10 13 16 20)
    ;;
  *)
    if [[ ! -z "$ATK_DS_CONF_ONLY" ]]; then
      IFS=',' read -ra ds_conf_arr <<< "$ATK_DS_CONF_ONLY"
    fi
    ;;
esac

case "$N_CHAINS_PRESET" in
  # note: this is probs too big -- 256 takes many minutes to simulate even for smaller DAAs
  balanced-with-very-big)
    nchain_arr=(256 128 64 32 23 16 11 `seq 8 -1 1`)
    ;;
  balanced-with-big)
    nchain_arr=(64 32 23 16 11 `seq 8 -1 1`)
    ;;
  balanced)
    nchain_arr=(32 23 16 11 `seq 8 -1 1`)
    ;;
  small-only)
    nchain_arr=(16 11 `seq 8 -1 1`)
    ;;
  1-8)
    nchain_arr=(`seq 8 -1 1`)
    ;;
  *)
    if [[ ! -z "$ATK_NCHAINS_ONLY" ]]; then
      IFS=',' read -ra nchain_arr <<< "$ATK_NCHAINS_ONLY"
    fi
    ;;
esac

atk_qs=( 0.40 0.44 0.48 )
case "$ATK_QS_PRESET" in
  light)
    atk_qs=( 0.40 0.44 )
    ;;
  0.48)
    atk_qs=(0.48)
    ;;
  0.44)
    atk_qs=(0.44)
    ;;
  std)
    atk_qs=( 0.40 0.44 0.48 )
    ;;
  0.2,0.3,0.4)
    atk_qs=( 0.2 0.3 0.4 )
    ;;
  0.2,0.3)
    atk_qs=( 0.2 0.3 )
    ;;
  bft)
    atk_qs=( 0.3333333 )
    ;;
  *)
    if [[ ! -z "$ATK_HR_ONLY" ]]; then
      # atk_qs=( $ATK_HR_ONLY )
      IFS=',' read -ra atk_qs <<< "$ATK_HR_ONLY"
    fi
    ;;
esac

(cat | tee -a $OUT_F_PREFIX.log) << EOF
----------------------------------------
Parameters:
  EXP: ${EXP_NUM} (Aux:${EXP_IS_AUX})
  atk_qs: ${atk_qs[@]}
  ds_confs: ${ds_conf_arr[@]}
  n_chains: ${nchain_arr[@]}
  B_PERIOD: ${B_PERIOD}
  HR_PER_CHAIN: ${HR_PER_CHAIN}
  DAA2_N_BLOCKS: ${DAA2_N_BLOCKS}
  ATK_START_TICK: ${ATK_START_TICK}
  RANDOMLY_DISTRIBUTE_HASHRATES: ${RANDOMLY_DISTRIBUTE_HASHRATES}
  RAND_HR_METHOD: ${RAND_HR_METHOD}
----------------------------------------
EOF

# note: in reality a simplex needs to use WeightedDag and an attacker needs to win via the DoubleSpendWork strategy.
# => no point calculating other combinations (those including WeightedChain or DoubleSpend strat)

echo "Output: ${OUT_F_PREFIX}_(q)_(dswin)_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_(strat)_(chain)_DAA${DAA2_N_BLOCKS}.csv"
if [[ "$SKIP_EXP_CONF_PROMPT" != "1" ]]; then
  read -p "Press enter to continue or ctrl-c to end."
fi
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
  AUX_MSG=''
  if [[ "$EXP_IS_AUX" = "1" ]]; then
    AUX_MSG=' >> AUX'
  fi
  export PROGRESS_STR=">> [${progress_msg}]${AUX_MSG} >> q:$atk_r / ds:$ds_conf_base"
  echo -e "$PROGRESS_STR"
}

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  export LAST_REPEAT_DURATION=$(echo $SECONDS-$LAST_REPEAT_ELAPSED | bc)
  export LAST_REPEAT_ELAPSED=$SECONDS

  if [[ -f "./cleanly_stop_sim" ]]; then
    echo "Exiting due to file presence: ./cleanly_stop_sim (delete it to enable running again)"
    date
    echo "About to start: $repeat_i of ${REPEAT_TIMES}. set RESUME_FROM=$repeat_i to resume. (Note: this run started with: RESUME_FROM=$RESUME_FROM)"
    echo "Exiting..."
    exit 0
  fi

  for strat in DoubleSpendWork; do # DoubleSpend
    export ATK_STRATEGY=$strat
    for crypto_sys in WeightedDag; do #WeightedChain, LongestChain; do
      export CRYPTO_SYSTEM=$crypto_sys

      for atk_r in ${atk_qs[@]}; do
        export ATK_RATIO=$atk_r
        # this is replaced by new way of constructing atk_qs array
        # if [[ ! -z "$ATK_HR_ONLY" ]] && [[ "$ATK_RATIO" != "$ATK_HR_ONLY" ]]; then
        #   continue
        # fi

        for ds_conf_base in ${ds_conf_arr[@]}; do
          export ATK_DS_CONFS=$ds_conf_base;
          # if [[ ! -z "$ATK_DS_CONF_ONLY" ]] && [[ "$ATK_DS_CONFS" != "$ATK_DS_CONF_ONLY" ]]; then
          #   continue
          # fi

          export OUT_FILE=${OUT_F_PREFIX}_q=${ATK_RATIO}_dswin=${ATK_DS_CONFS}_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_${ATK_STRATEGY}_${CRYPTO_SYSTEM}_DAA${DAA2_N_BLOCKS}.csv

          if [[ ! -f $OUT_FILE ]]; then
            cp result-columns.csv $OUT_FILE
            echo "Initialized $OUT_FILE"
          fi
          if [[ ! -z "$DRY_RUN" ]]; then
            echo "Dry run: would write to $OUT_FILE"
            make print-sim-args
            exit 0
            continue;
          fi

          write_progress $repeat_i $strat $crypto_sys $atk_r $ds_conf_base

          # for nchains in 1 2 30 `seq 21 -2 7` `seq 6 -1 1`; do
          for nchains in ${nchain_arr[@]}; do
            if [[ ("$ds_conf_base" = "20" && "$nchains" -gt 31) \
               || ("$ds_conf_base" = "40" && "$nchains" -gt 31) \
               || ("$ds_conf_base" = "80" && "$nchains" -gt 20) \
               || ("$ds_conf_base" = "10" && "$nchains" -gt 40) ]]; then
              # skip b/c we're not interested in these datapoints (v expensive)
              continue;
            fi
            # if [[ ! -z "$ATK_NCHAINS_ONLY" && "$ATK_NCHAINS_ONLY" != "$nchains" ]]; then
            #   continue;
            # fi

            if [[ "1" = "$EXP_IS_AUX" ]]; then
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
          echo "SIM_ARGS=$(make print-sim-args)."
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



echo ">> done <<"

exit 0




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
