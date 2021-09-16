
%% comment out closing epigraph
\begin{comment}
    \newpage

    \nofancyhdr

    \vspace*{\fill}
    \setlength\epigraphwidth{.5\textwidth}
    \epigraph{
        \hspace{4pt} Gunnie looked up at the lintel and, as though she read the words there, recited, \textit{“No hope for those who enter here.”}
        \par
        \hspace{4pt} “No, no,” Apheta murmured. “Every hope.”
    }{}
    \vspace*{\fill}
\end{comment}

\newpage
\printglossaries
\newpage

# Notation {-}
\fancypagestyle{notation}{%
    \fancyhead[R]{Notation}
}

\thispagestyle{notation}

%% ### TABLE: notation

| Term                | Definition                                                                                                   | Unit                |
| ------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------- |
| $k$                 | Approximate raw per-chain throughput                                                                         | bytes/second        |
| $k_i$               | Approximate raw per-chain throughput at $i^{th}$ level of nesting                                            | bytes/second        |
| $T_i$               | Network throughput at $i^{th}$ level of nesting                                                              | TPS                 |
| $N_i$               | Number of chains at nesting level $i$                                                                        | chain count         |
| $B_{max}$           | Maximum block size                                                                                           | bytes               |
| $B_f$               | Base-chain block frequency                                                                                   | Hz or $s^{-1}$      |
| $B_h$               | Base-chain block header size                                                                                 | bytes               |
| $D_f$               | Dapp-chain header frequency                                                                                  | Hz or $s^{-1}$      |
| $D_h$               | Dapp-chain header size                                                                                       | bytes               |
| $\Delta S$          | Network bandwidth requirements to acquire chain data                                                         | bytes/second        |
| $\mathbb{C}^\prime$ | Confirmation rate                                                                                            | Hz                  |
| $\UT{1}$            | $O(c^2)$ scaling strategy in UT (nested chain)                                                               |                     |
| $\UT{2}$            | $O(c^3)$ scaling strategy in UT (nested dapp chains)                                                         |                     |
| $\UT{3}$            | $O(C^4)$ scaling strategy in UT (nested dapp-dapp chains)                                                    |                     |
| $\UTinf{1}$         | Tiling of $\UT{1}$                                                                                           |                     |
| $\UTinf{2}$         | Tiling of $\UT{2}$                                                                                           |                     |
| $\UTinf{3}$         | Tiling of $\UT{3}$                                                                                           |                     |
| $+$HOT              | Protocol extension: header omission and truncation                                                           |                     |
| $+$HO               | Protocol extension: header omission only                                                                     |                     |
| $+$PoRs             | The protocol extension whereby miners explicitly include the corresponding PoR for each header they reflect. |                     |

: Notation used throughout the paper. \label{table:notation}

\newpage
\appendix
