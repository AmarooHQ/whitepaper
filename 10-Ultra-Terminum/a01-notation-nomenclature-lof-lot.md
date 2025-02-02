%% BEGIN ### RELEASE

\clearpage

\section*{Notation}
\addcontentsline{toc}{section}{Notation, Nomenclature}
\fancypagestyle{notation}{%
    \fancyhead[L]{}
    \fancyhead[R]{\emph{Notation, Nomenclature, Figures, \& Tables}}
}

\thispagestyle{notation}

%% ### TABLE: notation

| Term | Definition | Unit |
| ------- | ------------------------------------------------------------- | ---------------- |
| $c$ | Abstract representation of per-node computational resources. | - |
| $n$ | Abstract representation of network size. | - |
| $p$ | Proportion of the network's hash-rate controlled by honest nodes. | - |
| $q$ | Proportion of the network's hash-rate controlled by the attacker. | - |
| $L_d$, $R_d$ | The difficulty of chain \cL /\cR. | hashes/block |
| $L_r$, $R_r$ | The block reward of chain \cL /\cR. | coins/block |
| $w$ | Some amount of \emph{work}. | hashes |
| $X_{R\rightarrow L}$ | Exchange rate between L-coins and R-coins. | L-coins/R-coin |
| $\mathbb{C}^\prime$ | Confirmation rate. | Hz |
| $g$ | Hash digest size. | bytes |
| $k_i$ | A generalization of block size: the average per-chain raw throughput at the $i^{th}$ level of nesting. | bytes/second |
| $k$ | Average per-chain raw throughput across nesting levels. $k$ is used to simplify reasoning and equations, esp. when all $k_i$ are equal. | bytes/second |
| $T_i$ | Network throughput at the $i^{th}$ level of nesting. | bytes/second |
| $N_i$ | Number of chains at the $i^{th}$ level of nesting. | chains |
| $N_\text{tiles}$ | Number of tiles in a simplex-tiling. | tiles |
| $B_f$, $L_f$ | Base-chain block frequency. | Hz |
| $B_h$ | Base-chain header size. | bytes |
| $D_f$ | Dapp-chain block frequency. | Hz |
| $D_h$ | Dapp-chain header size. | bytes |
| $\phi$ | Propagation delay across the network | seconds |
| $\Sigma\;\text{TPS}_{i}$ | Network-wide transactions per second at the $i^{\text{th}}$ level of nesting (given no additional levels). | tx/s |
| $\Delta s$ | Minimum network bandwidth for a full node to remain in sync with a single simplex-chain (whilst also validating PoRs). | bytes/second |
| $\Delta r$ | Minimum network bandwidth for a full node to fully reconstruct the PoR graph. | bytes/second |
| $\Delta S$ | Minimum network bandwidth for a \emph{mining} node to remain in sync with all reflecting simplex-chains. | bytes/second |
| $\text{DAA}_N$ | The number of blocks over which the DAA operates. | blocks |

: Notation defined in this document. \label{table:notation}

\begin{comment}
\end{comment}

\section*{Nomenclature}

%% ### TABLE: nomenclature

\begin{table}[H]
\centering
\caption{Nomenclature defined in this document. \label{table:nomenclature}}
\begin{tabular}{lll}
\toprule
Term & Definition & Reference \\
\midrule
{$\UT{i}$} & {The UT scaling configuration with $i$ levels of nesting.} & {\autoref{sec:constructing-ut}} \\
{$\UT{1}$} & {UT with base-level chains only --- $O(c^2)$ scalability.} & {\autoref{sec:the-simplex}} \\
{$\UT{2}$} & {UT with nested dapp-chains --- $O(c^3)$ scalability.} & {\autoref{sec:dapp-chains}} \\
{$\UT{3}$} & {UT with nested dapp-dapp-chains --- $O(c^4)$ scalability.} & {\autoref{sec:dapp-chains}} \\
{$\UTinf{i}$} & {Tiling of $\UT{i}$ --- $O(n)$ scalability.} & {\autoref{sec:tiling}} \\
{+PoRs} & {Protocol variant: explicit proofs.} & {\autoref{sec:proving-reflection}} \\
{+PoRTs} & {Protocol variant: explicit proofs + T.} & {\autoref{sec:ext-ports}} \\
{+HOPoRs} & {Protocol variant: explicit proofs + header omission.} & {\autoref{sec:exploiting-seg-state}} \\
{+HOPoRTs} & {Protocol variant: explicit proofs + header omission + T.} & {\autoref{sec:ext-ports}} \\
{+OP} & {Protocol variant: omitted proofs.} & {\autoref{sec:proving-reflection}} \\
{+OPT} & {Protocol variant: omitted proofs + T.} & {\autoref{sec:exploiting-seg-state}} \\
{+HO} & {Protocol variant: omitted proofs + header omission.} & {\autoref{sec:exploiting-seg-state}} \\
{+HOT} & {Protocol variant: omitted proofs + header omission + T.} & {\autoref{sec:exploiting-seg-state}} \\
\bottomrule
\end{tabular}
\end{table}

\newpage

\printglossaries

\newpage

\listoffigures
\addcontentsline{toc}{section}{List of Figures, Tables}

\newpage

\listoftables

\newpage

\listofcitation
\addcontentsline{toc}{section}{References}
\listofsuppcites

%%\listofalgorithms

\clearpage

%% END ### RELEASE
