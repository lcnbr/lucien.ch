//! The /edit/ page: editor/ copied to dist/edit/, plus the in-browser
//! compiler, fonts, Typst packages and a snapshot of the sources.

use std::fs;
use std::io::{Read, Write};
use std::path::{Component, Path, PathBuf};
use std::process::Command;
use std::time::Duration;

use anyhow::{bail, Context, Result};
use base64::Engine;
use flate2::{read::GzDecoder, write::GzEncoder, Compression};
use serde_json::{json, Map, Value};
use sha2::{Digest, Sha512};

use crate::{manifest, util};

/// Versions of the in-browser compiler; typst-wasm 1.0.0 embeds Typst 0.15.
/// With each, the sha512 `integrity` the npm registry lists for its tarball
/// (registry.npmjs.org/<name>/<version>, `dist.integrity`), checked as npm does.
const TYPST_WASM: (&str, &str) =
    ("1.0.0", "sha512-x4YzWaq32NKW3Eall6g08DlDM/PsjbfYeKovc3SY/1cHdkwq42jT7IVN786uitCAb0vRZn7p6fJ03Gbq3iKS+Q==");
const TYPST_WASM_FONTS: (&str, &str) =
    ("1.0.0", "sha512-azAPU3NjsyQWl0TVPSqgPs96Rn0DekzPEvCcnl0sKcTTf43gRvuVjkxrgIUgNI6aBUx9NSsC8bjcqzOgM9Likg==");
const NANOTAR: (&str, &str) =
    ("0.2.1", "sha512-MUrzzDUcIOPbv7ubhDV/L4CIfVTATd9XhDE2ixFeCrM5yp9AlzUpn91JrnN0HD6hksdxvz9IW9aKANz0Bta0GA==");
/// Tinymist (Typst language server) for the editor; CI builds it for the
/// browser (see .github/workflows/build.yml, which reads this line) and
/// passes it in TINYMIST_PKG.
pub const TINYMIST_VERSION: &str = "0.15.2";
/// Typst's own fonts for the editor; the site's (fonts/) are added too.
const EDITOR_FONTS: [&str; 6] = [
    "NewCM10-Regular.otf",
    "NewCM10-Italic.otf",
    "NewCM10-Bold.otf",
    "NewCM10-BoldItalic.otf",
    "NewCMMath-Regular.otf",
    "DejaVuSansMono.ttf",
];
const MAX_TARBALL: u64 = 100 << 20;

/// A relative path as "a/b/c", if it has only plain components: no `..`, `.`,
/// root or drive, so joining it to a directory stays inside that directory.
fn plain(path: &Path) -> Option<String> {
    let parts: Option<Vec<&str>> = path
        .components()
        .map(|c| match c {
            Component::Normal(s) => s.to_str(),
            _ => None,
        })
        .collect();
    parts.filter(|p| !p.is_empty()).map(|p| p.join("/"))
}

/// Download an npm package from the registry, check its sha512 and unpack it.
fn npm_files(
    agent: &ureq::Agent,
    name: &str,
    (version, integrity): (&str, &str),
    dest: &Path,
    pick: impl FnMut(&str) -> Option<String>,
) -> Result<()> {
    let base = name.rsplit('/').next().unwrap();
    let url = format!("https://registry.npmjs.org/{name}/-/{base}-{version}.tgz");
    let mut data = Vec::new();
    let res = agent.get(&url).call().with_context(|| format!("downloading {url}"))?;
    res.into_reader().take(MAX_TARBALL + 1).read_to_end(&mut data).with_context(|| format!("downloading {url}"))?;
    let got = format!("sha512-{}", base64::engine::general_purpose::STANDARD.encode(Sha512::digest(&data)));
    if got != integrity {
        bail!("{url}: integrity is {got}, expected {integrity}");
    }
    unpack(&data, dest, pick).with_context(|| format!("unpacking {url}"))
}

