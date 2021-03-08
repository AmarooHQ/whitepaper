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
    I/we present *Amaroo* and *Ultra Terminum*. *Amaroo* is a machine for making blockchains. *Ultra Terminum* (UT) is a hybrid PoW/PoS method providing $O(c^2)$, $O(c^3)$, or $O(c^4)$ scaling.
    \newline
    **NOTE: PRERELEASE -- DO NOT SHARE OR DISTRIBUTE!!!**
---
