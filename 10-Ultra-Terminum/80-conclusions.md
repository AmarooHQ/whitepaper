%% BEGIN ### RELEASE

\clearpage

# Conclusions

\label{sec:conclusions}

\input{80-conclusions/20-addressing-trilemma}




## OLD CONCLUSIONS BELOW






\assignedTODO{{Max}}{h}{Write conclusion}

This paper introduced and constructed Amaroo's consensus mechanism, \emph{Ultra Terminum}, a proof-agnostic cross-chain consensus strategy that addresses the core conflict of Buterin's Trilemma.
\emph{Ultra Terminum} provides multiple scaling configurations, $\UT{1} (O(c^2))$, $\UT{2} (O(c^3))$, $\UT{3} (O(c^4))$ and a special configuration of tiling UT$_{\aleph}$ $O(n)$.

$\UT{}$ leverages existing consensus methods in combination and, by way of construction, adds security to these methods.
The paper presented the underlying primitive, \emph{Proof of Reflection}, that provides an agnostic way for chains of various proof mechanisms to participate in a collaborative network where chains share security amongst each other.
This critical piece of collaboration allows $\UT{}$ and Amaroo's network to scale to meet market demand without compromising decentralization or security.

## Addressing *Buterin's Trilemma*

The underlying primitive, \emph{Proof of Reflection}, promotes the necessary interconnections between chains to achieve scalability without compromising on decentralization or security, thus, in conjunction with \emph{Ultra Terminum}, addressing the conflicts that lie at the heart of the trilemma, as illustrated in \autoref{fig:trilemma-core-conflict-solved}.
\emph{Security} is achieved at the core of this approach, where each blockchain uses \emph{reflections} to share security, while keeping the state local, allowing each chain to become \emph{as secure as the entire network}.
\emph{Scalability} and \emph{decentralization} result from the fact that each chain only needs to process an $O(c)$ load for its chain state and an $O(c)$ load for the PoR graph.

\begin{figure}[H]
\centering
\includegraphics[max width=\linewidth]{trilemma/conflict_resolution_sag}
\caption{A solution to the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict-solved}
\end{figure}


On the base layer, the Simplex, each participating simplex-chain maintains its own local, independent state with its own specification, allowing for a multitude of chain implementations to meet the need of virtually any application.
Similarly, dapp-chains have the freedom to implement whatever state- and transaction-protocols that fit their desired use case.
Although heterogeneous, the chains are not siloed -- the interleaving of chains with PoR, tied with the secure cross-chain protocol presented in \autoref{sec:spv-in-ut}, enables chains to seamlessly communicate and transact amongst each other.
In essence, cross-chain transactions enable chains to converge toward an Internet of blockchains.

Finally, various tiling configurations allow the network to adopt a solution that pushes throughput beyond the limits of what was possible, without sacrificing the overall security of the network.
UT$_\aleph$ achieves unbounded $O(n)$ scalability and opens the way to a truly ubiquitous blockchain.

\autoref{table:ut-vs-trilemma} outlines the way in which $\UT{}$ variants evaluate against the trilemma, also presenting the possible throughput achieved.

\begin{table}[H]
    \centering
    \caption{
        Table evaluating UT against trilemma criteria ($3000 \le k \le 20000$ B/s).
    }
    \begin{tabular}{lllll}
        \toprule
        UT Config. & Decentralized? & $O(n)$ Secure? & \multicolumn{2}{l}{$O(n)$ Scalable?} \\
        \midrule
        $\UT{1}$ & Yes & Yes & Maybe & (Max. TPS: $\sim$ 1K - 400K) \\
        $\UT{2}$ & Yes & Yes & Possibly & (Max. TPS: $\sim$ 600K - 2B) \\
        $\UT{3}$ & Yes & Yes & Probably & (Max. TPS: $\sim$ 300M - 6T) \\
        $\UTinf{1}$ & Maybe & Yes & Probably & (Max. TPS: $\sim$ 50M - $10^{18}$) \\
        $\UTinf{2}$ & Maybe & Yes & Yes & (Max. TPS: $\sim$ 300B - $10^{21}$) \\
        $\UTinf{3}$ & Maybe & Yes & Yes & (Max. TPS: $\sim$ $10^{14}$ - $10^{25}$) \\
        \bottomrule
    \end{tabular}
\label{table:ut-vs-trilemma}
\end{table}

%% END ### RELEASE

%% BEGIN ### DRAFT

%%\input{80-conclusions/50-whats-beyond.tex}

%% END ### DRAFT
