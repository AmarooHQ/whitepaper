module Main where

import Prelude
-- import Data.List (List)
import Data.List.NonEmpty (NonEmptyList)
import Effect (Effect)
import Effect.Console (log)

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
    , simplex :: UtVariants ChainStats
    }

main :: Effect Unit
main = do
  log "🍝"
