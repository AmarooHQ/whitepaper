#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# for experimenting w/ reflected weight stuff

export OUT_FILE=exp-4c-hash-xxrev.csv

export B_PERIOD=20
export ATK_RATIO=0.4
export N_TRIALS_PER=100
export REPEAT_TIMES=10

if [[ ! -f $OUT_FILE ]]; then
  cp result-columns.csv $OUT_FILE
fi

for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  for nchains in `seq 1 5` `seq 7 2 20`; do
    for ntrials in `seq 1 ${N_TRIALS_PER}`; do
      (
        export N_CHAINS=${nchains};
        export SIM_ARGS=$(make print-sim-args);
        echo "$SIM_ARGS"
      )
    done
  done | xargs -P 24 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
done
