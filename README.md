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
| `/products/` | Product catalogue: 4 category pages + **11 product pages** |
| `/biometric-tablet/` | Biometric tablet overview |
| `/oem-odm/` | OEM / ODM customization — overview plus 5 sub-pages |
| `/insights/` | **15** technical guides and application notes |
| `/about/` | Company profile, factory and certifications |
| `/contact/` | Contact details, company verification and enquiry form |

Products: XH-100 to XH-500 series, 8-inch rugged tablet, 10-inch rugged tablet, 5-inch handheld PDA, document camera scanner, signature pad, dual-screen ID verification terminal.

Old flat URLs (for example `/products/xh-100/`, `/products/10-inch-rugged-tablet/`, `/custom/`) are kept as thin redirect stubs — canonical link plus meta refresh — so existing inbound links and citations keep working. The canonical addresses are the nested ones listed above; nothing on the site links to the stubs any more.

## Machine-readable metadata

| File | Purpose |
|---|---|
| `llms.txt` | Summarized company and product facts for AI / LLM retrieval |
| `sitemap.xml` | XML sitemap (**42** URLs) |
| `robots.txt` | Crawler rules; GPTBot, ClaudeBot, PerplexityBot, Google-Extended, CCBot and Applebot explicitly allowed |
| JSON-LD (inline) | Organization / WebSite on every page; Product, FAQPage, Article, BreadcrumbList where relevant |

## Contact form

The enquiry form on `/contact/` posts to FormSubmit and delivers to `sales@xinhongsmart.com`.

**FormSubmit needs a one-time activation:** after the first real submission it sends an activation link to that mailbox — until the link is opened, submissions are held and not delivered. Submit one test enquiry after deploy, open the activation email, and delivery works from then on.

To switch provider, replace the `action` URL on the `<form>` element in `contact/index.html`.

## Implementation notes

- Static HTML, no build step, no JavaScript framework
- Structured data: Organization, Product, FAQPage, Article, BreadcrumbList (JSON-LD)
- Images are served as WebP with a JPEG/PNG fallback through `<picture>`
- The stylesheet is loaded with a hard-coded `?v=` version — **bump it in every page when `assets/style.css` changes**, otherwise Cloudflare's edge keeps serving the old file
- Related site for the China market: https://www.xinhong.site/

## Repository layout

```
index.html                  Homepage
about/ contact/             Company profile, contact details and enquiry form
products/                   4 category pages + 11 product pages
biometric-tablet/           Biometric tablet overview
oem-odm/                    OEM/ODM overview + 5 sub-pages
insights/                   15 articles + section index
assets/                     Stylesheet and site images
uploads/                    Article and product images
sitemap.xml  robots.txt  llms.txt  404.html
```
