## Misconceptions

### PoW doesn't scale

> However, Bitcoin encounters performance problems of low throughput and high transaction latency. Other cryptocurrencies based on proof-of-work also inherit the flaws, leading to more concerns about the scalability of blockchain.

- Solutions to Scalability of Blockchain: A Survey (2020); 08962150.pdf; IPFS: QmbD8ad8a8cUgXERBThMGYAmzGjmDr2okPGsBGBrQJsv1k

> The list for brilliant, blockchain scalability solutions spans on. From blockchains that look less like chains and more like directed acyclic graphs [pictured above], to faster consensus algorithms like PoS, PoA, specifically mutations of federated BFTs and delegated BFTs that guarantee faster block finality & production… users now have a plethora of solutions to choose from.

- https://medium.com/hackernoon/simply-explained-blockchain-scalability-solutions-past-present-and-future-1bc4d5c309b6

comment: how exactly is PoS/PoA faster? the author doesn't say

----

There is a myth that somehow proof-of-work is not capable of scaling to the extent that proof-of-stake is.

While it's somewhat true that the *networks* which use PoW can become congested and have high confirmation latency, a cursory familiarity with the Bitcoin source code will reveal that these are controlled by chain parameters[^pow-chain-params]. This is why Litecoin can process more transactions than Bitcoin: the network parameters are different (in this case the target duration between blocks is 2.5 min instead of 10 min).

If a proof-of-stake network had the same chain parameters as Bitcoin -- i.e. a maximum block size of 1,000,000 bytes + 10 minutes between blocks -- then it would have the same throughput (all else being equal). Badly chosen chain parameters *can* be problematic, but it's not directly related to proof-of-X in most cases.

[^pow-chain-params]: **todo** find proper reference to block size limit; [here's MAX_BLOCK_BASE_SIZE in a test](https://github.com/bitcoin/bitcoin/blob/384e090f9345c07fa81ccafa8cd36037f3cd0813/test/functional/test_framework/messages.py#L40)


> The Trilemma posits that there is no silver bullet solution for scaling blockchains. At best, two out of the three criteria of scalability, security, versus decentralization can be satisfied.

- https://medium.com/hackernoon/simply-explained-blockchain-scalability-solutions-past-present-and-future-1bc4d5c309b6
