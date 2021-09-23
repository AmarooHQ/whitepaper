#!/usr/bin/env python3

from collections import defaultdict
from decimal import Decimal
from typing import Any, DefaultDict, List, Optional, Tuple, Union
from numpy.lib.scimath import sqrt, power
from scipy.special import lambertw
from numpy import log, log2, real, floor
import math
import sys


UT_NET_NAME_LOOKUP = {
    'UT':  '$\\UT{1}$', 'UT+HO':  '$\\UT{1+\\text{HO}}$', 'UT+HOT':  '$\\UT{1+\\text{HOT}}$', 'UT+PoRs':  '$\\UT{1+\\text{PoRs}}$', 'UT+PoRTs':  '$\\UT{1+\\text{PoRTs}}$',
    'UT2': '$\\UT{2}$', 'UT2+HO': '$\\UT{2+\\text{HO}}$', 'UT2+HOT': '$\\UT{2+\\text{HOT}}$', 'UT2+PoRs': '$\\UT{2+\\text{PoRs}}$', 'UT2+PoRTs': '$\\UT{2+\\text{PoRTs}}$',
    'UT3': '$\\UT{3}$', 'UT3+HO': '$\\UT{3+\\text{HO}}$', 'UT3+HOT': '$\\UT{3+\\text{HOT}}$', 'UT3+PoRs': '$\\UT{3+\\text{PoRs}}$', 'UT3+PoRTs': '$\\UT{3+\\text{PoRTs}}$',
    'UT2 inf': '$\\UTinf{2}$',
    'ideal sharded': 'Opt.Shard',  # make sure you update the name in the WP if this changes, too.
}

"""
eth2:
- 8192 validator set update data -- once per slot = 1/6.5 min
  - per shard
- 200 byte headers, only every 10th recorded
  - per shard
effective header size is 8192 / (6.5*60/12) + 200 * .1
"""
ETH2_EFFECTIVE_HEADER = int(8192 / (6.5*60/12) + 200 * .1)
ETH2_1M_K = 75278

# HO and HOT optimization stuff

HO_B_H = 32
HOT_B_H = 16

def hot_offset_f(d_h):
    return HOT_B_H if d_h == 84 else HO_B_H

def hot_calc_dh2(b_h, d_h):
    # NOTE: b_h is expected to be 16 already if using +HOT
    return d_h - hot_offset_f(d_h) if b_h == HOT_B_H else d_h

def por_with_merkle_branches_n1_root(k, bf, bh, g):
    ln2 = log(2)
    inner_w = (2 ** (bh / g - 1) * sqrt(math.e) * k * ln2)/(bf * g)
    d = 2 * bf * g * real(lambertw(inner_w))
    # return math.floor(k * ln2 / d)
    return (k * ln2 / d)

# ! NOTE: Older bits of this code still use the old UT nomenclature, like `ut_2_tps` is UT_1's tps -- T_1/tx_size
# ! Just something to keep in mind as you're reading below. e.g. `ut_4_tps` corresponds to O(c^4) UT -- now called UT_3

