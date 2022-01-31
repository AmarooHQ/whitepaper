-- | Original code from: https://github.com/alpacaaa/purescript-merkle-tree/blob/master/src/Crypto/Hash/MerkleTree.purs
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
  , VLMerkleProof(..)
  , VLMerkleRoot(..)
  , VLMerkleTree(..)
  , VLProofElem(..)
  , VLProofList(..)
  , VLMerkleNode
  , merkleProof
  , mkLeafRootHash
  , mkVLMerkleTree
  , mkVLRootHash
  , mtHash
  , mtHeight
  , mtRoot
  , mtSize
  , testVLMerkleProofN
  , validateVLMerkleProof
  , vlEmptyHash
  , vlNodeRoot
  )
  where


import Prel

import Amaroo.WP.VLMT.Crypto (class Hashable)
import Amaroo.WP.VLMT.Crypto as Crypto
import Data.Foldable (class Foldable, sum)
import Data.Foldable as Foldable
import Data.Generic.Rep (class Generic)
import Data.Int (even)
import Data.Int.Bits ((.&.), shl, shr)
import Data.List (List(..), zip, (:), intercalate)
import Data.List as List
import Data.List as List
import Data.Show.Generic (genericShow)
import Data.Tuple (Tuple(..), snd)
import Data.Tuple as Tuple
import Debug as Debug
import Prelude (Ordering(..))


hash = Crypto.hash Crypto.SHA256 >>> Crypto.toString


-- class VLMTDefault k where
--   vlDefault :: k

-- instance vldInt :: VLMTDefault Int where
--   vlDefault = 0


-- instance vldNumber :: VLMTDefault Number where
--   vlDefault = 0.0


type VLMTConfig k v
  = {
      combine :: k -> k -> k
    , order :: Tuple k String -> Tuple k String -> Ordering
  }


intThenStrOrdering :: Tuple Int String -> Tuple Int String -> Ordering
intThenStrOrdering (Tuple l1 l2) (Tuple r1 r2) = case compare l1 r1 of
  EQ -> compare l2 r2
  ord -> ord

vlmtIntConfig :: VLMTConfig Int String
vlmtIntConfig = {
    combine: (+)
  , order: intThenStrOrdering
}


newtype VLMerkleRoot k v = VLMerkleRoot (Tuple k String)


derive instance eqVLMerkleRoot :: Eq k => Eq (VLMerkleRoot k v)
derive instance genericVLMerkleRoot :: Generic (VLMerkleRoot k v) _

instance showVLMerkleRoot :: Show k => Show (VLMerkleRoot k v) where
  -- show r = genericShow r
  show (VLMerkleRoot (Tuple k _)) = "(VLMRoot: " <> show k <> ")"

data VLMerkleTree k v
  = VLMerkleEmpty k
  | VLMerkleTree Int (VLMerkleNode k v)

data VLMerkleNode k v
  = VLMerkleBranch {
      mRoot  :: VLMerkleRoot k v
    , mLeft  :: VLMerkleNode k v
    , mRight :: VLMerkleNode k v
  }
  | VLMerkleLeaf {
      mRoot :: VLMerkleRoot k v
    , mVal  :: Tuple k v
  }

instance foldableVLMerkleTree :: Foldable (VLMerkleTree k) where
  foldr f a b = Foldable.foldrDefault f a b
  foldl f a b = Foldable.foldlDefault f a b
  foldMap _ (VLMerkleEmpty _)  = mempty
  foldMap f (VLMerkleTree _ n) = Foldable.foldMap f n

instance foldableVLMerkleNode :: Foldable (VLMerkleNode k) where
  foldr f a b = Foldable.foldrDefault f a b
  foldl f a b = Foldable.foldlDefault f a b
  foldMap f x = case x of
    VLMerkleLeaf   { mVal }            -> f $ snd mVal
    VLMerkleBranch { mLeft, mRight }   ->
      Foldable.foldMap f mLeft `append` Foldable.foldMap f mRight



-- | Returns root of merkle tree.
mtRoot :: forall k v. VLMerkleTree k v -> VLMerkleRoot k v
mtRoot (VLMerkleEmpty k)     = vlEmptyHash k
mtRoot (VLMerkleTree _ node) = vlNodeRoot node


