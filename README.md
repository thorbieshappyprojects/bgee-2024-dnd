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

## License and attribution

The mod's own code, tables, texts and art are released under the MIT License (see `LICENSE`).

This work includes material from the System Reference Document 5.2 ("SRD 5.2") by Wizards of
the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2 is licensed under the
Creative Commons Attribution 4.0 International License, available at
https://creativecommons.org/licenses/by/4.0/legalcode. That material is not relicensed under
the MIT License.

This is an unofficial fan mod. It is not affiliated with, endorsed or sponsored by Wizards of
the Coast or Beamdog. Dungeons & Dragons and Baldur's Gate are trademarks of their respective
owners. The mod contains no game files: it needs an installed copy of Baldur's Gate: Enhanced
Edition or Baldur's Gate II: Enhanced Edition, and EEex.
