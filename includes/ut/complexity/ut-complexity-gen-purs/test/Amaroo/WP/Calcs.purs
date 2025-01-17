module Test.Amaroo.WP.Calcs where

import Amaroo.WP.Calcs
import Prel

import Amaroo.WP.Tables (_ETH2_1M_K, btToF, getTps)
import Data.Array (intercalate, zip)
import Data.Array as A
import Data.Either (Either(..), fromLeft, isLeft)
import Data.Int (toNumber)
import Data.Int as I
import Data.List.NonEmpty as NEL
import Data.Maybe (Maybe(..), fromJust)
import Data.Number.Format (toString)
import Data.Traversable (sequence_)
import Data.Tuple (Tuple(..), fst, snd)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Console as C
import Math (abs, ceil, floor, pow, round)
import Node.Encoding (Encoding(..))
import Node.FS.Sync (writeTextFile)
import Partial.Unsafe (unsafePartial)
import Test.QuickCheck (Result(..), (<?>))
import Test.QuickCheck.Gen (Gen, choose, chooseInt)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (fail, shouldEqual, shouldNotEqual, shouldSatisfy)
import Test.Spec.QuickCheck (quickCheck)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)


main = do
  launchAff_ $ runSpec [consoleReporter] do
    utSpec


basicTestPs :: Params
basicTestPs = mkSimplePs 1000.0 {bf: 1.0/10.0, bh: 100.0} 500.0

genParams :: _ Params
genParams =
  [ basicTestPs
  , mkSimplePs 3000.0 {bf: 1.0/15.0, bh: 84.0} 250.0
  ]

basicSample = genSample basicTestPs

basicN1Limit = 0.5
basicLimitKbRSample = genSample $ basicTestPs {limitN1Ratio = Just basicN1Limit}

genSample :: _
genSample = runChainCalcFor

expectTrue x = x `shouldEqual` true

isWithin d x y = (x - y) |> abs |> (d - _) |> (_ > 0.0)
isWithinR r x y = abs (x - y) / y < r

shouldBeLessThan x y = x < y |> not |> when $ fail $ show x <> " >= " <> show y <> " (should be less than instead)"
shouldBeMoreThan x y = x > y |> not |> when $ fail $ show x <> " <= " <> show y <> " (should be more than instead)"

shouldBeWithin d x y = isWithin d x y |> not |> when $
  fail $ show x <> " /= " <> show y <> " (difference should be less than" <> show d <> ")"

shouldBeCloseTo = shouldBeWithin 0.00001

shouldBeWithinR r x y = isWithinR r x y |> not |> when $
  fail $ show x <> " /= " <> show y <> " (values be within ratio: " <> show r <> ")"

shouldBasiallyEqual = shouldBeWithinR 0.00000001

dNShouldEqual actual@{n, t, tps} expected = {n, t, tps} `shouldEqual` expected

dNShouldBeVClose a e = (t a.n e.n && t a.t e.t && t a.tps e.tps) |> not |> when $
    fail $ show {n: a.n, t: a.t, tps: a.tps} <> " /= " <> show e <> " (values must be within " <> show d <> ")"
  where
    t x y = isWithin d x y
    d = 0.000001

kRange :: _ -> Array Number
kRange {from, to, step} = A.range 0 nEntries <#> \i -> from + step * toNumber i
  where
    nEntries = I.ceil $ (to - from) / step

