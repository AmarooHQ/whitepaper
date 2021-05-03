FROM ubuntu:focal

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y texlive-full make pandoc latexmk graphviz dot2tex gnuplot git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["make"]
