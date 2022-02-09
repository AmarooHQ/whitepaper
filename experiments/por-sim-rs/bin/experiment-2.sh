#!/usr/bin/env bash

for nchains in `seq 11 20`; do
  for i in `seq 3`; do
    N_CHAINS=${nchains} make run-dag-doublespend-100
  done
done
