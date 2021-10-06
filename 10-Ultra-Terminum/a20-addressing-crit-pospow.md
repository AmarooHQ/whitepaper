%% BEGIN ### DRAFT

\begin{comment}
# Addressing Zack Hess's Criticism of Hybrid PoW/PoS

Zack Hess has a criticism of hybrid PoW/PoS systems. Since UT might have PoS simplex-chains at some point, it's important that UT be able to address as yet[^asyet] unanswered criticisms like this one.

[^asyet]: To my knowledge. \todo{Chris to weigh in}

The hybrid \emph{context} that UT provides[^hybrid-context] is different to the context provided by a single blockchain that uses a hybrid PoW/PoS consensus mechanism. In UT, each chain is either PoW or PoS (or something else).

[^hybrid-context]: Note that UT can work exclusively with PoW chains, so in the case that PoS cannot be done securely (even with UT's improvements) then this does not break UT fundamentally.

\bquote{
  \cdots \\
  \\
  If it is the kind of PoS mechanism that is based on something like coin-age, so even if most PoS validators stop participating, PoS blocks can still be found, then we need to consider a some cases based on the fork-choice rule. In a hybrid design, the fork-choice rule depends on some combination of P = portion of PoS validators participating, and H = the amount of hashpower. \\
  \\
  We have a fork choice rule weight(H, P). \\
  \\
  Increasing PoS participation, or increasing hashpower, can only have a positive influence on the weight of that subchain. \\
  \\
  The cost to take majority control of the PoS portion is cheap, because of market failure in voting systems. So lets consider the case where the attacker has 2/3rds control of the validator stake.
  normal = weight(H0, P), attacker = weight(H1, P*2). \\
  \\
  To calculate how much hashpower the attacker would need to have exactly 50% likelyhood of the attack succeeding: \\
  \\
  F1: weight(H1, P*2) = weight(H0, P). \\
  \\
  lets suppose that the pow/pos hybrid design is more secure than pow, or at least equally secure. This means that the attacker's hashpower needs to be bigger than the network hashpower for the attack to succeed. (We will use proof by contradiction to show that this supposition is false.) \\
  \\
  S1: H1 > H0. \\
  \\
  Since weight only increases as participation increases, that means that: \\
  \\
  F2: weight(H1, P*2) > weight(H1, P) \\
  \\
  since weight only increases as hashrate increases, and H1 > H0, that means that: \\
  \\
  F3: weight(H1, P) > weight(H0, P) \\
  \\
  combining F2 and F3, we get that \\
  \\
  weight(H1, P*2) > weight(H0, P). \\
  \\
  but this contradicts with F1.
  so S1 must be false. \\
  \\
  Therefore H0 > H1. \\
  \\
  This means that it is always cheaper to do a hashrate rental attack against a pow/pos hybrid than against a normal pow blockchain.
}{Zack Hess; \href{https://github.com/zack-bitcoin/amoveo-docs/blob/9a4ffa2e800c24772fd68e1f745b6a14967e59c2/other_blockchains/pow_pos_hybrid.md}{PoW/PoS Hybrid Consensus Mechanisms}}

UT has two main complicating factors: simplex-chains are DAGs instead of trees (see \autoref{sec:dos-and-dags}), and the contribution of a chain's security contribution is capped via chain-work conversion (see \autoref{sec:reflection-pow-and-pos} and \autoref{sec:generalizing-reflection}). These answers assume that the the PoS method is DAG-compatible, that PoS validators can choose when to produce a block, and that (todo)

\q{
    Increasing PoS participation, or increasing hashpower, can only have a positive influence on the weight of that subchain. (We will use proof by contradiction to show that this supposition is false.)
}

\q{
  Since weight only increases as participation increases, that means that: \\
  \\
  F2: weight(H1, P*2) > weight(H1, P)
}



In UT, the weight contributed by a PoW or PoS reflection depends on the conversion method (part of UT's fork-choice rule), which depends on the value on each of those chains. Thus, it's not the case that ``increasing PoS participation, or increasing hashpower, can only have a positive influence on the weight of that subchain''[^subchain].

Particularly, Hess starts his proof with S1:

\todo{finish hybrid pow/pos stuff or clean up}

[^subchain]: The idea of \emph{subchains} is specific to individual blockchains that use a hybrid PoW/PoS consensus mechanism. I think the correct conversion of the idea of a \emph{subchain} to a UT context is to view the simplex (see \autoref{sec:the-simplex}) as a single chain, and simplex-chains as subchains.
\end{comment}

%% END ### DRAFT
