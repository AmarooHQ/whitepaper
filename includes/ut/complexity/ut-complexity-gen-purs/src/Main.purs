module Main where

import Prel

import Amaroo.WP.Formatter (wrap)
import Amaroo.WP.Tables (compareNets1mTps, compareNets30k, compareNets3k, compareUtOptimizations, compareUtOptimizations2, dappChains, dappChainsHot, showTable, tableTps, tableTpsHot, tpsPor, tpsPort)
import Amaroo.WP.Tables.Booktabs (LatexTablePos(..), TPositioning(..), renderBooktabs)
import Amaroo.WP.Tables.Types (Table(..))
import Control.Alt ((<|>))
import Control.Monad.Error.Class (throwError)
import Control.Monad.State (State, modify_, runState)
import Data.Array (drop, dropWhile, elem, filter, head, intercalate, take, takeWhile)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.String (Pattern(..), Replacement(..), contains, replace)
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

_WP_FILE_PATH = "./output/whitepaper.markdown"

genStrToReplace tn = "%% INSERT ### TABLE: " <> tn

newtype TableName = TableName String


allTables :: Array (Tuple TableName Table)
allTables =
    [ Tuple (TableName "tps") tableTps
    , Tuple (TableName "tps_optimized") tableTpsHot
    , Tuple (TableName "dapp-chains") dappChains
    , Tuple (TableName "dapp-chains_optimized") dappChainsHot
    , Tuple (TableName "tps_por") tpsPor
    , Tuple (TableName "tps_port") tpsPort
    , Tuple (TableName "compare_nets_3k") compareNets3k
    , Tuple (TableName "compare_nets_30k") compareNets30k
    , Tuple (TableName "comparison_1m_tps") compareNets1mTps
    , Tuple (TableName "compare_optimizations") compareUtOptimizations
    , Tuple (TableName "compare_optimizations2") compareUtOptimizations2
    ]


readWhitepaperMd :: Effect String
readWhitepaperMd = do
    -- gitExists <- FS.exists "./.git"
    wpExists <- FS.exists _WP_FILE_PATH
    if wpExists then do
        mdContents <- FS.readFile _WP_FILE_PATH
        B.toString UTF8 mdContents
      else do
        throwError $ error "./output/whitepaper.markdown does not exist -- bailing out."

renderTable :: Table -> TableName -> Maybe String -> String
renderTable table (TableName tn) caption = renderBooktabs (TPositioning [Hereish, Bottom, TablePage, Override]) {label: Just tn, caption} table

insertReplacement :: Table -> TableName -> {before :: Array String, mid :: _, after :: Array String} -> Array String
insertReplacement table tn {before, mid: Just caption, after} = before <> [renderTable table tn caption] <> after
insertReplacement _ _ {before, mid: Nothing, after} = before <> after

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

replaceTable :: Tuple TableName Table -> State String Unit
replaceTable (Tuple _tn@(TableName tn) table) = modify_ replaceTableAndCaption
  where
    replaceTableAndCaption md = md |> lines |> toBeforeTableAfter tn |> insertReplacement table _tn |> intercalate "\n"


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

logTable (Tuple (TableName tn) t) = do
  C.log $ wnltn tn
  C.log $ showTable t

logAllTables = do
  _ <- sequence $ logTable <$> allTables
  pure unit

main :: Effect Unit
main = do
    if shouldPopulateMd
      then replaceAllTablesInWP dryRun
      else logAllTables
  where
    shouldPopulateMd = elem "--populate-wp-md" argv
    dryRun = elem "--dry-run" argv
