<#
.SYNOPSIS
  Article image polish for /insights/* posts.
  1) Insert "image":["<og:image absolute url>"] into the Article JSON-LD block when missing.
  2) Make the first <img> of each post eager + fetchpriority="high" (LCP), keep the rest lazy.
.EXAMPLE
  .\fix-article-images.ps1 -repo "C:\path\to\site"
#>
param([string]$repo)

$root   = Join-Path $repo 'insights'
$listPg = Join-Path $root 'index.html'
$files  = Get-ChildItem -Path $root -Recurse -Filter index.html | Where-Object { $_.FullName -ne $listPg }

$imgAdded = 0
$fpAdded  = 0
$changed  = 0

foreach ($f in $files) {
    $orig = [System.IO.File]::ReadAllText($f.FullName)
    $t    = $orig

    $og = [regex]::Match($t, '(?i)<meta property="og:image" content="([^"]+)"').Groups[1].Value

    if ($og.Length -gt 0 -and -not [regex]::IsMatch($t, '(?i)"image"\s*:\s*\[')) {
        $needle = '"@type":"Article"'
        $i = $t.IndexOf($needle)
        if ($i -ge 0) {
            $t = $t.Substring(0, $i) + $needle + ',"image":["' + $og + '"]' + $t.Substring($i + $needle.Length)
            $imgAdded++
        }
    }

    $m = [regex]::Match($t, '(?is)<img[^>]*>')
    if ($m.Success) {
        $tag = $m.Value
        $new = $tag
        if ($new -match '(?i)loading\s*=\s*"lazy"') {
            $new = [regex]::Replace($new, '(?i)loading\s*=\s*"lazy"', 'loading="eager"')
        } elseif ($new -notmatch '(?i)loading\s*=') {
            $new = '<img loading="eager"' + $new.Substring(4)
        }
        if ($new -notmatch '(?i)fetchpriority') {
            $new = '<img fetchpriority="high"' + $new.Substring(4)
        }
        if ($new -ne $tag) {
            $t = $t.Replace($tag, $new)
            $fpAdded++
        }
    }

    if ($t -ne $orig) {
        [System.IO.File]::WriteAllText($f.FullName, $t, (New-Object System.Text.UTF8Encoding($false)))
        $changed++
    }
}

Write-Output ("articles scanned = " + $files.Count + " ; files changed = " + $changed + " ; jsonld image inserted = " + $imgAdded + " ; first img made eager = " + $fpAdded)
