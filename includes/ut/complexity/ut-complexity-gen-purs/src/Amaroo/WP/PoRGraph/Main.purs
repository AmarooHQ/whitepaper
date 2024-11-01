module Amaroo.WP.PoRGraph.Main where

import Prel

{-|

# Reconstructing the PoR graph

In a simplex, each header reflects ~N_1 headers (on average).

If a user downloads all of the headers (from all simplex-chains), then they know
the hashes of all the headers.

If a user knows the order of reflections, and all headers, then they should be
able to reconstruct all the necessary PoRs (since the PoRs root is a merkle root
of a tree of headers + branches proving a PoR to a root in the relevant header,
which is data the user has already constructed).

If an ordering algorithm (e.g., via VLMTs) is used to enforce a deterministic
structure of the root of PoRs, then the user only need to know the headers that
have not been reflected by any other block (that the current header reflects).
That's because all other headers that *can* be reflected *are* reflected in some
way.

https://forum.amaroo.com/t/reconstructing-the-complete-por-graph-whats-the-min-info-needed/51/3

this probs has a formulation in graph theory, like 2 graphs have a 1 to 1 mapping.

|-}

-- data Block a = Block (Array (Block a)) (Array (Block Symbol))

-- type Hash = Int
-- type ChainID = Int
-- type Refls = Array (Tuple ChainID (Array Hash))

-- type Block = {hash :: Int, parents :: Array Hash, chain :: ChainID, refls :: Refls}
