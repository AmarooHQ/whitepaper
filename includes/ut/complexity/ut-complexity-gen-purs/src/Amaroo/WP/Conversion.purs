module Amaroo.WP.Conversion where

import Prel

import Test.QuickCheck (class Arbitrary)

{-|

Quickcheck conversion properties.

In ./includes/ut/20-por/30-comparing-work-3.tex I mention some properties that need to hold.
Sweet, property based testing time.

Additionally, it means defining the conversion functions more specifically.

Example checks:
- does measuring chain-weight in coins work like predicted?

|-}

data State
  = State Int

newtype Timestamp
  = Timestamp Int

class BlockWeight b where
  weightOf :: b -> Number
  timestampOf :: b -> Timestamp

class Network n where
  getFrequencyOf :: n -> State

class
  (BlockWeight b, Network n) <= ConvBlockWeight n b where
  reflectedWeightOf :: n -> b -> Number
  networkInflation :: n -> b -> Number
  ratioTokensOn :: n -> b -> Number

newtype Hashes :: Symbol -> Type
newtype Hashes s
  = Hashes Number

newtype Coins :: Symbol -> Type
newtype Coins s
  = Coins Number

data Confirmations :: Symbol -> Type
data Confirmations s

{-|
network seconds
|-}
data NSeconds :: Symbol -> Type
data NSeconds s

newtype Frac :: Type -> Type -> Type
newtype Frac n d
  = Frac Number

unfrac :: forall a b. Frac a b -> Number
unfrac (Frac n) = n

type Units' :: Type -> Type
type Units' s = Frac s Unit

type FracU :: Type -> Type -> Type
type FracU n d = Frac (Units' n) (Units' d)

derive newtype instance showHashes :: Show (Hashes a)

derive newtype instance showCoins :: Show (Coins a)

derive newtype instance showFrac :: Show (Frac a b)
derive newtype instance eqFrac :: Eq (Frac a b)
derive newtype instance ordFrac :: Ord (Frac a b)
derive newtype instance arbFrac :: Arbitrary (Frac a b)


-- class Frac' :: forall k1 k2. k1 -> k2 -> Constraint
-- class Frac' x y

