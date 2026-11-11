<#
.SYNOPSIS
  Automated in-game smoke test: starts the game, loads a save, steps the protagonist through every
  class and level (tools\ingame\B24TEST.lua), and closes the game again.

.DESCRIPTION
  The test files are copied into the game's override folder for the run and removed afterwards.
  Results are the "[B24TEST]" lines of the game log (b24debug.log). The save is never written.
  Refuses to run while the game is already open (someone may be playing).

.EXAMPLE
  .\tools\ingame-test.ps1                    # both games
  .\tools\ingame-test.ps1 -Game BG2EE
  .\tools\ingame-test.ps1 -Save "Chapter 1 Start" -Game BG2EE
#>
param(
    [ValidateSet('BGEE', 'BG2EE', 'All')]
    [string]$Game = 'All',
    [string]$Save,
    # Only these classes (names as in B24TEST.lua, e.g. "Fighter,Barbarian"); all if empty.
    [string]$Classes = '',
    # Character creation: species key of the created character (B24SPEC.lua), e.g. DRAGONBORN.
    [string]$Species = 'HUMAN',
    # Character creation: then level the character up to this level through the record screen.
    [int]$LevelTo = 0,
    # Rules: load a save and step through classes and levels. Chargen: create a new character
    # through the character creation screens (tools\ingame\B24TCG.lua). Icons: load a save, put
    # the protagonist into each state and check its portrait icon, then prone and Escape Grapple.
    # Dying: drop the protagonist and a spawned companion to 0 hit points: death saves, Revivify,
    # Raise Dead, massive damage; at the end the protagonist dies and the game ends.
    # TurnProbe: feasibility of turn-based combat (the engine's Time Stop for one creature).
    # TurnCombat: turns in a fight with a spawned wolf (BG:EE: the BG2 start cages the protagonist).
    # Turns: the turn-based combat mode against a spawned wolf (BG:EE).
    # DownHits: a hostile wolf attacks the downed protagonist: failed death saves, then a hit in the
    # last minute kills and the game ends (BG:EE).
    # Companions: every companion of tools\ingame\companions.txt is spawned as a copy without dialogue
    # and scripts (companion-copies.pl, perl from PATH or Git for Windows), converted and checked.
    # Record: the character record's Features tab, then the choice popup's row icons (masteries,
    # fighting styles without icons, spells).
    # SaveLoad: a pending choice and a pending level-up, saved as "B24 Test Pending", loaded again and
    # compared (the save is deleted afterwards).
    # Joining: companion copies join the party, are converted on joining and level up through the
    # record screen (single class: the engine's level-up; multiclass: the mod's class choice).
    # Spells: the spells changed to their 2024 form, cast by a spawned wolf on itself and measured.
    # WildShape: no checks, for trying Wild Shape by hand: the protagonist becomes a Druid of
    # -DruidLevel in -Circle with all Wild Shape uses, a wolf, a gnoll and an ogre appear, and the
    # game is left running for the player (one game only: -Game BGEE or BG2EE).
    # TurnPlay: no checks, for playing a turn-based fight by hand: the protagonist becomes a
    # -PlayClass of -PlayLevel, companions (BG:EE Khalid and Kivan, BG2:EE Minsc) join at that level, the
    # level-up choices of everyone are taken, turn-based combat goes on, a wizard, a fighter and a wolf come
    # (a gnoll joins in round 2)
    # (for a Wizard after it has memorized its spells and rested); the game is left running.
    # Petrify: a turn-based fight with a lesser basilisk and a companion (BG:EE): a panicking party
    # member's turn ends by itself, the companion turned to stone leaves the order, turns go on.
    [ValidateSet('Rules', 'Chargen', 'Icons', 'Dying', 'TurnProbe', 'TurnCombat', 'Turns', 'DownHits', 'Multiclass', 'Features', 'Companions', 'Record', 'SaveLoad', 'Joining', 'Spells', 'XPCap', 'RangeProbe', 'Export', 'Drain', 'Slayer', 'WildShape', 'TurnPlay', 'Petrify')]
    [string]$Mode = 'Rules',
    # WildShape: the Druid's level and circle.
    [ValidateRange(2, 20)]
    [int]$DruidLevel = 8,
    [ValidateSet('Land', 'Moon', 'Sea', 'Stars')]
    [string]$Circle = 'Land',
    # WildShape: turn-based combat on (the Turn-Based Combat innate switches it, saved with the game).
    [switch]$TurnBased,
    # TurnPlay: the protagonist's class and level.
    [ValidateSet('Fighter', 'Wizard')]
    [string]$PlayClass = 'Fighter',
    [ValidateRange(1, 20)]
    [int]$PlayLevel = 5,
    # Chargen: import this exported character (characters folder) instead of creating one.
    [string]$Import = '',
    # Chargen in BG2:EE: the campaign of the new game (SoA, or ToB with its high starting XP).
    [ValidateSet('SoA', 'ToB')]
    [string]$Campaign = 'SoA',
    [int]$TimeoutSeconds = 900,
    # Folder for screenshots: every few seconds while the test runs, and whenever the test module
    # asks for one ("[B24TEST] SHOT <name>").
    [string]$ShotDir,
    [int]$ShotEverySeconds = 0
)

