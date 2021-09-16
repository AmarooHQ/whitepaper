
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
| -------- | --------------------------------------------------------------- | -------------- |
| $k_i$               | A generalization of block size; the per-chain raw throughput at the $i^{th}$ level of nesting.                                                               | bytes/second   |
| $k$                 | The per-chain raw throughput across nesting levels. $k$ is used to simplify reasoning and equations, especially in situations where all $k_i$ are equal. | bytes/second   |
| $T_i$               | Network throughput at $i^{th}$ level of nesting                                                                                                              | bytes/second   |
| $N_i$               | Number of chains at the $i^{th}$ level of nesting                                                                                                            | chain count    |
| $B_{max}$           | Maximum block size                                                                                                                                           | bytes          |
| $B_f$               | Base-chain block frequency                                                                                                                                   | Hz or $s^{-1}$ |
| $B_h$               | Base-chain header size                                                                                                                                       | bytes          |
| $D_f$               | Dapp-chain block frequency                                                                                                                                   | Hz or $s^{-1}$ |
| $D_h$               | Dapp-chain header size                                                                                                                                       | bytes          |
| $\Delta S$          | Network bandwidth requirements for a node to remain in sync with a given system                                                                              | bytes/second   |
| $\mathbb{C}^\prime$ | Confirmation rate                                                                                                                                            | Hz             |

: Notation used throughout this document. \label{table:notation}

# Nomenclature {-}

%% ### TABLE: nomenclature

| Term        | Definition                                                                                                  |
| ----------- | ----------------------------------------------------------------------------------------------------------- |
| $\UT{i} | UT scaling configuration with $i$ levels of nesting |
| $\UT{1}$    | UT nested chains with $O(c^2)$ complexity   |
| $\UT{2}$    | UT nested dapp-chains with $O(c^3)$ complexity |
| $\UT{3}$    | UT nested dapp-dapp-chains with $O(C^4)$ complexity           |
| $\UTinf{i}$ | Tiling of $\UT{i}$                                                                                          |
| +HOT        | Protocol extension: header omission and truncation                                                          |
| +HO         | Protocol extension: header omission                                                                         |
| +PoRs       | The protocol extension whereby miners explicitly include the corresponding PoR for each header they reflect |

: The nomenclature defined throughout this document. \label{table:nomenclature}

\newpage
\appendix
