module Test.Amaroo.WP.Tables where

import Amaroo.WP.Tables
import Amaroo.WP.Tables.Types
import Prel

import Amaroo.WP.Calcs (mkNestedPs, mkSimplePs, tradChainCalcEth2, tradChainCalcPolkadot, utCalcHOPoRs, utChainCalc)
import Data.Array (length)
import Data.Array as A
import Data.Array.Partial as AP
import Data.Int (decimal, toNumber, toStringAs)
import Data.String as S
import Data.Traversable (and, sequence, sequence_)
import Data.Tuple (Tuple(..))
import Main (allTables, lpTables)
import Partial.Unsafe (unsafePartial)
import Test.Amaroo.WP.Calcs (shouldBeCloseTo, shouldBeWithin)
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

    -- -- uncomment for testing
    -- let ccs = do
    --       Tuple i k <- ((\i -> Tuple i $ 113_500.0 + i * 50.0) <<< toNumber) <$> A.range 0 20
    --       -- pure $ tradChainCalcPolkadot $ mkSimplePs k {bf: _POLKADOT_BF, bh: _POLKADOT_BH} 250.0
    --       -- pure $ tradChainCalcEth2 $ mkNestedPs k {bf: _ETH2_BF, bh: _ETH2_BH} {bf: _ETH2_BF, bh: _ETH2_DH} 250.0
    --       pure $ Tuple i $ utCalcHOPoRs (mkSimplePs k _UT_HF 250.0) {hashTruncation: true}
    -- it "test find 1m tps" do
    --   (A.intercalate "\n" $ ccs <#> \(Tuple i cc) -> show i <> ": " <> show cc.d1.tps) `shouldEqual` ""

    describe "1m compare has tps == 1m as much as possible" do
      _ <- sequence $ do
        -- note: filter out HOPoRs1 here b/c there is no k that produces 1m TPS
        {net, p} <- A.filter (\{net} -> net /= UT (HOPoRs 1)) utVsOther1MAll
        let cs = netToChainStats net p
        pure $ do
          -- C.log $ show net
          it (show net <> "(current: " <> show (netToTps net cs) <> ")") do
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

    it "should have sensible 1m tps params" do
      let btc = _head utVsOther1M
          ada = _head $ A.drop 1 utVsOther1M
          btcP = mkSimplePs _BTC_1M_K {bh: 80.0, bf: 1.0/600.0} 250.0
          adaP = mkSimplePs _BTC_1M_K {bh: 1070.0, bf: 1.0/20.0} 250.0
          adaUt2Equiv = utChainCalc adaP {headerOmission: false, explicitPoRs: false, hashTruncation: true}
          bf = 1.0 / 20.0
          bh = 1070.0
          k = _BTC_1M_K
          n1 = k / 2.0 / bh / bf
          t1 = n1 * k / 2.0
          n2 = t1 / bh / bf
          t2 = n2 * k
          adaUt2EquivTps = t2 / 250.0
      {net: Bitcoin, p: btcP} `shouldEqual` btc
      {net: Cardano, p: adaP} `shouldEqual` ada
      adaUt2EquivTps `shouldBeCloseTo` adaUt2Equiv.d2.tps
