module Amaroo.WP.Tables where

import Prel

import Amaroo.WP.Calcs (Params, mkSimplePs, runChainCalcFor)
import Amaroo.WP.Formatter
import Data.Array (foldl, intercalate, (:))
import Data.Int (Radix, decimal, toNumber)
import Data.Int (Radix, toStringAs) as I
import Data.List.NonEmpty (head)
import Data.Maybe (fromMaybe)
import Data.Number.Format as N
import Data.String (length)
import Data.String.Utils as S
import Math (floor)

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

utNames :: Array UtName -> Array String
utNames = map (wrap "$" <<< utName)

_CARDANO_BH :: Number
_CARDANO_BH = 1070.0

_ETH2_EFF_BH = 8192.0 / (6.5*60.0) / 12.0 + 200.0 * 0.1

_ETH2_1M_K = 75278.0

_POLKADOT_BH = 288.0

_UT_BF = 1.0 / 15.0
_UT_BH = 84.0
_UT_BH_FOR_SHARDING = 68.0
_UT_HF = {bh: _UT_BH, bf: _UT_BF}


utComplexityParams :: Array Params
utComplexityParams = do
  k <- [2000.0, 20000.0]
  bf <- [1.0 / 7.5, 1.0 / 15.0, 1.0 / 30.0, 1.0 / 60.0]
  bh <- [84.0, 112.0]
  txSize <- [250.0]
  pure $ mkSimplePs k {bf, bh} txSize

utComplexityData = runChainCalcFor <$> utComplexityParams

btToF :: Int -> Number
btToF t = 1.0 / (toNumber t)


utVsOther :: Number -> Array {name :: String, p :: Params}
utVsOther k =
    [ {name: "bitcoin", p: mkSimplePs k {bf: btToF 600, bh: 80.0} tx }
    , {name: "cardano", p: mkSimplePs k {bf: btToF 20, bh: _CARDANO_BH} tx }
    , {name: "UT1", p: mkSimplePs k _UT_HF tx }
    , {name: "eth2", p: mkSimplePs k {bf: btToF 12, bh: _ETH2_EFF_BH} tx }
    , {name: "polkadot", p: mkSimplePs k {bf: btToF 6, bh: _POLKADOT_BH} tx }
    , {name: "optimal sharding", p: mkSimplePs k {bf: _UT_BF, bh: _UT_BH_FOR_SHARDING} tx }
    , {name: "UT2", p: mkSimplePs k {bf: _UT_BF, bh: _UT_BH_FOR_SHARDING} tx }
    ]
  where
    tx = 250.0

mkSpacer :: Int -> String
mkSpacer n = S.repeat n "-" |> fromMaybe ""

tableTps :: Table
tableTps =
    [ ["$k$, $B_f$, $B_h$", "$O(c)$", "Sharded $O(c^2)$"] <> utNames [Std 1, Std 2, Std 3]
    , mkSpacer <$> [6, 3, 6, 4, 4, 4]
    ] <> (genTpsRow <$> utComplexityData)
  where
    genTpsRow cd = [fmtPsKBfBh cd.ps] <> (fmtTps <$> getTps <$> [cd.trad.d1, cd.trad.d2, cd.ut.std.d1, cd.ut.std.d2, cd.ut.std.d3])
    getTps ns = ns.tps


-- tableTpsHot :: Table
-- tableTpsHot =



showTable :: Table -> String
showTable table = intercalate "\n" $ wrap "|" <$> intercalate "|" <$> table
