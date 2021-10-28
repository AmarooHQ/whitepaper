module Amaroo.WP.Tables where

import Amaroo.WP.Tables.Types
import Prel

import Amaroo.WP.Calcs (Params, UtVariants, ChainStats, allUtChainCalcs, allUtChainCalcsF, applyTDiscountToBH, auxStats, mkNestedPs, mkSimplePs, pToPF, runChainCalcFor, tradChainCalc, tradChainCalcEth2, tradChainCalcPolkadot, utChainCalc)
import Amaroo.WP.Formatter (fdPlain, fdPlainMixed, fdPlainZero, fdStd, fdStdMixed, fdStdNoSiMixed, fdStdTwo, fdStdZero, fmt1GbpsPs, fmtDyn, fmtPsKBfBh, fmtPsKBfBhDh, wrap, wrapXml, wrapXmlWAttr)
import Amaroo.WP.Tables.Booktabs (renderBooktabs)
import Amaroo.WP.Tables.Types (LatexTablePos(..), TPositioning(..))
import Amaroo.WP.Utils (diagonalApply, ui)
import Data.Array (drop, filter, intercalate, take)
import Data.Array as A
import Data.Int (decimal, toNumber)
import Data.Int (toStringAs) as I
import Data.Maybe (Maybe(..), fromJust, fromMaybe, isJust)
import Data.Number (infinity, nan)
import Data.String (Pattern(..), Replacement(..), length, replaceAll)
import Data.String.Utils as S
import Data.Traversable (sequence)
import Effect.Exception (error)
import Effect.Exception.Unsafe (unsafeThrowException)
import Math (pow)
import Partial.Unsafe (unsafePartial)

