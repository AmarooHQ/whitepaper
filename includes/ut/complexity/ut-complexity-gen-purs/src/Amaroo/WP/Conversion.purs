module Amaroo.WP.Conversion where

-- import Prel

-- import Data.Tuple (Tuple(..))
-- import Prelude (class Semiring)

{-|

Quickcheck conversion properties.

In ./includes/ut/20-por/30-comparing-work-3.tex I mention some properties that need to hold.
Sweet, property based testing time.

Additionally, it means defining the conversion functions more specifically.

Example checks:
- does measuring chain-weight in coins work like predicted?

|-}

-- weightOf_coinsSimple :: Block -> State -> Number
-- weightOf_coinsSimple b state = blockRewardOfAt_coinsSimple (chainOf b) (b.timestamp) state

-- weightOf_

data State = State Int

newtype Timestamp = Timestamp Int

class BlockWeight b where
  weightOf :: b -> Number
  timestampOf :: b -> Timestamp

class Network n where
  getFrequencyOf :: n -> State

class (BlockWeight b, Network n) <= ConvBlockWeight n b where
  reflectedWeightOf :: n -> b -> Number
  networkInflation :: n -> b -> Number
  ratioTokensOn :: n -> b -> Number