-- -- (Frac' a b, Frac' i j, Frac' x y) <=
-- class FracReducable i o | i -> o

-- -- :: Type -> Type

-- instance redFracDD :: FracReducable (Frac (Frac a b) (Frac c b)) (Frac a c)
-- -- instance redFracNN :: FracReducable a b a y y b



-- class Conv p a b where
--   conv :: p -> a -> b
-- instance convConvWork :: Conv _ (Hashes "R") (Hashes "L") where
--   conv = convWorkSafe

-- | Exchange rate


{--|

## Network NSeconds

If you want to know relative block frequencies -- **the network participation rate does not count**
like you explicitly *don't* want it to count
Questions like "how long would the L network take to do this thing that R network is doing?"
  aren't able to be answered by relative frequencies.
For that you need to convert *network seconds*

I said that any conversion methods needs to account for *participation*

>  a chain-weight measurement doesn’t account for this, then how does it include participation at all?




consider for same root token:

rr/lr * rf/lf -- unitless, but what does it mean when it's not == 1?

with network-seconds, we have the ratio of l-seconds to r-seconds as the units

it's a measure of relative *work* that each network can do; how long does it take to complete some task (that each network would be equally matched at performing)
do GPU miners provide an example?

no -- it's not that
consider 2 chains, same token same freq same block reward
but L hash takes 2x as long as R hash
(so hashrate of L is 50% R)
difficulty of L is 50% of R
but rr/lr * rf/lf = 1




Maybe reward is not `coins/block` but `coins/block-weight`; i.e. it's actually coins per (d hashes)

freq is block-events per second
confirmation rate is block-weights per second

difficulty is hashes per block-weight
diff * confRate = hashes per second (yeah)

diff * frequency is also hashes per second -- BUT ONLY B/C OF DIFFICULT ADJ ALG -- begging the quesiton when used for conversion? something like that?






|--}


type Xr2l
  = FracU (Coins "L") (Coins "R")

type Rd
  = (FracU (Hashes "R") (Confirmations "R"))

type Rdp
  = (FracU (Hashes "R") (NSeconds "R"))  -- these are *network seconds*

type Rr
  = (FracU (Coins "R") (Confirmations "R"))

type Ld
  = (FracU (Hashes "L") (Confirmations "L"))

type Ldp
  = (FracU (Hashes "L") (NSeconds "L"))

type Lr
  = (FracU (Coins "L") (Confirmations "L"))

type Lhpc
  = (FracU (Hashes "L") (Coins "L"))

type Rhpc
  = (FracU (Hashes "R") (Coins "R"))


type Params
  = { ld :: Ld
    , lr :: Lr
    -- , lf :: Lf
    , rd :: Rd
    , rr :: Rr
    -- , rf :: Rf
    , xrl :: Xr2l
    }

type AuxRates
  = { lhpc :: Lhpc
    , rhpc :: Rhpc
    , lcprb :: FracU (Coins "L") (Confirmations "R")
    }

auxRates :: Params -> AuxRates
auxRates { lr, ld, rr, rd, xrl } =
    { lhpc: divDD ld lr
    , rhpc: divDD rd rr
    , lcprb: multDN xrl rr
    -- , lhprh: divDD lhps rhps
    }
  -- where
    -- lhps = multDN ld lf
    -- rhps = multDN rd rf

invertParams :: Params -> Params
invertParams p =
  { ld: Frac (unfrac p.rd)
  , lr: Frac (unfrac p.rr)
  -- , lf: Frac (unfrac p.rf)
  -- , rf: Frac (unfrac p.lf)
  , rd: Frac (unfrac p.ld)
  , rr: Frac (unfrac p.lr)
  , xrl: Frac (1.0 / unfrac p.xrl)
  }

zeroParams :: Params
zeroParams =
  { ld: Frac 0.0
  , lr: Frac 0.0
  -- , lf: Frac 0.0
  -- , rf: Frac 0.0
  , rr: Frac 0.0
  , rd: Frac 0.0
  , xrl: Frac 0.0
  }

oneParams :: Params
oneParams =
  { ld: Frac 1.0
  , lr: Frac 1.0
  -- , lf: Frac 1.0
  -- , rf: Frac 1.0
  , rr: Frac 1.0
  , rd: Frac 1.0
  , xrl: Frac 1.0
  }

class Units a where
  getRaw :: a -> Number
  makeFrom :: Number -> a

newtype ConvConst :: forall k1 k2 k3. k1 -> k2 -> k3 -> Type
newtype ConvConst a x b
  = ConvConst Number

class
  (Units a, Units x, Units b) <= HasConst a x b where
  convAB :: Params -> ConvConst a x b

class
  (HasConst a x b) <= GetCC a x b where
  getConv :: ConvConst a x b -> Number

instance allGetCC :: (HasConst a x b) => GetCC a x b where
  getConv (ConvConst n) = n

class
  (Units a, Units x, Units b, HasConst a x b, GetCC a x b) <= Invertable a x b where
  conv :: (GetCC a x b) => (HasConst a x b) => Params -> a -> x -> b
  vnoc :: (GetCC a x b) => (HasConst a x b) => Params -> b -> x -> a

instance genInvert :: (Units a, Units x, Units b, GetCC a x b) => Invertable a x b where
  conv p a x = makeFrom $ getRaw a * getConv (convAB p :: ConvConst a x b) * getRaw x
  vnoc p b x = makeFrom $ getRaw b / getConv (convAB p :: ConvConst a x b) / getRaw x

-- instance crPbrTclPbl :: (Units x) => HasConst (Frac (Coins "R") (Confirmations "R")) x (Frac (Coins "L") (Confirmations "L")) where
--   convAB {lf, xrl, rf} = ConvConst (rf / lf * xrl)
-- asdf :: Frac (Coins "L") (Confirmations "L")
-- asdf = conv (zeroParams {lf = 2.0, xrl = 2.0, rf = 1.0}) (Frac 0.88 :: Frac (Coins "R") (Confirmations "R")) (Coins 1.0 :: Coins "R")
-- convReward2 :: Params -> Frac (Coins "R") (Confirmations "R") -> Frac (Coins "L") (Confirmations "L")
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
newtype FromTo a b
  = FromTo Number

-- convD2Dp :: Params -> FromTo Rd Rdp
-- convD2Dp {rf} = FromTo rf
-- convR2D :: Params -> FromTo Rr Rhpc
-- convR2D {rd, rr} = FromTo (rd / rr / rr)

--- # earliest implementations below

convWork { ld, lr, xrl, rr, rd } = (ld / lr * xrl * rr * rd)

convWorkSafe :: _ -> Hashes "R" -> Hashes "L"
convWorkSafe p (Hashes n) = Hashes (n * convWork p)

convIncome { xrl } = xrl

-- note safe
-- convIncomeSafe :: _ -> Frac (Coins "R") (NSeconds "R") -> Frac (Coins "L") (NSeconds "L")
-- convIncomeSafe p (Frac rrPrime) = Frac (rrPrime * convIncome p)

-- wrong
-- convReward { lf, rf, xrl } = (rf / lf * xrl)

-- convRewardSafe :: _ -> Frac (Coins "R") (Confirmations "R") -> Frac (Coins "L") (Confirmations "L")
-- convRewardSafe p (Frac rr) = Frac (rr * convReward p)

-- convRewardToWork p@{ ld, lr } = convReward p * (ld / lr)

-- convRewardToWorkSafe :: _ -> Frac (Coins "R") (Confirmations "R") -> Frac (Hashes "L") (Confirmations "L")
-- convRewardToWorkSafe p (Frac rr) = Frac (rr * convRewardToWork p * p.ld / p.lr)

convDex { ld, lf, lr, rf, xrl } = (*) (ld / lr * xrl * rf / lf)

convDexSafe :: _ -> Frac (Coins "R") (Confirmations "R") -> Frac (Hashes "L") (Confirmations "L")
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

multD :: forall a b. Units' b -> Frac (Units' a) (Units' b) -> (Units' a)
multD (Frac x) (Frac y) = Frac (x * y)

