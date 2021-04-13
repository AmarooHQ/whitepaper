## Misconceptions

### PoW doesn't scale

> However, Bitcoin encounters performance problems of low throughput and high transaction latency. Other cryptocurrencies based on proof-of-work also inherit the flaws, leading to more concerns about the scalability of blockchain.

- Solutions to Scalability of Blockchain: A Survey (2020); 08962150.pdf; IPFS: QmbD8ad8a8cUgXERBThMGYAmzGjmDr2okPGsBGBrQJsv1k

> The list for brilliant, blockchain scalability solutions spans on. From blockchains that look less like chains and more like directed acyclic graphs [pictured above], to faster consensus algorithms like PoS, PoA, specifically mutations of federated BFTs and delegated BFTs that guarantee faster block finality & production… users now have a plethora of solutions to choose from.

- https://medium.com/hackernoon/simply-explained-blockchain-scalability-solutions-past-present-and-future-1bc4d5c309b6

comment: how exactly is PoS/PoA faster? the author doesn't say

----

There is a myth that somehow proof-of-work is not capable of scaling to the extent that proof-of-stake is.

While it's somewhat true that the *networks* which use PoW can become congested and have high confirmation latency, a cursory familiarity with the Bitcoin source code will reveal that this is due to limits which are controlled by chain parameters[^pow-chain-params]. This is why Litecoin can process more transactions than Bitcoin: the network parameters are different (in this case the target duration between blocks is 2.5 min instead of 10 min, but the block size limit is the same).

If a proof-of-stake network had the same chain parameters as Bitcoin -- i.e., a maximum block size of 1,000,000 bytes + 10 minutes between blocks -- then it would have the same throughput (all else being equal). Badly chosen chain parameters *can* be problematic, but it's not directly related to proof-of-X in most cases.

