module Amaroo.WP.Calcs.Tiling where

import Prel

import Amaroo.WP.Calcs (mkSimplePs, utChainCalc)
import Amaroo.WP.Calcs as Calcs
import Amaroo.WP.Formatter (fdStd, fdStdMixed, fdStdTwo, fmtDyn)
import Amaroo.WP.Tables (_UT_BF, _UT_BH, id, mkSpacer, repeatSafe)
import Amaroo.WP.Tables.Types (Table(..))
import Data.Array as A
import Data.Int (floor, toNumber)
import Math as M
import Partial (crashWith)
import Partial.Unsafe (unsafePartial)

type Tiling i =
  { sigma_tiles :: i -> Number
  , tiles_at :: i -> Number
  , sec_ratio :: i -> Number
  }


tree_tiling :: Tiling {v :: Int, d :: Int}
tree_tiling =
    { sigma_tiles: \{v,d} -> (toNumber v) * M.floor (M.pow (toNumber $ v - 1) (toNumber d) - 1.0) / (toNumber $ v - 2) + 1.0
    , tiles_at: \{v,d} -> if d == 0 then 1.0 else toNumber v * M.floor (M.pow (toNumber $ v-1) (toNumber $ d - 1))
    , sec_ratio: \{v} -> (M.sqrt (toNumber $ 4 * v - 3) + 1.0) / 2.0
    }



params_tt k = mkSimplePs k {bf: _UT_BF, bh: _UT_BH} 250.0
ut_params = {explicitPoRs: true, headerOmission: true, hashTruncation: true, onlyNecessaryHeaders: false}

trim_for_lp :: Array String -> Array String
-- trim_for_lp [e1, e2, e3, e4, e5, e6, e7, e8, e9] = [e1, e3, e4, e5, e6, e7, e9]
trim_for_lp [e1, e3, e4, e5, e6, e7, _e8, _e9] = [e1, e3, e4, e5, e6, e7]
trim_for_lp _row = unsafePartial $ crashWith $ "trim_for_lp: bad sized row: " <> show _row

filter_big_hs_for_v :: Array Int -> Int -> Array Int
filter_big_hs_for_v hs v = A.filter (_ <= hLimit) hs
  where
    hLimit = case v of
      3 -> 90
      4 -> 60
      5 -> 50
      _ -> 90

tree_tiling_table :: Int -> {k :: Number, lp :: Boolean} -> Table
tree_tiling_table v {k, lp} = Table
    headings
    ({md: mkSpacer <$> A.replicate (l) 3, texTabular: "l" <> repeatSafe (l-1) "r"})
    $ mkRow <$> row_hs
  where
    row_hs = flip (filter_big_hs_for_v) v $ if lp then [0, 1, 2, 5, 10, 15, 20, 30, 60, 90] else A.range 0 6 <> [10, 15, 20, 25, 30, 60, 90]
    headings = (if lp then trim_for_lp else id)
      [ if lp then "# of Layers" else "$h$"
      -- , "$N_{\\text{tiles}|h}$"
      , "$N_{\\text{tiles}}$"
      , "$\\Sigma N_1$"
      , "$\\Sigma N_2$"
      , "$\\Sigma \\text{TPS}_1$"
      , "$\\Sigma \\text{TPS}_2$"
      , "$\\mathbb{C}^\\prime$"
      , "$\\times \\UT{\\text{+OPT}}$"
      ]
    l = A.length headings
    -- s_tps1, x_ut_tps1
    mkRow d = (if lp then trim_for_lp else id) $
        (fmtDyn fdStdMixed <$>
          [toNumber d
          -- , n_tiles_h
          , n_tiles
          , s_n1
          , s_n2
          , s_tps1
          , s_tps2
          ])
          <>
          (fmtDyn fdStd <$>
          [ conf_rate
          , x_ut_n1
          ])
      where
        sx_to_tile_ratio = 1.0 / (toNumber $ v + 1)
        n_tiles = tree_tiling.sigma_tiles {v, d}
        _n_tiles_h = tree_tiling.tiles_at {v, d}
        ut_cs = utChainCalc (params_tt k) ut_params
        ut_n1 = ut_cs.d1.n
        ut_n2 = ut_cs.d2.n
        tile_n1 = ut_n1 / (toNumber $ v + 1)
        tile_n2 = ut_n2 / (toNumber $ v + 1)
        s_n1 = n_tiles * tile_n1
        x_ut_n1 = s_n1 / ut_n1
        ut_tps1 = ut_cs.d1.tps
        tile_tps1 = ut_tps1 * sx_to_tile_ratio
        ut_tps2 = ut_cs.d2.tps
        tile_tps2 = ut_tps2 * sx_to_tile_ratio
        s_tps1 = n_tiles * tile_tps1
        s_tps2 = n_tiles * tile_tps2
        _x_ut_tps1 = s_tps1 / ut_tps1
        _x_ut_tps2 = s_tps2 / ut_tps2
        s_n2 = n_tiles * tile_n2
        _x_ut_n2 = s_n2 / ut_n2
        conf_rate = ut_cs.confRate * sx_to_tile_ratio

tree_tiling_3k_v3_table :: Table
tree_tiling_3k_v3_table = tree_tiling_table 3 {k: 3000.0, lp: false}

tree_tiling_3k_v3_table_lp :: Table
tree_tiling_3k_v3_table_lp = tree_tiling_table 3 {k: 3000.0, lp: true}

tree_tiling_3k_v4_table :: Table
tree_tiling_3k_v4_table = tree_tiling_table 4 {k: 3000.0, lp: false}

tree_tiling_3k_v5_table :: Table
tree_tiling_3k_v5_table = tree_tiling_table 5 {k: 3000.0, lp: false}

tree_tiling_20k_v3_table :: Table
tree_tiling_20k_v3_table = tree_tiling_table 3 {k: 20000.0, lp: false}

tree_tiling_20k_v4_table :: Table
tree_tiling_20k_v4_table = tree_tiling_table 4 {k: 20000.0, lp: false}

tree_tiling_20k_v5_table :: Table
tree_tiling_20k_v5_table = tree_tiling_table 5 {k: 20000.0, lp: false}
