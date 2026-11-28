//! build/manifest.json: every page to build (slug, section, source path,
//! output path, URL, git dates), the drafts left out, and the assets.
//! site.typ reads it to make one document per page.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::LazyLock;

use anyhow::{bail, Result};
use regex::Regex;
use serde_json::{json, Value};

use crate::util;

static DATED: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^(\d{4}-\d{2}-\d{2})-(.+)$").unwrap());
static TEMPLATE_CALL: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"\A#show:\s*(?:post|note|page)\.with\(").unwrap());
static DRAFT_ARG: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"draft\s*:\s*true").unwrap());
static LABEL: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"<([A-Za-z_][\w:.-]*)>").unwrap());

pub struct Page {
    pub slug: String,
    pub section: &'static str,
    pub path: String,
    pub out: String,
    pub url: String,
    pub date: Option<String>,
    pub created: String,
    pub updated: String,
    pub draft: bool,
}

pub struct Manifest {
    pub pages: Vec<Page>,
    /// Slugs of the drafts left out of this build, and the labels they define
    /// (equations, figures, sections), so links into them can be dropped too.
    pub hidden: Vec<String>,
    pub assets: Vec<(String, String)>,
}

fn word(c: char) -> bool {
    c.is_alphanumeric() || c == '_'
}

/// True if the file's `#show: post/note/page.with(...)` call says `draft: true`.
///
/// Not a Typst parser, but it knows enough Typst to read that call: comments
/// and raw text before it are skipped, and in its arguments only `draft:` at
/// the top level counts, not one in a string, a comment, `[content]`, math or
/// a nested group. The templates also check at compile time and stop the
/// public build if a draft slipped through, so a miss here fails loudly
/// instead of leaking.
pub fn is_draft(text: &str) -> bool {
    let Some(start) = template_call(text) else { return false };
    let mut args = Vec::new();
    group_end(text.as_bytes(), start, Mode::Code, b')', Some(&mut args));
    let args = String::from_utf8_lossy(&args);
    DRAFT_ARG.find_iter(&args).any(|d| {
        let before = args[..d.start()].chars().next_back();
        let after = args[d.end()..].chars().next();
        !before.is_some_and(|c| word(c) || c == '-') && !after.is_some_and(|c| word(c) || c == '-')
    })
}

/// Where the arguments of the first template call outside comments and raw
/// text start (just after its `(`).
fn template_call(text: &str) -> Option<usize> {
    let b = text.as_bytes();
    let mut i = 0;
    while i < b.len() {
        if let Some(end) = skip(b, i, Mode::Markup) {
            i = end;
            continue;
        }
        if b[i] == b'#' {
            if let Some(m) = TEMPLATE_CALL.find(&text[i..]) {
                return Some(i + m.end());
            }
        }
        i += 1;
    }
    None
}

#[derive(Clone, Copy, PartialEq)]
enum Mode {
    Code,
    Markup,
    Math,
}

/// Index of the first `pat` in `b` at or after `from`.
fn find(b: &[u8], from: usize, pat: &[u8]) -> Option<usize> {
    b.get(from..)?.windows(pat.len()).position(|w| w == pat).map(|p| from + p)
}

