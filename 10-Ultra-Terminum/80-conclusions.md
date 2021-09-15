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

\defineTerm{Scaling Factor}{For a given $k$, it is both the number of child-chains that a parent-chain can support, and the factor by which TPS increases with an additional nesting level. In effect, it allows for comparison of the efficacy of scaling schemes when $k$ is fixed. For some designs, the \emph{Scaling Factor} can change between nesting levels}

%% ### TABLE: compare_nets_3k

| $k$, $B_f$, $B_h$              | Network       | Scaling Factor | TPS per base-chain | Network-wide TPS    | TPS vs \newline $\UT{2}$     |
|------|------|-------|-----|-------|-------|
| $3000, \nicefrac{1}{600}, 80$  | Bitcoin       | 1              | 12                 | 12                  | $(1.39\times 10^{-5})\times$ |
| $3000, \nicefrac{1}{20}, 1070$ | Cardano       | 56             | 673                | 673                 | $(7.82\times 10^{-4})\times$ |
| $3000, \nicefrac{1}{6}, 288$   | Polkadot      | 62             | 750                | 750                 | $(8.71\times 10^{-4})\times$ |
| $3000, \nicefrac{1}{12}, 200$  | Eth2          | 180            | 2,160              | 2,160               | $(2.51\times 10^{-3})\times$ |
| $3000, \nicefrac{1}{15}, 84$   | $\UT{2+\text{PoRs}}$ | 291            | 3,486              | 254,509             | $(2.96\times 10^{-1})\times$ |
| $3000, \nicefrac{1}{15}, 84$   | $\UT{2}$      | 268            | 3,214              | 860,969             | $(1.0)\times$                |
| $3000, \nicefrac{1}{15}, 68$   | $\UT{2+\text{HOT}}$  | 331            | 3,971              | $5.58\times 10^{6}$ | $(6.49)\times$               |
| $3000, \nicefrac{1}{15}, 84$   | $\UTinf{2}$    | 268            | 3,214              | $\infty$            | $(\infty)\times$             |

: A comparison of quantitative scaling properties between UT and various networks given $k = 3000$ bytes/s. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$.

%% ### TABLE: compare_nets_30k

| $k$, $B_f$, $B_h$               | Network       | Scaling Factor | TPS per base-chain | Network-wide TPS    | TPS vs \newline $\UT{2}$     |
|------|------|------|-----|-------|-------|
| $30000, \nicefrac{1}{600}, 80$  | Bitcoin       | 1              | 120                | 120                 | $(1.39\times 10^{-7})\times$ |
| $30000, \nicefrac{1}{20}, 1070$ | Cardano       | 561            | 67,290             | 67,290              | $(7.82\times 10^{-5})\times$ |
| $30000, \nicefrac{1}{6}, 288$   | Polkadot      | 625            | 75,000             | 75,000              | $(8.71\times 10^{-5})\times$ |
| $30000, \nicefrac{1}{12}, 200$  | Eth2          | 1,800          | 216,000            | 216,000             | $(2.51\times 10^{-4})\times$ |
| $30000, \nicefrac{1}{15}, 84$   | $\UT{2+\text{PoRs}}$ | 2,834          | 340,136            | $1.91\times 10^{8}$ | $(2.22\times 10^{-1})\times$ |
| $30000, \nicefrac{1}{15}, 84$   | $\UT{2}$      | 2,679          | 321,429            | $8.61\times 10^{8}$ | $(1.0)\times$                |
| $30000, \nicefrac{1}{15}, 68$   | $\UT{2+\text{HOT}}$  | 3,309          | 397,059            | $5.58\times 10^{9}$ | $(6.49)\times$               |
| $30000, \nicefrac{1}{15}, 84$   | $\UTinf{2}$    | 2,679          | 321,429            | $\infty$            | $(\infty)\times$             |

: Similar to the previous table, but with $k = 30$ KB/s instead of 3 KB/s.

