%% BEGIN ### RELEASE

## Practical Considerations for UT's Design

\label{sec:practical-considerations}

### Availability of Reflected Blocks

\label{sec:availability-of-blocks}

\todoDraftOnly{Review this section. Got some feedback that this section was unclear. Is nomenclature introduced prior to this section? check if there's something that interacts with DAGs and mention if so.}

What would happen if a header -- with valid PoW but *without* a valid block -- were to be reflected? Let's consider the two chains (L and R) from \autoref{fig:por-step5}.

That would mean that chain L contains a header, $H_{R,1a}$, for chain R for which no block is available.

This does not break chain R, but it could mean that other blocks on chain R temporarily have a harder time competing, or waste the resources of chain R nodes as they go looking for that block, $B_{R,1a}$.
Furthermore, it risks chain R miners doing SPV mining, which is bad.

\todo{i think the below is wrong. should probs rewrite section}

After $H_{R,1a}$ is reflected, chain R miners shouldn't build on that header without validating the block (so they should not mine on top of it).
Before long they'd produce an alternate valid block, $B_{R,1b}$.
But $B_{R,1b}$ (and its header, $H_{R,1b}$) wouldn't be reflected yet.
So $B_{R,1a}$ would have priority over $B_{R,1b}$ until $B_{R,2b}$ (building on $B_{R,1b}$) is created and both $H_{R,1b}$ and $H_{R,2b}$ are reflected.
After that, a minor chain re-org would restore normality.

There is at least one way to ensure that blocks of reflected headers are available.
That is: miners on both chain L and chain R should *refuse* to build on blocks that include headers without a known block.
This would mean that the chain L block (which includes $H_{R,1a}$) is *invalid* on chain L while $B_{R,1a}$ is unavailable.
If such a method is feasible, then the malicious chain L miner has greater opportunity cost to produce a block reflecting $H_{R,1a}$.
Moreover, this method prevents chain L (and its miners) from contributing to a potential attack on chain R.

For this to work, though, miners must verify that blocks *exist* for all reflected headers. Is this practical if there are $10^3$ or $10^4$ reflected chains in a simplex? The miners are only required to do very small amounts of computation on these other blocks, so their computational capacity won't be a bottleneck here. Furthermore, they don't need to keep these other blocks indefinitely, just long enough to be confident that they reflect only headers with existent blocks. So they won't need much extra disk space, either -- after a few years, the history of a simplex-chain will be larger than, say, the last 12 hours of all simplex-chains' histories combined. What miners will need is *bandwidth*.

The complexity and impact of this strategy is discussed in \autoref{sec:bandwidth-complexity}.

### Proving Reflection

\label{sec:proving-reflection}

If simplex-chains' consensus protocols require accounting for reflected work, then nodes must have some method whereby they know which work (in a particular chain's history) has been reflected.
That is: a node for chain L must be able to answer the question *For each other simplex-chain, which blocks in chain L's history have been reflected?*
This means that each node must have $N_1 - 1$ answers, per block, for a simplex of $N_1$ chains.

There is a trivial method: with each header, include the corresponding merkle branch which proves reflection.
Specifically: when a miner on chain L mines a block that includes a header from chain R, they should also include -- along-side the header -- a merkle branch that shows the most recent chain L ancestor that has been reflected by chain R.
For example, block $B_{L,i+1}$ might include a proof that $H_{L,i}$ was reflected by $B_{R,j}$.
That branch is the only required branch (i.e., the \emph{missing} branch), as chain L nodes are \emph{already} aware whether $H_{R,j}$ was reflected by $B_{L,i+1}$.

\begin{comment}
(Note: in some sense, the full PoR cannot be included *in* a newly created block, since the PoR depends *on* that newly created block. Although a miner can *commit* to a PoR when mining a block, the PoR can only be fully constructed after the relevant merkle-root has been calculated. It is possible to segment the block-creation process so that PoRs can be directly included, but this is clunky and arguably unnecessary.)
\end{comment}

Miners would need to do this for *all* simplex-chains that they reflect. Predictably, this has overhead with order $O(N_1 \cdot \log_2 N_1)$, where $N_1$ is the number of chains in the simplex. This method has complexity $O(c \cdot \log_2 c)$ which is discussed in \autoref{sec:complexity-reflection-proof}.

