## Constructing *Ultra Terminum*

\label{sec:constructing-ut}

*Proof of Reflection* can be used to build an $O(c^2)$ foundation for a blockchain network (which I call *the simplex*). This section details the construction of such a foundation, and how it can be extended up to $O(c^4)$ complexity. The $O(n)$ scaling configuration is detailed in \autoref{sec:tiling}.

Such a foundation (*the simplex*) is *not* a sharded blockchain -- there's no requirement that chains in this foundation are either interchangeable or use the same primitives. This was demonstrated via the example in \autoref{sec:two-blockchains}. Rather, *the simplex* is an emergent construct that is created via the *relationships* between blockchains. Instead of one blockchain being split into many (as occurs with sharding), *the simplex* is many blockchains becoming one coherent network.

### Generalizing Reflection

\label{sec:generalizing-reflection}

*Proof of Reflection* is, in essence, the idea that a chain can acknowledge that its history has been confirmed by a different chain[^reflection-prior]. That is a simplification, but it *is* the essence of it.

[^reflection-prior]: I have not been able to find any existing discussion of this method. If you know of any existing discussion of this method, please post a link to the forum topic that is linked in the abstract.

In principle, the necessary capabilities (and actions) that some chains, $C_A$ and $C_B$, must have (and do) in order for $C_A$ to be reflected by $C_B$ are:

1. The headers of $C_A$ can be (and are) freely recorded -- promptly and unambiguously -- in $C_B$;
2. The headers of $C_B$ can be (and are) freely recorded -- promptly and unambiguously -- in $C_A$; and
3. $C_A$ is able to (and does) promptly prove that its headers have been recorded in $C_B$, and has full knowledge of which headers have been recorded.

The benefits from *Proof of Reflection* begin as soon as $C_A$ integrates this knowledge into its chain-weighting algorithm, by a method suitably similar to \autoref{alg:refl-1-bw} and \autoref{alg:weightof-1}.

If $C_A$ and $C_B$ are doing *mutual* Proof of Reflection, then both chains must satisfy all requirements.

Is $C_A$ able to *simultaneously* do reflection with more than one other chain, e.g., $C_C ... C_Z$? Yes. There is nothing that we have covered so far that would prevent this. If *Proof of Reflection* is viable with a single other chain, then it is viable with *many* other chains. However, the dynamics do becoming increasingly complex, as we will soon see.

In order to support arbitrarily many reflections, we need to modify \textsc{ReflectedBlockWeight} from \autoref{alg:refl-1-bw} as shown in \autoref{alg:refl-many-chains}.

\input{algorithms/refl-many-chains.tex}

### The Simplex

\label{sec:the-simplex}

\defineTerm{Simplex}{The single coherent structure that emerges from a collection of blockchains that mutually reflect each-other}

When two or more blockchains *mutually reflect* each-other, they form a *simplex*[^simplex-maths]. For the sake of brevity: all *reflections* within a simplex are *mutual reflections*, and I will omit *mutual* from now on when discussing them. Examples of simplexes are shown in \autoref{fig:simplexes}.

