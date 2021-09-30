module Main where

import Prel

import Amaroo.WP.Formatter (wrap)
import Amaroo.WP.Tables (compareNets1mTps, compareNets30k, compareNets3k, compareUtOptimizations, compareUtOptimizations2, dappChains, dappChainsHot, lpCompareNetworks, lpCompareUtOptimizations1, showLatexTable, showMdTable, tableTps, tableTpsHot, tpsPor, tpsPort)
import Amaroo.WP.Tables.Booktabs (renderBooktabs)
import Amaroo.WP.Tables.Types (LatexTablePos(..), TPositioning(..), TableDesc(..))
import Control.Alt ((<|>))
import Control.Monad.Error.Class (throwError)
import Control.Monad.State (State, modify_, runState)
import Data.Array (drop, dropWhile, elem, filter, head, intercalate, take, takeWhile)
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
import Effect.Unsafe (unsafePerformEffect)
import Node.Buffer as B
import Node.Encoding (Encoding(..))
import Node.FS.Sync as FS

foreign import argv :: Array String
foreign import getEnvOrEmpty :: String -> String

data Format = Markdown | Latex

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

wpTables :: Array TableDesc
wpTables =
    [ TD "tps" tableTps defaultPositioning
    , TD "tps_optimized" tableTpsHot defaultPositioning
    , TD "dapp-chains" dappChains defaultPositioning
    , TD "dapp-chains_optimized" dappChainsHot defaultPositioning
    , TD "tps_por" tpsPor defaultPositioning
    , TD "tps_port" tpsPort defaultPositioning
    , TD "compare_optimizations" compareUtOptimizations defaultPositioning
    , TD "compare_optimizations2" compareUtOptimizations2 defaultPositioning
    , TD "compare_nets_3k" compareNets3k tablePageOnly
    , TD "compare_nets_30k" compareNets30k tablePageOnly
    , TD "comparison_1m_tps" compareNets1mTps tablePageOnly
    ]

lpTables :: Array TableDesc
lpTables =
    [ TD "lp_compare_optimizations" lpCompareUtOptimizations1 defaultPositioning
    -- , TD "lp_compare_optimizations2" lpCompareUtOptimizations2 defaultPositioning
    -- , TD "lp_compare_optimizations3" lpCompareUtOptimizations3 defaultPositioning
    , TD "lp_compare_networks" lpCompareNetworks defaultPositioning
    ]

allTables :: Array TableDesc
allTables = if elem "--lp-tables" argv
  then lpTables
  else wpTables

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

insertReplacement :: TableDesc -> {before :: Array String, mid :: _, after :: Array String} -> Array String
insertReplacement td {before, mid: Just caption, after} = before <> [renderTable td caption] <> after
insertReplacement _ {before, mid: Nothing, after} = before <> after

toBeforeTableAfter tn ls = {before: takeWhile (_ /= toReplace) ls, mid, after}
  where
    midPre = dropWhile (_ /= toReplace) ls
    mid = (\_ -> getCaption $ take 3 midPre) <$> head midPre
    after = drop toDrop midPre
    toDrop = (mid <#> (\caption -> if isJust caption then 3 else 1) |> fromMaybe 0)
    toReplace = genStrToReplace tn

getCaption [_, blank, caption] = if S.length blank == 0
    then S.stripPrefix (Pattern ": ") trimmedCaption <|> S.stripPrefix (Pattern "Table: ") trimmedCaption
    else Nothing
  where
    trimmedCaption = S.trim caption
getCaption _ = unsafeThrowException $ error "getCaption recieved an array with length /= 3"

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
    format = if elem "--markdown" argv then Markdown else Latex
