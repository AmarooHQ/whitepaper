\newpage

# Notation {-}
\fancypagestyle{notation}{%
    \fancyhead[R]{Notation}
}

\thispagestyle{notation}

%% ### TABLE: notation

| Term        | Definition                                                     | Unit of measurement |
| ----------- | -------------------------------------------------------------- | ------------------- |
| $k$         | Raw per-chain throughput                                       | bytes/second        |
| $k_i$       | Raw per-chain throughput of chain at $i^{th}$ level of nesting | bytes/second        |
| $T_i$       | Network throughput at $i^{th}$ level of nesting                | TPS                 |
| $N_i$       | Number of chains at nesting level $i$                          | chain count         |
| $B_{max}$   | Maximum block size                                             | bytes               |
| $B_f$       | Block frequency                                                | Hz or $s^{-1}$      |
| $B_h$       | Block header size                                              | bytes               |
| $D_f$       | Dapp-chain header frequency                                    | Hz or $s^{-1}$      |
| $D_h$       | Dapp-chain header size                                         | bytes               |
| $S$         | Storage requirement                                            | bytes               |
| $\Delta S$  | Bandwidth requirement for storage                              | bytes/second        |
| $\UT{1}$    |                                                                |                     |
| $\UT{2}$    |                                                                |                     |
| $\UT{3}$    |                                                                |                     |
| $\UTinf{1}$ |                                                                |                     |
| $\UTinf{2}$ |                                                                |                     |
| $\UTinf{3}$ |                                                                |                     |
| $+$HOT      | Header omission and truncation                                 |                     |
| $+$HO       | Header omission only                                           |                     |
| $+$PoRs     | Includes Proof-of-Reflections in header                        |                     |

: Notation used throughout the paper. \label{table:notation}