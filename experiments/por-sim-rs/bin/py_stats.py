#!/usr/bin/env python3

from collections import defaultdict
from dataclasses import dataclass
from functools import lru_cache
import math
import os
from pathlib import Path
import sys
from typing import Any, Literal, Optional
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


@lru_cache
def p_ds_success_theoretical(q, n=20):
    q = Decimal(q)
    p = 1 - q
    if q >= p: return 1
    to_sum = list(n_choose_k(m+n-1, m) * (pow(p,n) * pow(q,m) - pow(p,m) * pow(q,n)) for m in range(n + 1))
    return 1.0 - float(sum(to_sum))


def p_ds_success_theoretical_combin(q, n=20):
    # assume this is broken -- experimental
    q = Decimal(q)
    p = 1 - q
    if q >= p: return 1
    to_sum = list(n_choose_k(m+n-1, m) * (Decimal(m/n) * pow(p,n) * pow(q,m) - Decimal(n/m) * pow(p,m) * pow(q,n)) for m in range(n + 1))
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
        use_experimental_combin=False
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

        if use_experimental_combin:
            r = p_ds_success_theoretical_combin(q, n)
        else:
            r = p_ds_success_theoretical(q, n)
        xs.append(n_por_chains)
        # ys.append(math.log(max(r, 0.0000000001))/n)
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


def read_csv_data(fname, chain_ty: Literal['por', 'trad']):
    # ensure that csv used for generating graphs are in the csv folder
    fname = f"csv" / Path(fname)
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


line_markers = ['s', 'h', '.', '*', '+', 'o', 'x', 'D'] * 10


@dataclass
class Comment:
    body: str
    y: float
    x: Optional[float] = None
    _font: Optional[dict] = None
    _bbox: Optional[dict] = None
    wrap_line_width: int = 500

    def scaled_line_width(self, dpi: int) -> int:
        return self.wrap_line_width * dpi // 100

    @property
    def font(self):
        return self._font or {
            'size': 11,
            'linespacing': 1.4,
        }

    @property
    def bbox(self):
        return self._bbox or {
            'facecolor': 'white',
            'alpha': 0.8,
            'edgecolor': 'gray',
            'boxstyle': 'round',
            'pad': 0.75,
        }


def plot_chart(csv_files=CSV_FILES, plot_kwargs=None, graph_theory_discounted=False,
        title=None, x_label=None, y_label=None, comment: Optional[Comment] = None,
        save_png=False, png_filename=None,
        figsize=(10, 7), dpi=100, x_range=None,
        seed_qs=None, seed_ds_targets=None,
        ):
    plt.figure(figsize=figsize, dpi=dpi)
    _max_ix = x_range[1] if x_range else 20
    qs = set(seed_qs or [])
    ds_targets = set(seed_ds_targets or [])
    kwargs = plot_kwargs or dict()
    print(f"Tabulating CSVs.")
    csv_series = []
    for csv_i, (fname, chain_ty, label_extra) in enumerate(csv_files):
        n_trials, max_ix, block_target, _q, ds_target, csv_data, ms_elapsed, d2 = read_csv_data(fname, chain_ty)
        csv_series.append(csv_data)
        ty_str = 'PoR' if chain_ty == 'por' else 'Trad'
        csv_data.plot(
            label=f"{ty_str}: $q={_q:.2f}$; $B_f^{{-1}} = {block_target}$; $n \\geq {n_trials}$; ds_win={ds_target}; {label_extra or ''}",
            marker=line_markers[csv_i],
            **kwargs)
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
    largest_x = max(multipliers)
    td_max_ys = []
    for q in _qs:
        for ds_target in ds_targets:
            theoretical_data = ds_theoretical_series(multipliers, q=q, after_n_confs=ds_target)
            t_series.append(theoretical_data)
            td_max_ys.append(theoretical_data.max())
            theoretical_data.plot(label=f"Theoretical Trad: $q={q:.2f}$ (confs = ${ds_target}x$)", zorder=-1, linestyle="dashed", linewidth=2.0)
    max_y = max(max(td_max_ys), max(s.max() for s in csv_series) if csv_series else 0)
    print(f"Done. Now drawing.")

    default_title = "\n".join([
        f"P(atk success) PoR vs Traditional Chain",
        "(more confirmations w/ trad chain vs more chains w/ PoR)",
        # f"Trials={n_trials}"
        ])
    plt.title(title or default_title)
    plt.xlabel(x_label or "x = Confirmation Multiplier / # Chains")
    plt.ylabel(y_label or "P(atk success)")
    plt.grid(True)
    plt.grid(True, which='minor', color=(0.9, 0.9, 0.9, 0.1))
    plt.minorticks_on()
    plt.legend()

    if x_range:
        plt.xlim(x_range)

    plt.tight_layout()

    if comment:
        x = comment.x or largest_x
        y = comment.y
        lb = (x/2, 0.0)
        # bounding_rect = plt.Rectangle(lb, x/2, max_y, fill=False)
        txt = plt.text(x, comment.y, comment.body,
            ha='right', va='center', wrap=True,
            fontdict=comment.font, bbox=comment.bbox)
        # https://gist.github.com/dneuman/90af7551c258733954e3b1d1c17698fe
        txt._get_wrap_line_width = lambda: comment.scaled_line_width(dpi)

    if save_png:
        plt.savefig(png_filename)
        print(f"Saved figure out: {png_filename}")
    else:
        plt.show()
    plt.close()

