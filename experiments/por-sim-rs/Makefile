default: test

N_CHAINS ?= 10

test:
	cargo test

run-dag-doublespend:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r --release -- -s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 2>&1 | tail -n 100

run-dag-doublespend-por:
	RUST_LOG=warn,por_sim_rs::strategies::relay=info cargo r --release -- -s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 -P 10 2>&1 | tail -n 100


run-dag-doublespend-100:
	export SIMULATOR_ARGS="-s 10000 -e 30000 -r 0.45 -S WeightedDag -b 100 -P $(N_CHAINS)" ; \
		./bin/run_n_times.sh
