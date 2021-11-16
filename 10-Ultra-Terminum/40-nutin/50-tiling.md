%% BEGIN ### RELEASE

\subsection{\texorpdfstring{$\text{UT}_{\aleph}$}{UT-aleph}: Tiling Simplexes}

\label{sec:tiling}

\defineTerm{Maximal Simplex}{
    A simplex with the maximum number of simplex-chains under $O(c)$ constraints
}

Tiling is a method which allows UT to scale with order $O(n)$. When UT simplexes are tiled, I call the result a *simplex tiling*.

\defineTerm{Simplex Tile}{
    Like a simplex, but $>75\%$ of the PoR capacity is reserved for reflections with \emph{neighboring} tiles; typically a quadrifurcated maximal simplex
}

\todoDraftOnly{terms and edit / refactor this section}

A simplex tile, on its own, is very similar to a standalone simplex. If a standalone simplex (of a given capacity) could host $1600$ simplex-chains, then an equivalent simplex tile will host $400$ (or maybe less); only $25\%$ of the PoR capacity is reserved for *internal* reflections -- i.e., reflections within that simplex tile. The other $75\%$ is reserved for *external* reflections to simplex-chains in *neighboring* tiles.

That is: it is a simplex that deliberately reserves only $\nicefrac{1}{4}$ of its otherwise maximum PoR capacity for internal reflections.
By definition, the maximum PoR capacity of a tile is $\nicefrac{1}{4}$ the maximum PoR capacity of an equivalent maximal simplex.
Why quadrifurcate capacity like this?
In a maximal simplex, all reflections are between simplex-chains within that simplex, i.e., all reflections are internal.
However, if a simplex reserves $\nicefrac{3}{4}$ of a its maximum capacity, that simplex (which thus becomes the root tile) can reflect every simplex-chain in 3 adjacent tiles (at least 2 of which are 'child' tiles).
Those child tiles do not reflect their siblings, though; initially, their only external reflections are with simplex-chains in the parent tile.
Each child tile, at this stage, has only reserved 50% of its full PoR capacity -- 25% for externally reflecting its parent's simplex-chains, and 25% for internally reflecting its own simplex-chains.
Thus, each tile is able to reflect all simplex-chains of the parent tile *and* two additional child tiles.
Child tiles can be instantiated in an ad-hoc basis, i.e., as a simplex-tiling (or an individual tile) approaches maximum capacity.

\defineTerm{Simplex Tiling}{An interconnected graph of mutually reflecting simplexes. This graph grows in a scalable manner when simplex tiles have a valence $\ge 3$}

\todoDraftOnly{
    from forum: \\
    max:[When a simplex does tiling:] it's not that `k` decreases, but the proportion of `k` dedicated to internal reflections decreases. like it's optimal to have `k/2` dedicated to reflections, and `k/2` dedicated to transactions. when tiling with a valence of 3, the `k/2` for reflections is quadrifurcated, so there's `k/8` dedicated for each group of reflections (internal, parent, child1, child2). \\
    leesa: oki yup this makes a lot of sense now. I felt like the `k` explanations were helpful in solidifying understanding. I think bc it helped to make the concept more concrete since it linked back to the proofs.
}

### Tile Valence

\label{sec:tile-valence}

Tiles *must* have a valance, $v$, of $v \ge 3$ for $O(n)$ scaling.
If tiles had a valence of 0, then no additional tiles can be added.
If tiles had a valence of 1, then only a single additional tile could be added (for a total of 2) but no more.
If tiles had a valance of 2, then the 'shape' that the tiles created would be a linear chain; a tile-chain.
For a tile-chain of length $n$, proving state on the far end of the chain would take $n$ SPV proofs, which is untenable.

However, if tiles have a valance of $3$, then each tile has up to 3 neighbors.
For all tiles but the first, this is equivalent to being a node in a binary tree (where each non-root, non-leaf node has 1 parent and 2 children: 3 neighbors).
In essence, this method of tiling simplexes results in 3 distinct binary trees as children of a single root tile -- this can be seen in \autoref{fig:tiled-simplex-5-d3}.

Increasing the valence beyond 3 does not make sense, though. There are two reasons for this.
The first reason is that, for complexity orders involving logarithms, higher valences change the *base* of the logarithms; and that has no effect on the order of complexity\footnote{
    Complexity orders involving logarithms are sensitive to changes in the base \emph{if} the logarithms are part of an exponent.
    e.g., $O(3^{\log_2 n}) > O(3^{\log_4 n})$.
    These considerations aren't relevant here, though.
}.
The second reason is: an increase in valence means that the tile's capacity for reflections is divided into more pieces, only one of which is reserved for internal reflections; that means that the tile will have fewer internal reflections (and more external reflections) which decreases confirmation rate.
 <!-- and the security of leaf tiles. -->

