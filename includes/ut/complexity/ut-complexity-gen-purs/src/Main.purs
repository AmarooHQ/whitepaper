module Main where

import Prel

import Amaroo.WP.Calcs.Tiling
import Amaroo.WP.Formatter (wrap)
import Amaroo.WP.Tables
import Amaroo.WP.Tables.Booktabs (renderBooktabs)
import Amaroo.WP.Tables.Types (LatexTablePos(..), TPositioning(..), TableDesc(..))
import Control.Alt ((<|>))
import Control.Monad.Error.Class (throwError)
import Control.Monad.State (State, modify_, runState)
import Data.Array (drop, dropWhile, elem, filter, head, intercalate, length, take, takeWhile)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.String (Pattern(..), contains)
import Data.String as S
import Data.String.Utils (lines)
import Data.Traversable (sequence)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Console as C
import Effect.Exception (error, throwException)
import Effect.Exception.Unsafe (unsafeThrowException)
import Node.Buffer as B
import Node.Encoding (Encoding(..))
import Node.FS.Sync as FS

foreign import argv :: Array String
foreign import getEnvOrEmpty :: String -> String

data Format = Markdown | Latex | HTML

getEnv :: String -> Maybe String
getEnv name = getEnvOrEmpty name |> \e -> if S.length e == 0 then Nothing else Just e

-- asdf = unsafePerformEffect $ do
--   C.log $ show argv
--   C.log $ show $ getEnv "USER"
--   C.log $ show $ getEnv "USER2"


_WP_FILE_PATH = getEnv "REPLACE_TABLES_IN" |> fromMaybe "./output/whitepaper.markdown"

genStrToReplace tn = "%% INSERT ### TABLE: " <> tn

defaultPositioning :: Array LatexTablePos
defaultPositioning = [Hereish, Top, Bottom, Override]

tablePageOnly :: Array LatexTablePos
tablePageOnly = [TablePage]

hereish :: Array LatexTablePos
hereish = [Hereish]

here :: Array LatexTablePos
here = [Here]

wpTables :: Array TableDesc
wpTables =
    [ TD "tps" tableTps defaultPositioning
    , TD "tps_optimized" tableTpsHot defaultPositioning
    , TD "tps_hopors" tableTpsHOPoRs defaultPositioning
    , TD "dapp-chains" dappChains defaultPositioning
    , TD "dapp-chains_optimized" dappChainsHot defaultPositioning
    , TD "dapp-chains_hopors" dappChainsHOPoRs defaultPositioning
    , TD "tps_por" tpsPor defaultPositioning
    , TD "tps_port" tpsPort defaultPositioning
    , TD "tps_hopors" tpsHOPoRs defaultPositioning
    , TD "tps_hoports" tpsHOPoRTs defaultPositioning
    , TD "compare_optimizations_a" compareUtOptimizationsA defaultPositioning
    , TD "compare_optimizations_b" compareUtOptimizationsB defaultPositioning
    , TD "compare_optimizations_a_20k" compareUtOptimizationsA20k defaultPositioning
    , TD "compare_optimizations_b_20k" compareUtOptimizationsB20k defaultPositioning
    , TD "compare_nets_3k" compareNets3k hereish
    , TD "compare_nets_20k" compareNets20k hereish
    , TD "comparison_1m_tps" compareNets1mTps hereish
    , TD "tree_tiling_3k_v4_table" tree_tiling_3k_v4_table hereish
    -- , TD "tree_tiling_3k_v3_table" tree_tiling_3k_v3_table hereish
    -- , TD "tree_tiling_3k_v5_table" tree_tiling_3k_v5_table hereish
    -- , TD "tree_tiling_20k_v4_table" tree_tiling_20k_v4_table hereish
    -- , TD "tree_tiling_20k_v3_table" tree_tiling_20k_v3_table hereish
    -- , TD "tree_tiling_20k_v5_table" tree_tiling_20k_v5_table hereish
    ]

lpTables :: Array TableDesc
lpTables =
    [ TD "lp_compare_networks" lpCompareNetworks defaultPositioning
    , TD "comparison_1m_tps" compareNets1mTps tablePageOnly
    , TD "comparison_1m_tps_all" compareNets1mTpsAll tablePageOnly
    , TD "lp_compare_optimizations_1" lpCompareUtOptimizations1 defaultPositioning
    , TD "lp_compare_ut1_to_eth2" lpCompareUt1Eth2 defaultPositioning
    , TD "lp_compare_ut1_to_optshard" lpCompareUt1OptShard defaultPositioning
    , TD "lp_compare_ut2_to_optshard" lpCompareUt2OptShard defaultPositioning
    , TD "lp_compare_ut2_to_optshard_20k" lpCompareUt2OptShard20k defaultPositioning
    -- , TD "lp_compare_optimizations2" lpCompareUtOptimizations2 defaultPositioning
    -- , TD "lp_compare_optimizations3" lpCompareUtOptimizations3 defaultPositioning
    , TD "tree_tiling_3k_v3_table" tree_tiling_3k_v3_table_lp hereish
    ]


