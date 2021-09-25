module Amaroo.WP.Formatter where

import Prel

import Amaroo.WP.Calcs (Params, ChainStats)
import Data.Array (intercalate, reverse, (:))
import Data.Array as A
import Data.List.NonEmpty (head)
import Data.Maybe (fromMaybe)
import Data.Number as N
import Data.Number.Format (exponential, fixed, precision)
import Data.Number.Format as NF
import Data.String (Pattern(..), contains, drop, length, split, stripPrefix, take)
import Data.String.Utils (fromCharArray, toCharArray)
import Effect.Exception (error)
import Effect.Exception.Unsafe (unsafeThrowException)
import Math (abs, floor)
import Undefined (undefined)


wrap :: String -> String -> String
wrap wrapWith toWrap = wrapWith <> toWrap <> wrapWith

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

_fmtSciNot [m, s] = wrap "$" $ m <> "\\times 10^{" <> (stripPrefix (Pattern "+") s |> fromMaybe s) <> "}"
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
  | n `vCloseTo` 0.15384615384615385 = "\\nicefrac{2}{13}"
  | n `vCloseTo` 0.14285714285714285 = "\\nicefrac{1}{7}"
  | n `vCloseTo` 0.16666666666666666 = "\\nicefrac{1}{6}"
  | n `vCloseTo` 1.8181818181818181 = "\\nicefrac{1}{0.55}"
  | otherwise = fmtCommasP 2 n

fmtTps = fmtCommas

_fmtParams = wrap "$" <<< intercalate ", "

fmtPsKBfBh :: Params -> String
fmtPsKBfBh ps = _fmtParams [fmtCommas k, fmtFract hf.bf, fmtPlain hf.bh]
  where
    k = head ps.ks
    hf = head ps.hfs

fmtPsKBfBhDh :: ChainStats -> String
fmtPsKBfBhDh cs = _fmtParams [fmtCommas k, fmtFract hf.bf, fmtPlain hf.bh, fmtPlain dh]
  where
    ps1 = cs.d1.p
    ps2 = cs.d2.p
    k = head ps1.ks
    hf = head ps1.hfs
    dh = (head ps2.hfs).bh

--- '$\\Delta S$, $B_f$, $B_h$, Tx (B)'
fmt1GbpsPs :: ChainStats -> Params -> String
fmt1GbpsPs cs ps = _fmtParams [fmtSciNot 1 cs.deltaBigS, fmtFract hf.bf, fmtPlain hf.bh, fmtPlain ps.txSize]
  where
    hf = head ps.hfs
