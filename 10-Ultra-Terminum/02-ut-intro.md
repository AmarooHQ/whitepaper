\newpage

# Introduction

*Ultra Terminum* is a consensus algorithm that solves *Buterin's Trilemma* (aka the *Scalability Trilemma*). That is: *Ultra Terminum* is a consensus method that is highly distributed, highly secure, and highly scalable. The method is, of course, trustless, as well as non-coercive and permissionless. It is capable of supporting millions of transactions per second in the security environment afforded by a first class blockchain (e.g. Bitcoin, Eth1) rather than the lessened environment of less prescriptive methods (like chain fibers, parachains, the tangle, PoS shards, etc). It is not without concessions, but the benefits are enormous.

NB: I think *Scalability Trilemma* is a bad name because *scalability* is one of the three conflicting qualities; you could just as well call it the *decentralization trilemma*, etc. Apparently the term was coined by Vitalik Buterin, so I prefer the name *Buterin's Trilemma*.

The essence of *Ultra Terminum* is a new method for sharing security: *PoW Reflection*. This technique allows us to build complex blockchain networks with powerful scaling properties. This is how *Ultra Terminum* can achieve scaling with complexities: $O(c^2)$, $O(c^3)$, $O(c^4)$, and -- in the right contexts -- $O(n)$.

## Assumed Knowledge

You will need to understand the following concepts to understand the foundations of *PoW Reflection* and *Ultra Terminum*:

* Nakamoto Consensus (i.e. how Bitcoin's blockchain works)
* The idea of $O(c)$ and $O(c^2)$ scaling -- you can read the first few FAQs [here](https://eth.wiki/sharding/Sharding-FAQs) for a refresher
* SPV proofs
* SPV proofs via Smart Contracts (e.g. [BTC Relay](https://github.com/ethereum/btcrelay))

And you'll need to understand the following to fully understand *Ultra Terminum* and it thwarts some attacks.

* Generalizations of Nakamoto Consensus to DAGs (particularly, read *Inclusive Block Chain Protocols*[^incl-proto])

[^incl-proto]: *Inclusive Block Chain Protocols* by Yoad Lewenberg, Yonatan Sompolinsky, and Aviv Zohar. <https://www.avivz.net/pubs/15/inclusive_btc_full.pdf>, <https://fc15.ifca.ai/preproceedings/paper_101.pdf>, DOI: 10.1007/978-3-662-47854-7_33
