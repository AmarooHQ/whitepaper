module Test.Main where

import Prel

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Calcs
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)

main :: Effect Unit
main = do
  launchAff_ $ runSpec [consoleReporter] do
    tradSpec
    utSpec
