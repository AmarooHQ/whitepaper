# Conclusions

\label{sec:conclusions}

## Answering *Buterin's Trilemma*

\todo{write out some explanation of how B.T. is answered.}

\begin{figure}[H]
\centering
\includegraphics[max width=\linewidth]{trilemma/conflict_resolution_sag}
\caption{A solution to the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict-solved}
\end{figure}

### Comparison: ``The Big 4''

Note: the following comparisons are indented to be an *apples to apples* between UT variants and ``The Big 4'': Bitcoin, Cardano, Eth2, and Polkadot. Cardano is an exception, here, as the Cardano and IOHK teams have been pursuing \emph{Layer 2} scalability solutions based on EUTXOs and Hydra. Their work is impressive, valuable, and good. I'm very excited to see their progress and I applaud their efforts. I mention this particularly because the nature of an *apples to apples* comparison casts Cardano in a light that some might consider to be misleading. However, these comparisons do not consider \emph{Layer 2} scalability solutions for one very simple reason: all networks can implement them in some fashion. It is not a fair (or accurate) comparison *of blockchain architecture* if \emph{Layer 2} scaling solutions are considered for some networks and not for others. Additionally, as mentioned in [Ethereum's *Sharding FAQs*](https://eth.wiki/sharding/Sharding-FAQs#how-does-plasma-state-channels-and-other-layer-2-technologies-fit-into-the-trilemma), payment- and state-channels provide a *constant factor* increase in throughput, so those techniques will not improve a network's scaling complexity.

Additionally, a network named *Opt.Shard* is included. This is a theoretical network (standing for ``Optimal Sharding'') which uses the best parameters possible among UT configurations. No real-world sharded network has come close to this level of performance.

\defineTerm{Base-chain}{A chain that has no parent-chains; i.e., is at the base nesting level}

\defineTerm{Scaling Factor}{For a given $k$, it is both the factor by which TPS increases with an additional nesting level. In effect, it allows for comparison of the efficacy of scaling schemes when $k$ is fixed. For some designs, the \emph{Scaling Factor} can change between nesting levels}

%% INSERT ### TABLE: compare_nets_3k

: A comparison of quantitative scaling properties between UT and various networks given $k = 3000$ bytes/s. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$.

%% INSERT ### TABLE: compare_nets_30k

: Similar to the previous table, but with $k = 30$ KB/s instead of 3 KB/s.

%% INSERT ### TABLE: comparison_1m_tps

: A comparison of computational requirements (approximated by $k$) for 1 million TPS between UT and various other networks. UT's equivalent TPS is also provided (for the $O(c^3)$ configuration of UT given identical parameters).

%% INSERT ### TABLE: comparison_1gbps

: A comparison of various networks' $k$ and TPS given a maximum network-wide throughput of 1 Gb/s ($\sim1.3\times 10^8$ B/s). Also included is the rate at which chains on that network grow in size (which is proportional to $k$).

\todo{make sure these tables aren't split over pages (they're short enough that we don't need to)}

\todo{write something about 'apples to apples' and why UT is $O(c^3)$ and the others are $O(c^2)$ (except bitcoin) + the exclusion of any easily replicable tech (like more layers of nesting, payment channels, etc)}

Why go to the effort of these comparisons (besides so that we have the numbers are at hand)?
