%% BEGIN ### RELEASE

## Proof of Reflection

\label{sec:proof-of-reflection}

\aside{
  A note on the term ``miner'': Consensus protocols sometimes choose a new name for the role of \emph{block producer}.
  For example: ``validator'', ``baker'', ``collator'', etc.
  In this document, the term ``miner'' refers to the generic role of \emph{block producer} in an inclusive sense, not specifically to block producers of PoW chains.
}

Can blockchains work cooperatively to secure each other? It certainly seems that there is nothing *in principle* that prohibits this. Can we come up with a way to do this?

The idea of one blockchain 'tracking' another blockchain via chain-headers and its state via SPV proofs is not new. In 2013[^xc1], I (loosely) proposed a system which used this method to support rich cross-chain exchange. I wrote a simplified implementation of this method in the very early days of Ethereum[^xc3], a precursor to the later-successful BTC Relay[^xc4]. The general idea of one blockchain tracking the headers of another will be our starting point.

[^xc1]: <https://bitcointalk.org/index.php?topic=198032.0>, <https://bitcointalk.org/index.php?topic=598784.0>
[^xc3]: <https://github.com/XertroV/coppr/blob/master/chainheaders.py>
[^xc4]: <https://github.com/ethereum/btcrelay>

The general idea of an on-chain headers-only version of another chain does not -- to my knowledge -- have a name. Herein this is called a *projection*. The generalized process via which projections are created is called *imaging*.

