## Escape Velocity (Constructing UT)

\label{sec:constructing-ut}

### Generalizing Reflection

If we can do reflection between two chains, can we also do reflection between three chains?

\todo[inline]{write this out}

guess: extending the Bitcoin + Ethereum example to, say, Bitcoin + Ethereum + Litecoin will provide the security benefits of all 3. it should be additive. a doublespend would require a doublespend against all 3.

### The Simplex

\todo[inline]{fix spacing of captions in \autoref{fig:simplexes}}

\begin{figure}
    \centering
    \begin{subfigure}{.33\textwidth}
        \centering
        \includegraphics[width=.75\linewidth]{ut/tiling/d1-many-tiled-2-simplexes}
        \caption{PoW reflection between 2 blockchains. The most basic non-trivial simplex.}
        \label{fig:simplex-2-d1}
    \end{subfigure}%%
    \begin{subfigure}{.33\textwidth}
        \centering
        \includegraphics[width=.75\linewidth]{ut/tiling/d1-many-tiled-7-simplexes}
        \caption{PoW reflection between 7 blockchains; a 7-chain simplex.}
        \label{fig:simplex-7-d1}
    \end{subfigure}%%
    \begin{subfigure}{.33\linewidth}
        \centering
        \includegraphics[width=.75\linewidth]{ut/tiling/d1-many-tiled-29-simplexes}
        \caption{A 29-chain simplex.}
        \label{fig:simplex-29-d1}
    \end{subfigure}
    \caption{Simplexes of increasing capacity. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
    \label{fig:simplexes}
\end{figure}

### Availability of Reflected Headers

\todo[inline]{can we do better than getting miners to download all the relevant blocks?} they don't have to verify them, just make sure the data is available. e.g. they could download and share for 24hrs and then drop the blocks for the chains they don't care about.

What would happen if a header -- with valid PoW but *without* a valid block -- were to be reflected? That would mean that chain A contains a header, $H_{1a}$, for chain B for which no block is available. This is does not break chain B, but it could mean that other blocks on chain B temporarily have a harder time competing, or waste the resources of chain B nodes as they go looking for that block, $B_{1a}$. Furthermore, it risks chain B miners doing SPV mining, which is bad.

After $H_{1a}$ is reflected, chain B miners shouldn't build on that header without validating the block. Eventually they'd produce a valid block, $B_{1b}$. But $B_{1b}$ (and it's header, $H_{1b}$) wouldn't be reflected yet. So $B_{1a}$ would have priority over $B_{1b}$ until $B_{2b}$ (building on $B_{1b}$) is created and both $H_{1b}$ and $H_{2b}$ are reflected. After that, a minor chain re-org would restore normality.

There is at least one way to ensure that reflected headers are available. That is: miners on both chain A and chain B should *refuse* to build on blocks that include headers without a known block. This would mean that the chain A block (which includes $H_{1a}$) is *invalid* on chain A while $B_{1a}$ is unavailable. If such a method is feasible, then the malicious chain A miner has greater opportunity cost to produce a block reflecting $H_{1a}$. Moreover, this method prevents chain A (and its miners) from contributing to a potential attach on chain B.

For this to work, though, miners must verify that blocks *exist* for all reflected headers. Is this practical if there are $10^3$ or $10^4$ reflected chains in a simplex? The miners are only required to do very small amounts of computation on these other blocks, so their computational capacity won't be a bottleneck here. Furthermore, they don't need to keep these other blocks indefinitely, just long enough to be confident that they won't reflect headers that don't have blocks attached. So they won't need much extra disk space, either; after a few years, the history of a simplex chain will be larger than, say, the last 12 hours of all simplex-chains' histories. What they will need is *bandwidth*.

The complexity and impact of this strategy is discussed in \autoref{sec:bandwidth-complexity}.
