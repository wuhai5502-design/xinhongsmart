<#
.SYNOPSIS
  Build one specification PDF per product from the live product pages.
  Extracts H1, meta description, main image and every spec table (grouped by the
  H2 section that precedes it), renders an A4 HTML and prints it with headless Edge.
.EXAMPLE
  .\build-product-spec-pdfs.ps1 -repo "C:\site" -outDir "C:\Users\me\Desktop\Xinhong-Product-Specs"
#>
param(
    [string]$repo,
    [string]$outDir,
    [string]$only
)

# A single Word instance dies after the first PDF export on this machine,
# so a fresh instance is started per product and quit straight after.

Add-Type -AssemblyName System.Drawing

$tmp = Join-Path $env:TEMP 'specpdf'
if (-not (Test-Path $tmp)) { New-Item -ItemType Directory -Path $tmp | Out-Null }
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

function Decode([string]$s) {
    $s = [regex]::Replace($s, '<[^>]+>', '')
    return [System.Net.WebUtility]::HtmlDecode($s).Trim()
}

# ---------- company block from contact page ----------
$ct   = [System.IO.File]::ReadAllText((Join-Path $repo 'contact\index.html'))
$orgM = [regex]::Match($ct, '"name"\s*:\s*"(Shenzhen [^"]+)"')
$org  = if ($orgM.Success) { $orgM.Groups[1].Value } else { 'Xinhong Smart' }
$zhM  = [regex]::Match($ct, '"legalName"\s*:\s*"([^"]+)"')
$zh   = if ($zhM.Success) { $zhM.Groups[1].Value } else { '' }
$emM  = [regex]::Match($ct, '"email"\s*:\s*"(sales[^"]+)"')
$em   = if ($emM.Success) { $emM.Groups[1].Value } else { 'sales@xinhongsmart.com' }
$telM = [regex]::Match($ct, '"telephone"\s*:\s*"([^"]+)"')
$tel  = if ($telM.Success) { $telM.Groups[1].Value } else { '' }
$adM  = [regex]::Match($ct, '"streetAddress"\s*:\s*"([^"]+)"')
$addr = if ($adM.Success) { $adM.Groups[1].Value + ', Shenzhen, Guangdong, China' } else { 'Shenzhen, Guangdong, China' }

Write-Output ("company = " + $org + " / " + $zh)
Write-Output ("contact = " + $em + "  " + $tel)

# ---------- product pages ----------
$products = @(
    'products\rugged-tablets\xh-500\index.html',
    'products\rugged-tablets\xh-300\index.html',
    'products\rugged-tablets\8-inch-rugged-tablet\index.html',
    'products\rugged-tablets\10-inch-rugged-tablet\index.html',
    'products\handheld-pdas\xh-200\index.html',
    'products\handheld-pdas\5-inch-handheld-pda\index.html',
    'products\biometric-devices\xh-100\index.html',
    'products\biometric-devices\xh-400\index.html',
    'products\biometric-devices\dual-screen-id-verification-terminal\index.html',
    'products\document-devices\document-camera-scanner\index.html',
    'products\document-devices\signature-pad\index.html'
)

