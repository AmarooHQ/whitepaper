#!/bin/bash

export RUST_LOG=warn

echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
cargo flamegraph --bin por-sim-rs -- -S WeightedDag -n 100 -r 0.3 -s 6000 && explorer.exe flamegraph.svg
echo 2 | sudo tee /proc/sys/kernel/perf_event_paranoid
