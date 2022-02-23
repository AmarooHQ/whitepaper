#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# Experiment 16: Like exp 13 but using blake hash
# blake3 is fastest crypto-secure hash out of all those tested (sha256, sha1, md5)
# but xx is still way faster (that's why it's used most of the time)
export POR_SIM_HASH=blake3
export OUT_F_PREFIX=csv/exp_16_RandHR_${POR_SIM_HASH}
export RANDOMLY_DISTRIBUTE_HASHRATES=1

export B_PERIOD=50
export N_TRIALS_PER=100
export REPEAT_TIMES=30
export HR_PER_CHAIN=50
export DAA2_N_BLOCKS=500

# export ATK_START_TICK=$(echo $B_PERIOD\*$DAA2_N_BLOCKS\*3/2 | bc)

export N_CPUS=$(echo $(grep -c ^processor /proc/cpuinfo)-1 | bc)
# built in bash feature
SECONDS=0

# note: in reality a simplex needs to use WeightedDag and an attacker needs to win via the DoubleSpendWork strategy.
# => no point calculating other combinations (those including WeightedChain or DoubleSpend strat)

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  LAST_REPEAT_ELAPSED=$SECONDS
  for strat in DoubleSpendWork; do # DoubleSpend
    export ATK_STRATEGY=$strat
    for crypto_sys in WeightedDag; do #WeightedChain, LongestChain; do
      export CRYPTO_SYSTEM=$crypto_sys
      for atk_r in 0.40 0.44 0.48; do # 0.40 0.44; do # 0.40 0.44 0.48 0.36; do
        export ATK_RATIO=$atk_r
        for ds_conf_base in 5 10 20; do
          export ATK_DS_CONFS=$ds_conf_base;

          elapsed=$SECONDS
          this_repeat=$(echo $elapsed-$LAST_REPEAT_ELAPSED | bc)
          export PROGRESS_STR=">> [$repeat_i/$REPEAT_TIMES | $LAST_REPEAT_ELAPSED +$this_repeat s] / rs:$strat / cs:$crypto_sys / q:$atk_r / ds:$ds_conf_base"
          export OUT_FILE=${OUT_F_PREFIX}_q=${ATK_RATIO}_dswin=${ATK_DS_CONFS}_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_${ATK_STRATEGY}_${CRYPTO_SYSTEM}_DAA${DAA2_N_BLOCKS}.csv
          # echo "$OUT_FILE" ; echo -e "$PROGRESS_STR" ; exit 0

          if [[ ! -f $OUT_FILE ]]; then
            cp result-columns.csv $OUT_FILE
          fi

          echo "$PROGRESS_STR"

          for nchains in `seq 1 6` `seq 7 2 21` 30; do
            export N_CHAINS=$nchains;
            export SIM_ARGS=$(make print-sim-args);
            for ntrials in `seq 1 ${N_TRIALS_PER}`; do
              echo "$SIM_ARGS"
            done
          done | xargs -P $N_CPUS -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE ; echo '$PROGRESS_STR'" | tail -n 4
        done
      done
    done
  done
done
