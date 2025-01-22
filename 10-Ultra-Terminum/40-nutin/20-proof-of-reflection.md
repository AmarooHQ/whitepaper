%% BEGIN ### RELEASE

\input{20-por/10-incremental-por.tex}

\subsubsection{Step 3. A Reflection of \cL in \cR}

Can we use a projection of a chain for a different purpose?
What happens if Chain \cL tracks whether Chain \cL's history is confirmed within Chain \cR?
This can be done via merkle branches\footnote{
  Vector commitments (or verkle branches) can be used, too (this applies to most uses of merkle trees / branches in this paper).
  For the sake of convenience and simplicity, verkle trees won't be explicitly mentioned as an alternative unless there is a specific purpose.
} that prove Chain \cR's relevant state.
In essence, Chain \cL uses its projection of Chain \cR to prove that its *own history* matches that of its *projection* in Chain \cR.
Chain \cL proves that it is *reflected* in Chain \cR.

What does this proof look like? The following progression is shown in \autoref{fig:por-step3-parts}.
First, Chain \cL must prove that its history is reflected, so we first find the most recently reflected header, $L_{i+1}$ (ideally, this is the previous \cL block).
Secondly, we want to prove that $L_{i+1}$ is also the \emph{best block} (for Chain \cL) according to \emph{Chain \cR's} projection of Chain \cL, using the best known \cR block, $R_{j+1}$.
For that, we need a merkle branch showing $L_{i+1}$ is part of $R_{j+1}$'s state --- this is sometimes referred to (in this paper) as the \emph{missing} merkle branch.
Thirdly, we want to prove that $R_{j+1}$ is the \emph{best block} according to Chain \cL's projection of Chain \cR.
We can do that via a merkle branch, too, but full nodes of Chain \cL already know whether $R_{j+1}$ is the best block or not, so this branch doesn't need to be explicit.
However, \cL's nodes must be able to generate it.
The \emph{full} collection of information required to prove reflection is called a *proof of reflection* (PoR).

\begin{figure}
    \begin{subfigure}[t]{.31\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{pow_refl_step3_1_sag}
        \caption{Find the most recently reflected \cL block.}
        \label{fig:por_step3-part1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{pow_refl_step3_2_sag}
        \caption{Prove that block is known to the most recently reflected \cR block.}
        \label{fig:por_step3-part2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.31\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[width=.95\linewidth]{pow_refl_step3_3_sag}
        \caption{Prove that \cR block is known to the current \cL block.}
        \label{fig:por_step3-part3}
    \end{subfigure}
    \caption{Incrementally constructing a \emph{proof of reflection} (PoR).}
    \label{fig:por-step3-parts}
\end{figure}

Segments of Chain \cL and \cR (events and data) are shown in \autoref{tab:por-step-3} and \autoref{fig:por-step3}.

Chain \cL now knows \emph{which \cL blocks are recorded by Chain \cR}, i.e., which local blocks are known about by some external source.
Put another way: Chain \cL's history is confirmed \emph{not only} by new Chain \cL blocks, \emph{but also} by Chain \cR blocks.
\begin{comment}
There's no data-availability concern here since Chain \cL nodes *know* that they have the blocks that Chain \cR knows about.
\end{comment}

\aside{
  \textbf{Important:} Soon, these confirmations will have real and useful meaning.
  Under the right conditions, an appropriate configuration of \emph{Proof of Reflection} results in an increase in the \emph{rate} that confirmations are acquired.
  This is the first hint of $O(c^{-1})$ confirmation time.
}

At this point, if an attacker was to publish an alternate, better Chain \cL history, then Chain \cL nodes would reorganize around the *new* history published by the attacker, and the attacker's block headers would end up being recorded in Chain \cR and causing a reorganization there, too. Currently, this configuration does not add any security to Chain \cL.

Could we use Chain \cL's knowledge \emph{that its own history is reflected in Chain \cR} to *prevent* such an attack?

\ctable[
  pos = hp,
  caption = {
    Step 3. Chain \cL records which of its headers are known about by Chain \cR.
    That is: Chain \cL includes \emph{proofs of reflection}.
    Note: ``Headers'' is abbreviated to ``Hdrs''.
  },
  cap = Step 3. Chain \cL records \emph{PoRs} via Chain \cR.,
  center,
  label = tab:por-step-3,
  width = \textwidth,
]{llZZlZZ}{}{
  \FL
  {Time} & \shortstack[l]{\cL block \\ mined} & \shortstack[l]{\cL block \\ contents} & {\cL state} & \shortstack[l]{\cR block \\ mined} & \shortstack[l]{\cR block \\ contents} & {\cR state}
  \ML
  $\vdots$ & & & & & & \NN
  0 & $k$ & {$R_{j-1}$ header, \newline $L_{k-1}$ PoR} & Hdrs: $R_{0 \cdots j-1}$, \newline PoRs: $L_{0 \cdots k-1}$ & & &
  \NN
  1 & & & & $j$ & $L_{k}$ header & Hdrs: $L_{0 \cdots k}$
  \NN
  2 & $k+1$ & $R_{j}$ header, \newline $L_{k}$ PoR & Hdrs: $R_{0 \cdots j}$, \newline PoRs: $L_{0 \cdots k}$ & & &
  \NN
  3 & & & & $j+1$ & $L_{k+1}$ header & Hdrs: $L_{0 \cdots k+1}$
  \NN
  $\vdots$ & & & & & &
  \LL
}


<!--
| Time | \cL block made | \cL block contents | \cL state | \cR block made | \cR block contents | \cR state |
|--|---|------|------|---|-----|------|
| $\vdots$ | | | | | | |
| 0 | k | $R_{j-1}$ header + Merkle proof of $L_{k-1}$ | Records $R_{0 \cdots j-1}$ *and* knows that Chain \cR records $L_{0 \cdots k-1}$ | | | |
| 1 | | | | j | $L_{k}$ header | Records $L_{0 \cdots k}$ |
| 2 | k + 1 | $R_{j}$ header + Merkle proof of $L_{k}$ | Records $R_{0 \cdots j}$ *and* knows that Chain \cR records $L_{0 \cdots k}$ | | | |
| 3 | | | | j + 1 | $L_{k+1}$ header | Records $L_{0 \cdots k+1}$ |
| $\vdots$ | | | | | | |

: Chain \cL records which of its headers are known about by Chain \cR. That is: Chain \cL includes *proofs of reflection*. -->

\begin{figure}
\centering
\includegraphics[max width=\linewidth, max height=0.33\textheight]{pow_refl_step3_sag}
\caption{
  Step 3. Chain \cL includes \textit{proofs of reflection} (PoRs) along with headers.
  Proofs of Reflection allow Chain \cL to know which of its own blocks are known to Chain \cR.
}
\label{fig:por-step3}
\end{figure}

\subsubsection{Step 4. One Way Reflection}

\label{sec:por-step4}

Before we discuss a change that Chain \cL could make, it is important to note that chain-work done with one hashing algorithm is *not generally convertible* to 'equivalent' work done via another hashing algorithm.
For example, there is no meaningful *generic* answer to the question *how many double SHA256[^btc2sha] hashes is one Ethash hash worth?*

[^btc2sha]: Bitcoin uses $\text{Hash}(x) = \text{SHA256}(\text{SHA256}(x))$ as its PoW hash.

For the purposes of our hypothetical construction, let's say that \cL and \cR do *equal work over equal time*. In the current example, that means that the work required to produce either $L_i$ or $R_j$ is the same. *For the sake of this construction, we'll also presume this relationship doesn't change over time*. Our constant of conversion is thus: 1 *R Blocks per \cL Block*.

\aside{
  We're not that concerned with whether this is a reasonable assumption in the real world or not; right now, we just need a way to convert the work done on each chain into the same units.
  Methods for converting work are discussed in \autoref{sec:comparing-chain-work}.
}

Currently, the Chain \cL network chooses the \`\`heaviest'' (most worked) chain as its common history.
Chain \cL calculates the \`\`weight'' of blocks (i.e., how much work went in to them) via an estimation of how many hashes were required --- e.g., some number of *double SHA256 hashes*.
For the purposes of illustration, let's convert this number to be in terms of *L Blocks* instead of *double SHA256 hashes*.
That's easy, since each block is worth 1 *L Block* by definition.
We can also measure the work of an \cL block in terms of *R Blocks* (1 \emph{L-Block} = 1 \emph{R-Block} by the constant of conversion above).

How can the network choose the heaviest chain? Well, a traditional blockchain might use a simple recursive function like \autoref{alg:vanilla-bw}.

\input{includes/ut/algorithms/vanilla-chainweight.tex}

Now that we can convert block weights between \cL blocks and \cR blocks, could \cL's \textsc{ChainWeight} algorithm incorporate the idea that Chain \cR had confirmed part of \cL's history?
Could Chain \cL use this to thwart some types of attack?

Yes, and we must modify the block-weight calculation so that it accounts for work contributed by Chain \cR.
\autoref{alg:refl-1-bw} is such an algorithm.
Essentially, additional weight is added to a block when it is *the best block* known to Chain \cR, i.e., when, according to Chain \cR, it is at the tip of Chain \cL.
Note that this weight is still added if Chain \cR knows of multiple competing chain-tips.

\input{includes/ut/algorithms/por-chainweight-1.tex}

What is the meaning and impact of this change?

The *meaning* of this change is that Chain \cL now incorporates work done on Chain \cR \emph{into Chain \cL's own calculation of the heaviest worked chain}.

When a chain does this we say \emph{Chain \cL (or Chain \cL's work) is \textbf{reflected} in Chain \cR}. This technique is what is meant by the term *Proof of Reflection*.

\defineTermTex{Proof of Reflection (PoR)}{
  The consensus technique whereby a blockchain becomes more difficult to attack by including work done by reflecting blockchains in its \emph{fork rule}
}

One particular *impact* of this change is that a doublespend attack on \cL (e.g., withholding a privately mined chain-segment that reverts a transaction) must now be performed *not only* against Chain \cL, *but also and simultaneously* against Chain \cR.

Why? The attacker's privately mined \cL blocks *are not known about* by Chain \cR.
Rather, Chain \cR knows about the *public* Chain \cL history *against which the attack competes*.
Thus, *either*:

* the private chain-segment must contribute more total work to the Chain \cL blockchain than the public chain-segment does (*including* the relevant Chain \cR chain-segment); *or*
* the attacker must *additionally* produce a private Chain \cR chain-segment such that the *total* work of both private chain-segments is greater than the total work of both public chain-segments, and publish both chain-segments simultaneously.

Note that, at this point, there is no benefit to Chain \cR's security. That's because Chain \cR isn't `reading' the reflected work back from Chain \cL. Thus a doublespend attack against Chain \cR has the expected, non-reflected profile --- it isn't more difficult to attack Chain \cR yet. However, Chain \cR can take advantage of the reflection. The main requirements are: the inclusion of appropriate proofs of reflection that show known Chain \cR blocks according to Chain \cL, and an update to Chain \cR's block-weight calculations to account for the reflected work. *Proof of Reflection* doesn't automatically secure both chains; each chain can proactively and independently take advantage of *Proof of Reflection*.

Naturally, if there were a large difference in target block frequencies (e.g., 10 minutes vs 15 seconds) then there would also be a good deal of latency between the points where the higher-frequency chain gains the security benefit from reflected work.
For this reason, *Proof of Reflection* is most useful between high frequency chains, or chains of similar frequencies.
One downside of this is that shortening the block production frequency requires the inclusion of more block headers.
In the scheme of things, this can be somewhat significant but it is not a deal-breaker.

Exactly how one chain can properly account for reflected work requires that we cover how to compare (and convert) that work, and is the topic of \autoref{sec:comparing-chain-work}.

Note that, as the Chain \cL tip is gaining reflections from Chain \cR, miners on Chain \cL are incented to include as many novel Chain \cR headers and PoRs as possible.
That's because each new Chain \cR header (with a PoR) will increase the weight of the *ancestors* of the Chain \cL draft block, which helps the draft block compete with other draft \cL blocks.
This increases the overall chain-weight that the miner is building on, and thus contributes to their block becoming part of the most-worked chain.
<!-- Additionally, this provides of reflections of \cR blocks, too, which allows Chain \cR miners to use these \cL blocks for their own PoRs.
The takeaway is that there's a positive feedback loop. -->

\aside{
  Where do Chain \cL miners get PoRs from?
  There are multiple answers, but one is for miners of Chain \cL to request them from Chain \cR nodes --- light-client protocols often support this sort of thing.
  The problem is discussed in \autoref{sec:practical-considerations}.
  For now, it's okay to assume that PoRs are broadcast alongside headers.
}

There are still potential attacks on Chain \cL.
For example: what if an attacker mines a doublespend in private and produces a longer chain-segment than the honest chain?
That is, the attacker's segment --- *excluding reflections* --- is heavier than the honest chain-segment.
At this point the attacker can publish their blocks even though the honest chain-segment --- *including reflections* --- is heavier.
Chain \cL nodes would *not* reorganize around this new chain-segment, so why would an attacker do this?
If the projection of Chain \cL in Chain \cR \emph{does not account for reflections}, then the attacker's chain-segment will appear (to Chain \cR) to have more work than the honest chain-segment.
Thus the *projection* of \cL in \cR will reorganize to favor the attacker's chain-segment.
If the attacker has more hash power than the honest miners (i.e., $q > p$\footnote{
  In Satoshi's \citeBitcoinLink{} the parameters $p$ and $q$ represent the probability that the next block will be found by an honest node or the attacker, respectively.
  This convention has been continued in subsequent analysis, e.g., Rosenfeld's \citeAHBDS{}, and is continued here, also.
}) then they might\footnotemark{} be able to use this reorganization as a foothold --- either to launch a traditional 51% attack against \cL, or to attack SPV verification and light clients.

\footnotetext{
  In a limited case like this, where there are only two chains, there are many options for preventing these sorts of attacks on full nodes.
  However, in a more general case, where there might be many reflecting chains, we need to deal with the \emph{root cause} of the vulnerability.
}

\aside{
  Note: Chain \cR is not \emph{required} to actually evaluate Chain \cL's tip.
  PoR can still work if Chain \cR simply records every Chain \cL header that it can, and nothing more.
  However, this increases the complexity of a PoR implementation, and Chain \cR users won't have protocol-level access to a projection of \cL.
  Since a correctly-evaluated projection of \cL is useful (for users of either chain), we should solve this problem if we can.
}

<!-- \todoDraftOnly[h]{rewrite / edit this: evaluating PoR weight --- inconsistent with later I think} -->

How can we prevent this kind of attack?
The attack is only possible because Chain \cR was *not* accounting for reflected weight --- if Chain \cR's projection of Chain \cL accounts for reflections, then this attack is not possible.
<!-- In other words, Chain \cR and Chain \cL must always agree on which Chain \cL block is the current tip. -->
If Chain \cR users were \emph{required} to run full nodes for both \cL and \cR, then we've essentially just combined \cL and \cR into one big, overly-complex blockchain --- this change would thwart the attack, but it isn't a solution.
Instead, we need to ensure that Chain \cR can cheaply and reliably evaluate the weight of \cL's reflections.

Let's add a field to \cL's header: the total chain-weight,\footnote{
  Instead of the total chain-weight, the sum of reflected weight works too (these are essentially equivalent).
} *including reflections*, of that block.
If this value is \emph{always} reliable, then it's trivial to correctly construct \cL's headers-only chain.
With traditional blockchains (like Bitcoin) it's easy to verify the weight of a header, and thus a headers-only chain, because the header's difficulty is \emph{already available} as part of the PoW's payload.
In \emph{this} case, though, \emph{additional} data is required --- specifically, the proofs of reflection.
Full nodes of Chain \cL already verify that the claimed chain-weight is accurate --- all the required data is contained in \cL blocks --- but this doesn't help light clients.
We need additional protocol changes to ensure that the \emph{claimed} chain-weight of a header is \emph{always} reliable.

\aside{
  One solution is to adopt a design that allows \cR nodes to independently calculate or verify \cL's reflections without evaluating \cL's state.
  Provided that \cR nodes can calculate any missing merkle branches on demand, this will work.
  This method has substantial advantages, however, some configurations have considerable overhead.
  It is discussed in \autoref{sec:segmented-state} and \autoref{sec:exploiting-seg-state}, and analyzed in \autoref{sec:bandwidth-complexity}.
}

<!-- \todoDraftOnly[l]{revisit / edit this} -->

We \emph{can}, at least, guarantee that a fraud proof will \emph{always} be possible when a malicious \cL block lies about its total chain-weight.
Additionally, other \cL miners can detect the lie and link back to the malicious block as an invalid parent alongside the fraud proof.
These are useful features, but they're overkill at this point.

For now, let's assume that \cR records \cL headers \emph{and} the corresponding PoRs, and that \cR nodes verify \cL headers' chain weights.


<!-- Broadly, there are two categories of low-overhead, potential solutions: proofs of validity, and proofs of invalidity (i.e., fraud proofs).
Let's consider the latter.

Say that it is easy for a full node to construct a concise proof showing that the claimed chain-weight is fraudulent.
Honest nodes (of both \cL and \cR) have an incentive to broadcast and record (on-chain) any such proofs.
Moreover, these proofs are valid regardless of their source, so nodes can act on on a proof independent of it being recorded on-chain.
Provided that \cR nodes (and \cL light clients) can be confident that, for any malicious \cL headers, a fraud proof will be readily available (or proactively provided), then \cR can trust the claimed chain-weight in absence of a fraud proof.\footnotemark{}
A data structure and methodology for suitable fraud proofs of chain-weight (and PoRs) is discussed in \autoref{sec:vlmt} and \autoref{sec:por-fraud-proofs}. -->

<!-- \footnotetext{
  Note that, based on what we've covered so far, there is still the potential for DoS attacks.
  Mitigation of DoS attacks is covered in \autoref{sec:dos-and-dags}.
} -->

<!-- \todoDraftOnly[l]{
  Since an invalid block's parent is known, such a fraud proof only needs to show that the difference (between the parent and block's chain-weight) is not possible.
  If we use a VLMT (see \autoref{sec:vlmt}) to store reflections, then the merkle branches used for PoR will contain, for each subtree, the contributed chain-weight.
  This means a complete and valid VLMT (with forged total chain-weight) is impossible, which in turn makes fraud proofs easy to generate.
} -->

<!-- \todoDraftOnly[l]{
  reconsider:\\
As a final point on this attack, in limited cases like this (where only one set of reflections needs validation), \cR can forgo fancy protocols provided that \cL and \cR share a simple and standardized way to record and verify reflected blocks.
Chain \cR nodes already know \cR's state, so they can trivially generate merkle branches proving reflection of \cL blocks in \cR --- these are \emph{the same} branches that \cL uses in its PoRs.
All that remains is, for each \cL header, the merkle branch proving reflection of \cR blocks in \cL.
\cR nodes *already* know (and record) every \cR header they can find --- including invalid ones.
\cR headers are also implicitly rate-limited via \cR's difficulty adjustment algorithm, so there will rarely be more than a few \cR headers reflected by a single \cL block.
If a merkle root of \cL's reflections is accessible (e.g., as a field in \cL's header) then \cR nodes can \emph{quickly and exhaustively} check all possible combinations of reflected blocks.
Under normal operation, \cR nodes should *always* find a matching merkle tree.
This might become an issue in the case of an active attack, but \cR nodes can fall back to explicitly recording and/or verifying those PoRs for the duration of the attack.
} -->

\subsubsection{Step 5. Mutual Reflection}

The final step in this progression is *mutual reflection* --- where both chains image one-another and include the necessary PoRs and modifications to their chain-weight algorithms.
This is shown in \autoref{fig:por-step5}.

\begin{figure}
\centering
\includegraphics[max width=\linewidth, height=0.35\textheight]{pow_refl_step5_sag}
\caption{Step 5. \textit{Proof of Reflection} between two UT Chains, Chain \cL and Chain \cR}
\label{fig:por-step5}
\end{figure}

When two chains (Chain \cL and Chain \cR) mutually reflect each other, detecting attacks becomes easier.
The security of both Chain \cL and \cR are partially dependent on each others' histories (along with their own, of course).
If one chain is attacked, where some alternate chain-segment is published, then that chain's nodes will know that those blocks have not been reflected --- potentially indicating that the recently-published chain-segment was constructed in private or constructed after the fact.

There are several details that still require discussion, though, such as: *how exactly is weight contributed by a reflecting chain converted to weight in the local chain?* (discussed in \autoref{sec:comparing-chain-work}); and *how can proofs of reflection be calculated without the requirement that miners are full nodes of both chains?* (discussed in \autoref{sec:practical-considerations}).
This last question is particularly important for moving beyond mutual reflection between only two chains.

The *essence* of *Proof of Reflection* should now be apparent. *In principle*, we can make blockchains more difficult to attack based on the idea that *blockchains can include a projection of the history of other blockchains (and confirm a chain's history like they do transactions)*. *In principle*, it is possible to increase the security of a blockchain via *reflection* and to increase the security of multiple blockchains via *mutual reflection*.

\subsubsubsubsubsection{Remarks}

Typically, it is insecure for a weaker PoW blockchain to use the same hashing algorithm as a more popular, more heavily mined PoW blockchain.
In such a situation, a small proportion of miners on the more popular chain could temporarily divert efforts to perform a doublespend or empty block DoS on the other chain, and thus the weaker chain is plainly insecure.
However, if those two chains were using \emph{mutual PoR}, then this kind of attack becomes impossible, and we've found a way for two PoW chains to coexist using the same PoW algorithm.

%% END ### RELEASE

%% BEGIN ### DRAFT

<!-- \input{20-por/15-cutdraft-applicability-of-por} -->

%% END ### DRAFT

%% BEGIN ### RELEASE

\subsection{Comparing Incomparable Proofs of Work}

\label{sec:comparing-chain-work}

\input{20-por/30-comparing-work-3}

\subsubsection{Theoretical Conversion}

Consider a traditional blockchain (like Bitcoin, or Eth1).
We know that traditional blockchains have properties specific to their blocks, like: reward per block (coins/block); a block target time (seconds/block) --- or block frequency (blocks/second); and a difficulty (hashes/block).
There are also \emph{network-wide} properties, too, like the \emph{inflation rate} (coins/second).
The \emph{instantaneous} relationship between these properties is mediated by various protocols --- these protocols (e.g., difficulty adjustment algorithms) are part of the \emph{context} of those properties and relationships.
How can we use these relationships to our advantage?

\aside{
  With regards to Proof of Reflection, consider that we \emph{only} need to convert \emph{simultaneous} work.
  That means: PoR does not need to be able to convert chain-work between chains \emph{over time}, only \emph{for some given moment}.\footnote{At this point, we are discussing how PoR works with Proof-of-Work, discussions of where other methods, such as Proof-of-Stake, fit into the ecosystem will be discussed in \cref{sec:converting-confirmations}.}
}

The units that we have to work with are: blocks, seconds, hashes, and coins\footnotemark{}.
\footnotetext{
  Note that the terms \emph{coin} and \emph{root token} are synonymous.
  The choice of \emph{coin} over \emph{root token}, for these sections, is for practicality --- we'll see this term \emph{a lot}.
}
There are actually multiple types of blocks (L-blocks and R-blocks), coins (L-coins and R-coins), and hashes (L-hashes and R-hashes).
We can't combine those unless we're able to convert those values to common units.

If we ignore some of the normal constraints on consensus algorithms --- like where information comes from --- what information could help us convert?
If we had \emph{an exchange rate} between L-coins and R-coins, then we can trivially convert between them.
If we have that, then, for our current purpose, we can treat L-coins and R-coins as interchangeable units --- because we can \emph{always} convert between them.
So now we have L-blocks, R-blocks, coins, and L-hashes and R-hashes.

Let's consider Chain \cL, and give some of these properties variables: $L_f$ (L-blocks/s) for block frequency, $L_r$ (L-coins/L-block) for the block reward, and $L_d$ (L-hashes/L-block) --- the difficulty. We can multiply combinations of these to get new units: $L_f \cdot L_d$ gives us L-hashes/s; $L_f \cdot L_r$ gives L-coins/s, and $\nicefrac{L_d}{L_r}$ gives us \textbf{L-hashes/L-coin}.

Now, let's add that exchange rate: $X_{R\rightarrow L}$ (L-coins/R-coin).
And some variables for Chain \cR which correspond to Chain \cL's above: $R_f$, $R_r$, and $R_d$.
There's a symmetry between chains \cL and \cR, so we already know that $\nicefrac{R_d}{R_r}$ gives us R-hashes/R-coin.

In theory, can an exchange rate help us convert between R-hashes/R-coin and L-hashes/L-coin?

\subsubsection{Converting Block-Weights}

\label{sec:converting-block-weights}

Can we find some function, $\text{ConvWork}_{R\rightarrow L}(w)$, that converts R-hashes to L-hashes?
\begin{align}
  & \frac{L_d}{L_r}
    & &\frac{\text{L-hashes}}{\text{L-coin}}
    & & \nonumber
    \\[0.5em]
  \implies \; & \frac{L_d}{L_r} \cdot X_{R\rightarrow L}
    & &\frac{\text{L-hashes}}{\text{R-coin}}
    & &\text{Multiply by }X_{R\rightarrow L} \nonumber
    \\[0.5em]
  \implies \; & \frac{L_d}{L_r} \cdot X_{R\rightarrow L} \cdot \frac{R_r}{R_d}
    & &\frac{\text{L-hashes}}{\text{R-hash}}
    & &\text{Divide by }\nicefrac{R_d}{R_r} \label{eq:por-conversion-const-1}
    \\[0.5em]
  \therefore \text{ConvWork}_{R\rightarrow L}(w) = \; & \frac{L_d}{L_r} \cdot X_{R\rightarrow L} \cdot \frac{R_r}{R_d} \cdot w
    & &\text{R-hashes }\rightarrow\text{ L-hashes}
    & & \label{eq:por-conv-work}
\end{align}

With \autoref{eq:por-conversion-const-1}, \textbf{we have just found our first constant of conversion for \ul{block-weight}.}

\aside{
  \autoref{eq:por-conversion-const-1} has a natural symmetry.
  It's worth noting for later.
}

What's going on here?
We start out by observing $\nicefrac{L_d}{L_r}$ gives us a value in units of $\frac{\text{L-hashes}}{\text{L-coin}}$.
This is a constant of conversion from L-coins to L-hashes for a given moment --- if some miner earned $x$ L-coins today, then $x \cdot \frac{L_d}{L_r}$ would tell you roughly how many hashes were done to earn that reward.
Next, we multiply by the exchange rate to find the constant of conversion for $\frac{\text{L-hashes}}{\text{R-coin}}$.
Then, we divide by $\nicefrac{R_d}{R_r}$ to find the constant of conversion for $\frac{\text{L-hashes}}{\text{R-hash}}$.
If we multiply this constant of conversion by a value of R-hashes, then we'll end up with a value of L-hashes.
It tells us \emph{the relative weight} contributed to each network by each hash performed.
Finally, we can deduce the function $\text{ConvWork}_{R\rightarrow L}(w)$ which takes a value of R-hashes and returns a value of L-hashes.

Let's sanity check this.

\defineTermTex{Root Token (RT)}{
  \emph{aka \textbf{Coin}}.
  The typically sole network-level token required by blockchain protocols.
  e.g., Bitcoin has BTC, Ethereum has ETH, Polkadot has DOT, Cardano has ADA, Amaroo has ROO, etc
}

Consider two blockchains (\cL and \cR) that are \emph{very} similar to Bitcoin.
Unless otherwise specified, the chains are identical.
Here are the key assumptions:

* Both \cL and \cR started on the same day, with the same block rewards (in their respective root tokens), block frequencies, and inflation schedules.
* \cL and \cR have equal money supplies, and (by chance) the exchange rate has been stable at $X_{R\rightarrow L} = 3$ L-coins/R-coin.
* \cL and \cR use different PoW algorithms, \cL uses something like Scrypt (similar to Litecoin) and \cR uses something like SHA256 (similar to Bitcoin).
* ASIC/FPGA mining doesn't exist yet, but GPU mining does.
* (In this thought experiment) the best GPUs for mining Scrypt and SHA256 are of the same brand and model --- i.e. the same supply is responsible for the hardware of *all* miners, regardless of which chain they mine.
* There's no comparative advantage between GPU makes/models --- i.e., a miner can't increase their revenue by cleverly organizing which GPUs mine which networks.
* The cost of running both \cL and \cR nodes is negligible.
* \cL and \cR have perfect difficulty adjustment algorithms.
* The miner(s) used in this thought experiment are small relative to the total population of miners --- their choices don't meaningfully impact network hash-rates or difficulty adjustments.

What should we expect regarding the conversion of work?
To start with, let's note that GPU miners could work on either chain --- good hardware for one chain is good hardware for the other, too.
We know that \cL and \cR's block rewards (in root tokens) and block frequencies are the same --- so the exchange rate is going to play a dominant role in RoI (since the only other difference is difficulty and hash-rate).
If a miner could break even by making 30 L-coins, then they could also break even by making 10 R-coins.
They'd need to make $3\times$ as many L-coins as R-coins --- that's the exchange rate.
If \cL and \cR used the same hashing algorithm, then we could compare difficulties to see if this makes sense --- does that miner make $3\times$ as many L-blocks as they would R-blocks?

In this case, though, the difficulties are set for \emph{different hashing algorithms} --- so how many hashes can GPUs do for each hash?
Say a GPU can do 7 SHA256 hashes for each 1 Scrypt hash.
A miner that can do $h$ Scrypt hashes/day should be able to do $7h$ SHA256 hashes/day.
That same miner should be able to make $h \cdot \nicefrac{L_r}{L_d}$ coins per day --- \cL's coins per block, divided by \cL's difficulty (hashes per block) gives us a constant of conversion with units L-coins/L-hash.
Of course, the miner could, instead, mine on \cR, thus making $7h \cdot \nicefrac{R_r}{R_d}$ coins per day.
How do we know which is better?
We use the exchange rate, of course!

If miners could swap from their current chain to the other chain and \emph{increase their revenue}, then we should expect some to do that.
In turn, we expect each chain's difficulty to change, reflecting that change in participation.
If some miners (on the whole) moved from \cL to \cR, then we'd expect \cL's difficulty to decrease and \cR's difficulty to increase, corresponding to how many miners moved.
Since this is an \emph{arbitrage opportunity} (for miners), we expect that any profitability gap will quickly be closed.
Thus, we can say that a miner's revenue is \emph{equal} regardless of which chain they're mining: $\text{Revenue}_L = \text{Revenue}_R$ when measured in the same units.
\begin{align}
  \text{Revenue}_L & = h \cdot \frac{L_r}{L_d}
    & & \text{L-coins}
    & & \text{Revenue on \cL}
    \label{eq:rev-L}
    \\[0.5em]
  \text{Revenue}_R & = 7h \cdot \frac{R_r}{R_d} \cdot X_{R\rightarrow L}
    & & \text{L-coins}
    & & \text{Revenue on \cR in L-coins}
    \label{eq:rev-R}
    \\[0.5em]
  \text{Revenue}_L & = \text{Revenue}_R
    & & \text{L-coins}
    & & \text{The equality we set above}
    \nonumber
    \\[0.5em]
  \therefore h \cdot \frac{L_r}{L_d} & = 7h \cdot \frac{R_r}{R_d} \cdot X_{R\rightarrow L}
    & & \text{L-coins}
    & & \text{\autoref{eq:rev-L} and \autoref{eq:rev-R}}
    \nonumber
    \\[0.5em]
  \frac{L_r}{L_d} & = 7 \cdot \frac{R_r}{R_d} \cdot X_{R\rightarrow L}
    & & \frac{\text{L-coins}}{\text{L-hash}}
    & & \text{Divide by }h
    \nonumber
    \\[0.5em]
  \frac{R_d}{L_d} & = 7 \cdot \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
    & & \frac{\text{R-hashes}\cdot\text{L-blocks}}{\text{L-hash}\cdot\text{R-block}}
    & & \text{Multiply by }\frac{R_d}{L_r}
    \nonumber
    \\[0.5em]
    \frac{R_d}{L_d} & = (7 \cdot 3)
    & & \frac{\text{R-hashes}\cdot\text{L-blocks}}{\text{L-hash}\cdot\text{R-block}}
    & & \text{Sub }X_{R\rightarrow L}\text{, }R_r\text{, and }L_r
    \label{eq:rev-diff-ratio-raw}
    \\[0.5em]
    R_d & = 21 L_d
    & & \frac{\text{R-hashes}}{\text{R-block}}
    & & \text{Multiply by }L_d
    \label{eq:rev-diff-ratio}
\end{align}

So, the ratio of \emph{difficulties} should be $21 \frac{\text{R-hashes}\cdot\text{L-blocks}}{\text{L-hash}\cdot\text{R-block}}$; or, \cR's difficulty \emph{value} should be $21\times$ \cL's difficulty \emph{value}.

Why did the substitution of $X_{R\rightarrow L}\text{, }R_r\text{, and }L_r$ (\autoref{eq:rev-diff-ratio-raw}) equal 3, though?
First, notice that the units did not change with that operation.
Next, we know the exchange rate $X_{R\rightarrow L}=3$; we said so earlier.
So it must be that $\nicefrac{R_r}{L_r}=1$.
This simplifying step is only possible because we began \emph{calculating} numerical values.
We said earlier that \cL and \cR have --- numerically --- identical block rewards, so it must be that $\nicefrac{R_r}{L_r}=1$ \emph{in this case.}

\begin{comment}
<!--
Does this make sense?
A miner can do $7\times$ the hashes on \cR (compared to \cL), but only produces $\nicefrac{7h}{R_d}$ R-blocks.
Those will give a return of $7h \cdot \nicefrac{R_r}{R_d}$ R-coins.
Alternatively, the miner could do $h$ hashes on \cL to produce $\nicefrac{h}{L_d}$ L-blocks.
That provides a return of $h \cdot \nicefrac{L_r}{L_d}$ L-coins.
The exchange rate is 3 L-coins/R-coin, so naturally a miner needs to make more L-coins ....
-->
\end{comment}

Let's consider \autoref{eq:por-conv-work} in light of the above.
\begin{align}
  \text{ConvWork}_{R\rightarrow L}(w) = \; & \frac{L_d}{L_r} \cdot X_{R\rightarrow L} \cdot \frac{R_r}{R_d} \cdot w
    & &\text{R-hashes }\rightarrow\text{ L-hashes}
    & &\text{\autoref{eq:por-conv-work}}
    \nonumber
    \\[0.5em]
  = \; & \frac{1}{21} \cdot \frac{R_r}{L_r} \cdot X_{R\rightarrow L} \cdot w
    & &\text{L-hashes}
    & &\text{Sub }\nicefrac{L_d}{R_d}\text{ from \autoref{eq:rev-diff-ratio-raw}}
    \nonumber
    \\[0.5em]
  = \; & \frac{3}{21} \cdot w = \frac{w}{7}
    & &\text{L-hashes}
    & &\text{Sub }\frac{R_r}{L_r} \cdot X_{R\rightarrow L}\text{ as before}
    \nonumber
\end{align}

We said this was true earlier --- 1 L-hash is worth 7 R-hashes. Thus far, we have not yet found an inconsistency (i.e., we don't yet have a reason to think this won't work).

There is, however, an inconsistency lurking.
Consider:
\begin{align}
  & & & \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
    & &\frac{\text{L-blocks}}{\text{R-block}}
    \nonumber
    \\[0.5em]
  & & & \frac{L_f}{R_f}
    & &\frac{\text{L-blocks}}{\text{R-block}}
    \nonumber
    \\[0.5em]
  \text{But!} & & \frac{L_f}{R_f} \ne \; & \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
    & &\frac{\text{L-blocks}}{\text{R-block}}
    \label{eq:lfrf-ne-rrlr}
\end{align}

These two values are \textbf{not} equal (or comparable), and nothing we've said implies that they should be!
There are \emph{qualitative differences} between the two that is not represented in the current units.
On the one hand, we have something like *relative block frequencies,* and on the other we have something like \emph{a ratio of the \ul{weight or value} of block creation}.
But they have the same units!
What's going on?
How do we know whether a constant of conversion \emph{works} for our purposes?

\subsubsection{Hold Up! We Need to Talk About $\nicefrac{L_f}{R_f}$ and $\nicefrac{R_r}{L_r} \cdot X_{R\rightarrow L}$}

\aside{
  This section regards some subtle ideas about when conversions work (i.e., give meaningful results), and when conversions don't.
  It's worth spending some time on these ideas because \emph{when and how} you can convert is not always obvious.
  But, we \emph{must} understand this to construct a meaningful method of converting block-weight --- which PoR \emph{requires}.
}

Let's consider some units with \emph{real-world} interpretations.
What can L-blocks/R-block \emph{mean?}

* \emph{Relative block frequencies} or \emph{relative confirmation rates} --- This has real-world meaning: Eth1 produces approximately 40 Ethereum-blocks in the same period (measured in seconds) that Bitcoin produces 1 Bitcoin-block.
* \emph{Relative block weights} --- This has real-world meaning: how much harder is it to generate a block on one network vs another network?
* \emph{Relative confirmations} --- This has real-world meaning: how many confirmations does one network take, compared to another, to reach equivalent security?\footnote{
  ``Equivalent security'' means that a doublespend attempt on one network is just as risky, costly, etc, as a doublespend attempt on the other network.
  To do this comparison, we start by picking some $q$ for the attacker on \cL, a transaction value (in L-coins), \cL's block reward, and then find the boundary of attack-viability (measured in L-confirmations).
  The boundary of attack-viability is where rules of thumb around confirmation times come from, e.g., \emph{for Bitcoin, a transaction is safe after 6 confirmations.}
  Next, we consider an \emph{equivalently valuable} transaction on \cR (converting via the exchange rate), and an equivalent attacker (using \autoref{eq:por-conv-work} to convert).
  How many confirmations are needed on \cR so that $\text{P}_L(\text{attack success}) = \text{P}_R(\text{attack success})$?
}

Intuitively, \emph{relative block weights} and \emph{relative confirmations} sound related.
If blocks on \cL are $5\times$ heavier than blocks on \cR,
then we'd have a constant of conversion of $\nicefrac{1}{5}$ L-blocks/R-block;
and a chain of 5 R-blocks would be \emph{roughly} as hard to create as a chain of 1 L-block.
So $\nicefrac{1}{5}$ seems like a reasonable estimate for \emph{relative confirmations}, too.\footnote{
  Due to the dynamics of confirmations, we can't directly compare chain-segments like this, \emph{generally} speaking --- this example is here to help give you an intuition.
  The reason we can't directly compare in this way is that simply \emph{having more confirmations} is worth something in and of itself.
  The relationship is not linear.
  See \citeAHBDS{} for more.
}

Naively, \emph{relative block frequencies} seems to be in the same units as the other two: L-blocks/R-blocks; but they \emph{cannot} be in the same units as \emph{the values mean different things}.
Let's consider \emph{relative confirmation \textbf{rates}} particularly.
What happens if we assume that \emph{seconds} on each chain aren't the same thing, i.e., the units of \emph{confirmation rate} are L-blocks/L-second (or R-blocks/R-second)?\footnote{
  Alternatively, you could assume that confirmation rates are \emph{always} in the same units (i.e., \emph{generic} blocks/second).
  That will yield similar results; the logic basically works either way with some minor tweaks.
  The important point is that the units of $\nicefrac{L_f}{R_f}$ are \textbf{not} L-blocks/R-block.
}
Crucially, we can \emph{not} cancel the \emph{seconds} anymore:
\begin{align}
  ? & = \frac{L_f}{R_f}
    & & \frac{\text{L-blocks} \cdot \text{R-seconds}}{\text{L-second} \cdot \text{R-block}}
    & & \text{Relative confirmation rates}
    \label{eq:rel-conf-hz}
    \\[0.5em]
  %  ? & = \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
  %    %& & \frac{\text{L-blocks} \cdot (\text{R-coins} \rightarrow \text{L-coins})}{\text{L-coins} \cdot \text{R-block}}
  %    & & \frac{\text{L-blocks} \cdot \text{L-coins}}{\text{L-coins} \cdot \text{R-block}}
  %    & & \text{Relative block rewards via } X_{R\rightarrow L}
  %    \nonumber
  %    \\[0.5em]
  %  ? & = \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
  %    & & \frac{\text{L-blocks} \cdot (\text{R-coins} \rightarrow \text{L-coins})}{\text{L-coins} \cdot \text{R-block}}
  %    %& & \frac{\text{L-blocks} \cdot \text{L-coins}}{\text{L-coins} \cdot \text{R-block}}
  %    & & \text{Relative block rewards via } X_{R\rightarrow L}
  %    \nonumber
  %    \\[0.5em]
  ? & = \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
    & & \frac{\text{L-blocks}}{\text{R-block}} \cdot \cancelto{1}{\frac{\text{R-coins} \cdot \text{L-coins}}{\text{L-coins} \cdot \text{R-coins}}}
    %& & \frac{\text{L-blocks} \cdot \text{L-coins}}{\text{L-coins} \cdot \text{R-block}}
    & & \text{Relative block weights via } X_{R\rightarrow L}
    \label{eq:rel-block-weight}
\end{align}

We can see that \autoref{eq:rel-conf-hz} and \autoref{eq:rel-block-weight} are now obviously not comparable.
\begin{comment}
Moreover, it's easy to see why \emph{relative confirmations} is not as simple as \emph{relative confirmation rates}.
\end{comment}

The reason that $\nicefrac{L_f}{R_f}$ did not make sense before is that we \emph{were not including all necessary \ul{context}!}
There is \emph{implicit context} in some properties of blockchains --- \emph{participation}.
Values like $\nicefrac{L_f}{R_f}$ --- when used to measure the \emph{target block frequency} --- \emph{do not factor in participation}; the target block time is usually a \emph{constant}, so it can hold no \emph{network-specific context}.

Where does this network-specific context come from?
How is it separated from \`\`world'' context --- like target block frequencies?
How is the network-specific context maintained over time?
The answer to all three questions is the same: the \textbf{Difficulty Adjustment Algorithm} (DAA).

\defineTermTex{Difficulty Adjustment Algorithm (DAA)}{
  An algorithm which updates its chain's difficulty as valid blocks are produced.
  The \emph{output} of a DAA is \emph{context laden} --- units take on \emph{additional context}
}

DAA's typically work like this: calculate a \emph{ratio} by which to adjust (multiply) the prior difficulty, based on a \emph{target} block production rate and the \emph{measured} block production rate.

Bitcoin, for example, adjusts its difficulty every 2016 blocks.\footnote{
  Note: in Bitcoin, a difficulty of 1 corresponds to $2^{32}$ hashes.
}
A ratio is found by multiplying the previous difficulty ($D_\text{prev}$) by the actual duration ($\Delta t_\text{actual}$) of the last 2016 blocks and dividing by the target duration ($\Delta t_\text{target}$) for 2016 blocks.\footnote{
  Note: in practice the ratio is clamped between $\nicefrac{1}{4}$ and $4$. See Bitcoin's \href{https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/pow.cpp\#L49-L72}{\texttt{src/pow.cpp}} for the implementation.
}
Note that the units of $\Delta t_\text{actual}$ are B-seconds/(2016 B-blocks), and the units of $\Delta t_\text{target}$ are seconds/(2016 blocks).

DAA's are special: they are the means by which \emph{context} is added.
DAA's don't explicitly deal with this context though --- it's not mentioned in the algorithm itself.
The key to a DAA's success is that it operates \emph{relative to a past state that is \ul{already} context laden.}
So DAA's don't need to have any special awareness of context, just that multiplying the past difficulty by a \emph{particular ratio} will adjust the \emph{confirmation rate} to align with the \emph{target block frequency}.
It's an \emph{incremental and ongoing process}.
Since DAA's don't have initial conditions, there's no bootstrapping concern.
To function, a DAA only needs to say how the difficulty should \emph{change}; it doesn't need to know what it actually \emph{is}.
We will use the subscript $W\rightarrow B$ to denote the idea of converting between some \emph{world} context, and the \emph{network context} (of Bitcoin).
<!-- By adding this special context (which is via the implicit conversion of ) -->
\begin{align}
  \text{Note that:}
    & & \text{ConversionConst}_{W\rightarrow B}
    & = \frac{\Delta t_\text{actual}}{\Delta t_\text{target}}
    & & \frac{\text{B-seconds} \cdot \text{blocks}}{\text{B-block} \cdot \text{second}}
    \nonumber
    \\[0.5em]
  \text{Bitcoin's DAA:}
    & & \text{NextWork}_{W\rightarrow B}(D_\text{prev})
    & = \frac{\Delta t_\text{actual}}{\Delta t_\text{target}} \cdot D_\text{prev}
    & & \frac{\text{B-hashes} \cdot \text{B-seconds} \cdot \text{blocks}}{\text{B-block}^2 \cdot \text{second}}
    \nonumber
\end{align}

When a DAA adds context, it converts blocks $\rightarrow$ B-blocks, and seconds $\rightarrow$ B-seconds.

Alternatively, it could \emph{strip} context; the only thing that matters is that $\text{ConversionConst}_{W\rightarrow B}$ is unitless.
Either way works because the DAA acts as a boundary of the convertible context in both cases.
\begin{align}
  \text{Alt. with context:}
    & & \text{NextWork}_{W\rightarrow B}(D_\text{prev})
    & = \frac{\Delta t_\text{actual}}{\Delta t_\text{target}} \cdot D_\text{prev}
    & & \frac{\text{B-hashes}}{\text{B-block}}
    \label{eq:bitcoin-daa}
    \\[0.5em]
  \text{}
    & & \implies \text{ConversionConst}_{W\rightarrow B}
    & = \frac{\Delta t_\text{actual}}{\Delta t_\text{target}}
    & & \text{(unitless)}
    \nonumber
\end{align}

\todoDraftOnly[m]{rework above and if kept then note that we'll include the context explicitly.}

<!-- \autoref{eq:bitcoin-daa} -->

\defineTermTex{Convertible Context}{
  The boundary of a group of values that are mutually convertible.
  Within a convertible context, all values must be of the same \emph{scale} or have known exact scaling factors
}

The general case of a DAA's relationships (flows of \emph{information} and \emph{context}) are diagrammed in \autoref{fig:daa-conversion}.

\begin{figure}[p]
\centering
\includegraphics[max width=\linewidth]{diff_adjustment_alg_sag}
\caption[
  How does a difficulty adjustment algorithm interact with and define the \emph{convertible context} of various properties of its chain?
  This figure shows flows of \emph{information} and \emph{context}, and where conversion is possible between these properties.
]{
  The difficulty adjustment algorithm governs the relationship between the inputs: the previous difficulty, the target block frequency, and network participation (chain history); and the output: the network difficulty.
  The DAA is how \emph{confirmations} and \emph{coins} become \textbf{laden} with \emph{implicit context}.
  If we don't account for this \emph{implicit context} then our conversions will be nonsensical.
  The implicit context is \emph{network participation} --- thus, \texttt{N-} prefixes the units which are \emph{context laden}.
  Thick arrows indicate \emph{network context}, and thin arrows indicate \emph{world context}.
  Solid arrows show the \emph{flow} of \emph{information}.
  Dashed arrows show the \emph{flow} of \emph{context}.
  Two-way arrows ($\longleftrightarrow$) link two values that are \emph{convertible}.
  The collection of values mutually linked by two-way arrows define the \emph{convertible context}.
  Values can only be converted when there is a direct two-way path between them.
}
\label{fig:daa-conversion}
\end{figure}

How do we know that \emph{both} blocks and seconds become context laden via a DAA, though?
Let's consider what $\nicefrac{L_f}{R_f}$ means for the possible combinations of context laden values and note whether the meaning works for conversion or not (i.e., whether using it \emph{appropriately} as a constant of conversion, or scaling factor, will produce sensible results).
\begin{align}
  \text{No context:} & & \frac{L_f}{R_f}
    & & \text{(unitless)}
    & & \text{works}
    \label{eq:conv-both-no-ctx}
    \\[0.5em]
  \text{Context laden blocks:} & & \frac{L_f}{R_f}
    & & \frac{\text{L-blocks}}{\text{R-block}}
    & & \text{fails}
    \label{eq:conv-both-ctx-blocks}
    \\[0.5em]
  \text{Context laden seconds:} & & \frac{L_f}{R_f}
    & & \frac{\text{R-seconds}}{\text{L-second}}
    & & \text{fails}
    \label{eq:conv-both-ctx-seconds}
    \\[0.5em]
  \text{Both context laden:} & & \frac{L_f}{R_f}
    & & \frac{\text{L-blocks} \cdot \text{R-seconds}}{\text{L-second} \cdot \text{R-block}}
    & & \text{?}
    \label{eq:conv-both-ctx-laden}
\end{align}

We've seen \autoref{eq:conv-both-no-ctx} and \autoref{eq:conv-both-ctx-blocks} before.
The first represents the ratio of block frequencies (unitless) --- that's straightforward and works.
The second has units L-blocks/R-block, which sounds like it should be the ratio of block \emph{weights} --- but it's clear that it \emph{isn't} that.
(So this conversion method fails.)

\autoref{eq:conv-both-ctx-seconds} has weird units, though.
R-seconds/L-second means something like: the relative participation of each network compared with a recent past state; i.e., the ratio of the ratios of each network's \emph{actual} block production compared to its \emph{target} block production.
(This conversion method also fails.)

\autoref{eq:conv-both-ctx-laden} measures something like \emph{relative weighted confirmation rates}.
It's not clear if is useful or not, but we \emph{do} know that \emph{no other} value we have access to has context laden seconds as a unit.
How can we use it to convert between anything meaningful if context laden seconds can't be canceled via some conversion?
(Do we even \emph{need} to ever use those units, anyway?)

In general, it seems like the safe option is \emph{not to use $L_f$ or $R_f$ when converting work} --- unless we have some \emph{specific, context-driven} explanation for why it's okay in that case.

How do these ideas of context laden values work when converting values \emph{between} these network-contexts? This is diagrammed in \autoref{fig:daa-conversion-2}.

In essence, an exchange rate provides meaningful conversion between L-coins and R-coins.
Converting in this way \emph{does not drop context}.
Since network context is respected, we can use an exchange rate to build a meaningful constant of conversion \emph{across networks}.

\begin{figure}[p]
\centering
\includegraphics[max width=\linewidth]{diff_adjustment_alg_times_2_sag}
\caption[
  How are the convertible contexts of two different networks related?
  This figure shows the expanded \emph{convertible context} of two interacting blockchains, enabled by an exchange rate, $X_{R\rightarrow L}$.
]{
  How are the convertible contexts of two different networks related?
  Without the market context, there's no conversion path that allows for the conversion of work --- the conversion path between difficulties is a \emph{consequence} of $X_{R\rightarrow L}$ (the exchange rate).
  This is the same convertible context that miners use to determine which network is most profitable for them.
  Double-lined arrows indicate \emph{market context}.
  Thin single-lined dashed arrows indicate \emph{world context}.
  Notice that the convertible properties which we are interested in (such as $L_d$ and $R_d$) use \emph{thick, double-lined, and dashed} two-way arrows, indicating that we are using network context \emph{and} market context to convert block-weight.
}
\label{fig:daa-conversion-2}
\end{figure}


<!-- re block freq and conf rate: everything about them is the same except their nature -->

<!-- can't divide conf rate (blocks/n-second) by block freq (blocks/s) to get (s/n-seconds) either --- so blocks must be diff units too. -->

<!-- ~~DAA is a constant of conversion --- in effect.~~ no --- it does more.
information is *lost* through the DAA. -->

\aside{
  With regard to DAAs, it should be noted that Bitcoin's was the first, and the method has some undesirable properties.
  I quite like the algorithm named \textsc{DAA-2} (which is used by Bitcoin Cash) in \citeDaaTwoLink{}.
  Experimentally, it seems to work well with \autoref{sec:dos-and-dags}.
}

\subsubsection{Conversions and Sums}

We know that, after conversion, we can sum work from two different chains.
Are there any \emph{other} values (in units other than L-hashes) that we can sum up, though?
When we're \emph{summing} weights as part of calculating chain-weight (e.g., that of \autoref{alg:refl-1-bw}, or \autoref{alg:por-reflected-block-weight}), do we need to sum \emph{L-hashes}?
Well, no.
We only need to \emph{end up} with L-hashes.

Consider the case for a two-stage linear conversion method.
That is: we convert the input into some common units (which could be anything), then we convert those common units into the final units.
If both partial-conversions are \emph{linear}, then we must have a situation like this:
\begin{align*}
  \text{Convert}_{L\rightarrow R}(\dots) =&\; \text{Conv}_1(\text{Conv}_2(\dots))
    & & \\[0.5em]
  =&\; V_1 \cdot \text{Conv}_2(\dots)
    & &\text{For some constant of conversion, }V_1
\end{align*}

Let's sum multiple conversions, e.g., as done in \autoref{alg:refl-1-bw}:
\begin{align*}
  \sum\limits_{i=0}^n \text{Convert}_{L\rightarrow R}(\dots) =&\; \sum\limits_{i=0}^n V_1 \cdot \text{Conv}_2(\dots)
    & &\text{} \\[0.5em]
  =&\; V_1 \cdot \sum\limits_{i=0}^n \text{Conv}_2(\dots)
    & &\text{Factorize out }V_1
\end{align*}

Thus, \emph{any} common units, which are linearly convertible both from a reflecting chain's block and to local chain-work, can be used during summation.

<!-- & \frac{R_r}{L_r}
  & &\frac{\text{R-coins}\cdot\text{L-blocks}}{\text{R-block}\cdot\text{L-coin}}
  & & \nonumber
  \\ -->

\aside{
  Before we move on, let's consider:
  \begin{align}
    & \frac{L_d}{L_r} \cdot X_{R\rightarrow L}
      & &\frac{\text{L-hashes}}{\text{R-coin}}
      & & \text{} \nonumber
      \\[0.5em]
    & \frac{R_r}{R_d} \cdot X_{R\rightarrow L}
      & &\frac{\text{L-coins}}{\text{R-hash}}
      & & \text{Similarly} \nonumber
      \\[0.5em]
    \therefore \text{ConvReward}_{R\rightarrow L}(w) = \; & \frac{R_r}{R_d} \cdot X_{R\rightarrow L} \cdot w
      & & \text{R-hashes} \rightarrow \text{L-coins}
      & & \label{eq:por-conv-reward}
  \end{align}

  Is it possible that we can convert chain-work \emph{via summing block rewards?}
}

\subsection{Conversion Contexts}

What blockchain contexts can facilitate the conversion of block-weight?

Whatever contexts we find, we will need to figure out a way to get the exchange rate that is \emph{at least as secure} as the consensus algorithms (otherwise we'd be introducing a new weakest-link).
That can't be too hard, right?

Can we \emph{avoid} that exchange rate, though?
Well, there is a context where $X_{R\rightarrow L}=1$: \textbf{when L-coins $\equiv$ R-coins}, i.e., both chains use the same root token.
In that case, $\nicefrac{L_d}{L_r} \cdot \nicefrac{R_r}{R_d}$ gives us L-hashes/R-hash directly.

\subsubsection{A Single Root Token Across Multiple Chains}

\label{sec:conversion-single-root-token}

\input{20-por/40-single-root-token-2.tex}

\subsubsection{Different Root Tokens with a DEX}

\label{sec:comparing-weight-dex}

\input{20-por/45-diff-rts-and-dex-2.tex}

\subsubsection{What About SPV?}

Both contexts (SRT and DEX) require that participating chains can do on-chain SPV against one another.
Chains need some ability to *introspect* reflecting chains --- e.g., SRT requires that users can move root tokens between chains, and the DEX context requires two chains to agree on the exchange rate between their root tokens.
Even without this requirement, some method of cross-chain communication is clearly desirable.

Eventually, we'll need to construct a method for SPV between mutually reflecting chains that works and is safe.
However, there are still other problems that we have not yet solved, and the solutions may motivate certain blockchain designs over others.
The difference between these designs will likely impact whether (and how) SPV can be done safely.
So, attempting to solve the SPV problem at this point is premature.

We will proceed on the \emph{assumption} that SPV is possible and easy to do in a reasonable time period, and we'll investigate the problem of SPV in detail in \autoref{sec:spv-in-ut}.

\subsection{Converting Confirmations}

\label{sec:converting-confirmations}

%% eq:por-conv-dex

So far, we've considered PoW chains only.
Conversion of chain-weight between PoW chains can work \emph{if and only if} we can convert between \emph{work} (i.e., hashes) done on each chain --- given an appropriate context.
For a given PoW block, the network knows exactly how much work is implied by that block --- the expected number of hashes to produce it.
Thus, for PoW chains, there is an exact conversion between \emph{work and confirmations} (for some context at some point in time).
Over short time-scales, this conversion ratio is approximately constant (in general it's a function that takes a timestamp as an input parameter).
Thus, \emph{chain-weight} (as represented in figures via $\Sigma_w$, e.g. \autoref{fig:dag-ex1-full}) can be represented either in something like \emph{hashes} or \emph{difficulty} \textbf{or} chain-weight can simply be in terms of \emph{confirmations}.

\aside{
  If we convert \emph{work to confirmations}, will we end up with something \emph{incompatible and contradictory} to the traditional notion of ``a confirmation''?
  There are definitely differences.
  For example: if we convert confirmations, then \emph{we'll have non-integer confirmations}, and what does 0.88 confirmations mean?
  Is that less good than a normal confirmation?

  This problem arises because \emph{we're not actually converting work to confirmations}, per se: we're converting \emph{another chain's work} into \emph{equivalent-confirmations} relative to something.
  Equivalent-confirmations are another chains confirmations that have been \emph{converted to be in terms of the local chain's confirmations}.
  Most likely, those equivalent-confirmations will be relative either to some known historical confirmation, or to that of the \emph{current} block.
}

Why think about chain-weight in terms of \emph{equivalent-confirmations} instead of \emph{work}?
There are a few reasons.
First, \emph{confirmations are general!}
If we reason in terms of \emph{confirmations} instead of \emph{work}, then \emph{maybe} we can apply these ideas to \emph{other chains} that don't use PoW.
Second, it \emph{simplifies thinking}.
The purpose of converting chain-weight is clearer and easier to reason about.
Finally, it makes explicit the requirement that \emph{we can only compare to a grounded context}.

There is no way to say \emph{X work on \cL is worth Y work on \cR} without adding necessary context like \emph{when} that conversion is happening.
Confirmations (like work) require that grounding, since they need to be scaled when converting between different chains.
What about confirmations from the same chain?
Unlike work (which can be summed directly), confirmations always require conversion to a \emph{known standard} --- even when they're \emph{from the same chain}.
For example, we can say that the single confirmation provided by Bitcoin block 704610 is \emph{equivalent} to approximately 19,893,045,000,000 genesis-confirmations.\footnote{
  A genesis-confirmation is relative to the Bitcoin genesis block --- which had a difficulty of exactly 1.
}
The conversion-ratio is equal to the difficulty of block 704610.
That is, it would take a chain of $\sim$ 20 trillion blocks, each with 1 genesis-confirmation worth of work, to match the weight of block 704610.

Now, \textbf{converting confirmations,} how do we actually do it?
<!-- Consider the \emph{excess capacity} in our methods of conversion that we covered in \autoref{sec:comparing-weight-dex}. -->
If we want to convert confirmations, then we'll need to abstract away from the idea of \emph{difficulty} in our conversion method.
<!-- Thus, \emph{there is no $R_d$ for us to rely on.} -->
\begin{align}
  % \text{Consider: } & \frac{R_d}{L_d}
  %   & &\frac{\text{R-hashes}\cdot\text{L-blocks}}{\text{R-block}\cdot\text{L-hash}}
  %   & & \nonumber
  %   \\[0.5em]
  % \implies \; & \frac{R_d}{L_d} \cdot \left( \frac{L_d}{L_r} \cdot X_{R\rightarrow L} \cdot \frac{R_r}{R_d} \right)
  %   & &\frac{\text{L-blocks}}{\text{R-block}}
  %   & &\text{From \autoref{eq:por-conversion-const-1}} \nonumber
  %   \\[0.5em]
  \text{Consider: } \;\;\; & \frac{R_r}{L_r} \cdot X_{R\rightarrow L}
    & &\frac{\text{L-blocks}}{\text{R-block}}
    & & \text{} \nonumber
    % & & \text{Reduce} \nonumber
    \\[0.5em]
  \therefore \text{ConvBlocks}_{R\rightarrow L}(b) = \; & \frac{R_r}{L_r} \cdot X_{R\rightarrow L} \cdot b
    & &\text{R-blocks }\rightarrow\text{ L-blocks}
    & & \label{eq:por-conv-blocks}
  %  \\[0.5em]
  %\therefore \text{ConvBToCoins}_{R\rightarrow L}(b) = \; & R_r \cdot X_{R\rightarrow L} \cdot b
  %  & &\text{R-blocks }\rightarrow\text{ L-coins}
  %  & & \nonumber
\end{align}

So $1\times$ \cR confirmations is worth $\big(\frac{R_r}{L_r} \cdot X_{R\rightarrow L}\big)$ \cL confirmations.
Nice and simple.

<!-- Notice that L-coins are easily converted to blocks via the conversion constant $\nicefrac{1}{L_r}$, and hashes via the conversion constant $\nicefrac{L_d}{L_r}$. -->

\subsubsection{Coins per Confirmation}

\label{sec:coins-per-confirmation}

Given a multi-chain network, could we measure block-weight in coins?
It seems promising and elegant if it works, but does it have any real-world meaning?

One example where measuring chain-weight in coins does have some meaning is \autoref{sec:conversion-single-root-token} (the SRT context).
Let's consider this, starting with the conversion used in \autoref{eq:srt-block-ratios}.
\begin{align}
  C_r = \; & L_r \cdot \frac{C_t}{L_t} \cdot \frac{L_f}{C_f}
    & & \frac{\text{L-coins}}{\text{C-block}}
    & & \text{Via \autoref{eq:srt-block-ratios}}
    \nonumber
    \\[0.5em]
  C_r \cdot \frac{C_f}{L_f} = \; & L_r \cdot \frac{C_t}{L_t}
    & & \frac{\text{L-coins}}{\text{L-block}}
    & & \text{}
    \nonumber
    \\[0.5em]
  \therefore \sum\limits_{C \in \{L, R\}} L_r \cdot \frac{C_t}{L_t} = \; & L_r \cdot \frac{L_t + R_t}{L_t}
    & &\frac{\text{L-coins}}{\text{L-block}}
    & &\text{Sum coins (as a proxy for weight)}
    \label{eq:chain-coin-weight}
    \\[0.5em]
  L_r \cdot \frac{C_t}{L_t} = \; & \frac{L_t \cdot I}{G_t \cdot L_f} \cdot \frac{C_t}{L_t}
    & & \frac{\text{L-coins}}{\text{L-block}}
    & & \text{Via \autoref{eq:srt-reward}}
    \nonumber
    \\[0.5em]
  = \; & \frac{C_t \cdot I}{G_t \cdot L_f}
    & & \frac{\text{L-coins}}{\text{L-block}}
    & & \text{}
    \nonumber
    \\[0.5em]
  \therefore \sum\limits_{C \in \{L, R\}} \frac{C_t \cdot I}{G_t \cdot L_f} = \; & \frac{L_t + R_t}{G_t} \cdot \frac{I}{L_f}
    & &\frac{\text{L-coins}}{\text{L-block}}
    & &\text{Sum coins (as a proxy for weight)}
    \label{eq:chain-coin-weight2}
\end{align}

What does \autoref{eq:chain-coin-weight} imply if \cL and \cR are the only two chains in a context like \autoref{sec:conversion-single-root-token}?
Notice that, in this case, $L_t + R_t = G_t$, the network-wide currency supply.
One implication is that weight (measured in coins) effectively counts \emph{how much of the full network} is contributing to Chain \cL's security --- represented via the coins that were minted in those contributing blocks.
It's easier to see in \autoref{eq:chain-coin-weight2} as the sum collapses to $\nicefrac{I}{L_f}$.

If the all chains in the network are functioning well, we should expect that summing a chain's weight in coins \emph{over the full history of the chain} should be close to the sum of all coins minted through block rewards.
Of course, this is only useful over \emph{multiple} chains.
\textbf{If a single, traditional blockchain tried to do this, then all chain-weights would be basically identical!}\footnote{
  This may be a new criticism of PoS.
  In essence: a blockchain needs something like a DAA to factor-in participation.
  PoS chains use \emph{coins} instead of \emph{hashes}, but \emph{coins} will never provide a way to determine which chain has higher participation.
  Moreover, \emph{coins} is actually a very \emph{bad} way to measure participation (for a standalone PoS chain), because the \emph{most valuable future network} is one where coins are being used for \emph{actual trade}, and this must happen at the expense of the number of coins dedicated for staking.
  Thus, PoS chains \emph{can only ever have objectively secure fork-rules} when other factors are included in their conversion contexts (like using PoR with a PoW chain).
  One thing PoS chains could try is: measuring weight \emph{in another chain's hashes}.
}
This happens because these conversion methods \emph{don't try to convert work done at different times.}
PoR only ever converts \emph{near-simultaneous work}, i.e., if the coin-weights of reflecting blocks are summed, that is always converted to local work \emph{with respect to some specific moment in time.}

While measuring weight in coins (in this case, at least) seems to have some meaning, we probably shouldn't \emph{leave} chain-weight in those units.
The difficulty of a PoW network converts network size (participation) into hashes, and it is adjusted regularly.
If a chain-weight measurement doesn't account for this, then \emph{how does it include participation at all?}
Without including participation in chain-weight, how can two local alternate histories be meaningfully compared?
When measuring and converting chain-work, we \emph{always} want to convert confirmations or coins back to meaningful units which factor in \emph{participation} in some way.


<!-- = \; & \frac{C_t \cdot I}{G_t \cdot C_f} \cdot \frac{C_f}{L_f} \cdot \frac{L_d}{L_r}
  & & C_r: \text{ Substitute \autoref{eq:srt-reward}}
  \\[0.5em]
= \; & \frac{C_t \cdot I}{G_t \cdot C_f} \cdot \frac{C_f}{L_f} \cdot \frac{L_d \cdot G_t \cdot L_f}{L_t \cdot I}
  & & L_r: \text{ Substitute \autoref{eq:srt-reward}}
  \\[0.5em]
= \; & \frac{C_t}{L_t} \cdot L_d
  & & \text{Reduce}
  \\[0.5em]
= \; & (\frac{G_t}{L_t} - 1) \cdot L_d
  & & \text{If } C_t = G_t - L_t
  \\[0.5em] -->


\subsection{Reflection Between PoW and PoS Chains}

\label{sec:reflection-pow-and-pos}

\aside{
  Whether PoS systems \emph{can} be secure is not a focus of this paper.
  There are still \href{https://github.com/zack-bitcoin/amoveo-docs/blob/master/other_blockchains/proof_of_stake.md}{criticisms of PoS} without \href{https://github.com/zack-bitcoin/amoveo-docs/blob/master/other_blockchains/the_defence_of_pos.md}{adequate answers}.
  The intention of sections like this is not to endorse PoS, but rather to explore what is possible \emph{if} PoS can be done securely.
}

Perhaps one of the most interesting features of *Proof of Reflection* is that PoW chains and PoS chains can reflect one another. Up till now, we've contextualized the weight of a reflection via the *work* required to produce a block. But the concept of *work* does not neatly apply to foundational consensus mechanisms that do not require the utilization of some physical resource --- such as PoS.

\defineTermTex{Foundational Consensus Mechanisms}{Those mechanisms, like PoW and PoS, which can work in some \emph{standalone} fashion; PoR is a cross-chain \emph{extension} to such mechanisms}

Putting the issue of *conversion* aside for a moment, is it possible *in principle* for PoW and PoS chains to reflect one another? Yes. Additionally, PoR provides decisive advantages *both* for PoW chains *and* PoS chains, though there are some additional problems that must be solved, too.

If a PoW chain is reflected in a PoS chain, then an attacker will likely need more than just computational resources to attack the PoW chain.
Consider a PoW chain and a PoS chain that share a root token, and each chain hosts approximately 50% of the total supply.
If the two chains have equal block production frequencies, then (using \autoref{alg:weightof-ratio}) 50% of the network's security comes from each chain.

Consider an attack on the PoW chain and presume that the difficulty on the PoW chain is constant over the attack, i.e., the PoW chain's difficulty doesn't adjust quickly enough to react to the attack. Additionally, assume the attacker has *not* been contributing to the network before the attack, i.e., their hash-rate is not accounted for in the PoW chain's difficulty. Given the two chains are mutually reflecting, half of the network's security is provided by the PoS chain (and thus immune to the attacker in this case). Therefore, a successful attacker --- *using the traditional method of mining a competing chain-segment in private* --- must generate more blocks than both chains combined. That means the attacker needs *twice* the honest hash-rate for a guaranteed successful attack.

However, consider the case that \emph{the security contribution of the PoW chain is \ul{capped} at 50\%} --- i.e., capped at the proportion of root tokens hosted on that chain.
For our purposes, this situation is approximately equivalent to that where the PoW chain has a *perfect* difficulty adjustment algorithm, i.e., the network instantly adapts to keep the block production frequency constant.
For the sake of this demonstration, assume that these chains *retroactively* adjust block weightings to ensure this cap holds.
Let $p > 0$ be the honest miners' contribution to *overall* network security, and $q > 0$ be the attacker's contribution.
As the PoW contribution to overall security is capped at 50%, the equality $p + q = 0.5$ is enforced.
In this case, the attacker will have a maximum chain-weight contribution rate of $\frac{1}{2} \cdot \frac{q}{q + p}$ and the honest chain-segments will have a maximum contribution rate of $\frac{1}{2} \cdot \frac{p}{q + p} + \frac{1}{2}$.
The condition for a successful attack is shown in \autoref{eq:refl-pow-pos-1}, and the inequality has no solutions.
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
  Additionally, with traditional blockchains (which are trees), an empty-block DoS is possible --- this is addressed in \autoref{sec:dos-and-dags}.
}

What about the PoS chain, though; what benefits does it gain from this relationship?
The answer here is simple: by using mutual PoR with a PoW chain, the PoS chain gains *thermodynamic security*; the PoS chain's history is *thermodynamically secured* by the PoW chain.
\textbf{This solves the \emph{Nothing at Stake} problem for any well constructed PoS scheme.}\footnote{
  I consider the \emph{Nothing at Stake} problem and \emph{long range} attacks to be two sides of the same coin.
  Maybe it's worth explicitly mentioning that mutual PoR solves long-range attacks, too.
}
Furthermore, it is possible for error-correction methods like \emph{slashing} to be implemented *on the PoW chain*, not the PoS chain.
Moving the staking and error correction methods to a different chain will require subtle and precise protocol design, but such changes are *in principle* possible with tolerable overhead.

There are some (as yet) unsolved problems that arise through this design, such as the *economic* details of managing block rewards across the PoW and PoS chains.
Given that solutions to this problem likely depend on the specific details of the relevant PoS systems, this problem is not addressed here.
Note: conversion methods for reflected weight, like \autoref{alg:por-reflected-block-weight}, will work provided a well defined \textsc{WeightOf} function exists.

There are some other conjectured solutions to the *Nothing at Stake* problem.

```{=latex}
\bquote{
  %% cspell: disable-next-line
  Long-range ``nothing-at-stake'' attacks are circumvented through a simple ``checkpoint'' latch which prevents a dangerous chain-reorganisation of more than a particular chain-depth. To ensure newly-syncing clients are not able to be fooled onto the wrong chain, regular ``hard forks'' will occur (of at most the same period of the validators' bond liquidation) that hard-code recent checkpoint block hashes into clients.
}[Dr. Gavin Wood; \citePolkadotLink, s5.2]
```

```{=latex}
\bquote{
  Provided that stakeholders are frequently online, nothing at stake is taken care of by our analysis of forkable strings (even if the adversary brute-forces all possible strategies to fork the evolving blockchain in the near future, there is none that is viable), and our chain selection rule that instructs players to ignore very deep forks that deviate from the block they received the last time they were online.
}[\citeOuroborosLink, s10]
```

These two examples solve the \emph{Nothing at Stake} problem via mechanisms that are *external* to the protocol itself, i.e., hard-coded checkpoints and the requirement that nodes are online ``frequently''.

The solution provided by mutual reflection with a PoW blockchain --- i.e., thermodynamic security --- is provided *by the protocol itself* and can only *increase* the security of PoS mechanisms.
Thus, UT's solution to *Nothing at Stake* is qualitatively superior.

<!-- \aside{
  \autoref{sec:converting-block-weights} mentions a \emph{natural symmetry} --
} -->

\subsection{Counting Work}

\label{sec:counting-work}

\input{20-por/90-counting-work.tex}


%% END ### RELEASE

%% BEGIN ### DRAFT

\subsection{Incompatibility between Merged Mining and PoR}

\todoDraftOnly[h]{write --- The Insecurity of Merged Mining}

- Merged Mining allows attacking merged chains at 0 cost.
- that means that if a parent chain and a merged mined child chain where to reflect one another, then the weight contributed via merged mining must be 0 --- no additional work was actually done beyond that of the parent-chain.
- Also, if some other chain reflects both a parent chain *and* a merged mined child chain, then the net benefit is equal to *only* the work contributed by the reflecting parent chain.


\todo{PoR in general: (nb: check if this is sufficiently answered) reflect only chains that reflect your history; if they favor a different history, then you should be building on that history instead, so don't reflect those blocks --- i.e. ppl should calculate weight to be 0.}


%% END ### DRAFT
