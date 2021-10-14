module Amaroo.WP.Conversion where

import Prel

-- import Data.Tuple (Tuple(..))
-- import Prelude (class Semiring)

{-|

Quickcheck conversion properties.

In ./includes/ut/20-por/30-comparing-work-3.tex I mention some properties that need to hold.
Sweet, property based testing time.

Additionally, it means defining the conversion functions more specifically.

Example checks:
- does measuring chain-weight in coins work like predicted?

|-}

-- weightOf_coinsSimple :: Block -> State -> Number
-- weightOf_coinsSimple b state = blockRewardOfAt_coinsSimple (chainOf b) (b.timestamp) state

-- weightOf_

data State = State Int

newtype Timestamp = Timestamp Int

class BlockWeight b where
  weightOf :: b -> Number
  timestampOf :: b -> Timestamp

class Network n where
  getFrequencyOf :: n -> State

class (BlockWeight b, Network n) <= ConvBlockWeight n b where
  reflectedWeightOf :: n -> b -> Number
  networkInflation :: n -> b -> Number
  ratioTokensOn :: n -> b -> Number

-- data Blocks :: forall s. s -> Type
-- data Blocks s
-- data Coins :: forall s. s -> Type
-- data Coins s
-- data Hashes :: forall s. s -> Type
-- data Hashes s
-- data Seconds

-- data Prod :: forall k1 k2. k1 -> k2 -> Type
-- data Prod a b
-- data Div :: forall k1 k2. k1 -> k2 -> Type
-- data Div a b

-- -- data Combination n = Unit n | Prod (Combination) Combination | Div Combination Combination

-- class DoMult a b where
--   mult :: a -> b -> Prod a b

-- class IsCombo :: forall k. k -> Constraint
-- class IsCombo c

-- class ComboProd :: forall k. Type -> Type -> k -> Constraint
-- class (IsCombo c) <= ComboProd a b c | a b -> c where
--   asdf :: a -> b -> Boolean

newtype Hashes :: forall k. k -> Type
newtype Hashes s = Hashes Number
newtype Coins :: forall k. k -> Type
newtype Coins s = Coins Number
data Blocks :: forall k. k -> Type
data Blocks s
data Seconds
newtype Frac :: forall k j. k -> j -> Type
newtype Frac n d = Frac Number

type Units' :: forall k. k -> Type
type Units' s = Frac s Unit

derive newtype instance showHashes :: Show (Hashes a)
derive newtype instance showCoins :: Show (Coins a)
derive newtype instance showFrac :: Show (Frac a b)

-- class Conv p a b where
--   conv :: p -> a -> b

-- instance convConvWork :: Conv _ (Hashes "R") (Hashes "L") where
--   conv = convWorkSafe

-- type Params =
--   { lf :: Frac (Blocks "L") (Seconds)
--   , lr :: Frac (Coins "L") (Blocks "L")
--   , ld :: Frac (Hashes "L") (Blocks "L")
--   , rf :: Frac (Blocks "R") (Seconds)
--   , rr :: Frac (Coins "R") (Blocks "R")
--   , rd :: Frac (Hashes "R") (Blocks "R")
--   , xrl :: Frac (Coins "L") (Coins "R")
--   }

type Params =
  { lf :: Number
  , lr :: Number
  , ld :: Number
  , rf :: Number
  , rr :: Number
  , rd :: Number
  , xrl :: Number
  }

-- zeroParams :: Params
-- zeroParams =
--   { lf: Frac 0.0
--   , lr: Frac 0.0
--   , ld: Frac 0.0
--   , rf: Frac 0.0
--   , rr: Frac 0.0
--   , rd: Frac 0.0
--   , xrl: Frac 0.0
--   }

-- oneParams :: Params
-- oneParams =
--   { lf: Frac 1.0
--   , lr: Frac 1.0
--   , ld: Frac 1.0
--   , rf: Frac 1.0
--   , rr: Frac 1.0
--   , rd: Frac 1.0
--   , xrl: Frac 1.0
--   }

zeroParams :: Params
zeroParams =
  { lf: 0.0
  , lr: 0.0
  , ld: 0.0
  , rf: 0.0
  , rr: 0.0
  , rd: 0.0
  , xrl: 0.0
  }

oneParams :: Params
oneParams =
  { lf: 1.0
  , lr: 1.0
  , ld: 1.0
  , rf: 1.0
  , rr: 1.0
  , rd: 1.0
  , xrl: 1.0
  }

class Units a where
  getRaw :: a -> Number
  makeFrom :: Number -> a

newtype ConvConst :: forall k1 k2 k3. k1 -> k2 -> k3 -> Type
newtype ConvConst a x b = ConvConst Number

class (Units a, Units x, Units b) <= HasConst a x b where
  convAB :: Params -> ConvConst a x b

class (HasConst a x b) <= GetCC a x b where
  getConv :: ConvConst a x b -> Number

instance allGetCC :: (HasConst a x b) => GetCC a x b where
  getConv (ConvConst n) = n

class (Units a, Units x, Units b, HasConst a x b, GetCC a x b) <= Invertable a x b where
  conv :: (GetCC a x b) => (HasConst a x b) => Params -> a -> x -> b
  vnoc :: (GetCC a x b) => (HasConst a x b) => Params -> b -> x -> a