{-|

# Tables for UT WP (and Amaroo WPs in general)

## Notes on props relevant to scalability of various chains

### Polkadot:

* header size: 288 bytes (via polkadot.js rpc)
* block time: 6s

https://telemetry.polkadot.io/#/Polkadot

also I made a little `npm init && npm i -S polkadot.js` project to get the header size (which is pretty easy; polkadot.js seems good -- I've seen way worse)

### Eth 2:

* header size: 192 bytes (mb 224?) (via lighthouse beaconchain node http API)
* 12s block times (inferred b/c there seems to be a very regular 5 blocks/min pattern; couldn't find a source as easily)

* update note: every 10th block (200B) + 8192 / 10

### Cardano:

* header size: 1070 B -- via https://liberlion.medium.com/what-you-should-know-about-cardano-part-1-8c59ebbace49 -- note: secondary source and doesn't provide citation
* 20s block time -- inferred via ~4250 blocks per day -> v close to 20s block time; data from: https://messari.io/asset/cardano/charts/network-activity/blocks

### Solana:

NB: out of date, see bandwidth_to_k_solana

* ~~header size: 64 + 1 + (8+8+8+8) + 32 + 4 + 8 = 141 -> 144 bytes after padding~~
* ~~block time about 550ms atm (31/8/21) via https://explorer.solana.com/ -- this source says 600ms https://forkast.news/what-is-solana-why-hottest-blockchain/~~

~~https://docs.rs/solana/0.16.6/src/solana/packet.rs.html#341 (the linked line is an incremental construction of the header layout)~~

~~also WTF re their hardware requirements!? https://youtu.be/6HHHYtPPUaA?t=421 !!! J.C.
https://web.archive.org/web/20210831185445/https://docs.solana.com/running-validator/validator-reqs~~

~~also good on their validators getting access to zen3 threadrippers only weeks after specifications were *leaked*. :/ (the author meant 3000 series threadrippers which are zen2)~~

~~how solana makes sure the validator base is decentralized enough :/ <https://twitter.com/aeyakovenko/status/1315689754743107584>~~

-}

confRateTex = "\\mathbb{C}^\\prime"

sigmaTps :: Maybe Int -> String
sigmaTps (Just n) = "$\\Sigma\\;\\text{TPS}_{" <> show n <> "}$"
sigmaTps Nothing = "$\\Sigma\\;\\text{TPS}$"

confRateTh = wrap "$" confRateTex <> " (Hz)"

data UtName = PoRs Int | PoRTs Int | HOPoRs Int | HOPoRTs Int | Std Int | T Int | HO Int | HOT Int | Aleph UtName

derive instance eqUtName :: Eq UtName

utBaseN :: String -> String
utBaseN inner = "\\UT{" <> inner <> "}"

utAlephN :: String -> String
utAlephN inner = "\\UTinf{" <> inner <> "}"

iToS = I.toStringAs decimal

sToExt s = if length s > 0 then "+\\text{" <> s <> "}" else "+\\emptyset"

utNameInner f i e = f $ (if i <= 0 then "" else iToS i) <> sToExt e

utNameI :: UtName -> Int
utNameI (PoRs i) = i
utNameI (PoRTs i) = i
utNameI (HOPoRs i) = i
utNameI (HOPoRTs i) = i
utNameI (Std i) = i
utNameI (T i) = i
utNameI (HO i) = i
utNameI (HOT i) = i
utNameI (Aleph n) = utNameI n

utNameE :: UtName -> String
utNameE (PoRs _) = "PoRs"
utNameE (PoRTs _) = "PoRTs"
utNameE (HOPoRs _) = "HOPoRs"
utNameE (HOPoRTs _) = "HOPoRTs"
utNameE (Std _) = "OP"
utNameE (T _) = "OPT"
utNameE (HO _) = "HO"
utNameE (HOT _) = "HOT"
utNameE (Aleph n) = utNameE n

utName :: UtName -> String
utName (Aleph n) = utNameInner utAlephN (utNameI n) (utNameE n)
utName s = utNameInner utBaseN (utNameI s) (utNameE s)

utName_ = wrap "$" <<< utName

utNames :: Array UtName -> Array String
utNames = map utName_

ut1TpsToK tps txSize bf bh = pow (tps * txSize * 4.0 * bf * bh) 0.5
ut2TpsToK tps txSize bf bh dh = pow (tps * txSize * 4.0 * bf * bf * bh * dh) (1.0 / 3.0)
oc2TpsToK tps txSize bf bh = pow (tps * txSize * bf * bh) 0.5

_1M = 1_000_000.0

_BTC_BH = 80.0
_BTC_1M_K = 250000000.0

_CARDANO_BH :: Number
_CARDANO_BH = 1070.0
_CARDANO_1M_K = _BTC_1M_K

_ETH2_BF = btToF 12
_ETH2_BH = 200.0
_ETH2_DH = 280.0
-- _ETH2_1M_K = 105_700.0
_ETH2_1M_K = 244_200.0

_POLKADOT_BF = btToF 6
_POLKADOT_BH = 288.0
_POLKADOT_DH = 288.0
-- _POLKADOT_1M_K = 109_810.0
_POLKADOT_1M_K = 184_800.0

_UT_BF = 1.0 / 15.0
_UT_BH = 84.0
_UT_BH_FOR_SHARDING = applyTDiscountToBH _UT_BH
_UT_HF = {bh: _UT_BH, bf: _UT_BF}

_UT1PORS_1M_K = 177000.0  -- manual binary search
_UT1PORTS_1M_K = 131250.0  -- manual binary search
_UT1HOPORS_1M_K = 160_000.0  -- manual search
_UT1HOPORTS_1M_K = 113_500.0  -- manual search
_UT1_1M_K = ut1TpsToK _1M 250.0 _UT_BF _UT_BH
_UT1T_1M_K = ut1TpsToK _1M 250.0 _UT_BF _UT_BH_FOR_SHARDING
_UT1HO_1M_K = ut1TpsToK _1M 250.0 _UT_BF 32.0
_UT1HOT_1M_K = ut1TpsToK _1M 250.0 _UT_BF 16.0

_UT2PORS_1M_K = 4870.0  -- manual binary search
_UT2PORTS_1M_K = 3790.0  -- manual binary search
_UT2HOPORS_1M_K = 4400.0  -- manual search
_UT2HOPORTS_1M_K = 3450.0  -- manual search
_UT2_1M_K = ut2TpsToK _1M 250.0 _UT_BF _UT_BH _UT_BH
_UT2T_1M_K = ut2TpsToK _1M 250.0 _UT_BF _UT_BH_FOR_SHARDING _UT_BH_FOR_SHARDING
_UT2HO_1M_K = ut2TpsToK _1M 250.0 _UT_BF 32.0 _UT_BH
_UT2HOT_1M_K = ut2TpsToK _1M 250.0 _UT_BF 16.0 _UT_BH_FOR_SHARDING

_OPT_SHARD_1M_K = oc2TpsToK _1M 250.0 _UT_BF _UT_BH_FOR_SHARDING


_UT_INIT_CONFIG = mkSimplePs 3000.0 _UT_HF 250.0

_COMPARE_20K = 20_000.0

utComplexityParams :: Array Params
utComplexityParams = do
      k <- [3000.0, _COMPARE_20K]
      bf <- [1.0 / 7.5, 1.0 / 15.0, 1.0 / 30.0, 1.0 / 60.0]
      bh <- [112.0, 84.0]
      txSize <- [250.0]
      pure $ mkSimplePs k {bf, bh} txSize
    <> [ mkSimplePs _POLKADOT_1M_K {bf: btToF 15, bh: 84.0} 250.0
       , mkSimplePs _ETH2_1M_K {bf: btToF 15, bh: 84.0} 250.0 ]

utComplexityData = runChainCalcFor <$> utComplexityParams

btToF :: Int -> Number
btToF t = 1.0 / (toNumber t)

data Network = Bitcoin | Cardano | Eth2 | Polkadot | OptShard | UT UtName

derive instance eqNetwork :: Eq Network

instance showNetwork :: Show Network where
  show Bitcoin = "Bitcoin"
  show Cardano = "Cardano"
  show Eth2 = "Eth2"
  show Polkadot = "Polkadot"
  show OptShard = "Opt.Shard"
  show (UT ut) = utName_ ut

type UtVsOtherDesc = {net :: Network, p :: Number -> Params, oneMTps :: Maybe Number}

utVsOther :: Array UtVsOtherDesc
utVsOther =
    [ {net: Bitcoin, p: \k -> mkSimplePs k {bf: btToF 600, bh: 80.0} tx, oneMTps: Just _BTC_1M_K}
    , {net: Cardano, p: \k -> mkSimplePs k {bf: btToF 20, bh: _CARDANO_BH} tx, oneMTps: Just _CARDANO_1M_K}
    , {net: UT (PoRs 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1PORS_1M_K}
    , {net: UT (PoRTs 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1PORTS_1M_K}
    , {net: UT (HOPoRs 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1HOPORS_1M_K}
    , {net: UT (HOPoRTs 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1HOPORTS_1M_K}
    , {net: UT (Std 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1_1M_K}
    , {net: UT (T 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1T_1M_K}
    , {net: UT (HO 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1HO_1M_K}
    , {net: UT (HOT 1), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT1HOT_1M_K}
    , {net: UT (Aleph (HOT 1)), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Nothing}
    , {net: Polkadot, p: \k -> mkSimplePs k {bf: _POLKADOT_BF, bh: _POLKADOT_BH} tx, oneMTps: Just _POLKADOT_1M_K}
    , {net: Eth2, p: \k -> mkNestedPs k {bf: _ETH2_BF, bh: _ETH2_BH} {bf: _ETH2_BF, bh: _ETH2_DH} tx, oneMTps: Just _ETH2_1M_K}
    , {net: OptShard, p: \k -> mkSimplePs k {bf: _UT_BF, bh: _UT_BH_FOR_SHARDING} tx, oneMTps: Just _OPT_SHARD_1M_K}
    , {net: UT (PoRs 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2PORS_1M_K}
    , {net: UT (PoRTs 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2PORTS_1M_K}
    , {net: UT (HOPoRs 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2HOPORS_1M_K}
    , {net: UT (HOPoRTs 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2HOPORTS_1M_K}
    , {net: UT (Std 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2_1M_K}
    , {net: UT (T 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2T_1M_K}
    , {net: UT (HO 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2HO_1M_K}
    , {net: UT (HOT 2), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Just _UT2HOT_1M_K}
    , {net: UT (Aleph (HOT 2)), p: \k -> mkSimplePs k _UT_HF tx, oneMTps: Nothing}
    ]
  where
    tx = 250.0


filterUtVsOther :: Array Network -> Array UtVsOtherDesc
filterUtVsOther = filterRecsByNet utVsOther

filterRecsByNet :: forall (r ∷ Row Type) a. Eq a ⇒ Array { net ∷ a | r } → Array a → Array { net ∷ a | r }
filterRecsByNet recs nets = do
    n <- nets
    A.filter (\{net} -> net == n) recs

compareNetsFilterList :: Array Network
compareNetsFilterList = [Bitcoin, Cardano, UT (PoRTs 1), UT (HOPoRTs 1), UT (T 1), UT (HOT 1), Polkadot, Eth2, OptShard, UT (PoRTs 2), UT (HOPoRTs 2), UT (T 2), UT (HOT 2), UT (Aleph (HOT 2))]

filteredUtVsOther :: Array UtVsOtherDesc
filteredUtVsOther = filterUtVsOther compareNetsFilterList

id x = x

utNestingLvl :: UtName -> Int
utNestingLvl (PoRs i) = i
utNestingLvl (PoRTs i) = i
utNestingLvl (HOPoRs i) = i
utNestingLvl (HOPoRTs i) = i
utNestingLvl (Std i) = i
utNestingLvl (T i) = i
utNestingLvl (HO i) = i
utNestingLvl (HOT i) = i
utNestingLvl (Aleph other) = utNestingLvl other

netToChainStats :: Network -> Params -> ChainStats
netToChainStats (UT (PoRs _)) p = (utChainCalc p (allUtChainCalcsF id).pors)
netToChainStats (UT (PoRTs _)) p = (utChainCalc p (allUtChainCalcsF id).ports)
netToChainStats (UT (HOPoRs _)) p = (utChainCalc p (allUtChainCalcsF id).hopors)
netToChainStats (UT (HOPoRTs _)) p = (utChainCalc p (allUtChainCalcsF id).hoports)
netToChainStats (UT (Std _)) p = (utChainCalc p (allUtChainCalcsF id).std)
netToChainStats (UT (T _)) p = (utChainCalc p (allUtChainCalcsF id).t)
netToChainStats (UT (HO _)) p = (utChainCalc p (allUtChainCalcsF id).ho)
netToChainStats (UT (HOT _)) p = (utChainCalc p (allUtChainCalcsF id).hot)
netToChainStats (UT (Aleph v)) p = netToChainStats (UT v) p
netToChainStats Eth2 p = tradChainCalcEth2 p
netToChainStats Polkadot p = tradChainCalcPolkadot p
netToChainStats _ p = tradChainCalc p

netLookupChainStats :: Network -> UtVariants ChainStats -> ChainStats
netLookupChainStats (UT (PoRs _)) utvs = utvs.pors
netLookupChainStats (UT (PoRTs _)) utvs = utvs.ports
netLookupChainStats (UT (HOPoRs _)) utvs = utvs.hopors
netLookupChainStats (UT (HOPoRTs _)) utvs = utvs.hoports
netLookupChainStats (UT (Std _)) utvs = utvs.std
netLookupChainStats (UT (T _)) utvs = utvs.t
netLookupChainStats (UT (HO _)) utvs = utvs.ho
netLookupChainStats (UT (HOT _)) utvs = utvs.hot
netLookupChainStats (UT (Aleph v)) utvs = netLookupChainStats (UT v) utvs
netLookupChainStats net _ = unsafeThrowException $ error $ "[netLookupChainStats] non UT network provided: " <> show net

netToScalingFactor :: Network -> _ -> Number
netToScalingFactor Bitcoin aux = aux.scalingFactors.noNesting
netToScalingFactor Cardano aux = aux.scalingFactors.noNesting
netToScalingFactor Eth2 aux = aux.scalingFactors.nesting
netToScalingFactor Polkadot aux = aux.scalingFactors.nesting
netToScalingFactor OptShard aux = aux.scalingFactors.nesting
netToScalingFactor (UT ut) aux = case utNameI ut of
  1 -> aux.scalingFactors.noNesting
  2 -> aux.scalingFactors.nesting
  3 -> aux.scalingFactors.nesting
  _ -> unsafeThrowException $ error $ "[netToScalingFactor] got bad level of nesting in UT network: " <> utName_ ut

netToN2 :: Network -> ChainStats -> Number
netToN2 Bitcoin _ = nan
netToN2 Cardano _ = nan
netToN2 (UT ut) cs = if utNestingLvl ut >= 2 then cs.d2.n else nan
netToN2 _ cs = cs.d2.n

netToTps :: Network -> ChainStats -> Number
netToTps Bitcoin cd = cd.d1.tps
netToTps Cardano cd = cd.d1.tps
netToTps Eth2 cd = cd.d2.tps
netToTps Polkadot cd = cd.d2.tps
netToTps OptShard cd = cd.d2.tps
netToTps (UT ut) cd = case utNameI ut of
  1 -> cd.d1.tps
  2 -> cd.d2.tps
  3 -> cd.d3.tps
  _ -> unsafeThrowException $ error $ "[netToTps] got bad level of nesting in UT network: " <> utName_ ut

notPoRs :: Network -> Boolean
notPoRs (UT (PoRs _)) = false
notPoRs (UT (PoRTs _)) = false
notPoRs (UT (HOPoRs _)) = false
notPoRs (UT (HOPoRTs _)) = false
notPoRs _ = true

isAleph :: Network -> Boolean
isAleph (UT (Aleph _)) = true
isAleph _ = false

-- diagF1M :: Number -> Array _
-- diagF1M = filter (notPoRs <<< \e -> e.net) <<< utVsOther

-- utVsOther1MOld :: Array {net :: Network, p :: Params}
-- utVsOther1MOld = diagonalApply diagF1M ut1MCompareKs

utVsOther1M :: Array {net :: Network, p :: Params}
utVsOther1M = unsafePartial fromJust $ sequence $ calc1M <$> filter (\{oneMTps} -> isJust oneMTps) filteredUtVsOther
  where
    calc1M {net, p, oneMTps} = case oneMTps of
      Just k -> Just {net, p: p k}
      Nothing -> Nothing

utVsOther1MAll :: Array {net :: Network, p :: Params}
utVsOther1MAll = unsafePartial fromJust $ sequence $ calc1M <$> filter (\{oneMTps} -> isJust oneMTps) utVsOther
  where
    calc1M {net, p, oneMTps} = case oneMTps of
      Just k -> Just {net, p: p k}
      Nothing -> Nothing

-- Note: CBF -- it was only there b/c of solana's rediculous 700k tps claim anyway
-- utVsOther1Gbps :: Array {net :: Network, p :: Params}
-- utVsOther1Gbps =

repeatSafe :: Int -> String -> String
repeatSafe n s = S.repeat n s |> fromMaybe ""

mkSpacer :: Int -> String
mkSpacer n = repeatSafe (max n 3) "-"

getTps ns = ns.tps

genTpsRow utF cd = [fmtPsKBfBh $ pToPF cd.ps] <> (fmtDyn fdStdMixed <$> getTps <$> [cd.trad.d1, cd.trad.d2, (utF cd).d1, (utF cd).d2, (utF cd).d3])

tableTps :: Table
tableTps = Table
    (["$k$, $B_f$, $B_h$", "$O(c)$", "Sharded $O(c^2)$"] <> utNames [Std 1, Std 2, Std 3])  -- , sigmaTps 1, sigmaTps 2, sigmaTps 3]
    {md: mkSpacer <$> [6, 2, 5, 4, 4, 4], texTabular: "lrrrrr"}
    (genTpsRow (\cd -> cd.ut.std) <$> utComplexityData)

tableTpsHot :: Table
tableTpsHot = Table
    (["$k$, $B_f$, $B_h$", "$O(c)$", "Sharded $O(c^2)$"] <> utNames [HOT 1, HOT 2, HOT 3])
    {md: mkSpacer <$> [6, 2, 5, 4, 4, 4], texTabular: "lrrrrr"}
    (genTpsRow (\cd -> cd.ut.hot) <$> utComplexityData)

genDappChainsRow utF cd = [fmtPsKBfBh $ pToPF cd.ps] <> (fmtDyn fdStdMixed <$> [(utF cd).d1.n, (utF cd).d2.n, (utF cd).d3.n, (utF cd).deltaBigS]) <> [fmtDyn fdStd (utF cd).confRate]

dappChains :: Table
dappChains = Table
    ["$k$, $B_f$, $B_h$", "$N_1$", "$N_2$", "$N_3$", "$\\Delta S$ (B/s)", confRateTh]
    {md: mkSpacer <$> [6, 4, 5, 5, 5, 4], texTabular: "lrrrrr"}
    (genDappChainsRow (\cd -> cd.ut.std) <$> utComplexityData)

dappChainsHot :: Table
dappChainsHot = Table
    ["$k$, $B_f$, $B_h$", "$N_1$", "$N_2$", "$N_3$", "$\\Delta S$ (B/s)", confRateTh]
    {md: mkSpacer <$> [6, 4, 5, 5, 5, 4], texTabular: "lrrrrr"}
    (genDappChainsRow (\cd -> cd.ut.hot) <$> utComplexityData)

-- TODO: replace `fmtDyn fdPlain`
genPoRRow utF cd = [fmtPsKBfBh $ pToPF cd.ps] <> (fmtDyn fdStdMixed <$> [ut.d1.n, ut.d1.tps, ut.d2.n, ut.d2.tps, ut.porBytes]) <> [fmtDyn fdStd ut.confRate] -- <> (fmtDyn fdStdTwo <$> [ut.d1.n / ut.d1.p.k])
  where
    ut = utF cd

porTableSpacer = mkSpacer <$> [6, 2, 5, 4, 5, 3, 3] -- , 4]

porTpsHeader :: (Int -> UtName) -> _ -> Table
porTpsHeader utv = Table
    ["$k$, $B_f$, $B_h$", "$N_1$", (utName_ $ utv 1) <> " TPS", "$N_2$", (utName_ $ utv 2) <> " TPS", "PoR (B)", confRateTh] -- , "$\\nicefrac{N_1}{k}$"]
    {md: porTableSpacer, texTabular: "lrrrrrr"}

tpsPor :: Table
tpsPor = porTpsHeader PoRs (genPoRRow (\cd -> cd.ut.pors) <$> utComplexityData)

tpsPort :: Table
tpsPort = porTpsHeader PoRTs (genPoRRow (\cd -> cd.ut.ports) <$> utComplexityData)

-- todo: fix fmtDyn fdPlain
genCompareRow k o@{net} = [fmtPsKBfBh $ pToPF p, show net] <> (fmtDyn fdPlainMixed <$> [cs.effBh, cs.effDh]) <> ([fmtDyn fdStdZero scalingFactor, fmtDyn fdStdMixed n2]) <> (fmtDyn fdStdMixed <$> [tps])
  where
    p = o.p k
    cs = netToChainStats net p
    aux = auxStats cs
    -- n1 = if isAleph net then infinity else cs.d1.n
    tps = if isAleph net then infinity else netToTps net cs
    tpsPerBaseChain = netToTps net cs / cs.d1.n
    scalingFactor = netToScalingFactor net aux
    n2 = if isAleph net then infinity else netToN2 net cs

compareNetsTH = Table
    ["$k$, $B_f$, $B_h$", "Network", "E. $B_h$ (B)", "E. $D_h$ (B)", "Scale $\\times$"
    -- , "$\\nicefrac{\\Sigma\\;\\text{TPS}}{N_1}$"
    , "$N_2$"
    , "$\\Sigma$ TPS"] -- , "TPS vs " <> (utName_ $ Std 2)]
    {md: mkSpacer <$> [5, 6, 2, 2, 3, 4, 3], texTabular: "llrrrrr"}

compareNetsConciseTH = Table
    ["$k$, $B_f$, $B_h$", "Network", "Scale $\\times$"
    -- , "$\\nicefrac{\\Sigma\\;\\text{TPS}}{N_1}$"
    , "$N_2$"
    , "$\\Sigma$ TPS"] -- , "TPS vs " <> (utName_ $ Std 2)]
    {md: mkSpacer <$> [5, 6, 3, 4, 3], texTabular: "llrrr"}

compareNets3k :: Table
compareNets3k =
    compareNetsTH (genCompareRow 3_000.0 <$> filteredUtVsOther)

compareNets20k :: Table
compareNets20k =
    compareNetsTH (genCompareRow _COMPARE_20K <$> filteredUtVsOther)

makeCompareRowConcise [ps, net, _, _, scale, n2, tps] = [ps, net, scale, n2, tps]
makeCompareRowConcise _ = unsafeThrowException $ error "makeCompareRowConcise got wrong number of cols"


filterRows rows = rows

lpCompareNetworks :: Table
lpCompareNetworks = compareNetsConciseTH t
  where
    t = (makeCompareRowConcise <<< genCompareRow 3_000.0) <$> utVsOther
      -- append (A.filter (\{net} -> net == Bitcoin) rows)
      -- $ append (A.filter (\{net} -> net == UT (PoRTs 1)) rows)
      -- $ append (A.filter (\{net} -> net == Eth2) rows)
      -- $ append (A.filter (\{net} -> net == UT (Std 1)) rows)
      -- $ append (A.filter (\{net} -> net == UT (T 1)) rows)
      -- $ append (A.filter (\{net} -> net == OptShard) rows)
      -- $ append (A.filter (\{net} -> net == UT (HOT 1)) rows)
      -- $ append (A.filter (\{net} -> net == UT (PoRTs 2)) rows)
      -- $ append (A.filter (\{net} -> net == UT (T 2)) rows)
      -- $ (A.filter (\{net} -> net == UT (HOT 2)) rows)


-- todo: fix fmtDyn fdPlain
genCompare1MRow {net, p} = [fmtPsKBfBh $ pToPF p, show net] <> (fmtDyn fdStdMixed <$> [n2, netToTps net cs]) <> (fmtDyn fdStdMixed <$> [ut2.d2.tps]) -- , cs.k1 / ut2K])
  where
    ut2K = ut2TpsToK (netToTps net cs) p.txSize pf.hf.bf pf.hf.bh pf.hf.bh
    pf = pToPF p
    -- ut2 = utChainCalc p (allUtChainCalcsF id).t
    ut2 = netToChainStats (UT (T 2)) p
    cs = netToChainStats net p
    tpsPerN1 = netToTps net cs / cs.d1.n
    n2 = netToN2 net cs
    -- aux = auxStats cs

compareNets1mTps :: Table
compareNets1mTps = Table
    ["$k$, $B_f$, $B_h$", "Network"
    -- , "$\\nicefrac{\\Sigma\\;\\text{TPS}}{N_1}$"
    , "$N_2$"
    , "$\\Sigma$ TPS", "Equiv. " <> utName_ (T 2) <> " $\\Sigma$ TPS"] -- , "$k$ vs Equiv. $\\UT{2}$"]
    {md: mkSpacer <$> [5, 5, 3, 3, 3], texTabular: "llrrr"}
    (genCompare1MRow <$> utVsOther1M)

compareNets1mTpsAll :: Table
compareNets1mTpsAll = Table
    ["$k$, $B_f$, $B_h$", "Network"
    -- , "$\\nicefrac{\\Sigma\\;\\text{TPS}}{N_1}$"
    , "$N_2$"
    , "$\\Sigma$ TPS", "Equiv. " <> utName_ (T 2) <> " $\\Sigma$ TPS"] -- , "$k$ vs Equiv. $\\UT{2}$"]
    {md: mkSpacer <$> [5, 5, 3, 3, 3], texTabular: "llrrr"}
    (genCompare1MRow <$> utVsOther1MAll)


genCompare1GbpsRow {net, p} = [fmt1GbpsPs cs p, show net] <> (fmtDyn fdPlain <$> [netToTps net cs, k, mbChainDay])
  where
    mbChainDay = k * 86400.0 / 1024.0 / 1024.0
    k = (pToPF p).k
    cs = netToChainStats net p


-- compareNets1Gbps :: Table
-- compareNets1Gbps =
--     [ ["$\\Delta S$, $B_f$, $B_h$, Tx (B)", "Network", "TPS", "$k$ (B/s)", "MB/chain/day"]
--     , mkSpacer <$> [6, 3, 3, 3, 4]
--     ] <> (genCompare1GbpsRow <$> utVsOther1Gbps)

genCompareFlippedUtRow :: UtVariants ChainStats -> Array UtName -> {f :: ChainStats -> String, s :: String} -> Array String
genCompareFlippedUtRow ut utvs {f, s} = [s] <> (getProp <$> utvs)
  where
    getProp = f <<< (\n -> netLookupChainStats (UT n) ut)

genCompareUtRow :: UtVariants ChainStats -> Array {f :: ChainStats -> String, s :: String} -> UtName -> Array String
genCompareUtRow uts props v = [utName_ v] <> (propGens <@> (getCS v))
  where
    getCS n = netLookupChainStats (UT n) uts
    propGens = (\{f} -> f) <$> props

-- {s: "$\\Sigma$ TPS", f: \cs -> fmtDyn fdPlainZero cs.d1.tps}

type OProps = {s :: String, f :: (ChainStats -> String)}

optimizationProps1 :: Array OProps
optimizationProps1 =
  [ {s: "$N_1$", f: \cs -> fmtDyn fdStdMixed cs.d1.n}
  -- , {s: "$T_1$ (B/s)", f: \cs -> fmtDyn fdStdMixed cs.d1.t}
  , {s: "$\\Sigma\\;\\text{TPS}_{1}$", f: \cs -> fmtDyn fdStdMixed cs.d1.tps}
  , {s: "$N_2$", f: \cs -> fmtDyn fdStdMixed cs.d2.n}
  , {s: "$\\Sigma\\;\\text{TPS}_{2}$", f: \cs -> fmtDyn fdStdMixed cs.d2.tps}
  -- , {s: "$T_2$ (B/s)", f: \cs -> fmtDyn fdStdMixed cs.d2.t}
  -- , {s: "$T_3$ (B/s)", f: \cs -> fmtDyn fdPlainZero cs.d3.t}
  -- , {s: "$N_3$", f: \cs -> fmtDyn fdPlainZero cs.d3.n}
  , {s: confRateTh, f: \cs -> fmtDyn fdPlain cs.confRate}
  , {s: "E. $B_h$ (B)", f: \cs -> fmtDyn fdPlainZero cs.effBh}
  -- , {s: "E. $D_h$ (B)", f: \cs -> fmtDyn fdPlainZero cs.effDh}
  , {s: "PoR (B)", f: \cs -> fmtDyn fdPlainZero cs.porBytes}
  ]

optimizationProps2 :: Array OProps
optimizationProps2 =
  [ {s: "$\\Delta s$ (B/s)", f: \cs -> fmtDyn fdStdZero cs.deltaSmallS}
  , {s: "$\\text{TTS}_{5yrs}$ (days)", f: \cs -> fmtDyn fdStdTwo cs.tts}
  , {s: "Chain-GB/yr", f: \cs -> fmtDyn fdStdTwo (cs.deltaSmallS * 86400.0 * 365.25 / 1024.0 / 1024.0 / 1024.0)}
  , {s: "$\\Delta S$ (B/s)", f: \cs -> fmtDyn fdStdMixed cs.deltaBigS}
  , {s: "$\\Sigma$ $\\text{TTS}_{5yrs}$ (days)", f: \cs -> fmtDyn fdStdTwo cs.sigmaTts}
  -- , {s: "$\\nicefrac{\\Sigma\\;\\text{TPS}}{\\Delta s}$ (Tx/B)", f: \cs -> fmtDyn fdStdTwo (cs.d1.tps / cs.deltaSmallS)}
  -- , {s: "Scale $\\times$", f: \cs -> fmtDyn fdStd (auxStats cs).scalingFactors.nesting}
  ]

allOptimizationProps = optimizationProps1 <> optimizationProps2

compareUtOptimizationsFlipped :: Table
compareUtOptimizationsFlipped = Table
    ([""] <> utNames variants)
    {md: mkSpacer <$> [7, 4, 5, 3, 4, 4, 4], texTabular: repeatSafe 7 "l"}
    (genCompareFlippedUtRow ut variants <$> allOptimizationProps)
  where
    ut = allUtChainCalcs _UT_INIT_CONFIG
    variants = [PoRs 1, PoRTs 1, HOPoRs 1, HOPoRTs 1, Std 1, T 1, HO 1, HOT 1]

compareUtOptimizations :: Table
compareUtOptimizations = Table
    ([""] <> (oProps <#> (\{s} -> s)))
    {md: mkSpacer <$> A.replicate (l+1) 3, texTabular: "l" <> repeatSafe l "r"}
    (genCompareUtRow ut oProps <$> variants)
  where
    ut = allUtChainCalcs _UT_INIT_CONFIG
    variants = [PoRs 0, PoRTs 0, HOPoRs 0, HOPoRTs 0, Std 0, T 0, HO 0, HOT 0]
    oProps = optimizationProps1
    l = A.length oProps

compareUtOptimizations2 :: Table
compareUtOptimizations2 = Table
    ([""] <> (oProps <#> (\{s} -> s)))
    {md: mkSpacer <$> A.replicate 6 3, texTabular: "l" <> repeatSafe 5 "r"}
    (genCompareUtRow ut oProps <$> variants)
  where
    ut = allUtChainCalcs _UT_INIT_CONFIG
    variants = [PoRs 0, PoRTs 0, HOPoRs 0, HOPoRTs 0, Std 0, T 0, HO 0, HOT 0]
    oProps = optimizationProps2


mkCompareUtOptimizations :: Array OProps -> Table
mkCompareUtOptimizations oProps = Table
    ([""] <> (oProps <#> (\{s} -> s)))
    {md: mkSpacer <$> A.replicate 6 3, texTabular: "l" <> repeatSafe 5 "r"}
    (genCompareUtRow ut oProps <$> variants)
  where
    ut = allUtChainCalcs _UT_INIT_CONFIG
    variants = [PoRs 0, PoRTs 0, HOPoRs 0, HOPoRTs 0, Std 0, T 0, HO 0, HOT 0]

_fmtStd = fmtDyn fdStdMixed

lpCompareUtOptimizations1 :: Table
lpCompareUtOptimizations1 = mkCompareUtOptimizations
    [ {s: "$\\Sigma\\;\\text{TPS}_{1}$ (tx/s)", f: \cs -> _fmtStd cs.d1.tps}
    , {s: "$N_1$ (chains)", f: \cs -> _fmtStd cs.d1.n}
    , {s: confRateTh, f: \cs -> fmtDyn fdStd cs.confRate}
    , {s: "$\\Sigma\\;\\text{TPS}_{2}$ (tx/s)", f: \cs -> _fmtStd cs.d2.tps}
    , {s: "$N_2$ (chains)", f: \cs -> _fmtStd cs.d2.n}
    ]

genLpCompareRow k o@{net} = [fmtPsKBfBh $ pToPF p, show net] <> (fmtDyn fdStdMixed <$> [effBh, tps])
  where
    p = o.p k
    cs = netToChainStats net p
    effBh = case net of
      Eth2 -> cs.effDh
      OptShard -> cs.effDh
      _ -> cs.effBh
    tps = if isAleph net then infinity else netToTps net cs

genLpCompare2Row k o@{net} = [fmtPsKBfBh $ pToPF p, show net] <> (fmtDyn fdStdNoSiMixed <$> [cs.effBh, cs.effDh, tps])
  where
    p = o.p k
    cs = netToChainStats net p
    tps = if isAleph net then infinity else netToTps net cs

lpCompareTH = Table
    ["$k$, $B_f$, $B_h$", "Network", "E. $B_h$ (B)", "$\\Sigma$ TPS (tx/s)"]
    {md: mkSpacer <$> [5, 6, 3, 3], texTabular: "llrr"}

lpCompare2TH = Table
    ["$k$, $B_f$, $B_h$", "Network", "E. $B_h$ (B)", "E. $D_h$ (B)", "$\\Sigma$ TPS (tx/s)"]
    {md: mkSpacer <$> [5, 6, 3, 3, 3], texTabular: "llrrr"}

lpCompareUt1Eth2 :: Table
lpCompareUt1Eth2 = lpCompareTH $ (genLpCompareRow 3000.0) <$> (filterUtVsOther [Bitcoin, UT (PoRTs 1), Eth2, UT (T 1)])

lpCompareUt1OptShard :: Table
lpCompareUt1OptShard = lpCompareTH $ (genLpCompareRow 3000.0) <$> (filterUtVsOther [Bitcoin, UT (PoRTs 1), Eth2, UT (T 1), UT (HOT 1), OptShard])

lpCompareUt2OptShard :: Table
lpCompareUt2OptShard = lpCompare2TH $ (genLpCompare2Row 3000.0) <$> (filterUtVsOther [Bitcoin, UT (PoRTs 1), Eth2, UT (T 1), UT (HOT 1), OptShard, UT (PoRTs 2), UT(T 2), UT (HOT 2)])

lpCompareUt2OptShard20k :: Table
lpCompareUt2OptShard20k = lpCompare2TH $ (genLpCompare2Row _COMPARE_20K) <$> (filterUtVsOther [Bitcoin, UT (PoRTs 1), Eth2, UT (T 1), UT (HOT 1), OptShard, UT (PoRTs 2), UT(T 2), UT (HOT 2)])


fixRow2 :: Array String -> Array String
fixRow2 rs = take 1 rs <> [replaceAll (Pattern " ") (Replacement "") $ ui rs 1] <> drop 2 rs

latexToMathjax :: String -> String
latexToMathjax = replaceAll (Pattern "\\nicefrac") (Replacement "\\frac")
    <<< replaceAll (Pattern "\\UT") (Replacement "\\text{UT}_")
    <<< replaceAll (Pattern "\\UTinf{") (Replacement "\\text{UT}_{\\aleph ")

showMdTable :: Table -> String
showMdTable (Table headings {md} table) = (intercalate "\n" <<< fixRow2) $ (wrap "|" <<< wrap " " <<< intercalate " | ") <$> ([headings, md] <> table)

showLatexTable :: Table -> String
showLatexTable table = renderBooktabs (TPositioning [Hereish, Top, Bottom, Override]) {label: Nothing, caption: Nothing} table

showHtmlTable :: String -> Table -> String
showHtmlTable _id (Table headings _ table) = latexToMathjax $ wrapXmlWAttr "table" ("id=\"" <> _id <> "\"") $ flip append "\n" $
    wXmlWNs "tr" (join $ wrapXml "th" <$> headings) <> (join $ (wXmlWNs "tr" <<< join <<< map (wrapXml "td")) <$> table)
  where
    join = intercalate ""
    wXmlWNs tag = append "\n" <<< wrapXml tag
