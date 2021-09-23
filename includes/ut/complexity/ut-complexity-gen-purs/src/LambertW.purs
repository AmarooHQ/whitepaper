module LambertW where

foreign import gsl_sf_lambert_W0 :: Number -> Number

lambertW :: Number -> Number
lambertW = gsl_sf_lambert_W0
