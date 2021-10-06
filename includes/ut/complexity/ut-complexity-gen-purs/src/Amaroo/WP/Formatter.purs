module Amaroo.WP.Formatter where

import Prel

import Amaroo.WP.Calcs (ChainStats, Params, ParamsF)
import Data.Array (intercalate, reverse)
import Data.Array as A
import Data.Int (toNumber)
import Data.List.NonEmpty (head)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number (isFinite, isNaN)
import Data.Number.Format (exponential, fixed)
import Data.Number.Format as NF
import Data.String (Pattern(..), contains, drop, length, split, stripPrefix, take)
import Data.String.Utils (fromCharArray, toCharArray)
import Data.Tuple (Tuple(..))
import Effect.Exception (error)
import Effect.Exception.Unsafe (unsafeThrowException)
import Math (abs, floor, pow)


wrap :: String -> String -> String
wrap wrapWith toWrap = wrapWith <> toWrap <> wrapWith

wrapXml :: String -> String -> String
wrapXml tag inner = ("<" <> tag <> ">") <> inner <> ("</" <> tag <> ">")

wrapXmlWAttr :: String -> String -> String -> String
wrapXmlWAttr tag attr inner = ("<" <> tag <> " " <> attr <> ">") <> inner <> ("</" <> tag <> ">")

chunk :: Int -> String -> Array String
chunk n s = if length s <= 3 then [s] else [take 3 s] <> chunk n (drop 3 s)

rev :: String -> String
rev = fromCharArray <<< reverse <<< toCharArray

fmtCommas :: Number -> String
fmtCommas n = rev $ intercalate "," $ chunk 3 $ rev $ NF.toString $ floor n

fmtCommasP :: Int -> Number -> String
fmtCommasP p n = fmtCommas n <> (if length lsf == 0 then "" else "." <> lsf)
  where
    lsf = (NF.toStringWith (fixed p) n |> split (Pattern ".") |> A.drop 1 |> A.head |> fromMaybe "")

_fmtSciNot [m, s] = m <> "\\times 10^{" <> (stripPrefix (Pattern "+") s |> fromMaybe s) <> "}"
_fmtSciNot i = unsafeThrowException (error $ "bad input to _fmtSciNot: " <> show i)

fmtSciNot :: Int -> Number -> String
fmtSciNot precision = NF.toStringWith (exponential precision) >>> split (Pattern "e") >>> _fmtSciNot

fmtRatioX :: String -> String
fmtRatioX s = (if contains (Pattern "times") s then "(" <> s <> ")" else s) <> "\\times"

fmtPlain = NF.toString

vCloseTo a b = a - b |> abs |> flip (-) 0.00000001 |> (>) 0.0

fmtFract :: Number -> String
fmtFract n
  | n `vCloseTo` 0.0016666666666666668 = "\\nicefrac{1}{600}"
  | n `vCloseTo` 0.016666666666666666 = "\\nicefrac{1}{60}"
  | n `vCloseTo` 0.025 = "\\nicefrac{1}{40}"
  | n `vCloseTo` 0.03333333333333333 = "\\nicefrac{1}{30}"
  | n `vCloseTo` 0.05 = "\\nicefrac{1}{20}"
  | n `vCloseTo` 0.06666666666666667 = "\\nicefrac{1}{15}"
  | n `vCloseTo` 0.08333333333333333 = "\\nicefrac{1}{12}"
  | n `vCloseTo` 0.13333333333333333 = "\\nicefrac{1}{7.5}"
  | n `vCloseTo` 0.14285714285714285 = "\\nicefrac{1}{7}"
  | n `vCloseTo` 0.15384615384615385 = "\\nicefrac{1}{6.5}"
  | n `vCloseTo` 0.16666666666666666 = "\\nicefrac{1}{6}"
  | n `vCloseTo` 1.8181818181818181 = "\\nicefrac{1}{0.55}"
  | otherwise = fmtCommasP 2 n

fmtFixedP p = NF.toStringWith (fixed p)

fmtDyn :: _ -> Number -> String
fmtDyn {low, high, mp, commas, pOnlySi, wSI, infLikeNan} n =
    if not (isFinite n) then (if isNaN n || infLikeNan then "-" else wrap "$" "\\infty") else
      if outsideRange then wrap (if wSI then "$" else "") $ fmtSciNot p n else
        if commas then fmtP fmtCommasP fmtCommas else fmtFixedP pNotSi n
  where
    p = fromMaybe 2 mp
    pNotSi = if pOnlySi then 0 else p
    outsideRange = n < pow 10.0 (toNumber low) + err || n >= pow 10.0 (toNumber high) - err
    err = (pow 10.0 $ -1.0 * toNumber p) * 0.5
    fmtP fP f = case (Tuple pOnlySi mp) of
        Tuple false (Just _) -> fP pNotSi n
        Tuple _ _ -> f n

fdDefaults = {low: -1, high: 6, mp: Just 1, commas: false, pOnlySi: false, wSI: true, infLikeNan: false}
fdK = fdDefaults {pOnlySi = true, wSI = false}
fdPlain = fdDefaults {commas = false, pOnlySi = false}
fdPlainZero = fdPlain {mp = Just 0}
fdPlainTwo = fdPlain {mp = Just 2}
fdStd = fdDefaults {commas = true, pOnlySi = false}
fdStdZero = fdStd {mp = Just 0}
fdStdTwo = fdStd {mp = Just 2}
fdStdMixed = fdStdTwo {pOnlySi = true}
fdStdNoSiMixed = fdStdTwo {pOnlySi = true, high = 15}
fdPlainMixed = fdPlainTwo {pOnlySi = true}

fmtTps = fmtCommas

_fmtParams = wrap "$" <<< intercalate ", "

fmtPsKBfBh :: ParamsF -> String
fmtPsKBfBh ps = _fmtParams [fmtDyn fdK k, fmtFract hf.bf, fmtPlain hf.bh]
  where
    k = ps.k
    hf = ps.hf

fmtPsKBfBhDh :: ChainStats -> String
fmtPsKBfBhDh cs = _fmtParams [fmtDyn fdK k, fmtFract hf.bf, fmtPlain hf.bh, fmtPlain dh]
  where
    ps1 = cs.d1.p
    ps2 = cs.d2.p
    k = ps1.k
    hf = ps1.hf
    dh = ps2.hf.bh

--- '$\\Delta S$, $B_f$, $B_h$, Tx (B)'
fmt1GbpsPs :: ChainStats -> Params -> String
fmt1GbpsPs cs ps = _fmtParams [fmtSciNot 1 cs.deltaBigS, fmtFract hf.bf, fmtPlain hf.bh, fmtPlain ps.txSize]
  where
    hf = head ps.hfs
