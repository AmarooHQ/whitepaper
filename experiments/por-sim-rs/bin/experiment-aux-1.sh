#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs

# Single chain doublespend vs theoretical.

export OUT_FILE=exp-aux1.csv

export B_PERIOD=50
export ATK_RATIO=0.44
export N_TRIALS_PER=1000

if [[ ! -f $OUT_FILE ]]; then
  cp result-columns.csv $OUT_FILE
fi

for nchains in `seq 1 20` 25 30 35 40 50 60; do
  nconfs=$(echo $nchains\*20 | bc)
  for ntrials in `seq 1 ${N_TRIALS_PER}`; do
    (
      export N_CHAINS=1;
      export ATK_DS_CONFS=$nconfs;
      export SIM_ARGS=$(make print-sim-args);
      echo "$SIM_ARGS"
    )
  done
done | xargs -P 24 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
# $SIM_BIN $SIM_ARGS | grep "RESULT:" | cut -d ":" -f 2- | tee -a $OUT_FILE
