## Scaling Complexity Analysis of *Ultra Terminum*

\label{sec:ut-complexity}

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
T_2 & = \frac{k_1 \cdot k_2}{D_f \cdot D_h} \\
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

\todo[inline]{insert maths}

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

### Complexity of SPV proofs

\todo[inline]{I refactored the equations in this section to use $j$ instead of $i$ as the exponent of $c$. LMK if there are any $i$s left around.}

Each chain -- at full capacity -- operates with order $O(c)$ by definition. Thus its state has order $O(c)$ also. The size of SPV proofs scale logarithmically with the set you're proving membership of, e.g. the number of transactions, or size of the chain's state, etc. Thus, SPV proofs scale with order $O(\log_2 c)$.

For a given $O(c^j); j \in \{2,3,4\}$ configuration of UT, a chain can process SPV proofs of state on another chain. For $j = 4$, the furthest that a transaction can occur from its host simplex-chain is in the 3rd level of nesting (i.e. a dapp-dapp-chain). It would require $j-1$ SPV proofs to "ascend" from the host simplex-chain to a dapp-dapp-chain. However, given that full nodes of a dapp-dapp-chain are required to be full nodes of both the host dapp-chain and the host simplex-chain, transactions in that dapp-dapp-chain do not need to provide SPV proofs of state in either of those host chains -- full nodes already have those details. That is: transactions which "descend" the layers of nesting can do so with $O(1)$ cost. SPV proofs are only required when transactions "ascend" the layers of nesting to other simplex-, dapp-, or dapp-dapp-chains.

Thus, the maximum number of SPV proofs required to prove state anywhere in a UT simplex is $j$.

Since $j$ is constant, cross-chain SPV proofs therefore have order:

\begin{equation}
O(j \cdot \log_2 c) = O(\log_2 c) \label{eq:spv-complexity}
\end{equation}

### Complexity comparison

$k$: raw per-chain throughput (bytes/$s$) \newline
$B_f$: simplex block frequency ($s^{-1}$) \newline
$B_h$: simplex block header size (bytes) \newline
$D_f$: dapp-chain block frequency ($s^{-1}$) \newline
$D_h$: dapp-chain block header size (bytes) \newline
%% $Tx_{avg}$: average tx size (bytes)

NB: For the purposes of the following table, the average transaction size is taken to be 250 bytes.

