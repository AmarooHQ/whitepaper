module Amaroo.WP.Tables.Types where

data ColAlignment

type Headings = Array String
type Alignments = {md :: Array String, texTabular :: String}
type Rows = Array (Array String)

data Table = Table Headings Alignments Rows
