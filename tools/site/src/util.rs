//! Small helpers shared by the commands.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{bail, Context, Result};
use serde_json::Value;

/// Every file under `dir`, recursively, sorted by path components (as
/// Python's sorted(Path.rglob) did). Missing directory: nothing.
pub fn files(dir: &Path) -> Result<Vec<PathBuf>> {
    let mut out = entries(dir)?;
    out.retain(|p| p.is_file());
    Ok(out)
}

/// Every file and directory under `dir`, recursively, sorted.
pub fn entries(dir: &Path) -> Result<Vec<PathBuf>> {
    fn walk(dir: &Path, out: &mut Vec<PathBuf>) -> Result<()> {
        if !dir.is_dir() {
            return Ok(());
        }
        for e in fs::read_dir(dir).with_context(|| format!("reading {}", dir.display()))? {
            let p = e?.path();
            let is_dir = p.is_dir();
            out.push(p.clone());
            if is_dir {
                walk(&p, out)?;
            }
        }
        Ok(())
    }
    let mut out = Vec::new();
    walk(dir, &mut out)?;
    out.sort();
    Ok(out)
}

/// The directories directly inside `dir`, sorted. Missing directory: none.
pub fn dirs(dir: &Path) -> Result<Vec<PathBuf>> {
    let Ok(rd) = fs::read_dir(dir) else { return Ok(Vec::new()) };
    let mut out: Vec<PathBuf> = rd.filter_map(|e| e.ok().map(|e| e.path())).filter(|p| p.is_dir()).collect();
    out.sort();
    Ok(out)
}

/// `path` relative to `base`, with forward slashes.
pub fn rel(path: &Path, base: &Path) -> String {
    let r = path.strip_prefix(base).unwrap_or(path);
    r.components().map(|c| c.as_os_str().to_string_lossy()).collect::<Vec<_>>().join("/")
}

/// Run a command, failing if it does.
pub fn run(cmd: &mut Command) -> Result<()> {
    let status = cmd.status().with_context(|| format!("could not run {:?}", cmd.get_program()))?;
    if !status.success() {
        bail!("{:?} failed ({status})", cmd.get_program());
    }
    Ok(())
}

/// Today's local date, YYYY-MM-DD.
pub fn today() -> String {
    chrono::Local::now().format("%Y-%m-%d").to_string()
}

/// Write JSON indented by `indent` spaces (0: compact).
pub fn write_json(path: &Path, value: &Value, indent: usize) -> Result<()> {
    let text = if indent == 0 {
        serde_json::to_string(value)?
    } else {
        let spaces = vec![b' '; indent];
        let mut buf = Vec::new();
        let fmt = serde_json::ser::PrettyFormatter::with_indent(&spaces);
        let mut ser = serde_json::Serializer::with_formatter(&mut buf, fmt);
        serde::Serialize::serialize(value, &mut ser)?;
        String::from_utf8(buf)?
    };
    fs::write(path, text).with_context(|| format!("writing {}", path.display()))
}
