module Calcs where

import Data.List.NonEmpty (NonEmptyList)

{-|

# Complexity Calculations

For a given set of parameters we want to generate all possible output data (keeps things easy and general).

Other chains are all under the `ChainCalcs.trad` model; and UT is under `ChainCalcs.ut`.

Any new UT variants should be added to the `UtVariants` type, and

-}

type ChainNestingParams
  = { bf :: Number, bh :: Number }

type Params
  = { ks :: NonEmptyList Number
    , hfs :: NonEmptyList ChainNestingParams -- | List of {header,frequency} pairs
    , txSize :: Number
    }

type UtVariants a
  = { pors :: a
    , ports :: a
    , std :: a
    , t :: a
    , ho :: a
    , hot :: a
    }

type NestingStats
  = { tps :: Number
    , n :: Number
    , t :: Number
    }

type ChainStats
  = { d1 :: NestingStats
    , d2 :: NestingStats
    , d3 :: NestingStats
    , deltaBigS :: Number
    , deltaSmallS :: Number
    , tts :: Number
    , confRate :: Number
    }

type ChainCalcs
  = { trad :: ChainStats
    , ut :: UtVariants ChainStats
    }
