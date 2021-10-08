%% BEGIN ### RELEASE

## Scaling Complexity Analysis of *Ultra Terminum*

\label{sec:ut-complexity}

\todoDraftOnly{review for references to PoS dapp-chains and update}

UT has two primary methods of scaling: reflection and dapp-chains. Reflection is novel. Dapp-chains are similar to many of the sharding and pseudo-sharding ideas proposed for other networks (Polkadot, Eth2, etc), though there are fewer restrictions on dapp-chains in UT compared to other designs. Additionally, dapp-chains in UT are hosted by the simplex. In the case of PoS dapp-chains, this provides \emph{additional} security compared to 'naked' PoS chains -- and without compromising on any other associated developments (e.g., finality). Hosting dapp-chains on simplex-chains also provides greater maximum capacity than a single base-chain can.

A common method of sharding is to *nest* blockchains. For example, Ethereum 2 has a root-chain called *The Beacon Chain*.

\bquote{
    The Beacon Chain will conduct or coordinate the expanded network of shards and stakers. But it won't be like the Ethereum mainnet of today. It can't handle accounts or smart contracts.
}{\url{https://ethereum.org/en/eth2/beacon-chain/}}

This type of configuration, where a base-chain facilitates child-chains, is referred to as *nesting* in this section. The shards of Ethereum 2 are *a level of nesting* above the Beacon Chain.

\defineTerm{Base-chain}{A chain that has no parent-chains; i.e., is at the base nesting level}

Sometimes (but not always) people use terms like *layer 2* to describe this sort of nesting, though such usage of *layer 2* is ambiguous and potentially misleading. It easily confuses nesting with off-chain scaling methods (such as payment channels or ephemeral 'child' blockchains, e.g., Plasma), and it potentially misleads readers about the security properties of nested blockchains. Nested blockchains *can* faithfully inherit the security properties of their parent-chains, which is not the case for layer 2 solutions.

Furthermore, terms like *layer x* cannot accurately describe UT's design. Consider a PoS dapp-chain on UT. Would that dapp-chain be *layer 1* or *layer 2*? It would be misleading to call them *layer 2* whilst comparable chains (like Ethereum 2, Polkadot, or Cardano) are called *layer 1*. Such UT dapp-chains have all the security qualities equivalent stand-alone PoS chains, *and more*. If they were called *layer 1* chains, then what is the simplex -- *layer 0*? It is clear that the common idea behind *layer 1/2* scaling does not have sufficient capacity to accurately describe UT's simplex- and dapp-chains; it is inadequate.

The following derivations focus on *throughput* of particular blockchain designs and scaling configurations. Raw throughput of a network, $T_i$, is measured in bytes/sec (B/s) for some level of nesting, $i$. Note that $T_i$ directly corresponds to a design's maximum transactions per second (TPS) via $\text{Tx}_{i} = \nicefrac{T_i}{\text{Tx}_{\text{avg}}}$, where $\text{Tx}_{\text{avg}}$ is the average size of a transaction. The raw B/s throughput of a chain at the $i^{\text{th}}$ level of nesting is denoted by $k_i$. Note that $T_i$ is a *calculated* value, but $k_i$ is a *parameter* that may be chosen. An increase to $k_i$ is equivalent or similar to an increase in maximum block size.

Shown below are relationships between the maximum number of chains at a level of nesting, $N_i$, and the maximum network throughput at that level of nesting, $T_i$. For most existing blockchain designs, note that $N_1 = 1$.

Additionally, $O(k_i)$ is \emph{defined} as $O(k_i) \equiv O(c)$.

### Complexity of $O(c)$ Chains

Example: Bitcoin.

The *raw throughput*, $k_1$, can be calculated for existing chains (e.g., Bitcoin) via the product of the maximum block size, $B_{\text{max}}$ (in bytes), and the block production frequency, $B_f$ (in hertz, or $s^{-1}$):

\begin{equation*}
k_1 = B_{\text{max}} \cdot B_f
\end{equation*}

The *throughput*, $T_1$, of an $O(c)$ chain is equivalent to its raw throughput:

\begin{equation*}
T_1 = k_1
\end{equation*}

The complexity order of the network is given by $O(T_1) = O(k_1) = O(c)$ as expected.

Care should be taken to account for protocol extensions like *Segregated Witness* that effectively reduce the size of transactions by $\nicefrac{1}{4}$.

For Bitcoin -- given $k_1 \approx 1700$ B/s, and transaction size $\text{Tx}_{\text{avg}} = 500 \cdot \nicefrac{3}{4}$ B -- the maximum TPS is given by:

\begin{equation*}
{\text{TPS}}_{\text{Bitcoin}} \approx \frac{1700}{\text{Tx}_{\text{avg}}} \approx 4.5
\end{equation*}

This is what we expect based on the measured real-world performance of Bitcoin.

### Optimistic Complexity of $O(c^2)$ Chains

Examples: Ethereum 2, Polkadot.

Suppose the root-chain has a throughput of $k_1$ B/s and it can support up to $N_2$ nested chains. Those nested chains have headers of $D_h$ bytes that are produced at a frequency of $D_f$ ($s^{-1}$). If \emph{all} headers of nested chains are recorded in the host chain, then each nested chain consumes \emph{at least} $D_f \cdot D_h$ B/s of the root-chain's capacity.

It's typical, though, that the headers of nested chains, alone, are not sufficient: additional data is required. For example, in an *Ethereum 2* beacon block, each shard has a header size of 280 B, but there is additional overhead, and a reasonable lower-bound is that each header uses a minimum of 312 B per beacon block[^eth2-dh]. In the case of *Polkadot*, it is [measurable](https://github.com/AmarooHQ/polkadot-effective-dh/blob/5cd0f0d21ff1cd3c57d1c2af70aaf6d8ee19dc11/main.js) that a minimum of 819 B is used in the `paraInclusion.candidateBacked` extrinsic (i.e., transaction), so a lower-bound on the effective header size of a parachain is 819 B (this does not include *bitfields*[^bitfields]).

In those situations, with regards to these complexity derivations, one can use the *effective* header size as a replacement for the *raw* header size.

[^eth2-dh]: The *current* Ethereum 2 [sharding spec](https://github.com/ethereum/consensus-specs/blob/296f9bab81566e2a11dd0ce3de806ff191e926bb/specs/sharding/beacon-chain.md#beaconblockbody) has capacity for 2:1 attestations to shards per block (with 64 shards), but only 32 B of each attestation is dedicated to sharding. The spec also has capacity for 4:1 shard headers to shards per block. It seems reasonable that capacity which exists will be used within reason. Thus a reasonable lower-bound for the effective header-size of shards is taken via: $1\times$ headers per shard per block, $1\times$ attestations per shard per block (which do not count towards effective header-size), and $1\times$ 32 B per attestation per block. Shards have headers of 280 B, so the minimum effective header size is taken to be 312 B. (note: a required dependency of the current sharding spec is the [current merge spec](https://github.com/ethereum/consensus-specs/blob/296f9bab81566e2a11dd0ce3de806ff191e926bb/specs/merge/beacon-chain.md#beaconblockbody) and [current phase0 spec](https://github.com/ethereum/consensus-specs/blob/296f9bab81566e2a11dd0ce3de806ff191e926bb/specs/phase0/beacon-chain.md).)

[^bitfields]: Bitfields is a Polkadot term -- it's a list of hundreds of signatures, totalling $> 14$ KB per block on the current Kusama testnet (October $3^{\text{rd}}$ 2021).

\begin{comment}
I think Eth2 sharding (wrt headers) has a larger effective Dh than we calculated before:

* attestations: 8 + 8 + 32 + 2*(8 + 32) + 32 + 96 = 256
  * https://github.com/ethereum/consensus-specs/blob/dev/specs/sharding/beacon-chain.md#attestationdata
* SignedShardBlobHeader: 96 + (8 * 4 + (48 + 8 + 48 + 32 + 8*2)) = 280
  * https://github.com/ethereum/consensus-specs/blob/dev/specs/sharding/beacon-chain.md#shard-work-status

Both are included in the BeaconBlockBody: https://github.com/ethereum/consensus-specs/blob/dev/specs/sharding/beacon-chain.md#beaconblockbody  (inherits from https://github.com/ethereum/consensus-specs/blob/dev/specs/merge/beacon-chain.md#beaconblockbody). The sharding spec for BeaconBlockBody has: shard_headers: List[SignedShardBlobHeader, MAX_SHARDS * MAX_SHARD_HEADERS_PER_SHARD] which seems to indicate that headers would be included every block (for every shard). note: MAX_SHARD_HEADERS_PER_SHARD=4

There's enough capacity for attestations (128 each block for 64 shards) that they could be done each block. That doesn't include any committee stuff.
\end{comment}

Thus, $N_2$ is given by:

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

### Complexity of $\UT{1}$

There is no single root-chain for a collection of mutually reflecting blockchains (i.e., a simplex), so $N_1 \neq 1$. What is $N_1$ then? In a simplex, each chain has $k_1$ B/s capacity, but this is split between reflections and transactions. At this foundational level (where there is no nesting yet), headers are $B_h$ bytes with a frequency of $B_f$ Hz. There are $N_1$ simplex chains.

For the purpose of \autoref{sec:ut-complexity} we will *not* be considering the impact of *explicitly* including PoRs along with block headers (i.e., the +PoRs UT variants).
The methods we use here are easily generalized to account for those variants, and associated analysis can be found in \autoref{sec:por-with-proofs}.

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
%% & = N_1(k_1 - (N_1 - 1) \cdot B_f \cdot B_h) \notag \\
& = N_1 \cdot k_1 - N_1^2 \cdot B_f \cdot B_h \label{eq:reflection-t1-in-terms-of-n1}
%% & = N_1 \cdot k_1 - N_1^2 \cdot B_f \cdot B_h + N_1 \cdot B_f \cdot B_h \label{eq:reflection-t1-in-terms-of-n1}
\end{align}

The optimal number of simplex-chains will maximize throughput. We can find that maxima via:

\begin{equation*}
\begin{split}
\frac{dT_1}{dN_1} & = k_1 - 2 \cdot N_1 \cdot B_f \cdot B_h
%% \frac{dT_1}{dN_1} & = k_1 - 2 \cdot N_1 \cdot B_f \cdot B_h - B_f \cdot B_h
\end{split}
\end{equation*}

At $\frac{dT_1}{dN_1} = 0$:

\begin {equation}
\label{eq:simplex-N1}
\begin{split}
k_1 & = 2 \cdot N_1 \cdot B_f \cdot B_h \\
%% k_1 - B_f \cdot B_h & = 2 \cdot N_1 \cdot B_f \cdot B_h \\
\therefore N_1 & = \frac{k_1}{2 \cdot B_f \cdot B_h}
%% \therefore N_1 & = \frac{k_1 - B_f \cdot B_h}{2 \cdot B_f \cdot B_h}
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

### Dapp-Chains and the Complexity of $\UT{2}$ and $\UT{3}$

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

Note that this relationship only holds for the traditional sharding model of securing sharded chains via their inclusion in a parent-chain, e.g., UT's dapp-chains ($\UT{2}$) and dapp-dapp-chains ($\UT{3}$), or existing $O(c^2)$ designs.

Combining these yields:

\begin{equation}
\label{eq:simple-scaling}
N_{i+1} = \frac{T_{i+1}}{k_{i+1}}
\end{equation}

#### UT with Dapp-Chains ($\UT{2}$)

Starting with \autoref{eq:simplex-T1} and building on \autoref{eq:throughput-iter}:

\begin{equation}
\begin{split}
\label{eq:throughput-c-3}
T_1 & = \frac{k_1^2}{4 \cdot B_f \cdot B_h} \\
\therefore T_2 & = \frac{k_1^2 \cdot k_2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{split}
\end{equation}

Thus $O(T_2) = O(c^3)$.

The maximum number of dapp-chains is given by:

\begin{equation*}
\begin{split}
N_2 & = \frac{T_2}{k_2} \\
& = \frac{k_1^2}{4 \cdot B_f \cdot B_h \cdot D_f \cdot D_h}
\end{split}
\end{equation*}

#### UT with Dapp-Dapp-Chains ($\UT{3}$)

If we say each dapp-chain hosts shards or more dapp-chains (e.g., as a dapp-chain version of Eth2 or Polkadot would), then via \autoref{eq:throughput-iter} and \autoref{eq:throughput-c-3},

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

For a given $O(c^j); j \in \{2,3,4\}$ configuration of UT (i.e., $\UT{1}$, $\UT{2}$, $\UT{3}$), a chain can process SPV proofs of state on another chain. For $j = 4$, the furthest that a transaction can occur from its host simplex-chain is in the 3rd level of nesting (i.e., a dapp-dapp-chain). It would require $j-1$ SPV proofs to \`\`ascend'' from the host simplex-chain to a dapp-dapp-chain. However, given that full nodes of a dapp-dapp-chain are required to be full nodes of both the host dapp-chain and the host simplex-chain, transactions in that dapp-dapp-chain do not need to provide SPV proofs of state in either of those host chains -- full nodes already have those details. That is: transactions which \`\`descend'' the levels of nesting can do so with $O(1)$ cost. SPV proofs are only required when transactions \`\`ascend'' the levels of nesting to other simplex-, dapp-, or dapp-dapp-chains.

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
$D_h = B_h$: dapp-chain block header size (bytes) \newline
\begin{comment}
$Tx_{avg}$: average tx size (bytes)
\end{comment}

NB: For the purposes of \autoref{table:tps}, the average transaction size is taken to be 250 bytes.
\begin{comment}
Additionally, the discrepancy in header size (between $B_h$ and $D_h$) is due to the overhead of PoS mechanisms.
\end{comment}

%% INSERT ### TABLE: tps

: A comparison of the maximum transaction throughput (transactions per second) given different scaling configurations. Note that the \emph{Sharded $O(c^2)$} column is optimal if all headers are recorded in the base-chain.

### Bandwidth Complexity

\label{sec:bandwidth-complexity}

\todoDraftOnly{
BW for full node: $\Delta s = k_1 + N_1 \cdot B_f \cdot g \cdot \log_2{N_1}$. BW for all headers (w/o header omission):
$N_1 \cdot B_h \cdot B_f = \frac{k_1 \cdot B_h \cdot B_f}{2 \cdot B_h \cdot B_f} = \frac{k_1}{2} = O(c)$
}

If miners temporarily keep the blocks of every simplex-chain (so that they can verify reflected headers correspond to existent blocks) then what is the complexity and burden of this? Each simplex-chain has a raw throughput of $k_1$ bytes/s. From \autoref{eq:simplex-N1} we know that $N_1 = \frac{k_1}{2 \cdot B_f \cdot B_h}$.

The amount of network bandwidth, $\Delta S$, required to download all blocks (as they are produced) across all simplex-chains is equal to the product of: the number of simplex-chains -- $N_1$, and the raw throughput of each chain -- $k_1$.

\begin{equation}
\begin{split}
\Delta S & = N_1 \cdot k_1 \\
& = \frac{k_1^2}{2 \cdot B_f \cdot B_h}
\label{eq:bandwidth-req}
\end{split}
\end{equation}

It is clear that $\Delta S$ has order $O(c^2)$, but how bad is this? For $k_1 = 3000$, $B_f = \frac{1}{60}$, and $B_h = 112$: $\Delta S \approx 2.4$ MB/s. With those figures: $N_1 \approx 800$ simplex-chains, $N_2 \approx 645,000$ dapp-chains, and maximum tps of $\sim 7.7\times 10^{6}$. Decreasing block times to 15s correspondingly decrease the bandwidth requirements to 0.6 MB/s for a simplex with $\sim 200$ chains, $\sim 40,000$ dapp-chains, and $\sim 484,000$ max tps.

While $O(c^2)$ bandwidth scaling is not ideal, it's clear that -- especially in the early days of a UT simplex when there are fewer simplex-chains -- there are tolerable configurations available.

%% INSERT ### TABLE: dapp-chains

: UT's capacity and bandwidth requirements: $N_1, N_2, N_3, \text{and}\;\Delta S$ for various parameters.

### The Impact of Header Size

\label{sec:impact-of-header-size}

\autoref{eq:throughput-iter} shows that UT's throughput is inversely proportional to the size of headers, $D_h$, for that given depth of nesting (this is true for $\UT{1}$, too). It also shows that throughput is inversely proportional to the block frequency, $D_f$, and proportional to chosen raw throughput, $k$.

Of these three values (header size, block frequency, and raw throughput), header size is the only value we *cannot* choose arbitrarily. To maintain overall throughput, doubling the header size requires one of: halving the block production frequency (i.e., doubling the block target time), or doubling the chain's raw throughput, or some combination of those two options. One such combination would be to decrease the block production frequency by a factor of $\nicefrac{1}{\sqrt{2}}$ and increase the raw throughput by a factor of $\sqrt{2}$.

Changing all header sizes by some factor has different effects for different UT configurations. For $\UT{1}$, the effect on throughput is linearly proportional to the factor; doubling the header sizes reduces overall throughput by a factor of 2. However, for $\UT{2}$, the effect is quadratically proportional to the factor; doubling the header sizes will reduce overall throughput by a factor of 4! The relationship is even worse for $\UT{3}$, where the effect is cubicly proportional.

It is worth noting, though, that different header schemes can be used in each level of nesting. This means that if, say, dapp-chains need larger headers than simplex-chains, then there isn't a negative effect on the capacity of the simplex (i.e., the level(s) beneath).

This effect is not unique to UT, though. In general, any system of sharding is also affected in this manner when the headers of a child-chain are included in the parent-chain's blocks.

Practically, this effect means that a decrease to the size of headers has *increasing* marginal benefit. Compared to $O(c)$ blockchains (e.g., Bitcoin), efficient header schemes are far more important for UT and sharded blockchain networks.

### Optimizations

\todoDraftOnly{present TPS and $N_x$ numbers using header-omission and hash-compression optimizations as mentioned in \autoref{sec:exploiting-seg-state}}

%% INSERT ### TABLE: tps_optimized

: TPS when using +HOT simplex optimizations (Header Omission and +T).

%% INSERT ### TABLE: dapp-chains_optimized

: Values of $N_i$, $\mathbb{C}^\prime$, and $\Delta S$ for a simplex using +HOT simplex optimizations.

%% END ### RELEASE

%% BEGIN ### DRAFT

#### Impact on the Impact of Header Size

\todo{headers at base layer don't matter now -- only for nesting -- so PoS chains (even with big headers) might be okay at base layer without impacting scalability}

%% END ### DRAFT

%% BEGIN ### RELEASE

### Comparison of UT Variants

\autoref{table:compare_optimizations} and \autoref{table:compare_optimizations2} show a comparison between UT variants. Note that the +PoRs variants are covered in \autoref{sec:por-with-proofs}.

%% INSERT ### TABLE: compare_optimizations

: Comparison of UT variants. Parameters are: $k = 3000$ B/s; $B_f = \nicefrac{1}{15}$; $B_h = 84$ bytes; 250 byte transactions. ``E. $B_h$'' means the \emph{effective} header-size.

%% INSERT ### TABLE: compare_optimizations2

: Comparison of UT variants. Parameters are: $k = 3000$ B/s; $B_f = \nicefrac{1}{15}$; $B_h = 84$ bytes; 250 byte transactions. The time to sync 5 years of a simplex-chain's history, including verifying PoRs ($\text{TTS}_{5yrs}$) is measured against a fully utilized 10 MB/s network connection and assumes no software bottlenecks. The equivalent for \emph{all} simplex-chains and PoRs being verified ($\Sigma$ $\text{TTS}_{5yrs}$) is also shown.

%% END ### RELEASE