\defineTerm{Projection}{
  A \emph{projection} of a chain is its \emph{headers-only} version which is recorded and evaluated \emph{by a different chain}. For example \href{https://github.com/ethereum/btcrelay}{BTC Relay} is a smart contract by which Ethereum can host a \emph{projection} of Bitcoin. The \emph{act} of one chain creating and maintaining the reflection of another is called \emph{imaging}
}

### A Projection of Bitcoin in Ethereum

The idea that Ethereum smart contracts (SCs) can track Bitcoin chain-headers is well understood -- i.e., Ethereum *images* Bitcoin. The result of this is that the *projection* of Bitcoin is available to Ethereum users and SCs. Bitcoin's proof of work algorithm is clean and simple, so implementing the necessary logic in an Ethereum SC is viable. In principle, any chain that supports some headers-only mode can include projections in this way. In practice that can be difficult (e.g., Ethereum's EVM doesn't support memory hard hashes unless special cases are introduced). But we're not interested in practicality *at the moment*.

Let's add such a contract to Ethereum and describe the relevant data and events in the following table. \autoref{fig:pr-btc-eth-step1} illustrates this. Note: \autoref{fig:pr-btc-eth-step1} includes some variance in Ethereum's block production rate, similar to what might be observed in a real-world environment.

| Time (~15s increments) | Bitcoin block made | Eth block made | Eth block contents | Eth state |
|---|---|---|-----|------|
| $\vdots$ | | | | |
| 0 | k | | | |
| 1 | | j | $\text{BTC}_k$ header | Records $\text{BTC}_{0 \cdots k}$ |
| $\vdots$ | | | | |
| 40 | k + 1 | | | |
| 41 | | j + 40 | $\text{BTC}_{k+1}$ header | Records $\text{BTC}_{0 \cdots k+1}$ |
| $\vdots$ | | | | |

: Data and events for both Bitcoin and Ethereum as blocks are produced and a projection of Bitcoin in Ethereum is maintained via Bitcoin headers being included in an Ethereum SC.

\begin{figure}[]
\centering
\includegraphics[max width=\linewidth, height=0.35\textheight]{pow_refl_btc_eth_step1_sag}
\caption{Bitcoin headers, as they are produced, are included in Ethereum's state (via user made transactions). This is roughly how \textit{BTC Relay} works.}
\label{fig:pr-btc-eth-step1}
\end{figure}

After a Bitcoin block is produced, an Ethereum miner includes a transaction containing the Bitcoin header, which updates the SC imaging the Bitcoin chain. In reality there are practical concerns about incenting someone to produce such a transaction (among other things); we're not concerned with those here. We're just concerned with the relationships that exist and what they can do.

Why would a chain want to include a projection of another chain? The typical answer is to prove transactions or state occurred on the foreign chain. On Ethereum, one could build a trustless $\text{BTC}\leftrightarrow\text{ETH}$ market, for example.

### Incremental Implementation of Proof of Reflection

\label{sec:two-blockchains}

Let's build up the idea via a hypothetical situation with two distinct blockchains. For simplicity, you can imagine these as Bitcoin and Ethereum 1 -- at least to start with. However, keep in mind that the changes required to support *Proof of Reflection* are unlikely to ever be integrated with either Bitcoin or Ethereum (and reaching social agreement about the details would be difficult, to say the least).

Our starting case is that both chains use different Proof of Work algorithms and neither includes a projection of the other. For simplicity, the following progression will use two blockchains with identical block times, and will not account for variance in block production.

#### Step 1. Chain R images Chain L

This is conceptually similar to having a projection of Bitcoin in Ethereum, and shown in \autoref{fig:pow_refl_step1}.

\begin{figure}
\centering
\includegraphics[max width=\linewidth, height=0.28\textheight]{pow_refl_step1_sag}
\caption{Step 1: Chain R images Chain L; thus Chain R hosts a \emph{projection} of Chain L.}
\label{fig:pow_refl_step1}
\end{figure}

Similar to before, Chain R will include Chain L's headers as they are produced. Note that this can be a protocol-level implementation; it does not have to be at the smart contract level -- as it would be with Ethereum.

#### Step 2. Chain L images Chain R

Say that the protocol of Chain L is extended to support a projection of Chain R. That is, a bespoke protocol extension is created that allows/requires miners to publish known Chain R headers along with their Chain L block. Similar to the way Chain R images Chain L, now Chain L also images Chain R. This is shown in \autoref{fig:pow_refl_step2} and the following table.

\begin{table}[H]
\centering
\caption{Both Chain L and Chain R host a projection of each-other.}
\resizebox{\textwidth}{!} {%
\begin{tabular}{lllllll}
\toprule
{Time} & {L block made} & {L block contents} & {L state} & {R block made} & {R block contents} & {R state} \\
\midrule
{$\vdots$} & {} & {} & {} & {} & {} & {} \\
{0} & {k} & {$R_{j-1}$ header} & {Records $R_{0 \cdots j-1}$} & {} & {} & {} \\
{1} & {} & {} & {} & { j} & {$L_{k}$ header} & {Records $L_{0 \cdots k}$} \\
{2} & {k + 1} & {$R_{j}$ header} & {Records $R_{0 \cdots j}$} & {} & {} & {} \\
{3} & {} & {} & {} & {j + 1} & {$L_{k+1}$ header} & {Records $L_{0 \cdots k+1}$} \\
{$\vdots$} & {} & {} & {} & {} & {} & {} \\
\bottomrule
\end{tabular}%
}
\end{table}


\begin{figure}[p]
\centering
\includegraphics[max width=\linewidth, max height=0.4\textheight]{pow_refl_step2_sag}
\caption{Step 2: Chain L and Chain R contain a projection of each other's header-only chain.}
\label{fig:pow_refl_step2}
\end{figure}

#### Step 3. Chain L's *reflection* in Chain R

Can we use a projection of a chain for a different purpose? What happens if Chain L tracks whether Chain L's history is confirmed within Chain R? This can be done via merkle branches that prove the particular states of Chain R which contain this information. In essence, Chain L uses its projection of Chain R to prove that its *own history* matches that of it's *projection* in Chain R. Chain L proves that it is *reflected* in Chain R.

What does this proof look like? The following progression is shown in \autoref{fig:por-step3-parts}. First, Chain L must prove that it's history is reflected, so we first find the most recently reflected header, $L_{i+1}$ (ideally, this is the previous L block). Secondly, we want to prove that $L_{i+1}$ is also the \emph{best block} (for Chain L) according to \emph{Chain R's} projection of Chain L, using the best known R block, $R_{j+1}$. For that, we need a merkle branch showing $L_{i+1}$ is part of $R_{j+1}$'s state -- this is sometimes referred to as the \emph{missing} merkle branch. Thirdly, we want to prove that $R_{j+1}$ is the \emph{best block} according to Chain L's projection of Chain R. We can do that via a merkle branch, too, but full nodes of Chain L already know whether $R_{j+1}$ is the best block or not, so this branch doesn't need to be explicit. However, L's nodes must be able to generate it. The \emph{full} collection of information required to prove reflection is called a *proof of reflection*.

\begin{figure}[H]
    \begin{subfigure}[t]{.31\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{pow_refl_step3_1_sag}
        \caption{Find the most recently reflected L block.}
        \label{fig:por_step3-part1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{pow_refl_step3_2_sag}
        \caption{Prove that block is known to the most recently reflected R block.}
        \label{fig:por_step3-part2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{pow_refl_step3_3_sag}
        \caption{Prove that R block is known to the current L block.}
        \label{fig:por_step3-part3}
    \end{subfigure}
    \caption{Incrementally constructing a \emph{proof of reflection}.}
    \label{fig:por-step3-parts}
\end{figure}

Segments of Chain L and R (events and data) are shown in the following table and \autoref{fig:por-step3}.

| Time | L block made | L block contents | L state | R block made | R block contents | R state |
|--|---|------|------|---|-----|------|
| $\vdots$ | | | | | | |
| 0 | k | $R_{j-1}$ header + Merkle proof of $L_{k-1}$ | Records $R_{0 \cdots j-1}$ *and* knows that Chain R records $L_{0 \cdots k-1}$ | | | |
| 1 | | | | j | $L_{k}$ header | Records $L_{0 \cdots k}$ |
| 2 | k + 1 | $R_{j}$ header + Merkle proof of $L_{k}$ | Records $R_{0 \cdots j}$ *and* knows that Chain R records $L_{0 \cdots k}$ | | | |
| 3 | | | | j + 1 | $L_{k+1}$ header | Records $L_{0 \cdots k+1}$ |
| $\vdots$ | | | | | | |

: Chain L records which of its headers are known about by Chain R. That is: Chain L includes *proofs of reflection*.

\begin{figure}[p]
\centering
\includegraphics[max width=\linewidth, max height=0.4\textheight]{pow_refl_step3_sag}
\caption{Step 3: Chain L includes \textit{proofs of reflection} (PoRs) along with headers. Proofs of Reflection allow Chain L to know which of its own blocks are known to Chain R.}
\label{fig:por-step3}
\end{figure}

Chain L now knows *which L blocks are recorded by Chain R*, i.e., which local blocks are known about by some external source. Put another way: Chain L's history is confirmed *not only* by new Chain L blocks, *but also* by Chain R blocks. There's no data-availability concern here since Chain L nodes *know* that they have the blocks that Chain R knows about.

**Important:** Soon, these confirmations will have real and useful meaning. Under the right conditions, an appropriate configuration of *Proof of Reflection* results in an increase in the *rate* that confirmations are acquired. This is the first hint of $\frac{1}{O(c)}$ confirmation time.

At this point, if an attacker was to publish an alternate, better Chain L history, then Chain L nodes would reorganize around the *new* history published by the attacker, and the attacker's block headers would end up being recorded in Chain R and causing a reorganization there, too. Currently, this configuration does not add any security to Chain L.

Could we use Chain L's knowledge *that it's own history is reflected in Chain R* to *prevent* such an attack?

#### Step 4. One Way Reflection

\label{sec:por-step4}

Before we discuss a change that Chain L could make, it is important to note that chain-work done with one hashing algorithm is *not generally convertible* to 'equivalent' work done via another hashing algorithm.
For example, there is no meaningful *generic* answer to the question *how many double SHA256[^btc2sha] hashes is one Ethash hash worth?*

[^btc2sha]: Bitcoin uses $\text{Hash}(x) = \text{SHA256}(\text{SHA256}(x))$ as it's PoW hash.

For the purposes of our hypothetical construction, let's say that L and R do *equal work over equal time*. In the current example, that means that the work required to produce either $L_i$ or $R_j$ is the same. *For the sake of this construction, we'll also presume this relationship doesn't change over time*. Our constant of conversion is thus: 1 *R Blocks per L Block*.

NB: we're not that concerned with whether this is a reasonable assumption in the real world or not; right now, we just need a way to convert the work done on each chain into the same units.
(Some methods for doing this will be discussed in \autoref{sec:comparing-diff-pows}.)

Currently, the Chain L network chooses the \`\`heaviest'' (most worked) chain as its common history. Chain L calculates the \`\`weight'' of blocks (i.e., how much work went in to them) via an estimation of how many hashes were required -- say these are measured in *double SHA256 hashes*. For the purposes of illustration, let's normalize this number to be in terms of *L Blocks* -- instead of *double SHA256 hashes*; that's easy, since each block is worth 1 *L Block* by definition. Now, we can also measure the work in *R Blocks*, too (that being: 1 *R Block*).

How can the network choose the heaviest chain? Well, a traditional blockchain might use a simple recursive function like \autoref{alg:vanilla-bw}.

\input{includes/ut/algorithms/vanilla-chainweight.tex}

Could Chain L incorporate the idea that Chain R had confirmed part of its history? Could Chain L use this to thwart some types of attack?

Yes, and we must modify the block-weight calculation so that it accounts for work contributed by Chain R. Such an algorithm is described in \autoref{alg:refl-1-bw}. Essentially, additional weight is added to a block when it is *the best block* known to Chain R, i.e., according to Chain R it is at the tip of Chain L. Note that this weight is still added if Chain R knows of multiple competing chain-tips.

\input{includes/ut/algorithms/por-chainweight-1.tex}

\todoDraftOnly{Check this section for LP consistency regarding equal work explanation and WeightOf = ReflectedWeight}

What is the meaning and impact of this change?

The *meaning* of this change is that Chain L now incorporates work done on Chain R *into Chain L's own calculation of the heaviest worked chain*.

When a chain does this we say *Chain L (or Chain L's work) is **reflected** in Chain R*. This technique is what is meant by the term *Proof of Reflection*.

\defineTerm{Proof of Reflection (PoR)}{
  The consensus technique whereby a blockchain becomes more difficult to attack via the weighted inclusion of proofs that its history is reflected in another blockchain
}

One particular *impact* of this change is that a doublespend attack (e.g., by withholding a privately mined chain that reverts a transaction) must now be performed *not only* against Chain L, *but also and simultaneously* against Chain R.

Why? The privately mined blocks to perform the attack *are not known about* by Chain R. Rather, Chain R knows about the *public* Chain L history *against which the attack competes*. Thus, *either*:

* the private chain-segment must contribute more total work to the Chain L blockchain than the public chain-segment does -- *including* the relevant Chain R chain-segment; *or*
* the attacker must *additionally* produce a private Chain R chain-segment such that the *total* work of both private chain-segments is greater than the total work of both public chain-segments, and publish both chain-segments simultaneously.

It's worth noting that, at this point, there is no benefit to Chain R's security. That's because Chain R isn't 'reading' the reflected work back from Chain L. Thus a doublespend attack against Chain R has the expected, non-reflected profile -- it isn't more difficult to attack Chain R yet. However, Chain R can take advantage of the reflection. The main requirements are: the inclusion of appropriate proofs of reflection that show known Chain R blocks according to Chain L, and an update to Chain R's block-weight calculations to account for the reflected work. *Proof of Reflection* doesn't automatically secure both chains; each chain can proactively and independently take advantage of *Proof of Reflection*.

Naturally, if there were a large difference in target block frequencies (e.g., 10 minutes vs 15 seconds) then there would also be a good deal of latency before a chain gains the security benefit from reflected work. For this reason, *Proof of Reflection* makes the most sense when used with high frequency chains, or chains of similar frequencies. One downside of this is that shortening the block production frequency requires the inclusion of more block headers. In the scheme of things, this can be somewhat significant but is not a deal-breaker.

Practical methods of comparing (and converting the weight of) different Proofs of Work are discussed in \autoref{sec:comparing-diff-pows}.

Note that, as the Chain L tip is gaining reflections from Chain R, miners on Chain L are incented to include as many Chain R headers (and PoRs) as possible. That's because each new header will add weight to the *parent* of the block which the Chain L miner is attempting to produce. This increases the overall chain-weight that the miner is building on, and thus contributes to their block becoming part of the most-worked chain.

How is it that Chain L miners can know the partial state of Chain R that is required to produce the necessary PoRs? Typically a blockchain network will support some light-client protocol that allows nodes to ask for such proofs, and that is one method. However, it is possible to design a blockchain system so that this is not required, and one such method is discussed in \autoref{sec:segmented-state}.

It's worth noting that there are still potential attacks on Chain L at this point. For example: what if an attacker mines a doublespend in private and produces a longer chain-segment than the honest chain? At this point the attacker can publish their blocks even though the honest chain-segment still weighs more due to reflections. Why would they do this? Well, if Chain R images Chain L's headers-only chain without accounting for reflections, then the attackers chain-segment appears to have more work than the honest chain-segment. Thus Chain R's reflection of Chain L will reorganize to favor the attacker's chain-segment. If the attacker has more hash power than the honest miners (i.e., $q > p$[^hr-footnote]) then they can use this reorganization as a foothold to launch a normal 51% attack.

[^hr-footnote]: In \href{https://bitcoin.org/bitcoin.pdf}{Satoshi's original paper} the parameters $p$ and $q$ represent the probability that the next block will be found by an honest node or the attacker, respectively. This convention has been continued in subsequent analysis, e.g., Rosenfeld's \href{https://cloudflare-ipfs.com/ipfs/QmNUWmY94QUievK8ptoxsPyAQUsKvx1cjRyCgPcfmysAVv}{\emph{Analysis of hash-rate-based double-spending}}, and is continued here, also.

How can we prevent this sort of attack? The attack is predicated on Chain R *not* accounting for the added weight from reflections. Chain R can easily account for that weight, though, with some protocol changes. First: the total chain-weight[^total-vs-rel-chain-weight], *including reflections*, can be committed to via a field in the header. Based on this field, a headers-only version of the chain can be constructed correctly. Full nodes of Chain L can now also validate the claimed weight against the verifiable weight, and a mismatch invalidates the block. Second: When such a block is found (where the claimed chain-weight violates the protocol), full nodes can construct a fraud proof. Chain R should then confirm the fraud proof (i.e., record it on-chain) and thus prevent the attackers blocks from taking priority and/or gaining reflections. Third: Chain R already knows its own headers, and so it only requires the necessary merkle branches to verify the reflections between Chain L and Chain R. This third method provides an additional means of detecting blocks that are invalid due to fraudulent chain-weight claims in the header.

In the worst case, we would need to *recursively* verify proofs of reflection (those of our own chain, and reflecting chains).
This overhead is discussed in \autoref{sec:proving-reflection} and \autoref{sec:exploiting-seg-state}, and analyzed in \autoref{sec:bandwidth-complexity}.

[^total-vs-rel-chain-weight]: Instead of the total chain-weight, the change in total chain-weight can be committed to instead. These are essentially equivalent.

\todoDraftOnly{develop ideas around fraud proofs -- or omit}

#### Step 5. Mutual Reflection

The final step in this progression is *mutual reflection* -- where both chains image one-another and include the necessary PoRs and modifications to their chain-weight algorithms. This is shown in \autoref{fig:por-step5}.

\begin{figure}[]
\centering
\includegraphics[max width=\linewidth, height=0.35\textheight]{pow_refl_step5_sag}
\caption{\textit{Proof of Reflection} between two UT Chains, Chain L and Chain R}
\label{fig:por-step5}
\end{figure}

When two chains (Chain L and Chain R) mutually reflect each-other, detecting attacks becomes easier. The security of both Chain L and R are partially dependant on each others' histories (along with their own, of course). If one chain is attacked, where some alternate chain-segment is published, then that chain's nodes will know that those blocks have not been reflected - potentially indicating that the recently-published chain-segment was constructed in private or constructed after the fact.

There are several details that still require discussion, though, such as: *how exactly is weight contributed by a reflecting chain converted to weight in the local chain?* (discussed in \autoref{sec:comparing-diff-pows}); and *how can proofs of reflection be calculated without the requirement that miners are full nodes of both chains?* (discussed in \autoref{sec:practical-considerations}). This last question is particularly important for moving beyond mutual reflection between only two chains.

The *essence* of *Proof of Reflection* should now be apparent. *In principle*, we can make blockchains more difficult to attack based on the idea that *blockchains can include a projection of the history of other blockchains (and confirm a chain's history like they do transactions)*. *In principle*, it is possible to increase the security of a blockchain via *reflection* and to increase the security of multiple blockchains via *mutual reflection*.

\todoDraftOnly{PoW -- 2 chains using the same algorithm isn't insecure!}

### Comparing Incomparable Proofs of Work

\label{sec:comparing-diff-pows}

\input{20-por/30-comparing-work-3}

#### A Single Root Token Across Multiple Chains

\defineTerm{Root Token (RT)}{
  The typically sole network-level token required by blockchain protocols. e.g., Bitcoin has BTC, Ethereum has ETH, Polkadot has DOT, Cardano has ADA, Amaroo has ROO, etc
}

\begin{comment}
The simplest method for comparing work done via different algorithms is for all reflecting chains to measure that work via a common unit. How can we do this? We could try to measure it in some external unit like USD. However, that would require accounting for external factors like the availability of silicon and mining rigs, the cost of electricity, and various exchange rates. Accounting for those external factors impractical, so whatever method we choose, those factors must *cancel out*.
\end{comment}

In blockchains like Bitcoin and Ethereum, block rewards are denominated in the *root token* of that chain. What if we had two chains with the same root token?

Consider two PoW blockchains that share a root token, but use different hashing algorithms. We can't directly compare their rates of work because the PoW algorithms are different, but we \emph{can} compare their rates of *token generation via block rewards* (normalized against time). Why does this work? Market externalities are encapsulated by the *economic* decisions that miners have to make. Thus, the rate of work of each chain will approach equilibrium, and if both are at equilibrium we can say that the work contributed to each chain is in proportion to the token generation rate. What do I mean by this? Let's look at an example.

Say we had Chain L and Chain R: two PoW chains using different algorithms, but with the *same* root token and the same block production rate. Firstly, we need a way to determine what their block rewards are, and the intuitive solution is to set each chain's block reward proportionally to the percentage of root tokens (i.e., *coins*) on that chain. Say that 100% of the root tokens should correspond to 50 coins generated per block. So, if one chain had 60% of the root tokens, then 30 coins are generated per block *on that chain*, and (since we only have 2 chains) *the other chain* has 20 coins generated per block -- corresponding to the remaining 40% of root tokens. One reason this method makes sense is that the *ratio* of coins on each chain is not affected by block rewards. We can generalize the method by normalizing against time so that we're comparing the rates of coin production rather than the block rewards themselves.

Now that we know what the block rewards are, and have defined them in terms of the percentage of total coins that are on that chain, we can work on comparing the chains' hash rates. What sort of foundation could we do this from? What about *equal work for equal reward*? Because we have defined block rewards in terms of *where* root tokens are held, we can measure things like *hashes per token* (when considering block rewards particularly). Crucially, we can measure this *for each chain*, which allows us to -- *contextually* -- make claims like 100 hashes on Chain L are worth 25 hashes on Chain R.

Since we know the percentage of root tokens on each chain for each moment in history, we can safely use that figure in chain-weight calculations. The reliability of that data will be the same as the reliability of the blockchains themselves, provided we enforce the 2-way peg that ensures no root tokens are created or destroyed (which would violate protocol rules).

\autoref{alg:weightof-1} and \autoref{alg:weightof-ratio} detail simplistic \textsc{WeightOf} functions that return a weight normalized in coins (i.e., root tokens). It does not account for some things, e.g., changes to the difficulty of $C$ over time.

\input{includes/ut/algorithms/weightof-basic.tex}

\input{includes/ut/algorithms/weightof-ratio.tex}

#### Different Root Tokens with a DEX

\label{sec:comparing-weight-dex}

Instead of using the same token on multiple chains, a similar method could work between chains with different root tokens. Implicit in the above single-token methods was a 1:1 conversion ratio between root tokens held on each chain. Can we not replace that with an exchange rate? If that exchange rate was provided via a trustless and decentralized exchange, could that not also be a reasonable context to do this sort of conversion?

One can use the same principles to compare work between chains that have different root tokens. Such a method is detailed in \autoref{alg:weightof-dex}. However, there is a major new caveat with this method: the DEX and price-finding methods now become *part* of the consensus methods of those chains. This caveat makes this context (with differing root tokens) much harder to reason about, and introduces questions like *What is the effect of front running?* and *Could an attacker exploit market conditions to perform a doublespend when they wouldn't normally be able to?*

\begin{comment}
This is defined so that it can be quoted later and doesn't need to be updated in multiple locations.
\end{comment}

\def\convertingWeightDexNotImportant{In the context of \emph{Ultra Terminum} and \emph{Amaroo}, these aren't questions that are important to answer. If \emph{Proof of Reflection} is ever used to secure multiple chains with heterogenous tokens, it's likely that either these questions will need to be answered or alternate methods will need to be devised.}

\convertingWeightDexNotImportant

\input{includes/ut/algorithms/weightof-dex.tex}

### Converting Confirmations

So far, we've considered PoW chains only.
Conversion of chain-weight between PoW chains can work \emph{if and only if} we can convert between \emph{work} (i.e., hashes) done on each chain -- given an appropriate context.
For a given PoW block, the network knows exactly how much work is implied by that block -- the expected number of hashes to produce it.
Thus, for PoW chains, there is an exact conversion between \emph{work and confirmations} (for some context at some point in time).
Over short time-scales, this conversion ratio is approximately constant (in general it's a function that accepts a timestamp as input).
Thus, \emph{chain-weight} (as represented in figures via $\Sigma_w$, e.g. \autoref{fig:dag-ex1-full}) can be represented either in something like \emph{hashes} or \emph{difficulty} -- though those numbers be unwieldy -- \textbf{or} chain-weight can simply be in terms of \emph{confirmations}.

\aside{
  If we convert \emph{work to confirmations}, will we end up with something \emph{incompatible and contradictory} to the traditional notion of ``a confirmation''?
  There are definitely differences.
  For example: if we convert confirmations, then \emph{we'll have non-integer confirmations}, and what does 0.88 confirmations mean?
  Is that less good than a normal confirmation?

  This problem arises because \emph{we're not actually converting work to confirmations}, per se: we're converting \emph{another chain's work} into \emph{equivalent-confirmations} relative to something.
  Converted confirmations are \emph{in terms of the local chain's confirmations}.
  Most likely, those equivalent-confirmations will be relative either to some known historical confirmation, or to that of the \emph{current} block.
}

Why think about chain-weight in terms of \emph{equivalent-confirmations} instead of \emph{work}?
There are a few reasons.
First, \emph{confirmations are general!}
If we reason in terms of \emph{confirmations} instead of \emph{work}, then \emph{maybe} we can apply these ideas to \emph{other chains} that don't use PoW.
Second, it \emph{simplifies thinking}.
The purpose of converting chain-weight is clearer and easier to reason about.
Finally, it makes explicit the requirement that \emph{we can only compare to a grounded context}.

There is no way to \emph{universally} say \emph{X work on L is worth Y work on R} without adding necessary context like \emph{when} that conversion is happening.
Confirmations (like work) require that grounding.
For confirmations (not work), this is true even when converting confirmations \emph{from the same chain}.
For example, we can say that the single confirmation provided by Bitcoin block 704610 is \emph{equivalent} to approximately 19,893,045,000,000 genesis-confirmations.\footnote{A genesis-confirmation is relative to the Bitcoin genesis block -- which had a difficulty of exactly 1.}
The conversion-ratio is equivalent to the difficulty of block 704610.
That is, it would take a chain of $\sim$ 20 trillion blocks (each with 1 genesis-confirmation worth of work) to match the weight of block 704610.

When will conversion methods fail for converting confirmations?

\emph{Proof of Reflection} adds block-weight in discrete amounts.
Some alternative distributed ledger networks (in essence: DLTs) do not produce network-wide discrete updates.
So it's not clear how those would use PoR themselves or be used by another chain for PoR.
Examples: Hedera uses Hashgraph; Solana uses Proof of History (PoH).\footnote{
  It's also not clear how either Hashgraph or PoH networks could support cross-chain transactions in general.
}

PoR also requires that \emph{state can be verified} in the reflecting chain.
Some blockchains obscure their state (e.g. Monero).
If we can't \emph{publicly verify} PoRs, we can't convert chain-work, so they can't be used \emph{for} reflection (such networks could perhaps do one-way PoR, though).
In that case, protocol upgrades might enable \emph{mutual} PoR.
Some DLTs don't have meaningful network-wide state; i.e., there is no single, consistent view of that network's history.
In this case we can't convert.
Example: IOTA uses The Tangle.

PoR also needs a way to normalize the idea of \`\`a confirmation'' so they can be compared.
Consider a PoA chain with \emph{irregular} block production.
It has discrete updates, and state can be verified against it.
But, what does each confirmation \emph{mean?}
Is a block that is produced soon after its parent worth as much as a block produced a long time after its parent?
For non-PoW chains, we'll need conversion methods that have non-arbitrary answers for these questions.

In general, my intuition is that we can almost always use PoR with networks that fit the \emph{traditional} idea of blockchains. (And when we can't, a protocol change could fix that.)

### Reflection Between PoW and PoS Chains

\label{sec:reflection-pow-and-pos}

\aside{
  Whether PoS systems \emph{can} be secure is not a focus of this paper.
  There are still \href{https://github.com/zack-bitcoin/amoveo-docs/blob/master/other_blockchains/proof_of_stake.md}{criticisms of PoS} without \href{https://github.com/zack-bitcoin/amoveo-docs/blob/master/other_blockchains/the_defence_of_pos.md}{adequate answers}.
  The intention of sections like this is not to endorse PoS, but rather to explore what is possible \emph{if} PoS can be done securely.
}

Perhaps one of the most interesting features of *Proof of Reflection* is that PoW chains and PoS chains can reflect one another. Up till now, we've contextualized the weight of a reflection via the *work* required to produce a block. But the concept of *work* does not neatly apply to foundational consensus mechanisms that do not require the utilization of some physical resource -- such as PoS.

\defineTerm{Foundational Consensus Mechanisms}{Those mechanisms, like PoW and PoS, which can work in some \emph{standalone} fashion; PoR is a cross-chain \emph{extension} to such mechanisms}

Putting the issue of *conversion* aside for a moment, is it possible *in principle* for PoW and PoS chains to reflect one another? Yes. Additionally, PoR provides decisive advantages *both* for PoW chains *and* PoS chains, though there are some additional problems that must be solved, too.

If a PoW chain is reflected in a PoS chain, then an attacker will likely need more than just computational resources to attack the PoW chain.
Consider a PoW chain and a PoS chain that share a root token, and each chain hosts approximately 50% of the total supply.
If the two chains have equal block production frequencies, then (using \autoref{alg:weightof-ratio}) 50% of the network's security comes from each chain.

Consider an attack on the PoW chain and presume that the difficulty on the PoW chain is constant over the attack, i.e., the PoW chain's difficulty doesn't adjust quickly enough to react to the attack. Additionally, assume the attacker has *not* been contributing to the network before the attack, i.e., their hash-rate is not accounted for in the PoW chain's difficulty. Given the two chains are mutually reflecting, half of the network's security is provided by the PoS chain (and thus immune to the attacker in this case). Therefore, a successful attacker -- *using the traditional method of mining a competing chain-segment in private* -- must generate more blocks than both chains combined. That means the attacker needs *twice* the honest hash-rate for a guaranteed successful attack.

However, consider the case that *the security contribution of the PoW chain is \textbf{capped} at 50%* -- i.e., capped at the proportion of root tokens hosted on that chain. For our purposes, this situation is approximately equivalent to that where the PoW chain has a *perfect* difficulty adjustment algorithm, i.e., the network instantly adapts to keep the block production frequency constant. For the sake of this demonstration, assume that these chains *retroactively* adjust block weightings to ensure this cap holds. Let $p > 0$ be the honest miners' contribution to *overall* network security, and $q > 0$ be the attacker's contribution. As the PoW contribution to overall security is capped at 50%, the equality $p + q = 0.5$ is enforced. In this case, the attacker will have a maximum chain-weight contribution rate of $\frac{1}{2} \cdot \frac{q}{q + p}$ and the honest chain-segments will have a maximum contribution rate of $\frac{1}{2} \cdot \frac{p}{q + p} + \frac{1}{2}$. The condition for a successful attack is shown in \autoref{eq:refl-pow-pos-1}, and the inequality has no solutions.

\begin{align}
&& \frac{1}{2} \cdot \frac{q}{q + p} & > \frac{1}{2} \cdot \frac{p}{q + p} + \frac{1}{2} \notag \\
&& q & > p + (q + p) \notag \\
&& 0 & > 2p && \text{which is a contradiction since\;} p > 0
\label{eq:refl-pow-pos-1}
\end{align}

Given the right set-up, a PoW chain gains an *incredible* security advantage from mutual reflection with a PoS chain.

\aside{
  \textbf{Note:} The attack scenario above assumes that the attacker is not attacking the PoS chain that is reflecting the PoW chain.
  That is not a safe assumption.
  Additionally, with traditional blockchains (which are trees), an empty-block DoS is possible -- this is addressed in \autoref{sec:dos-and-dags}.
}

What about the PoS chain, though; what benefits does it gain from this relationship?
The answer here is simple: by using mutual PoR with a PoW chain, the PoS chain gains *thermodynamic security*; the PoS chain's history is *thermodynamically secured* by the PoW chain.
\textbf{This solves the \emph{Nothing at Stake} problem for any well constructed PoS scheme.}
Furthermore, it is possible for error-correction methods like \emph{slashing} to be implemented *on the PoW chain*, not the PoS chain.
Moving the staking and error correction methods to a different chain will require subtle and precise protocol design, but such changes are *in principle* possible with tolerable overhead.

There are some (as yet) unsolved problems that arise through this design, such as the *economic* details of managing block rewards across the PoW and PoS chains.
Given that solutions to this problem likely depend on the specific details of the relevant PoS systems, this problem is not addressed here.
Note: conversion methods for reflected weight, like \autoref{alg:por-reflected-block-weight}, will work provided a well defined \textsc{WeightOf} function exists.

There are some other conjectured solutions to the *Nothing at Stake* problem. The two examples that follow solve the problem via mechanisms that are *external* to the protocol itself, i.e., hard-coded checkpoints and the requirement that nodes are online ``frequently''. The solution provided by mutual reflection with a PoW blockchain -- i.e., thermodynamic security -- is provided *by the protocol itself* and can only *increase* the security of PoS mechanisms. Thus, UT's solution to *Nothing at Stake* is qualitatively superior.

\bquote{
  %% cspell: disable-next-line
  Long-range ``nothing-at-stake'' attacks are circumvented through a simple ``checkpoint'' latch which prevents a dangerous chain-reorganisation of more than a particular chain-depth. To ensure newly-syncing clients are not able to be fooled onto the wrong chain, regular ``hard forks'' will occur (of at most the same period of the validators' bond liquidation) that hard-code recent checkpoint block hashes into clients.
}{Dr. Gavin Wood; \href{https://cloudflare-ipfs.com/ipfs/QmbH4TzUB7izvuwidG598DNnk3Nmd1aWEyf8KLxeAkrvkK}{Polkadot Whitepaper, s5.2}}

\bquote{
  Provided that stakeholders are frequently online, nothing at stake is taken care of by our analysis of forkable strings (even if the adversary brute-forces all possible strategies to fork the evolving blockchain in the near future, there is none that is viable), and our chain selection rule that instructs players to ignore very deep forks that deviate from the block they received the last time they were online.
}{\href{https://cloudflare-ipfs.com/ipfs/QmWCAHyi35SeXH2E4e8jRVk7yNse2x6D14uPfABnhagbvN}{Ouroboros: A Provably Secure Proof-of-Stake Blockchain Protocol, s10}}


%% END ### RELEASE

%% BEGIN ### DRAFT



### The Insecurity of Merged Mining in UT

\todo{write -- The Insecurity of Merged Mining}

- Merged Mining allows attacking merged chains at 0 cost.
- that means that if a parent chain and a merged mined child chain where to reflect one another, then the weight contributed via merged mining must be 0 -- no additional work was actually done beyond that of the parent-chain.
- Also, if some other chain reflects both a parent chain *and* a merged mined child chain, then the net benefit is equal to *only* the work contributed by the reflecting parent chain.


\todo{PoR in general: (nb: check if this is sufficiently answered) reflect only chains that reflect your history; if they favor a different history, then you should be building on that history instead, so don't reflect those blocks -- i.e. ppl should calculate weight to be 0.}


%% END ### DRAFT
