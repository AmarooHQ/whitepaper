#!/usr/bin/env python3

from collections import defaultdict
from decimal import Decimal
from typing import Any, DefaultDict, List, Optional, Tuple
from numpy.lib.scimath import sqrt
from scipy.special import lambertw
from numpy import log, log2, real
import math


def por_with_merkle_branches_n1_root(k, bf, bh, g):
    ln2 = log(2)
    inner_w = (2 ** (bh / g - 1) * sqrt(math.e) * k * ln2)/(bf * g)
    d = 2 * bf * g * real(lambertw(inner_w))
    return math.floor(k * ln2 / d)


def calc_tps_throughput(k, bf, df, bh, dh, tx_size):
    ut_n_1 = k / (2 * bh * bf)
    ut_n_2_factor = k / (2 * dh * df)
    ut_n_2 = ut_n_1 * ut_n_2_factor
    ut_2_tps = k**2 / (4 * bf * bh) / tx_size
    ut_3_tps = k**3 / (4 * bf * bh * df * dh) / tx_size
    ut_4_tps = k**4 / (4 * bf * bh * df**2 * dh**2) / tx_size
    ut_n_1_with_por = por_with_merkle_branches_n1_root(k, bf, bh, 32)
    ut_k_1b_with_por = int(round(bf * ut_n_1_with_por * (bh + 32 * log2(ut_n_1_with_por))))
    ut_k_1tx_with_por = k - ut_k_1b_with_por
    ut_n_2_factor_with_por = ut_k_1tx_with_por / (dh * df)
    # ut_n_2_factor_with_por = k / (2 * ut_with_por_effective_bh * df)  # do we need to include PoRs with the header size for N_2? I don't think so... --> don't need to be recorded in the simplex-chain
    ut_n_2_with_por = ut_n_1_with_por * ut_n_2_factor_with_por
    ut_with_por_effective_bh = k / (2 * bf * ut_n_1_with_por)
    ut_n1_per_k = ut_n_1_with_por / k
    ut_n_2_with_por = ut_n_1_with_por * ut_n_2_factor_with_por
    ut_2_with_por = k * ut_n_1_with_por
    ut_2_tps_with_por = ut_2_with_por / tx_size
    ut_3_with_por = k * ut_n_2_with_por
    ut_3_tps_with_por = ut_3_with_por / tx_size

    return {
        'btc_tps': k / tx_size,
        'btc_n_2_factor': 1,
        'btc_tps_per_basechain': k / tx_size,
        # c^2 estimate, remove constants to be optimistic
        'eth2_tps': k**2 / (df * dh) / tx_size,
        'eth2_n_2_factor': k / (df * dh),
        'ut_2_tps': ut_2_tps,
        # c^3 estimate
        'ut_3_tps': ut_3_tps,
        'ut_3_tps_per_basechain': ut_3_tps / ut_n_1,
        'ut_4_tps': ut_4_tps,
        'ut_m_tps': '{:.2f} million'.format(ut_3_tps / 1000000),
        'ut_chain_gb_per_year': k * 60 * 60 * 24 * 365.25 / (1024 ** 3),
        'ut_n_1': ut_n_1,
        'ut_n_2': ut_n_2,
        'ut_n_2_factor': ut_n_2_factor,
        'ut_n_1_with_por': ut_n_1_with_por,
        'ut_n_2_with_por': ut_n_2_with_por,
        'ut_2_tps_with_por': ut_2_tps_with_por,
        'ut_n_2_factor_with_por': ut_n_2_factor_with_por,
        'ut_3_tps_with_por': ut_3_tps_with_por,
        'ut_3_tps_with_por_per_basechain': ut_3_tps_with_por / ut_n_1_with_por,
        'ut_with_por_bh': ut_with_por_effective_bh,
        'ut_por_size': ut_with_por_effective_bh - bh,
        'ut_n1_per_k': ut_n1_per_k,
        'ut_3_optimal_dappchains': k / (2 * dh * df),
        'ut_n_3': k**3 / (4 * bh * bf * dh**2 * df**2),
        'delta_s_Bps': k**2 / (2 * bh * bf),
    }

