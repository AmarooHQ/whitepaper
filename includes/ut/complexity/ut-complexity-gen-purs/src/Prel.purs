module Prel (module Prelude, module Prel) where

import Prelude

import Data.Function (applyFlipped)
import Math (ceil, log)

-- (|>) :: \forall a b. a -> (a -> b) -> b
infixl 1 applyFlipped as |>

log2 :: Number -> Number
log2 x = log x / log 2.0

log2c :: Number -> Number
log2c = ceil <<< log2
