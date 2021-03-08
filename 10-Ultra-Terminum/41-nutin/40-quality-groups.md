### Qualities of different security methods

A *quality-group* is a group of qualities that can exist simultaneously. For any indivisible (and applicable) problem, you can choose one of the quality groups; but you can't mix and match qualities from each group.

This sort of thing happens (at least in this case) because there is a choice of method, and each method provides different emergent properties.

Consider these 3 categories of methods of securing a blockchain:

* PoW with ASICs
* PoW without ASICs (e.g. GPUs/CPUs; aka "ASIC resistant")
* PoS

PoW+ASICs means the miner-base is inflexible; they don't have many choices for where to point their ASICs. It's super high hash-rate, tho, and has near-optimal thermodynamic security given the state of ASIC manufacturing (e.g. 5nm chips).

PoW+GPUs means the miner-base is super flexible; there are lots of choices for profitable chains to mine. They can pick and choose and have low overhead to doing so. They aren't near the limit for thermodynamic security, tho. If relevant ASICs come along they'll always out-compete GPUs.

PoS has an inflexible miner base too -- most PoS schemes (e.g. PBFT, DPoS, etc) require the miners to stake coins and that happens over a period of time. However, there is a sense where the thermodynamic security of PoS is high (provided ECDSAs and EC crypto keep working). There's another sense where the thermodynamic security of PoS is low: miners control their private keys and have near zero energy cost per signature. That's the reason that PoS systems include mechanics like *slashing*.

So these methods of doing blockchain security all have different qualities. What does it mean for Amaroo, and how should the UT simplex be divided between these groups?

UT's consensus is emergent from an *additive and collaborative* process. Adding more simplex-chains increases security incrementally, but if one fails (or is attacked) then it doesn't have magnified negative effects for the rest of the network. This means we can potentially add lots of different types of blockchain security, with different qualities, to create a platform where dapp-authors can *choose the desired qualities*.

Do they want a highly secure base-chain, but variance in block times isn't a problem? Then they should go with an ASIC-chain. Do they want a moderately secure base-chain, but with *low* variance in block times? Then go with a GPU-chain. Do they want a moderate-to-low security base-chain, but with regular (near-zero-variance) block times? Then go with a PoS/PoA-chain (at the simplex level).

My intuition is that each of these three quality-groups should be responsible for <50% of UT's overall security. If they were balanced, then they'd be at one-third each; however, something like 45%/40%/15% would work too.

NB: The only way to directly compare security like this is to proxy the measurement via the distribution of ROO per group. i.e., for the 45/40/15 example, we might have 45% of ROO in (or on dapp-chains via) ASIC-chains, 40% in GPU-chains, and 15% in PoS-chains. For this calculation I count any ROO in a dapp-chain as also being in the parent simplex-chain.

#### Lowering the variance of block production in PoW blockchains

op: https://3.basecamp.com/4985262/buckets/20820958/messages/3532467549

no direct modification of incentives required -- like that is an emergent phenomona via tx fees.

the soln is in how the network is structured -- then miners follow easy+rational choices about what to mine on. it's important not to try and make it artificially (e.g. by increasing the block reward based on time-since-last-block) because you don't want ppl to game a system. better to have a simple system with emergent props than a system with those props designed in that's gameable.

Say you have a network with 10 chains: C0, C1, C2, ..., C9. If the networks are separate then you have 10 groups of miners: M0, M1, M2, ..., M9. They have to choose one chain to mine on (basically), so you expect a distribution to be basically proportional to normalized (e.g. in USD) block rewards + tx fees. The proportions of block rewards between Ci & Cj don't really matter, we expect the mining groups Mi & Mj will just sort themselves out. For simplicity, tho, we can say that everything is an even 10% across the board (mining rewards, miners on each chain, etc).

IF the network has spare capacity (i.e. txs are mostly cleared out with each block; the mempool for each chain is ~empty) then we have a situation like this:

set t=0 to be immediately after a block is published on a chain. then, as t progresses, txs with fees should build up in the mempool, so `tx_fees ~ t`. the reward for mining a block is `r + tx_fees` for some block reward, r. if tx_fees ~ t then r+tx_fees ~ K+t for some constant K.

the reward-over-time looks like a saw function with a y-axis offset (e.g. first image on: https://www.thefouriertransform.com/series/sawExample.php). it slowly builds as more txs pile up, and drops back to the baseline reward after a block.

If the miners M0, ..., M9 are capable of working on one of any {C0, ..., C9} (they have identical ROI profiles to the other miners), then basically they're incentivised to work on each chain "late" in the cycle of tx-accumulation-then-new-block. What should we *roughly* expect based on those incentives? Miners should work on each chain only in the final moments of the cycle. If block times were set to 60s, then they'd start mining at like the 54s mark b/c that's how you maximise ROI.

why wouldn't they just keep mining on the same chain? b/c in the time that they focused on one chain, another one entered into that >54s threshold and thus has the best ROI potential per hash done.

I wouldn't be surprised if chains basically end up synchronising so that there's a much more reliable 'tick-tick-tick' pattern of blocks.

One reason that we can predict txs will build up in this fashion (with those fees and in a predictable way) is that most of the txs that are included in simplex blocks will be dapp-chain-block-transactions. Because those are probs PoS, they should be predictable and regular.

The average hash rate on each chain, as described above, is always the same regardless of which of the two miner strats are used (always averages to 10%). however, the variance of the blocks won't be that of a chain with 60s block times, it'll be one of a chain with 6s block times.

I haven't thought enough about it yet, but I think this will help prevent attacks too; the attacker has the same 51% params to try and like DOS a chain or whatever (tho a block-dag helps here), however, the attacker is competing against 0% of his hashpower for 54s out of 60s, and competing against 2000% of his hashpower for 6s out of 60s. (if the chains average to 10% of all miners, then the attacker needs 5% of all miners to 51% attack the chain. relative to the attacker, he might have 51% of the avg mining power on that chain, but the aggregate of miners is 20x that; hence 2000% mentioned before).
