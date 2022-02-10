#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs

# expand exp4 -- other values of q

# export B_PERIOD=25
# export ATK_RATIO=0.44
export N_TRIALS_PER=500

for B_PERIOD in 25 50 100; do
  for ATK_RATIO in 0.25 0.4; do
    export OUT_FILE=exp-5-q$ATK_RATIO-target$B_PERIOD.csv
    echo $OUT_FILE
    if [[ ! -f $OUT_FILE ]]; then
      cp result-columns.csv $OUT_FILE
    fi
    for nchains in `seq 1 20`; do
      for ntrials in `seq 1 ${N_TRIALS_PER}`; do
        (
          export N_CHAINS=${nchains};
          export SIM_ARGS=$(make print-sim-args);
          echo "$SIM_ARGS"
        )
      done
    done | xargs -P 24 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
  done
done
