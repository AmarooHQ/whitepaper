### PoW reflection

**note: reminder about secrecy and patent-ability, this is part of it**

Can blockchains work cooperatively to secure each other? It certainly seems that there is nothing *in principle* that prohibits this. Can we come up with a way to do this?

The idea of one blockchain 'tracking' another blockchain via chain-headers and SPV proofs is not new: I (loosely) proposed a system to do this for the purposes of rich cross-chain exchange in 2013 (1,2). I wrote an implementation in the very early days of Ethereum (3), a precursor to the later-successful BTCRelay (4). The general idea of one blockchain tracking the headers of another will be our starting point.

* 1: https://bitcointalk.org/index.php?topic=198032.0
* 2: https://bitcointalk.org/index.php?topic=598784.0
* 3: https://github.com/XertroV/coppr/blob/master/chainheaders.py
* 4: https://github.com/ethereum/btcrelay

#### Two Blockchains

Let's build up the idea via a hypothetical situation with two distinct blockchains. For simplicity, let's use Bitcoin and Ethereum 1.

Our starting case is that both chains use different Proof of Work algorithms and neither track one another.

##### 1. Ethereum tracks Bitcoin

The idea that Ethereum SCs can track Bitcoin chain-headers is well understood. Bitcoin's proof of work algorithm is clean and simple so implementing the necessary logic in an Eth SC is not that difficult (3). In principle, any chain that supports some headers-only mode can be tracked in this way. In practice that can be difficult (e.g. Ethereum doesn't support memory hard hashes unless special cases are introduced), but we're not interested in practicality *at the moment*.

Let's add such a contract to Ethereum and describe the relevant data and events:

| Time (~15s increments) | Bitcoin block made | Eth block made | Eth block contents | Eth state |
|---|---|---|---|---|
| ... |||||
| 0 | k ||||
| 1 | | j | BTC[k] header | Tracks BTC chain up to BTC[k] |
| ... |||||
| 40 | k + 1 ||||
| 41 | | j + 40 | BTC [k+1] header | Tracks BTC chain up to BTC[k+1] |
| ... |||||

After a Bitcoin block is produced, an Ethereum miner includes an Eth tx containing the BTC header, which updates the SC tracking the Bitcoin chain. In reality there are practical concerns about incentivizing someone to produce such a transaction (among other things); we're not concerned with those here. We're just concerned with the relationships that exist and what they can do.

##### 2. Bitcoin tracks Ethereum

Let's consider a hypothetical change to Bitcoin. The protocol is extended to add support for tracking Ethereum's chainheaders. That is, a bespoke protocol extension is created that allows/requires miners to publish known Ethereum chainheaders along with their Bitcoin block. Similar to the way Ethereum tracks Bitcoin, now Bitcoin also tracks Ethereum.

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

##### 3. Bitcoin tracks Ethereum tracking Bitcoin

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

At this point, if an attacker was to publish a better Bitcoin chain, then Bitcoin nodes would reorganise around the *new* history published by the attacker, and the attacker's block headers would end up being recorded in the Ethereum SC (so the SC would reorganise just as Bitcoin nodes do).

Could we use Bitcoin's knowledge *that it's own history is reflected in the Ethereum SC* to *prevent* such an attack?

##### 4. A modification to Bitcoin's *block-weight* calculation

NOTE: I think it might be good to reorg this section a bit so that the current-btc stuff comes first, then we go into the modifications. TODO

Before we discuss a change that Bitcoin could make, it is important to note that chain-work done with one hashing algorithm is *not generally convertible* to 'equivalent' work done in another hashing algorithm. There is no meaningful *generic* answer to the question "how many *double SHA256* hashes is one *Ethash* hash worth?". In fact there is no meaningful answer to similar questions that use any other other combination of hashing algorithms, either. It is not possible to *generically and universally* convert between different units. You can *only* do this within a *context*. We'll look at some such contexts later.

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

Could the Bitcoin chain incorporate the idea that Ethereum had confirmed part of it's history? (Ideally the Ethereum chain would know about all but the latest block, but there might be some latency in reality.) Could the Bitcoin chain use this to thwart some types of attack?

Let's modify the Bitcoin weight-calculation functions to account for Bitcoin history that has been confirmed by the Ethereum chain:

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

It's worth noting that, at this point, there is no benefit to Ethereum's security as Ethereum isn't 'reading' the reflected work. Thus a doublespend attack against Ethereum has the expected, non-reflected parameters. The only thing required for Ethereum to take advantage of the reflected PoW is the inclusion of appropriate merkle proofs that show the Eth chain according to Bitcoin.