\defineTerm{Explicit Proofs (+PoRs)}{
    The UT protocol variant wherein miners/validators explicitly record \emph{both} reflected headers \emph{and} the single missing merkle branch required to prove reflection
}

Do we *need* to include proofs of reflection, though? Is it possible to avoid the explicit inclusion of those proofs, potentially allowing for $O(c)$ complexity instead?

If miners of any simplex-chain download the blocks of *all* simplex-chains -- as mentioned in \autoref{sec:availability-of-blocks} -- then including all necessary proofs of reflection can be made redundant. Since miners, theoretically, have all the necessary data to construct the proofs, do those miners need to actually include those proofs? Could we treat those proofs as witnesses and prune them -- similar to SegWit?

\defineTerm{Omitted Proofs (+OP)}{
    The UT protocol variant wherein miners/validators explicitly record \emph{only} reflected headers, such that necessary proofs of reflection are deterministically recalculable
}

There would be some downsides to omitting the proofs of reflection.
For one, it would mean that simplex-chain nodes, during an initial sync, would not be able to verify the PoRs without auxillary data -- potentially a lot.
Secondly, it would mean that miners *must* track the state of *all* reflections in the simplex for some period of time so that they ensure the integrity of the reflection protocol.
Given \autoref{sec:availability-of-blocks}, this is possible without significant overhead.

A practical method for treating proofs of reflection as witnesses that may be excluded/pruned is discussed in \autoref{sec:segmented-state}.

%% END ### RELEASE

%% BEGIN ### DRAFT

#### Verkle Trees and Shorter PoRs

\label{sec:verkle-proofs}

\emph{Verkle trees} are a new alternative to merkle trees.
Similar to merkle trees, they allow efficient proofs of membership against a cryptographically secure root.

\todo{probs remove -- not worth explaining here.}

%% END ### DRAFT

%% BEGIN ### RELEASE

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
}{Dr. Gavin Wood; \citeEthYellowPaperLink, s2}

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

### Exploiting Segmented State

\label{sec:exploiting-seg-state}

Given that the reflection-segments of simplex-chains will contain mostly redundant data (i.e., headers), numerous optimizations are possible.

For example, it's not necessary for a miner's node to re-download reflected headers since it already has most (or all) of them; that node just needs to know *which* headers are reflected and in what order.
Transmitting the \emph{hashes} of headers, only, reduces the effective size of simplex-blocks[^sb-size] from $b$ to $b \cdot (\frac{g + B_h}{2B_h})$, where $g$ is the size of the relevant digest in bytes.
For $g=32; B_h=112$, this reduces effective block size to $\sim 0.643 b$ --- an improvement of $\sim 35\%$.

[^sb-size]: Assuming those blocks dedicate 50% capacity to transactions, and 50% to reflected headers (without PoRs).

However, \emph{instead} of using that technique to \emph{minimize bandwidth} we could instead use it to \emph{maximize the number of simplex-chains}.
If simplex-blocks dedicate $\nicefrac{1}{2}$ of their capacity to reflections, then we can reduce that burden by $1 - \nicefrac{32}{B_h} \approx 70\%$, \emph{or} we could increase the capacity for reflections by $\nicefrac{B_h}{32} \approx 300\%$!

\defineTerm{Header Omission (+HO)}{
    The UT protocol variant wherein miners/validators explicitly record \emph{only} the hashes of reflected headers.
    A requirement is that block producers must eagerly download the headers of all simplex-chains and deterministically recalculate the relevant Proofs of Reflection
}

Starting with +PoRs, we have just reached the +HO variant via *omitting proofs* (+OP).
However, it is not the *proofs* that are redundant, but the *headers*.
Does *header omission* with *explicit proofs* provide any advantages? Yes.

Particularly, if miners include only the single missing merkle branch associated with the necessary PoRs, then *no additional information* is required besides the *header* itself.
Headers are trivial to acquire from the network, and each only needs to be acquired once, regardless of the number of PoRs it is a part of.
Since the *hash of each header* is *part* of the missing PoR merkle branch, miners only need to provided *an ordered list of merkle branches* for full PoR verifiability.
Additionally, these merkle branches *will be part of specific SPV proofs*, so when a cross-chain SPV transaction (that uses those branches) is made, it can omit those parts of the proof (replacing them with a pointer).

