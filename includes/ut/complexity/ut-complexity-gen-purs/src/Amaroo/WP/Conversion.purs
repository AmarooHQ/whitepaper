module Amaroo.WP.Conversion where

import Prel

import Prelude (class Semiring)

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

unfrac :: forall a b. Frac a b -> Number
unfrac (Frac n) = n

type Units' :: forall k. k -> Type
type Units' s = Frac s Unit

type FracU n d = Frac (Units' n) (Units' d)

derive newtype instance showHashes :: Show (Hashes a)
derive newtype instance showCoins :: Show (Coins a)
derive newtype instance showFrac :: Show (Frac a b)

-- class Conv p a b where
--   conv :: p -> a -> b

-- instance convConvWork :: Conv _ (Hashes "R") (Hashes "L") where
--   conv = convWorkSafe

type Xr2l = FracU (Coins "L") (Coins "R")

type Rd = (FracU (Hashes "R") (Blocks "R"))
type Rdp = (FracU (Hashes "R") (Seconds))
type Rf = (FracU (Blocks "R") (Seconds))
type Rr = (FracU (Coins "R") (Blocks "R"))
type Rhpc = (FracU (Hashes "R") (Coins "R"))

type Ld = (FracU (Hashes "L") (Blocks "L"))
type Ldp = (FracU (Hashes "L") (Seconds))
type Lf = (FracU (Blocks "L") (Seconds))
type Lr = (FracU (Coins "L") (Blocks "L"))
type Lhpc = (FracU (Hashes "L") (Coins "L"))


type Params =
  { lf :: Lf
  , lr :: Lr
  , ld :: Ld
  , rf :: Rf
  , rr :: Rr
  , rd :: Rd
  , xrl :: Xr2l
  }

invertParams :: Params -> Params
invertParams p =
  { lf: Frac (unfrac p.rf)
  , lr: Frac (unfrac p.rr)
  , ld: Frac (unfrac p.rd)
  , rf: Frac (unfrac p.lf)
  , rr: Frac (unfrac p.lr)
  , rd: Frac (unfrac p.ld)
  , xrl: Frac (1.0 / unfrac p.xrl)
  }

zeroParams :: Params
zeroParams =
  { lf: Frac 0.0
  , lr: Frac 0.0
  , ld: Frac 0.0
  , rf: Frac 0.0
  , rr: Frac 0.0
  , rd: Frac 0.0
  , xrl: Frac 0.0
  }

