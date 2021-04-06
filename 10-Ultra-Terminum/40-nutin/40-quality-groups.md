## Qualities of different security methods

\label{sec:quality-groups}

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

### Lowering the variance of block production in PoW blockchains

\todo[inline]{mb -- figures showing block production to demonstrate variance}

Is it possible to *dramatically* lower the variance of block production in PoW blockchains without altering incentive structures, compromising security, or changing the probability of generating a valid block?

Yes. The method relies on the *structure* of the network, rather than the consensus protocol itself. Particularly, the network must be structured such that miners' choices result in decreased block production variance --- an emergent phenomenon. It's important not to try and make it artificially (e.g. by increasing the block reward with time-since-last-block) because you don't want ppl to game the system. It's better to have a simple system with emergent properties than a complex system with those properties "designed in".

Say you have a network with 10 chains: $C_0, C_1, C_2, ..., C_9$. If the networks are separate, then you have 10 groups of miners: $M_0, M_1, M_2, ..., M_9$. They have to choose one chain to mine on, so the distribution of miners is expected approximate the distribution of normalized block rewards + tx fees. The proportions of block rewards between $C_i$ & $C_j$ don't really matter, we expect the mining groups $M_i$ & $M_j$ will just sort themselves out due to market forces. For simplicity, though, this example assumes that mining rewards and the distribution of miners is an even 10% across the board.

If the network has spare capacity (i.e., txs are mostly cleared out with each block; the mempool for each chain is ~empty) then we have a situation like this:

Set $t=0$ to be immediately after a block is published on a chain. then, as $t$ progresses, txs with fees should build up in the mempool, so $TxFees \propto t$. The reward for mining a block is $r + TxFees$ for some block reward, $r$. if $TxFees \propto t$ then $r + TxFees \propto K + t$ for some constant $K$.

The potential reward-over-time for a miner ($t$ vs $r + TxFees$) looks like a sawtooth function with a y-axis offset. It builds as more txs pile up, and drops back to the baseline reward after a block.

\todo[inline]{figure of reward vs time mb, and one with lower variance? IDK, mb not necessary. Here's a paper about block production/arrival times \url{https://arxiv.org/pdf/1801.07447.pdf} also \url{https://en.wikipedia.org/wiki/Negative_binomial_distribution}}

If the miners $M_0, ..., M_9$ are capable of working on one of any $\{C_0, ..., C_9\}$ (and they have identical ROI profiles to the other miners), then they're incented to work on the chain with the most txs in the mempool. That means: miners should, roughly, work the chain that has gone the longest without a block. What should we expect based on those incentives? Miners should work on each chain only in the final moments of the block production cycle. If block times were set to 60s, then they'd start mining at like the 54s mark b/c that's how they maximize their ROI.

Why wouldn't they just keep mining on the same chain? b/c in the time that they focused on one chain, another one passed that >54s high-ROI threshold and thus has the best ROI potential per hash done.

We should thus expect that this configuration of chains actually *synchronizes* miners, resulting in block production that is somewhat regular and lower in variance.

One reason that we can predict that txs will build up in this fashion (with those fees and in a predictable way) is that most of the txs that are included in simplex blocks will be dapp-chain-header-transactions. Since dapp-chains will use PoS, we should expect them to be predictable and regular.

The average hash rate on each simplex chain, as described above, is always the same regardless of which of the two miner strats are used. However, the variance of block production on each of these chains won't be that of a chain with 60s block times, it'll be that of a chain with 6s block times.

\todo[inline]{paragraph below needs to be polished}

Is it possible that this will help prevent attacks too? An attacker has the same 51% parameters to DoS a chain (tho a block-dag can thwart naive DoS attacks), however, the attacker is competing against no other hashpower for 54s out of 60s, and competing against 20x his hashpower for the last 6s out of that 60s. Why 20x? If each chains' average hashrate is 10% of the total hashrate, then the attacker needs 5% of the total hashrate to 51% attack a single chain. Relative to the attacker, he might have 51% of the avg mining power for a given chain, but the aggregate hashrate is 20x that.
