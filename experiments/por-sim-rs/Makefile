default: test

N_CHAINS ?= 10
B_PERIOD ?= 100
DAA2_N_BLOCKS ?= 100
ATK_DS_CONFS ?= 20
ATK_START_TICK ?= $(shell echo $(B_PERIOD)\*$(DAA2_N_BLOCKS) | bc)
ATK_END_TICK ?= $(shell echo $(ATK_DS_CONFS)\*$(B_PERIOD)\*7+$(ATK_START_TICK) | bc)
ATK_RATIO ?= 0.44
HR_PER_CHAIN ?= 100
# ATK_STRATEGY ?= DoubleSpendWork
ATK_STRATEGY ?= DoubleSpend
ATK_END_DELAY_TICKS ?= 0

# set this env var to `1` to do random hash-rate distrib
RANDOMLY_DISTRIBUTE_HASHRATES ?=
_RAND_HRS_ARG =
ifeq ($(RANDOMLY_DISTRIBUTE_HASHRATES),1)
	_RAND_HRS_ARG = --random_hr_distrib
endif

ATK_USE_DYN_END_TICK ?=
_USE_DYN_END =
ifeq ($(ATK_USE_DYN_END_TICK),1)
	_USE_DYN_END = --use_dyn_end_tick
endif


CRYPTO_SYSTEM ?= WeightedDag
# CRYPTO_SYSTEM ?= WeightedChain

RUN_BIN = target/release/por-sim-rs

SIMULATOR_ARGS ?= -R $(ATK_STRATEGY) -s $(ATK_START_TICK) -e $(ATK_END_TICK) -r $(ATK_RATIO) -S $(CRYPTO_SYSTEM) -b $(B_PERIOD) -P $(N_CHAINS) -H $(HR_PER_CHAIN) --ds_win_threshold $(ATK_DS_CONFS) --daa2_n_blocks $(DAA2_N_BLOCKS) --atk_end_delay_ticks $(ATK_END_DELAY_TICKS) $(_RAND_HRS_ARG) $(_USE_DYN_END)

test:
	cargo test

release:
	cargo build --release

print-sim-args:
	@echo '$(SIMULATOR_ARGS)'

stats:
	./bin/py_stats.py

run-random-hr-distrib:
	cargo r -- --random_hr_distrib --ds_win_threshold 5 -s 10000 -e 20000 -r 0.45 -S WeightedChain -b 50 -H 50 -P 11

run-lc-20k-blocks:
	cargo r -- -s 10000 -e 1000000 -r 0.0 -S WeightedChain -b 50 -H 50 -P 1

run-lc-20k-blocks-10simplex:
	cargo r -- -s 10000 -e 1000000 -r 0.0 -S WeightedChain -b 50 -H 50 -P 11

run-lc-20k-blocks-20simplex:
	cargo r -- -s 10000 -e 1000000 -r 0.0 -S WeightedChain -b 50 -H 50 -P 21

run-lc-50k-blocks: release
	$(RUN_BIN) -s 10000 -e 2500000 -r 0.0 -S WeightedChain -b 50 -H 50 -P 1

run-lc-50k-blocks-10simplex: release
	$(RUN_BIN) -s 10000 -e 2500000 -r 0.0 -S WeightedChain -b 50 -H 50 -P 11

run-lc-50k-blocks-20simplex: release
	$(RUN_BIN) -s 10000 -e 2500000 -r 0.0 -S WeightedChain -b 50 -H 50 -P 21

run-dag-doublespend:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r -- -s 10000 -e 20000 -r 0.45 -S WeightedDag -b 100 2>&1 | tail -n 100

run-dag-doublespend-por:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r -- -s 10000 -e 20000 -r 0.45 -S WeightedDag -b 100 -P 10 2>&1 | tail -n 100

run-dag-doublespend-100:
	# export SIMULATOR_ARGS="-s $(ATK_START_TICK) -e $(ATK_END_TICK) -r $(ATK_RATIO) -S WeightedDag -b $(B_PERIOD) -P $(N_CHAINS) -H $(HR_PER_CHAIN) --ds_win_threshold $(ATK_DS_CONFS)" ; \
	./bin/run_n_times.sh

sudo-flamegraph:
	bash ./bin/unsafe_flamegraph.sh