/// If a comment, string, raw text or escape starts at `i`, the index just
/// past it. Delimiters are ASCII, so byte indices are always char boundaries.
fn skip(b: &[u8], i: usize, mode: Mode) -> Option<usize> {
    let rest = &b[i..];
    // In markup, the `//` of a URL like https://example.org isn't a comment.
    let url = mode == Mode::Markup && (b[..i].ends_with(b"http:") || b[..i].ends_with(b"https:"));
    if rest.starts_with(b"//") && !url {
        return Some(find(b, i, b"\n").unwrap_or(b.len()));
    }
    if rest.starts_with(b"/*") {
        // Block comments nest.
        let (mut depth, mut j) = (0, i);
        while j < b.len() {
            if b[j..].starts_with(b"/*") {
                depth += 1;
                j += 2;
            } else if b[j..].starts_with(b"*/") {
                depth -= 1;
                j += 2;
                if depth == 0 {
                    return Some(j);
                }
            } else {
                j += 1;
            }
        }
        return Some(b.len());
    }
    match (rest[0], mode) {
        (b'\\', Mode::Markup | Mode::Math) => Some((i + 2).min(b.len())),
        (b'"', Mode::Code | Mode::Math) => {
            let mut j = i + 1;
            while j < b.len() && b[j] != b'"' {
                j += if b[j] == b'\\' { 2 } else { 1 };
            }
            Some((j + 1).min(b.len()))
        }
        (b'`', Mode::Code | Mode::Markup) => {
            // `x`, or ```lang ...``` closed by as many backticks as opened it.
            let n = rest.iter().take_while(|&&c| c == b'`').count();
            if n == 2 {
                return Some(i + 2);
            }
            Some(find(b, i + n, &rest[..n]).map_or(b.len(), |j| j + n))
        }
        _ => None,
    }
}

/// Scan from `i` in `mode` to the `close` byte that ends this group, and
/// return the index just past it (or the end of the text). Comments, strings,
/// raw text and nested groups are skipped: `[...]` as markup, `$...$` as math,
/// `(...)` and `{...}` as code; in markup and math, parentheses are just text.
/// With `out`, what is directly in this group is copied there, with a space
/// for each skipped part.
fn group_end(b: &[u8], mut i: usize, mode: Mode, close: u8, mut out: Option<&mut Vec<u8>>) -> usize {
    while i < b.len() {
        let end = if let Some(end) = skip(b, i, mode) {
            end
        } else if b[i] == close {
            return i + 1;
        } else {
            match (b[i], mode) {
                (b'[', Mode::Code | Mode::Markup) => group_end(b, i + 1, Mode::Markup, b']', None),
                (b'$', Mode::Code | Mode::Markup) => group_end(b, i + 1, Mode::Math, b'$', None),
                (b'(', Mode::Code) => group_end(b, i + 1, Mode::Code, b')', None),
                (b'{', Mode::Code) => group_end(b, i + 1, Mode::Code, b'}', None),
                (c, _) => {
                    if let Some(o) = out.as_deref_mut() {
                        o.push(c);
                    }
                    i += 1;
                    continue;
                }
            }
        };
        if let Some(o) = out.as_deref_mut() {
            o.push(b' ');
        }
        i = end;
    }
    b.len()
}

/// Labels a file defines: `<label>`, but not the `<label>` in `#link(<label>)`.
fn labels(text: &str) -> impl Iterator<Item = &str> {
    LABEL.captures_iter(text).filter_map(move |c| {
        let start = c.get(0).unwrap().start();
        match text[..start].chars().next_back() {
            Some(p) if p == '(' || word(p) => None,
            _ => Some(c.get(1).unwrap().as_str()),
        }
    })
}

/// First and last commit dates (YYYY-MM-DD) of a file, if it is tracked.
fn git_dates(root: &Path, path: &Path) -> Option<(String, String)> {
    let out = Command::new("git")
        .args(["log", "--follow", "--format=%cs", "--"])
        .arg(util::rel(path, root))
        .current_dir(root)
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let text = String::from_utf8(out.stdout).ok()?;
    let dates: Vec<&str> = text.split_whitespace().collect();
    Some((dates.last()?.to_string(), dates.first()?.to_string()))
}

fn valid_slug(s: &str) -> bool {
    let mut cs = s.chars();
    cs.next().is_some_and(|c| c.is_ascii_lowercase() || c.is_ascii_digit())
        && cs.all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
}

