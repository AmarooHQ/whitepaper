#!/usr/bin/env python3

from collections import defaultdict
import os
import os.path as path
import random
import logging
import sys
from time import time

save_in = 'includes/ut/diags'
out_file = '27-practical-30-fig4-refls.tikz'
logging.warning(f"saving to {out_file}. currdir: {os.getcwd()}")
if not os.getcwd().endswith(save_in):
    out_file = f"{save_in}/{out_file}"

rand_seed = int(time())
for arg in sys.argv:
    if arg.startswith("entropy="):
        method = arg.split('=', 1)[-1]
        if method == "decisecond":
            rand_seed = int(time()) // 10
        else:
            try:
                rand_seed = int(method)
            except:
                rand_seed = method
    if arg == "no_replace_recent":
        # we don't want to run if the tikz file was generated recently
        if path.exists(out_file):
            mod_time = path.getmtime(out_file)
            if abs(time() - mod_time) < 60:
                logging.warning(f"bailing early b/c file was modified recently.")
                sys.exit()

logging.warning(f"set random.seed to {rand_seed}")
random.seed(rand_seed)

n_chains = 50
n_ticks = 100
phi_ticks = 3 * n_ticks // 15 // 10
avg_overlap = 1
overlap_each_tick = avg_overlap / phi_ticks
prob_mine = overlap_each_tick / n_chains

logging.warning("Parameters: %s", {
    "n_chains": n_chains,
    "n_ticks": n_ticks,
    "phi_ticks": phi_ticks,
    "avg_overlap": avg_overlap,
    "overlap_each_tick": overlap_each_tick,
    "prob_mine": prob_mine,
})
logging.warning(f"expected blocks per chain: {n_ticks * prob_mine}")

def block_flags_ixs(bs: list[int]):
    return list(ix for ix,b in enumerate(bs) if b)

focus_chain = 15

# def refl_stats(cbs):
#     bs = cbs[focus_chain]
#     b_ixs = block_flags_ixs(bs)
#     prev_block_t = max(ix for ix in b_ixs if ix < focus_block_min_t)
#     pp_block_t = max(ix for ix in b_ixs if ix < prev_block_t)
#     block_t = min(ix for ix in b_ixs if ix >= focus_block_min_t)
#     return {'t': block_t, 'pt': prev_block_t, 'ppt': pp_block_t}

def between(x, l, h):
    return l <= x <= h

def seg_is_suitable(cbs: list[list[int]]):
    for c, chain in enumerate(cbs):
        if sum(chain) == 0:
            return False
    if sum([c[-1] for c in cbs]) == 0:
        return False
    return len(cbs) > 1

last_block_for_chain = defaultdict(lambda: -1000)
def check_mine_block(prob_mine, chain_id, t):
    if last_block_for_chain[chain_id] > t - phi_ticks:
        return 0
    success = 1 if random.random() < prob_mine else 0
    if success:
        last_block_for_chain[chain_id] = t
    return success


def gen_blocks(chain_id, prob_mine, n_blocks):
    return list(check_mine_block(prob_mine, chain_id, t) for t in range(n_blocks))

def gen_chain_blocks():
    return list(gen_blocks(chain_id, prob_mine, n_ticks) for chain_id in range(n_chains))

chain_blocks = gen_chain_blocks()
# while not seg_is_suitable(chain_blocks):
#     chain_blocks = gen_chain_blocks()
#     chain_blocks[focus_chain][-1] = 1

# for chain in chain_blocks:
#     logging.warning(f"{{{','.join(map(str,chain))}}},")

# focus_chain_refl_stats = refl_stats(chain_blocks)
# fcrs = focus_chain_refl_stats
# logging.warning(fcrs)
# focus_b_t = fcrs['t']
# focus_pb_t = fcrs['pt']
# focus_ppb_t = fcrs['ppt']

# special_from = set((focus_chain,t) for t in [focus_b_t, focus_pb_t, focus_ppb_t])
# special_to = set((focus_chain,t) for t in [focus_pb_t, focus_ppb_t])

def find_block_between(c2, lower_t, upper_t):
    for t in range(upper_t, max(0, lower_t) - 1, -1):
        if chain_blocks[c2][t]:
            return (c2, t)
    return None

def refl_tips_of(c, t):
    rts = set(find_block_between(c2, t-phi_ticks, t-1) for c2 in range(n_chains) if c2 != c and find_block_between(c2, t-phi_ticks, t-1))
    if len(rts) == 0:
        return refl_tips_of(c, t-1)
    return rts

def refls_of(c, t):
    novel_refls = set()
    for t2 in range(t-1, -1, -1):
        novel_refls.update((c2, t2) for c2 in range(n_chains) if c2 != c and chain_blocks[c2][t2])
        if chain_blocks[c][t2]:
            break # break after adding refls from this t2
    return novel_refls

# focus_refl_tips = refl_tips_of(focus_chain, focus_b_t)
# focus_refls = refls_of(focus_chain, focus_b_t)
# focus_refl_nontips = focus_refls - focus_refl_tips

