%% BEGIN ### RELEASE

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
| ------ | ------------------------------------------------------------- | ------------ |
| $\mathbb{C}^\prime$ | Confirmation rate. | Hz |
| $k_i$ | A generalization of block size: the average per-chain raw throughput at the $i^{th}$ level of nesting. | bytes/second |
| $k$ | Average per-chain raw throughput across nesting levels. $k$ is used to simplify reasoning and equations, especially in situations where all $k_i$ are equal. | bytes/second |
| $T_i$ | Network throughput at the $i^{th}$ level of nesting. | bytes/second |
| $N_i$ | Number of chains at the $i^{th}$ level of nesting. | chains |
| $N_\text{tiles}$ | Number of tiles in a simplex-tiling. | tiles |
| $B_{max}$ | Maximum block size. | bytes |
| $B_f$ | Base-chain block frequency. | Hz or $s^{-1}$ |
| $B_h$ | Base-chain header size. | bytes |
| $D_f$ | Dapp-chain block frequency. | Hz or $s^{-1}$ |
| $D_h$ | Dapp-chain header size. | bytes |
| TPS | Transactions per second. | tx/s |
| $\Sigma\;\text{TPS}_{i}$ | Network-wide transactions per second at the $i^{\text{th}}$ level of nesting (given no additional levels). Primarily used when ``TPS'' alone would be ambiguous. | tx/s |
| $\Delta s$ | Minimum network bandwidth for a full node to remain in sync with a single simplex-chain (whilst also validating PoRs). | bytes/second |
| $\Delta S$ | Minimum network bandwidth for a \emph{mining} node to remain in sync with all reflecting simplex-chains. | bytes/second |

: Notation defined in this document. \label{table:notation}

\begin{comment}
\end{comment}

# Nomenclature {-}

%% ### TABLE: nomenclature

| Term | Definition | Reference |
| ------ | ------------------------------------------------------------- | ----------- |
| $\UT{i}$ | The UT scaling configuration with $i$ levels of nesting. | \autoref{sec:constructing-ut} |
| $\UT{1}$ | UT with base-level chains only -- $O(c^2)$ scalability. | \autoref{sec:the-simplex} |
| $\UT{2}$ | UT with nested dapp-chains -- $O(c^3)$ scalability. | \autoref{sec:dapp-chains} |
| $\UT{3}$ | UT with nested dapp-dapp-chains -- $O(c^4)$ scalability. | \autoref{sec:dapp-chains} |
| $\UTinf{i}$ | Tiling of $\UT{i}$ -- $O(n)$ scalability. | \autoref{sec:tiling} |
| +PoRs | The protocol extension whereby simplex-chain miners explicitly include the corresponding PoR for each header they reflect. | \autoref{sec:por-with-proofs} |
| +PoRTs | +PoRs with shorter proofs and smaller headers via hash-truncation. | \autoref{sec:ext-ports} |
| +OP | Protocol extension: omitted proofs. | \autoref{sec:exploiting-seg-state} |
| +OPT | Protocol extension: omitted proofs and smaller headers via hash truncation. | \autoref{sec:exploiting-seg-state} |
| +HO | Protocol extension: header omission. | \autoref{sec:exploiting-seg-state} |
| +HOT | Protocol extension: header omission and truncation. | \autoref{sec:exploiting-seg-state} |

: Nomenclature defined in this document. \label{table:nomenclature}

\newpage
\appendix

%% END ### RELEASE
