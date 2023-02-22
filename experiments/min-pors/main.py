'''
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
'''

# -- data Block a = Block (Array (Block a)) (Array (Block Symbol))

# type Hash = Int
# type ChainID = Int
# type Refls = Array (Tuple ChainID (Array Hash))

# type Block = {hash :: Int, parents :: Array Hash, chain :: ChainID, refls :: Refls}

from dataclasses import dataclass
from random import random, randint


@dataclass
class Block:
    hash: int
    chain: int
    parents: list[int]
    refls: list[tuple[int, list[int]]]  # [(ChainID, [Hash])], sortable
    novel_refls: list[tuple[int, list[int]]]

    @staticmethod
    def make(h, c, ps, rs, nrs):
        b = Block(h, c, ps, rs, nrs)
        all_blocks[h] = b
        return b

@dataclass
class Chain:
    id: int
    tips: list[int]
    refls: dict[int, set[int]] # chainID => set of all reflected blocks for that R chain


'''
each tick, there's a 1/15 chance of a block being created (to simulate 1s propagation time and 15s block times)
say we have 200 chains
say that 2 blocks are generated with P = (1/15)^2
  note: idk if that really matters, maybe skip it for now and add it in later
'''

creation_prob = 1 / 15
n_chains = 200
n_blocks_total = 10_000
hash_upper = n_blocks_total**2

all_blocks = {0: Block(0, [], -1, [])}

def tick():
    for i in range(n_chains):
        if random() < creation_prob:
            # make a block
            h = randint(100, hash_upper)
            while h in all_blocks:
                h = randint(100, hash_upper)
            b = Block.make(h)  # todo: add chain-state here for refls and things
            # tell all chains about block so they can do refls