/// Write the files of an npm tarball that `pick` chooses (given their path
/// inside the package) to the path it returns under `dest`.
fn unpack(tgz: &[u8], dest: &Path, mut pick: impl FnMut(&str) -> Option<String>) -> Result<()> {
    let mut tar = tar::Archive::new(GzDecoder::new(tgz));
    for entry in tar.entries()? {
        let mut entry = entry?;
        if !entry.header().entry_type().is_file() {
            continue;
        }
        let path = entry.path()?.into_owned();
        let Ok(inner) = path.strip_prefix("package") else { continue };
        let Some(inner) = plain(inner) else { bail!("unsafe path {}", path.display()) };
        if let Some(to) = pick(&inner) {
            let Some(to) = plain(Path::new(&to)) else { bail!("unsafe destination {to} for {inner}") };
            let to = dest.join(to);
            fs::create_dir_all(to.parent().unwrap())?;
            let mut data = Vec::new();
            entry.read_to_end(&mut data)?;
            fs::write(&to, data)?;
        }
    }
    Ok(())
}

/// Copy a directory, leaving out files and folders named in `skip`.
fn copy_tree(from: &Path, to: &Path, skip: &[&str]) -> Result<()> {
    for p in util::entries(from)? {
        let rel = p.strip_prefix(from)?;
        if rel.components().any(|c| skip.contains(&c.as_os_str().to_string_lossy().as_ref())) {
            continue;
        }
        let dest = to.join(rel);
        if p.is_dir() {
            fs::create_dir_all(&dest)?;
        } else {
            fs::create_dir_all(dest.parent().unwrap())?;
            fs::copy(&p, &dest)?;
        }
    }
    Ok(())
}

fn typst_package_cache() -> PathBuf {
    if let Some(p) = std::env::var_os("TYPST_PACKAGE_CACHE_PATH").filter(|p| !p.is_empty()) {
        return p.into();
    }
    let home = PathBuf::from(std::env::var_os("HOME").unwrap_or_default());
    if cfg!(target_os = "macos") {
        return home.join("Library/Caches/typst/packages");
    }
    if cfg!(windows) {
        let local = std::env::var_os("LOCALAPPDATA").map(PathBuf::from).unwrap_or(home);
        return local.join("typst/packages");
    }
    let cache = std::env::var_os("XDG_CACHE_HOME").map(PathBuf::from).unwrap_or_else(|| home.join(".cache"));
    cache.join("typst/packages")
}

/// Add the browser build of tinymist (completion, hover, go to definition).
///
/// Optional: without it the editor works as before. TINYMIST_PKG points at a
/// wasm-pack output (crates/tinymist/pkg) or at CI's cached copy. The wasm is
/// ~36 MB, over Cloudflare Pages' 25 MiB file limit, so it ships gzipped and
/// the editor unpacks it.
fn vendor_tinymist(dest: &Path) -> Result<()> {
    let src = PathBuf::from(std::env::var_os("TINYMIST_PKG").unwrap_or_default());
    if src.as_os_str().is_empty() || !src.join("tinymist.js").exists() {
        println!("editor: tinymist not added (set TINYMIST_PKG to a wasm-pack build of tinymist {TINYMIST_VERSION})");
        return Ok(());
    }
    fs::create_dir_all(dest)?;
    fs::copy(src.join("tinymist.js"), dest.join("tinymist.js"))?;
    let gz = src.join("tinymist_bg.wasm.gz");
    if gz.exists() {
        fs::copy(gz, dest.join("tinymist_bg.wasm.gz"))?;
    } else {
        let wasm = fs::read(src.join("tinymist_bg.wasm"))?;
        let mut enc = GzEncoder::new(fs::File::create(dest.join("tinymist_bg.wasm.gz"))?, Compression::best());
        enc.write_all(&wasm)?;
        enc.finish()?;
    }
    println!("editor: added tinymist from {}", src.display());
    Ok(())
}

/// Snapshot of the sources, used when GitHub's API can't be reached. Drafts
/// are left out of the public build.
fn snapshot(root: &Path, include_drafts: bool) -> Result<Map<String, Value>> {
    let skip = if include_drafts { Vec::new() } else { manifest::draft_paths(root)? };
    let mut files = Map::new();
    for d in ["content", "lib", "data"] {
        for f in util::files(&root.join(d))? {
            let rel = util::rel(&f, root);
            if skip.contains(&rel) {
                continue;
            }
            let bytes = fs::read(&f)?;
            let value = match String::from_utf8(bytes) {
                Ok(text) => Value::String(text),
                Err(e) => json!({"base64": base64::engine::general_purpose::STANDARD.encode(e.as_bytes())}),
            };
            files.insert(rel, value);
        }
    }
    Ok(files)
}

