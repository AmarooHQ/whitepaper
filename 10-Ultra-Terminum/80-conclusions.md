%% BEGIN ### RELEASE

\newpage

# Conclusions

\label{sec:conclusions}

\assignedTODO{{Max}}{h}{Write conclusion}

## Comparison: ``The Big 4''

The following comparisons (\autoref{table:compare_nets_3k}, \autoref{table:compare_nets_20k}, and \autoref{table:comparison_1m_tps}) are intended to be an *apples to apples* comparison between UT variants and ``The Big 4'': Bitcoin, Cardano, Eth2, and Polkadot.
Cardano, as a cutting-edge network, is an exception here: the Cardano/IOHK teams have not been pursuing \emph{Layer 1} scalability solutions --- unlike the Eth2 and Polkadot teams --- and are focusing instead on a \emph{Layer 2} solution: Hydra via EUTXOs.
Their work is good and promising.
I mention this particularly because the nature of an *apples to apples* comparison casts Cardano in a light that some might consider to be misleading.
However, these comparisons do not consider \emph{Layer 2} scalability solutions for one very simple reason: all networks can implement them in some fashion.
It is not a fair (or accurate) comparison *of blockchain architecture* if \emph{Layer 2} scaling solutions are considered for some networks and not for others.
\begin{comment}
Additionally, as mentioned in [Ethereum's *Sharding FAQs*](https://eth.wiki/sharding/Sharding-FAQs#how-does-plasma-state-channels-and-other-layer-2-technologies-fit-into-the-trilemma), payment- and state-channels provide a *constant factor* increase in throughput, so those techniques will not improve a network's scaling complexity as it is measured here.
\end{comment}

In addition to those four, a network named *Opt.Shard* (for *Optimal Sharding*) is included in these comparisons.
This is a theoretical network which uses the \emph{best parameters possible among UT configurations}.
No real-world sharded network has come close to this level of performance, and it is incompatible with PoS.

\defineTermTex{Scaling Factor}{
    Also: ``Scale $\times$''. For a given $k$, it is the factor by which TPS increases with an additional nesting level.
    In effect, it allows for comparison of the efficacy of scaling schemes when $k$ is fixed.
    For some designs, the \emph{Scaling Factor} can change between nesting levels
}

\pz{Last row with infinity: theoretically yes, but is it practically achievable?}
%% INSERT ### TABLE: compare_nets_3k

: A comparison of quantitative scaling properties between UT and various networks given $k = 3000$ bytes/s. Transaction size is set to 250 bytes, $D_f = B_f$, and $D_h = B_h$.

%% INSERT ### TABLE: compare_nets_20k

: Similar to the previous table, but with $k = 20$ KB/s instead of 3 KB/s.

%% INSERT ### TABLE: comparison_1m_tps

: A comparison of computational requirements (approximated by $k$) for 1 million TPS between UT and various other networks. $\UT{2}$'s equivalent TPS is also provided (given the same parameters of $k$, $B_f$ and $B_h$).

\begin{comment}
%% INS--ERT ### TABLE: comparison_1gbps

: A comparison of various networks' $k$ and TPS given a maximum network-wide throughput of 1 Gb/s ($\sim1.3\times 10^8$ B/s). Also included is the rate at which chains on that network grow in size (which is proportional to $k$).
\end{comment}

\ctable[
    pos = htb,
    caption = Table evaluating various other networks against trilemma criteria.,
    cap = Table evaluating various other networks against trilemma criteria.,
    center,
    label = tab:other-nets-trilemma,
]{lllll}{
    \tnote[*]{Real-world performance of Bitcoin; $k \approx 1700$ B/s; $\text{Tx}_\text{avg} \approx 375$ B.}
    \tnote[$\!$\#,$\|$,\P]{Prediction based on $3000 \le k \le 20000$.}
    %\tnote[et]{Prediction based on $3000 \le k \le 20000$.}
    %\tnote[pt]{Prediction based on $3000 \le k \le 20000$.}
    \tnote[\S]{
        Assuming $3000 \le k \le 20000$ and that child-chains use PoW + PoR with the smallest possible headers.
    }
    \tnote[PoS]{
        \href{\linkZackPoSCriticisms}{Unanswered criticisms of PoS} (\href{\linkZackPoSDefence}{replies})
        mean that we cannot conclude that PoS is $O(n)$ secure.
        Saying PoS is ``Maybe'' $O(n)$ secure is being kind --- since there are unanswered criticisms, we should really conclude ``No''.
        (There are no such unanswered criticisms of PoW-based consensus.)
    }
    \tnote[$\dagger$]{
        \href{https://web.archive.org/web/20241227202028/https://solana.com/solana-whitepaper.pdf}{PoH} is $O(c)$ secure by design.
        Solana uses PoS on top of PoH, but it's unclear which has precedence (and one must).
        Additionally, since a $\le O(c)$ DoS has brought down Solana before, this is an upper limit on Solana's security.
    }
    \tnote[$\ddagger$]{
        Even though Solana requires $k \approx 10^8$ ($\sim$ 12 MB/s) for 50K TPS, this is consistent with their published ``strategy'' for ``scaling''.
        50K is chosen as the limit because \href{\linkSolanaFiftyKClaim}{the official site claims \emph{at least} 50K as the upper limit} and \href{\linkSolanaFourHundKFail}{400K is known to be beyond Solana's capabilities}.
        (Note: this also earns Solana a decisive ``No'' under the ``Decentralized?'' column.)
    }
}{
        \FL
        Network & Decentralized? & $O(n)$ Secure? & \multicolumn{2}{l}{$O(n)$ Scalable?}
        \ML
        Bitcoin   & Yes           & Yes              & No    & (Max. TPS: $\sim$ 5)\tmark[*] \NN
        Cardano   & Yes           & Maybe\tmark[PoS] & No    & (Max. TPS: $\sim$ 10 - 80)\tmark[$\!$\#] \NN
        Solana    & No\tmark[$\ddagger$]  & No ($O(c)$)\tmark[$\dagger$] & Maybe & (Max. TPS: $\sim$ 50K)\tmark[$\ddagger$] \NN
        Polkadot  & Maybe         & Maybe\tmark[PoS] & Maybe & (Max. TPS: $\sim$ 200 - 12K)\tmark[\P] \NN
        Eth2      & Maybe         & Maybe\tmark[PoS] & Maybe & (Max. TPS: $\sim$ 1K - 62K)\tmark[$\|$] \NN
        Opt.Shard & Yes           & Yes              & Maybe & (Max. TPS: $\sim$ 8K - 350K)\tmark[\S]
        \LL
}

## Addressing *Buterin's Trilemma*

\pz{Clarify $\lambda$ and $T$}

This paper introduced a new consensus mechanism, proof of reflection, that solves the Buterin trilemma by achieving scalability without compromising on decentralization or on security.
At the core of this approach resides the ability for blockchains to share security using reflection while keeping the state of each chain local.
Scalability and decentralization result from the fact that each chain only needs to process an $O(c)$ load for its chain state and an $O(c)$ load for the PoR graph, and $O(n)$ security is achieved through reflection whereby each chain becomes as secure as the network.

\begin{figure}[H]
\centering
\includegraphics[max width=\linewidth]{trilemma/conflict_resolution_sag}
\caption{A solution to the core conflict of \textit{Buterin's Trilemma}.}
\label{fig:trilemma-core-conflict-solved}
\end{figure}

Each chain state is independent and has its own specifications, thus allowing for a multitude of chain implementations to meet the needs of virtually any application.
However, chains are not siloed and we presented a secure cross-chain protocol that enables chains to communicate and transfer assets between them.
In essence, cross-chain transactions enable chains to converge toward an Internet of blockchains.

Finally, with tiling configurations, chains can optionally adopt a solution that pushes throughput even further while still benefiting from the security of the network.
With UT$_\aleph$, the network can achieve unbounded throughput and open the way to a truly ubiquitous blockchain.
In \Cref{table:ut-vs-trilemma}, we present an evaluation of the throughput of the UT variants.

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
        $\UTinf{1}$ & Yes & Yes & Probably & (Max. TPS: $\sim$ 50M - $10^{18}$) \\
        $\UTinf{2}$ & Yes & Yes & Yes & (Max. TPS: $\sim$ 300B - $10^{21}$) \\
        $\UTinf{3}$ & Yes & Yes & Yes & (Max. TPS: $\sim$ $10^{14}$ - $10^{25}$) \\
        \bottomrule
    \end{tabular}
\label{table:ut-vs-trilemma}
\end{table}

%% END ### RELEASE

%% BEGIN ### DRAFT

%%\input{80-conclusions/50-whats-beyond.tex}

%% END ### DRAFT
