#!/usr/bin/env python3
"""Fetch the feeds listed in blogroll.txt and write build/blogroll.json.

Called by scripts/build.py before compiling; the /blogroll/ page (lib/indexes.typ)
lists the latest posts of every blog, newest first, like
https://matklad.github.io/links.html.

A feed that times out, errors or doesn't parse is skipped with a warning: the
build never fails because someone else's site is down.

Usage:
    python3 scripts/blogroll.py            # fetch and write build/blogroll.json
    python3 scripts/blogroll.py FILE.xml   # parse local files, print the result
"""
from __future__ import annotations

import html
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.parse import urljoin

ROOT = Path(__file__).resolve().parent.parent
LIST = ROOT / "blogroll.txt"
OUT = ROOT / "build" / "blogroll.json"

POSTS_PER_BLOG = 3   # newest posts kept from each feed
MAX_POSTS = 150      # length of the merged list on the page
TIMEOUT = 15         # seconds per feed
MAX_BYTES = 10 << 20 # ignore feeds larger than this
USER_AGENT = "lucien.ch-blogroll/1.0 (+https://lucien.ch/blogroll/)"

ATOM = "{http://www.w3.org/2005/Atom}"
RSS1 = "{http://purl.org/rss/1.0/}"
DC = "{http://purl.org/dc/elements/1.1/}"
TAG = re.compile(r"<[^>]+>")


def read_list(path: Path = LIST) -> list[str]:
    """Feed URLs, one per line; `#` starts a comment."""
    if not path.exists():
        return []
    urls = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            urls.append(line.split()[0])  # anything after the URL is a comment
    return urls


def text(el: ET.Element | None) -> str:
    """Plain text of an element: entities decoded, HTML tags stripped, spaces collapsed."""
    if el is None:
        return ""
    s = "".join(el.itertext())
    s = html.unescape(TAG.sub("", s))  # Atom type="html" titles arrive as markup
    return " ".join(s.split())


def parse_date(s: str) -> datetime | None:
    s = s.strip()
    if not s:
        return None
    try:
        d = parsedate_to_datetime(s)  # RFC 822 (RSS)
    except (TypeError, ValueError, IndexError):
        try:
            d = datetime.fromisoformat(s.replace("Z", "+00:00"))  # RFC 3339 (Atom)
        except ValueError:
            m = re.match(r"\d{4}-\d{2}-\d{2}", s)
            if not m:
                return None
            d = datetime.fromisoformat(m.group())
    if d.tzinfo is None:
        d = d.replace(tzinfo=timezone.utc)
    return d  # keeps the feed's own offset, so the shown date is the author's


def atom_link(el: ET.Element, base: str) -> str:
    links = el.findall(ATOM + "link")
    for l in links:
        if l.get("rel", "alternate") == "alternate" and l.get("href"):
            return urljoin(base, l.get("href"))
    return urljoin(base, links[0].get("href", "")) if links else ""


def parse_feed(data: bytes, url: str) -> dict:
    """Blog title, home page and newest posts of an RSS 2.0, RSS 1.0 or Atom feed."""
    root = ET.fromstring(data)
    posts = []
    if root.tag == ATOM + "feed":
        title = text(root.find(ATOM + "title"))
        home = atom_link(root, url)
        for e in root.findall(ATOM + "entry"):
            d = text(e.find(ATOM + "published")) or text(e.find(ATOM + "updated"))
            posts.append((text(e.find(ATOM + "title")), atom_link(e, home or url), d))
    else:
        channel = root.find("channel")
        if channel is None:
            channel = root.find(RSS1 + "channel")
        if channel is None:
            raise ValueError(f"not an RSS or Atom feed (root <{root.tag}>)")
        ns = "" if channel.tag == "channel" else RSS1
        title = text(channel.find(ns + "title"))
        home = urljoin(url, text(channel.find(ns + "link")))
        items = channel.findall("item") if ns == "" else root.findall(RSS1 + "item")
        for i in items:
            d = text(i.find("pubDate")) or text(i.find(DC + "date"))
            link = text(i.find(ns + "link")) or text(i.find("guid"))
            posts.append((text(i.find(ns + "title")), urljoin(home or url, link), d))
    out = []
    for t, link, d in posts:
        dt = parse_date(d)
        if not link or dt is None:
            continue
        out.append({"title": t or link, "url": link, "date": dt.strftime("%Y-%m-%d"), "ts": dt.timestamp()})
    out.sort(key=lambda p: p["ts"], reverse=True)
    if not home:
        home = re.sub(r"^(https?://[^/]+).*", r"\1/", url)
    return {"feed": url, "title": title or re.sub(r"^https?://([^/]+).*", r"\1", url), "url": home,
            "posts": out[:POSTS_PER_BLOG]}


def fetch(url: str) -> bytes:
    if not url.startswith(("https://", "http://")):
        raise ValueError("not an http(s) URL")
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/atom+xml, application/rss+xml, application/xml;q=0.9, */*;q=0.5"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        data = r.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("feed too large")
    return data


def load(url: str) -> dict | None:
    try:
        return parse_feed(fetch(url), url)
    except Exception as e:  # noqa: BLE001 - any failure just skips this feed
        print(f"blogroll: skipped {url}: {e}", file=sys.stderr)
        return None


def build(urls: list[str]) -> dict:
    with ThreadPoolExecutor(max_workers=16) as pool:
        blogs = [b for b in pool.map(load, urls) if b]
    posts = [
        {"blog": b["title"], "blog-url": b["url"], **p}
        for b in blogs for p in b["posts"]
    ]
    posts.sort(key=lambda p: p["ts"], reverse=True)
    for p in posts:
        del p["ts"]
    for b in blogs:
        for p in b["posts"]:
            p.pop("ts", None)
    blogs.sort(key=lambda b: b["title"].lower())
    return {
        "fetched": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "posts": posts[:MAX_POSTS],
        "blogs": [{"title": b["title"], "url": b["url"], "feed": b["feed"]} for b in blogs],
        "failed": len(urls) - len(blogs),
    }


def write(offline: bool = False) -> None:
    """Write build/blogroll.json. Offline, keep the previous file (or write an empty one)."""
    OUT.parent.mkdir(exist_ok=True)
    if offline:
        if not OUT.exists():
            OUT.write_text(json.dumps({"fetched": None, "posts": [], "blogs": [], "failed": 0}))
        print("blogroll: offline, not fetching feeds")
        return
    urls = read_list()
    result = build(urls)
    OUT.write_text(json.dumps(result, indent=1, ensure_ascii=False))
    print(f"blogroll: {len(result['blogs'])}/{len(urls)} feeds, {len(result['posts'])} posts")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        for f in sys.argv[1:]:
            print(json.dumps(parse_feed(Path(f).read_bytes(), "https://example.com/feed.xml"), indent=1, ensure_ascii=False))
    else:
        write()
