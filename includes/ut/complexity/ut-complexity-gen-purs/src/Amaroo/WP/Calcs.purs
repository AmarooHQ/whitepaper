module Amaroo.WP.Calcs where

import Prel

import Amaroo.WP.Utils (prel)
import Data.Array (intercalate)
import Data.Array as A
import Data.Array.NonEmpty (cons)
import Data.Int (toNumber)
import Data.Int as I
import Data.List.NonEmpty (NonEmptyList, cons', fromList, head, singleton, tail)
import Data.List.NonEmpty as NEL
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Effect.Exception (error, throwException)
import Effect.Exception.Unsafe (unsafeThrowException)
import Effect.Unsafe (unsafePerformEffect)
import Math (abs, ceil, floor, ln2, log, pow, (%))
import Math as M

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
    , limitN1Ratio :: Maybe Number
    }
type Params = ParamsL NonEmptyList

type ParamsF = {k :: Number, hf :: ChainNestingParams, txSize :: Number, limitN1Ratio :: Maybe Number}

pToPF :: Params -> ParamsF
pToPF p = {k: head p.ks, hf: head p.hfs, txSize: p.txSize, limitN1Ratio: p.limitN1Ratio}

showableParams :: Params -> ParamsL Array
showableParams p = {ks: NEL.toUnfoldable p.ks, hfs: NEL.toUnfoldable p.hfs, txSize: p.txSize, limitN1Ratio: p.limitN1Ratio}

-- instance showParams :: Show Params where
--   show {ks, hfs, txSize} = show {ks: NEL.toList ks, hfs: NEL.toList hfs, txSize}

mkSimplePs :: Number -> ChainNestingParams -> Number -> Params
mkSimplePs k hf txSize = {ks: singleton k, hfs: singleton hf, txSize, limitN1Ratio: Nothing}

mkNestedPs :: Number -> ChainNestingParams -> ChainNestingParams -> Number -> Params
mkNestedPs k hf hf2 txSize = {ks: singleton k, hfs: hf `NEL.cons` singleton hf2, txSize, limitN1Ratio: Nothing}

type UtVariants a
  = { pors :: a
    , ports :: a
    , hopors :: a
    , hoports :: a
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
    , sigmaTts :: Number
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
    , tradPolkadot :: ChainStats
    , ut :: UtVariants ChainStats
    , ps :: Params
    }


-- | Return a set of parameters sutiable to use for the next nesting level
paramsForNextNS :: Params -> Params
paramsForNextNS ps@{txSize} = {ks, hfs, txSize, limitN1Ratio: Nothing}
  where
    -- Take the tale of the list, or if that is empty, use the existing list as default (which must only have 1 entry)
    ks = tail ps.ks |> fromList |> fromMaybe ps.ks
    hfs = tail ps.hfs |> fromList |> fromMaybe ps.hfs

tradInitNS :: Params -> NestingStats
tradInitNS ps = {n: 1.0, t: t, tps: t / ps.txSize, p: pToPF ps}
  where t = head ps.ks

type NestingCap = {maxN :: Maybe Number}

calcNextNestingLevel' :: NestingCap -> Params -> NestingStats -> NestingStats
calcNextNestingLevel' {maxN} ps nsPrev = {n, t, tps, p: pToPF ps}
  where
    limitN = fromMaybe (\x -> x) $ min <$> maxN
    n = limitN $ nsPrev.t / bfbh
    t = n * k
    tps = t / ps.txSize
    h = head ps.hfs
    bfbh = h.bf * h.bh
    k = head ps.ks

calcNextNestingLevel :: Params -> NestingStats -> NestingStats
calcNextNestingLevel = calcNextNestingLevel' {maxN: Nothing}

data TradVar = Trad | TradEth2 | TradPolkadot

committeeUpdatePerBlock = 8192.0 / 32.0

-- eth2EffBh bh = floor $ committeeUpdatePerBlock + bh
-- counting committee updates doesn't matter so don't bother
eth2EffBh bh = bh

-- note: committeeUpdatePerBlock is not needed for Dh (but is needed for light clients of the beacon chain)

eth2AttestationSize = 256.0

