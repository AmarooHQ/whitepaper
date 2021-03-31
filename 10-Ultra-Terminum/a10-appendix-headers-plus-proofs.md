# Reflection with Merkle Branches

What does a simplex look like if simplex-chains include proofs of reflection?

Let $g$ be the length of the digest in bytes, i.e., the size of the hashes used in our merkle trees.

\begin{equation}
\begin{split}
k_1 & = k_{1,tx} + k_{1,b} \\
& = k_{1,tx} + B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1) \\
\implies T_1 & = N_1 \cdot (k_{1} - B_f \cdot N_1 \cdot (B_h + g \cdot \log_2 N_1)) \\
\frac{dT_1}{dN_1} & = \frac{1}{\ln 2}(k_1 \cdot \ln 2 - B_f \cdot N_1 \cdot (g + B_h \cdot \ln 4) - 2 \cdot B_f \cdot g \cdot N_1 \cdot \ln N_1) \\
& \mbox{which has the root} \\
N_1 & = \frac{k_1 \cdot \ln 2}{2 \cdot B_f \cdot g \cdot W_0(\frac{1}{B_f \cdot g}(2^{\frac{B_h}{g} - 1} \cdot \sqrt e \cdot k_1 \cdot \ln 2))}
\end{split}
\end{equation}

Note: $W_0(z)$ is the Lambert W function, aka the product logarithm.