/// Slug and URL base of a page under content/research/: index.typ is
/// /research/; a thesis is a folder, <thesis>/index.typ is /research/<thesis>/
/// (slug "<thesis>"), and a chapter <thesis>/<stem>.typ is
/// /research/<thesis>/<stem>/ (slug "<thesis>-<stem>"). See lib/thesis.typ.
fn research_place(rel: &Path) -> (String, String) {
    let stem = rel.file_stem().unwrap_or_default().to_string_lossy().into_owned();
    let parts: Vec<_> = rel.components().map(|c| c.as_os_str().to_string_lossy().into_owned()).collect();
    if parts.len() == 1 {
        return if stem == "index" {
            ("research".into(), "research".into())
        } else {
            (stem.clone(), format!("research/{stem}"))
        };
    }
    let thesis = &parts[0];
    if stem == "index" {
        (thesis.clone(), format!("research/{thesis}"))
    } else {
        (format!("{thesis}-{stem}"), format!("research/{thesis}/{stem}"))
    }
}

impl Manifest {
    pub fn collect(root: &Path, include_drafts: bool) -> Result<Self> {
        let content = root.join("content");
        let today = util::today();
        let mut pages = Vec::new();
        let mut hidden: Vec<String> = Vec::new();
        let mut seen: HashMap<String, PathBuf> = HashMap::new();

        for section in ["posts", "garden", "pages", "research"] {
            let dir = content.join(section);
            let files: Vec<PathBuf> = if section == "research" {
                util::files(&dir)?
            } else {
                let mut v: Vec<PathBuf> = match fs::read_dir(&dir) {
                    Ok(rd) => rd.filter_map(|e| e.ok().map(|e| e.path())).filter(|p| p.is_file()).collect(),
                    Err(_) => Vec::new(),
                };
                v.sort();
                v
            };
            for path in files.into_iter().filter(|p| p.extension().is_some_and(|e| e == "typ")) {
                let stem = path.file_stem().unwrap_or_default().to_string_lossy().into_owned();
                let mut slug = stem.clone();
                let mut post_date = None;
                if section == "posts" {
                    let Some(c) = DATED.captures(&stem) else {
                        bail!("post {} must be named YYYY-MM-DD-slug.typ", path.display());
                    };
                    post_date = Some(c[1].to_string());
                    slug = c[2].to_string();
                }
                let base = match section {
                    "posts" => format!("blog/{slug}"),
                    "garden" => format!("garden/{slug}"),
                    "pages" => slug.clone(),
                    _ => {
                        let (s, b) = research_place(path.strip_prefix(&dir)?);
                        slug = s;
                        b
                    }
                };
                if !valid_slug(&slug) {
                    bail!("{}: slug '{slug}' must be lowercase letters, digits and dashes", path.display());
                }
                if let Some(other) = seen.get(&slug) {
                    bail!("slug '{slug}' used by both {} and {}", other.display(), path.display());
                }
                seen.insert(slug.clone(), path.clone());

                let text = fs::read_to_string(&path)?;
                let draft = is_draft(&text);
                if draft && !include_drafts {
                    for l in std::iter::once(slug.as_str()).chain(labels(&text)) {
                        if !hidden.iter().any(|h| h == l) {
                            hidden.push(l.to_string());
                        }
                    }
                    continue;
                }
                let (created, updated) = git_dates(root, &path).unzip();
                let fallback = || post_date.clone().unwrap_or_else(|| today.clone());
                pages.push(Page {
                    path: format!("/{}", util::rel(&path, root)),
                    out: format!("{base}/index.html"),
                    url: format!("/{base}/"),
                    created: created.unwrap_or_else(fallback),
                    updated: updated.unwrap_or_else(fallback),
                    date: post_date,
                    slug,
                    section,
                    draft,
                });
            }
        }

        let assets = util::files(&root.join("assets"))?
            .iter()
            .map(|p| {
                let r = util::rel(p, root);
                (format!("/{r}"), r)
            })
            .collect();
        Ok(Self { pages, hidden, assets })
    }

