$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$model = Get-Content -Raw (Join-Path $root 'lib/model.dart')
$ids = [regex]::Matches($model, 'Ability\((\d+),') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$destination = Join-Path $root 'assets/spells'
New-Item -ItemType Directory -Force $destination | Out-Null
$manifest = @()
foreach ($id in $ids) {
    $pageUrl = "https://legion-shoot.tauri.hu/?spell=$id"
    $html = (Invoke-WebRequest $pageUrl).Content
    $pattern = '_\[' + $id + '\]\s*=\s*\{icon:''([^'']+)'''
    $match = [regex]::Match($html, $pattern)
    if (-not $match.Success) { throw "Icon not found for spell $id" }
    $icon = $match.Groups[1].Value
    $url = "https://legion-static.tauri.hu/images/icons/large/$icon.png"
    $file = Join-Path $destination "$id.png"
    Invoke-WebRequest $url -OutFile $file
    $bytes = [IO.File]::ReadAllBytes($file)
    if ($bytes.Length -lt 8 -or [BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A') { throw "Invalid PNG: $id" }
    $manifest += [ordered]@{spellId=[int]$id; icon=$icon; source=$pageUrl; image=$url; sha256=(Get-FileHash $file -Algorithm SHA256).Hash}
}
$manifestPath = Join-Path $destination 'sources.json'
if (Test-Path -LiteralPath $manifestPath) {
    $old = Get-Content -Raw $manifestPath | ConvertFrom-Json
    $newIds = @($manifest | ForEach-Object { $_.spellId })
    $manifest += @($old | Where-Object { $_.spellId -notin $newIds })
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 $manifestPath
Write-Output "Downloaded $($manifest.Count) spell icons."
