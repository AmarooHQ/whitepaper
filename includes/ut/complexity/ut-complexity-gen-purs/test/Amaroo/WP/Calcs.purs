module Test.Amaroo.WP.Calcs where

import Prel

import Amaroo.WP.Calcs
import Control.Monad.Trans.Class (lift)
import Data.Array (range)
import Data.Array (zip)
import Data.Int (floor, round, toNumber)
import Data.Int as I
import Data.List.NonEmpty as NEL
import Data.Maybe (fromJust)
import Data.Ord (abs)
import Data.Traversable (sequence, sequence_)
import Data.Tuple (fst, snd)
import Effect.Class (liftEffect)
import Effect.Console as C
import Math (exp, log, pow)
import Partial.Unsafe (unsafePartial)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual, shouldNotEqual, shouldSatisfy)
import Undefined (undefined)


basicTestPs :: _
basicTestPs = mkSimplePs 1000.0 {bf: 1.0/10.0, bh: 100.0} 500.0

genParams :: _ Params
genParams =
  [ basicTestPs
  , mkSimplePs 3000.0 {bf: 1.0/15.0, bh: 84.0} 250.0
  ]

basicSample = genSample basicTestPs

genSample :: _
genSample = runChainCalcFor

expectTrue x = x `shouldEqual` true

shouldBeWithin d x y = not ((x - y) |> abs |> (-) d |> (<) 0.0) |> when $
  fail $ show x <> " != " <> show y <> " (must be within " <> show d <> ")"

shouldBeCloseTo = shouldBeWithin 0.00001

dNShouldEqual actual@{n, t, tps} expected = {n, t, tps} `shouldEqual` expected

tradSpec :: Spec Unit
tradSpec = describe "trad chains" do
      let pss = genParams
          samples = genSample <$> pss
      it "should calc trad.d1 correctly" do
        basicSample.trad.d1 `dNShouldEqual` {n: 1.0, t: 1000.0, tps: 2.0}
      it "should calc trad.d2 correctly" do
        basicSample.trad.d2 `dNShouldEqual` {n: 100.0, t: 100000.0, tps: 200.0}
      it "should calc trad.d3 correctly" do
        basicSample.trad.d3 `dNShouldEqual` {n: 10000.0, t: 10000000.0, tps: 20000.0}
      it "should calc trad other stuff" do
        basicSample.trad.confRate `shouldEqual` 0.1
        basicSample.trad.deltaBigS `shouldEqual` 1000.0
        basicSample.trad.deltaSmallS `shouldEqual` 1000.0
        basicSample.trad.tts `shouldBeCloseTo` 0.18262499999999998

auxStatsSpec :: Spec Unit
auxStatsSpec = describe "Aux Stats" do
    let utvs = basicSample.ut
        trad = basicSample.trad
        stdAux = auxStats utvs.std
        tradAux = auxStats trad
    it "tps/n1" do
      stdAux.tpsPerBaseChain.d1 `shouldEqual` (0.5 * tradAux.tpsPerBaseChain.d1)
      stdAux.tpsPerBaseChain.d2 `shouldEqual` (0.5 * tradAux.tpsPerBaseChain.d2)
    it "n1PerK" do
      stdAux.n1PerK `shouldEqual` (1.0 / stdAux.bfbh / 2.0)
      tradAux.n1PerK `shouldEqual` 0.001
    describe "scaling factors" do
      it "noNesting" do
        stdAux.scalingFactors.noNesting `shouldEqual` 1.0
        tradAux.scalingFactors.noNesting `shouldEqual` 1.0
      it "nesting" do
        stdAux.scalingFactors.nesting `shouldEqual` (utvs.std.d2.n / utvs.std.d1.n * 2.0)
        tradAux.scalingFactors.nesting `shouldEqual` (trad.d2.n / trad.d1.n)

