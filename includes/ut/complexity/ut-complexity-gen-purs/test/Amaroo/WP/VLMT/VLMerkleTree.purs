module Test.Amaroo.WP.VLMT.VLMerkleTree where

import Prel

import Amaroo.WP.VLMT.VLMerkleTree as VLMerkleTree
import Data.Generic.Rep (class Generic)
import Data.Int (pow)
import Data.Show.Generic (genericShow)
import Test.QuickCheck.Arbitrary (class Arbitrary)
import Test.QuickCheck.Gen (chooseInt)
import Test.Spec (describe, it)
import Test.Spec.QuickCheck (quickCheck)

newtype VLBalancedMerkleTest = VLBalancedMerkleTest { size :: Int, leaf :: Int }
newtype VLMerkleTest = VLMerkleTest { size :: Int, leaf :: Int }

derive instance genericVLMerkleTest :: Generic VLMerkleTest _
derive instance genericVLBalancedMerkleTest :: Generic VLBalancedMerkleTest _

instance showVLMerkleTest :: Show a => Show VLMerkleTest where
  show = genericShow
instance showVLBalancedMerkleTest :: Show a => Show VLBalancedMerkleTest where
  show = genericShow

instance arbitraryVLBalancedMerkleTest :: Arbitrary VLBalancedMerkleTest where
  arbitrary = do
    -- binary
    size <- pow 2 <$> chooseInt 6 13
    leaf <- chooseInt 64 size
    pure $ VLBalancedMerkleTest { size, leaf }

instance arbitraryVLMerkleTest :: Arbitrary VLMerkleTest where
  arbitrary = do
    -- binary
    size <- chooseInt 100 10_000
    leaf <- chooseInt 100 size
    pure $ VLMerkleTest { size, leaf }

testVLMerkleTreeSpec =
  describe "VLMT" do
    it "Balanced VLMTs quickcheck" do
      quickCheck \(VLBalancedMerkleTest { size, leaf }) ->
        VLMerkleTree.testVLMerkleProofN size leaf
    it "Unbalanced VLMTs quickcheck" do
      quickCheck \(VLMerkleTest { size, leaf }) ->
        VLMerkleTree.testVLMerkleProofN size leaf
