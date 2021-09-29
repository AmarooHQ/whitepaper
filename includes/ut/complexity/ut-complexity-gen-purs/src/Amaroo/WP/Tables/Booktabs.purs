module Amaroo.WP.Tables.Booktabs where

import Prel

import Amaroo.WP.Formatter (wrap)
import Amaroo.WP.Tables.Types (Table(..), TPositioning(..), TMeta)
import Amaroo.WP.Utils (uniq)
import Data.Array (intercalate)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Show.Generic (genericShow)
import Data.String as S

renderBooktabs :: TPositioning -> TMeta -> Table -> String
renderBooktabs pos {label, caption} (Table headings aligns table) = intercalate "\n" $
    [ "\\begin{table}[" <> show pos <> "]"
    , "\\centering"
    ] <> captionOrEmpty <>
    [ "\\begin{tabular}{" <> aligns.texTabular <> "}"
    , "\\toprule"
    ] <> ([headings <#> (\h -> "{" <> h <> "}") # intercalate " & " # (_ <> " \\\\")]) <>
    [ "\\midrule"
    ] <> rows <>
    [ "\\bottomrule"
    , "\\end{tabular}"
    , "\\end{table}"
    ]
  where
    rows = (intercalate " & " >>> (_ <> " \\\\")) <$> table
    captionOrEmpty = if S.length clPre == 0 then [] else [clPre]
    clPre = mToL c2 <> mToL l2 # intercalate " "
    c2 = caption <#> (\c -> "\\caption{" <> c <> "}")
    l2 = label <#> (\l -> "\\label{table:" <> l <> "}")
    mToL (Just x) = [x]
    mToL (Nothing) = []
