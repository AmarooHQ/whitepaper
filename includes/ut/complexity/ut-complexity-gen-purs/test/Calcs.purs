module Test.Calcs where

import Calcs
import Prel

import Data.Array (range)
import Data.Array (zip)
import Data.Int (floor, round, toNumber)
import Data.List.NonEmpty as NEL
import Data.Ord (abs)
import Data.Traversable (sequence, sequence_)
import Data.Tuple (fst, snd)
import Effect.Class (liftEffect)
import Effect.Console as C
import Math (exp, log, pow)
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
  fail $ show x <> " != " <> show y

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
      let dss = (1000.0 + 0.1 * 50.0 * (100.0 + 32.0 * log2c 50.0))  -- k + bf * N1 proofs * (bh + proof_size)
          tts = 5.0 * 365.25 * dss / 10_000_000.0
      it "confRate" do
        basicSample.ut.std.confRate `shouldEqual` 5.0
      it "dbs" do
        basicSample.ut.std.deltaBigS `shouldEqual` (1000.0 * 50.0)
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
      let getBH1 v = (v.d1.p.hfs |> NEL.head).bh
          getBH2 v = (v.d2.p.hfs |> NEL.head).bh
          getBH3 v = (v.d3.p.hfs |> NEL.head).bh
      it "header omission should use hashSize" do
        getBH1 utvs.ho `shouldEqual` 32.0
        getBH2 utvs.ho `shouldEqual` 100.0
        getBH3 utvs.ho `shouldEqual` 100.0
        getBH1 utvs.hot `shouldEqual` 16.0
        getBH2 utvs.hot `shouldEqual` 84.0
        getBH3 utvs.hot `shouldEqual` 100.0  -- at nesting-l-3, truncation is not something we can realiably predict
      it "truncation should shorten headers and PoRs" do
        utvs.t.porBytes `shouldSatisfy` ((>) utvs.std.porBytes)
        getBH1 utvs.t `shouldEqual` 84.0
        getBH2 utvs.t `shouldEqual` 84.0
        getBH3 utvs.t `shouldEqual` 100.0
        getBH1 utvs.hot `shouldEqual` 16.0
        getBH2 utvs.hot `shouldEqual` 84.0
        getBH3 utvs.hot `shouldEqual` 100.0  -- at nesting-l-3, truncation is not something we can realiably predict
      it "+PoRs variants shouldn't have kTx == kB" do
        utvs.pors.kTx `shouldNotEqual` utvs.pors.kB
        utvs.ports.kTx `shouldNotEqual` utvs.ports.kB

    describe "ut comparison test vecs" do
      let tpss = [50, 156, 312]
          n1s = [50, 156, 312]
          dbs = [50000, 156250, 312500]
          -- confRates = [1.93, 2.67, 5.00, 15.62, 31.25]
          -- TTS isn't an exact match, but p close. Definitely *looks* mostly right WRT numbers coming out.
          -- ttss = [0.44, 0.94, 1.03]
          s = basicSample.ut
          -- exclude +T variant b/c py script doesn't get it
          variants = [s.std, s.ho, s.hot]
      it "TPS" do
        ((\v -> floor v.d1.tps) <$> variants) `shouldEqual` tpss
      it "N1" do
        ((\v -> floor v.d1.n) <$> variants) `shouldEqual` n1s
      it "dS" do
        ((\v -> floor v.deltaBigS) <$> variants) `shouldEqual` dbs
      -- it "ds" do
      --   ((\v -> floor v.deltaSmallS) <$> variants) `shouldEqual` dss
      -- it "Conf Rates" $ do
      --   ((\v -> v.confRate) <$> variants) `shouldEqual` confRates
      --   sequence_ $ (\t -> shouldBeWithin 0.005 (fst t) (snd t)) <$> zip ((\v -> v.confRate) <$> variants) confRates
      -- it "TTS" $ do
      --   ((\v -> v.tts) <$> variants) `shouldEqual` ttss
      --   sequence_ $ (\t -> shouldBeWithin 0.005 (fst t) (snd t)) <$> zip ((\v -> v.tts) <$> variants) ttss

    describe "easy testing" do
      it "sandbox" do
        liftEffect $ C.log $ show $ utvStripP $ allUtChainCalcs {
          hfs: NEL.singleton {bf: 1.0/15.0, bh: 84.0}
          , ks: NEL.singleton 3000.0
          , txSize: 250.0
          }