[^pow-chain-params]: **todo** find proper reference to block size limit; [here's MAX_BLOCK_BASE_SIZE in a test](https://github.com/bitcoin/bitcoin/blob/384e090f9345c07fa81ccafa8cd36037f3cd0813/test/functional/test_framework/messages.py#L40)


> The Trilemma posits that there is no silver bullet solution for scaling blockchains. At best, two out of the three criteria of scalability, security, versus decentralization can be satisfied.

- https://medium.com/hackernoon/simply-explained-blockchain-scalability-solutions-past-present-and-future-1bc4d5c309b6

### PoW is "wasteful"

Another common misconception is that proof-of-work is "wasteful"[^pow-waste]. This ignores a qualitative difference between PoW and PoS: PoW has *thermodynamic* security. That is, an attempt to re-write a PoW chain's history requires the *destructive* use of energy. By comparison, PoS only consumes negligible energy.

This means that there are no laws of physics which prevent re-writing the arbitrary history of a PoS chain[^phys-info]. There are thus many methods of re-writing PoS chains' histories, because "if something is permitted by the laws of physics, then the only thing that can prevent it from being technologically possible is not knowing how"[^boi-optimism].

It is within a person's *rights* to think and claim that PoW is wasteful. However, any person with philosophical integrity *must* acknowledge that this is a value-judgement, because there *is* a qualitative difference. By implication, such a person claims that thermodynamic security has zero value. This is an error in reasoning since thermodynamic security does have utility that isn't replicable via PoS methods. They might claim that this property is not *useful*, however, they are therefore claiming that Adam Back, Satoshi, and others have made major mistakes in their methods. To date, I am not aware of any unanswered criticisms of the aforementioneds' ideas that imply this. Without such a criticism, the conjecture that *thermodynamic security has no utility* cannot be accepted on the basis of *reason*.

[^pow-waste]: e.g. http://elaineshi.com/docs/blockchain-book.pdf chapter 18 intro

[^boi-optimism]: See the reasoning behind *The Principle of Optimism* in *The Beginning of Infinity*, chapter 9: *Optimism*.

[^phys-info]: Granted, information theory is implied by the laws of physics, but this does not guard against $5 wrench attacks. PoW and thermodynamic security do, though. Wrenches do not reverse entropy.

### The Nothing-at-Stake problem isn't an issue, or it's easy to solve in a pure PoS environment

To my knowledge, there is no good solution to the nothing-at-stake problem for pure PoS blockchains.

\todo{check if there have been any new ideas to solve NAS problem}

Two of the most popular PoS chains -- Polkadot and Cardano -- barely attempt to deal with this problem. While it's likely true that these chains are secure *enough* for their current usage, we can't surely say the same if these chains gained massive popularity.

From the Polkadot whitepaper:

> To ensure newly-syncing clients are not able to be fooled onto the wrong chain, regular "hard forks" will occur (of at most the same period of the validators’ bond liquidation) that hard-code recent check-point block hashes into clients.

From the Ouroboros (Cardano's consensus method) paper:

> Provided that stakeholders are frequently online, nothing at stake is taken care of by our analysis of forkable strings (even if the adversary brute-forces all possible strategies to fork the evolving blockchain in the near future, there is none that is viable), and our chain selection rule that instructs players to ignore very deep forks that deviate from the block they received the last time they were online.

In essence, the solutions proposed to address the nothing-at-stake problem are: do regular and frequent checkpoint hard forks, or keep your nodes online and reject deep forks. Neither of these solutions provide comparable security to the thermodynamic security of proof-of-work chains; which is why Bitcoin (et al.) nodes don't need to remain online, and why Bitcoin doesn't *need* checkpoints[^btc-checkpoint]. It is worth noting that both Polkadot and Cardano introduce *new* and *external* sources of security: hard-forks that depend on developers updating client codebases, and a requirement that nodes remain online and the relevant networks remain unsegregated (e.g. that governments do not segregate the internet across borders).

Why does the nothing-at-stake problem exist? It is due to the conflict between these two necessary conditions: *miners must have some opportunity cost when producing blocks*, and *miners can soft-fork new rules in that prevent error correction methods like slashing from taking place*.

A simple demonstration of the nothing-at-stake problem can be seen via the following attack. NB: both Polkadot's and Cardano's solutions do guard against this attack, so the following is purely demonstrative.

A malicious user, perhaps a previously honest node, acquires (e.g. buys) private keys that do not *currently* hold stake, but did at some point in the past. That user can do this over a long period of time and can acquire private keys that correspond to stake at many different points in a chain's history. Once they reach some critical threshold they can begin the attack. First, they liquidate any coins they hold (e.g. via a 3rd party exchange) so that their assets will not be affected by the immanent attack. They then proceed to find the best point in the past to begin creating a chain-fork. Either via brute force or a more efficient method, they engineer some context by which they control the consensus method *at that point in the past* (and possibly selectively include past, valid, transactions). They create an alternate history from this starting point up to a relevant breakpoint in the PoS method (e.g. when new validators are chosen) and repeat the previous process of brute forcing or otherwise engineering a context where they control the consensus protocol. They repeat this process, selectively including pre-existing or newly created transactions such that they can control the consensus method indefinitely. This allows them to create a competing chain-fork of comparable length, which is then published and undoes relevant history (such as their transactions which deposit coins in an exchange account). They also soft-fork the protocol to prevent the publication of proofs that would lead to effects like slashing.

In this way, a malicious user can subvert one of the necessary conditions mentioned previously: that of opportunity cost. Fundamentally, since pure PoS methods do not have *thermodynamic* opportunity cost, there is no *physical* reason that this is impossible.

There is a mostly-trivial solution to this problem: do not use PoS as the foundation of a network's security. The nothing-at-stake problem only exists because of the circularity required in pure PoS systems: the consensus method determines the validators who control the transaction set, but the transaction set determines which validators are empowered under the consensus method. If, however, a PoS method is implemented *within* a PoW foundation, then properties like the required opportunity cost can be guaranteed by *moving the error correction methods to a PoW-secured layer*. This means that techniques like *slashing* cannot occur in the PoS layer, they should take place in a more foundational layer. Provided that a network's security resolves to some PoW layer, then well-designed PoS protocols can ~inherit enough thermodynamic security to thwart the nothing-at-stake problem. This method is universal in the correct design-space.

[^btc-checkpoint]: Bitcoin does include checkpoints, but checkpoints are only added when they are uncontroversial (e.g. *months* after the relevant blocks are produced) and these checkpoints aren't crucial for Bitcoin's integrity. These checkpoints do prevent certain types of non-critical ~griefing attacks -- a quality of life feature.


### The Myth of Spaceship Earth

### The Myth of Sustainability
