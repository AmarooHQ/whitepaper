module Test.Main where

import Prel

import Amaroo.WP.Tables.Types (LatexTablePos(..), Table(..), TableDesc(..))
import Control.Monad.State (runState)
import Data.Array (drop, zip)
import Data.Foldable (sequence_)
import Data.Maybe (Maybe(..))
import Data.String as S
import Data.String.Utils (lines)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Main (getCaption, insertReplacement, replaceTable, toBeforeTableAfter)
import Test.Amaroo.WP.Calcs (auxStatsSpec, tradSpec, utSpec)
import Test.Amaroo.WP.Conversion (convQuickChecks)
import Test.Amaroo.WP.Formatter (fmtSpec)
import Test.Amaroo.WP.Tables (utNamesSpec)
import Test.Amaroo.WP.Tables.Booktabs (booktabsSpec)
import Test.Amaroo.WP.Utils (utilSpecs)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)

pos = [Hereish, Bottom, TablePage, Override]
sampleAsdf1 = "\\begin{table}[hbp!]\n\\centering\n\\label{table:tn1}\n\\begin{tabular}{asdf1}\n\\toprule\n \\\\\n\\midrule\n\\bottomrule\n\\end{tabular}\n\\end{table}"
sampleAsdf2 = "\\begin{table}[hbp!]\n\\centering\n\\caption{Test caption.\nMultiline.} \\label{table:tn1}\n\\begin{tabular}{asdf2}\n\\toprule\n \\\\\n\\midrule\n\\bottomrule\n\\end{tabular}\n\\end{table}"
tableAsdf1 = (Table [] {md: [], texTabular: "asdf1"} [])
tableAsdf2 = (Table [] {md: [], texTabular: "asdf2"} [])

sample1 = """

%% INSERT ### TABLE: tn1

: Test caption.
Multiline.

"""
res1Expected = "\n\n" <> sampleAsdf2 <> "\n\n"


replaceTableSpec = do
    describe "replaceTable" do
      it "insertReplace works" do
        insertReplacement (TD "tn1" tableAsdf1 pos) {before: ["1"], mid: Nothing, after: ["2"]} `shouldEqual` ["1", sampleAsdf1, "2"]
        insertReplacement (TD "tn1" tableAsdf2 pos) {before: ["1"], mid: Just "Test caption.\nMultiline.", after: ["2"]} `shouldEqual` ["1", sampleAsdf2, "2"]
      it "handles captions" do
        getCaption ["", "", "Not a caption"] `shouldEqual` Nothing
        getCaption ["", "", ": a caption"] `shouldEqual` Just {cap: "a caption", capLines: [": a caption"]}
        getCaption ["jkhfgkjhg", "", "Table: a caption2"] `shouldEqual` Just {cap: "a caption2", capLines: ["Table: a caption2"]}
        getCaption ["jkhfgkjhg", "", "Table: a caption2", "l2"] `shouldEqual` Just {cap: "a caption2\nl2", capLines: ["Table: a caption2", "l2"]}
        getCaption ["", "not blank", ": a caption"] `shouldEqual` Nothing
      it "works with sample" do
        let (Tuple _ res1) = runState (replaceTable (TD "tn1" tableAsdf2 pos)) sample1
            pairs = zip (lines res1) (lines res1Expected)
            expMid = toBeforeTableAfter "tn1" $ lines sample1
        (lines sample1 |> drop 3) `shouldEqual` ["", ": Test caption.", "Multiline.", "", ""]
        S.trim ": Test caption" `shouldEqual` ": Test caption"
        S.trim "  : Test caption    " `shouldEqual` ": Test caption"
        expMid.mid `shouldEqual` Just "Test caption.\nMultiline."
        expMid `shouldEqual` {before: ["", ""], mid: Just "Test caption.\nMultiline.", after: ["", ""]}
        sequence_ $ do
          (Tuple l1 l2) <- pairs
          pure $ shouldEqual l1 l2
        res1 `shouldEqual` res1Expected


main :: Effect Unit
main = do
  launchAff_ $ runSpec [consoleReporter] do
    tradSpec
    utSpec
    auxStatsSpec
    utNamesSpec
    fmtSpec
    utilSpecs
    booktabsSpec
    replaceTableSpec
    convQuickChecks
