FROM texlive/texlive:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y make latexmk graphviz dot2tex gnuplot git && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-1-amd64.deb && \
    dpkg -i pandoc-2.5-1-amd64.deb && \
    rm pandoc-2.5-1-amd64.deb

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y texlive-science texlive-extra-utils texlive-latex-extra && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["make"]