-- eth2EffDh dh = dh + eth2AttestationSize
-- Don't count attestation size (except 32 B) b/c it's sorta a constant overhead and I don't count it for polkadot so w/e
eth2EffDh dh = dh + 32.0

polkadotEffDh _ = 819.0  -- via polkadot.js block.extrinsics[1].method.args[0].backedCandidates[0].encodedLength; seems constant, but not every paraId included every block -- https://github.com/AmarooHQ/polkadot-effective-dh/blob/master/main.js

tradChainCalc' :: Params -> TradVar -> ChainStats
tradChainCalc' ps var = {d1, d2, d3, confRate, deltaBigS, deltaSmallS, tts, sigmaTts, effBh, effDh, kTx: k, k1: k, kB: 0.0, porBytes: 0.0, porBytes2: 0.0}
  where
    d1 = {n: 1.0, t: k, tps: k / ps.txSize, p: pToPF ps}
    k = head ps.ks
    hf = head ps.hfs
    ps2 = paramsForNextNS ps
    hf2 = head ps2.hfs
    ps3 = paramsForNextNS ps2
    bhMod = case var of
      TradEth2 -> eth2EffBh
      _ -> identity
    dhMod = case var of
      TradEth2 -> eth2EffDh
      TradPolkadot -> polkadotEffDh
      _ -> identity
    effBh = bhMod hf.bh
    effDh = dhMod hf2.bh
    d2Calc = case var of
      TradEth2 -> calcNextNestingLevel' {maxN: Just 1024.0}
      _ -> calcNextNestingLevel
    d2 = d2Calc (ps2 { hfs = singleton {bf: hf2.bf, bh: effDh} }) d1
    d3 = calcNextNestingLevel ps3 d2
    deltaBigS = k
    deltaSmallS = k
    tts = ((deltaSmallS * 5.0 * 365.25) / 10_000_000.0)
    sigmaTts = tts
    confRate = hf.bf

tradChainCalc :: Params -> ChainStats
tradChainCalc ps = tradChainCalc' ps Trad

tradChainCalcEth2 :: Params -> ChainStats
tradChainCalcEth2 ps = tradChainCalc' ps TradEth2

tradChainCalcPolkadot :: Params -> ChainStats
tradChainCalcPolkadot ps = tradChainCalc' ps TradPolkadot

vcBranchingF ∷ Number
vcBranchingF = 256.0
-- vcBranchingF = 64.0

vcCommitSize ∷ Number
vcCommitSize = 32.0
-- vcCommitSize = 48.0

-- | estimate PoR len via average depth in a verkle tree
porVCLen2 ∷ Number → Number
porVCLen2 n = if n <= vcBranchingF
    then 1.0
    else if l2Groups > vcBranchingF
      then 1.0 + porVCLen2 (n / vcBranchingF)
      else avgDepth
  where
    l2Groups = floor $ n / vcBranchingF
    l1Nodes = (min n vcBranchingF) - l2Groups
    l2Nodes = n - l1Nodes
    avgDepth = (1.0 * l1Nodes + 2.0 * l2Nodes) / n

-- ethereum numbers add 0.66 to branch length (I think to account for sparseness)
-- and we use the average not the ceil
vcSparseExtra ∷ Number
-- vcSparseExtra = 0.66
vcSparseExtra = 0.0

porVCLen :: Number -> Number
porVCLen n = max 1.0 $ (log n / log vcBranchingF + vcSparseExtra)

-- | Length (in bytes) of a merkle proof
-- | deprecated in favor of porVCLen2
porMPLen :: Number -> Number
porMPLen = log2c

porLen ∷ Number → Number → Number
porLen g n = min (g * porMPLen n) (vcCommitSize * porVCLen2 n)

utPorsT1 :: Number -> Number -> Number -> Number -> Number -> Number
utPorsT1 n1 k1 bf bh g = n1 * (k1 - bf * n1 * (bh + porLen g n1))

utHOPorsT1 :: Number -> Number -> Number -> _ -> Number -> Number
utHOPorsT1 n1 k1 bf _ g = n1 * (k1 - bf * n1 * (g + porLen g n1))

type LoopFindMax = {i :: Int, t :: Number}

