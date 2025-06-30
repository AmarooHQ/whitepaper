## setup

- `npm i`
- `npx spago test`

in general prefix `spago` and `purs` commands with `npx` (which will run `./node_modules/bin/XXXX`)

- installing packages: `npx spago install XXX`
- repl: `npx spago repl`

you get the idea

## tests

`spago test`

TODO:

* quickcheck tests would be nice
* the markdown table-replace stuff seems to work fine, mb test? probs good to have tests (e.g. for the error msg when tables aren't replaced)

## actually testing table replacement -- command

`spago bundle-app && (cd ../../../../ ; make build-whitepaper ; node includes/ut/complexity/ut-complexity-gen-purs/index.js --populate-wp-md --dry-run)`

## generate and print per capita numbers

`spago bundle-app && node index.js --calc-tx-per-day-per-capita`

## compile new PW on change

`npm run bundle-for-wp -- -w --then "cd ../../../../ && make"`

## compile new LP tables on change

`npm run bundle-for-wp -- -w --then "cd ../../../../ && make mk-lp-tables"`

<!--
## lambert W function

You need to download the (GPL-3 licensed) lambertw.js code yourself.

```bash
LAMW_URL="https://raw.githubusercontent.com/XertroV/lambertw/7c65e241b353e296f58cdad774c77d500d0a11bd/lambertw.js" ;
curl "$LAMW_URL" > src/LambertW.js ;
echo "exports.gsl_sf_lambert_W0 = gsl_sf_lambert_W0;" >> src/LambertW.js
```

```purescript
-- src/LambertW.purs

module LambertW where

foreign import gsl_sf_lambert_W0 :: Number -> Number

lambertW :: Number -> Number
lambertW = gsl_sf_lambert_W0
```
-->
