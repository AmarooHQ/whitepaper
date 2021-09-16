\newpage

# Notation {-}
\fancypagestyle{notation}{%
    \fancyhead[R]{Notation}
}

\thispagestyle{notation}

%% ### TABLE: notation

| Term                | Definition                                                          | Unit of measurement |
| ------------------- | ------------------------------------------------------------------- | ------------------- |
| $k$                 | Raw per-chain throughput                                            | bytes/second        |
| $k_i$               | Raw per-chain throughput of chain at $i^{th}$ level of nesting      | bytes/second        |
| $T_i$               | Network throughput at $i^{th}$ level of nesting                     | TPS                 |
| $N_i$               | Number of chains at nesting level $i$                               | chain count         |
| $B_{max}$           | Maximum block size                                                  | bytes               |
| $B_f$               | Block frequency                                                     | Hz or $s^{-1}$      |
| $B_h$               | Block header size                                                   | bytes               |
| $D_f$               | Dapp-chain header frequency                                         | Hz or $s^{-1}$      |
| $D_h$               | Dapp-chain header size                                              | bytes               |
| $S$                 | Raw size of blockchain storage requirement                          | bytes               |
| $\Delta S$          | Network bandwidth requirements to acquire $d$ seconds of chain data | bytes/second        |
| $\UT{1}$            | $O(c^2)$ scaling strategy in UT (nested chain)                      |                     |
| $\UT{2}$            | $O(c^3)$ scaling strategy in UT (nested dapp chains)                |                     |
| $\UT{3}$            | $O(C^4)$ scaling strategy in UT (nested dapp-dapp chains)           |                     |
| $\UTinf{1}$         | Tiling of $\UT{1}$                                                  |                     |
| $\UTinf{2}$         | Tiling of $\UT{2}$                                                  |                     |
| $\UTinf{3}$         | Tiling of $\UT{3}$                                                  |                     |
| $+$HOT              | Includes header omission and truncation                             |                     |
| $+$HO               | Includes header omission only                                       |                     |
| $+$PoRs             | Includes Proof-of-Reflections                                       |                     |
| $\mathbb{C}^\prime$ | Rate of confirmations                                               |                     |

: Notation used throughout the paper. \label{table:notation}