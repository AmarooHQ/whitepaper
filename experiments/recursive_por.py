'''
ctx: recursive PoR between single chains (L <-> M <-> R)
q: how long is the delay for recursive PoRs?
assumptions:
- chains have equal B_f
'''

import random as rand
import logging
from logging import info
from collections import defaultdict
from math import floor

logging.basicConfig(level=logging.INFO)

def was_a_block_mined(block_period: float):
    '''
    run this once per tick.
    block_period is measured in ticks.
    '''
    x = rand.random()  # [0,1]
    # block mined win condition
    return x * block_period < 1

def run_expected_delay(block_period=100, por_depth=1):
    '''
    por_depth >= 1 (depth 1 = two-chain mutual PoR; depth 0 = trad blockchain (no PoR), so d>0)
    number of M chains = n_m = por_depth-1
    reflection set-up:
      L <-> M^1 <-> M^2 <-> ... <-> M^{n_m} <-> R
    '''
    assert por_depth >= 1
    n_chains = por_depth + 1
    # idx 0 is chain L, idx -1 is chain R (other chains are M chains)
    chain_logs: list[list[int]] = [[] for _ in range(n_chains)]
    tick_n = 0
    # assume that we start from a confirmation on chain L
    chain_logs[0].append(tick_n)
    waiting_for_chain = 1
    first_half_por_path = True
    # break condition: waiting_for_chain is -1 and first_half_por_path = False
    while waiting_for_chain >= 0 or first_half_por_path:
        tick_n += 1
        count_conf_this_tick = True
        for i, cl in enumerate(chain_logs):
            if was_a_block_mined(block_period):
                cl.append(tick_n)
                if i == waiting_for_chain and count_conf_this_tick:
                    # info(f"Waited for confirmation on chain {i} at tick {tick_n} (DONE)")
                    # check if we're at R chain, reverse direction if so
                    if i == n_chains - 1:
                        first_half_por_path = False
                    waiting_for_chain += 1 if first_half_por_path else -1
                    count_conf_this_tick = False
    ret = (len(chain_logs[0]), f"L-blocks mined"), (chain_logs[0][-1], f"ticks taken")
    # info(f"completed after {' '.join(map(str, ret[0]))}")
    return ret

def run_test_expected_delay(n_trials=10000, max_por_depth=7, block_period=20):
    '''Hypothesis: expected delay is 2x por depth = length of recursive PoR'''
    results: dict[int, list[int]] = defaultdict(list)
    trials_per_pct = n_trials / 25
    for por_depth in range(1, max_por_depth+1):
        for trial_no in range(n_trials):
            res = run_expected_delay(por_depth=por_depth, block_period=block_period)
            results[por_depth].append(res[0][0])
            if floor(trial_no % trials_per_pct) == 0:
                info(f"{trial_no / n_trials * 100:.1f} % complete (PoR length: {por_depth})")

    res_strs = ["| PoR length | Avg. # of L-blocks mined |", "|---|---|"]
    for por_depth in range(1, max_por_depth+1):
        _res = results[por_depth]
        avg_l_blocks = sum(_res) / len(_res)
        res_strs.append(f"| {por_depth:2d} | {avg_l_blocks:5.2f} |")
    info(f"\n\n >> RESULTS (N={n_trials}) << \n")
    info('\n'.join(res_strs))

run_test_expected_delay()
