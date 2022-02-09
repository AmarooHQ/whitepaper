#!/usr/bin/env bash

success=0
failure=0

N_TRIALS=${N_TRIALS:-100}
N_CHAINS=${N_CHAINS:-10}
SIMULATOR_ARGS=${SIMULATOR_ARGS:-"-s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 -P $N_CHAINS"}
RUN_CMD="RUST_LOG=warn,por_sim_rs::strategies::relay=info target/release/por-sim-rs "

LOG_FILE="last_run.log"

# build it
cargo build --release

# run it
for i in `seq $N_TRIALS`; do
    bash -c "$RUN_CMD $SIMULATOR_ARGS" 2>&1 | tee $LOG_FILE
    if cat $LOG_FILE | grep "ATTACK SUCCESS"; then
        success=$((success+1))
    else
        failure=$((failure+1))
    fi
done

echo "Trials: ${N_TRIALS} -- Successes: ${success}; Failures: ${failure} (${SIMULATOR_ARGS})" | tee -a results.txt

# benchmarks:
#
# N_CHAINS=1 -- -s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 -P 1
# - Trials: 100 -- Successes: 37; Failures: 63
# - Trials: 100 -- Successes: 46; Failures: 54
# - Trials: 100 -- Successes: 46; Failures: 54
# - Trials: 100 -- Successes: 39; Failures: 61
# - runtime (s): 12
#
# N_CHAINS=2 -- -s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 -P 2
# - Trials: 100 -- Successes: 34; Failures: 66
# - Trials: 100 -- Successes: 33; Failures: 67
# - Trials: 100 -- Successes: 35; Failures: 65
# - runtime (s): 24, 24
#
# N_CHAINS=3
# - Trials: 100 -- Successes: 29; Failures: 71
# - runtime: 45 s (last: 460 ms)
