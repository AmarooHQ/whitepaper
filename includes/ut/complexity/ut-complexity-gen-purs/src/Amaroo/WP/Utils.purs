module Amaroo.WP.Utils where

import Prel

import Data.Array (length, unsafeIndex)
import Partial.Unsafe (unsafePartial)

ui :: forall a. Array a -> Int -> a
ui xs i = unsafePartial unsafeIndex xs i

diagonalApply_ :: forall b o. (b -> Array o) -> Array b -> Int -> Array o
diagonalApply_ f bs i
    | i >= length bs = []
    | otherwise = [ui (f $ ui bs i) i] <> diagonalApply_ f bs (i + 1)

diagonalApply f bs = diagonalApply_ f bs 0
