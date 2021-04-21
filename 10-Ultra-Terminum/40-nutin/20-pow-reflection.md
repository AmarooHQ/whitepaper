## PoW reflection

\mk{note: reminder about secrecy and patent-ability, this is part of it}

Can blockchains work cooperatively to secure each other? It certainly seems that there is nothing *in principle* that prohibits this. Can we come up with a way to do this?

The idea of one blockchain 'tracking' another blockchain via chain-headers and its state via SPV proofs is not new. In 2013[^xc1], I (loosely) proposed a system which used this method to support rich cross-chain exchange. I wrote a simplified implementation of this method in the very early days of Ethereum[^xc3], a precursor to the later-successful BTC Relay[^xc4]. The general idea of one blockchain tracking the headers of another will be our starting point.

[^xc1]: <https://bitcointalk.org/index.php?topic=198032.0>, <https://bitcointalk.org/index.php?topic=598784.0>
[^xc3]: <https://github.com/XertroV/coppr/blob/master/chainheaders.py>
[^xc4]: <https://github.com/ethereum/btcrelay>

### Tracking Bitcoin Headers and Txs from Ethereum

The idea that Ethereum SCs can track Bitcoin chain-headers is well understood. Bitcoin's proof of work algorithm is clean and simple, so implementing the necessary logic in an Ethereum SC is not that difficult. In principle, any chain that supports some headers-only mode can be tracked in this way. In practice that can be difficult (e.g., Ethereum's EVM doesn't support memory hard hashes unless special cases are introduced). But we're not interested in practicality *at the moment*.

Let's add such a contract to Ethereum and describe the relevant data and events in the following table. \autoref{fig:pr-btc-eth-step1} illustrates this.

| Time (~15s increments) | Bitcoin block made | Eth block made | Eth block contents | Eth state |
|---|---|---|---|---|
| ... |||||
| 0 | k ||||
| 1 | | j | $BTC_k$ header | Tracks BTC chain up to $BTC_k$ |
| ... |||||
| 40 | k + 1 ||||
| 41 | | j + 40 | $BTC_{k+1}$ header | Tracks BTC chain up to $BTC_{k+1}$ |
| ... |||||

