module Main where

import Amaroo.WP.Calcs
import Amaroo.WP.Tables
import Prel

import Amaroo.WP.Formatter (wrap)
import Data.Array (elem, length)
import Effect (Effect)
import Effect.Console as C
import Effect.Exception (error, throwException)
import Undefined (undefined)

foreign import argv :: Array String

genStrToReplace tn = "%% INSERT ### TABLE: " <> tn

wnltn tn = wrap "\n" $ "### TABLE: " <> tn

logTable tn t = do
  C.log $ wnltn tn
  C.log $ showTable t

main :: Effect Unit
main = do
    f "tps" tableTps
    f "tps_optimized" tableTpsHot
    f "dapp-chains" dappChains
    f "dapp-chains_optimized" dappChainsHot
    f "tps_por" tpsPor
    f "tps_port" tpsPort
    f "compare_nets_3k" compareNets3k
    f "compare_nets_30k" compareNets30k
    f "comparison_1m_tps" compareNets1mTps
    -- f "comparison_1gbps" compareNets1Gpbs
    f "compare_optimizations" compareUtOptimizations
    -- C.log $ show utVsOther1M
    -- C.log $ show ut1MCompareKs
    if not checkF
      then throwException $ error "checkF failed"
      else C.log "checkF passed"
  where
    shouldPopulateMd = elem "--populate-wp-md" argv
    f = if shouldPopulateMd then undefined else logTable
    checkF = if shouldPopulateMd then undefined else true
