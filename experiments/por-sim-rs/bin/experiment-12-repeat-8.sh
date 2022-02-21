#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# for experimenting w/ reflected weight stuff

export OUT_F_PREFIX=exp-12-repeat-8

export N_TRIALS_PER=100
export REPEAT_TIMES=30
export HR_PER_CHAIN=50
export B_PERIOD=50
# export CRYPTO_SYSTEM=WeightedDag
export CRYPTO_SYSTEM=WeightedChain
# export ATK_STRATEGY=DoubleSpendWork
export ATK_STRATEGY=DoubleSpend

# updated manually if hash changes in code
# export HASH_ALG=blake3
export HASH_ALG=xxh3

export N_CPUS=$(echo $(grep -c ^processor /proc/cpuinfo)-1 | bc)
echo $N_CPUS

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  # for atk_q in 0.36 0.4 0.42 0.44 0.46 0.48; do
  for atk_q in 0.40 0.44 0.48; do
    for ds_confs in 5 10 20; do
      export ATK_RATIO=${atk_q}
      export ATK_DS_CONFS=${ds_confs}
      export OUT_FILE=${OUT_F_PREFIX}-R${ATK_STRATEGY}-q${ATK_RATIO}-t${ATK_DS_CONFS}-p${B_PERIOD}-H${HR_PER_CHAIN}-${CRYPTO_SYSTEM}-${HASH_ALG}.csv
      if [[ ! -f $OUT_FILE ]]; then
        cp result-columns.csv $OUT_FILE
      fi

      for nchains in `seq 1 6` `seq 7 2 15` 19 23 30 45; do
        for ntrials in `seq 1 ${N_TRIALS_PER}`; do
          (
            export N_CHAINS=${nchains};
            export SIM_ARGS=$(make print-sim-args);
            echo "$SIM_ARGS"
          )
        done
      done | xargs -P $N_CPUS -I{} sh -c "$SIM_BIN {} | grep 'RESULT:' | cut -d ':' -f 2- | tee -a $OUT_FILE"
    done
  done
done
