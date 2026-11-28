//! Fetch the feeds listed in blogroll.txt and write build/blogroll.json.
//!
//! The /blogroll/ page (lib/indexes.typ) lists the latest posts of every
//! blog, newest first, like https://matklad.github.io/links.html.
//!
//! A feed that times out, errors or doesn't parse is skipped with a warning:
//! the build never fails because someone else's site is down. Links that are
//! not http(s) (a feed could send `javascript:`) are dropped.

use std::fs;
use std::io::Read;
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::LazyLock;
use std::time::Duration;

use anyhow::{bail, Context, Result};
use chrono::{DateTime, FixedOffset, NaiveDate, NaiveDateTime, Utc};
use regex::Regex;
use roxmltree::{Document, Node};
use serde_json::{json, Value};

use crate::util;

const POSTS_PER_BLOG: usize = 3; // newest posts kept from each feed
const MAX_POSTS: usize = 150; // length of the merged list on the page
const TIMEOUT: Duration = Duration::from_secs(15); // per feed
const MAX_BYTES: u64 = 10 << 20; // ignore feeds larger than this
const WORKERS: usize = 16;
const USER_AGENT: &str = "lucien.ch-blogroll/1.0 (+https://lucien.ch/blogroll/)";

const ATOM: &str = "http://www.w3.org/2005/Atom";
const RSS1: &str = "http://purl.org/rss/1.0/";
const DC: &str = "http://purl.org/dc/elements/1.1/";

static TAG: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"<[^>]+>").unwrap());
static DATE_PREFIX: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^\d{4}-\d{2}-\d{2}").unwrap());

struct Post {
    title: String,
    url: String,
    date: String,
    ts: i64,
}

struct Blog {
    feed: String,
    title: String,
    url: String,
    posts: Vec<Post>,
}

/// Feed URLs, one per line; `#` starts a comment, and so does anything after the URL.
fn read_list(path: &Path) -> Vec<String> {
    let Ok(text) = fs::read_to_string(path) else { return Vec::new() };
    text.lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .filter_map(|l| l.split_whitespace().next().map(String::from))
        .collect()
}

