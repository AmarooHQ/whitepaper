from collections import defaultdict
from decimal import Decimal
from typing import Any, DefaultDict, List, Tuple
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
    return f"{round(value):,}" if 1 <= value < 10**6 else f"\x24{value:.1e}}}\x24" \
        .replace("e+0", "e+").replace("e+", "\\times 10^{") \
        .replace("e-0", "e-").replace("e-", "\\times 10^{-")

def table_header(table_name):
    headings = ({
        'tps': ['$O(c)$', '$O(c^2)$', '$O(c^2)$ UT', '$O(c^3)$ UT', '$O(c^4)$ UT'],
        'dappchains': ['$N_1$ (UT)', '$N_2$ (UT)', '$N_3$ (UT)', '$\Delta S$'],
        'tps_por': ['$N_1$', '$O(c^2)$ tps', '$N_2$', '$O(c^3)$ tps', 'PoR size (bytes)', '$\\nicefrac{N_1}{k}$'],
        'compare_nets': ['Network', 'Scaling Factor', 'TPS per base-chain', 'Network-wide TPS'],
    })[table_name]

    col_sizes = ({
        'tps': ['---','----','----','----','----'],
        'dappchains': ['---', '----', '----', '----'],
        'tps_por': ['---', '---', '----', '----', '----', '----'],
        'compare_nets': ['--------', '---------', '---', '---'],
    })[table_name]

    col1_heading = ({
        'compare_nets': '$k$, $D_f$, $D_h$',
        'other': '$k$, $B_f$, $D_f$, $B_h$, $D_h$',
    })[table_name if table_name in ['compare_nets'] else 'other']
    headings.insert(0, col1_heading)

    return [headings, ['--------'] + col_sizes]

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
            .replace('0.05', '\\nicefrac{1}{20}') \
            .replace('0.06666666666666667', '\\nicefrac{1}{15}') \
            .replace('0.08333333333333333', '\\nicefrac{1}{12}') \
            .replace('0.16666666666666666', '\\nicefrac{1}{6}') for r in row)


def format_params(params):
    return '$' + ', '.join(map(str, list(params)[:-1])) + '$'


def table_row(params, table_name):
    r = calc_tps_throughput(*params)
    cols = ({
        'tps': [format_params(params), r['btc_tps'], r['eth2_tps'], r['ut_2_tps'], r['ut_3_tps'], r['ut_4_tps']],
        'dappchains': [format_params(params), r['ut_n_1'], r['ut_n_2'], r['ut_n_3'], r['delta_s_Bps']],
        'tps_por': [format_params(params), r['ut_n_1_with_por'], r['ut_2_tps_with_por'], r['ut_n_2_with_por'], r['ut_3_tps_with_por'], r['ut_por_size'], r['ut_n1_per_k']],
    })[table_name]
    return format_table_row(cols)


def mod_ut_por_params(p: Tuple) -> Tuple:
    r = calc_tps_throughput(p[0], p[1], p[1], p[2], p[2], p[3])
    return (p[0], p[1], round(r['ut_with_por_bh']), p[3])

def mod_params_id(p: Tuple) -> Tuple:
    return p