\todo{revisit the above: The second reason is: an increase in valence means that the tile's capacity for reflections is divided into more pieces, only one of which is reserved for internal reflections; that means that the tile will have fewer internal reflections (and more external reflections) which decreases confirmation rate.}

### Tree Tiling

As shown in \autoref{sec:tessellating-tiles-efficiency}, there are different ways to arrange a tiling.
We will focus on a tiling method that exploits the exponential growth of \emph{trees}.
Particularly, trees of branching factor $v - 1$ (so $v=3$ corresponds to binary trees, $v=4$ corresponds to ternary trees, etc).

#### The First Tile

\begin{figure}
\centering
\includegraphics[width=50mm]{simplex_5_sag}
\caption{The initial state of a 5-chain simplex-tile before tiling. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
\label{fig:tiled-simplex-5-d0}
\end{figure}

\autoref{fig:tiled-simplex-5-d0} assumes an $O(c)$ node has capacity for tracking $4 \cdot n$ simplex-chains, with $n = 5$. In reality, an $O(c)$ node has capacity to track between $100$ to $10,000$ simplex-chains (this implies $25$ to $2,500$ simplex-chains per tile). Simplexes and simplex-tilings of that magnitude are impractical to illustrate.

#### Adding Tiles

A tiling 'iteration' is the process by which new tiles are added. For the sake of simplicity and demonstration, each iteration will add *all possible new tiles* as children of all 'leaf' tiles -- though in reality there's no requirement that new tiles be added at the same time, or that tiles are added in a balanced fashion.

We start from the foundation that each tile has a maximum of $\frac{N_1}{4}$ simplex-chains, where $N_1$ is the maximum capacity of a maximal simplex. That is: if one computer (based on $O(c)$ reasoning) could be a full node[^simplex-full-validation] for a simplex-chain in a 4000-simplex, then each tile will have, at most, 1000 simplex-chains. Since a tile is adjacent to $\le 3$ other tiles, a tiled simplex-chain will have, at most, $N_1$ reflections (since a tile and its neighbors have, at most, $\frac{N_1}{4}$ simplex-chains, and all of those simplex-chains are reflected).

[^simplex-full-validation]: A full node for a simplex-chain does not need to fully validate any other simplex-chains, or dapp-chains on that simplex-chain.

Our starting point is a $\frac{N_1}{4}$-simplex which constitutes a single tile.
This is shown in \autoref{fig:tiled-simplex-5-d0}.

The next iteration is to add $3$ adjacent tiles, since tiling has a valence of 3. Each of these new tiles has one pre-existing neighbor (the root tile), so each new tile has capacity for 2 more neighbors. Thus, the next iteration will add twice the number of tiles as the preceding iteration -- in this case, $6$ new tiles. This pattern -- adding twice the number of tiles as the previous iteration -- continues indefinitely.

\begin{comment}
side by side figures: https://tex.stackexchange.com/questions/37581/latex-figures-side-by-side
\end{comment}

\begin{figure}
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_s5_d1_sag}
        \caption{1st iteration. 4 tiles.}
        \label{fig:tiled-simplex-5-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_s5_d2_sag}
        \caption{2nd iteration. 10 tiles.}
        \label{fig:tiled-simplex-5-d2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_s5_d3_sag}
        \caption{3rd iteration. 22 tiles.}
        \label{fig:tiled-simplex-5-d3}
    \end{subfigure}
    \caption{The state of tiled 5-chain simplexes after sequential iterations. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
    \label{fig:simplex-tiling}
\end{figure}

### Tiling Complexity

Two elements of complexity will be analyzed: the size of SPV proofs between simplex-chains, and the network capacity overall.

If our tiling is balanced (in the sense that a binary tree can be balanced) then the root tile has 3 children, each of which is the root node of a balanced binary tree.
If those trees have a height of $h-1$, then each have $2^{h} - 1$ total nodes.
The height of the trees is set to $h-1$ so that the full tiling has a height of $h$.
There are 3 such trees, plus the root tile.
The number of tiles in the full tiling is thus:
\begin{equation}
\begin{split}
N_{\text{tiles}} & = 3 \cdot (2^{h} - 1) + 1 \\
& = 3 \cdot 2^h - 2 \label{eq:n-tiles}
\end{split}
\end{equation}

and in general, for some valence, $v \ge 3$:
\begin{equation}
\begin{split}
N_{\text{tiles}} &= v \cdot \frac{(v-1)^h - 1}{v - 2} + 1 \\
\therefore O(N_{\text{tiles}}) &= O((v-1)^h)
\label{eq:n-tiles-general}
\end{split}
\end{equation}

From \autoref{eq:n-tiles-general}, the number of tiles at height $h \ge 1$ (denoted $N_{\text{tiles}|h}$) is:
\begin{align}
    N_{\text{tiles}|h} &= v \cdot \frac{(v-1)^h - 1}{v - 2} + 1 - (v \cdot \frac{(v-1)^{h-1} - 1}{v - 2} + 1)
    \nonumber \\
    %%&= v\Big( \frac{(v-1)^h - (v-1)^{h-1}}{v - 2}\Big)
    %%\nonumber \\
    &= v \cdot (v-1)^{h-1}
    \label{eq:n-tiles-at-h-def} \\
    \therefore O(N_{\text{tiles}|h}) &= O((v-1)^h)
\end{align}

Since we defined the height of each binary tree as $h-1$ (and the root tile adds 2 hops), the maximal distance between leaf tiles is $2h$.
This is also the maximal number of SPV proofs required to prove state between any two simplex-chains. Given \autoref{eq:n-tiles}:
\begin{equation}
\begin{split}
N_{\text{tiles}} & = 3 \cdot 2^h - 2 \\
\log_{2}(\frac{N_{\text{tiles}} + 2}{3}) & = h \label{eq:tiles-h}
\end{split}
\end{equation}

Thus, the maximal distance between leaf tiles is $2 \cdot \log_{2}(\frac{N_{\text{tiles}} + 2}{3})$, and thus the number of SPV proofs required (across simplex-chains) scales with $O(\log_2 N_{\text{tiles}})$.

Consider that tiles can be added in an ad-hoc fashion depending on current capacity requirements, and each tile has capacity in $O(c^j); j \in \{2,3,4\}$.
Since we can always add tiles, we can always ensure there is \emph{excess capacity}.
Provided we do this, then the number of tiles required is roughly the capacity used by the network ($n$) divided by the capacity of each tile ($c^j$).
Thus, successful $O(n)$ scaling depends upon our ability to maintain this relationship:
\begin{equation}
\begin{split}
    O(N_{\text{tiles}}) &\ge O(\frac{n}{c^j}) \\
    \implies O((v-1)^h) &\ge O(\frac{n}{c^j}) \\
    \implies O(h) &\ge O(\log \frac{n}{c^j}) \\
    &\ge O(\log n - \log c) \\
    &\ge O(\log n)
    \label{eq:o-n-tiles-in-terms-of-c}
\end{split}
\end{equation}

\begin{comment}
\begin{equation}
\begin{split}
    O(N_{\text{tiles}} \cdot c^j &> n \\
    \therefore O(N_{\text{tiles}} \cdot c^j) &> O(n)
    %%\label{eq:o-n-tiles-in-terms-of-c}
\end{split}
\end{equation}
\end{comment}

Given \autoref{eq:spv-complexity}, dapp-chain inter-tile SPV proofs have order:
\begin{equation}
\begin{split}
O(\log c + \log N_{\text{tiles}}) &\ge O(\log c + \log n) \\
&\ge O(\log n) \label{eq:tiled-spv-complexity}
\end{split}
\end{equation}

If it's possible that $O(N_{\text{tiles}}) \ge O(\frac{n}{c^j})$ then we can limit it to $O(N_{\text{tiles}}) = O(\frac{n}{c^j}) \iff O(h) = O(\log n)$.
This will limit inter-tile SPV proofs to order $O(\log n)$.

In \autoref{eq:o-n-tiles-in-terms-of-c} we assume that $O(N_{\text{tiles}}) \ge O(\frac{n}{c^j})$ is possible.
On this assumption, given that each tile has order $O(c^j)$, the complexity of the network overall is given by the product of a tile's order and the number of tiles:
\begin{equation}
\begin{split}
O(c^j \cdot N_{\text{tiles}}) & = O(c^j \cdot \frac{n}{c^j}) \\
& = O(n)
\label{eq:simplex-tiling-complexity}
\end{split}
\end{equation}

For all practical purposes, if we can grow the tiling fast enough, $\UTinf{}$ provides unbounded capacity.

%% END ### RELEASE

%% BEGIN ### DRAFT

The above assumes that tiles have equal capacities; what if they do not?
The total capacity of $O(c)$ base-chains in a tree tiling ($\Sigma T_1$) is the sum of their capacities.
There are several ways for a simplex-tile to increase or decrease in capacity: e.g., that tile might increase $k_{1,tx}$ for all simplex-chains, or contain fewer simplex-chains.
For the sake of analysis, let's ignore the \emph{details} of differing capacity, and assume there is a consistent *ratio* ($0 < r \le 1$) between a tile's child's capacity and that tile's capacity.
That is: tiles introduced at each iteration are $r\times$ the capacity of their parent.

Let $t$ refer to the root tile's $T_1$ (capacity). For a small tilings, we can say:
\begin{align*}
  \text{max } h = 0 & \implies \Sigma T_1 = 1tr^0 \\
  \text{max } h = 1 & \implies \Sigma T_1 = 1tr^0 + 3tr^1 \\
  \text{max } h = 2 & \implies \Sigma T_1 = 1tr^0 + 3tr^1 + 6tr^2
\end{align*}

In general (via \autoref{eq:n-tiles-at-h-def}):
\begin{align}
    \Sigma T_1 &= t\Big( 1 + \sum_{h=1}^h N_{\text{tiles}|h} \cdot r^h \Big)
    \nonumber \\
    &= t\Big( 1 + \sum_{h=1}^h v(v-1)^{h-1} \cdot r^h \Big)
\end{align}

Let us find the bounds under which this sum converges as $h \rightarrow \infty$:
\begin{align}
    \Sigma T_1 &= t\Big( 1 + \sum_{h=1} v(v-1)^{h-1} \cdot r^h \Big)
    \nonumber \\
    r (v-1) \Sigma T_1 &= t\Big( r(v-1) + \sum_{h=1} v(v-1)^{h} \cdot r^{h+1} \Big)
    \nonumber \\
    \therefore \Sigma T_1 - r (v-1) \Sigma T_1 &= \; t \cdot ( 1 + vr + vr^2(v-1) + vr^3(v-1)^2 \cdots
    \nonumber \\
    & \;\;\;\; - r(v-1) - vr^2(v-1) - vr^3(v-1)^2 \cdots )
    \nonumber \\
    (1 - r(v-1)) \cdot \Sigma T_1 &= t(1 + vr - r(v-1))
    \nonumber \\
    &= t(1 + r)
    \nonumber \\
    \therefore \Sigma T_1 &= t \cdot \frac{1 + r}{1 + r - rv}
    \label{eq:sigma-t1-conv}
\end{align}

For the sum to converge, the denominator of \autoref{eq:sigma-t1-conv} ($1 + r - rv$) must be positive; the sum diverges when the denominator is negative.
Let us consider when the sum diverges:
\begin{align}
    0 &> 1 + r - rv \nonumber \\
    r(v-1) &> 1 \nonumber \\
    r &> (v-1)^{-1}
    \label{eq:tiling-capacity-constraint}
\end{align}


\begin{comment}
\begin{align}
    \\
    \intertext{When sum is greater than valence $\implies$ 'worth it' compared to no tiling. note, should be v+1 on RHS below}
    \frac{1 + r}{1 + r - rv} > v \\
    1 + r > v + rv - rv^2 \\
    rv^2 - rv - v + 1 + r > 0 \\
    rv^2 - v(r + 1) + r + 1 > 0 \\
    \intertext{zeros at:}
    v = \frac{r + 1}{2r} \pm \frac{\sqrt{(r+1)^2 - 4r(r + 1)}}{2r} \\
    v = \frac{r + 1}{2r} \pm \frac{\sqrt{r^2 + 2r +1 - 4r^2 - 4r}}{2r} \\
    v = \frac{r + 1}{2r} \pm \frac{\sqrt{-3r^2 - 2r + 1}}{2r} \\
    -3r^2 - 2r + 1 > 0 \\
    1 > 2r + 3r^2 \cdots \\
    \intertext{back to orig}
    \frac{1 + r}{1 + r - rv} > v + 1 \\
    1 + r > 1 + r - rv + v + rv - rv^2 \\
    0 > v - rv^2 \\
    rv^2 > v \\
    r > v^{-1}
\end{align}
\end{comment}

Thus, $\Sigma T_1$ \emph{does not converge} when $r > (v-1)^{-1}$.
In other words, $\Sigma T_1$ converges when $r < (v-1)^{-1}$.

A \emph{requirement} for \emph{unbounded} tiling (via the tree method) is that the ratio of a child-tile's capacity to that of their parent is $r > (v-1)^{-1}$.

There are practical issues that come with $r \sim (v-1)^{-1}$, like that there are minimum requirements for the capacity of a blockchain (e.g., none can run with $k < 1$ B/s).
To avoid practical issues: $r \gg (v-1)^{-1}$.
Ideally, $r \approx 1$ (ensuring $O(c)$ limits on nodes are respected).
This is possible, and is discussed in \autoref{sec:tiling-sec-cap-asymmetry}.

$\Sigma T_1$ diverging implies $O(n)$ scalability \emph{if} the lower bound on the capacity of a tile at height $h$ is $O(c^j \cdot r^h) > O(c^j \cdot (v-1)^{-h})$.
The essence of $\Sigma T_1$ diverging is that \emph{there is always meaningful capacity to add} when the network requires it.

Let's discuss \autoref{eq:o-n-tiles-in-terms-of-c} and \autoref{eq:tiled-spv-complexity}.
It's plain to see that, if $r \approx 1$, then child tiles have the same capacity as their parent, so each tile has $O(c^j)$ capacity.
Given \autoref{eq:n-tiles-general}, the capacity of a tiling with $r \approx 1$ and height $h$ is in $O(c^j \cdot (v-1)^h)$.
For the $O(n)$ claim in \autoref{eq:simplex-tiling-complexity} to hold, we need $O(n) < O(c^j \cdot (v-1)^h)$.
This matches what we said earlier.
\todo{this bit}

%% END ### DRAFT

%% BEGIN ### RELEASE

How can it be possible for a network of blockchains to have $O(n)$ capacity, and $O(n)$ security, without breaking $O(c)$ constrains on full nodes?
It is because of a \emph{new asymmetry} between \emph{capacity} and \emph{security}.

### Tiling Security

#### A New Asymmetry Between Capacity and Security

\label{sec:tiling-sec-cap-asymmetry}

If there is a \emph{symmetry} between capacity and security, that means they're \emph{coupled} somehow; i.e., a change in one results in a change to the other.
In this case, they're inversely related -- this is essentially a restatement of Buterin's trilemma!
In traditional blockchain designs that have a maximum block size, the tradeoffs described in \autoref{sec:core-conflict} are describing the symmetry: increasing capacity negatively effects security, and vice versa.

To claim that the trilemma is broken is to claim that this symmetry has been broken.

Traditional PoW already provides for practically unbounded security.
Currently\footnote{
    Bitcoin block 709793 has difficulty 22,674,148,233,453.11, corresponding to an expected $\sim 2^{76.366}$ hashes per block.
}, Bitcoin blocks require a $\sim 76.4$ zero-bit prefix (which is the proof of work).
So, for half of a Bitcoin PoW hash to be half-zeros (i.e., have a 128 zero-bit prefix), $\sim 51.6$ doublings in hash-rate need to happen.
To date, only $\sim 44.4$ such doublings have occurred; i.e., current blocks require $\sim 2^{44.4}\times$ as many hashes as early Bitcoin blocks required.
Clearly, PoW has excess capacity in the potential security it provides.
However, traditional PoW networks don't scale horizontally.

With regards to $\UTinf{}$, let's take stock.
We've already taken care of the \emph{decentralization} criterion by setting the upper computational complexity to $O(c)$ (via $k$ in \autoref{sec:ut-complexity}).
We've also seen that tiling is a method for unbounded \emph{capacity}, but only if it's secure (which we haven't yet seen).
We know that there's excess capacity in PoW itself, so the only remaining thing to show is that tiling is secure.
If tiling is secure, then the asymmetry is real.
If tiling is secure, then the core conflict of the trilemma is broken.

So, that's the question: *is performing a doublespend in a tiling as difficult as attacking 51% of the network?*

#### Tiling Security: $h=0$

At $h=0$, all tilings are equivalent to a standalone simplex: all simplex-chains reflect all other simplex-chains.
(This is also true for tiling variants mentioned in \autoref{sec:tiling-variants}.)
Thus, trivial tilings (those with $h=0$) are secure if standalone simplexes are secure.

#### Tiling Security: $h=1$

\providecommand\sec[1]{\text{Sec}(#1)}

This configuration corresponds to \autoref{fig:tiled-simplex-5-d1}.

What are the requirements for 51% attacking the root tile?
In this case, since all chains in the root tile mutually reflect all chains in the tiling (like a normal simplex), an attacker would need at least 51% the resources of the network.
So, a network-wide 51% attack is required; the root tile is secure.

Assuming $v=3$, what are the requirements for 51% attacking one of 3 leaf tiles?
In this case, we need to define some terms first; particularly, we need to be able to compare a tile's security with that of their parent and children.

Let's gives tiles an identifier that lets us easily determine how to find a tile in a tiling -- the tiles \emph{location}.
The root tile is easy, we can just give it the identifier $1$, since there's only one.\footnote{
    Regarding tilings in \autoref{sec:alt-equiv-tilings}: this is easily generalized by giving additional root tiles the identifiers 2 and 3.
}
We can refer to a tile's child by appending its parent's identifier with $|1$, $|2$, $|3$, etc.
(For a valence of 3, $|3$ is only used for direct children of the root tile; all other tiles will always have the suffix $|1$ or $|2$).
So the \emph{location} of a tile might be $1|3|1|1|2$: the root tile's 3rd child's 1st child's 1st child's 2nd child.
If a tile has the location $l$, then $l|1|2$ is the tile at $l$'s 1st child's 2nd child.
Since there's a one-to-one correspondence between a tile and its location, we can address tiles directly via this identifier; i.e., the tile at location $1|2|1$ \emph{is} tile $1|2|1$.

Let's also say that $w_l$ is the total \emph{chain-work} produced by all simplex-chains that are part of tile $l$.
So, $w_1$ is the chain-work produced by the root tile, and it's children's chain-works are $w_{1|1}$, $w_{1|2}$, and $w_{1|3}$ respectively.

Let's define a function, $\text{Sec}(l)$ that returns the \emph{total} chain-work contributing to tile $l$'s security.
For the root tile, this is easy, and agrees with our earlier conclusion that the root tile is as secure as the whole tiling:
\begin{equation}
    \sec{1} = w_1 + w_{1|1} + w_{1|2} + w_{1|3}
\end{equation}
In general, it's the work contributed by the tile, tile's parent, and tile's children.
For some tile $p|i$ (i.e., the $i^{th}$ child of a parent tile $p$) in a tiling of valence $v$:
\begin{equation}
\begin{split}
    \sec{1} &= w_1 + w_{1|1} + w_{1|2} + \cdots + w_{1|v} \\
    \sec{p|i} &= w_p + w_{p|i} + w_{p|i|1} + \cdots + w_{p|i|v-1}
    \label{eq:tiling-sec-function}
\end{split}
\end{equation}
When a tile $p|i$ has no children, $w_{p|i|1}, w_{p|i|2}, \cdots = 0$.

\aside{
    Note: for $h=1$, it's always the case that $\sec{1|i} < \sec{1}$, which implies that the root tile is as difficult to attack as the whole tiling.
}

Returning to the case at hand ($h=1$): when are the 3 leaf tiles secure?

First, if $w_{1|i} > w_1$, then it's possible for an attacker who's already mining the leaf tile to attack it.
Let's calculate the minimum ratio, $q$, of tile $1|i$'s hash-rate that an attacker would need to do this (the honest hash-rate of $1|i$ has ratio $p$; $q + p = 1$):
\begin{align}
    qw_{1|i} &= pw_{1|i} + w_{1}
    \nonumber \\
    &= (1 - q)w_{1|i} + w_{1}
    \nonumber \\
    2qw_{1|i} &= w_{1|i} + w_{1}
    \nonumber \\
    q &= \frac{w_{1|i} + w_{1}}{2w_{1|i}}
    \label{eq:tiling-child-unsafe}
    \\
    \intertext{Since $w_{1|i} > w_1$:}
    2w_{1|i} &> w_{1|i} + w_1
    \nonumber \\
    \therefore 1 &> \frac{w_{1|i} + w_1}{2w_{1|i}}
    \nonumber \\
    \therefore q &< 1
    \label{eq:tiling-child-unsafe-q}
\end{align}
\autoref{eq:tiling-child-unsafe-q} implies that some fraction of a leaf tile's hash-rate could attack that tile.
If that happened, then compromising the leaf tile would not necessarily compromise the root tile (since it has multiple children).
This would mean that the histories of the leaf tile and root tile would diverge -- the leaf tile would be effectively \emph{severed} from the network.
Thus, $h=1$ is insecure if $w_{1|i} > w_1$.

 <!-- -- i.e., the total chain-work securing each of the root tile's children is less than that of the root tile -->

So what about $w_{1|i} < w_{1}$?
Let's consider two cases: whether the attacking hash-rate \emph{already factored in} to the relevant chain's difficulties, or not.
If the hash-rate \emph{is} factored in, then no change in distribution of hash-rate occurs when the attack happens.

If the attacking hash-rate \textbf{is} \emph{already factored in}, then leaf tiles are \emph{definitely} secure when $w_{1|i} < w_{1}$.
That's because -- in that context -- it's impossible to 51% attack a child-tile without attacking the root tile, and attacking the root tile is as difficult as attacking the entire tiling.
If the attack were possible, then the attacker would need to create private chain-segments for many of the simplex-chains in the root tile and tile $1|i$.
But, the attacker cannot convince tile $1|i$ nodes of a reorganization on the root tile (which would require attacking the root tile) -- the attacker's chain-segments are not better than the honest ones.
Thus, the attacker cannot undo reflections from the root tile, which provide more chain-weight than local reflections.
In essence: a reorg on tile $1|i$ won't stick because honest $1|i$ nodes can tell that the attackers blocks arrived later.
We can show this with \autoref{eq:tiling-sec-function}, too; assuming $v=3$:
\begin{align*}
    LHS &= \sec{1|i} & & & RHS &= \sec{1} \\
    &= w_1 + w_{1|i} & & & &= w_1 + w_{1|1} + w_{1|2} + w_{1|3} \\
    & & \therefore LHS &< RHS \;\; \blacksquare & &
\end{align*}
So, this case is secure.

If the attacking hash-rate \textbf{isn't} \emph{already factored in}, then \emph{normally} $w_{1|i} < w_{1}$, but it might not be true \emph{during the attack}.
In other words, significantly more blocks are produced for tile $1|i$ simplex-chains than expected.
Isn't this the same problem discussed (and solved) in \autoref{sec:reflection-pow-and-pos}?
If the weight of chain-work contribution (via PoR) is \emph{already} capped, then it's not possible for the attacker to substantially increase the weight of their chain-segments beyond $w_{1|i}$!
We don't need to change anything -- we guard against this already.
So, in this case, the attacker needs to attack the root tile, too -- this case is secure.

#### Tiling Security: $h = 2$

<!-- \begin{equation*}
    %%\xymatrix@M=4pt@C=-4pt@R=10pt{
    %%    & & & 1 \ar[dll] \ar[drr] \\
    %%    & 1|1 \ar[dl] \ar[dr] & & & & 1|2 \ar[dl] \ar[dr] \\
    %%    1|1|1 & & 1|1|2 & & 1|2|1 & & 1|2|2 \\
    %%} \\
    \xymatrix@M=4pt@C=-4pt@R=10pt{
        & & & & & 1 \ar[dllll] \ar[d] \ar[drrrr] \\
        & 1|1 \ar[dl] \ar[dr] & & & & 1|2 \ar[dl] \ar[dr] & & & & 1|3 \ar[dl] \ar[dr] \\
        1|1|1 & & 1|1|2 & & 1|2|1 & & 1|2|2 & & 1|3|1 & & 1|3|2 \\
    }
\end{equation*}
\begin{equation*}
    \xymatrix@M=4pt@C=-4pt@R=10pt{
        & 1 \ar[d] \\
        & 1|i \ar[dl] \ar[dr] \\
        1|i|1 & & 1|i|2
    }
\end{equation*} -->

Let's illustrate the tree structure of the tiling at $h=2$ in \autoref{fig:tiling-sec-tile-tree-h2}.

\begin{figure}[H]
    \centering
    \hfill
    \begin{subfigure}[t]{.6\textwidth}
        \vskip 0pt
        \centering
        \begin{equation*}
            \xymatrix@M=4pt@C=-4pt@R=10pt{
                & & & & & 1 \ar[dllll] \ar[d] \ar[drrrr] \\
                & 1|1 \ar[dl] \ar[dr] & & & & 1|2 \ar[dl] \ar[dr] & & & & 1|3 \ar[dl] \ar[dr] \\
                1|1|1 & & 1|1|2 & & 1|2|1 & & 1|2|2 & & 1|3|1 & & 1|3|2 \\
            }
        \end{equation*}
        \caption{The complete tile tree for $h=2$.}
        \label{fig:tiling-sec-tile-tree-h2-complete}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.35\textwidth}
        \vskip 0pt
        \centering
        \begin{equation*}
            \xymatrix@M=4pt@C=-4pt@R=10pt{
                & 1 \ar[d] \\
                & 1|i \ar[dl] \ar[dr] \\
                1|i|1 & & 1|i|2
            }
        \end{equation*}
        \caption{The branch around $1|i$.}
        \label{fig:tiling-sec-tile-tree-h2-branch}
    \end{subfigure}%%
    \hfill
    \caption{Tile trees for $h=2$, $v=3$.}
    \label{fig:tiling-sec-tile-tree-h2}
\end{figure}

<!-- fig:tiling-sec-tile-tree-h2-complete
fig:tiling-sec-tile-tree-h2-branch
fig:tiling-sec-tile-tree-h2 -->

There are three things we need to establish: that leaf tiles are secure, that those leaf tiles' parents (which are children of the root tile) are secure, and that the root tile is secure.

Leaf tiles are secure if $w_{1|i|j} < w_{1|i}$ -- attacking the leaf tile requires attacking its parent.

What about the parent tile ${1|i}$?
If \emph{both} leaf tiles (under $1|i$) are attacked, then the attacker has coopted, at most, $2w_{1|i|j}$ of the chain-work contributing to $1|i$.
\begin{equation}
\begin{split}
    \text{Assume:  } w_{1|i} &< w_{1} \\
    \text{Assume:  } w_{1|i|j} &< w_{1|i} \\
    \therefore 2w_{1|i|j} &< 2w_{1|i} \\
        &< w_{1|i} + w_1
\end{split}
\end{equation}
So the parent tile is secure even when an attacker could 51% attack both leaf tiles under $1|i$.

If $1|i$ \textbf{and} both leaf tiles ($1|i|j$) are attacked, what then?
Well, since the attacker can 51% attack those 3 tiles, the attack on tile $1|i$ is sort of 'supported' by the leaves.
However, that chain-work isn't considered by the root tile -- $\sec{1}$ does not include $w_{1|i|j}$.
So we know, at least, that the root tile is still secure.

Can $1|i$ be \emph{severed} from the tiling, though?
To do that, the attacker needs at least 51% of $\sec{1|i}$.
Let's use $q$ to represent the attackers proportion of hash-power (in total over $w_{1|i|j}$ and $w_{1|i}$).
When is the tiling secure?
\begin{align*}
    \sec{1|i} &= 2w_{1|i|j} + w_{1|i} + w_{1} \\
    q(2w_{1|i|j} + w_{1|i}) &< p(2w_{1|i|j} + w_{1|i}) + w_1 \\
    (q - p)(2w_{1|i|j} + w_{1|i}) &< w_1 \\
    \intertext{assume that $w_{l|i}$ is only slightly less than $w_{l}$ (worst case), so that $w_{l|i} \approx w_{l}$:}
    \implies (q - p)(3w_{1|i|j}) &< w_{1|i} \\
    \implies (q - p)(3w_{1|i|j}) &< w_{1|i|j} \\
    q - p &< \nicefrac{1}{3} \\
    q &< p + \nicefrac{1}{3} \\
    1 - p &< p + \nicefrac{1}{3} \\
    \nicefrac{2}{3} &< 2p \\
    \nicefrac{1}{3} &< p \\
\end{align*}

<!-- note: something about tiles essentially being yes/no (all or nothing) -->

Since $2w_{1|i|j} < w_{1|i} + w_{1}$, we can say that

root tile

\begin{align*}
    \sec{1} = w_1 + vw_{1|i} \\
    \intertext{To be secure, before the next iteration:}
    w_{1|i} < w_1 < vw_{1|i}
\end{align*}

that way, control of the root tile requires control of some children.

root's children

\begin{align*}
    \sec{1|i} = w_1 + w_{1|i} + w_{1|i|j}(v-1) \\
    \intertext{To be secure, before the next iteration:}
    w_{1|i|j} < w_{1|i} < w_1
\end{align*}



#### Tiling Security: $h \ge 3$

\aside{
    We'll presume $v=3$ here.
}

$w_{p|i} < w_{p}$

$w_{p|i|1} + w_{p|i|2} < w_{p|i} + w_{p}$

This is implied by $w_{p|i} < w_{p}$!
Since $p$ has a parent, we can expand $p$ to $g|1$ (or ${g|2}$ -- which doesn't matter).
\begin{align}
    w_{p|i} &< w_{p}
    \nonumber \\
    \implies w_{g|1|i} &< w_{g|1}
    \nonumber \\
    2w_{g|1|i} \approx w_{g|1|1} + w_{g|1|2} &< 2w_{g|1} < w_{g|1} + w_{g}
    \nonumber \\
    w_{g|1|1} + w_{g|1|2} &< w_{g|1} + w_{g}
    \label{eq:child-lt-parent-implied}
\end{align}

Case: leaf tile. $w_{g|i|1} < w_{g|i} + w_{g}$ $\implies$ secure.

Case: 2 leaf tiles. $w_{g|i|1} + w_{g|i|2} < w_{g|i} + w_{g}$ $\implies$ secure.

Case: 2 children + tile. $w_{g|i} < w_{g} + w_{g|..}$ $\implies$ secure. (leaf tiles don't help w/ attacking $g$, just being able to attack $g|i$ in the first place.)

\textbf{general case:}

$w_{p|i} < rw_{p}$

\begin{align}
3w_{p|i|j} &< rw_{p|i} + rrw_{p} \nonumber \\
0 &< rrw_{p} + rw_{p|i} - 3w_{p|i|j} \nonumber \\
\implies r &> \frac{1}{2}(\sqrt{4v-3}-1) \label{eq:tilingsec-r-gt-v-expr} \\
\intertext{We expect that:}
r^2 + r &> v - 1 \nonumber \\
\intertext{Via \autoref{eq:tilingsec-r-gt-v-expr}, observe that:}
\Big( \frac{1}{2}(\sqrt{4v-3}-1) \Big)^2 + \frac{1}{2}(\sqrt{4v-3}-1)
    &= \frac{1}{4}(4v-2\sqrt{4v-3}-2) + \frac{1}{2}(\sqrt{4v-3}-1) \nonumber \\
    &= \frac{1}{2}(2v - \sqrt{4v-3} - 1 + \sqrt{4v-3} - 1) \nonumber \\
    &= v - 1 \nonumber \\
\therefore r &> \frac{1}{2}(\sqrt{4v-3}-1)
\end{align}



\todo{this section}

%% END ### RELEASE

%% BEGIN ### DRAFT

#### blah

There is at least one obvious example of this asymmetry: existing blockchains.
How is it that Bitcoin is more secure than Litecoin, but Litecoin has $4\times$ the capacity?


Before we analyze the security of tree tilings,
\todo{this bit}

#### Security Implications

\begin{comment}

What are the implications of tiled simplexes compared to a standalone simplex?

\end{comment}


\todo{tiling security implications -- tiling weaker than maximal simplex?}

e.g., The leaf tiles in \autoref{fig:tiled-simplex-5-d1} have simplex-chains that are weaker than an equiv 20-chain simplex.
The root tile has equiv security, though.
This is true even though both systems have 20 simplex-chains total.

this only happens when leaf tiles + their children have $==$ weight to their direct parent, tho.
that is: if the parent has $\ge$ simplex-chains, then isolated attacks on the the descendant tiles always fail b/c the parent tile has $>$ weight.

main idea: if you want to attack a simplex tile in the middle of the graph, then you *must* attack its peers -- b/c that's where *most* of the security contribution comes from (75% at max cap).
on the edges mb things are different.
my intuition is that, if sensible precautionary parameters are maintained, then it can be done securely.
but there are failure modes when the sec contribs from adjacent tiles are out of wack.

%% END ### DRAFT

%% BEGIN ### RELEASE

### Tiling Variants

\label{sec:tiling-variants}

#### Alternate and Equivalent Tilings

\label{sec:alt-equiv-tilings}

There exists an alternate tiling that begins with two tiles instead of one, though the iteration algorithm is the same.
It is shown in \autoref{fig:alt-tiling}. It has $N_{\text{tiles}} = 2^{h+2} - 2$.

Similarly, another alternate tiling starts with three tiles.
To preserve valencies, each tile at height 0 has only 1 child.
Otherwise, the iteration algorithm is the same.
This tiling is shown in \autoref{fig:alt-tri-tiling} and has $N_{\text{tiles}} = 3 \cdot 2^{h}$.
One advantage of this variant is that the tiling algorithm can begin when a single original simplex reaches $75\%$ capacity (at which point, it must be split into the trio of root-tiles).

\begin{figure}[p]
    \centering
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_alt_s5_d2_sag}
        \caption{1st iteration. 6 tiles.}
        \label{fig:tiled-simplex-alt-d2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_alt_s5_d3_sag}
        \caption{2nd iteration. 14 tiles.}
        \label{fig:tiled-simplex-alt-d3}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_alt_s5_d4_sag}
        \caption{3rd iteration. 30 tiles.}
        \label{fig:tiled-simplex-alt-d4}
    \end{subfigure}%%
    \caption{An alternate tree tiling, starting with 2 tiles, that is equivalent in terms of complexity, security, etc.}
    \label{fig:alt-tiling}
\end{figure}

\begin{figure}[p]
    \centering
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_a3_v3_s5_d1_sag}
        \caption{1st iteration. 6 tiles.}
        \label{fig:tiled-simplex-alt3-d2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_a3_v3_s5_d2_sag}
        \caption{2nd iteration. 12 tiles.}
        \label{fig:tiled-simplex-alt3-d3}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_a3_v3_s5_d3_sag}
        \caption{3rd iteration. 24 tiles.}
        \label{fig:tiled-simplex-alt3-d4}
    \end{subfigure}%%
    \caption{An alternate tree tiling, starting with 3 tiles, that is equivalent in terms of complexity, security, etc.}
    \label{fig:alt-tri-tiling}
\end{figure}

#### Tiling With Individual Blockchains

A 3-simplex (which has 4 chains) is the least populous simplex that may be tiled with a valence of 3.
The result of this is shown in \autoref{fig:tiled-3-simplexes} and is equivalent to a tiling of individual blockchains (a single-chain tiling).
This configuration still has $O(n)$ scalability.

\begin{figure}[p]
\centering
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_s1_d6_sag}
        \label{fig:tiled-3-simplexes-main}
    \end{subfigure}%% \hspace{0.1\textwidth}
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_alt_s1_d6_sag}
        \label{fig:tiled-3-simplexes-alt}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_a3_s1_d6_sag}
        \label{fig:tiled-3-simplexes-a3}
    \end{subfigure}%%
    \caption{Tree tilings ($v=3$) where each tile has only external reflections, i.e., there is only 1 single blockchain per tile.}
    \label{fig:tiled-3-simplexes}
