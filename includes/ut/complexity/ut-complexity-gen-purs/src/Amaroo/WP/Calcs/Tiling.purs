module Amaroo.WP.Calcs.Tiling where

import Prel

import Amaroo.WP.Calcs (mkSimplePs, utChainCalc)
import Amaroo.WP.Calcs as Calcs
import Amaroo.WP.Formatter (fdStdMixed, fmtDyn)
import Amaroo.WP.Tables (_UT_BF, _UT_BH, mkSpacer, repeatSafe)
import Amaroo.WP.Tables.Types (Table(..))
import Data.Array as A
import Data.Int (floor, toNumber)
import Math as M

type Tiling i =
  { sigma_tiles :: i -> Int
  , tiles_at :: i -> Int
  , sec_ratio :: i -> Number
  }


tree_tiling :: Tiling {v :: Int, d :: Int}
tree_tiling =
    { sigma_tiles: \{v,d} -> v * floor (M.pow (toNumber $ v - 1) (toNumber d) - 1.0) / (v - 2) + 1
    , tiles_at: \{v,d} -> if d == 0 then 1 else v * floor (M.pow (toNumber $ v-1) (toNumber $ d - 1))
    , sec_ratio: \{v} -> (M.sqrt (toNumber $ 4 * v - 3) + 1.0) / 2.0
    }



params3k = mkSimplePs 3000.0 {bf: _UT_BF, bh: _UT_BH} 250.0
ut_params = {explicitPoRs: false, headerOmission: false, hashTruncation: true}

tree_tiling_v4_table :: Table
tree_tiling_v4_table = Table
    headings
    ({md: mkSpacer <$> A.replicate (l+1) 3, texTabular: "l" <> repeatSafe l "r"})
    (mkRow <$> A.range 0 6)
  where
    v = 4
    headings =
      [ "Depth"
      , "$N_{\\text{tiles}|h}$", "$N_{\\text{tiles}}$"
      , "$\\Sigma N_1$"
      , "$\\Sigma N_2$"
      , "$\\Sigma \\text{TPS}_1$"
      , "$\\Sigma \\text{TPS}_2$"
      , "$\\times \\UT{}$"
      ]
    l = A.length headings
    -- s_tps1, x_ut_tps1
    mkRow d = fmtDyn fdStdMixed <$>
        [toNumber d
        , n_tiles_h, n_tiles
        , s_n1
        , s_n2
        , s_tps1
        , s_tps2
        , x_ut_n1
        ]
      where
        sx_to_tile_ratio = 1.0 / (toNumber $ v + 1)
        n_tiles = toNumber $ tree_tiling.sigma_tiles {v, d}
        n_tiles_h = toNumber $ tree_tiling.tiles_at {v, d}
        ut_cs = utChainCalc params3k ut_params
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
        x_ut_tps1 = s_tps1 / ut_tps1
        x_ut_tps2 = s_tps2 / ut_tps2
        s_n2 = n_tiles * tile_n2
        x_ut_n2 = s_n2 / ut_n2