This UT protocol variant is +HOPoRs, the combination of *header omission* (+HO) and *explicit proofs* (+PoRs). It may present decisive advantages for implementations of *simplex tilings* (which are introduced in \autoref{sec:tiling}).

\aside{
    There is an independent protocol variant (from those above) called +T which provides a significant reduction to header size.
    % proof size and
    This optimization is currently redacted. \\
    \\
    Each protocol variant thus far has a corresponding +T variant, e.g., +PoRs and +PoRTs, +HO and +HOT, etc.
}

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
    Possible upgrade paths between UT variants, starting at $\UT{\text{+PoRs}}$ in the top left -- the most conservative variant.
    Solid arrows show paths of increasing capacity.
}
\end{figure}

### Confirmation Times

\label{sec:confirmation-times}

A confirmation is a *discrete* event that occurs when a block is produced. When an attacker is performing a hash-rate based doublespend attack they are, effectively, racing the honest network; that race is measured in confirmations, not *time*.

\bquote{
    The probability of success [of a double-spend attempt] depends on the number of blocks [by which the honest network has an advantage], and not on the time constant $T_0$.
}{Meni Rosenfeld; \citeAHBDS}

In a traditional blockchain (e.g., Bitcoin, Ethereum) confirmations occur, on average, at a predictable rate (that of the target block production frequency). Thus, for any *particular* traditional blockchain, a convenient time-based \emph{rule of thumb} can be devised, e.g., a Bitcoin transaction is safe to accept after 1 hour. However, this approximation only works because blocks (and thus confirmations) are only produced locally (to that blockchain) and at a probabilistic (roughly constant) rate. Put another way, the frequency of confirmations is identical to the frequency of blocks, $B_f$ Hz. Since $O(B_f) = O(1)$, the time-complexity of confirmation in these networks is also $O(1)$.

When using PoR, though, the assumptions behind that \emph{rule of thumb} do not hold -- while blocks on a single chain may be produced at a constant rate, that chain also gains a security benefit from other chains. For the case of a 2-chain simplex (where those chains have the same block production frequency), the rate of confirmations will be twice the rate of block production. This is easily generalized: for an $N_1$-simplex with simplex-chains that share some block frequency $B_f$, the rate of confirmation will be $\mathbb{C}^\prime = N_1 \cdot B_f$ Hz. Thus, the rate of confirmations has complexity $O(\mathbb{C}^\prime) = O(N_1 \cdot B_f) = O(N_1) = O(c)$.

Let *confirmation time* be the duration breakpoint beyond which enough confirmations have occurred to consider a transaction *safe*. This is equivalent to the *rule of thumb* mentioned earlier. For a traditional blockchain, as mentioned, this is the product of some constant and the expected duration between blocks: ${B_f}^{-1}$. For a simplex, though, the expected *duration* is ${\mathbb{C}^\prime}^{-1} = \frac{1}{N_1 \cdot B_f}$. Thus, as the simplex grows -- as $N_1$ *increases* -- the entire network's rate of confirmations also increases, and thus *confirmation time* approaches 0[^approach-zero].

[^approach-zero]: To say that confirmation time approaches 0 only tells the latter half of the process by which a transaction becomes confirmed. The first half of that process is *getting an initial confirmation*, which is effectively a small, but constant, overhead.

