# AGENTS.md — Working rules for AI agents on this repository

This is the source of **xinhongsmart.com**, the English B2B site of Shenzhen Xinhong Smart
Technology Co., Ltd. (rugged tablets, handheld PDAs, biometric terminals). The old Chinese
site xinhong.site runs on a separate server and is **not** in this repository — never touch
it from here.

Read this file before making changes. Several decisions below were made after real
incidents; reversing them silently is how problems come back.

## What this site is

- **Static HTML, no build step.** Repository root = site root. Deploy = `git push` to
  `main`; GitHub Pages serves it. Build takes ~90 seconds.
- Shared stylesheet: `assets/style.css`. Images live under `uploads/` (with `-800` /
  `-1200` / `.webp` variants). Articles live under `insights/<slug>/index.html`; product
  pages under `products/<category>/<slug>/index.html`.
- `llms.txt` at the root is the AI-readable site summary — keep it in sync when pages are
  added.

## Git and deploy

- Default branch is `main`. After every push, **verify it actually landed**:
  `git ls-remote origin refs/heads/main` must match your local `git rev-parse HEAD`.
  A silent push failure has happened before and left the live site stale.
- Verify the deploy ~100 s after push with `curl`: the page must return 200 and contain
  the new content (check the title or a new string, not just the status code).
- Commit messages: imperative subject line, body explaining **why**, not just what.

## Page structure rules

1. **One `<h1>` per page.** On the homepage the H1 is an `sr-only` heading inside the
   hero; the visible hero headline is an `<h2>`. Do not "fix" this.
2. **Titles ≤ 60 characters, core product term only.** Long-tail keywords go into the
   description, body and FAQ — not stacked into the title.
3. **Do not add page-level `<style>` blocks that override site variables.** The shared
   stylesheet already covers article typography and tables. The exceptions are
   `.answer-lead` and `.article-byline`, which need inline styles copied from a sibling
   article.
4. **New article pages must copy head, header and footer from an existing article**
   (e.g. `insights/hk-electronics-fair-2026/index.html`). That is what carries the GA4
   snippet (`G-459FM7B610` + `xhsLeadTrack` conversion listeners) and the correct relative
   stylesheet link. A page built from scratch will lose lead analytics.
5. Article JSON-LD is a `@graph` of `WebPage`+`FAQPage`, `Article`, `BreadcrumbList`.
   The Article `abstract` must be the same text as the visible "Quick answer" block.

## SEO decisions already made — do not reverse without the owner

- **No `Product` schema on product pages.** Removed 2026-10-15 because GSC reports
  invalid content (a Product needs `offers`, `review` or `aggregateRating`; a
  made-to-order B2B site has neither). It was accidentally re-added once and reverted
  (2026-10-28). Do not add it a third time. Machine-readable specs belong in `llms.txt`.
- **No new URLs for attribute words.** OS version, RFID band, NFC, screen size, IP rating
  etc. are handled on existing product/guide pages. One product belongs to exactly one
  category, and categories are by form factor only (rugged tablets / handheld PDAs /
  biometric devices / document devices / POS terminals).
- **Case-study articles state only verifiable facts:** country, application, the model
  used, device capabilities and specs already published on product pages. No invented
  quantities, prices, signing dates or client names — buyers check.

## Publishing a new article — full checklist

Skipping any step means the page is effectively not published:

1. `insights/<slug>/index.html` — Quick answer block, visible FAQ (`<h3>`+`<p>`), a
   `landing-faq` `<details>` copy of the same FAQ, and a `Related reading` line.
2. `insights/index.html` — prepend a row in `.article-list`; increment the eyebrow count
   `NEWS / N`; insert the item at position 1 of the CollectionPage `hasPart` JSON-LD and
   renumber the rest.
3. `index.html` (home) — prepend a tile in `.news-grid` and delete the oldest tile so
   exactly **4** tiles remain (the grid wraps badly at 5).
4. `sitemap.xml` — append the URL. Exclude `404.html` and the legacy redirect stubs
   (`/products/xh-100/`, `/custom/`, etc.).
5. `llms.txt` — add the title + URL under "Technical Guides and Articles".
6. **Backlink:** add a link to the new article in the `Related reading` line of 2–3
   related existing articles.
7. Images: `<picture>` with a WebP `<source>`, `width`/`height` matching the real pixel
   dimensions, hero `loading="eager"`, the rest `lazy`. Do not reference files that do
   not exist — e.g. `uploads/blog/quality-lab.webp` does not exist, only
   `quality-lab-800.webp`.

## After any change

- Re-parse every JSON-LD block you touched (`json.loads`), and check internal links —
  a dead link or a broken script is a P0. Known trap: the existing slug is
  `civil-identity-enrolment-biometric-terminal`, **not** `…-biometric-tablet`.
- Test at least one changed page in a real browser (headless is fine): title, single H1,
  Quick answer visible, no JS errors, no 404 resources.

## What is not in this repository

- **Bing Webmaster / IndexNow submissions** run from the owner's machine with a local API
  key. The daily quota is 100 URLs — if you submit, check the remaining quota first.
- **Google Search Console** access is separate; GitHub credentials do not include it.
- If you are an external agent: you were most likely given a fine-grained token with
   Contents read/write on this repo only. That is all you need to edit the site.