def fmt_rounded_commas(value):
    if isinstance(value, str):
        return value
    return f"{round(value):,}" if 1 <= value < 10**6 else f"\x24{value:.2e}}}\x24" \
        .replace("e+0", "e+").replace("e+", "\\times 10^{") \
        .replace("e-0", "e-").replace("e-", "\\times 10^{-")

def table_header(table_name):
    headings = ({
        'tps': ['$O(c)$', '$O(c^2)$ (optimal)', '$O(c^2)$ UT', '$O(c^3)$ UT', '$O(c^4)$ UT'],
        'dappchains': ['$N_1$ (UT)', '$N_2$ (UT)', '$N_3$ (UT)', '$\Delta S$'],
        'tps_por': ['$N_1$', '$O(c^2)$ tps', '$N_2$', '$O(c^3)$ tps', 'PoR (bytes)', '$\\nicefrac{N_1}{k}$'],
        'compare_nets_3k': ['Network', 'Scaling Factor', 'TPS per base-chain', 'Network-wide TPS', 'UT TPS out-scales by'],
        'compare_nets_30k': ['Network', 'Scaling Factor', 'TPS per base-chain', 'Network-wide TPS', 'UT TPS out-scales by'],
        'comparison_1m_tps': ['Network', 'Scaling Factor', 'TPS per base-chain', 'Network-wide TPS', 'UT $k$ out-scales by'],
    })[table_name]

    col_sizes = ({
        'tps': ['---','----','----','----','----'],
        'dappchains': ['----', '-----', '-----', '-----'],
        'tps_por': ['---', '----', '----', '----', '-----', '----'],
        'compare_nets_3k': ['------', '-------', '-----', '-------', '------'],
        'compare_nets_30k': ['------', '-------', '-----', '-------', '------'],
        'comparison_1m_tps': ['---', '---', '----', '-----', '----'],
    })[table_name]

    col_heading_lookup = {
        'compare_nets_3k': '$k$, $D_f$, $D_h$',
        'compare_nets_30k': '$k$, $D_f$, $D_h$',
        'default': '$k$, $B_f$, $B_h$',
    }
    col1_heading = col_heading_lookup.get(table_name, col_heading_lookup['default'])
    headings.insert(0, col1_heading)

    return [headings, ['------'] + col_sizes]

    # return '\n'.join([
    #     '| ' + ' | '.join(headings) + ' |',
    #     '|'.join(['', '--------'] \
    #     + col_sizes + [''])
    # ])


def format_table_row(row: List[Any]):
    return list(fmt_rounded_commas(r).strip() \
            .replace('0.0016666666666666668', '\\nicefrac{1}{600}') \
            .replace('0.016666666666666666', '\\nicefrac{1}{60}') \
            .replace('0.025', '\\nicefrac{1}{40}') \
            .replace('0.03333333333333333', '\\nicefrac{1}{30}') \
            .replace('0.05', '\\nicefrac{1}{20}') \
            .replace('0.06666666666666667', '\\nicefrac{1}{15}') \
            .replace('0.08333333333333333', '\\nicefrac{1}{12}') \
            .replace('0.16666666666666666', '\\nicefrac{1}{6}') \
            .replace('1.8181818181818181', '\\nicefrac{1}{0.55}') for r in row)


def format_params(params):
    return '$' + ', '.join(map(str, list(params)[:-1])) + '$'


