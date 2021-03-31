## Escape Velocity (Constructing UT)

\label{sec:constructing-ut}

### Generalizing Reflection

\label{sec:generalizing-reflection}

If we can do reflection between two chains, can we also do reflection between three or more chains?

\todo[inline]{write this out}

### The Simplex

\label{sec:the-simplex}

\begin{figure}
    \centering
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d1-many-tiled-2-simplexes}
        \caption{PoW reflection between 2 blockchains. The most basic non-trivial simplex.}
        \label{fig:simplex-2-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d1-many-tiled-7-simplexes}
        \caption{PoW reflection between 7 blockchains; a 7-chain simplex.}
        \label{fig:simplex-7-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d1-many-tiled-17-simplexes}
        \caption{A 17-chain simplex.}
        \label{fig:simplex-17-d1}
    \end{subfigure}
    \hfill
    \caption{Simplexes of increasing capacity. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
    \label{fig:simplexes}
\end{figure}

### Dapp-chains

\label{sec:dapp-chains}

#### Dapp-dapp-chains

### Availability of Reflected Blocks

\label{sec:availability-of-blocks}

What would happen if a header -- with valid PoW but *without* a valid block -- were to be reflected? That would mean that chain A contains a header, $H_{1a}$, for chain B for which no block is available. This is does not break chain B, but it could mean that other blocks on chain B temporarily have a harder time competing, or waste the resources of chain B nodes as they go looking for that block, $B_{1a}$. Furthermore, it risks chain B miners doing SPV mining, which is bad.

After $H_{1a}$ is reflected, chain B miners shouldn't build on that header without validating the block. Eventually they'd produce a valid block, $B_{1b}$. But $B_{1b}$ (and it's header, $H_{1b}$) wouldn't be reflected yet. So $B_{1a}$ would have priority over $B_{1b}$ until $B_{2b}$ (building on $B_{1b}$) is created and both $H_{1b}$ and $H_{2b}$ are reflected. After that, a minor chain re-org would restore normality.

There is at least one way to ensure that reflected headers are available. That is: miners on both chain A and chain B should *refuse* to build on blocks that include headers without a known block. This would mean that the chain A block (which includes $H_{1a}$) is *invalid* on chain A while $B_{1a}$ is unavailable. If such a method is feasible, then the malicious chain A miner has greater opportunity cost to produce a block reflecting $H_{1a}$. Moreover, this method prevents chain A (and its miners) from contributing to a potential attach on chain B.

For this to work, though, miners must verify that blocks *exist* for all reflected headers. Is this practical if there are $10^3$ or $10^4$ reflected chains in a simplex? The miners are only required to do very small amounts of computation on these other blocks, so their computational capacity won't be a bottleneck here. Furthermore, they don't need to keep these other blocks indefinitely, just long enough to be confident that they reflect only headers with existent blocks. So they won't need much extra disk space, either -- after a few years, the history of a simplex chain will be larger than, say, the last 12 hours of all simplex-chains' histories combined. What miners will need is *bandwidth*.

The complexity and impact of this strategy is discussed in \autoref{sec:bandwidth-complexity}.

### Proving Reflection

\label{sec:proving-reflection}

\todo[inline]{write this. come up with a method by which a miner having all blocks can construct the witnesses for proof-of-reflection. by doing this, miners don't need to include SPV proofs of reflection; the witnesses don't need to be included.}

If simplex-chains' consensus protocol requires accounting for reflected work, then nodes must have some method whereby they know which work (in a particular chain's history) has been reflected. That is: a node for chain A must be able to answer the question *For each other simplex-chain, which blocks in chain A's history have been reflected?* This means that each node must have $N_1 - 1$ answers for a simplex of $N_1$ chains.

There is a trivial method: include merkle branch proofs along with reflected headers. Specifically: when a miner on chain A includes a header from chain B, they should also include a merkle branch that shows the most recent chain A header that has been reflected by chain B. Miners would need to do this for *all* simplex-chains that they reflect. Predictably, this has overhead with order $O(N_1 \cdot log_2 N_1)$, where $N_1$ is the number of chains in the simplex.

NB:



This complexity is discussed in \autoref{sec:complexity-reflection-proof}.



### Confirmation Times

\label{sec:confirmation-times}

\todo[inline]{write this.}