%% ### TABLE: comparison_1m_tps

| $k$, $B_f$, $B_h$                  | Network       | TPS per base-chain  | Network-wide TPS    | $k$ vs $\UT{2}$              | Equivalent $\UT{2}$ TPS |
|------|---|----|-----|-----|-----|
| $250000000, \nicefrac{1}{600}, 80$ | Bitcoin       | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(1.26\times 10^{-5})\times$ | $8.79\times 10^{23}$    |
| $115700, \nicefrac{1}{20}, 1070$   | Cardano       | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(2.73\times 10^{-2})\times$ | $5.41\times 10^{8}$     |
| $109810, \nicefrac{1}{6}, 288$     | Polkadot      | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(2.87\times 10^{-2})\times$ | $5.75\times 10^{8}$     |
| $64600, \nicefrac{1}{12}, 200$     | Eth2          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(4.88\times 10^{-2})\times$ | $9.71\times 10^{8}$     |
| $4844, \nicefrac{1}{15}, 84$       | $\UT{2+\text{PoRs}}$ | 9,041               | $1.00\times 10^{6}$ | $(6.51\times 10^{-1})\times$ | $3.62\times 10^{6}$     |
| $3154, \nicefrac{1}{15}, 84$       | $\UT{2}$      | 3,553               | $1.00\times 10^{6}$ | $(1.0)\times$                | $1.00\times 10^{6}$     |
| $1692, \nicefrac{1}{15}, 68$       | $\UT{2+\text{HOT}}$  | 1,263               | $1.00\times 10^{6}$ | $(1.86)\times$               | 235,703                 |

: A comparison of computational requirements (approximated by $k$) for 1 million TPS between UT and various other networks. UT's equivalent TPS is also provided (for the $O(c^3)$ configuration of UT given identical parameters).

%% ### TABLE: comparison_1gbps

| $\Delta S$, $B_f$, $B_h$, Tx (B)                 | Network      | TPS     | $k$ (B/s)           | MB/chain/day        |
|------|---|---|---|----|
| $1.34\times 10^{8}, 2.0, 200, 250$               | Solana       | 536,871 | $1.34\times 10^{8}$ | $1.11\times 10^{7}$ |
| $1.34\times 10^{8}, \nicefrac{1}{600}, 80, 250$  | Bitcoin      | 536,871 | $1.34\times 10^{8}$ | $1.11\times 10^{7}$ |
| $1.34\times 10^{8}, \nicefrac{1}{20}, 1070, 250$ | Cardano      | 536,862 | 84,738              | 6,982               |
| $1.34\times 10^{8}, \nicefrac{1}{6}, 288, 250$   | Polkadot     | 536,859 | 80,264              | 6,614               |
| $1.34\times 10^{8}, \nicefrac{1}{12}, 200, 250$  | Eth2         | 536,859 | 47,296              | 3,897               |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 84, 250$   | $\UT{1}$     | 268,427 | 38,771              | 3,195               |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 68, 250$   | $\UT{1+\text{HOT}}$ | 268,425 | 16,921              | 1,394               |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 84, 250$   | $\UT{2}$     | 536,871 | 2,563               | 211                 |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 68, 250$   | $\UT{2+\text{HOT}}$ | 536,431 | 1,374               | 113                 |

: A comparison of various networks' $k$ and TPS given a maximum network-wide throughput of 1 Gb/s ($\sim1.3\times 10^8$ B/s). Also included is the rate at which chains on that network grow in size (which is proportional to $k$).

\todo{make sure these tables aren't split over pages (they're short enough that we don't need to)}

\todo{write something about 'apples to apples' and why UT is $O(c^3)$ and the others are $O(c^2)$ (except bitcoin) + the exclusion of any easily replicable tech (like more layers of nesting, payment channels, etc)}

Why go to the effort of these comparisons (besides so that we have the numbers are at hand)?
