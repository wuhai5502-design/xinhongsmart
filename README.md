# xinhongsmart.com 新独立站 · 部署包

生成日期：2026-09-28
内容基准：老站产品真实参数（products 表），全部文案**原创重写**，未复制老站英文内容。

## 文件清单

| 文件 | 用途 | 部署位置建议 |
|------|------|-------------|
| `product-8-inch-rugged-tablet.html` | 8寸三防平板产品页 | `/products/8-inch-rugged-tablet/` |
| `product-10-inch-rugged-tablet.html` | 10寸三防平板产品页 | `/products/10-inch-rugged-tablet/` |
| `product-handheld-pda.html` | 5寸工业手持终端产品页 | `/products/handheld-pda/` |
| `product-document-camera-scanner.html` | A3高拍仪/文档摄录仪产品页 | `/products/document-camera-scanner/` |
| `product-signature-pad.html` | 10.1寸手写签字板产品页 | `/products/signature-pad/` |
| `product-dual-screen-id-terminal.html` | 双屏人证核验终端产品页 | `/products/dual-screen-id-verification-terminal/` |
| `schema-organization.html` | 全站公共 Organization 结构化数据 | 每页 `</head>` 前（或公共模板） |
| `robots.txt` | 爬虫规则 | 站点根目录 |
| `seo-checklist.md` | 上线技术清单（GSC/sitemap/IndexNow 等） | 参考，不部署 |
| `sitemap-template.xml` | sitemap 模板（含 6 个产品 URL） | 站点根目录 `sitemap.xml` |

## 每个 HTML 文件的内部结构

```
<!-- ============ SEO META ============ -->
  title / meta description / canonical / H1 —— 部署时填入对应模板字段
<!-- ============ PAGE CONTENT ============ -->
  完整正文 HTML（hero → features → specs → workflows → FAQ → CTA）
  可直接作为页面主体，或按 CodeBuddy 站点模板拆分
<!-- ============ JSON-LD ============ -->
  Product + FAQPage 结构化数据，放 </head> 前或 </body> 前
```

## 内链关系（已写进文案，部署后自动成立）

```
8寸平板  ↔  10寸平板（互相"更大/更小屏选项"）
PDA      →  8寸平板（同平台、扫码更专）
6个产品页 →  /contact/（CTA）
首页/分类页 → 各产品页（部署分类页时记得挂链接）
```

## 部署时的两件待确认事项

1. **8寸机型防护等级**：老站规格表未标注 IP 等级（宣传物料写 IP65/IP67）。
   产品页里我写的是 "IP65 sealed (IP67 optional)" —— **请跟工厂确认后修正**，B2B 买家会问。
2. **图片**：文案里 `src` 全部用占位路径 `/images/products/xxx.webp`。
   建议压缩到 WebP 300KB 以内再上传（老站 banner 7MB 的教训）。

## 与老站 (xinhong.site) 的关系

- 老站英文版：**冻结保留**，不加新内容，不做 301
- 新站内容：100% 原创重写，避开老站已占的词（warehouse guide / mil-std / IP ratings / TCO）
- 实体关联：两站 Organization schema 的 sameAs 互指