def calc_tps_throughput(k, bf, df, bh, dh, tx_size):
    ut_n_1 = k / (2 * bh * bf)
    ut_n_2_factor = k / (2 * dh * df)
    ut_n_2 = ut_n_1 * ut_n_2_factor
    ut_2_t1 = k**2 / (4 * bf * bh)
    ut_2_tps = k**2 / (4 * bf * bh) / tx_size
    ut_3_t2 = k**3 / (4 * bf * bh * df * dh)
    ut_3_tps = k**3 / (4 * bf * bh * df * dh) / tx_size
    ut_4_t3 = k**4 / (4 * bf * bh * df**2 * dh**2)
    ut_4_tps = k**4 / (4 * bf * bh * df**2 * dh**2) / tx_size
    ut_n_1_with_por = por_with_merkle_branches_n1_root(k, bf, bh, 32)
    ut_n_1_with_port = por_with_merkle_branches_n1_root(k, bf, bh, 16)
    ut_k_1b_with_por = int(round(bf * ut_n_1_with_por * (bh + 32 * log2(ut_n_1_with_por))))
    ut_k_1b_with_port = int(round(bf * ut_n_1_with_port * (bh + 16 * log2(ut_n_1_with_port))))
    por_hash_len = 16 if bh == 16 else 32
    ut_k1_full_node = k + int(bf * ut_n_1 * (bh + por_hash_len * log2(ut_n_1)))
    ut_k_1tx_with_por = k - ut_k_1b_with_por
    ut_k_1tx_with_port = k - ut_k_1b_with_port
    ut_n_2_factor_with_por = ut_k_1tx_with_por / (dh * df)
    ut_n_2_factor_with_port = ut_k_1tx_with_port / (dh * df)
    # ut_n_2_factor_with_por = k / (2 * ut_with_por_effective_bh * df)  # do we need to include PoRs with the header size for N_2? I don't think so... --> don't need to be recorded in the simplex-chain
    ut_n_2_with_por = ut_n_1_with_por * ut_n_2_factor_with_por
    ut_n_2_with_port = ut_n_1_with_port * ut_n_2_factor_with_port
    ut_with_por_effective_bh = k / (2 * bf * ut_n_1_with_por)
    ut_with_port_effective_bh = k / (2 * bf * ut_n_1_with_port)
    ut_n1_per_k_with_por = ut_n_1_with_por / k
    ut_n1_per_k_with_port = ut_n_1_with_port / k
    ut_2_with_por = k * ut_n_1_with_por
    ut_2_with_port = k * ut_n_1_with_port
    ut_2_tps_with_por = ut_2_with_por / tx_size
    ut_2_tps_with_port = ut_2_with_port / tx_size
    ut_3_with_por = k * ut_n_2_with_por
    ut_3_with_port = k * ut_n_2_with_port
    ut_3_tps_with_por = ut_3_with_por / tx_size
    ut_3_tps_with_port = ut_3_with_port / tx_size

    return {
        'btc_t1': k,
        'btc_tps': k / tx_size,
        'btc_n_2_factor': 1,
        'btc_tps_per_basechain': k / tx_size,
        # c^2 estimate, remove constants to be optimistic
        'eth2_t2': k**2 / (df * dh),
        'eth2_tps': k**2 / (df * dh) / tx_size,
        'eth2_n_2_factor': k / (df * dh),
        'ut_2_t1': ut_2_t1,
        'ut_2_tps': ut_2_tps,
        # c^3 estimate
        'ut_3_t2': ut_3_t2,
        'ut_3_tps': ut_3_tps,
        'ut_2_tps_per_basechain': ut_2_tps / ut_n_1,
        'ut_3_tps_per_basechain': ut_3_tps / ut_n_1,
        'ut_4_tps': ut_4_tps,
        'ut_m_tps': '{:.2f} million'.format(ut_3_tps / 1000000),
        'ut_chain_gb_per_year': k * 60 * 60 * 24 * 365.25 / (1024 ** 3),
        'ut_n_1': ut_n_1,
        'ut_n_2': ut_n_2,
        'ut_n_2_factor': ut_n_2_factor,
        'ut_n_1_with_por': ut_n_1_with_por,
        'ut_n_1_with_port': ut_n_1_with_port,
        'ut_n_2_with_por': ut_n_2_with_por,
        'ut_n_2_with_port': ut_n_2_with_port,
        'ut_2_t1_with_por': ut_2_with_por,
        'ut_2_t1_with_port': ut_2_with_port,
        'ut_2_tps_with_por': ut_2_tps_with_por,
        'ut_2_tps_with_port': ut_2_tps_with_port,
        'ut_2_tps_with_por_per_basechain': ut_2_tps_with_por / ut_n_1_with_por,
        'ut_2_tps_with_port_per_basechain': ut_2_tps_with_port / ut_n_1_with_port,
        'ut_n_2_factor_with_por': ut_n_2_factor_with_por,
        'ut_n_2_factor_with_port': ut_n_2_factor_with_port,
        'ut_3_t2_with_por': ut_3_with_por,
        'ut_3_t2_with_port': ut_3_with_port,
        'ut_3_tps_with_por': ut_3_tps_with_por,
        'ut_3_tps_with_port': ut_3_tps_with_port,
        'ut_3_tps_with_por_per_basechain': ut_3_tps_with_por / ut_n_1_with_por,
        'ut_3_tps_with_port_per_basechain': ut_3_tps_with_port / ut_n_1_with_port,
        'ut_with_por_bh': ut_with_por_effective_bh,
        'ut_with_port_bh': ut_with_port_effective_bh,
        'ut_por_size': ut_with_por_effective_bh - bh,
        'ut_port_size': ut_with_port_effective_bh - bh,
        'ut_n1_per_k_with_por': ut_n1_per_k_with_por,
        'ut_n1_per_k_with_port': ut_n1_per_k_with_port,
        'ut_3_optimal_dapp-chains': k / (2 * dh * df),
        'ut_n_3': k**3 / (4 * bh * bf * dh**2 * df**2),
        'delta_s_bps_btc': k,
        'delta_s_bps': k * ut_n_1,
        # todo start
        'delta_s_bps_por': k,
        'delta_s_bps_port': k,  # the point of +PoRTs is that you don't need to download all blocks
        # 'delta_s_bps_por_anyway': k * ut_n_1_with_por,
        # 'delta_s_bps_port_anyway': k * ut_n_1_with_por,
        'full_node_delta_s': ut_k1_full_node,
        'full_node_delta_s_por': k,  # the point of +PoRs is that you don't need to download all blocks
        'full_node_delta_s_port': k,  # the point of +PoRTs is that you don't need to download all blocks
        'tts_1': ut_k1_full_node / 10000000 * (365.25 * 5),
        'tts_1_por': k / 10000000 * (365.25 * 5),
        'tts_1_port': k / 10000000 * (365.25 * 5),
        # todo end
        'ut_confirmation_rate': ut_n_1 * bf,
        'ut_confirmation_rate_por': ut_n_1_with_por * bf,
        'ut_confirmation_rate_port': ut_n_1_with_port * bf,
        'btc_confirmation_rate': bf,
    }

def bandwidth_to_k_solana(delta_s, bf, bh):
    '''
    assuming:
        * PoH need to be transmitted infrequently (N > 100 say)
        * An ordered list of msg hashes is required so validators know the order of txs
        * Validators need to know that the transactions are valid too (given some state) and have received those txs
    So validators need bandwidth: PoH packet + N*20 B for msg order + 176*N B for txs
        * PoH packet lim-> 0; 176+20 for each transaction ~ 200B
    '''
    return delta_s


