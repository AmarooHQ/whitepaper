#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# aux stuff for exp 14
# particularly for bt=100 hr=100
# exp_aux14_q={q}_dsconf-base={t}_bt={bt}_hr={hr}_DoubleSpendWork_WeightedDag_DAA100.csv

export OUT_F_PREFIX=csv/exp_aux14

export B_PERIOD=100
export N_TRIALS_PER=100
export REPEAT_TIMES=30
# export REPEAT_TIMES=18
export HR_PER_CHAIN=100
export N_CHAINS=1
export DAA2_N_BLOCKS=100

# # run 2nd time for DS+LC
# export CRYPTO_SYSTEM=LongestChain
# export ATK_STRATEGY=DoubleSpend

# built in bash feature
SECONDS=0

for strat in DoubleSpend; do
  # loop a few times so we incrementally generate data over the whole x-axis
  for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
    LAST_REPEAT_ELAPSED=$SECONDS
    export ATK_STRATEGY=$strat
    for crypto_sys in WeightedChain; do #LongestChain; do
      export CRYPTO_SYSTEM=$crypto_sys
      for atk_r in 0.40 0.44 0.48; do # 0.40 0.44 0.48 0.36; do
        export ATK_RATIO=$atk_r
        for ds_conf_base in 5 10 20; do
          export OUT_FILE=${OUT_F_PREFIX}_q=${ATK_RATIO}_dsconf-base=${ds_conf_base}_bt=${B_PERIOD}_hr=${HR_PER_CHAIN}_${ATK_STRATEGY}_${CRYPTO_SYSTEM}_DAA${DAA2_N_BLOCKS}.csv

          elapsed=$SECONDS
          this_repeat=$(echo $elapsed-$LAST_REPEAT_ELAPSED | bc)
          export PROGRESS_STR=">> [$repeat_i/$REPEAT_TIMES | $LAST_REPEAT_ELAPSED +$this_repeat s] / rs:$strat / cs:$crypto_sys / q:$atk_r / ds:$ds_conf_base"

          if [[ ! -f $OUT_FILE ]]; then
            cp result-columns.csv $OUT_FILE
          fi

          echo "$PROGRESS_STR"

          # called `nchains` to remain consistent with other experiments
          for nchains in `seq 1 6` `seq 7 2 21` 30; do
            nconfs=$(echo $nchains\*$ds_conf_base | bc)
            export ATK_DS_CONFS=$nconfs;
            export SIM_ARGS=$(make print-sim-args);
            for ntrials in `seq 1 ${N_TRIALS_PER}`; do
              echo "$SIM_ARGS"
            done
          done | xargs -P 70 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE" | tail -n 4
        done
      done
    done
  done
done
