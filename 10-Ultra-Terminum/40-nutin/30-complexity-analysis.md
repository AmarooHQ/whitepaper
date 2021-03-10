### Scaling Complexity Analysis of *Ultra Terminum*

UT has two primary methods of scaling: reflection and dapp-chains. Reflection is novel. Dapp-chains are similar to many of the scaling ideas proposed for other networks (polkadot, eth2, etc), though there are fewer restrictions on dapp-chains in UT compared to other networks.

#### Complexity of Dapp-Chains

Dapp-chains look and act like typical shards; i.e. dapp-chains are 'child' chains of some 'parent' chain. If we presume that all chains have some constant maximum capacity (similar to the block-limit in Bitcoin and gas-limit in Ethereum) then calculating the scaling complexity is straight-forward and typical.

NB: capacity is often discussed in *transactions per second* (tps) or in terms of maximum block size and block production rate. For example, Bitcoin's block production rate is $\SI{1/600}{blocks\per\sec}$ (given a 10 minute block target time) and Ethereum's is $\SI{1/15}{blocks\per\sec}$ (given a 15 second block target time). Since Bitcoin's block limit is $\SI{1000000}{bytes}$ (though, practically it's slightly more due to segwit), Bitcoin's capacity is approx $\SI{1670}{bytes\per\sec}$. Ethereum's capacity is approx[^1] $\SI{3100}{bytes\per\sec}$. Readers familiar with the architecture of both Bitcoin and Ethereum will realize that this is not really a fair comparison as there are significant differences between each network's method of state management. In the context of this analysis we are't too concerned with that; these numbers are here to give us reasonable expectations and enable both sanity checking and order-of-magnitude estimates.

[^1]: Ethereum's capacity is slightly harder to calculate in $\si{bytes\per\sec}$ since we need to convert from $\si{gas\per\sec}$ to $\si{bytes\per\sec}$. Averaging the size of blocks 11949129 to 11949134 (which were all above 98% gas utilization) gives $\SI{46896}{bytes/block}$, or $\SI{3126.4}{bytes\per\sec}$.

\todo[inline]{fix up units and maths to work with latex, mathjax, etc.}

Each dapp-chain has some maximum capacity, $k \si{bytes/sec/dchain}$, and some header-size $h \si{bytes/header}$. Additionally, there is some average block production rate per dapp-chain: `b blocks/sec/dchain`. The parent chain also has some maximum capacity, which we set equal to the dapp-chains' capacity, `k bytes/sec/pchain` (nb: since there is only one parent-chain we can omit the `pchain` component from these units). We can choose `k` to fit with reasonable expectations about each nodes' computational capacity, `c`. Note that $O(k) = O(c)$; throughput grows with computational capacity (naturally).

The parent chain can host multiple dapp-chains. If it is *only* hosting dapp-chains, then, at maximum capacity, each parent-block will be full of headers for dapp-chains. That is, a parent chain can handle up to `k/h headers/sec/pchain = k/h headers/sec`. We've said that there is, on average, `b blocks/sec/dchain`, and headers have a 1:1 relationship to blocks. Thus we can say that we can support up to `k/bh dchains`.

*Total capacity* (or throughput) of a parent-child architecture, like this, is the sum of the capacity of all child-chains. Each child chain has `k` capacity. Since we have $\frac{k}{b*h} dchains$ total, we can say that the total throughput is approximately $\frac{k}{b*h} \si{dchains} * k bytes/sec/dchain = \frac{k^2}{b.h} bytes/sec$. Since $b$ and $h$ are constants, a parent-child architecture like this has total capacity in $O(k^2) = O(c^2)$. Given previous research, this is the expected result.

todo: is 'in' correct to use, as used in "has total capacity in $O(k^2) = O(c^2)$"?

#### Complexity of PoW Reflection

- similar to above

$k$ space in each block split between headers of other chains + transactions; $k = k_{tx} + k_r$

$k_r$ bytes/sec shared between all the headers of other chains, so we get $\frac{k_r}{b_r \cdot h_r}$ rchains - note that these $b$ and $h$ are for PoW reflected chains (block times and header sizes of reflected chains might be diff to those of dapp-chains).

