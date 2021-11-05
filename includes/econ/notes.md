


philosophy (wrt writing draft):
- don't innovate in areas we don't need to -- simple is good
- just the constraints and a simple system that works
- should be capable of becoming the world's reserve currency (if we do it wrong then we might eliminate the option!)
- don't rule out options with tiling! we need to make sure whatever we do is compatible with many options for doing tiling



regarding tracking supply on each schain (and doing so in simplex-lvl headers)
* 128 bits (16 bytes) for tracking supply?


- draft
- initial view
- working model
- * tables
- "smart coin"

- Reward Adjustment Algorithm
  -
- map out invovled things
- supply -- no dapp-chains
- value -- dapp-chains
- constraints

- avoid supply shocks to currency
  - add neg pressure / incentive for micro-corrections
  - fake stability -> instability


- case analysis
  - dapp-chains move host simplex-chain
  - external net migrates to be roo-dapp-chain
  - or migrates out





# CN:

structured around incentives -> long term models
-> would look at block rewards, IDK about conversion between.. well not conversion, spread of tokens between them (and dapp-chains)
if there is a way to model a supply cap



why supply cap important

provides a limit so there's not an over inflation of things

infinite money printing is bad
- given to exclusive group (oligarchy)
-


*makes sure* that everyone's balance doesn't devalue
- so you have a finite number of things
- after that you know the value ... it sorta stabalizes



### Overview

* Why supply cap important?
  - Provides a _shortcut_ for predictability and reliability (e.g. that in future the balance won't devalue outside of known factors)
    - (potential if non trivial large percentage gets _burnt_)
* Inflation Rates
  - deterministic (i.e. 10 coins, or fixed percentage) provides predictability, even with no supply cap, can still be predictable
  - non-deterministic (i.e. fiat currencies (AUD)) have (i) variable/unseen inflation, and (ii) not very publicly known supply makes predictability and reliability difficult to forecast.

Studying Ethereum:
* Doesn't have fixed supply.
* Predictions for long term - few unknowns because of variability in the block reward
* "Not all miners are happy"
  - If against changes, should be against _any_ change, not just the ones that don't favour you.
  - E.g. look at Bitcoin's prohibited: https://en.bitcoin.it/wiki/Prohibited_changes


Simplex Chains and Dapps

* Ratio and distribution of ROO
* What happens if a single simplex chain has too many dapp-chains, that it reaches capacity?
  - Allow dapp-chains to move?
    - How?
      * Dapp-chain adjustment algorithms
      * Hook to the simplex chain to say that the dapp is moving (to new destination)
      * Protocol level move (so that people know where it is moving to, and the state gets acknowledged)
      * **division**
        - Like 'cell-division', a simplex chain can be _partitioned_?
        - Don't want to redistribute the ROO
      * **Incentives**
        - As a simplex chain reaches capacity, if going > 100%, then difficulty will rise and tx fees will be burnt.
          - example: 'Most valuable transaction fees, 50% of it will be burnt'
          - Incentive to move to a different simplex chain before this happens.



Reward items:
  - Block rewards (mining)
  - Tx Fees

Variables:
* Distribution
  - Number of dapp-chains, ratio/amount of ROO on the simplex chain
  - Difficulty of the blocks,
* Incentives
  - Burning / minting of the coins.
    - As a reaction to distribution/difficulty/capacity?


Questions:
  - Ratio of block rewards dedicated to 'reflection'?
    - i.e. 10% of the block reward goes to inclusion of headers to facilitate PoR
    - if a miner doesn't include it, is there some punishment?
    - What if a miner includes the _wrong_ block? (what is a _wrong_ block? How would they know?)
  -


- https://github.com/ethereum/EIPs/pull/2878
- https://ethereum-magicians.org/t/eip-2878-block-reward-reduction-to-0-5-eth/4500
- https://www.reddit.com/r/EtherMining/comments/idvpf7/eip2878_i_am_sick_and_tired_of_this_network/






jan 1st 2014