loopFindMaxPoRsN1F :: _ -> Params -> Number -> LoopFindMax -> LoopFindMax
loopFindMaxPoRsN1F utT1F ps g initM = inner ({i: initM.i, t: initM.t, bestI: initM.i }) |> \{bestI,t} -> {i: bestI,t}
  where
    -- drop this condition:  i >= wontBeMoreThan ||
    inner m@{i, t} = if t1 < 0.0 || t1 < t * 0.96 || (t1 < t && (abs $ log2 bestN) % 1.0 > 0.01)
        then m
        else inner (
          if t1 > t
            then {i: i + 1, bestI: i, t: t1}
            else {i: i + 1, bestI: m.bestI, t: m.t})
      where
        bestN = toNumber m.bestI
        n = toNumber i
        t1 = utPorsT1Applied n
    -- nRange = A.range 1 wontBeMoreThan <#> I.toNumber
    utPorsT1Applied n1 = utT1F n1 k1 bf bh g
    k1 = head ps.ks
    bf = hf.bf
    bh = hf.bh
    hf = head ps.hfs
    -- wontBeMoreThan = I.ceil $ k1 / bf / bh  -- N1 without explicit PoRs * 2.0
    -- from WP, useful for some things.
    -- | \frac{\d{T_1}}{\d{N_1}}
    utPorsDT1byDN1 n1 = (k1 * ln2 - bf * n1 * (g + bh * log 4.0) - 2.0 * bf * g * n1 * log n1) / ln2

findMaxPoRsN1 :: Params -> Number -> Number
findMaxPoRsN1 ps g = (loopFindMaxPoRsN1F utPorsT1 ps g {i: 1, t: 0.0}).i |> toNumber >>> M.floor

findMaxHOPoRsN1 :: Params -> Number -> Number
findMaxHOPoRsN1 ps g = (loopFindMaxPoRsN1F utHOPorsT1 ps g {i: 1, t: 0.0}).i |> toNumber >>> M.floor

-- | This will *efficiently* calculate the best N_1s for some array of parameters, provided N_1 will monotonically increase (which it does for increasing k).
-- | utT1F should be a function that returns T_1 for given parameters
findMaxPoRsN1ForRanges' :: _ -> {g :: Number, r :: Array Params} -> Array (Tuple Params LoopFindMax)
findMaxPoRsN1ForRanges' utT1F {g, r} = (inner {last: Nothing, next: A.head r, rest: A.tail r, outs: []}).outs
  where
    -- init condition
    inner {last: Nothing, next: Just ps, rest: Just rLeft, outs} =
        inner {last: Just res, next: A.head rLeft, rest: A.tail rLeft, outs: outs <> [Tuple ps res]}
      where
        res = loopFindMaxPoRsN1F utT1F ps g {i: 1, t: 0.0}
    inner {last: Just l, next: Just ps, rest, outs} =
        if res.t < l.t
          then unsafeThrowException $ error $ "findMaxPoRsN1ForRanges assumes that the output (n) will always increase as the input params are iterated over. but curr.t < last.t! " <> show {curr: res, last: l}
          else inner {last: Just res, next: A.head =<< rest, rest: A.tail =<< rest, outs: outs <> [Tuple ps res]}
      where
        res = loopFindMaxPoRsN1F utT1F ps g {i: newStartI, t: newStartT}
        newStartI = max 1 l.i
        newStartT = utT1F (toNumber newStartI - 1.0) pf.k pf.hf.bf pf.hf.bh g
        pf = pToPF ps
    inner endState = endState

findMaxPoRsN1ForRanges :: {g :: Number, r :: Array Params} -> Array (Tuple Params LoopFindMax)
findMaxPoRsN1ForRanges = findMaxPoRsN1ForRanges' utPorsT1

findMaxHOPoRsN1ForRanges :: {g :: Number, r :: Array Params} -> Array (Tuple Params LoopFindMax)
findMaxHOPoRsN1ForRanges = findMaxPoRsN1ForRanges' utHOPorsT1

applyTDiscountToBH :: Number -> Number
applyTDiscountToBH bh = (bh - _) $ ceil $ (1.0 + prel {f: 80.0, t: 112.0, v: bh}) * 16.0

type UtParams = {explicitPoRs :: Boolean, headerOmission :: Boolean, hashTruncation :: Boolean}

