\newpage

# Introduction

*Ultra Terminum* (UT) is a cross-chain consensus method that solves *Buterin's Trilemma*[^buterins-trilemma] (aka the *Scalability Trilemma*). That is: *Ultra Terminum* is a consensus method that is highly distributed, highly secure, and highly scalable. In essence, UT is a new way to organize blockchains.

[^buterins-trilemma]: I think *Scalability Trilemma* is a bad name because *scalability* is one of the three conflicting qualities; you could just as well call it the *Decentralization Trilemma*, etc. The term *Blockchain Trilemma* has been used recently, which I think is worse. Apparently the term was coined by Vitalik Buterin, so I prefer the name *Buterin's Trilemma*.

\todo[inline]{something about methodology + generic modification to existing consensus methods}

It may be more accurate to describe UT as a new *methodology* because

UT has equal or better security properties than all individual/singular/atomic/foundational consensus methods (including Bitcoin's PoW method and all PoS variants). This is because UT is able to leverage many existing consensus methods in combination and, by way of construction, UT can only *add* security to these methods, or *do nothing*.

UT is capable of supporting millions of transactions per second in the security environment afforded by a first class blockchain (e.g. Bitcoin, Eth1).

The essence of *Ultra Terminum* is a new method for sharing security: *PoW Reflection*. This technique allows us to build complex blockchain networks with powerful scaling properties. This is how *Ultra Terminum* can scale with orders $O(c^2)$, $O(c^3)$, $O(c^4)$, and -- in the right contexts -- $O(n)$.

\todo[inline]{UT isn't like a singular consensus method, more like a multi-method or methodology. todo: decide what to call this. a meta-consensus method? a multi-consensus method? a consensus multi-method? a consensus methodology?}

\todo[inline]{What do we call other consensus methods? individual/singular/atomic/foundational mb}

## Assumed Knowledge

You will need to have mastered the following concepts to reliably understand the foundations of *PoW Reflection* and *Ultra Terminum*:

* Nakamoto Consensus (i.e., how Bitcoin's blockchain works)
* The idea of $O(c)$ and $O(c^2)$ scaling -- you can read the first few FAQs [here](https://eth.wiki/sharding/Sharding-FAQs) for a refresher
* SPV proofs
* SPV proofs via Smart Contracts (e.g. [BTC Relay](https://github.com/ethereum/btcrelay))

And you'll need to understand the following to understand how *Ultra Terminum* thwarts some attacks:

* Generalizations of Nakamoto Consensus to DAGs (particularly, read [*Inclusive Block Chain Protocols*](https://www.avivz.net/pubs/15/inclusive_btc_full.pdf)[^incl-proto])

[^incl-proto]: *Inclusive Block Chain Protocols* by Yoad Lewenberg, Yonatan Sompolinsky, and Aviv Zohar. <https://www.avivz.net/pubs/15/inclusive_btc_full.pdf>, <https://fc15.ifca.ai/preproceedings/paper_101.pdf>, DOI: 10.1007/978-3-662-47854-7_33

## A Principle of Scaling

When you have worse than $O(c)$ complexity, that thing cannot become a bottleneck. If it's not a bottleneck, then it doesn't matter that it's worse than $O(c)$.

\todo[inline]{include this?}
