# Conclusions

## Answering *Buterin's Trilemma*

\todo{write out some explanation of how B.T. is answered.}

\begin{figure}[H]
\centering
\includegraphics[max width=\linewidth]{trilemma/conflict_resolution_sag}
\caption{A solution to the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict-solved}
\end{figure}

### Comparison with 'the big 4'

\defineTerm{Base-chain}{A chain that has no parent-chains; i.e., is at the base nesting level}

\defineTerm{Scaling Factor}{For a given $k$, it is both the number of child-chains that a parent-chain can support, and the factor by which TPS increases with an additional nesting level. In effect, it allows for comparison of the efficacy of scaling schemes when $k$ is fixed. For some designs, the \emph{Scaling Factor} can change between nesting levels.}

| $k$, $D_f$, $D_h$              | Network      | Scaling Factor | TPS per base-chain | Network-wide TPS | UT TPS out-scales by |
|------|------|-------|-----|-------|------|
| $3000, \nicefrac{1}{600}, 80$  | Bitcoin      | 1              | 12                 | 12               | $(40,358)\times$     |
| $3000, \nicefrac{1}{20}, 1070$ | Cardano      | 56             | 673                | 673              | $(720)\times$        |
| $3000, \nicefrac{1}{6}, 288$   | Polkadot     | 62             | 750                | 750              | $(646)\times$        |
| $3000, \nicefrac{1}{12}, 200$  | Eth2         | 180            | 2,160              | 2,160            | $(224)\times$        |
| $3000, \nicefrac{1}{15}, 112$  | UT+PoRs      | 215            | 2,586              | 175,841          | $(3)\times$          |
| $3000, \nicefrac{1}{15}, 112$  | UT           | 201            | 2,411              | 484,295          | $(1)\times$          |
| $3000, \nicefrac{1}{15}, 112$  | UT w/ tiling | 201            | 2,411              | $\infty$         | $0.0\times$          |

: A comparison of quantitative scaling properties between UT and various networks given $k = 3000$ bytes/s. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$.

| $k$, $D_f$, $D_h$               | Network      | Scaling Factor | TPS per base-chain | Network-wide TPS    | UT TPS out-scales by        |
|------|------|-------|-----|-------|------|
| $30000, \nicefrac{1}{600}, 80$  | Bitcoin      | 1              | 120                | 120                 | $(4.04\times 10^{6})\times$ |
| $30000, \nicefrac{1}{20}, 1070$ | Cardano      | 561            | 67,290             | 67,290              | $(7,197)\times$             |
| $30000, \nicefrac{1}{6}, 288$   | Polkadot     | 625            | 75,000             | 75,000              | $(6,457)\times$             |
| $30000, \nicefrac{1}{12}, 200$  | Eth2         | 1,800          | 216,000            | 216,000             | $(2,242)\times$             |
| $30000, \nicefrac{1}{15}, 112$  | UT+PoRs      | 2,121          | 254,571            | $1.35\times 10^{8}$ | $(4)\times$                 |
| $30000, \nicefrac{1}{15}, 112$  | UT           | 2,009          | 241,071            | $4.84\times 10^{8}$ | $(1)\times$                 |
| $30000, \nicefrac{1}{15}, 112$  | UT w/ tiling | 2,009          | 241,071            | $\infty$            | $0.0\times$                 |

: Similar to the previous table, but with $k = 30$ KB/s instead of 3 KB/s.

| $k$, $B_f$, $B_h$                  | Network  | Scaling Factor | TPS per base-chain  | Network-wide TPS    | UT $k$ out-scales by |
|------|---|---|----|-----|----|
| $250000000, \nicefrac{1}{600}, 80$ | Bitcoin  | 1              | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(65,342)\times$     |
| $115700, \nicefrac{1}{20}, 1070$   | Cardano  | 2,163          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(30)\times$         |
| $109810, \nicefrac{1}{6}, 288$     | Polkadot | 2,288          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(29)\times$         |
| $64600, \nicefrac{1}{12}, 200$     | Eth2     | 3,876          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | $(17)\times$         |
| $5501, \nicefrac{1}{15}, 112$      | UT+PoRs  | 393            | 8,658               | $1.00\times 10^{6}$ | $(1)\times$          |
| $3826, \nicefrac{1}{15}, 112$      | UT       | 256            | 3,921               | $1.00\times 10^{6}$ | $(1)\times$          |

: A comparison of computational requirements (approximated by $k$) for 1 million TPS between UT and various other networks. Note: \emph{Scaling Factor} has a different (incomparable) meaning here, as it is dependant on $k$ which is not fixed. It is included for the sake of consistency between these tables.

| $\Delta S$, $B_f$, $B_h$, Tx (B)                | Network     | $k_1$               | TPS     | $\nicefrac{\text{TPS}}{k_1}$ vs UT |
|------|---|---|---|----|
| $1.34\times 10^{8}, 2.0, 200, 200$              | Solana      | $1.34\times 10^{8}$ | 671,089 | $(8.34\times 10^{-4})\times$       |
| $1.34\times 10^{8}, \nicefrac{1}{15}, 112, 250$ | UT $O(c^2)$ | 44,769              | 268,428 | $(1)\times$                        |

: A comparison of various networks' $k_1$ and TPS given a maximum network throughput of 1 Gb/s ($\sim1.3\times 10^8$ B/s), and a direct comparison between the resultant TPS efficiency (against $k_1$) and that of UT's $O(c^2)$ configuration.

\todo{make sure these tables aren't split over pages (they're short enough that we don't need to)}

\todo{write something about 'apples to apples' and why UT is $O(c^3)$ and the others are $O(c^2)$ (except bitcoin) + the exclusion of any easily replicable tech (like more layers of nesting, payment channels, etc)}

Why go to the effort of these comparisons (besides so that the numbers are at hand)?
