#!/usr/bin/env bash

# this is expected to be run in dir w/ Cargo.toml & Makefile
SIM_BIN=./target/release/por-sim-rs
cargo b --release

# for experimenting w/ reflected weight stuff

export N_TRIALS_PER=100
export REPEAT_TIMES=100
export HR_PER_CHAIN=100
export B_PERIOD=100
export CRYPTO_SYSTEM=WeightedDag
export CRYPTO_SYSTEM=WeightedChain

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  # for atk_q in 0.36 0.4 0.42 0.44 0.46 0.48; do
  for atk_q in 0.44; do
    for ds_confs in 5 10 20; do
      export ATK_RATIO=${atk_q}
      export ATK_DS_CONFS=${ds_confs}
      export OUT_FILE=exp-8-q${ATK_RATIO}-t${ATK_DS_CONFS}-p${B_PERIOD}-H${HR_PER_CHAIN}-blake3.csv
      if [[ ! -f $OUT_FILE ]]; then
        cp result-columns.csv $OUT_FILE
      fi

      for nchains in `seq 1 6` `seq 7 2 21` 30 40 50; do
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


# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  # for atk_q in 0.36 0.4 0.42 0.44 0.46 0.48; do
  for atk_q in 0.40; do
    for ds_confs in 10; do
      export ATK_RATIO=${atk_q}
      export ATK_DS_CONFS=${ds_confs}
      export OUT_FILE=exp-8-q${ATK_RATIO}-t${ATK_DS_CONFS}-p${B_PERIOD}-H${HR_PER_CHAIN}-blake3.csv
      if [[ ! -f $OUT_FILE ]]; then
        cp result-columns.csv $OUT_FILE
      fi

      for nchains in 30 40 50; do
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

# loop a few times so we incrementally generate data over the whole x-axis
for repeat_i in `seq 1 ${REPEAT_TIMES}`; do
  # for atk_q in 0.36 0.4 0.42 0.44 0.46 0.48; do
  for atk_q in 0.40; do
    for ds_confs in 5 20; do
      export ATK_RATIO=${atk_q}
      export ATK_DS_CONFS=${ds_confs}
      export OUT_FILE=exp-8-q${ATK_RATIO}-t${ATK_DS_CONFS}-p${B_PERIOD}-H${HR_PER_CHAIN}-blake3.csv
      if [[ ! -f $OUT_FILE ]]; then
        cp result-columns.csv $OUT_FILE
      fi

      for nchains in `seq 1 6` `seq 7 2 21` 30 40 50; do
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
