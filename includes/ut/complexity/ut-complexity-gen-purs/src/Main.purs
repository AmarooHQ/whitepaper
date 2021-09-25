module Main where

import Prel

import Amaroo.WP.Calcs
import Amaroo.WP.Tables
import Data.Array (length)
import Effect (Effect)
import Effect.Console as C

main :: Effect Unit
main = do
  C.log "🍝"
  C.log $ showTable tableTps
