module Test.Amaroo.WP.VLMT.Main where

import Prel

import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Amaroo.WP.VLMT.MerkleTree (testMerkleTreeQuickcheck)
import Test.Amaroo.WP.VLMT.VLMerkleTree (testVLMerkleTreeSpec)
import Test.Spec (Spec, describe, it)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)

allMerkleTreesSpec :: Spec Unit
allMerkleTreesSpec = describe "Merkle Trees (All)" do
  describe "Vanilla Merkle Tree" do
    it "quickcheck proofs" do
      testMerkleTreeQuickcheck
  testVLMerkleTreeSpec


main :: Effect Unit
main = do
  launchAff_ $ runSpec [consoleReporter] do
    allMerkleTreesSpec
