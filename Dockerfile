FROM texlive/texlive:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget make latexmk graphviz dot2tex gnuplot git && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-1-amd64.deb && \
    dpkg -i pandoc-2.5-1-amd64.deb && \
    rm pandoc-2.5-1-amd64.deb

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip texlive-science texlive-extra-utils texlive-latex-extra nodejs npm expect && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install -U --break-system-packages numpy scipy click blessings GitPython

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y pdfgrep && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /.npm && chown -R 1000:1000 "/.npm"

WORKDIR /work

CMD ["unbuffer", "make"]
