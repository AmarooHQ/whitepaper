# Invention Details

\let\origSec\section
\let\origSubSec\subsection
\let\origSubSubSec\subsubsection
\let\origSubSubSubSec\paragraph

\let\subsubsection\origSubSubSubSec
\let\subsection\origSubSubSec
\let\section\origSubSec

\input{includes/inventiveness/abstract.tex}
\input{includes/inventiveness/body.tex}

\let\section\origSec
\let\subsection\origSubSec
\let\subsubsection\origSubSubSec