$css = @'
@page { size: A4; margin: 15mm 14mm; }
* { box-sizing: border-box; }
body { font-family: "Segoe UI", "Helvetica Neue", Arial, sans-serif; color:#142346; font-size:10.5pt; line-height:1.45; margin:0; }
.brand { border-bottom:2px solid #1f5eff; padding-bottom:6px; margin-bottom:14px; }
.brand b { font-size:12pt; letter-spacing:.2px; }
.brand span { float:right; color:#5e6d84; font-size:9pt; }
h1 { font-size:19pt; margin:0 0 6px; line-height:1.2; letter-spacing:-.2px; }
.summary { color:#4c5d78; font-size:10pt; margin:0 0 14px; }
.hero { display:block; margin:0 auto 14px; border:1px solid #e6eaf0; border-radius:6px; background:#f7f9fc; padding:6px; page-break-inside:avoid; page-break-before:avoid; page-break-after:avoid; }
.break { page-break-before: always; }
h2 { font-size:12pt; margin:16px 0 6px; padding-bottom:4px; border-bottom:1px solid #dfe5ee; color:#0f2f6b; }
table { width:100%; border-collapse:collapse; font-size:9.6pt; margin-bottom:10px; }
th { width:34%; text-align:left; font-weight:600; vertical-align:top; padding:5px 8px; border-bottom:1px solid #e6eaf0; color:#42506b; background:#f7f9fc; }
td { padding:5px 8px; border-bottom:1px solid #e6eaf0; }
.foot { margin-top:18px; border-top:2px solid #1f5eff; padding-top:8px; font-size:8.6pt; color:#5e6d84; }
.foot b { color:#142346; }
.commercial { margin-top:10px; font-size:9pt; color:#42506b; }
'@

$made = 0
foreach ($rel in $products) {
    $slug = (Split-Path (Split-Path $rel -Parent) -Leaf)
    if ($only -and $slug -ne $only) { continue }

    $fp = Join-Path $repo $rel
    if (-not (Test-Path $fp)) { Write-Output ("skip missing " + $rel); continue }

    $t    = [System.IO.File]::ReadAllText($fp)
    $h1   = Decode([regex]::Match($t, '(?is)<h1[^>]*>(.*?)</h1>').Groups[1].Value)
    $desc = [regex]::Match($t, '(?i)<meta name="description" content="([^"]*)"').Groups[1].Value
    $desc = [System.Net.WebUtility]::HtmlDecode($desc)
    $slug = (Split-Path (Split-Path $rel -Parent) -Leaf)
    $url  = 'https://xinhongsmart.com/' + (($rel -replace '\\', '/') -replace '/index.html$', '') + '/'

    # main image -> local file url
    $imgTag = ''
    foreach ($m in [regex]::Matches($t, '(?is)<img[^>]*>')) {
        $s = [regex]::Match($m.Value, '(?i)src\s*=\s*"([^"]+)"').Groups[1].Value
        if ($s -match 'uploads/') { $imgTag = $m.Value; $imgSrc = $s; break }
    }
    $imgHtml = ''
    if ($imgTag -ne '') {
        $clean = $imgSrc.Split('?')[0]
        $rel2  = $clean -replace '^https://xinhongsmart\.com/', ''
        $rel2  = ($rel2 -replace '^\.\./', '') -replace '^\.\./', ''
        $rel2  = $rel2.TrimStart('/')
        $abs   = Join-Path $repo ($rel2 -replace '/', '\')
        if (Test-Path $abs) {
            # Word ignores max-height/object-fit, so the width is derived from the
            # real aspect ratio to keep the picture inside page one
            $im = [System.Drawing.Image]::FromFile($abs)
            $ratio = $im.Width / $im.Height
            $im.Dispose()
            # 75 mm tall at 96 dpi = 283 px ; content width 178 mm = 673 px
            $wpx = 283 * $ratio
            if ($wpx -gt 673) { $wpx = 673 }
            if ($wpx -lt 150) { $wpx = 150 }
            $imgHtml = '<img class="hero" width="' + [int]$wpx + '" style="width:' + [int]$wpx + 'px" src="file:///' + ($abs -replace '\\', '/') + '" alt="">'
        }
    }

    # pair each table with the nearest preceding h2
    $h2s = @([regex]::Matches($t, '(?is)<h2[^>]*>(.*?)</h2>') | ForEach-Object {
        [pscustomobject]@{ Pos = $_.Index; Text = Decode($_.Groups[1].Value) }
    })
    $tbls = @([regex]::Matches($t, '(?is)<table.*?</table>') | ForEach-Object {
        [pscustomobject]@{ Pos = $_.Index; Html = $_.Value }
    })

    $body = ''
    $firstDone = $false
    foreach ($tb in $tbls) {
        $sec = ''
        foreach ($h in $h2s) { if ($h.Pos -lt $tb.Pos) { $sec = $h.Text } }
        $rows = ''
        foreach ($r in [regex]::Matches($tb.Html, '(?is)<tr[^>]*>(.*?)</tr>')) {
            # some pages use th/td, others use td/td for the label+value pair
            $cells = [regex]::Matches($r.Groups[1].Value, '(?is)<t[dh][^>]*>(.*?)</t[dh]>')
            if ($cells.Count -lt 2) { continue }
            $k = Decode($cells[0].Groups[1].Value)
            $v = Decode($cells[1].Groups[1].Value)
            if ($k -eq '') { continue }
            $rows += '<tr><th>' + $k + '</th><td>' + $v + '</td></tr>'
        }
        if ($rows -eq '') { continue }
        if (-not $firstDone) { $pb = ' style="page-break-before:always"'; $firstDone = $true } else { $pb = '' }
        if ($sec -ne '') { $body += '<h2' + $pb + '>' + $sec + '</h2>' } else { $body += '<div' + $pb + '></div>' }
        $body += '<table>' + $rows + '</table>'
    }

    # keep page one short so the photo always fits above the fold
    if ($desc.Length -gt 220) { $desc = $desc.Substring(0, 217).TrimEnd() + '...' }

    $pretty = ($slug -split '-' | ForEach-Object { if ($_.Length -gt 0) { $_.Substring(0,1).ToUpper() + $_.Substring(1) } }) -join '-'
    if ($slug -match '^xh-\d+$') { $pretty = $slug.ToUpper() }

    $html = '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>' + $h1 + '</title><style>' + $css + '</style></head><body>' +
        '<div class="brand"><b>' + $org + '</b><span>' + $url + '</span></div>' +
        '<h1>' + $h1 + '</h1>' +
        '<p class="summary">' + $desc + '</p>' +
        $imgHtml +
        '<div class="commercial">Sample lead time about 3 days for a standard configuration; mass production about 25 days after sample approval. Minimum order quantity 2 units. OEM and ODM supported.</div>' +
        '<div class="foot"><b>' + $org + '</b>' + $(if ($zh -ne '') { ' / ' + $zh } else { '' }) + '<br>' +
        $addr + '<br>Tel / WhatsApp: ' + $tel + ' &nbsp;|&nbsp; Email: ' + $em + ' &nbsp;|&nbsp; ' + $url +
        '<br>Hours: Monday to Saturday, 09:00-18:30 (GMT+8)</div>' +
        '<p style="page-break-before:always"></p>' +
        $body +
        '</body></html>'

    $htmlPath = Join-Path $tmp ($slug + '.html')
    [System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding($false)))

    $pdfName = $pretty + '-Specification.pdf'
    $pdfPath = Join-Path $outDir $pdfName
    Remove-Item $pdfPath -Force -ErrorAction SilentlyContinue

    # Word instances that have not fully exited corrupt the next export,
    # so wait between runs and retry once if nothing was written
    $tries = 0
    while ($tries -lt 2 -and -not (Test-Path $pdfPath)) {
        $tries++
        $word = $null
        try {
            $word = New-Object -ComObject KWPS.Application -ErrorAction Stop
            $word.Visible = $false
            $word.DisplayAlerts = 0
            $doc = $word.Documents.Open($htmlPath, $false, $true)
            $doc.ExportAsFixedFormat($pdfPath, 17)
            $doc.Close(0)
            $word.Quit()
        } catch {
            if ($tries -eq 1) { Write-Output ("  export attempt 1 failed, retrying: " + $_.Exception.Message) }
            if ($word -ne $null) { try { $word.Quit() } catch { } }
        }
        Start-Sleep -Milliseconds 1200
    }

    if (Test-Path $pdfPath) {
        $kb = [int]((Get-Item $pdfPath).Length / 1KB)
        Write-Output ("OK   " + $pdfName + "  (" + $kb + " KB, spec rows: " + ([regex]::Matches($body,'<tr>')).Count + ")")
        $made++
    } else {
        Write-Output ("FAIL " + $pdfName)
    }
}

Write-Output ("PDFs written = " + $made + "  ->  " + $outDir)
