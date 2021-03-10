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

If a proof-of-stake network had the same chain parameters as Bitcoin -- i.e. a maximum block size of 1,000,000 bytes + 10 minutes between blocks -- then it would have the same throughput (all else being equal). Badly chosen chain parameters *can* be problematic, but it's not directly related to proof-of-X in most cases.

[^pow-chain-params]: **todo** find proper reference to block size limit; [here's MAX_BLOCK_BASE_SIZE in a test](https://github.com/bitcoin/bitcoin/blob/384e090f9345c07fa81ccafa8cd36037f3cd0813/test/functional/test_framework/messages.py#L40)


> The Trilemma posits that there is no silver bullet solution for scaling blockchains. At best, two out of the three criteria of scalability, security, versus decentralization can be satisfied.

- https://medium.com/hackernoon/simply-explained-blockchain-scalability-solutions-past-present-and-future-1bc4d5c309b6

### PoW is "wasteful"

Another common misconception is that proof-of-work is "wasteful"[^pow-waste]. This ignores a qualatative difference between PoW and PoS: PoW has *thermodynamic* security. That is, an attempt to re-write a PoW chain's history requires the *destructive* use of energy. By comparison, PoS only consumes negligable energy.

This means that there are no laws of physics which prevent re-writing the arbitrary history of a PoS chain[^phys-info]. There are thus many methods of re-writing PoS chains' histories, because "if something is permitted by the laws of physics, then the only thing that can prevent it from being technologically possible is not knowing how"[^boi-optimism].

It is within a person's *rights* to think and claim that PoW is wasteful. However, any person with philosophical integrity *must* acknowledge that this is a value-judgement, because there *is* a qualitative difference. By implication, such a person claims that thermodynamic security has zero value. This is an error in reasoning since thermodynamic security does have utility that isn't replicable via PoS methods. They might claim that this property is not *useful*, however, they are therefore claiming that Adam Back, Satoshi, and others have made major mistakes in their methods. To date, I am not aware of any unanswered criticisms of the aforementioneds' ideas that imply this. Without such a criticism, the conjecture that *thermodynamic security has no utility* cannot be accepted on the basis of *reason*.

[^pow-waste]: e.g. http://elaineshi.com/docs/blockchain-book.pdf chapter 18 intro

[^boi-optimism]: See the reasoning behind *The Principle of Optimism* in *The Beginning of Infinity*, chapter 9: *Optimism*.

[^phys-info]: Granted, information theory is implied by the laws of physics, but this does not guard against $5 wrench attacks. PoW and thermodynamic security do, though. Wrenches do not reverse entropy.