def bandwidth_to_k(delta_s, bf, bh, dh=None):
    '''
    UT1: DeltaS = k**2 / (2 * bh * bf)
    power(2 * ds * bh * bf, 1/2)

    UT2: DeltaS = k**3 / (4 * bf * bh * df * dh)
    power(delta_s * bf * bf * bh * bh * 4, 1/3)
    NB: technically DeltaS = T_2 + k**2 / (2 * bh * bf); but T_2 >> k**2 / (2 * bh * bf); like, > 99.9% for k=3000

    eth2: T_2 = k**2 / (df * dh)
    power(delta_s * bf * bh, 1/2)
    '''
    dh = dh if dh is not None else bh
    ut1_k = power(2 * delta_s * bf * bh, 1/2)
    ut2_k = power(delta_s * bf * bf * bh * dh * 4, 1/3)

    eth2_k = power(delta_s * bf * bh, 1/2)

    return {
        'UT': ut1_k,
        'UT+HOT': ut1_k,
        'UT2': ut2_k,
        'UT2+HOT': ut2_k,
        'ideal sharded': eth2_k,
        'eth2': eth2_k,
        'polkadot': eth2_k,
        # 'cardano': eth2_k,
        'cardano': delta_s,
        'solana': delta_s,
        'bitcoin': delta_s,
    }


def tps_to_k(tps, tx_size, bf, bh):
    hot_bh_reduction = ({84: 16, 112: 32})[bh]
    throughput = tps*tx_size
    ut1_k = power(throughput * 4 * bf * bh, 1/2)
    ut1_hot_k = power(throughput * 4 * bf * 16, 1/2)
    ut2_k = power(throughput * 4 * bf * bf * bh * bh, 1/3)
    ut2_ho_k = power(throughput * 4 * bf * bf * (bh) * 32, 1/3)
    ut2_hot_k = power(throughput * 4 * bf * bf * (bh - hot_bh_reduction) * 16, 1/3)
    ideal_sharded = power(throughput * bf * (bh - hot_bh_reduction), 1/2)

    return {
        'UT': ut1_k,
        'UT+HOT': ut1_hot_k,
        'UT2': ut2_k,
        'UT2+HO': ut2_ho_k,
        'UT2+HOT': ut2_hot_k,
        'ideal_sharded': ideal_sharded,
        # 'eth2': eth2_k,
        # 'polkadot': eth2_k,
        # 'cardano': eth2_k,
        # 'solana': delta_s,
        # 'bitcoin': delta_s,
    }


def fmt_rounded_commas(value, non_sn_range=(1, 10**6), should_round=True, precision=2):
    if isinstance(value, str):
        return value
    mb_round = lambda v: f"{round(v):,}" if should_round else f"{v:,.{precision}f}"
    return mb_round(value) if non_sn_range[0] <= value < non_sn_range[1] else f"\x24{value:.{precision}e}}}\x24" \
        .replace("e+0", "e+").replace("e+", "\\times 10^{") \
        .replace("e-0", "e-").replace("e-", "\\times 10^{-")

def table_header(table_name: str):
    tn_no_opim = table_name.removesuffix("_optimized")
    _headings = ({
        'tps': ['$O(c)$', 'Sharded $O(c^2)$', '$\\UT{1}$', '$\\UT{2}$', '$\\UT{3}$'],
        'tps_optimized': ['$O(c)$', 'Sharded $O(c^2)$'] + [UT_NET_NAME_LOOKUP[n] for n in ['UT+HOT', 'UT2+HOT', 'UT3+HOT']],
        'dapp-chains': ['$N_1$ ($\\UT{1}$)', '$N_2$ ($\\UT{2}$)', '$N_3$ ($\\UT{3}$)', '$\\Delta S$', '$\\mathbb{C}^\\prime$ (Hz)'],
        # 'dapp-chains_optimized': [f'$N_1$ ({UT_NET_NAME_LOOKUP["UT+HOT"]})', f'$N_2$ ({UT_NET_NAME_LOOKUP["UT2+HOT"]})', f'$N_3$ ({UT_NET_NAME_LOOKUP["UT3+HOT"]})', '$\\Delta S$', '$\\mathbb{C}^\\prime$ (Hz)'],
        'dapp-chains_optimized': [f'$N_1$', f'$N_2$', f'$N_3$', '$\\Delta S$', '$\\mathbb{C}^\\prime$ (Hz)'],
        'tps_por': ['$N_1$', '$\\UT{1}$ tps', '$N_2$', '$\\UT{2}$ tps', 'PoR (bytes)', '$\\nicefrac{N_1}{k}$'],
        'tps_port': ['$N_1$', '$\\UT{1}$ tps', '$N_2$', '$\\UT{2}$ tps', 'PoR (bytes)', '$\\nicefrac{N_1}{k}$'],
        'compare_nets_3k': ['Network', 'Scaling Factor', '$\\nicefrac{\\Sigma \\text{TPS}}{N_1}$', '$\\Sigma$ TPS', 'TPS vs $\\UT{2}$'],
        'compare_nets_30k': ['Network', 'Scaling Factor', '$\\nicefrac{\\Sigma \\text{TPS}}{N_1}$', '$\\Sigma$ TPS', 'TPS vs $\\UT{2}$'],
        'comparison_1m_tps': ['Network', '$\\nicefrac{\\Sigma \\text{TPS}}{N_1}$', '$\\Sigma$ TPS', '$k$ vs $\\UT{2}$', 'Equivalent $\\UT{2}$ TPS'],
        'comparison_1m_tps_conf_hz': ['Network', 'Equivalent $\\UT{2}$ Confirmation Rate (Hz)'],
        'comparison_1gbps': ['Network', 'TPS', '$k$ (B/s)', 'MB/chain/day'], #'$\\nicefrac{\\text{TPS}}{k_1}$ vs $\\UT{2}$'], #, '$k_1 \cdot$ TPS vs $\\UT{2}$', 'TPS vs $\\UT{2}$', 'combined'],
        'compare_optimizations': [UT_NET_NAME_LOOKUP[v] for v in ['UT+PoRs', 'UT+PoRTs', 'UT', 'UT+HO', 'UT+HOT']],
    })
    headings = _headings.get(table_name, _headings[tn_no_opim])

    _col_sizes = ({
        'tps': ['---','------','----','----','----'],
        'dapp-chains': ['----', '-----', '-----', '-----', '----'],
        'dapp-chains_optimized': ['----', '-----', '-----', '----', '----'],
        'tps_por': ['---', '----', '----', '----', '-----', '----'],
        'tps_port': ['---', '----', '----', '----', '-----', '----'],
        'compare_nets_3k':  ['------', '---', '---', '----', '------'],
        'compare_nets_30k': ['------', '---', '---', '----', '------'],
        'comparison_1m_tps': ['---', '----', '---', '-----', '-----'],
        'comparison_1m_tps_conf_hz': ['---', '----'],
        'comparison_1gbps': ['---', '---', '---', '----'], #'-----'], #'-----', '------'],
        'compare_optimizations': ['-----', '-----', '----', '-----', '-----']
    })
    col_sizes = ['------'] + _col_sizes.get(table_name, _col_sizes[tn_no_opim])

    col_heading_lookup = {
        'compare_nets_3k': '$k$, $B_f$, $B_h$',
        'compare_nets_30k': '$k$, $B_f$, $B_h$',
        'comparison_1gbps': '$\\Delta S$, $B_f$, $B_h$, Tx (B)',
        'compare_optimizations': '',
        'default_optimized': '$k$, $B_f$, $B_h$, $D_h$',
        'default': '$k$, $B_f$, $B_h$',
    }
    default_name = 'default'
    default_name = 'default_optimized' if 'optimized' in table_name else default_name
    col1_heading = col_heading_lookup.get(table_name, col_heading_lookup[default_name])
    headings.insert(0, col1_heading)

    return [headings, col_sizes]


