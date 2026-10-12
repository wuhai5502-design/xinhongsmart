param([string]$repo)
$g="C:\Program Files\Git\cmd\git.exe"
if(-not (Test-Path $g)){ $g="git" }
$sm=[System.IO.File]::ReadAllText("$repo\sitemap.xml")
$blocks=[regex]::Matches($sm,'(?s)\s*<url>\s*<loc>(.*?)</loc>\s*<lastmod>(.*?)</lastmod>(.*?)</url>')
$sb=New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
$changed=0
foreach($b in $blocks){
  $loc=$b.Groups[1].Value
  $old=$b.Groups[2].Value
  $rest=$b.Groups[3].Value
  $rel=$loc -replace 'https://xinhongsmart\.com/',''
  if($rel -eq '' -or $rel -eq 'https://xinhongsmart.com'){ $rel='index.html' } else { $rel=$rel.TrimEnd('/') + '/index.html' }
  $fp=Join-Path $repo ($rel -replace '/','\')
  $d=$old
  if(Test-Path $fp){
    $gd=(& $g -C $repo log -1 --format=%ad --date=short -- $rel 2>$null | Out-String).Trim()
    if($gd -match '^\d{4}-\d{2}-\d{2}$'){ $d=$gd }
  }
  if($d -ne $old){ $changed++ }
  [void]$sb.AppendLine('  <url>')
  [void]$sb.AppendLine('    <loc>' + $loc + '</loc>')
  [void]$sb.AppendLine('    <lastmod>' + $d + '</lastmod>')
  $lines = ($rest -split "`n") | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
  foreach($l in $lines){ [void]$sb.AppendLine('    ' + $l) }
  [void]$sb.AppendLine('  </url>')
}
[void]$sb.AppendLine('</urlset>')
[System.IO.File]::WriteAllText("$repo\sitemap.xml",$sb.ToString(),(New-Object System.Text.UTF8Encoding($false)))
Write-Output ("urls = " + $blocks.Count + "   lastmod changed = " + $changed)
$new=[System.IO.File]::ReadAllText("$repo\sitemap.xml")
$vals=([regex]::Matches($new,'<lastmod>(.*?)</lastmod>') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
Write-Output ("lastmod values now = " + ($vals -join ', '))