\end{figure}

This method has some decisive criticisms.

First, the confirmation rate is much slower -- both intra-tile and inter-tile. Inter-tile confirmations (which are important for e.g., cross-tile SPV transactions) occur with frequency $B_f \cdot N_1$, i.e., the frequency is proportional to the number of simplex-chains in each tile. This means that single-chain tilings have the theoretically *worst case* confirmation rate compared to tilings of larger simplexes.

Second, because the inter-tile confirmation rate is *worst case*, the window for attack (via the private creation of chain-segments) is correspondingly longer. That is, the window for attack is also *worst case* for a chosen block frequency.

#### Higher Valencies

The tree-method of tiling (which we've just covered) works for valencies higher than 3. \autoref{fig:tiling-v4} shows a tiling of valence 4, and \autoref{fig:tiling-v5} shows a tiling of valence 5.

\begin{figure}
    \centering
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_v4_s7_d1_sag}
        \caption{1st iteration. 5 tiles.}
        \label{fig:tiled-simplex-v4-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_v4_s7_d2_sag}
        \caption{2nd iteration. 17 tiles.}
        \label{fig:tiled-simplex-v4-d2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_v4_s7_d3_sag}
        \caption{3rd iteration. 53 tiles.}
        \label{fig:tiled-simplex-v4-d3}
    \end{subfigure}%%
    \caption{Tiling of valence 4.}
    \label{fig:tiling-v4}
