"""Post-process Typst's MathML for Chromium.

Chromium sizes a stretchy vertical operator by the widest of all its size
variants and assembly parts (MathML Core's preferred inline size). In New
Computer Modern Math the largest parenthesis variants are more than twice as
wide as the base glyph, so `f(x)` renders as `f ( x )` in Chrome and Edge.

Delimiters around short content never need to stretch, so this pass marks the
fences of every <mrow> that contains nothing tall (fractions, tables, big
operators, roots...) as stretchy="false". Tall content keeps stretchy fences.
Firefox and Safari render the same with or without the attribute.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

TAG = re.compile(r"<(/?)([a-zA-Z0-9]+)((?:\s[^>]*)?)>")
TALL_TAGS = {"mfrac", "mtable", "munderover", "munder", "msqrt", "mroot", "mpadded"}
LARGE_OPS = set("∑∏∐∫∬∭∮∯∰⋀⋁⋂⋃⨀⨁⨂⨄⨆")
FENCES = set("()[]{}|‖⟨⟩⌈⌉⌊⌋⟦⟧")
FIRST_MO = re.compile(r"<mo>(.)</mo>")
LAST_MO = re.compile(r"<mo>(.)</mo>$")


def fix_math(math: str) -> str:
    edits: list[int] = []  # string offsets right after "<mo" to insert the attribute
    stack: list[dict] = []
    for m in TAG.finditer(math):
        closing, name = m.group(1) == "/", m.group(2)
        if not closing and name == "mrow":
            stack.append({"content_start": m.end(), "tall": False})
        elif closing and name == "mrow" and stack:
            frame = stack.pop()
            if frame["tall"]:
                if stack:
                    stack[-1]["tall"] = True
                continue
            inner = math[frame["content_start"]:m.start()]
            first, last = FIRST_MO.match(inner), LAST_MO.search(inner)
            if first and last and first.start() != last.start() and first.group(1) in FENCES and last.group(1) in FENCES:
                edits.append(frame["content_start"] + 3)
                edits.append(frame["content_start"] + last.start() + 3)
        elif not closing and (name in TALL_TAGS or (name == "mo" and math[m.end():m.end() + 1] in LARGE_OPS)):
            for frame in stack:
                frame["tall"] = True
    for pos in sorted(edits, reverse=True):
        math = math[:pos] + ' stretchy="false"' + math[pos:]
    return math


MATH = re.compile(r"<math\b.*?</math>", re.S)


def fix_html(html: str) -> str:
    return MATH.sub(lambda m: fix_math(m.group(0)), html)


def fix_tree(root: Path) -> int:
    n = 0
    for path in root.rglob("*.html"):
        src = path.read_text(encoding="utf-8")
        out = fix_html(src)
        if out != src:
            path.write_text(out, encoding="utf-8")
            n += 1
    return n


if __name__ == "__main__":
    print(f"mathml_fix: {fix_tree(Path(sys.argv[1]))} files changed")