devTables =
    -- [ TD "lp_compare_ut1_to_optshard" lpCompareUt1OptShard defaultPositioning
    -- , TD "lp_compare_ut1_lim_to_optshard" lpCompareUt1LimitedOptShard defaultPositioning
    -- , TD "compare_optimizations_a" compareUtOptimizationsA defaultPositioning
    -- , TD "compare_lim_optimizations_a" compareUtLimOptimizationsA defaultPositioning
    -- , TD "tree_tiling_3k_v4_table" tree_tiling_3k_v4_table defaultPositioning
    [ TD "compareUtOptimizationsA" compareUtOptimizationsA defaultPositioning
    , TD "compare_optimizations_a_20k" compareUtOptimizationsA20k defaultPositioning
    , TD "tree_tiling_3k_v4_table" tree_tiling_3k_v4_table hereish
    , TD "comparison_1m_tps" compareNets1mTps hereish
    ]


allTables :: Array TableDesc
allTables
  | elem "--lp-tables" argv = lpTables
  | elem "--dev-tables" argv = devTables
  | otherwise = wpTables

readWhitepaperMd :: Effect String
readWhitepaperMd = do
    -- gitExists <- FS.exists "./.git"
    wpExists <- FS.exists _WP_FILE_PATH
    if wpExists then do
        mdContents <- FS.readFile _WP_FILE_PATH
        B.toString UTF8 mdContents
      else do
        throwError $ error "./output/whitepaper.markdown does not exist -- bailing out."

renderTable :: TableDesc -> Maybe String -> String
renderTable (TD tn table pos) caption = renderBooktabs (TPositioning pos) {label: Just tn, caption} table

insertReplacement :: TableDesc -> {before :: Array String, mid :: Maybe String, after :: Array String} -> Array String
insertReplacement td {before, mid, after} = before <> [renderTable td mid] <> after
-- insertReplacement _ {before, mid: Nothing, after} = before <> after

toBeforeTableAfter tn ls = {before: takeWhile (_ /= toReplace) ls, mid, after}
  where
    midPre = dropWhile (_ /= toReplace) ls
    -- capRes = (\_ -> getCaption $ take 2 midPre <> takeWhile (_ /= "") (drop 2 midPre)) =<< head midPre
    capRes = getCaption $ take 2 midPre <> (takeWhile (_ /= "") <<< drop 2) midPre
    toDrop = capRes <#> (\{capLines} -> length capLines + 2) |> fromMaybe 0
    after = drop toDrop midPre
    -- toDrop = (capRes <#> (\caption -> if isJust caption then 3 else 1) |> fromMaybe 0)
    mid = (capRes <#> (\{cap} -> cap)) :: Maybe String
    toReplace = genStrToReplace tn

getCaption :: Array String -> Maybe {cap :: String, capLines :: Array String}
getCaption lines = do
    _ <- shouldBeBlank
    cap <- S.stripPrefix (Pattern ": ") trimmedCaption <|> S.stripPrefix (Pattern "Table: ") trimmedCaption
    pure { cap, capLines }
  where
    trimmedCaption = S.trim $ intercalate "\n" capLines
    capLines = drop 2 lines
    shouldBeBlank = (\l -> if l == "" then Just "" else Nothing) <=< head $ drop 1 $ take 2 lines
-- getCaption _ = unsafeThrowException $ error "getCaption recieved an array with length /= 3"

replaceTable :: TableDesc -> State String Unit
replaceTable td@(TD tn _ _) = modify_ $ lines >>> toBeforeTableAfter tn >>> insertReplacement td >>> intercalate "\n"

replaceAllTablesInWP :: Boolean -> Effect Unit
replaceAllTablesInWP dryRun = do
    md <- readWhitepaperMd
    let (Tuple _ outMd) = runState replaceAllT_ md
    if contains (Pattern $ genStrToReplace "") outMd
      then do
        throwException $ error $
          "Process whitepaper.markdown file contains unreplaced tables: "
          <> "\n * " <> (lines outMd |> filter (contains (Pattern $ genStrToReplace "")) |> intercalate "\n * ")
      else
        if dryRun
          then C.log outMd
          else do
            FS.writeTextFile UTF8 _WP_FILE_PATH outMd
            C.log "Replaced tables in whitepaper.markdown and saved output"
  where
    replaceAllT_ = do
      _ <- sequence $ replaceTable <$> allTables
      pure unit

wnltn tn = wrap "\n" $ "### TABLE: " <> tn

logTable format (TD tn t _) = do
    C.log $ wnltn tn
    C.log $ showFunc t
  where
    showFunc = case format of
      Latex -> showLatexTable
      Markdown -> showMdTable
      HTML -> showHtmlTable tn

logAllTables format = do
  _ <- sequence $ logTable format <$> allTables
  pure unit

main :: Effect Unit
main = do
    if shouldPopulateMd
      then replaceAllTablesInWP dryRun
      else logAllTables format
  where
    shouldPopulateMd = elem "--populate-wp-md" argv
    dryRun = elem "--dry-run" argv
    format = if elem "--markdown" argv
      then Markdown
      else if elem "--html" argv then HTML else Latex
