## Practical Considerations for UT's Design

\label{sec:practical-considerations}

### Availability of Reflected Blocks

\label{sec:availability-of-blocks}

What would happen if a header -- with valid PoW but *without* a valid block -- were to be reflected? That would mean that chain A contains a header, $H_{1a}$, for chain B for which no block is available. This does not break chain B, but it could mean that other blocks on chain B temporarily have a harder time competing, or waste the resources of chain B nodes as they go looking for that block, $B_{1a}$. Furthermore, it risks chain B miners doing SPV mining, which is bad.

After $H_{1a}$ is reflected, chain B miners shouldn't build on that header without validating the block. Eventually they'd produce a valid block, $B_{1b}$. But $B_{1b}$ (and it's header, $H_{1b}$) wouldn't be reflected yet. So $B_{1a}$ would have priority over $B_{1b}$ until $B_{2b}$ (building on $B_{1b}$) is created and both $H_{1b}$ and $H_{2b}$ are reflected. After that, a minor chain re-org would restore normality.

There is at least one way to ensure that reflected headers are available. That is: miners on both chain A and chain B should *refuse* to build on blocks that include headers without a known block. This would mean that the chain A block (which includes $H_{1a}$) is *invalid* on chain A while $B_{1a}$ is unavailable. If such a method is feasible, then the malicious chain A miner has greater opportunity cost to produce a block reflecting $H_{1a}$. Moreover, this method prevents chain A (and its miners) from contributing to a potential attack on chain B.

For this to work, though, miners must verify that blocks *exist* for all reflected headers. Is this practical if there are $10^3$ or $10^4$ reflected chains in a simplex? The miners are only required to do very small amounts of computation on these other blocks, so their computational capacity won't be a bottleneck here. Furthermore, they don't need to keep these other blocks indefinitely, just long enough to be confident that they reflect only headers with existent blocks. So they won't need much extra disk space, either -- after a few years, the history of a simplex chain will be larger than, say, the last 12 hours of all simplex-chains' histories combined. What miners will need is *bandwidth*.

The complexity and impact of this strategy is discussed in \autoref{sec:bandwidth-complexity}.

### Proving Reflection

\label{sec:proving-reflection}

If simplex-chains' consensus protocol requires accounting for reflected work, then nodes must have some method whereby they know which work (in a particular chain's history) has been reflected. That is: a node for chain A must be able to answer the question *For each other simplex-chain, which blocks in chain A's history have been reflected?* This means that each node must have $N_1 - 1$ answers for a simplex of $N_1$ chains.

There is a trivial method: include merkle branch proofs along with reflected headers. Specifically: when a miner on chain A includes a header from chain B, they should also include a merkle branch that shows the most recent chain A header that has been reflected by chain B. Miners would need to do this for *all* simplex-chains that they reflect. Predictably, this has overhead with order $O(N_1 \cdot \log_2 N_1)$, where $N_1$ is the number of chains in the simplex. This method has complexity $O(c \cdot \log_2 c)$ which is discussed in \autoref{sec:complexity-reflection-proof}.

Do we *need* to include proofs of reflection, though? Is it possible to avoid the explicit inclusion of those proofs, potentially allowing for $O(c)$ complexity instead?

If miners of any simplex-chain download the blocks of *all* simplex-chains -- as mentioned in \autoref{sec:availability-of-blocks} -- then including all necessary proofs of reflection can be made redundant. Since miners, theoretically, have all the necessary data to construct the proofs, do those miners need to actually include those proofs? Could we treat those proofs as witnesses and prune them -- similar to SegWit?

There would be some downsides to excluding the proofs of reflection. For one, it would mean that simplex-chain nodes, during an initial sync, would not be able to verify Proofs of Reflection without auxillary data -- potentially a lot. Secondly, it would mean that miners *must* track the state of *all* reflections in the simplex for some period of time so that they ensure the integrity of the reflection protocol. Given \autoref{sec:availability-of-blocks}, this is possible without significant overhead.

