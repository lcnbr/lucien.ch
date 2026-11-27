// CodeMirror 6 + Typst, bundled for the site editor (see README.md).
export { EditorView, keymap } from "@codemirror/view";
export { EditorState, Compartment } from "@codemirror/state";
export { basicSetup } from "codemirror";
export { indentWithTab } from "@codemirror/commands";
export { HighlightStyle, syntaxHighlighting } from "@codemirror/language";
export { tags } from "@lezer/highlight";
export { setDiagnostics, lintGutter } from "@codemirror/lint";
export { typstTags } from "codemirror-lang-typst/lezer";

import { Language, LanguageSupport, languageDataProp } from "@codemirror/language";
import {
  TypstLezerParser, typstLezerLanguageData, typstLezerHighlighting, typstLezerIndentation,
  typstLezerFolding, typstLezerIndentService, typstLezerListKeymap, typstLezerFoldService,
} from "codemirror-lang-typst/lezer";

// Typst language (parser, completion, indentation, folding, list continuation)
// without the package's fixed light-only colours, so the editor can theme it.
export function typst() {
  const parser = new TypstLezerParser(
    languageDataProp.add(t => (t.isTop ? typstLezerLanguageData : undefined)),
    typstLezerHighlighting, typstLezerIndentation, typstLezerFolding);
  return new LanguageSupport(new Language(typstLezerLanguageData, parser, [], "typst"),
    [typstLezerIndentService, typstLezerListKeymap, typstLezerFoldService]);
}

// Language server client (tinymist runs in editor/lsp-worker.js).
export {
  LSPClient, LSPPlugin, Workspace, serverCompletion, hoverTooltips, signatureHelp,
  jumpToDefinition, jumpToDefinitionKeymap,
} from "@codemirror/lsp-client";
