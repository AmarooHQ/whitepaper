#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# Single chain doublespend vs theoretical.
# aux2: WeightedDag + DSW

export OUT_F_PREFIX=exp_aux2

export B_PERIOD=100
export ATK_RATIO=0.40
export N_TRIALS_PER=100
export REPEAT_TIMES=30
export HR_PER_CHAIN=100
# export CRYPTO_SYSTEM=WeightedChain
export CRYPTO_SYSTEM=WeightedDag
export ATK_STRATEGY=DoubleSpendWork
export N_CHAINS=1

# run 2nd time for DS+LC
export CRYPTO_SYSTEM=LongestChain
export ATK_STRATEGY=DoubleSpend


# loop a few times so we incrementally generate data over the whole x-axis
for ds_conf_base in 5; do # 5 10 20; do
  for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
    export OUT_FILE=${OUT_F_PREFIX}_q=${ATK_RATIO}_dsconf-base=${ds_conf_base}_${ATK_STRATEGY}_${CRYPTO_SYSTEM}.csv
    echo "$OUT_FILE"
    # exit 0
    if [[ ! -f $OUT_FILE ]]; then
      cp result-columns.csv $OUT_FILE
    fi

    # called `nchains` to remain consistent with other experiments
    for nchains in `seq 1 6` `seq 7 2 21` 30; do
      nconfs=$(echo $nchains\*$ds_conf_base | bc)
      for ntrials in `seq 1 ${N_TRIALS_PER}`; do
        (
          export ATK_DS_CONFS=$nconfs;
          export SIM_ARGS=$(make print-sim-args);
          echo "$SIM_ARGS"
        )
      done
    done | xargs -P 24 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
  done
done
