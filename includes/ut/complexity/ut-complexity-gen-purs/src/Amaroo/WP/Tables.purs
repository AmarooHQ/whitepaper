module Amaroo.WP.Tables where

import Prel

import Amaroo.WP.Calcs (ChainStats, Params, UtVariants, allUtChainCalcs, allUtChainCalcsF, auxStats, eth2EffBh, mkSimplePs, pToPF, runChainCalcFor, tradChainCalc, tradChainCalcEth2, utChainCalc)
import Amaroo.WP.Formatter (fdPlain, fdPlainMixed, fdPlainZero, fdStdMixed, fdStdTwo, fdStdZero, fmt1GbpsPs, fmtDyn, fmtPsKBfBh, wrap)
import Amaroo.WP.Utils (diagonalApply, ui)
import Data.Array (drop, filter, intercalate, take)
import Data.Int (decimal, toNumber)
import Data.Int (toStringAs) as I
import Data.Maybe (fromMaybe)
import Data.Number (infinity)
import Data.String (Pattern(..), Replacement(..), length, replaceAll)
import Data.String.Utils as S
import Effect.Exception (error)
import Effect.Exception.Unsafe (unsafeThrowException)
import Math (pow)

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


type Table = Array (Array String)

data UtName = PoRs Int | PoRTs Int | Std Int | T Int | HO Int | HOT Int | Aleph UtName

utBaseN :: String -> String
utBaseN inner = "\\UT{" <> inner <> "}"

utAlephN :: String -> String
utAlephN inner = "\\UTinf{" <> inner <> "}"


iToS = I.toStringAs decimal

sToExt s = if length s > 0 then "+\\text{" <> s <> "}" else ""

utNameInner f i e = f $ iToS i <> sToExt e

utNameI :: UtName -> Int
utNameI (PoRs i) = i
utNameI (PoRTs i) = i
utNameI (Std i) = i
utNameI (T i) = i
utNameI (HO i) = i
utNameI (HOT i) = i
utNameI (Aleph n) = utNameI n

utNameE :: UtName -> String
utNameE (PoRs _) = "PoRs"
utNameE (PoRTs _) = "PoRTs"
utNameE (Std _) = ""
utNameE (T _) = "T"
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
_ETH2_EFF_BH = eth2EffBh _ETH2_BH
_ETH2_1M_K = 75278.0

_POLKADOT_BH = 288.0
_POLKADOT_1M_K = 109810.0

_UT_BF = 1.0 / 15.0
_UT_BH = 84.0
_UT_BH_FOR_SHARDING = 68.0
_UT_HF = {bh: _UT_BH, bf: _UT_BF}

_UT1_1M_K = ut1TpsToK _1M 250.0 _UT_BF _UT_BH
_UT1HOT_1M_K = ut1TpsToK _1M 250.0 _UT_BF 16.0
_UT2_1M_K = ut2TpsToK _1M 250.0 _UT_BF _UT_BH _UT_BH
_UT2HOT_1M_K = ut2TpsToK _1M 250.0 _UT_BF 16.0 _UT_BH_FOR_SHARDING
_OPT_SHARD_1M_K = oc2TpsToK _1M 250.0 _UT_BF _UT_BH_FOR_SHARDING


_UT_INIT_CONFIG = mkSimplePs 3000.0 _UT_HF 250.0


utComplexityParams :: Array Params
utComplexityParams = do
      k <- [3000.0, 30000.0]
      bf <- [1.0 / 7.5, 1.0 / 15.0, 1.0 / 30.0, 1.0 / 60.0]
      bh <- [84.0, 112.0]
      txSize <- [250.0]
      pure $ mkSimplePs k {bf, bh} txSize
    <> [ mkSimplePs _ETH2_1M_K {bf: btToF 15, bh: 84.0} 250.0 ]

utComplexityData = runChainCalcFor <$> utComplexityParams

btToF :: Int -> Number
btToF t = 1.0 / (toNumber t)

data Network = Bitcoin | Cardano | Eth2 | Polkadot | OptShard | UT UtName