we end up with $\frac{k_{tx} \cdot k_r}{b_r \cdot h_r}$ throughput --> roughly `space for txs * space for headers / header size / header frequency`

to maximize $k_{tx} \cdot k_r$ we set $k_{tx} = k_r = \frac{k}{2}$ => so final calc is $\frac{k^2}{4 \cdot b_r \cdot h_r}$ => scales with $O(k^2) = O(c^2)$.

#### Complexity of UT

Basically, replace $k_{tx}$ with dapp-chain headers. so dapp-chain capacity decreases from `k^2/bh` to `k^2/2bh` (for dapp-chain values of `b` and `h`). but we get to multiply by `k[r]/bh = k/2bh` rchains (for reflected chain values of `b` and `h`).

it's unlikely that `b` and `h` will be the same for reflected parent PoW chains and dapp-chains, but presuming they are:

\begin{equation}
Throughput_{Total} = \frac{k^2}{2\cdot b_d \cdot h_d} \cdot \frac{k}{2 \cdot b_r \cdot h_r}
= \frac{k^3}{4 \cdot b_d \cdot b_r \cdot h_d \cdot h_r}
\end{equation}

we simplify as before, and we have complexity $O(k^3) = O(c^3)$.

the total ($t$) number of dapp-chains we can have is $t = r\cdot d$. We know that `r*h[r] + d*h[d] = k`; i.e. `reflection-chains * size of reflection header + dapp-chains * size of dapp-chain headers = k`. We can use these two to obtain: `t = r*(k - r*h[r])/h[d]` (eliminating the variable `d`). we then get `dt/dr = k/h[d] - 2*r*h[r]/h[d]`. find the maximum at `dt/dr = 0` to yield `r = k/(2*h[r])` at maximum throughput. since `t = r*(k - r*h[r])/h[d] = rk/h[d] - r^2*h[r]/h[d]` we get `t[max] = k^2/(2*h[r]*h[d]) - k^2/(4*h[r]^2) * h[r]/h[d] = 2*k^2/(4*h[r]*h[d]) - k^2/(4*h[r]*h[d]) = k^2/(4*h[r]*h[d])`

$t_{max} = \frac{k^2}{4 \cdot h_r \cdot h_d}$

thus: the maximum number of dapp chains is given by $\frac{k^2}{4 \cdot h_r \cdot h_d}$.

\todo[inline]{This formula must be wrong, it doesn't sanity check. e.g. $k=3000; h_r=150; h_d=300$ yeilds $50$, which doesn't make sense. mb that's *per second* but even then that seems wrong. need to check units and derivation.}

#### Some numbers

NB: Ethereum's throughput is about 3000 bytes/sec maximum.

| throughput (bytes/sec) | $b_r$ ($s^{-1}$); set $b_r = b_d$ | $h_r$ (bytes) | $h_d$ (bytes) | avg tx size (bytes) | Eth2 tps estimate | UT tps |
|---|---|---|---|---|---|---|
| 3000 | $\frac{1}{60}$ | 500 | 500 | 200 | 5,400 | 486,000 |
||||||||
| 3000 | $\frac{1}{600}$ | 150 | 300 | 300 | 60,000 | 180,000,000 |

\todo[inline]{put below data into table}

at 3000 bytes/sec (Ethereum), 60s block times, geom avg 200 byte headers (`sqrt(h[r]*h[d])`), 500 byte avg tx size => UT can do 1,215,000 tps. With just dapp-chains (like polkadot, eth2, etc) those params would give 5,400 tps.

3000 bytes/sec, 60s block times, avg 500 byte headers, 200 byte txs => UT: 486,000 tps; Eth2: 5,400 tps.

(note that UT is v sensitive to header sizes; better to have smaller headers and larger txs if we get a choice)

3000 bytes/sec, 15s block times, avg 500 byte headers, 200 byte txs => UT: 30,375 tps; Eth2: 1,350 tps.

3000 bytes/sec, 150s block times, 500 byte headers, 500 byte txs => UT: 1,215,000 tps; Eth2: 5,400 tps.

3000 bytes/sec, 600s block times, 500 byte headers, 500 byte txs => UT: 19,440,000 tps; Eth2: 21,600 tps.