$ErrorActionPreference = 'Stop'
if (($Mode -in @('WildShape', 'TurnPlay')) -and $Game -eq 'All') { throw "$Mode leaves the game running: pick one game with -Game BGEE or -Game BG2EE." }
if ($Mode -eq 'Petrify' -and $Game -ne 'BGEE') { throw "Petrify runs in BG:EE only (BG2:EE has no hostile basilisk): -Game BGEE." }
$ModRoot = Split-Path $PSScriptRoot -Parent
$GameRoot = 'C:\BG'
$DefaultSaves = @{ BGEE = 'Prologue Start'; BG2EE = 'Chapter 1 Start' }
$TestFiles = @('M_B24TS.lua', 'B24TEST.lua', 'B24TEST.menu', 'B24TCG.lua')

# Path is read once: a process that exits meanwhile has none.
function Get-GameProcess([string]$gameDir) {
    Get-Process -Name Baldur, InfinityLoader -ErrorAction SilentlyContinue |
        Where-Object { $p = $_.Path; $p -and $p.StartsWith($gameDir, [StringComparison]::OrdinalIgnoreCase) }
}

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class B24Win {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
    // Left click in the middle of a window.
    public static void ClickCenter(IntPtr hWnd) {
        RECT r;
        if (!GetWindowRect(hWnd, out r)) return;
        SetCursorPos((r.Left + r.Right) / 2, (r.Top + r.Bottom) / 2);
        mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero);
        mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero);
    }
}
'@
# Physical pixels for window rectangles, clicks and screenshots (Windows display scaling).
[B24Win]::SetProcessDPIAware() | Out-Null

