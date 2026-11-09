#!/usr/bin/env python3
"""Submit the pages changed in this push to IndexNow.

Ownership is proved by /<key>.txt at the site root, so no secret is stored in
this repository or in the workflow.

Rules, in order:
  1. A URL is a candidate only if it maps to an index.html changed in this push
     (git diff HEAD^..HEAD), or was passed with --urls.
  2. It is dropped unless sitemap.xml lists it - the legacy redirect stubs and
     404.html must never be submitted.
  3. On a push, it is also dropped unless its lastmod is within a couple of
     days. A bulk edit that touches every page (a footer change, a skip link)
     must not burn the daily quota on pages whose content did not change.
  4. At most --max URLs are sent (default 100).

Usage:
    python3 tools/indexnow_ci.py               # use the push diff
    python3 tools/indexnow_ci.py --dry-run     # show what would be sent
    python3 tools/indexnow_ci.py --urls https://xinhongsmart.com/foo/
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import date, timedelta

HOST = "xinhongsmart.com"
BASE = f"https://{HOST}/"
KEY = "a79072b72a494fef94801722677a0723"
KEY_LOCATION = f"https://{HOST}/{KEY}.txt"
ENDPOINT = "https://api.indexnow.org/indexnow"


def urls_from_diff():
    has_parent = subprocess.run(
        ["git", "rev-parse", "--verify", "HEAD^"], capture_output=True
    ).returncode == 0
    cmd = (
        ["git", "diff", "--name-only", "HEAD^", "HEAD"]
        if has_parent
        else ["git", "show", "--name-only", "--format=", "HEAD"]
    )
    files = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout.split()

    urls = set()
    for f in files:
        if f == "index.html":
            urls.add(BASE)
        elif f.endswith("/index.html"):
            urls.add(BASE + f[: -len("index.html")])
    return sorted(urls)


def sitemap_entries(path="sitemap.xml"):
    with open(path, encoding="utf-8") as fh:
        raw = fh.read()
    out = {}
    for block in re.findall(r"<url>(.*?)</url>", raw, re.S):
        loc = re.search(r"<loc>\s*([^<]+?)\s*</loc>", block)
        lm = re.search(r"<lastmod>\s*([^<]+?)\s*</lastmod>", block)
        if loc:
            out[loc.group(1).strip()] = lm.group(1).strip() if lm else ""
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--urls", nargs="*", default=None,
                    help="submit these URLs instead of reading the push diff")
    ap.add_argument("--max", type=int, default=100)
    ap.add_argument("--recent-days", type=int, default=2)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    manual = bool(args.urls)
    urls = sorted({u.strip() for u in args.urls}) if manual else urls_from_diff()

    if not urls:
        print("No page changed in this push, nothing to submit.")
        return 0

    book = sitemap_entries()

    unknown = [u for u in urls if u not in book]
    known = [u for u in urls if u in book]

    stale = []
    if not manual:
        cutoff = (date.today() - timedelta(days=args.recent_days)).isoformat()
        stale = [u for u in known if book[u] < cutoff]
        known = [u for u in known if book[u] >= cutoff]

    if unknown:
        print("Not in sitemap, skipped:")
        for u in unknown:
            print("  " + u)
    if stale:
        print("lastmod older than the cutoff, skipped:")
        for u in stale:
            print("  " + u)

    if not known:
        print("Nothing eligible to submit.")
        return 0

    if len(known) > args.max:
        print(f"{len(known)} pages changed, submitting the first {args.max} only.")
        known = known[: args.max]

    print(f"Submitting {len(known)} URL(s):")
    for u in known:
        print("  " + u)

    if args.dry_run:
        print("Dry run, nothing sent.")
        return 0

    payload = json.dumps({
        "host": HOST,
        "key": KEY,
        "keyLocation": KEY_LOCATION,
        "urlList": known,
    }).encode("utf-8")

    req = urllib.request.Request(
        ENDPOINT, data=payload, method="POST",
        headers={"Content-Type": "application/json; charset=utf-8"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            print(f"IndexNow responded HTTP {r.status}")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:400]
        print(f"IndexNow responded HTTP {e.code}: {body}")
        return 1

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write("### IndexNow\n\n")
            fh.write(f"Submitted {len(known)} URL(s):\n\n")
            for u in known:
                fh.write(f"- {u}\n")
            for label, items in (("Not in sitemap", unknown),
                                 ("lastmod too old", stale)):
                if items:
                    fh.write(f"\n{label}:\n\n")
                    for u in items:
                        fh.write(f"- {u}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