A 200-simplex with $B_f = \nicefrac{1}{15}$ has a confirmation rate of $\mathbb{C}^\prime = \nicefrac{40}{3} \approx 13.3$ Hz. An 800-simplex with $B_f = \nicefrac{1}{60}$ has the same confirmation rate. A 1400-simplex (the optimized maximal simplex given \emph{Amaroo's} initial configuration) with $B_f = \nicefrac{1}{15}$ has $\mathbb{C}^\prime \approx 93$ Hz. This is $\sim 46.5\times$ faster than EOS/Solana, $\sim 1116\times$ faster than Eth2, $\sim 1400\times$ faster than Ethereum, and $\sim 55,800\times$ faster than Bitcoin.

Note that PoR incents miners to publish blocks as soon as possible so that those blocks begin gaining reflections.
If a miner does not publish a block immediately, then the reflections in that block become out-of-date very quickly as there are new, additional headers to reflect arriving constantly.
Additionally, any competing block (published immediately by an honest miner) will begin acquiring reflections earlier, and contains more valuable reflected headers (incenting other miners to subsequently reflect it).
So the published block has two distinct advantages over the withheld block.
This mitigates the selfish mining[^selfish-mining] attack.

[^selfish-mining]: See \citeSelfishMiningLink{} by Ittay Eyal and Emin Gün Sirer.

### DoS and DAGs

\label{sec:dos-and-dags}

Up to this point, simplex-chains have been treated like traditional blockchains, where each block has only one parent.
Since the vast majority of a simplex-chain's security is provided by other simplex-chains (and only a small proportion comes from that chain's foundational consensus method), are attacks like an empty-block Denial of Service\footnote{
    For an example of this attack, see \citeLJCoiledcoinLink.
} (DoS) possible?
If a simplex-chain were to use PoW, then it might be (relatively) trivial for an attacker to perform such an attack.
This is because -- in traditional blockchains -- controlling more than 50% of the blocks produced provides *exclusive* control over *which candidate child blocks win* (i.e., are accepted into the canonical chain).\footnote{
    Exclusive control of this nature also allows for protocol changes via soft-forks.
    Additionally, because these soft-forks can be undetectable (when done well) and don't necessarily affect the income of a miner substantially, bribery (of miners) is theoretically inexpensive.
    WRT UT, this problem is resolved in \autoref{sec:preventing-dos-attacks}.
}
Is there a way that we can mitigate this risk?
If blocks were permitted *more* than a single parent, can this *exclusivity* be denied?

#### Block-DAG Lineage

\label{sec:block-dag-lineage}

The idea that blocks in a chain can have multiple parents -- i.e., the chain forms a Directed Acyclic Graph (DAG) that is not also a tree -- dates back to (at least) late 2013 with the publication of GHOST\footnote{
    \citeGhostFull{}
} by Sompolinsky and Zohar. However, GHOST disallows multiple *canonical* parents, and a chain using GHOST defines its *canonical history* -- the *main chain* -- via the chain formed exclusively from the first parent of each block. A block's other, non-canonical parents are linked to *only* for the purpose of contributing to the total chain-weight.

In the two years after GHOST was published, a number of DAG-based blockchain designs were developed that facilitated merging histories from multiple parent blocks.

In mid-2014 I created a prototype DAG-based blockchain called Quanta[^quanta-2014] with a novel method of linearization that converged to a complete and stable ordering of blocks.
This method was independently rediscovered[^redisc] in mid-2015 by Lewenberg, Sompolinsky, and Zohar[^inclusive-july-2015] -- who also further developed and analyzed the method, which they named *the inclusive protocol*.
Additionally, in 2016 Paul Firth further developed Quanta in his *Trustless Eventual Total Order* draft.[^teto-2016]

In late-2015 several new, alternative methods were also published, however these are not generalizations of Nakamoto consensus. Namely: Lerner's DagCoin[^dagcoin-sept-2015], and IOTA's Tangle[^iota-oct-2015]. Since then, multiple other models have been proposed, and some built.

For the purposes of this paper, we are concerned with the method detailed in *Inclusive Block Chain Protocols*.

<!-- \href{https://cloudflare-ipfs.com/ipfs/QmTDz4WuAXi2rV7Ei3pHHKTFCYGPeDbDoAkmypkHdJnnKe}{Secure High-Rate Transaction Processing in Bitcoin} by Yonatan Sompolinsky and Aviv Zohar. -->

[^quanta-2014]: \href{https://github.com/XertroV/quanta-test/blob/ba598d5fe89d3b16db07533957a2080edb19a9cd/quanta.py\#L157}{Quanta source code}, \href{https://bitcointalk.org/index.php?topic=1057342}{Quanta BitcoinTalk thread}.

[^dagcoin-sept-2015]: \href{https://cloudflare-ipfs.com/ipfs/QmbXhgQzN8FPFLiJoVApHvT1vf3xZUGefvD5GdfYPHuBpe}{DagCoin Draft} by Sergio Demian Lerner.

[^iota-oct-2015]: \href{https://bitcointalk.org/index.php?topic=1216479.0}{IOTA BitcoinTalk thread}.

[^inclusive-july-2015]: \citeInclusiveFull{}

[^redisc]: As far as I can tell, the linearization methods produce identical results.

[^teto-2016]: \href{https://github.com/wildbunny/docs/blob/master/T.E.T.O-draft.pdf}{T.E.T.O Draft} by Paul Firth.

##### A Criticism of GHOST

GHOST allows for blocks to link to a single canonical parent and multiple *uncle* blocks.
In the full GHOST algorithm, uncle blocks contribute *weight* to the canonical chain-segment, but do not contribute *transactions*.
Thus, uncles have *no ability* to substantially contribute to the canonical chain's *state*.

Consider an empty-block DoS against a chain using GHOST.
If an attacker were to perform an empty-block DoS, the attacker could link back to honest miners' blocks as uncles, but never parents.
Given this, there is no easy way for the honest miners to end or mitigate the DoS.
The attacker can include honest miners' chain-work in a purely *beneficial* way -- there is a symmetry, thus honest miners (and the network) are at the mercy of the attacker.

Why does this symmetry exist?
Because the *cumulative weight* of each block (including uncles) is *divorced* from *the set of transactions* that is contributed by that block.
However, with a full DAG-chain, when an attacker links to uncles in this way *they must allow for the execution of all non-conflicting transactions* (i.e., those which would not cause a doublespend to occur).
Thus, GHOST *does not mitigate* empty-block DoS attacks; *only* a full DAG-chain can do that.

#### Basic Structure

There are decisive advantages to using DAGs (instead of trees) as the fundamental structure of a chain.
Namely, multiple histories (both compatible and incompatible) can be merged into a single, consistent history -- a feature which eliminates stale blocks and thwarts attacks like an empty-block DoS.
UT's simplex-chains must be block-DAGs to remain functional and avoid such DoS attacks.

\textbf{Note:} often the motivation for using a block-DAG instead of a block-tree is to increase the block frequency.
Since block-DAGs can reference multiple previous blocks, the stale-rate can approach (or reach) 0.
Increasing the block frequency is counter-productive in UT, though, since UT is sensitive to the size and number of headers that are produced (see \autoref{sec:impact-of-header-size}).
In UT, the purpose of using block-DAGs is to thwart certain attacks, not to increase the block frequency.
The intention is for UT simplex-chains to use fairly typical block frequencies (e.g., 15s) -- possibly decreasing those frequencies over time to increase capacity.
Slower block frequencies also decrease incidence of multiple parents (each parent typically increases the header size by 32 bytes).

Some basic block-dag segments are shown in \autoref{fig:dag-simple-segments}.

\begin{figure}[h]
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

> There are decisive advantages to using DAGs (instead of trees) as the fundamental structure of a chain. Namely, multiple histories (both compatible and incompatible) can be merged into a single, consistent history -- a feature which eliminates stale blocks and thwarts attacks like an empty-block Denial of Service

\end{comment}
-->

The essence of DAG-based consensus (at least the kind we're concerned with) is to *prioritize execution* of blocks and transactions based on the *security contribution* (i.e., weight) of each parent block (and that parent's ancestry).
Based on a *most recent common direct[^directanc] ancestor*, we can decide which parent's *history* has priority execution.
Prioritized blocks are positioned *earlier* in the final ordering.

[^directanc]: In DAG (or DAG-like) chains, direct ancestors are sometimes called the *pivot chain* or *main chain*.
Provided that parent blocks *are sorted by cumulative work*, the chain of *direct ancestors* between a given block and the genesis block must be the *single heaviest path* between the two. (This is the case for UT.)

Let's limit DAG-chain blocks to two parents. If the best block has two parents, then each parent will have a *subgraph of blocks* between itself and the *most recent common direct ancestor* of the two parents.
The subgraph which takes priority is that of the *prioritized parent's ancestry*.
If that subgraph is a chain, then the ordering and execution of blocks is trivial.
If it is not, then there must be another subgraph within that subgraph, and this algorithm is applied recursively.
After the prioritized subgraph is processed, the remaining blocks (those that are only ancestors of the remaining parent block) are ordered and applied -- invoking recursion where necessary.
Finally, the best block is applied.
In this way, all blocks are executed after their ancestors, and there is a clear and total ordering that trivially converges.

In the case that more than two parent blocks are permitted, there is a trivial generalization of the above.
That is: replace \emph{all} but the last (worst) parent with a *virtual parent block* that links back to all remaining *actual* parent blocks (but contributes zero block-weight itself).
Replacing the best parents (rather than the worst parents) with a virtual block means that the fork rule works automatically.
This can be repeated to allow for arbitrarily many parents.

\autoref{fig:dag-ex1-full} is an example of this algorithm for a moderately complex chain-segment ($B_i\cdots B_{i+3}$ which is 7 blocks total), and each step is enumerated and explained.

\begin{figure}[p]
    \caption[
        Example: sorting a moderately complex block-DAG.
    ]{
        Example: sorting a moderately complex block-DAG; note that the left parent is always the best parent, so will have priority. Each block is annotated with its \emph{chain-weight} ($\Sigma_w$). \label{fig:dag-ex1-full}}
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_sag}
        \vspace{0.55em}
        \caption{How should we order this block-DAG? Note: children should \emph{always} be after their parents, and \emph{prioritization} means \emph{earlier execution}.}
        \label{fig:dag-ex1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_00_sag}
        \caption{The first thing we should do is create any virtual nodes that are required ($V_{i+2,1}$).}
        \label{fig:dag-ex1-order-00}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_10_sag}
        \caption{Since there are two parents, we look at the \emph{prioritized subgraph} (i.e., most worked).}
        \label{fig:dag-ex1-order-10}
    \end{subfigure}

    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_20_sag}
        \caption{Again, there are two parents, so we look at the \emph{next} prioritized subgraph.}
        \label{fig:dag-ex1-order-20}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_30_sag}
        \caption{We've found a chain. These blocks have the highest priority, so are executed first.}
        \label{fig:dag-ex1-order-30}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_40_sag}
        \caption{We're now \emph{ordering} the blocks -- the solid arrows represent the final ordering. In this step we order the highest priority blocks.}
        \label{fig:dag-ex1-order-40}
    \end{subfigure}

    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_50_sag}
        \caption{Now that the highest priority blocks are ordered, we can order the \emph{previous} subgraph.}
        \label{fig:dag-ex1-order-50}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_60_sag}
        \caption{Once more, we order the next-in-line subgraph.}
        \label{fig:dag-ex1-order-60}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{dag_example1_expanded_order_70_sag}
        \caption{And finally we order the last remaining blocks. (We could remove virtual blocks too).}
        \label{fig:dag-ex1-order-70}
    \end{subfigure}
    %$\text{Note: caption at top.}$
\end{figure}

We should expect that conflicting transactions (which might otherwise be attempted doublespends) arise during this process.
Ancestors of one parent may not be ancestors of another parent.
The exact protocol for handling conflicts is up to the implementation, but a trivial method is that blocks commit to (via hash-pointers) conflicting transactions.
If a miner produces an invalid block (which is invalid only because it breaks this rule), then other miners can flag it as a conflicting *block* via a similar mechanism.

Further reading: \citeInclusive{}.

#### Preventing DoS Attacks

\label{sec:preventing-dos-attacks}

Consider the situation where an attacker is attempting to deny service via the production of empty blocks, and that the attacker can create blocks faster than the honest network. Such a situation is illustrated in \autoref{fig:dag-dos-1}. Since the goal of the attack is to prevent transactions from occurring, the attacker must[^nb-must] produce empty blocks[^empty-nb]. Furthermore, if the attacker links back to any honest blocks then the honest blocks' histories will be merged with the canonical history; thus the attack would fail. The attacker's only available strategy is to produce a single chain of empty blocks.

[^nb-must]: The attacker could also fill the blocks with spam transactions. That's more work for the attacker, but also more work for the honest network (calculating and storing that state, maybe indefinitely). It's preferable that the attacker has minimal transactions in their blocks. It's tempting to think of ideas like: \emph{since the attacker's blocks are empty, we can let honest nodes make larger blocks via some kind of weighted average block size calculation plus some flexibility in the size of blocks produced}. The problem with this is that it incents the attacker to fill their blocks with spam transactions, which is counterproductive.

