#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# for experimenting w/ reflected weight stuff

export N_TRIALS_PER=100
export REPEAT_TIMES=30
export HR_PER_CHAIN=100
export B_PERIOD=100
# export CRYPTO_SYSTEM=WeightedDag
export CRYPTO_SYSTEM=WeightedChain
# export ATK_STRATEGY=DoubleSpendWork
export ATK_STRATEGY=DoubleSpend

export DAA2_N_BLOCKS=1000

export ATK_DS_CONFS=5

# exp 10: longer DAA blocks -> more constant difficulty
# does this make attacks harder/easier?

export ATK_START_TICK=$(echo ${B_PERIOD}\*${DAA2_N_BLOCKS}/3 | bc)
export ATK_END_TICK=$(echo ${ATK_DS_CONFS}\*${B_PERIOD}\*10+${ATK_START_TICK} | bc)

echo "$ATK_START_TICK"
echo "$ATK_END_TICK"

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  # for atk_q in 0.36 0.4 0.42 0.44 0.46 0.48; do
  for atk_q in 0.40; do # 0.44; do
    export ATK_RATIO=${atk_q}
    export OUT_FILE=exp-10-R${ATK_STRATEGY}-q${ATK_RATIO}-t${ATK_DS_CONFS}-p${B_PERIOD}-H${HR_PER_CHAIN}-DAA${DAA2_N_BLOCKS}-${CRYPTO_SYSTEM}-blake3.csv
    if [[ ! -f $OUT_FILE ]]; then
      cp result-columns.csv $OUT_FILE
    fi

    for nchains in `seq 1 6` `seq 7 2 21` 30; do # 40 50
      for ntrials in `seq 1 ${N_TRIALS_PER}`; do
        (
          export N_CHAINS=${nchains};
          export SIM_ARGS=$(make print-sim-args);
          echo "$SIM_ARGS"
        )
      done
    done | xargs -P 36 -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
  done
done