instance showNetwork :: Show Network where
  show Bitcoin = "Bitcoin"
  show Cardano = "Cardano"
  show Eth2 = "Eth2"
  show Polkadot = "Polkadot"
  show OptShard = "Optimal Sharding"
  show (UT ut) = utName_ ut

utVsOther :: Number -> Array {net :: Network, p :: Params}
utVsOther k =
    [ {net: Bitcoin, p: mkSimplePs k {bf: btToF 600, bh: 80.0} tx }
    , {net: Cardano, p: mkSimplePs k {bf: btToF 20, bh: _CARDANO_BH} tx }
    , {net: UT (PoRs 1), p: mkSimplePs k _UT_HF tx }
    , {net: UT (Std 1), p: mkSimplePs k _UT_HF tx }
    , {net: UT (HOT 1), p: mkSimplePs k _UT_HF tx }
    , {net: Polkadot, p: mkSimplePs k {bf: btToF 6, bh: _POLKADOT_BH} tx }
    , {net: Eth2, p: mkSimplePs k {bf: _ETH2_BF, bh: _ETH2_BH} tx }
    , {net: OptShard, p: mkSimplePs k {bf: _UT_BF, bh: _UT_BH_FOR_SHARDING} tx }
    , {net: UT (PoRs 2), p: mkSimplePs k _UT_HF tx }
    , {net: UT (Std 2), p: mkSimplePs k _UT_HF tx }
    , {net: UT (HOT 2), p: mkSimplePs k _UT_HF tx }
    , {net: UT (Aleph (HOT 2)), p: mkSimplePs k _UT_HF tx }
    ]
  where
    tx = 250.0

ut1MCompareKs = [_BTC_1M_K, _CARDANO_1M_K, _UT1_1M_K, _UT1HOT_1M_K, _POLKADOT_1M_K, _ETH2_1M_K, _OPT_SHARD_1M_K, _UT2_1M_K, _UT2HOT_1M_K]

id x = x

netToChainStats :: Network -> Params -> ChainStats
netToChainStats (UT (PoRs _)) p = (utChainCalc p (allUtChainCalcsF id).pors)
netToChainStats (UT (PoRTs _)) p = (utChainCalc p (allUtChainCalcsF id).ports)
netToChainStats (UT (Std _)) p = (utChainCalc p (allUtChainCalcsF id).std)
netToChainStats (UT (T _)) p = (utChainCalc p (allUtChainCalcsF id).t)
netToChainStats (UT (HO _)) p = (utChainCalc p (allUtChainCalcsF id).ho)
netToChainStats (UT (HOT _)) p = (utChainCalc p (allUtChainCalcsF id).hot)
netToChainStats (UT (Aleph v)) p = netToChainStats (UT v) p
netToChainStats Eth2 p = tradChainCalcEth2 p
netToChainStats _ p = tradChainCalc p

netLookupChainStats :: Network -> UtVariants ChainStats -> ChainStats
netLookupChainStats (UT (PoRs _)) utvs = utvs.pors
netLookupChainStats (UT (PoRTs _)) utvs = utvs.ports
netLookupChainStats (UT (Std _)) utvs = utvs.std
netLookupChainStats (UT (T _)) utvs = utvs.t
netLookupChainStats (UT (HO _)) utvs = utvs.ho
netLookupChainStats (UT (HOT _)) utvs = utvs.hot
netLookupChainStats (UT (Aleph v)) utvs = netLookupChainStats (UT v) utvs
netLookupChainStats net _ = unsafeThrowException $ error $ "[netLookupChainStats] non UT network provided: " <> show net

notPoRs :: Network -> Boolean
notPoRs (UT (PoRs _)) = false
notPoRs (UT (PoRTs _)) = false
notPoRs _ = true

isAleph :: Network -> Boolean
isAleph (UT (Aleph _)) = true
isAleph _ = false

diagF1M :: Number -> Array _
diagF1M = filter (notPoRs <<< \e -> e.net) <<< utVsOther

utVsOther1M :: Array {net :: Network, p :: Params}
utVsOther1M = diagonalApply diagF1M ut1MCompareKs

-- Note: CBF -- it was only there b/c of solana's rediculous 700k tps claim anyway
-- utVsOther1Gbps :: Array {net :: Network, p :: Params}
-- utVsOther1Gbps =

