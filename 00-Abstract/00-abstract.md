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
    \fancyfoot[C]{\thepage\ of \zpageref{LastPage}}
    \DeclareSIUnit{\block}{block}
    \setuptodonotes{inlinepar}
    \fancypagestyle{firststyle}
    {
        \fancyhf{}
        \fancyfoot[C]{\thepage\ of \zpageref{LastPage}}
    }
    \usepackage[mark]{gitinfo2}
    \renewcommand{\gitMark}{
        \gitAbbrevHash{} (\gitAuthorDate)}
abstract: >
    \thispagestyle{firststyle}
    I/we present *Amaroo* and *Ultra Terminum*. *Amaroo* is a machine for making blockchains.
    \todo{nb: these are "todo" comments}
    *Ultra Terminum* (UT) is a hybrid PoW/PoS method providing $O(c^2)$, $O(c^3)$, or $O(c^4)$ scaling.
    \todo{check the maths for tiling complexity:}
    Additionally, a novel method of 'tiling' is proposed which provides $O(2^i \cdot c^j)$ scaling, for $i = \lceil \log_2 ((\frac{n}{c^j} + 2) / 3) \rceil, j \in \{2,3,4\}$ --- just in case.
    With reasonable parameters (i.e., a per-node load comparable to Bitcoin) and $O(c^3)$ scaling, UT can comfortably exceed 1m tps without additional scaling methods (e.g. payment channels).
    For comparison's sake, parameters that allow existing $O(c^2)$ blockchains to reach 1m tps can, under $O(c^3)$ UT, provide a raw maximum capacity of between 1 and 20 billion tps (give or take).
    \newline
    **NOTE: PRERELEASE -- DO NOT SHARE OR DISTRIBUTE!!!**
include-before: >
    \newpage
    \todo{format this correctly. see BOTNS for correct formatting.\newline ... Hmm, actually mb I like this formatting.}
    \vspace*{\fill}
    \begin{center}
    \textit{
    A thousand ages in thy sight\newline
    Are like an evening gone;\newline
    Short as the watch that ends the night\newline
    Before the rising sun.
    }
    \end{center}
    \vspace*{\fill}
    \newpage
---