| $k$, $B_f$, $D_f$, $B_h$, $D_h$ | $O(c)$ tps | $O(c^2)$ tps | $O(c^3)$ UT tps | $O(c^4)$ UT tps |
|---|---|---|---|---|
| 1000, 1/15, 1/15, 112, 250 | 4 | 240 | 8,036 | 482,143 |
| 3000, 1/15, 1/15, 112, 250 | 12 | 2,160 | 216,964 | $3.9\times 10^{7}$ |
| 3000, 1/20, 1/40, 112, 250 | 12 | 5,760 | 771,429 | $3.7\times 10^{8}$ |
| 1000, 1/60, 1/60, 112, 250 | 4 | 960 | 128,571 | $3.1\times 10^{7}$ |
| 3000, 1/60, 1/60, 200, 500 | 12 | 4,320 | 972,000 | $3.5\times 10^{8}$ |
| 3000, 1/60, 1/60, 112, 500 | 12 | 4,320 | $1.7\times 10^{6}$ | $6.2\times 10^{8}$ |
| 3000, 1/60, 1/60, 200, 250 | 12 | 8,640 | $1.9\times 10^{6}$ | $1.4\times 10^{9}$ |
| 3000, 1/60, 1/60, 112, 250 | 12 | 8,640 | $3.5\times 10^{6}$ | $2.5\times 10^{9}$ |
| 26000, 1/60, 1/60, 200, 200 | 104 | 811,200 | $1.6\times 10^{9}$ | $1.2\times 10^{13}$ |
| 26000, 1/60, 1/60, 112, 200 | 104 | 811,200 | $2.8\times 10^{9}$ | $2.2\times 10^{13}$ |
| 1000, 1/600, 1/600, 112, 250 | 4 | 9,600 | $1.3\times 10^{7}$ | $3.1\times 10^{10}$ |
| 3000, 1/600, 1/600, 200, 250 | 12 | 86,400 | $1.9\times 10^{8}$ | $1.4\times 10^{12}$ |
| 3000, 1/600, 1/600, 112, 250 | 12 | 86,400 | $3.5\times 10^{8}$ | $2.5\times 10^{12}$ |
| 26000, 1/600, 1/600, 200, 200 | 104 | $8.1\times 10^{6}$ | $1.6\times 10^{11}$ | $1.2\times 10^{16}$ |
| 26000, 1/600, 1/600, 112, 200 | 104 | $8.1\times 10^{6}$ | $2.8\times 10^{11}$ | $2.2\times 10^{16}$ |
| 1000, 1/60, 1/600, 112, 250 | 4 | 9,600 | $1.3\times 10^{6}$ | $3.1\times 10^{9}$ |
| 3000, 1/60, 1/600, 112, 250 | 12 | 86,400 | $3.5\times 10^{7}$ | $2.5\times 10^{11}$ |
| 26000, 1/60, 1/600, 112, 250 | 104 | $6.5\times 10^{6}$ | $2.3\times 10^{10}$ | $1.4\times 10^{15}$ |
| 3000, 1/60, 1/60, 500, 500 | 12 | 4,320 | 388,800 | $1.4\times 10^{8}$ |
| 3000, 1/60, 1/60, 500, 700 | 12 | 3,086 | 277,714 | $7.1\times 10^{7}$ |

\todo[inline]{add figure of graphs of $B_f$ a/or $D_f$ vs tps, $B_h$ a/or $D_h$ vs tps, tx-size vs tps, k vs tps}

### Bandwidth Complexity

\todo[inline]{bandwidth requirement presuming all simplex blocks downloaded (to ensure availability)}

### The Impact of Header Size

\todo[inline]{UT is sensitive to header-size}

\autoref{eq:throughput-iter} shows that UT's throughput is inversely proportional to the size of headers, $D_h$, for that given depth of nesting (this is true for $O(c^2)$ configurations, too). It also shows that throughput is inversely proportional to the block frequency, $D_f$, and proportional to chosen raw throughput, $k$.

Of these three values, header size is the only value we *cannot* choose arbitrarily. To maintain overall throughput, doubling the header size requires one of: halving the block production frequency (i.e. doubling the block target time), or doubling the chain's raw throughput, or some combination of those two options. One such combination would be to decrease the block production frequency by a factor of $\frac{1}{\sqrt{2}}$ and increase the raw throughput by a factor of $\sqrt{2}$.

Changing all header sizes by some factor has different effects for different UT configurations. For $O(c^2)$ configurations of UT, the effect on throughput is linearly proportional to the factor; doubling the header sizes reduces overall throughput by a factor of 2. However, for the $O(c^3)$ configuration of UT, the effect is quadratically proportional to the factor; doubling the header sizes will reduce overall throughput by a factor of 4! The relationship is even worse for the $O(c^4)$ configuration of UT, where the effect is cubicly proportional.

It is worth noting, though, that different header schemes can be used in each level of nesting. This means that if, say, dapp-chains need larger headers than simplex-chains, then there isn't a negative affect on the capacity of the simplex (i.e. the layer(s) beneath).

This effect is not unique to UT, though. In general, any system of sharding is affected in this manner when the headers of a child-chain are included in the parent-chain's blocks.

Practically, this effect means that a decrease to the size of headers has *increasing* marginal benefit. Compared to $O(c)$ blockchains (e.g. Bitcoin), efficient header schemes are far more important for sharded blockchain networks.
