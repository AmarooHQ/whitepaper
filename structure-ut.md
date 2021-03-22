# Structure of UT WP

The structure itself will be captured in the TOC generated for the UT paper. This doc is ancillary and a place to list stuff that should be included. It'll let me/us check that everything that needs to be included has been included. The order is roughly reflective of the paper tho that's just a convenience.

## big / meta / theme stuff

- what is the structure of other consensus papers?
  - **TODO** identify common structural elements of past papers and compare to what we have. is anything missing?

## sections and deets

- intro
- background info & foundational concepts
  - Meaning of O(C)
  - SPV
  - *probs not* MM? IDK
  - *probs not* DAGS? Not required at this stage
- problem that we're solving
  - buterin's trilemma
  - explanation and conflict
- UT itself
  - PoW reflection
    - comparing hashrate
      - foreshadow incentive structure stuff
    - redux of block-weight calculations
      - **todo** brainstorm block-weight methods and crits/qualities/etc
        - compare to existing nakamoto consensus weight method
  - Simplex
    - blockchain requirements to work with the simplex
    - PoW / PoS algs
      - security params?
    - design requirements
      - good and bad qualities of simplex-chains
    - problems with naive architecture
  - Dapp-chains
    - flexibility & extending UT/Amaroo
    - dapp-chain attacks
  - Complexity analysis
    - algebra and derivation
      - o(c)
      - o(c^2) -- other e.g. eth2
      - o(c^2) -- UT
      - o(c^3) and generalization
    - Comparison to other methods
  - Attacks on simplex
    - meta: Methods of analyzing security
  - Fixing Problems
    - DAGs
    - block availability
  - Tiling
    - method
      - initial
      - iteration step
    - complexity
      - derive formula from method rather than searching OEIS
    - tiling attacks?
  - Practicality
    - data struct requirements
    - bandwidth requirements
    - architecture limitations
    - **todo** brainstorm impracticality concerns
  - Neat features
    - lower variance of PoW blocks without changing target time
- appendix: answered crit index
  - **todo** brainstorm predicted crits
  - **todo** answer those crits and/or link to parts of paper where they are answered
  - **todo** brainstorm reasons ppl would have a negative reaction (e.g. PoW, patent)
- appendix: code for generating comparison tables
- glossary

## other structure stuff todo

Set dates for WP review, probably more at end of month.
