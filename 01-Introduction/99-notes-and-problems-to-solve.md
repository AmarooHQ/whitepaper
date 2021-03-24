## notes on some problems to solve

idea:

there are at least two problems i think the reflection idea + heterogeneous hashing algs needs to solve:
1. how do you deal with situations that might arise from a withholding attack (e.g. the withheld local chain history has more work than the 'honest' one, but the 'honest' one has reflected PoW -- possible answer: user choice)?
2. how do you measure relative weight between PoW algorithms? you need some answer to this to answer questions like 'which chain+reflections "weigh" more', 'what should the block reward be?', 'can you deal with situations that might arise from a withholding attack by summing the relative weights of PoW chains and maximizing?', etc.

I think we should reject (2) as an invalid question; it's backwards. We aren't trying to decide what the relative weight is, or measure it like some constant of the universe; that's impossible to do perfectly since it's based on chaotic market conditions (at least from the network's PoV). Instead, a magic number for the relative weight is ~obtainable via the relative block rewards which is itself determined by ROO on those chains. (The idea to use ROO to determine block reward has been around for a while; I just forgot it thinking about heterogeneous stuff.) That is: if the relative weight of different chains is dependent on market forces, and the relative manifestations of those market forces are dependent on something we know, then we should just use the ratio of the 'somethings we know'. i.e. the scaling factor is approx: 'the ratio of ROO on the paired chains' * 'delta time' (i.e. duration). bonus points for ~integrating over 'time' rather than taking a simple rectangular approximation.

What I mean is:

the users determine the weight between chains via their distribution of ROO; market forces follow. We can't include factors like "litecoin price drops a bit so some scrypt miners move over because more ROI", and even if we tried to ~normalize against the ROO/LTC pair, we can't know all the scrypt chains or all the incentives for scrypt miners, not to mention the troubles in trying to track many many blockchains' protocol updates (even if distributed). we can't have that sort of complexity and variance in a core protocol like deciding mining rewards.

So the answer (if one exists) must be that mining rewards are based on simple known things, and 'the total ROO stored on each chain' fits the bill. All this means that the resource distribution (of miners) will follow a market equilibrium (everyone maximizes ROI). If, despite the above, we tried to balance things anyway, then we'd want a formula like: 'magic_conversion_number' = 'magic_AB_constant' * ('constant for market adjustment for A') / ('constant for market adjustment for B'). However, we can also expect that 'block_reward(ROO_on_A_chains)' / 'block_reward(ROO_on_B_chains)' to converge to the product of 'magic_AB_constant' with the ratio of 'constant for market adjustment for \{A,B\}'. What would our 'magic_conversion_number' let us do? It would let us convert non-native PoW to some unit we can compare to native PoW, which means that we can base a consensus algorithm on it. It also means that we could say something like: 'hashes of type A' = 'magic_conversion_number' * 'hashes of type B'. We already decide all the variables we need to for complete information.

Q (2) is invalid b/c it's treating relative weight between PoW algs as an *output* when really it's just an *input* in disguise.

This means we can reject (2) and answer (1) - how do we deal with situations like a withholding attack, we know the relative weights because the users decided them.

further idea: (speculative)

could we index the ROO on all chains centrally and then like ~sort/order them to engineer situations where particular properties hold? mb like security stuff. Is the network stronger if the network were to not have a microchain and all chains just paired/reflected with "neighbouring" chains post-sort? they'd still share PoW but weak chains would be more susceptible to short term attacks. but weak chains don't have much reason to be attacked over the short term (nothing economically vital is going on; it'd be like comments and forums and low value stuff).

this relates to another thought I haven't written yet: I think ROO distribution can be used to make a ~balanced microchain with heterogenous hashing (like the microchain itself accepts PoW in different hashes). i.e. we could give like ~all ASIC miners a reason to consider running an Amaroo node (b/c all ASIC miners have some opportunity cost by not running one and occasionally switching over). the problem with that is that block headers are pretty crucial to ASICs, and often ASICs alter blockheaders to do e.g. 4b at once (e.g. via incrementing the nonce in Bitcoin PoW calculation). The problem is that the may be necessary overhead b/c we have to fit within lots of diff protcol specifications (like have something that looks and acts like a valid data struct for that chain).

Hmm. Not sure yet.
