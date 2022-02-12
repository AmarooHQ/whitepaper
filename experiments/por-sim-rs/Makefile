default: test

N_CHAINS ?= 10
B_PERIOD ?= 25
DAA2_N_BLOCKS ?= 100
ATK_DS_CONFS ?= 20
ATK_START_TICK ?= $(shell echo $(B_PERIOD)\*$(DAA2_N_BLOCKS) | bc)
ATK_END_TICK ?= $(shell echo $(ATK_DS_CONFS)\*$(B_PERIOD)\*5+$(ATK_START_TICK) | bc)
ATK_RATIO ?= 0.44
HR_PER_CHAIN ?= 1000

# CRYPTO_SYSTEM ?= WeightedDag
CRYPTO_SYSTEM ?= WeightedChain

RUN_BIN = target/release/por-sim-rs

SIMULATOR_ARGS ?= -s $(ATK_START_TICK) -e $(ATK_END_TICK) -r $(ATK_RATIO) -S $(CRYPTO_SYSTEM) -b $(B_PERIOD) -P $(N_CHAINS) -H $(HR_PER_CHAIN) --ds_win_threshold $(ATK_DS_CONFS)

test:
	cargo test

stats:
	./bin/py_stats.py

run-dag-doublespend:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r --release -- -s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 2>&1 | tail -n 100

run-dag-doublespend-por:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r --release -- -s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 -P 10 2>&1 | tail -n 100

run-dag-doublespend-100:
	# export SIMULATOR_ARGS="-s $(ATK_START_TICK) -e $(ATK_END_TICK) -r $(ATK_RATIO) -S WeightedDag -b $(B_PERIOD) -P $(N_CHAINS) -H $(HR_PER_CHAIN) --ds_win_threshold $(ATK_DS_CONFS)" ; \
	./bin/run_n_times.sh

print-sim-args:
	@echo '$(SIMULATOR_ARGS)'
