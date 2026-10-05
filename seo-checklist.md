# xinhongsmart.com 上线技术清单（按顺序执行）

> 建议每完成一项打勾。前三项在部署页面时同步做，其余在站点可访问后进行。

## A. 部署页面时（做对一次，省去返工）

- [ ] 6 个产品页 HTML 部署到对应 URL（见 README 表格），URL 一律**小写 + 连字符 + 结尾斜杠**
- [ ] 每页填入文件头部注释里的 `<title>` / `<meta description>` / `<canonical>`
- [ ] **唯一 H1**：每页只有一个 `<h1>`（就是产品名）
- [ ] JSON-LD 两段脚本放 `</head>` 前（Product + FAQPage；高拍仪页只有 Product）
- [ ] `schema-organization.html` 里的两段脚本放进**全站公共模板**（每页都输出）
- [ ] `robots.txt` 放站点根目录；`sitemap-template.xml` 改名 `sitemap.xml` 并更新 lastmod
- [ ] 图片：上传前压成 **WebP，单图 < 300KB**（可用 squoosh.app 免费压缩）；`alt` 已写好，别删
- [ ] 首页/分类页向 6 个产品页挂链接（产品页文案里的互链已写好，不用再改）
- [ ] `/contact/` 页必须有：表单 + 邮箱 + 电话（+86-185-9427-9341）+ WhatsApp（如有）—— **询盘转化全靠它**
- [ ] HTTPS 强制跳转（http → 301 → https）

## B. 站点可访问后（第 1 天就做）

- [ ] 浏览器访问 `https://xinhongsmart.com/robots.txt` 和 `/sitemap.xml` 确认 200
- [ ] 手机打开首页检查布局（Google 是移动优先索引）
- [ ] 用 PageSpeed Insights（pagespeed.web.dev）跑一次首页 —— 移动端 ≥ 70 分即可接受，图片压缩是最大杠杆

## C. Google Search Console（第 1 天）

- [ ] GSC 添加资源（建议用「网址前缀」方式，DNS 或 HTML 文件验证均可）
- [ ] 提交 `sitemap.xml`
- [ ] 对 6 个产品页逐个用「网址检查 → 请求编入索引」
- [ ] 一周后回来看「网页索引编制」报告

## D. IndexNow / 其他引擎（第 1 天，可选但推荐）

- [ ] 生成 IndexNow 密钥文件放根目录（Bing / Yandex / Seznam 共用协议）
- [ ] 提交 6 个产品 URL 到 `api.indexnow.org`（老站 `daily_push.py` 里的函数可复用，换域名即可）

## E. 持续运营（每周）

- [ ] 每周 1~2 篇博客（选题方向见 README「与老站的分工」，避开老站已占的词）
- [ ] 每篇发布后 GSC「请求编入索引」
- [ ] 每月看一次 GSC「效果」报告：曝光 > 0 的词就是 Google 给的正反馈
- [ ] **第 3 个月内不要因为没流量改版** —— 新域名沙盒期 2~3 个月是正常的

## 待确认事项（影响文案准确性，尽快回我）

1. **8寸机型的 IP 等级**：目前文案写 "IP65 standard / IP67 optional" —— 请跟工厂确认
2. ~~**公司成立年份**：schema 里写了 2016，请确认（影响 Organization 数据）~~ ✅ 已确认 2016（2026-10-05 用户确认），About 页正文 + Organization.foundingDate + llms.txt 三处均已写入
3. **WhatsApp / 领英**：海外 B2B 站强烈建议挂 WhatsApp 按钮；有领英公司页的话加进 schema 的 sameAs
