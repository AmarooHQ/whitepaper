#!/usr/bin/env python3

from collections import defaultdict
import math
import pandas as pd
import matplotlib.pyplot as plt
from decimal import Decimal


MAX_N_CHAINS = 41


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


def ds_theoretical_series(q=0.44, after_n_confs=20):
    xs = []
    ys = []
    for n_por_chains in range(1, MAX_N_CHAINS):
        n = after_n_confs * n_por_chains
        r = p_ds_success_theoretical(q, n)
        xs.append(n_por_chains)
        ys.append(r)
    data = pd.Series(ys, index=xs)
    return data


def read_csv_data():
    d: pd.DataFrame = pd.read_csv('./exp-3.csv')
    xs = list(range(1, MAX_N_CHAINS))
    win_counter = defaultdict(lambda: 0)
    row_counter = defaultdict(lambda: 0)
    for row in d.itertuples():
        x = row.n_chains
        row_counter[x] += 1
        if row.win > 0:
            win_counter[x] += 1
    ys = list(win_counter[x] / row_counter[x] for x in xs if row_counter[x] > 0)
    series = pd.Series(ys, index=xs[:len(ys)])
    series2 = pd.Series(ys, index=[x / 2 for x in xs[:len(ys)]])
    s3 = pd.Series(ys, index=[math.sqrt(x) for x in xs[:len(ys)]])
    s4 = pd.Series(ys, index=[x**(2/3) for x in xs[:len(ys)]])
    # err_bars = list(())
    n_trials = row_counter[1]
    return n_trials, series, series2, s3, s4


def plot_chart(theoretical_data, q=0.44):
    n_trials, csv_data, d2, d3, d4 = read_csv_data()
    plt.figure()
    theoretical_data.plot(label=f"Theoretical")
    csv_data.plot(label=f"PoR")
    d2.plot(label="PoR - $x/2$")
    d3.plot(label="PoR - $\sqrt{x}$")
    d4.plot(label="PoR - $x^{2/3}$")
    plt.title(f"P(atk success) PoR vs Traditional Chain\n(more confirmations w/ trad chain vs more chains w/ PoR)\nTrials={n_trials}")
    plt.xlabel("Confirmation Multiplier / # Chains")
    plt.ylabel(f"P(atk success; q={q})")
    plt.legend()
    plt.show()


if __name__ == "__main__":
    t_data = ds_theoretical_series()
    plot_chart(t_data)
