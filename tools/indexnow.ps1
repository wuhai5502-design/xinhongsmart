<#
.SYNOPSIS
  IndexNow 主动推送 —— 把网址提交给 Bing / Yandex / Seznam / Naver / Yep / ChatGPT-search
.DESCRIPTION
  读取站点 sitemap.xml 生成网址清单，向 IndexNow 端点 POST 提交。
  走 curl.exe 通道（本机 .NET 出不了网，Invoke-WebRequest 会连不上）。
.EXAMPLE
  .\indexnow.ps1                 # 推送 sitemap 全部网址
  .\indexnow.ps1 -LastDays 7     # 只推送最近 7 天有更新记录的页面
  .\indexnow.ps1 -Urls https://xinhongsmart.com/oem-odm/   # 只推送指定网址
  .\indexnow.ps1 -DryRun         # 只列出将要推送的清单，不实际提交
#>
param(
    [int]$LastDays = 0,
    [string[]]$Urls = @(),
    [string]$Sitemap = 'sitemap.xml',
    [string]$SiteHost = 'xinhongsmart.com',
    [string]$Key = 'dd877ae5ec2cef3b826b8ecda430de56',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$root        = Split-Path -Parent $PSScriptRoot
$sitemapPath = Join-Path $root $Sitemap
$keyLocation = "https://$SiteHost/$Key.txt"
$endpoint    = 'https://api.indexnow.org/indexnow'

if (-not (Test-Path $sitemapPath)) {
    Write-Host "[错误] 找不到 sitemap: $sitemapPath" -ForegroundColor Red
    exit 1
}

# ---------- 1. 收集待推送网址 ----------
if ($Urls.Count -gt 0) {
    $list = @($Urls)
} else {
    $xml    = [IO.File]::ReadAllText($sitemapPath)
    $cutoff = (Get-Date).Date.AddDays(-$LastDays)
    $list   = @()
    foreach ($m in [regex]::Matches($xml, '(?s)<url>(.*?)</url>')) {
        $block = $m.Groups[1].Value
        $loc   = [regex]::Match($block, '<loc>\s*([^<]+?)\s*</loc>').Groups[1].Value
        if (-not $loc) { continue }

        if ($LastDays -gt 0) {
            $lmText = [regex]::Match($block, '<lastmod>\s*([^<]+?)\s*</lastmod>').Groups[1].Value
            $lm     = [datetime]::MinValue
            if (-not [datetime]::TryParse($lmText, [ref]$lm)) { continue }
            if ($lm -lt $cutoff) { continue }
        }
        $list += $loc
    }
}

# 只保留属于本站的 https 网址，并去重
$esc  = [regex]::Escape($SiteHost)
$list = @($list | Where-Object { $_ -match "^https://$esc/" } | Sort-Object -Unique)

if ($list.Count -eq 0) {
    Write-Host '[提示] 没有符合推送条件的网址。' -ForegroundColor Yellow
    exit 0
}

Write-Host ("待推送网址 " + $list.Count + " 条：") -ForegroundColor Cyan
$list | ForEach-Object { Write-Host ('  ' + $_) }

if ($DryRun) {
    Write-Host ''
    Write-Host '[DryRun] 未实际提交。' -ForegroundColor Yellow
    exit 0
}

# ---------- 2. 分批提交（IndexNow 单批上限 10000 条）----------
$tmp = Join-Path $env:TEMP ('indexnow-body-' + [guid]::NewGuid().ToString('N') + '.json')
$ok   = 0
$fail = 0

try {
    for ($i = 0; $i -lt $list.Count; $i += 10000) {
        $end   = [Math]::Min($i + 9999, $list.Count - 1)
        $batch = @($list[$i..$end])

        $payload = [ordered]@{
            host        = $SiteHost
            key         = $Key
            keyLocation = $keyLocation
            urlList     = @($batch)
        }
        # UTF-8 无 BOM 写入，避免 curl 读到 BOM 导致 JSON 解析失败
        [IO.File]::WriteAllText($tmp, ($payload | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))

        Write-Host ''
        Write-Host ("向 IndexNow 提交 " + $batch.Count + " 条 ...") -ForegroundColor Cyan

        $code = curl.exe -s -m 60 -o NUL -w '%{http_code}' `
            -X POST $endpoint `
            -H 'Content-Type: application/json; charset=utf-8' `
            --data-binary "@$tmp"

        if ($code -eq '200' -or $code -eq '202') {
            Write-Host ('  成功 -> HTTP ' + $code) -ForegroundColor Green
            $ok += $batch.Count
        } else {
            Write-Host ('  失败 -> HTTP ' + $code) -ForegroundColor Red
            $fail += $batch.Count
        }
    }
} finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host '===== 推送完成 =====' -ForegroundColor Cyan
Write-Host ('  成功: ' + $ok + ' 条    失败: ' + $fail + ' 条')
if ($ok -gt 0) {
    Write-Host '  说明：IndexNow 受理后通常数小时内被 Bing / Yandex / ChatGPT-search 抓取。'
}
