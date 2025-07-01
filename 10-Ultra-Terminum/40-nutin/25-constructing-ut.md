%% BEGIN ### RELEASE

\clearpage
\section{\titlemath{$\UT{i}$}{UTᵢ}: Constructing \emph{Ultra Terminum}}

\label{sec:constructing-ut}

*Proof of Reflection* can be used to build $\UT{1}$ --- an $O(c^2)$ foundation for a blockchain network (called *the simplex*). This section details the construction of such a foundation, and how it can be extended up to $\UT{3}$ --- which has $O(c^4)$ complexity. The $O(n)$ scaling configuration ($\UTinf{}$) is detailed in \autoref{sec:tiling}.

Such a foundation (*the simplex*) is *not* a sharded blockchain --- there's no requirement that participating chains are interchangeable or using the same primitives. This was demonstrated via the example in \autoref{sec:two-blockchains}. Rather, *the simplex* is an emergent construct that is created via the *relationships* between blockchains. Instead of one blockchain being split into many (as occurs with sharding), *the simplex* is many blockchains becoming one coherent network.

\subsection{Generalizing Reflection}

\label{sec:generalizing-reflection}

*Proof of Reflection* is, in essence, the idea that a chain can acknowledge that its history has been confirmed by a different chain, and that this fact can be used to share security between chains.
That is a simplification, but it *is* the essence of it.

In principle, the necessary capabilities (and actions) that some chains, $C_A$ and $C_B$, must have (and do) in order for $C_A$ to be reflected by $C_B$ are:

1. The headers of $C_A$ can be (and are) freely recorded --- promptly and unambiguously --- in $C_B$;
2. The headers of $C_B$ can be (and are) freely recorded --- promptly and unambiguously --- in $C_A$; and
3. $C_A$ is able to (and does) promptly prove that its past headers have been recorded in $C_B$, and has full knowledge of which headers have been recorded.

\input{includes/ut/algorithms/por-reflected-block-weight.tex}

The benefits from *Proof of Reflection* begin as soon as $C_A$ integrates this knowledge into its chain-weighting algorithm, by a method suitably similar to \autoref{alg:refl-1-bw} and \autoref{alg:weightof-1}.

If $C_A$ and $C_B$ are doing *mutual* Proof of Reflection, then both chains must satisfy all requirements.

Is $C_A$ able to *simultaneously* do reflection with more than one other chain, e.g., $C_C ... C_Z$? Yes. There is nothing that we have covered so far that would prevent this. If *Proof of Reflection* is viable with a single other chain, then it is viable with *many* other chains. However, the dynamics do become increasingly complex, as we will soon see.

In order to support arbitrarily many reflections, we need to modify \textsc{ReflectedBlockWeight} from \autoref{alg:refl-1-bw} as shown in \autoref{alg:por-reflected-block-weight}.

Note that \autoref{alg:por-reflected-block-weight} integrates the cap on weight contributed by each reflecting chain, as suggested in \autoref{sec:reflection-pow-and-pos}.


%% --- %%

%% SIMPLEX

\input{includes/ut/headings/25-the-simplex.tex}
\label{sec:the-simplex}