oneParams :: Params
oneParams =
  { lf: Frac 1.0
  , lr: Frac 1.0
  , ld: Frac 1.0
  , rf: Frac 1.0
  , rr: Frac 1.0
  , rd: Frac 1.0
  , xrl: Frac 1.0
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


-- instance crPbrTclPbl :: (Units x) => HasConst (Frac (Coins "R") (Blocks "R")) x (Frac (Coins "L") (Blocks "L")) where
--   convAB {lf, xrl, rf} = ConvConst (rf / lf * xrl)

-- asdf :: Frac (Coins "L") (Blocks "L")
-- asdf = conv (zeroParams {lf = 2.0, xrl = 2.0, rf = 1.0}) (Frac 0.88 :: Frac (Coins "R") (Blocks "R")) (Coins 1.0 :: Coins "R")

-- convReward2 :: Params -> Frac (Coins "R") (Blocks "R") -> Frac (Coins "L") (Blocks "L")
-- convReward2 p rr = conv p rr (Coins 1.0)

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


-- convD2Dp :: Params -> FromTo Rd Rdp
-- convD2Dp {rf} = FromTo rf

-- convR2D :: Params -> FromTo Rr Rhpc
-- convR2D {rd, rr} = FromTo (rd / rr / rr)



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
multND = flip multDN
-- multND (Frac x) (Frac y) = Frac (x * y)

-- instance semiringFrac :: Semiring (Frac a b) where
--   add :: (Frac a b) -> (Frac a b) -> Frac a b
--   add (Frac x) (Frac y) = Frac (x + y)
--   zero = Frac zero
--   one = Frac one
--   -- this isn't right w/ units :/
--   mul :: (Frac a b) -> (Frac a b) -> Frac a b
--   mul (Frac x) (Frac y) = Frac (x * y)

divDD :: forall a b c. Frac a b -> Frac c b -> Frac a c
divDD x y = multDN x (invert y)

divNN :: forall d e n. Frac n d -> Frac n e -> Frac e d
divNN x y = multND x (invert y)

div' :: forall a d b e. Frac a d -> Frac b e -> Frac (Frac a d) (Frac b e)
div' (Frac x) (Frac y) = Frac (x * y)

mul' :: forall a d b e. Frac a d -> Frac b e -> Frac (Frac a d) (Frac e b)
mul' (Frac x) (Frac y) = Frac (x * y)

multD :: forall a b. (Units' b) -> Frac (Units' a) (Units' b) -> Units' a
multD (Frac x) (Frac y) = Frac (x * y)

divN :: forall a b. (Units' a) -> Frac (Units' a) b -> Frac Unit b
divN (Frac y) (Frac x) = Frac (y / x)

div_ :: forall a b. Frac a b -> Frac a b -> Frac Unit Unit
div_ (Frac x) (Frac y) = Frac (x / y)

mul_ :: forall a b. Frac a b -> Frac b a -> Frac Unit Unit
mul_ (Frac x) (Frac y) = Frac (x * y)

mulRate :: forall a b m n. Frac a b -> Frac (Frac m n) (Frac a b) -> Frac m n
mulRate (Frac x) (Frac y) = Frac (x * y)

cancelD :: forall a b c. Frac (Frac a b) (Frac c b) -> Frac a c
cancelD (Frac x) = Frac x

cancelN :: forall a b c. Frac (Frac a b) (Frac a c) -> Frac c b
cancelN (Frac x) = Frac x

--| reorg, swap denom of numerator with numerator of denom.
--| (x/y) / (a/b) = bx/ay = (x/a) / (y/b)
swapDN :: forall a b c d. Frac (Frac a b) (Frac c d) -> Frac (Frac a c) (Frac b d)
swapDN (Frac x) = Frac x

--| reorg, swap numerator of numerator with denom of denom.
--| (x/y) / (a/b) = bx/ay = (b/y) / (a/x)
swapND :: forall a b c d. Frac (Frac a b) (Frac c d) -> Frac (Frac d b) (Frac c a)
swapND (Frac x) = Frac x

test1 :: Params -> Units' (Blocks "R") -> (Units' (Hashes "R"))
test1 {rd} b = multD b rd

-- test11 :: Params -> FracU (Coins "R")

test2 :: Params -> Rd -> Ld
test2 {ld, lr, xrl, rr, rf, lf} rd = lhpb
  where
    rcph = (divDD rr rd) :: FracU (Coins "R") (Hashes "R")
    -- rcplb = ?asdf :: FracU (Coins "R") (Blocks "L")
    lcprh = (multDN xrl rcph) :: FracU (Coins "L") (Hashes "R")
    lbprh = divNN lcprh lr :: FracU (Blocks "L") (Hashes "R")
    lhprh = multND lbprh ld :: FracU (Hashes "L") (Hashes "R")
    lhprb = multDN lhprh rd :: FracU (Hashes "L") (Blocks "R")
    lhps = multDN lhprb rf :: FracU (Hashes "L") (Seconds)
    lhpb = divDD lhps lf :: FracU (Hashes "L") (Blocks "L")

test3 :: Params -> Rr -> Ld
test3 {ld, lr, xrl} rr = res
  where
    ldplr = divDD ld lr :: FracU (Hashes "L") (Coins "L")
    lcprb = multDN xrl rr :: FracU (Coins "L") (Blocks "R")
    lhprb = multND lcprb ldplr :: FracU (Hashes "L") (Blocks "R")
    -- rhplh = divDD rd lhprb :: FracU (Hashes "R") (Hashes "L")
    -- lc2lh = divDD ld lr :: FracU (Hashes "L") (Coins "L")
    -- rc2rh = divDD rd rr :: FracU (Hashes "R") (Coins "R")
    rb2lb = divNN (multND rr xrl) lr :: FracU (Blocks "L") (Blocks "R")
    res = divDD lhprb rb2lb

    -- lhprh = multDN ldplr lcprb :: FracU (Hashes "L") (Hashes "R")
    -- lhprh = multDN ldplr lcprd :: FracU (Hashes "L") (Hashes "R")

test4 :: Params -> _ -> Frac _ _
test4 {rd, rf, rr, ld, lf, lr, xrl} x = rfplf `mul'` ldplr `mul'` (multND rr xrl)
  where
    rrp = multDN rr rf :: FracU (Coins "R") (Seconds)
    rrplb = divDD rrp lf :: FracU (Coins "R") (Blocks "L")
    ldplr = cancelD $ div' ld lr
    rfplf = divDD rf lf :: FracU (Blocks "R") (Blocks "L")

convWork3 :: Params -> Units' (Hashes "R") -> Frac (Hashes "L") Unit
convWork3 {ld, lr, xrl, rd, rr} x = multD x $ multDN (divDD ld lr) (multDN xrl (divDD rr rd))
