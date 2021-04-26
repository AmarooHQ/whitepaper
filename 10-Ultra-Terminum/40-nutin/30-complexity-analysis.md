## Scaling Complexity Analysis of *Ultra Terminum*

\label{sec:ut-complexity}

UT has two primary methods of scaling: reflection and dapp-chains. Reflection is novel. Dapp-chains are similar to many of the scaling ideas proposed for other networks (Polkadot, Eth2, etc), though there are fewer restrictions on dapp-chains in UT compared to other designs. Additionally, dapp-chains in UT are hosted by the simplex. This provides additional security compared to 'naked' PoS chains without sacrificing any of their other developments (e.g. finality), and provides greater capacity than a single host-chain.

A common method of sharding is to *nest* blockchains. For example, Ethereum 2 has a root-chain called *The Beacon Chain*.

\bquote{
    The Beacon Chain will conduct or coordinate the expanded network of shards and stakers. But it won't be like the Ethereum mainnet of today. It can't handle accounts or smart contracts.
}{\url{https://ethereum.org/en/eth2/beacon-chain/}}

This type of configuration, where a root-chain facilitates shards, is referred to as *nesting* in this section. The shards of Ethereum 2 are *a level of nesting* above the root-chain. Sometimes people use terms like *layer 2* to describe this sort of nesting, though such usage of *layer 2* is ambiguous and potentially misleading. It easily confuses nesting with off-chain scaling methods (such as payment channels or ephemeral 'child' blockchains, e.g., Plasma), and it potentially misleads readers about the security properties of nested blockchains. Nested blockchains *can* faithfully inherit the security properties of their parent-chains, which is not the case for layer 2 solutions. Furthermore, terms like *layer x* cannot accurately describe UT's design. Would UT's dapp-chains (having equal or better security properties than comparable chains like Ethereum 2, Polkadot, or Cardano) be *layer 1* or *layer 2*? It would be misleading to call them *layer 2* because UT dapp-chains have all the security qualities of other PoS chains, *and more*. If they were called *layer 1* chains, then what is the simplex -- *layer 0*? It is clear that the common idea behind *layer 1/2* scaling does not have sufficient capacity to accurately describe UT's simplex- and dapp-chains; it is inadequate.

\todo{look for references to 'layer2' and change to nesting as appropriate.}

The following derivations focus on *throughput* of particular blockchain designs and scaling configurations. Raw throughput of a network, $T_i$, is measured in bytes/sec (B/s) for some level of nesting, $i$. Note that $T_i$ directly corresponds to a design's maximum transactions per second (tps) via ${tps}_i = \nicefrac{T_i}{Tx_{avg}}$, where $Tx_{avg}$ is the average size of a transaction. The raw B/s throughput of a chain at the $i^{th}$ level of nesting is denoted by $k_i$. Note that $T_i$ is a *calculated* value, but $k_i$ is a *parameter* that may be chosen. An increase to $k_i$ is equivalent or similar to an increase in maximum block size.

Shown below are relationships between the number of chains at a level of nesting, $N_i$, and the network throughput at that level of nesting, $T_i$. For existing blockchain designs, note that $N_1 = 1$.

Additionally, $O(k_i)$ is defined via $O(k_i) \equiv O(c)$.

### Complexity of $O(c)$ chains

Example: Bitcoin.

The *raw throughput*, $k_1$, can be calculated for existing chains (e.g. Bitcoin) via the product of the maximum block size, $B_{max}$ (in bytes), and the block production frequency, $B_f$ (in hertz, or $s^{-1}$):

\begin{equation*}
k_1 = B_{max} \cdot B_f
\end{equation*}

Care should be taken to account for protocol extensions like *Segregated Witness* that effectively reduce the size of transactions (or, equivalently, increase the effective maximum block size).

The *throughput*, $T_1$, of an $O(c)$ chain is equivalent to its raw throughput:

\begin{equation*}
T_1 = k_1
\end{equation*}

The complexity order of the network is given by $O(T_1) = O(k_1) = O(c)$ as expected.

For Bitcoin, given $k_1 \approx 2000$ B/s (accounting for SegWit), and $Tx_{avg} = 500$ B, then

\begin{equation*}
{tps}_{Bitcoin,max} \approx \frac{2000}{Tx_{avg}} \approx 4
\end{equation*}

This is what we expect based on the measured real-world performance of Bitcoin.

### Optimistic Complexity of $O(c^2)$ chains

Examples: Ethereum 2, Polkadot.

Suppose the root-chain has a throughput of $k_1$ B/s and it can support up to $N_2$ nested chains. Those nested chains have headers of $D_h$ bytes that are produced at a frequency of $D_f$ ($s^{-1}$). Thus, each nested chain consumes $D_f \cdot D_h$ B/s of the root-chain's capacity.

$N_2$ is thus given by:

\begin{equation}
\label{eq:n2-for-c2-traditional}
N_2 = \frac{k_1}{D_f \cdot D_h}
\end{equation}

NB: For blockchains of this design: $N_1 = 1$.

If each nested chain has a throughput capacity of $k_2$ B/s, then:

\begin{equation}
\label{eq:t2-for-c2-traditional}
\begin{split}
T_2 & = \frac{k_1 \cdot k_2}{D_f \cdot D_h} \\
& \approx \frac{k^2}{D_f \cdot D_h}
\end{split}
\end{equation}

Thus $O(T_2) = O(c^2)$ as expected.

### Complexity of $O(c^2)$ reflection

There is no root-chain for a collection of mutually reflecting blockchains (i.e., a simplex), so $N_1 \neq 1$. In a simplex, each chain has $k_1$ B/s capacity, but this is split between reflections and transactions. At this foundational level (where there is no nesting yet), headers are $B_h$ bytes with a frequency of $B_f$ Hz. There are $N_1$ simplex chains.

Reflecting a single simplex-chain requires $B_f \cdot B_h$ B/s of capacity, and each simplex-chain must reflect $N_1 - 1 \approx N_1$ other simplex-chains. This means that a simplex-chain must reserve $N_1 \cdot B_f \cdot B_h$ B/s of its capacity for reflections, denoted by $k_{1,B} = N_1 \cdot B_f \cdot B_h$. Additionally, simplex-chains must reserve some capacity for transactions, $k_{1,tx}$.

Since simplex-chains must split their capacity between reflections and transactions, set:

\begin{equation}
\begin{split}
\label{eq:k1-reflection-defn}
k_1 & = k_{1,tx} + k_{1,B} \\
k_{1,tx} & = k_1 - k_{1,B}
\end{split}
\end{equation}

Given $k_{1,B} = N_1 \cdot B_f \cdot B_h$:

\begin{equation}
\label{eq:k-optimal}
k_{1,tx} = k_1 - N_1 \cdot B_f \cdot B_h
\end{equation}

Since each simplex-chain reserves $k_{1,tx}$ B/s for transactions, the total throughput reserved for transactions will be $N_1 \cdot k_{1,tx}$. Thus:

\begin{align}
T_1 & = N_1 \cdot k_{1,tx} \label{eq:reflection-t1-start} \\
& = N_1(k_1 - N_1 \cdot B_f \cdot B_h) \notag \\
& = N_1 \cdot k_1 - N_1^2 \cdot B_f \cdot B_h \label{eq:reflection-t1-in-terms-of-n1}
\end{align}

The optimal number of simplex-chains will maximize throughput. We can find that optimum via:

\begin{equation*}
\begin{split}
\frac{dT_1}{dN_1} & = k_1 - 2 \cdot N_1 \cdot B_f \cdot B_h
\end{split}
\end{equation*}

At $\frac{dT_1}{dN_1} = 0$:

\begin {equation}
\label{eq:simplex-N1}
\begin{split}
k_1 & = 2 \cdot N_1 \cdot B_f \cdot B_h \\
\therefore N_1 & = \frac{k_1}{2 \cdot B_f \cdot B_h}
\end{split}
\end {equation}

Thus $O(N_1) = O(k_1) = O(c)$.

From \autoref{eq:reflection-t1-in-terms-of-n1} and substituting $N_1$ from \autoref{eq:simplex-N1}:

\begin{equation}
\label{eq:simplex-T1}
\begin{split}
T_1 & = k_1 \cdot \frac{k_1}{2 \cdot B_f \cdot B_h} - B_f \cdot B_h \cdot \frac{k_1^2}{4 \cdot B_f^2 \cdot B_h^2} \\
& = \frac{2 k_1^2}{4 \cdot B_f \cdot B_h} - \frac{k_1^2}{4 \cdot B_f \cdot B_h} \\
& = \frac{k_1^2}{4 \cdot B_f \cdot B_h}
\end{split}
\end{equation}

Thus $O(T_1) = O(k_1^2) = O(c^2)$.

What are $k_{1,B}$ and $k_{1,tx}$ in terms of $k_1$? From \autoref{eq:reflection-t1-start} and \autoref{eq:simplex-T1}:

\begin{equation*}
\begin{split}
N_1 \cdot k_{1,tx} & = \frac{k_1^2}{4 \cdot B_f \cdot B_h}
\end{split}
\end{equation*}

Substituting $N_1$ from \autoref{eq:simplex-N1} gives:

\begin{equation*}
\begin{split}
\label{eq:k-tx-optimal}
\frac{k_1 \cdot k_{1,tx}}{2 \cdot B_f \cdot B_h} & = \frac{k_1^2}{4 \cdot B_f \cdot B_h} \\
k_{1,tx} & = \frac{k_1}{2}
\end{split}
\end{equation*}

Thus, from the definition of $k_1$ in \autoref{eq:k1-reflection-defn}:

\begin{equation*}
k_{1,B} = \frac{k_1}{2}
\end{equation*}

### Replacing Transactions with Dapp-Chains

If a system supports nested chains, then we can say that for some throughput, $T_i$, at nesting level $i$, that $(i+1)^{th}$ nesting level can support $N_{i+1}$ nested chains via:

\begin{equation}
\label{eq:N-i-plus-1-in-terms-of-Ti}
N_{i+1} = \frac{T_i}{D_f \cdot D_h}
\end{equation}

Therefore, via the same logic used for \autoref{eq:t2-for-c2-traditional}:

\begin{equation}
\label{eq:throughput-iter}
T_{i+1} = T_i \cdot \frac{k_{i+1}}{D_f \cdot D_h}
\end{equation}

Note that this relationship only holds for the traditional sharding model of securing sharded chains via their inclusion in a parent-chain, e.g., UT's dapp-chains and dapp-dapp-chains, or existing $O(c^2)$ designs.

Combining these yields:

\begin{equation}
\label{eq:simple-scaling}
N_{i+1} = \frac{T_{i+1}}{k_{i+1}}
\end{equation}

### Complexity of $O(c^3)$ UT

Starting with \autoref{eq:simplex-T1} and building on \autoref{eq:throughput-iter}:

\begin{equation}
\begin{split}
\label{eq:throughput-c-3}
T_1 & = \frac{k_1^2}{4 \cdot B_f \cdot B_h} \\
\therefore T_2 & = \frac{k_1^2 \cdot k_2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{split}
\end{equation}

Thus $O(T_2) = O(c^3)$.

The maximum number of dapp chains is given by:

\begin{equation*}
\begin{split}
N_2 & = \frac{T_2}{k_2} \\
& = \frac{k_1^2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{split}
\end{equation*}

### Complexity of $O(c^4)$ UT

If we say each dapp chain hosts shards or more dapp chains (such as Eth2 or Polkadot do), then via \autoref{eq:throughput-iter} and \autoref{eq:throughput-c-3},

\begin{equation}
\label{eq:throughput-c-4}
\begin{split}
T_3 & = \frac{T_2}{D_f \cdot D_h} \cdot k_3 \\
& = \frac{k_1^2 \cdot k_2 \cdot k_3}{4 \cdot B_f \cdot B_h \cdot D_f^2 \cdot D_h^2}
\end{split}
\end{equation}

Thus $O(T_3) = O(c^4)$.

Note that the derivation of $T_3$ presumes that the parameters $D_f$ and $D_h$ are the same for both dapp-chains and dapp-dapp-chains.

Via \autoref{eq:simple-scaling} and \autoref{eq:throughput-c-4}:

\begin{equation*}
\begin{split}
N_3 & = \frac{T_3}{k_3} \\
& = \frac{k_1^2 \cdot k_2}{4 \cdot B_f \cdot B_h \cdot D_h^2 \cdot D_f^2}
\end{split}
\end{equation*}

### Complexity of SPV proofs

Each chain -- at full capacity -- operates with order $O(c)$ by definition. Thus its state has order $O(c)$ also. The size of SPV proofs scale logarithmically with the set you're proving membership of, e.g. the number of transactions, or size of the chain's state, etc. Thus, SPV proofs scale with order $O(\log_2 c)$.

For a given $O(c^j); j \in \{2,3,4\}$ configuration of UT, a chain can process SPV proofs of state on another chain. For $j = 4$, the furthest that a transaction can occur from its host simplex-chain is in the 3rd level of nesting (i.e., a dapp-dapp-chain). It would require $j-1$ SPV proofs to "ascend" from the host simplex-chain to a dapp-dapp-chain. However, given that full nodes of a dapp-dapp-chain are required to be full nodes of both the host dapp-chain and the host simplex-chain, transactions in that dapp-dapp-chain do not need to provide SPV proofs of state in either of those host chains -- full nodes already have those details. That is: transactions which "descend" the layers of nesting can do so with $O(1)$ cost. SPV proofs are only required when transactions "ascend" the layers of nesting to other simplex-, dapp-, or dapp-dapp-chains.

Thus, the maximum number of SPV proofs required to prove state anywhere in a UT simplex is $j$.

Since $j$ is constant, cross-chain SPV proofs therefore have order:

\begin{equation}
O(j \cdot \log_2 c) = O(\log_2 c) \label{eq:spv-complexity}
\end{equation}

### Complexity of Proofs of Reflection

\label{sec:complexity-reflection-proof}

A simplex-chain reflects $N_1 - 1 \approx N_1$ other simplex-chains. A merkle tree of reflected headers has order $O(N_1) = O(k_1) = O(c)$ and a corresponding proof size of order $O(\log_2 N_1) = O(\log_2 k_1) = O(\log_2 c)$. Since those other simplex-chains also have $\sim N_1$ reflections, proving reflection in those other $\sim N_1$ simplex-chains requires $\sim N_1$ merkle branches. Thus, the full set of reflection proofs, per simplex-chain, is $O(N_1 \cdot \log_2 N_1) = O(c \cdot \log_2 c)$.

Note: In a production system, these proofs can be excluded from blocks by treating them as droppable witnesses; see \autoref{sec:proving-reflection}.

### Complexity comparison

$k$: raw per-chain throughput (bytes/$s$) \newline
$B_f$: simplex block frequency ($s^{-1}$) \newline
$B_h$: simplex block header size (bytes) \newline
$D_f$: dapp-chain block frequency ($s^{-1}$) \newline
$D_h$: dapp-chain block header size (bytes) \newline
\begin{comment}
$Tx_{avg}$: average tx size (bytes)
\end{comment}

NB: For the purposes of the following table, the average transaction size is taken to be 250 bytes.

| $k$, $B_f$, $D_f$, $B_h$, $D_h$ | $O(c)$ tps | $O(c^2)$ tps | $O(c^3)$ UT tps | $O(c^4)$ UT tps |
|--------|---|---|----|----|
| 1000, 1/15, 1/15, 112, 250 | 4 | 240 | 8,036 | 482,143 |
| 3000, 1/15, 1/15, 112, 250 | 12 | 2,160 | 216,964 | $3.9\times 10^{7}$ |
| 30000, 1/15, 1/15, 112, 250 | 120 | 216,000 | $2.2\times 10^{8}$ | $3.9\times 10^{11}$ |
| 1000, 1/60, 1/60, 112, 250 | 4 | 960 | 128,571 | $3.1\times 10^{7}$ |
| 3000, 1/60, 1/60, 112, 250 | 12 | 8,640 | $3.5\times 10^{6}$ | $2.5\times 10^{9}$ |
| 3000, 1/60, 1/60, 112, 500 | 12 | 4,320 | $1.7\times 10^{6}$ | $6.2\times 10^{8}$ |
| 3000, 1/60, 1/60, 200, 250 | 12 | 8,640 | $1.9\times 10^{6}$ | $1.4\times 10^{9}$ |
| 3000, 1/60, 1/60, 200, 500 | 12 | 4,320 | 972,000 | $3.5\times 10^{8}$ |
| 30000, 1/60, 1/60, 200, 200 | 120 | $1.1\times 10^{6}$ | $2.4\times 10^{9}$ | $2.2\times 10^{13}$ |
| 30000, 1/60, 1/60, 112, 200 | 120 | $1.1\times 10^{6}$ | $4.3\times 10^{9}$ | $3.9\times 10^{13}$ |
| 1000, 1/600, 1/600, 112, 250 | 4 | 9,600 | $1.3\times 10^{7}$ | $3.1\times 10^{10}$ |
| 3000, 1/600, 1/600, 200, 250 | 12 | 86,400 | $1.9\times 10^{8}$ | $1.4\times 10^{12}$ |
| 3000, 1/600, 1/600, 112, 250 | 12 | 86,400 | $3.5\times 10^{8}$ | $2.5\times 10^{12}$ |
| 30000, 1/600, 1/600, 200, 200 | 120 | $1.1\times 10^{7}$ | $2.4\times 10^{11}$ | $2.2\times 10^{16}$ |
| 30000, 1/600, 1/600, 112, 200 | 120 | $1.1\times 10^{7}$ | $4.3\times 10^{11}$ | $3.9\times 10^{16}$ |
| 1000, 1/60, 1/600, 112, 250 | 4 | 9,600 | $1.3\times 10^{6}$ | $3.1\times 10^{9}$ |
| 3000, 1/60, 1/600, 112, 250 | 12 | 86,400 | $3.5\times 10^{7}$ | $2.5\times 10^{11}$ |
| 30000, 1/60, 1/600, 112, 250 | 120 | $8.6\times 10^{6}$ | $3.5\times 10^{10}$ | $2.5\times 10^{15}$ |
| 3000, 1/60, 1/60, 500, 500 | 12 | 4,320 | 388,800 | $1.4\times 10^{8}$ |
| 3000, 1/60, 1/60, 500, 700 | 12 | 3,086 | 277,714 | $7.1\times 10^{7}$ |

\todo{add figure of graphs of $B_f$ a/or $D_f$ vs tps, $B_h$ a/or $D_h$ vs tps, tx-size vs tps, k vs tps}

### Bandwidth Complexity

\label{sec:bandwidth-complexity}

If miners temporarily keep the blocks of every simplex-chain (so that they can verify reflected headers correspond to existent blocks) then what is the complexity and burden of this?

Each simplex-chain has a raw throughput of $k_1$ bytes/s. From \autoref{eq:simplex-N1} we know that $N_1 = \frac{k_1}{2 \cdot B_f \cdot B_h}$. The amount of storage, $S$, required to keep $d$ seconds worth of each simplex-chain's history is equal to the product of: the number of simplex-chains -- $N_1$, the raw throughput of each chain -- $k_1$, and the duration we want to store -- $d$. Let $\Delta S$ be the bandwidth requirements (in bytes/s) to facilitate this.

\begin{equation}
\begin{split}
S & = \frac{k_1}{2 \cdot B_f \cdot B_h} \cdot k_1 \cdot d \\
& = \frac{k_1^2 \cdot d}{2 \cdot B_f \cdot B_h}  \label{eq:bandwidth-req} \\
\Delta S & = \frac{k_1^2}{2 \cdot B_f \cdot B_h}
\end{split}
\end{equation}

It is clear that $\Delta S$ has order $O(c^2)$, but how bad is this? For $k_1 = 3000$, $B_f = \frac{1}{60}$, and $B_h = 112$: $\Delta S \approx 4.8 \cdot 10^6$ bytes/s, or 4.8 MB/s. With those figures: $N_1 \approx 1600$ simplex-chains. Decreasing block times to 15s correspondingly decrease the bandwidth requirements to 1.2 MB/s for a simplex with $\sim 400$ chains.

While $O(c^2)$ bandwidth scaling is not ideal, it's clear that -- especially in the early days of a UT simplex when there are fewer simplex-chains -- there are tolerable configurations available.

### The Impact of Header Size

\autoref{eq:throughput-iter} shows that UT's throughput is inversely proportional to the size of headers, $D_h$, for that given depth of nesting (this is true for $O(c^2)$ configurations, too). It also shows that throughput is inversely proportional to the block frequency, $D_f$, and proportional to chosen raw throughput, $k$.

Of these three values, header size is the only value we *cannot* choose arbitrarily. To maintain overall throughput, doubling the header size requires one of: halving the block production frequency (i.e., doubling the block target time), or doubling the chain's raw throughput, or some combination of those two options. One such combination would be to decrease the block production frequency by a factor of $\frac{1}{\sqrt{2}}$ and increase the raw throughput by a factor of $\sqrt{2}$.

Changing all header sizes by some factor has different effects for different UT configurations. For $O(c^2)$ configurations of UT, the effect on throughput is linearly proportional to the factor; doubling the header sizes reduces overall throughput by a factor of 2. However, for the $O(c^3)$ configuration of UT, the effect is quadratically proportional to the factor; doubling the header sizes will reduce overall throughput by a factor of 4! The relationship is even worse for the $O(c^4)$ configuration of UT, where the effect is cubicly proportional.

It is worth noting, though, that different header schemes can be used in each level of nesting. This means that if, say, dapp-chains need larger headers than simplex-chains, then there isn't a negative effect on the capacity of the simplex (i.e., the level(s) beneath).

This effect is not unique to UT, though. In general, any system of sharding is also affected in this manner: when the headers of a child-chain are included in the parent-chain's blocks.

Practically, this effect means that a decrease to the size of headers has *increasing* marginal benefit. Compared to $O(c)$ blockchains (e.g. Bitcoin), efficient header schemes are far more important for UT and sharded blockchain networks.

\todo{(todo/polish) look for references to sharding and, if they are talking about UT, change to talk about UT and sharding or correct the wording.}
