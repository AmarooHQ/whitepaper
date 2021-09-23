module Calcs where

import Prel

import Data.List.NonEmpty (NonEmptyList, cons', fromList, head, singleton, tail)
import Data.Maybe (fromMaybe)
import Data.Tuple (Tuple)
import Undefined (undefined)

{-|

# Complexity Calculations

For a given set of parameters we want to generate all possible output data (keeps things easy and general).

Other chains are all under the `ChainComplexities.trad` model; and UT is under `ChainComplexities.ut`.

Any new UT variants should be added to the `UtVariants` type, and

-}

type ChainNestingParams
  = { bf :: Number, bh :: Number }

type Params
  = { ks :: NonEmptyList Number
    , hfs :: NonEmptyList ChainNestingParams -- | List of {header,frequency} pairs
    , txSize :: Number
    }

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

type NestingStats
  = { tps :: Number
    , n :: Number
    , t :: Number
    }

type ChainStats
  = { d1 :: NestingStats
    , d2 :: NestingStats
    , d3 :: NestingStats
    , deltaBigS :: Number
    , deltaSmallS :: Number
    , tts :: Number
    , confRate :: Number
    }

type ChainComplexities
  = { trad :: ChainStats
    , ut :: UtVariants ChainStats
    }


-- | Return a set of parameters sutiable to use for the next nesting level
paramsForNextNS :: Params -> Params
paramsForNextNS ps@{txSize} = {ks, hfs, txSize}
  where
    -- Take the tale of the list, or if that is empty, use the existing list as default (which must only have 1 entry)
    ks = tail ps.ks |> fromList |> fromMaybe ps.ks
    hfs = tail ps.hfs |> fromList |> fromMaybe ps.hfs

tradInitNS :: Params -> NestingStats
tradInitNS ps = {n: 1.0, t: t, tps: t / ps.txSize}
  where t = head ps.ks


calcNextNestingLevel :: Params -> NestingStats -> NestingStats
calcNextNestingLevel ps nsPrev = {n, t, tps}
  where
    n = nsPrev.t / bfbh
    t = nsPrev.t * k / bfbh
    tps = t / ps.txSize
    h = head ps.hfs
    bfbh = h.bf * h.bh
    k = head ps.ks

tradChainCalc :: Params -> ChainStats
tradChainCalc ps = {d1, d2, d3, confRate, deltaBigS, deltaSmallS, tts}
  where
    d1 = {n: 1.0, t: k, tps: k / ps.txSize}
    k = head ps.ks
    d2 = calcNextNestingLevel ps d1
    d3 = calcNextNestingLevel ps d2
    deltaBigS = k
    deltaSmallS = k
    tts = ((deltaSmallS * 5.0 * 365.25) / 10_000_000.0)
    confRate = (head ps.hfs).bf

type UtParams = {explicitPoRs :: Boolean, headerOmission :: Boolean, hashTruncation :: Boolean}

utChainCalc :: Params -> UtParams -> ChainStats
utChainCalc ps {explicitPoRs, headerOmission, hashTruncation} = {d1, d2, d3, confRate, tts, deltaBigS, deltaSmallS}
  where
    hashSize = if hashTruncation then 16.0 else 32.0
    htModBh bh = bh - (if hashTruncation then 16.0 else 0.0)
    fixBH1 r@{bh} = r {bh = (if headerOmission then hashSize else htModBh bh)}
    fixBH2 r@{bh} = r {bh = htModBh bh}
    ps1 = ps {hfs = (fixBH1 (head ps.hfs) `cons'` tail ps.hfs)}
    hf = (head ps1.hfs)
    bfbh = hf.bf * hf.bh
    k1 = head ps1.ks
    kB = if explicitPoRs then undefined else (k1 / 2.0)
    kTx = k1 - kB
    n1 = kB / bfbh
    t1 = kTx * n1
    d1 = {n: n1, t: t1, tps: t1 / ps.txSize}
    -- NB: we want to re-adjust *unaltered params `ps` not `ps1` which we use for d1
    ps2Pre = paramsForNextNS ps -- trim param-depth lists
    ps2 = ps2Pre {hfs = (fixBH2 (head ps2Pre.hfs) `cons'` tail ps2Pre.hfs)}
    ps3 = paramsForNextNS $ ps2Pre
    deltaBigS = if explicitPoRs then undefined else n1 * k1
    deltaSmallS = if explicitPoRs then k1 else k1 + n1 * hashSize * log2c 50.0
    tts = ((deltaSmallS * 5.0 * 365.25) / 10_000_000.0)
    confRate = hf.bf * n1
    d2 = calcNextNestingLevel ps2 d1
    d3 = calcNextNestingLevel ps3 d2


allUtChainCalcs :: Params -> UtVariants _
allUtChainCalcs ps =
  { pors: utChainCalc ps {explicitPoRs: true, headerOmission: false, hashTruncation: false}
  , ports: utChainCalc ps {explicitPoRs: true, headerOmission: false, hashTruncation: true}
  , std: utChainCalc ps {explicitPoRs: false, headerOmission: false, hashTruncation: false}
  , t: utChainCalc ps {explicitPoRs: false, headerOmission: false, hashTruncation: true}
  , ho: utChainCalc ps {explicitPoRs: false, headerOmission: true, hashTruncation: false}
  , hot: utChainCalc ps {explicitPoRs: false, headerOmission: true, hashTruncation: true}
  }

runChainCalcFor :: Params -> ChainComplexities
runChainCalcFor ps = {trad, ut}
  where
    trad = tradChainCalc ps
    ut = allUtChainCalcs ps
