## Escape Velocity (Constructing UT)

\label{sec:constructing-ut}

*PoW reflection* can be used as a foundational technique to build an $O(c^2)$ base-layer for a blockchain network (which I call *the simplex*). This section details the construction of such a foundation, and how it can be extended up to $O(c^4)$ complexity. The $O(n)$ scaling configuration is detailed in \autoref{sec:tiling}.

Such a foundation (*the simplex*) is *not* a sharded blockchain -- there's no requirement that chains in this base-layer are either interchangeable or use the same primitives. This was demonstrated via the example in \autoref{sec:two-blockchains}. Rather, the simplex is an emergent construct that is created via the *relationships* between blockchains. Instead of one blockchain being split into many (as occurs with sharding), the simplex is many blockchains becoming one coherent network.

### Generalizing Reflection

\label{sec:generalizing-reflection}

*PoW reflection* is, in essence, the idea that a chain can acknowledge that its history has been confirmed by a different chain[^reflection-prior]. That is a simplification, but it *is* the essence of it.

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

[^simplex-maths]: The name is taken from geometry (particularly: the higher-dimensional kind). A simplex, for a given dimensionality, is the uniquely simplest polytope; e.g., a line in 1D space, a triangle in 2D space, a tetrahedron in 3D space, etc. A $k$-dimensional simplex is known as a $k$-simplex. As shown in \autoref{fig:simplexes}, the 2D projection of a $k$-simplex is identical to a diagram of all possible mutual reflections between $k+1$ blockchains, where each chain is represented by a vertex and each mutual reflection is represented by an edge.

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

What are *dapp-chains*? Dapp-chains are *application-specific* PoS blockchains with architecturally distinct state- and transaction-schemes (distinct from those used in the simplex, and each other). The headers of dapp-chains are encoded as simplex-transactions, which means that techniques like *slashing* are first-class operations within the **PoW** context provided by the simplex. *This solves the nothing-at-stake problem for any PoS mechanism*, provided the necessary primitives can be encoded in a simplex-transaction. Practically speaking, a simple input-output transaction system with scripting capabilities (like that of Bitcoin) can be created to facilitate the necessary primitives. Additionally, different simplex-chains can implement different scripting systems, effectively facilitating any practical PoS-esq consensus mechanism.

There are numerous practical benefits to using dapp-chains in this fashion. One benefit is: the abstraction interface that exists between simplex-chains and dapp-chains means that existing PoS blockchain schemes can be easily integrated. Existing PoW blockchain schemes can be integrated, too, though will likely require some additional work.

The most likely method of integration has four components: modification of the headers, modification of existing slashing protocols, implementation of a two-way peg, and support for intra-simplex SPV proofs. For example: [Parity Technologies' OpenEthereum](https://github.com/openethereum/openethereum) could be integrated as a dapp-chain with the creation of a new [header format](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/types/src/header.rs), the creation or modification of a suitable [engine](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/src/engines/basic_authority.rs), and the implementation of suitable [builtins](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/vm/builtin/src/lib.rs) that facilitate both the two-way peg and intra-simplex SPV proofs[^builtins-or-sc].

[^builtins-or-sc]: Note: instead of builtins, these requirements could be met via EVM/WASM smart contracts.

\todo{finish below}

The abstraction layer between simplex-chains and dapp-chains has another advantage; one with great *reach*. Any PoS system with special features, say with [finality guarantees](https://github.com/w3f/consensus/blob/master/pdf/grandpa.pdf) or one that is [provably secure](https://iohk.io/en/research/library/papers/ouroborosa-provably-secure-proof-of-stake-blockchain-protocol/), then *something about how their security guarantees stick around*

plan:

- advantages
  - abstraction -> universality
  - reach -> use existing PoS tech without sacrifice/compromise
  - cross-community benefits
  - optimized/specialized dapps - e.g. dex (high freq too mb)
    - DB specialization (or lack of)
  - inter-dapp-chain dependencies -> synergies
    - e.g. two chains can both depend on the "bitcoin SPV proofs" chain. their full nodes need to run that other dapp-chain as a dependency
  - use tech like mimblewimble without changing the entire system
  - in general deploy new tech quickly, low risk, high cadence, isolated (sandboxed)
    - tangent about sandbox: is there some good structural principles that prevent classes of attacks? I guess that requiring SPV cross-chain proofs and/or latency stops lots of that (e.g. no re-entrancy). **nb:** i'm wrong about no re-entrancy here; that sorta attack can still be done step-by-step manually sending SPV proofs back and forth or w/e.
    - it does mean that we can maintain guarantees about the ROO and it's distribution and things, tho. like we know how much is where, and it shouldn't leave without being accounted for.
  - low overhead for integrating wallets b/c mostly stuff is the same (e.g. interfaces, etc)
    - nb: need a common format for addresses or some understanding of them at a data/type level
  - *all* the layer-2 solns
  - todo: more tomorrow

\todo{
  dev potential;
}

#### Dapp-dapp-chains

\todo{write it}

plan:

- dapp-dapp-chains are the shards of dapp-chains
  - These are based on whatever is implemented in the dapp-chain; so abstracted away from UT
  - If Eth2 is $O(c^2)$ with shards, and we modify Eth2 to run as a dapp-chain, then Eth2 shards would be dapp-dapp-chains and UT's max complexity would be $O(c^4)$.
  - Basically we can use other $O(c^2)$ chains as needed to create lots of capacity w/ no loss of security
  - dapp-dapp-chains aren't a big deal really, just nice to have.