\end{figure}

\begin{figure}
    \centering
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_v5_s7_d1_sag}
        \caption{1st iteration. 6 tiles.}
        \label{fig:tiled-simplex-v5-d1}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_v5_s7_d2_sag}
        \caption{2nd iteration. 26 tiles.}
        \label{fig:tiled-simplex-v5-d2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_v5_s7_d3_sag}
        \caption{3rd iteration. 106 tiles.}
        \label{fig:tiled-simplex-v5-d3}
    \end{subfigure}%%
    \caption{Tiling of valence 5.}
    \label{fig:tiling-v5}
\end{figure}

#### Tessellating tiles are less efficient

\label{sec:tessellating-tiles-efficiency}

Because $O(\log_2 n) < O(\sqrt{n})$.

In a tessellating set of tiles, we can approximate the *maximum* distance between tiles via a geometric interpretation: for a set of $n$ tessellating tiles, each tile having a constant area, then the full area is $\propto {n}$. Thus, the maximal distance between tiles is $\propto \sqrt{n}$.

However, using the tree method (with $v=3$), the *maximal* distance between any 2 of $n$ tiles, is $\sim \log_2 n$. So it's (maybe counterintuitively) more efficient to use non-tessellating tiles.

Additionally, a model of tilings of similar capacity -- i.e., similar $N_{\text{tiles}}$ -- shows that the *average* distance between tiles is lower for tree-based tilings. \autoref{fig:tiling-avg-dist-comparison} shows a comparison of the average distance between tiles given different tiling methods. The square tessellating method produces the tiling shown in \autoref{fig:tiling-square}.

