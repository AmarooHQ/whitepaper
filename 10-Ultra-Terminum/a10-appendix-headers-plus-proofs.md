# Reflection Including Merkle Branches

What does a simplex look like if simplex-chains include explicit proofs of reflection (as merkle branches)?

Let $g$ be the length of the digest in bytes, i.e., the size of the hashes used in our merkle trees.

\begin{equation}
\begin{split}
\label{eq:simplex-N1-with-PoR}
k_1 & = k_{1,tx} + k_{1,b} \\
& = k_{1,tx} + B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1) \\
\implies T_1 & = N_1 \cdot (k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1)) \\
\frac{dT_1}{dN_1} & = \frac{1}{\ln 2}(k_1 \cdot \ln 2 - B_f \cdot N_1 \cdot (g + B_h \cdot \ln 4) - 2 \cdot B_f \cdot g \cdot N_1 \cdot \ln N_1) \\
& \mbox{which has the root} \\
N_1 & = \frac{k_1 \cdot \ln 2}{2 \cdot B_f \cdot g \cdot W_0(\frac{1}{B_f \cdot g}(2^{\frac{B_h}{g} - 1} \cdot \sqrt e \cdot k_1 \cdot \ln 2))}
\end{split}
\end{equation}

Note: $W_0(z)$ is the Lambert W function, aka the product logarithm.

Given that we can avoid including proofs of reflection (see \autoref{sec:proving-reflection}), I'm only going to roughly estimate the complexity here. Note that -- for configurations exclusive of proofs of reflection -- \autoref{eq:simplex-N1} shows that $O(N_1) = O(c)$, and \autoref{eq:simplex-T1} shows that $O(T_1) = O(c^2)$.

From \autoref{eq:simplex-N1-with-PoR}, we have $N_1$ that is of the form $N_1 = O(1) \cdot \frac{k_1}{W_0(O(1) \cdot k_1)}$. \autoref{fig:x-over-lambert} shows that $f(x) = \frac{x}{W_0(x)}$ looks similar to a straight line for values of $x$ that we care about. So lets approximate: $O(\frac{k}{W_0(k)}) = O(k)$. Thus I guess that, even if simplex-chains include proofs of reflection along with reflected headers, the result is still $O(N_1) = O(c)$ and $O(T_1) = O(c^2)$.

\begin{figure}
    \begin{subfigure}[t]{.48\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.75\linewidth]{graph_prodlog_sag}
        \caption{Using linear axes}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.48\linewidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.75\linewidth]{graph_prodlog_loglog_sag}
        \caption{Using log axes}
    \end{subfigure}%%
    \caption{Graphs of $f(x) = \frac{x}{W_0(x)}$ for $x \in [10^2, 10^8]$.}
    \label{fig:x-over-lambert}
\end{figure}

| $k$, $B_f$, $D_f$, $B_h$, $D_h$ | $N_1$ | $O(c^2)$ tps | $O(c^3)$ tps | $B_h$ + PoRs | $\nicefrac{N_1}{k}$ |
|--------|---|----|----|----|----|
| $1000, \nicefrac{1}{15}, \nicefrac{1}{15}, 112, 250$ | 26 | 52 | 12 | 288 | $2.6\times 10^{-2}$ |
| $3000, \nicefrac{1}{15}, \nicefrac{1}{15}, 112, 250$ | 68 | 408 | 294 | 331 | $2.3\times 10^{-2}$ |
| $30000, \nicefrac{1}{15}, \nicefrac{1}{15}, 112, 250$ | 529 | 31,740 | 228,528 | 425 | $1.8\times 10^{-2}$ |
| $1000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 250$ | 87 | 174 | 167 | 345 | $8.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 250$ | 232 | 1,392 | 4,009 | 388 | $7.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 500$ | 232 | 1,392 | 2,004 | 388 | $7.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 200, 250$ | 193 | 1,158 | 3,335 | 466 | $6.4\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 200, 500$ | 193 | 1,158 | 1,668 | 466 | $6.4\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, \nicefrac{1}{60}, 200, 200$ | 1,596 | 95,760 | $3.4\times 10^{6}$ | 564 | $5.3\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 200$ | 1,864 | 111,840 | $4.0\times 10^{6}$ | 483 | $6.2\times 10^{-2}$ |
| $1000, \nicefrac{1}{600}, \nicefrac{1}{600}, 112, 250$ | 687 | 1,374 | 13,190 | 437 | $6.9\times 10^{-1}$ |
| $3000, \nicefrac{1}{600}, \nicefrac{1}{600}, 200, 250$ | 1,596 | 9,576 | 275,789 | 564 | $5.3\times 10^{-1}$ |
| $3000, \nicefrac{1}{600}, \nicefrac{1}{600}, 112, 250$ | 1,864 | 11,184 | 322,099 | 483 | $6.2\times 10^{-1}$ |
| $30000, \nicefrac{1}{600}, \nicefrac{1}{600}, 200, 200$ | 13,586 | 815,160 | $2.9\times 10^{8}$ | 662 | $4.5\times 10^{-1}$ |
| $30000, \nicefrac{1}{600}, \nicefrac{1}{600}, 112, 200$ | 15,503 | 930,180 | $3.3\times 10^{8}$ | 581 | $5.2\times 10^{-1}$ |
| $1000, \nicefrac{1}{60}, \nicefrac{1}{600}, 112, 250$ | 87 | 174 | 1,670 | 345 | $8.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{600}, 112, 250$ | 232 | 1,392 | 40,090 | 388 | $7.7\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, \nicefrac{1}{600}, 112, 250$ | 1,864 | 111,840 | $3.2\times 10^{7}$ | 483 | $6.2\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 500, 500$ | 120 | 720 | 1,037 | 750 | $4.0\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 500, 700$ | 120 | 720 | 741 | 750 | $4.0\times 10^{-2}$ |

: The effect of including Proofs of Reflection with headers.
