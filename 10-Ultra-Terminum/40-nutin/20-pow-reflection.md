## PoW reflection

**note: reminder about secrecy and patent-ability, this is part of it**

Can blockchains work cooperatively to secure each other? It certainly seems that there is nothing *in principle* that prohibits this. Can we come up with a way to do this?

The idea of one blockchain 'tracking' another blockchain via chain-headers and SPV proofs is not new: I (loosely) proposed a system which used this method to support rich cross-chain exchange in 2013[^xc1]. I wrote a simplified implementation in the very early days of Ethereum[^xc3], a precursor to the later-successful BTCRelay[^xc4]. The general idea of one blockchain tracking the headers of another will be our starting point.

[^xc1]: <https://bitcointalk.org/index.php?topic=198032.0>, <https://bitcointalk.org/index.php?topic=598784.0>
[^xc3]: <https://github.com/XertroV/coppr/blob/master/chainheaders.py>
[^xc4]: <https://github.com/ethereum/btcrelay>

### Two Blockchains

Let's build up the idea via a hypothetical situation with two distinct blockchains. For simplicity, let's use Bitcoin and Ethereum 1.

Our starting case is that both chains use different Proof of Work algorithms and neither tracks the other.

#### Step 1. Ethereum tracks Bitcoin

The idea that Ethereum SCs can track Bitcoin chain-headers is well understood. Bitcoin's proof of work algorithm is clean and simple so implementing the necessary logic in an Ethereum SC is not that difficult. In principle, any chain that supports some headers-only mode can be tracked in this way. In practice that can be difficult (e.g. Ethereum's EVM doesn't support memory hard hashes unless special cases are introduced), but we're not interested in practicality *at the moment*.

Let's add such a contract to Ethereum and describe the relevant data and events:

| Time (~15s increments) | Bitcoin block made | Eth block made | Eth block contents | Eth state |
|---|---|---|---|---|
| ... |||||
| 0 | k ||||
| 1 | | j | $BTC_k$ header | Tracks BTC chain up to $BTC_k$ |
| ... |||||
| 40 | k + 1 ||||
| 41 | | j + 40 | $BTC_{k+1}$ header | Tracks BTC chain up to $BTC_{k+1}$ |
| ... |||||

After a Bitcoin block is produced, an Ethereum miner includes an Eth tx containing the BTC header, which updates the SC tracking the Bitcoin chain. In reality there are practical concerns about incenting someone to produce such a transaction (among other things); we're not concerned with those here. We're just concerned with the relationships that exist and what they can do.

#### Step 2. Bitcoin tracks Ethereum

Let's consider a hypothetical change to Bitcoin. The protocol is extended to add support for tracking Ethereum's chain-headers. That is, a bespoke protocol extension is created that allows/requires miners to publish known Ethereum chain-headers along with their Bitcoin block. Similar to the way Ethereum tracks Bitcoin, now Bitcoin also tracks Ethereum.

\todo[inline]{[ANYONE] Update "Eth[j]" syntax to match $BTC_k$ syntax used in prev table.}

| Time (~15s increments) | Bitcoin block made | BTC block contents | BTC state | Eth block made | Eth block contents | Eth state |
|---|---|---|---|---|---|---|
| ... |||||||
| 0 | k | Eth[j-40:j-1] headers | Tracks Eth chain up to Eth[j-1] ||||
| 1 | ||| j | BTC[k] header | Tracks BTC chain up to BTC[k] |
| ... |||||||
| 40 | k + 1 | Eth[j:j+39] headers | Tracks Eth chain up to Eth[j+39] ||||
| 41 | ||| j + 40 | BTC[k+1] header | Tracks BTC chain up to BTC[k+1] |
| ... |||||||

Why would a chain want to track another chain? The typical answer is to prove transactions or state occurred on the foreign chain. On Ethereum one could build a trustless BTC<->Ether market, for example.

#### Step 3. Bitcoin tracks Ethereum tracking Bitcoin

Can we use a tracked chain for a different purpose? What happens if the Bitcoin chain tracks whether Bitcoin history is confirmed within the Ethereum SC?

