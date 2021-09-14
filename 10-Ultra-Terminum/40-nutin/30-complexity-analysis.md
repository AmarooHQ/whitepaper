## Scaling Complexity Analysis of *Ultra Terminum*

\label{sec:ut-complexity}

\todo{review for references to PoS dapp-chains and update}

UT has two primary methods of scaling: reflection and dapp-chains. Reflection is novel. Dapp-chains are similar to many of the scaling ideas proposed for other networks (Polkadot, Eth2, etc), though there are fewer restrictions on dapp-chains in UT compared to other designs. Additionally, dapp-chains in UT are hosted by the simplex. This provides additional security compared to 'naked' PoS chains without sacrificing any of their other developments (e.g., finality), and provides greater capacity than a single host-chain.

A common method of sharding is to *nest* blockchains. For example, Ethereum 2 has a root-chain called *The Beacon Chain*.

\bquote{
    The Beacon Chain will conduct or coordinate the expanded network of shards and stakers. But it won't be like the Ethereum mainnet of today. It can't handle accounts or smart contracts.
}{\url{https://ethereum.org/en/eth2/beacon-chain/}}

This type of configuration, where a root-chain facilitates shards, is referred to as *nesting* in this section. The shards of Ethereum 2 are *a level of nesting* above the root-chain. Sometimes people use terms like *layer 2* to describe this sort of nesting, though such usage of *layer 2* is ambiguous and potentially misleading. It easily confuses nesting with off-chain scaling methods (such as payment channels or ephemeral 'child' blockchains, e.g., Plasma), and it potentially misleads readers about the security properties of nested blockchains. Nested blockchains *can* faithfully inherit the security properties of their parent-chains, which is not the case for layer 2 solutions. Furthermore, terms like *layer x* cannot accurately describe UT's design. Would UT's dapp-chains (having equal or better security properties than comparable chains like Ethereum 2, Polkadot, or Cardano) be *layer 1* or *layer 2*? It would be misleading to call them *layer 2* because UT dapp-chains have all the security qualities of other PoS chains, *and more*. If they were called *layer 1* chains, then what is the simplex -- *layer 0*? It is clear that the common idea behind *layer 1/2* scaling does not have sufficient capacity to accurately describe UT's simplex- and dapp-chains; it is inadequate.

The following derivations focus on *throughput* of particular blockchain designs and scaling configurations. Raw throughput of a network, $T_i$, is measured in bytes/sec (B/s) for some level of nesting, $i$. Note that $T_i$ directly corresponds to a design's maximum transactions per second (tps) via ${tps}_i = \nicefrac{T_i}{Tx_{avg}}$, where $Tx_{avg}$ is the average size of a transaction. The raw B/s throughput of a chain at the $i^{th}$ level of nesting is denoted by $k_i$. Note that $T_i$ is a *calculated* value, but $k_i$ is a *parameter* that may be chosen. An increase to $k_i$ is equivalent or similar to an increase in maximum block size.

Shown below are relationships between the number of chains at a level of nesting, $N_i$, and the network throughput at that level of nesting, $T_i$. For most existing blockchain designs, note that $N_1 = 1$.

Additionally, $O(k_i)$ is defined via $O(k_i) \equiv O(c)$.

### Complexity of $O(c)$ Chains

Example: Bitcoin.

The *raw throughput*, $k_1$, can be calculated for existing chains (e.g., Bitcoin) via the product of the maximum block size, $B_{max}$ (in bytes), and the block production frequency, $B_f$ (in hertz, or $s^{-1}$):

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

### Optimistic Complexity of $O(c^2)$ Chains

Examples: Ethereum 2, Polkadot.

Suppose the root-chain has a throughput of $k_1$ B/s and it can support up to $N_2$ nested chains. Those nested chains have headers of $D_h$ bytes that are produced at a frequency of $D_f$ ($s^{-1}$). Thus, each nested chain consumes \emph{at least} $D_f \cdot D_h$ B/s of the root-chain's capacity.

\todo{Add note about eth2 equivalent header-size, at least 256 bytes, not 200}

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

### Complexity of $O(c^2)$ Reflection

\todo{add note about excluding PoRs}

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

The optimal number of simplex-chains will maximize throughput. We can find that maxima via:

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

### Dapp-Chains and the Complexity of $O(c^3)$ and $O(c^4)$ UT

#### Dapp-Chains

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

#### UT with Dapp-Chains

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

#### UT with Dapp-Dapp-Chains

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

### Complexity of Cross-Chain SPV Proofs & Proofs of Reflection

#### Cross-Chain SPV Proofs

Each chain -- at full capacity -- operates with order $O(c)$ by definition. Thus its state has order $O(c)$ also. The size of SPV proofs scale logarithmically with the set you're proving membership of, e.g., the number of transactions, or size of the chain's state, etc. Thus, SPV proofs scale with order $O(\log_2 c)$.

For a given $O(c^j); j \in \{2,3,4\}$ configuration of UT, a chain can process SPV proofs of state on another chain. For $j = 4$, the furthest that a transaction can occur from its host simplex-chain is in the 3rd level of nesting (i.e., a dapp-dapp-chain). It would require $j-1$ SPV proofs to \`\`ascend'' from the host simplex-chain to a dapp-dapp-chain. However, given that full nodes of a dapp-dapp-chain are required to be full nodes of both the host dapp-chain and the host simplex-chain, transactions in that dapp-dapp-chain do not need to provide SPV proofs of state in either of those host chains -- full nodes already have those details. That is: transactions which \`\`descend'' the levels of nesting can do so with $O(1)$ cost. SPV proofs are only required when transactions \`\`ascend'' the levels of nesting to other simplex-, dapp-, or dapp-dapp-chains.

Thus, the maximum number of SPV proofs required to prove state anywhere in a UT simplex is $j$.

Since $j$ is constant, cross-chain SPV proofs therefore have order:

\begin{equation}
O(j \cdot \log_2 c) = O(\log_2 c) \label{eq:spv-complexity}
\end{equation}

#### Proofs of Reflection

\label{sec:complexity-reflection-proof}

A simplex-chain reflects $N_1 - 1 \approx N_1$ other simplex-chains. A merkle tree of reflected headers has order $O(N_1) = O(k_1) = O(c)$ and a corresponding proof size of order $O(\log_2 N_1) = O(\log_2 k_1) = O(\log_2 c)$. Since those other simplex-chains also have $\sim N_1$ reflections, proving reflection in those other $\sim N_1$ simplex-chains requires $\sim N_1$ merkle branches. Thus, the full set of reflection proofs, per simplex-chain, is $O(N_1 \cdot \log_2 N_1) = O(c \cdot \log_2 c)$.

Note: In a production system, these proofs can be excluded from blocks by treating them as droppable witnesses; see \autoref{sec:proving-reflection}.

### TPS Complexity Comparison

$k$: raw per-chain throughput (bytes/$s$) \newline
$B_f$: simplex block frequency ($s^{-1}$) \newline
$B_h$: simplex block header size (bytes) \newline
$D_f = B_f$: dapp-chain block frequency ($s^{-1}$) \newline
%% $D_h = B_h$: dapp-chain block header size (bytes) \newline
\begin{comment}
$Tx_{avg}$: average tx size (bytes)
\end{comment}

NB: For the purposes of the following table, the average transaction size is taken to be 250 bytes.
%% Additionally, the discrepancy in header size (between $B_h$ and $D_h$) is due to the overhead of PoS mechanisms.

| $k$, $B_f$, $B_h$, $D_h$             | $O(c)$ | Sharded $O(c^2)$ | $\UT{1}$            | $\UT{2}$             | $\UT{3}$             |
|------|---|------|----|----|----|
| $1000, \nicefrac{1}{15}, 23, 84$     | 4      | 714                 | 652                 | 116,460              | $2.08\times 10^{7}$  |
| $1000, \nicefrac{1}{15}, 32, 84$     | 4      | 714                 | 469                 | 83,705               | $1.49\times 10^{7}$  |
| $1000, \nicefrac{1}{15}, 84, 84$     | 4      | 714                 | 179                 | 31,888               | $5.69\times 10^{6}$  |
| $1000, \nicefrac{1}{15}, 112, 112$   | 4      | 536                 | 134                 | 17,937               | $2.40\times 10^{6}$  |
| $3000, \nicefrac{1}{15}, 23, 84$     | 12     | 6,429               | 5,870               | $3.14\times 10^{6}$  | $1.68\times 10^{9}$  |
| $3000, \nicefrac{1}{15}, 32, 84$     | 12     | 6,429               | 4,219               | $2.26\times 10^{6}$  | $1.21\times 10^{9}$  |
| $3000, \nicefrac{1}{15}, 84, 84$     | 12     | 6,429               | 1,607               | 860,969              | $4.61\times 10^{8}$  |
| $3000, \nicefrac{1}{15}, 112, 112$   | 12     | 4,821               | 1,205               | 484,295              | $1.95\times 10^{8}$  |
| $30000, \nicefrac{1}{15}, 112, 112$  | 120    | 482,143             | 120,536             | $4.84\times 10^{8}$  | $1.95\times 10^{12}$ |
| $1000, \nicefrac{1}{30}, 112, 112$   | 4      | 1,071               | 268                 | 71,747               | $1.92\times 10^{7}$  |
| $3000, \nicefrac{1}{30}, 112, 112$   | 12     | 9,643               | 2,411               | $1.94\times 10^{6}$  | $1.56\times 10^{9}$  |
| $30000, \nicefrac{1}{30}, 112, 112$  | 120    | 964,286             | 241,071             | $1.94\times 10^{9}$  | $1.56\times 10^{13}$ |
| $1000, \nicefrac{1}{60}, 112, 112$   | 4      | 2,143               | 536                 | 286,990              | $1.54\times 10^{8}$  |
| $3000, \nicefrac{1}{60}, 112, 112$   | 12     | 19,286              | 4,821               | $7.75\times 10^{6}$  | $1.25\times 10^{10}$ |
| $30000, \nicefrac{1}{60}, 112, 112$  | 120    | $1.93\times 10^{6}$ | 482,143             | $7.75\times 10^{9}$  | $1.25\times 10^{14}$ |
| $1000, \nicefrac{1}{600}, 112, 112$  | 4      | 21,429              | 5,357               | $2.87\times 10^{7}$  | $1.54\times 10^{11}$ |
| $3000, \nicefrac{1}{600}, 112, 112$  | 12     | 192,857             | 48,214              | $7.75\times 10^{8}$  | $1.25\times 10^{13}$ |
| $30000, \nicefrac{1}{600}, 112, 112$ | 120    | $1.93\times 10^{7}$ | $4.82\times 10^{6}$ | $7.75\times 10^{11}$ | $1.25\times 10^{17}$ |
| $3000, \nicefrac{1}{30}, 200, 200$   | 12     | 5,400               | 1,350               | 607,500              | $2.73\times 10^{8}$  |
| $3000, \nicefrac{1}{30}, 500, 500$   | 12     | 2,160               | 540                 | 97,200               | $1.75\times 10^{7}$  |
| $3000, \nicefrac{1}{30}, 1000, 1000$ | 12     | 1,080               | 270                 | 24,300               | $2.19\times 10^{6}$  |
| $3000, \nicefrac{1}{30}, 1500, 1500$ | 12     | 720                 | 180                 | 10,800               | 648,000              |

: A comparison of the maximum transaction throughput (transactions per second) given different scaling configurations. Note that the \emph{Sharded $O(c^2)$} column is optimal if all headers are recorded in the base-chain.

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

It is clear that $\Delta S$ has order $O(c^2)$, but how bad is this? For $k_1 = 3000$, $B_f = \frac{1}{60}$, and $B_h = 112$: $\Delta S \approx 2.4$ MB/s. With those figures: $N_1 \approx 800$ simplex-chains, $N_2 \approx 645,000$ dapp-chains, and maximum tps of $\sim 7.7\times 10^{6}$. Decreasing block times to 15s correspondingly decrease the bandwidth requirements to 0.6 MB/s for a simplex with $\sim 200$ chains, $\sim 40,000$ dapp-chains, and $\sim 484,000$ max tps.

While $O(c^2)$ bandwidth scaling is not ideal, it's clear that -- especially in the early days of a UT simplex when there are fewer simplex-chains -- there are tolerable configurations available.

| $k$, $B_f$, $B_h$, $D_h$             | $N_1$ ($\UT{1}$) | $N_2$ ($\UT{2}$)    | $N_3$ ($\UT{3}$)     | $\Delta S$          |
|------|----|-----|-----|-----|
| $1000, \nicefrac{1}{15}, 23, 84$     | 326              | 29,115              | $5.20\times 10^{6}$  | 326,087             |
| $1000, \nicefrac{1}{15}, 32, 84$     | 234              | 20,926              | $3.74\times 10^{6}$  | 234,375             |
| $1000, \nicefrac{1}{15}, 84, 84$     | 89               | 7,972               | $1.42\times 10^{6}$  | 89,286              |
| $1000, \nicefrac{1}{15}, 112, 112$   | 67               | 4,484               | 600,565              | 66,964              |
| $3000, \nicefrac{1}{15}, 23, 84$     | 978              | 262,034             | $1.40\times 10^{8}$  | $2.93\times 10^{6}$ |
| $3000, \nicefrac{1}{15}, 32, 84$     | 703              | 188,337             | $1.01\times 10^{8}$  | $2.11\times 10^{6}$ |
| $3000, \nicefrac{1}{15}, 84, 84$     | 268              | 71,747              | $3.84\times 10^{7}$  | 803,571             |
| $3000, \nicefrac{1}{15}, 112, 112$   | 201              | 40,358              | $1.62\times 10^{7}$  | 602,679             |
| $30000, \nicefrac{1}{15}, 112, 112$  | 2,009            | $4.04\times 10^{6}$ | $1.62\times 10^{10}$ | $6.03\times 10^{7}$ |
| $1000, \nicefrac{1}{30}, 112, 112$   | 134              | 17,937              | $4.80\times 10^{6}$  | 133,929             |
| $3000, \nicefrac{1}{30}, 112, 112$   | 402              | 161,432             | $1.30\times 10^{8}$  | $1.21\times 10^{6}$ |
| $30000, \nicefrac{1}{30}, 112, 112$  | 4,018            | $1.61\times 10^{7}$ | $1.30\times 10^{11}$ | $1.21\times 10^{8}$ |
| $1000, \nicefrac{1}{60}, 112, 112$   | 268              | 71,747              | $3.84\times 10^{7}$  | 267,857             |
| $3000, \nicefrac{1}{60}, 112, 112$   | 804              | 645,727             | $1.04\times 10^{9}$  | $2.41\times 10^{6}$ |
| $30000, \nicefrac{1}{60}, 112, 112$  | 8,036            | $6.46\times 10^{7}$ | $1.04\times 10^{12}$ | $2.41\times 10^{8}$ |
| $1000, \nicefrac{1}{600}, 112, 112$  | 2,679            | $7.17\times 10^{6}$ | $3.84\times 10^{10}$ | $2.68\times 10^{6}$ |
| $3000, \nicefrac{1}{600}, 112, 112$  | 8,036            | $6.46\times 10^{7}$ | $1.04\times 10^{12}$ | $2.41\times 10^{7}$ |
| $30000, \nicefrac{1}{600}, 112, 112$ | 80,357           | $6.46\times 10^{9}$ | $1.04\times 10^{15}$ | $2.41\times 10^{9}$ |
| $3000, \nicefrac{1}{30}, 200, 200$   | 225              | 50,625              | $2.28\times 10^{7}$  | 675,000             |
| $3000, \nicefrac{1}{30}, 500, 500$   | 90               | 8,100               | $1.46\times 10^{6}$  | 270,000             |
| $3000, \nicefrac{1}{30}, 1000, 1000$ | 45               | 2,025               | 182,250              | 135,000             |
| $3000, \nicefrac{1}{30}, 1500, 1500$ | 30               | 900                 | 54,000               | 90,000              |

: UT's capacity and bandwidth requirements: $N_1, N_2, N_3, \text{and}\;\Delta S$ for various parameters.

### The Impact of Header Size

\label{sec:impact-of-header-size}

\autoref{eq:throughput-iter} shows that UT's throughput is inversely proportional to the size of headers, $D_h$, for that given depth of nesting (this is true for $O(c^2)$ UT configurations, too). It also shows that throughput is inversely proportional to the block frequency, $D_f$, and proportional to chosen raw throughput, $k$.

Of these three values (header size, block frequency, and raw throughput), header size is the only value we *cannot* choose arbitrarily. To maintain overall throughput, doubling the header size requires one of: halving the block production frequency (i.e., doubling the block target time), or doubling the chain's raw throughput, or some combination of those two options. One such combination would be to decrease the block production frequency by a factor of $\frac{1}{\sqrt{2}}$ and increase the raw throughput by a factor of $\sqrt{2}$.

Changing all header sizes by some factor has different effects for different UT configurations. For $O(c^2)$ configurations of UT, the effect on throughput is linearly proportional to the factor; doubling the header sizes reduces overall throughput by a factor of 2. However, for the $O(c^3)$ configuration of UT, the effect is quadratically proportional to the factor; doubling the header sizes will reduce overall throughput by a factor of 4! The relationship is even worse for the $O(c^4)$ configuration of UT, where the effect is cubicly proportional.

It is worth noting, though, that different header schemes can be used in each level of nesting. This means that if, say, dapp-chains need larger headers than simplex-chains, then there isn't a negative effect on the capacity of the simplex (i.e., the level(s) beneath).

This effect is not unique to UT, though. In general, any system of sharding is also affected in this manner when the headers of a child-chain are included in the parent-chain's blocks.

Practically, this effect means that a decrease to the size of headers has *increasing* marginal benefit. Compared to $O(c)$ blockchains (e.g., Bitcoin), efficient header schemes are far more important for UT and sharded blockchain networks.

### Optimizations

\todo{present TPS and $N_x$ numbers using header-omission and hash-compression optimizations as mentioned in \autoref{sec:exploiting-seg-state}}

#### Impact on the Impact of Header Size

\todo{headers at base layer don't matter now -- only for nesting -- so PoS chains (even with big headers) might be okay at base layer without impacting scalability}