utChainCalc :: Params -> UtParams -> ChainStats
utChainCalc ps varParams@{explicitPoRs, headerOmission, hashTruncation} =
    if explicitPoRs && headerOmission
      then utCalcHOPoRs ps {hashTruncation}
      else utCalcMonolithic ps varParams

utCalcMonolithic :: Params -> UtParams -> ChainStats
utCalcMonolithic ps varParams@{explicitPoRs, headerOmission, hashTruncation} =
    {d1, d2, d3, confRate, tts, sigmaTts, deltaBigS, deltaSmallS, porBytes, porBytes2, effBh, effDh, kTx, kB, k1}
  where
    _assertNoHOPoRs = if not (explicitPoRs && headerOmission) then unit else unsafePerformEffect $ throwException $ error $ "this function should never recieve (explicitPoRs && headerOmission)"
    hashSize = if hashTruncation then 16.0 else 32.0
    origBh = (head ps.hfs).bh
    -- ~~if bh<96 (1/2 way between 80 and 112) then only discount 1 hash, otherwise 2~~
    -- discount between 1 and two hashes worth depending on bh (inverse linear interpolate)
    htModBh bh = if hashTruncation then applyTDiscountToBH bh else bh
    fixBH1 r@{bh} = r {bh = (if headerOmission then hashSize else htModBh bh)}
    fixBH2 r@{bh} = r {bh = htModBh bh}
    -- we have to modify the header size based on optimizations, but we don't want to pass
    --    this to other levels of nesting, so we'll make params for each nesting level.
    ps1 = ps {hfs = (fixBH1 (head ps.hfs) `cons'` tail ps.hfs)}
    hf = (head ps1.hfs)
    bfbh = hf.bf * hf.bh
    k1 = head ps1.ks
    n1Raw = if explicitPoRs then findMaxPoRsN1 ps1 hashSize else (k1 / 2.0 / bfbh)
    n1 = n1Raw * (fromMaybe 1.0 ps1.limitN1Ratio)
    confRate = hf.bf * n1
    porBytes = porLen hashSize n1
    -- if we are using headerOmission -> then we need to download headers + PoRs
    -- else if we are doingExplicitPoRs but otherwise the hash is fine (which is the last element in the branch, anyway)
    explicitPorsK = confRate * porBytes
    explicitHeadersK = confRate * htModBh origBh
    kB = (if explicitPoRs then explicitPorsK else 0.0) + (if headerOmission then confRate * hashSize else explicitHeadersK)
    kTx = k1 - kB
    -- kTx refactored so that everything depends on N1
    kTxOld = if explicitPoRs then (k1 - explicitPorsK - explicitHeadersK) else (k1 - confRate * hf.bh)
    _asdf = if abs (kTx - kTxOld) < 1.0 then unit else unsafePerformEffect $ throwException $ error $ intercalate "\n-- " ["kTx != kTxOld:", show {kTx, kTxOld, n1, n1Raw, explicitPorsK, explicitHeadersK, confRate, porBytes}, "limitN1Ratio: " <> show ps.limitN1Ratio, "Variant Ps: " <> show varParams, "Params: " <> show ps]
    t1 = kTx * n1
    d1 = {n: n1, t: t1, tps: t1 / ps.txSize, p: pToPF ps1}
    effBh = if explicitPoRs then d1.p.hf.bh + porBytes else d1.p.hf.bh
    -- NB: we want to re-adjust *unaltered params `ps` not `ps1` which we use for d1
    ps2Pre = paramsForNextNS ps -- trim param-depth lists
    ps2 = ps2Pre {hfs = (fixBH2 (head ps2Pre.hfs) `cons'` tail ps2Pre.hfs)}
    ps3 = paramsForNextNS $ ps2Pre
    deltaBigS = n1 * k1 -- wp says: "The amount of network bandwidth, $\Delta S$, required to download all blocks (as they are produced) across all simplex-chains is"
    deltaSmallS = if explicitPoRs then k1 else k1 + explicitPorsK + (if headerOmission then explicitHeadersK else 0.0)  -- TODO: write up in WP
    tts = ((5.0 * 365.25) * deltaSmallS / 10_000_000.0)
    sigmaTts = ((5.0 * 365.25) * deltaBigS / 10_000_000.0)
    d2 = calcNextNestingLevel ps2 d1
    porBytes2 = porLen hashSize (d2.n / n1)
    effDh = d2.p.hf.bh  -- Note: don't take into account porBytes2 -- if explicitPoRs then d2.p.hf.bh + porBytes2 else d2.p.hf.bh
    d3 = calcNextNestingLevel ps3 d2

