# Vendored editor code

`codemirror.js` is CodeMirror 6 with Typst syntax support, bundled from
`codemirror-entry.js`:

```sh
npm i codemirror@6.0.2 @codemirror/view @codemirror/state @codemirror/commands @codemirror/lint \
  @codemirror/language @lezer/highlight codemirror-lang-typst@0.6.0 esbuild
npx esbuild codemirror-entry.js --bundle --format=esm --minify --outfile=codemirror.js
```

The Typst compiler (typst-wasm), its fonts, nanotar and the Typst packages the
site uses are not committed: `scripts/build.py --editor` downloads them from npm
and copies them into `dist/edit/vendor/` at build time.
