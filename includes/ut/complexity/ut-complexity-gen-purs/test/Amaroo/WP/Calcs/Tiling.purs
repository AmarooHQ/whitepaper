module Test.Amaroo.WP.Calcs.Tiling where

import Prel

import Amaroo.WP.Calcs.Tiling (tree_tiling)
import Data.Foldable (sequence_)
import Data.Int (toNumber)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)


tilingSpec :: Spec Unit
tilingSpec = describe "tiling spec" do
    describe "tree_tiling" do
      it "tiles_at v=3" do
        tree_tiling.tiles_at {v: 3, d: 0} `shouldEqual` 1
        tree_tiling.tiles_at {v: 3, d: 1} `shouldEqual` 3
        tree_tiling.tiles_at {v: 3, d: 2} `shouldEqual` 6
        tree_tiling.tiles_at {v: 3, d: 3} `shouldEqual` 12
        tree_tiling.tiles_at {v: 3, d: 4} `shouldEqual` 24
      it "sigma_tiles v=3" do
        tree_tiling.sigma_tiles {v: 3, d: 0} `shouldEqual` 1.0
        tree_tiling.sigma_tiles {v: 3, d: 1} `shouldEqual` 4.0
        tree_tiling.sigma_tiles {v: 3, d: 2} `shouldEqual` 10.0
        tree_tiling.sigma_tiles {v: 3, d: 3} `shouldEqual` 22.0
        tree_tiling.sigma_tiles {v: 3, d: 4} `shouldEqual` 46.0
      it "tiles_at v=4" do
        let v = 4
        tree_tiling.tiles_at {v, d: 0} `shouldEqual` 1
        tree_tiling.tiles_at {v, d: 1} `shouldEqual` 4
        tree_tiling.tiles_at {v, d: 2} `shouldEqual` 12
        tree_tiling.tiles_at {v, d: 3} `shouldEqual` 36
        tree_tiling.tiles_at {v, d: 4} `shouldEqual` (36*3)
      it "simga_tiles v=4" do
        let v = 4
        tree_tiling.sigma_tiles {v, d: 0} `shouldEqual` 1.0
        tree_tiling.sigma_tiles {v, d: 1} `shouldEqual` 5.0
        tree_tiling.sigma_tiles {v, d: 2} `shouldEqual` 17.0
        tree_tiling.sigma_tiles {v, d: 3} `shouldEqual` 53.0
        tree_tiling.sigma_tiles {v, d: 4} `shouldEqual` (53.0 + 36.0*3.0)
      describe "sec_ratio" do
        let d = -1
        it "known int ratios" do
          tree_tiling.sec_ratio {v: 3, d} `shouldEqual` 2.0
          tree_tiling.sec_ratio {v: 7, d} `shouldEqual` 3.0
        sequence_ do
          v <- [3, 4, 5, 6, 7]
          pure $ it ("v=" <> show v) do
            tree_tiling.sec_ratio {v, d} `shouldSatisfy` (_ <= toNumber (v - 1))
        it "fails w/ v < 3" do
          let v = 2
          tree_tiling.sec_ratio {v, d} `shouldSatisfy` (_ > toNumber (v - 1))
