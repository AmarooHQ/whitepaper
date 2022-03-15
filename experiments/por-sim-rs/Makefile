default: test

N_CHAINS ?= 10
B_PERIOD ?= 100
DAA2_N_BLOCKS ?= 100
ATK_DS_CONFS ?= 20
ATK_START_TICK ?= $(shell echo $(B_PERIOD)\*$(DAA2_N_BLOCKS) | bc)
ATK_END_MULTIPLIER ?= 10
ATK_END_TICK ?= $(shell echo $(ATK_DS_CONFS)\*$(B_PERIOD)\*$(ATK_END_MULTIPLIER)+$(ATK_START_TICK) | bc)
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

lock-release:
	chmod -w target/release/por-sim-rs

unlock-release:
	chmod u+w target/release/por-sim-rs

release:
	cargo build --release

build:
	cargo build

print-sim-args:
	@echo '$(SIMULATOR_ARGS)'

stop-sim-clean:
	@echo '>> Sim will stop after this iteration finishes. <<'
	touch cleanly_stop_sim

clear-stop-sim-file:
	rm cleanly_stop_sim

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

run-bonusblock-checker:
	RUST_LOG=warn,por_sim_rs::message_manager=debug cargo r -- -s 5000 -e 13000 -r 0.46 -R DoubleSpendWork -S WeightedDag -H 50 -b 50 --ds_win_threshold 5 -P 5 --random_hr_distrib --use_dyn_end_tick

run-check-high-hr:
	RUST_LOG=warn,por_sim_rs::message_manager=debug cargo r -- -s 10000 -e 3000 -r 0.36 -R DoubleSpendWork -S WeightedDag -H 50 -b 50 --daa2_n_blocks 1000 --ds_win_threshold 5 -P 5 --random_hr_distrib --use_dyn_end_tick

run-check-fractional-dswin: build
	RUST_LOG=warn,por_sim_rs::message_manager=debug ./target/debug/por-sim-rs -s 2500 -e 3000 -r 0.44 -R DoubleSpendWork -S WeightedDag -H 50 -b 50 --daa2_n_blocks 100 --ds_win_threshold 2.5 -P 5 --random_hr_distrib --use_dyn_end_tick

run-dag-doublespend:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r -- -s 10000 -e 20000 -r 0.45 -R DoubleSpendWork -S WeightedDag -b 100

run-dag-doublespend-por:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r -- -s 10000 -e 20000 -r 0.45 -R DoubleSpendWork -S WeightedDag -b 100 -P 10

run-dag-doublespend-100:
	# export SIMULATOR_ARGS="-s $(ATK_START_TICK) -e $(ATK_END_TICK) -r $(ATK_RATIO) -S WeightedDag -b $(B_PERIOD) -P $(N_CHAINS) -H $(HR_PER_CHAIN) --ds_win_threshold $(ATK_DS_CONFS)" ; \
	./bin/run_n_times.sh

sudo-flamegraph:
	bash ./bin/unsafe_flamegraph.sh

print-randomized-hr-distributions:
	cargo t -- --nocapture --test test_random_hr_distribution_properties

print-randhr-pmfs: print-randomized-hr-distributions
