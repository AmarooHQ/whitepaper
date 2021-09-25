module Prel (module Prelude, module Prel) where

import Prelude

import Data.Function (applyFlipped)
import Data.Tuple (Tuple, fst, snd)
import Math (ceil, log)

-- (|>) :: \forall a b. a -> (a -> b) -> b
infixl 1 applyFlipped as |>
infixr 0 apply as <|

log2 :: Number -> Number
log2 x = log x / log 2.0

log2c :: Number -> Number
log2c = ceil <<< log2

tupToRec :: forall a b. Tuple a b -> {a :: a, b :: b}
tupToRec t = {a: fst t, b: snd t}
