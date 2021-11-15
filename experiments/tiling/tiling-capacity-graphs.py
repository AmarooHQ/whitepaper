from typing import TypeAlias
import matplotlib.pyplot as plt
import numpy as np
from math import *
from collections import defaultdict
from dataclasses import dataclass




def do_plot(xs: list[float|int], yss: list[tuple[str, list[float|int]]], title: str, xlab: str, ylab: str, ylog=False, xlog=False, xplots=1, yplots=1, figax=None, savefig=True):
    if figax is None:
        _fig, ax = plt.subplots()
    else:
        _fig, ax = figax
    plot_f = ax.semilogy if ylog and not xlog else ax.semilogx if xlog and not ylog else ax.loglog if xlog and ylog else ax.plot
    for ys in yss:
        print(f"{title}--{ys[0]}")
        plot_f(xs, ys[1], label=ys[0])
    ax.legend()
    ax.set_title(title)
    ax.set_xlabel(xlab)
    ax.set_ylabel(ylab)
    title = title.replace(' ', '-').replace('/', '-div-')
    if savefig:
        _fig.savefig(f"{title}.pdf")
    print(f"saved? {title}.pdf")
    del _fig
    del ax


def frange(start, stop, step):
    d = stop - start
    steps = ceil(d / step)
    return (i * step + start for i in range(steps))


def tiles_at_d(i, v=3):
    return floor(v * (v-1) ** (i - 1))


def S(n, r=0.5):
    return sum(tiles_at_d(i) * r**i for i in range(n + 1))


@dataclass
class ChainsPerLayerRes:
    layer_tile_n1: float | int
    n_tiles: float | int
    layer_n1: float | int
    sigma_n1: float | int
    hist: list[float | int]
    s_hist: list[float | int]
    r: float | int
    k: float | int
    simplex_n1: float | int
    root_n1: float | int
    factor_more_chains: float | int


def n_chains_per_layer(d: int, v=3, r=0.5, k=3000, bf=1/15, bh=84):
    assert 0 <= r <= 1
    n_tiles = 1
    simplex_n1 = k / 2 / bf / bh
    root_n1: float = ceil(simplex_n1 / 4)
    layer_tile_n1 = root_n1
    sigma_n1: int = root_n1
    hist: list[float|int] = [root_n1]
    s_hist: list[float|int] = [root_n1]
    layer_n1 = layer_tile_n1
    for i in range(1, d+1):
        layer_tile_n1 *= r
        layer_tile_n1 = floor(layer_tile_n1)
        # if layer_tile_n1 < 1:
        #     layer_tile_n1 = 0
        hist.append(floor(layer_tile_n1))
        n_tiles = tiles_at_d(i, v=v)
        layer_n1 = floor(n_tiles * layer_tile_n1)
        sigma_n1 += layer_n1
        s_hist.append(floor(layer_n1))
        if layer_tile_n1 == 0:
            break
    return ChainsPerLayerRes(layer_tile_n1=layer_tile_n1, n_tiles=n_tiles, layer_n1=layer_n1, sigma_n1=sigma_n1, hist=hist,
                s_hist=s_hist, r=r, k=k, simplex_n1=simplex_n1, root_n1=root_n1,
                factor_more_chains=(sigma_n1 / simplex_n1))


Ys: TypeAlias = dict[str, list[float|int]]
Yss: TypeAlias = list[tuple[str, list[float|int]]]


def make_ys() -> Ys:
    return defaultdict(list)


def ys_to_yss(ys: Ys) -> Yss:
    return list((k,v) for k,v in ys.items())


def gen_k_vs_sigma_n1():
    xs: list[float|int] = list(k * 1000 for k in range(1, 101))
    ys = make_ys()
    for r in frange(0.29, 0.891, 0.1):
        label = f"ΣN₁ (r={r:.2f})"
        for k in xs:
            res = n_chains_per_layer(999, r=r, k=k)
            ys[label].append((res.sigma_n1))
    do_plot(xs, ys_to_yss(ys), 'chains in tiling vs k', 'k', 'capacity (chains)', ylog=True, xlog=True)


def gen_k_vs_sigma_n1_div_k():
    xs: list[float|int] = list(k * 1000 for k in range(1, 101))
    fig, axes = plt.subplots(3, 2)
    for _pi, _p in enumerate([2, 3, 4, 5, 6, 6.6]):
        ys = make_ys()
        for r in frange(0.5, 0.901, 0.05):
            label = lambda p: f"(ΣN₁)^(1/{p})/k (r={r:.2f})"
            for k in xs:
                res = n_chains_per_layer(999, r=r, k=k)
                ys[label(_p)].append(pow(res.sigma_n1, 1/_p) / k)
        do_plot(xs, ys_to_yss(ys), f'{_p}th root of n1 div k vs k', 'k', 'ΣN₁', ylog=True, xlog=True)


if __name__ == "__main__":
    gen_k_vs_sigma_n1()
    gen_k_vs_sigma_n1_div_k()
