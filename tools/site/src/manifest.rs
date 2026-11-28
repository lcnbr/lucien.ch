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
static TEMPLATE_CALL: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"#show:\s*(?:post|note|page)\.with\(").unwrap());
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
/// The templates also check this at compile time and stop the public build if
/// a draft slipped through, so a miss here fails loudly instead of leaking.
pub fn is_draft(text: &str) -> bool {
    let Some(m) = TEMPLATE_CALL.find(text) else { return false };
    let (mut depth, mut i) = (1, m.end());
    let bytes = text.as_bytes();
    while i < bytes.len() && depth > 0 {
        match bytes[i] {
            b'(' => depth += 1,
            b')' => depth -= 1,
            _ => {}
        }
        i += 1;
    }
    let args = &text[m.end()..i];
    DRAFT_ARG.find_iter(args).any(|d| {
        let before = args[..d.start()].chars().next_back();
        let after = args[d.end()..].chars().next();
        !before.is_some_and(|c| word(c) || c == '-') && !after.is_some_and(|c| word(c) || c == '-')
    })
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