def table_row_compare(net: str, params, table_name):
    p = params
    r = calc_tps_throughput(p[0], p[1], p[1], p[2], p[2], p[3])
    mod_params = defaultdict(lambda: mod_params_id, **({'UT_PoRs': mod_ut_por_params}))
    fp = format_params(mod_params[net](params))
    fn = net if 'UT' in net else net.capitalize()
    cols = ({
        'UT': [fp, fn, r['ut_n_2_factor'], r['ut_3_tps_per_basechain'], r['ut_3_tps']],
        'UT_PoRs': [fp, fn, r['ut_n_2_factor_with_por'], r['ut_3_tps_with_por_per_basechain'], r['ut_3_tps_with_por']],
        'bitcoin': [fp, fn, r['btc_n_2_factor'], r['btc_tps_per_basechain'], r['btc_tps']],
        'cardano': [fp, fn,  r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
        'polkadot': [fp, fn, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
        'eth2': [fp, fn, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps']],
    })[net.split(' ')[0]]
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
    (1000, 1/15, 1/15, 112, 250, 250),
    (3000, 1/15, 1/15, 112, 250, 250),
    (30000, 1/15, 1/15, 112, 250, 250),
    # fast chains
    (1000, 1/60, 1/60, 112, 250, 250),
    (3000, 1/60, 1/60, 112, 250, 250),
    (3000, 1/60, 1/60, 112, 500, 250),
    (3000, 1/60, 1/60, 200, 250, 250),
    (3000, 1/60, 1/60, 200, 500, 250),
    (30000, 1/60, 1/60, 200, 200, 250),
    (30000, 1/60, 1/60, 112, 200, 250),
    # slow chains
    (1000, 1/600, 1/600, 112, 250, 250),
    (3000, 1/600, 1/600, 200, 250, 250),
    (3000, 1/600, 1/600, 112, 250, 250),
    (30000, 1/600, 1/600, 200, 200, 250),
    (30000, 1/600, 1/600, 112, 200, 250),
    # fast root chain, slow dapp chains
    (1000, 1/60, 1/600, 112, 250, 250),
    (3000, 1/60, 1/600, 112, 250, 250),
    (30000, 1/60, 1/600, 112, 250, 250),
    # big headers
    (3000, 1/60, 1/60, 500, 500, 250),
    (3000, 1/60, 1/60, 500, 700, 250),
    (3000, 1/60, 1/60, 1000, 1000, 250),
    (3000, 1/60, 1/60, 1500, 1500, 250),
]

# Note: If eth2 really is as efficient as an 8kb update every ~27 hours then it's close enough to 0.
# (https://hackmd.io/@wemeetagain/SkuswKu_r#Update-data-size)
#
# But if a proof is required, too, then that's an extra 3.2kb!
# (https://hackmd.io/@wemeetagain/SkuswKu_r#Proof-sizes-Token-EE-Balance-Example)
#
# https://www.reddit.com/r/ethfinance/comments/ojafms/conjecture_how_far_can_rollups_data_shards_scale/
# > expect each data shard to target 2.480 MB per block (PS: this is history, not state).
# that's
#
# .
#

comparison_k = 3000
comparison_inputs = [
    ('bitcoin', (comparison_k, 1/600, 80, 250)),
    ('cardano', (comparison_k, 1/20, 1070, 250)),
    ('polkadot', (comparison_k, 1/6, 288, 250)),
    ('eth2', (comparison_k, 1/12, 200, 250)),
    ('UT', (comparison_k, 1/15, 112, 250)),
    ('UT (w/ tiling)', (comparison_k, 1/15, 112, 250)),
    ('bitcoin (w/ extras)', (comparison_k, 1/600, 80, 250)),
    ('cardano (w/ extras)', (comparison_k, 1/20, 1070 + 1024, 250)),
    ('polkadot (w/ extras)', (comparison_k, 1/6, 288 + 1024, 250)),
    ('eth2 (w/ extras)', (comparison_k, 1/12, 200 + (476 + 224 + 128 + 672 + 736 + 1024), 250)),
    ('UT_PoRs', (comparison_k, 1/15, 112, 250)),
    ('UT_PoRs (w/ tiling)', (comparison_k, 1/15, 112, 250)),
]

for table_name in ['tps', 'dappchains', 'tps_por']:
    print(f"\n#### TABLE: {table_name}\n")
    rows = table_header(table_name)
    rows += list(table_row(r, table_name) for r in row_inputs)
    padded_rows = pad_rows(rows, [])
    rows = list(map(row_to_str, padded_rows))
    print('\n'.join(rows))

for table_name in ['compare_nets']:
    print(f"\n### TABLE: {table_name}")
    rows = table_header(table_name)
    rows += list(table_row_compare(net, r, table_name) for (net, r) in comparison_inputs)
    for r in rows:
        if 'tiling' in r[1]:
            r[-1] = '$\infty$'
    padded_rows = pad_rows(rows, [])
    rows_str = list(map(row_to_str, padded_rows))
    print('\n'.join(rows_str))