utSpec :: Spec Unit
utSpec = describe "ut" do
    let utvs = basicSample.ut

    describe "ut.std" do
      it "d1" do
        basicSample.ut.std.d1 `dNShouldEqual` {n: 50.0, t: 500.0 * 50.0, tps: 50.0}
      it "d2" do
        basicSample.ut.std.d2 `dNShouldEqual` {n: 50.0 `pow` 2.0, t: 2500000.0, tps: 5000.0}
      it "d3" do
        basicSample.ut.std.d3 `dNShouldEqual` {n: 2500.0 * 100.0, t: 250000000.0, tps: 500000.0}
      it "confRate" do
        basicSample.ut.std.confRate `shouldEqual` 5.0
      it "dbs" do
        basicSample.ut.std.deltaBigS `shouldEqual` (1000.0 * 50.0)

      let dss = (1000.0 + 0.1 * 50.0 * (100.0 + 32.0 * log2c 50.0))  -- k + bf * N1 proofs * (bh + proof_size)
          tts = 5.0 * 365.25 * dss / 10_000_000.0
      it "dss" do
        basicSample.ut.std.deltaSmallS `shouldEqual` dss
      it "tts" do
        basicSample.ut.std.tts `shouldBeCloseTo` tts

    describe "ut.ho" do
      let ut = basicSample.ut.ho
          bf = 0.1
          bh = 100.0
          n1 = 500.0 / 32.0 / bf
          t1 = 500.0 * n1
          txSize = 500.0
          n2 = t1 / bf / bh
          t2 = 1_000_000_000.0 / 4.0 / bf / bf / 32.0 / bh
          t3 = (pow 1_000.0 4.0) / 4.0 / (pow (bf * bh) 2.0) / 32.0 / bf
          n3 = t3 / 1000.0
      it "d1" do
        ut.d1 `dNShouldEqual` {n: n1, t: t1, tps: t1 / txSize}
        round ut.d1.tps `shouldEqual` 156
        round ut.d1.n `shouldEqual` 156
        round (auxStats ut).scalingFactors.nesting `shouldEqual` (round $ ut.d2.tps / ut.d1.tps)
      it "d2" do
        -- constants from comparison-gen.py
        floor ut.d2.n `shouldEqual` 7_812
        round (t2 / txSize) `shouldEqual` 15_625
        round t2 `shouldEqual` (15_625 * 500)
        round ut.d2.tps `shouldEqual` 15_625
        ut.d2 `dNShouldEqual` {n: n2, t: t1 * 100.0, tps: t1 * 100.0 / txSize}
      it "d3" do
        ut.d3 `dNShouldEqual` {n: n3, t: t3, tps: t3 / 500.0}
      -- it "other" do
      --   ut.tts `shouldEqual`

    describe "UT variant effective header size" do
      let getHF1 v = v.d1.p.hf
          getHF2 v = v.d2.p.hf
          getHF3 v = v.d3.p.hf
          getK1 v = v.d1.p.k
          getK2 v = v.d2.p.k
          getK3 v = v.d3.p.k
          tDiscount bh = bh - ((bh - 80.0) / (112.0 - 80.0) + 1.0) * 16.0
      it "header omission should use hashSize" do
        (getHF1 utvs.ho).bh `shouldEqual` 32.0
        (getHF2 utvs.ho).bh `shouldEqual` 100.0
        (getHF3 utvs.ho).bh `shouldEqual` 100.0
        (getHF1 utvs.hot).bh `shouldEqual` 16.0
        (getHF2 utvs.hot).bh `shouldEqual` tDiscount 100.0
        (getHF3 utvs.hot).bh `shouldEqual` 100.0  -- at nesting-l-3, truncation is not something we can realiably predict
      it "truncation should shorten headers and PoRs" do
        utvs.t.porBytes `shouldSatisfy` ((>) utvs.std.porBytes)
        (getHF1 utvs.t).bh `shouldEqual` tDiscount 100.0
        (getHF2 utvs.t).bh `shouldEqual` tDiscount 100.0
        (getHF3 utvs.t).bh `shouldEqual` 100.0
        (getHF1 utvs.hot).bh `shouldEqual` 16.0
        (getHF2 utvs.hot).bh `shouldEqual` tDiscount 100.0
        (getHF3 utvs.hot).bh `shouldEqual` 100.0  -- at nesting-l-3, truncation is not something we can realiably predict
      it "+PoRs variants shouldn't have kTx == kB" do
        utvs.pors.kTx `shouldNotEqual` utvs.pors.kB
        utvs.ports.kTx `shouldNotEqual` utvs.ports.kB
      it "multi-tier headers work" do
        let ps = { hfs: NEL.fromFoldable [{bf: 0.11, bh: 10.0}, {bf: 0.22, bh: 20.0}] |> unsafePartial fromJust
                 , ks: NEL.cons 1111.0 $ NEL.singleton 2222.0
                 , txSize: 500.0
                 }
            trad = tradChainCalc ps
            ut = allUtChainCalcs ps
        -- liftEffect $ C.log $ "t:" <> show trad
            checkStats stats = do
              getK1 stats `shouldEqual` 1111.0
              getK2 stats `shouldEqual` 2222.0
              getK3 stats `shouldEqual` 2222.0
              (getHF1 stats).bh `shouldEqual` 10.0
              (getHF2 stats).bh `shouldEqual` 20.0
              (getHF3 stats).bh `shouldEqual` 20.0
        checkStats trad
        checkStats ut.std
        (getHF1 ut.hot).bh `shouldEqual` 16.0
        (getHF2 ut.hot).bh `shouldEqual` 4.0
        (getHF3 ut.hot).bh `shouldEqual` 20.0

    describe "ut comparison test vecs" do
      -- note that k=1000
      let tpss = [50, 156, 312]
          n1s = [50, 156, 312]
          dbs = [50000, 156250, 312500]
          confRates = [5.00, 15.625, 31.25]
          -- TTS isn't an exact match, but p close. Definitely *looks* mostly right WRT numbers coming out.
          -- ttss = [0.44, 0.94, 1.03]  -- from python gen
          ttss = [0.45, 1.0, 1.004]  -- these are the new TTS figures; keeping them here to make sure we know if they change
          dss = [2460, 5500, 5500]  -- these are the new TTS figures; keeping them here to make sure we know if they change
          s = basicSample.ut
          -- exclude +T variant b/c py script doesn't get it
          variants = [s.std, s.ho, s.hot]
      it "TPS" do
        ((\v -> floor v.d1.tps) <$> variants) `shouldEqual` tpss
      it "N1" do
        ((\v -> floor v.d1.n) <$> variants) `shouldEqual` n1s
      it "dS" do
        ((\v -> floor v.deltaBigS) <$> variants) `shouldEqual` dbs
      it "ds" do
        ((\v -> floor v.deltaSmallS) <$> variants) `shouldEqual` dss
      it "Conf Rates" $ do
        sequence_ $ (\t -> shouldBeWithin 0.005 (fst t) (snd t)) <$> zip ((\v -> v.confRate) <$> variants) confRates
      it "TTS" $ do
        sequence_ $ (\t -> shouldBeWithin 0.005 (fst t) (snd t)) <$> zip ((\v -> v.tts) <$> variants) ttss





    -- describe "+PoRs find max" do
    --   findMaxPoRsN1 (mkSimplePs 3000.0 {bf:0.06666, bh:84.0} 68.0) 16.0

    -- describe "easy testing" do
    --   it "sandbox" do
    --     liftEffect $ C.log $ show $
    --       -- utvStripP $ allUtChainCalcs {
    --       --   hfs: NEL.singleton {bf: 1.0/15.0, bh: 84.0}
    --       --   , ks: NEL.singleton 3000.0
    --       --   , txSize: 250.0
    --       --   }
    --       range 1 250 <#> I.toNumber <#> (\n1 -> utPorsT1 n1 3000.0 0.06666 68.0 16.0)
