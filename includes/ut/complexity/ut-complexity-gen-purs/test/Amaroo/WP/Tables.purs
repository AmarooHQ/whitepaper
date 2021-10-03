module Test.Amaroo.WP.Tables where

import Amaroo.WP.Tables
import Amaroo.WP.Tables.Types
import Prel

import Amaroo.WP.Calcs (mkNestedPs, mkSimplePs, tradChainCalcEth2, tradChainCalcPolkadot)
import Data.Array (length)
import Data.Array as A
import Data.Array.Partial as AP
import Data.Int (decimal, toNumber, toStringAs)
import Data.String as S
import Data.Traversable (and, sequence, sequence_)
import Main (allTables, lpTables)
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
    it "spaces (md)" do
      mkSpacer 1 `shouldEqual` "---"
      mkSpacer 2 `shouldEqual` "---"
      mkSpacer 3 `shouldEqual` "---"
      mkSpacer 4 `shouldEqual` "----"
      mkSpacer 5 `shouldEqual` "-----"
      mkSpacer 6 `shouldEqual` "------"
    it "ut names" do
      shouldEqual (utNames [PoRs 1, PoRTs 2, Std 3, T 1, HO 2, HOT 3, Aleph (Std 2), Aleph (HOT 1)]) $
        [ mkUtTestName "PoRs" 1
        , mkUtTestName "PoRTs" 2
        , mkUtTestName "OP" 3
        , mkUtTestName "OPT" 1
        , mkUtTestName "HO" 2
        , mkUtTestName "HOT" 3
        , "$\\UTinf{2+\\text{OP}}$"
        , "$\\UTinf{1+\\text{HOT}}$"
        ]

    -- it "1m compare len" do
    --   -- note: because we filter the output of (utVsOther 1.0), it's inconvenient to test length (utVsOther 1.0) == length ut1mcompareks
    --   length utVsOther1M `shouldEqual` length ut1MCompareKs

    it "1m compare has tps == 1m as much as possible" do
      -- let ccs = do
      --       k <- ((\i -> 244_200.0 + i * 100.0) <<< toNumber) <$> A.range 0 20
      --       -- pure $ tradChainCalcPolkadot $ mkSimplePs k {bf: _POLKADOT_BF, bh: _POLKADOT_BH} 250.0
      --       pure $ tradChainCalcEth2 $ mkNestedPs k {bf: _ETH2_BF, bh: _ETH2_BH} {bf: _ETH2_BF, bh: _ETH2_DH} 250.0
      -- (ccs <#> \cc -> cc.d2.tps) `shouldEqual` []
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
        (TD _ (Table hdrs aligns table) _) <- allTables <> lpTables
        let ls = length <$> ([hdrs, aligns.md] <> table)
        pure $ do
          S.length aligns.texTabular `shouldEqual` (length aligns.md)
          shouldSatisfy ls allTheSame
