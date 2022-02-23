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

# prediction: as N_1 (the number of simplex chains) grows, X confirmations on one chain is as secure as N_1 * X confirmations. like, for a doublespend to succeed, if you wait X confirmations on a chain, then the doublespend (with given parameters) occurs as often as if it were waiting for N_1 * X confirmations on a traditional chain (e.g. bitcoin, ethereum).
# - this is based on Meni Rosenfeld's 2012 paper on confirmation dynamics Analysis of hashrate-based double-spending (archive.org). basically: security depends on # of confirmations, not time. so if N_1 chains, the confirmation rate is N_1*B_f, so we get N_1 times as many confirmations as w/ a single chain. The prediction is basically just a restatement of that.
# - note: there might be issues w/ the simulator at some point b/c of the architecture (everything is done in 'steps' w/ a block target time of 10 steps, which means 10% of blocks would be 'stale' in bitcoin parlance)
