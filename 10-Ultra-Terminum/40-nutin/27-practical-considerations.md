%% BEGIN ### RELEASE

\section{Practical Considerations for UT's Design}

\label{sec:practical-considerations}

\input{includes/ut/content/27-practical/05-intro.tex}

\input{includes/ut/content/27-practical/10-refl-availability.tex}

%% END ### RELEASE

%% BEGIN ### DRAFT

\todo{argue that hiding blocks can cause massive reorgs and invalidate future blocks after those future blocks have been mined (note: might be covered in part by 10-refl-availability.tex)}

\todo{note that it is vital that new stuff doesn't invalidate old stuff / cause a re-org; or check that it's noted (ties into SPV)}

%% END ### DRAFT

%% BEGIN ### RELEASE

\subsection{Proving Reflection}

\label{sec:proving-reflection}

If simplex-chains' consensus protocols require accounting for reflected work, then nodes must have some method whereby they know which work (in a particular chain's history) has been reflected.
That is: a node for chain L must be able to answer the question *For each other simplex-chain, which blocks in chain L's history have been reflected?*
This means that each node must have $N_1 - 1$ answers, per block, for a simplex of $N_1$ chains.

There is a trivial method: with each header, include the corresponding merkle branch which proves reflection.
Specifically: when a miner on chain L mines a block that includes a header from chain R, they should also include --- along-side the header --- a merkle branch that shows the most recent chain L ancestor that has been reflected by chain R.
For example, block $B_{L,i+1}$ might include a proof that $H_{L,i}$ was reflected by $B_{R,j}$.
That branch is the only required branch (i.e., the \emph{missing} branch), as chain L nodes are \emph{already} aware whether $H_{R,j}$ was reflected by $B_{L,i+1}$.

\begin{comment}
(Note: in some sense, the full PoR cannot be included *in* a newly created block, since the PoR depends *on* that newly created block. Although a miner can *commit* to a PoR when mining a block, the PoR can only be fully constructed after the relevant merkle-root has been calculated. It is possible to segment the block-creation process so that PoRs can be directly included, but this is clunky and arguably unnecessary.)
\end{comment}

Miners would need to do this for *all* simplex-chains that they reflect. Predictably, this has overhead with order $O(N_1 \cdot \log_2 N_1)$, where $N_1$ is the number of chains in the simplex. This method has complexity $O(c \cdot \log_2 c)$ which is discussed in \autoref{sec:complexity-reflection-proof}.

\defineTermTex{Explicit Proofs (+PoRs)}{
    The UT protocol variant wherein miners/validators explicitly record \emph{both} reflected headers \emph{and} the single missing merkle branch required to prove reflection
}

Do we *need* to include proofs of reflection, though? Is it possible to avoid the explicit inclusion of those proofs, potentially allowing for $O(c)$ complexity instead?