mkSpacer :: Int -> String
mkSpacer n = S.repeat n "-" |> fromMaybe ""

getTps ns = ns.tps

genTpsRow utF cd = [fmtPsKBfBh cd.ps] <> (fmtDyn fdStdMixed <$> getTps <$> [cd.trad.d1, cd.trad.d2, (utF cd).d1, (utF cd).d2, (utF cd).d3])

tableTps :: Table
tableTps =
    [ ["$k$, $B_f$, $B_h$", "$O(c)$", "Sharded $O(c^2)$"] <> utNames [Std 1, Std 2, Std 3]
    , mkSpacer <$> [6, 2, 5, 4, 4, 4]
    ] <> (genTpsRow (\cd -> cd.ut.std) <$> utComplexityData)

tableTpsHot :: Table
tableTpsHot =
    [ ["$k$, $B_f$, $B_h$", "$O(c)$", "Sharded $O(c^2)$"] <> utNames [HOT 1, HOT 2, HOT 3]
    , mkSpacer <$> [6, 2, 5, 4, 4, 4]
    ] <> (genTpsRow (\cd -> cd.ut.hot) <$> utComplexityData)

genDappChainsRow utF cd = [fmtPsKBfBh cd.ps] <> (fmtDyn fdStdMixed <$> [(utF cd).d1.n, (utF cd).d2.n, (utF cd).d3.n, (utF cd).deltaBigS]) <> [fmtDyn fdStdTwo (utF cd).confRate]

dappChains :: Table
dappChains =
    [ ["$k$, $B_f$, $B_h$", "$N_1$", "$N_2$", "$N_3$", "$\\Delta S$", "$\\mathbb{C}^\\prime$ (Hz)"]
    , mkSpacer <$> [6, 4, 5, 5, 5, 4]
    ] <> (genDappChainsRow (\cd -> cd.ut.std) <$> utComplexityData)

dappChainsHot :: Table
dappChainsHot =
    [ ["$k$, $B_f$, $B_h$", "$N_1$", "$N_2$", "$N_3$", "$\\Delta S$", "$\\mathbb{C}^\\prime$ (Hz)"]
    , mkSpacer <$> [6, 4, 5, 5, 5, 4]
    ] <> (genDappChainsRow (\cd -> cd.ut.hot) <$> utComplexityData)

-- TODO: replace `fmtDyn fdPlain`
genPoRRow utF cd = [fmtPsKBfBh cd.ps] <> (fmtDyn fdStdMixed <$> [ut.d1.n, ut.d1.tps, ut.d2.n, ut.d2.tps, ut.porBytes]) -- <> (fmtDyn fdStdTwo <$> [ut.d1.n / ut.d1.p.k])
  where
    ut = utF cd

porTableSpacer = mkSpacer <$> [6, 2, 5, 4, 5, 3] -- , 4]

tpsPor :: Table
tpsPor =
    [ ["$k$, $B_f$, $B_h$", "$N_1$", (utName_ $ PoRs 1) <> " TPS", "$N_2$", (utName_ $ PoRs 2) <> " TPS", "PoR (B)"] -- , "$\\nicefrac{N_1}{k}$"]
    , porTableSpacer
    ] <> (genPoRRow (\cd -> cd.ut.pors) <$> utComplexityData)

tpsPort :: Table
tpsPort =
    [ ["$k$, $B_f$, $B_h$", "$N_1$", (utName_ $ PoRTs 1) <> " TPS", "$N_2$", (utName_ $ PoRTs 2) <> " TPS", "PoR (B)"] -- , "$\\nicefrac{N_1}{k}$"]
    , porTableSpacer
    ] <> (genPoRRow (\cd -> cd.ut.ports) <$> utComplexityData)

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

-- todo: fix fmtDyn fdPlain
genCompareRow {net, p} = [fmtPsKBfBh p, show net] <> [fmtDyn fdPlainMixed cs.effBh] <> (fmtDyn fdStdTwo <$> [scalingFactor, tpsPerBaseChain]) <> (fmtDyn fdStdMixed <$> [tps])
  where
    cs = netToChainStats net p
    aux = auxStats cs
    -- n1 = if isAleph net then infinity else cs.d1.n
    tps = if isAleph net then infinity else netToTps net cs
    tpsPerBaseChain = netToTps net cs / cs.d1.n
    scalingFactor = netToScalingFactor net aux

