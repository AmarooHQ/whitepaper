#!/bin/bash

export RUST_LOG=warn
export PERF=$HOME/src/WSL2-Linux-Kernel/tools/perf/perf

echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
# cargo flamegraph -- -s 20000 -e 60000 -r 0.4 -R SelfishMining -S SimpleChain \
# cargo flamegraph -- -s 10000 -e 20000 -S WeightedChain -r 0.3 -P 9 \
cargo flamegraph -- -s 100000 -e 150000 -S WeightedDag -r 0.45 -P 9 -b 100 -H 100 \
  && wslview flamegraph.svg
echo 2 | sudo tee /proc/sys/kernel/perf_event_paranoid