\begin{figure}
\centering
    \hspace{0.03\textwidth}
    \begin{subfigure}[t]{.40\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{avg-dist-v3}
        \caption{Tree of valence 3.}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.40\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{avg-dist-v4}
        \caption{Tree of valence 4.}
    \end{subfigure}%%
    \hspace{0.03\textwidth}
    \caption[
        Distances between randomly selected tiles for the tree method of tiling vs a simple square tessellating method.
    ]{
        Shown are the distances between randomly selected tiles for two tiling methods -- the tree method (which this section primarily concerns) and a simple square tessellating method.
        Valence and depth parameters were chosen so that the number of tiles are comparable.
    }
    \label{fig:tiling-avg-dist-comparison}
\end{figure}

\begin{figure}
    \centering
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_square_s5_d1_sag}
        \caption{1st iteration. 5 tiles.}
        \label{fig:tiling_square_s5_d1_sag}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_square_s5_d2_sag}
        \caption{2nd iteration. 13 tiles.}
        \label{fig:tiling_square_s5_d2_sag}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.32\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[height=.95\linewidth]{tiling_square_s5_d3_sag}
        \caption{3rd iteration. 25 tiles.}
        \label{fig:tiling_square_s5_d3_sag}
    \end{subfigure}%%
    \caption{An example of a square tiling used in \autoref{fig:tiling-avg-dist-comparison}.}
    \label{fig:tiling-square}
