//! Build tool for lucien.ch.
//!
//! `cargo site build` (an alias in .cargo/config.toml):
//! 1. walks content/ and assets/, reads git dates, writes build/manifest.json;
//! 2. fetches the blogroll feeds into build/blogroll.json;
//! 3. runs `typst compile --format bundle site.typ dist/`, builds the CV PDFs
//!    and fixes up the MathML;
//! 4. optionally builds the /edit/ page (--editor), the drafts gate
//!    (--drafts) and the Pagefind index (--search).
//!
//! Drafts (`draft: true` in a file's template call) are left out of the normal
//! build entirely: no page, no listing, no search entry, no graph node, no feed
//! item, and links to them from public pages render as plain text. The --drafts
//! build includes them and writes a `_worker.js` that only lets through requests
//! signed by Cloudflare Access (GitHub login), see drafts.rs.

mod blogroll;
mod drafts;
mod editor;
mod manifest;
mod mathml;
mod serve;
mod util;

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{bail, Context, Result};

const USAGE: &str = "\
usage: cargo site <command> [options]

  build                build the site into dist/
    --watch            typst watch with live reload (no PDFs, editor or search)
    --search           also build the Pagefind search index (needs npx)
    --editor           also build the /edit/ page
    --drafts           private build: include drafts, behind GitHub login
    --out DIR          output directory (default: dist/); emptied first, so it
                       may not be the repository, a source folder or a checkout
    --offline          don't fetch the blogroll feeds (reuse the last fetch)
  serve [PORT]         serve dist/ on PORT (default 8000) with the editor's headers
    --host ADDR        address to listen on (default 127.0.0.1; 0.0.0.0 lets
                       other devices, such as a phone, reach it)
    --dir DIR          serve DIR instead of dist/ (say, a --drafts --out DIR build)
  blogroll FILE...     parse local feed files and print what the blogroll keeps
  mathml-fix DIR       apply the MathML fix-up to every .html file under DIR
";