[^empty-nb]: Note that the attacker should still be reflecting other simplex-chains so as to maximize the total weight of the attacker's chain-segment. Given this, the attacker's blocks will contain reflected simplex-chain headers but no transactions.

\begin{figure}
    \centering
    \includegraphics[width=\linewidth]{dag_dos1_sag}
    \caption[
        An attempted DoS attack on a block-DAG.
    ]{
        An attempted DoS attack on a block-DAG.
        The attacker's blocks, $A_j$, contain no transactions.
        Each block is annotated with its \emph{chain-weight} ($\Sigma_w$).
        Even though the attacker produces $2\times$ as many blocks as the honest network, the attack inevitably fails after a short while.
        NB: $H_i$ is defined to have $\Sigma_w = 0$ for illustrative convenience.
    }
    \label{fig:dag-dos-1}
\end{figure}

How does such an attack fair?
The challenge of such a DoS attack is to prevent honest miners from extending the attacker's chain-segment.
For traditional (non-DAG) chains -- where each non-genesis block has exactly one parent -- this is accomplished as soon as the attacker is able to reliably produce a heavier chain-segment than the honest network for a given period.
(Typically, this means the attacker produces blocks more frequently.)

However, if blocks are allowed to have *more* than one parent then there *is no point* where an attacker can *maintain* a DoS attack indefinitely. Instead, they can only *delay the execution* of some transactions for a short period of time.
Particularly, if an attacker can produce $A_{blocks} = \nicefrac{q}{p} > 1$ for every 1 block produced by the honest network, then the attack can delay transactions for up to $A_{blocks} \cdot {B_f}^{-1}$ seconds, where $B_f$ is the frequency of block production (in Hz).
After this (approximate) point, the weight of the honest chain-segment, which includes the attacker's chain-segment, is always greatest.

