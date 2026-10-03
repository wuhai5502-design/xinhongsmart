# Xinhong Smart — Official Website

**Live site:** https://xinhongsmart.com/

Source repository for the website of **Shenzhen Xinhong Smart Technology Co., Ltd.** (Xinhong Smart), a Shenzhen-based manufacturer of rugged mobile computing and identity verification hardware. Served by GitHub Pages on the custom domain `xinhongsmart.com`.

## About the company

Xinhong Smart designs and manufactures:

- **Industrial rugged tablets** — 8-inch and 10-inch, Android 12 or Windows 11, IP65 / IP67
- **Handheld PDAs and mobile computers** — 5-inch and 6-inch, Android 12
- **Biometric handheld terminals** — fingerprint capture, face recognition
- **Document camera scanners** — A3 / A4, 1-second capture
- **Digital signature pads** — 10.1-inch, 5080 LPI electromagnetic pen, 2048 pressure levels
- **Dual-screen ID verification terminals** — dual 15.6-inch panels, ID card reader, document camera

Data capture options: 1D/2D barcode scanning (Honeywell / Zebra / Newland engines), fingerprint, RFID, NFC, national ID card reading, high-resolution document imaging.

OEM/ODM services cover interface, hardware, software and mechanical customization, plus SDK and API integration.

Typical deployments: warehousing and logistics, manufacturing and MES, field inspection and utilities, voter registration, bank card issuance, border and immigration control, healthcare, and public-sector identity programs.

**Contact:** sales@xinhongsmart.com | +86 185 9427 9341

## Site structure

| Path | Content |
|---|---|
| `/` | Homepage |
| `/products/` | 11 product pages |
| `/custom/` | OEM / ODM customization |
| `/insights/` | 9 technical guides and application notes |
| `/about/` | Company profile and contact |

Products: XH-100 to XH-500 series, 8-inch rugged tablet, 10-inch rugged tablet, 5-inch handheld PDA, document camera scanner, signature pad, dual-screen ID verification terminal.

## Machine-readable metadata

| File | Purpose |
|---|---|
| `llms.txt` | Summarized company and product facts for AI / LLM retrieval |
| `sitemap.xml` | XML sitemap (25 URLs) |
| `robots.txt` | Crawler rules; GPTBot, ClaudeBot, PerplexityBot, Google-Extended, CCBot and Applebot explicitly allowed |
| `schema-organization.html` | Shared Organization JSON-LD |

## Implementation notes

- Static HTML, no build step, no JavaScript framework
- Structured data: Organization, Product, FAQPage, Article, BreadcrumbList (JSON-LD)
- Related site for the China market: https://www.xinhong.site/

## Repository layout

```
index.html                  Homepage
about/ custom/ insights/    Section pages
products/                   11 product pages
assets/                     Stylesheet and site images
uploads/                    Article images
sitemap.xml  robots.txt  llms.txt  404.html
```
