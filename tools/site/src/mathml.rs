//! Post-process Typst's MathML for Chromium.
//!
//! Chromium sizes a stretchy vertical operator by the widest of all its size
//! variants and assembly parts (MathML Core's preferred inline size). In New
//! Computer Modern Math (and other math fonts with wide large variants) the
//! largest parenthesis variants are much wider than the base glyph, so `f(x)`
//! renders as `f ( x )` in Chrome and Edge.
//!
//! Delimiters around short content never need to stretch, so this pass marks
//! the fences of every <mrow> that contains nothing tall (fractions, tables,
//! big operators, roots...) as stretchy="false". Tall content keeps stretchy
//! fences. Firefox and Safari render the same with or without the attribute.
//! editor/mathml-fix.js does the same in the editor's preview.

use std::fs;
use std::path::Path;
use std::sync::LazyLock;

use anyhow::Result;
use regex::Regex;

use crate::util;

static TAG: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"<(/?)([a-zA-Z0-9]+)((?:\s[^>]*)?)>").unwrap());
static MATH: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"(?s)<math\b.*?</math>").unwrap());
static FIRST_MO: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^<mo>(.)</mo>").unwrap());
static LAST_MO: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"<mo>(.)</mo>$").unwrap());

const TALL_TAGS: [&str; 7] = ["mfrac", "mtable", "munderover", "munder", "msqrt", "mroot", "mpadded"];
const LARGE_OPS: &str = "∑∏∐∫∬∭∮∯∰⋀⋁⋂⋃⨀⨁⨂⨄⨆";
const FENCES: &str = "()[]{}|‖⟨⟩⌈⌉⌊⌋⟦⟧";

struct Frame {
    content_start: usize,
    tall: bool,
}

fn is_fence(s: &str) -> bool {
    let mut cs = s.chars();
    matches!((cs.next(), cs.next()), (Some(c), None) if FENCES.contains(c))
}

pub fn fix_math(math: &str) -> String {
    let mut edits = Vec::new(); // offsets right after "<mo" to insert the attribute at
    let mut stack: Vec<Frame> = Vec::new();
    for m in TAG.captures_iter(math) {
        let whole = m.get(0).unwrap();
        let closing = &m[1] == "/";
        let name = &m[2];
        if !closing && name == "mrow" {
            stack.push(Frame { content_start: whole.end(), tall: false });
        } else if closing && name == "mrow" && !stack.is_empty() {
            let frame = stack.pop().unwrap();
            if frame.tall {
                if let Some(parent) = stack.last_mut() {
                    parent.tall = true;
                }
                continue;
            }
            let inner = &math[frame.content_start..whole.start()];
            if let (Some(first), Some(last)) = (FIRST_MO.captures(inner), LAST_MO.captures(inner)) {
                let (f, l) = (first.get(0).unwrap(), last.get(0).unwrap());
                if f.start() != l.start() && is_fence(&first[1]) && is_fence(&last[1]) {
                    edits.push(frame.content_start + 3);
                    edits.push(frame.content_start + l.start() + 3);
                }
            }
        } else if !closing
            && (TALL_TAGS.contains(&name)
                || (name == "mo" && math[whole.end()..].chars().next().is_some_and(|c| LARGE_OPS.contains(c))))
        {
            for frame in &mut stack {
                frame.tall = true;
            }
        }
    }
    edits.sort_unstable();
    let mut out = math.to_string();
    for pos in edits.into_iter().rev() {
        out.insert_str(pos, " stretchy=\"false\"");
    }
    out
}

pub fn fix_html(html: &str) -> String {
    MATH.replace_all(html, |c: &regex::Captures| fix_math(&c[0])).into_owned()
}

/// Fix every .html file under `root`; returns how many changed.
pub fn fix_tree(root: &Path) -> Result<usize> {
    let mut n = 0;
    for path in util::files(root)? {
        if path.extension().is_none_or(|e| e != "html") {
            continue;
        }
        let src = fs::read_to_string(&path)?;
        let out = fix_html(&src);
        if out != src {
            fs::write(&path, out)?;
            n += 1;
        }
    }
    Ok(n)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn short_fences_do_not_stretch() {
        let m = "<math><mi>f</mi><mrow><mo>(</mo><mi>x</mi><mo>)</mo></mrow></math>";
        assert_eq!(
            fix_math(m),
            "<math><mi>f</mi><mrow><mo stretchy=\"false\">(</mo><mi>x</mi><mo stretchy=\"false\">)</mo></mrow></math>"
        );
    }

    #[test]
    fn tall_fences_stretch() {
        let m = "<math><mrow><mo>(</mo><mfrac><mi>a</mi><mi>b</mi></mfrac><mo>)</mo></mrow></math>";
        assert_eq!(fix_math(m), m);
        let m = "<math><mrow><mo>[</mo><mo>∑</mo><mi>x</mi><mo>]</mo></mrow></math>";
        assert_eq!(fix_math(m), m);
    }
}