\end{figure}

%% END ### RELEASE

%% BEGIN ### DRAFT

### Tiling Security Principles

\begin{align*}
    2 \cdot \; & \text{Sec}(\text{tile.child}) \\
    & < 2 \cdot \text{Sec}(\text{tile}) \\
    & < \text{Sec}(\text{tile}) \\
    & \; \; \; + \; \text{Sec}(\text{tile.parent})
\end{align*}

\begin{align*}
& \; \text{Sec}(\text{tile.grandparent}) \\
+ & \; \text{Sec}(\text{tile.parent}) \\
+ & \; 2 \cdot \text{Sec}(\text{tile})
\end{align*}

\begin{align*}
& \; \text{Sec}(\text{tile.parent}) \\
+ & \; \text{Sec}(\text{tile}) \\
+ & \; 2 \cdot \text{Sec}(\text{tile.child})
\end{align*}

\begin{align*}
    \text{let} \; S &= \sum_{i=0}^n (3 \cdot 2^{i-1}) \cdot r^i \\
    \implies 2r \cdot S &= \sum_{i=0}^n (3 \cdot 2^i) \cdot r^{i+1} \\
    &= \sum_{i=1}^{n+1} (3 \cdot 2^{i-1}) \cdot r^i \\
    \therefore S - 2r\cdot S &= r^0 + r = 1 + r \\
    \implies S &= \frac{1 + r}{1 - 2r}