def format_table_row(row: List[Any]):
    return list(fmt_rounded_commas(r).strip() \
            .replace('0.0016666666666666668', '\\nicefrac{1}{600}') \
            .replace('0.016666666666666666', '\\nicefrac{1}{60}') \
            .replace('0.025', '\\nicefrac{1}{40}') \
            .replace('0.03333333333333333', '\\nicefrac{1}{30}') \
            .replace('0.05', '\\nicefrac{1}{20}') \
            .replace('0.06666666666666667', '\\nicefrac{1}{15}') \
            .replace('0.08333333333333333', '\\nicefrac{1}{12}') \
            .replace('0.14285714285714285', '\\nicefrac{1}{7}') \
            .replace('0.15384615384615385', '\\nicefrac{2}{13}') \
            .replace('0.16666666666666666', '\\nicefrac{1}{6}') \
            .replace('1.8181818181818181', '\\nicefrac{1}{0.55}') for r in row)


def format_params(params, strip_last_n=1):
    ps = list(params)[:-1 * strip_last_n] if strip_last_n > 0 else list(params)  # remove TPS (last param)
    k = ps[0]
    ps[0] = k if isinstance(k, str) or k < 10**6 else fmt_rounded_commas(k, precision=1).replace('$', '')  # any K > 1m in scientific notation
    conv_f = lambda p: str(p[1] if isinstance(p, list) else p)
    return '$' + ', '.join(map(conv_f, ps)) + '$'

def ratio_to_x(ratio):
    # return f"${ratio:.1f}\\times$"
    return f"$({fmt_rounded_commas(ratio, should_round=False, precision=3).strip('$')})\\times$"

def table_row(params, table_name: str, r):
    fp = format_params(params)
    cols = ({
        'tps': [fp, r['btc_tps'], r['eth2_tps'], r['ut_2_tps'], r['ut_3_tps'], r['ut_4_tps']],
        'dapp-chains': [fp, r['ut_n_1'], r['ut_n_2'], r['ut_n_3'], r['delta_s_bps'], fmt_rounded_commas(r['ut_confirmation_rate'], should_round=False)],
        'tps_por': [fp, r['ut_n_1_with_por'], r['ut_2_tps_with_por'], r['ut_n_2_with_por'], r['ut_3_tps_with_por'], r['ut_por_size'], r['ut_n1_per_k_with_por']],
        'tps_port': [fp, r['ut_n_1_with_port'], r['ut_2_tps_with_port'], r['ut_n_2_with_port'], r['ut_3_tps_with_port'], r['ut_port_size'], r['ut_n1_per_k_with_port']],
    })[table_name.removesuffix("_optimized")]
    return format_table_row(cols)

def mod_params_id(p: Tuple) -> Tuple:
    return p

# CompareParams = tuple[int, float, int | tuple[int, int], int]
CompareParams = Tuple[int, float, Union[int, Tuple[int, int]], int]