If an attacker performs a *repeating cycle* of these attacks, then they may be able to decrease the effective capacity of the chain by a factor of $A_{blocks} = \nicefrac{q}{p}$.
The opportunity cost of this attack, for the attacker, is at least as much as the lost transaction fees.

All that sounds okay so far (maybe not that last bit), but this thought experiment is flawed. It is *smoothed out* compared to what we'd expect in reality -- the discrete and probabilistic natures of block production and reflections are ignored. In \autoref{fig:dag-dos-1}, those're explicitly excluded! What happens if we include the effect of other simplex-chains, though? Well... something \emph{magical}.

Consider an attacker producing 2 blocks for every 1 honest block.
What happens most of the time?
Well the attacker's blocks get reflected first, so those blocks have an appreciable advantage over the honest blocks.
The honest blocks will get reflected, too, but most of the time the attacker's blocks will get the advantage from earlier reflections.
\emph{Most} of the time.
Occasionally, when an honest block is a bit lucky, an honest block will beat the attacker's next block -- gaining reflections earlier.
At that point, the attacker has lost -- they need to outpace the \emph{difference} in the number of reflections between the honest block and attacking blocks.
So, unlike a normal doublespend (where the attacker wins if they \emph{ever} get ahead), now the honest network wins (ends the DoS) if it \emph{ever} gets ahead of the attacker -- after that point, there's no viable strategy for the attacker besides to build on the honest blocks.
\emph{The asymmetry has flipped!}

