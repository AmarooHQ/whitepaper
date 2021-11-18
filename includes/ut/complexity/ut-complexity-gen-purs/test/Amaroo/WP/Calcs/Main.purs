module Test.Amaroo.WP.Calcs.Main where

import Prel

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Amaroo.WP.Calcs.Tiling (tilingSpec)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)


main :: Effect Unit
main = do
  launchAff_ $ runSpec [consoleReporter] do
    tilingSpec