\end{align*}

\begin{align*}
    1 - 2r &> 0 \\
    r &< \frac{1}{2}
\end{align*}

### Worst Case Tiling

\todo{write this section properly}

What's the worst case for tiling -- as a method? Probably that PoR isn't safe to do non-recursively in a way that works for $O(n)$ tiling. The solution is to validate PoRs recursively which means that *every* miner needs *every* base-level (i.e., simplex-chain) block across all simplex tiles. That would enable edge-to-edge verification of all PoRs. In that case, an upper-bound is set based on minimum bandwidth requirements (for miners) and $\Delta S$ (see \autoref{sec:bandwidth-complexity}). For a given set of parameters, the limit is $N_{\text{tiles}} \cdot \nicefrac{\Delta S}{4} < \text{MinBandwidth}$.

possible extension: maybe PoRs can be provided to miners but excluded from blocks. Like you can be a full node or a full-full-node, and full-full-nodes validate PoRs recursively in a way that isn't required for a single simplex. Or full-full-nodes are miners in a simplex, and full-full-full-nodes are miners in a tiling of simplexes.

<!-- for each tile:
- work(0.5 * child + self) < work(other child + parent)
- work(children) < (self + parent)

## - work(self) < work(children) [nb: exception for work(self) > 0.5 * work(whole_network), and parents of leaf nodes]

