<#
.SYNOPSIS
  Generate responsive JPEG derivatives (800w / 1200w / 1600w) for the heavy blog and
  product images, then add srcset + sizes to every <img> that references them.
  Uses only .NET System.Drawing, no external tools required.
.EXAMPLE
  .\make-responsive-images.ps1 -repo "C:\path\to\site"
#>
param(
    [string]$repo,
    [int]$Quality = 82
)

Add-Type -AssemblyName System.Drawing

$uploads = Join-Path $repo 'uploads'
$targets = @(
    'blog\manufacturing-line.jpg',
    'blog\field-products.jpg',
    'blog\quality-lab.jpg',
    '8-inch-rugged-tablet.jpg',
    'xh-400.jpg',
    'xh-500.jpg'
)
$widths  = @(800, 1200, 1600)
$origMap = @{}

# ---------- 1. generate derivatives ----------
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$made = 0
$widthMap = @{}

foreach ($t in $targets) {
    $src = Join-Path $uploads $t
    if (-not (Test-Path $src)) { Write-Output ("skip missing: " + $t); continue }

    $im = [System.Drawing.Image]::FromFile($src)
    $w = $im.Width
    $h = $im.Height
    $variants = @()

    foreach ($tw in $widths) {
        if ($tw -ge $w) { continue }
        $th = [int][Math]::Round($tw * $h / $w)
        $bmp = New-Object System.Drawing.Bitmap($tw, $th)
        $g   = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($im, 0, 0, $tw, $th)
        $g.Dispose()

        $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
        $dest = [regex]::Replace($src, '\.jpg$', '-' + $tw + '.jpg')
        $bmp.Save($dest, $codec, $ep)
        $bmp.Dispose()
        $made++
        $variants += $tw
        Write-Output ("made " + (Split-Path $dest -Leaf) + "  " + $tw + "x" + $th + "  " + [int]((Get-Item $dest).Length / 1KB) + " KB")
    }

    $variants += $w
    $im.Dispose()
    $leaf = Split-Path $t -Leaf
    $widthMap[$leaf] = ($variants | Sort-Object)
    $origMap[$leaf]  = $w
    Write-Output ("source " + $leaf + " " + $w + "x" + $h + " " + [int]((Get-Item $src).Length / 1KB) + " KB -> widths " + (($widthMap[$leaf]) -join ','))
}

Write-Output ("derivatives generated = " + $made)

# ---------- 2. add srcset + sizes to html ----------
$htmlFiles = Get-ChildItem -Path $repo -Recurse -Filter *.html
$imgTouched = 0
$filesTouched = 0

foreach ($f in $htmlFiles) {
    $orig = [System.IO.File]::ReadAllText($f.FullName)
    $t    = $orig

    $tags = [regex]::Matches($t, '(?is)<img[^>]*>')
    foreach ($m in $tags) {
        $tag = $m.Value
        if ($tag -match '(?i)srcset') { continue }

        $sm = [regex]::Match($tag, '(?i)src\s*=\s*"([^"]+)"')
        if (-not $sm.Success) { continue }
        $src  = $sm.Groups[1].Value
        $leaf = [System.IO.Path]::GetFileName($src)
        if (-not $widthMap.ContainsKey($leaf)) { continue }
        if ($src -notmatch '\.jpg$') { continue }

        $base = $src.Substring(0, $src.Length - 4)
        $set  = @()
        foreach ($vw in $widthMap[$leaf]) {
            if ($vw -eq $origMap[$leaf]) {
                $set += ($src + ' ' + $vw + 'w')
            } else {
                $set += ($base + '-' + $vw + '.jpg ' + $vw + 'w')
            }
        }

        $mw = [regex]::Match($tag, '(?i)max-width:\s*(\d+)px')
        if ($mw.Success) {
            $px = [int]$mw.Groups[1].Value
            if ($px -lt 200) { $px = 200 }
            $sizes = '(max-width: ' + $px + 'px) 100vw, ' + $px + 'px'
        } else {
            $sizes = '(max-width: 820px) 100vw, 820px'
        }

        $new = '<img srcset="' + ($set -join ', ') + '" sizes="' + $sizes + '"' + $tag.Substring(4)
        $t = $t.Replace($tag, $new)
        $imgTouched++
    }

    if ($t -ne $orig) {
        [System.IO.File]::WriteAllText($f.FullName, $t, (New-Object System.Text.UTF8Encoding($false)))
        $filesTouched++
    }
}

Write-Output ("html files touched = " + $filesTouched + " ; img tags upgraded = " + $imgTouched)
