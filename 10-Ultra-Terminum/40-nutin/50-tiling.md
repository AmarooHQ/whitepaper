%% BEGIN ### RELEASE

\section{\titlemath{$\text{UT}_{\aleph}$:}{UT-aleph:} Tiling Simplexes}

\label{sec:tiling}

\draftOnly{\mk{This section (\autoref{sec:tiling}) is being redrafted. It replaces \autoref{sec:tiling-old}}}

\assignedTODO{{Max+Pouriya+Chris}}{h}{{
    All three to discuss what needs to be in section.\\
    Chris and Pouriya to pull together missing parts / refine.\\
    Max to finish off writing.\\
    Chris and Pouriya to do review after done.
}}

\input{50-tiling/00-tiling-intro.tex}
\input{50-tiling/10-simplex-tilings.tex}
\input{50-tiling/20-recursive-por.tex}
\input{50-tiling/30-tiling-security.tex}
\input{50-tiling/80-future-work.tex}

%% END ### RELEASE

%% BEGIN ### DRAFT

\section{Tiling --- Previous (Old) Version}

\label{sec:tiling-old}

\mk{This section is being replaced by \autoref{sec:tiling} (which is currently being redrafted.)}

Tiling is a method which allows UT to scale with order $O(n)$. When UT simplexes are tiled, the result is called a *simplex tiling*.

<!-- \defineTermTex{Simplex-Tile}{
    Like a simplex, but $\ge 75\%$ of the PoR capacity is reserved for reflections with \emph{neighboring} tiles; typically a quadrifurcated maximal simplex
} -->

\todoDraftOnly{terms and edit / refactor this section}

A simplex-tile, on its own, is very similar to a standalone simplex.
If a standalone simplex (of a given capacity) could host $1600$ simplex-chains, then an equivalent simplex-tile will host $400$ (or maybe less); only $25\%$ of the PoR capacity is reserved for *internal* reflections --- i.e., reflections within that simplex-tile.
The other $75\%$ is reserved for *external* reflections to simplex-chains in *neighboring* tiles.

That is: it is a simplex that deliberately reserves only $\nicefrac{1}{4}$ of its otherwise maximum PoR capacity for internal reflections.
By definition, the maximum PoR capacity of a tile is $\nicefrac{1}{4}$ the maximum PoR capacity of an equivalent maximal simplex.
Why quadrifurcate capacity like this?
In a maximal simplex, all reflections are between simplex-chains within that simplex, i.e., all reflections are internal.
However, if a simplex reserves $\nicefrac{3}{4}$ of a its maximum capacity, that simplex (which thus becomes the root tile) can reflect every simplex-chain in 3 adjacent tiles (at least 2 of which are 'child' tiles).
Those child tiles do not reflect their siblings, though; initially, their only external reflections are with simplex-chains in the parent tile.
Each child tile, at this stage, has only reserved 50% of its full PoR capacity --- 25% for externally reflecting its parent's simplex-chains, and 25% for internally reflecting its own simplex-chains.
Thus, each tile is able to reflect all simplex-chains of the parent tile *and* two additional child tiles.
Child tiles can be instantiated in an ad-hoc basis, i.e., as a simplex-tiling (or an individual tile) approaches maximum capacity.

<!-- \defineTermTex{Simplex Tiling}{An interconnected graph of mutually reflecting simplexes. This graph grows in a scalable manner when simplex-tiles have a valence $\ge 3$} -->

<!-- \todoDraftOnly{
    from forum: \\
    max:[When a simplex does tiling:] it's not that `k` decreases, but the proportion of `k` dedicated to internal reflections decreases. like it's optimal to have `k/2` dedicated to reflections, and `k/2` dedicated to transactions. when tiling with a valence of 3, the `k/2` for reflections is quadrifurcated, so there's `k/8` dedicated for each group of reflections (internal, parent, child1, child2). \\
    leesa: oki yup this makes a lot of sense now. I felt like the `k` explanations were helpful in solidifying understanding. I think bc it helped to make the concept more concrete since it linked back to the proofs.
} -->

