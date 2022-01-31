-- | Original code from: https://github.com/alpacaaa/purescript-merkle-tree/blob/master/src/Crypto/Hash/VLMerkleTree.purs
-- | (Original code distributed under MIT license)
{-

# LICENSE FOR **THIS** FILE

MIT License

Copyright (c) 2017 Marco Sampellegrini, (c) 2022 Max Kaye

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-}
module Amaroo.WP.VLMT.VLMerkleTree
  ( Side(..)
  , VLMerkleNode(..)
  , VLMerkleProof(..)
  , VLMerkleRoot(..)
  , VLMerkleTree(..)
  , VLProofElem(..)
  , VLProofList(..)
  , merkleProof
  , mkLeafRootHash
  , mkVLRootHash
  , mkVLMerkleTree
  , mtHash
  , mtHeight
  , mtRoot
  , mtSize
  , vlNodeRoot
  , testVLMerkleProofN
  , validateVLMerkleProof
  , vlEmptyHash
  )
  where


import Prel

import Data.Foldable (class Foldable)
import Data.Foldable as Foldable
import Amaroo.WP.VLMT.Crypto as Crypto
import Data.Int (even)
import Data.Int.Bits ((.&.), shl, shr)
import Data.List (List(..), (:))
import Data.List as List

newtype VLMerkleRoot :: forall k. k -> Type
newtype VLMerkleRoot a = VLMerkleRoot String

derive instance eqVLMerkleRoot :: Eq (VLMerkleRoot a)

data VLMerkleTree a
  = VLMerkleEmpty
  | VLMerkleTree Int (VLMerkleNode a)

data VLMerkleNode a
  = MerkleBranch {
      mRoot  :: VLMerkleRoot a
    , mLeft  :: VLMerkleNode a
    , mRight :: VLMerkleNode a
  }
  | MerkleLeaf {
      mRoot :: VLMerkleRoot a
    , mVal  :: a
  }

instance foldableVLMerkleTree :: Foldable VLMerkleTree where
  foldr f a b = Foldable.foldrDefault f a b
  foldl f a b = Foldable.foldlDefault f a b
  foldMap _ VLMerkleEmpty      = mempty
  foldMap f (VLMerkleTree _ n) = Foldable.foldMap f n

instance foldableVLMerkleNode :: Foldable VLMerkleNode where
  foldr f a b = Foldable.foldrDefault f a b
  foldl f a b = Foldable.foldlDefault f a b
  foldMap f x = case x of
    MerkleLeaf   { mVal }            -> f mVal
    MerkleBranch { mLeft, mRight }   ->
      Foldable.foldMap f mLeft `append` Foldable.foldMap f mRight



-- | Returns root of merkle tree.
mtRoot :: forall a. VLMerkleTree a -> VLMerkleRoot a
mtRoot VLMerkleEmpty         = vlEmptyHash
mtRoot (VLMerkleTree _ node) = vlNodeRoot node


-- | Returns root of merkle tree root hashed.

mtHash :: forall a. VLMerkleTree a -> String
mtHash VLMerkleEmpty      = vlMerkleHash ""
mtHash (VLMerkleTree _ x) = vlMerkleHash value
  where
    (VLMerkleRoot value) = vlNodeRoot x

mtSize :: forall a. VLMerkleTree a -> Int
mtSize VLMerkleEmpty      = 0
mtSize (VLMerkleTree s _) = s

vlEmptyHash :: forall a. VLMerkleRoot a
vlEmptyHash = VLMerkleRoot (vlMerkleHash "")


vlMerkleHash :: String -> String
vlMerkleHash value = Crypto.hash Crypto.SHA256 value
                 # Crypto.toString


-- | Merkle tree height
mtHeight :: Int -> Int
mtHeight ntx
  | ntx < 2 = 0
  | even ntx  = 1 + mtHeight (ntx `div` 2)
  | otherwise = mtHeight $ ntx + 1

-- | Merkle tree width
mtWidth
  :: Int -- ^ Number of transactions (leaf nodes).
  -> Int -- ^ Height at which we want to compute the width.
  -> Int -- ^ Width of the merkle tree.
mtWidth ntx h = (ntx + (1 `shl` h) - 1) `shr` h

-- | Return the largest power of two such that it's smaller than n.
powerOfTwo :: Int -> Int
powerOfTwo n
   | n .&. (n - 1) == 0 = n `shr` 1
   | otherwise = go n
 where
    go w = if w .&. (w - 1) == 0 then w else go (w .&. (w - 1))


-------------------------------------------------------------------------------
-- Constructors
-------------------------------------------------------------------------------

mkLeaf :: String -> VLMerkleNode String
mkLeaf a =
  MerkleLeaf
    { mRoot: mkLeafRootHash a
    , mVal : a
    }

mkLeafRootHash :: String -> VLMerkleRoot String
mkLeafRootHash a = VLMerkleRoot $ vlMerkleHash ("0" <> a)

