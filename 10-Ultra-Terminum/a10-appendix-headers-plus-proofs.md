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
%% \implies k_{1,tx} & = k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1) \\
& \mbox{Note that} \; k_{1,tx} \neq k_{1,b}
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

| $k$, $B_f$, $B_h$               | $N_1$  | $O(c^2)$ tps       | $N_2$              | $O(c^3)$ tps        | PoR (bytes) | $\nicefrac{N_1}{k}$ |
|--------|---|----|----|----|-----|----|
| $1000, \nicefrac{1}{15}, 112$   | 26     | 104                | 1,898              | 7,591               | 176         | $2.6\times 10^{-2}$ |
| $3000, \nicefrac{1}{15}, 112$   | 68     | 816                | 14,653             | 175,841             | 219         | $2.3\times 10^{-2}$ |
| $30000, \nicefrac{1}{15}, 112$  | 529    | 63,480             | $1.1\times 10^{6}$ | $1.3\times 10^{8}$  | 313         | $1.8\times 10^{-2}$ |
| $1000, \nicefrac{1}{60}, 112$   | 87     | 348                | 25,121             | 100,485             | 233         | $8.7\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, 200$   | 193    | 2,316              | 91,192             | $1.1\times 10^{6}$  | 266         | $6.4\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, 112$   | 232    | 2,784              | 198,236            | $2.4\times 10^{6}$  | 276         | $7.7\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, 200$  | 1,596  | 191,520            | $7.5\times 10^{6}$ | $9.0\times 10^{8}$  | 364         | $5.3\times 10^{-2}$ |
| $30000, \nicefrac{1}{60}, 112$  | 1,864  | 223,680            | $1.6\times 10^{7}$ | $1.9\times 10^{9}$  | 371         | $6.2\times 10^{-2}$ |
| $1000, \nicefrac{1}{600}, 112$  | 687    | 2,748              | $1.9\times 10^{6}$ | $7.7\times 10^{6}$  | 325         | $6.9\times 10^{-1}$ |
| $3000, \nicefrac{1}{600}, 200$  | 1,596  | 19,152             | $7.5\times 10^{6}$ | $9.0\times 10^{7}$  | 364         | $5.3\times 10^{-1}$ |
| $3000, \nicefrac{1}{600}, 112$  | 1,864  | 22,368             | $1.6\times 10^{7}$ | $1.9\times 10^{8}$  | 371         | $6.2\times 10^{-1}$ |
| $30000, \nicefrac{1}{600}, 200$ | 13,586 | $1.6\times 10^{6}$ | $6.3\times 10^{8}$ | $7.6\times 10^{10}$ | 462         | $4.5\times 10^{-1}$ |
| $30000, \nicefrac{1}{600}, 112$ | 15,503 | $1.9\times 10^{6}$ | $1.3\times 10^{9}$ | $1.6\times 10^{11}$ | 469         | $5.2\times 10^{-1}$ |
| $3000, \nicefrac{1}{60}, 500$   | 120    | 1,440              | 22,435             | 269,222             | 250         | $4.0\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, 1000$  | 73     | 876                | 6,754              | 81,048              | 233         | $2.4\times 10^{-2}$ |
| $3000, \nicefrac{1}{60}, 1500$  | 52     | 624                | 3,207              | 38,488              | 231         | $1.7\times 10^{-2}$ |

: The effect of including Proofs of Reflection with headers.
