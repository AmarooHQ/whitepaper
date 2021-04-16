\newpage

# Introduction

*Ultra Terminum* (UT) is a cooperative cross-chain consensus strategy that solves *Buterin's Trilemma*[^buterins-trilemma] (aka the *Scalability Trilemma*). That is: *Ultra Terminum* builds on existing consensus methods to produce a blockchain network that is highly distributed, highly secure, and highly scalable. In essence, UT is a new way to organize blockchains.

[^buterins-trilemma]: I think *Scalability Trilemma* is a bad name because *scalability* is one of the three conflicting qualities; you could just as well call it the *Decentralization Trilemma*, etc. The term *Blockchain Trilemma* has been used recently, which I think is worse. Apparently the term was coined by Vitalik Buterin, so I prefer the name *Buterin's Trilemma*.

Compared with existing consensus methods, UT provides *equal or better* security properties than **all** existing consensus methods (including Bitcoin's PoW method and variants, and *all* PoS variants). This is because UT leverages existing consensus methods in combination and, by way of construction, UT can only *add* security to these methods.

As a consensus method[^ut-consensus-method], UT differs from existing consensus methods in that it is a *generic modification* to particular components of consensus algorithms. These modifications allow existing consensus algorithms to synergistically cooperate. This results in *massive* improvements to the security and decentralization of the network, whilst also providing a foundation for incredible scalability.

[^ut-consensus-method]: Whether *Ultra Terminum* is a consensus method or not is somewhat unclear. On the one hand: a new combination of methods is still a method. On the other hand: UT provides a way to modify most/all other consensus methods, and UT doesn't provide a way to run a *single* blockchain. This is why I've described it as a cross-chain consensus *strategy*.

UT is capable of supporting millions of transactions per second in the security environment afforded by a first class blockchain (e.g. Bitcoin, Eth1).

At the core of *Ultra Terminum* is a new method for sharing security: *PoW Reflection*. This technique (which works with PoS, too) allows us to incrementally build complex blockchain networks with powerful scaling properties. *PoW Reflection* is how *Ultra Terminum* can scale with orders $O(c^2)$, $O(c^3)$, $O(c^4)$, and -- in the right contexts -- $O(n)$.

As UT is primarily a method of *structuring* a blockchain network, the scalability configurations mentioned herein *do not include **layer 2** methods*. That means that *layer 2* techniques (e.g., state/payment channels, ZK/optimistic rollups, and anchored/side chains) can be implemented *on top* of UT.

UT's unique structure means that confirmation times within UT are of order $\frac{1}{O(c)}$. This is a significant improvement over existing architectures, which are of order $O(1)$. This means that, as computers get more powerful, confirmation times in UT approach 0.

## Assumed Knowledge

You will need to understand (or, perhaps, have mastered) the following concepts to reliably understand the foundations of *PoW Reflection* and *Ultra Terminum*:

* Nakamoto Consensus (i.e., how Bitcoin's blockchain works)
* The idea of $O(c)$ and $O(c^2)$ scaling and existing strategies -- you can read the first few FAQs [here](https://eth.wiki/sharding/Sharding-FAQs) for a refresher
* SPV proofs
* SPV proofs via Smart Contracts (e.g. [BTC Relay](https://github.com/ethereum/btcrelay))

And you'll need to understand the following to understand how *Ultra Terminum* thwarts some attacks:

* Generalizations of Nakamoto Consensus to DAGs (particularly, read [*Inclusive Block Chain Protocols*](https://www.avivz.net/pubs/15/inclusive_btc_full.pdf)[^incl-proto])

[^incl-proto]: *Inclusive Block Chain Protocols* by Yoad Lewenberg, Yonatan Sompolinsky, and Aviv Zohar. <https://www.avivz.net/pubs/15/inclusive_btc_full.pdf>, <https://fc15.ifca.ai/preproceedings/paper_101.pdf>, DOI: 10.1007/978-3-662-47854-7_33
