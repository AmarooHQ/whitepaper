module Test.Amaroo.WP.Tables where

import Prel

import Amaroo.WP.Tables
import Data.Array (all, head, length, tail)
import Data.Array.Partial as AP
import Data.Int (decimal, toStringAs)
import Data.Traversable (and, sequence, sequence_)
import Data.Tuple (Tuple(..))
import Effect.Class.Console as C
import Main (TableName(..), allTables)
import Partial.Unsafe (unsafePartial)
import Test.Amaroo.WP.Calcs (shouldBeWithin)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)

mkUtTestName s i = "$\\UT{" <> toStringAs decimal i <> "+\\text{" <> s <> "}}$"
mkUtTestNameStd i = "$\\UT{" <> toStringAs decimal i <> "}$"

_head = unsafePartial AP.head
_tail = unsafePartial AP.tail

allTheSame :: forall a. (Eq a) => Array a -> Boolean
allTheSame xs = and $ map ((==) $ _head xs) (_tail xs)

utNamesSpec :: Spec Unit
utNamesSpec = describe "tables" do
    it "ut names" do
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

    it "1m compare len" do
      length utVsOther1M `shouldEqual` length ut1MCompareKs

    it "1m compare has tps == 1m as much as possible" do
      _ <- sequence $ do
        {net, p} <- utVsOther1M
        let cs = netToChainStats net p
        pure $ do
          -- C.log $ show net
          shouldBeWithin 10_000.0 (netToTps net cs) 1_000_000.0
          shouldSatisfy (netToTps net cs) (_ >= 999_999.0)
      pure unit

    it "all tables are square (all rows same len)" do
      sequence_ $ do
        (Tuple (TableName tn) table) <- allTables
        let ls = length <$> table
        pure $ shouldSatisfy ls allTheSame