- work(self) < work(parent)
- work(self) > work(child)
- work(self + parent) > work(children)

 -->



#### A Thought (Draft)

Thought: let's say that tiling *requires* edge-to-edge verification. Is it still useful? Yes.

Let's *assume* there *is* significant work in a simplex-miner calculating and verifying the internal PoRs (via the method in \autoref{sec:segmented-state}). Since the number of mutual reflections in a simplex is $O(c^2)$, let's assume the algorithm a miner needs to run is $O(c^2)$, too[^opt1].

[^opt1]: Note that there is significant room for optimization due to the repeated operations that need to be done for each simplex-chain.

Now, let's consider two systems of equal (network wide) throughput: a tiling of depth 1 (with 4 tiles) and a single simplex. This should be an easy comparison if the tiling has a valence of 3.

In the tiled system, with non-recursive validation, miners on the root tile need to do more work than miners on leaf tiles -- internal reflections for 4 tiles and 3 sets of inter-tile reflections. With recursive validation all miners (for all tiles) have this same burden.
\begin{equation}
\begin{split}
& \text{Tiling Refls} = (\frac{N_1}{4})^2 \cdot (4 + 3) = \frac{7 N_1^2}{16} \\
& \text{Simplex Refls} = N_1^2
\end{split}
\end{equation}

So the complexity is the same, but there's a pretty steep discount (like 50%).

Does that trend continue? Get better?

%% END ### DRAFT
