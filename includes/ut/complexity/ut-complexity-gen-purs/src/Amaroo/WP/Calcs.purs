module Amaroo.WP.Calcs where

import Prel

import Amaroo.WP.Utils (prel)
import Data.Int (toNumber)
import Data.Int as I
import Data.List.NonEmpty (NonEmptyList, cons', fromList, head, singleton, tail)
import Data.List.NonEmpty as NEL
import Data.Maybe (fromMaybe)
import Math (ceil, floor, ln2, log)

{-|

# Complexity Calculations

For a given set of parameters we want to generate all possible output data (keeps things easy and general).

Other chains are all under the `ChainComplexities.trad` model; and UT is under `ChainComplexities.ut`.

Any new UT variants should be added to the `UtVariants` type, and

-}

type ChainNestingParams
  = { bf :: Number, bh :: Number }

type ParamsL l
  = { ks :: l Number
    , hfs :: l ChainNestingParams -- | List of {header,frequency} pairs
    , txSize :: Number
    }
type Params = ParamsL NonEmptyList

type ParamsF = {k :: Number, hf :: ChainNestingParams, txSize :: Number}

pToPF :: Params -> ParamsF
pToPF p = {k: head p.ks, hf: head p.hfs, txSize: p.txSize}

showableParams :: Params -> ParamsL Array
showableParams p = {ks: NEL.toUnfoldable p.ks, hfs: NEL.toUnfoldable p.hfs, txSize: p.txSize}

-- instance showParams :: Show Params where
--   show {ks, hfs, txSize} = show {ks: NEL.toList ks, hfs: NEL.toList hfs, txSize}

mkSimplePs :: Number -> ChainNestingParams -> Number -> Params
mkSimplePs k hf txSize = {ks: singleton k, hfs: singleton hf, txSize}

type UtVariants a
  = { pors :: a
    , ports :: a
    , std :: a
    , t :: a
    , ho :: a
    , hot :: a
    }

type UtOptimizations
  = { explicitPoRs :: Boolean
    , headerOmission :: Boolean
    , hashTruncation :: Boolean
    }

type NestingStats
  = { tps :: Number
    , n :: Number
    , t :: Number
    , p :: ParamsF
    }

stripParams :: NestingStats -> _
stripParams {n, t, tps} = {n, t, tps}

-- nsShowable :: NestingStats -> _
-- nsShowable ns@{p} = ns { p = p }

type ChainStats
  = { d1 :: NestingStats
    , d2 :: NestingStats
    , d3 :: NestingStats
    , deltaBigS :: Number
    , deltaSmallS :: Number
    , tts :: Number
    , confRate :: Number
    , porBytes :: Number
    , porBytes2 :: Number
    , effBh :: Number
    , effDh :: Number
    , kTx :: Number
    , kB :: Number
    , k1 :: Number
    }

csStripP :: ChainStats -> _
csStripP cs@{d1, d2, d3} = cs { d1 = stripParams d1, d2 = stripParams d2, d3 = stripParams d3 }

utvStripP :: UtVariants ChainStats -> _
utvStripP {pors, ports, std, t, ho, hot} = { pors: csStripP pors, ports: csStripP ports, std: csStripP std, t: csStripP t, ho: csStripP ho, hot: csStripP hot }


type ChainComplexities
  = { trad :: ChainStats
    , tradEth2 :: ChainStats
    , ut :: UtVariants ChainStats
    , ps :: Params
    }


-- | Return a set of parameters sutiable to use for the next nesting level
paramsForNextNS :: Params -> Params
paramsForNextNS ps@{txSize} = {ks, hfs, txSize}
  where
    -- Take the tale of the list, or if that is empty, use the existing list as default (which must only have 1 entry)
    ks = tail ps.ks |> fromList |> fromMaybe ps.ks
    hfs = tail ps.hfs |> fromList |> fromMaybe ps.hfs

tradInitNS :: Params -> NestingStats
tradInitNS ps = {n: 1.0, t: t, tps: t / ps.txSize, p: pToPF ps}
  where t = head ps.ks


calcNextNestingLevel :: Params -> NestingStats -> NestingStats
calcNextNestingLevel ps nsPrev = {n, t, tps, p: pToPF ps}
  where
    n = nsPrev.t / bfbh
    t = n * k
    tps = t / ps.txSize
    h = head ps.hfs
    bfbh = h.bf * h.bh
    k = head ps.ks

data TradVar = Trad | TradEth2

eth2EffDh bh = floor $ 8192.0 / (6.5*60.0) * 12.0 + bh * 0.1

tradChainCalc' :: Params -> TradVar -> ChainStats
tradChainCalc' ps var = {d1, d2, d3, confRate, deltaBigS, deltaSmallS, tts, effBh, effDh, kTx: k, k1: k, kB: 0.0, porBytes: 0.0, porBytes2: 0.0}
  where
    d1 = {n: 1.0, t: k, tps: k / ps.txSize, p: pToPF ps}
    k = head ps.ks
    hf = head ps.hfs
    ps2 = paramsForNextNS ps
    hf2 = head ps2.hfs
    ps3 = paramsForNextNS ps2
    bhMod = case var of
      Trad -> identity
      TradEth2 -> eth2EffDh
    effBh = hf.bh
    effDh = bhMod hf2.bh
    d2 = calcNextNestingLevel (ps2 { hfs = singleton {bf: hf2.bf, bh: effDh} }) d1
    d3 = calcNextNestingLevel ps3 d2
    deltaBigS = k
    deltaSmallS = k
    tts = ((deltaSmallS * 5.0 * 365.25) / 10_000_000.0)
    confRate = hf.bf

tradChainCalc ps = tradChainCalc' ps Trad

tradChainCalcEth2 ps = tradChainCalc' ps TradEth2

porLen :: Number -> Number -> Number
porLen hashSize n = hashSize * log2c n

utPorsT1 :: Number -> Number -> Number -> Number -> Number -> Number
utPorsT1 n1 k1 bf bh g = n1 * (k1 - bf * n1 * (bh + porLen g n1))

-- todo: convert from sorted-array method to a fixed memory iteration where the maximum gets tracked
findMaxPoRsN1 :: Params -> Number -> Number
findMaxPoRsN1 ps g = (loopFindMaxF {i: 1, n: 0.0, t: 0.0}).n
  where
    -- answer = bestTN.n
    -- -- inefficient, but foolproof (why I cared about performance before, IDK)
    -- bestTN = sortedT1s |> A.last |> fromMaybe {a: 0.0, b: 0.0} |> (\{a,b} -> {n: a, t: b})
    -- sortedT1s = A.sortBy (\o1 o2 -> compare o1.b o2.b) possibleT1s
    -- possibleT1s = (nRange <#> utPorsT1Applied |> A.zip nRange) <#> tupToRec
    loopFindMaxF m@{i, t} = if i >= wontBeMoreThan || t1 < 0.0 then m else loopFindMaxF (if t1 > t then {i: i + 1, n: i_, t: t1} else m {i = i + 1})
      where
        i_ = toNumber i
        t1 = utPorsT1Applied i_
    -- nRange = A.range 1 wontBeMoreThan <#> I.toNumber
    utPorsT1Applied n1 = utPorsT1 n1 k1 bf bh g
    k1 = head ps.ks
    bf = hf.bf
    bh = hf.bh
    hf = head ps.hfs
    wontBeMoreThan = I.floor $ k1 / 2.0 / bf / bh  -- N1 without explicit PoRs
    -- from WP, useful for some things.
    -- | \frac{\d{T_1}}{\d{N_1}}
    utPorsDT1byDN1 n1 = (k1 * ln2 - bf * n1 * (g + bh * log 4.0) - 2.0 * bf * g * n1 * log n1) / ln2

applyDiscountToHash :: Number -> Number
applyDiscountToHash bh = (bh - _) $ ceil $ (1.0 + prel {f: 80.0, t: 112.0, v: bh}) * 16.0

type UtParams = {explicitPoRs :: Boolean, headerOmission :: Boolean, hashTruncation :: Boolean}

utChainCalc :: Params -> UtParams -> ChainStats
utChainCalc ps {explicitPoRs, headerOmission, hashTruncation} = {d1, d2, d3, confRate, tts, deltaBigS, deltaSmallS, porBytes, porBytes2, effBh, effDh, kTx, kB, k1}
  where
    hashSize = if hashTruncation then 16.0 else 32.0
    -- ~~if bh<96 (1/2 way between 80 and 112) then only discount 1 hash, otherwise 2~~
    -- discount between 1 and two hashes worth depending on bh (inverse linear interpolate)
    htModBh bh = if hashTruncation then applyDiscountToHash bh else bh
    fixBH1 r@{bh} = r {bh = (if headerOmission then hashSize else htModBh bh)}
    fixBH2 r@{bh} = r {bh = htModBh bh}
    -- we have to modify the header size based on optimizations, but we don't want to pass
    --    this to other levels of nesting, so we'll make params for each nesting level.
    ps1 = ps {hfs = (fixBH1 (head ps.hfs) `cons'` tail ps.hfs)}
    hf = (head ps1.hfs)
    bfbh = hf.bf * hf.bh
    k1 = head ps1.ks
    n1 = if explicitPoRs then findMaxPoRsN1 ps1 hashSize else (k1 / 2.0 / bfbh)
    confRate = hf.bf * n1
    porBytes = porLen hashSize n1
    explicitPorsK = hf.bf * n1 * (porBytes + htModBh hf.bh)
    kTx = if explicitPoRs then k1 - explicitPorsK else (k1 / 2.0)
    kB = k1 - kTx
    t1 = kTx * n1
    d1 = {n: n1, t: t1, tps: t1 / ps.txSize, p: pToPF ps1}
    effBh = if explicitPoRs then d1.p.hf.bh + porBytes else d1.p.hf.bh
    -- NB: we want to re-adjust *unaltered params `ps` not `ps1` which we use for d1
    ps2Pre = paramsForNextNS ps -- trim param-depth lists
    ps2 = ps2Pre {hfs = (fixBH2 (head ps2Pre.hfs) `cons'` tail ps2Pre.hfs)}
    ps3 = paramsForNextNS $ ps2Pre
    deltaBigS = if explicitPoRs then k1 + explicitPorsK else n1 * k1
    deltaSmallS = if explicitPoRs then k1 else k1 + explicitPorsK  -- TODO: figure this out
    tts = ((5.0 * 365.25) * deltaSmallS / 10_000_000.0)  -- TODO: figure this out
    d2 = calcNextNestingLevel ps2 d1
    porBytes2 = porLen hashSize (d2.n / n1)
    effDh = d2.p.hf.bh  -- Note: don't take into account porBytes2 -- if explicitPoRs then d2.p.hf.bh + porBytes2 else d2.p.hf.bh
    d3 = calcNextNestingLevel ps3 d2

allUtChainCalcsF :: forall a. (UtOptimizations -> a) -> UtVariants a
allUtChainCalcsF f =
  { pors: f {explicitPoRs: true, headerOmission: false, hashTruncation: false}
  , ports: f {explicitPoRs: true, headerOmission: false, hashTruncation: true}
  , std: f {explicitPoRs: false, headerOmission: false, hashTruncation: false}
  , t: f {explicitPoRs: false, headerOmission: false, hashTruncation: true}
  , ho: f {explicitPoRs: false, headerOmission: true, hashTruncation: false}
  , hot: f {explicitPoRs: false, headerOmission: true, hashTruncation: true}
  }


allUtChainCalcs :: Params -> UtVariants ChainStats
allUtChainCalcs ps = allUtChainCalcsF (utChainCalc ps)


runChainCalcFor :: Params -> ChainComplexities
runChainCalcFor ps = {trad, ut, ps, tradEth2}
  where
    trad = tradChainCalc ps
    tradEth2 = tradChainCalcEth2 ps
    ut = allUtChainCalcs ps

-- | Calculate other stats based on ChainStats
auxStats :: ChainStats -> _
auxStats cs = {scalingFactors, tpsPerBaseChain, n1PerK, bfbh}
  where
    scalingFactors = {noNesting: 1.0, nesting: cs.d2.tps / cs.d1.tps}
    tpsPerBaseChain = {d1: cs.d1.tps / cs.d1.n, d2: cs.d2.tps / cs.d1.n, d3: cs.d3.tps / cs.d1.n}
    n1PerK = cs.d1.n / (cs.d1.p.k)
    hf = cs.d1.p.hf
    bfbh = hf.bf * hf.bh