If miners of any simplex-chain download the blocks of *all* simplex-chains --- as mentioned in \autoref{sec:availability-of-blocks} --- then including all necessary proofs of reflection can be made redundant.
Since miners, theoretically, have all the necessary data to construct the proofs, do those miners need to actually include those proofs?
Could we treat those proofs as witnesses and prune them --- similar to Segregated Witness (SegWit)\footnote{\href{https://web.archive.org/web/20240926154239/https://en.bitcoin.it/wiki/Segregated_Witness}{Segregated Witness} was a new ``witness'' structure introduced to bitcoin blocks, separate from the transaction merkle tree. The structure contains data required to check transaction validity but not required to determine the transaction effects. Introduced with \href{https://web.archive.org/web/20240423183945/https://en.bitcoin.it/wiki/BIP_0141}{BIP-141}.}?

\defineTermTex{Omitted Proofs (+OP)}{
    The UT protocol variant wherein miners/validators explicitly transmit \emph{only} the reflected header component of PoRs, such that necessary proofs of reflection themselves are deterministically recalculable
}

There would be some downsides to omitting the proofs of reflection.
For one, it would mean that simplex-chain nodes of a single chain, during an initial sync, would not be able to verify the PoRs without auxiliary data --- potentially a lot.
Secondly, it would mean that miners *must* track the state of *all* reflections in the simplex for some period of time so that they ensure the integrity of the reflection protocol.
Although, given the \AxiomOfAvailability{}, this is possible without significant overhead.

A practical method for treating proofs of reflection as witnesses that may be excluded/pruned is discussed in \autoref{sec:segmented-state}.

%% END ### RELEASE

%% BEGIN ### DRAFT

\subsubsection{Verkle Trees and Shorter PoRs}

\label{sec:verkle-proofs}

\emph{Verkle trees} are a new alternative to merkle trees.
Similar to merkle trees, they allow efficient proofs of membership against a cryptographically secure root.

\todoDraftOnly[m]{probs remove --- not worth explaining here.}

%% END ### DRAFT

%% BEGIN ### RELEASE

\subsection{Segmented State}

\label{sec:segmented-state}

Traditionally, blockchain protocols have some *global* state and a state-transition function. For example, the Ethereum Yellow Paper says:

```{=latex}
\bquote{
    Ethereum, taken as a whole, can be viewed as a transaction-based state machine: we begin with a genesis state and incrementally execute transactions to morph it into some current state. It is this current state which we accept as the canonical “version” of the world of Ethereum. \\
    {[\ldots]} \\
    A valid state transition is one which comes about through a transaction. Formally:
    \begin{equation*}
        \sigma_{t+1} \equiv \Upsilon(\sigma_t, T)
    \end{equation*}
    where $\Upsilon$ is the Ethereum state transition function.
}[Dr. Gavin Wood; \citeEthYellowPaperLink, s2]
```

One of the reasons for this tradition is that transactions are (typically) permitted to depend on any part of the global state. For example: a Bitcoin transaction is permitted to spend any UTXO, and an Ethereum smart contract may interact with any other smart contract on the Ethereum blockchain.

However, it is not necessary for a protocol to allow *any and all* transactions to depend on global state. A protocol could specify that certain transactions may depend only on a strictly defined subset of global state, i.e., a well defined *segment* of global state that is independently calculable.

Simplex-chains can use this technique to their advantage by segmenting both transactions and state which are specific to Proof of Reflection.
That way, the state of a simplex-chain's reflections can be calculated without needing to calculate the remaining state for that simplex-chain.

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

If simplex-chains are segmented in this manner, then miners will be able to calculate the reflection-state of other simplex-chains without calculating their complete state.
This would allow them to deterministically calculate proofs of reflection for all other simplex-chains.

\subsection{Exploiting Segmented State}

\label{sec:exploiting-seg-state}
\label{sec:exploiting-segmented-state}

Given that the reflection-segments of simplex-chains will contain mostly redundant data (i.e., headers), numerous optimizations are possible.

For example, it's not necessary for a miner's node to re-download reflected headers (which are part of other chains' blocks), since it can download them in advance and as they become available.
We can reconstruct the PoRs root, provided that we know *which* headers are reflected and in what order.
Transmitting the \emph{hashes} of headers, only, reduces the effective size of simplex-blocks[^sb-size] from $b$ to $\sim b \cdot (\frac{g + B_h}{2B_h})$, where $g$ is the size of the relevant digest in bytes.
For $g=32; B_h=112$, this reduces effective block size to $\sim 0.643 b$ --- an improvement of $\sim 35\%$.

[^sb-size]: Assuming those blocks dedicate 50% capacity to transactions, and 50% to reflected headers (without PoRs).

However, \emph{instead} of using that technique to \emph{minimize bandwidth} we could instead use it to \emph{maximize the number of simplex-chains}.
If simplex-blocks dedicate $\nicefrac{1}{2}$ of their capacity to reflections, and assuming +OP, then we can reduce that burden by $1 - \nicefrac{32}{B_h} \approx 70\%$, \emph{or} we could increase the capacity for reflections by $\nicefrac{B_h}{32} \approx 300\%$!

\defineTermTex{Header Omission (+HO)}{
    The UT protocol variant wherein miners/validators explicitly record \emph{only} the hashes of reflected headers.
    A requirement is that block producers must eagerly download the headers of all simplex-chains and deterministically recalculate the relevant Proofs of Reflection
}

We have just reached the +HO variant via *omitting proofs* (+OP).
This time, however, it is not the *proofs* that are redundant, but the *headers*.

Does *header omission* with *explicit proofs* provide any advantages? Yes, in some cases.

Particularly, if miners include only the single missing merkle branch associated with each necessary PoR, then *no additional information* is required besides the *header* itself.
Headers are trivial to acquire from the network, and each only needs to be acquired once, regardless of the number of PoRs it is a part of.
Since the *hash of each header* is *part* of the missing PoR merkle branch, miners only need to provided *an ordered list of merkle branches* for full PoR verifiability.
Additionally, these merkle branches *will be part of specific SPV proofs*, so that when a cross-chain SPV transaction (which uses those branches) is made, it can omit those parts of the proof (replacing them with a pointer).

This UT protocol variant is +HOPoRs: the combination of *header omission* (+HO) and *explicit proofs* (+PoRs).
It may present decisive advantages for implementations of *simplex tilings* (which are introduced in \Cref{sec:tiling}).

\subsubsection {Hash Compression \& Truncation}

\warning{The following applies to PoW chains with compatible header hashes.}

Consider a fairly normal PoW chain, in that the PoW algorithm compares the hashes of headers as a number with a target.
That is, the output hash has a bunch of zero digits at one end (or can be losslessly converted into such a form).
For simplicity, we'll assume that the zero digits are the most significant and are leading (and the least significant bits are trailing).

When we serialize this hash as a binary string, there is a trivial compression method.
Since we \emph{know} that one end of the hash has multiple zero bytes, we can replace this substring with the number of zero bytes replaced.\footnote{
    Since we're now dealing with a variable length byte-string, a typical encoding scheme would prefix this with the length of the bytes.
    From this we can recover the number of zero bytes, so we don't need to explicitly encode it.
}

This reduces the length of the hash (in bytes) from $g$ to $g - z + 1$ ($z$ being the number of zero bytes), \emph{however}, the \emph{security} of the hash \ul{is still $8g$ bits}.
This is a limited form of hash compression.
In a mature network using +HO, reducing hash length by $\sim \nicefrac{1}{4}$ is possible, corresponding to an increase in maximum capacity of $\sim \nicefrac{1}{3}$ or so.

This kind of compression is possible (and valuable) because the hashes are \emph{laden} with special properties by the PoW algorithm.
There are two main properties we are concerned with.
The first is that better header hashes, interpreted as numbers, are smaller.
The second is subtle.

Consider a mature, healthy PoW chain, like Bitcoin.
The proofs of work produced by such a chain are, through market feedback mechanisms, the \emph{best} proofs of work that the market as a whole (i.e., the global economy) is capable of producing profitably.
Therefore, the proofs of work are an approximate \emph{measure} of the global capacity for hashing.
More specifically, the number of leading zero-bits loosely encodes humanity's collective ability to produce arbitrary partial collisions via brute force.
For example, Bitcoin block 879,273 has a difficulty around $1.1 \times 10^{14}$, corresponding to at least 78 leading zero-bits.\footnote{
    The block itself had 81 leading zero-bits.
}
Given Bitcoin produces around 52600 blocks per year (and all else being equal), we can expect the best block hash produced in the last year to have around $78 + \log_2(52600) \approx 94$ leading zero-bits.
Practically speaking, all the silicon in the world working for a year, singularly, on finding a partial SHA256 collision would not do much better than 94 bits.
We can be confident in this \emph{particular} prediction because the market for Bitcoin ASICs is mature -- those ASICs use the latest fabrication processes, are numerous enough, and are orders of magnitude more efficient than general processors (CPUs, GPUs, etc).
For less mature networks, or networks using algorithms that benefit less from ASICs, the difference will be greater and more dependent on external compute resources which are not reflected in the PoW difficulty.
But, provided that $g \gg 2z$, this does not present an issue -- the low value of $z$ means we have more buffer until we pass the insecurity breakpoint, so these two forces roughly cancel out in all but extreme cases.

We will make use of this second property, that the leading zero-bits are related to the global hashing capacity, to justify the safety of \emph{hash truncation} as an optimization.

\defineTermTex{Hash Truncation (+T)}{
    The UT protocol variant wherein miners/validators refer to reflected headers using \emph{only} the least significant half of the hash.
    This effectively halves the hash size in throughput calculations for +OP and +HO variants
}

The idea behind +T is that the security of a truncated hash in bits, assuming $g > 2z$, is given by $8(\nicefrac{g}{2} + z)$\footnote{
    I use $g$ here, even though it's measured in bytes, for consistency with the rest of the whitepaper.
    A more rigorous method would measure everything in bits instead, and avoid the somewhat awkward multiplication by 8, but it's not important for this discussion.
}, and that this is \emph{always} sufficient, given that $z$ is intimately related to the largest reasonable attack that we could expect at that moment.
The $g > 2z$ condition is there for two reasons.
First, if $2z \ge g$ then the security of the truncated hash is just $8g$ bits, like normal.
Second, using significantly more than half the hash for PoW is problematic because the chance of collisions between valid headers increases dramatically.
So, intuitively, there is some breakpoint that we cross as the bits used for PoW increases.
Crossing that breakpoint indicates that the hash is no longer suitable for use in PoW -- we've ``maxed it out'' and need a hash with more bits, or a hash that is harder to generate (or slower, etc).
Therefore, there is also some similar and related breakpoint where the safety of hash truncation degrades.
Perhaps it does not degrade completely, but at least enough that partial collisions (without the required PoW) of the least significant bits become practical to generate.
Even though this shouldn't cause an issue for full and rigorous validation, it might open up DoS vectors, or other unforeseen exploits associated with optimizations or software patterns that might otherwise be safe.
Treating that breakpoint as $g \approx 2z$ should provide us a reasonable safety margin to avoid such issues --- if we get close to it, it's time to change the hash.

Combining +HO and +T gives us +HOT, the highest capacity variant of \UT{1}.
In this configuration: headers are smaller, the information required for PoR regeneration is minimal, and the number of chains per simplex within given constraints is maximal.
Since +T halves the effective hash length (which is all the data in the PoRs half of the block), the overall simplex capacity increases $2 \times$.


\begin{figure}[H]
\begin{equation*}
\xymatrix@R=14pt@!R@C=-24pt@!C@M=4pt{
    *+[F:<3pt>]{\text{Conservative}} \ar@{.>}[d] \\
     \text{UT}_{+\text{PoRs}} \ar@*{[gold]}[dr] \ar[rr] \ar[dd] & & \text{UT}_{+\text{OP}} \ar'[d][dd] \ar[dr] & \\
     & \text{UT}_{+\text{PoRTs}} \ar[dd] \ar@*{[gold]}[rr] & & \text{UT}_{+\text{OPT}} \ar@*{[gold]}[dd] \\
     \text{UT}_{+\text{HOPoRs}} \ar[dr] \ar'[r][rr] & & \text{UT}_{+\text{HO}} \ar[dr] & \\
     & \text{UT}_{+\text{HOPoRTs}} \ar[rr] & & \text{UT}_{+\text{HOT}} \\
     & & & *+[F:<3pt>]{\text{Maximal TPS}} \ar@{.>}[u]
}
\end{equation*}
\caption{
    Possible upgrade paths between UT variants, starting at $\UT{\text{+PoRs}}$ in the top left --- the most conservative variant.
    Solid arrows show paths of increasing capacity.
}
\end{figure}

<!-- \todoDraftOnly{uber optimization at mega cost? reflecting a block also reflects all blocks that it reflects? hmm. think this doesn't work b/c recursive PoR in a simplex would get stupid. also, what's the upper limit? each block can end up reflecting like $k^2$ blocks? pretty cray} -->

<!--

.dP"Y8 888888 88     .dP"Y8      d888         888888 88""Yb .dP"Y8
`Ybo."   88   88     `Ybo."     dP_______     88__   88__dP `Ybo."
o.`Y8b   88   88  .o o.`Y8b     Yb"""88""     88""   88"""  o.`Y8b
8bodP'   88   88ood8 8bodP'     `Ybo 88       88     88     8bodP'

-->


\input{includes/ut/content/27-practical/25-stateless-and-fraud-proofs.tex}


<!--

88""Yb  dP"Yb  88""Yb      dP""b8 88""Yb    db    88""Yb 88  88
88__dP dP   Yb 88__dP     dP   `" 88__dP   dPYb   88__dP 88  88
88"""  Yb   dP 88"Yb      Yb  "88 88"Yb   dP__Yb  88"""  888888
88      YbodP  88  Yb      YboodP 88  Yb dP""""Yb 88     88  88

-->

\input{includes/ut/content/27-practical/30-the-PoR-graph.tex}

<!--
%  dP""b8  dP"Yb  88b 88 888888     888888 88 8b    d8 888888 .dP"Y8
% dP   `" dP   Yb 88Yb88 88__         88   88 88b  d88 88__   `Ybo."
% Yb      Yb   dP 88 Y88 88""         88   88 88YbdP88 88""   o.`Y8b
%  YboodP  YbodP  88  Y8 88           88   88 88 YY 88 888888 8bodP'

conf times
-->

\subsection{Confirmation Times}

\label{sec:confirmation-times}

A confirmation is a *discrete* event that occurs when a block is produced. When an attacker is performing a hash-rate based doublespend attack, they are, effectively, racing the honest network; that race is measured in confirmations, not *time*.

```{=latex}
\bquote{
    The probability of success [of a double-spend attempt] depends on the number of blocks [by which the honest network has an advantage], and not on the time constant $T_0$.
}[Meni Rosenfeld; \citeAHBDS]
```

In a traditional blockchain (e.g., Bitcoin, Ethereum) confirmations occur, on average, at a predictable rate (that of the target block production frequency). Thus, for any *particular* traditional blockchain, a convenient time-based \emph{rule of thumb} can be devised, e.g., a Bitcoin transaction is safe to accept after 1 hour. However, this approximation only works because blocks (and thus confirmations) are only produced locally (to that blockchain) and at a probabilistic (roughly constant) rate. Put another way, the frequency of confirmations is identical to the frequency of blocks, $B_f$ Hz. Since $O(B_f) = O(1)$, the time-complexity of confirmation in these networks is also $O(1)$.

When using PoR, though, the assumptions behind that \emph{rule of thumb} do not hold --- while blocks on a single chain may be produced at a constant rate, that chain also gains a security benefit from other chains.
For the case of a 2-chain simplex (where those chains have the same block production frequency), the rate of confirmations will be twice the rate of block production.
This is easily generalized: for an $N_1$-simplex with simplex-chains that share some block frequency $B_f$, the rate of confirmation will be $\Cprime = N_1 \cdot B_f$ Hz.
Thus, the rate of confirmations has complexity $O(\Cprime) = O(N_1 \cdot B_f) = O(N_1) = O(c)$.

Let *confirmation time* be the duration breakpoint beyond which enough confirmations have occurred to consider a transaction *safe*. This is equivalent to the *rule of thumb* mentioned earlier.
For a traditional blockchain, as mentioned, this is the product of some constant and the expected duration between blocks: ${B_f}^{-1}$.
For a simplex, though, the expected *duration* is ${\mathbb{C}^\prime}^{-1} \propto \frac{1}{N_1 \cdot B_f}$.
Thus, as the simplex grows --- as $N_1$ *increases* --- the entire network's rate of confirmations also increases, and thus *confirmation time* approaches 0[^approach-zero].

[^approach-zero]: To say that confirmation time approaches 0 only tells the latter half of the process by which a transaction becomes confirmed. The first half of that process is *getting an initial confirmation*, which is effectively a small, but constant, overhead.

A 200-simplex with $B_f = \nicefrac{1}{15}$ has a confirmation rate of $\mathbb{C}^\prime = \nicefrac{40}{3} \approx 13.3$ Hz. An 800-simplex with $B_f = \nicefrac{1}{60}$ has the same confirmation rate. A 1400-simplex (the most optimized maximal simplex given \emph{Amaroo's} initial configuration) with $B_f = \nicefrac{1}{15}$ has $\mathbb{C}^\prime \approx 93$ Hz --- $\sim 46.5\times$ faster than EOS/Solana, $\sim 1116\times$ faster than Eth2, $\sim 1400\times$ faster than Eth1, and $\sim 55,800\times$ faster than Bitcoin.

Note that PoR incents miners to publish blocks as soon as possible so that those blocks begin gaining reflections.
If a miner does not publish a block immediately, then the reflections in that block become out-of-date very quickly as there are new, additional headers to reflect arriving constantly.
Additionally, any competing block (published immediately by an honest miner) will begin acquiring reflections earlier, and contains more valuable reflected headers (incenting other miners to subsequently reflect it).
So the published block has two distinct advantages over the withheld block.
This mitigates the selfish mining[^selfish-mining] attack.

[^selfish-mining]: See \citeSelfishMiningLink{} by Ittay Eyal and Emin Gün Sirer.

<!--

8888b.   dP"Yb  .dP"Y8     8888b.     db     dP""b8 .dP"Y8
 8I  Yb dP   Yb `Ybo."      8I  Yb   dPYb   dP   `" `Ybo."
 8I  dY Yb   dP o.`Y8b      8I  dY  dP__Yb  Yb  "88 o.`Y8b
8888Y"   YbodP  8bodP'     8888Y"  dP""""Yb  YboodP 8bodP'

-->

\input{includes/ut/content/27-practical/50-dags-00-all.tex}

<!-- \href{https://cloudflare-ipfs.com/ipfs/QmTDz4WuAXi2rV7Ei3pHHKTFCYGPeDbDoAkmypkHdJnnKe}{Secure High-Rate Transaction Processing in Bitcoin} by Yonatan Sompolinsky and Aviv Zohar. -->

<!--
\begin{comment}

# DAG BG plan

https://3.basecamp.com/4985262/buckets/20820958/messages/4184917383#__recording_4203214425

- Inclusive blockchain protocols details a method to define the order of blocks in a DAG.
    - This technique not only selects a main chain in a DAG, but also selectively incorporates blocks not on this canonical chain as long as they do not conflict.
- Conflicting transactions are ordered in the order that they arrived.


- sorting blocks
  - essence: prioritize execution based on security contribution (weight)
    - priority: goes first
    - can recursively apply through a dag
    - the specific details aren't important here (ref inclusive paper)
    - main details:
      - ordering is convergent and stable provided dag doesn't get to 'wide'
- conflicts
  - can be handled however the proto likes


goal: support this sentence (top of section):

> There are decisive advantages to using DAGs (instead of trees) as the fundamental structure of a chain. Namely, multiple histories (both compatible and incompatible) can be merged into a single, consistent history --- a feature which eliminates stale blocks and thwarts attacks like an empty-block Denial of Service

\end{comment}
-->


\subsection{Lowering Block Production Variance}

\label{sec:miner-resonance}

\todoDraftOnly[l]{redraft 'lowering block prod variance'}

Is it possible to *dramatically* lower the variance of block production in PoW blockchains without altering incentive structures, compromising security, or changing the probability of generating a valid block?

Yes. The method relies on the *structure* of the network, rather than the consensus protocol itself.
Particularly, the network must be structured such that miners' choices result in decreased block production variance --- an emergent phenomenon.
It's important that it is emergent and not synthetic (e.g., by increasing the block reward with time-since-last-block) because we don't want people to game the system.
It's better to have a simple system with emergent properties than a complex system with those properties \`\`designed in''.

Say you have a network with 10 chains: $C_0, C_1, C_2, ..., C_9$.
If the networks are separate, then you have 10 groups of miners: $M_0, M_1, M_2, ..., M_9$.
They have to choose one chain to mine on, so the distribution of miners is expected to be approximately the distribution of normalized block rewards plus tx fees.
The proportions of block rewards between $C_i$ & $C_j$ don't really matter, we expect the mining groups $M_i$ & $M_j$ to just sort themselves out due to market forces.
For simplicity, though, this example assumes that mining rewards and the distribution of miners is an even 10% across the board.

If the network has spare capacity (i.e., transactions are mostly cleared out with each block; the mempool for each chain is ~empty) then we have a situation like this:

Set $t=0$ immediately after a block is published on a chain.
Then, as $t$ progresses, transactions with fees should build up in the mempool, so $\text{TxFees} \propto t$.
The reward for mining a block is $r + \text{TxFees}$ for some block reward, $r$.
If $\text{TxFees} \propto t$ then $r + \text{TxFees} \propto K + t$ for some constant $K$.

The potential reward-over-time for a miner ($t$ vs $r + \text{TxFees}$) looks like a sawtooth function with a y-axis offset.
It builds as more transactions pile up, and drops back to the baseline reward after a block.

If the miners $M_0, ..., M_9$ are capable of working on one of any $\{C_0, ..., C_9\}$ (and they have identical ROI profiles to the other miners), then they're incented to work on the chain with the most transactions in the mempool. That means: miners should, roughly, work the chain that has gone the longest without a block. What should we expect based on those incentives? Miners should work on each chain only in the final moments of the block production cycle. If block times were set to 60s, then they'd start mining at around the 54s mark because that's how they maximize their ROI.

Why wouldn't they just keep mining on the same chain? Because in the time that they focused on one chain, another one passed that >54s high-ROI threshold and thus has the best ROI potential per hash done.

We should thus expect that this configuration of chains actually *synchronizes* miners, resulting in block production that is somewhat regular and lower in variance.

\defineTermTex{Miner Resonance}{
    The effect whereby block production \emph{variance} is reduced when miners can (and do) collectively change which chain they are currently mining faster than blocks are produced for those chains, due to changes in network-wide incentivization
}

One reason that we can predict that transactions will build up in this fashion (with those fees and in a predictable way) is that most of the transactions that are included in simplex blocks will be dapp-chain header-transactions.

The average hash-rate on each simplex-chain, as described above, is always the same regardless of which of the two miner strategies are used.
However, the variance of block production on each of these chains won't be that of a chain with 60s block times, it'll be closer to that of a chain with 6s block times.

%% END ### RELEASE

%% BEGIN ### DRAFT

\subsection{Reflection: Incentive and Censorship}

\todo{is a refl censorship attack possible? meaningful? explore. (NB: I don't think there's a viable strategy here, which is why I haven't prioritized writing this out.)}

\todo{
    Add a nash equilibrium diagram + explanation to show that it's always in the interest of miners to publish headers --- intuition: including headers means that the \emph{other chain's miner} has an incentive to include your header. that means that the next miner (on your chain) will be able to build on a heavier chain if they reflect that other chain's next header --- so that next miner (on the local chain) has an incentive to include that other chain's next header. If the original miner (who might chose not to publish the most recent header of that other chain) censors that reflection, then they disadvantage themselves relative to their competitors (other miners of that simplex-chain). Thus, it's never helpful to a miner to censor reflections (esp if we enforce the limit on $k_b$ and $k_{tx}$). It doesn't help honest miners, and it makes an attackers chain-segment less competitive.
}

Does a miner ever benefit from withholding reflections?

%% END ### DRAFT

%% BEGIN ### RELEASE

\subsection{Simplex Security and the Confirmation Equivalence Conjecture}

\label{sec:simplex-security-cec}

\input{27-practical/90-simplex-security-and-cec.tex}

%% END ### RELEASE

<!--

atk situations:
- global 51%
- local 51%
- bad block
- spv in presence of bad block
  - flag invalid blocks + spv requires uncontested block in main chain as soln?
- miners play invalid "tag" game (where 1 always claims the other's blocks are invalid so there's a back and forth)
- reflection censorship (not rly a problem)

-->

<!-- ### Exists $\implies$ Valid: Watching the Watchers -->

%% BEGIN ### RELEASE

\subsection{Intra-Simplex Cross-Chain Transactions}

\label{sec:spv-in-ut}

%% END ### RELEASE

%% BEGIN ### DRAFT

\input{27-practical/95-spv-requires-valid-state.tex}

%% END ### DRAFT

%% BEGIN ### RELEASE

\input{27-practical/95-spv-2-mk.tex}

\input{27-practical/98-ut1-protocol-summary.tex}

%% END ### RELEASE
