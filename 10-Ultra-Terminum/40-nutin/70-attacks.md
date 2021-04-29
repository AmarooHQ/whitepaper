## Attacks

\mk{
  the dialogs are a bit sparse on the page with the current formatting. mb they should be a bit more condensed. I like the colors tho -- let's you scan quickly. I guess that left/right alignment does that somewhat too, tho.
}

### Dialog: Attacks and Mitigation

\newcommand{\nefName}{ExMalo}
\newcommand{\cMax}[1]{\ChatR{title={Max:},colback=Cerulean!20}{#1}}
\newcommand{\cNef}[1]{\ChatL{title={\nefName:},colback=BrickRed!20}{#1}}
\newcommand{\cSe}[1]{\ChatL{title={ExSe:},colback=ForestGreen!20}{#1}}

\begin{tcolorbox}[colback=black!70,coltext=white]
    \centering
    This is the beginning of your direct message history with @\nefName
\end{tcolorbox}

\cNef{I have an offer for you. I'm planning on doing a doublespend. It'll destroy confidence in your system. If you pay me, then I won't do it.}

\cMax{Uhh, okay... IDK if you're credible tho. Convince me of that and I'll consider your "offer".}

\cNef{I have a bunch of sha256 ASICs. I know that one of the simplex-chains uses that, and it doesn't have that much hashing power behind it, so I'm going to attack it. Std stuff.}

\cMax{You're going to mine in private and then publish after enough confirmations?}

\cNef{Yeah.}

\cMax{The sha256 simplex-chain only has 6\% of the ROO supply on it. Plus, there'll be way too many reflections by the time you try to publish.}

\cNef{Wait, what do you mean "reflections", and why does 6\% of the supply matter?}

\cMax{
  Once a block for one chain is published, its existence gets confirmed by the other chains. That's a reflection. There are 15 other simplex-chains, so every sha256 block gets roughly 15 \emph{other} confirmations before the next sha256 block gets produced. The number of confs is a bit random, so mb it's a few less or a few more. The point is that the honest chain will weigh like 15x more than your privately-mined chain, even if your hashrate is 20x the honest hashrate.
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
  Say you attacked \emph{all} the PoW simplex-chains, what about the PoS ones? You can't mine those, too.
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
  GL with that. Since the PoS chains are reflected in the PoW chains, you can't screw with their history to brute-force a favorable quorum --- you'd have to re-write way too much PoW history for that. If you're already PoS mining, then your stake will get slashed the second you publish, so the rest of the network will calc those PoS blocks to have a negative weight.
}

\cMax{
  Not to mention that you can't attack the PoA simplex-chains, anyway. The honest network's always going to have an extra 20\% on you.
}

\cNef{
  I can still attack some dapp-chains.
}

\bigtodo{look into PoS bribe attacks}

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

### Dialog 2

\mk{
  should redo the intro -- too slow / wasted space on page.
}

\cMax{
  chatlog-{\lowercase{\nefName}}.txt (6 KB)
}

\cMax{
  What do you think?
}

\cSe{
  Seems okay as illustration, but it's not very detailed.
}

\cMax{
  Any ideas on what I should do?
}

\cSe{
  Convince \emph{me}.
}

\cSe{
  I've read the WP. Let's start from the top --- reflection. Start from first principles and build the idea up. I'll ask Qs as we go.
}

\bigtodo{
  Continue dialog.
}

### Analysis of Existing Attacks

\todo{Link to response locations for: 51\%, publishing bad data, selfish mining, dag-based, reflection stuff}




\begin{comment}

### 51% and double-spends

\bigtodo{discuss 51 percent and how difficult it is in UT vs Bitcoin, et al.}

need to do 51% attacks on 51% of simplex chains - worst case, that mb isn't enough

similar to how you can theoretically win govt in a democracy by winning 51% of votes in 51% of electorates => only 25% of total votes. it's still harder than winning 51% of votes in one seat, tho.

\mk{
  I think I was wrong here; you need more than 51\% of 51\% b/c of private mining. so you still need 51\% overall, tho that can be more/less in diff simplex-chains.
}

### Poisoning the Well

\bigtodo{the deliberate and malicious production of malformed data}

- e.g. making blocks with valid PoW but invalid contents so that they get reflected (soln: miners can reject blocks or link to blocks as invalid; no block reward for producer)

### Selfish Mining

\bigtodo{discuss selfish mining, and how it doesn't work}

- Proof of Reflection means that withholding blocks is a big disadvantage b/c you want the network (and other chains) to know about them ASAP. Attack doesn't work.

### DAG based attacks

- creating lots of DAG blocks to link back to with low PoW (soln: no variable PoW targets or min limit)
- more backlinks -> larger headers -> lower total throughput (soln: max numbers of backlinks + min PoW target)

\end{comment}
