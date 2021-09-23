## setup

- `npm i`
- `npx spago test`

in general prefix `spago` and `purs` commands with `npx` (which will run `./node_modules/bin/XXXX`)

- installing packages: `npx spago install XXX`
- repl: `npx spago repl`

you get the idea

## lambert W function

You need to download the (GPL-3 licensed) lambertw.js code yourself.

```bash
LAMW_URL="https://raw.githubusercontent.com/XertroV/lambertw/7c65e241b353e296f58cdad774c77d500d0a11bd/lambertw.js" ;
curl "$LAMW_URL" > src/LambertW.js ;
echo "exports.gsl_sf_lambert_W0 = gsl_sf_lambert_W0;" >> src/LambertW.js
```
