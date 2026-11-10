#!/usr/bin/env python3
"""Report pages whose sitemap <lastmod> is older than the file's last commit.

The IndexNow workflow only submits pages whose lastmod is recent, so a page
whose content changed without a lastmod bump is silently never pushed. This
script is the guard: run it before committing.

    python tools/check-lastmod.py
    python tools/check-lastmod.py --fail        # exit 1 when anything is behind

Not every hit is a mistake. A bulk edit - a footer change, a skip link added on
every page - touches files without changing their content, and those pages are
deliberately left alone. The commit subject is printed so you can tell the two
apart at a glance.
"""

import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GIT = 'git'


def git(*args):
    out = subprocess.run([GIT, '-C', ROOT, *args], capture_output=True, text=True,
                         encoding='utf-8', errors='replace')
    return out.stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--fail', action='store_true', help='exit 1 when any page is behind')
    ap.add_argument('--quiet', action='store_true', help='summary only')
    args = ap.parse_args()

    sm = open(os.path.join(ROOT, 'sitemap.xml'), encoding='utf-8').read()
    entries = []
    for block in re.findall(r'(?s)<url>(.*?)</url>', sm):
        loc = re.search(r'<loc>\s*([^<]+?)\s*</loc>', block)
        lm = re.search(r'<lastmod>\s*([^<]+?)\s*</lastmod>', block)
        if loc:
            entries.append((loc.group(1).strip(), (lm.group(1).strip() if lm else '')))

    behind = []
    for url, lastmod in entries:
        rel = url.replace('https://xinhongsmart.com', '').strip('/')
        path = (rel + '/index.html') if rel else 'index.html'
        if not os.path.exists(os.path.join(ROOT, path)):
            continue
        date = git('log', '-1', '--format=%cs', '--', path)
        if date and lastmod and date > lastmod:
            subject = git('log', '-1', '--format=%s', '--', path)
            behind.append((url, lastmod, date, subject))

    if not behind:
        print('sitemap lastmod is up to date for all %d pages.' % len(entries))
        return 0

    print('%d of %d pages have a lastmod older than their last commit:' % (len(behind), len(entries)))
    if not args.quiet:
        for url, lastmod, date, subject in behind:
            print('  %s -> %s  %-58s %s' % (lastmod, date, url.replace('https://xinhongsmart.com', '') or '/',
                                            subject[:60]))
        print('\nIf the commit only touched shared boilerplate (footer, skip link, consent), '
              'leaving lastmod alone is correct. Otherwise bump it, or the page will not be pushed.')
    return 1 if args.fail else 0


if __name__ == '__main__':
    sys.exit(main())