utCalcHOPoRs :: Params -> {hashTruncation :: Boolean} -> ChainStats
utCalcHOPoRs ps {hashTruncation} = {d1, d2, d3, confRate, tts, sigmaTts, deltaBigS, deltaSmallS, porBytes, porBytes2, effBh, effDh, kTx, kB, k1}
  where
    hashSize = if hashTruncation then 16.0 else 32.0
    origBh = (head ps.hfs).bh
    htModBh bh = if hashTruncation then applyTDiscountToBH bh else bh
    fixBH2 r@{bh} = r {bh = htModBh bh}
    ps1 = ps -- {hfs = (fixBH1 (head ps.hfs) `cons'` tail ps.hfs)}
    -- limit N1 if specified
    n1 = (fromMaybe 1.0 ps1.limitN1Ratio) * findMaxHOPoRsN1 ps1 hashSize
    porBytes = porLen hashSize n1
    -- since we're omitting headers, we need to include the header's hash still if using VCs
    effBh = hashSize + porBytes
    k1 = head ps1.ks
    hf = (head ps1.hfs)
    confRate = hf.bf * n1
    explicitHOPorsK = confRate * effBh
    kTx = k1 - explicitHOPorsK
    kB = k1 - kTx
    t1 = kTx * n1
    d1 = {n: n1, t: t1, tps: t1 / ps.txSize, p: pToPF ps1}

    explicitHeadersK = confRate * htModBh origBh

    -- NB: we want to re-adjust *unaltered params `ps` not `ps1` which we use for d1
    ps2Pre = paramsForNextNS ps -- trim param-depth lists
    ps2 = ps2Pre {hfs = (fixBH2 (head ps2Pre.hfs) `cons'` tail ps2Pre.hfs)}
    ps3 = paramsForNextNS $ ps2Pre
    deltaBigS = n1 * k1 -- wp says: "The amount of network bandwidth, $\Delta S$, required to download all blocks (as they are produced) across all simplex-chains is"
    deltaSmallS = k1 + explicitHeadersK
    tts = ((5.0 * 365.25) * deltaSmallS / 10_000_000.0)
    sigmaTts = ((5.0 * 365.25) * deltaBigS / 10_000_000.0)
    d2 = calcNextNestingLevel ps2 d1
    porBytes2 = porLen hashSize (d2.n / n1)
    effDh = d2.p.hf.bh  -- Note: don't take into account porBytes2 -- if explicitPoRs then d2.p.hf.bh + porBytes2 else d2.p.hf.bh
    d3 = calcNextNestingLevel ps3 d2

allUtChainCalcsF :: forall a. (UtOptimizations -> a) -> UtVariants a
allUtChainCalcsF f =
  { pors: f {explicitPoRs: true, headerOmission: false, hashTruncation: false}
  , ports: f {explicitPoRs: true, headerOmission: false, hashTruncation: true}
  , hopors: f {explicitPoRs: true, headerOmission: true, hashTruncation: false}
  , hoports: f {explicitPoRs: true, headerOmission: true, hashTruncation: true}
  , std: f {explicitPoRs: false, headerOmission: false, hashTruncation: false}
  , t: f {explicitPoRs: false, headerOmission: false, hashTruncation: true}
  , ho: f {explicitPoRs: false, headerOmission: true, hashTruncation: false}
  , hot: f {explicitPoRs: false, headerOmission: true, hashTruncation: true}
  }


allUtChainCalcs :: Params -> UtVariants ChainStats
allUtChainCalcs ps = allUtChainCalcsF (utChainCalc ps)


runChainCalcFor :: Params -> ChainComplexities
runChainCalcFor ps = {trad, ut, ps, tradEth2, tradPolkadot}
  where
    trad = tradChainCalc ps
    tradEth2 = tradChainCalcEth2 ps
    tradPolkadot = tradChainCalcPolkadot ps
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