\begin{comment}
- mk
cut from after "when an honest block is a bit lucky":
> (which will be more often if there's \emph{miner resonance})
it's worth noting the convergence better than we do atm (right now, that's: "If there were, it'd be possible to temporarily limit the attacker to $<50\%$ of mining power, ending the DoS quickly. (See \autoref{sec:miner-resonance}.))"
\end{comment}

There's more that can be done here, too, like honest users (not necessarily miners) creating transactions (with large fees) that depend on certain history (i.e., that some honest block is in the history of the chain).
That will attract miners from other chains due to unrealized RoI (potentially a lot).
The attacker could include that transaction, but then they need to voluntarily end the DoS themselves.
If you're worried about that, because it seems like miners might empty-block DoS simplex-chains, consider: when in equilibrium, that situation is essentially the same as an efficient market (for transaction execution).

Is there a reasonable strategy whereby the honest network can temporarily increase the number of miners?
If there were, it'd be possible to temporarily limit the attacker to $<50\%$ of mining power, ending the DoS quickly.
(See \autoref{sec:miner-resonance}.)



\todoDraftOnly{The above should work for simplex-chains *and* dapp-chains}

\todoDraftOnly{Dynamic average block-size for simplex-chains based on dapp-chain headers having some PoW}

%% END ### RELEASE

%% BEGIN ### RELEASE

### Lowering Block Production Variance

\label{sec:miner-resonance}

\todoDraftOnly{redraft 'lowering block prod variance'}

Is it possible to *dramatically* lower the variance of block production in PoW blockchains without altering incentive structures, compromising security, or changing the probability of generating a valid block?

Yes. The method relies on the *structure* of the network, rather than the consensus protocol itself.
Particularly, the network must be structured such that miners' choices result in decreased block production variance --- an emergent phenomenon.
It's important that it's emergent and not synthetic (e.g., by increasing the block reward with time-since-last-block) because we don't want people to game the system.
It's better to have a simple system with emergent properties than a complex system with those properties \`\`designed in''.

Say you have a network with 10 chains: $C_0, C_1, C_2, ..., C_9$. If the networks are separate, then you have 10 groups of miners: $M_0, M_1, M_2, ..., M_9$. They have to choose one chain to mine on, so the distribution of miners is expected to be approximately the distribution of normalized block rewards + tx fees. The proportions of block rewards between $C_i$ & $C_j$ don't really matter, we expect the mining groups $M_i$ & $M_j$ will just sort themselves out due to market forces. For simplicity, though, this example assumes that mining rewards and the distribution of miners is an even 10% across the board.

If the network has spare capacity (i.e., transactions are mostly cleared out with each block; the mempool for each chain is ~empty) then we have a situation like this:

Set $t=0$ to be immediately after a block is published on a chain. Then, as $t$ progresses, transactions with fees should build up in the mempool, so $\text{TxFees} \propto t$. The reward for mining a block is $r + \text{TxFees}$ for some block reward, $r$. if $\text{TxFees} \propto t$ then $r + \text{TxFees} \propto K + t$ for some constant $K$.

The potential reward-over-time for a miner ($t$ vs $r + \text{TxFees}$) looks like a sawtooth function with a y-axis offset. It builds as more transactions pile up, and drops back to the baseline reward after a block.

If the miners $M_0, ..., M_9$ are capable of working on one of any $\{C_0, ..., C_9\}$ (and they have identical ROI profiles to the other miners), then they're incented to work on the chain with the most transactions in the mempool. That means: miners should, roughly, work the chain that has gone the longest without a block. What should we expect based on those incentives? Miners should work on each chain only in the final moments of the block production cycle. If block times were set to 60s, then they'd start mining at around the 54s mark because that's how they maximize their ROI.

Why wouldn't they just keep mining on the same chain? Because in the time that they focused on one chain, another one passed that >54s high-ROI threshold and thus has the best ROI potential per hash done.

We should thus expect that this configuration of chains actually *synchronizes* miners, resulting in block production that is somewhat regular and lower in variance.

\defineTerm{Miner Resonance}{
    The effect whereby block production \emph{variance} is reduced when miners can (and do) collectively change which chain they are currently mining faster than blocks are produced for those chains, due to changes in network-wide incentivization
}

One reason that we can predict that transactions will build up in this fashion (with those fees and in a predictable way) is that most of the transactions that are included in simplex blocks will be dapp-chain-header-transactions.

The average hash-rate on each simplex-chain, as described above, is always the same regardless of which of the two miner strategies are used.
However, the variance of block production on each of these chains won't be that of a chain with 60s block times, it'll be closer to that of a chain with 6s block times.

%% END ### RELEASE

%% BEGIN ### DRAFT

### Reflection: Incentive and Censorship

\todo{is a refl censorship attack possible? meaningful? explore. (NB: I don't think there's a viable strategy here, which is why I haven't prioritized writing this out.)}

\todo{
    Add a nash equilibrium diagram + explanation to show that it's always in the interest of miners to publish headers -- intuition: including headers means that the \emph{other chain's miner} has an incentive to include your header. that means that the next miner (on your chain) will be able to build on a heavier chain if they reflect that other chain's next header -- so that next miner (on the local chain) has an incentive to include that other chain's next header. If the original miner (who might chose not to publish the most recent header of that other chain) censors that reflection, then they disadvantage themselves relative to their competitors (other miners of that simplex-chain). Thus, it's never helpful to a miner to censor reflections (esp if we enforce the limit on $k_b$ and $k_{tx}$). It doesn't help honest miners, and it makes an attackers chain-segment less competitive.
}

Does a miner ever benefit from withholding reflections?

%% END ### DRAFT

%% BEGIN ### RELEASE

### Simplex Security and the Confirmation Equivalence Conjecture

\label{sec:simplex-security-cec}

\input{27-practical/90-simplex-security-and-cec.tex}

%% END ### RELEASE
