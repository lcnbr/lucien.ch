// JavaScript twin of tools/site/src/mathml.rs, applied to the editor preview so it
// matches the built site. See that file for why Chromium needs it.
const TAG = /<(\/?)([a-zA-Z0-9]+)((?:\s[^>]*)?)>/g;
const TALL_TAGS = new Set(["mfrac", "mtable", "munderover", "munder", "msqrt", "mroot", "mpadded"]);
const LARGE_OPS = new Set([..."∑∏∐∫∬∭∮∯∰⋀⋁⋂⋃⨀⨁⨂⨄⨆"]);
const FENCES = new Set([..."()[]{}|‖⟨⟩⌈⌉⌊⌋⟦⟧"]);
const FIRST_MO = /^<mo>(.)<\/mo>/u;
const LAST_MO = /<mo>(.)<\/mo>$/u;

function fixMath(math) {
  const edits = [], stack = [];
  for (const m of math.matchAll(TAG)) {
    const closing = m[1] === "/", name = m[2], end = m.index + m[0].length;
    if (!closing && name === "mrow") stack.push({ start: end, tall: false });
    else if (closing && name === "mrow" && stack.length) {
      const frame = stack.pop();
      if (frame.tall) { if (stack.length) stack[stack.length - 1].tall = true; continue; }
      const inner = math.slice(frame.start, m.index);
      const first = inner.match(FIRST_MO), last = inner.match(LAST_MO);
      if (first && last && last.index !== 0 && FENCES.has(first[1]) && FENCES.has(last[1])) {
        edits.push(frame.start + 3, frame.start + last.index + 3);
      }
    } else if (!closing && (TALL_TAGS.has(name) || (name === "mo" && LARGE_OPS.has([...math.slice(end, end + 2)][0])))) {
      for (const f of stack) f.tall = true;
    }
  }
  edits.sort((a, b) => b - a);
  for (const pos of edits) math = math.slice(0, pos) + ' stretchy="false"' + math.slice(pos);
  return math;
}

export const fixMathML = html => html.replace(/<math\b[\s\S]*?<\/math>/g, fixMath);