### Tile Valence

\label{sec:tile-valence}

Tiles *must* have a valance, $v$, of $v \ge 3$ for $O(n)$ scaling.
If tiles had a valence of 0, then no additional tiles can be added.
If tiles had a valence of 1, then only a single additional tile could be added (for a total of 2) but no more.
If tiles had a valance of 2, then the 'shape' that the tiles created would be a linear chain; a tile-chain.
For a tile-chain of length $n$, proving state on the far end of the chain would take $n$ SPV proofs, which is untenable.

However, if tiles have a valance of $3$, then each tile has up to 3 neighbors.
For all tiles but the first, this is equivalent to being a node in a binary tree (where each non-root, non-leaf node has 1 parent and 2 children: 3 neighbors).
In essence, this method of tiling simplexes results in 3 distinct binary trees as children of a single root tile --- this can be seen in \autoref{fig:tiled-simplex-5-d3}.

Increasing the valence beyond 3 does not make sense, though. There are two reasons for this.
The first reason is that, for complexity orders involving logarithms, higher valences change the *base* of the logarithms; and that has no effect on the order of complexity\footnote{
    Complexity orders involving logarithms are sensitive to changes in the base \emph{if} the logarithms are part of an exponent.
    e.g., $O(3^{\log_2 n}) > O(3^{\log_4 n})$.
    These considerations aren't relevant here, though.
}.
The second reason is: an increase in valence means that the tile's capacity for reflections is divided into more pieces, only one of which is reserved for internal reflections; that means that the tile will have fewer internal reflections (and more external reflections) which decreases confirmation rate.
 <!-- and the security of leaf tiles. -->

