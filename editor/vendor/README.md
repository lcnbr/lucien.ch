# Vendored editor code

`codemirror.js` is CodeMirror 6 with Typst syntax support, bundled from
`codemirror-entry.js`:

```sh
npm i codemirror@6.0.2 @codemirror/view @codemirror/state @codemirror/commands @codemirror/lint \
  @codemirror/language @codemirror/lsp-client@6.3.1 @lezer/highlight codemirror-lang-typst@0.6.0 esbuild
npx esbuild codemirror-entry.js --bundle --format=esm --minify --outfile=codemirror.js
```

The Typst compiler (typst-wasm), its fonts, nanotar and the Typst packages the
site uses are not committed: `cargo site build --editor` downloads them from npm
and copies them into `dist/edit/vendor/` at build time.

Tinymist (the Typst language server behind completion, hover docs and go to
definition) is built for the browser in CI (`.github/workflows/build.yml`,
cached per version) and passed to the build as `TINYMIST_PKG`. Locally, point
`TINYMIST_PKG` at a `wasm-pack` build of `crates/tinymist`; without it the
editor works as before.