def table_row_compare_inner_all(params: CompareParams):
    print(params)
    p = params
    bh, dh = (p[2], p[2]) if isinstance(p[2], int) else p[2]  # destructure if not an int
    r = calc_tps_throughput(p[0], p[1], p[1], bh, dh, p[3])
    fp = format_params(params)
    # note: formatted name inserted via table_row_compare_inner
    # params, scaling factor, tps/basechain, tps
    cols = ({
        'UT+PoRs': [fp, r['btc_n_2_factor'], r['ut_2_tps_with_por_per_basechain'], r['ut_2_tps_with_por'], r['ut_confirmation_rate_por'], r['ut_2_t1_with_por'], r['ut_n_1_with_por'], r['delta_s_bps_por'], r['full_node_delta_s_por'], r['tts_1_por']],
        'UT+PoRTs': [fp, r['btc_n_2_factor'], r['ut_2_tps_with_port_per_basechain'], r['ut_2_tps_with_port'], r['ut_confirmation_rate_port'], r['ut_2_t1_with_port'], r['ut_n_1_with_port'], r['delta_s_bps_port'], r['full_node_delta_s_port'], r['tts_1_port']],
        'UT': [fp, r['btc_n_2_factor'], r['ut_2_tps_per_basechain'], r['ut_2_tps'], r['ut_confirmation_rate'], r['ut_2_t1'], r['ut_n_1'], r['delta_s_bps'], r['full_node_delta_s'], r['tts_1']],
        'UT+HO': [fp, r['btc_n_2_factor'], r['ut_2_tps_per_basechain'], r['ut_2_tps'], r['ut_confirmation_rate'], r['ut_2_t1'], r['ut_n_1'], r['delta_s_bps'], r['full_node_delta_s'], r['tts_1']],
        'UT+HOT': [fp, r['btc_n_2_factor'], r['ut_2_tps_per_basechain'], r['ut_2_tps'], r['ut_confirmation_rate'], r['ut_2_t1'], r['ut_n_1'], r['delta_s_bps'], r['full_node_delta_s'], r['tts_1']],
        'UT2+PoRs': [fp, r['ut_n_2_factor_with_por'], r['ut_3_tps_with_por_per_basechain'], r['ut_3_tps_with_por'], r['ut_confirmation_rate'], r['ut_3_t2_with_por'], r['ut_n_1_with_por'], r['delta_s_bps_por'], r['full_node_delta_s_por'], r['tts_1_por']],
        'UT2+PoRTs': [fp, r['ut_n_2_factor_with_port'], r['ut_3_tps_with_port_per_basechain'], r['ut_3_tps_with_port'], r['ut_confirmation_rate'], r['ut_3_t2_with_port'], r['ut_n_1_with_port'], r['delta_s_bps_port'], r['full_node_delta_s_port'], r['tts_1_port']],
        'UT2': [fp, r['ut_n_2_factor'], r['ut_3_tps_per_basechain'], r['ut_3_tps'], r['ut_confirmation_rate'], r['ut_3_t2'], r['ut_n_1'], r['delta_s_bps'], r['full_node_delta_s'], r['tts_1']],
        'UT2+HO': [fp, r['ut_n_2_factor'], r['ut_3_tps_per_basechain'], r['ut_3_tps'], r['ut_confirmation_rate'], r['ut_3_t2'], r['ut_n_1'], r['delta_s_bps'], r['full_node_delta_s'], r['tts_1']],
        'UT2+HOT': [fp, r['ut_n_2_factor'], r['ut_3_tps_per_basechain'], r['ut_3_tps'], r['ut_confirmation_rate'], r['ut_3_t2'], r['ut_n_1'], r['delta_s_bps'], r['full_node_delta_s'], r['tts_1']],
        'bitcoin': [fp, r['btc_n_2_factor'], r['btc_tps_per_basechain'], r['btc_tps'], r['btc_confirmation_rate'], r['btc_t1'], 1, 'delta_s', 'full_node_delta_s', 'time_to_sync_5yr_chain'],
        # Cardano doesn't use sharding
        'cardano': [fp, r['btc_n_2_factor'], r['btc_tps_per_basechain'], r['btc_tps'], r['btc_confirmation_rate'], r['btc_t1'], 1, 'delta_s', 'full_node_delta_s', 'time_to_sync_5yr_chain'],
        # Shareded cardano
        # 'cardano': [fp,  r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps'], r['btc_confirmation_rate'], r['eth2_t2']],
        'polkadot': [fp, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps'], r['btc_confirmation_rate'], r['eth2_t2'], 1, 'delta_s', 'full_node_delta_s', 'time_to_sync_5yr_chain'],
        'eth2': [fp, r['eth2_n_2_factor'], r['eth2_tps'], r['eth2_tps'], r['btc_confirmation_rate'], r['eth2_t2'], 1, 'delta_s', 'full_node_delta_s', 'time_to_sync_5yr_chain'],
    })
    cols['ideal'] = cols['eth2']
    return cols

def table_select_optimize_compare(tn, inputs):
    rows = []
    for ps in inputs:
        # (prop name, prop col, should_round)
        for prop in [
            ('TPS', 3, True),
            ('$N_1$', 6, True),
            ('$\\mathbb{C}^\\prime$ (Hz)', 4, False),
            ('$\\Delta s$ (B/s)', 8, True),
            ('TTS 5yrs (days)', 9, False),
            ('$\\Delta S$ (B/s)', 7, True),
            ]:
            row_deets = table_row_compare_inner_all(ps)
            variants = ['UT+PoRs', 'UT+PoRTs', 'UT']
            col_inputs = [row_deets[v] for v in variants]
            # for variants: 'UT+HO', 'UT+HOT'
            for bh in [32, 16]: # +HO first then +HOT
                dh = ps[2]
                dh2 = hot_calc_dh2(bh, dh)
                gen_ps = (ps[0], ps[1], (bh, dh2), ps[3])
                col_inputs.append(table_row_compare_inner_all(gen_ps)['UT'])
            # get TPS
            print(col_inputs)
            cols = format_table_row([prop[0]] + [fmt_rounded_commas(c[prop[1]], should_round=prop[2], non_sn_range=(0.01, 10**6)) for c in col_inputs])
            rows.append(cols)
    return rows

def table_row_compare_inner(net: str, params: CompareParams):
    all_cols = table_row_compare_inner_all(params)
    fn = UT_NET_NAME_LOOKUP.get(net, net.capitalize())
    cols = all_cols[net.split(' ')[0]][:4]  # remove extra cols from table_row_compare_inner_all
    cols.insert(1, fn)
    return cols

def table_row_compare(net: str, params: CompareParams, ut_tps: int):
    cols = table_row_compare_inner(net, params)
    return format_table_row(cols + [ratio_to_x(cols[-1] / ut_tps)])

def table_row_1m_compare(net: str, params: CompareParams, ut_k):
    p = params
    ut_ps = p if isinstance(p[2], int) else (p[0], p[1], p[2][1], p[3])
    ut_cols = table_row_compare_inner('UT2', ut_ps)
    cols = table_row_compare_inner(net, params) + [ratio_to_x(ut_k / params[0])]
    #
    cols_processed = cols[:2] + cols[3:] + [ut_cols[4]]
    return format_table_row(cols_processed)

def table_row_1m_hz_compare(net: str, params: CompareParams, ut_k):
    p = params
    bh, dh = (p[2], p[2]) if isinstance(p[2], int) else p[2]  # destructure if not an int
    r = calc_tps_throughput(p[0], p[1], p[1], bh, dh, p[3])
    fp = format_params(params)
    fn = net if 'UT' in net else net.capitalize()
    cols = [fp, fn, f"{r['ut_confirmation_rate']:.1f}"]
    return format_table_row(cols)


def table_row_1gbps(net, params, ut_params):
    ut_net, ut_ps = ut_params
    ut_ds, ut_bf, ut_bh, ut_tx = ut_ps
    ds, bf, dh, tx_size = params  # note: I use d_h here b/c we want to format params then set b_h afterwards
    bh = dh
    if 'HOT' in net:
        bh = 16
        dh -= 16
    fp = format_params([fmt_rounded_commas(ds).strip('$'), bf, dh, tx_size], strip_last_n=0)
    k = math.floor(bandwidth_to_k(ds, bf, bh, dh=dh)[net])
    k_ut = bandwidth_to_k(ut_ds, ut_bf, ut_bh)[ut_net]
    r = calc_tps_throughput(k, bf, bf, bh, dh, tx_size)
    r_ut = calc_tps_throughput(k_ut, ut_bf, ut_bf, ut_bh, ut_bh, ut_tx)
    get_net_vals = lambda _r, _net: ({
        'UT': (_r['ut_2_tps'], _r['ut_n_1']),
        'UT+HO': (_r['ut_2_tps'], _r['ut_n_1']),
        'UT+HOT': (_r['ut_2_tps'], _r['ut_n_1']),
        'UT2': (_r['ut_3_tps'], _r['ut_n_2']),
        'UT2+HOT': (_r['ut_3_tps'], _r['ut_n_2']),
        'ideal sharded': (_r['eth2_tps'], _r['eth2_n_2_factor']),
        'eth2': (_r['eth2_tps'], _r['eth2_n_2_factor']),
        'polkadot': (_r['eth2_tps'], _r['eth2_n_2_factor']),
        'cardano': (_r['btc_tps'], 1),
        'solana': (_r['btc_tps'], 1),
        'bitcoin': (_r['btc_tps'], 1),
    })[_net]
    tps_val, n_chains = get_net_vals(r, net)
    tps_val_ut, n_chains_ut = get_net_vals(r_ut, ut_net)
    vs_tps = tps_val / tps_val_ut
    vs_k = k_ut / k
    tps_per_k = tps_val / k
    tps_per_k_ut = tps_val_ut / k_ut
    vs_combined = vs_tps * vs_k
    vs_tps_per_k = tps_per_k / tps_per_k_ut
    gb_p_chain_p_day = k * 86400 / 1024 / 1024
    cols = [fp, net, tps_val, k, gb_p_chain_p_day]  #, ratio_to_x(vs_tps_per_k)] #, ratio_to_x(vs_k), ratio_to_x(vs_tps), ratio_to_x(vs_combined)]
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
    # (1000, 1/10, 100, 500),  # testing for purs
    # ver fast chains
    (1000, 1/15, 84, 250),
    (1000, 1/15, 112, 250),
    (3000, 1/15, 84, 250),
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
    # big headers
    (3000, 1/30, 200, 250),
    (3000, 1/30, 500, 250),
    (3000, 1/30, 1000, 250),
    (3000, 1/30, 1500, 250),
]

