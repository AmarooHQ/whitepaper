%% BEGIN ### RELEASE

%% \newpage

\begin{comment}
keep toc to d=1 for this section --- reduces ToC page size. default is d=3
\end{comment}

\addtocontents{toc}{\protect\setcounter{tocdepth}{1}}

# Buterin's Trilemma

\href{\citeShardingFAQsLink}{The trilemma} is as follows:

For some magnitude of computational resources available to each node (computation, bandwidth, storage, etc), $c$, and abstract magnitude of the network (transaction throughput, state size, user population, market cap, etc), $n$, it is claimed that blockchain systems have, at most, two of these three properties:

* Decentralization --- the system can operate with participants that have only $O(c)$ resources (e.g., a laptop, a raspberry pi, a VPS; typical internet bandwidth, storage space, etc).
* Security --- the system is secure against attackers with up to $O(n)$ resources.
* Scalability --- the system can process $O(n)$ transactions with $O(n) > O(c)$; this means that, as the network grows, the throughput of the system grows faster than the computational resources required per user.

The definition of scalability is perhaps problematic.
If the network, which is $O(n)$, becomes bottlenecked by an $O(c^2)$ scaling method, is the network really scalable?
I prefer an alternative definition of scalability: the system can process $O(n)$ transactions in $O(1)$ time, i.e., getting a transaction confirmed is neither more expensive nor delayed as $n$ and/or $c$ change.\footnote{
    This does not mean there is no fee market for transactions, nor that localized congestion will not happen.
    Rather, we are interested in an equilibrium that provides substantial value and capacity whilst avoiding transactions being as free as sending an email.
}

Why mention $O(c^2)$ scaling particularly?
Why is that an important breakpoint for scaling configurations?
In a word: sharding.
The standard method of sharding (or hosting child-chains generally) is to replace transactions with shard-headers in the host-chain.
Extra data might also be required.
If the host-chain has $O(c)$ capacity, then it should support\footnote{
    Presuming a secure method of sharding is known and in use, and $O(1)$ load per shard-header.
} $O(c)$ shards.
Each shard has $O(c)$ capacity also, thus the full system has $O(c^2)$ capacity.

## Core Conflict

\label{sec:core-conflict}

\begin{figure}
\centering
\includegraphics[max width=\linewidth]{trilemma/core_conflict_sag}
\caption{A cloud of the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict}
\end{figure}

\autoref{fig:trilemma-core-conflict} shows a cloud\footnote{
    For more on clouds, see \href{https://www.google.com/search?q=ISBN+0-88427-115-3}{It's Not Luck} by Eli Goldratt (1994).
} for the core conflict.
It reads: *safely increasing capacity* requires that we *stay decentralized*.
*Staying decentralized* requires that we *use many chains and small blocks*.
*Safely increasing capacity* requires that the network *stays secure*.
*Staying secure* requires that we *use big blocks*.
Big blocks are the opposite of small blocks, so we have a *conflict*.
Additionally: using multiple chains compromises security; and big blocks compromise decentralization.

To understand the core conflict we need to look at the underlying assumptions.

Buterin writes\footnote{
    See \href{\citeShardingFAQsLink}{\emph{On sharding blockchains FAQs}} (this appears to have been originally written by V. Buterin).
} in the Ethereum sharding FAQ regarding the *many chains with small blocks* strategy:

> [...] This greatly increases throughput, but at a cost of security: an N-factor increase in throughput using this method necessarily comes with an N-factor decrease in security, as a level of resources 1/N the size of the whole ecosystem will be sufficient to attack any individual chain. [...]

He writes, regarding the *big blocks* strategy:

> [...] such an approach inevitably has its limits: if one goes too far, then nodes running on consumer hardware will drop out, the network will start to rely exclusively on a very small number of supercomputers running the blockchain, which can lead to great centralization risk.

A mistaken way to break the conflict is *merged mining* (aka AuxPoW). This method attempts to share security between chains, so that one might be able to have decentralization and security via small blocks and merged mined chains/shards (sometimes called side-chains). Buterin writes:

> [...] If all miners participate, this theoretically can increase throughput by a factor of N without compromising security. However, this also has the problem that it increases the computational and storage load on each miner by a factor of N, and so in fact this solution is simply a stealthy form of block size increase.

\autoref{fig:trilemma-mm-conflict} shows the cloud for the merged mining conflict.

\begin{figure}[H]
\centering
\includegraphics[max width=\linewidth]{trilemma/mm_conflict_sag}
\caption{A cloud showing the scaling conflict of \textit{merged mining}.}
\label{fig:trilemma-mm-conflict}
\end{figure}

An underlying assumption here is that maximally sharing security across the network requires miners to maintain a record of all chains and do validation on all those chains.
The naive solution (using many chains, mentioned above) conflicts with secure methods of merged mining.
It seems like progress is impossible.

We have some hints to conditions that might belong to a solution:

* We can share security between chains/shards and can use small blocks.
* We can share security without miners keeping and validating all chains/shards.

**This is the crux of the problem: how do you construct a network of blockchains (scalable) such that attacking an individual chain is about as difficult as attacking the full network (secure), whilst ensuring that the security of the network does not require validating all chains (decentralized)?**

### Prior Assumptions

Here are some prior underlying assumptions that are either common or which I expect to be:

* Sharing PoW security requires merged mining.
* Sharing PoW security requires that chains use the same hashing algorithm.
* Multiple (non-merged-mined) PoW chains using the same hashing algorithm means that at least some of those chains are vulnerable to a 51\% attack.
* Simultaneously securing a network with PoW and PoS is not possible without compromises (like that PoW miners could DoS PoS validators or vice versa).
* It is unsafe for miners/validators to build on unvalidated histories (as is done with SPV mining, which *is* unsafe).

\begin{comment}
These assumptions *are* true in lots of cases (arguably in all cases up to now).
Are they always?
\end{comment}

\aside{
    I call them \emph{assumptions}; some people will likely (and rightly) take issue with that and call them \emph{conclusions} instead.
    For our purposes there isn't really a difference; I include them here so that I can later show you conditions under which they are all simultaneously false.
}

## Conjecture: A Principle of Scaling

\label{sec:a-principle-of-scaling}

A scalable system *can* have components with complexities worse than $O(c)$ *if and only if* those components are not *bottlenecks*, i.e., *constraints*.
As long as there is *excess capacity* in those components, the system can still scale.
%%\text{(See also: \emph{Theory of Constraints}; \emph{Critical Fallibilism}.)}

\begin{comment}
end of section, reset toc to default
\end{comment}

\SetToCDepthDefault

%% END ### RELEASE
