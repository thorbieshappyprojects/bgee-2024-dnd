# Test results

Automated in-game test runs (`tools/ingame-test.ps1`), newest first. Each run starts the game, loads
the test save (BG:EE "Prologue Start", BG2:EE "Chapter 1 Start") or creates a character, checks the
mod's rules and closes the game again. The checks are in `tools/ingame/B24TEST.lua`.

## 2026-10-28: 30-minute batch (the runs the one-hour batch left out)

Build: commit 9a36e6f. 16 runs, about 63 minutes, of which 40 were one run stuck until its
timeout; no player input. Then the two failed runs again after the fixes below.

**Result: 70 checks passed, 1 failed, 1 run without a result** (the ToB Wizard, stuck in the
Spellbook choice). After the fixes both runs pass: Import 1/0, ToB Wizard to 20 6/0.

| Run | Game | What it covers | Minutes | Passed | Failed |
| --- | --- | --- | --- | --- | --- |
| TurnProbe | BG:EE | The engine's Time Stop for one creature, the base of turn-based mode | 0.4 | 1 | 0 |
| RangeProbe | BG:EE, BG2:EE | Every spell's range measured in the game | 2.5 | 2 | 0 |
| Record | BG:EE | Record screen Features tab, choice popup icons | 0.6 | 5 | 0 |
| Export | BG:EE | Export of a character with the mod's choices | 0.4 | 1 | 0 |
| Import | BG2:EE | That character imported in BG2:EE (fixed: 1 passed, 0 failed) | 1.7 | 0 | **1** |
| Chargen Bard to 5 | BG:EE | Character creation, then level-ups 2 to 5 on the record screen | 1.6 | 5 | 0 |
| Chargen Fighter to 5 | BG:EE | The same | 1.4 | 5 | 0 |
| Chargen Monk to 5 | BG:EE | The same | 1.3 | 5 | 0 |
| Chargen Rogue to 5 | BG:EE | The same | 1.4 | 5 | 0 |
| Chargen Sorcerer to 5 | BG:EE | The same | 1.7 | 5 | 0 |
| Chargen Wizard to 5 | BG:EE | The same | 1.9 | 5 | 0 |
| Chargen Fighter to 9 | BG2:EE | Creation and level-ups in SoA | 3.3 | 3 | 0 |
| Chargen Cleric to 9 | BG2:EE | The same | 3.4 | 3 | 0 |
| Chargen Rogue to 9 | BG2:EE | The same | 3.2 | 2 | 0 |
| Chargen Fighter to 20 | BG2:EE (ToB) | Creation in ToB, level-ups to 20, level cap, Epic Boons | 1.8 | 4 | 0 |
| Chargen Wizard to 20 | BG2:EE (ToB) | The same (fixed: 6 passed, 0 failed in 3.3 minutes) | 40.1 | 3 | stuck |

### Fixed: the Wizard's Spellbook choice came back forever (mod fault)

At level 19 the Spellbook choice offered Invisibility (SPWI206), the wizard picked it, and it
came back with the same spell, again and again until the timeout. A player would have been stuck
in the same popup. Two causes:

- **The Shadow-Touched feat removed the spell.** Feat resources are rebuilt by removing their
  spell (op172) and granting it again (op171). Shadow-Touched's resource was SPWI206 itself, so
  every rebuild took Invisibility out of the wizard's spellbook. Fey-Touched did the same with
  Command (SPPR102) to priests. Op171 with a wizard or priest spell only adds it to the spells
  known, so the two feats never gave their free cast either. Both now use the innate copies
  (B24IW206, B24IP102; `lua/B24GFEAT.lua`), as Spell Mastery does. Found by a diagnostic: op147
  with SPWI206 directly made it known, and it was gone again after the next rebuild.