Naturally, the large difference in target block frequencies means that Ethereum has a good deal of latency before its chain gains the security benefit from reflected work. For this reason, PoW reflection makes the most sense when used with high frequency chains. The downside of this is the increased overhead of more block headers, however, this is minimal in the scheme of things.

\todo[inline]{UT won't be done until we figure out how to tell what the right algorithm is to count/weigh reflected blocks.}

#### Two *merge mined* blockchains

The case of two merged mined chains (e.g. Bitcoin and Namecoin) is not as simple as the case of two chains using different hashing algorithms for their work. That is because the conclusion drawn about the difficult of attack does not hold. If we consider two chains that are both reflected in one another and able to be merged mined, then it is trivial to see that an attack is, at most, as difficult as attacking the strongest chain (presuming that 100% of miners are mining that chain). So there is an upper limit on the additional security provided via this technique.

NB: It is possible that, given two merge mined chains, the sum of all work is greater than the work done on either chain; that is easier to see with a general method of merge mining as opposed to the method used for Namecoin. While it doesn't make much sense for a miner to *only* mine Namecoin and never attempt to produce Bitcoin blocks, it is possible that a miner could choose to do that. We won't spend much time focusing on this situation. In reality it's reasonable to expect that (or design a system such that) miners will always mine the heaviest chain. Miners will then selectively merge mine other chains, though they might not mine all possible chains.

However, that doesn't mean that PoW reflection isn't merited in these cases. For this next example, let us consider Bitcoin and Namecoin.

There is something that we should note before proceeding. Valid Namecoin proofs include the Bitcoin header, the merkle proof of the coinbase transaction, and the coinbase transaction itself. Although that Bitcoin header *might* have corresponded to a valid Bitcoin block, had the proof met Bitcoin's standards, we should expect that most of the time this is not the case. Namecoin does not automatically get access to a valid Bitcoin header-chain just because it is merged mined with Bitcoin. The current merge mining scheme requires that, for PoW to be reflected, Namecoin must explicitly include known Bitcoin headers as they are produced. Because of this, Namecoin blocks cannot implicitly contain the Bitcoin headers associated with that Namecoin block's proof since, much of the time, that Bitcoin header *will not* correspond to a valid Bitcoin block. We still have latency between these chains with Namecoin's current merge mining scheme.

**todo: can we get around this problem so we have like 0 latency? can we implicitly do this when the Bitcoin header in the Namecoin proof *is* valid?**

What would the effect for Namecoin be if all Namecoin block headers were confirmed on the Bitcoin chain (similar to what we investigated with Ethereum), and Namecoin was to track Bitcoin headers?

NB: since we presume, in this case, that all Namecoin miners are *also* Bitcoin miners, we won't focus on the effect for Bitcoin's security.

This is a table that's similar to the Bitcoin/Ethereum tables above, except that our time scale is now in terms of 10 minute increments (which both Bitcoin and Namecoin use). For simplicity, it's assumed that blocks are produced at a constant rate and that Bitcoin blocks aren't produced simultaneously.

| Time (10 min increments) | NMC block made | NMC block contents | NMC state | BTC block made | BTC block contents | BTC  state |
|---|---|---|---|---|---|---|
| ... |||||||
| 0 | k | BTC[k-1] header + Merkle proof of NMC[k-1] | Tracks BTC chain up to BTC[k-1] *and* knows that BTC knows of NMC[k-1] ||||
| 0.5 | ||| k | NMC[k] header | Tracks NMC chain up to NMC[k] |
| 1 | k+1 | BTC[k] header + Merkle proof of NMC[k] | Tracks BTC chain up to BTC[k] *and* knows that BTC knows of NMC[k] ||||
| 1.5 | ||| k+1 | NMC[k+1] header | Tracks NMC chain up to NMC[k+1] |
| ... |||||||

How can Namecoin alter it's 'block weight' calculation to take advantage of this? How can we structure things to help Namecoin prevent attacks?

NB: it is assumed that `hashrate(NMC) < hashrate(BTC)` and `totalHashrate([NMC, BTC]) = hashrate(BTC)`. That means that `1 NmcBlock` must 'weigh' less than `1 BtcBlock`. For this example: `2 NmcBlocks = 1 BtcBlock`; i.e. `2 BtcBlocks/NmcBlock` is our constant of conversion.

Like our previous examples, Namecoin needs a block weight calculation like:

```haskell
-- namecoin-vanilla-weight-calc.hs
type NmcWeight = Number

nmcChainWeight :: List Block -> NmcWeight
nmcChainWeight [] = 0
nmcChainWeight b:bs = nmcBlockWeight b + nmcChainWeight bs

nmcBlockWeight :: Block -> NmcWeight
nmcBlockWeight block = 1
```

Let's alter this like before. However, we need to remember that we can't *double count* the hashrate here. An attacker wouldn't need extra hardware like they might with the Bitcoin/Ethereum example, and if we calculate a block's weight as we did with Ethereum, then we might calculate a Namecoin block's security to be `3 NmcBlocks` rather than the intuitive maximum of `2 NmcBlocks` (since `2 NmcBlocks = 1 BtcBlock`).

```haskell
-- namecoin-modified-weight-calc.hs
type BtcWeight = Number
type NmcWeight = Number

btcWToNmcW btcW = btcW * 2
nmcWToBtcW nmcW = nmcW / 2

nmcChainWeight :: NmcState -> List Block -> NmcWeight
nmcChainWeight _ [] = 0
nmcChainWeight state b:bs = nmcTotalBlockWeight state b + nmcChainWeight state bs

nmcTotalBlockWeight :: NmcState -> Block -> NmcWeight
nmcTotalBlockWeight state block = nmcBlockWeight block +
    if btcHasConfirmed state block
        then btcWToNmcW (btcOnlyWorkFor state block)
        else 0

btcHasConfirmed :: NmcState -> Block -> Boolean
btcHasConfirmed state block =
    doesBtcHaveBlock state block &&
    isBlockInMainChainAccordingToBtc state block

-- we won't define these functions as their names are illustrative enough
doesBtcHaveBlock _ _ = undefined
isBlockInMainChainAccordingToBtc _ _ = undefined

btcOnlyWorkFor :: NmcState -> Block -> BtcWeight
btcOnlyWorkFor state block = sum $ (\b -> btcBlockWeight b - doubleCountedWeight) <$> relevantBtcBlocks
  where
    relevantBtcBlocks = filter currBlockIsHead (btcMainChainBlocks state)
    currBlockIsHead btcBlock = nmcHash block == getNmcHeadFromBtcBlock btcBlock
    -- todo: is this correct? what about if an NMC block get's confirmed, then there
    -- are 3x BTC confirmations on top, but no NMC blocks in that time? (so 4 confs total)
    -- Should that count as `3.5 BtcBlocks` or `2 BtcBlocks`?
    -- Max's intuition: 2 (the latter). IDK tho, needs more thinking.
    doubleCountedWeight :: BtcWeight
    doubleCountedWeight = nmcWToBtcW $ nmcBlockWeight block

nmcBlockWeight :: Block -> NmcWeight
nmcBlockWeight block = 1

btcBlockWeight :: BtcBlock -> BtcWeight
btcBlockWeight btcBlock = 1
```

The above code should reflect the essence of the expected result: the NMC chain is as resistant to doublespend attacks as the Bitcoin chain is. However, this isn't the case:

What if an attacker deliberately creates a bad NMC block, with valid PoW, and adds it to the tip of the NMC-header chain in Bitcoin? (the attacker can do this for 'free')
- NMC miners will reject and mine on fork
- Bad miner could try and 51% attack NMC; attacker produces more blocks (free!)
- Then BTC chain will confirm the bad NMC chain
- Even if NMC miners get their blocks confirmed, those blocks won't be part of best header-chain according to BTC (they'll be in a 'stale' branch). The bad NMC chain will be winning according to Bitcoin's knowledge of headers.
- NMC needs to do like 2x the work (or more!) to get 'good' NMC chain back on top.
- What if BTC reflects in NMC? Then the bad NMC header needs a proof of BTC history - fine, can be selectively produced to meet reflection criteria
- Can we get BTC to fork with NMC fork? (this can happen with heterogeneous hash algs)
- Insecure? Sort of; NMC users don't actually follow the invalid chain, just they don't get the security benefit of reflection.
- the security benefit can't be given to any and all headers that are known about just b/c they're included; they're somewhat arbitrary to the foreign chain so if a header gets a benefit but isn't in the main chain then we get back to normal security params -- no advantage for honest chain.
- how does this change if we use a dag instead of a tree?
- how does this change if NMC is also reflected in Eth? How would you calculate the work/weight on each block?

