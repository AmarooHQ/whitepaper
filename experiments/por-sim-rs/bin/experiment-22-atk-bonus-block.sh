#!/usr/bin/env bash

set -e

export _BIN_DIR=$(dirname $0)

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# Experiment 21: use big numbers so things are high resolution (avoids all limits of accuracy stuff)
export EXP_NUM=22
export POR_SIM_HASH=xxh3
export RANDOMLY_DISTRIBUTE_HASHRATES=1
export HR_DISTRIB=$(if [[ ! -z "$RANDOMLY_DISTRIBUTE_HASHRATES" ]]; then echo 'RandHR'; else echo 'UniHR'; fi)
export OUT_F_PREFIX=csv/exp_${EXP_NUM}_${HR_DISTRIB}_${POR_SIM_HASH}

export ATK_USE_DYN_END_TICK=1

# run REPEAT_TIMES total loops, where the simulator is run N_TRIALS_PER times for each set of params per loop.
# => the total number of samples per x val is N_TRIALS_PER * REPEAT_TIMES
# => this should be >= 3000 (picked b/c it's not too many but graphs are reasonably smooth)
# status updates are more frequent with larger REPEAT_TIMES
export N_TRIALS_PER=60
export REPEAT_TIMES=50

# note: the attackers q is multiplied by HR_PER_CHAIN and fractional components are dropped.
# so HR_PER_CHAIN=50 means q can only go up/down in increments of 0.02
export B_PERIOD=50
export HR_PER_CHAIN=50
export DAA2_N_BLOCKS=100

export N_CPUS=$(echo $(grep -c ^processor /proc/cpuinfo)-1 | bc)
# built in bash feature
SECONDS=0

# note: in reality a simplex needs to use WeightedDag and an attacker needs to win via the DoubleSpendWork strategy.
# => no point calculating other combinations (those including WeightedChain or DoubleSpend strat)

echo "Starting simulation loops..."

function write_progress () {
  repeat_i=$1
  strat=$2
  crypto_sys=$3
  atk_r=$4
  ds_conf_base=$5

  elapsed=$SECONDS
  this_repeat=$(echo $elapsed-$LAST_REPEAT_ELAPSED | bc)
  progress_msg=$(python3 $_BIN_DIR/_exp_progress.py $repeat_i $REPEAT_TIMES $LAST_REPEAT_ELAPSED $this_repeat)
  export PROGRESS_STR=">> [${progress_msg}]\n>> Loop: rs:$strat / cs:$crypto_sys / q:$atk_r / ds:$ds_conf_base"
  echo -e "$PROGRESS_STR"
}

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  export LAST_REPEAT_ELAPSED=$SECONDS
  for strat in DoubleSpendWork; do # DoubleSpend
    export ATK_STRATEGY=$strat
    for crypto_sys in WeightedDag; do #WeightedChain, LongestChain; do
      export CRYPTO_SYSTEM=$crypto_sys
      for atk_r in 0.40 0.44 0.48; do
        export ATK_RATIO=$atk_r
        for ds_conf_base in 5 10 20; do
          export ATK_DS_CONFS=$ds_conf_base;
          export OUT_FILE=${OUT_F_PREFIX}_q=${ATK_RATIO}_dswin=${ATK_DS_CONFS}_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_${ATK_STRATEGY}_${CRYPTO_SYSTEM}_DAA${DAA2_N_BLOCKS}.csv
          # echo "$OUT_FILE" ; exit 0

          if [[ ! -f $OUT_FILE ]]; then
            cp result-columns.csv $OUT_FILE
          fi

          write_progress $repeat_i $strat $crypto_sys $atk_r $ds_conf_base

          for nchains in 1 2 30 `seq 21 -2 7` `seq 6 -1 1`; do
            export N_CHAINS=$nchains;
            export SIM_ARGS=$(make print-sim-args);
            for ntrials in `seq 1 ${N_TRIALS_PER}`; do
              echo "$SIM_ARGS"
            done
          done | xargs -P $N_CPUS -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE" | tail -n 2
          write_progress $repeat_i $strat $crypto_sys $atk_r $ds_conf_base
        done
      done
    done
  done
done | tee $OUT_F_PREFIX.log
