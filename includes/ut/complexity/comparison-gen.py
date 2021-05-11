from decimal import Decimal

def calc_tps_throughput(k, bf, df, bh, dh, tx_size):
    ut_2_tps = k**2 / (4 * bf * bh) / tx_size
    ut_3_tps = k**3 / (4 * bf * bh * df * dh) / tx_size
    ut_4_tps = k**4 / (4 * bf * bh * df**2 * dh**2) / tx_size
    return {
        'btc_tps': k / tx_size,
        # c^2 estimate, remove constants to be optimistic
        'eth2_tps': k**2 / (df * dh) / tx_size,
        'ut_2_tps': ut_2_tps,
        # c^3 estimate
        'ut_3_tps': ut_3_tps,
        'ut_4_tps': ut_4_tps,
        'ut_m_tps': '{:.2f} million'.format(ut_3_tps / 1000000),
        'ut_chain_gb_per_year': k * 60 * 60 * 24 * 365.25 / (1024 ** 3),
        'ut_n_2': k**2 / (4 * bh * bf * dh * df),
        'ut_n_1': k / (2 * bh * bf),
        'ut_3_optimal_dappchains': k / (2 * dh * df),
        'ut_n_3': k**3 / (4 * bh * bf * dh**2 * df**2),
        'delta_s_Bps': k**2 / (2 * bh * bf),
    }

def fmt_rounded_commas(value):
    return f"{round(value):,}" if value < 10**6 else f"\x24{value:.1e}}}\x24" \
        .replace("e+0", "e+").replace("e+", "\\times 10^{")

def table_header(incl_dappchains=False):
    headings = ['$O(c)$', '$O(c^2)$', '$O(c^2)$ UT', '$O(c^3)$ UT', '$O(c^4)$ UT'] \
        if not incl_dappchains else ['$N_1$ (UT)', '$N_2$ (UT)', '$N_3$ (UT)', '$\Delta S$']
    return '\n'.join([
        '| ' + ' | '.join(['$k$, $B_f$, $D_f$, $B_h$, $D_h$'] + headings) + ' |',
        '|'.join(['', '--------'] \
        + (['---','----','----','----','----'] if not incl_dappchains else ['---', '----', '----', '----']) + [''])
    ])

def table_row(params, incl_dappchains=False):
    r = calc_tps_throughput(*params)
    cols = [r['btc_tps'], r['eth2_tps'], r['ut_2_tps'], r['ut_3_tps'], r['ut_4_tps']] if not incl_dappchains else [r['ut_n_1'], r['ut_n_2'], r['ut_n_3'], r['delta_s_Bps']]
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

do_dappchains = False

print(table_header(incl_dappchains=do_dappchains))
for r in row_inputs:
    print(table_row(r, incl_dappchains=do_dappchains))

# list((r, calc_tps_throughput(*r)) for r in row_inputs)