| Time (~15s increments) | Bitcoin block made | BTC block contents | BTC state | Eth block made | Eth block contents | Eth state |
|---|---|---|---|---|---|---|
| ... |||||||
| 0 | k | Eth[j-40:j-1] headers + Merkle proof of BTC[k-1] | Tracks Eth chain up to Eth[j-1] *and* knows that Eth knows of BTC[k-1] ||||
| 1 | ||| j | BTC[k] header | Tracks BTC chain up to BTC[k] |
| ... |||||||
| 40 | k + 1 | Eth[j:j+39] headers + Merkle proof of BTC[k] | Tracks Eth chain up to Eth[j+39] *and* knows that Eth knows of BTC[k] ||||
| 41 | ||| j + 40 | BTC[k+1] header | Tracks BTC chain up to BTC[k+1] |
| ... |||||||

Bitcoin now knows *which Bitcoin blocks are known about by some external source* (Ethereum in this case).

Put another way: Bitcoin's history is confirmed *not only* by new Bitcoin blocks, *but also* by Ethereum blocks. Since Bitcoin nodes *know* they have the blocks that Ethereum knows about, there's no data-availability concern here.

At this point, if an attacker was to publish a better Bitcoin chain, then Bitcoin nodes would reorganize around the *new* history published by the attacker, and the attacker's block headers would end up being recorded in the Ethereum SC (so the SC would reorganize just as Bitcoin nodes do).

Could we use Bitcoin's knowledge *that it's own history is reflected in the Ethereum SC* to *prevent* such an attack?

#### Step 4. A modification to Bitcoin's *block-weight* calculation

NOTE: I think it might be good to reorg this section a bit so that the current-btc stuff comes first, then we go into the modifications. TODO

Before we discuss a change that Bitcoin could make, it is important to note that chain-work done with one hashing algorithm is *not generally convertible* to 'equivalent' work done via another hashing algorithm. There is no meaningful *generic* answer to the question "how many *double SHA256* hashes is one *Ethash* hash worth?". In fact there is no meaningful answer to similar questions that use any other other combination of hashing algorithms, either. It is not possible to *generically and universally* convert between qualitatively different units. You can *only* do this within some *context* where you *define* a conversion method. We'll look at some such contexts later.

NB: Bitcoin does two SHA256 hashes per block, which is why I refer to "double SHA256" above.

