## Tiling Simplexes

Tiling is a method which allows UT to scale with order $O(n)$. When UT simplexes are tiled, we call the result a *simplex-tiling*.

Maximal Simplex: a simplex with the maximum number of simplex-chains under $O(c)$ constraints.

A tile is a quadrifurcated maximal simplex. That is: it is a simplex that deliberately reserves only $\frac{1}{4}$ of its otherwise maximum capacity for internal reflections. By definition, the maximum capacity of a tile is $\frac{1}{4}$ the maximum capacity of an equivalent maximal simplex. Why quadrifurcate capacity like this? In a maximal simplex, all reflections are between simplex-chains within that simplex, i.e., all reflections are internal. However, by reserving $\frac{3}{4}$ of a simplex's maximum capacity, that simplex (which thus becomes the root tile) can reflect all simplex-chains in 3 adjacent 'children' tiles. Those adjacent tiles do not reflect their siblings, though; initially, their only external reflections are with simplex-chains in the parent tile. Each child tile, at this stage, has only reserved 50% of the capacity of an equivalent maximal simplex -- 25% for externally reflecting its parent's simplex-chains, and 25% for internally reflecting its own simplex-chains. Thus, each tile is able to reflect all simplex-chains of the parent tile *and* two additional children tiles. Children tiles can be instantiated in an ad-hoc basis, i.e., as a simplex-tiling (or an individual tile) approaches maximum capacity.

### Tile Valence

\label{sec:tile-valence}

Tiles *must* have a valance of $>= 3$ for $O(n)$ scaling. If tiles had a valence of 0, then no additional tiles can be added. If tiles had a valence of 1, then only a single additional tile could be added (for a total of 2) but no more. If tiles had a valance of 2, then the 'shape' that the tiles created would be a linear chain; a tile-chain. For a tile-chain of length $n$, proving state on the far end of the chain would take $n$ SPV proofs, which is untenable.

However, if tiles have a valance of $3$, then each tile has up to 3 neighbors. For all tiles but the first, this is equivalent to being a node in a binary tree (where each non-root, non-leaf node has 1 parent and 2 children: 3 neighbors). In essence, this method of tiling simplexes results in 3 distinct binary trees as children of a single root tile -- this can be seen in \autoref{fig:tiled-simplex-5-d4}.

Increasing the valence beyond 3 does not make sense, though. There are two reasons for this. The first reason is that, for complexity orders involving logarithms, higher valences change the *base* of the logarithms; and that has no effect on the order of complexity[^log-complexity]. The second reason is: an increase in valence means that the tile's capacity for reflections is divided into more pieces, only one of which is reserved for internal reflections; that means that the tile will have fewer internal reflections (and more external reflections) which decreases the security of leaf tiles.

[^log-complexity]: Complexity orders involving logarithms are sensitive to changes in the base *if* the logarithms are part of an exponent. e.g. $O(3^{\log_2 n}) > O(3^{\log_4 n})$. These considerations aren't relevant here, though.

### The First Tile

\todo[inline]{mb a diagram of simplex in quadrants -- this would show like a 20-chain simplex in partitions of 5, but mb with 15/20 chains being like 'empty'. IDK, TBD}

