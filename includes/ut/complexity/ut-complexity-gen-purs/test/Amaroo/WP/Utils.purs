module Test.Amaroo.WP.Utils where

import Prel

import Amaroo.WP.Utils (lerp, prel, uniq)
import Data.Array (all, filter, length)
import Effect.Class.Console as C
import Math (abs, (%))
import Test.QuickCheck ((<?>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.QuickCheck (quickCheck)
import Undefined (undefined)


newtype LerpIn = LerpIn {f :: Number, t :: Number, pct :: Number}

-- instance lerpGen :: Gen LerpIn where
--   gen = undefined


checkLerp :: {f :: Number, t :: Number, pct :: Number} -> _
checkLerp i = (abs (pct - prel {f,t,v}) < 0.00000001 || f == t || pct < 0.0 || pct > 1.0) <?> "bad answer: " <> show v <> "input failed: " <> show {f,t,pct}
  where
    f = min i.f i.t
    t = max i.f i.t
    pct = i.pct % 2.0 - 0.5
    v = lerp {f,t,pct: pct}

checkUniq :: Array Int -> _
checkUniq xs_ = (flip all) xs $ \x -> length (filter (_ == x) xs) == 1
  where
    xs = uniq (xs_ <> xs_)

utilSpecs :: Spec Unit
utilSpecs = do
    describe "utils" do
      it "lerps" do
        lerp {f: 2.0, t: 4.0, pct: 0.5} `shouldEqual` 3.0
        lerp {f: 2.0, t: 4.0, pct: 0.75} `shouldEqual` 3.5
        lerp {f: 2.0, t: 4.0, pct: 0.25} `shouldEqual` 2.5
      it "prels" do
        prel {f: 2.0, t: 4.0, v: 400.0} `shouldEqual` 1.0
        prel {f: 2.0, t: 4.0, v: 4.0} `shouldEqual` 1.0
        prel {f: 2.0, t: 4.0, v: 3.5} `shouldEqual` 0.75
        prel {f: 2.0, t: 4.0, v: 3.0} `shouldEqual` 0.5
        prel {f: 2.0, t: 4.0, v: 2.5} `shouldEqual` 0.25
        prel {f: 2.0, t: 4.0, v: 2.0} `shouldEqual` 0.0
        prel {f: 2.0, t: 4.0, v: 1.0} `shouldEqual` 0.0
      it "lerps QC" do
        quickCheck checkLerp
      it "uniq QC" do
        uniq [1, 1, 1] `shouldEqual` [1]
        quickCheck checkUniq