divN :: forall a b. Units' a -> Frac (Units' a) (Units' b) -> (Units' b)
divN (Frac y) (Frac r) = Frac (y / r)

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

test1 :: Params -> Units' (Confirmations "R") -> (Units' (Hashes "R"))
test1 { rd } b = multD b rd

-- rr2Lr :: Params -> Rr -> Lr
-- rr2Lr p rr = multDN (multDN p.xrl rr) (divDD p.rf p.lf)

-- rd2Ld :: Params -> Rd -> Ld
-- rd2Ld { ld, lr, xrl, rr, rf, lf } rd = lhpb
--   where
--   rcph = (divDD rr rd) :: FracU (Coins "R") (Hashes "R")
--   -- rcplb = ?asdf :: FracU (Coins "R") (Confirmations "L")
--   lcprh = (multDN xrl rcph) :: FracU (Coins "L") (Hashes "R")
--   lbprh = divNN lcprh lr :: FracU (Confirmations "L") (Hashes "R")
--   lhprh = multND lbprh ld :: FracU (Hashes "L") (Hashes "R")
--   lhprb = multDN lhprh rd :: FracU (Hashes "L") (Confirmations "R")
--   lhps = multDN lhprb rf :: FracU (Hashes "L") (NSeconds)
--   lhpb = divDD lhps lf :: FracU (Hashes "L") (Confirmations "L")

-- rd2Ld :: Params -> Rd -> Ld
-- rd2Ld p rd = (rd2Rr p >>> rr2Lr p >>> lr2Ld p) rd

-- ld2Rd :: Params -> Ld -> Rd
-- ld2Rd p@{rr, xrl} ld = res
--   where
--     {lhpc} = auxRates p
--     lcprb = multDN xrl rr :: FracU (Coins "L") (Confirmations "R")
--     lhprb = multDN lhpc lcprb :: FracU (Hashes "L") (Confirmations "R")
--     res = (multDN ?a lhprb) :: Rd

rr2Ld :: Params -> Rr -> Ld
rr2Ld { ld, lr, xrl } rr = res
  where
  ldplr = divDD ld lr :: FracU (Hashes "L") (Coins "L")
  lcprb = multDN xrl rr :: FracU (Coins "L") (Confirmations "R")
  lhprb = multND lcprb ldplr :: FracU (Hashes "L") (Confirmations "R")
  -- rhplh = divDD rd lhprb :: FracU (Hashes "R") (Hashes "L")
  -- lc2lh = divDD ld lr :: FracU (Hashes "L") (Coins "L")
  -- rc2rh = divDD rd rr :: FracU (Hashes "R") (Coins "R")
  rb2lb = divNN (multND rr xrl) lr :: FracU (Confirmations "L") (Confirmations "R")
  res = divDD lhprb rb2lb :: Ld

rd2Rr :: Params -> Rd -> Rr
rd2Rr p rd = p.rr `divDD` p.rd `multDN` rd

rd2Rr2 :: Params -> Rd -> Rr
rd2Rr2 p rd = mulRate (invert p.rd) v1
  where
    v1 = p.rr `mul'` rd :: Frac (FracU (Coins "R") (Confirmations "R")) (FracU (Confirmations "R") (Hashes "R"))