A practical method for treating proofs of reflection as witnesses that may be excluded/pruned is discussed in \autoref{sec:segmented-state}.

### Segmented State

\label{sec:segmented-state}

Traditionally, blockchain protocols have some *global* state and a state-transition function. For example, the Ethereum Yellow Paper says:

\bquote{
    Ethereum, taken as a whole, can be viewed as a transaction-based state machine: we begin with a genesis state and incrementally execute transactions to morph it into some current state. It is this current state which we accept as the canonical “version” of the world of Ethereum. \\
    \ldots \\
    A valid state transition is one which comes about through a transaction. Formally:
    \begin{equation*}
        \sigma_{t+1} \equiv \Upsilon(\sigma_t, T)
    \end{equation*}
    where $\Upsilon$ is the Ethereum state transition function.
}{Dr. Gavin Wood; \href{https://cloudflare-ipfs.com/ipfs/QmcdwaEqKjsASs1sZqxBNPw5vmypE5YL61zSvWdGoX7wtC}{Ethereum Yellow Paper / Petersburg Version 41c1837}, s2}

One of the reasons for this tradition is that transactions are (typically) permitted to depend on any part of the global state. For example: a Bitcoin transaction is permitted to spend any UTXO, and an Ethereum smart contract may interact with any other smart contract on the Ethereum blockchain.

However, it is not necessary for a protocol to allow *any and all* transactions to depend on global state. A protocol could specify that certain transactions may depend only on a strictly defined subset of global state, i.e., a well defined *segment* of global state that is independently calculable.

Simplex-chains can use this technique to their advantage by segmenting both transactions and state which are specific to Proofs of Reflection. That way, the state of a simplex-chain's reflections can be calculated without needing to calculate the remaining state for that simplex-chain.

We could specify the state-transition of simplex-chains (using Ethereum's nomenclature) like this:

\begin{equation}
\begin{split}
\label{eq:segregated-state}
\sigma_{R,t+1} & \equiv \Upsilon_R(\sigma_{R,t}, T) \\
\sigma_{\star,t+1} & \equiv \Upsilon_{\star}(\sigma_{R,t} + \sigma_{\star,t}, T)
\end{split}
\end{equation}

Where, at some time $t$: $\sigma_{R,t}$ is the segment of state that is tracking reflections and headers; $\sigma_{\star,t}$ is the global state excluding $\sigma_{R,t}$: $\Upsilon_R$ is the state-transition function for the reflections segment; and $\Upsilon_{\star}$ is the state transition function for all remaining segments. Note that if $T$ is a reflection-transaction (i.e., it contains headers to be reflected) then $\Upsilon_{\star}$ does nothing, and if $T$ is any other type of transaction then $\Upsilon_R$ does nothing.

In essence \autoref{eq:segregated-state} shows that $\sigma_{R,t}$ depends *only* on the $\sigma_{R,t-1}$ state-segment and the current transaction, whereas $\sigma_{\star,t}$ depends on global state.

If simplex-chains are segmented in this manner, then miners will be able to calculate the reflection-state of other simplex-chains without calculating their complete state. This would allow them to deterministically calculate proofs of reflection for all other simplex-chains.

Given that the reflection-segments of simplex-chains will contain mostly repeated data (i.e., headers), and that these segments will have very similar resultant state, there should be numerous optimizations that are possible. For example, it's not necessary for a miner's node to re-download reflected headers since it already has most (or all) of them; that node just needs to know *which* headers are reflected. This reduces the effective size of simplex-blocks from $b$ to $b \cdot (\frac{g + B_h}{2B_h})$, where $g$ is the size of the relevant digest in bytes. For $g=32; B_h=112$, this reduces effective block size to $\sim 0.643 b$ --- an improvement of $\sim 35\%$.

### Confirmation Times

\label{sec:confirmation-times}

A confirmation is a *discreet* event that occurs when a block is produced. When an attacker is performing a hash-rate based doublespend attack they are, effectively, racing the honest network; that race is measured in confirmations[^confirmation-race], not *time*.

\bquote{
    The probability of success [of a double-spend attempt] depends on the number of blocks [by which the honest network has an advantage], and not on the time constant $T_0$.
}{Meni Rosenfeld; \href{https://cloudflare-ipfs.com/ipfs/QmNUWmY94QUievK8ptoxsPyAQUsKvx1cjRyCgPcfmysAVv}{Analysis of hashrate-based double-spending}}

In a traditional blockchain (e.g., Bitcoin, Ethereum) confirmations occur at a predictable rate (that of the target block production frequency). Thus, for any *particular* traditional blockchain a convenient time-based \emph{rule of thumb} can be devised, e.g., a Bitcoin transaction is safe to accept after 1 hour. However, this approximation only works because blocks are only produced locally and at a constant rate. Put another way, the frequency of confirmations is identical to the frequency of blocks, $B_f$ Hz. Since $O(B_f) = O(1)$, the time-complexity of confirmation in these networks is also $O(1)$.

When using PoR, though, the assumptions behind that \emph{rule of thumb} do not hold -- while blocks on a single chain may be produced at a constant rate, that chain also gains a security benefit from other chains. For the case of a 2-chain simplex (where those chains have the same block production frequency), the rate of confirmations will be twice the rate of block production. This is easily generalized: for an $N_1$-simplex with simplex-chains that share some block frequency $B_f$, the rate of confirmation will be $N_1 \cdot B_f$ Hz. Thus, the rate of confirmations has complexity $O(N_1 \cdot B_f) = O(N_1) = O(c)$.

Let *confirmation time* be the duration breakpoint, above which a large enough number of confirmations have occurred to consider a transaction *safe*. This is equivalent to the *rule of thumb* mentioned earlier. For a traditional blockchain, as mentioned, this is the product of some constant and the expected duration between blocks: $B_f^{-1}$. For a simplex, though, the expected *duration* is $(N_1 \cdot B_f)^{-1}$. Thus, as the simplex grows -- as $N_1$ *increases* -- the entire network's rate of confirmations also increases, and thus *confirmation time* approaches 0[^approach-zero].

A 200-simplex with $B_f = \nicefrac{1}{15}$ has a confirmation rate of $\nicefrac{40}{3} \approx 13.3$ Hz. An 800-simplex with $B_f = \nicefrac{1}{60}$ has the same confirmation rate. This is $\sim 6.5\times$ faster than EOS, $\sim 200\times$ faster than Ethereum, and $\sim 8,000\times$ faster than Bitcoin.

[^approach-zero]: To say that confirmation time approaches 0 only tells the latter half of the process by which a transaction becomes confirmed. The first half of that process is *getting an initial confirmation*, which is effectively a constant overhead.

Note that PoR incents miners to publish blocks as soon as possible so that those blocks begin gaining reflections. If a miner does not publish a block immediately, then any competing block will start acquiring reflections first and thus hold an advantage over the withheld block. This mitigates the selfish mining[^selfish-mining] attack.

[^selfish-mining]: See \href{https://cloudflare-ipfs.com/ipfs/QmNukb1L8BhEsiCbrmnkEJWAvUjhBHidinKMZKfCaLG6ep}{Majority is not Enough: Bitcoin Mining is Vulnerable} by Ittay Eyal and Emin Gün Sirer.


### DoS and DAGs

\label{sec:dos-and-dags}

There are decisive advantages to using DAGs (instead of trees) as the fundamental structure of a chain. Namely, multiple histories (both compatible and incompatible) can be merged into a single, consistent history -- a feature which eliminates stale blocks and thwarts attacks like an empty-block Denial of Service[^empty-dos]. Although it's rare that I explicitly mention this, UT's simplex-chains must be block-DAGs to remain functional and avoid such DoS attacks.

[^empty-dos]: For an example of this attack, see \href{https://bitcointalk.org/index.php?topic=56675.msg678006\#msg678006}{Luke Jr's attack on Coiledcoin}.

#### Block-DAG Lineage

\label{sec:block-dag-lineage}

The idea that blocks in a chain can have multiple parents -- i.e., the chain forms a Directed Acyclic Graph (DAG) that is not also a tree -- dates back to (at least) late 2013[^ghost-dec-2013] with the publication of GHOST by Sompolinsky and Zohar. However, GHOST disallows multiple *canonical* parents, and a chain using GHOST defines its *canonical history* -- the *main chain* -- via the chain formed exclusively from the first parent of each block. A block's other, non-canonical parents are linked to *only* for the purpose of contributing to the total chain-weight.

In the two years after GHOST was published, a number of DAG-based blockchain designs were developed that facilitated merging histories from multiple parent blocks.

In mid-2014 I created a prototyped DAG-based blockchain called Quanta[^quanta-2014] with a novel method of linearization that converged to a complete and stable ordering of blocks. This method was independently rediscovered[^redisc] in mid-2015 by Lewenberg, Sompolinsky, and Zohar[^inclusive-july-2015] -- who also further developed and analysed the method, which they named *the inclusive protocol*. Additionally, in 2016 Paul Firth further developed Quanta in his *Trustless Eventual Total Order* draft[^teto-2016].

In late-2015 several new, alternative methods were also published, however these are not generalizations of Nakamoto consensus. Namely: Lerner's DagCoin[^dagcoin-sept-2015], and IOTA's Tangle[^iota-oct-2015]. Since then, multiple other models have been proposed, and some built.

For the purposes of this paper, we are concerned with the method detailed in *Inclusive Block Chain Protocols*.

[^ghost-dec-2013]: \href{https://cloudflare-ipfs.com/ipfs/QmTDz4WuAXi2rV7Ei3pHHKTFCYGPeDbDoAkmypkHdJnnKe}{Secure High-Rate Transaction Processing in Bitcoin} by Yonatan Sompolinsky and Aviv Zohar.

[^quanta-2014]: \href{https://github.com/XertroV/quanta-test/blob/ba598d5fe89d3b16db07533957a2080edb19a9cd/quanta.py\#L157}{Quanta source code}, \href{https://bitcointalk.org/index.php?topic=1057342}{Quanta BitcoinTalk thread}.

[^dagcoin-sept-2015]: \href{https://cloudflare-ipfs.com/ipfs/QmbXhgQzN8FPFLiJoVApHvT1vf3xZUGefvD5GdfYPHuBpe}{DagCoin Draft} by Sergio Demian Lerner.

[^iota-oct-2015]: \href{https://bitcointalk.org/index.php?topic=1216479.0}{IOTA BitcoinTalk thread}.

[^inclusive-july-2015]: \href{https://cloudflare-ipfs.com/ipfs/QmPb3oZBwyg1EJCR2CivnjTKWkf9UxhVbU8JByv6SW1pXy}{Inclusive Block Chain Protocols}.

[^redisc]: As far as I can tell, the linearization methods produce identical results.

[^teto-2016]: \href{https://github.com/wildbunny/docs/blob/master/T.E.T.O-draft.pdf}{T.E.T.O Draft} by Paul Firth.

#### Basic Structure

\begin{figure}[H]
    \begin{subfigure}[t]{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{dag_simple_sag}
        \caption{A simple 2-parent example of a block-dag segment.}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{dag_simple2_sag}
        \caption{A slightly more complex example of a block-dag segment.}
        \label{fig:dag-simple2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{dag_simple3_sag}
        \caption{A 3-parent example of a block-dag segment.}
    \end{subfigure}%%
    \caption{Some examples of simple block-dag segments.}
    \label{fig:dag-simple-segments}
\end{figure}

Some basic block-dag segments are shown in \autoref{fig:dag-simple-segments}. If the figures do not speak for themselves, then I suggest you revisit some of the material linked in \autoref{sec:block-dag-lineage}.

#### Preventing DoS Attacks

\label{sec:preventing-dos-attacks}

Consider the situation where an attacker is attempting to deny service via the production of empty blocks, and that the attacker can create blocks faster than the honest network. Such a situation is illustrated in \autoref{fig:dag-dos-1}. Since the goal of the attack is to prevent transactions from occurring, the attacker must[^nb-must] produce empty blocks[^empty-nb]. Furthermore, if the attacker links back to any honest blocks then the honest blocks' histories will be merged with the canonical history; thus the attack would fail. The attacker's only available strategy is to produce a single chain of empty blocks.

[^nb-must]: The attacker could also fill the blocks with spam transactions. That's more work for the attacker, but also more work for the honest network (calculating and storing that state, maybe indefinitely). It's preferable that the attacker has minimal transactions in their blocks. It's tempting to think of ideas like: \emph{since the attackers blocks are empty, we can let honest nodes make larger blocks via some kind of weighted average block size calculation plus some flexibility in the size of blocks produced}. The problem with this is that it incents the attacker to fill their blocks with spam transactions, which is counterproductive.

[^empty-nb]: Note that the attacker should still be reflecting other simplex-chains so as to maximize the total weight of the attacker's chain-segment. Given this, the attacker's blocks will contain reflected headers but no transactions.

\begin{figure}
    \centering
    \includegraphics[width=\linewidth]{dag_dos1_sag}
    \caption{An attempted DoS attack on a block-DAG. The attacker's blocks, $A_j$, contain no transactions. Each block is annotated with its \emph{chain-weight} ($\Sigma_w$). Even though the attacker produces $2\times$ as many blocks as the honest network, the attack inevitably fails after a short while. NB: $H_i$ is defined to have $\Sigma_w = 0$ for illustrative convenience.}
    \label{fig:dag-dos-1}
\end{figure}

How does such an attack fair? The challenge of such a DoS attack is to prevent honest miners from extending the attacker's chain-segment. For traditional (non-DAG) chains -- where each non-genesis block has exactly one parent -- this is accomplished as soon as the attacker is able to reliably produce a heavier chain-segment than the honest network for a given period. (Typically, this means the attacker produces blocks more frequently.) However, if blocks are allowed to have *more* than one parent then there *is no point* where an attacker can *maintain* a DoS attack indefinitely. Instead, they can only *delay the execution* of some transactions for a short period of time. Particularly, if an attacker can produce $A_{blocks} = \nicefrac{q}{p} > 1$ for every 1 block produced by the honest network, then the attack can delay transactions for up to $A_{blocks} \cdot B_f^{-1}$ seconds, where $B_f$ is the regulated frequency of block production (in Hz). After this point, the weight of the honest chain-segment (which includes the attacker's chain-segment) is always greatest.

However, if an attacker performs a *repeating cycle* of these attacks, then they may be able to decrease the effective capacity of the chain by a factor of $A_{blocks} = \nicefrac{q}{p}$. The opportunity cost of this attack (for the attacker) is the lost transaction fees.


### Qualities of Different Security Methods

\label{sec:quality-groups}

Consider these 3 categories of methods of securing a blockchain:

* PoW with ASICs
* PoW without ASICs (e.g., GPUs/CPUs; aka \`\`ASIC resistant'')
* PoS

PoW+ASICs means the miner-base is inflexible; they don't have many choices for where to point their ASICs. It's super high hash-rate, though, and has near-optimal thermodynamic security given the state of ASIC manufacturing (e.g., 5nm chips).

PoW+GPUs means the miner-base is super flexible; there are lots of choices for profitable chains to mine. They can pick and choose and have low overhead to doing so. They aren't near the limit for thermodynamic security, though. If relevant ASICs come along they'll always out-compete GPUs.

PoS has an inflexible miner base too -- most PoS schemes (e.g., DPoS, etc) require the miners to stake coins and that happens over a period of time. However, there is a sense where the thermodynamic security of PoS is high (provided ECDSAs and EC crypto keep working). There's another sense where the thermodynamic security of PoS is low: miners control their private keys and have near zero energy cost per signature. The former is irrelevant while the latter sense is true. That's the reason that PoS systems include mechanics like *slashing*.

\todo{Polish different qualities section + check questions are answered.}

So these methods of doing blockchain security all have different qualities. What does it mean for Amaroo, and how should the UT simplex be divided between these groups? Note: this assumes that there is a secure way to do PoS consensus.

UT's consensus is emergent from an *additive and collaborative* process. Adding more simplex-chains increases security incrementally, but if one simplex-chain fails (or is attacked) then it doesn't have magnified negative effects for the rest of the network (e.g., by causing a network-wide DoS). This means we can potentially add lots of different types of blockchain security, with different qualities, to create a platform where dapp-authors can *choose the desired qualities*.

Do they want a highly secure base-chain, but variance in block times isn't a problem? Then they should go with an ASIC-chain[^asic-variance]. Do they want a moderately secure base-chain, but with *low* variance in block times? Then go with a GPU-chain. Do they want a moderate-to-low security base-chain, but with regular (near-zero-variance) block times? Then go with a PoS/PoA-chain (at the simplex level).

[^asic-variance]: Note that simplex-chains with PoW algorithms for which there are ASICs can have lower variance, too, if there are multiple simplex-chains with that same algorithm.

### Lowering Block Production Variance

Is it possible to *dramatically* lower the variance of block production in PoW blockchains without altering incentive structures, compromising security, or changing the probability of generating a valid block?

Yes. The method relies on the *structure* of the network, rather than the consensus protocol itself. Particularly, the network must be structured such that miners' choices result in decreased block production variance --- an emergent phenomenon. It's important not to try and make it artificially (e.g., by increasing the block reward with time-since-last-block) because you don't want ppl to game the system. It's better to have a simple system with emergent properties than a complex system with those properties \`\`designed in''.

Say you have a network with 10 chains: $C_0, C_1, C_2, ..., C_9$. If the networks are separate, then you have 10 groups of miners: $M_0, M_1, M_2, ..., M_9$. They have to choose one chain to mine on, so the distribution of miners is expected approximate the distribution of normalized block rewards + tx fees. The proportions of block rewards between $C_i$ & $C_j$ don't really matter, we expect the mining groups $M_i$ & $M_j$ will just sort themselves out due to market forces. For simplicity, though, this example assumes that mining rewards and the distribution of miners is an even 10% across the board.

If the network has spare capacity (i.e., transactions are mostly cleared out with each block; the mempool for each chain is ~empty) then we have a situation like this:

Set $t=0$ to be immediately after a block is published on a chain. then, as $t$ progresses, transactions with fees should build up in the mempool, so $TxFees \propto t$. The reward for mining a block is $r + TxFees$ for some block reward, $r$. if $TxFees \propto t$ then $r + TxFees \propto K + t$ for some constant $K$.

The potential reward-over-time for a miner ($t$ vs $r + TxFees$) looks like a sawtooth function with a y-axis offset. It builds as more transactions pile up, and drops back to the baseline reward after a block.

If the miners $M_0, ..., M_9$ are capable of working on one of any $\{C_0, ..., C_9\}$ (and they have identical ROI profiles to the other miners), then they're incented to work on the chain with the most transactions in the mempool. That means: miners should, roughly, work the chain that has gone the longest without a block. What should we expect based on those incentives? Miners should work on each chain only in the final moments of the block production cycle. If block times were set to 60s, then they'd start mining at like the 54s mark b/c that's how they maximize their ROI.

Why wouldn't they just keep mining on the same chain? b/c in the time that they focused on one chain, another one passed that >54s high-ROI threshold and thus has the best ROI potential per hash done.

We should thus expect that this configuration of chains actually *synchronizes* miners, resulting in block production that is somewhat regular and lower in variance.

One reason that we can predict that transactions will build up in this fashion (with those fees and in a predictable way) is that most of the transactions that are included in simplex blocks will be dapp-chain-header-transactions. Since dapp-chains will use PoS, we should expect them to be predictable and regular.

The average hash rate on each simplex chain, as described above, is always the same regardless of which of the two miner strategies are used. However, the variance of block production on each of these chains won't be that of a chain with 60s block times, it'll be that of a chain with 6s block times.

### Reflection Censorship Attack

\todo{is a refl censorship attack possible? meaningful? explore.}