# Saves a PNG of the game window (the screen area it covers).
function Save-Screenshot($proc, [string]$path) {
    if (-not $proc -or $proc.MainWindowHandle -eq [IntPtr]::Zero) { return }
    $r = New-Object B24Win+RECT
    if (-not [B24Win]::GetWindowRect($proc.MainWindowHandle, [ref]$r)) { return }
    $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
    if ($w -le 0 -or $h -le 0) { return }
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

function Remove-TestFiles([string]$override) {
    foreach ($f in $TestFiles) {
        $p = Join-Path $override $f
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    # Companion copies of the Companions mode.
    Get-ChildItem $override -Filter 'B24TC*.cre' -ErrorAction SilentlyContinue | Remove-Item -Force
}

# The save the SaveLoad mode makes (only that name; the player's saves stay untouched).
$SaveFolders = @{ BGEE = "Baldur's Gate - Enhanced Edition"; BG2EE = "Baldur's Gate II - Enhanced Edition" }
function Remove-TestSave([string]$game) {
    $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) (Join-Path $SaveFolders[$game] 'save')
    Get-ChildItem $dir -Directory -Filter '*-B24 Test Pending' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}

if ($ShotDir) { New-Item -ItemType Directory -Force $ShotDir | Out-Null }
$failedGames = 0
$games = if ($Game -eq 'All') { @('BGEE', 'BG2EE') } else { @($Game) }
foreach ($name in $games) {
    $gameDir = Join-Path $GameRoot $name
    $override = Join-Path $gameDir 'override'
    $log = Join-Path $gameDir 'b24debug.log'
    $saveName = if ($Save) { $Save } else { $DefaultSaves[$name] }
    Write-Host "=== $name (save: $saveName) ==="

    if (Get-GameProcess $gameDir) { throw "$name is running; close it first (the test starts and closes the game itself)." }

    # Test module: loaded by the engine like every M_*.lua, after the mod's own M_B24*.lua files.
    Copy-Item (Join-Path $PSScriptRoot 'ingame\B24TEST.lua'), (Join-Path $PSScriptRoot 'ingame\B24TEST.menu'),
        (Join-Path $PSScriptRoot 'ingame\B24TCG.lua') $override -Force
    $saveLua = $saveName.Replace('\', '\\').Replace('"', '\"')
    # Companions mode: copies of the companions without dialogue and scripts (companion-copies.pl).
    $companionsLua = 'nil'
    if ($Mode -in @('Companions', 'Joining', 'TurnPlay', 'Petrify')) {
        $perl = (Get-Command perl -ErrorAction SilentlyContinue).Source
        if (-not $perl -and (Test-Path 'C:\Program Files\Git\usr\bin\perl.exe')) { $perl = 'C:\Program Files\Git\usr\bin\perl.exe' }
        $pairs = & $perl (Join-Path $PSScriptRoot 'ingame\companion-copies.pl') $gameDir $(if ($Mode -eq 'Companions') { $name } else { "$Mode$name" })
        $entries = foreach ($line in $pairs) {
            $copy, $original = $line -split ' '
            "{ copy = `"$copy`", original = `"$original`" }"
        }
        $companionsLua = '{ ' + ($entries -join ', ') + ' }'
    }
    # Import: the mod's locals in the character file (op402 carriers B24LOCL, B24CORE.lua), which the
    # imported character must have in the game. In an effect, resource 2 and 3 (the name) are 0x40
    # and 0x48 bytes after the resource, parameter 1 (the value) 0x14 before it.
    $importLocalsLua = 'nil'
    if ($Import) {
        $docs = [Environment]::GetFolderPath('MyDocuments')
        $chr = Join-Path $docs (Join-Path $SaveFolders[$name] "characters\$Import.chr")
        # The Export run saves the character in the other game's folder (BG:EE): copied over, with
        # its .bio, into this game's characters folder (created if missing; BG2:EE had none).
        if (-not (Test-Path $chr)) {
            foreach ($other in $SaveFolders.Keys | Where-Object { $_ -ne $name }) {
                $from = Join-Path $docs (Join-Path $SaveFolders[$other] "characters\$Import.chr")
                if (Test-Path $from) {
                    New-Item -ItemType Directory -Force (Split-Path $chr) | Out-Null
                    Copy-Item $from $chr -Force
                    $bio = [IO.Path]::ChangeExtension($from, '.bio')
                    if (Test-Path $bio) { Copy-Item $bio ([IO.Path]::ChangeExtension($chr, '.bio')) -Force }
                    Write-Host "  copied $Import from $($SaveFolders[$other]) into $($SaveFolders[$name])\characters"
                    break
                }
            }
        }
        if (Test-Path $chr) {
            $bytes = [IO.File]::ReadAllBytes($chr)
            $text = [Text.Encoding]::ASCII.GetString($bytes)
            $entries = foreach ($m in [regex]::Matches($text, 'B24LOCL\x00')) {
                $at = $m.Index
                if ($at -lt 0x14 -or $at + 0x50 -gt $bytes.Length) { continue }
                $local = ($text.Substring($at + 0x40, 8) + $text.Substring($at + 0x48, 8)).TrimEnd([char]0) -replace '\x00.*$', ''
                if ($local -notmatch '^B24\w+$') { continue }
                "$local = $([BitConverter]::ToInt32($bytes, $at - 0x14))"
            }
            $importLocalsLua = '{ ' + (($entries | Sort-Object -Unique) -join ', ') + ' }'
        }
    }
    @"
-- Written by tools/ingame-test.ps1 for one test run; removed afterwards.
B24TEST_SAVE = "$saveLua"
B24TEST_CLASSES = "$Classes"
B24TEST_MODE = "$($Mode.ToLower())"
B24TEST_MODE_NAME = "$Mode"
B24TEST_GAME = "$(if ($name -eq 'BGEE') { 'BG:EE' } else { 'BG2:EE' })"
B24TEST_SPECIES = "$($Species.ToUpper())"
B24TEST_LEVELUP = $(if ($LevelTo -gt 0) { $LevelTo } else { 'nil' })
B24TEST_IMPORT = $(if ($Import) { '"' + $Import + '"' } else { 'nil' })
B24TEST_IMPORT_LOCALS = $importLocalsLua
B24TEST_CAMPAIGN = "$($Campaign.ToUpper())"
B24TEST_COMPANIONS = $companionsLua
B24TEST_DRUIDLEVEL = $DruidLevel
B24TEST_CIRCLE = "$($Circle.ToUpper())"
B24TEST_PLAYCLASS = "$($PlayClass.ToUpper())"
B24TEST_PLAYLEVEL = $PlayLevel
B24TEST_TURNBASED = $(if ($TurnBased) { 'true' } else { 'false' })
Infinity_DoFile("B24TEST")
if EEex_Menu_AddAfterMainFileLoadedListener then
	EEex_Menu_AddAfterMainFileLoadedListener(function() Infinity_DoFile("B24TEST") end)
end
"@ | Set-Content -Path (Join-Path $override 'M_B24TS.lua') -Encoding ascii

    if (Test-Path $log) { Remove-Item $log -Force }
    Remove-TestSave $name
    $started = Get-Date
    Start-Process -FilePath (Join-Path $gameDir 'InfinityLoader.exe') -WorkingDirectory $gameDir | Out-Null
    $done = $null
    # WildShape: the test module hands the game to the player; it stays open.
    $handover = $false
    $lastBeats, $heartbeat = 0, (Get-Date)
    $shell = New-Object -ComObject WScript.Shell
    $lastLoop = Get-Date
    try {
        while (((Get-Date) - $started).TotalSeconds -lt $TimeoutSeconds) {
            Start-Sleep -Seconds 1
            # The computer slept (a closed laptop): that time counts for neither the timeout nor the
            # heartbeat.
            $gap = (Get-Date) - $lastLoop
            if ($gap.TotalSeconds -gt 30) {
                $started, $heartbeat = $started + $gap, $heartbeat + $gap
                Write-Host "  the computer slept for $([int]$gap.TotalMinutes) min; the timeout starts over from there"
            }
            $lastLoop = Get-Date
            $text = [string](Get-Content $log -Raw -ErrorAction SilentlyContinue)
            if ($null -eq $text) { $text = '' }
            $proc = Get-Process -Name Baldur -ErrorAction SilentlyContinue |
                Where-Object { $p = $_.Path; $p -and $p.StartsWith($gameDir, [StringComparison]::OrdinalIgnoreCase) } |
                Select-Object -First 1
            # Screenshots first: a SHOT line shows the screen after the click that wrote it.
            if ($ShotDir) {
                $elapsed = [int]((Get-Date) - $started).TotalSeconds
                if ($ShotEverySeconds -gt 0 -and $elapsed % $ShotEverySeconds -eq 0) {
                    Save-Screenshot $proc (Join-Path $ShotDir ("{0}-t{1:D4}.png" -f $name, $elapsed))
                }
                foreach ($m in [regex]::Matches($text, '\[B24TEST\] SHOT (\S+)')) {
                    $file = Join-Path $ShotDir ("{0}-{1}.png" -f $name, $m.Groups[1].Value)
                    if (-not (Test-Path $file)) { Save-Screenshot $proc $file }
                }
            }
            # The loader goes as soon as the game has read it: if this script is killed before its
            # cleanup, the player's next start of the game runs no test.
            if ($text -match '\[B24TEST\] test module loaded') {
                Remove-Item (Join-Path $override 'M_B24TS.lua') -Force -ErrorAction SilentlyContinue
            }
            if ($text -match '\[B24TEST\] DONE') {
                $done = Select-String -Path $log -Pattern '\[B24TEST\] DONE' | Select-Object -First 1
                $handover = $text -match '\[B24TEST\] HANDOVER'
                break
            }
            # A click skips the startup movies and drives the test module's menu steps (the
            # full-screen button of B24TEST.menu) while the module's last word was not "CLICKS OFF"
            # (the level-up test turns them on again). No keys: Escape quits from the main menu.
            if ($text.LastIndexOf('[B24TEST] CLICKS OFF') -le $text.LastIndexOf('[B24TEST] CLICKS ON')) {
                if ($proc -and $proc.MainWindowHandle -ne [IntPtr]::Zero -and $shell.AppActivate($proc.Id)) {
                    [B24Win]::ClickCenter($proc.MainWindowHandle)
                }
            }
            # A movie (the intro after character creation, a chapter movie, the death movie) stops the
            # module's heartbeat: Escape skips it. Not before the first heartbeat (startup, main menu).
            $beats = [regex]::Matches($text, '\[B24TEST-ALIVE\]').Count
            if ($beats -ne $lastBeats) { $lastBeats, $heartbeat = $beats, (Get-Date) }
            # 15 s: Escape in the game world opens the game menu, so only a long silence counts (BG2:EE's
            # intro movies don't skip on Escape and play to their end anyway).
            $wait = 15
            if ($beats -gt 0) {
                if (((Get-Date) - $heartbeat).TotalSeconds -gt $wait -and $proc -and $shell.AppActivate($proc.Id)) {
                    Write-Host "  no heartbeat for $wait s (a movie?): Escape"
                    $shell.SendKeys('{ESC}')
                    $heartbeat = Get-Date
                }
            }
            if (((Get-Date) - $started).TotalSeconds -gt 30 -and -not (Get-GameProcess $gameDir)) {
                Write-Host "The game exited before the test finished (crash?)."
                break
            }
        }
    } finally {
        if ($handover) {
            Write-Host "  The game stays open for you (the test module rests; close the game when you are done)."
        } else {
            Get-GameProcess $gameDir | Stop-Process -Force -ErrorAction SilentlyContinue
            # Gone before the next run checks for it (a hung game takes a while to end).
            for ($i = 0; $i -lt 30 -and (Get-GameProcess $gameDir); $i++) { Start-Sleep -Seconds 1 }
            Start-Sleep -Seconds 2
        }
        Remove-TestFiles $override
        Remove-TestSave $name
    }

    if (Test-Path $log) {
        Select-String -Path $log -Pattern '\[B24TEST\]' | ForEach-Object { $_.Line -replace '^.*\[B24TEST\] ', '  ' }
        $errors = Select-String -Path $log -Pattern 'stack traceback|\.lua:\d+:' | Select-Object -First 10
        if ($errors) { Write-Host "  Lua errors in the log (first 10):"; $errors | ForEach-Object { "    " + $_.Line } }
    }
    if (-not $done) {
        Write-Host "  no DONE line after $([int]((Get-Date) - $started).TotalSeconds) s: test did not finish"
        $failedGames++
    } elseif ($done.Line -notmatch 'DONE \d+ 0\s*$') {
        $failedGames++
    }
    Write-Host ""
}
if ($failedGames) { Write-Host "In-game test FAILED in $failedGames game(s)"; exit 1 }
Write-Host "In-game test passed"
