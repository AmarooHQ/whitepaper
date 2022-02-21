#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# for experimenting w/ reflected weight stuff

export N_TRIALS_PER=100
export REPEAT_TIMES=30
# export HR_PER_CHAIN=100
export HR_PER_CHAIN=50  # okay provided we have atk_q divisible by 0.02
export B_PERIOD=100
export CRYPTO_SYSTEM=WeightedDag
# export CRYPTO_SYSTEM=WeightedChain
export ATK_STRATEGY=DoubleSpendWork
# export ATK_STRATEGY=DoubleSpend
export ATK_DS_CONFS=5

export DAA2_N_BLOCKS=100

# export ATK_END_DELAY_TICKS=$(echo ${B_PERIOD}\*2 | bc)

# exp 11: atk_end_delay_ticks -- what happens if we wait say 0.25 block periods? or 2 block periods?
# note re old csvs: had to fix `condition for stopping based on RelayStrategy` in message_manager.rs -- I noticed that nothing was ending early without also being successful
# todo: why did old csvs look better, then?
# note old2: fix public_draft_refl_work in _atk_won of DoubleSpendStrat

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  # for delay_ticks in $(echo ${B_PERIOD}/4 | bc) $(echo ${B_PERIOD}/2 | bc) $(echo ${B_PERIOD}\*1 | bc) $(echo ${B_PERIOD}\*2 | bc); do
  for delay_ticks in 0; do
    export ATK_END_DELAY_TICKS=$delay_ticks
    # for atk_q in 0.36 0.4 0.42 0.44 0.46 0.48; do
    for atk_q in 0.40; do
      for ds_confs in 5; do
        export ATK_RATIO=${atk_q}
        export OUT_FILE=exp-11-R${ATK_STRATEGY}-q${ATK_RATIO}-t${ATK_DS_CONFS}-p${B_PERIOD}-H${HR_PER_CHAIN}-DAA${DAA2_N_BLOCKS}-delay${ATK_END_DELAY_TICKS}-${CRYPTO_SYSTEM}-blake3.csv
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
  done
done
