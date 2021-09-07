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

### Comparison with 'the big 4'

\todo{experiment with inverting comparisons to UT (like with Solana table). instead of \emph{UT out-scales by $1000\times$}, it'd be like \emph{Network X vs UT X: $10^{-3}\times$}.}

\defineTerm{Base-chain}{A chain that has no parent-chains; i.e., is at the base nesting level}

\defineTerm{Scaling Factor}{For a given $k$, it is both the number of child-chains that a parent-chain can support, and the factor by which TPS increases with an additional nesting level. In effect, it allows for comparison of the efficacy of scaling schemes when $k$ is fixed. For some designs, the \emph{Scaling Factor} can change between nesting levels.}

| $k$, $B_f$, $B_h$              | Network      | Scaling Factor | TPS per base-chain | Network-wide TPS | TPS vs \newline UT $O(c^3)$           |
|------|------|-------|-----|-------|-------|
| $3000, \nicefrac{1}{600}, 80$  | Bitcoin      | 1              | 12                 | 12               | $(2.48\times 10^{-5})\times$ |
| $3000, \nicefrac{1}{20}, 1070$ | Cardano      | 56             | 673                | 673              | $(1.39\times 10^{-3})\times$ |
| $3000, \nicefrac{1}{6}, 288$   | Polkadot     | 62             | 750                | 750              | $(1.55\times 10^{-3})\times$ |
| $3000, \nicefrac{1}{12}, 200$  | Eth2         | 180            | 2,160              | 2,160            | $(4.46\times 10^{-3})\times$ |
| $3000, \nicefrac{1}{15}, 112$  | UT+PoRs      | 215            | 2,586              | 175,841          | $(3.63\times 10^{-1})\times$ |
| $3000, \nicefrac{1}{15}, 112$  | UT           | 201            | 2,411              | 484,295          | $(1)\times$                  |
| $3000, \nicefrac{1}{15}, 112$  | UT w/ tiling | 201            | 2,411              | $\infty$         | $(\infty)\times$                  |

: A comparison of quantitative scaling properties between UT and various networks given $k = 3000$ bytes/s. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$.

| $k$, $B_f$, $B_h$               | Network      | Scaling Factor | TPS per base-chain | Network-wide TPS    | TPS vs \newline UT $O(c^3)$           |
|------|------|------|-----|-------|-------|
| $30000, \nicefrac{1}{600}, 80$  | Bitcoin      | 1              | 120                | 120                 | $(2.48\times 10^{-7})\times$ |
| $30000, \nicefrac{1}{20}, 1070$ | Cardano      | 561            | 67,290             | 67,290              | $(1.39\times 10^{-4})\times$ |
| $30000, \nicefrac{1}{6}, 288$   | Polkadot     | 625            | 75,000             | 75,000              | $(1.55\times 10^{-4})\times$ |
| $30000, \nicefrac{1}{12}, 200$  | Eth2         | 1,800          | 216,000            | 216,000             | $(4.46\times 10^{-4})\times$ |
| $30000, \nicefrac{1}{15}, 112$  | UT+PoRs      | 2,121          | 254,571            | $1.35\times 10^{8}$ | $(2.78\times 10^{-1})\times$ |
| $30000, \nicefrac{1}{15}, 112$  | UT           | 2,009          | 241,071            | $4.84\times 10^{8}$ | $(1)\times$                  |
| $30000, \nicefrac{1}{15}, 112$  | UT w/ tiling | 2,009          | 241,071            | $\infty$            | $(\infty)\times$                  |

: Similar to the previous table, but with $k = 30$ KB/s instead of 3 KB/s.

| $k$, $B_f$, $B_h$                  | Network  | TPS per base-chain  | Network-wide TPS    | $k$ vs UT $O(c^3)$           | Equivalent UT $O(c^3)$ TPS |
|------|---|----|-----|-----|-----|
| $250000000, \nicefrac{1}{600}, 80$ | Bitcoin  | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(1.53\times 10^{-5})\times$ | $8.79\times 10^{23}$       |
| $115700, \nicefrac{1}{20}, 1070$   | Cardano  | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(3.31\times 10^{-2})\times$ | $5.41\times 10^{8}$        |
| $109810, \nicefrac{1}{6}, 288$     | Polkadot | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(3.48\times 10^{-2})\times$ | $5.75\times 10^{8}$        |
| $64600, \nicefrac{1}{12}, 200$     | Eth2     | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(5.92\times 10^{-2})\times$ | $9.71\times 10^{8}$        |
| $5501, \nicefrac{1}{15}, 112$      | UT+PoRs  | 8,658               | $1.00\times 10^{6}$ | $(6.96\times 10^{-1})\times$ | $2.99\times 10^{6}$        |
| $3826, \nicefrac{1}{15}, 112$      | UT       | 3,921               | $1.00\times 10^{6}$ | $(1)\times$                  | $1.00\times 10^{6}$        |

: A comparison of computational requirements (approximated by $k$) for 1 million TPS between UT and various other networks. UT's equivalent TPS is also provided (for the $O(c^3)$ configuration of UT given identical parameters).

| $\Delta S$, $B_f$, $B_h$, Tx (B)                 | Network     | TPS     | $k$ (B/s)           | MB/chain/day        |
|------|---|---|---|----|
| $1.34\times 10^{8}, 2.0, 200, 250$               | Solana      | 536,871 | $1.34\times 10^{8}$ | $1.11\times 10^{7}$ |
| $1.34\times 10^{8}, \nicefrac{1}{600}, 80, 250$  | Bitcoin     | 536,871 | $1.34\times 10^{8}$ | $1.11\times 10^{7}$ |
| $1.34\times 10^{8}, \nicefrac{1}{20}, 1070, 250$ | Cardano     | 536,862 | 84,738              | 6,982               |
| $1.34\times 10^{8}, \nicefrac{1}{6}, 288, 250$   | Polkadot    | 536,859 | 80,264              | 6,614               |
| $1.34\times 10^{8}, \nicefrac{1}{12}, 200, 250$  | Eth2        | 536,859 | 47,296              | 3,897               |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 112, 250$  | UT $O(c^2)$ | 268,428 | 44,769              | 3,689               |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 112, 250$  | UT $O(c^3)$ | 536,428 | 3,104               | 256                 |

: A comparison of various networks' $k$ and TPS given a maximum network-wide throughput of 1 Gb/s ($\sim1.3\times 10^8$ B/s). Also included is the rate at which chains on that network grow in size (which is proportional to $k$).

\todo{make sure these tables aren't split over pages (they're short enough that we don't need to)}

\todo{write something about 'apples to apples' and why UT is $O(c^3)$ and the others are $O(c^2)$ (except bitcoin) + the exclusion of any easily replicable tech (like more layers of nesting, payment channels, etc)}

Why go to the effort of these comparisons (besides so that we have the numbers are at hand)?