def mk_optimized_rows():
    # yield (1000, 1/10, 32, 100, 500)  # testing for purs generator
    for b_f in [1/15, 1/60]:
        ks = [1000, 3000] + ([30000] if True or b_f > 1/20 else [])
        for k in ks:
            for d_h in [84, 112]:
                for b_h in [16]: # [16, 32]:  # exclude +HO for the moment
                    dh2 = hot_calc_dh2(b_h, d_h)
                    yield (k, b_f, b_h, dh2, 250)
    yield (3120, 1/6, 16, hot_calc_dh2(16, 84), 250)
    yield (ETH2_1M_K, 1/15, 16, hot_calc_dh2(16, 84), 250)

optimized_row_inputs = list(mk_optimized_rows())

# Update table compare_optimizations in WP if these parameters change
select_optimized_row_inputs: list[CompareParams] = [(3000, 1/15, 84, 250)]

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
def mk_comparison_inputs(k: int) -> list[tuple[str, CompareParams]]:
    ''' returns a list of network params with a network name. '''
    return [
        ('bitcoin', (k, 1/600, 80, 250)),
        # ('solana', (k, 1/0.55, 141, 250)),
        ('cardano', (k, 1/20, 1070, 250)),
        ('UT', (k, 1/15, 84, 250)),
        ('UT+HO', (k, 1/15, 32, 250)),  # No dappchains so don't need tuple
        ('UT+HOT', (k, 1/15, 16, 250)),  # No dappchains so don't need tuple
        ('polkadot', (k, 1/6, 288, 250)),
        ('eth2', (k, 1/12, ETH2_EFFECTIVE_HEADER, 250)),
        ('ideal sharded', (k, 1/15, 84-16, 250)),
        ('UT2+PoRs', (k, 1/15, 84, 250)),
        ('UT2', (k, 1/15, 84, 250)),
        ('UT2+HOT', (k, 1/15, (16, 84-16), 250)),  # TODO: the tuple gets printed atm, not the best
        ('UT2 inf', (k, 1/15, 84, 250)),
    ]
