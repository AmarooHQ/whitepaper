module Main where

import Amaroo.WP.Calcs
import Amaroo.WP.Tables
import Prel

import Amaroo.WP.Formatter (wrap)
import Data.Array (length)
import Effect (Effect)
import Effect.Console as C

wnltn tn = wrap "\n" $ "### TABLE: " <> tn

logTable tn t = do
  C.log $ wnltn tn
  C.log $ showTable t

main :: Effect Unit
main = do
  logTable "tps" tableTps
  logTable "tps_optimized" tableTpsHot
  logTable "dapp-chains" dappChains
  logTable "dapp-chains_optimized" dappChainsHot
  logTable "tps_por" tpsPor
  logTable "tps_port" tpsPort
  logTable "compare_nets_3k" compareNets3k
  logTable "compare_nets_30k" compareNets30k
  logTable "compare_nets_1m_tps" compareNets1mTps
  C.log $ show utVsOther1M
  C.log $ show ut1MCompareKs
