%% BEGIN ### RELEASE

\clearpage

# UT Variant Complexities

\label{sec:ut-variant-complexities}

## +PoRs: Explicit PoRs

\label{sec:por-with-proofs}

What is the throughput of the simplex if simplex-chains include explicit proofs of reflection (as merkle branches) and the headers of reflecting chains?

Let $g$ be the length of the digest in bytes, i.e., the size of the hashes used in our merkle trees.
\begin{equation}
\begin{split}
\label{eq:simplex-N1-with-PoR}
k_1 & = k_{1,tx} + k_{1,B} \\
& = k_{1,tx} + B_f \cdot N_1 \cdot (B_h + g \cdot \ceil{\log_2 N_1}) \\
& \approx k_{1,tx} + B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1) \\
\implies T_1 & = N_1 \cdot (k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1)) \\
\frac{dT_1}{dN_1} & = \frac{1}{\ln 2}(k_1 \cdot \ln 2 - B_f \cdot N_1 \cdot (g + B_h \cdot \ln 4) - 2 \cdot B_f \cdot g \cdot N_1 \cdot \ln N_1) \\
\mbox{\href{\wolframAlphaPorsRootUrl}{which has a zero at:}} \\
N_1 & = \frac{k_1 \cdot \ln 2}{2 \cdot B_f \cdot g \cdot W_0((2^{B_h g^{-1} - 1} \cdot \sqrt e \cdot k_1 \cdot \ln 2)(B_f \cdot g)^{-1})} \\
\implies k_{1,tx} & \neq k_{1,B}
\end{split}
\end{equation}
Note: $W_0(z)$ is the Lambert W function, a.k.a. the product logarithm.

\autoref{eq:simplex-N1-with-PoR} gives an $N_1$ that is of the form $N_1 = O(1) \cdot \frac{k_1}{W_0(O(1) \cdot k_1)}$.
\autoref{fig:x-over-lambert} graphs $f(x) = \frac{x}{W_0(x)}$ for values of $x$ that we care about; $f(x) = 0.0638x$ is included for comparison.
Regarding this specific case, approximating $O(\frac{k}{W_0(k)}) = O(k)$ gives us $O(N_1) = O(c)$ and $O(T_1) = O(c^2)$.

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

If we use verkle PoRs instead of merkle PoRs, then we'll have a different $k_{1,B}$. Assuming that vector commitments and proofs are $g$ bytes, and vector locations are 1 byte:
\begin{equation}
    k_{1,B} = B_f \cdot N_1 \cdot (B_h + (1 + g) \cdot \log_{256} N_1)
\end{equation}
Other than this change, the logic that is used in \autoref{eq:simplex-N1-with-PoR} still works, and the resulting complexities will be the same.

%% INSERT ### TABLE: tps_por

: $\UT{\text{+PoRs}}$ capacity given different parameters.

### +PoRs with +T

\label{sec:ext-ports}

%% INSERT ### TABLE: tps_port

: $\UT{\text{+PoRTs}}$ capacity given different parameters.

## +OP and +OPT

The +OP variants exclude PoRs from simplex-chain blocks.
This is reasonable if users running full nodes are willing to download and temporarily store all blocks from all simplex-chains (this allows each node to regenerate the PoRs).
The PoRs are still processed as part of a chain's state transition (each reflecting header will have a corresponding PoR), and are thus provable.
Additionally, since full nodes will need to recalculate these, a suitable P2P protocol will allow PoRs to be requested from full nodes on an ad-hoc basis.

The derivations of +OP's complexity was covered in \autoref{sec:ut-complexity}.

%% INSERT ### TABLE: tps_op

: $\UT{\text{+OP}}$ capacity given different parameters.

%% INSERT ### TABLE: tps_opt

: $\UT{\text{+OPT}}$ capacity given different parameters.

## +HO and +HOT

The +HO variants replace the headers of reflecting chains with the respective header's hash.
This is reasonable since the headers of each simplex-chain (that would otherwise be recorded in simplex-chain blocks) are \emph{common} among all simplex-chains.
If a user is running nodes for multiple simplex-chains, they should only need to download each header once --- including raw headers in each block is redundant.

Thus, +HO has $k_{1,B}$ of:
\begin{equation}
    k_{1,B} = N_1 \cdot B_f \cdot g
\end{equation}
This is equivalent to +OP with very small headers --- 32 bytes instead of 80+ bytes.

%% INSERT ### TABLE: tps_ho

: $\UT{\text{+HO}}$ capacity given different parameters.

%% INSERT ### TABLE: tps_hot

: $\UT{\text{+HOT}}$ capacity given different parameters.

## +HOPoRs and +HOPoRTs

+HOPoRs is the combination of +HO and +PoRs --- headers are omitted but PoRs are still explicitly recorded.

Thus, +HOPoRs has $k_{1,B}$ of:
\begin{align}
    \text{Merkle PoRs:} & & k_{1,B} &= B_f \cdot N_1 \cdot g \cdot (1 + \log_2 N_1) &
    \nonumber \\
    \text{Verkle PoRs:} & & k_{1,B} &= B_f \cdot N_1 \cdot (g + (g + 1) \cdot \max(1, \log_{256} N_1)) &
\end{align}

%% INSERT ### TABLE: tps_hopors

: $\UT{\text{+HOPoRs}}$ capacity given different parameters.

%% INSERT ### TABLE: tps_hoports

: $\UT{\text{+HOPoRTs}}$ capacity given different parameters.


%% END ### RELEASE