#     ('bitcoin', (comparison_k2, 1/600, 80, 250)),
#     ('solana', (comparison_k2, 1/0.4, 141, 250)),
#     ('cardano', (comparison_k2, 1/20, 1070, 250)),
#     ('polkadot', (comparison_k2, 1/6, 288, 250)),
#     ('eth2', (comparison_k2, 1/12, ETH2_EFFECTIVE_HEADER, 250)),
#     ('$\\UT{2}$+PoRs', (comparison_k2, 1/15, 112, 250)),
#     ('UT', (comparison_k2, 1/15, 112, 250)),
#     ('UT w/ tiling', (comparison_k2, 1/15, 112, 250)),
#     # ('bitcoin (w/ extras)', (comparison_k, 1/600, 80, 250)),
#     # ('cardano (w/ extras)', (comparison_k, 1/20, 1070 + 1024, 250)),
#     # ('polkadot (w/ extras)', (comparison_k, 1/6, 288 + 1024, 250)),
#     # ('eth2 (w/ extras)', (comparison_k, 1/12, ETH2_EFFECTIVE_HEADER + (476 + 224 + 128 + 672 + 736 + 1024), 250)),
#     # ('$\\UT{2}$+PoRs', (comparison_k, 1/15, 112, 250)),
#     # ('$\\UT{2}$+PoRs (w/ tiling)', (comparison_k, 1/15, 112, 250)),
#     # ('eth2', (206000, 1/12, 200, 250)),  # approx the '14m tps' claim above
#     # ('UT', (8298, 1/15, 112, 250)),
#     # ('solana', (248500, 1/0.4, 141, 250)),  # should match their '700k tps theoretical limit' claim
#     # ('UT', (3393, 1/15, 112, 250)),
# ]

# UT_1M_K = 3826
ALL_UT_1M_K = tps_to_k(1000000, 250, 1/15, 84)
UT_1M_K = int(ALL_UT_1M_K['UT2']) + 1

# math.floor(UT_1M_K * 0.598)

'''For comparison_1m_tps: for non-UT we want to chose the *lowest* value of k where the total TPS rounds to 1.00*10^6; and for UT we want to choose the *largest* k that does similarly. This will minimize the 'out-scaling' ratios.'''
comparison_1m_tps = [
    ('bitcoin', (250000000, 1/600, 80, 250)),
    # ('solana', (296900, 1/0.55, 141, 250)),
    ('cardano', (250000000, 1/20, 1070, 250)),
    # ('cardano', (115700, 1/20, 1070, 250)),
    ('UT', (int(ALL_UT_1M_K['UT']) + 1, 1/15, 84, 250)),
    ('UT+HOT', (int(ALL_UT_1M_K['UT+HOT']) + 1, 1/15, 16, 250)),
    ('polkadot', (109810, 1/6, 288, 250)),
    ('eth2', (ETH2_1M_K, 1/12, ETH2_EFFECTIVE_HEADER, 250)),
    ('ideal sharded', (int(ALL_UT_1M_K['ideal_sharded'] + 1), 1/15, (84-16), 250)),
    ('UT2+PoRs', (int(UT_1M_K * 1.536), 1/15, 84, 250)),
    ('UT2+PoRTs', (int(UT_1M_K * 1.337), 1/15, 84, 250)),
    ('UT2', (UT_1M_K, 1/15, 84, 250)),
    ('UT2+HO', (math.ceil(ALL_UT_1M_K['UT2+HO']), 1/15, (32, 84), 250)),
    ('UT2+HOT', (math.ceil(ALL_UT_1M_K['UT2+HOT']), 1/15, (16, 68), 250)),
]

