
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
    \fancyhead[R]{Notation \& Nomenclature}
}

\thispagestyle{notation}

%% ### TABLE: notation

| Term | Definition | Unit |
| ------ | ------------------------------------------------------------- | -------------- |
| $\mathbb{C}^\prime$ | Confirmation rate | Hz |
| $k_i$ | Per-chain raw throughput at the $i^{th}$ level of nesting \newline A generalization of block size | bytes/second |
| $k$ | Per-chain raw throughput across nesting levels \newline $k$ is used to simplify reasoning and equations, especially in situations where all $k_i$ are equal | bytes/second |
| $T_i$ | Network throughput at the $i^{th}$ level of nesting | bytes/second |
| $N_i$ | Number of chains at the $i^{th}$ level of nesting | chain count |
| $B_{max}$ | Maximum block size | bytes |
| $B_f$ | Base-chain block frequency | Hz or $s^{-1}$ |
| $B_h$ | Base-chain header size | bytes |
| $D_f$ | Dapp-chain block frequency | Hz or $s^{-1}$ |
| $D_h$ | Dapp-chain header size | bytes |
| $\Delta S$ | Minimum network bandwidth for a node to remain in sync with a given system | bytes/second |

: Notation defined in this document. \label{table:notation}

# Nomenclature {-}

%% ### TABLE: nomenclature

| Term | Definition |
| ------ | ----------------------------------------------------------------------- |
| $\UT{i}$ | The UT scaling configuration with $i$ levels of nesting |
| $\UT{1}$ | UT with base-level chains only -- $O(c^2)$ scalability |
| $\UT{2}$ | UT with nested dapp-chains -- $O(c^3)$ scalability |
| $\UT{3}$ | UT with nested dapp-dapp-chains -- $O(c^4)$ scalability |
| $\UTinf{i}$ | Tiling of $\UT{i}$ -- $O(n)$ scalability |
| +HO | Protocol extension: header omission |
| +HOT | Protocol extension: header omission and truncation |
| +PoRs | The protocol extension whereby simplex-chain miners explicitly include the corresponding PoR for each header they reflect |
| +PoRTs | +PoRs with shorter proofs via hash-truncation |

: Nomenclature defined in this document. \label{table:nomenclature}

\newpage
\appendix
