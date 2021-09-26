module Test.Amaroo.WP.Formatter where

import Amaroo.WP.Formatter
import Amaroo.WP.Tables
import Prel

import Data.Int (decimal)
import Data.Int as I
import Data.Maybe (Maybe(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)


testFSN m s = m <> "\\times 10^{" <> s <> "}"

testFNF n d = "\\nicefrac{" <> I.toStringAs decimal n <> "}{" <> d <> "}"

testFdPlain = fdDefaults {mp = Nothing, commas = false, pOnlySi = false, wSI = false}

fmtSpec :: Spec Unit
fmtSpec = describe "formatting" do
    it "commas" do
      fmtCommas 0.0 `shouldEqual` "0"
      fmtCommas 10.0 `shouldEqual` "10"
      fmtCommas 100.0 `shouldEqual` "100"
      fmtCommas 1000.0 `shouldEqual` "1,000"
      fmtCommas 10000.0 `shouldEqual` "10,000"
      fmtCommas 100000.0 `shouldEqual` "100,000"
      fmtCommas 1000000.0 `shouldEqual` "1,000,000"
      fmtCommas 10000000.0 `shouldEqual` "10,000,000"
      fmtCommas 100000000.0 `shouldEqual` "100,000,000"
      fmtCommas 100000000.83746 `shouldEqual` "100,000,000"
      fmtCommas 133300000.183746 `shouldEqual` "133,300,000"
      fmtCommasP 2 133300000.183746 `shouldEqual` "133,300,000.18"
      fmtCommasP 2 133300000.299746 `shouldEqual` "133,300,000.30"

    it "sci notation" do
      fmtSciNot 1 0.0 `shouldEqual` testFSN "0.0" "0"
      fmtSciNot 1 1.0 `shouldEqual` testFSN "1.0" "0"
      fmtSciNot 1 10.0 `shouldEqual` testFSN "1.0" "1"
      fmtSciNot 1 13.0 `shouldEqual` testFSN "1.3" "1"
      fmtSciNot 1 73.0 `shouldEqual` testFSN "7.3" "1"
      fmtSciNot 2 13_331_337.0 `shouldEqual` "1.33\\times 10^{7}"
      fmtSciNot 2 0.000_000_13337 `shouldEqual` "1.33\\times 10^{-7}"

    it "fracts" do
      fmtFract (1.0 / 15.0) `shouldEqual` "\\nicefrac{1}{15}"
      fmtFract (1.0 / 15.0) `shouldEqual` testFNF 1 "15"
      fmtFract (1.0 / 60.0) `shouldEqual` testFNF 1 "60"
      fmtFract (2.0 / 13.0) `shouldEqual` testFNF 1 "6.5"
      fmtFract (1.0 / 7.5) `shouldEqual` testFNF 1 "7.5"

    it "dynamic" do
      fmtDyn testFdPlain 2345.6789 `shouldEqual` "2345.68"
      fmtDyn fdStd 2345.6789 `shouldEqual` "2,345.7"
      fmtDyn fdStd 23_456_789.11 `shouldEqual` (wrap "$" $ testFSN "2.3" "7")
      fmtDyn testFdPlain 23_456_789.11 `shouldEqual` testFSN "2.35" "7"
      fmtDyn testFdPlain 1_000_000.0 `shouldEqual` testFSN "1.00" "6"
      fmtDyn testFdPlain 999_999.999 `shouldEqual` testFSN "1.00" "6"
      fmtDyn testFdPlain 0.9 `shouldEqual` "0.90"
      fmtDyn testFdPlain 0.1 `shouldEqual` testFSN "1.00" "-1"
