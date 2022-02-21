#!/usr/bin/env python3

from collections import defaultdict
import math
import sys
from typing import Literal
import numpy
import pandas as pd
import matplotlib.pyplot as plt
from decimal import Decimal


MAX_N_CHAINS = 41

CSV_FILES = ['exp-3.csv', 'exp-4.csv', 'exp-4a.csv'] \
    + list(f"exp-5-q{q}-target{t}.csv" for q in ['0.25', '0.4'] for t in ['25', '50', '100'])


# n! / (k! * (n - k)!)
def n_choose_k(n, k) -> Decimal:
    return Decimal(math.factorial(n) // (math.factorial(k) * math.factorial(n - k)))


def pow(b: Decimal, i) -> Decimal:
    # return numpy.prod([b] * i)
    return b ** Decimal(i)


def p_ds_success_theoretical(q, n=20):
    q = Decimal(q)
    p = 1 - q
    if q >= p: return 1
    to_sum = list(n_choose_k(m+n-1, m) * (pow(p,n) * pow(q,m) - pow(p,m) * pow(q,n)) for m in range(n + 1))
    return 1.0 - float(sum(to_sum))


def tri_numbers_decreasing(i_start, iter_limit):
    '''
    first col of height i_start, at most iter_limit cols
    i_start=4, iter_limit=3
    x
    xx
    xxx
    xxx
    = 9
    '''
    if i_start <= 0 or iter_limit <= 0:
        return 0
    return i_start + tri_numbers_decreasing(i_start-1, iter_limit-1)


assert tri_numbers_decreasing(4, 3) == 9


def exp_tri_numbers_decreasing(i_start, iter_limit, n_cols=1):
    '''
    x
    xxx
    xxxxxxx
    xxxxxxxxxxxxxxx
    '''
    if i_start <= 0 or iter_limit <= 0:
        return 0
    return i_start * min(n_cols, iter_limit) \
        + exp_tri_numbers_decreasing(i_start-1, iter_limit-n_cols, n_cols=n_cols*2)

assert exp_tri_numbers_decreasing(4, 3) == 10
assert exp_tri_numbers_decreasing(4, 99) == 26

def exp_numbers_decreasing(i_start, iter_limit, n_cols=1):
    '''
    x
    x
    xxx
    xxxxxxx
    '''
    if i_start <= 0 or iter_limit <= 0:
        return 0
    return i_start * min(n_cols, iter_limit) \
        + exp_numbers_decreasing(math.ceil(i_start / 2), iter_limit-n_cols, n_cols=n_cols*2)

assert exp_numbers_decreasing(4, 3) == 8
assert exp_numbers_decreasing(4, 7) == 12

def ds_theoretical_series(multipliers, q=0.44, after_n_confs=20,
        discount_after_first_mult=False, triangular_mult_discount=False,
        exp_tri_mult_discount=False, exp_mult_discount=False,
        ):
    xs = []
    ys = []
    for n_por_chains in multipliers:
        if discount_after_first_mult:
            n = int(after_n_confs + ((after_n_confs - 1) * (n_por_chains - 1)))
        elif triangular_mult_discount:
            n = int(tri_numbers_decreasing(after_n_confs, n_por_chains))
        elif exp_tri_mult_discount:
            n = int(exp_tri_numbers_decreasing(after_n_confs, n_por_chains))
        elif exp_mult_discount:
            n = int(exp_numbers_decreasing(after_n_confs, n_por_chains))
        else:
            n = int(after_n_confs * n_por_chains)
        r = p_ds_success_theoretical(q, n)
        xs.append(n_por_chains)
        ys.append(r)
    data = pd.Series(ys, index=xs)
    return data


def lerp(a, b, t):
    assert b >= a
    return (1-t) * a + b * t

def inv_lerp(a, b, v):
    assert b >= a
    return (v-a)/(b-a)


# assumes monotonically decreasing function
def estimate_inverse(data: pd.Series, y_val):
    x1 = data.idxmax()  # idx of max value
    xn = data.idxmin()  # idx of min value
    if y_val > data[x1]:
        # can't estimate left of start
        return x1
    if y_val < data[xn]:
        return xn
    # otherwise, it's between these two
    for ((xa, ya), (xb, yb)) in zip(data.iteritems(), data[1:].iteritems()):
        # print(xa, xb, xa<xb, ya, yb, ya>yb)
        if ya >= y_val >= yb:
            # then we linearly interpolate x coord
            t = inv_lerp(yb, ya, y_val)
            return lerp(xa, xb, t)
    raise Exception("we should never reach this point")


def read_csv_data(fname, chain_ty: Literal['por'] | Literal['trad']):
    d: pd.DataFrame = pd.read_csv(fname)
    only_target = d['block_target'][1]
    ds_target = int(d['doublespend_after_n_confs'][1])
    q = d['atk_q'][1]
    if chain_ty == 'por':
        xs = d['n_chains'].unique()
    elif chain_ty == 'trad':
        xs = list(x // ds_target for x in d['doublespend_after_n_confs'].unique())
    def get_x_from_row(row):
        if chain_ty == 'por':
            return row.n_chains
        elif chain_ty == 'trad':
            return row.doublespend_after_n_confs // ds_target
    # xs = list(range(1, MAX_N_CHAINS))
    win_counter = defaultdict(lambda: 0)
    row_counter = defaultdict(lambda: 0)
    d_to_count = d[d['block_target'] == only_target]
    for row in d_to_count.itertuples():
        x = get_x_from_row(row)
        row_counter[x] += 1
        if row.win > 0:
            win_counter[x] += 1
    ys = list(win_counter[x] / row_counter[x] for x in xs if row_counter[x] > 0)
    max_ix = max(xs)
    series = pd.Series(ys, index=[x for x in xs if x <= max_ix])
    series2 = pd.Series([y**0.7 for y in ys], index=[x for x in xs[:max_ix]])
    # s3 = pd.Series(ys, index=[math.sqrt(x) for x in xs[:max_ix]])
    # s4 = pd.Series(ys, index=[x**(2/3) for x in xs[:max_ix]])
    ms_elapsed = d.reset_index().groupby('n_chains')['ms_elapsed'].mean()
    nts = list(n for x,n in row_counter.items())
    n_trials = int(numpy.array(nts).min())
    return n_trials, max_ix, only_target, q, ds_target, series, ms_elapsed, series2


def plot_chart(csv_files=CSV_FILES, plot_kwargs=None, graph_theory_discounted=False):
    plt.figure()
    _max_ix = 0
    qs = set()
    ds_targets = set()
    kwargs = plot_kwargs or dict()
    print(f"Tabulating CSVs.")
    csv_series = []
    for (fname, chain_ty, label_extra) in csv_files:
        n_trials, max_ix, block_target, _q, ds_target, csv_data, ms_elapsed, d2 = read_csv_data(fname, chain_ty)
        csv_series.append(csv_data)
        csv_data.plot(label=f"PoR $q={_q:.2f}$; $B_f^{{-1}} = {block_target}$; $n \\geq {n_trials}$; ds_win={ds_target} {label_extra or ''}", **kwargs)
        # ms_elapsed.plot(label=f"$\\bar{{d}}$ (ms); $B_f^{{-1}} = {block_target}$", secondary_y=True)
        # d2.plot(label="PoR - $y^{0.7}$")
        _max_ix = max(_max_ix, max_ix)
        qs.add(_q)
        ds_targets.add(ds_target)
    _qs = list(qs)
    _qs.sort()
    print(f"Calculating theoretical probabilities.")
    t_series = []
    multipliers = list(range(1, min(_max_ix+1,20))) + list(range(20, _max_ix+1, 1))
    for q in _qs:
        for ds_target in ds_targets:
            theoretical_data = ds_theoretical_series(multipliers, q=q, after_n_confs=ds_target)
            t_series.append(theoretical_data)
            theoretical_data.plot(label=f"Theoretical $q={q:.2f}$ (confs = ${ds_target}x$)")
        # if graph_theory_discounted:
        #     for ds_target in ds_targets:
        #         theoretical_data = ds_theoretical_series(multipliers, q=q, after_n_confs=ds_target, something_here)
        #         t_series.append(theoretical_data)
        #         theoretical_data.plot(label=f"Theoretical $q={q:.2f}$ (confs = ExpDec(${ds_target}$))")
    # d3.plot(label="PoR - $\sqrt{x}$")
    # d4.plot(label="PoR - $x^{2/3}$")
    if False and len(csv_series) == len(t_series) == 1:
        print(f"Calculating experimental / theoretical")
        exp_d = csv_series[0]
        thr_d = t_series[0]
        max_t_prob = thr_d[1]
        xs = []
        ys = []
        ys_alt = []
        for (x,y) in exp_d.iteritems():
            equiv_x = estimate_inverse(thr_d, y)
            xs.append(x)
            ys.append(x / equiv_x)
            ys_alt.append(equiv_x)
            print(x, '->', equiv_x)
        # ratio_series = pd.Series(ys, index=xs)
        # ratio_series.plot(label=f"Ratio of x coords w/ equiv y values")
        alt_series = pd.Series(ys_alt, index=xs)
        alt_series.plot(label=f"Theoretical x coord w/ equiv y values")
    print(f"Done. Now drawing.")
    plt.title("\n".join([
        f"P(atk success) PoR vs Traditional Chain",
        "(more confirmations w/ trad chain vs more chains w/ PoR)",
        # f"Trials={n_trials}"
        ]))
    plt.xlabel("x = Confirmation Multiplier / # Chains")
    plt.ylabel(f"P(atk success)")
    plt.legend()
    plt.show()


if __name__ == "__main__":
    csv_files = \
        [
            # ('exp-6-p5.csv', 'por', ''),
            # ('exp-6-p10.csv', 'por', ''),
            # ('exp-6-p20.csv', 'por', ''),
            # ('exp-6-p100.csv', 'por', ''),
            ('exp-6-p5-q0.42.csv', 'por', ''),
            ('exp-6-p10-q0.42.csv', 'por', ''),
            ('exp-6-p20-q0.42.csv', 'por', ''),
            ('exp-6-p100-q0.42.csv', 'por', ''),
        ]
        # [ ('exp-4c-rng1.csv', 'por', '(rng,xx)')
        # , ('exp-4c-rng-hash.csv', 'por', '(rng+hash,xx)')
        # , ('exp-4c-hash-hash.csv', 'por', '(rng+hash,hash)')
        # , ('exp-4c-hash-xxrev.csv', 'por', '(rng+hash,xxrev)')
        # # , ('exp-aux1.csv', 'trad', '(1 chain)')  # this one compares a simulated traditional doublespend at various numbers of confirmations with n_chains=1
        # , ('exp-aux1-q0.40.csv', 'trad', '(1 chain)')  # this one compares a simulated traditional doublespend at various numbers of confirmations with n_chains=1
        # ]

    # csv_files = list((f"exp-6m-q{q}.csv", 'por', None) for q in ['0.36', '0.4', '0.42', '0.44', '0.46', '0.48'])
    # csv_files = list((f"exp-6n-q{q}.csv", 'por', None) for q in ['0.40'])
    # csv_files = list((f"exp-6o-q{q}-t{t}.csv", 'por', None) for q in ['0.40'] for t in ['10', '20', '30'])

    csv_files = [
        ('exp-aux1-q0.44-sha256.csv', 'trad', '(trad; N_1=1)'),
        ('exp-7-q0.44-t20-sha256.csv', 'por', None),
        ]
    csv_files = [
        # ('exp-aux1-q0.44-sha256.csv', 'trad', '(trad; N_1=1)'),
        # ('exp-8-q0.40-t10-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t10-p40-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t10-p100-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t10-p200-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t5-p200-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t10-p200-H25-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t5-p200-H25-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t10-p200-H25-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t5-p200-H25-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t5-p200-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t5-p100-H100-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t5-p100-H100-blake3.csv', 'por', None),
        # ('exp-8-q0.40-t10-p100-H100-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t10-p100-H100-blake3.csv', 'por', None),
        ('exp-8-q0.40-t20-p100-H100-blake3.csv', 'por', None),
        # ('exp-8-q0.44-t20-p100-H100-blake3.csv', 'por', None),
        # ('exp-9-RDoubleSpendWork-q0.40-t5-p100-H100-WeightedChain-blake3.csv', 'por', None),
        # ('exp-9-RDoubleSpendWork-q0.40-t10-p100-H100-WeightedChain-blake3.csv', 'por', None),
        ('exp-9-RDoubleSpendWork-q0.40-t20-p100-H100-WeightedChain-blake3.csv', 'por', None),
        ]

    csv_files_compare_DSW_t20 = [
        ('exp-9-RDoubleSpendWork-q0.40-t20-p100-H100-WeightedChain-blake3.csv', 'por', '(DSW+WC)'),
        ('exp-9-RDoubleSpendWork-q0.40-t20-p100-H100-WeightedDag-blake3.csv', 'por', '(DSW+WD)'),
        ('exp-8-q0.40-t20-p100-H100-blake3.csv', 'por', '(DS+WC)'),
    ]
    csv_files_compare_DSW_t10 = [
        ('exp-9-RDoubleSpendWork-q0.40-t10-p100-H100-WeightedChain-blake3.csv', 'por', '(DSW+WC)'),
        ('exp-9-RDoubleSpendWork-q0.40-t10-p100-H100-WeightedDag-blake3.csv', 'por', '(DSW+WD)'),
        ('exp-8-q0.40-t10-p100-H100-blake3.csv', 'por', '(DS+WC)'),
    ]
    csv_files_compare_DSW_t5 = [
        ('exp-9-RDoubleSpendWork-q0.40-t5-p100-H100-WeightedChain-blake3.csv', 'por', '(DSW+WC)'),
        ('exp-9-RDoubleSpendWork-q0.40-t5-p100-H100-WeightedDag-blake3.csv', 'por', '(DSW+WD)'),
        ('exp-8-q0.40-t5-p100-H100-blake3.csv', 'por', '(DS+WC)'),
    ]

    csv_files = csv_files_compare_DSW_t20


    plot_chart(csv_files, plot_kwargs=dict(logy=False), graph_theory_discounted=False)
    # plot_chart(csv_files=['exp-4a-wPoRFix.csv', 'exp-4a-wPoRFix-2.csv', 'exp-4a-wPoRFix-3.csv'], plot_kwargs=dict(logy=False))
    # plot_chart(csv_files=['exp-4b.csv'], plot_kwargs=dict(logy=False))
