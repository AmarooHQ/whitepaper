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
N_1 & = \frac{k_1 \cdot \ln 2}{2 \cdot B_f \cdot g \cdot W_0(\frac{1}{B_f \cdot g}(2^{\frac{B_h}{g} - 1} \cdot \sqrt e \cdot k_1 \cdot \ln 2))} \\
& \mbox{Note:} \\
\implies k_{1,tx} & = k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1)
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


| $k$, $B_f$, $D_f$, $B_h$, $D_h$                         | $N_1$  | $O(c^2)$ tps       | $N_2$              | $O(c^3)$ tps        | PoR size (bytes) | $\nicefrac{N_1}{k}$ |
|--------|---|---|----|----|----|----|
| $1000, \nicefrac{1}{15}, \nicefrac{1}{15}, 112, 250$    | 26     | 104                | 850                | 3,401               | 176              | $2.6\times 10^{-2}$ |
| $3000, \nicefrac{1}{15}, \nicefrac{1}{15}, 112, 250$    | 68     | 816                | 6,565              | 78,777              | 219              | $2.3\times 10^{-2}$ |
| $30000, \nicefrac{1}{15}, \nicefrac{1}{15}, 112, 250$   | 529    | 63,480             | 502,762            | $6.0\times 10^{7}$  | 313              | $1.8\times 10^{-2}$ |
| $1000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 250$    | 87     | 348                | 11,254             | 45,017              | 233              | $8.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 250$    | 232    | 2,784              | 88,810             | $1.1\times 10^{6}$  | 276              | $7.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 500$    | 232    | 2,784              | 44,405             | 532,858             | 276              | $7.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 200, 250$    | 193    | 2,316              | 72,954             | 875,448             | 266              | $6.4\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 200, 500$    | 193    | 2,316              | 36,477             | 437,724             | 266              | $6.4\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, \nicefrac{1}{60}, 200, 200$   | 1,596  | 191,520            | $7.5\times 10^{6}$ | $9.0\times 10^{8}$  | 364              | $5.3\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, \nicefrac{1}{60}, 112, 200$   | 1,864  | 223,680            | $8.8\times 10^{6}$ | $1.1\times 10^{9}$  | 371              | $6.2\times 10^{-2}$ |
| $1000, \nicefrac{1}{600}, \nicefrac{1}{600}, 112, 250$  | 687    | 2,748              | 867,269            | $3.5\times 10^{6}$  | 325              | $6.9\times 10^{-1}$ |
| $3000, \nicefrac{1}{600}, \nicefrac{1}{600}, 200, 250$  | 1,596  | 19,152             | $6.0\times 10^{6}$ | $7.2\times 10^{7}$  | 364              | $5.3\times 10^{-1}$ |
| $3000, \nicefrac{1}{600}, \nicefrac{1}{600}, 112, 250$  | 1,864  | 22,368             | $7.0\times 10^{6}$ | $8.4\times 10^{7}$  | 371              | $6.2\times 10^{-1}$ |
| $30000, \nicefrac{1}{600}, \nicefrac{1}{600}, 200, 200$ | 13,586 | $1.6\times 10^{6}$ | $6.3\times 10^{8}$ | $7.6\times 10^{10}$ | 462              | $4.5\times 10^{-1}$ |
| $30000, \nicefrac{1}{600}, \nicefrac{1}{600}, 112, 200$ | 15,503 | $1.9\times 10^{6}$ | $7.3\times 10^{8}$ | $8.7\times 10^{10}$ | 469              | $5.2\times 10^{-1}$ |
| $1000, \nicefrac{1}{60}, \nicefrac{1}{600}, 112, 250$   | 87     | 348                | 112,543            | 450,173             | 233              | $8.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{600}, 112, 250$   | 232    | 2,784              | 888,096            | $1.1\times 10^{7}$  | 276              | $7.7\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, \nicefrac{1}{600}, 112, 250$  | 1,864  | 223,680            | $7.0\times 10^{7}$ | $8.4\times 10^{9}$  | 371              | $6.2\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 500, 500$    | 120    | 1,440              | 22,435             | 269,222             | 250              | $4.0\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 500, 700$    | 120    | 1,440              | 16,025             | 192,302             | 250              | $4.0\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 1000, 1000$  | 73     | 876                | 6,754              | 81,048              | 233              | $2.4\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, \nicefrac{1}{60}, 1500, 1500$  | 52     | 624                | 3,207              | 38,488              | 231              | $1.7\times 10^{-2}$ |

: The effect of including Proofs of Reflection with headers.
