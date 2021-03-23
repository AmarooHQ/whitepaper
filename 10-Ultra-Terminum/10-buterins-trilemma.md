# Buterin's Trilemma

The trilemma is as follows:

For some magnitude of computational resources (computation, bandwidth, storage, etc), *c*, and magnitude of the network (transaction throughput, state size, market cap, etc), *n*, it is claimed that blockchain systems have at most 2 of these 3 properties:

* Decentralization --- the system can operate with participants that have only $O(c)$ resources (e.g. a laptop, a raspberry pi, a VPS, etc).
* Security --- the system is secure against attackers with up to $O(n)$ resources.
* Scalability --- the system can process $O(n)$ transactions with $O(n) > O(c)$; this means that, as the network grows, the throughput of the system grows faster than the computational resources required per user.

## Core Conflict

\autoref{fig:trilemma-core-conflict} shows a cloud for the core conflict.

\begin{figure}
\centering
\begin{BVerbatim}
              stay               shard +
        /---> decentralized ---> small blocks
       /
we need scale                    (**conflict**)
       \
        \---> stay ------------> no shards +
              secure             big blocks
\end{BVerbatim}
\caption{A cloud of the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict}
\end{figure}

To break the core conflict we need to look at the underlying assumptions.

Buterin writes in the Ethereum sharding FAQ regarding the *shard + small blocks* strategy:

> This greatly increases throughput, but at a cost of security: an N-factor increase in throughput using this method necessarily comes with an N-factor decrease in security, as a level of resources $1/N$ the size of the whole ecosystem will be sufficient to attack any individual chain.

He writes, regarding the *no shards + big blocks* strategy:

> ... such an approach inevitably has its limits: if one goes too far, then nodes running on consumer hardware will drop out, the network will start to rely exclusively on a very small number of supercomputers running the blockchain, which can lead to great centralization risk.

A mistaken way to break the conflict is *merged mining* (aka AuxPoW). This method attempts to share security between chains, so that one might be able to have security + merged shards (aka side-chains) + small blocks. Buterin writes:

> If all miners participate, this theoretically can increase throughput by a factor of N without compromising security. However, this also has the problem that it increases the computational and storage load on each miner by a factor of N, and so in fact this solution is simply a stealthy form of block size increase.

\autoref{fig:trilemma-mm-conflict} shows the cloud for the merged mining conflict.

\begin{figure}
\centering
\begin{BVerbatim}
               users have       users don't need
         /---> less burden ---> super computers
        /
       /                        (**conflict**:
add MM blockchains               decentralization implies
       \                         that users ~ miners)
        \
         \---> miners keep ---> miners need
               all chains       super computers
\end{BVerbatim}
\caption{A cloud showing the scaling conflict of \textit{merged mining}.}
\label{fig:trilemma-mm-conflict}
\end{figure}

An underlying assumption here is that maximally sharing security across the network requires miners to maintain a record of all chains and do validation on all those chains. The naive solution (sharding, mentioned above) gets us back to the start. It seems like progress is impossible.

We have some hints to conditions that might belong to a *silver bullet* solution:

* We can share security with shards and small blocks.
* We can share security without miners keeping and validating all chains.

**This is the crux of the problem: how do you construct a sharded blockchain (scalable) such that attacking a shard is about as difficult as attacking the full network (secure), whilst ensuring that the security of the network does not require validating all shards (decentralized)?**

## Assumptions

Here are some additional underlying assumptions that are either common or which I expect to be common:

* Sharing PoW requires merged mining.
* Sharing PoW security requires that chains use the same hashing algorithm.
* Simultaneously securing a network with PoW and PoS is not possible without compromises (like that PoW miners could DOS PoS miners or vice versa).
* It is unsafe for PoW miners to build on unvalidated histories (as is done with SPV mining, which *is* unsafe).

These assumptions *are* true in lots of cases (arguably in all cases up to now). Do they need to be?

NB: I call them *assumptions*; some people will likely (and rightly) take issue with that and call them *conclusions* instead. For our purposes there isn't really a difference; I include them here so that I can later show you under which conditions they are all false.
