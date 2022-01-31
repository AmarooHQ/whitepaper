module Test.Amaroo.WP.VLMT.VLMerkleTree where

import Prel

import Amaroo.WP.VLMT.VLMerkleTree as VLMerkleTree
import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)
import Test.Spec.QuickCheck (quickCheck)
import Test.QuickCheck.Arbitrary (class Arbitrary)
import Test.QuickCheck.Gen (chooseInt)

newtype VLMerkleTest = VLMerkleTest { size :: Int, leaf :: Int }

derive instance genericVLMerkleTest :: Generic VLMerkleTest _

instance showVLMerkleTest :: Show a => Show VLMerkleTest where
  show = genericShow

instance arbitraryVLMerkleTest :: Arbitrary VLMerkleTest where
  arbitrary = do
    size <- chooseInt 100 10000
    leaf <- chooseInt 100 size
    pure $ VLMerkleTest { size, leaf }

testVLMerkleTreeQuickcheck = quickCheck \(VLMerkleTest { size, leaf }) ->
  VLMerkleTree.testVLMerkleProofN size leaf