\begin{figure}[H]
\centering
\includegraphics[height=0.3\textheight]{pow_refl_btc_eth_step1_sag}
\caption{Bitcoin headers are included in Ethereum's state (via user made transactions) as they are produced. This is roughly how \textit{BTC Relay} works.}
\label{fig:pr-btc-eth-step1}
\end{figure}

After a Bitcoin block is produced, an Ethereum miner includes a transaction containing the Bitcoin header, which updates the SC tracking the Bitcoin chain. In reality there are practical concerns about incenting someone to produce such a transaction (among other things); we're not concerned with those here. We're just concerned with the relationships that exist and what they can do.

Why would a chain want to track another chain? The typical answer is to prove transactions or state occurred on the foreign chain. On Ethereum one could build a trustless $\text{BTC}\leftrightarrow\text{ETH}$ market, for example.

### Two Blockchains

\label{sec:two-blockchains}

Let's build up the idea via a hypothetical situation with two distinct blockchains. For simplicity, you can imagine these as Bitcoin and Ethereum 1 -- at least to start with. However, keep in mind that the changes required to support *PoW reflection* are unlikely to ever be integrated with either Bitcoin or Ethereum (and reaching social agreement about the details would be difficult, to say the least).

Our starting case is that both chains use different Proof of Work algorithms and neither tracks the other. For simplicity, the following progression will use two blockchains with identical block times, and will not account for variance in block production.

#### Step 1. Chain E tracks Chain B

This is conceptually similar to Ethereum tracking Bitcoin, and shown in \autoref{fig:pow_refl_step1}.

\begin{figure}
\centering
\includegraphics[height=0.28\textheight]{pow_refl_step1_sag}
\caption{Step 1: Chain B's headers are tracked by Chain E.}
\label{fig:pow_refl_step1}
\end{figure}

Similar to before, Chain E will include Chain B's headers as they are produced. Note that this can be a protocol-level implementation; it does not have to be at the smart contract level as it would be with Ethereum.

#### Step 2. Chain B tracks Chain E

Say that the protocol of Chain B is extended to add support for tracking Chain E's headers. That is, a bespoke protocol extension is created that allows/requires miners to publish known Chain E headers along with their Chain B block. Similar to the way Chain E tracks Chain B, now Chain B also tracks Chain E. This is shown in \autoref{fig:pow_refl_step2} and the following table.

| Time | B block made | B block contents | B state | E block made | E block contents | E state |
|---|---|---|---|---|---|---|
| ... |||||||
| 0 | k | $E_{j-1}$ header | Tracks E up to $E_{j-1}$ ||||
| 1 | ||| j | $B_{k}$ header | Tracks B chain up to $B_{k}$ |
| 2 | k + 1 | $E_{j}$ headers | Tracks E up to $E_{j}$ ||||
| 3 | ||| j + 1 | $B_{k+1}$ header | Tracks B up to $B_{k+1}$ |
| ... |||||||

\begin{figure}[H]
\centering
\includegraphics[height=0.3\textheight]{pow_refl_step2_sag}
\caption{Step 2: Chain B and Chain E track each other's header-only chain.}
\label{fig:pow_refl_step2}
\end{figure}

#### Step 3. B tracks E's tracking of B

Can we use a tracked chain for a different purpose? What happens if Chain B tracks whether Chain B's history is confirmed within Chain E?

| Time | B block made | B block contents | B state | E block made | E block contents | E state |
|---|---|---|---|---|---|---|
| ... |||||||
| 0 | k | $E_{j-1}$ header + Merkle proof of $B_{k-1}$ | Tracks Chain E up to $E_{j-1}$ *and* knows that Chain E knows of $B_{k-1}$ ||||
| 1 | ||| j | $B_{k}$ header | Tracks Chain B up to $B_{k}$ |
| 2 | k + 1 | $E_{j}$ header + Merkle proof of $B_{k}$ | Tracks Chain E up to $E_{j}$ *and* knows that E knows of $B_{k}$ ||||
| 3 | ||| j + 1 | $B_{k+1}$ header | Tracks B up to $B_{k+1}$ |
| ... |||||||

Chain B now knows *which B blocks are known about by some external source* (Chain E in this case).

\begin{figure}[H]
\centering
\includegraphics[height=0.3\textheight]{pow_refl_step3_sag}
\caption{Step 3: Chain B includes Proofs of Reflection (PoRs) along with headers. Proofs of Reflection allow Chain B to know which of its own blocks are known to Chain E.}
\label{fig:pow-refl-step3}
\end{figure}

Put another way: Chain B's history is confirmed *not only* by new Chain B blocks, *but also* by Chain E blocks. Since Chain B nodes *know* they have the blocks that Chain E knows about, there's no data-availability concern here.

**Important:** Soon, these confirmations will have real and useful meaning. Under the right conditions, an appropriate configuration of *PoW reflection* results in an increase in the *rate* that confirmations are acquired. This is the first hint of $\frac{1}{O(c)}$ confirmation time.

At this point, if an attacker was to publish an alternate, better Chain B history, then Chain B nodes would reorganize around the *new* history published by the attacker, and the attacker's block headers would end up being recorded in Chain E and causing a reorganization there, too. Currently, this configuration does not add any security to Chain B.

Could we use Chain B's knowledge *that it's own history is reflected in Chain E* to *prevent* such an attack?

#### Step 4. One Way Reflection

\todo{Replace refs to Bitcoin with Chain B and Ethereum with Chain E}

\todo{NOTE: I think it might be good to reorg this section a bit so that the current-btc stuff comes first, then we go into the modifications.}

Before we discuss a change that Chain B could make, it is important to note that chain-work done with one hashing algorithm is *not generally convertible* to 'equivalent' work done via another hashing algorithm. For example, there is no meaningful *generic* answer to the question "how many *double SHA256* hashes is one *Ethash* hash worth?". In fact, there is no meaningful answer to similar questions that use any other other combination of hashing algorithms, either. It is not possible to *generically and universally* convert between qualitatively different units[^et-conversion]. It is *only* to do this within some *context* where with a *defined* conversion method. We'll look at some such contexts later.

[^et-conversion]: The philosophical generalization of *qualitative conversion* and the *necessary* role that *goals* and *context* play is [Elliot Temple's](https://elliottemple.com) idea. It is covered in his [*Critical Fallibilism Course*](https://gumroad.com/l/mhtbA). It's also partially covered in (or related to) [Elliot's *Yes or No Philosophy* course](https://gumroad.com/l/hxqsh) and some of his articles, e.g., [*IGCs* ({Idea, Context, Goal} triples)](https://curi.us/2387-igcs) and [*Bottleneck Examples*](https://curi.us/2353-bottleneck-examples).

NB: Bitcoin does two SHA256 hashes per block, which is why I refer to "double SHA256" above.

For the purposes of our hypothetical construction, let's say that B and E do *equal work over equal time*. In the current example, that means that the work required to produce either $B_i$ or $E_j$ is the same. *For the sake of this construction, we'll also presume this relationship doesn't change over time*. Our constant of conversion is thus: 1 *E Blocks per B Block*.

NB: we're not that concerned with whether this is a reasonable assumption or not; right now, we just need a way to convert the work done on each chain into the same units. (Some methods for doing this will be discussed later.)

Currently, the Chain B network chooses the "heaviest" (most worked) chain as its common history. Chain B calculates the "weight" of blocks (i.e., how much work went in to them) via an estimation of how many hashes were required -- say these are measured in *double SHA256 hashes*. For the purposes of illustration, let's normalize this number to be in terms of *B Blocks* -- instead of *double SHA256 hashes*; that's easy, since each block is worth 1 *B Block* by definition. Now, we can also measure the work in *E Blocks*, too (that being: 1 *E Block*).

How can the network choose the heaviest chain? Well, a traditional blockchain might use a simple recursive function like this:

```haskell
-- chain-b-vanilla-weight-calc.hs
type BWeight = Number

chainWeight :: List Block -> BWeight
chainWeight [] = 0
chainWeight b:bs = blockWeight b + chainWeight bs
-- pattern match a list of blocks. The head is `b` and the rest
-- of the chain is `bs`. If the list is empty then return 0.

blockWeight :: Block -> BWeight
blockWeight block = 1
-- by definition; this is not representative of a production chain
```

Could Chain B incorporate the idea that Chain E had confirmed part of its history? Could Chain B use this to thwart some types of attack?

Let's modify the Chain B block-weight calculation functions so that they account for the Chain B history that has been confirmed by Chain E:

%%TC:ignore
```haskell
-- chain-b-modified-weight-calc.hs
type BWeight = Number
type EWeight = Number

weightConvConst = 1
bWToEWeight bW = bW * weightConvConst
eWToBWeight eW = eW / weightConvConst

chainWeight :: BState -> List Block -> BWeight
chainWeight _ [] = 0
chainWeight state b:bs = totalBlockWeight state b + chainWeight state bs

totalBlockWeight :: BState -> Block -> BWeight
totalBlockWeight state block = blockWeight block +
    if chainEHasConfirmed state block
        then eWToBWeight (eWorkFor state block)
        else 0

chainEHasConfirmed :: BState -> Block -> Boolean
chainEHasConfirmed state block =
    doesEHaveBlock state block &&
    isBlockInMainChainAccordingToE state block

-- we won't define these functions as their names are illustrative enough
doesEHaveBlock _ _ = undefined
isBlockInMainChainAccordingToE _ _ = undefined

eWorkFor :: BState -> Block -> EWeight
eWorkFor state block = sum (map eBlockWeight relevantEBlocks)
  where
    -- a `filter` like this is inefficient but illustrative enough
    relevantEBlocks = filter currBlockIsHead (eMainChainBlocks state)
    currBlockIsHead eBlock = hash block == getBHeadFromEBlock eBlock

blockWeight :: Block -> BWeight
blockWeight block = 1

eBlockWeight :: EBlock -> EWeight
eBlockWeight eBlock = 1
-- -- alternatively:
-- eBlockWeight eBlock = 1 / (countBChainHeads eBlock)
-- -- this would go some way for accounting for multiple Chain B heads
-- -- without giving either Chain B head an advantage.
```
%%TC:endignore

\todo{formalize the above mathematically so it can be more easily analyzed}

\begin{equation}
a = 1
\end{equation}

What is the meaning and impact of this change?

The *meaning* of this change is that Chain B now incorporates work done on Chain E *into Chain B's own calculation of the heaviest worked chain*.

When a chain does this we say *Chain B (or Chain B's work) is **reflected** in Chain E*. This technique is what is meant by the term *PoW reflection*.

One particular *impact* of this change is that a doublespend attack (e.g. by withholding a privately mined chain that reverts a transaction) must now be performed *not only* against Chain B, *but also and simultaneously* against Chain E.

Why? The privately mined blocks to perform the attack *are not known about* by Chain E. Rather, Chain E knows about the *public* Chain B history *against which the attack competes*. Thus, *either*:

* the private chain-segment must contribute more total work to the Chain B blockchain than the public chain-segment does -- *including* the relevant Chain E chain-segment; *or*
* the attacker must *additionally* produce a private Chain E chain-segment such that the *total* work of both private chain-segments is greater than the total work of both public chain-segments, and publish both chain-segments simultaneously.

It's worth noting that, at this point, there is no benefit to Chain E's security. That's because Chain E isn't 'reading' the reflected work back from Chain B. Thus a doublespend attack against Chain E has the expected, non-reflected profile -- it isn't more difficult to attack Chain E yet. However, Chain E can take advantage of the reflection, though. The main requirements are: the inclusion of appropriate merkle proofs that show known Chain E blocks according to Chain B, and an update to Chain E's block-weight calculations to account for the reflected work. PoW reflection doesn't automatically secure both chains; each chain can proactively and independently take advantage of PoW reflection.

Naturally, if there were a large difference in target block frequencies (e.g., 10 minutes vs 15 seconds) then there would also be a good deal of latency before a chain gains the security benefit from reflected work. For this reason, PoW reflection makes the most sense when used with high frequency chains, or chains of similar frequencies. One downside of this is that shortening the block production frequency requires the inclusion of more block headers. In the scheme of things, this can be somewhat significant but is not a deal-breaker.

Practical methods of comparing (and converting the weight of) different Proofs of Work are discussed in \autoref{sec:comparing-diff-pows}.

\todo{What if you mine a longer B-chain and then publish it to Chain E? Well you have to do that later, and you need to publish the blocks, too. If Chain E just checks the work on that local chain, then it looks like the attacker's chain is longer. But the chain, as calculated by full nodes is, not worth as much as the original chain, so they will keep mining on the orig chain. However, if the attacker has $q>p$ then they'll always outperform the honest chain and the reflections will eventually favour the attackers chain. so the reflecting chains (Chain E) need to incorporate calculations of the *total* block weight of Chain B. That means they need to be half-nodes for Chain B so that they can track Chain B's known reflections.}

#### Step 5. Mutual Reflection

\todo{Write out a bit about mutual reflection or move from elsewhere.}

\begin{figure}[H]
\centering
\includegraphics[height=0.35\textheight]{pow_refl_step4_sag}
\caption{\textit{PoW Reflection} between two UT Chains}
\label{fig:pow-refl-step4}
\end{figure}

### PoW reflection between chains using the same alg

tl;dr it can work fine I think. Like it's still secure; there's nothing about PoW reflection that *requires* more than one hashing alg, it's just the easier context to explain it in b/c miners of one chain can't attack the other.

\todo{tidy this section, provide explanation.}

\begin{comment}

\todo{build this section out -- seems like this can be done securely. nb: the rest of this subsection are just notes; probs just skip over them}

What about chains using the same alg? e.g. Bitcoin (B) and Bitcoin-copy (C)?

- opportunity cost exists for a miner choosing to mine B or C.
- they can switch, tho.
- can we get a situation where attacking one is as difficult as attacking both?
- normal reflection works????? mb
- if so, mb we don't merge mine at all.
- requires *constant* mining tho (on all chains). like doesn't work if ppl only mine a chain sometimes (bc an attacker can come in with no competition)
- chains mb can be DOSd? reflection can make this harder b/c honest blocks can build on DOS blocks -- if they're not private (i.e., they're available).
- but an attacker still need some profit driven reason, otherwise they're losing money by mining an attack; doublespends provide an out for that.
- would a pseudo merge mining (PMM) scheme work if the diff of merged multi-blocks is the sum of the diffs? like mining for B and C is as difficult as mining a block on B then mining a block on C. Call these special combined blocks *dual-chain-blocks*.
- that way there's opportunity cost but also there's a reason to do PMM: efficiency (don't need to swap between multiple chains, can reduce variance, etc)
- plus you could auto-reflect I think b/c the blocks will always be valid on both (and if not it's as difficult as as mining one valid block and one invalid one)
- for such dual-chain-blocks, could the proof attached be worth more than ratio of difficulty of mining on the two chains. IDK, i think each chain can probs still count only their difficulty, not diff for both chains. otherwise might open door to censorship/DOS attacks.

is this secure? if so, then mixing with reflection to other chains provides extra security as expected?

under that sort of thing the 'microchain' would become like an O(c) record of all headers from all chains. then all chains would sync their reflections up against the full headers-only-network (i.e., all chain headers of all chains). each dapp can then be O(c). so we get back to O(c^2) scaling.

\end{comment}

### Comparing Incomparable Proofs of Work

\label{sec:comparing-diff-pows}

For PoW reflection to work effectively, there must be some method of comparing and converting the *work* done by reflecting chains. Earlier, we simply *set* a ratio between Bitcoin blocks and Ethereum blocks based on the arbitrary notion of *equal work in equal time*, but that isn't a context that's easy to create and maintain in reality.

How can we design a system that allows for sensible comparisons between Proofs of Work that use different hashing algorithms?

#### A Single Root Token Across Multiple Chains

*Root Token*: The sole network-level token required by typical blockchain protocols. e.g. Bitcoin has BTC, Ethereum has ETH, Polkadot has DOT, Cardano has ADA, etc.

The simplest method for comparing work done via different algorithms is to measure that work via a common unit. How can we do this? Whatever method we choose, it must *cancel out* market conditions like: silicon availability, the cost of power, the availability of mining rigs, and short-term effects like a drastic shift in token price.

In blockchains like Bitcoin and Ethereum, block rewards are denominated in the *root token* of that chain. What if we had two chains with the same root token?

If two PoW blockchains using different hashing algorithms use the same root token, then we can directly compare the rates of work done on each via the normalized block rewards of the root token on each (normalized against time). What do I mean by this? Let's look at an example.

Say we had Altcoin1 and Altcoin2: two near-identical PoW chains using different algorithms, but with the *same* root token (conserved via a 2-way peg or w/e). Firstly, we need a way to determine what their block rewards are, and the intuitive solution is to set each chain's block reward proportionally to the percentage of root tokens (i.e., *coins*) on that chain. If one of them has 100% of the root tokens, then 50 coins are generated as a reward per block. If one had 60% of the root tokens, then 30 coins are generated per block *on that chain*, and (since we only have 2 chains) 20 coins are generated per block *for the other chain*, corresponding to the remaining 40% of root tokens. One reason this method makes sense is that the ratio of coins on each chain is not affected by block rewards -- though this property only holds (as I've put it here) if both chains have the same rate of block production. We can generalize the method by normalizing against time so that we're comparing the rates of coin production rather than the block rewards themselves.

Now that we know what the block rewards are and have defined them in terms of the percentage of total coins that are on that chain, we can work on comparing the chains' hash rates. What sort of foundation could we do this from? What about *equal work for equal reward*? Because we have defined block rewards in terms of *where* root tokens are held, we can measure things like *hashes per token* (when considering block rewards particularly). Crucially, we can measure this *for each chain*, which allows us to -- *contextually* -- make claims like 100 hashes of algorithm 1 are worth 25 hashes of algorithm 2.

Since we know the percentage of root tokens on each chain for each moment in history, we can safely use that figure in chain-weight calculations. The reliability of that data will be the same as the reliability of the blockchains themselves, provided we enforce the 2-way peg that ensures no root tokens are created or destroyed outside protocol rules.

\todo{should we bother deriving the maths for this here? IMO it's not that important to include in the paper provided the core idea is. Just some basic algebra and calculus.}

#### Different Root Tokens with a DEX

Instead of using the same token on multiple chains, you could use a similar method with different root tokens on different chains. Implicit in above single-token method was a 1:1 conversion ratio between root tokens held on each chain. Can we not replace that with an exchange rate? If that exchange rate was provided via a trustless and decentralized exchange, could that not also be a reasonable context to do this sort of conversion?

In principle you can use the same principles to compare work between chains that have different root tokens. However, there is a major new caveat with this method: the DEX and price-finding methods now become *part* of the consensus methods of those chains. This caveat makes the different-tokens context much harder to reason about, and introduces questions like *What is the effect of front running?* and *Could an attacker exploit market conditions to perform a doublespend when they wouldn't normally be able to?*

In the context of *Ultra Terminum* and *Amaroo*, these aren't questions that are important to answer. If PoW reflection is ever used to secure multiple chains with heterogenous tokens, it's likely that these questions will need answering, or that alternate methods be devised.

### Reflection with PoS chains / otherwise unsafe consensus algs (like PoA)

- helps solve *nothing at stake* problem b/c history is committed to thermodynamically (b/c of reflection in PoW chains), even with internal-based-stake (i.e., ROO); slashing can happen on like a 'watchdog' chain to ensure bad actors can't get away with it
- provides easy way for corps to run darkchains for whatever they want (tho *how* exactly you do the dark bit is ??) -- nb: doesn't make sense to do them as simplex-chains, they can just be dapp chains.
- "anyone" can make a little PoS chain to add to security
- PoS chains could like safely provide mb up to 50% of security? this would mean a 50% reduction in energy usage (not that a reduction of that complexity matters -> energy usage still of same complexity, i.e., O(n))
  - mb just 33% security
- how to balance PoW rewards with PoS? if staking is just 'free money' then why would ppl mine? possible options: lower reward, burning coins is required, other?
- would deffo need a deposit for PoS chains, still. can't start a chain from nothing, need some cost (or opportunity cost at least)
- could build on parity/ethereum/polkadot/etc clients. Cardano too if Ouroboros isn't garbage.
  - probs best to just use these as dappchains

### New block-weight algorithms

\label{s:counting-reflected-work}

\todo{brainstorm and progress this}

From forum last night:

> Here's the way we can think about the block weighting algorithm:
>
> Miners want to include reflection block headers b/c it helps them achieve the goal "be part of the longest chain" which is an intermediate goal to "get block rewards" -- b/c the protocol must demand it. So whatever block weighting algorithm we go with, a constraint (mb the starting point, mb not) needs to be something like:
>
>> contributing to reflections (including other chains' block headers in your blocks + proofs of state) is instrumental to producing blocks that become part of the main chain.
>
> This gives us a good yes/no quality that a block weighting algorithm *must* have. We can add some additional stuff that might help conjecture good weighting algorithms, too.
>
> meta comment: next step is to brainstorm algorithms (which is a step in the current WP plan I think)
>
> note: b/c block headers are like ~everywhere, and proving the most up-to-date reflection on a foreign chain is basically going to be a block header + merkle branch, there should be some significant engineering efficiencies we can make there -- so that, like, we don't need to send the proofs *and* the headers, we only need to send a small part, or maybe something in O(1) (like a bloom filter?).

----

> mb an insight: as a miner, contributing other block headers doesn't make *your* block "more confirmed" or something. But it does help confirm *prior* blocks, which means that *by adding foreign block headers your block is built on a "more worked" chain, b/c you're providing the evidence of that work!*
>
> Is that enough incentive? IDK, but one alternative is to like give them a boost to the "work" in that block (e.g. 10% of the work in the headers they include). that feels arbitrary and unprincipled, tho.

----

> note for scaling calcs/algebra: what happens if we include the overhead of merkle proofs along with the other headers? Does that like break everything? surely we can't calc all the permutations of likely header combos to find a matching merkle root... that sounds like a lot of work with e.g. 1000 reflected chains. easy with 2 or 3 chains tho.

----

>> what happens if we include the overhead of merkle proofs along with the other headers?
>
> that overhead is approx log(n_reflected_chains) for *each header* btw, that sort of thing might not be catastrophic, but it'd be a weird governor-esq anti-scaling overhead; like potentially `n*log(n)` for header sizes, i.e., something like:
>
> `constant + n_simplex_chains * log2(n_simplex_chains)`

----

>> that sort of thing might not be catastrophic, but it'd be a weird governor-esq anti-scaling overhead
>
> I added some worst case sorta numbers to the WP. the "500, 500" and "500, 700" below represent log2(4096)*32 byte increases to the header size (i.e., something like 384 bytes added to headers of a base size 112 bytes and 250 bytes)
>
> | (3000, 1/60, 1/60, 500, 500, 250) | 12 | 4,320 | 388,800 | $1.4\times 10^{8}$ |
> | (3000, 1/60, 1/60, 500, 700, 250) | 12 | 3,086 | 277,714 | $7.1\times 10^{7}$ |
>
> So yeah, it's not catastrophic; our TPS would still be above 100k and with O(c^4) scaling it's still approx 10^8.
>
> One thing that might come in to play is the basic idea I have to ensure block availability: download and store every block for 24hrs. That's O(c^2) bandwidth but c is relative to like 3 kb/s, so O(c^2) bandwidth isn't a show-stopper here (at least atm, todo: calc limits)

\todo{calc limits}

> If all miners have all simplex blocks in the last 24hrs *anyway*, then they can construct the proofs themselves. That might mean there's a way to avoid transmitting the proof + still be able to verify it. sort of like segwit does: throw away the data that's useless after it's been verified b/c the miner already had that anyway. In Bitcoin's case, that's the tx signatures; in UT's case, it's the block header proof-of-inclusion merkle branches.
>
> aside: does segwit mean that like a persistent, long term 51% attack can steal funds? b/c witnesses aren't included anymore?

----

> another **todo**: how are confirmation times affected by the simplex? IMO other chains confirming a particular chain's block counts for something in terms of the idea of "confirmation".
>
> confirmation is typically calculated via the probability (or ability) that an attacker can reverse a transaction. it's a measure of *assurance*, as such.
>
> how does UT play in to this? well, more reflection => harder for an attacker to reverse. Consider the parameters of an attacker having specific resources (e.g. a bunch of sha256 ASICs -- which is of a contiguous and homogeneous quality that past analysis has alluded to, tho it's abstracted via maths that presumes that); we can thwart most of those. But if we take an "optimistic" (for the attacker) look at an attacker with O(n) resources, then we're in worst-case-ville and I think UT might degrade to, *at worst*, the best lower-bound (i.e., best of all the worst-case situations) of other blockchains. Note to self: Need to write more on this to figure it out.

\todo{how are confirmation times affected by the simplex?}

### Recursive Reflection

\todo{not sure if this should be included. if so then need to write out this section}

Say chain B reflects both A and C. $A <-> B <-> C$. PoW reflection says A gets a benefit by proving that B reflects specific work from A. Does A get a security benefit by proving that C reflects B reflects A?

### Equivalency of Reflecting and Non-Reflecting Block-Weightings

\label{sec:equiv-state-block-weightings}

\todo{show that the result under PoW reflection is backwards compatible, i.e., existing consensus methods will settle on the same result. Needs to work for DAGs, too.}

##### Notes:

I think this should pan out b/c miners build on the longest chain. So if, at some time $t$, there's a disagreement between block-weighting methods, then miners will choose the reflection weighting. That should mean that a few blocks later (e.g., at $t+5$) the 'problematic' section of the chain is now re-orgd so that the methods agree again.

note: I think this *must* hold for double-spend mitigation stuff to work out.

An alternative plan, if the above doesn't work out, is for the header to include its corresponding block-weighting that accounts for reflections. That would allow a full-node doing an initial sync to reproduce the block-ordering that accounts for reflections, even though it isn't verifying those reflections (similar to SegWit).

### Effect on Confirmation Speed

The idea of *confirmation* is a representation of the risk that a transaction will fail to become finalized within a blockchain network; as a transaction receives more *confirmations*, the probability that a doublespend attempt succeeds approaches 0. A transaction is said to have been *confirmed* once it has enough confirmations to pass a *breakpoint*, beyond which the probability of an attack succeeding is close (enough) to 0.

Let us say that some chain, $C_1$, is reflected by another chain, $C_2$. Since we have two chains, we will also say that $N = 2$. For simplicity, let us assume that these two chains have equal hash power and use the same hash function for the PoW -- this means the attacker can mine either chain. Let us also denote the probability of an attack succeeding on some chain, $C_i$, via the function $P_{C_i}(q_i)$, where $q_i$ is the proportion of computational power that the attacker controls.

\todo{write out these paragraphs properly and make maths more formal}

\mk{
  NTS: For the case of ${C_1, C_2}$, it's clear that if $q_1 > 0.5$ and $q_2 > 0.5$ then the attacker should be able to perform arbitrary doublespends. This is equivalent to doing a 51% attack on both $C_1$ and $C_2$ simultaneously.
}

What if $q_1 > 0.5$ and $q_2 < 0.5$?

\mk{
  NTS: attacker dominates if $q_1 + q_2 > 1$, or more generally:

  \begin{equation}
  \sum_{i = i}^{N} q_i > \frac{N}{2}
  \end{equation}
}

What if $q_1 < 0.5$ and $q_2 < 0.5$?

\mk{NST: If the attacker is withholding then there are two races: one on $C_1$ and one on $C_2$. to secretly do a doublespend then the attacker must win both races and publish both chain-segments simultaneously, causing a simultaneous reorg on both chains.}

\todo{finish this section}

\todo{what are the dynamics of winning one race but not both? say they won $C_1$, they'd publish both but then someone else building on $C_1$ would add all the real headers from $C_2$ that don't include the reflections, which *after the fact* would diminish the chain-weight of $C_1$, but then with new $C_2$ blocks would reflect the new $C_1$ chain-segment. Todo: how does this interact with block-weighting calculation? need to do some simulations I think. Also todo: should miners like take into account new reflected work in their draft blocks? if so does that mean they'd still favor the old (honest) chain segment? probs need to formalize the chain-weighting alg so that it can be analyzed easily}

\mk{
  NTS: for cases where multiple races need to be won, the probability of success will be like

\begin{equation}
\prod_{i=1}^{N} P_{C_i}(q_i)
\end{equation}

Which becomes vanishingly small much faster than for a single chain. There's a breakpoint around winning the race, sorta. The attacker does get some bonus from winning by a larger margin, but winning the race is still important.
}

### The Previous Block-Weighting Function

\todo{exploratory notes}

Let: $T$ be the target for the verification function; $T_{\text{max}}$ be the maximum meaningful target (e.g., $2^{256}$); $h$ be the hash digest as a number.

If $T > h$ (the success criterion) then $T - h > 0$. $P(x); x \neq 0$ is a function which returns 1 if $x$ is positive, and 0 otherwise.

\begin{equation}
\begin{split}
P(x) & = \frac{\sqrt{x^2}}{2x} + \frac{1}{2} \\
W_{\text{block},1}(T, h) & = P(T - h) \cdot \frac{T_{\text{max}}}{T}
\end{split}
\end{equation}

This function, $W_{\text{block},1}$ will return the weight of a block in terms of the expected number of hashes needed to generate the proof of work. This function is useful because it is able to compare blocks between chain forks, even if the difficulty is different on each fork. That is to say: this weighting-function is meaningful over long periods of time; it works both instantaneously and long-term.

### Block-Weighting w/ Conversion

\todo{exploratory notes}

In order to convert between different hashes (or even the same hash function on different blockchains) we need a method, and the best method discussed above is to normalize against the distribution of some common root-token (provided the inflation rate, mining rewards, etc are all of the same profile). The root-token's distribution will change over time, but is essentially constant over the period of a few blocks.

Our goal is to convert some other block's work into something comparable to $W_{\text{block},1}$.

ROO/s is generated on each chain ~proportionally to the ratio, $r_j$, of local-ROO to global-ROO. Each chain will (dependant on the hash function) have some attempts/s (hashrate) that is implicitly measured via the target value. Attempts/block is given by $\frac{T_{\text{max}}}{T_j}$, so attempts/s is given by $\frac{T_{\text{max}}}{T_j} \cdot B_{f,j}$, where $B_{f,j}$ is the block frequency measured in hertz ($s^{-1}$). The generated ROO/s is proportional to attempts/s over small time scales, i.e., there is some scaling constant. Over longer periods of time, the generated ROO/s is related to attempts/s, but not necessarily via a constant.

A miner's attempts/s is proportional to their expected reward-rate over small time scales. For the chain as a whole, this is demonstrated by: expected attempts per block is proportional to the block reward, i.e., the product of expected attempts per block and some constant, $Z$, measured in ROO/attempt equals the block reward. For example: given some chain $j$ with $A_j$ expected attempts per block, and $B_{R,j}$ block reward; $A_j \cdot Z_j = B_{R,j}$. Since attempts per block is given by $\frac{T_{\text{max}}}{T_j}$, we can say $\frac{T_{\text{max}}}{T_j} \cdot Z = B_R$. Additionally, $B_R$ is proportional to $r$; i.e., $B_{R,j} = r_j \cdot B_{R,\text{global}}$. Thus $\frac{T_{\text{max}}}{T_j} \cdot Z_j = r_j \cdot B_{R,\text{global}}$.

\begin{equation}
\frac{T_{\text{max}}}{T_j} \cdot \frac{Z_j}{r_j} = B_{R,\text{global}}
\end{equation}

Thus, given two chains, $j$ and $k$:

\begin{equation}
\begin{split}
\frac{T_{\text{max}} Z_j}{T_j r_j} & = \frac{T_{\text{max}} Z_k}{T_k r_k} \\
\frac{T_k}{T_j} & = \frac{Z_k r_j}{Z_j r_k}
\end{split}
\end{equation}


\mk{
  nb: I need to consider that the history that the miner builds on increases with time (b/c reflections start accumulating, and once that miner publishes a block, then that block will have sigma-weight more than just its own weight). so the place to look isn't what a block weighs, it's to look at what a block is building on -- how much does that weigh.
}


\begin{equation}
r_1 = Z_1 \cdot \frac{T_{\text{max}}}{T_1} \cdot B_{f,1}
\end{equation}
