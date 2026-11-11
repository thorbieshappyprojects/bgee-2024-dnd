<#
.SYNOPSIS
  Copies the mod into the working game copies and runs the WeiDU installer.

.EXAMPLE
  .\deploy.ps1                      # both games, components 1 and 2
  .\deploy.ps1 -Game BG2EE
  .\deploy.ps1 -Reset               # restore working copies from the -clean folders first
  .\deploy.ps1 -Components 1
  .\deploy.ps1 -NoCheck             # skip the data checks after installing
#>
param(
    [ValidateSet('BGEE', 'BG2EE', 'All')]
    [string]$Game = 'All',
    [int[]]$Components = @(1, 2, 3, 4, 5),
    [switch]$Reset,
    [switch]$NoCheck,
    [string]$WeiduExe
)

$ErrorActionPreference = 'Stop'

$ModRoot = $PSScriptRoot
$ModName = 'bg2024'
$GameRoot = 'C:\BG'
# Only these paths are part of the mod; docs, tools and Git metadata stay out of the game folder.
$ModItems = @('bg2024.tp2', 'README.md', 'lib', 'lua', 'tables', 'spells', 'kits', 'npc', 'tra', 'icons', 'portraits')

function Find-Weidu {
    if ($WeiduExe) { return (Resolve-Path $WeiduExe).Path }
    if ($env:WEIDU_EXE) { return (Resolve-Path $env:WEIDU_EXE).Path }
    foreach ($rel in 'tools\weidu.exe', 'tools\weidu\weidu.exe') {
        $local = Join-Path $ModRoot $rel
        if (Test-Path $local) { return $local }
    }
    $cmd = Get-Command weidu.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "weidu.exe not found. Put it in tools\weidu\, set WEIDU_EXE, or pass -WeiduExe."
}

function Reset-GameCopy([string]$name) {
    $clean = Join-Path $GameRoot "$name-clean"
    $work = Join-Path $GameRoot $name
    if (-not (Test-Path (Join-Path $clean 'chitin.key'))) { throw "Clean copy not found: $clean" }
    Write-Host "Resetting $work from $clean"
    # Mirror clean -> work. The clean folder is only read, never written.
    robocopy $clean $work /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }
}

function Copy-Mod([string]$gameDir) {
    $target = Join-Path $gameDir $ModName
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    New-Item -ItemType Directory $target | Out-Null
    foreach ($item in $ModItems) {
        $src = Join-Path $ModRoot $item
        if (Test-Path $src) { Copy-Item $src -Destination $target -Recurse -Force }
    }
    Get-ChildItem $target -Recurse -Filter .gitkeep | Remove-Item -Force
}

function Install-Mod([string]$gameDir, [string]$weidu) {
    $weiduArgs = @(
        "$ModName/$ModName.tp2",
        '--game', $gameDir,
        '--language', '0',
        '--use-lang', 'en_US',
        '--force-install-list') + ($Components | ForEach-Object { "$_" }) + @(
        '--no-exit-pause',
        '--noautoupdate',
        '--skip-at-view',
        '--log', "setup-$ModName.debug")
    Push-Location $gameDir
    try {
        & $weidu @weiduArgs
        if ($LASTEXITCODE -ne 0) { throw "WeiDU failed in $gameDir with exit code $LASTEXITCODE (see setup-$ModName.debug)" }
    } finally {
        Pop-Location
    }
}

$weidu = Find-Weidu
$games = if ($Game -eq 'All') { @('BGEE', 'BG2EE') } else { @($Game) }

# Structural check of the Lua scripts (block and bracket balance) before installing; needs perl
# (Git for Windows ships one).
$perl = (Get-Command perl -ErrorAction SilentlyContinue).Source
if (-not $perl -and (Test-Path 'C:\Program Files\Git\usr\bin\perl.exe')) { $perl = 'C:\Program Files\Git\usr\bin\perl.exe' }
if ($perl) {
    $scripts = Get-ChildItem (Join-Path $ModRoot 'lua') -Filter *.lua | ForEach-Object { $_.FullName }
    $result = & $perl (Join-Path $ModRoot 'tools\luacheck.pl') @scripts
    if ($LASTEXITCODE -ne 0) { $result | Where-Object { $_ -notmatch ': ok$' } | Write-Host; throw "Lua check failed" }
} else {
    Write-Host "perl not found: Lua check skipped"
}

foreach ($name in $games) {
    $gameDir = Join-Path $GameRoot $name
    if (-not (Test-Path (Join-Path $gameDir 'chitin.key'))) { throw "Game not found: $gameDir" }
    Write-Host "=== $name ==="
    if ($Reset) { Reset-GameCopy $name }
    Copy-Mod $gameDir
    Install-Mod $gameDir $weidu
}

# Offline checks of the installed data against the 2024 rules (tools\datacheck.pl). Only meaningful
# when every component is installed.
if ($perl -and -not $NoCheck -and @(Compare-Object $Components @(1, 2, 3, 4, 5)).Count -eq 0) {
    $gameDirs = @($games | ForEach-Object { Join-Path $GameRoot $_ })
    & $perl (Join-Path $ModRoot 'tools\datacheck.pl') @gameDirs
    if ($LASTEXITCODE -ne 0) { throw "Data checks failed (see above)" }
}
