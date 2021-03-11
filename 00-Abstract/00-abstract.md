---
title: The Amaroo Whitepaper
author: Max Kaye
output:
    html_document:
        mathjax: https://cdn.rawgit.com/mathjax/MathJax/2.7.1/latest.js?config=TeX-AMS-MML_HTMLorMML
        number_sections: yes
        includes:
            in_header: includes/header.html
header-includes: |
    \usepackage{comment}
    \usepackage{siunitx}
    \usepackage{todonotes}
    \usepackage[lastpage,user]{zref}
    \usepackage{fancyhdr}
    \pagestyle{fancy}
    \begin{comment}
        \fancyhead[CO,CE]{This is fancy}
        \fancyfoot[LE,RO]{}
    \end{comment}
    \fancyfoot[C]{\thepage\ of \zpageref{LastPage}}
    \DeclareSIUnit{\block}{block}
    \setuptodonotes{inlinepar}
    \fancypagestyle{firststyle}
    {
        \fancyhf{}
        \fancyfoot[C]{\thepage\ of \zpageref{LastPage}}
    }
abstract: >
    \thispagestyle{firststyle}
    I/we present *Amaroo* and *Ultra Terminum*. *Amaroo* is a machine for making blockchains.
    \todo[inline]{nb: these are "todo" comments}
    *Ultra Terminum* (UT) is a hybrid PoW/PoS method providing $O(c^2)$, $O(c^3)$, or $O(c^4)$ scaling.
    \todo[inline]{check the maths for tiling complexity:}
    Additionally, a novel method of 'tiling' is proposed which provides $O(2^i \cdot c^j)$ scaling, for $i = \lceil \log_2 ((\frac{n}{c^j} + 2) / 3) \rceil, j \in \{2,3,4\}$ --- just in case.
    With reasonable parameters (i.e. a per-node load comparable to Bitcoin) and $O(c^3)$ scaling, UT can comfortably exceed 1m tps without additional scaling methods (e.g. payment channels).
    This figure is highly sensitive to block production frequency and, for comparison's sake, 10 minute target times for blocks could provide up to 180m tps.
    \newline
    **NOTE: PRERELEASE -- DO NOT SHARE OR DISTRIBUTE!!!**
---