* [The Order of Things](https://www.newyorker.com/magazine/2011/02/14/the-order-of-things) ([unpaywalled-mirror](https://outline.com/8gMRNR))
* https://curi.us/2353-bottleneck-examples - explanation of above under "College Rankings"
* yes/no and CF course (can't remember specifics)
* Goldratt's *The Choice* (is a cucumber longer than it is green?)

For the purposes of our hypothetical construction, let's say that the Bitcoin chain and Ethereum chain do *equal work over equal time*. That is: the work required to mine 1 Bitcoin block, which happens approx every 10 minutes, is equal to the work done on the Ethereum chain over the same time period (10 minutes), which is approximately 40 Ethereum blocks (with a target time of 15 seconds). So: 1 Bitcoin confirmation is worth approx 40 Ethereum confirmations. *For the sake of this construction, we'll also presume this relationship doesn't change over time*. Our constant of conversion is thus: `40` and the unit is `EthBlocks / BtcBlock`.

NB: we're not that concerned with whether this is a reasonable assumption or not, we just need a way to convert the work done on each chain into the same units. (Some methods for doing this will be discussed later.)

Currently, the Bitcoin network chooses the "heaviest" (most worked) chain as its common history. Bitcoin calculates the "weight" of blocks (i.e. how much work went in to them) via an estimation of how many hashes were required -- measured in `double SHA256 hashes`. Let's normalize this number so that we're working in terms of `BtcBlocks` instead of `double SHA256 hashes`; that's pretty easy, since each block is worth `1 BtcBlock` by definition. Now, we can also measure the work in `EthBlocks`, too (that being: `40 EthBlocks`).

How can the network choose the heaviest chain? Well, here is a simple recursive function to do just that:

```haskell
-- bitcoin-vanilla-weight-calc.hs
type BtcWeight = Number

chainWeight :: List Block -> BtcWeight
chainWeight [] = 0
chainWeight b:bs = blockWeight b + chainWeight bs
-- pattern match against a block (b) and the rest of the chain (bs), or return 0.

blockWeight :: Block -> BtcWeight
blockWeight block = 1
-- we set the weight to 1 earlier; this is not representative of a production chain
```

Could the Bitcoin chain incorporate the idea that Ethereum had confirmed part of its history? (Ideally the Ethereum chain would know about all but the latest block, but, in reality, there might be some latency.) Could the Bitcoin chain use this to thwart some types of attack?

Let's modify the Bitcoin weight-calculation functions so that they account for Bitcoin history that has been confirmed by the Ethereum chain:

```haskell
-- bitcoin-modified-weight-calc.hs
type BtcWeight = Number
type EthWeight = Number

btcWToEthW btcW = btcW * 40
ethWToBtcW ethW = ethW / 40

chainWeight :: BtcState -> List Block -> BtcWeight
chainWeight _ [] = 0
chainWeight state b:bs = totalBlockWeight state b + chainWeight state bs

totalBlockWeight :: BtcState -> Block -> BtcWeight
totalBlockWeight state block = blockWeight block +
    if ethHasConfirmed state block
        then ethWToBtcW (ethWorkFor state block)
        else 0

ethHasConfirmed :: BtcState -> Block -> Boolean
ethHasConfirmed state block =
    doesEthHaveBlock state block &&
    isBlockInMainChainAccordingToEth state block

-- we won't define these functions as their names are illustrative enough
doesEthHaveBlock _ _ = undefined
isBlockInMainChainAccordingToEth _ _ = undefined

ethWorkFor :: BtcState -> Block -> EthWeight
ethWorkFor state block = sum $ ethBlockWeight <$> relevantEthBlocks
  where
    -- a `filter` like this is inefficient but illustrative enough
    relevantEthBlocks = filter currBlockIsHead (ethMainChainBlocks state)
    currBlockIsHead ethBlock = btcHash block == getBtcHeadFromEthBlock ethBlock

blockWeight :: Block -> BtcWeight
blockWeight block = 1

ethBlockWeight :: EthBlock -> EthWeight
ethBlockWeight ethBlock = 1
-- -- alternatively:
-- ethBlockWeight ethBlock = 1 / (countBtcChainHeads ethBlock)
-- -- this would go some way for accounting for multiple Bitcoin heads
-- -- without giving either Bitcoin head an advantage.
```

What is the meaning and impact of this change?

The *meaning* of this change is that Bitcoin now incorporates work done on the Ethereum chain *into Bitcoin's own calculation of the heaviest worked chain*.

When a chain does this we say *Bitcoin (or Bitcoin's work) is **reflected** in Ethereum (or in the Ethereum chain)*. This technique is what is meant by the term *PoW reflection*.

One particular *impact* of this change is that a doublespend attack (e.g. by withholding a privately mined chain that reverts a transaction) must now be performed *not only* against Bitcoin, *but also and simultaneously* against Ethereum.

Why? The privately mined blocks to perform the attack *are not known about* by Ethereum. Rather, Ethereum knows about the *public* Bitcoin history *against which the attack competes*. Thus, the private chain-segment must *either* contribute more total work to the Bitcoin blockchain than the public chain-segment does *including* the relevant Ethereum chain-segment, *or* the attacker must, in addition to their private Bitcoin chain-segment, *also* produce a private Ethereum chain-segment such that the *total* work of both private chain-segments is calculated to be greater than the total work of both public chain-segments, and then publish both segments simultaneously.

It's worth noting that, at this point, there is no benefit to Ethereum's security as Ethereum isn't 'reading' the reflected work. Thus a doublespend attack against Ethereum has the expected, non-reflected profile. The only thing that is required for Ethereum to take advantage of the reflected PoW is the inclusion of appropriate merkle proofs which show the Ethereum chain according to Bitcoin.

Naturally, the large difference in target block frequencies means that Ethereum has a good deal of latency before its chain gains the security benefit from reflected work. For this reason, PoW reflection makes the most sense when used with high frequency chains, or chains of similar frequencies. One downside of this is that shortening the block production frequency requires the inclusion of more block headers, however, this is minimal in the scheme of things.

\todo[inline]{UT won't be done until we figure out how to tell what the right algorithm is to count/weigh reflected blocks.}

### PoW reflection between chains using the same alg

tl;dr it can work fine I think. Like it's still secure; there's nothing about PoW reflection that *requires* more than one hashing alg, it's just the easier context to explain it in b/c miners of one chain can't attack the other.

\todo[inline]{build this section out -- seems like this can be done securely. nb: the rest of this subsection are just notes; probs just skip over them}

What about chains using the same alg? e.g. Bitcoin (B) and Bitcoin-copy (C)?

- opportunity cost exists for a miner choosing to mine B or C.
- they can switch, tho.
- can we get a situation where attacking one is as difficult as attacking both?
- normal reflection works????? mb
- if so, mb we don't merge mine at all.
- requires *constant* mining tho (on all chains). like doesn't work if ppl only mine a chain sometimes (bc an attacker can come in with no competition)
- chains mb can be DOSd? reflection can make this harder b/c honest blocks can build on DOS blocks -- if they're not private (i.e. they're available).
- but an attacker still need some profit driven reason, otherwise they're losing money by mining an attack; doublespends provide an out for that.
- would a pseudo merge mining (PMM) scheme work if the diff of merged multi-blocks is the sum of the diffs? like mining for B and C is as difficult as mining a block on B then mining a block on C. Call these special combined blocks *dual-chain-blocks*.
- that way there's opportunity cost but also there's a reason to do PMM: efficiency (don't need to swap between multiple chains, can reduce variance, etc)
- plus you could auto-reflect I think b/c the blocks will always be valid on both (and if not it's as difficult as as mining one valid block and one invalid one)
- for such dual-chain-blocks, could the proof attached be worth more than ratio of difficulty of mining on the two chains. IDK, i think each chain can probs still count only their difficulty, not diff for both chains. otherwise might open door to censorship/DOS attacks.

is this secure? if so, then mixing with reflection to other chains provides extra security as expected?

under that sort of thing the 'microchain' would become like an O(c) record of all headers from all chains. then all chains would sync their reflections up against the full headers-only-network (i.e. all chain headers of all chains). each dapp can then be O(c). so we get back to O(c^2) scaling.

### Comparing incomparable Proofs of Work

For PoW reflection to work effectively, there must be some method of comparing the *work* done by reflecting chains. Earlier, we simply *set* a ratio between Bitcoin blocks and Ethereum blocks based on the arbitrary notion of *equal work in equal time*, but that isn't a context that's easy to create and maintain in reality.

How can we design a system that allows for sensible comparisons between Proofs of Work that use different hashing algorithms?

#### A Single Root Token Across Multiple Chains

The simplest method for comparing work done via different algorithms is to measure that work via a common unit. How can we do this? Whatever method we choose, it must *cancel out* market conditions like: silicon availability, the cost of power, the availability of mining rigs, and short-term effects like a drastic shift in token price.

In blockchains like Bitcoin and Ethereum, block rewards are denominated in the *root token* of that chain. What if we had two chains with the same root token?

If two PoW blockchains using different hashing algorithms use the same root token, then we can directly compare the rates of work done on each via the normalized block rewards of the root token on each (normalized against time). What do I mean by this? Let's look at an example.

Say we had Altcoin1 and Altcoin2: two near-identical PoW chains using different algorithms, but with the *same* root token (conserved via a 2-way peg or w/e). Firstly, we need a way to determine what their block rewards are, and the intuitive solution is to set each chain's block reward proportionally to the percentage of root tokens (i.e. *coins*) on that chain. If one of them has 100% of the root tokens, then 50 coins are generated as a reward per block. If one had 60% of the root tokens, then 30 coins are generated per block *on that chain*, and (since we only have 2 chains) 20 coins are generated per block *for the other chain*, corresponding to the remaining 40% of root tokens. One reason this method makes sense is that the ratio of coins on each chain is not affected by block rewards -- though this property only holds (as I've put it here) if both chains have the same rate of block production. We can generalize the method by normalizing against time so that we're comparing the rates of coin production rather than the block rewards themselves.

Now that we know what the block rewards are and have defined them in terms of the percentage of total coins that are on that chain, we can work on comparing the chains' hash rates. What sort of foundation could we do this from? What about *equal work for equal reward*? Because we have defined block rewards in terms of *where* root tokens are held, we can measure things like *hashes per token* (when considering block rewards particularly). Crucially, we can measure this *for each chain*, which allows us to -- *contextually* -- make claims like 100 hashes of algorithm 1 are worth 25 hashes of algorithm 2.

Since we know the percentage of root tokens on each chain for each moment in history, we can safely use that figure in chain-weight calculations. The reliability of that data will be the same as the reliability of the blockchains themselves, provided we enforce the 2-way peg that ensures no root tokens are created or destroyed outside protocol rules.

\todo[inline]{should we bother deriving the maths for this here? IMO it's not that important to include in the paper provided the core idea is. Just some basic algebra and calculus.}

#### Different Root Tokens with a DEX

Instead of using the same token on multiple chains, you could use a similar method with different root tokens on different chains. Implicit in above single-token method was a 1:1 conversion ratio between root tokens held on each chain. Can we not replace that with an exchange rate? If that exchange rate was provided via a trustless and decentralized exchange, could that not also be a reasonable context to do this sort of conversion?

In principle you can use the same principles to compare work between chains that have different root tokens. However, there is a major new caveat with this method: the DEX and price-finding methods now become *part* of the consensus methods of those chains. This caveat makes the different-tokens context much harder to reason about, and introduces questions like *What is the effect of front running?* and *Could an attacker exploit market conditions to perform a doublespend when they wouldn't normally be able to?*

In the context of *Ultra Terminum* and *Amaroo*, these aren't questions that are important to answer. If PoW reflection is ever used to secure multiple chains with heterogenous tokens, it's likely that these questions will need answering, or that alternate methods be devised.

### Reflection with more than two blockchains

If we can do reflection between two chains, can we also do reflection between three chains?

guess: extending the Bitcoin + Ethereum example to, say, Bitcoin + Ethereum + Litecoin will provide the security benefits of all 3. it should be additive. a doublespend would require a doublespend against all 3.

### Reflection with PoS chains / otherwise unsafe consensus algs (like PoA)

- helps solve *nothing at stake* problem b/c history is committed to thermodynamically (b/c of reflection in PoW chains), even with internal-based-stake (i.e. ROO); slashing can happen on like a 'watchdog' chain to ensure bad actors can't get away with it
- provides easy way for corps to run darkchains for whatever they want (tho *how* exactly you do the dark bit is ??) -- nb: doesn't make sense to do them as simplex-chains, they can just be dapp chains.
- "anyone" can make a little PoS chain to add to security
- PoS chains could like safely provide mb up to 50% of security? this would mean a 50% reduction in energy usage (not that a reduction of that complexity matters -> energy usage still of same complexity, i.e. O(n))
  - mb just 33% security
- how to balance PoW rewards with PoS? if staking is just 'free money' then why would ppl mine? possible options: lower reward, burning coins is required, other?
- would deffo need a deposit for PoS chains, still. can't start a chain from nothing, need some cost (or opportunity cost at least)
- could build on parity/ethereum/polkadot/etc clients. Cardano too if Ouroboros isn't garbage.
  - probs best to just use these as dappchains

### ensuring availability of blocks corresponding to reflected headers

\todo[inline]{can we do better than getting miners to download all the relevant blocks?} they don't have to verify them, just make sure the data is available. e.g. they could download and share for 24hrs and then drop the blocks for the chains they don't care about.
