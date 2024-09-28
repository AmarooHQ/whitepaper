%% BEGIN ### RELEASE

\newpage
# Introduction

*Ultra Terminum* (UT) is a cooperative cross-chain consensus strategy that addresses *Buterin's Trilemma*[^buterins-trilemma] (aka. the *Scalability Trilemma*).
That is: *Ultra Terminum* builds on existing consensus methods to produce a blockchain network that is highly distributed, highly secure, and highly scalable. In essence, UT is a new way to organize blockchains.

[^buterins-trilemma]: I think *Scalability Trilemma* is a bad name because *scalability* is one of the three conflicting qualities; you could just as well call it the *Decentralization Trilemma*. Arguably, as we will see, the most appropriate of the 3 would actually be the *Security Trilemma*. The term *Blockchain Trilemma* has been used recently, which I think is worse. Apparently the term was coined by Vitalik Buterin, so I prefer the name *Buterin's Trilemma*.

Compared with existing consensus methods, UT provides *equal or better* security properties than **all** existing consensus methods (including Bitcoin's PoW method and variants, and *all* PoS variants).
This is because UT leverages existing consensus methods in combination and, by way of construction, UT can only *add* security to these methods.

As a consensus method[^ut-consensus-method], UT differs from existing consensus methods in that it is a *novel modification* to particular components of preexisting consensus algorithms.
These modifications allow those consensus algorithms to cooperate.
This improves the maximal security and decentralization of the network, whilst also providing a foundation for scalability.

[^ut-consensus-method]: Whether *Ultra Terminum* is a consensus \emph{method} or not is somewhat unclear.
On the one hand: a new combination of methods is still a method.
On the other hand: UT provides a way to modify other consensus methods via the fork rule, and UT doesn't provide a way to run a *single* blockchain.
This is why I introduced it as a cross-chain consensus *strategy*.

UT is capable of supporting millions of transactions per second with similar chain parameters (like block size) to those of traditional blockchains (like Bitcoin or Eth1).

At the core of *Ultra Terminum* is a new method for sharing security: *Proof of Reflection*.
This technique (which works in conjunction with PoW, PoS, etc) allows the incremental construction of complex blockchain networks with powerful scaling properties.
*Proof of Reflection* is how *Ultra Terminum* (excluding nested chains) scales with order $O(c^2)$, and is the basis for unbounded $O(n)$ scaling.
UT's higher-order scaling configurations, $O(c^3)$ and $O(c^4)$, require dapp-chains: chains that are application-specific and which inherit security properties from the foundational structure.

As UT is primarily a method of *structuring* a blockchain network, the scalability configurations mentioned herein *do not include **layer 2** methods*.
That means that *layer 2* techniques (e.g., state/payment channels, ZK/optimistic rollups) can be implemented *on top* of UT.

UT's novel structure means that confirmation times within UT are of order $O(c^{-1})$ (i.e., the confirmation rate is $O(c)$).
This means that, as the network grows and $c$ increases, confirmation times in UT will approach 0.
This is an improvement over existing architectures, which are, ideally and at best, $O(1)$.


%% END ### RELEASE
