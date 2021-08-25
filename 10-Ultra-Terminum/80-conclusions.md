# Conclusions

## Answering *Buterin's Trilemma*

\todo{write out some explanation of how B.T. is answered.}

\begin{figure}[H]
\centering
\includegraphics[max width=\linewidth]{trilemma/conflict_resolution_sag}
\caption{A solution to the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict-solved}
\end{figure}

| $k$, $D_f$, $D_h$              | Network              | Scaling Factor | TPS per base-chain | Network-wide TPS |
|--------|--------|---------|---|---|
| $3000, \nicefrac{1}{600}, 80$  | Bitcoin              | 1              | 12                 | 12               |
| $3000, \nicefrac{1}{20}, 1070$ | Cardano              | 56             | 673                | 673              |
| $3000, \nicefrac{1}{6}, 288$   | Polkadot             | 62             | 750                | 750              |
| $3000, \nicefrac{1}{12}, 200$  | Eth2                 | 180            | 2,160              | 2,160            |
| $3000, \nicefrac{1}{15}, 112$  | UT                   | 201            | 2,411              | 484,295          |
| $3000, \nicefrac{1}{15}, 112$  | UT (w/ tiling)       | 201            | 2,411              | $\infty$         |
| $3000, \nicefrac{1}{600}, 80$  | Bitcoin (w/ extras)  | 1              | 12                 | 12               |
| $3000, \nicefrac{1}{20}, 2094$ | Cardano (w/ extras)  | 29             | 344                | 344              |
| $3000, \nicefrac{1}{6}, 1312$  | Polkadot (w/ extras) | 14             | 165                | 165              |
| $3000, \nicefrac{1}{12}, 3460$ | Eth2 (w/ extras)     | 10             | 125                | 125              |
| $3000, \nicefrac{1}{15}, 331$  | UT_PoRs              | 215            | 2,586              | 175,841          |
| $3000, \nicefrac{1}{15}, 112$  | UT_PoRs (w/ tiling)  | 215            | 2,586              | $\infty$         |

: A comparison between various networks of quantitative scaling properties. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$. "TPS per base-chain" is a measure of the efficacy of sharding-esq schemes. "Scaling Factor" is the number of child-chains per nesting-level (e.g., number of shards, number of dapp-chains per base-chain, etc).