vlNodeRoot :: forall a. VLMerkleNode a -> VLMerkleRoot a
vlNodeRoot (MerkleBranch { mRoot }) = mRoot
vlNodeRoot (MerkleLeaf { mRoot })   = mRoot

mkBranch :: forall a. VLMerkleNode a -> VLMerkleNode a -> VLMerkleNode a
mkBranch a b =
  MerkleBranch
    { mLeft : a
    , mRight: b
    , mRoot : mkVLRootHash (vlNodeRoot a) (vlNodeRoot b)
    }

mkVLRootHash :: forall a. VLMerkleRoot a -> VLMerkleRoot a -> VLMerkleRoot a
mkVLRootHash (VLMerkleRoot l) (VLMerkleRoot r) = VLMerkleRoot $ vlMerkleHash $ ("1" <> l <> r)

-- | Smart constructor for 'VLMerkleTree'.
mkVLMerkleTree :: List String -> VLMerkleTree String
mkVLMerkleTree Nil = VLMerkleEmpty
mkVLMerkleTree ls  = VLMerkleTree lsLen (go lsLen ls)
  where
    lsLen              = List.length ls
    go _  (x : Nil) = mkLeaf x
    go len xs = mkBranch (go i l) (go (len - i) r)
      where
        i = powerOfTwo len
        {l, r} = { l: List.take i xs, r: List.drop i xs }

-------------------------------------------------------------------------------
-- Merkle Proofs
-------------------------------------------------------------------------------

type VLProofList :: forall k. k -> Type
type VLProofList a = List (VLProofElem a)

newtype VLMerkleProof :: forall k. k -> Type
newtype VLMerkleProof a = VLMerkleProof (VLProofList a)

data VLProofElem :: forall k. k -> Type

data VLProofElem a = VLProofElem
  { vlNodeRoot    :: VLMerkleRoot a
  , siblingRoot :: VLMerkleRoot a
  , nodeSide    :: Side
  }

data Side = L | R

-- | Construct a merkle tree proof of inclusion
-- Walks the entire tree recursively, building a list of "proof elements"
-- that are comprised of the current node's root and it's sibling's root,
-- and whether it is the left or right sibling (this is necessary to determine
-- the order in which to hash each proof element root and it's sibling root).
-- The list is ordered such that the for each element, the next element in
-- the list is the proof element corresponding to the node's parent node.
merkleProof :: forall a. VLMerkleTree a -> VLMerkleRoot a -> VLMerkleProof a
merkleProof VLMerkleEmpty _ =
  VLMerkleProof Nil
merkleProof (VLMerkleTree _ rootNode) leafRoot =
  VLMerkleProof $ constructPath Nil rootNode
  where
    constructPath :: (VLProofList a) -> VLMerkleNode a -> (VLProofList a)
    constructPath pElems (MerkleLeaf leaf)
      | leafRoot == leaf.mRoot = pElems
      | otherwise              = Nil
    constructPath pElems (MerkleBranch branch) = lPath <> rPath
      where
        bRoot = branch.mRoot
        ln    = branch.mLeft
        rn    = branch.mRight
        lVLProofElem = VLProofElem
          { vlNodeRoot: (vlNodeRoot ln), siblingRoot: (vlNodeRoot rn), nodeSide: L }
        rVLProofElem = VLProofElem
          { vlNodeRoot: (vlNodeRoot rn), siblingRoot: (vlNodeRoot ln), nodeSide: R }

        lPath = constructPath (lVLProofElem:pElems) ln
        rPath = constructPath (rVLProofElem:pElems) rn

-- | Validate a merkle tree proof of inclusion
validateVLMerkleProof :: forall a. VLMerkleProof a ->  VLMerkleRoot a -> VLMerkleRoot a -> Boolean
validateVLMerkleProof (VLMerkleProof proofElems) treeRoot leafRoot =
  validate proofElems leafRoot
  where
    validate :: VLProofList a -> VLMerkleRoot a -> Boolean
    validate Nil proofRoot = proofRoot == treeRoot
    validate (pElem : pElems) proofRoot =
      let
        (VLProofElem proof) = pElem
      in
      if proofRoot /= proof.vlNodeRoot
        then false
        else validate pElems (hashVLProofElem pElem)

    hashVLProofElem :: VLProofElem a -> VLMerkleRoot a
    hashVLProofElem (VLProofElem proof) =
      case proof.nodeSide of
        L -> mkVLRootHash proof.vlNodeRoot proof.siblingRoot
        R -> mkVLRootHash proof.siblingRoot proof.vlNodeRoot


testVLMerkleProofN :: Int -> Int -> Boolean
testVLMerkleProofN size leaf =
  let
      input = List.range 1 size
      mtree = mkVLMerkleTree $ map show input
      randLeaf = mkLeafRootHash $ show leaf
      proof = merkleProof mtree randLeaf
  in
  validateVLMerkleProof proof (mtRoot mtree) randLeaf
