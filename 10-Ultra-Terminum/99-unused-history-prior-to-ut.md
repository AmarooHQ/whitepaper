##

To explain *Ultra Terminum*, we will need to go back.

2011 - merged mining and AuxPoW
2013 - marketcoin, SPV proofs, and distributed exchange
2013/4 - Ethereum
2014 - GPDHT, The Grachten, and Microchains
2014 - Quanta (a DAG-chain) and Cryptonet
2015 - The Beginning of Infinity
2015/6/7 - Voting and Anchoring
2017/8 - Daggy Microchains
2018 - Quanta generalization
2018/9/20/21 - yes/no, Goldratt, and Critical Fallibilism
2021 - mutual confirmation and PoW reflection
2021 - heterogeneous PoW
2021 - *Ultra Terminum*

heterogeneous PoW means: multiple hash algorithms are involved; this implies that multiple types of ASICs and/or GPUs and/or whatever are necessary in some way for an attack to be successful.

PoW reflection means: two chains track each other's block headers and recursively calculate a block's weight to efficiently share PoW; this does introduce some potential issues, like a chain fork on one might cause a chain fork on the other, but those issues are somewhat reconcilable. it could be the sort of thing you can only
practically achieve when launching your own network. the effect of PoW reflection is that a successful 51% attack against *one* chain MUST attack *both* chains.

heterogenous PoW reflection means: the combination of the above. a key ingredient in what makes this work is: the block reward is tied to the total ROO stored in the dapp-chains that are mined. b/c the block reward is proportional to the ratio of ROO stored there, we can effectively measure the current market rate of ROO/hash, and thus we can meaningfully combine and compare the work done on two different chains.
