module Test.Amaroo.WP.VLMT.MerkleTree where

import Prel

import Amaroo.WP.VLMT.MerkleTree as MerkleTree
import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)
import Test.Spec.QuickCheck (quickCheck)
import Test.QuickCheck.Arbitrary (class Arbitrary)
import Test.QuickCheck.Gen (chooseInt)

newtype MerkleTest = MerkleTest { size :: Int, leaf :: Int }

derive instance genericMerkleTest :: Generic MerkleTest _

instance showMerkleTest :: Show a => Show MerkleTest where
  show = genericShow

instance arbitraryMerkleTest :: Arbitrary MerkleTest where
  arbitrary = do
    size <- chooseInt 100 10000
    leaf <- chooseInt 100 size
    pure $ MerkleTest { size, leaf }

testMerkleTreeQuickcheck = quickCheck \(MerkleTest { size, leaf }) ->
  MerkleTree.testMerkleProofN size leaf
