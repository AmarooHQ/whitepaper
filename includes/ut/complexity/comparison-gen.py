
from decimal import Decimal

def calc_tps_throughput(k, bf, df, bh, dh, tx_size):
    ut_tps = k**3 / (4 * bf * bh * df * dh) / tx_size
    ut_4_tps = k**4 / (4 * bf * bh * df**2 * dh**2) / tx_size
    return {
        'btc_tps': k / tx_size,
        # c^2 estimate, remove constants to be optimistic
        'eth2_tps': k**2 / (df * dh) / tx_size,
        # c^3 estimate
        'ut_tps': ut_tps,
        'ut_4_tps': ut_4_tps,
        'ut_m_tps': '{:.2f} million'.format(ut_tps / 1000000),
        'ut_chain_gb_per_year': k * 60 * 60 * 24 * 365.25 / (1024 ** 3),
        'ut_3_max_dappchains': k**2 / (4 * bh * bf * dh * df),
        'ut_3_optimal_rchains': k / (2 * bh * bf),
        'ut_3_optimal_dappchains': k / (2 * dh * df),
        'ut_4_max_dappchains': k**3 / (4 * bh * bf * dh**2 * df**2),
    }

def fmt_rounded_commas(value):
    return f"{round(value):,}" if value < 10**6 else f"\x24{value:.1e}}}\x24" \
        .replace("e+0", "e+").replace("e+", "\\times 10^{")

def table_row(params, incl_dappchains=False):
    r = calc_tps_throughput(*params)
    cols = [r['btc_tps'], r['eth2_tps'], r['ut_tps']] \
        + ([r['ut_3_max_dappchains']] if incl_dappchains else []) \
        + [r['ut_4_tps']] \
        + ([r['ut_4_max_dappchains']] if incl_dappchains else [])
    return ' | '.join(str(i) for i in
            (['', '$' + ', '.join(map(str, list(params)[:-1])) + '$'] \
                + list(map(fmt_rounded_commas, cols)) + [''])
        ).strip() \
            .replace('0.0016666666666666668', '\\nicefrac{1}{600}') \
            .replace('0.016666666666666666', '\\nicefrac{1}{60}') \
            .replace('0.06666666666666667', '\\nicefrac{1}{15}') \
            .replace('0.05', '\\nicefrac{1}{20}').replace('0.025', '\\nicefrac{1}{40}')

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
]

for r in row_inputs:
    print(table_row(r))

# list((r, calc_tps_throughput(*r)) for r in row_inputs)
