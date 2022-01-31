module Amaroo.WP.VLMT.Crypto where

import Prel

import Data.Int (decimal, toStringAs)
import Effect.Unsafe (unsafePerformEffect)
import Node.Buffer (freeze, thaw)
import Node.Buffer.Immutable as Buffer
import Node.Crypto.Hash as NCHash
import Node.Encoding (Encoding(..))

data Hash = SHA256 | FastHash

class Eq h <= Hashable h where
  hash :: Hash -> h -> Buffer.ImmutableBuffer

instance hashBuf :: Hashable Buffer.ImmutableBuffer where
  hash hType inputBuf = unsafePerformEffect $ do
      buf <- thaw inputBuf
      h <- NCHash.update buf =<< NCHash.createHash (hStr hType)
      freeze =<< NCHash.digest h
    where
      hStr SHA256 = "sha256"
      hStr FastHash = "ripemd"

instance hashStr :: Hashable String where
  hash hType s = hash hType (Buffer.fromString s UTF8)

instance hashInt :: Hashable Int where
  hash ht i = hash ht $ toStringAs decimal i
-- hashBuf :: Hash -> Buffer.ImmutableBuffer -> Buffer.ImmutableBuffer


-- hash ∷ (Hashable h) => Hash → h → Buffer.ImmutableBuffer
-- hash hType hashable = hashBuf hType (Buffer.fromString inputStr UTF8)

toString = Buffer.toString UTF8