-- | Returns root of merkle tree root hashed.

mtHash :: forall k v. VLMerkleTree k v -> String
mtHash (VLMerkleEmpty k)  = vlMerkleHash $ Tuple k ""
mtHash (VLMerkleTree _ x) = vlMerkleHash value
  where
    (VLMerkleRoot value) = vlNodeRoot x

mtSize :: forall k v. VLMerkleTree k v -> Int
mtSize (VLMerkleEmpty _)  = 0
mtSize (VLMerkleTree s _) = s

vlEmptyHash :: forall k v. k -> VLMerkleRoot k v
vlEmptyHash k = VLMerkleRoot $ Tuple k $ vlMerkleHash $ Tuple k ""


vlMerkleHash :: Tuple _ String -> String
vlMerkleHash (Tuple _ value) = hash value


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

mkLeaf :: forall k. (Hashable k) => k -> String -> VLMerkleNode k String
mkLeaf k v =
  VLMerkleLeaf
    { mRoot: mkLeafRootHash $ Tuple k v
    , mVal : Tuple k v
    }

mkLeafRootHash :: forall k. (Hashable k) => (Tuple k String) -> VLMerkleRoot k String
mkLeafRootHash (Tuple k v) = VLMerkleRoot $ Tuple k $ vlMerkleHash (Tuple k $ "0" <> hash k <> v)

vlNodeRoot :: forall k v. VLMerkleNode k v -> VLMerkleRoot k v
vlNodeRoot (VLMerkleBranch { mRoot }) = mRoot
vlNodeRoot (VLMerkleLeaf { mRoot })   = mRoot

mkBranch :: forall k v. (Crypto.Hashable k) => VLMTConfig k v -> VLMerkleNode k v -> VLMerkleNode k v -> VLMerkleNode k v
mkBranch combine a b =
  VLMerkleBranch
    { mLeft : a
    , mRight: b
    , mRoot : mkVLRootHash combine (vlNodeRoot a) (vlNodeRoot b)
    }

mkVLRootHash :: forall k v. (Crypto.Hashable k) => VLMTConfig k v -> VLMerkleRoot k v -> VLMerkleRoot k v -> VLMerkleRoot k v
mkVLRootHash config (VLMerkleRoot (Tuple lk l)) (VLMerkleRoot (Tuple rk r)) =
    VLMerkleRoot $ Tuple k $ vlMerkleHash $ Tuple k ("1" <> hash lk <> l <> hash rk <> r)
  where
    k = config.combine lk rk