fn main() {
    if let Err(e) = run() {
        eprintln!("error: {e:#}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let mut args = std::env::args().skip(1);
    let cmd = args.next().unwrap_or_else(|| "build".into());
    let rest: Vec<String> = args.collect();
    match cmd.as_str() {
        "build" => build(&BuildOptions::parse(&rest)?),
        "serve" => serve(&rest),
        "blogroll" => {
            if rest.is_empty() {
                blogroll::write(&root()?, false)
            } else {
                blogroll::print_files(&rest)
            }
        }
        "mathml-fix" => {
            let dir = rest.first().context("mathml-fix needs a directory")?;
            println!("mathml_fix: {} files changed", mathml::fix_tree(Path::new(dir))?);
            Ok(())
        }
        "help" | "-h" | "--help" => {
            print!("{USAGE}");
            Ok(())
        }
        other => bail!("unknown command {other:?}\n\n{USAGE}"),
    }
}

#[derive(Default)]
struct BuildOptions {
    watch: bool,
    search: bool,
    editor: bool,
    drafts: bool,
    offline: bool,
    out: Option<PathBuf>,
}

impl BuildOptions {
    fn parse(args: &[String]) -> Result<Self> {
        let mut o = Self::default();
        let mut it = args.iter();
        while let Some(a) = it.next() {
            match a.as_str() {
                "--watch" => o.watch = true,
                "--search" => o.search = true,
                "--editor" => o.editor = true,
                "--drafts" => o.drafts = true,
                "--offline" => o.offline = true,
                "--out" => o.out = Some(it.next().context("--out needs a directory")?.into()),
                _ if a.starts_with("--out=") => o.out = Some(a["--out=".len()..].into()),
                _ => bail!("unknown option {a:?}\n\n{USAGE}"),
            }
        }
        Ok(o)
    }
}

/// `cargo site serve [PORT] [--host ADDR] [--dir DIR]`.
fn serve(args: &[String]) -> Result<()> {
    let (mut port, mut host, mut dir) = (8000, "127.0.0.1".to_string(), None);
    let mut it = args.iter();
    while let Some(a) = it.next() {
        match a.as_str() {
            "--host" => host = it.next().context("--host needs an address")?.clone(),
            "--dir" => dir = Some(PathBuf::from(it.next().context("--dir needs a directory")?)),
            _ if a.starts_with("--host=") => host = a["--host=".len()..].into(),
            _ if a.starts_with("--dir=") => dir = Some(a["--dir=".len()..].into()),
            _ if a.starts_with('-') => bail!("unknown option {a:?}\n\n{USAGE}"),
            p => port = p.parse().with_context(|| format!("not a port: {p}"))?,
        }
    }
    let dir = match dir {
        Some(d) => d,
        None => root()?.join("dist"),
    };
    serve::run(&dir, &host, port)
}

/// The repository root: the nearest directory up from here with a site.typ.
fn root() -> Result<PathBuf> {
    let here = std::env::current_dir()?;
    here.ancestors()
        .find(|d| d.join("site.typ").is_file())
        .map(Path::to_path_buf)
        .context("not inside the site's repository (no site.typ here or above)")
}

fn build(o: &BuildOptions) -> Result<()> {
    let root = root()?;
    let dist = match &o.out {
        Some(p) => std::path::absolute(p)?,
        None => root.join("dist"),
    };
    check_out_dir(&root, &dist)?;
    let build_dir = root.join("build");
    fs::create_dir_all(&build_dir)?;

    let m = manifest::Manifest::collect(&root, o.drafts)?;
    util::write_json(&build_dir.join("manifest.json"), &m.to_json(), 2)?;
    println!(
        "manifest: {} pages ({} drafts included, {} left out), {} assets",
        m.pages.len(),
        m.pages.iter().filter(|p| p.draft).count(),
        m.hidden.len(),
        m.assets.len()
    );

    // Feeds for /blogroll/. CI sets BLOGROLL_OFFLINE=1 on the drafts build so
    // it reuses the public build's fetch.
    let offline = o.offline || std::env::var("BLOGROLL_OFFLINE").as_deref() == Ok("1");
    blogroll::write(&root, offline)?;

    if dist.exists() {
        fs::remove_dir_all(&dist).with_context(|| format!("removing {}", dist.display()))?;
    }
    util::run(
        Command::new("typst")
            .arg(if o.watch { "watch" } else { "compile" })
            .args(["--features", "html,bundle", "--format", "bundle", "--root"])
            .arg(&root)
            .arg("--font-path")
            .arg(root.join("fonts"))
            .args(["--input", if o.drafts { "drafts=true" } else { "drafts=false" }])
            .arg(root.join("site.typ"))
            .arg(&dist),
    )?;
    if o.watch {
        return Ok(());
    }

    build_cv_pdfs(&root, &dist)?;
    println!("mathml_fix: {} files changed", mathml::fix_tree(&dist)?);
    if o.editor {
        editor::build(&root, &dist, o.drafts)?;
    }
    write_cors_headers(&dist)?;
    if o.drafts {
        drafts::write_gate(&dist)?;
    }
    if o.search {
        util::run(Command::new("npx").args(["--yes", "pagefind@1", "--site"]).arg(&dist))?;
    }
    Ok(())
}

/// What the repository holds besides build output: --out must not point here.
const SOURCES: [&str; 13] = [
    ".git",
    ".github",
    ".cargo",
    "assets",
    "content",
    "cv",
    "data",
    "editor",
    "fonts",
    "functions",
    "lib",
    "tools",
    "site.typ",
];

/// The build empties its output directory first, so refuse one that may hold
/// more than an earlier build: the repository, a folder above it or build/,
/// its sources, another checkout, or anything git tracks.
fn check_out_dir(root: &Path, out: &Path) -> Result<()> {
    // Symlinks and `..` resolved, also for an `out` that doesn't exist yet.
    let real = |p: &Path| {
        p.ancestors()
            .find_map(|a| {
                let rest = p.strip_prefix(a).ok()?;
                fs::canonicalize(a).ok().map(|r| if rest.as_os_str().is_empty() { r } else { r.join(rest) })
            })
            .unwrap_or_else(|| p.to_path_buf())
    };
    let (root, out) = (real(root), real(out));
    let why = if root.join("build").starts_with(&out) {
        Some("it contains the repository or its build/ folder".to_string())
    } else if let Some(s) = SOURCES.iter().find(|s| out.starts_with(root.join(s))) {
        Some(format!("it is part of the sources ({s})"))
    } else if let Some(s) = ["site.typ", ".git"].iter().find(|s| out.join(s).exists()) {
        Some(format!("it looks like a checkout (has {s})"))
    } else {
        let tracked = Command::new("git").args(["ls-files", "-z"]).current_dir(&out).output();
        tracked.is_ok_and(|o| o.status.success() && !o.stdout.is_empty()).then(|| "git tracks files in it".to_string())
    };
    match why {
        Some(why) => bail!("refusing to use {} as the output directory: {why}", out.display()),
        None => Ok(()),
    }
}

/// The CV as PDF, one per language, next to the /cv/ page (lib/cv.typ).
fn build_cv_pdfs(root: &Path, dist: &Path) -> Result<()> {
    fs::create_dir_all(dist.join("cv"))?;
    for lang in ["en", "fr"] {
        util::run(
            Command::new("typst")
                .args(["compile", "--root"])
                .arg(root)
                .arg("--font-path")
                .arg(root.join("cv/fonts"))
                .args(["--input", &format!("lang={lang}")])
                .arg(root.join("cv/cv-pdf.typ"))
                .arg(dist.join(format!("cv/lucien-huber-cv-{lang}.pdf"))),
        )?;
    }
    println!("cv: built dist/cv/lucien-huber-cv-{{en,fr}}.pdf");
    Ok(())
}

/// Let giscus' iframe (giscus.app) load the comments theme and its fonts.
/// Appends to _headers, which the editor build may have started.
fn write_cors_headers(dist: &Path) -> Result<()> {
    use std::io::Write;
    let mut f = fs::OpenOptions::new().create(true).append(true).open(dist.join("_headers"))?;
    for path in ["/assets/giscus.css", "/assets/fonts/*"] {
        write!(f, "{path}\n  Access-Control-Allow-Origin: *\n")?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn out_dir_guard() {
        let tmp = std::env::temp_dir().join(format!("site-out-test-{}", std::process::id()));
        let (root, other) = (tmp.join("repo"), tmp.join("other"));
        fs::create_dir_all(root.join("content/posts")).unwrap();
        fs::write(root.join("site.typ"), "").unwrap();
        fs::create_dir_all(&other).unwrap();
        fs::write(other.join("site.typ"), "").unwrap();
        let refused = |out: &Path| check_out_dir(&root, out).is_err();
        assert!(refused(&root));
        assert!(refused(&tmp));
        assert!(refused(&root.join("build")));
        assert!(refused(&root.join("content")));
        assert!(refused(&root.join("content/posts/new")));
        fs::create_dir_all(root.join("dist")).unwrap();
        assert!(refused(&root.join("dist/../content")));
        assert!(refused(&root.join("site.typ")));
        assert!(refused(&other));
        assert!(!refused(&root.join("dist")));
        assert!(!refused(&root.join("dist-drafts")));
        assert!(!refused(&tmp.join("elsewhere")));
        fs::remove_dir_all(&tmp).unwrap();
    }
}