/// Plain text of an element: entities decoded, HTML tags stripped, spaces collapsed.
fn text(node: Option<Node>) -> String {
    let Some(node) = node else { return String::new() };
    let raw: String = node.descendants().filter(|n| n.is_text()).filter_map(|n| n.text()).collect();
    // Atom type="html" titles arrive as markup.
    let stripped = TAG.replace_all(&raw, "");
    let decoded = html_escape::decode_html_entities(&stripped);
    decoded.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// True if `n` is an element with this namespace and name.
fn is(n: &Node, ns: Option<&str>, name: &str) -> bool {
    n.is_element() && n.tag_name().name() == name && n.tag_name().namespace() == ns
}

/// Child elements with this namespace and name.
fn children<'a, 'i>(node: Node<'a, 'i>, ns: Option<&str>, name: &str) -> Vec<Node<'a, 'i>> {
    node.children().filter(|n| is(n, ns, name)).collect()
}

/// First child element with this namespace and name.
fn child<'a, 'i>(node: Node<'a, 'i>, ns: Option<&str>, name: &str) -> Option<Node<'a, 'i>> {
    node.children().find(|n| is(n, ns, name))
}

fn parse_date(s: &str) -> Option<DateTime<FixedOffset>> {
    let s = s.trim();
    if s.is_empty() {
        return None;
    }
    let utc = |n: NaiveDateTime| n.and_utc().fixed_offset();
    // RFC 822 (RSS), RFC 3339 (Atom), then looser ISO forms and a bare date.
    // The feed's own offset is kept, so the shown date is the author's.
    DateTime::parse_from_rfc2822(s)
        .or_else(|_| DateTime::parse_from_rfc3339(s))
        .or_else(|_| DateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f%:z"))
        .ok()
        .or_else(|| NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S%.f").ok().map(utc))
        .or_else(|| NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S%.f").ok().map(utc))
        .or_else(|| {
            let d = NaiveDate::parse_from_str(DATE_PREFIX.find(s)?.as_str(), "%Y-%m-%d").ok()?;
            Some(utc(d.and_hms_opt(0, 0, 0)?))
        })
}

/// `href` resolved against `base`, if that gives an http(s) URL.
fn join(base: &str, href: &str) -> Option<String> {
    let u = match url::Url::parse(base) {
        Ok(b) => b.join(href).ok()?,
        Err(_) => url::Url::parse(href).ok()?,
    };
    matches!(u.scheme(), "http" | "https").then(|| u.to_string())
}

fn atom_link(el: Node, base: &str) -> Option<String> {
    let links = children(el, Some(ATOM), "link");
    let first = *links.first()?;
    let alternate = links
        .into_iter()
        .find(|l| l.attribute("rel").unwrap_or("alternate") == "alternate" && l.attribute("href").is_some());
    join(base, alternate.unwrap_or(first).attribute("href").unwrap_or(""))
}

/// Origin of a URL with a trailing slash ("https://example.org/").
fn origin(url: &str) -> String {
    url::Url::parse(url).map(|u| format!("{}/", u.origin().ascii_serialization())).unwrap_or_default()
}

/// Blog title, home page and newest posts of an RSS 2.0, RSS 1.0 or Atom feed.
fn parse_feed(data: &[u8], url: &str) -> Result<Blog> {
    let text_data = String::from_utf8_lossy(data);
    // Feeds are taken as UTF-8 (nearly all are). A DOCTYPE is allowed, as
    // Python's parser allowed it; roxmltree bounds entity expansion.
    let opts = roxmltree::ParsingOptions { allow_dtd: true, ..Default::default() };
    let doc = Document::parse_with_options(text_data.trim_start_matches('\u{feff}'), opts)?;
    let root = doc.root_element();
    let mut raw: Vec<(String, Option<String>, String)> = Vec::new(); // title, link, date
    let (title, home);
    if root.tag_name().namespace() == Some(ATOM) && root.tag_name().name() == "feed" {
        title = text(child(root, Some(ATOM), "title"));
        home = atom_link(root, url);
        for e in children(root, Some(ATOM), "entry") {
            let mut d = text(child(e, Some(ATOM), "published"));
            if d.is_empty() {
                d = text(child(e, Some(ATOM), "updated"));
            }
            raw.push((text(child(e, Some(ATOM), "title")), atom_link(e, home.as_deref().unwrap_or(url)), d));
        }
    } else {
        let (channel, ns) = match child(root, None, "channel") {
            Some(c) => (c, None),
            None => match child(root, Some(RSS1), "channel") {
                Some(c) => (c, Some(RSS1)),
                None => bail!("not an RSS or Atom feed (root <{}>)", root.tag_name().name()),
            },
        };
        title = text(child(channel, ns, "title"));
        home = join(url, &text(child(channel, ns, "link")));
        let items = match ns {
            None => children(channel, None, "item"),
            Some(_) => children(root, Some(RSS1), "item"),
        };
        for i in items {
            let mut d = text(child(i, None, "pubDate"));
            if d.is_empty() {
                d = text(child(i, Some(DC), "date"));
            }
            let mut link = text(child(i, ns, "link"));
            if link.is_empty() {
                link = text(child(i, None, "guid"));
            }
            raw.push((text(child(i, ns, "title")), join(home.as_deref().unwrap_or(url), &link), d));
        }
    }
    let mut posts: Vec<Post> = raw
        .into_iter()
        .filter_map(|(t, link, d)| {
            let link = link?;
            let dt = parse_date(&d)?;
            Some(Post {
                title: if t.is_empty() { link.clone() } else { t },
                url: link,
                date: dt.format("%Y-%m-%d").to_string(),
                ts: dt.timestamp(),
            })
        })
        .collect();
    posts.sort_by_key(|p| std::cmp::Reverse(p.ts));
    posts.truncate(POSTS_PER_BLOG);
    let host = url::Url::parse(url).ok().and_then(|u| u.host_str().map(String::from)).unwrap_or_else(|| url.into());
    Ok(Blog {
        feed: url.into(),
        title: if title.is_empty() { host } else { title },
        url: home.unwrap_or_else(|| origin(url)),
        posts,
    })
}

fn fetch(agent: &ureq::Agent, url: &str) -> Result<Vec<u8>> {
    if !url.starts_with("https://") && !url.starts_with("http://") {
        bail!("not an http(s) URL");
    }
    let res = agent
        .get(url)
        .set("Accept", "application/atom+xml, application/rss+xml, application/xml;q=0.9, */*;q=0.5")
        .call()?;
    let mut data = Vec::new();
    res.into_reader().take(MAX_BYTES + 1).read_to_end(&mut data)?;
    if data.len() as u64 > MAX_BYTES {
        bail!("feed too large");
    }
    Ok(data)
}

fn load(agent: &ureq::Agent, url: &str) -> Option<Blog> {
    match fetch(agent, url).and_then(|d| parse_feed(&d, url)) {
        Ok(b) => Some(b),
        Err(e) => {
            eprintln!("blogroll: skipped {url}: {e:#}");
            None
        }
    }
}

fn post_json(p: &Post) -> Value {
    json!({"title": p.title, "url": p.url, "date": p.date})
}

fn build(urls: &[String]) -> Value {
    let agent = ureq::AgentBuilder::new().timeout(TIMEOUT).user_agent(USER_AGENT).build();
    // Fetch in parallel, keeping the list's order.
    let next = AtomicUsize::new(0);
    let mut slots: Vec<Option<Blog>> = (0..urls.len()).map(|_| None).collect();
    let results = std::sync::Mutex::new(&mut slots);
    std::thread::scope(|s| {
        for _ in 0..WORKERS.min(urls.len()) {
            s.spawn(|| loop {
                let i = next.fetch_add(1, Ordering::Relaxed);
                let Some(url) = urls.get(i) else { break };
                let b = load(&agent, url);
                results.lock().unwrap()[i] = b;
            });
        }
    });
    let mut blogs: Vec<Blog> = slots.into_iter().flatten().collect();

    let mut posts: Vec<(&Blog, &Post)> = blogs.iter().flat_map(|b| b.posts.iter().map(move |p| (b, p))).collect();
    posts.sort_by_key(|(_, p)| std::cmp::Reverse(p.ts));
    let posts: Vec<Value> = posts
        .iter()
        .take(MAX_POSTS)
        .map(|(b, p)| json!({"blog": b.title, "blog-url": b.url, "title": p.title, "url": p.url, "date": p.date}))
        .collect();
    let n = blogs.len();
    blogs.sort_by_key(|b| b.title.to_lowercase());
    json!({
        "fetched": Utc::now().format("%Y-%m-%d").to_string(),
        "posts": posts,
        "blogs": blogs.iter().map(|b| json!({"title": b.title, "url": b.url, "feed": b.feed})).collect::<Vec<_>>(),
        "failed": urls.len() - n,
    })
}

/// Write build/blogroll.json. Offline, keep the previous file (or write an empty one).
pub fn write(root: &Path, offline: bool) -> Result<()> {
    let out = root.join("build/blogroll.json");
    fs::create_dir_all(out.parent().unwrap())?;
    if offline {
        if !out.exists() {
            util::write_json(&out, &json!({"fetched": null, "posts": [], "blogs": [], "failed": 0}), 0)?;
        }
        println!("blogroll: offline, not fetching feeds");
        return Ok(());
    }
    let urls = read_list(&root.join("blogroll.txt"));
    let result = build(&urls);
    util::write_json(&out, &result, 1)?;
    println!(
        "blogroll: {}/{} feeds, {} posts",
        result["blogs"].as_array().map_or(0, Vec::len),
        urls.len(),
        result["posts"].as_array().map_or(0, Vec::len)
    );
    Ok(())
}

/// `cargo site blogroll FILE...`: what the blogroll keeps from local feed files.
pub fn print_files(files: &[String]) -> Result<()> {
    for f in files {
        let data = fs::read(f).with_context(|| format!("reading {f}"))?;
        let b = parse_feed(&data, "https://example.com/feed.xml").with_context(|| format!("parsing {f}"))?;
        let v = json!({
            "feed": b.feed, "title": b.title, "url": b.url,
            "posts": b.posts.iter().map(post_json).collect::<Vec<_>>(),
        });
        println!("{}", serde_json::to_string_pretty(&v)?);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rss_drops_non_http_links() {
        let feed = br#"<rss><channel><title>T</title><link>javascript:alert(1)</link>
            <item><title>Good</title><link>/a</link><pubDate>Tue, 03 Feb 2026 10:00:00 +0100</pubDate></item>
            <item><title>Bad</title><link>javascript:alert(1)</link><pubDate>Wed, 04 Feb 2026 10:00:00 GMT</pubDate></item>
        </channel></rss>"#;
        let b = parse_feed(feed, "https://example.org/feed.xml").unwrap();
        assert_eq!(b.url, "https://example.org/");
        assert_eq!(b.posts.len(), 1);
        assert_eq!(b.posts[0].url, "https://example.org/a");
        assert_eq!(b.posts[0].date, "2026-02-03");
    }

    #[test]
    fn atom() {
        let feed = br#"<feed xmlns="http://www.w3.org/2005/Atom"><title type="html">A &lt;b&gt;bold&lt;/b&gt; &amp;amp; co</title>
            <link rel="self" href="/feed.xml"/><link href="https://blog.example/"/>
            <entry><title>One</title><link href="posts/1"/><updated>2026-01-02T03:04:05Z</updated></entry>
        </feed>"#;
        let b = parse_feed(feed, "https://blog.example/feed.xml").unwrap();
        assert_eq!(b.title, "A bold & co");
        assert_eq!(b.url, "https://blog.example/");
        assert_eq!(b.posts[0].url, "https://blog.example/posts/1");
        assert_eq!(b.posts[0].date, "2026-01-02");
    }

    #[test]
    fn dates() {
        assert_eq!(parse_date("2026-01-02").unwrap().format("%F").to_string(), "2026-01-02");
        assert_eq!(parse_date("2026-01-02 10:00:00").unwrap().format("%F").to_string(), "2026-01-02");
        assert!(parse_date("someday").is_none());
    }
}
