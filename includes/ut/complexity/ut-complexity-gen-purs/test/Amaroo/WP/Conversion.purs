module Test.Amaroo.WP.Conversion (convQuickChecks) where

import Prel

import Amaroo.WP.Conversion (Frac(..), convWorkL2R, convWorkR2L, rd2Rr, rd2Rr2)
import Test.Spec (Spec, describe, it)
import Test.Spec.QuickCheck (quickCheck)
import Test.Amaroo.WP.Calcs (isWithin)
import Test.QuickCheck ((<?>))




convQuickChecks :: Spec Unit
convQuickChecks = do
  describe "Conversion quickchecks" do
    -- it "checkCpsRoundTrip" do
    --   quickCheck checkCpsRoundTrip
    it "checkWorkRoundTrip" do
      quickCheck checkWorkRoundTrip
    -- it "checkDiffRoundTrip" do
    --   quickCheck checkDiffRoundTrip
    -- it "lb2Rb_reward" do
    --   quickCheck \n p -> (rb2Lb_reward p <<< lb2Rb_freq p) n `fracsMatch` n
    it "rd2Rr and rd2Rr2 match" do
      quickCheck \n p -> rd2Rr p n `fracsMatch` rd2Rr2 p n

fracsMatch :: forall a b. Frac a b -> Frac a b -> Boolean
fracsMatch (Frac x) (Frac y) = isWithin 0.0000001 x y

-- checkCpsRoundTrip :: _
-- checkCpsRoundTrip = \n p -> (lcps2Rcps p >>> rcps2Lcps p) n `fracsMatch` n <?> ("lcps: " <> show n <> "\nparams: " <> show p)

checkWorkRoundTrip :: _
checkWorkRoundTrip = \n p -> (convWorkR2L p >>> convWorkL2R p) n `fracsMatch` n <?> (show {n, p})

-- checkDiffRoundTrip :: _
-- checkDiffRoundTrip = \n p -> (ld2Rd p <<< rd2Ld p) n `fracsMatch` n <?> (show {n, p})
