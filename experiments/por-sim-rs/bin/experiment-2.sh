#!/usr/bin/env bash

for nchains in `seq 21 21`; do
  for i in `seq 3`; do
    N_CHAINS=${nchains} B_PERIOD=100 make run-dag-doublespend-100 &
  done
done

wait