def table_row(params, table_name):
    p = params
    r = calc_tps_throughput(p[0], p[1], p[1], p[2], p[2], p[3])
    cols = ({
        'tps': [format_params(params), r['btc_tps'], r['eth2_tps'], r['ut_2_tps'], r['ut_3_tps'], r['ut_4_tps']],
        'dappchains': [format_params(params), r['ut_n_1'], r['ut_n_2'], r['ut_n_3'], r['delta_s_Bps']],
        'tps_por': [format_params(params), r['ut_n_1_with_por'], r['ut_2_tps_with_por'], r['ut_n_2_with_por'], r['ut_3_tps_with_por'], r['ut_por_size'], r['ut_n1_per_k']],
    })[table_name]
    return format_table_row(cols)


def mod_ut_por_params(p: Tuple) -> Tuple:
    r = calc_tps_throughput(p[0], p[1], p[1], p[2], p[2], p[3])
    return p  # we don't need to alter D_h, just B_h, so don't mod the param
    # return (p[0], p[1], round(r['ut_with_por_bh']), p[3])

def mod_params_id(p: Tuple) -> Tuple:
    return p

def table_row_compare_inner(net: str, params):
    p = params
    r = calc_tps_throughput(p[0], p[1], p[1], p[2], p[2], p[3])
    mod_params = defaultdict(lambda: mod_params_id, **({'UT+PoRs': mod_ut_por_params}))
    fp = format_params(mod_params[net](params))
    fn = net if 'UT' in net else net.capitalize()
    cols = ({
        'UT': [fp, fn, r['ut_n_2_factor'], r['ut_3_tps_per_basechain'], r['ut_3_tps']],
        'UT+PoRs': [fp, fn, r['ut_n_2_factor_with_por'], r['ut_3_tps_with_por_per_basechain'], r['ut_3_tps_with_por']],
        'bitcoin': [fp, fn, r['btc_n_2_factor'], r['btc_tps_per_basechain'], r['btc_tps']],
        'cardano': [fp, fn,  r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
        'polkadot': [fp, fn, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
        'eth2': [fp, fn, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
        'solana': [fp, fn, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
    })[net.split(' ')[0]]
    return cols

def ratio_to_x(ratio):
    return f"${ratio:.1f}\\times$"

def table_row_compare(net: str, params, ut_tps: int):
    cols = table_row_compare_inner(net, params)
    return format_table_row(cols + [ratio_to_x(ut_tps / cols[-1])])

def table_row_1m_compare(net: str, params, ut_k):
    cols = table_row_compare_inner(net, params) + [ratio_to_x(params[0] / ut_k)]
    return format_table_row(cols)

def is_table_aligner(item: str) -> bool:
    return '-' in item and 0 == len(item.replace('-', ''))

def space_item(item: str):
    c = '' if is_table_aligner(item) else ' '
    return f"{c}{item}{c}"

def row_to_str(cols: List[str]):
    cols_str = ([''] + list(space_item(c) for c in cols) + [''])
    return '|'.join(cols_str).strip()


def pad_rows(rows: List[List[str]], ns: List[int]):
    for n in (ns or range(len(rows[0]))):
        max_coln = max(map(lambda c: len(c[n]), rows))
        for c in rows:
            char = '' if is_table_aligner(c[0]) else ' '
            c[n] += char * (max_coln - len(c[n]))
    return rows


## NOTE: too many table entries to be useful. it'd be nice to generate the data
## with a more ordered format, though.
# row_inputs = []
# for k in [1000, 3000, 30000]:
#     for b_f in [1/20, 1/60, 1/600]:
#         for d_f in [1/20, 1/60, 1/600]:
#             for b_h in [112, 200, 500]:
#                 for d_h in [200, 250, 500]:
#                     for tx_avg in [250]:
#                         row_inputs.append((k, b_f, d_f, b_h, d_h, tx_avg))

row_inputs = [
    # ver fast chains
    (1000, 1/15, 112, 250),
    (3000, 1/15, 112, 250),
    (30000, 1/15, 112, 250),
    # fast chains
    (1000, 1/30, 112, 250),
    (3000, 1/30, 112, 250),
    (30000, 1/30, 112, 250),
    # moderate chains
    (1000, 1/60, 112, 250),
    (3000, 1/60, 112, 250),
    (30000, 1/60, 112, 250),
    # slow chains
    (1000, 1/600, 112, 250),
    (3000, 1/600, 112, 250),
    (30000, 1/600, 112, 250),
    # bigger headers
    # (1000, 1/60, 200, 250),
    # (3000, 1/60, 200, 250),
    # (30000, 1/60, 200, 250),
    # (1000, 1/600, 200, 250),
    # (3000, 1/600, 200, 250),
    # (30000, 1/600, 200, 250),
    # big headers
    (3000, 1/30, 200, 250),
    (3000, 1/30, 500, 250),
    (3000, 1/30, 1000, 250),
    (3000, 1/30, 1500, 250),
]

# Note: If eth2 really is as efficient as an 8kb update every ~27 hours then it's close enough to 0.
# (https://hackmd.io/@wemeetagain/SkuswKu_r#Update-data-size)
#
# But if a proof is required, too, then that's an extra 3.2kb!
# (https://hackmd.io/@wemeetagain/SkuswKu_r#Proof-sizes-Token-EE-Balance-Example)
#
# curious, a post about Eth2 reaching 14 million tps
# https://www.reddit.com/r/ethfinance/comments/ojafms/conjecture_how_far_can_rollups_data_shards_scale/
# > expect each data shard to target 2.480 MB per block (PS: this is history, not state).
# that's: k ~= 206,000
# plugging that in to comparison table: 1e7 (10million) tps; so in the ballpark
#

comparison_ks = {'compare_nets_3k': 3000, 'compare_nets_30k': 30000}
def mk_comparison_inputs(k: int):
    ''' returns a list of network params with a network name. '''
    return [
        ('bitcoin', (k, 1/600, 80, 250)),
        ('solana', (k, 1/0.55, 141, 250)),
        ('cardano', (k, 1/20, 1070, 250)),
        ('polkadot', (k, 1/6, 288, 250)),
        ('eth2', (k, 1/12, 200, 250)),
        ('UT+PoRs', (k, 1/15, 112, 250)),
        ('UT', (k, 1/15, 112, 250)),
        ('UT w/ tiling', (k, 1/15, 112, 250)),
    ]
#     ('bitcoin', (comparison_k2, 1/600, 80, 250)),
#     ('solana', (comparison_k2, 1/0.4, 141, 250)),
#     ('cardano', (comparison_k2, 1/20, 1070, 250)),
#     ('polkadot', (comparison_k2, 1/6, 288, 250)),
#     ('eth2', (comparison_k2, 1/12, 200, 250)),
#     ('UT+PoRs', (comparison_k2, 1/15, 112, 250)),
#     ('UT', (comparison_k2, 1/15, 112, 250)),
#     ('UT w/ tiling', (comparison_k2, 1/15, 112, 250)),
#     # ('bitcoin (w/ extras)', (comparison_k, 1/600, 80, 250)),
#     # ('cardano (w/ extras)', (comparison_k, 1/20, 1070 + 1024, 250)),
#     # ('polkadot (w/ extras)', (comparison_k, 1/6, 288 + 1024, 250)),
#     # ('eth2 (w/ extras)', (comparison_k, 1/12, 200 + (476 + 224 + 128 + 672 + 736 + 1024), 250)),
#     # ('UT+PoRs', (comparison_k, 1/15, 112, 250)),
#     # ('UT+PoRs (w/ tiling)', (comparison_k, 1/15, 112, 250)),
#     # ('eth2', (206000, 1/12, 200, 250)),  # approx the '14m tps' claim above
#     # ('UT', (8298, 1/15, 112, 250)),
#     # ('solana', (248500, 1/0.4, 141, 250)),  # should match their '700k tps theoretical limit' claim
#     # ('UT', (3393, 1/15, 112, 250)),
# ]

UT_1M_K = 3826

'''For comparison_1m_tps: for non-UT we want to chose the *lowest* value of k where the total TPS rounds to 1.00*10^6; and for UT we want to choose the *largest* k that does similarly. This will minimize the 'out-scaling' ratios.'''
comparison_1m_tps = [
    ('bitcoin', (250000000, 1/600, 80, 250)),
    ('solana', (296900, 1/0.55, 141, 250)),
    ('cardano', (115700, 1/20, 1070, 250)),
    ('polkadot', (109810, 1/6, 288, 250)),
    ('eth2', (64600, 1/12, 200, 250)),
    ('UT+PoRs', (math.floor(UT_1M_K * 1.438), 1/15, 112, 250)),
    ('UT', (UT_1M_K, 1/15, 112, 250)),
]

def mk_table(table_name, row_func):
    print(f"\n### TABLE: {table_name}")
    rows = table_header(table_name)
    rows += row_func()
    padded_rows = pad_rows(rows, [])
    rows_str = list(map(row_to_str, padded_rows))
    print('\n'.join(rows_str))


for table_name in ['tps', 'dappchains', 'tps_por']:
    mk_table(table_name, lambda: list(table_row(r, table_name) for r in row_inputs))


for table_name in ['compare_nets_3k', 'compare_nets_30k']:
    k = comparison_ks[table_name]
    net_inputs = mk_comparison_inputs(k)
    ut_row = table_row_compare_inner('UT', list(filter(lambda i: i[0] == 'UT', net_inputs))[0][1])
    ut_tps: int = ut_row[-1]
    def mk_row():
        rows = list(table_row_compare(net, r, ut_tps) for (net, r) in net_inputs)
        for r in rows:
            if 'tiling' in r[1]:
                r[-2] = '$\\infty$'
                r[-1] = '$0.0\\times$'
        return rows
    mk_table(table_name, mk_row)


for table_name in ['comparison_1m_tps']:
    mk_table(table_name, lambda: list(table_row_1m_compare(net, r, UT_1M_K) for (net, r) in comparison_1m_tps))


"""
# Notes on props relevant to scalability of various chains

### Polkadot:

* header size: 288 bytes (via polkadot.js rpc)
* block time: 6s

https://telemetry.polkadot.io/#/Polkadot

also I made a little `npm init && npm i -S polkadot.js` project to get the header size (which is pretty easy; polkadot.js seems good -- I've seen way worse)

### Eth 2:

* header size: 192 bytes (mb 224?) (via lighthouse beaconchain node http API)
* 12s block times (inferred b/c there seems to be a very regular 5 blocks/min pattern; couldn't find a source as easily)

### Cardano:

* header size: 1070 B -- via https://liberlion.medium.com/what-you-should-know-about-cardano-part-1-8c59ebbace49 -- note: secondary source and doesn't provide citation
* 20s block time -- inferred via ~4250 blocks per day -> v close to 20s block time; data from: https://messari.io/asset/cardano/charts/network-activity/blocks

### Solana:

* header size: 64 + 1 + (8+8+8+8) + 32 + 4 + 8 = 141 -> 144 bytes after padding
* block time about 550ms atm (31/8/21) via https://explorer.solana.com/ -- this source says 600ms https://forkast.news/what-is-solana-why-hottest-blockchain/

https://docs.rs/solana/0.16.6/src/solana/packet.rs.html#341 (the linked line is an incremental construction of the header layout)

also WTF re their hardware requirements!? https://youtu.be/6HHHYtPPUaA?t=421 !!! J.C.

also good on their validators getting access to zen3 threadrippers only weeks after specifications were *leaked*. :/ (the author meant 3000 series threadrippers which are zen2)

how solana makes sure the validator base is decentralized enough :/ <https://twitter.com/aeyakovenko/status/1315689754743107584>

"""
