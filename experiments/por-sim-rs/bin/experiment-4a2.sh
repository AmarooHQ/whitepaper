#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo build --release

# compared to exp3, how does B_PERIOD change things?
# 4a2 variant: separate CSV

export OUT_FILE=exp-4a-wPoRFix.csv

export B_PERIOD=25
export ATK_RATIO=0.44
export N_TRIALS_PER=100

if [[ ! -f $OUT_FILE ]]; then
  cp result-columns.csv $OUT_FILE
fi

for nchains in `seq 1 20` 30 40 50 60 70 80 90 100; do
  for ntrials in `seq 1 ${N_TRIALS_PER}`; do
    (
      export N_CHAINS=${nchains};
      export SIM_ARGS=$(make print-sim-args);
      echo "$SIM_ARGS"
    )
  done
done | xargs -P 24 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
# $SIM_BIN $SIM_ARGS | grep "RESULT:" | cut -d ":" -f 2- | tee -a $OUT_FILE
