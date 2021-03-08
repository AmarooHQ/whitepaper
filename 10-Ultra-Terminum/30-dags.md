## PoW: Some Problems and Solutions

I'll briefly talk about some problems and solutions with Satoshi's proof of work method. Descendants of these ideas have been used somewhat sporadically by newer blockchains (e.g. Ethereum 1 integrated GHOST).

- selfish mining / block withholding
- ghost
- incompatible histories

### Wasted Work

**todo mb**

## DAGs

Satoshi chains (like Bitcoin) are made of blocks with a single parent. Although the *canonical* history of the chain is the *heaviest* branch, other branches do exist. Though, those other branches are typically abandoned quickly (and are known as *stale*, though sometimes incorrectly referred to as *orphaned*). Thus, Satoshi chains are trees. They are also, technically, DAGs; though they don't include any DAG-specific features. *Generally* speaking, blockchains follow this method.

A notable exception to this generalization -- that still fits within a narrow, tree-like interpretation of a blockchain -- is GHOST and its most famous implementation: Ethereum. GHOST allows for additional back-references (called *uncles*); though uncle blocks never become canonicalized. Rather, they are included for the additional proofs of work alone. Chains using GHOST still use *only* the chain of parents -- from the head to the genesis block -- as their source of canonical transactions and state.

This section is concerned with more radical DAG based economic data structures.

**todo - review**

### The Quanta DAG (aka T.E.T.O.)

**With thanks and appreciation to Paul Firth, who wrote a draft paper about this under the title T.E.T.O. (Trustless Eventual Total Order) in 2016.**

\todo[inline]{idk about this acknowledgement; depends how much we use stuff he built on / formalized}

features:

- dag
- 2 parents (we generalize this in a moment)
- includes conflicts/doublespend attempts
- ordered

earliest public dag-chain work mb (in the world) - august 2014: https://github.com/XertroV/quanta-test/tree/ba598d5fe89d3b16db07533957a2080edb19a9cd
https://cointelegraph.com/news/true-democracy-worlds-first-political-app-blockchain-party-launches-in-australia

\todo[inline]{idk if we include that bit of info anywhere; feels a bit ott}

**todo**

### Generalizing to N parents

\todo[inline]{this is trivial via a demonstration with virtual nodes. if you have N parents then you can take the first as the 'real' parent, and then have a virtual uncle with the 2..Nth parents; do this to completion and you have a DAG where each node has 1 or 2 parents (except the genesis block) and you can order with the existing alg. as it turns out, this is trivial to add to the existing alg without virtual blocks; the point of virtual blocks is simply to demonstrate the transitive nature of properties between a 2-parent DAG and an N-parent DAG.}

**todo**
