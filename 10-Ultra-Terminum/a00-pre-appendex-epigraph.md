
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
    \fancyhead[L]{}
    \fancyhead[R]{Notation}
}

\thispagestyle{notation}

%% ### TABLE: notation

| Term                | Definition                                                                                                                                                   | Unit           |
| --------- | ------------------------------------------------------------------ | -------------- |
| $k$                 | Approximate raw per-chain throughput at all levels of nesting; used to simplify reasoning and equations, especially in situations where all $k_i$ are equal. | bytes/second   |
| $k_i$               | Raw per-chain throughput at $i^{th}$ level of nesting                                                                                                        | bytes/second   |
| $T_i$               | Network throughput at $i^{th}$ level of nesting                                                                                                              | bytes/second   |
| $N_i$               | Number of chains at nesting level $i$                                                                                                                        | chain count    |
| $B_{max}$           | Maximum block size                                                                                                                                           | bytes          |
| $B_f$               | Base-chain block frequency                                                                                                                                   | Hz or $s^{-1}$ |
| $B_h$               | Base-chain header size                                                                                                                                       | bytes          |
| $D_f$               | Dapp-chain block frequency                                                                                                                                   | Hz or $s^{-1}$ |
| $D_h$               | Dapp-chain header size                                                                                                                                       | bytes          |
| $\Delta S$          | Network bandwidth requirements to acquire chain data                                                                                                         | bytes/second   |
| $\mathbb{C}^\prime$ | Confirmation rate                                                                                                                                            | Hz             |

: Notation used throughout the paper. \label{table:notation}

# Nomenclature {-}

%% ### TABLE: nomenclature

| Term        | Definition                                                                                                  |
| ----------- | ----------------------------------------------------------------------------------------------------------- |
| $\UT{1}$    | $O(c^2)$ scaling configuration in UT (nested chain)                                                         |
| $\UT{2}$    | $O(c^3)$ scaling configuration in UT (nested dapp chains)                                                   |
| $\UT{3}$    | $O(C^4)$ scaling configuration in UT (nested dapp-dapp chains)                                              |
| $\UTinf{1}$ | Tiling of $\UT{1}$                                                                                          |
| $\UTinf{2}$ | Tiling of $\UT{2}$                                                                                          |
| $\UTinf{3}$ | Tiling of $\UT{3}$                                                                                          |
| $+$HOT      | Protocol extension: header omission and truncation                                                          |
| $+$HO       | Protocol extension: header omission                                                                         |
| $+$PoRs     | The protocol extension whereby miners explicitly include the corresponding PoR for each header they reflect |

: The nomenclature defined through this wp. \label{table:nomenclature}

\newpage
\appendix
