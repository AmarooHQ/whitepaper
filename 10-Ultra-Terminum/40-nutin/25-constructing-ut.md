## Escape Velocity (Constructing UT)

\label{sec:constructing-ut}

*PoW reflection* can be used as a foundational technique to build an $O(c^2)$ base-layer for a blockchain network (which I call *the simplex*). This section details the construction of such a foundation, and how it can be extended up to $O(c^4)$ complexity. The $O(n)$ scaling configuration is detailed in \autoref{sec:tiling}.

Such a foundation (*the simplex*) is *not* a sharded blockchain -- there's no requirement that chains in this base-layer are either interchangeable or use the same primitives. This was demonstrated via the example in \autoref{sec:two-blockchains}. Rather, the simplex is an emergent construct that is created via the *relationships* between blockchains. Instead of one blockchain being split into many (as occurs with sharding), the simplex is many blockchains becoming one coherent network.

\todo[inline]{Should I summarize the section here? e.g.: this section will cover generalizing to N reflections, the simplex, dapp chains, then analysis. IDK, seems superfluous}

### Generalizing Reflection

\label{sec:generalizing-reflection}

*PoW reflection* is, in essence, the idea that a chain can acknowledge that its history has been confirmed by a different chain[^reflection-prior]. That is a simplification, but it is the essence of it.

[^reflection-prior]: I have not been able to find any existing discussion of this method. If you know of any existing discussion of this method, please post a link to the forum topic that is linked in the abstract.

In principle, the necessary capabilities that some chain, $C_A$, must have in order for it to be reflected by another chain, $C_B$, are:

1. The headers of $C_A$ can be freely recorded, unambiguously, in $C_B$;
2. The headers of $C_B$ can be freely recorded, unambiguously, in $C_A$;
3. $C_A$ is able to prove that its headers have been recorded in $C_B$, and has full knowledge of which headers have been recorded; and
4. $C_A$ integrates this knowledge into its chain-weighting algorithm.

If $C_A$ and $C_B$ are doing *mutual* PoW reflection, then the same conditions must be satisfied by $C_B$.

Is $C_A$ able to *simultaneously* do reflection with more than one other chain, e.g., $C_C ... C_Z$? Yes. There is nothing that we have covered so far that would prevent this. If *PoW reflection* is viable with one other foreign chain, then it is viable with *many* other foreign chains. However, the dynamics do becoming increasingly complex, as we will now see.

### The Simplex

\label{sec:the-simplex}

When two or more blockchains *mutually reflect* each-other, they form a *simplex*[^simplex-maths]. For the sake of brevity: all *reflections* within a simplex are *mutual reflections*, and I will omit *mutual* from now on when discussing them.

When a blockchain is part of a simplex, it is called a *simplex-chain* (as distinct from *dapp-chains*).

To maintain consistency with the geometric usage of the term *simplex*: a simplex with $k+1$ chains is called a $k$-simplex or a $(k+1)$-chain simplex[^simplex-approx]. In a $k$-simplex, each simplex-chain has $k$ reflections (one reflection for each of the other simplex-chains). A $k$-simplex has, in total, ${k+1} \choose 2$ reflections.

[^simplex-maths]: The name is taken from geometry (particularly the higher-dimensional kind). A simplex, for a given dimensionality, is the uniquely simplest polytope; e.g., a line in 1D space, a triangle in 2D space, a tetrahedron in 3D space, etc. A $k$-dimensional simplex is known as a $k$-simplex. As shown in \autoref{fig:simplexes}, the 2D projection of a $k$-simplex is identical to a diagram of all possible mutual reflections between $k+1$ blockchains, where each chain is represented by a vertex and each mutual reflection is represented by an edge.

[^simplex-approx]: \textbf{NB:} I will ignore this distinction for $k \gg 1$.