-- rd2Lr :: Params -> Rd -> Lr
-- rd2Lr {xrl, rf, lf} rd = multDN xrl (multND rd (aux.rcph)) `multDN` (divDD rf lf)

lr2Ld :: Params -> Lr -> Ld
lr2Ld p lr = multDN aux.lhpc lr
  where
    aux = (auxRates p)

-- lcps2Rcps :: Params -> Lcps -> Rcps
-- lcps2Rcps {xrl} lcps = divNN lcps xrl

-- rcps2Lcps :: Params -> Rcps -> Lcps
-- rcps2Lcps {xrl} rcps = multDN xrl rcps

-- lhprh = multDN ldplr lcprb :: FracU (Hashes "L") (Hashes "R")
-- lhprh = multDN ldplr lcprd :: FracU (Hashes "L") (Hashes "R")
-- test4 :: Params -> _ -> Frac _ _
-- test4 { rd, rr, ld, lr, xrl } x = ?asdf `mul'` ldplr `mul'` (multND rr xrl)
--   where
--   -- rrp = multDN rr rf :: FracU (Coins "R") (NSeconds "R")
--   -- rrplb = divDD rrp lf :: FracU (Coins "R") (Confirmations "L")
--   ldplr' = div' ld lr :: Frac Ld Lr
--   ldplr = cancelD ldplr' :: FracU (Hashes "L") (Coins "L")

convWorkR2L :: Params -> Units' (Hashes "R") -> Units' (Hashes "L")
convWorkR2L { ld, lr, xrl, rd, rr } x = multD x $ multDN (divDD ld lr) (multDN xrl (divDD rr rd))

convWorkL2R :: Params -> Units' (Hashes "L") -> Units' (Hashes "R")
convWorkL2R { ld, lr, xrl, rd, rr } x = res
  where
    lhprh = multDN (divDD ld lr) (multDN xrl (divDD rr rd)) :: FracU (Hashes "L") (Hashes "R")
    res = divN x lhprh





rb2Lb_reward :: Params -> Units' (Confirmations "R") -> Units' (Confirmations "L")
rb2Lb_reward {rr, lr, xrl} b = multD b $ multDN (invert lr) $ multND rr xrl

-- lb2Rb_freq :: Params -> Units' (Confirmations "L") -> Units' (Confirmations "R")
-- lb2Rb_freq {rf, lf} b = multD b $ (divDD rf lf)


{----

Rd * Rf / Lf => R-hashes done per L-blocks
Ld           => L-hashes done per L-blocks


Rd / Ld -> R-hashes per L-hashes



idea: don't include frequency
do we need to scale based on frequency in the conversion?


rd / ld => rh / lh ---- normalized against time

rr / rh * xrl *
           - l coins per r hash


CONVERTING REQUIRES SYMMETRY?
i.e. each side is built up the same -- well you need to use the same constant of conversion


ld/lr * xrl   * rr/rd        lh / rh    ---- RATIO OF HASHES OVER VALUE

ld/1  * lf/rf *  1/rd        lh / rh    ---- RATIO OF HASHES OVER TIME


% \begin{algorithm}
% \caption{A \textsc{WeightOf} function for PoR between chains with a different root token and equal block frequencies}
% \label{alg:weightof-dex}
% \begin{algorithmic}
% \Procedure{WeightOf}{$B_i, state$} \Comment{The weight of a block normalized to coins}
%     \State $t \gets$ \Call{BlockTimestamp}{$B_i$}
%     \State $C \gets$ \Call{ChainOf}{$B_i$, $state$}
%     \State $C_r \gets$ \Call{BlockRewardOfChainAt}{$C$, $t$, $state$} \Comment{Block reward of $C$ at $t$}
%     % \State $C_f \gets$ \Call{BlockFrequencyOfChain}{$C$} \Comment{Block production Hz of $C$}
%     \State $X_{C\rightarrow L} \gets$ \Call{ExchangeRateOfCoinToLocalAt}{$C$, $t$, $state$}
%     \State \Return{$C_r \cdot X_{C\rightarrow L}$}
% \EndProcedure
% \end{algorithmic}
% \end{algorithm}




Lcoins / xrl -> Rcoins

exchange rate = 1
-- inflation rate = same



10 coins / block vs 20 coins / block ---> implies difference in frequency of blocks (2:1)




----}
