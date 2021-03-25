## Mixing Proof Methods

\todo[inline]{Mixing PoW with PoS (etc) in the simplex itself}

* e.g. have some PoS simplex chains, or PoSpace (if proofs are efficient), or PoWhatever.

### The security of dapp-chains compared to pure PoS chains

\todo[inline]{Write this section out}

comment: I posted this to forum last night:

> one thing I can't forget to put in the WP:
>
> dapp-chains via UT aren't *less* secure than their equivalent standalone blockchains. (e.g. eth2, parity, etc). The idea for dapp-chains in UT is to make them transactions on the simplex-chains. A PoS blockchain, is **in essence**, equivalent in security to *zero-confirmation* transactions via UT. That's because, if they're not confirmed, then they form a *transaction-chain* that has all the same properties as the PoS methods used by said blockchains!
>
> So, that means that adding UT underneath can only *add* **or** *do nothing* for the security of PoS dapp-chains, but it can't *weaken* it (if it's well designed).
>
> Since those dapp-chains would, in other circumstances, be called *Layer 1* chains, is it fair to call them *Layer 2* under UT? Mb it's better to call UT a new type of layer: *Layer 0*, so that dapp-chains (which are the vast majority of UT chains) are comparable to their pure-PoS counterparts.

some thoughts on this now:

* I suspect the Layer 1/2 discussion is just flawed. like it makes sense for payment-channels sorta stuff, but not if you're 'layering' blockchains (like, hanging a blockchain off another blockchain) -- mb 'nesting' is a better term.
* If the idea of *Layer X* is okay, then something like *PoW: layer 0, PoS: layer 1* makes sense. But you still end up with questions like: *What layer is a PoS chain that's nested 1 level deep?*
* I suspect that security is transitive, which makes some sense. Like if transactions are secured by a chain, and have security measurements that are consistent with the security of the chain itself, then how does security get worse through nesting?