# focus_p_refl_tips = refl_tips_of(focus_chain, focus_pb_t)
# focus_p_refls = refls_of(focus_chain, focus_pb_t)
# focus_p_refl_nontips = focus_refls - focus_refl_tips

def all_blocks_in_refl_history(c, t):
    bs = set()
    edge = refls_of(c, t)
    while len(edge) > 0:
        c2, t2 = edge.pop()
        bs.add((c2, t2))
        to_add = refls_of(c2, t2) - edge - bs
        edge.update(to_add)
    return bs

# all_in_prev_rtips_past = set().union(*[all_blocks_in_refl_history(c, t) for c,t in focus_p_refl_tips])
# new_in_rtips_past = set().union(*[all_blocks_in_refl_history(c, t) for c, t in focus_refl_tips]) \
#     - all_in_prev_rtips_past \
#     - focus_p_refl_tips \
#     - special_from

# generate code for the whole graph

def node_style(c, t):
    return 'block'
    if c != focus_chain:
        ct = (c, t)
        if ct in all_in_prev_rtips_past:
            return 'block, color=green'
        if ct in new_in_rtips_past:
            return 'block, color=blue'
        if ct in focus_refl_tips:
            return 'block, color=red'
        if ct in focus_p_refl_tips:
            return 'block, color=orange'
    return 'block'

count_blocks = 0
def node_block(c, t):
    global count_blocks
    count_blocks += 1
    s = f"\\node ({nodename_of_block((c,t))}) [{node_style(c,t)}] at ({t}*\\sx, {c}*\\sy) {{}};"
    return s

def node_invis(c, t):
    return f"\\node ({nodename_of_block((c,t))}) at ({t}*\\sx, {c}*\\sy) {{}};"

def nodename_of_block(ct: tuple[int, int]):
    c, t = ct
    return f"c{c}t{t}"

def edge_style(ct_from, ct_to):
    cf, tf = ct_from
    ct, tt = ct_to

    if ct_to in refl_tips_of(*ct_from):
        return 'arFocus'
    return 'arNone'

    # we care about the focus chain
    if ct_from in special_from: # cf == focus_chain and tf <= focus_b_t:
        if ct_to in focus_refl_tips:
            return 'arFocusTip'
        if ct_to in focus_refl_nontips:
            return 'arFocusOut'
        if ct_to in focus_p_refl_tips:
            return 'arFocusPrevTip'
        if ct_to in focus_p_refl_nontips:
            return 'arFocusOut'
        # # we want special styling for these edges
        # if tf == focus_b_t:
        #     return 'arFocusOut'
        # return 'arPreFocusOut'
    # and reflections of the focus chain
    if ct_to in special_to:
        return 'arFocusIn'
    if ct_to in special_from:
        return 'ar'
    # default
    return 'ar'

count_refls = 0
count_sec_refls = 0

def edge_refl(ct_from, ct_to):
    global count_refls, count_sec_refls
    style = edge_style(ct_from, ct_to)
    if style != 'arNone':
        count_refls += 1
        s = f"\\draw [{style}] ({nodename_of_block(ct_from)}) -- ({nodename_of_block(ct_to)});"
        return s
    else:
        count_sec_refls += 1

def edge_parent(ct_from, ct_to):
    s = f"\\draw [pAr] ({nodename_of_block(ct_from)}) -- ({nodename_of_block(ct_to)});"
    return s

def other_chains(local_c):
    return {c for c in range(n_chains) if c != local_c}

tikz_lines = []

# loop through ticks and construct por graph segment
for t in range(n_ticks):
    for c in range(n_chains):
        blocks = chain_blocks[c]
        got_block = 1 == blocks[t]
        if got_block:
            tikz_lines.append(node_block(c, t))
            # now to check for refls
            last_local_block = -1
            for prev_t in range(t - 1, -1, -1):
                if blocks[prev_t]:
                    last_local_block = prev_t
                    tikz_lines.append(edge_parent((c,t), (c, prev_t)))
                    break
            # check to see if we're the first block
            if last_local_block < 0:
                tikz_lines.append(node_invis(c, -1))
                tikz_lines.append(edge_parent((c,t), (c, -1)))
            # we reflect any and all R blocks that were not in last local block's history
            for other_c in other_chains(c):
                for prev_t in range(t - 1, max(last_local_block - 1, -1), -1):
                    if chain_blocks[other_c][prev_t]:
                        tikz_lines.append(edge_refl((c, t), (other_c, prev_t)))

# final arrows from future parents
for c in range(n_chains):
    blocks = chain_blocks[c]
    last_local_block = None
    for t in range(n_ticks - 1, -1, -1):
        if blocks[t]:
            last_local_block = t
            break
    else:
        continue
        # raise Exception(f'no local blocks for chain {c}')
    tikz_lines.append(node_invis(c, n_ticks))
    tikz_lines.append(edge_parent((c, n_ticks), (c, last_local_block)))

with open(out_file, 'w') as f:
    f.write("\n".join(l for l in tikz_lines if l))

logging.warning(f"count_blocks / n_chains: {count_blocks / n_chains}")
logging.warning(f"count_refls: {count_refls}")
logging.warning(f"count_sec_refls: {count_sec_refls}")
