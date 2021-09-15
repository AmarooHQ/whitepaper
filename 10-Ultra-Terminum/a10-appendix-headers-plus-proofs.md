# Reflection Including Merkle Branches

\label{sec:por-with-proofs}

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

%% INSERT ### TABLE: tps_por

: The effect of including Proofs of Reflection with headers.