/// Mirror the Typst packages this build used, so the editor works offline
/// from the registry and with exactly the same versions. Returns how many.
fn mirror_packages(packages: &Path) -> Result<usize> {
    let cache = typst_package_cache();
    fs::create_dir_all(packages)?;
    let mut n = 0;
    for ns in util::dirs(&cache)? {
        for name in util::dirs(&ns)? {
            for version_dir in util::dirs(&name)? {
                let file = |p: &Path| p.file_name().unwrap().to_string_lossy().into_owned();
                let dest = packages.join(file(&ns)).join(format!("{}-{}.tar.gz", file(&name), file(&version_dir)));
                fs::create_dir_all(dest.parent().unwrap())?;
                let mut tar = tar::Builder::new(GzEncoder::new(fs::File::create(&dest)?, Compression::best()));
                for p in util::entries(&version_dir)? {
                    let rel = p.strip_prefix(&version_dir)?;
                    if p.is_dir() {
                        tar.append_dir(rel, &p)?;
                    } else {
                        tar.append_path_with_name(&p, rel)?;
                    }
                }
                tar.into_inner()?.finish()?;
                n += 1;
            }
        }
    }
    let mut index: Vec<String> = util::files(packages)?
        .iter()
        .filter(|p| p.to_string_lossy().ends_with(".tar.gz"))
        .map(|p| util::rel(p, packages))
        .collect();
    index.sort();
    util::write_json(&packages.join("index.json"), &json!(index), 0)?;
    Ok(n)
}

