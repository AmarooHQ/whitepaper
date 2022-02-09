#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs

export B_PERIOD=50;
export ATK_RATIO=0.44;

for nchains in `seq 1 40`; do
  for ntrials in `seq 1 500`; do
    (
      export N_CHAINS=${nchains};
      export SIM_ARGS=$(make print-sim-args);
      echo "$SIM_ARGS"
    )
  done
done | xargs -P 24 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a exp-3.csv"
# $SIM_BIN $SIM_ARGS | grep "RESULT:" | cut -d ":" -f 2- | tee -a exp-3.csv
