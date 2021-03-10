---
title: Amaroo Whitepaper
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
    \usepackage{fancyhdr}
    \pagestyle{fancy}
    \begin{comment}
        \fancyhead[CO,CE]{This is fancy}
        \fancyfoot[CO,CE]{So is this}
    \end{comment}
    \fancyfoot[LE,RO]{\thepage}
    \DeclareSIUnit{\block}{block}
    \setuptodonotes{inlinepar}
abstract: >
    I/we present *Amaroo* and *Ultra Terminum*. *Amaroo* is a machine for making blockchains.
    \todo[inline]{nb: these are "todo" comments}
    *Ultra Terminum* (UT) is a hybrid PoW/PoS method providing $O(c^2)$, $O(c^3)$, or $O(c^4)$ scaling. \todo[inline]{check these numbers:} Additionally, a novel method of 'tiling' is proposed which provides $O(2^i \cdot c^j)$ scaling, for $i = \lceil \log_2 ((\frac{n}{c^j} + 2) / 3) \rceil, j \in \{2,3,4\}$ --- just in case.
    \newline
    **NOTE: PRERELEASE -- DO NOT SHARE OR DISTRIBUTE!!!**
---
