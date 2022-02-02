module Amaroo.WP.VecCom.SimpleVectorCommit
  ( genPolyP
  , genRandInts
  , lagrangePolynomial
  , main
  , max_v
  , min_v
  , n
  )
  where

import Prel

import Data.Foldable (product, sum)
import Data.Int (toNumber)
import Data.List (List)
import Data.List as List
import Data.List.Lazy as LL
import Data.Traversable (sequence)
import Effect.Class.Console (log)
import Effect.Random (randomInt)

{-|

We want to replicate the idea of a vector commitment via a polynomial commitment.
This is just a test impl w/ boring regular numbers (so not cryptographically secure)

https://dankradfeist.de/ethereum/2020/06/16/kate-polynomial-commitments.html

Note: we don't care about the operations (like division) that are possible for numbers but not for EC points.
e.g., secret key p with generator G corresponds to public key P = pG. P and G are public, but p is safe b/c P/G is not feasible.

## construct polynomial

the data we want to commit to is a list of n values (these might normally be leaves of a merkle tree).

vs = [v_0, v_1, ..., v_{n-1}]

make a list of points: (i, v_i)
vs' = [(0, v_0), (1, v_1), ..., (n-1, v_{n-1})]

these points will define a polynomial P (of degree n) that we'll use.

P(x) = <<lagrange interpolation>>

we then need the output of P(s) for some unknown value (s) -- this is effectively the commitment.
note: w/ EC points the commitment is C = P(s)G

C = P(s)

---

we can prove multiple things using a special polynomial (I) that shares some points with P.
the points that are shared correspond to the points that we want to prove are in vs'.

zs = the elements of vs' that we want to prove
k = len(zs)

crucially: P(x) - I(x) = 0 at all points we want to prove (and these are unique roots of P - I)

since this polynomial (P - I) is zero at all those points, we can divide this polynomial like so:

```
                 P(x) - I(x)
Q(x) = ----------------------------------
       (x - z_0)(x - z_1)...(x - z_{k-1})
```

the proof is:

pi = Q(s)

-}

n = 10

max_v = 100_000
min_v = -1 * max_v

genRandInts = sequence $ List.fromFoldable $ LL.replicate n $ randomInt min_v max_v

{-|
The L_{n,j}(x) bit from lagrange interpolation.
Note: if our x coordinates weren't 0..n we'd need to
-}
lagrangePolynomial :: Int -> Int -> Int -> Number
lagrangePolynomial n_ j x =
  product $ do
    k <- List.filter (_ /= j) $ List.range 0 (n_ - 1)
    pure $ toNumber (x - k) / toNumber (j - k)

genPolyP :: List Int -> Int -> Number
genPolyP vs x = sum $
  flip List.mapWithIndex vs $ \i v -> toNumber v * lagrangePolynomial n i x

genZeroPoly :: List Int -> Int -> Number
genZeroPoly zs x = toNumber $ product $ (x - _) <$> zs

main = do
  vs <- genRandInts
  s <- randomInt min_v max_v
  let
      -- how many elements we'll prove
      m = n / 2
      -- we set vsToProve to the first however many vs so that the indexes match (which is part of this working as a vector commitment).
      -- if we didn't keep the order the same, we'd need to track the index of each v that we want to prove.
      vsToProve = List.take m vs
      -- polynomial over all elements
      polyP = genPolyP vs
      -- commitment
      commitment = polyP s
      -- polynomial over only the elements we want to prove
      polyI = genPolyP vsToProve
      polyZ = genZeroPoly $ List.range 0 (m - 1)
      polyQ x = (polyP x - polyI x) / polyZ x

      proof = polyQ s
      verifyProof = (commitment - polyI s) / polyZ s - proof

      badPolyZ = genZeroPoly $ List.range 1 (m-2)
      badPolyI = genPolyP vsToProve
      badVerify = (commitment - badPolyI s) / badPolyZ s

  log $ show badVerify
  log $ show proof
  log $ show $ badVerify - proof
  log $ show verifyProof