pub fn build(root: &Path, dist: &Path, include_drafts: bool) -> Result<()> {
    let out = dist.join("edit");
    copy_tree(&root.join("editor"), &out, &["README.md", "codemirror-entry.js"])?;
    let vendor = out.join("vendor");

    // Cloudflare Pages header rules: cross-origin isolation lets the editor use
    // typst-wasm's worker backend (SharedArrayBuffer). Without it, it falls
    // back to JSPI, which only recent Chromium-based browsers have.
    // require-corp (not credentialless) because Safari supports only that.
    // Only /edit/ is always isolated: isolation would also block the giscus
    // comments iframe for every reader. Pages get isolated only while the
    // editor is docked on them (edit=1 cookie, see functions/_middleware.js).
    fs::write(
        dist.join("_headers"),
        "/edit/*\n  Cross-Origin-Opener-Policy: same-origin\n  Cross-Origin-Embedder-Policy: require-corp\n",
    )?;
    // Run that function on pages only, not on static files. Not on the drafts
    // site, whose _worker.js must see every request (it is the Access check).
    if !include_drafts {
        let routes = json!({
            "version": 1, "include": ["/*"],
            "exclude": ["/assets/*", "/edit/*", "/pagefind/*", "/feed.xml"],
        });
        fs::write(dist.join("_routes.json"), format!("{routes}\n"))?;
    }

    // Timeouts, so a stalled registry fails the build instead of hanging it.
    let agent =
        ureq::AgentBuilder::new().timeout_connect(Duration::from_secs(30)).timeout(Duration::from_secs(300)).build();
    npm_files(&agent, "typst-wasm", TYPST_WASM, &vendor.join("typst-wasm"), |p| {
        let rest = p.strip_prefix("dist/")?;
        (!rest.ends_with(".map") && !rest.ends_with(".d.ts")).then(|| rest.into())
    })?;
    let fonts = vendor.join("fonts");
    npm_files(&agent, "@typst-wasm/fonts", TYPST_WASM_FONTS, &fonts, |p| {
        let f = p.strip_prefix("dist/files/")?;
        EDITOR_FONTS.contains(&f).then(|| f.into())
    })?;
    // The site's own fonts, so diagrams look the same in the preview.
    for f in util::files(&root.join("fonts"))? {
        fs::copy(&f, fonts.join(f.file_name().unwrap()))?;
    }
    npm_files(&agent, "nanotar", NANOTAR, &vendor.join("nanotar"), |p| {
        (p == "dist/index.mjs").then(|| "index.mjs".into())
    })?;
    for f in EDITOR_FONTS {
        if !fonts.join(f).exists() {
            bail!("@typst-wasm/fonts {} has no {f}", TYPST_WASM_FONTS.0);
        }
    }
    vendor_tinymist(&vendor.join("tinymist"))?;

    let today = util::today();
    // The branch the editor reads and commits to by default: the one this
    // site was built from (CI sets GITHUB_HEAD_REF on pull requests).
    let env = |k| std::env::var(k).ok().filter(|v: &String| !v.is_empty());
    let branch = env("GITHUB_HEAD_REF")
        .or_else(|| env("GITHUB_REF_NAME"))
        .or_else(|| {
            let o = Command::new("git").args(["rev-parse", "--abbrev-ref", "HEAD"]).current_dir(root).output().ok()?;
            Some(String::from_utf8_lossy(&o.stdout).trim().to_string()).filter(|b| !b.is_empty())
        })
        .unwrap_or_else(|| "main".into());
    util::write_json(&out.join("build.json"), &json!({"branch": branch, "built": today}), 0)?;
    util::write_json(
        &out.join("snapshot.json"),
        &json!({"built": today, "files": snapshot(root, include_drafts)?}),
        0,
    )?;

    let n = mirror_packages(&vendor.join("packages"))?;
    println!("editor: built dist/edit/ with {n} mirrored Typst packages");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A .tgz with these (name, contents) entries, names written as given.
    fn tgz(files: &[(&str, &str)]) -> Vec<u8> {
        let mut b = tar::Builder::new(GzEncoder::new(Vec::new(), Compression::fast()));
        for (name, data) in files {
            let mut h = tar::Header::new_gnu();
            h.as_old_mut().name[..name.len()].copy_from_slice(name.as_bytes());
            h.set_size(data.len() as u64);
            h.set_mode(0o644);
            h.set_entry_type(tar::EntryType::Regular);
            h.set_cksum();
            b.append(&h, data.as_bytes()).unwrap();
        }
        b.into_inner().unwrap().finish().unwrap()
    }

    #[test]
    fn plain_paths() {
        assert_eq!(plain(Path::new("dist//files/a.otf")).as_deref(), Some("dist/files/a.otf"));
        assert_eq!(plain(Path::new("/etc/x")), None);
        assert_eq!(plain(Path::new("a/../../x")), None);
        assert_eq!(plain(Path::new("./x")), None);
        assert_eq!(plain(Path::new("")), None);
    }

    #[test]
    fn unpack_stays_inside() {
        let dir = std::env::temp_dir().join(format!("site-unpack-test-{}", std::process::id()));
        let dest = dir.join("vendor");
        let take_dist = |p: &str| p.strip_prefix("dist/").map(String::from);
        unpack(&tgz(&[("package/dist/a.js", "a"), ("package/README.md", "r")]), &dest, take_dist).unwrap();
        assert_eq!(fs::read_to_string(dest.join("a.js")).unwrap(), "a");
        assert!(!dest.join("README.md").exists());
        // An absolute path after the prefix would make dest.join() leave dest.
        let evil = dir.join("evil");
        let name = format!("package/dist/{}", evil.display());
        assert!(unpack(&tgz(&[(&name, "x")]), &dest, take_dist).is_ok());
        assert!(!evil.exists() && dest.join(evil.strip_prefix("/").unwrap()).exists());
        assert!(unpack(&tgz(&[("package/dist/../../x", "x")]), &dest, take_dist).is_err());
        assert!(unpack(&tgz(&[("package/a", "x")]), &dest, |_| Some("/tmp/x".into())).is_err());
        assert!(unpack(&tgz(&[("package/a", "x")]), &dest, |_| Some("../x".into())).is_err());
        fs::remove_dir_all(&dir).unwrap();
    }
}