\begin{figure}
\centering
\includegraphics[width=50mm]{ut/tiling/d1-many-tiled-5-simplexes}
\caption{The initial state of a 5-chain simplex-tile before tiling. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
\label{fig:tiled-simplex-5-d1}
\end{figure}

\autoref{fig:tiled-simplex-5-d1} assumes an $O(c)$ node has capacity for tracking $4 \cdot n$ simplex-chains, with $n = 5$. In reality, an $O(c)$ node has capacity to track $\sim 10^3$ or $10^4$ simplex-chains. Simplexes and simplex-tilings of that magnitude are impractical to illustrate.

### Adding Tiles

A tiling 'iteration' is the process by which new tiles are added. For the sake of simplicity and demonstration, each iteration will add *all possible new tiles* as children of all 'leaf' tiles -- though in reality there's no requirement that new tiles be added at the same time, or that tiles are added in a balanced fashion.

We start from the foundation that each tile has a maximum of $\frac{N_1}{4}$ simplex-chains, where $N_1$ is the maximum capacity of a maximal simplex. That is: if one computer (based on $O(c)$ reasoning) could be a full-node[^simplex-full-validation] for a simplex-chain in a 4000-simplex, then each tile will have, at most, 1000 simplex-chains. Since a tile is adjacent to $<=3$ other tiles, a tiled simplex-chain will have, at most, $N_1$ reflections (since a tile and its neighbors have, at most, $\frac{N_1}{4}$ simplex-chains, and all of those simplex-chains are reflected).

[^simplex-full-validation]: A full-node for a simplex-chain does not need to fully validate any other simplex-chains, or dapp-chains on that simplex-chain. Header-only validation is fine.

Our starting point is a $\frac{N_1}{4}$-simplex which constitutes a single tile. This is shown in \autoref{fig:tiled-simplex-5-d1}.

The next iteration is to add $3$ adjacent tiles, since our initial tile has a valence of 3. Each of these new tiles has one pre-existing neighbor (the root tile), so each new tile has capacity for 2 more neighbors. Thus, the next iteration will add twice the number of tiles as the preceding iteration -- in this case, $6$ new tiles. This pattern -- adding twice the number of tiles as the previous iteration -- continues indefinitely.

\begin{comment}
side by side figures: https://tex.stackexchange.com/questions/37581/latex-figures-side-by-side
\end{comment}

\begin{figure}
    \centering
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d2-many-tiled-5-simplexes}
        \caption{1st iteration. 4 tiles.}
        \label{fig:tiled-simplex-5-d2}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d3-many-tiled-5-simplexes}
        \caption{2nd iteration. 10 tiles.}
        \label{fig:tiled-simplex-5-d3}
    \end{subfigure}%%
    \hfill
    \begin{subfigure}{.28\textwidth}
        \centering
        \includegraphics[width=.95\linewidth]{ut/tiling/d4-many-tiled-5-simplexes}
        \caption{3rd iteration. 22 tiles.}
        \label{fig:tiled-simplex-5-d4}
    \end{subfigure}
    \hfill
    \caption{The state of tiled 5-chain simplexes after sequential iterations. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
\end{figure}

### Complexity Analysis

Two elements of complexity will be analysed: the size of SPV proofs between simplex-chains, and the network overall.

\todo[inline]{Need to check the Big O stuff in this section.}

#### Tiling Complexity

If our tiling is balanced (in the sense that a binary tree can be balanced) then the root tile has 3 children, each of which is the root node of a balanced binary tree. If those trees have a height of $h-1$, then each have $2^{h} - 1$ total nodes. The height of the trees is set to $h-1$ so that the full tiling has a height of $h$. The number of tiles in the full tiling is thus:

\begin{equation}
\begin{split}
N_{tiles} & = 3 \cdot (2^{h} - 1) + 1 \\
& = 3 \cdot 2^h - 2 \label{eq:n-tiles}
\end{split}
\end{equation}

Thus, the maximal distance between leaf tiles is $2h$, which is also the maximal number of SPV proofs required to prove state between any two simplex-chains. Given \autoref{eq:n-tiles}:

\begin{equation}
\begin{split}
N_{tiles} & = 3 \cdot 2^h - 2 \\
\log_{2}(\frac{N_{tiles} + 2}{3}) & = h \label{eq:tiles-h}
\end{split}
\end{equation}

Thus, the maximal distance between leaf tiles is $2 \cdot \log_{2}(\frac{N_{tiles} + 2}{3})$, and thus the number of SPV proofs required (across simplex-chains) scales with $O(\log_2 N_{tiles})$.

Since tiles can be added in an ad-hoc fashion depending on current capacity, and each tile scales with complexity $O(c^j); j \in \{2,3,4\}$: $N_{tiles} \propto \frac{n}{c^j}$. Thus $O(N_{tiles}) = O(\frac{n}{c^j})$.

Given \autoref{eq:spv-complexity}, dapp-chain inter-tile SPV proofs have order:

\begin{equation}
\begin{split}
O(\log_2 c + \log_2 N_{tiles}) & = O(\log_2 c + \log_2 \frac{n}{c^j}) \\
& = O(\log_2 c + \log_2 n - j \cdot \log_2 c) \\
& = O(\log_2 c + \log_2 n - \log_2 c) \\
& = O(\log_2 n) \label{eq:tiled-spv-complexity}
\end{split}
\end{equation}

#### Tessellating tiles are less efficient

Because $O(\log_2 n) < O(\sqrt{n})$.

In a tessellating set of tiles, we can approximate the distance between tiles via a geometric interpretation: for a set of $n$ tessellating tiles, each tile having a constant area, then the full area is $\propto {n}$. Thus, the maximal distance between tiles is $\propto \sqrt{n}$.

However, the distance between any 2 of $n$ tiles, using the binary-tree method, is $\sim \log_2 n$. So it's (maybe counterintuitively) more efficient to use non-tessellating tiles.

#### Network Complexity

Since $O(N_{tiles}) = O(\frac{n}{c^j})$, and each tile has order $O(c^j)$, the complexity of the network  overall is given by the product of a tile's order by the number of tiles:

\begin{equation}
\begin{split}
O(c^j \cdot N_{tiles}) & = O(c^j \cdot \frac{n}{c^j}) \\
& = O(n) \label{eq:simplex-tiling-complexity}
\end{split}
\end{equation}

For all practical purposes, simplex-tiling provides unbounded capacity.

#### Security Implications

\todo[inline]{tiling security implications -- tiling weaker than maximal simplex.}

e.g. The leaf tiles in \autoref{fig:tiled-simplex-5-d2} have simplex-chains that are weaker than an equiv 20-chain simplex. The root tile has equiv security, tho. This is true even tho both systems have 20 simplex-chains total.

\begin{comment}

#### Upper Bound

Solving problems via the creation of new knowledge, i.e., *progress*, has no upper bound[^boi-progress]. Additionally: "If something is permitted by the laws of physics, then the only thing that can prevent it from being technologically possible is not knowing how."[^boi-optimism] Thus, there are no know near-term[^near-term-limit] limits to the expansion of human civilization, our population, or our economy[^boi-spaceship-earth]; and consequently, there is no near-term limit on $n$.

[^boi-progress]: The explanations by which we *know* that progress is unbounded are a primary focus of David Deutsch's *The Beginning of Infinity* (2011).
[^boi-optimism]: *The Beginning of Infinity* p. 231.
[^near-term-limit]: By *near-term*, I mean: within the next $10^7$ years or so.
[^boi-spaceship-earth]: I guess a common response to this will be something like Spaceship Earth. The myth of Spaceship Earth is refuted in *The Beginning of Infinity*, Ch 3 (*The Spark*).


Dyson swarms can hold, say, $10^{15}$ people[^dyson-pop] on the low end. \todo[inline]{finish dyson pop stuff}

Galaxies that are close enough to us, and that have a low enough relative velocity, can remain within a relevant (to us) inter-galactic civilization. Some of these galaxies are gravitationally bound to our own, so -- if humanity is successful -- will be part of our inter-galactic civilization 'for free'. Galaxies within, give or take, $10^21 km$ ($\sim$1 billion light-years) have a low enough relative velocity. We can colonize these galaxies and use devices such as Shkadov thrusters to move them close enough to Milkdromeda so that they remain part of an inter-galactic civilization[^move-galaxies] (i.e., 2-way communication is possible). Within those galaxies, there are approximately $10^17$ stars[^stars-1b-ly].

[^dyson-pop]: \todo[inline]{\url{https://www.youtube.com/watch?v=Ef-mxjYkllw&t=1089s}}
[^move-galaxies]: *Intergalactic Colonization* by Isaac Arthur, <https://youtu.be/xRB7a89Jh7w?t=1618>, 26:58
[^stars-1b-ly]: <http://www.icc.dur.ac.uk/~tt/Lectures/Galaxies/LocalGroup/Back/superc.html>, <https://archive.vn/wEu5E>, <http://web.archive.org/web/20201021141956/http://www.icc.dur.ac.uk/~tt/Lectures/Galaxies/LocalGroup/Back/superc.html>

\end{comment}