\begin{figure}
    \begin{subfigure}[t]{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{simplex_2_sag}
        \caption{Proof of Reflection between 2 blockchains. A 1-simplex. The most basic non-trivial simplex.}
        \label{fig:simplex-2-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{simplex_7_sag}
        \caption{Proof of Reflection between 7 blockchains; a 7-chain simplex; a 6-simplex.}
        \label{fig:simplex-7-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{simplex_17_sag}
        \caption{A 17-chain simplex; a 16-simplex. It has 136 unique mutual reflections in total.}
        \label{fig:simplex-17-d1}
    \end{subfigure}
    \caption{Simplexes of increasing capacity. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
    \label{fig:simplexes}
\end{figure}

When a blockchain is part of a simplex, it is called a *simplex-chain* (as distinct from *dapp-chains*).

\defineTerm{Simplex-chain}{A blockchain that is part of a \emph{simplex}; it mutually reflects all other simplex-chains in that simplex}

To maintain consistency with the geometric usage of the term *simplex*: a simplex with $k+1$ chains is called a $k$-simplex or a $(k+1)$-chain simplex[^simplex-approx]. In a $k$-simplex, each simplex-chain has $k$ reflections (one reflection for each of the other simplex-chains). A $k$-simplex has, in total, ${k+1} \choose 2$ reflections.

[^simplex-maths]: The name is taken from geometry (particularly: the higher-dimensional kind). A simplex, for a given dimensionality, is the uniquely simplest polytope; e.g., a line in 1D space, a triangle in 2D space, a tetrahedron in 3D space, etc. A $k$-dimensional simplex is known as a $k$-simplex. As shown in \autoref{fig:simplexes}, the 2D skew orthogonal projection of a $k$-simplex is identical to a diagram of all possible mutual reflections between $k+1$ blockchains, where each chain is represented by a vertex and each mutual reflection is represented by an edge.

[^simplex-approx]: \textbf{NB:} I will ignore this distinction for $k \gg 1$.

### Dapp-chains

\label{sec:dapp-chains}

\bquote{
    Decoupling the underlying consensus from the state-transition has been informally proposed in private for at least two years---Max Kaye was a proponent of such a strategy during the very early days of Ethereum.
}{
    Dr. Gavin Wood; \href{https://cloudflare-ipfs.com/ipfs/QmbH4TzUB7izvuwidG598DNnk3Nmd1aWEyf8KLxeAkrvkK}{Polkadot Whitepaper, s2.2}
}

*Dapp-chains* are the method by which *Ultra Terminum* exceeds $O(c^2)$ scaling without using the method described in \autoref{sec:tiling}. To be clear: the $O(c^2)$ configuration of UT is compatible with that other method (and it is thus sufficient to reach $O(n)$ scalability). However, there are *decisive* reasons to introduce and use *dapp-chains*. Dapp-chains provide features that the $O(n)$ scaling configuration alone cannot provide. Additionally, dapp-chains increase the simplex's scalability to $O(c^3)$ or $O(c^4)$.

\defineTerm{Dapp-chain}{An \emph{application-specific} PoS blockchain that may have architecturally distinct state- and transaction-schemes (distinct from those schemes used in the simplex, and other dapp-chains)}

The headers of dapp-chains are encoded as simplex-transactions, which means that techniques like *slashing* are first-class operations within the *hybrid PoW* context provided by the simplex. This solves the *nothing at stake* problem for dapp-chains, provided the necessary PoS primitives can be encoded in a simplex-transaction[^pos-prim-simplex]. Practically speaking, a simple input-output transaction system with scripting capabilities (like that of Bitcoin) can be created to facilitate the necessary primitives. Additionally, different simplex-chains can implement different scripting systems, effectively facilitating *any* practical PoS-esq consensus mechanism.

\defineTerm{Header-transactions}{Dapp-chain headers that are encoded as simplex-level transactions; i.e., they are processed by a simplex-chain as a transaction, but they also function as the header for a dapp-chain block}

[^pos-prim-simplex]: In practice, this is always possible via dedicated opcodes; though it's preferable to use a lower-level DSL with some *reach*, and ideally with meaningful *universality*.

There are numerous practical benefits to using dapp-chains in this fashion. One benefit is: the abstraction interface that exists between simplex-chains and dapp-chains means that existing PoS blockchain schemes can be easily integrated. Existing PoW blockchain schemes can be integrated, too, though will likely require some additional work.

The most likely method of integration has four components: modification of the headers, modification of existing slashing protocols, implementation of a two-way peg, and support for intra-simplex SPV proofs. For example: [OpenEthereum](https://github.com/openethereum/openethereum) could be integrated as a dapp-chain with the creation of a new [header format](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/types/src/header.rs), the creation or modification of a suitable [engine](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/src/engines/basic_authority.rs), and the implementation of suitable [builtins](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/vm/builtin/src/lib.rs) that facilitate both the two-way peg and intra-simplex SPV proofs[^builtins-or-sc]. Naturally, there are some other components that are necessary, they they're also common over many dapp-chain integrations, like a component to actually publish header-transactions to the simplex.

[^builtins-or-sc]: Note: instead of builtins, these requirements could be met via EVM/WASM smart contracts.

If the headers of dapp-chains are simplex-level transactions, what can we say about the security of dapp-chains? Since dapp-chains will use some sort of PoS scheme, and there is no substantive difference between standalone headers and header-transactions. That means that *zero-confirmation* header-transactions are *precisely* as secure as their standalone counterparts -- by definition. This means that other features -- e.g., [finality guarantees](https://github.com/w3f/consensus/blob/master/pdf/grandpa.pdf) -- are *free*. As these header-transactions are subsequently confirmed by the simplex, they inherit the typical security benefits that transactions gain from confirmation. Similar to reflection between PoW and PoS chains, dapp-chains also gain additional security benefits that would not normally be possible without the simplex.




\todo{finish below}

plan:

- advantages
  - abstraction -> universality
  - reach -> use existing PoS tech without sacrifice/compromise
  - cross-community benefits
  - optimized/specialized dapps - e.g., dex (high freq too mb)
    - DB specialization (or lack of)
  - inter-dapp-chain dependencies -> synergies
    - e.g., two chains can both depend on the "bitcoin SPV proofs" chain. their full nodes need to run that other dapp-chain as a dependency
  - use tech like mimblewimble without changing the entire system
  - in general deploy new tech quickly, low risk, high cadence, isolated (sandboxed)
    - tangent about sandbox: is there some good structural principles that prevent classes of attacks? I guess that requiring SPV cross-chain proofs and/or latency stops lots of that (e.g., no re-entrancy). **nb:** i'm wrong about no re-entrancy here; that sorta attack can still be done step-by-step manually sending SPV proofs back and forth or w/e.
    - it does mean that we can maintain guarantees about the ROO and it's distribution and things, tho. like we know how much is where, and it shouldn't leave without being accounted for.
  - low overhead for integrating wallets b/c mostly stuff is the same (e.g., interfaces, etc)
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
