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

def was_a_block_mined(block_period: float, group_size=1):
    '''
    run this once per tick.
    block_period is measured in ticks.
    '''
    for _ in range(group_size):
        # x = rand.random()  # [0,1]
        # block mined win condition
        # if x * block_period < 1:
        if rand.random() * block_period < 1:
            return True
    return False

def run_expected_delay(block_period=100, por_depth=1, group_size=1):
    '''
    por_depth >= 1 (depth 1 = two-chain mutual PoR; depth 0 = trad blockchain (no PoR), so d>0)
    number of M chains = n_m = por_depth-1
    reflection set-up:
      L <-> M^1 <-> M^2 <-> ... <-> M^{n_m} <-> R
    group size: how many chains are in M^i or R (a group is equiv to a tile; we assume there are that many chains in R (we don't care which provides the first reflection))
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
            _grp_sz = 1 if i == 0 else group_size
            if was_a_block_mined(block_period, group_size=_grp_sz):
                # we only use this value for the L-chain anyway
                if i == 0:
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

def run_test_expected_delay(n_trials=3000, max_por_depth=10, block_period=300):
    '''Hypothesis: expected delay is 2x por depth = length of recursive PoR'''
    results: dict[int, dict[int, list[int]]] = defaultdict(lambda: defaultdict(list))
    stats_msgs_per_data_set = 13
    trials_per_pct = n_trials / stats_msgs_per_data_set
    group_sizes = [1, 10, 50, 100]
    por_depths = list(filter(lambda d: d < 3 or d % 2 == 1, range(1, max_por_depth+1)))
    n_data_sets = len(por_depths) * len(group_sizes)
    c_data_sets_done = 0

    def print_results():
        table_h_line = "|-----|--------|-----|--------|"
        table_headings = "| PoR length | Avg. # of L-blocks mined | Group Size | Predicted Equiv (to GrpSz=1): $(\\text{Avg.} - 2) \\cdot \\text{Group Size} + 2$ |"
        res_strs = [table_headings]
        for _grp_sz in group_sizes:
            res_strs.append(table_h_line)
            for por_depth in por_depths:
                _res = results[_grp_sz][por_depth]
                if len(_res) > 0:
                    avg_l_blocks = sum(_res) / len(_res)
                    predicted_equiv = (avg_l_blocks - 2) * _grp_sz + 2
                    res_strs.append(f"| {por_depth:3d} | {avg_l_blocks:6.2f} | {_grp_sz:3d} | {predicted_equiv:6.2f} |")
        info(f"\n\n >> RESULTS (N={n_trials}; 1/B_f={block_period}) << \n\n" + '\n'.join(res_strs))

    for _grp_sz in group_sizes:
        for por_depth in por_depths:
            for trial_no in range(n_trials):
                res = run_expected_delay(por_depth=por_depth, block_period=block_period, group_size=_grp_sz)
                results[_grp_sz][por_depth].append(res[0][0])
                if floor(trial_no % trials_per_pct) == 0:
                    info(f"{(trial_no / n_trials + c_data_sets_done) / n_data_sets * 100:.1f} % complete (PoR length: {por_depth}, Grp Sz: {_grp_sz}, DS: {c_data_sets_done+1} of {n_data_sets})")
            c_data_sets_done += 1
        # at end of each chunk of group sizes, print interim results
        print_results()
    # don't need to print results at end if we do it during each outer loop
    # print_results()
    return

run_test_expected_delay()
