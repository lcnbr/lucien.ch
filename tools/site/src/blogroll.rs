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
use encoding_rs::{Encoding, UTF_8};
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
static XML_ENCODING: LazyLock<regex::bytes::Regex> = LazyLock::new(|| {
    regex::bytes::Regex::new(r#"\A\s*<\?xml\s[^>]*?\bencoding\s*=\s*["']([A-Za-z0-9._:-]+)["']"#).unwrap()
});
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

/// The feed as text, in the encoding its BOM gives, else the one its XML
/// declaration names, else the server's charset, else UTF-8 (XML's default).
fn decode(data: &[u8], charset: Option<&str>) -> String {
    // A declaration that could be read as ASCII can't truthfully say UTF-16.
    let label = |l: &[u8]| Encoding::for_label(l).filter(|e| e.is_ascii_compatible());
    let declared = || label(XML_ENCODING.captures(data)?.get(1)?.as_bytes());
    let enc = Encoding::for_bom(data)
        .map(|(e, _)| e)
        .or_else(declared)
        .or_else(|| label(charset?.as_bytes()))
        .unwrap_or(UTF_8);
    enc.decode(data).0.into_owned() // drops a BOM
}

/// Plain text of an element, spaces collapsed.
fn text(node: Option<Node>) -> String {
    let Some(node) = node else { return String::new() };
    let raw: String = node.descendants().filter(|n| n.is_text()).filter_map(|n| n.text()).collect();
    raw.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Text of an element that holds escaped HTML: tags stripped, entities decoded.
fn html_text(node: Option<Node>) -> String {
    let html = text(node);
    let stripped = TAG.replace_all(&html, "");
    html_escape::decode_html_entities(&stripped).split_whitespace().collect::<Vec<_>>().join(" ")
}

/// An Atom text construct: plain text, escaped HTML (type="html"), or XHTML
/// (type="xhtml"), whose markup is elements, so its text nodes are the text.
fn atom_text(node: Option<Node>) -> String {
    match node.and_then(|n| n.attribute("type")) {
        Some("html") => html_text(node),
        _ => text(node),
    }
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

/// An Atom element's rel="alternate" link (the default rel). With `any`, else
/// its first other link, but never rel="self", which is the feed (or entry)
/// document itself, not a page to read.
fn atom_link(el: Node, base: &str, any: bool) -> Option<String> {
    let links: Vec<Node> = children(el, Some(ATOM), "link").into_iter().filter(|l| l.has_attribute("href")).collect();
    let rel_is = |l: &&Node, rel: &str| l.attribute("rel").unwrap_or("alternate") == rel;
    let link =
        links.iter().find(|l| rel_is(l, "alternate")).or_else(|| links.iter().find(|l| any && !rel_is(l, "self")))?;
    join(base, link.attribute("href")?)
}

/// Origin of a URL with a trailing slash ("https://example.org/").
fn origin(url: &str) -> String {
    url::Url::parse(url).map(|u| format!("{}/", u.origin().ascii_serialization())).unwrap_or_default()
}

/// Blog title, home page and newest posts of an RSS 2.0, RSS 1.0 or Atom feed.
/// `charset` is the one the server named, if any.
fn parse_feed(data: &[u8], url: &str, charset: Option<&str>) -> Result<Blog> {
    let text_data = decode(data, charset);
    // A DOCTYPE is allowed, as Python's parser allowed it; roxmltree bounds
    // entity expansion.
    let opts = roxmltree::ParsingOptions { allow_dtd: true, ..Default::default() };
    let doc = Document::parse_with_options(&text_data, opts)?;
    let root = doc.root_element();
    let mut raw: Vec<(String, Option<String>, String)> = Vec::new(); // title, link, date
    let (title, home);
    // Titles are plain text in RSS, and in Atom unless type="html" says otherwise.
    if root.tag_name().namespace() == Some(ATOM) && root.tag_name().name() == "feed" {
        title = atom_text(child(root, Some(ATOM), "title"));
        home = atom_link(root, url, false);
        for e in children(root, Some(ATOM), "entry") {
            let mut d = text(child(e, Some(ATOM), "published"));
            if d.is_empty() {
                d = text(child(e, Some(ATOM), "updated"));
            }
            raw.push((atom_text(child(e, Some(ATOM), "title")), atom_link(e, home.as_deref().unwrap_or(url), true), d));
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

/// The feed's bytes, and the charset its Content-Type names, if any.
fn fetch(agent: &ureq::Agent, url: &str) -> Result<(Vec<u8>, Option<String>)> {
    if !url.starts_with("https://") && !url.starts_with("http://") {
        bail!("not an http(s) URL");
    }
    let res = agent
        .get(url)
        .set("Accept", "application/atom+xml, application/rss+xml, application/xml;q=0.9, */*;q=0.5")
        .call()?;
    let charset = res.header("Content-Type").and_then(|ct| {
        let mut params = ct.split(';').skip(1).filter_map(|p| p.split_once('='));
        let (_, v) = params.find(|(k, _)| k.trim().eq_ignore_ascii_case("charset"))?;
        Some(v.trim().trim_matches('"').to_string())
    });
    let mut data = Vec::new();
    res.into_reader().take(MAX_BYTES + 1).read_to_end(&mut data)?;
    if data.len() as u64 > MAX_BYTES {
        bail!("feed too large");
    }
    Ok((data, charset))
}

fn load(agent: &ureq::Agent, url: &str) -> Option<Blog> {
    match fetch(agent, url).and_then(|(d, charset)| parse_feed(&d, url, charset.as_deref())) {
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
        let b = parse_feed(&data, "https://example.com/feed.xml", None).with_context(|| format!("parsing {f}"))?;
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
        let b = parse_feed(feed, "https://example.org/feed.xml", None).unwrap();
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
        let b = parse_feed(feed, "https://blog.example/feed.xml", None).unwrap();
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

    fn rss_title(b: &Blog) -> (&str, &str) {
        (b.title.as_str(), b.posts[0].title.as_str())
    }

    #[test]
    fn encodings() {
        let item = b"<item><title>Th\xe9\xe2tre</title><link>/a</link><pubDate>2026-01-02</pubDate></item>";
        let latin1 = [
            &b"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><rss><channel><title>Caf\xe9</title>"[..],
            item,
            b"</channel></rss>",
        ]
        .concat();
        let b = parse_feed(&latin1, "https://example.org/feed.xml", None).unwrap();
        assert_eq!(rss_title(&b), ("Café", "Théâtre"));
        // The declaration wins over the server's charset, the BOM over both.
        let b = parse_feed(&latin1, "https://example.org/feed.xml", Some("utf-8")).unwrap();
        assert_eq!(b.title, "Café");
        // No declaration: the server's charset, else UTF-8.
        let bare = [&b"<rss><channel><title>Caf\xe9</title>"[..], item, b"</channel></rss>"].concat();
        let b = parse_feed(&bare, "https://example.org/feed.xml", Some("iso-8859-1")).unwrap();
        assert_eq!(b.title, "Café");
        let utf8 =
            "\u{feff}<?xml version='1.0' encoding='iso-8859-1'?><rss><channel><title>Café</title></channel></rss>";
        assert_eq!(parse_feed(utf8.as_bytes(), "https://example.org/", None).unwrap().title, "Café");
        let utf16: Vec<u8> =
            "\u{feff}<?xml version=\"1.0\" encoding=\"UTF-16\"?><rss><channel><title>Café</title></channel></rss>"
                .encode_utf16()
                .flat_map(u16::to_le_bytes)
                .collect();
        assert_eq!(parse_feed(&utf16, "https://example.org/", None).unwrap().title, "Café");
        // A declaration read as ASCII can't be UTF-16: UTF-8 then.
        let liar = "<?xml version='1.0' encoding='utf-16'?><rss><channel><title>Café</title></channel></rss>";
        assert_eq!(parse_feed(liar.as_bytes(), "https://example.org/", None).unwrap().title, "Café");
    }

    #[test]
    fn plain_and_html_titles() {
        let rss = br#"<rss><channel><title>Vec&lt;T&gt; &amp; co</title>
            <item><title>Why &lt;b&gt; is not bold</title><link>/a</link><pubDate>2026-01-02</pubDate></item>
        </channel></rss>"#;
        let b = parse_feed(rss, "https://example.org/feed.xml", None).unwrap();
        assert_eq!(rss_title(&b), ("Vec<T> & co", "Why <b> is not bold"));
        let atom = br#"<feed xmlns="http://www.w3.org/2005/Atom"><title>Vec&lt;T&gt;</title>
            <entry><title type="html">Vec&amp;lt;T&amp;gt; in &lt;i&gt;Rust&lt;/i&gt;</title><link href="/1"/><updated>2026-01-03</updated></entry>
            <entry><title type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">Vec&lt;T&gt; in <i>Rust</i></div></title><link href="/2"/><updated>2026-01-02</updated></entry>
        </feed>"#;
        let b = parse_feed(atom, "https://example.org/feed.xml", None).unwrap();
        assert_eq!(b.title, "Vec<T>");
        assert_eq!(b.posts[0].title, "Vec<T> in Rust");
        assert_eq!(b.posts[1].title, "Vec<T> in Rust");
    }

    #[test]
    fn atom_self_link_is_not_the_home_page() {
        let feed = br#"<feed xmlns="http://www.w3.org/2005/Atom"><title>T</title>
            <link rel="self" href="https://blog.example/notes/feed.atom"/><link rel="hub" href="https://hub.example/"/>
            <entry><title>A</title><link rel="self" href="/api/a.atom"/><link href="/a"/><updated>2026-01-02</updated></entry>
            <entry><title>B</title><link rel="self" href="/api/b.atom"/><updated>2026-01-01</updated></entry>
        </feed>"#;
        let b = parse_feed(feed, "https://blog.example/notes/feed.atom", None).unwrap();
        assert_eq!(b.url, "https://blog.example/");
        assert_eq!(b.posts.len(), 1);
        assert_eq!(b.posts[0].url, "https://blog.example/a");
    }
}