compareNetsTH =
    [ ["$k$, $B_f$, $B_h$", "Network", "Eff. $B_h$", "Scale $\\times$", "$\\nicefrac{\\Sigma\\;\\text{TPS}}{N_1}$", "$\\Sigma$ TPS"] -- , "TPS vs " <> (utName_ $ Std 2)]
    , mkSpacer <$> [5, 6, 3, 3, 4, 3] -- , 6]
    ]

compareNets3k :: Table
compareNets3k =
    compareNetsTH <> (genCompareRow <$> utVsOther 3_000.0)

compareNets30k :: Table
compareNets30k =
    compareNetsTH <> (genCompareRow <$> utVsOther 30_000.0)

-- todo: fix fmtDyn fdPlain
genCompare1MRow {net, p} = [fmtPsKBfBh p, show net] <> (fmtDyn fdStdTwo <$> [netToTps net cs / cs.d1.n, netToTps net cs]) <> (fmtDyn fdStdMixed <$> [ut2.d2.tps]) -- , cs.k1 / ut2K])
  where
    ut2K = ut2TpsToK (netToTps net cs) p.txSize pf.hf.bf pf.hf.bh pf.hf.bh
    pf = pToPF p
    ut2 = utChainCalc p (allUtChainCalcsF id).std
    cs = netToChainStats net p
    -- aux = auxStats cs

compareNets1mTps :: Table
compareNets1mTps =
    [ ["$k$, $B_f$, $B_h$", "Network", "$\\nicefrac{\\Sigma\\;\\text{TPS}}{N_1}$", "$\\Sigma$ TPS", "$\\UT{2}$ $\\Sigma$ TPS"] -- , "$k$ vs Equiv. $\\UT{2}$"]
    , mkSpacer <$> [5, 5, 3, 3, 3] -- , 5]
    ] <> (genCompare1MRow <$> utVsOther1M)


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

genCompareUtRow :: UtVariants ChainStats -> Array UtName -> {f :: ChainStats -> String, s :: String} -> Array String
genCompareUtRow ut utvs {f, s} = [s] <> (getProp <$> utvs)
  where
    getProp = f <<< (\n -> netLookupChainStats (UT n) ut)

optimizationProps =
  [ {s: "$\\Sigma$ TPS", f: \cs -> fmtDyn fdPlainZero cs.d1.tps}
  , {s: "$N_1$ (chains)", f: \cs -> fmtDyn fdPlainZero cs.d1.n}
  , {s: "$\\mathbb{C}^\\prime$ (Hz)", f: \cs -> fmtDyn fdPlain cs.confRate}
  , {s: "Effective $B_h$ (B)", f: \cs -> fmtDyn fdPlainZero cs.effBh}
  , {s: "PoR Size (B)", f: \cs -> fmtDyn fdPlainZero cs.porBytes}
  , {s: "$\\Delta s$ (B/s)", f: \cs -> fmtDyn fdStdZero cs.deltaSmallS}
  , {s: "TTS 5yrs (days)", f: \cs -> fmtDyn fdStdTwo cs.tts}
  , {s: "$\\Delta S$ (B/s)", f: \cs -> fmtDyn fdStdMixed cs.deltaBigS}
  ]

compareUtOptimizations :: Table
compareUtOptimizations =
    [ [""] <> utNames variants
    , mkSpacer <$> [7, 4, 5, 3, 4, 4, 4]
    ] <> (genCompareUtRow ut variants <$> optimizationProps)
  where
    ut = allUtChainCalcs _UT_INIT_CONFIG
    variants = [PoRs 1, PoRTs 1, Std 1, T 1, HO 1, HOT 1]

fixRow2 :: Array String -> Array String
fixRow2 rs = take 1 rs <> [replaceAll (Pattern " ") (Replacement "") $ ui rs 1] <> drop 2 rs

showTable :: Table -> String
showTable table = (intercalate "\n" <<< fixRow2) $ (wrap "|" <<< wrap " " <<< intercalate " | ") <$> table
