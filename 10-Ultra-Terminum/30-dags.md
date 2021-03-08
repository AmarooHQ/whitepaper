## PoW: Some Problems and Solutions

I'll briefly talk about some problems and solutions with Satoshi's proof of work method. Descendants of these ideas have been used somewhat sporadically by newer blockchains (e.g. Ethereum 1 integrated GHOST).

- selfish mining / block withholding
- ghost
- incompatible histories

### Wasted Work

**todo mb**

## DAGs

Satoshi chains (like Bitcoin) are made of blocks with a single parent. Although the *canonical* history of the chain is the *heaviest* branch, other branches do exist, though, those other branches are typically abandoned quickly (and are known as *stale*, though sometimes incorrectly referred to as *orphaned*). Thus, Satoshi chains are trees. They are also, technically, DAGs; though they don't include any DAG-specific features. *Generally* speaking, blockchains follow this method.

A notable exception to this generalization -- that still fits within a narrow, tree-like interpretation of a blockchain -- is GHOST and its most famous implementation: Ethereum. GHOST allows for additional back-references (called *uncles*) though uncle blocks never become canonicalized. Rather, they are included for the additional proofs of work alone. Chains using GHOST still use *only* the chain of parents -- from the head to the genesis block -- as their source of canonical transactions and state.

This section is concerned with more radical DAG based economic data structures.

**todo - review**

### The Quanta DAG (aka T.E.T.O.)

**With thanks and appreciation to Paul Firth, who wrote a draft paper about this under the title T.E.T.O. (Trustless Eventual Total Order) in 2016.**

features:

- dag
- 2 parents
- includes conflicts/doublespend attempts
- ordered

earliest public dag-chain work mb (in the world) - august 2014: https://github.com/XertroV/quanta-test/tree/ba598d5fe89d3b16db07533957a2080edb19a9cd
https://cointelegraph.com/news/true-democracy-worlds-first-political-app-blockchain-party-launches-in-australia

**todo**

### Generalizing to N parents

**todo**
