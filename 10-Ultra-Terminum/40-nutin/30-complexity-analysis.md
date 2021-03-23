## Scaling Complexity Analysis of *Ultra Terminum*

UT has two primary methods of scaling: reflection and dapp-chains. Reflection is novel. Dapp-chains are similar to many of the scaling ideas proposed for other networks (polkadot, eth2, etc), though there are fewer restrictions on dapp-chains in UT compared to other networks. Additionally, dapp-chains in UT are hosted by the simplex. This provides additional security compared to 'naked' PoS chains without sacrificing any of their other developments (e.g. finality).

### Complexity of $O(c)$ chains

e.g. Bitcoin

\todo[inline]{do algebra; lol there's like no algebra for this one}

\begin{equation}
T_1 = k
\end{equation}

### Optimistic Complexity of $O(c^2)$ chains

e.g. Eth2, Polkadot

\todo[inline]{do algebra}

\begin{equation}
\begin{split}
T_2 & = \frac{k_1 \cdot k_2}{D_f \cdot D_h}
    & \approx \frac{k^2}{D_f \cdot D_h}
\end{split}
\end{equation}

### Complexity of $O(c^2)$ reflection

\todo[inline]{do algebra}

For simplexes, the optimal number of simplex-chains is:

\begin{equation}
N_1 = \frac{k_1}{2 \cdot B_f \cdot B_h}
\end{equation}

\begin{equation}
\label{eq:simplex-T1}
T_1 = \frac{k_1^2}{4 \cdot B_f \cdot B_h}
\end{equation}

($T_1$ in bytes/sec)

what's the balance (in b/s) of transactions to reflections?

Set:

\begin{equation}
\label{eq:k-optimal}
k_1 = k_{1,tx} + k_{1,B}
\end{equation}

by the power of maths and sorta-documented algebra (equations 1,2,3,4 in scans on basecamp):

\begin{equation}
\label{eq:k-tx-optimal}
k_{1,tx} = \frac{k_1}{2}
\end{equation}

thus, via \autoref{eq:k-optimal}

\begin{equation}
k_{1,B} = \frac{k_1}{2}
\end{equation}

### Replacing Transactions with Dapp-Chains

\todo[inline]{do algebra}

\todo[inline]{this section covers both throughput and optimal numbers for dapp-chains and simplex-chains}


also generally:

\begin{equation}
\label{eq:throughput-iter}
T_{i+1} = \frac{T_i}{D_f \cdot D_h} \cdot k_{i+1}
\end{equation}

maybe this next one only works for simple scaling like eth2, not reflection (can't remember off the top of my head; it's eq 9 in the scans on BC)

\begin{equation}
N_{i} = \frac{T_i}{k_i}
\end{equation}

\todo[inline]{(insert maths)}

Thus, the maximum number of dapp chains is given by:

\begin{equation}
N_2 = \frac{k_1^2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{equation}

### Complexity of $O(c^3)$ UT

\todo[inline]{do algebra}

\begin{equation}
T_1 = \frac{k_1^2}{4 \cdot B_f \cdot B_h}
\end{equation}

\begin{equation}
T_2 = \frac{k_1^2 \cdot k_2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{equation}

### Complexity of $O(c^4)$ UT

\todo[inline]{do algebra}

\begin{equation}
T_3 = \frac{k_1^2 \cdot k_2 \cdot k_3}{4 \cdot B_f \cdot B_h \cdot D_f^2 \cdot D_h^2}
\end{equation}

(presuming that params $D_f$ and $D_h$ are used for dapp-chains and dapp-dapp-chains)

### Complexity comparison

| $k$, $B_f$, $D_f$, $B_h$, $D_h$, $Tx_{avg}$ | $O(c)$ tps | $O(c^2)$ tps | $O(c^3)$ UT tps | $O(c^4)$ UT tps |
|---|---|---|---|---|
| (1000, 1/15, 1/15, 112, 250, 250) | 4 | 240 | 8,036 | 482,143 |
| (3000, 1/15, 1/15, 112, 250, 250) | 12 | 2,160 | 216,964 | $3.9\times 10^{7}$ |
| (3000, 1/20, 1/40, 112, 250, 250) | 12 | 5,760 | 771,429 | $3.7\times 10^{8}$ |
| (1000, 1/60, 1/60, 112, 250, 250) | 4 | 960 | 128,571 | $3.1\times 10^{7}$ |
| (3000, 1/60, 1/60, 200, 500, 250) | 12 | 4,320 | 972,000 | $3.5\times 10^{8}$ |
| (3000, 1/60, 1/60, 112, 500, 250) | 12 | 4,320 | $1.7\times 10^{6}$ | $6.2\times 10^{8}$ |
| (3000, 1/60, 1/60, 200, 250, 250) | 12 | 8,640 | $1.9\times 10^{6}$ | $1.4\times 10^{9}$ |
| (3000, 1/60, 1/60, 112, 250, 250) | 12 | 8,640 | $3.5\times 10^{6}$ | $2.5\times 10^{9}$ |
| (26000, 1/60, 1/60, 200, 200, 250) | 104 | 811,200 | $1.6\times 10^{9}$ | $1.2\times 10^{13}$ |
| (26000, 1/60, 1/60, 112, 200, 250) | 104 | 811,200 | $2.8\times 10^{9}$ | $2.2\times 10^{13}$ |
| (1000, 1/600, 1/600, 112, 250, 250) | 4 | 9,600 | $1.3\times 10^{7}$ | $3.1\times 10^{10}$ |
| (3000, 1/600, 1/600, 200, 250, 250) | 12 | 86,400 | $1.9\times 10^{8}$ | $1.4\times 10^{12}$ |
| (3000, 1/600, 1/600, 112, 250, 250) | 12 | 86,400 | $3.5\times 10^{8}$ | $2.5\times 10^{12}$ |
| (26000, 1/600, 1/600, 200, 200, 250) | 104 | $8.1\times 10^{6}$ | $1.6\times 10^{11}$ | $1.2\times 10^{16}$ |
| (26000, 1/600, 1/600, 112, 200, 250) | 104 | $8.1\times 10^{6}$ | $2.8\times 10^{11}$ | $2.2\times 10^{16}$ |
| (1000, 1/60, 1/600, 112, 250, 250) | 4 | 9,600 | $1.3\times 10^{6}$ | $3.1\times 10^{9}$ |
| (3000, 1/60, 1/600, 112, 250, 250) | 12 | 86,400 | $3.5\times 10^{7}$ | $2.5\times 10^{11}$ |
| (26000, 1/60, 1/600, 112, 250, 250) | 104 | $6.5\times 10^{6}$ | $2.3\times 10^{10}$ | $1.4\times 10^{15}$ |

\todo[inline]{add figure of graphs of $B_f$ a/or $D_f$ vs tps, $B_h$ a/or $D_h$ vs tps, tx-size vs tps, k vs tps}

### Bandwidth Complexity

\todo[inline]{bandwidth requirement presuming all simplex blocks downloaded (to ensure availability)}


### Outdated Sections

#### Complexity of Dapp-Chains

\todo[inline]{outdated, will be replaced by above sections}

Dapp-chains look and act like typical shards; i.e. dapp-chains are 'child' chains of some 'parent' chain. If we presume that all chains have some constant maximum capacity (similar to the block-limit in Bitcoin and gas-limit in Ethereum) then calculating the scaling complexity is straight-forward and typical.

NB: capacity is often discussed in *transactions per second* (tps) or in terms of maximum block size and block production rate. For example, Bitcoin's block production rate is $\SI{1/600}{blocks\per\sec}$ (given a 10 minute block target time) and Ethereum's is $\SI{1/15}{blocks\per\sec}$ (given a 15 second block target time). Since Bitcoin's block limit is $\SI{1000000}{bytes}$ (though, practically it's slightly more due to segwit), Bitcoin's capacity is measured to be approx $\SI{1670}{bytes\per\sec}$. Ethereum's capacity is approx[^1] $\SI{3100}{bytes\per\sec}$. Readers familiar with the architecture of both Bitcoin and Ethereum will realize that this is not really a fair comparison as there are significant differences between each network's method of state management. In the context of this analysis we aren't too concerned with that; these numbers are here to give us reasonable expectations and enable both sanity checking and order-of-magnitude estimates.

[^1]: Ethereum's capacity is slightly harder to calculate in $\si{bytes\per\sec}$ since we need to convert from $\si{gas\per\sec}$ to $\si{bytes\per\sec}$. Averaging the size of blocks 11949129 to 11949134 (which were all above 98% gas utilization) gives $\SI{46896}{bytes/block}$, or $\SI{3126.4}{bytes\per\sec}$.

\todo[inline]{fix up units and maths to work with latex, mathjax, etc.}
Each dapp-chain has some maximum capacity, $k \si{bytes/sec/dchain}$, and some header-size $h \si{bytes/header}$. Additionally, there is some average block production rate per dapp-chain: `b blocks/sec/dchain`. The parent chain also has some maximum capacity, which we set equal to the dapp-chains' capacity, `k bytes/sec/pchain` (nb: since there is only one parent-chain we can omit the `pchain` component from these units). We can choose `k` to fit with reasonable expectations about each nodes' computational capacity, `c`. Note that $O(k) = O(c)$; throughput grows with computational capacity (naturally).

The parent chain can host multiple dapp-chains. If it is *only* hosting dapp-chains, then, at maximum capacity, each parent-block will be full of headers for dapp-chains. That is, a parent chain can handle up to `k/h headers/sec/pchain = k/h headers/sec`. We've said that there is, on average, `b blocks/sec/dchain`, and headers have a 1:1 relationship to blocks. Thus we can say that we can support up to `k/bh dchains`.

*Total capacity* (or throughput) of a parent-child architecture, like this, is the sum of the capacity of all child-chains. Each child chain has `k` capacity. Since we have $\frac{k}{b*h} dchains$ total, we can say that the total throughput is approximately $\frac{k}{b*h} \si{dchains} * k bytes/sec/dchain = \frac{k^2}{b.h} bytes/sec$. Since $b$ and $h$ are constants, a parent-child architecture like this has total capacity in $O(k^2) = O(c^2)$. Given previous research, this is the expected result.

#### Complexity of PoW Reflection

\todo[inline]{outdated, will be replaced by above sections}

- similar to above

$k$ space in each block split between headers of other chains + transactions; $k = k_{tx} + k_r$

$k_r$ bytes/sec shared between all the headers of other chains, so we get $\frac{k_r}{b_r \cdot h_r}$ rchains - note that these $b$ and $h$ are for PoW reflected chains (block times and header sizes of reflected chains might be diff to those of dapp-chains).

we end up with $\frac{k_{tx} \cdot k_r}{b_r \cdot h_r}$ throughput --> roughly `space for txs * space for headers / header size / header frequency`

to maximize $k_{tx} \cdot k_r$ we set $k_{tx} = k_r = \frac{k}{2}$ => so final calc is $\frac{k^2}{4 \cdot b_r \cdot h_r}$ => scales with $O(k^2) = O(c^2)$.

#### Complexity of UT

\todo[inline]{outdated, will be replaced by above sections}

Basically, replace $k_{tx}$ with dapp-chain headers. so dapp-chain capacity decreases from `k^2/bh` to `k^2/2bh` (for dapp-chain values of `b` and `h`). but we get to multiply by `k[r]/bh = k/2bh` rchains (for reflected chain values of `b` and `h`).

it's unlikely that `b` and `h` will be the same for reflected parent PoW chains and dapp-chains, but presuming they are:

\begin{equation}
Throughput_{Total} = \frac{k^3}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{equation}

we simplify as before, and we have complexity $O(k^3) = O(c^3)$.

##### Maximum number of dapp-chains

\todo[inline]{outdated, will be replaced by above sections}

the total ($t$) number of dapp-chains we can have is $t = r\cdot d$. We know that $r \cdot h_r \cdot b_r + d \cdot h_d \cdot b_d = k$; \todo[inline]{check remainder of paragraph} i.e. `reflection-chains * size of reflection header + dapp-chains * size of dapp-chain headers = k`. We can use these two to obtain: `t = r*(k - r*h[r])/h[d]` (eliminating the variable `d`). we then get `dt/dr = k/h[d] - 2*r*h[r]/h[d]`. find the maximum at `dt/dr = 0` to yield `r = k/(2*h[r])` at maximum throughput. since `t = r*(k - r*h[r])/h[d] = rk/h[d] - r^2*h[r]/h[d]` we get `t[max] = k^2/(2*h[r]*h[d]) - k^2/(4*h[r]^2) * h[r]/h[d] = 2*k^2/(4*h[r]*h[d]) - k^2/(4*h[r]*h[d]) = k^2/(4*h[r]*h[d])`

\todo[inline]{The below is right tho}

Thus, the maximum number of dapp chains is given by:

\begin{equation}
N_2 = \frac{k_1^2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{equation}

### code to generate complexity comparison table

\todo[inline]{move this code to an appendix eventually}

```python
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
            (['', params] + list(map(fmt_rounded_commas, cols)) + [''])
        ).strip() \
            .replace('0.0016666666666666668', '1/600') \
            .replace('0.016666666666666666', '1/60') \
            .replace('0.06666666666666667', '1/15') \
            .replace('0.05', '1/20').replace('0.025', '1/40')

row_inputs = [
    (1000, 1/15, 1/15, 112, 250, 250),
    (3000, 1/15, 1/15, 112, 250, 250),
    (3000, 1/20, 1/40, 112, 250, 250),
    (1000, 1/60, 1/60, 112, 250, 250),
    (3000, 1/60, 1/60, 200, 500, 250),
    (3000, 1/60, 1/60, 112, 500, 250),
    (3000, 1/60, 1/60, 200, 250, 250),
    (3000, 1/60, 1/60, 112, 250, 250),
    (26000, 1/60, 1/60, 200, 200, 250),
    (26000, 1/60, 1/60, 112, 200, 250),
    (1000, 1/600, 1/600, 112, 250, 250),
    (3000, 1/600, 1/600, 200, 250, 250),
    (3000, 1/600, 1/600, 112, 250, 250),
    (26000, 1/600, 1/600, 200, 200, 250),
    (26000, 1/600, 1/600, 112, 200, 250),
    (1000, 1/60, 1/600, 112, 250, 250),
    (3000, 1/60, 1/600, 112, 250, 250),
    (26000, 1/60, 1/600, 112, 250, 250),
]
for r in row_inputs:
    print(table_row(r))
# list((r, calc_tps_throughput(*r)) for r in row_inputs)
```
