%% BEGIN ### RELEASE

## Attacks

*Ultra Terminum* -- with appropriate configuration -- is resistant to the following attacks; see the linked section for discussion:

- 51% Attack, see \autoref{sec:proof-of-reflection} and \autoref{sec:preventing-dos-attacks}.
- Selfish mining, see \autoref{sec:confirmation-times}
- Reflection without publication, see \autoref{sec:availability-of-blocks}
- Empty block DoS and censorship, see \autoref{sec:dos-and-dags}
- \emph{Nothing at Stake} and \emph{long range} attacks, see \autoref{sec:reflection-pow-and-pos} and \autoref{sec:dapp-chains}

### Dialog: Attacks and Mitigation

\newcommand{\nefName}{EMalo}
\newcommand{\cMax}[1]{\ChatR{title={Max:},colback=Cerulean!20}{#1}}
\newcommand{\cNef}[1]{\ChatL{title={\nefName:},colback=BrickRed!20}{#1}}
\newcommand{\cSe}[1]{\ChatL{title={ESe:},colback=ForestGreen!20}{#1}}

\begin{tcolorbox}[colback=black!70,coltext=white]
    \centering
    This is the beginning of your direct message history with @\nefName
\end{tcolorbox}

\cNef{I have an offer for you. I'm planning on doing a doublespend. It'll destroy confidence in your system. If you pay me, then I won't do it.}

\cMax{Uhh, okay... IDK if you're credible tho. Convince me of that and I'll consider your ``offer''.}

\cNef{I have a bunch of sha256 ASICs. I know that one of the simplex-chains uses that, and it doesn't have that much hashing power behind it, so I'm going to attack it. Std stuff.}

\cMax{You're going to mine in private and then publish after enough confirmations?}

\cNef{Yeah.}

\cMax{The sha256 simplex-chain only has 6\% of the ROO supply on it. Plus, there'll be way too many reflections by the time you try to publish.}

\cNef{Wait, what do you mean ``reflections'', and why does 6\% of the supply matter?}

\cMax{
  Once a block for one chain is published, its existence gets confirmed by the other chains. That's a reflection. There are 15 other simplex-chains, so every sha256 block gets roughly 15 \emph{other} confirmations before the next sha256 block gets produced. The number of confs is a bit random, so mb it's a few less or a few more. The point is that the honest chain will weigh like 15x more than your privately-mined chain, even if your hash-rate is 20x the honest hash-rate.
}

\cMax{
  The 6\% of supply matters b/c the sha256 chain can't have more than 6\% of the total security of the system. Whatever work is done on the sha256 chain is always 6\% of the total network security. You can mb push out some of the other sha256 miners, but that doesn't help you do a doublespend. It just makes them less profitable for a bit, and you waste money running your miners.
}

\cNef{
  I can still selfish mine.
}

\cMax{
  No you can't; selfish mining works b/c you keep some blocks unpublished. If they're not published then they don't get reflections. The honest blocks have an advantage b/c they're published immediately.
}

\cNef{
  I have lots of other ASICs too. And GPUs. I'll mine the ethash chain and the scrypt chain and the cuckoo chain too and just reflect my blocks. Then I'll publish them all at once.
}

\cNef{
  \q{
    and you waste money running your miners
  }
  That's not a problem. The attack will cost you more than it costs me.
}

\cMax{
  Even if you mine those other chains, that's still only 4 out of 16 chains. And they only hold about 30\% of the ROO supply anyway. The honest chains will still have like 3-4x the work of your chains, if not more.
}

\cMax{
  Say that you did try to attack \emph{all} the PoW simplex-chains, what about the PoS ones? You need to pwn those first if you want to 51\% the PoW chains.
}

\cMax{
  \q{
    The attack will cost you more than it costs me.
  }
  We'll see.
}

\cNef{
  I have lots of ROO for PoS chains.
}

\cMax{
  \q{I have lots of ROO for PoS chains.}
  GL with that.
  Since the PoS chains are reflected in the PoW chains, you can't screw with their history to brute-force a favorable quorum --- you'd have to rewrite way too much PoW history for that.
  If you're already PoS mining, then your stake will get slashed the second you publish, so the rest of the network will calc those PoS blocks to have a negative weight.
}
\begin{comment}
%% From above quote
Bribes don't work either b/c the PoS set-up is done on a different chain and reflections from the simplex stop long-range attacks.
\end{comment}

\cMax{
  Not to mention that you can't attack the PoA simplex-chains, anyway. The honest network's always going to have an extra 20\% on you.
}

\cNef{
  %% this box grew too much
  \q{
    \begin{varwidth}{0.91\linewidth}
    Since the PoS chains are reflected in the PoW chains, you can't screw with their history to brute-force a favorable quorum --- you'd have to rewrite way too much PoW history for that.
    \end{varwidth}
  }
  Like I said, it'll cost you more than it costs me. Have you forgotten that I can launch these attacks simultaneously?
}

\cMax{
  \q{simultaneously}
  That's just it. You can't. Attacking the PoS chains requires set-up, which means that you need to attack the PoW chains *at an earlier point in time* than the moment of launch. But attacking the PoW chains won't succeed without the reflections from PoS chains. And if you want to provide lots of PoS reflections, well you need to attack the PoW chains *even further* back to do *that* set-up. Do you see the problem here? Your only option is to *start from the genesis blocks*.
}

\cNef{
  I can still attack some dapp-chains.
}

\cMax{
  How? Dapp-chain history is secured by the PoW done in the simplex. If you try, then your stake will get slashed and things will go back to normal. It's more like a donation than an attack.
}

\cNef{
  Fine. I'll just DoS your chains instead. Like Luke Jr did to Coiledcoin.
}

\cMax{
  Did you forget that UT uses a block-dag? The honest nodes will just build on your blocks and include any txs that you don't. It might take a few minutes, but soon enough the honest blocks will weigh too much for you to catch up (b/c they build on your blocks too). That won't help you doublespend, and the DoS vector doesn't work. You're just \emph{adding} to the security of UT, not reducing it.
}

\cNef{
  Then I'll make bad blocks. They'll get reflected and will screw with the simplex's history.
}

\cMax{
  No they won't. If you try to get headers reflected without blocks, then other miners will reject them b/c the blocks aren't available -- there's no point reflecting them b/c there's no benefit to the miners. If the blocks are invalid, then they will get reflected, but miners on that particular chain will link to them as an invalid uncle.
}

\cMax{
   So if you make invalid blocks, sure nodes will need to store those blocks for a bit (so that they know they were invalid), but after a while all that is prunable. It's a short term inconvenience that still helps the security of the network long term. Plus you won't get block rewards doing that --- so it's actually worse than just making empty blocks. For you, that is.
}

\cMax{
  Still there?
}

\begin{tcolorbox}[title={\pill{\scriptsize{\checkmark \; BOT}} Clyde}]
Your message could not be delivered. This is usually because you don't share a server with the recipient or the recipient is only accepting direct messages from friends.
\end{tcolorbox}

%% END ### RELEASE