{-|
  Smart constructor for 'VLMerkleTree'.
  Note: we need to ensure we construct the VLMT so that the order constraint is always met.
  Practically, that means we want `LT == compare left right` *always*.
  This is trivial for a balanced tree (i.e., with size == a power of 2).
  For other sizes, we want to divide the list in two:
    - the right side with larger aux values
    - the left side with smaller aux values
    - if the size is odd, then the right side should have 1 more element than the left
|-}
mkVLMerkleTree :: forall k. (Hashable k) => VLMTConfig k String -> k -> List (Tuple k String) -> VLMerkleTree k String
mkVLMerkleTree _ defaultK Nil = VLMerkleEmpty defaultK
mkVLMerkleTree config _ ls'   = VLMerkleTree lsLen (go lsLen ls)
  where
    ls = List.sortBy config.order ls'
    lsLen              = List.length ls
    go _ (Tuple k' x : Nil) = mkLeaf k' x
    go _ (Tuple k1 x1 : Tuple k2 x2 : Nil) = mkBranch config (mkLeaf k1 x1) (mkLeaf k2 x2)
    go len xs = mkBranch config (go i l) (go (len - i) r)
      where
        i = len / 2  -- length of left side; **note**, assumes integer division
        {l, r} = { l: List.take i xs, r: List.drop i xs }

-------------------------------------------------------------------------------
-- Merkle Proofs
-------------------------------------------------------------------------------

type VLProofList k v = List (VLProofElem k v)

newtype VLMerkleProof k v = VLMerkleProof (VLProofList k v)

instance showVLMTProof :: Show k => Show (VLMerkleProof k v) where
  show (VLMerkleProof xs) = intercalate "\n\t" $ "Proof:" : map show xs

data VLProofElem k v = VLProofElem
  { vlNodeRoot    :: VLMerkleRoot k v
  , siblingRoot :: VLMerkleRoot k v
  , nodeSide    :: Side
  }

instance showVLProofElem :: Show k => Show (VLProofElem k v) where
  show (VLProofElem {vlNodeRoot, siblingRoot, nodeSide}) =
      show nodeSide <> " | " <> show l <> " | " <> show r
    where
      Tuple l r = case nodeSide of
        L -> Tuple vlNodeRoot siblingRoot
        R -> Tuple siblingRoot vlNodeRoot

data Side = L | R

derive instance eqSide :: Eq Side

instance showSide :: Show Side where
  show L = "L"
  show R = "R"

-- | Construct a merkle tree proof of inclusion
-- Walks the entire tree recursively, building a list of "proof elements"
-- that are comprised of the current node's root and it's sibling's root,
-- and whether it is the left or right sibling (this is necessary to determine
-- the order in which to hash each proof element root and it's sibling root).
-- The list is ordered such that the for each element, the next element in
-- the list is the proof element corresponding to the node's parent node.
merkleProof :: forall k v. (Eq k) => VLMerkleTree k v -> VLMerkleRoot k v -> VLMerkleProof k v
merkleProof (VLMerkleEmpty _) _ =
  VLMerkleProof Nil
merkleProof (VLMerkleTree _ rootNode) leafRoot =
  VLMerkleProof $ constructPath Nil rootNode
  where
    constructPath :: (VLProofList k v) -> VLMerkleNode k v -> (VLProofList k v)
    constructPath pElems (VLMerkleLeaf leaf)
      | leafRoot == leaf.mRoot = pElems
      | otherwise              = Nil
    constructPath pElems (VLMerkleBranch branch) = lPath <> rPath
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
validateVLMerkleProof :: forall k v. (Hashable k) => VLMTConfig k v -> VLMerkleProof k v ->  VLMerkleRoot k v -> VLMerkleRoot k v -> Boolean
validateVLMerkleProof config (VLMerkleProof proofElems) treeRoot leafRoot =
  validate proofElems leafRoot
  where
    validate :: VLProofList k v -> VLMerkleRoot k v -> Boolean
    validate Nil proofRoot = proofRoot == treeRoot
    validate (pElem : pElems) proofRoot =
      let
        (VLProofElem proof) = pElem
      in
      if proofRoot /= proof.vlNodeRoot || orderIsBad proof
        then false
        else validate pElems (hashVLProofElem pElem)

    getLR proof = case proof.nodeSide of
      L -> Tuple proof.vlNodeRoot proof.siblingRoot
      R -> Tuple proof.siblingRoot proof.vlNodeRoot

    orderIsBad proof = let
        Tuple (VLMerkleRoot ln) (VLMerkleRoot rn) = getLR proof
      in
      config.order ln rn /= LT

    hashVLProofElem :: VLProofElem k v -> VLMerkleRoot k v
    hashVLProofElem (VLProofElem proof) =
      case proof.nodeSide of
        L -> mkVLRootHash config proof.vlNodeRoot proof.siblingRoot
        R -> mkVLRootHash config proof.siblingRoot proof.vlNodeRoot


testVLMerkleProofN :: Int -> Int -> Boolean
testVLMerkleProofN size leaf =
  let
      input = List.range 1 size
      mtree = mkVLMerkleTree vlmtIntConfig 0 $ List.zip input $ map show input
      randLeaf = mkLeafRootHash $ Tuple leaf $ show leaf
      proof = merkleProof mtree randLeaf
      combinedK = case mtree of
        (VLMerkleTree _ (VLMerkleBranch {mRoot: VLMerkleRoot (Tuple k _)})) -> k
        _ -> 0
      root = mtRoot mtree
  in
  validateVLMerkleProof vlmtIntConfig proof (mtRoot mtree) randLeaf
  && combinedK == sum input
  && Debug.spy ("\n\nSize:" <> show size <> " | root: " <> show root <> " | leaf: " <> show randLeaf) true
  && Debug.spy (show proof) true
