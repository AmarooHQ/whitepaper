#!/usr/bin/env python3

from collections import defaultdict
import math
import sys
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


def ds_theoretical_series(multipliers, q=0.44, after_n_confs=20):
    xs = []
    ys = []
    for n_por_chains in multipliers:
        print(n_por_chains)
        n = after_n_confs * n_por_chains
        r = p_ds_success_theoretical(q, n)
        xs.append(n_por_chains)
        ys.append(r)
    data = pd.Series(ys, index=xs)
    return data


def read_csv_data(fname='./exp-3.csv'):
    d: pd.DataFrame = pd.read_csv(fname)
    only_target = d['block_target'][1]
    q = d['atk_q'][1]
    xs = d['n_chains'].unique()
    # xs = list(range(1, MAX_N_CHAINS))
    win_counter = defaultdict(lambda: 0)
    row_counter = defaultdict(lambda: 0)
    d_to_count = d[d['block_target'] == only_target]
    for row in d_to_count.itertuples():
        x = row.n_chains
        row_counter[x] += 1
        if row.win > 0:
            win_counter[x] += 1
    ys = list(win_counter[x] / row_counter[x] for x in xs if row_counter[x] > 0)
    max_ix = max(xs)
    series = pd.Series(ys, index=[x for x in xs if x <= max_ix])
    # series2 = pd.Series(ys, index=[x / 2 for x in xs[:max_ix]])
    # s3 = pd.Series(ys, index=[math.sqrt(x) for x in xs[:max_ix]])
    # s4 = pd.Series(ys, index=[x**(2/3) for x in xs[:max_ix]])
    ms_elapsed = d.reset_index().groupby('n_chains')['ms_elapsed'].mean()
    nts = list(n for x,n in row_counter.items())
    n_trials = int(numpy.array(nts).min())
    return n_trials, max_ix, only_target, q, series, ms_elapsed


def plot_chart(csv_files=CSV_FILES, plot_kwargs=None):
    plt.figure()
    _max_ix = 0
    qs = set()
    kwargs = plot_kwargs or dict()
    for fname in csv_files:
        n_trials, max_ix, block_target, _q, csv_data, ms_elapsed = read_csv_data(fname=fname)
        csv_data.plot(label=f"PoR $q={_q:.2f}$; $B_f^{{-1}} = {block_target}$; $n \\geq {n_trials}$", **kwargs)
        # ms_elapsed.plot(label=f"$\\bar{{d}}$ (ms); $B_f^{{-1}} = {block_target}$", secondary_y=True)
        _max_ix = max(_max_ix, max_ix)
        qs.add(_q)
    _qs = list(qs)
    _qs.sort()
    for q in _qs:
        multipliers = list(range(1, min(_max_ix+1,20))) + list(range(20, _max_ix+1, 10))
        theoretical_data = ds_theoretical_series(multipliers, q=q)#, max_multiplier=_max_ix)
        theoretical_data.plot(label=f"Theoretical $q={q:.2f}$ (confs = $20x$)")
    # d2.plot(label="PoR - $x/2$")
    # d3.plot(label="PoR - $\sqrt{x}$")
    # d4.plot(label="PoR - $x^{2/3}$")
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
    plot_chart(csv_files=['exp-4a-wPoRFix.csv'], plot_kwargs=dict(logy=False))