\todoDraftOnly{revisit the above: The second reason is: an increase in valence means that the tile's capacity for reflections is divided into more pieces, only one of which is reserved for internal reflections; that means that the tile will have fewer internal reflections (and more external reflections) which decreases confirmation rate.}

### Tree-Tiling

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

A tiling 'iteration' is the process by which new tiles are added. For the sake of simplicity and demonstration, each iteration will add *all possible new tiles* as children of all 'leaf' tiles --- though in reality there's no requirement that new tiles be added at the same time, or that tiles are added in a balanced fashion.

We start from the foundation that each tile has a maximum of $\frac{N_1}{4}$ simplex-chains, where $N_1$ is the maximum capacity of a maximal simplex. That is: if one computer (based on $O(c)$ reasoning) could be a full node[^simplex-full-validation] for a simplex-chain in a 4000-simplex, then each tile will have, at most, 1000 simplex-chains. Since a tile is adjacent to $\le 3$ other tiles, a tiled simplex-chain will have, at most, $N_1$ reflections (since a tile and its neighbors have, at most, $\frac{N_1}{4}$ simplex-chains, and all of those simplex-chains are reflected).

[^simplex-full-validation]: A full node for a simplex-chain does not need to fully validate any other simplex-chains, or dapp-chains on that simplex-chain.

Our starting point is a $\frac{N_1}{4}$-simplex which constitutes a single tile.
This is shown in \autoref{fig:tiled-simplex-5-d0}.

The next iteration is to add $3$ adjacent tiles, since tiling has a valence of 3.
Each of these new tiles has one pre-existing neighbor (the root tile), so each new tile has capacity for 2 more neighbors.
Thus, the next iteration will add twice the number of tiles as the preceding iteration --- in this case, $6$ new tiles.
This pattern --- adding twice the number of tiles as the previous iteration --- continues indefinitely.
It is shown in \autoref{fig:simplex-tiling}.

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

%% END ### DRAFT

%% BEGIN ### DRAFT

%% INSERT ### TABLE: tree_tiling_3k_v4_table

: Tree-Tiling performance of various heights ($h$) with $v=4$ and $k=3000$.
Values for $N_1$ and $N_2$ and a comparison between $\UTinf{\text{+OPT}}$ and $\UT{\text{+OPT}}$ with equivalent values.

%% END ### DRAFT

%% BEGIN ### DRAFT

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

\begin{figure}
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
    \caption{An alternate tree-tiling, starting with 2 tiles, that is equivalent in terms of complexity, security, etc.}
    \label{fig:alt-tiling}
\end{figure}

\begin{figure}
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
    \caption{An alternate tree-tiling, starting with 3 tiles, that is equivalent in terms of complexity, security, etc.}
    \label{fig:alt-tri-tiling}
\end{figure}

#### Tiling With Individual Blockchains

A 3-simplex (which has 4 chains) is the least populous simplex that may be tiled with a valence of 3.
The result of this is shown in \autoref{fig:tiled-3-simplexes} and is equivalent to a tiling of individual blockchains (a single-chain tiling).
This configuration still has $O(n)$ scalability.

\begin{figure}
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
    \caption{Tree-tilings ($v=3$) where each tile has only external reflections, i.e., there is only 1 single blockchain per tile.}
    \label{fig:tiled-3-simplexes}
\end{figure}

This method has some decisive criticisms.

First, the confirmation rate is much slower --- both intra-tile and inter-tile. Inter-tile confirmations (which are important for e.g., cross-tile SPV transactions) occur with frequency $B_f \cdot N_1$, i.e., the frequency is proportional to the number of simplex-chains in each tile. This means that single-chain tilings have the theoretically *worst case* confirmation rate compared to tilings of larger simplexes.

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

Additionally, a model of tilings of similar capacity --- i.e., similar $N_{\text{tiles}}$ --- shows that the *average* distance between tiles is lower for tree-based tilings. \autoref{fig:tiling-avg-dist-comparison} shows a comparison of the average distance between tiles given different tiling methods. The square tessellating method produces the tiling shown in \autoref{fig:tiling-square}.

\begin{figure}
\centering
    \hspace{0.03\textwidth}
    \begin{subfigure}[t]{.45\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[max width=1.0\textwidth]{avg-dist-v3}
        \caption{Tree of valence 3.}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}[t]{.45\textwidth}
        \vskip 0pt
        \centering
        \includegraphics[max width=1.0\textwidth]{avg-dist-v4}
        \caption{Tree of valence 4.}
    \end{subfigure}%%
    \hspace{0.03\textwidth}
    \caption[
        Distances between randomly selected tiles for the tree method of tiling vs a simple square tessellating method.
    ]{
        Shown are the distances between randomly selected tiles for two tiling methods --- the tree method (which this section primarily concerns) and a simple square tessellating method.
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

%% END ### DRAFT

%% BEGIN ### DRAFT

### Worst Case Tiling

\todo{write this section properly}

What's the worst case for tiling --- as a method? Probably that PoR isn't safe to do non-recursively in a way that works for $O(n)$ tiling. The solution is to validate PoRs recursively which means that *every* miner needs *every* base-level (i.e., simplex-chain) block across all simplex-tiles. That would enable edge-to-edge verification of all PoRs. In that case, an upper-bound is set based on minimum bandwidth requirements (for miners) and $\Delta S$ (see \autoref{sec:bandwidth-complexity}). For a given set of parameters, the limit is $N_{\text{tiles}} \cdot \nicefrac{\Delta S}{4} < \text{MinBandwidth}$.

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

In the tiled system, with non-recursive validation, miners on the root tile need to do more work than miners on leaf tiles --- internal reflections for 4 tiles and 3 sets of inter-tile reflections. With recursive validation all miners (for all tiles) have this same burden.
\begin{equation}
\begin{split}
& \text{Tiling Refls} = (\frac{N_1}{4})^2 \cdot (4 + 3) = \frac{7 {N_1}^2}{16} \\
& \text{Simplex Refls} = {N_1}^2
\end{split}
\end{equation}

So the complexity is the same, but there's a pretty steep discount (like 50%).

Does that trend continue? Get better?

%% END ### DRAFT