    pub fn to_json(&self) -> Value {
        json!({
            "pages": self.pages.iter().map(|p| json!({
                "slug": p.slug,
                "section": p.section,
                "path": p.path,
                "out": p.out,
                "url": p.url,
                "date": p.date,
                "created": p.created,
                "updated": p.updated,
                "draft": p.draft,
            })).collect::<Vec<_>>(),
            "hidden": self.hidden,
            "assets": self.assets.iter().map(|(path, out)| json!({"path": path, "out": out})).collect::<Vec<_>>(),
        })
    }
}

/// Repo-relative paths of the draft content files.
pub fn draft_paths(root: &Path) -> Result<Vec<String>> {
    let mut out = Vec::new();
    for p in util::files(&root.join("content"))? {
        if p.extension().is_some_and(|e| e == "typ") && is_draft(&fs::read_to_string(&p)?) {
            out.push(util::rel(&p, root));
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn drafts() {
        assert!(is_draft("#show: post.with(title: [A], draft: true)\nbody"));
        assert!(is_draft("#show: note.with(\n  title: [A (b)],\n  draft : true,\n)"));
        assert!(!is_draft("#show: post.with(title: [A], draft: false)"));
        assert!(!is_draft("#show: post.with(title: [A], my-draft: true)"));
        assert!(!is_draft("#show: post.with(title: [A])\ndraft: true"));
        assert!(!is_draft("no template call, draft: true"));
        // Parentheses in content, strings and math don't end the call.
        assert!(is_draft("#show: post.with(title: [Smile :)], draft: true)"));
        assert!(is_draft("#show: post.with(summary: \")\", draft: true)"));
        assert!(is_draft("#show: post.with(summary: \"a \\\" ) b\", draft: true)"));
        assert!(is_draft("#show: post.with(title: [On $[0, 1)$ and \\]], draft: true)"));
        assert!(is_draft("#show: post.with(title: [See https://example.org (x], draft: true)"));
        assert!(is_draft("#show: post.with(title: [`)` and ```typ #f())```], draft: true)"));
        assert!(is_draft("#show: post.with(tags: (\"a\", (1, 2)), extra: {(1)}, draft: /* yes */ true)"));
        // Only the call's own argument counts.
        assert!(!is_draft("#show: post.with(title: [A], summary: \"draft: true\")"));
        assert!(!is_draft("#show: post.with(title: [A, draft: true])"));
        assert!(!is_draft("#show: post.with(title: [A],\n  // draft: true,\n)"));
        assert!(!is_draft("#show: post.with(title: [A], /* draft: true */)"));
        assert!(!is_draft("#show: post.with(meta: (draft: true))"));
        // A call in a comment or raw text isn't the template call.
        assert!(!is_draft("// #show: post.with(draft: true)\n#show: post.with(title: [A])"));
        assert!(!is_draft("/* /* nested */ #show: post.with(draft: true) */\n#show: post.with(title: [A])"));
        assert!(!is_draft("```\n#show: post.with(draft: true)\n```\n#show: post.with(title: [A])"));
        assert!(!is_draft("\\#show: post.with(draft: true)\n#show: post.with(title: [A])"));
        assert!(is_draft("// #show: post.with(title: [A])\n#show: post.with(title: [B], draft: true)"));
        assert!(!is_draft("// only a comment: #show: post.with(draft: true)"));
        // Unclosed call: the rest of the file counts as its arguments.
        assert!(is_draft("#show: post.with(title: [A], draft: true"));
    }

    #[test]
    fn label_defs() {
        let t = "= Head <sec-a>\n$ x $ <eq:b.1>\nsee #link(<sec-a>)[here] and a<not>";
        assert_eq!(labels(t).collect::<Vec<_>>(), ["sec-a", "eq:b.1"]);
    }

    #[test]
    fn research() {
        assert_eq!(research_place(Path::new("index.typ")), ("research".into(), "research".into()));
        assert_eq!(research_place(Path::new("msc/index.typ")), ("msc".into(), "research/msc".into()));
        assert_eq!(research_place(Path::new("msc/intro.typ")), ("msc-intro".into(), "research/msc/intro".into()));
    }
}
