%% BEGIN ### RELEASE

# UT Variant Complexities

## +PoRs: Explicit PoRs

\label{sec:por-with-proofs}

What is the throughput of simplex if simplex-chains include explicit proofs of reflection (as merkle branches)?
This extension to UT is called +PoRs.

Let $g$ be the length of the digest in bytes, i.e., the size of the hashes used in our merkle trees.
\begin{equation}
\begin{split}
\label{eq:simplex-N1-with-PoR}
k_1 & = k_{1,tx} + k_{1,b} \\
& = k_{1,tx} + B_f \cdot N_1 \cdot (B_h + g \cdot \ceil{\log_2 N_1}) \\
& \approx k_{1,tx} + B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1) \\
\implies T_1 & = N_1 \cdot (k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1)) \\
\frac{dT_1}{dN_1} & = \frac{1}{\ln 2}(k_1 \cdot \ln 2 - B_f \cdot N_1 \cdot (g + B_h \cdot \ln 4) - 2 \cdot B_f \cdot g \cdot N_1 \cdot \ln N_1) \\
& \mbox{which has the root} \\
N_1 & = \frac{k_1 \cdot \ln 2}{2 \cdot B_f \cdot g \cdot W_0(\frac{1}{B_f \cdot g}(2^{\frac{B_h}{g} - 1} \cdot \sqrt e \cdot k_1 \cdot \ln 2))} \\
%% \implies k_{1,tx} & = k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1) \\
& \mbox{Note that} \; k_{1,tx} \neq k_{1,b}
\end{split}
\end{equation}

Note: $W_0(z)$ is the Lambert W function, aka the product logarithm.

\autoref{eq:simplex-N1-with-PoR} gives an $N_1$ that is of the form $N_1 = O(1) \cdot \frac{k_1}{W_0(O(1) \cdot k_1)}$.
\autoref{fig:x-over-lambert} graphs $f(x) = \frac{x}{W_0(x)}$ for values of $x$ that we care about; $f(x) = 0.0638x$ is included for comparison.
Regarding this specific case, is it reasonable to approximate $O(\frac{k}{W_0(k)}) = O(k)$?
If it is, then we still have $O(N_1) = O(c)$ and $O(T_1) = O(c^2)$.

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

If we use verkle PoRs instead of merkle PoRs, then we'll have a different $k_{1,b}$. Assuming that vector commitments and proofs are $g$ bytes:
\begin{equation}
    k_{1,b} = B_f \cdot N_1 \cdot (B_h + (1 + g) \cdot \ceil{\log_{256} N_1})
\end{equation}
Other than this change, the logic that is used in \autoref{eq:simplex-N1-with-PoR} still works, and the resulting complexities will be the same.

%% INSERT ### TABLE: tps_por

: $\UT{\text{+PoRs}}$ capacity given different parameters.

### +PoRs with +T

\label{sec:ext-ports}

%% INSERT ### TABLE: tps_port

: $\UT{\text{+PoRTs}}$ capacity given different parameters.

## +HOPoRs

\todo{add +HOPoRs and +HOPoRTs}

%% INSERT ### TABLE: tps_hopors

: $\UT{\text{+HOPoRs}}$ capacity given different parameters.

%% INSERT ### TABLE: tps_hoports

: $\UT{\text{+HOPoRTs}}$ capacity given different parameters.

%% END ### RELEASE
