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

\defineTerm{Scaling Factor}{The factor by which TPS increases with additional nesting layers for a given $k$}

| $k$, $D_f$, $D_h$              | Network        | Scaling Factor | TPS per base-chain | Network-wide TPS | UT TPS out-scales by |
|------|------|-------|---|---|---|
| $3000, \nicefrac{1}{600}, 80$  | Bitcoin        | 1              | 12                 | 12               | 40357x               |
| $3000, 2.5, 141$               | Solana         | 9              | 102                | 102              | 4742x                |
| $3000, \nicefrac{1}{20}, 1070$ | Cardano        | 56             | 673                | 673              | 719x                 |
| $3000, \nicefrac{1}{6}, 288$   | Polkadot       | 62             | 750                | 750              | 645x                 |
| $3000, \nicefrac{1}{12}, 200$  | Eth2           | 180            | 2,160              | 2,160            | 224x                 |
| $3000, \nicefrac{1}{15}, 112$  | UT+PoRs        | 215            | 2,586              | 175,841          | 2x                   |
| $3000, \nicefrac{1}{15}, 112$  | UT             | 201            | 2,411              | 484,295          | 1x                   |
| $3000, \nicefrac{1}{15}, 112$  | UT (w/ tiling) | 201            | 2,411              | $\infty$         | 0x                   |

: A comparison of quantitative scaling properties between UT and various networks. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$. "TPS per base-chain" is a measure of the efficacy of sharding-esq schemes. "Scaling Factor" is the number of child-chains per nesting-level (e.g., number of shards, number of dapp-chains per base-chain, etc).

| $k$, $D_f$, $D_h$               | Network        | Scaling Factor | TPS per base-chain | Network-wide TPS    | UT TPS out-scales by |
|------|------|-------|---|---|---|
| $30000, \nicefrac{1}{600}, 80$  | Bitcoin        | 1              | 120                | 120                 | 4035794x             |
| $30000, 2.5, 141$               | Solana         | 85             | 10,213             | 10,213              | 47420x               |
| $30000, \nicefrac{1}{20}, 1070$ | Cardano        | 561            | 67,290             | 67,290              | 7197x                |
| $30000, \nicefrac{1}{6}, 288$   | Polkadot       | 625            | 75,000             | 75,000              | 6457x                |
| $30000, \nicefrac{1}{12}, 200$  | Eth2           | 1,800          | 216,000            | 216,000             | 2242x                |
| $30000, \nicefrac{1}{15}, 112$  | UT+PoRs        | 2,121          | 254,571            | $1.35\times 10^{8}$ | 3x                   |
| $30000, \nicefrac{1}{15}, 112$  | UT             | 2,009          | 241,071            | $4.84\times 10^{8}$ | 1x                   |
| $30000, \nicefrac{1}{15}, 112$  | UT (w/ tiling) | 2,009          | 241,071            | $\infty$            | 0x                   |

: Similar to the previous table, but with $k = 30$ KB/s instead of 3 KB/s.

| $k$, $B_f$, $B_h$                | Network  | Scaling Factor | TPS per base-chain  | Network-wide TPS    | UT $k$ out-scales by |
|------|------|-------|---|---|---|
| $296900, 2.5, 141$               | Solana   | 842            | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | 77x                  |
| $115700, \nicefrac{1}{20}, 1070$ | Cardano  | 2,163          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | 30x                  |
| $109810, \nicefrac{1}{6}, 288$   | Polkadot | 2,288          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | 28x                  |
| $64600, \nicefrac{1}{12}, 200$   | Eth2     | 3,876          | $1.00\times 10^{6}$ | $1.00\times 10^{6}$ | 16x                  |
| $3826, \nicefrac{1}{15}, 112$    | UT       | 256            | 3,921               | $1.00\times 10^{6}$ | 1x                   |

: A comparison of computational requirements (approximated by $k$) for 1 million TPS between UT and various other networks.

\todo{write something about 'apples to apples' and why UT is $O(c^3)$ and the others are $O(c^2)$ (except bitcoin) + the exclusion of any easily replicable tech (like more layers of nesting, payment channels, etc)}
