module Test.Amaroo.WP.Tables.Booktabs (booktabsSpec) where

import Prel

import Amaroo.WP.Tables.Types (Table(..), LatexTablePos(..), TPositioning(..))
import Amaroo.WP.Tables.Booktabs (renderBooktabs)
import Data.Array (zip)
import Data.Foldable (sequence_)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), Replacement(..))
import Data.String as S
import Data.String.Utils (lines)
import Data.Tuple (Tuple(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)


booktabsSpec :: Spec Unit
booktabsSpec = do
  describe "booktabs" do
    positioningSpec
    renderBooktabsSpec


positioningSpec :: Spec Unit
positioningSpec = do
  describe "positioning" do
    it "show" do
      show (TPositioning [Hereish, Top, Bottom, TablePage, Override, Here, Here, Hereish])
        `shouldEqual` "htbp!H"


booktabsSample = """\begin{table}[!hbp]
\centering
\caption{Some caption for the table} \label{table:mytable}
\begin{tabular}{llll}
\toprule
{Id} & {$N_T$} & {$E_p$ [keV]} & {Something $\Delta E$ [keV]} \\
\midrule
1 & 1234(567) & 10 & 34(7) \\
2 & 8900(200) & 200 & 27(6) \\
3 & 3570(170) & 3000 & 21(6) \\
4 & 1590(420) & 40000 & 22(5) \\
\bottomrule
\end{tabular}
\end{table}"""

sampleTable = Table
    ["Id", "$N_T$", "$E_p$ [keV]", "Something $\\Delta E$ [keV]"]
    {md: [], texTabular: "llll"}
    [ ["1", "1234(567)", "10", "34(7)"]
    , ["2", "8900(200)", "200", "27(6)"]
    , ["3", "3570(170)", "3000", "21(6)"]
    , ["4", "1590(420)", "40000", "22(5)"]
    ]

samplePos = (TPositioning [Override, Hereish, Bottom, TablePage])
sampleLabel = {label: Just "mytable", caption: Just "Some caption for the table"}

renderedSample = renderBooktabs samplePos sampleLabel sampleTable

renderedSNoLabel = renderBooktabs samplePos (sampleLabel {label = Nothing}) sampleTable

renderedSNoCaption = renderBooktabs samplePos (sampleLabel {caption = Nothing}) sampleTable

renderedSNoMeta = renderBooktabs samplePos ({label: Nothing, caption: Nothing}) sampleTable

renderBooktabsSpec :: Spec Unit
renderBooktabsSpec = describe "render" do
    it "matches sample" do
      let sampleLines = lines booktabsSample
          renderedLines = lines renderedSample
          pairs = zip sampleLines renderedLines
      sequence_ $ do
        (Tuple l1 l2) <- pairs
        pure $ shouldEqual l1 l2
      booktabsSample `shouldEqual` renderedSample
      (S.replace (Pattern " \\label{table:mytable}") (Replacement "") booktabsSample) `shouldEqual` renderedSNoLabel
      (S.replace (Pattern "\\caption{Some caption for the table} ") (Replacement "") booktabsSample) `shouldEqual` renderedSNoCaption
      (S.replace (Pattern "\\caption{Some caption for the table} \\label{table:mytable}\n") (Replacement "") booktabsSample) `shouldEqual` renderedSNoMeta
