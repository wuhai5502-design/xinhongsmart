<#
.SYNOPSIS
  Bing Webmaster Tools 网址提交 —— 把网址主动投进 Bing 抓取队列
.DESCRIPTION
  读取站点 sitemap.xml 生成网址清单，调用 Bing Webmaster Tools 的 SubmitUrlbatch 接口提交。
  与 indexnow.ps1 的区别：IndexNow 是"通知"，本接口是"投递"，配额按站点给、更可控。
  走 curl.exe 通道（本机 .NET 出不了网，Invoke-WebRequest 会连不上）。

  密钥不入库，按以下顺序取值：
    1. -ApiKey 参数
    2. 环境变量 $env:BING_API_KEY
    3. 本机文件 $env:USERPROFILE\.bing_wmt_apikey.txt

.EXAMPLE
  .\bing-submit.ps1                # 提交 sitemap 全部网址
  .\bing-submit.ps1 -LastDays 3    # 只提交最近 3 天有更新的页面
  .\bing-submit.ps1 -Quota         # 查询当天剩余配额
  .\bing-submit.ps1 -DryRun        # 只列出将要提交的清单，不实际提交
#>
param(
    [int]$LastDays = 0,
    [string[]]$Urls = @(),
    [string]$Sitemap = 'sitemap.xml',
    [string]$SiteUrl = 'https://xinhongsmart.com/',
    [int]$BatchSize = 500,
    [string]$ApiKey = '',
    [switch]$Quota,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$root        = Split-Path -Parent $PSScriptRoot
$sitemapPath = Join-Path $root $Sitemap
$apiBase     = 'https://ssl.bing.com/webmaster/api.svc/json'

# ---------- 0. 解析 API 密钥 ----------
if (-not $ApiKey) {
    if ($env:BING_API_KEY) {
        $ApiKey = $env:BING_API_KEY
    } else {
        $keyFile = Join-Path $env:USERPROFILE '.bing_wmt_apikey.txt'
        if (Test-Path $keyFile) {
            $ApiKey = (Get-Content $keyFile -Raw).Trim()
        }
    }
}
if (-not $ApiKey) {
    Write-Host '[错误] 找不到 Bing API 密钥。请用 -ApiKey 传入，或设置环境变量 $env:BING_API_KEY。' -ForegroundColor Red
    exit 1
}

# ---------- 1. 查询配额 ----------
if ($Quota) {
    $qUrl  = "$apiBase/GetUrlSubmissionQuota?apikey=$([Uri]::EscapeDataString($ApiKey))&siteUrl=$([Uri]::EscapeDataString($SiteUrl))"
    $qBody = curl.exe -s -m 60 $qUrl
    Write-Host '= 当前配额 =' -ForegroundColor Cyan
    Write-Host ('  siteUrl: ' + $SiteUrl)
    Write-Host ('  response: ' + $qBody)
    exit 0
}

if (-not (Test-Path $sitemapPath)) {
    Write-Host "[错误] 找不到 sitemap: $sitemapPath" -ForegroundColor Red
    exit 1
}

# ---------- 2. 收集待提交网址 ----------
if ($Urls.Count -gt 0) {
    $list = @($Urls | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
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

# 只保留属于本站点前缀下的网址，并去重
$esc  = [regex]::Escape(($SiteUrl -replace '/$', ''))
$list = @($list | Where-Object { $_ -match "^$esc/" -or $_ -eq ($SiteUrl -replace '/$', '') } | Sort-Object -Unique)

if ($list.Count -eq 0) {
    Write-Host '[提示] 没有符合提交条件的网址。' -ForegroundColor Yellow
    exit 0
}

Write-Host ("待提交网址 " + $list.Count + " 条：") -ForegroundColor Cyan
$list | ForEach-Object { Write-Host ('  ' + $_) }

if ($DryRun) {
    Write-Host ''
    Write-Host '[DryRun] 未实际提交。' -ForegroundColor Yellow
    exit 0
}

# ---------- 3. 分批提交 ----------
$tmp  = Join-Path $env:TEMP ('bing-body-' + [guid]::NewGuid().ToString('N') + '.json')
$endpoint = "$apiBase/SubmitUrlbatch?apikey=$([Uri]::EscapeDataString($ApiKey))"
$ok   = 0
$fail = 0

try {
    for ($i = 0; $i -lt $list.Count; $i += $BatchSize) {
        $end   = [Math]::Min($i + $BatchSize - 1, $list.Count - 1)
        $batch = @($list[$i..$end])

        $payload = [ordered]@{
            siteUrl = $SiteUrl
            urlList = @($batch)
        }
        # UTF-8 无 BOM 写入，避免 curl 读到 BOM 导致 JSON 解析失败
        [IO.File]::WriteAllText($tmp, ($payload | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))

        Write-Host ''
        Write-Host ("向 Bing 提交 " + $batch.Count + " 条 ...") -ForegroundColor Cyan

        $out  = Join-Path $env:TEMP ('bing-resp-' + [guid]::NewGuid().ToString('N') + '.txt')
        $code = curl.exe -s -m 90 -o $out -w '%{http_code}' `
            -X POST $endpoint `
            -H 'Content-Type: application/json; charset=utf-8' `
            --data-binary "@$tmp"

        $body = ''
        if (Test-Path $out) { $body = ((Get-Content $out -Raw) -replace '\s+', ' ').Trim(); Remove-Item $out -Force -ErrorAction SilentlyContinue }

        if ($code -eq '200' -and ($body -eq '{"d":null}' -or $body -eq '{ "d": null }' -or $body -match '"d":\s*null')) {
            Write-Host ('  成功 -> HTTP ' + $code + '  ' + $body) -ForegroundColor Green
            $ok += $batch.Count
        } else {
            Write-Host ('  失败 -> HTTP ' + $code + '  ' + $body) -ForegroundColor Red
            $fail += $batch.Count
        }
    }
} finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host '===== 提交完成 =====' -ForegroundColor Cyan
Write-Host ('  成功: ' + $ok + ' 条    失败: ' + $fail + ' 条')
if ($ok -gt 0) {
    Write-Host '  说明：Bing 受理后进入抓取队列，通常数天内完成；Copilot 与依赖 Bing 索引的检索随之受益。'
}
