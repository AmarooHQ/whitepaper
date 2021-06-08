#!/bin/bash

export RUST_LOG=warn

echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
# cargo flamegraph --bin por-sim-rs -- -S WeightedDag -n 100 -r 0.3 -s 20000 \
cargo flamegraph -- -s 20000 -e 60000 -n 100 -r 0.4 -R SelfishMining -S SimpleChain \
  && explorer.exe flamegraph.svg
echo 2 | sudo tee /proc/sys/kernel/perf_event_paranoid
