#!/usr/bin/env python3

from collections import defaultdict
from dataclasses import dataclass
from functools import lru_cache
import math
import os
from pathlib import Path
import sys
from typing import Any, Callable, Literal, Optional
import numpy
import pandas as pd
import matplotlib.pyplot as plt
from decimal import Decimal
import click
import multiprocessing.pool as mpp
import multiprocessing as mp


@dataclass
class PorPlotOpts:
    _trans_x: Optional[Callable[[float], float]] = None
    _label_extra: Optional[str] = None
    cec_scaled: Optional[float] = None
    _kwargs: Optional[dict] = None

    def trans_x(self, x):
        if self._trans_x:
            return self._trans_x(x)

    @property
    def label_extra(self):
        r = self._label_extra or ''
        # if self.cec_scaled:
            # r += f" | Scaled: $x \\to {self.cec_scaled} x$"
        return r

    def should_scale(self):
        return self.cec_scaled is not None

    @property
    def kwargs(self):
        return self._kwargs or dict()


CsvFileToPlot = tuple[str, Literal['por', 'trad'], Optional[str | PorPlotOpts]]


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
    # print(f"Reading: {fname}")
    d: pd.DataFrame = pd.read_csv(fname)
    only_target = d['block_target'][1]
    ds_target = int(d['doublespend_after_n_confs'][1])
    q = d['atk_q'][1]
    if chain_ty == 'por':
        xs = d['n_chains'].unique()
    elif chain_ty == 'trad':
        xs = list(x // ds_target for x in d['doublespend_after_n_confs'].unique())
    xs.sort()

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


por_line_markers = ['x','*','3','+','4'] * 10
trad_line_markers = ['s','o','P','D','X'] * 10

line_markers = {
    'por': por_line_markers,
    'trad': trad_line_markers,
}

def get_line_marker(chain_ty: Literal['por', 'trad'], por_i, trad_i):
    return line_markers[chain_ty][por_i if chain_ty == 'por' else trad_i]

@dataclass
class Comment:
    body: str
    y: float
    x: Optional[float] = None
    _font: Optional[dict] = None
    _bbox: Optional[dict] = None
    wrap_line_width: int = 500
    font_size: int = 10

    def scaled_line_width(self, dpi: int) -> int:
        return self.wrap_line_width * dpi // 100

    @property
    def font(self):
        return self._font or {
            'size': self.font_size,
            'linespacing': 1.3,
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


def gen_cec_prob_str(ds_target, is_trad=False, scaled=None):
    extra_pad = '  ' if int(ds_target) < 10 else ''
    # spacing at end is to help them line up in plot legend
    cec_prob = f"$P(q; N_1 = x; c = {ds_target})$   "
    cec_trad_prob = f"$P(q; N_1 = 1; c = {ds_target}x)$ "
    cec_scaled_prob = f"$P(q; N_1 = x / {scaled}; c = {ds_target})$"
    return (cec_trad_prob if is_trad else (cec_scaled_prob if scaled else cec_prob)) + extra_pad


def plot_chart(csv_files: list[CsvFileToPlot], plot_kwargs=None, graph_theory_discounted=False,
        title=None, x_label=None, y_label=None, comment: Optional[Comment] = None,
        save_png=False, png_filename=None,
        figsize=(10, 7), dpi=100, x_range=None,
        seed_qs=None, seed_ds_targets=None,
        ):
    print(f"\nPlotting chart: {png_filename or '<tmp-not-saved>'}")
    plt.figure(figsize=figsize, dpi=dpi)
    _x_range_max = x_range[1] if x_range else 21
    _max_ix = 0
    qs = set(seed_qs or [])
    ds_targets = set(seed_ds_targets or [])
    kwargs = plot_kwargs or dict()
    print(f"Tabulating CSVs.")
    csv_series = []
    por_count = -1
    trad_count = -1
    for csv_i, (fname, chain_ty, label_extra) in enumerate(csv_files):
        z_order = 2 + (.1 if chain_ty == 'por' else -.1)
        _kwargs = dict(**kwargs)
        _kwargs.update(marker=get_line_marker(chain_ty, por_count, trad_count), zorder=z_order)
        is_por = chain_ty == 'por'
        is_trad = not is_por
        label_extra = label_extra or ''
        por_plot_opts = None
        if not isinstance(label_extra, str):
            por_plot_opts = label_extra
            label_extra = por_plot_opts.label_extra

        n_trials, max_ix, block_target, _q, ds_target, csv_data, ms_elapsed, d2 = read_csv_data(fname, chain_ty)
        csv_series.append(csv_data)
        if chain_ty == 'por':
            ty_str = 'PoR: '
            por_count += 1
        else:
            ty_str = 'Trad:'
            trad_count += 1

        log_ds_target = ds_target
        if por_plot_opts and por_plot_opts.cec_scaled:
            csv_data = pd.Series(csv_data.values, index=[x * por_plot_opts.cec_scaled for x in csv_data.index])
            log_ds_target = int(ds_target / por_plot_opts.cec_scaled)

        if por_plot_opts:
            _kwargs.update(**por_plot_opts.kwargs)

        prob_math = gen_cec_prob_str(ds_target, is_trad=is_trad, scaled=por_plot_opts and por_plot_opts.cec_scaled)
        if 'label' not in _kwargs:
            _kwargs['label'] = f"y = {prob_math} --- {ty_str} $q={_q:.2f}$; $B_f^{{-1}} = {block_target}$; $n \\geq {n_trials}$; ds_win={ds_target}; {label_extra or ''}"

        csv_data.plot(**_kwargs)
        # ms_elapsed.plot(label=f"$\\bar{{d}}$ (ms); $B_f^{{-1}} = {block_target}$", secondary_y=True)
        # d2.plot(label="PoR - $y^{0.7}$")
        _max_ix = max(_max_ix, max_ix)
        qs.add(_q)
        ds_targets.add(log_ds_target)
    _qs = list(qs)
    _qs.sort()

    # in case we are graphing only theoretical curves
    if _max_ix == 0:
        _max_ix = _x_range_max

    # if we don't have data then don't needlessly increase x_range
    _max_ix = min(_max_ix + 1, _x_range_max)
    x_range = (0 if x_range is None else x_range[0], _max_ix)

    print(f"Calculating theoretical probabilities.")
    t_series = []
    # multipliers = list(range(1, min(_max_ix+1,20))) + list(range(20, _max_ix+1, 1))
    multipliers = list(range(1, _max_ix+1))
    largest_x = _max_ix
    td_max_ys = []
    for q in _qs:
        for ds_target in ds_targets:
            theoretical_data = ds_theoretical_series(multipliers, q=q, after_n_confs=ds_target)
            t_series.append(theoretical_data)
            td_max_ys.append(theoretical_data.max())
            prob_math = gen_cec_prob_str(ds_target, is_trad=True)
            theoretical_data.plot(label=f"y = {prob_math} --- Theoretical Trad: $q={q:.2f}$", zorder=2, linestyle="dashed", linewidth=2.0)
    max_y = max(max(td_max_ys), max(s.max() for s in csv_series) if csv_series else 0)
    print(f"Done. Now drawing.")

    default_title = "\n".join([
        f"P(atk success) PoR vs Traditional Chain",
        "(more confirmations w/ trad chain vs more chains w/ PoR)",
        # f"Trials={n_trials}"
        ])
    plt.suptitle(title or default_title, fontdict=dict(linespacing=1.5))
    plt.title('', fontdict=dict(fontsize=8))
    plt.xlabel(x_label or "x = Confirmation Multiplier / # Chains")
    plt.ylabel(y_label or "P(atk success)")
    plt.grid(True)
    plt.grid(True, which='minor', color=(0.9, 0.9, 0.9, 0.1))
    plt.minorticks_on()
    plt.legend()

    if len(ds_targets) == 1:
        ds_c = list(ds_targets)[0]
        c2n = lambda c: c / ds_c
        n2c = lambda n: n * ds_c
        sec_x_axis = plt.gca().secondary_xaxis('top', functions=(n2c, c2n))
        sec_x_axis.set_xlabel('Equivalent Traditional Confirmations')

    if x_range:
        plt.xlim(x_range)
    plt.ylim(bottom=0)

    plt.tight_layout()

    if comment:
        x = comment.x or x_range[1] - 0.5
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


@dataclass
class SavePlot:
    csv_files: list[CsvFileToPlot]
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


@click.command()
@click.option('-F', '--filter-fname', default=None, help='If present, only generate those graphs with filenames contining the filter string.')
@click.option('-j', '--n-jobs', default=max(1, mp.cpu_count() - 1), help='Number of chart-generation threads to run in parallel')
def main(filter_fname: Optional[str], n_jobs: int):

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

    largest_x_range = (0, 46)
    q_t_to_x_range: dict[tuple[str, str], Optional[tuple[float, float]]] = defaultdict(
        lambda: largest_x_range, {
        ('0.40', '5'): (0, 20),
        ('0.40', '10'): (0, 16),
        ('0.40', '20'): (0, 10),
        ('0.44', '5'): (0, 46),
        ('0.44', '10'): (0, 31),
        ('0.44', '20'): (0, 20),
    })

    def compare_e12_e13_e15(q, t) -> list[CsvFileToPlot]:
        return [
            (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'e12'),
            (exp_13_csv_name(q, t, exp_num='13', strat="DoubleSpendWork", cs="WeightedDag"), 'por', 'e13'),
            (exp_13_csv_name(q, t, exp_num='15', strat="DoubleSpendWork", cs="WeightedDag", daa=500), 'por', 'e15'),
            (exp_16_csv_name(q, t, exp_num='17', strat="DoubleSpendWork", cs="WeightedDag"), 'por', 'e17'),
        ]


    def gen_por_equiv_csvs(q, t) -> list[CsvFileToPlot]:
        return [
            (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', 'DS+WC'),
            (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'DS+WD'),
            (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', 'DSW+WC'),
            (f'exp-12-repeat-8-RDoubleSpendWork-q{q}-t{t}-p50-H50-WeightedDag-xxh3.csv', 'por', 'DSW+WD'),
            (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD'),
            (f'exp_aux3_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC'),
        ]

    def exp_12_csv_name(q, t, bt=50, hr=50, strat="DoubleSpend", cs="WeightedChain", daa=None, exp_num=None, hashname=None):
        return f'exp-12-repeat-8-R{strat}-q{q}-t{t}-p{bt}-H{hr}-{cs}-xxh3.csv'

    def exp_13_csv_name(q, t, bt=50, hr=50, strat="DoubleSpend", cs="WeightedChain", daa=100, exp_num=None, hashname=None):
        assert exp_num
        return f'exp_{exp_num}_RandHR_q={q}_dswin={t}_bt={bt}_hr={hr}_{strat}_{cs}_DAA{daa}.csv'

    def exp_16_csv_name(q, t, bt=50, hr=50, strat="DoubleSpendWork", cs="WeightedDag", daa=100, exp_num=None, hashname='blake3'):
        assert exp_num
        rand_hr_dist = exp_num not in ['17'] # in ['16', '18', '19', '20']
        hr_dist = 'RandHR' if rand_hr_dist else 'UniHR'
        return f'exp_{exp_num}_{hr_dist}_{hashname}_q={q}_dswin={t}_bt={bt}_hr={hr}_{strat}_{cs}_DAA{daa}.csv'

    def unknown_exp_num_name(q, t, bt=50, hr=50, strat="DoubleSpendWork", cs="WeightedDag", daa=100, exp_num='16', hashname='blake3') -> str:
        raise Exception(f'unknown exp_num: {exp_num}')

    def csv_name_f_from_exp(exp_num):
        try:
            exp_num = str(int(exp_num[:2]))
        except:
            pass
        return ({
            '12': exp_12_csv_name,
            '13': exp_13_csv_name,
            '14': exp_13_csv_name,
            '15': exp_13_csv_name,
            '16': exp_16_csv_name,
            '17': exp_16_csv_name,
            '18': exp_16_csv_name,
            '19': exp_16_csv_name,
            '20': exp_16_csv_name,
            '21': exp_16_csv_name,
            '22': exp_16_csv_name,
            '22b': exp_16_csv_name,
            '22c': exp_16_csv_name,
            '22aux': exp_16_csv_name,
            '23': exp_16_csv_name,
            '23aux': exp_16_csv_name,
            '24': exp_16_csv_name,
            '25': exp_16_csv_name,
            '26': exp_16_csv_name,
            '27': exp_16_csv_name,
            '28': exp_16_csv_name,
            '29': exp_16_csv_name,
        }).get(exp_num, unknown_exp_num_name)

    def gen_por_equiv_rand_hrs_csvs(q, t, bt=50, hr=50, only_real_world=False, exp_num='13', aux_num='3', daa='100') -> list[CsvFileToPlot]:
        csv_name_f = csv_name_f_from_exp(exp_num)
        csvs = [
            (csv_name_f(q, t, bt, hr, exp_num=exp_num, daa=daa, strat="DoubleSpend", cs="WeightedChain"), 'por', 'DS+WC'),
            (csv_name_f(q, t, bt, hr, exp_num=exp_num, daa=daa, strat="DoubleSpend", cs="WeightedDag"), 'por', 'DS+WD'),
            (csv_name_f(q, t, bt, hr, exp_num=exp_num, daa=daa, strat="DoubleSpendWork", cs="WeightedChain"), 'por', 'DSW+WC'),
            (csv_name_f(q, t, bt, hr, exp_num=exp_num, daa=daa, strat="DoubleSpendWork", cs="WeightedDag"), 'por', 'DSW+WD'),
            # (f'exp_aux{aux_num}_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD (Best Trad)'),
            # (f'exp_aux{aux_num}_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC (Worst Trad)'),
            (f'exp_aux{aux_num}_q={q}_dsconf-base={t}_bt={bt}_hr={hr}_DoubleSpendWork_WeightedDag_DAA100.csv', 'trad', 'DSW+WD (Best Trad)'),
            (f'exp_aux{aux_num}_q={q}_dsconf-base={t}_bt={bt}_hr={hr}_DoubleSpend_WeightedChain_DAA100.csv', 'trad', 'DS+WC (Worst Trad)'),
        ]
        if only_real_world:
            return csvs[3:]
        return csvs

    # $P(q; N_1 = N; c = C) \\approx P(q; N_1 = \\frac{{N}}{{2}}; c = 2C)$
    def gen_por_cec_ext_test(q, t, exp, aux, bt, hr, daa) -> list[CsvFileToPlot]:
        csv_name_f = csv_name_f_from_exp(exp)
        return [
            (csv_name_f(q, t, bt, hr, exp_num=exp, daa=daa, strat="DoubleSpendWork", cs="WeightedDag"), 'por', None),
            (csv_name_f(q, f'{2*int(t):d}', bt, hr, exp_num=exp, daa=daa, strat="DoubleSpendWork", cs="WeightedDag"), 'por', PorPlotOpts(cec_scaled=2)),
        ]

    def gen_por_hash_comare(q, t) -> list[CsvFileToPlot]:
        return [
            (exp_13_csv_name(q, t, exp_num='13', strat="DoubleSpendWork", cs="WeightedDag"), 'por', 'hash:xxh3'),
            (exp_16_csv_name(q, t, exp_num='16', strat="DoubleSpendWork", cs="WeightedDag", hashname="blake3"), 'por', 'hash:blake3'),
        ]


    def std_x_label(t):
        # return f"PoR: $x = N_1$; Trad: $x = Confirmations / {t}$"
        return f"Simplex $N_1$ (or, for trad chains: $x = Confirmations / {t}$)"


    CEC_TITLE_STR = "$P(q; N_1 = N; c = C) \\approx P(q; N_1 = 1; c = NC)$"
    CEC_EXT_TITLE_STR = "$P(q; N_1 = N; c = C) \\approx P(q; N_1 = \\frac{{N}}{{2}}; c = 2C)$"


    jobs_to_save: list[SavePlot] = [
        SavePlot(
            csvs,
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: Is the simulation of traditional doublespends consisted with theoretical results?",
                f"Theoretical vs DS+WC vs DSW+WD vs DS+LC@DAA100 vs DS+LC@DAA1000"
                # f"$N_1=1$; doublespend target: ${t} x$"
                ]),
            # "Traditional Doublespend Comparison: $N_1=1$\nTheoretical vs DS+WC vs DSW+WD vs DS+LC (w/ DAA over {100,1000} blocks)",
            fname,
            x_label=f"x = Confirmations / {t}",
            comment=Comment(' '.join([
                "Notice that the green line does not approach 0:",
                "the LC (Longest Chain) fork rule is only secure",
                "when the DAA adjustment period is $\\gg$ the number",
                "of confirmations required.",
                "e.g., LC with a DAA range of 100 blocks is somewhat insecure after ~40 confirmations.",
                "This makes sense because,",
                "once the DAA has adjusted to the attacker's hashrate,",
                "the attacker's chain-segment gains blocks at the same",
                "rate as the honest chain.",
                "This is why fork rules should use chain $weight$ rather than $height$."
                ]), c_y, wrap_line_width=425),
            ) for t, csvs, c_y, fname in [
                (5, csv_compare_aux, 0.22, "png/trad_doublespend_comparison.png"),
            ]
    ] + [
        SavePlot(
            csv_compare_aux_3(q, t),
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: Is the simulation of traditional doublespends consisted with theoretical results?",
                f"$N_1=1$; $q={q}$; doublespend target: ${t} x$"]),
            f"png/trad_ds_comparison_q={q}_t={t}.png",
            x_label=f"x = Confirmations / {t}",
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
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
            "\n".join([f"PoR Confirmation Equivalence Conjecture | $q={q}$", f"{CEC_TITLE_STR}"]),
            f"png/por_equiv_q={q}_t{t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        SavePlot(
            gen_por_equiv_rand_hrs_csvs(q, t, exp_num='13'),
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture",
                f"$q={q}$ | {'hash-rate randomly distributed ($q+p=1$ true network-wide)'}",
                f"{CEC_TITLE_STR}"]),
            # f" PoR Confirmation Equivalence Conjecture \n $q={q}$ | hash-rate randomly distributed ($q+p=1$ true network-wide) \n{CEC_TITLE_STR}",
            f"png/por_equiv_rand_hr_q={q}_t{t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        # "real world" means WeightedDag + DoubleSpendWork b/c that's what's necessary in a production build
        SavePlot(
            gen_por_equiv_rand_hrs_csvs(q, t, bt, hr, only_real_world=True, exp_num=exp, aux_num=aux, daa=daa),
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture | WeightedDag + DoubleSpendWork",
                f"$q={q}$ | {'hash-rate randomly distributed ($q+p=1$ true network-wide)' if int(exp) < 17 else 'uniform hash rate distribution'}",
                f"{CEC_TITLE_STR}"]),
            f"png/por_equiv_onlyrealworld_{'rand_hr' if int(exp) < 17 else 'uni_hr'}_e{exp}_a{aux}_q={q}_t{t}_bt={bt}_hr={hr}_daa={daa}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48']
            for t in ['5', '10', '20']
            for (exp, aux, bt, hr, daa) in [
                ('13', '3', '50', '50', '100'),
                ('14', '14', '100', '100', '100'),
                ('15', '3', '50', '50', '500'),
                ('16', '3', '50', '50', '100'),
                ('17', '3', '50', '50', '100'),
            ]
    ] + [
        # $P(q; N_1 = N; c = C) \\approx P(q; N_1 = \\frac{{N}}{{2}}; c = 2C)$
        SavePlot(
            gen_por_cec_ext_test(q, t, exp=exp, aux=aux, bt=bt, hr=hr, daa=daa),
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture (Extended)",
                f"$q={q}$ | WD+DSW | {'random' if int(exp) < 17 else 'uniform'} hash rate distribution",
                f"{CEC_EXT_TITLE_STR}"]),
            # f" PoR Confirmation Equivalence Conjecture (Extended) \n $q={q}$ | WD+DSW | random hash rate distribution \n{CEC_EXT_TITLE_STR}",
            f"png/por_equiv_orw_ext-cec_e{exp}_q={q}_t{t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10']
            for (exp, aux, bt, hr, daa) in [
                    ('12', '3', '50', '50', '100'),
                    ('13', '3', '50', '50', '100'),
                    ('14', '14', '100', '100', '100'),
                    ('15', '3', '50', '50', '500'),
                    ('16', '3', '50', '50', '100'),
                    ('17', '3', '50', '50', '100'),
                    ]
    ] + [
        SavePlot(
            [
                (f'exp-12-repeat-8-RDoubleSpend-q{q}-t{t}-p50-H50-WeightedChain-xxh3.csv', 'por', None),
                (f'exp_aux2_q={q}_dsconf-base={t}_bt=50_hr=50_DoubleSpend_WeightedChain_DAA100.csv', 'trad', None),
            ],
            f"Confirmation Equivalence Conjecture | PoR vs Traditional vs Theoretical \n DS+WC | $q={q}$ | DoubleSpend Target: ${t} \\cdot x$ \n{CEC_TITLE_STR}",
            f"png/por_eqiv_hyp_vs_trad_q={q}_t={t}_DS+WC.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44'] for t in ['5', '10', '20']  # , '0.48'
    ] + [
        # compare results from diff experiments
        # note: experiment 12 has uniform HR distribution (all chains have same HR and attacker always has q proportion)
        #       e13,e15 have random HR distributions
        SavePlot(
            compare_e12_e13_e15(q, t),
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Comparison of experiments 12,13,15,17 (12 and 17 have uniform HRs)",
                # f"{CEC_TITLE_STR}"
                ]),
            # f"(Comparison of experiments 12,13,15)",
            f"png/compare_e12-13-15-17_q={q}_t={t}.svg",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        # compare e13 to e16 -- only differs by hash (xx vs blake)
        SavePlot(
            gen_por_hash_comare(q, t),
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: is xxh3 good enough compared against blake3?",
                # f"{CEC_TITLE_STR}"
                ]),
            f"png/e16_hash_comparison_q={q}_t={t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        ) for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        SavePlot([], f"Theoretical doublespend success rates given\n $q \\in \\{{{','.join(qs)}\\}}$ after ${t} \\cdot x$ confirmations. ",
            # f"png/theoretical_q={q}_t={t}.svg",
            f"png/theoretical_q={'-'.join(qs)}_t={t}.svg",
            x_label=f"$x = Confirmations / {t}$",
            x_range=(0, 46),
            # seed_qs={float(q)}, seed_ds_targets={float(t)},
            seed_qs=set(map(float, qs)), seed_ds_targets={float(t)},
            )
        for qs in [['0.40', '0.44', '0.48']] for t in ['5', '10', '20']
    ] + [
        # exp 18/19
        SavePlot(
            [
                (csv_name_f_from_exp(exp)(q, t, exp_num=exp, hashname=hn), 'por', extra)
                for exp,hn,extra in [
                    ('16', 'blake3', 'Default'),
                    ('20', 'xxh3', 'Dynamic Cutoff'),
                    ('18', 'xxh3', 'Early Cutoff'),
                    ('19', 'xxh3', 'Late Cutoff'),
                    ]
            ],
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: Do we cut failing doublespend attempts off too early?",
            ]),
            f"png/atk_length_comparison_q={q}_t={t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        )
        for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        # exp21: high res vs default
        SavePlot(
            [
                (csv_name_f_from_exp(exp)(q, t, exp_num=exp, hashname=hn, **kw), 'por', extra)
                for exp, hn, extra, kw in [
                    ('20', 'xxh3', ' HR= 50, Dynamic Cutoff', dict()),
                    ('19', 'xxh3', ' HR= 50, Late Cutoff', dict()),
                    ('21', 'xxh3', 'HR=200, xxh3', dict(bt=200, hr=200)),
                ] + ([] if (q,t) != ('0.44', '5') else [('21', 'blake3', 'HR=200, blake3', dict(bt=200, hr=200))])
            ],
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: Do we get different results w/ larger numbers?",
            ]),
            f"png/highres_vs_std_q={q}_t={t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        )
        # this is expensive so not as many combos
        for q in ['0.40', '0.44', '0.48'] for t in ['5', '10']
    ] + [
        # exp22: bonus block
        SavePlot(
            [
                (csv_name_f_from_exp(exp)(q, t, exp_num=exp, hashname=hn, **kw), 'por', extra)
                for exp, hn, extra, kw in [
                    ('20', 'xxh3', 'No Bonus', dict()),
                    ('19', 'xxh3', 'No Bonus', dict()),
                    # ('22b', 'xxh3', 'bonus b', dict()),
                    # _kwargs=dict(color=(0xf0/0xff, 0x19/0xff, 0x92/0xff, 1), marker='+')
                    ('22c', 'xxh3', PorPlotOpts(_label_extra='Bonus Block'), dict()),
                ]
            ],
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: Does giving the attacker a bonus block change things??",
            ]),
            f"png/bonusblock_2_vs_std_q={q}_t={t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        )
        for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        # exp22aux: doublespends on trad with bonus block
        SavePlot(
            [
                (csv_name_f_from_exp(exp)(q, t, exp_num=exp, hashname=hn, **kw), ty, extra)
                for exp, hn, ty, extra, kw in [
                    # _kwargs=dict(color=(0xf0/0xff, 0x19/0xff, 0x92/0xff, 1), marker='+')
                    ('22c', 'xxh3', 'por', PorPlotOpts(_label_extra='Bonus Block'), dict()),
                    # _kwargs=dict(color='orangered', marker='o')
                    ('22aux', 'xxh3', 'trad', PorPlotOpts(_label_extra='Bonus Block'), dict()),
                ]
            ],
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture Auxiliary Graph",
                f"Q: Does giving the attacker a bonus block change trad doublespends?",
            ]),
            f"png/bonusblock_2_trad_q={q}_t={t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        )
        for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ] + [
        # exp3: overnight runs
        # NOTE: csv/exp_23b_RandHR_xxh3_q=0.40_dswin=5_bt=75_hr=75_DoubleSpendWork_WeightedDag_DAA100.csv
        #       contains an instance of `_,_` in cols 12,13
        SavePlot(
            [
                (csv_name_f_from_exp(exp)(q, t, exp_num=exp, hashname=hn, **kw), ty, extra)
                for exp, hn, ty, extra, kw in [
                    ('22c', 'xxh3', 'por', PorPlotOpts(_label_extra='22c: Bonus Block'), dict()),
                    ('23', 'xxh3', 'por', PorPlotOpts(_label_extra='23'), dict(bt=75, hr=75)),
                    ('23b', 'xxh3', 'por', PorPlotOpts(_label_extra='23b'), dict(bt=75, hr=75)),
                    # ('24', 'xxh3', 'por', PorPlotOpts(_label_extra='24'), dict(bt=50, hr=50)),
                    # ('25', 'xxh3', 'por', PorPlotOpts(_label_extra='25'), dict(bt=75, hr=75)),
                    ('26', 'xxh3', 'por', PorPlotOpts(_label_extra='26'), dict(bt=75, hr=75)),
                    ('22aux', 'xxh3', 'trad', PorPlotOpts(_label_extra='22aux: Bonus Block'), dict()),
                    ('23aux', 'xxh3', 'trad', PorPlotOpts(_label_extra='23aux'), dict(bt=75, hr=75)),
                    ('23baux', 'xxh3', 'trad', PorPlotOpts(_label_extra='23baux'), dict(bt=75, hr=75)),
                    # ('24aux', 'xxh3', 'trad', PorPlotOpts(_label_extra='24aux'), dict(bt=50, hr=50)),
                    # ('25aux', 'xxh3', 'trad', PorPlotOpts(_label_extra='25aux'), dict(bt=75, hr=75)),
                    # ('26aux', 'xxh3', 'trad', PorPlotOpts(_label_extra='26aux'), dict(bt=75, hr=75)),
                ]
            ],
            "\n".join([
                f"PoR Confirmation Equivalence Conjecture",
                f"{CEC_TITLE_STR}",
            ]),
            f"png/e23_nice={q}_t={t}.png",
            x_label=std_x_label(t),
            x_range=q_t_to_x_range[(q, t)],
        )
        for q in ['0.40', '0.44', '0.48'] for t in ['5', '10', '20']
    ]

    pool = mpp.Pool(n_jobs)
    count = 0

    for j in jobs_to_save:
        if filter_fname is None or filter_fname in j.filename:
            if n_jobs > 1:
                pool.apply_async(j.run)
            else:
                j.run()
            count += 1

    pool.close()
    pool.join()
    print(f"should be all done generating {count} graphs via {n_jobs} threads")



main()