CsvFileToPlot = tuple[str, Literal['por', 'trad'], Optional[str]]

@dataclass
class SavePlot:
    csv_files: list[tuple[str, Literal['por', 'trad'], Optional[str]]]
    title: str
    filename: str
    kwargs: Optional[dict[str, Any]] = None
    x_label: Optional[str] = None
    y_label: Optional[str] = None
    x_range: Optional[tuple[float, float]] = None
    comment: Optional[Comment] = None
    figsize: tuple[float, float] = (10, 10 * 0.6)
    dpi: int = 300
    seed_qs: Optional[set[float]] = None
    seed_ds_targets: Optional[set[float]] = None

    def run(self):
        plot_chart(
            self.csv_files, save_png=True, png_filename=self.filename,
            title=self.title, x_label=self.x_label, y_label=self.y_label,
            comment=self.comment, figsize=self.figsize, dpi=self.dpi,
            x_range=self.x_range,
            seed_qs=self.seed_qs, seed_ds_targets=self.seed_ds_targets,
        )


if __name__ == "__main__":
    if "put the old code in a block to make it collapsable":
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

        csv_files_just_trad = [
            # ('exp_aux1_q=0.40_dsconf-base=20.old.csv', 'trad', '(trad; $N_1=1$)'),
            # ('exp_aux1_q=0.40_dsconf-base=5.csv', 'trad', '(trad; $N_1=1$)'),
            # ('exp_aux1_q=0.40_dsconf-base=10.csv', 'trad', '(trad; $N_1=1$)'),
            # ('exp_aux1_q=0.40_dsconf-base=20.csv', 'trad', '(trad; $N_1=1$)'),
        ]

        csv_exp_10 = [
            ('exp-10-RDoubleSpend-q0.40-t5-p100-H100-DAA1000-WeightedChain-blake3.csv', 'por', 'e10 (DS+WC+DAA1000)'),
            ('exp-9-RDoubleSpendWork-q0.40-t5-p100-H100-WeightedChain-blake3.csv', 'por', 'e9 (DSW+WC)'),
            ('exp-9-RDoubleSpendWork-q0.40-t5-p100-H100-WeightedDag-blake3.csv', 'por', 'e9 (DSW+WD)'),
            ('exp-8-q0.40-t5-p100-H100-blake3.csv', 'por', 'e8 (DS+WC)'),
        ]

        csv_exp_11 = [
                ('exp-11-RDoubleSpend-q0.40-t5-p100-H50-DAA100-delay25-WeightedChain-blake3.csv', 'por', 'e11 (DS+WC + Delay 0.25 blocks)'),
                ('exp-11-RDoubleSpend-q0.40-t5-p100-H50-DAA100-delay50-WeightedChain-blake3.csv', 'por', 'e11 (DS+WC + Delay 0.50 blocks)'),
                ('exp-11-RDoubleSpend-q0.40-t5-p100-H50-DAA100-delay100-WeightedChain-blake3.csv', 'por', 'e11 (DS+WC + Delay 1 blocks)'),
                ('exp-11-RDoubleSpend-q0.40-t5-p100-H50-DAA100-delay200-WeightedChain-blake3.csv', 'por', 'e11 (DS+WC + Delay 2 blocks)'),
                ('exp-8-q0.40-t5-p100-H100-blake3.csv', 'por', 'e8 (DS+WC) Best prior'),
                ('exp-11-RDoubleSpend-q0.40-t5-p100-H50-DAA100-delay0-WeightedChain-blake3.csv', 'por', 'e11 (DS+WC + Draft Refl Considered)'),
            ]

        csv_exp_11_vs_aux = [
                ('exp-11-RDoubleSpend-q0.40-t5-p100-H50-DAA100-delay0-WeightedChain-blake3.csv', 'por', 'e11 (DS+WC + Draft Refl Considered)'),
                ('exp-11-RDoubleSpendWork-q0.40-t5-p100-H50-DAA100-delay0-WeightedDag-blake3.csv', 'por', 'e11 (DSW+WD + Draft Refl Considered)'),
                ('exp_aux1_q=0.40_dsconf-base=5.csv', 'trad', '(trad; $N_1=1$)'),
            ]

        csv_exp_12 = [
            ('exp-12-repeat-8-RDoubleSpendWork-q0.40-t10-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.40-t20-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.40-t5-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.44-t10-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.44-t20-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.44-t5-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.48-t10-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.48-t20-p50-H50-WeightedDag-blake3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpendWork-q0.48-t5-p50-H50-WeightedDag-blake3.csv', 'por', None),
        ]

        csv_exp_12_q40 = list(filter(lambda t: 'q0.40' in t[0], csv_exp_12))
        csv_exp_12_q44 = list(filter(lambda t: 'q0.44' in t[0], csv_exp_12))
        csv_exp_12_q48 = list(filter(lambda t: 'q0.48' in t[0], csv_exp_12))

        csv_exp_12_q40_xx = [
            # ('exp-12-repeat-8-RDoubleSpend-q0.40-t5-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.40-t10-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.40-t20-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.44-t5-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.44-t10-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.44-t20-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.48-t5-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-repeat-8-RDoubleSpend-q0.48-t10-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            ('exp-12-repeat-8-RDoubleSpend-q0.48-t20-p50-H50-WeightedChain-xxh3.csv', 'por', None),
        ]

        csv_exp_12_5050 = [
            # actual 50/50 is just high variance noise -- 0.5 < P() < 1 (whereas theoretical is == 1; but we cut off length of attack)
            # ('exp-12-fiftyfifty-8-RDoubleSpend-q0.5-t5-p50-H50-WeightedChain-xxh3.csv', 'por', None),
            # ('exp-12-point495-RDoubleSpend-q0.495-t5-p50-H200-WeightedChain-xxh3.csv', 'por', None),
            ('exp-12-point490-RDoubleSpend-q0.490-t5-p50-H100-WeightedChain-xxh3.csv', 'por', None),
        ]

        # csv_files = csv_files_just_trad
        csv_files = csv_files_compare_DSW_t5
        csv_files = csv_exp_11_vs_aux
        csv_files = csv_exp_12_q40
        csv_files = csv_exp_12_5050
        csv_files = csv_exp_12_q40_xx

    csv_compare_aux = [
        ('exp_aux1_q=0.40_dsconf-base=5.csv', 'trad', 'DS+WC; DAA_100'),
        ('exp_aux2_q=0.40_dsconf-base=5_DoubleSpendWork_WeightedDag.csv', 'trad', 'DSW+WD; DAA_100'),
        ('exp_aux2_q=0.40_dsconf-base=5_DoubleSpend_LongestChain_DAA100.csv', 'trad', 'DS+LC; DAA_100'),
        ('exp_aux2_q=0.40_dsconf-base=5_DoubleSpend_LongestChain_DAA1000.csv', 'trad', 'DS+LC; DAA_1000'),
    ]

    csv_compare_aux_3 = lambda q, t: [
        (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC; DAA_100'),
        (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedChain_DAA100.csv', 'trad', 'DSW+WC; DAA_100'),
        (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedDag_DAA100.csv', 'trad', 'DS+WD; DAA_100'),
        (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD; DAA_100'),
        # (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_LongestChain_DAA100.csv', 'trad', 'DS+LC; DAA_100'),
    ]

    csv_files = csv_compare_aux
    # plot_chart(csv_files, plot_kwargs=dict(logy=False))

    q_t_to_x_range: dict[tuple[str, str], Optional[tuple[float, float]]] = {
        ('0.40', '5'): (0, 20),
        ('0.40', '10'): (0, 16),
        ('0.40', '20'): (0, 10),
        ('0.44', '5'): (0, 46),
        ('0.44', '10'): (0, 31),
        ('0.44', '20'): (0, 20),
    }

    def gen_por_equiv_csvs(q, t) -> list[CsvFileToPlot]:
        return [
            (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', 'DS+WC'),
            (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'DS+WD'),
            (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', 'DSW+WC'),
            (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'DSW+WD'),
            (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD'),
            (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC'),
        ]

    def exp_13_csv_name(q, t, bt=50, hr=50, strat="DoubleSpend", cs="WeightedChain", daa=100):
        return f'exp_13_RandHR_q={q}_dswin={t}_bt={bt}_hr={hr}_{strat}_{cs}_DAA{daa}.csv'

    def gen_por_equiv_rand_hrs_csvs(q, t) -> list[CsvFileToPlot]:
        return [
            (exp_13_csv_name(q, t, strat="DoubleSpend", cs="WeightedChain"), 'por', 'DS+WC'),
            (exp_13_csv_name(q, t, strat="DoubleSpend", cs="WeightedDag"), 'por', 'DS+WD'),
            (exp_13_csv_name(q, t, strat="DoubleSpendWork", cs="WeightedChain"), 'por', 'DSW+WC'),
            (exp_13_csv_name(q, t, strat="DoubleSpendWork", cs="WeightedDag"), 'por', 'DSW+WD'),
            (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD'),
            (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC'),
        ]


    jobs_to_save: list[SavePlot] = [
        SavePlot(
            csvs,
            "Traditional Doublespend Comparison: $N_1=1$\nTheoretical vs DS+WC vs DSW+WD vs DS+LC (w/ DAA over {100,1000} blocks)",
            fname,
            x_label=f"x = Confirmations / {t}",
            comment=Comment(' '.join([
                "The LC (Longest Chain) configuration is only secure",
                "when the DAA adjustment period is $\\gg$ the number",
                "of confirmations required. This makes sense because,",
                "once the DAA has adjusted to the attacker's hashrate,",
                "the attacker's chain-segment gains blocks at the same",
                "rate as the honest chain."
                ]), c_y, wrap_line_width=400),
            ) for t, csvs, c_y, fname in [
                (5, csv_compare_aux, 0.22, "png/trad_doublespend_comparison.png"),
            ]
    ] + [
        SavePlot(
            csv_compare_aux_3(q, t),
            f"Traditional Doublespend Comparison\n$N_1=1$; $q={q}$; doublespend target: ${t}\cdot x$",
            f"png/trad_ds_comparison_q={q}_t={t}.png",
            x_label=f"x = Confirmations / {t}",
            x_range=q_t_to_x_range.get((q, t), None),
        ) for q in ['0.40', '0.44'] for t in ['5', '10', '20']
                # (5, csv_compare_aux_3(5), 0.30, "png/trad_ds_comparison_q=0.44_t=5.png"),
                # (10, csv_compare_aux_3(10), 0.30, "png/trad_ds_comparison_q=0.44_t=10.png"),
    ] + [
        SavePlot(
            # [
            #     (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', 'DS+WC'),
            #     (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'DS+WD'),
            #     (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', 'DSW+WC'),
            #     (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'DSW+WD'),
            #     (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD'),
            #     (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC'),
            # ],
            gen_por_equiv_csvs(q, t),
            f"PoR Confirmation Equivalence Conjecture | $q={q}$",
            f"png/por_equiv_q={q}_t{t}.png",
            x_label=f"PoR: $x = N_1$; Trad: $x = Confirmations / {t}$",
            x_range=q_t_to_x_range.get((q, t), None)
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        SavePlot(
            gen_por_equiv_rand_hrs_csvs(q, t),
            f" PoR Confirmation Equivalence Conjecture \n $q={q}$ | hash-rate randomly distributed ($q+p=1$ true network-wide)",
            f"png/por_equiv_rand_hr_q={q}_t{t}.png",
            x_label=f"PoR: $x = N_1$; Trad: $x = Confirmations / {t}$",
            x_range=q_t_to_x_range.get((q, t), None)
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        SavePlot(
            [
                (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', None),
                (f'exp_aux2_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', None),
            ],
            f"PoR Equivalency Hypothesis | PoR vs Traditional vs Theoretical \n DS+WC | $q={q}$ | DoubleSpend Target: ${t} \\cdot x$ ",
            f"png/por_eqiv_hyp_vs_trad_q={q}_t={t}_DS+WC.png",
            x_label=f"PoR: $x = N_1$; Trad: $x = Confirmations / {t}$",
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44'] for t in ['5', '10', '20']
    ] + [
        SavePlot([], f"Theoretical doublespend success rates given\n $q={q}$ after ${t} \\cdot x$ confirmations. ",
            f"png/theoretical_q={q}_t={t}.svg",
            x_label=f"$x = Confirmations / {t}$",
            x_range=q_t_to_x_range[(q, t)],
            seed_qs={float(q)}, seed_ds_targets={float(t)},
            )
        for q in ['0.40', '0.44'] for t in ['5', '10', '20']
    ]

    for j in jobs_to_save:
        j.run()
