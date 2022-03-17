#!/bin/bash

export RUST_LOG=warn
export PERF=$HOME/src/WSL2-Linux-Kernel/tools/perf/perf

echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
# cargo flamegraph -- -s 20000 -e 60000 -r 0.4 -R SelfishMining -S LongestChain \
# cargo flamegraph -- -s 10000 -e 20000 -S WeightedChain -r 0.3 -P 9 \
cargo flamegraph -- -s 100000 -e 150000 --ds_win_threshold 20 -r 0.48 -P 30 -b 75 -H 75 --use_dyn_end_tick \
  -S WeightedDag -R DoubleSpendWork \
  --daa2_n_blocks 2000 --random_hr_distrib \
  && wslview flamegraph.svg
echo 2 | sudo tee /proc/sys/kernel/perf_event_paranoid