comparison_1gbps = [
    ('solana', [1024 ** 3 // 8, 1/.5, 200, 250]),  # realistically, min 200 bytes tx size
    ('bitcoin', [1024 ** 3 // 8, 1/600, 80, 250]),
    ('cardano', [1024 ** 3 // 8, 1/20, 1070, 250]),
    ('UT', [1024 ** 3 // 8, 1/15, 84, 250]),
    ('UT+HOT', [1024 ** 3 // 8, 1/15, 84, 250]),
    ('polkadot', [1024 ** 3 // 8, 1/6, 288, 250]),
    ('eth2', [1024 ** 3 // 8, 1/12, ETH2_EFFECTIVE_HEADER, 250]),
    ('ideal sharded', [1024 ** 3 // 8, 1/15, 68, 250]),
    ('UT2', [1024 ** 3 // 8, 1/15, 84, 250]),
    ('UT2+HOT', [1024 ** 3 // 8, 1/15, 84, 250]),  # HOT accounted for later
]

all_tables = {}

def mk_table(table_name, row_func):
    rows = table_header(table_name)
    rows += row_func()
    padded_rows = pad_rows(rows, [])
    rows_str = list(map(row_to_str, padded_rows))
    all_tables[table_name] = '\n'.join(rows_str)

for table_name in ['tps', 'dapp-chains', 'tps_por', 'tps_port']:
    tn_opt = f'{table_name}_optimized'
    mk_table(table_name, lambda: list(table_row(r, table_name, calc_tps_throughput(r[0], r[1], r[1], r[2], r[2], r[3])) for r in row_inputs))
    if 'tps_por' not in table_name:
        mk_table(tn_opt, lambda: list(table_row(r, tn_opt, calc_tps_throughput(r[0], r[1], r[1], r[2], r[3], r[4])) for r in optimized_row_inputs))

for table_name in ['compare_nets_3k', 'compare_nets_30k']:
    k = comparison_ks[table_name]
    net_inputs = mk_comparison_inputs(k)
    ut_row = table_row_compare_inner('UT2', list(filter(lambda i: i[0] == 'UT2', net_inputs))[0][1])
    ut_tps: int = ut_row[-1]
    def mk_row():
        rows = list(table_row_compare(net, r, ut_tps) for (net, r) in net_inputs)
        for r in rows:
            if 'UTinf{2}' in r[1]:
                # r[1] = '$\\UTinf{2}$'
                r[-2] = '$\\infty$'
                r[-1] = '$(\\infty)\\times$'
        return rows
    mk_table(table_name, mk_row)

mk_table('comparison_1m_tps', lambda: list(table_row_1m_compare(net, r, UT_1M_K) for (net, r) in comparison_1m_tps))
mk_table('comparison_1m_tps_conf_hz', lambda: list(table_row_1m_hz_compare(net, r, UT_1M_K) for (net, r) in comparison_1m_tps))

for table_name in ['comparison_1gbps']:
    compare_to = 'UT2'
    def gen_rows():
        rs = []
        ut_params = list(filter(lambda r: r[0] == compare_to, comparison_1gbps))[0]
        get_network_name = lambda n: UT_NET_NAME_LOOKUP.get(n, n.capitalize())
        for (net, ps) in comparison_1gbps:
            r = table_row_1gbps(net, ps, ut_params)
            r[1] = get_network_name(r[1])
            rs += [r]
        return rs
    mk_table(table_name, gen_rows)

mk_table('compare_optimizations', lambda: table_select_optimize_compare('compare_optimizations', select_optimized_row_inputs))

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

* update note: every 10th block (200B) + 8192 / 10

### Cardano:

* header size: 1070 B -- via https://liberlion.medium.com/what-you-should-know-about-cardano-part-1-8c59ebbace49 -- note: secondary source and doesn't provide citation
* 20s block time -- inferred via ~4250 blocks per day -> v close to 20s block time; data from: https://messari.io/asset/cardano/charts/network-activity/blocks

### Solana:

NB: out of date, see bandwidth_to_k_solana

* ~~header size: 64 + 1 + (8+8+8+8) + 32 + 4 + 8 = 141 -> 144 bytes after padding~~
* ~~block time about 550ms atm (31/8/21) via https://explorer.solana.com/ -- this source says 600ms https://forkast.news/what-is-solana-why-hottest-blockchain/~~

~~https://docs.rs/solana/0.16.6/src/solana/packet.rs.html#341 (the linked line is an incremental construction of the header layout)~~

~~also WTF re their hardware requirements!? https://youtu.be/6HHHYtPPUaA?t=421 !!! J.C.
https://web.archive.org/web/20210831185445/https://docs.solana.com/running-validator/validator-reqs~~

~~also good on their validators getting access to zen3 threadrippers only weeks after specifications were *leaked*. :/ (the author meant 3000 series threadrippers which are zen2)~~

~~how solana makes sure the validator base is decentralized enough :/ <https://twitter.com/aeyakovenko/status/1315689754743107584>~~

"""

def main():
    for table_name in all_tables.keys():
        # running it from CLI
        if '--populate-wp-md' not in sys.argv:
            print(f"\n### TABLE: {table_name}\n")
            print(all_tables[table_name])
        else: # it's being run from makefile (or w/e)
            # tables to ignore when run from makefile
            if table_name in ['comparison_1m_tps_conf_hz']:
                continue
            to_replace = f'%% INSERT ### TABLE: {table_name}'
            print(f"Replacing `{to_replace}` with table {table_name} to output/whitepaper.markdown")
            with open('./output/whitepaper.markdown', 'r') as f:
                whitepaper_md = f.read()
            pre_len = len(whitepaper_md)
            whitepaper_md = whitepaper_md.replace(to_replace + "\n", all_tables[table_name] + "\n")
            post_len = len(whitepaper_md)
            if pre_len == post_len:
                print(f"Warning: attempted to insert table {table_name} in whitepaper but it didn't look like that happened. (before: {pre_len} B, after: {post_len} B")
                sys.exit(-1)
            with open('./output/whitepaper.markdown', 'w') as f:
                f.write(whitepaper_md)
            print(f"Table {table_name} written to output/whitepaper.markdown")

if __name__ == "__main__":
    main()
