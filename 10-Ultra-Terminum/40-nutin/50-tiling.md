## Tiling Simplexes

* can tile simplexes by dividing initial simplex into 4 parts.
* then creating new nodes as required
* $3 \cdot 2^i - 2$ (nb: I think this was for a prev simplex tiling method; same complexity as the alt formula tho)

### initial state

\todo[inline]{diagram of simplex in quadrants -- this would show like a 20-chain simplex in partitions of 5, but mb with 15/20 chains being like 'empty'. IDK, TBD}

\begin{figure}
\centering
\includegraphics[width=50mm]{ut/tiling/d1-many-tiled-5-simplexes}
\caption{The initial state of a 5-chain simplex before tiling. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
\label{fig:tiled-simplex-5-d1}
\end{figure}

\begin{figure}
\centering
\includegraphics[width=50mm]{ut/tiling/d1-many-tiled-17-simplexes}
\caption{The initial state of a 17-chain simplex before tiling. Vertices are simplex-chains. Edges are the reflections between simplex-chains.}
\label{fig:tiled-simplex-17-d1}
\end{figure}

\autoref{fig:tiled-simplex-5-d1} assumes an $O(c)$ node has capacity for tracking $4 \cdot n$ simplex-chains, with $n = 5$.

### incrementing depth of tiles

\todo[inline]{explain diags}

NB for figs: Vertices are simplex-chains. Edges are the reflections between simplex-chains.

\begin{comment}
side by side figures: https://tex.stackexchange.com/questions/37581/latex-figures-side-by-side
\end{comment}

\begin{figure}
    \centering
    \begin{subfigure}{.30\textwidth}
        \centering
        \includegraphics[width=.75\linewidth]{ut/tiling/d2-many-tiled-5-simplexes}
        \caption{1st iteration.}
        \label{fig:tiled-simplex-5-d2}
    \end{subfigure}%%
    \begin{subfigure}{.30\textwidth}
        \centering
        \includegraphics[width=.75\linewidth]{ut/tiling/d3-many-tiled-5-simplexes}
        \caption{2nd iteration.}
        \label{fig:tiled-simplex-5-d3}
    \end{subfigure}%%
    \begin{subfigure}{.30\linewidth}
        \centering
        \includegraphics[width=.75\linewidth]{ut/tiling/d4-many-tiled-5-simplexes}
        \caption{3rd iteration.}
        \label{fig:tiled-simplex-5-d4}
    \end{subfigure}
    \caption{The state of tiled 5-chain simplexes after sequential iterations.}
\end{figure}