tradSpec :: Spec Unit
tradSpec = describe "trad chains" do
      let pss = genParams
          samples = genSample <$> pss
      it "should calc trad.d1 correctly" do
        basicSample.trad.d1 `dNShouldEqual` {n: 1.0, t: 1000.0, tps: 2.0}
        basicSample.tradEth2.d1 `dNShouldEqual` {n: 1.0, t: 1000.0, tps: 2.0}
      it "should calc trad.d2 correctly" do
        basicSample.trad.d2 `dNShouldEqual` {n: 100.0, t: 100000.0, tps: 200.0}
      it "should calc trad.d3 correctly" do
        basicSample.trad.d3 `dNShouldEqual` {n: 10000.0, t: 10000000.0, tps: 20000.0}
      it "should calc trad other stuff" do
        basicSample.trad.confRate `shouldEqual` 0.1
        basicSample.trad.deltaBigS `shouldEqual` 1000.0
        basicSample.trad.deltaSmallS `shouldEqual` 1000.0
        basicSample.trad.tts `shouldBeCloseTo` 0.18262499999999998
        basicSample.tradEth2.confRate `shouldEqual` 0.1
        basicSample.tradEth2.deltaBigS `shouldEqual` 1000.0
        basicSample.tradEth2.deltaSmallS `shouldEqual` 1000.0
        basicSample.tradEth2.tts `shouldBeCloseTo` 0.18262499999999998
      it "shouldn't depend on limitN1Ratio" do
        basicLimitKbRSample.trad.kB `shouldEqual` 0.0
        basicLimitKbRSample.tradEth2.kB `shouldEqual` 0.0
        basicLimitKbRSample.trad.kTx `shouldEqual` basicLimitKbRSample.trad.k1
        basicLimitKbRSample.tradEth2.kTx `shouldEqual` basicLimitKbRSample.tradEth2.k1


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
    describe "misc" do
      it "has a working isWithin function" do
        quickCheck \n -> isWithin 0.000000001 n n <?> "isWithin broken! t0 " <> show n
        quickCheck \n -> isWithin 0.0001 n n <?> "isWithin broken! t1 " <> show n
        quickCheck \n -> not (isWithin 0.00001 n (n + 0.000011)) <?> "isWithin broken! t2 " <> show n
        quickCheck \n -> (isWithin 1.0 n (n + 0.8)) <?> "isWithin broken! t3 " <> show n
        quickCheck \n -> (isWithin 1.0 n (n - 0.8)) <?> "isWithin broken! t4 " <> show n
        quickCheck \n -> not (isWithin 1.0 n (n - 1.8)) <?> "isWithin broken! t5 " <> show n

    let utvs = basicSample.ut
        std = utvs.std
    describe "ut.std" do
      let p_n1 = pToPF basicTestPs
          lKB = p_n1.k * basicN1Limit / 2.0
          lKTx = p_n1.k - lKB
          {bf, bh} = p_n1.hf
          limitedD1 = {n: lKB / bf / bh, t: lKTx * lKB / bf / bh, tps: lKTx * lKB / bf / bh / 500.0}
      it "d1" do
        basicSample.ut.std.d1 `dNShouldEqual` {n: 50.0, t: 500.0 * 50.0, tps: 50.0}
        basicLimitKbRSample.ut.std.d1 `dNShouldEqual` limitedD1
      it "d2" do
        basicSample.ut.std.d2 `dNShouldEqual` {n: 50.0 `pow` 2.0, t: 2500000.0, tps: 5000.0}
      it "d3" do
        basicSample.ut.std.d3 `dNShouldEqual` {n: 2500.0 * 100.0, t: 250000000.0, tps: 500000.0}
      it "confRate" do
        basicSample.ut.std.confRate `shouldEqual` 5.0
      it "dbs" do
        -- basicSample.ut.std.deltaBigS `shouldEqual` (1000.0 * 50.0)
        basicSample.ut.std.deltaBigS `shouldEqual` (1000.0 * 50.0 / 2.0 + 50.0 * bf * (bh + 32.0 * (1.0 + bf * 50.0 * phiOverlapSec))) -- 1060.0)  -- 1060.0 is the PoR graph overhead
      it "k" do
        std.k1 `shouldEqual` 1000.0

      let n1 = 50.0
          k = 1000.0
          -- note, don't add bh (because we don't omit headers in std) and don't add hash(bh) b/c it's the last element in the PoR branch
          dss = k + 0.1 * n1 * (porLen 32.0 n1)  -- k + bf * N1 proofs * (proof_size)
          -- dS = k * n1
          dS = k * n1 / 2.0 + 50.0 * bf * (bh + 32.0 * (1.0 + bf * n1 * phiOverlapSec))
          tts = 5.0 * 365.25 * dss / 10_000_000.0
          stts = 5.0 * 365.25 * dS / 10_000_000.0
      it "dss" do
        basicSample.ut.std.deltaSmallS `shouldEqual` dss
      it "tts" do
        basicSample.ut.std.tts `shouldBeCloseTo` tts
      it "sigma-tts" do
        basicSample.ut.std.sigmaTts `shouldBeCloseTo` stts

    sequence_ $ do
      (Tuple getCs (Tuple g bh)) <- [Tuple (\vs -> vs.pors) $ Tuple 32.0 100.0, Tuple (\vs -> vs.ports) $ Tuple 16.0 (applyTDiscountToBH 100.0)]
      pure $ do
        let name = if g == 32.0 then "pors" else "ports"
            ps = mkSimplePs 1000.0 {bh, bf: 0.1} 500.0
            gHdr = g
            gElse = 32.0
        describe ("ut." <> name) do
          let n1 = findMaxPoRsN1 ps gHdr gElse
              porSize = porLen gElse n1
              kTx = 1000.0 - n1 * (bh + porSize) * 0.1
              t1 = n1 * kTx
              ut = getCs utvs
          it "should not increase throughput to add more chains" do
            t1 `shouldSatisfy` (_ > (n1 + 1.0) * (1000.0 - ((n1 + 1.0) * porSize)))
          it "kTx matches" do
            ut.kTx `shouldBasiallyEqual` kTx
          it "d1" do
            ut.d1 `dNShouldBeVClose` {n: n1, t: t1, tps: t1 / 500.0}
          it "d2" do
            let n2 = n1 * (kTx / 0.1 / bh)
                t2 = n2 * 1000.0
                tps2 = t2 / 500.0
            ut.d2 `dNShouldBeVClose` {n: n2, t: t2, tps: tps2}


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
        I.round ut.d1.tps `shouldEqual` 156
        I.round ut.d1.n `shouldEqual` 156
        I.round (auxStats ut).scalingFactors.nesting `shouldEqual` (I.round $ ut.d2.tps / ut.d1.tps)
      it "d2" do
        -- constants from comparison-gen.py
        I.floor ut.d2.n `shouldEqual` 7_812
        I.round (t2 / txSize) `shouldEqual` 15_625
        I.round t2 `shouldEqual` (15_625 * 500)
        I.round ut.d2.tps `shouldEqual` 15_625
        ut.d2 `dNShouldEqual` {n: n2, t: t1 * 100.0, tps: t1 * 100.0 / txSize}
      it "d3" do
        ut.d3 `dNShouldEqual` {n: n3, t: t3, tps: t3 / 500.0}
      -- it "other" do
      --   ut.tts `shouldEqual`

    describe "limited N1" do
      sequence_ $ do
        Tuple utVName getUtVar <-
          [ Tuple "pors"    $ \ut -> ut.pors
          , Tuple "ports"   $ \ut -> ut.ports
          , Tuple "hopors"  $ \ut -> ut.hopors
          , Tuple "hoports" $ \ut -> ut.hoports
          , Tuple "std"     $ \ut -> ut.std
          , Tuple "t"       $ \ut -> ut.t
          , Tuple "ho"      $ \ut -> ut.ho
          , Tuple "hot"     $ \ut -> ut.hot
          ]
        pure $ describe utVName do
          sequence_ do
            Tuple propName getProp <-
              [ Tuple "d1.n" $ \cs -> cs.d1.n
              , Tuple "d1.t" $ \cs -> cs.d1.t
              , Tuple "d2.n" $ \cs -> cs.d2.n
              , Tuple "d2.t" $ \cs -> cs.d2.t
              , Tuple "d3.n" $ \cs -> cs.d3.n
              , Tuple "d3.t" $ \cs -> cs.d3.t
              ]
            pure $ it propName do
              getProp (getUtVar basicLimitKbRSample.ut) `shouldBeLessThan` getProp (getUtVar basicSample.ut)
        --       basicLimitKbRSample.ut.hoports.d1.n `shouldSatisfy (<=)` basicSample.ut.hoports.d1.n
        -- basicLimitKbRSample.ut.hopors.d1.n `shouldSatisfy (<=)` basicSample.ut.hopors.d1.n
        -- basicLimitKbRSample.ut.std.d1.n `shouldSatisfy (<=)` basicSample.ut.std.d1.n
        -- basicLimitKbRSample.ut.t.d1.n `shouldSatisfy (<=)` basicSample.ut.t.d1.n
        -- basicLimitKbRSample.ut.ho.d1.n `shouldSatisfy (<=)` basicSample.ut.ho.d1.n
        -- basicLimitKbRSample.ut.hot.d1.n `shouldSatisfy (<=)` basicSample.ut.hot.d1.n
        -- basicLimitKbRSample.ut.pors.d1.n `shouldSatisfy (<=)` basicSample.ut.pors.d1.n
        -- basicLimitKbRSample.ut.ports.d1.n `shouldSatisfy (<=)` basicSample.ut.ports.d1.n

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
        -- note: with vector commits we'll often hit the lower limit of 32 bytes
        utvs.t.porBytes `shouldSatisfy` ((>=) utvs.std.porBytes)
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
                 , limitN1Ratio: Nothing
                 }
            trad = tradChainCalc ps
            ut = allUtChainCalcs ps
            ps2 = mkNestedPs 1111.0 {bf: 0.11, bh: 10.0} {bf: 0.22, bh: 20.0} 500.0
            trad2 = tradChainCalc ps2
            ut2 = allUtChainCalcs ps2
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
        trad2.d1.p.hf.bh `shouldEqual` 10.0
        trad2.d2.p.hf.bh `shouldEqual` 20.0
        trad2.d1.p.hf.bf `shouldEqual` 0.11
        trad2.d2.p.hf.bf `shouldEqual` 0.22
        ut2.std.d1.p.hf.bh `shouldEqual` 10.0
        ut2.std.d2.p.hf.bh `shouldEqual` 20.0
        ut2.std.d1.p.hf.bf `shouldEqual` 0.11
        ut2.std.d2.p.hf.bf `shouldEqual` 0.22

    describe "calcNextNestingLevel and maxN" do
      it "eth2 limited to 1024 shards" do
        let eth2Ps = basicTestPs { ks = NEL.singleton _ETH2_1M_K }
            eth2 = tradChainCalcEth2 eth2Ps
            notEth2 = tradChainCalc eth2Ps
        eth2.d2.n `shouldEqual` 1024.0
        notEth2.d2.n `shouldNotEqual` 1024.0

    describe "ut comparison test vecs" do
      -- note that k=1000
      let tpss = [50, 156, 312]
          n1s = [50, 156, 312]
          dbs = [26060, 84093, 166875]
          confRates = [5.00, 15.625, 31.25]
          -- TTS isn't an exact match, but p close. Definitely *looks* mostly right WRT numbers coming out.
          -- ttss = [0.44, 0.94, 1.03]  -- from python gen
          ttss = [0.212, 0.559, 0.828]  -- these are the new TTS figures; keeping them here to make sure we know if they change
          dss = [1165, 3078, 4533]  -- these are the new TTS figures; keeping them here to make sure we know if they change
          s = basicSample.ut
          -- exclude +T variant b/c py script doesn't get it
          variants = [s.std, s.ho, s.hot]
      it "TPS" do
        ((\v -> I.floor v.d1.tps) <$> variants) `shouldEqual` tpss
      it "N1" do
        ((\v -> I.floor v.d1.n) <$> variants) `shouldEqual` n1s
      it "dS" do
        ((\v -> I.floor v.deltaBigS) <$> variants) `shouldEqual` dbs
      it "ds" do
        ((\v -> I.floor v.deltaSmallS) <$> variants) `shouldEqual` dss
      it "Conf Rates" $ do
        sequence_ $ (\t -> shouldBeWithin 0.005 (fst t) (snd t)) <$> zip ((\v -> v.confRate) <$> variants) confRates
      it "TTS" $ do
        sequence_ $ (\t -> shouldBeWithin 0.005 (fst t) (snd t)) <$> zip ((\v -> v.tts) <$> variants) ttss

    describe "PoR consistency checks" do
      it "numbers from tables (or otherwise calculated)" do
        let getN1PoRs k = (\ps -> findMaxPoRsN1 ps 32.0 32.0) $ mkSimplePs k {bf: btToF 15, bh: 84.0} 250.0
            getN1PoRTs k = (\ps -> findMaxPoRsN1 ps 16.0 32.0) $ mkSimplePs k {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0
        getN1PoRs 3000.0 `shouldEqual` 192.0
        getN1PoRTs 3000.0 `shouldEqual` 227.0
        findMaxPoRsN1 (mkSimplePs 3000.0 {bf: btToF 60, bh: 112.0} 250.0) 32.0 32.0 `shouldEqual` 511.0
        let expected = [5119.0, 10239.0, 15359.0, 20223.0, 25343.0, 30463.0, 35583.0, 40447.0, 45567.0, 50687.0]
            actual = getN1PoRTs <$> [100000.0, 200000.0, 300000.0, 400000.0, 500000.0, 600000.0, 700000.0, 800000.0, 900000.0, 1000000.0]
        actual `shouldEqual` expected

    -- Note: probs best to leave this as `false` b/c it is slooooow
    let record_k_vs_n1_forPoRs_csv = false
    if record_k_vs_n1_forPoRs_csv
      then describe "PoR experiment" do
        -- hypothesis: close enough to O(c) scaling of N1 -- roughly linear vs k
        it "prints" do
          let r = kRange {from: 100.0, to: 100_000.0, step: 100.0}
              r2 = kRange {from: 10_000.0, to: 100_000_000.0, step: 10_000.0}
          liftEffect $ writeTextFile UTF8 "test-output-ports-k-vs-n1.csv" $ intercalate "\n" $
            r <#> (\k -> Tuple k $ (\ps -> findMaxPoRsN1 ps 16.0 32.0) $ mkSimplePs k {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0)
              <#> (\(Tuple k n) -> show k <> "," <> show n)
          liftEffect $ writeTextFile UTF8 "test-output-pors-k-vs-n1.csv" $ intercalate "\n" $
            r <#> (\k -> Tuple k $ (\ps -> findMaxPoRsN1 ps 32.0 32.0) $ mkSimplePs k {bf: btToF 15, bh: 84.0} 250.0)
              <#> (\(Tuple k n) -> show k <> "," <> show n)
          -- -- NB: This one is v slow
          liftEffect $ C.log $ "Warning, about to calculate PoRs table for k in (10_000, 100_000_000) with a step size of 10_000. This may take some time"
          liftEffect $ writeTextFile UTF8 "test-output-ports-k-vs-n1-waymore.csv" $ intercalate "\n" $
            r2 <#> (\k -> Tuple k $ (\ps -> findMaxPoRsN1 ps 16.0 32.0) $ mkSimplePs k {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0)
              <#> (\(Tuple k n) -> show k <> "," <> show n)
      else pure unit

    let doPoRExp2 = false
    if not doPoRExp2
      then pure unit
      else describe "por exp 2" do
        it "quickchecks" do
          quickCheck porsForRangesQC
        it "test findMaxPoRsN1ForRanges" do
          let r10MPors = kRange {from: 10_000.0, to: 10_000_000.0, step: 10_000.0}
                    <#> (\k -> mkSimplePs k {bf: btToF 15, bh: 84.0} 250.0)
              r10MPorts = kRange {from: 10_000.0, to: 10_000_000.0, step: 10_000.0}
                    <#> (\k -> mkSimplePs k {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0)
              rPors = kRange {from: 100.0, to: 100_000.0, step: 33.33333333333}
                    <#> round <#> (\k -> mkSimplePs k {bf: btToF 15, bh: 84.0} 250.0)
              rPorts = kRange {from: 100.0, to: 100_000.0, step: 33.33333333333}
                    <#> round <#> (\k -> mkSimplePs k {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0)
          -- -- liftEffect $ C.log $ "testing new pors for ranges"
          -- liftEffect $ writeTextFile UTF8 "ports-k-vs-n1-to10MBs.csv" $ intercalate "\n" $
          --   findMaxPoRsN1ForRanges {g: 16.0, r} <#> (\(Tuple ps {i}) -> show (pToPF ps).k <> "," <> show i)
          liftEffect $ writePoRTableToCsv {r: r10MPors, gHdr: 32.0, gElse: 32.0, fn: "pors-k-vs-n-to-k-eq-10M.csv"}
          liftEffect $ writePoRTableToCsv {r: r10MPorts, gHdr: 16.0, gElse: 32.0, fn: "ports-k-vs-n-to-k-eq-10M.csv"}
          liftEffect $ writePoRTableToCsv {r: rPors, gHdr: 32.0, gElse: 32.0, fn: "pors-k-vs-n-to-k-eq-100000.csv"}
          liftEffect $ writePoRTableToCsv {r: rPorts, gHdr: 16.0, gElse: 32.0, fn: "ports-k-vs-n-to-k-eq-100000.csv"}
          liftEffect $ writeHOPoRTableToCsv {r: r10MPors, gHdr: 32.0, gElse: 32.0, fn: "hopors-k-vs-n-to-k-eq-10M.csv"}
          liftEffect $ writeHOPoRTableToCsv {r: r10MPorts, gHdr: 16.0, gElse: 32.0, fn: "hoports-k-vs-n-to-k-eq-10M.csv"}
          liftEffect $ writeHOPoRTableToCsv {r: rPors, gHdr: 32.0, gElse: 32.0, fn: "hopors-k-vs-n-to-k-eq-100000.csv"}
          liftEffect $ writeHOPoRTableToCsv {r: rPorts, gHdr: 16.0, gElse: 32.0, fn: "hoports-k-vs-n-to-k-eq-100000.csv"}

    let doComparitiveK = false
    if not doComparitiveK
      then pure unit
      else describe "comparative k graph" do
        it "writes csv for comparative k graph" do
          let ks = kRange {from: 100.0, to: 30_000.0, step: 100.0}
              ps = ks <#> (\k -> mkSimplePs k {bf: btToF 15, bh: 84.0} 250.0)
              stats_rows = (allUtChainCalcs <$> ps) :: Array (UtVariants ChainStats)
              heading_row = ["$k$ (B/s)", "PoRs TPS2", "PoRTs TPS2", "HOPoRs TPS2", "HOPoRTs TPS2", "OP TPS2", "OPT TPS2", "HO TPS2", "HOT TPS2"]
              rows = [heading_row] <> ((chain_stats_to_row >>> map toString) <$> stats_rows)
              rows' = map (intercalate ",") rows
              contents = intercalate "\n" rows'
          liftEffect $ writeTextFile UTF8 "comparative-k.csv" contents

    describe "+PoRs vs large headers checks" do
      it "large headers approx (w/in ~33%) of +PoRs" do
        let tx = 250.0
            utL = utChainCalc (mkSimplePs 3000.0 {bf: btToF 15, bh: 115.0} tx) {explicitPoRs: false, hashTruncation: false, headerOmission: false, onlyNecessaryHeaders: false}
            utP = utChainCalc (mkSimplePs 3000.0 {bf: btToF 15, bh: 84.0} tx) {explicitPoRs: true, hashTruncation: false, headerOmission: false, onlyNecessaryHeaders: false}
        -- +PoRs and std
        utP.d1.tps `shouldBeWithin 0.5` 1154.0
        utP.d1.n `shouldBeWithin 0.5` 192.0
        utL.d1.tps `shouldBeWithin 30.0` utP.d1.tps  -- 489 vs 467
        utL.d1.n `shouldBeWithin 20.0` utP.d1.n  -- 82 vs 64
      it "large headers approx (w/in ~33%) of +PoRTs" do
        let tx = 250.0
            utLT = utChainCalc (mkSimplePs 3000.0 {bf: btToF 15, bh: 99.0} tx) {explicitPoRs: false, hashTruncation: false, headerOmission: false, onlyNecessaryHeaders: false}
            utPT = utChainCalc (mkSimplePs 3000.0 {bf: btToF 15, bh: 84.0} tx) {explicitPoRs: true, hashTruncation: true, headerOmission: false, onlyNecessaryHeaders: false}
        -- +T
        utPT.d1.tps `shouldBeWithin 0.5` 1364.0
        utPT.d1.n `shouldBeWithin 0.5` 227.0
        utLT.d1.tps `shouldBeWithin 2.0` utPT.d1.tps
        utLT.d1.n `shouldBeWithin 1.0` utPT.d1.n

    describe "quickchecks" do
      it "passes" do
        quickCheck (utChecks <$> paramsGen)

      it "porVCLen" do
        quickCheck $ abs >>> \n ->
          porVCLen n == porVCLen2 n

writePoRTableToCsv :: {fn :: String, gHdr :: Number, gElse :: Number, r :: Array Params} -> Effect Unit
writePoRTableToCsv {fn, gHdr, gElse, r} = writeTextFile UTF8 fn $ intercalate "\n" $
          findMaxPoRsN1ForRanges {gHdr, gElse, r} <#> (\(Tuple ps {i}) -> intercalate "," $ show <$> [(pToPF ps).k, toNumber i, (utNoExplicitPoRsN1 (pToPF ps))])

writeHOPoRTableToCsv :: {fn :: String, gHdr :: Number, gElse :: Number, r :: Array Params} -> Effect Unit
writeHOPoRTableToCsv {fn, gHdr, gElse, r} = writeTextFile UTF8 fn $ intercalate "\n" $ append ["k, N1, \"N1 w/o PoRs\", T1"] $
          findMaxHOPoRsN1ForRanges {gHdr, gElse, r} <#> (\(Tuple ps {i, t}) -> intercalate "," $ show <$> [(pToPF ps).k, toNumber i, (utNoExplicitPoRsN1 (pToPF ps)), t])

utNoExplicitPoRsN1 p =
  let bh = p.hf.bh
      bf = p.hf.bf
  in p.k / 2.0 / bf / bh

porsForRangesQC :: Number -> Result
porsForRangesQC _k = normalAnswer == rangesAnswer <?> "Mismatching: " <> show {expected: normalAnswer, got: rangesAnswer}
  where
    k = enlarge 3000.0 _k
    enlarge target i = if abs i < target then enlarge (abs target) (abs $ 10.0 * i) else floor i
    normalAnswer :: {k :: Number, n :: Number}
    normalAnswer = {k: lastRangeK, n: (\ps -> findMaxPoRsN1 ps 16.0 32.0) $ mkSimplePs lastRangeK {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0}
    rangesAnswer :: {k :: Number, n :: Number}
    rangesAnswer = findMaxPoRsN1ForRanges {gHdr: 16.0, gElse: 32.0, r: inputRanges}
                    |> A.last |> unsafePartial fromJust |> (\(Tuple ps {i}) -> {k:(pToPF ps).k, n: toNumber i})
    inputRanges = (\inK -> mkSimplePs inK {bf: btToF 15, bh: applyTDiscountToBH 84.0} 250.0)
                    <$> rangeKs
    rangeKs = kRange {from: floor $ k / 2.0, to: ceil k, step: floor $ k / 20.0}
    lastRangeK = unsafePartial fromJust $ A.last rangeKs

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


paramsGen :: Gen Params
paramsGen = do
    bh <- choose 40.0 500.0
    tx <- choose 50.0 1000.0
    k <- (max (3.0 * (bh + tx)) <<< add tx <<< add bh) <$> choose 1000.0 10000.0
    bt <- chooseInt 1 20
    pure $ mkSimplePs k {bf: btToF bt, bh} tx

utChecks :: Params -> Result
utChecks p = doUtChecks p $ allUtChainCalcs p

orError :: Boolean -> String -> Either String Unit
orError b e = if b then Right unit else Left e

infixl 1 orError as <?

doUtChecks :: Params -> UtVariants ChainStats -> Result
doUtChecks p uts = if A.length filteredRes == 0
    then Success
    else Failed $ A.intercalate "\n * " $ ["UT checks failed -- P(" <> show p <> "):"] <> errMsgs
  where
    filteredRes = A.filter isLeft results
    errMsgs = fromLeft ":( no error (you should never see this)" <$> filteredRes
    utStdNperTps = uts.std.d1.n / uts.std.d1.tps
    results =
      [ Right unit
      , isWithin 0.20 (uts.pors.d1.n / uts.pors.d1.tps) utStdNperTps <? "+PoRs should have a tps ratio v similar to std -- " <> show (uts.pors.d1.n / uts.pors.d1.tps) <> " vs " <> show utStdNperTps
      , isWithin 0.20 (uts.ports.d1.n / uts.ports.d1.tps) utStdNperTps <? "+PoRTs should have a tps ratio v similar to std -- " <> show (uts.ports.d1.n / uts.ports.d1.tps) <> " vs " <> show utStdNperTps
      , isWithin 0.01 (uts.t.d1.n / uts.t.d1.tps) utStdNperTps <? "+T should have a tps ratio v similar to std"
      , isWithin 0.01 (uts.ho.d1.n / uts.ho.d1.tps) utStdNperTps <? "+HO should have a tps ratio v similar to std"
      , isWithin 0.01 (uts.hot.d1.n / uts.hot.d1.tps) utStdNperTps <? "+HOT should have a tps ratio v similar to std"
      -- , Left "oh no"
      -- , false <? "well that didn't work"
      -- , true <? "but this did"
      ]


chain_stats_to_row :: UtVariants ChainStats -> Array _
chain_stats_to_row utcs = [utcs.std.k1] <> (rowval <$> [utcs.pors, utcs.ports, utcs.hopors, utcs.hoports, utcs.std, utcs.t, utcs.ho, utcs.hot])
  where
    rowval cs = (cs :: ChainStats).d2.tps
