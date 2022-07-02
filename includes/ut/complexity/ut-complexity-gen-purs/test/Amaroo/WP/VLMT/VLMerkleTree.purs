module Test.Amaroo.WP.VLMT.VLMerkleTree where

import Prel

import Amaroo.WP.VLMT.VLMerkleTree (VLMerkleProof(..), VLMerkleRoot(..), VLProofElem(..), testVLMTConfigDefault)
import Amaroo.WP.VLMT.VLMerkleTree as VLMerkleTree
import Data.Generic.Rep (class Generic)
import Data.Int (pow)
import Data.List (List(..), (:))
import Data.Show.Generic (genericShow)
import Data.Tuple (Tuple(..))
import Test.Amaroo.WP.VLMT.Consts (_MERKLE_TREE_SIZE)
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
    size <- chooseInt 100 _MERKLE_TREE_SIZE
    leaf <- chooseInt 100 size
    pure $ VLMerkleTest { size, leaf }

corruptProof :: VLMerkleProof _ _ -> VLMerkleProof _ _
corruptProof p@(VLMerkleProof Nil) = p
corruptProof (VLMerkleProof (elem : p')) = VLMerkleProof (newElem : p')
  where
    VLProofElem elem'@{siblingRoot: VLMerkleRoot (Tuple k v)} = elem
    newElem = VLProofElem (elem' {siblingRoot = VLMerkleRoot (Tuple (k+1) v)})

testVLMerkleTreeSpec =
  describe "VLMT" do
    let testConf = testVLMTConfigDefault
        testConfBad = { expectValid: false, modifyProof: corruptProof }
    it "Balanced VLMTs quickcheck" do
      quickCheck \(VLBalancedMerkleTest { size, leaf }) ->
        VLMerkleTree.testVLMerkleProofN size leaf testConf
    it "Unbalanced VLMTs quickcheck" do
      quickCheck \(VLMerkleTest { size, leaf }) ->
        VLMerkleTree.testVLMerkleProofN size leaf testConf
    it "VLMTs with broken proofs quickcheck" do
      quickCheck \(VLMerkleTest { size, leaf }) ->
        VLMerkleTree.testVLMerkleProofN size leaf testConfBad
