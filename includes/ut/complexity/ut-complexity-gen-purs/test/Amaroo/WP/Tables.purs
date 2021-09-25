module Test.Amaroo.WP.Tables where

import Prel

import Amaroo.WP.Tables
import Data.Int (decimal, toStringAs)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

mkUtTestName s i = "$\\UT{" <> toStringAs decimal i <> "+\\text{" <> s <> "}}$"
mkUtTestNameStd i = "$\\UT{" <> toStringAs decimal i <> "}$"

utNamesSpec :: Spec Unit
utNamesSpec = describe "ut names" do
    it "is correct" do
      shouldEqual (utNames [PoRs 1, PoRTs 2, Std 3, T 1, HO 2, HOT 3, Aleph (Std 2), Aleph (HOT 1)]) $
        [ mkUtTestName "PoRs" 1
        , mkUtTestName "PoRTs" 2
        , mkUtTestNameStd 3
        , mkUtTestName "T" 1
        , mkUtTestName "HO" 2
        , mkUtTestName "HOT" 3
        , "$\\UTinf{2}$"
        , "$\\UTinf{1+\\text{HOT}}$"
        ]