\begin{figure}[H]
    \begin{subfigure}{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{simplex_2_sag}
        \caption{Proof of Reflection between 2 blockchains. A 1-simplex. The most basic non-trivial simplex.}
        \label{fig:simplex-2-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{simplex_7_sag}
        \caption{Proof of Reflection between 7 blockchains; a 7-chain simplex; a 6-simplex.}
        \label{fig:simplex-7-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.31\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{simplex_17_sag}
        \caption{A 17-chain simplex; a 16-simplex. It has 136 unique mutual reflections in total.}
        \label{fig:simplex-17-d1}
    \end{subfigure}
    \caption[Simplexes of increasing capacity.]{Simplexes of increasing capacity. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
    \label{fig:simplexes}
\end{figure}

\defineTermTex{Simplex}{The single coherent structure that emerges from a collection of blockchains that mutually reflect each other}

When two or more blockchains *mutually reflect* each other, they form a *simplex*[^simplex-maths]. For the sake of brevity: all *reflections* within a simplex are *mutual reflections*, and I will omit *mutual* from now on when discussing them. Examples of simplexes are shown in \autoref{fig:simplexes}.

When a blockchain is part of a simplex, it is called a *simplex-chain* (as distinct from *dapp-chains*).

\defineTermTex{Simplex-chain}{A blockchain that is part of a \emph{simplex}; it mutually reflects all other simplex-chains in that simplex}

To maintain consistency with the geometric usage of the term *simplex*: a simplex with $k+1$ chains is called a $k$-simplex or a $(k+1)$-chain simplex[^simplex-approx].
In a $k$-simplex, each simplex-chain has $k$ reflections (one reflection for each of the other simplex-chains).
A $k$-simplex has, in total, ${k+1} \choose 2$ reflections.

[^simplex-maths]: The name is taken from geometry (particularly: the higher-dimensional kind). A simplex, for a given dimensionality, is the uniquely simplest polytope; e.g., a line in 1D space, a triangle in 2D space, a tetrahedron in 3D space, etc. A $k$-dimensional simplex is known as a $k$-simplex. As shown in \autoref{fig:simplexes}, a particular 2D projection of a $k$-simplex (which produces a regular $(k+1)$-gon with additional edges between all pairs of vertices), is identical to a diagram of all possible mutual reflections between $k+1$ blockchains, where each chain is represented by a vertex and each mutual reflection is represented by an edge.

[^simplex-approx]: NB: I will ignore this distinction for $k \gg 1$.

The security of simplexes is discussed in \autoref{sec:simplex-security}.


<!-- ### Scaling Complexity Intuition -->


\input{includes/ut/content/25-constructing-ut/20-scaling-complexity-intuition.tex}


%% --- %%

\input{includes/ut/headings/25-dapp-chains.tex}

\label{sec:dapp-chains}

*Dapp-chains* are the method by which *Ultra Terminum* exceeds $O(c^2)$ scaling *without* using the method described in \autoref{sec:tiling}. To be clear: the $O(c^2)$ configuration of UT is compatible with that other method; dapp-chains are a *separate and independent* method of scaling. However, there are *decisive* reasons to introduce and use *dapp-chains*. Dapp-chains provide features that the $O(n)$ scaling configuration alone cannot \emph{easily} provide. Additionally, dapp-chains increase the simplex's scalability to $O(c^3)$ or $O(c^4)$.

\defineTermTex{Dapp-chain}{
  An \emph{application-specific} child-chain that is secured via the parent-chain. Dapp-chains may have architecturally distinct state- and transaction-schemes (distinct from those schemes used in the simplex, and other dapp-chains)
}

Intrinsically, dapp-chains are not restricted to any particular foundational consensus method.
They might use PoW, or PoS, or PoA, or something else.
However, dapp-chains also use *Proof of Reflection* with their host simplex-chain.
With a suitable foundational consensus method, PoR enables dapp-chains to be as secure as their host simplex-chain with little overhead.
Note that, since dapp-chains can use whichever foundational consensus method, they can optionally have \emph{their own} root token (and use that for mining rewards, transaction fees, etc).

It's preferable that a simplex-chain validate the headers of its dapp-chains (similar to a light client), though this is not required.
For some consensus methods that dapp-chains might choose (such as PoS), there might be special primitives that a host simplex-chain must support.
However, only that host simplex-chain requires those primitives; other simplex-chains do not.\footnote{
  The caveat here is that other simplex-chains may need to be capable of validating fraud proofs for the simplex-chain in question.
  So they don't need these primitives \emph{available to local transactions}, but do need to be capable of executing those primitives if a fraud proof involves one.
}
This means that simplex-chains can *specialize* in hosting *particular types* of dapp-chains, providing rich and efficient environments (for nodes of both simplex-chains *and* dapp-chains).

Validating dapp-chain headers, on-chain, can be done via the following simple, clean, and extensible method: \emph{encode dapp-chain headers as simplex-level transactions}.
This means that supporting new dapp-chain consensus methods is about as difficult as introducing new transaction types (or opcodes), and different simplex-chains have a great deal of freedom in choosing which dapp-chain consensus methods to support.

\defineTermTex{Header-transactions}{
  Dapp-chain headers that are encoded as simplex-level transactions; i.e., they are processed by a simplex-chain as a transaction, but they also function as the header for a dapp-chain block
}

Practically speaking, a simple input-output transaction system with light scripting capabilities (like that of Bitcoin) can be created to facilitate the necessary primitives.
Additionally, different simplex-chains can implement different scripting systems, effectively facilitating *any* practical consensus mechanism.
There is not much (if any) overhead to using an input-output system like this: a header's parent hash is like a transaction input, the *output* can be omitted[^scriptpk], and other particulars of the header can be treated as an input script to the transaction[^scriptsig].

[^scriptpk]: A header-transaction's output script can be generic (or templated) as it is the same for all header-transactions for that dapp-chain. In practice this can be as simple as a single opcode that validates that header. In Bitcoin, an output script is known as the `scriptPubKey`.

[^scriptsig]: In Bitcoin, the input script to a transaction is called the `scriptSig`; see \url{https://en.bitcoin.it/wiki/Transaction}.

\subsubsection{Dapp-chain Security}

\label{sec:dapp-chain-security}

If the headers of dapp-chains are simplex-level transactions, what can we say about the security of dapp-chains?

First, notice that there is no substantive difference between standalone headers and header-transactions.
That means that *zero-confirmation* header-transactions are *exactly* as secure as a standalone counterparts (and at least as secure as zero-confirmation transactions).
This is not very secure in the case of a PoW dapp-chain, but it means that a PoS dapp-chain's zero-confirmation header-transactions are just as secure as blocks from an equivalent standalone PoS blockchain.
(It also means that the PoS dapp-chain is much more secure after header-transactions are confirmed, compared to the standalone equivalent.)

When a header-transaction is confirmed by the simplex, the corresponding dapp-chain can efficiently use one-way PoR to inherit the security (and security properties) of the host simplex-chain[^dc-por]. Similar to mutual PoR, this can provide a *security context* where otherwise-insecure methods of consensus can be done securely.

[^dc-por]: Note: PoW dapp-chains will have a much lower difficulty than the host simplex-chain. Although a simplex-chain could do mutual PoR with dapp-chains, this is unnecessary and inefficient --- provided that this difficulty asymmetry exists. Although there is no fundamental reason that PoW dapp-chains must have a much lower difficulty, we should take care to avoid any implementation that would compromise or reduce the security of the simplex. Practically, this probably means avoiding PoW dapp-chains (see \autoref{sec:child-chain-pow-pos-asymmetry}).

With regards to doublespends, one-way PoR means that the reflected chain is *at least* as difficult to attack as the reflecting chain (as we covered in \autoref{sec:por-step4}).
Since the parent simplex-chain is as difficult to attack as the complete simplex, each dapp-chain must therefore *also* be that difficult to attack.
Attacking a dapp-chain is as difficult as attacking the entire network.

Note that parent-chains (generally) need to record their child-chains' headers *anyway*, so this use of one-way PoR --- where a simplex-chain reflects child dapp-chains --- has near-zero overhead for both the simplex-chain and the dapp-chain.

One major, generic concern for dapp-chains is \emph{preventing DoS attacks}.\footnote{
  Unfortunately, the strategy we use in \autoref{sec:preventing-dos-attacks} to protect simplex-chains does not work here.
}
This is one reason to favor PoS (or PoA) dapp-chains over PoW dapp-chains.
Another concern is the \emph{availability} of dapp-chain blocks.

<!-- Note: may contain >1 subsubsection -->
\input{25-constructing-ut/42-dapp-chain-pow-pos}


\subsubsection{Three General Incentive Models for Dapp-chain Reflection}

If dapp-chain headers are included along-side transactions in simplex-blocks, is it not the case that both must pay some kind of *transaction fee*?
If not, how are simplex-chain miners to prioritize what to include in their blocks?
Even if such a fee is *not always necessary*, the *ability* to provide a fee has decisive advantages --- like creating asymmetry between an attacker and honest simplex-chain miners.

If it is possible to implement dapp-chains (or any system of child-chains) such that those chains have \emph{freedom of protocol} and \emph{freedom of incentivization} whilst inheriting the parent-chain's security, then we should strive to achieve that.

\defineTermTex{Freedom of Incentivization}{
  The property whereby child-chains have free choice of incentive-system (i.e., the nature and dynamics of their root token, or lack thereof)
}

\defineTermTex{Freedom of Protocol}{
  The property whereby child-chains have free choice of protocol (including consensus mechanism, scripting, accounting methods, block structures, etc)
}

\autoref{sec:comparing-weight-dex} details a conversion method whereby PoR is possible between chains using different root tokens via a DEX. Could dapp-chains use a \emph{protocol-level} DEX to abstract their protocol and incentive method away from those of its parent-chain? Yes.

Is this required for this kind of abstraction? No.

Here are three methods of abstraction which maintain the above freedoms.

\subsubsubsection{Method 1: Pay the simplex miner on the dapp-chain}

In this method, the dapp-chain uses its root token to pay both the dapp-chain miner and the simplex-chain miner (who includes the relevant dapp-chain header in their block).

Since all dapp-chain miners are required to run a full node of the parent-chain, this is trivial. In essence, the host simplex-chain is a subset of the dapp-chain. Simplex-miners can run light clients[^hostminercollect] of the dapp-chain to regularly collect block-rewards.

[^hostminercollect]: A simplex-miner could use other methods too, like maintaining full nodes of each dapp-chain and continuously cycling through them (alternating which are running and which are not) to avoid massive computation requirements.
Light clients seem obviously preferable where possible.

A dapp-chain could, perhaps, have a rule like *X root tokens are created as part of the coinbase transaction and the miner of that dapp-block has free choice of the proportion of those which are provided as a transaction fee to the host-miner*.

Example use-case: an existing blockchain migrates to become an *Amaroo* dapp-chain.

\subsubsubsection{Method 2: Pay the simplex miner via a native DEX}

When a dapp-chain hosts a native DEX, it can use that DEX for PoR.
The general case (where a reflecting chain contributes far more chain-work than the reflected chain) was discussed in \autoref{sec:comparing-weight-dex}.

Consider the limited context of a DEX with only one required trading pair (between the dapp-chain's root token and the ROO), combined with the security-contribution differential between a simplex-chain and a dapp-chain.
Note that a conservative implementation of a DEX between this pair *only relies on local state* --- that of the host simplex-chain and the dapp-chain, all of which is accessible to dapp-chain full nodes.
The simplest method of preventing market manipulation (that might allow for some attack on the dapp-chain) is to calculate PoR weight via an *old* exchange rate (e.g., from 24 hours ago), or to use an *average* over some period of time.
Both of these ensure that *competition between blocks* (at any given time) is not dependent on the *current* DEX execution.
With regards to dapp-chains using Proof of Reflection, this is sufficient.

Given a DEX, the dapp-chain can use this to automatically convert some of the mining reward to the root token of the host simplex-chain.
These rewards could accrue over time and be bundled into far fewer transactions than would otherwise be necessary and automatically managed by the DEX.
Unlike the previous method, this method doesn't require the simplex-chain miner to ever interact with dapp-chains (besides including their header-transactions); however, the protocol is more complex.

Example use-case: a greenfield dapp-chain uses an Amaroo-compatible DEX (which requires no development effort) so that simplex-miners have lower operating costs; thus incenting simplex-miners to include their headers over those of others.

\subsubsubsection{Method 3: Pay the simplex miner directly}

If the dapp-chain is willing to forego more efficient SPV transactions (or otherwise doesn't require them), and it is willing to bear the full burden of PoR in this context, then simply recording the hash of a dapp-chain header might be sufficient.
In such a case, transactions (in the style of Bitcoin's \textsc{OP\_RETURN} transaction format) provide everything required.
This makes sense if the dapp-chain has exceptionally large headers, or if the dapp-chain does not wish to *disclose* the headers themselves (perhaps it is a private/permissioned network).
In any case, since it is impossible to stop users including hashes in transactions, this is always a method by which dapp-chains can enable PoR with the host simplex-chain.

Example use-cases:

- An existing *anchored*[^anchoring] blockchain migrates to become an Amaroo dapp-chain.

- A new (and ephemeral) dapp-chain is created to facilitate a national election that will result in a 200 GB audit log (facilitating unprivileged verification of the election result) and a peak votes-per-second over $10^5$.
This demonstrates both *freedom of incentivization* (as there is none) and *freedom of protocol* as no payments are made and no restriction is placed on the nature of this dapp-chain's payload.

\begin{comment}
<!-- [^election]: The major problem that frustrated systems of end-to-end arbitrarily-verifiable online elections was the difficulty of implementing secret ballot. Today, there are at least three known methods: zero-knowledge proofs, homomorphic encryption, and [a CoinShuffle-based system of my own design](https://gitlab.com/exo-one/svst-docker/blob/master/svst-docs/secure.vote.white.napkin.md). (Note that it is [impossible to prevent the voter from creating some proof-of-vote](https://github.com/zack-bitcoin/amoveo-docs/issues/2) --- in these and all other systems of secret ballot.) -->
\end{comment}

[^anchoring]: **Anchoring**: The process by which the hash of some data (perhaps a secondary chain's blocks) is included in transactions of a primary blockchain (e.g., [Bitcoin](https://www.reddit.com/r/Bitcoin/comments/5xkvc1/psa_were_running_a_stress_test_of_our_blockchain/)).
Anchoring *would* be a progenitor to PoR, except that I believe the idea of an [on-chain light client predates](https://github.com/XertroV/coppr/blob/master/chainheaders.py) the term *anchoring*.
Though I think that the idea of time-stamping a hash (e.g., via an \textsc{OP\_RETURN} transaction on Bitcoin) predates the idea of an on-chain light client.

\subsubsection{PoS Dapp-chains}

If the headers of dapp-chains are encoded as simplex-transactions, then techniques like *slashing* can be first-class operations within the *hybrid* PoW context provided by the simplex.
This solves the *Nothing at Stake* problem for PoS dapp-chains, provided the necessary PoS primitives can be encoded in a simplex-transaction.

The abstraction layer between simplex-chains and dapp-chains brings practical benefits, too.
For example: existing (open-source) PoS blockchain schemes can be easily integrated as dapp-chains.
Given that dapp-chains inherit security properties of their parent-chain (via one-way PoR), if such a dapp-chain's consensus method supports *other* features --- e.g., \href{\citeGrandpaLink}{finality guarantees} --- those features are *free*.
(Sharding, too, for that matter\dots)

The most likely method of integration has three core components: modification of the headers (and integration of PoR), modification of existing slashing protocols, and support for intra-simplex SPV proofs.
For example: \citeOpenEthereumLink{} [^open-eth] could be integrated as a dapp-chain with the creation of a new [header format](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/types/src/header.rs), the creation or modification of a suitable [engine](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/ethcore/src/engines/basic_authority.rs), and the implementation of suitable [builtins](https://github.com/openethereum/openethereum/blob/582bca385fedb1af682e989e5bcc6b3b2cf53028/crates/vm/builtin/src/lib.rs) that facilitate intra-simplex SPV proofs[^builtins-or-sc] and any other useful features.
Naturally, there are some other components that are necessary (like a component for broadcasting header-transactions), but those components are common over many dapp-chain integrations and only need to be written once for each *kind* of dapp-chain.

[^open-eth]: OpenEthereum itself has, since this section was written, been deprecated.
This section is left unchanged since the specific client we might modify is immaterial to the main point: that relatively few modifications can be applied to existing clients to create a dapp-chain version of that kind of blockchain.

[^builtins-or-sc]: Note: instead of builtins, these requirements could be met via EVM/WASM smart contracts.

%% END ### RELEASE

%% BEGIN ### DRAFT

\input{25-constructing-ut/45-dapp-chains-extra}

%% END ### DRAFT

%% BEGIN ### RELEASE

\input{25-constructing-ut/60-going-further-research}

%% END ### RELEASE

%% BEGIN ### DRAFT

\begin{comment}

\subsubsection{Dapp-chain simplexes}

\subsubsection{Future Dapp-chain Stuff (todo)}

\todo{finish below about future dapp-chain stuff}

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
    - it does mean that we can maintain guarantees about the ROO and its distribution and things, tho. like we know how much is where, and it shouldn't leave without being accounted for.
  - low overhead for integrating wallets b/c mostly stuff is the same (e.g., interfaces, etc)
    - nb: need a common format for addresses or some understanding of them at a data/type level
  - *all* the layer-2 solns
  - todo: more tomorrow

\todo{
  dev potential;
}

%% --- %%
%% we don't technically need \texorpdfstring{}{}
%% here b/c this subsubsubsection isn't in the TOC

\input{includes/ut/headings/25-dapp-dapp-chains.tex}

\todo{write UT3 dapp-dapp chains section}

plan:

- dapp-dapp-chains are the shards of dapp-chains
  - These are based on whatever is implemented in the dapp-chain; so abstracted away from UT
  - If Eth2 is $O(c^2)$ with shards, and we modify Eth2 to run as a dapp-chain, then Eth2 shards would be dapp-dapp-chains and UT's maximum complexity would be $O(c^4)$.
  - Basically we can use other $O(c^2)$ chains as needed to create lots of capacity w/ no loss of security
  - dapp-dapp-chains aren't a big deal really, just nice to have.

\end{comment}

%% END ### DRAFT