So reflections between merged chains *aren't secure and provide no security benefit?* (perhaps even making the situation worse for honest aux-chain nodes/miners?)

Is there a way to fix the weight calculation to avoid this problem? Core of the problem seems to be that BTC miners can mine bad NMC blocks for free. no opportunity cost => attack costs 'nothing'.

(todo / meta / editors note / NB: This was the conclusion I reached on Monday, too. Reflecting work in a totally separate chain increases the cost for an attacker to attack b/c they can't re-use work for free. but, since with MM they can re-use work for free, there's no overhead for the attack. That's why it can be secure with heterogeneous algs / multiple diff chains.) this isn't too surprising, the security weaknesses of MM chains (if miners aren't mining *all* the MM chains) are known.

Directions for research/solutions:
- DAG; let's us build on invalid history, both groups of headers (valid and invalid) are tips at various times on the 'parent'-chain (i.e. the strongest MM chain).
- Rewards for MM work depend on all MM blocks being accepted into the relevant chains? Note: MMed chains can't be hidden via microchain MM method, but can be hidden via BTC/NMC MM method
- What if the 'main' (or 'parent') MM chain is *only* tracking the headers of all merged-chains? Like there's a 'microchain' for Bitcoin and Namecoin, and both are MM against the 'microchain', and the state of the 'microchain' is just the headers of both BTC and NMC?
  - What if that *plus* they have a common reward coin (the ROO) and the rewards for *all* the work depend on their blocks being accepted into the relevant MM chains? (in this case the MM chains would be the dapp chains)
  - the idea here is that *all* your blocks have to be valid to get a mining reward
  - would that actually weaken MM security by allowing a 51% of NMC to prevent other miners' BTC rewards being handed out? So a minority rule situation?
- the MM reflection attack exists b/c the BTC reward doesn't depend on *all* contributions from the mining effort being valid -- like the validity of the BTC block doesn't have anything to do with the validity of the NMC block. It's not one single yes/no system. But mining is only secure *because* there's one single yes/no outcome. you either get the reward or you don't.
- could ZKPs (or like proofs of valid computation) be used here (part of the header) to prove that the txs and state transitions are valid? If that has complexity O(h), s.t. O(h) < O(c), then it's easier to verify a valid header transition than to actually do the transition calc (plus, would mean that it might be possible to verify a state transition without knowing the state transition).

**ditch merged mining? can reflection between chains of the same work algs be secure? could that replace merged mining?**

links to a lot of research, some might be relevant. is interesting in any case: https://medium.com/@adlerjohn/the-why-s-of-optimistic-rollup-7c6a22cbb61a

#### PoW reflection between chains using the same alg

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

#### Contexts where PoW can be directly compared

- decentralized market
  - risk of manipulation
  - does provide a way to convert between reward tokens => a way to get a 'constant of conversion'
- single token across multiple chains (like the ROO)
  - 'constant of conversion' = to ratio of ROO on each chain (at that time)

#### Reflection with more than two blockchains

guess: extending the Bitcoin + Ethereum example to, say, Bitcoin + Ethereum + Litecoin will provide the security benefits of all 3. it should be additive. a doublespend would require a doublespend against all 3.

#### Reflection with PoS chains / otherwise unsafe consensus algs (like PoA)

- helps solve *nothing at stake* problem b/c history is committed to thermodynamically (b/c of reflection in PoW chains), even with internal-based-stake (i.e. ROO); slashing can happen on like a 'watchdog' chain to ensure bad actors can't get away with it
- provides easy way for corps to run darkchains for whatever they want (tho *how* exactly you do the dark bit is ??)
- anyone can make a little PoS chain to add to security; has to fit within the O(c) 'microchain' but that should be fine-ish
- PoS chains could like safely provide mb up to 50% of security? this would mean a 50% reduction in energy usage (not that a reduction of that complexity matters -> energy usage still of same complexity, i.e. O(n))
- how to balance PoW rewards with PoS? if staking is just 'free money' then why would ppl mine? mb staking involves some burning? i.e. you burn 100 coins and if you mine for 1yr you get 105 coins back or something. hmm. burn means slashing is hard, so mb not burn.
- would deffo need a deposit for PoS chains, still. can't start a chain from nothing, need some cost (or opportunity cost at least)
- could build of parity/ethereum/polkadot/etc clients. Cardano too if Ouroboros isn't garbage.
- PoS implementations more complex but easier to think about. Their building blocks are simpler but there are more of them. PoW systems have fewer building blocks but harder to think/reason about.

#### can rewards be based on PoW being accepted into a foreign chain?

e.g. you lose your BTC reward if your MM NMC block isn't accepted? This could only be done with a DAG system b/c there's a chance of a stale NMC block penalizing an honest BTC+NMC miner

this is the only thing i have thought of (so far?) that could make MM PoW reflection secure.