\begin{figure}
    \centering
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d1-many-tiled-2-simplexes}
        \caption{PoW reflection between 2 blockchains. A 1-simplex. The most basic non-trivial simplex.}
        \label{fig:simplex-2-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d1-many-tiled-7-simplexes}
        \caption{PoW reflection between 7 blockchains; a 7-chain simplex; a 6-simplex.}
        \label{fig:simplex-7-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d1-many-tiled-17-simplexes}
        \caption{A 17-chain simplex; a 16-simplex.}
        \label{fig:simplex-17-d1}
    \end{subfigure}
    \hfill
    \caption{Simplexes of increasing capacity. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
    \label{fig:simplexes}
\end{figure}

### Dapp-chains

\label{sec:dapp-chains}

\bquote{
    Decoupling the underlying consensus from the state-transition has been informally proposed in private for at least two years---Max Kaye was a proponent of such a strategy during the very early days of Ethereum.
}{
    Dr. Gavin Wood; \href{https://cloudflare-ipfs.com/ipfs/QmbH4TzUB7izvuwidG598DNnk3Nmd1aWEyf8KLxeAkrvkK}{Polkadot Whitepaper, s2.2}
}

*Dapp-chains* are the method by which *Ultra Terminum* exceeds $O(c^2)$ scaling without using the method described in \autoref{sec:tiling}. To be clear: the $O(c^2)$ configuration of UT is compatible with that other method (and it is thus sufficient to reach $O(n)$ scalability). However, there are *decisive* reasons to introduce and use *dapp-chains*. Dapp-chains provide features that the $O(n)$ scaling configuration alone cannot provide. Additionally, dapp-chains increase the simplex's scalability to $O(c^3)$ or $O(c^4)$.

What are *dapp-chains*? Dapp-chains are *application-specific* PoS blockchains and their state- and transaction-schemes are architecturally distinct from those used in the simplex. The headers of dapp-chains are encoded as simplex-transactions, which means that techniques like *slashing* are first-class operations within the *PoW* context provided by the simplex. *This solves the nothing-at-stake problem for any PoS mechanism*, provided the necessary primitives can be encoded in a simplex-transaction. Practically speaking, an input-output transaction system with scripting capabilities (like that of Bitcoin) can be created to facilitate the necessary primitives. Additionally, different simplex-chains can implement different scripting systems, effectively facilitating any practical PoS-esq consensus mechanism.

There are numerous practical benefits to using dapp-chains in this fashion. The abstraction interface that exists between simplex-chains and dapp-chains means that existing PoS blockchain schemes can be easily integrated. Existing PoW blockchain schemes can be integrated, too, though will likely require some additional work.

The most likely method of integration has four components: modification of the headers, modification of existing slashing protocols, implementation of a two-way peg, and support for intra-simplex SPV proofs. For example: [Parity Technologies' OpenEthereum](https://github.com/openethereum/openethereum) could be integrated as a dapp-chain with the creation of a new [header format](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/types/src/header.rs), the creation or modification of a suitable [engine](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/src/engines/basic_authority.rs), and the implementation of suitable [builtins](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/vm/builtin/src/lib.rs) that facilitate both the two-way peg and intra-simplex SPV proofs[^builtins-or-sc].

[^builtins-or-sc]: Note: instead of builtins, these requirements could be met via EVM/WASM smart contracts.

#### Dapp-dapp-chains

\todo[inline]{write it}

### Availability of Reflected Blocks

\label{sec:availability-of-blocks}

What would happen if a header -- with valid PoW but *without* a valid block -- were to be reflected? That would mean that chain A contains a header, $H_{1a}$, for chain B for which no block is available. This does not break chain B, but it could mean that other blocks on chain B temporarily have a harder time competing, or waste the resources of chain B nodes as they go looking for that block, $B_{1a}$. Furthermore, it risks chain B miners doing SPV mining, which is bad.

After $H_{1a}$ is reflected, chain B miners shouldn't build on that header without validating the block. Eventually they'd produce a valid block, $B_{1b}$. But $B_{1b}$ (and it's header, $H_{1b}$) wouldn't be reflected yet. So $B_{1a}$ would have priority over $B_{1b}$ until $B_{2b}$ (building on $B_{1b}$) is created and both $H_{1b}$ and $H_{2b}$ are reflected. After that, a minor chain re-org would restore normality.

There is at least one way to ensure that reflected headers are available. That is: miners on both chain A and chain B should *refuse* to build on blocks that include headers without a known block. This would mean that the chain A block (which includes $H_{1a}$) is *invalid* on chain A while $B_{1a}$ is unavailable. If such a method is feasible, then the malicious chain A miner has greater opportunity cost to produce a block reflecting $H_{1a}$. Moreover, this method prevents chain A (and its miners) from contributing to a potential attack on chain B.

For this to work, though, miners must verify that blocks *exist* for all reflected headers. Is this practical if there are $10^3$ or $10^4$ reflected chains in a simplex? The miners are only required to do very small amounts of computation on these other blocks, so their computational capacity won't be a bottleneck here. Furthermore, they don't need to keep these other blocks indefinitely, just long enough to be confident that they reflect only headers with existent blocks. So they won't need much extra disk space, either -- after a few years, the history of a simplex chain will be larger than, say, the last 12 hours of all simplex-chains' histories combined. What miners will need is *bandwidth*.

The complexity and impact of this strategy is discussed in \autoref{sec:bandwidth-complexity}.

### Proving Reflection

\label{sec:proving-reflection}

\todo[inline]{write this. come up with a method by which a miner having all blocks can construct the witnesses for proof-of-reflection. by doing this, miners don't need to include SPV proofs of reflection; the witnesses don't need to be included.}

If simplex-chains' consensus protocol requires accounting for reflected work, then nodes must have some method whereby they know which work (in a particular chain's history) has been reflected. That is: a node for chain A must be able to answer the question *For each other simplex-chain, which blocks in chain A's history have been reflected?* This means that each node must have $N_1 - 1$ answers for a simplex of $N_1$ chains.

There is a trivial method: include merkle branch proofs along with reflected headers. Specifically: when a miner on chain A includes a header from chain B, they should also include a merkle branch that shows the most recent chain A header that has been reflected by chain B. Miners would need to do this for *all* simplex-chains that they reflect. Predictably, this has overhead with order $O(N_1 \cdot log_2 N_1)$, where $N_1$ is the number of chains in the simplex.

This complexity is discussed in \autoref{sec:complexity-reflection-proof}.

NB: **todo** something about $O(c)$ scaling still rather than $O(c \log_2 c)$.
\todo[inline]{how do we solve?}

Do we *need* to include proofs of reflection, though? If miners of any simplex-chain download blocks of *all* simplex-chains -- as mentioned in \autoref{sec:availability-of-blocks} -- then including all necessary proofs of reflection *smells* redundant. Since miners have all the necessary data to construct the proofs, do they need to actually include those proofs? Could we treat them as witnesses similar to SegWit?

There would be some downsides to excluding the proofs of reflection. For one, it would mean that simplex-chain nodes, during an initial sync, would not be able to verify PoW reflection without auxillary data -- potentially a lot. This may not be a problem, though, because we expect that a *non-miners'* evaluation of a simplex-chain's history will be identical regardless of whether they account for PoW reflection or not (discussed in \autoref{sec:equiv-state-block-weightings}). Secondly, it would mean that miners *must* track the state of *all* reflections in the simplex for some period of time so that they ensure the integrity of the reflection protocol. Given \autoref{sec:availability-of-blocks}, this might be possible without significant overhead.

A practical method for treating proofs of reflection as witnesses that may be excluded is discussed in \autoref{sec:segmented-state}.

### Segmented State

\label{sec:segmented-state}

Traditionally, blockchain protocols have some *global* state and a state-transition function. For example, the Ethereum Yellow Paper[^eth-yellow-paper-state-trans] says:

> Ethereum, taken as a whole, can be viewed as a transaction-based state machine: we begin with a genesis state and incrementally execute transactions to morph it into some current state. It is this current state which we accept as the canonical “version” of the world of Ethereum. \newline
> ... \newline
> A valid state transition is one which comes about through a transaction. Formally:
> \begin{equation*}
>     \sigma_{t+1} \equiv \Upsilon(\sigma_t, T)
> \end{equation*}
> where $\Upsilon$ is the Ethereum state transition function.

[^eth-yellow-paper-state-trans]: \url{https://ethereum.github.io/yellowpaper/paper.pdf} Petersburg Version 41c1837 – 2021-02-14; *Dr. Gavin Wood*, Section: 2. The Blockchain Paradigm. CID: `QmcdwaEqKjsASs1sZqxBNPw5vmypE5YL61zSvWdGoX7wtC`

One of the reasons for this tradition is that transactions are permitted to depend on any parts of the global state. For example: a Bitcoin transaction is permitted to spend any UTXO, and Ethereum smart contracts can interact with any other smart contracts on the Ethereum blockchain.

However, it is not necessary for a protocol to permit *all* transactions to potentially depend on global state. A protocol could specify that certain transactions may depend only on a strictly defined subset of global state, i.e., state is segmented and some of those segments is calculable independently of global state.

Simplex-chains can use this technique to their advantage by segregating both transactions and state which are specific to PoW reflections. That way, the state of a simplex-chain's reflections is calculable independently of anything else that simplex-chain is doing, i.e., dapp-chain extensions and other simplex-level transactions.

We could specify the state-transition of simplex-chains (using Ethereum's nomenclature) like this, for example:

\begin{equation}
\begin{split}
\label{eq:segregated-state}
\sigma_{R,t+1} & \equiv \Upsilon_R(\sigma_{R,t}, T) \\
\sigma_{\star,t+1} & \equiv \Upsilon_{\star}(\sigma_{R,t} + \sigma_{\star,t}, T)
\end{split}
\end{equation}

Where $\sigma_{R,t}$ is the segment of state tracking reflections and headers, $\sigma_{\star,t}$ is the global state excluding $\sigma_{R,t}$, $\Upsilon_R$ is the state-transition function for the reflections segment, and $\Upsilon_{\star}$ is the state transition function for all remaining segments. Note that if $T$ is a reflection-transaction (i.e., it contains headers to be reflected) then $\Upsilon_{\star}$ does nothing, and if $T$ is any other type of transaction then $\Upsilon_R$ does nothing.

In essence \autoref{eq:segregated-state} shows that $\sigma_{R,t}$ depends *only* on the $\sigma_{R,t-1}$ state-segment and the current transaction, whereas $\sigma_{\star,t}$ depends on global state.

If simplex-chains are segmented in this manner, then miners will be able to calculate the reflection-state of other simplex-chains without calculating their complete state. This would allow them to deterministically calculate proofs of reflection for all other simplex-chains.

Given that the reflection-segments of simplex-chains will contain mostly repeated data (i.e., headers), and that these segments will have very similar resultant state, there should be numerous optimizations that are possible. For example, it's not necessary for a miner's node to re-download reflected headers since it already has most (or all) of them; that node just needs to know *which* headers are reflected. This reduces the effective size of simplex-blocks from $b$ to $b \cdot (\frac{g + B_h}{2B_h})$, where $g$ is the size of the relevant digest in bytes. For $g=32; B_h=112$, this reduces effective block size to $\sim 0.643 b$.

\begin{comment}
* note here: don't need to store all the headers $N_1$ times, just their hashes. that could reduce storage of headers to like $\frac{32}{112}$ of what they were before.
* b/c we store all block headers anyway, if reflection takes $t$ seconds to propagate through the simplex, then nodes need $t \cdot N_1 \cdot B_f \cdot B_h$ bytes to store all the headers.
* then, each simplex-chain (per header) has $t \cdot B_f \cdot N_1$ pointers to the heads of the header-chains it reflects, and since we have $N_1$ simplex chains to track, that means $t \cdot B_f \cdot N_1^2$ many pointers are necessary to know the a complete description of all reflections
* having that info means you can deterministically recreate SPV proofs of reflection
* so we can treat these proofs as a witness and not include them in the blockchain

\todo[inline]{write this section out and specify the algorithm -- or at least a draft}
\end{comment}

### Confirmation Times

\label{sec:confirmation-times}

\todo[inline]{write this.}
