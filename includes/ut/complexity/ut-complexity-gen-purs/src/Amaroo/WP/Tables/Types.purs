module Amaroo.WP.Tables.Types where

import Prel

import Amaroo.WP.Utils (uniq)
import Data.Array (intercalate)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)

data ColAlignment

type Headings = Array String
type Alignments = {md :: Array String, texTabular :: String}
type Rows = Array (Array String)

data Table = Table Headings Alignments Rows

data LatexTablePos = Hereish | Top | Bottom | TablePage | Override | Here

derive instance eqLTP :: Eq LatexTablePos
derive instance genericLTP :: Generic LatexTablePos _

instance showLTP :: Show LatexTablePos where
  show Hereish = "h"
  show Top = "t"
  show Bottom = "b"
  show TablePage = "p"
  show Override = "!"
  show Here = "H"

newtype TPositioning = TPositioning (Array LatexTablePos)

instance showTPos :: Show TPositioning where
  show :: TPositioning -> String
  show (TPositioning poss) = intercalate "" $ uniq $ show <$> poss

type TMeta = {label :: Maybe String, caption :: Maybe String}

data TableDesc = TD String Table (Array LatexTablePos)