instance genInvert :: (Units a, Units x, Units b, GetCC a x b) => Invertable a x b where
  conv p a x = makeFrom $ getRaw a * getConv (convAB p :: ConvConst a x b) * getRaw x
  vnoc p b x = makeFrom $ getRaw b / getConv (convAB p :: ConvConst a x b) / getRaw x


instance crPbrTclPbl :: (Units x) => HasConst (Frac (Coins "R") (Blocks "R")) x (Frac (Coins "L") (Blocks "L")) where
  convAB {lf, xrl, rf} = ConvConst (rf / lf * xrl)

asdf :: Frac (Coins "L") (Blocks "L")
asdf = conv (zeroParams {lf = 2.0, xrl = 2.0, rf = 1.0}) (Frac 0.88 :: Frac (Coins "R") (Blocks "R")) (Coins 1.0 :: Coins "R")

convReward2 :: Params -> Frac (Coins "R") (Blocks "R") -> Frac (Coins "L") (Blocks "L")
convReward2 p rr = conv p rr (Coins 1.0)

-- class ConvToRate a b o | a b -> o

instance uCoins :: Units (Coins c) where
  getRaw (Coins n) = n
  makeFrom n = Coins n

instance uHashes :: Units (Hashes c) where
  getRaw (Hashes n) = n
  makeFrom n = Hashes n

instance uFrac :: Units (Frac a b) where
  getRaw (Frac n) = n
  makeFrom n = Frac n

newtype FromTo :: forall k1 k2. k1 -> k2 -> Type
newtype FromTo a b = FromTo Number

type Rd = (Frac (Hashes "R") (Blocks "R"))
type Rdp = (Frac (Hashes "R") (Seconds))
type Rf = (Frac (Blocks "R") (Seconds))
type Rr = (Frac (Coins "R") (Blocks "R"))
type Rhpc = (Frac (Hashes "R") (Coins "R"))

convD2Dp :: Params -> FromTo Rd Rdp
convD2Dp {rf} = FromTo rf

convR2D :: Params -> FromTo Rr Rhpc
convR2D {rd, rr} = FromTo (rd / rr / rr)



--| # earliest implementations below

convWork {ld, lr, xrl, rr, rd} = (ld / lr * xrl * rr * rd)
convWorkSafe :: _ -> Hashes "R" -> Hashes "L"
convWorkSafe p (Hashes n) = Hashes (n * convWork p)

convIncome {xrl} = xrl
convIncomeSafe :: _ -> Frac (Coins "R") (Seconds) -> Frac (Coins "L") (Seconds)
convIncomeSafe p (Frac rrPrime) = Frac (rrPrime * convIncome p)

convReward {lf, rf, xrl} = (rf / lf * xrl)
convRewardSafe :: _ -> Frac (Coins "R") (Blocks "R") -> Frac (Coins "L") (Blocks "L")
convRewardSafe p (Frac rr) = Frac (rr * convReward p)

convRewardToWork p@{ld, lr} = convReward p * (ld / lr)
convRewardToWorkSafe :: _ -> Frac (Coins "R") (Blocks "R") -> Frac (Hashes "L") (Blocks "L")
convRewardToWorkSafe p (Frac rr) = Frac (rr * convRewardToWork p * p.ld / p.lr)

convDex {ld, lf, lr, rf, xrl} = (*) (ld / lr * xrl * rf / lf)
convDexSafe :: _ -> Frac (Coins "R") (Blocks "R") -> Frac (Hashes "L") (Blocks "L")
convDexSafe p (Frac rr) = Frac (convDex p rr)

{-|
# thoughts

constant of conversion is always a *rate*.

But rates also have constant of conversions: rates of rates.

say:

f :: X -> Y
f x = (v1 :: V1) * x

well then V1 must be of type (Y/X)

so, what if you had some

g :: V1 -> V2
g v1 = (u1 :: U1) * v1

let's say V2 is of type (Z/W)

then U1 must be of type ((Z/W)/(Y/X)) = XZ/Y/W

in full g :: (Y/X) -> (Z/W)

Call the numberator of X: N[X]
Call the denominator of X: D[X]

so U1 is D[V1] * N[V2] / N[V1] / D[V2]
       = D[F]  * N[T]  / N[F]  / D[T]
F (From) = V1
T (To) = V2

|-}


invert :: forall a b. Frac a b -> Frac b a
invert (Frac n) = Frac (1.0 / n)

multDN :: forall a b c. Frac a b -> Frac b c -> Frac a c
multDN (Frac x) (Frac y) = Frac (x * y)

multND :: forall a b c. Frac a b -> Frac c a -> Frac c b
multND (Frac x) (Frac y) = Frac (x * y)

divDD :: forall a b c. Frac a b -> Frac c b -> Frac a c
divDD x y = multDN x (invert y)

divNN :: forall a b c. Frac a b -> Frac a c -> Frac c b
divNN x y = multND x (invert y)

multD :: forall a b. Frac a (Units' b) -> (Units' b) -> Units' a
multD (Frac x) (Frac y) = Frac (x * y)

divN :: forall a b. Frac (Units' a) b -> (Units' a) -> Frac Unit b
divN (Frac x) (Frac y) = Frac (x / y)

div_ :: forall a b. Frac a b -> Frac a b -> Frac Unit Unit
div_ (Frac x) (Frac y) = Frac (x / y)

mul_ :: forall a b. Frac a b -> Frac b a -> Frac Unit Unit
mul_ (Frac x) (Frac y) = Frac (x * y)