- **BG's Intelligence caps on the spellbook.** INTMOD.2DA limits the highest spell level a
  wizard can learn and the spells known per level by INT (INT 17: level 8 at most, 14 per level;
  the mod's upcast copies count). 2024 has no such caps; the fixed run ends with 17 level-2
  spells. The Spells component now sets them to level 9 and 99 spells (`lib/b24_spells.tpa`).

The test now logs each Spellbook pick and fails at once if the same spell is offered twice in a
row, instead of waiting for the timeout.

### Fixed in the test: Import (1 failure)

The check expected fixed skills and background. The export run takes them from the BG:EE test
save's protagonist, and they differed between runs (2058/10 in the batch, 260/2 in the rerun).
The import carried them over correctly both times. The test script now reads the expected values
from the exported character file (the mod's B24LOCL carrier effects) and passes them to the
check.

## 2026-10-28: one-hour batch

Build: commit bf5903d plus the turn-based follow-ups that came after it (party AI off while
turn-based mode is on, a short wait after spells so their effects land, the initiative bar in its
fixed order with a moving gold frame, spell names in the prepared casting message). 34 runs, about
75 minutes, no player input; then three more Dying runs in BG2:EE to narrow down its failures.

**Result: 626 checks passed, 3 failed.** All 3 failures were in Dying, BG2:EE: a fault in the test,
fixed the same day (see below; the run now passes 18/18).

| Run | Game | What it covers | Minutes | Passed | Failed |
| --- | --- | --- | --- | --- | --- |
| Rules | BG:EE | Every class through its levels: hit points, saves, proficiency, slots, features applied | 9.6 | 155 | 0 |
| Rules | BG2:EE | The same in BG2:EE | 9.7 | 155 | 0 |
| Features | BG2:EE | Class and subclass features at high levels, incl. the new Wild Shape | 1.6 | 41 | 0 |
| Features | BG:EE | The same in BG:EE | 1.5 | 41 | 0 |
| Spells | BG:EE | The 2024 versions of the spells, cast and measured | 5.8 | 23 | 0 |
| Spells | BG2:EE | The same in BG2:EE | 5.8 | 23 | 0 |
| Turns | BG:EE | Turn-based mode: initiative, alternating turns, frozen waiting side, End Turn, bonus actions, Opportunity Attacks, reaction prompts, end of combat | 2.3 | 13 | 0 |
| TurnCombat | BG:EE | Turns in a fight with a spawned wolf | 0.6 | 3 | 0 |
| DownHits | BG:EE | Hits on a downed character count as failed death saves | 1.0 | 2 | 0 |
| Dying | BG:EE | Dropping to 0, death saves, stabilizing, Revivify, Raise Dead, massive damage, game over | 1.3 | 18 | 0 |
| Dying | BG2:EE | The same in BG2:EE (fixed afterwards: 18 passed, 0 failed) | 2.0 | 15 | **3** |
| SaveLoad | BG:EE | Pending choice, pending level-up and concentration across save and load | 0.5 | 2 | 0 |
| SaveLoad | BG2:EE | The same in BG2:EE | 0.5 | 2 | 0 |
| Record | BG2:EE | Record screen Features tab, choice popup icons | 0.6 | 5 | 0 |
| Multiclass | BG:EE | Multiclass rules | 0.4 | 1 | 0 |
| Multiclass | BG2:EE | Multiclass rules, multiclass companions | 0.4 | 10 | 0 |
| Companions | BG:EE | Every joinable companion converted to the 2024 rules | 1.6 | 30 | 0 |
| Companions | BG2:EE | The same in BG2:EE | 1.3 | 22 | 0 |
| Joining | BG:EE | Companions join, are converted and level up through the record screen | 1.4 | 7 | 0 |
| Joining | BG2:EE | The same in BG2:EE | 1.9 | 7 | 0 |
| Icons | BG:EE | Portrait icons of the mod's states, prone, Escape Grapple | 0.6 | 5 | 0 |
| Icons | BG2:EE | The same in BG2:EE | 0.6 | 5 | 0 |
| Drain | BG2:EE | BG's level drain and its restoration | 0.5 | 2 | 0 |
| XPCap | BG2:EE | XP given the way the game gives it reaches the character | 0.4 | 1 | 0 |
| Slayer | BG2:EE | The Slayer change and back with the mod's numbers | 0.5 | 2 | 0 |
| Chargen Druid to 5 | BG:EE | Character creation, then level-ups 2 to 5 on the record screen | 1.6 | 5 | 0 |
| Chargen Barbarian to 5 | BG:EE | The same | 1.4 | 5 | 0 |
| Chargen Cleric to 5 | BG:EE | The same | 1.4 | 5 | 0 |
| Chargen Paladin to 5 | BG:EE | The same | 1.4 | 5 | 0 |
| Chargen Ranger to 5 | BG:EE | The same | 1.5 | 5 | 0 |
| Chargen Wizard to 9 | BG2:EE | Creation and level-ups in SoA | 3.6 | 3 | 0 |
| Chargen Druid to 20 | BG2:EE (ToB) | Creation in ToB, level-ups to 20, level cap, Epic Boons | 2.2 | 8 | 0 |

### Fixed in the test during the batch

The first runs of "Chargen Druid to 5" and "Chargen Wizard to 9" each failed "level cap and Epic
Boons". That check belongs to level-20 runs (ToB) but also ran after level-ups to 5 and 9, where it
can only fail. It now runs only at level 20; both runs passed again afterwards (counted above).

### Fixed afterwards: Dying in BG2:EE (3 failures)

The revived companion came back at full hit points instead of 1, and the downed protagonist was
healed to full, so the checks after it failed. The cause was the party AI: in BG2:EE the
protagonist has the Bhaalspawn powers, and its AI script healed the downed party member with Cure
Wounds (SPIN101, caught by a watch on the hit points: 1 -> 20 with SPIN101's effects on the
companion). That is normal play, not a fault of the mod; in BG:EE the protagonist has no such power
at the start. The test now switches party AI off before it starts (it never saves). Rerun in
BG2:EE: 18 passed, 0 failed. It also failed with the builds of commits aba4d55 and 8f26136, so it
wasn't caused by the day's changes.

### Not covered by this batch (by hand)

The Wild Shape beast menu (opcode 214 waits for a click), the turn-based screen elements (initiative
bar, End Turn button, the mode switch and its tooltip), party AI switching off in turn-based mode,
and how the new icon order looks in the spellbook and on the action bar.
