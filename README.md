# BG 2024 Rules Mod

WeiDU mod that brings BG:EE and BG2:EE close to the D&D 2024 rules. Design: `docs/BG 2024 Rules Mod – Design Document.md`.

## Requirements

- BG:EE or BG2:EE, game build 2.7.3.0
- EEex v1.1.0 or newer (v1.3.1 tested target), installed before this mod
- On BG:EE from Steam/GOG: DLC Merger as the first mod

## Development

`deploy.ps1` copies the mod into `C:\BG\BGEE` and `C:\BG\BG2EE` and runs WeiDU.
It looks for `weidu.exe` in `tools\weidu\`, then `$env:WEIDU_EXE`, then `PATH`.
`-Reset` restores the working copies from the `-clean` folders first.
