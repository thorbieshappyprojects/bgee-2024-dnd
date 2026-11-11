# 2024 Coverage

How much of the D&D 2024 Player's Handbook has a corresponding mechanic in BG:EE / BG2:EE with this
mod: every class feature, subclass feature, feat, species trait, background, spell and core rule.
Audited from the code and the installed game files (commit 70347c2, 2026-10-27); 2024 lists from
the PHB 2024. Statuses:

- **Implemented**: works as the 2024 rule.
- **Approximated**: exists, differs from 2024 (the note says how).
- **BG native**: the unchanged engine already does it the 2024 way.
- **No BG form**: cannot exist in BG (no such system), left out on purpose.
- **Missing**: could be done in BG, not done yet.

## Overview

| Area | Implemented | Approximated | BG native | No BG form | Missing | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Base-class features (11 BG classes) | 93 | 58 | 0 | 11 | 8 | 170 |
| Subclass features (44 subclasses) | 79 | 78 | 0 | 21 | 46 | 224 |
| Feats | 22 | 24 | 0 | 3 | 26 | 75 |
| Species traits | 15 | 16 | 1 | 3 | 9 | 44 |
| Backgrounds | 2 | 18 | 0 | 0 | 1 | 21 |
| Core rules | 33 | 45 | 10 | 9 | 13 | 110 |
| Spells (all lists, cantrips to 9) | 45 | 56 | 41 | 111 | 137 | 390 |
| **Total** | **289** | **295** | **52** | **158** | **240** | **1034** |
| Warlock (class, 4 patrons) | 0 | 0 | 0 | 10 | 21 | 31 |

## Biggest gaps

1. **Spells:** 137 of the 2024 spells that could work in BG are missing (Guidance, True Strike,
   Faerie Fire, Heroism, Moonbeam, Spike Growth, Hypnotic Pattern, Banishment, Wall of Fire, all
   smite spells, all Summon spells, the Ranger-only spells, ...), and many present ones are the 2e
   versions under the 2024 name (Inflict Wounds, Shield of Faith, Haste, Magic Missile, Sleep,
   Bless/Bane, Spiritual Weapon, Flame Strike, Harm). Class spell lists are too wide (Bards and
   Sorcerers share the whole arcane list; Paladins and Rangers the whole Cleric/Druid lists).
2. **Subclass spell lists** (domain, oath, circle spells) are granted nowhere (17 rows).
3. **Warlock** does not exist (no BG class; could be built as a Sorcerer kit).
4. **Reactions, Opportunity Attacks, bonus actions**: being built in the turn-based mode
   (bonus actions done); this unlocks Sentinel, Interception, Protection, Shield/Counterspell as
   reactions, Retaliation, Riposte and more.
5. 6 of 10 **Fighting Styles** are missing (the 12 **Epic Boons** were added 2026-10-28).
6. **Druid Wild Shape**: done 2026-10-28, the 2024 beast forms from level 2 (lua/B24DRUID.lua).
7. **Generic actions** (Dash, Dodge, Help, Shove, Grapple for everyone), **Heroic Inspiration**
   on attacks, **exhaustion sources**, the 14 **creature types** (only BG's 6 general groups are read).
8. **Species**: Elf and Gnome lineages, Tiefling legacies, Aasimar and Goliath traits.

## Bugs found by the audit

Fixed 2026-10-28 unless noted:

- Tough gives no hit points to characters without a background (companions) when taken at an ASI.
  Fixed (`B24FEAT.lua`: the check also looks at feats taken at an improvement).
- Wayfarer background lacks Thieves' Tools: fixed. The Goliath description says human body, the
  code uses the half-orc body (with infravision): the description now says so.
- Concentration is kept only in a Lua table (lost on save/load): fixed (the spell is kept in two
  variables of the caster, `B24.Conc_Restore`; SaveLoad test); a paralysed or held caster now
  loses it; Spirit Guardians is a concentration spell (its end also ends the guardians).
- Storm of Vengeance (catalog) and Dimension Door are hidden spells in the game: unhidden (BG hides
  them for its HLAs, which the mod switches off); Conjure Elemental appears twice per element for
  wizards: the level 6 versions (SPWI620-622, hidden by BG) are dropped from the catalog.
- The mod's new spells (Healing Word, Guiding Bolt, Thunderwave, Shatter, Spirit Guardians, Mass
  Healing Word) have no upcasting: fixed (copies B24U..., Lua dice by spell level; Spells test).
- War God's Blessing is the 2014 feature: now Channel Divinity Shield of Faith without concentration
  (Spiritual Weapon left out). Psi Warrior's Guarded Mind and Bulwark of Force come at the wrong
  levels: now 10 and 15.
- Design document: some "Native" rows are done in Lua; the turn-based mode is missing; "Land:
  Circle Spells Native" is wrong. Fixed: rows done by the mod's Lua say "Native (in Lua, EEex)"; the
  turn-based mode is described (Rounds, Action economy); Land: Circle Spells is Approximated.

# Details

## BG 2024 Rules Mod: base-class feature coverage (PHB 2024, levels 1-20)

Audit of the repo C:\BG\bg2024 at commit 70347c2, read-only. Only base-class features are covered; subclass features are out of scope. The "Subclass" row only checks that the level 3 choice exists.

Status: **I** = Implemented, **A** = Approximated, **B** = BG native, **N** = No BG form, **M** = Missing.

Shared mechanics, referred to in the rows below:
- **ASI**: `lua/B24LEVEL.lua` (choice popup `B24ASI`): +2/+1+1, or a general or origin feat from `lua/B24GFEAT.lua`.
- **Epic Boon**: the level 19 entry in every class's `ASI_LEVELS` offers the 12 boons (B24GFEAT.lua) or another feat; past level 20 more boons come with XP.
- **Extra Attack** (warriors): `lib/b24_core_tables.tpa` patches WSPATCK.2DA to 2 attacks from level 5 with no specialization bonus. Higher counts come from op1 in the class Lua.
- **Weapon Mastery**: `lua/B24PROF.lua` (counts) and `lua/B24WPN.lua` (properties). The chosen masteries can only be added to. Nothing swaps them on a long rest. Graze works only on misses produced by the mod's advantage rolls. Nick has no effect.
- **Fighting Style**: `B24LV.STYLES` in `lua/B24LEVEL.lua` has only Archery, Defense, Great Weapon Fighting and Two-Weapon Fighting, 4 of the 10 PHB styles.
- **Spellcasting**: `lua/B24SPELL.lua` plus `tables/b24_mxspl*.2da` and `tables/b24_splsrckn.2da`. These give 2024 slot tables with no Wisdom bonus slots, cantrips as at-will innates that scale at 5/11/17, and spell DC and attack computed in EEx. Prepared casting means memorized entries that swap within a level. Upcasting uses generated copies. Cleric and druid lists are separated through exclusion flags. Priest 8th and 9th level spells and slots sit at level 7.
- **Expertise / skills**: `lua/B24PROF.lua` maps 2024 skills onto BG thief skills and Lore.
- **Resources**: `B24LV.AddResource` handles short and long rest recovery.

---

### Barbarian (BG: Fighter with Barbarian kit) - `lua/B24BARB.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Rage | Bonus action, 2-6 uses, regain 1 on short rest; B/P/S resistance, +2/+3/+4 Str damage, adv. on Str checks/saves; 10 min, extendable | A | `B24RAGE` (op402): op86-88 50%, damage listener, Str-save advantage; `B24LV` resource (shortRest "one") | Fixed 1 min. No heavy-armor or no-spellcasting restriction. No Str-check advantage. Uses and damage progression are correct. |
| 1 | Unarmored Defense | AC 10 + Dex + Con without armor (shield ok) | I | Stat listener subtracts the Con mod from AC when no body armor is worn | |
| 1 | Weapon Mastery | 2 kinds (3 at 4, 4 at 10), swap on long rest | A | `B24.MasteryCount` override; `B24WPN.lua` | No long-rest swap. Graze and Nick are limited (see shared). |
| 2 | Danger Sense | Adv. on Dex saves unless incapacitated | I | `B24.AddSaveAdvantageListener` (DEX, not helpless/stunned/sleeping) | |
| 2 | Reckless Attack | Adv. on Str attacks this turn; attacks vs you have adv. | I | `B24RECKL` innate: ATTACK_ADV + GRANTS_ADV for 6 s | Applies to every attack, not only Str-based ones. |
| 3 | Subclass | Choose Path | I | `B24LV.AddSubclasses` popup | |
| 3 | Primal Knowledge | +1 Barbarian skill; Str for some checks while raging | M | none (header: "no BG effect") | The skill system exists, so the extra proficiency could be granted (e.g. Perception affects finding traps). |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Extra Attack | 2 attacks | I | WSPATCK patch (Barbarian = Fighter kit) | |
| 5 | Fast Movement | +10 ft unless in heavy armor | A | Permanent op176 133% | No heavy-armor check. |
| 7 | Feral Instinct | Adv. on Initiative | N | none | BG has no initiative. |
| 7 | Instinctive Pounce | Move half speed when entering rage | N | none | Real-time movement, no turn movement budget. |
| 9 | Brutal Strike | Forgo Reckless adv. on one attack: +1d10 and Forceful/Hamstring Blow | A | Damage listener: +1d10 on first hit per round while Reckless | Advantage is not given up. No Forceful (push) or Hamstring (slow) effect, though both exist as mastery effects. |
| 11 | Relentless Rage | At 0 HP while raging: DC 10 Con save (+5 each) -> HP = 2x level | A | op208 min-HP 1 once per rage; `B24.AddDownSaver` | No save. Stays at 1 HP instead of 2x level. Once per rage. |
| 13 | Improved Brutal Strike | Adds Staggering Blow and Sundering Blow | M | none | No Brutal Strike effects exist at all. |
| 15 | Persistent Rage | Regain all rages on Initiative (1/long rest); rage lasts 10 min without upkeep | M | none (header: "no BG effect") | `B24.AddCombatStartListener` (as Archdruid uses) and a 10 min duration would do it. |
| 17 | Improved Brutal Strike | 2d10, two effects | A | +2d10 in damage listener | Damage only, no effects. |
| 18 | Indomitable Might | Str check total < Str score -> use score | N | none | No d20 Strength checks in BG. |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon (B24GFEAT.lua) or another feat | |
| 20 | Primal Champion | Str and Con +4 (max 25) | I | Permanent op44/op10 +4 | |

### Bard - `lua/B24BARD.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Bardic Inspiration | Cha-mod uses/long rest; ally adds die to a failed d20 test within 1 h; d6->d12 | A | `B24BINSP` innate; `B24.AddSaveFailedListener` | Works on failed saves only. No attack rolls or checks ("BG reports no misses"). Die sizes and uses are correct. |
| 1 | Spellcasting | Cha prepared caster, Bard list, cantrips 2/3/4 | A | `b24_mxsplbrd.2da`, prepared-casting swap, cantrip choice | Bards learn from the whole arcane (wizard) list via scrolls, not the 2024 Bard list. Bard-only healing copies added (B24HWBRD etc.). |
| 2 | Expertise | 2 skills (2 more at 9) | I | EXPERTISE choice (B24EXPRT) | |
| 2 | Jack of All Trades | Half PB to unproficient checks | I | `B24.AddSkillBonusListener` | |
| 3 | Subclass | Choose College | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Font of Inspiration | Regain on short rest; spend slot to regain a use | A | Short-rest listener resets uses | Slot -> Inspiration conversion missing (`B24SP.SpendSlot` exists). |
| 7 | Countercharm | Reaction: ally within 30 ft rerolls failed charm/fear save with adv. | A | Passive advantage on charm/fear saves for party within ~24 ft | Passive aura instead of a reaction reroll. |
| 9 | Expertise | 2 more skills | I | EXPERTISE count 4 | |
| 10 | Magical Secrets | Prepare spells from Bard/Cleric/Druid/Wizard lists | A | Pick list `SECRETS`: 2/4/6 Cleric or Druid spells as innate copies cast with Bard slots | Limited count, not any prepared spell. Wizard spells are already open to bards. |
| 18 | Superior Inspiration | On Initiative regain up to 2 uses | I | `B24.AddCombatStartListener` | |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Words of Creation | Power Word Heal and Kill always prepared, can target 2 | A | Power Word Kill (SPWI912) added to the spellbook | No Power Word Heal (no BG spell), no second target. |

### Cleric - `lua/B24CLER.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Spellcasting | Wis prepared caster, Cleric list, cantrips 3/4/5 | A | `b24_mxsplprs.2da`, catalog C list, prepared swap | 8th and 9th level spells and slots sit at level 7 (engine limit). |
| 1 | Divine Order | Protector (martial, heavy armor) or Thaumaturge (+cantrip, Wis to Arcana/Religion) | I | `B24LV.AddOption` DIVINE_ORDER; weapon-proficiency and skill listeners | BG clerics already wear heavy armor. |
| 2 | Channel Divinity | 2 uses (3 at 6, 4 at 18), regain 1 on short rest | I | Resource CLERIC_CHANNEL | |
| 2 | Divine Spark | Heal 1d8+Wis or Con save vs radiant/necrotic damage; dice grow at 7/13/18 | I | `B24DSPRK` | |
| 2 | Turn Undead | Undead within 30 ft: Wis save or frightened/incapacitated 1 min | I | `B24TURNU` (op24 panic 60 s) | |
| 3 | Subclass | Choose Domain | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Sear Undead | Turned undead take Wis-mod d8 radiant | I | In `B24TURNU` | |
| 7 | Blessed Strikes | Divine Strike (+1d8 1/turn) or Potent Spellcasting (+Wis to cantrips) | I | Option BLESSED_STRIKES; weapon and spell damage listeners | Divine Strike damage takes the weapon's type, not radiant/necrotic. |
| 10 | Divine Intervention | Cast a Cleric spell of level 5 or lower, no slot, 1/long rest | I | `B24CDIVI` choice -> innate copy | |
| 14 | Improved Blessed Strikes | Divine Strike 2d8; Potent Spellcasting grants temp HP 2x Wis | A | 2d8 done | Potent Spellcasting temp HP missing. |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Greater Divine Intervention | Wish via DI; then 2d4 long rests | I | Wish (SPWI914) entry with B24DIWSH counter | Only where the game has Wish (BG2:EE). |

### Druid - `lua/B24DRUID.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Spellcasting | Wis prepared caster, Druid list, cantrips 2/3/4 | A | `b24_mxspldru.2da`, D list, prepared swap | 8th and 9th level at 7 (engine). |
| 1 | Druidic | Secret language | N | none | No languages in BG. |
| 1 | Primal Order | Magician or Warden | I | Option PRIMAL_ORDER; proficiency and skill listeners | |
$1Wild Shape innate B24WSHAP (a Wild Shape use) opens the forms up to the druid's tier (op214, B24WSL1-4.2DA); a form (B24WSHAP.2DA, 13 beasts with BG animations) is a timed claws item (op111: look, attacks per round) for half the level in hours; Lua sets Str/Dex/Con, AC and attack bonus; temp HP = level; no casting (op145) below 18; ends on 0 HP, incapacitation or Natural Form (B24WSEND); riders: prone, poison, Pack Tactics, Bloodied Fury | No known-form choice: every form of the tier can be taken. No flying forms. Charge riders, Constrict, Web and Nimble Escape missing. Worn items keep their non-AC effects. |
| 2 | Wild Companion | Spend Wild Shape use or slot: Find Familiar | A | `B24WCOMP`: summon wolf B24BST03 for 1 h | Wolf instead of a familiar. No spell-slot option. |
| 3 | Subclass | Choose Circle | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Wild Resurgence | Slot -> Wild Shape use (no uses left); 1/long rest Wild Shape -> level 1 slot | I | `B24WRES1`, `B24WRES2` | |
| 7 | Elemental Fury | Potent Spellcasting (+Wis cantrips) or Primal Strike (+1d8 elemental) | I | Option ELEMENTAL_FURY; damage listeners | Primal Strike damage takes the weapon's type, not cold/fire/lightning. |
| 15 | Improved Elemental Fury | Primal Strike 2d8; Potent Spellcasting +300 ft cantrip range | A | 2d8 done | Range extension missing (fixed spell ranges). |
| 18 | Beast Spells | Cast spells in Wild Shape | I | From level 18 the form blocks no spellcasting | Spells with a costly or consumed material component are not singled out. |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Archdruid | Evergreen Wild Shape; Nature Magician; Longevity | I | Combat start restores a use; `B24NMAGI` | Longevity has no BG form. |

### Fighter - `lua/B24FIGHT.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Fighting Style | Fighting Style feat | A | STYLE choice (`B24LV.STYLES`) | 4 of 10 styles (no Dueling, Protection, Interception, Blind Fighting, Thrown Weapon, Unarmed). |
| 1 | Second Wind | Heal 1d10+level; 2/3/4 uses, regain 1 short rest | I | `B24SWIND`, resource SECOND_WIND | |
| 1 | Weapon Mastery | 3/4/5/6 kinds | A | `B24.MasteryCount` override | No long-rest swap (see shared). |
| 2 | Action Surge | One extra action (2 uses at 17), short rest | A | `B24ASURG`: +attacks equal to a round's attacks and op189 faster casting for 6 s | Extra attacks and faster casting, not a full extra action. |
| 2 | Tactical Mind | Spend Second Wind: +1d10 to a failed ability check | N | none | No d20 ability checks in BG. |
| 3 | Subclass | Choose archetype | I | Subclass popup | |
| 4/6/8/12/14/16 | Ability Score Improvement | ASI or feat | I | `ASI_LEVELS` {4,6,8,12,14,16,19} | |
| 5 | Extra Attack | 2 attacks | I | WSPATCK patch | |
| 5 | Tactical Shift | Second Wind: move half speed without OAs | A | +50% speed for 6 s after Second Wind | No opportunity attacks in BG. |
| 9 | Indomitable | Reroll failed save + Fighter level; 1/2/3 uses (9/13/17) | I | `B24.AddSaveFailedListener`, resource INDOMITABLE | Party members only, used automatically. |
| 9 | Tactical Master | Replace mastery with Push/Sap/Slow | I | `B24TMAST` toggle; `PropertyOverrideListeners` | |
| 11 | Two Extra Attacks | 3 attacks | I | Permanent op1 +1 | |
| 13 | Studied Attacks | Miss -> adv. on next attack vs that target | I | `B24WPN.MissListeners` (Vex record) | Only on misses the mod detects. |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Three Extra Attacks | 4 attacks | I | Permanent op1 +2 | |

### Monk - `lua/B24MONK.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Martial Arts | Die d6->d12, Dex for unarmed/monk weapons, bonus unarmed strike | I | Fist items B24MF* via MONKFIST.2DA (`lib/b24_fighter.tpa`); finesse listener; permanent op1 +1 | The bonus strike is a permanent extra attack. |
| 1 | Unarmored Defense | AC 10 + Dex + Wis | I | Stat listener (no armor or shield) | |
| 2 | Monk's Focus | Focus = level, short rest; Flurry, Patient Defense, Step of the Wind | I | Resource FOCUS; `B24FLURY`, `B24PDEF` (attacks vs you at disadvantage), `B24STEPW` | The free Disengage/Dash part has no meaning without OAs. |
| 2 | Unarmored Movement | +10 to +30 ft without armor/shield | A | Permanent op176 133-200% | No armor or shield check. |
| 2 | Uncanny Metabolism | On Initiative: regain all Focus, heal MA die + level; 1/long rest | A | `B24UMETA` innate, used by hand | Manual instead of on Initiative. |
| 3 | Deflect Attacks | Reaction: reduce B/P/S attack damage by 1d10+Dex+level; redirect for 1 Focus | A | Damage listener: auto, first weapon hit per round | No redirect. Covers all weapon damage. |
| 3 | Subclass | Choose Warrior of ... | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 4 | Slow Fall | Reduce falling damage | N | none | No falling in BG. |
| 5 | Extra Attack | 2 attacks | I | Permanent op1 +2 (with Martial Arts strike) | |
| 5 | Stunning Strike | 1 Focus on hit: Con save or stunned; success: half speed, adv. vs it | I | `B24STUN` readies the next hit | Readied beforehand rather than chosen on hit. |
| 6 | Empowered Strikes | Unarmed strikes may deal force damage | A | Fists B24MF8+ are magical (+1 enchantment) | Overcome magic-weapon immunity, but no force damage type. |
| 7 | Evasion | Dex save: none/half damage | I | `B24.AddEvasionListener` | |
| 9 | Acrobatic Movement | Move on walls and water | N | none | No vertical or water movement. |
| 10 | Heightened Focus | Flurry 3 strikes; Patient Defense temp HP; Step of the Wind carries an ally | A | Flurry +2 at 10 | Temp HP and ally carry missing. |
| 10 | Self-Restoration | End charmed/frightened/poisoned at end of turn | A | Permanent immunity to charm and fear (op101) | Immunity instead of an end-of-turn cure. Poison not covered. The header says level 6; the code uses 10. |
| 13 | Deflect Energy | Deflect Attacks works on any damage type | M | none ("no BG effect yet") | Could reuse the damage hook for spell damage. |
| 14 | Disciplined Survivor | All save proficiencies; 1 Focus to reroll a failed save | I | Save proficiency and SaveFailed listeners | |
| 15 | Perfect Focus | On Initiative with fewer than 4 Focus, regain up to 4 | M | none | Combat-start listener exists. Easy to add. |
| 18 | Superior Defense | 3 Focus: resistance to all but force, 1 min | I | `B24SUPDF` | |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Body and Mind | Dex and Wis +4 (max 25) | I | Permanent op15/op49 +4 | |

### Paladin - `lua/B24PALA.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Lay on Hands | Pool 5x level; heal, or 5 points to cure poison | A | `B24LOH` (heals the missing amount from the pool) | The 5-point poison cure is missing below level 14. |
| 1 | Spellcasting | Cha prepared half caster, Paladin list | A | `b24_mxsplpal.2da` (2024 table), prepared swap | Uses the whole cleric list up to level 5, not the Paladin list. The header comment still says "spells follow". |
| 1 | Weapon Mastery | 2 kinds | A | `B24.MASTERY_COUNT.PALADIN = 2` | No long-rest swap. |
| 2 | Fighting Style | Style feat or Blessed Warrior | A | STYLE choice | 4 styles, no Blessed Warrior. |
| 2 | Paladin's Smite | Divine Smite always prepared, 1 free cast/long rest; slots fuel more | A | `B24SMITE` toggle; first melee hit per round; separate SMITE pool (1 + 2024 slot count); dice by level | Does not spend real spell slots. Dice scale with level, not slot. |
| 3 | Channel Divinity | 2 uses (3 at 11), regain 1 short rest | I | Resource CHANNEL_DIVINITY | |
| 3 | Divine Sense (CD option) | Sense celestials, fiends, undead within 60 ft | M | none | Could reveal or mark undead and fiends nearby. |
| 3 | Subclass | Choose Oath | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Extra Attack | 2 attacks | I | WSPATCK patch | |
| 5 | Faithful Steed | Find Steed always prepared, 1 free cast/long rest | M | none ("a spell: not yet") | No mounts, but a summoned fighting steed is possible (`B24.Summon` exists). |
| 6 | Aura of Protection | Allies within 10 ft add Cha mod to saves | I | `B24.AddSaveBonusListener` | Not while the paladin is dead or helpless. |
| 9 | Abjure Foes | CD: Cha-mod enemies, Wis save or frightened | I | `B24ABJUR` | |
| 10 | Aura of Courage | Immune to frightened in the aura | I | Tick: op101 (fear) for allies in range | |
| 11 | Radiant Strikes | +1d8 radiant on melee weapon hits | I | Damage listener | Damage takes the weapon's type. |
| 14 | Restoring Touch | LoH ends conditions, 5 points each | I | `B24PA.RestoringTouch` (op337) | |
| 18 | Aura Expansion | Auras 30 ft | I | `auraRange` 240 | |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |

### Ranger - `lua/B24RANGR.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Spellcasting | Wis prepared half caster, Ranger list | A | `b24_mxsplran.2da` (2024 table), prepared swap | Uses the whole druid list up to level 5. |
| 1 | Favored Enemy | Hunter's Mark always prepared; 2-6 free casts | A | `B24HMARK` innate, 1d6 on weapon hits, 1 h, resource uses 2/3/4/5/6 | Innate, not a spell. No concentration, no slot casting, no moving the mark. |
| 1 | Weapon Mastery | 2 kinds | A | `B24.MASTERY_COUNT.RANGER = 2` | No long-rest swap. |
| 2 | Deft Explorer | Expertise in 1 skill; 2 languages | I | EXPERTISE count 1 | Languages have no BG form. |
| 2 | Fighting Style | Style feat or Druidic Warrior | A | STYLE choice | 4 styles, no Druidic Warrior. |
| 3 | Subclass | Choose conclave | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Extra Attack | 2 attacks | I | WSPATCK patch | |
| 6 | Roving | +10 ft unless in heavy armor; climb/swim | I | Permanent op176 133% | No heavy-armor check. Climbing and swimming have no BG form. |
| 9 | Expertise | 2 more skills | I | EXPERTISE count 3 | |
| 10 | Tireless | Temp HP 1d8+Wis (Wis-mod uses); short rest -1 Exhaustion | I | `B24TIRLS` (op18 for 1 h); short-rest listener | Temp HP are extra max HP. |
| 13 | Relentless Hunter | Damage can't break concentration on Hunter's Mark | N | none | Moot: Hunter's Mark is not a concentration spell here. |
| 14 | Nature's Veil | Invisible until end of next turn, Wis-mod uses | I | `B24NVEIL` (op20, 12 s) | |
| 17 | Precise Hunter | Adv. vs marked target | I | `AdvantageAgainstListeners` | |
| 18 | Feral Senses | Blindsight 30 ft | A | Permanent see-invisible (op193) | Unlimited range, invisibility only. |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Foe Slayer | Hunter's Mark die d10 | I | Damage listener | |

### Rogue (BG: Thief) - `lua/B24ROGUE.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Expertise | 2 skills (2 more at 6) | I | Character creation (`B24CHGEN.lua`), defaults Stealth and Thieves' Tools | |
| 1 | Sneak Attack | 1d6/2 levels, 1/turn, finesse/ranged, adv. or ally adjacent | I | Damage listener; backstab removed at install | |
| 1 | Thieves' Cant | Secret language | N | none | No languages in BG. |
| 1 | Weapon Mastery | 2 kinds | A | `B24.MASTERY_COUNT.ROGUE = 2` | No long-rest swap. |
| 2 | Cunning Action | Bonus Dash/Disengage/Hide | A | `B24CUNNG`: speed x2 for a round, at will | Dash only. Hide is BG's own Stealth action. Disengage is moot. |
| 3 | Subclass | Choose archetype | I | Subclass popup | |
| 3 | Steady Aim | Adv. on next attack, speed 0 | I | `B24STAIM` | |
| 4/8/10/12/16 | Ability Score Improvement | ASI or feat | I | `ASI_LEVELS` incl. 10 | |
| 5 | Cunning Strike | Trade SA dice: Poison, Trip, Withdraw | I | Innates B24RC* ready an option for the next Sneak Attack | |
| 5 | Uncanny Dodge | Reaction: halve an attack's damage | I | Auto, first weapon hit per round | Automatic instead of a reaction. |
| 6 | Expertise | 2 more | I | EXPERTISE count 2 | |
| 7 | Evasion | Dex save: none/half | I | `B24.AddEvasionListener` | |
| 7 | Reliable Talent | d20 <= 9 counts as 10 on proficient checks | N | none | BG thief skills are percentage rolls, not d20 checks. |
| 11 | Improved Cunning Strike | 2 effects per SA | I | `cunningPerAttack` 2 | |
| 14 | Devious Strikes | Daze, Knock Out, Obscure | I | B24RCDAZ/KNO/OBS | Daze is approximated as slow for 1 round. |
| 15 | Slippery Mind | Wis and Cha save proficiency | I | Save proficiency listener | |
| 18 | Elusive | No adv. against you unless incapacitated | I | `NoAdvantageAgainstListeners` | |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Stroke of Luck | Failed d20 test -> 20, 1/short rest | A | `B24.AddSaveFailedListener` | Saves only. No missed attacks or checks. |

### Sorcerer - `lua/B24SORC.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Spellcasting | Cha, Sorcerer list, 2024 prepared count, cantrips 4/5/6 | A | `b24_mxsplsrc.2da`, `b24_splsrckn.2da`; engine spontaneous casting | Picks come from the whole arcane list. The S list is used only for new spells and cantrips. |
| 1 | Innate Sorcery | 2/long rest: +1 DC, adv. on spell attacks, 1 min | I | `B24INSOR`; SpellDC listener; SPELL_ADV | |
| 2 | Font of Magic | Sorcery Points = level; slots <-> points | A | Resource SORCERY_POINTS; `B24FOM1-5` create slots (op261) | Slot -> points is missing. The header calls it "no BG form", yet `B24SP.SpendSlot` already spends slots for the Bard. |
| 2 | Metamagic | 2 options (4 at 10, 6 at 17) | A | Pick METAMAGIC; Careful, Empowered, Extended, Heightened, Quickened, Seeking, Transmuted | 7 of 10. Distant, Subtle and Twinned have no form. Heightened hits all targets. |
| 3 | Subclass | Choose origin | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Sorcerous Restoration | Short rest: regain half level in points, 1/long rest | I | Short-rest listener | Automatic. |
| 7 | Sorcery Incarnate | Innate Sorcery for 2 points; 2 Metamagic per spell | I | `B24INSO2`; `optionsPerSpell` | |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Arcane Apotheosis | During Innate Sorcery, 1 free Metamagic per turn | I | `apotheosis` free once per round | |

### Wizard - `lua/B24WIZ.lua`

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Spellcasting | Int prepared caster, spellbook 6 + 2/level, Wizard list, cantrips 3/4/5 | A | `b24_mxsplwiz.2da`; SPELLBOOK choice tops the book up; prepared swap | Memorized entry per slot, with a swap within each level. |
| 1 | Ritual Adept | Cast ritual spells from the book without preparing | M | none (header: "no rituals in BG") | BG has ritual spells (e.g. Identify SPWI110). The mod already lists long-casting-time spells in `b24_spells.tpa`, so a slotless innate copy with a long cast is feasible. |
| 1 | Arcane Recovery | Short rest: slots totalling half level (max 5th), 1/long rest | I | Short-rest listener, `B24SP.Restore` | Automatic on a short rest. |
| 2 | Scholar | Expertise in Arcana/History/Investigation/Medicine/Nature/Religion | A | EXPERTISE count 1 | Any proficient skill is allowed, not just those six. |
| 3 | Subclass | Choose school | I | Subclass popup | |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | I | ASI popup | |
| 5 | Memorize Spell | Short rest: swap one prepared spell | A | One newly memorized, not-yet-ready spell becomes ready after a short rest | Close in effect, but it relies on the engine's re-memorize flow. |
| 18 | Spell Mastery | Level 1 and 2 spell at will | I | Picks MASTERY1/2; innate copies re-granted | |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Signature Spells | Two 3rd-level spells, 1 free cast each per short rest | I | Pick SIGNATURE; innate copies, B24WSGU | |

### Warlock - no file

BG has no Warlock class, and the mod adds none. The only mention is "Warlock" in the Later spell-list column of the design doc scope table. No kit, table or Lua exists.

| Level | 2024 feature | 2024 rule (short) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 1 | Eldritch Invocations | Chosen invocations | N | none | No Warlock class. Could be built as a Sorcerer kit. |
| 1 | Pact Magic | Few slots, all max level, short rest | N | none | Same. |
| 2 | Magical Cunning | Regain half pact slots, 1/long rest | N | none | Same. |
| 3 | Subclass | Patron | N | none | Same. |
| 4/8/12/16 | Ability Score Improvement | ASI or feat | N | none | Same. |
| 9 | Contact Patron | Contact Other Plane | N | none | Same. |
| 11/13/15/17 | Mystic Arcanum | One 6th-9th level spell 1/long rest each | N | none | Same. |
| 19 | Epic Boon | Epic Boon feat | I | Improvement popup: a boon or another feat | |
| 20 | Eldritch Master | Magical Cunning regains all slots | N | none | Same. |

---

### Summary

| Class | Implemented | Approximated | BG native | No BG form | Missing | Rows |
|---|---|---|---|---|---|---|
| Barbarian | 7 | 7 | 0 | 3 | 3 | 20 |
| Bard | 6 | 7 | 0 | 0 | 0 | 13 |
| Cleric | 10 | 3 | 0 | 0 | 0 | 13 |
| Druid | 6 | 5 | 0 | 2 | 0 | 13 |
| Fighter | 9 | 5 | 0 | 1 | 0 | 15 |
| Monk | 11 | 7 | 0 | 2 | 2 | 22 |
| Paladin | 10 | 6 | 0 | 0 | 2 | 18 |
| Ranger | 10 | 6 | 0 | 1 | 0 | 17 |
| Rogue | 13 | 4 | 0 | 2 | 0 | 19 |
| Sorcerer | 6 | 4 | 0 | 0 | 0 | 10 |
| Wizard | 5 | 4 | 0 | 0 | 1 | 10 |
| **Total (11 BG classes)** | **93** | **58** | **0** | **11** | **8** | **170** |
| Warlock | 0 | 0 | 0 | 9 | 0 | 9 |
| **Total incl. Warlock** | **93** | **58** | **0** | **20** | **8** | **179** |

"BG native" is 0 because the mod replaced or patched every engine mechanic that could have counted. Examples: the WSPATCK attack table, backstab, 2e kit and class abilities, slot tables. Druid shapeshifting was the last engine mechanic kept as is; the 2024 Wild Shape replaced it on 2026-10-28.

#### Discrepancies between docs/comments and code
- Wild Shape follows the design doc since 2026-10-28, except the 4/6/8 known forms: every form of the tier can be taken.
- The design doc lists Fighting Style, Spell Mastery and Signature Spells as "Native". They are Lua implementations, and Fighting Style offers only 4 styles.
- The Paladin and Ranger headers say "spells follow with the spell updates". 2024 slot tables are installed, but there are no Paladin or Ranger lists.
- The Monk header puts Self-Restoration at 6. FEATURES and the code use 10.
- The Sorcerer header calls slot -> Sorcery Points "no BG form". `B24SP.SpendSlot` already does the needed slot spending.
- The Wizard header says "no rituals in BG". Ritual spells such as Identify exist.


## PHB 2024 subclass coverage — BG 2024 Rules Mod

Audit of every PHB 2024 subclass feature (48 subclasses) against the mod code (lua/B24X*.lua, the SRD subclass entries in lua/B24<CLASS>.lua, lib/*.tpa, tools/subclass_innates.txt). Read-only audit; statuses judged from code, not comments.

Status key: **Implemented** (works as the 2024 rule; small edge cases in Note) · **Approximated** (exists, differs noticeably) · **BG native** (engine already does it) · **No BG form** (cannot exist in BG) · **Missing** (possible in BG, not done).

General findings:
- **Subclass spell lists are not granted anywhere** (Cleric domains, Paladin oaths, Druid Land/Moon/Sea circles, Fey Wanderer/Gloom Stalker, Draconic/Aberrant spells, Glamour's Charm Person/Mirror Image). Only exception: Clockwork Spells as once-per-long-rest innates. The design doc row "Land: Circle Spells … Native" is wrong; the code says "circle spells follow".
- "No reactions in BG" is used as a reason for leaving out Retaliation, Soul of Vengeance, Spell Thief etc., but the mod already automates reactions elsewhere (Glorious Defense via `EEex_Sprite_AddBlockWeaponHitListener`, Cutting Words, Protective Field, Superior Hunter's Defense, Projected Ward). Those are counted as Missing.
- Several "no BG effect" teleports (Travel Along the Tree, Arcane Charge, Shadow Step, Warping Implosion, Psychic Teleportation) could use the mod's own Misty Step (B24MSTEP, a Dimension Door copy).
- Radiant, necrotic, psychic and force damage are all dealt as BG magic damage (`B24X.MAGIC`); counted as Implemented.
- No Warlock class exists; nothing for the four patrons is in lua/, lib/, tables/ or tools/ (grep "warlock|patron" finds only the design-doc spell-list line and Tiefling's Fiendish Legacy).
- Stale texts found: design doc says Champion Survivor has "no death saves" (lua/B24DYING.lua has death saves); B24XROG.lua says "Cunning Strike itself is not in yet" (B24RCPOI etc. exist); Psi Warrior features are granted 3–5 levels early (Guarded Mind 7 instead of 10, Bulwark of Force 10 instead of 15); War Domain level 6 is the 2014 War God's Blessing.

---

### Barbarian

#### Path of the Berserker (SRD — lua/B24BARB.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Frenzy | Reckless Attack while raging: first Str hit each turn + d6s equal to Rage Damage | Implemented | B24BARB.lua damage listener (RECKLESS + raging) | |
| 6 | Mindless Rage | Immune to Charmed/Frightened while raging; such effects end when rage starts | Implemented | op101 vs op5/op24 for the rage | effects already on you are not removed |
| 10 | Retaliation | Reaction: melee attack against a creature within 5 ft that damaged you | Missing | – | "no reactions in BG"; an automatic counter-hit is feasible as for Glorious Defense |
| 14 | Intimidating Presence | 30-ft Wis save or Frightened 1 min (save each turn); 1/LR or spend a Rage | Approximated | innate B24INTIM, op24 60 s | no repeated save, no Rage-for-use |

#### Path of the Wild Heart (lua/B24XBAR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Animal Speaker | Beast Sense, Speak with Animals as rituals | No BG form | – | no animal dialogue |
| 3 | Rage of the Wilds | Each rage: Bear (resist all but force/necrotic/psychic/radiant), Eagle (Dash+Disengage), Wolf (allies adv. vs adjacent foes) | Approximated | option B24WRAGE; Bear op27-30,173; Eagle op176 150%; Wolf AdvantageAgainstListener | chosen once at level 3, not per rage |
| 6 | Aspect of the Wilds | Owl darkvision / Panther climb / Salmon swim, choose per long rest | No BG form | – | Owl could at most be cosmetic infravision |
| 10 | Nature Speaker | Commune with Nature as ritual | No BG form | – | |
| 14 | Power of the Wilds | Each rage: Falcon (fly), Lion (adjacent foes disadv. vs others), Ram (melee hit knocks prone) | Approximated | option B24WPOWR; Lion DisadvantageAgainstListener; Ram KnockProne | chosen once; Falcon no BG form; Ram no size limit |

#### Path of the World Tree (lua/B24XBAR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Vitality of the Tree | Temp HP = level on rage; each turn a creature within 10 ft gets Rage-Damage d6 temp HP | Implemented | RageListener TempHP; tick listener | ally auto-picked (most hurt) |
| 6 | Branches of the Tree | Reaction: creature starting turn within 30 ft, Str save or teleported next to you, speed 0 | Approximated | innate B24WTBRN: once/round Str save or pulled next to you (B24.ForceMove) and GRAPPLED 6 s | used actively, not as a reaction |
| 10 | Battering Roots | +10 ft reach with Heavy/Versatile; add Push or Topple mastery | Approximated | damage listener: Heavy/Versatile melee hits Topple (Con save or prone), a prone target is pushed 10 ft | no reach |
| 14 | Travel Along the Tree | Teleport 60 ft on rage/bonus action; once per rage 150 ft with up to 6 allies | Approximated | innate B24WTTRV (Dimension Door copy, 60 ft) while raging, once per round | group teleport has no BG form |

#### Path of the Zealot (lua/B24XBAR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Divine Fury | Raging: first hit each turn +1d6 + half level necrotic/radiant | Implemented | damage listener, magic damage | |
| 3 | Warrior of the Gods | Pool of d12s (4/5/6/7) to heal yourself | Implemented | resource WARRIOR_OF_THE_GODS, innate B24ZWARG | one die per use |
| 6 | Fanatical Focus | Once per rage reroll failed save + Rage Damage | Implemented | SaveFailedListener | |
| 10 | Zealous Presence | Up to 10 creatures in 60 ft: adv. on attacks and saves; 1/LR or a Rage | Implemented | innate B24ZPRES | no Rage-for-use |
| 14 | Rage of the Gods | 1 min: fly, resist necrotic/psychic/radiant, Revivification (spend Rage: ally at 0 HP gets HP = level) | Approximated | RageListener op31 (magic resistance) 1/LR | flight no BG form; Revivification missing though B24.AddDownSaver exists |

### Bard

#### College of Lore (SRD — lua/B24BARD.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Bonus Proficiencies | Three skills of your choice | Approximated | B24BD.LORE_SKILLS | auto-picked (first three not yet proficient), no choice |
| 3 | Cutting Words | Reaction: subtract BI die from a creature's attack, damage or check | Approximated | damage listener: once/round, hit vs party member in 30 ft loses a BI die | damage only, auto-spent |
| 6 | Magical Discoveries | Two spells from Cleric, Druid or Wizard lists | Implemented | Magical Secrets pick +2 (priest spells as innates on bard slots) | wizard spells via scrolls |
| 14 | Peerless Skill | Failed check or attack: add BI die (kept if still failed) | Approximated | SaveFailedListener on saves | used on saves, not checks/attacks |

#### College of Dance (lua/B24XBRD.lua; BLADE kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Dazzling Footwork | Unarmored: AC 10+Dex+Cha; Agile Strikes (unarmed strike when spending BI); unarmed Dex + BI die damage | Approximated | StatListener AC; FinesseListener fists; fist die = BI die | Agile Strikes missing; Dance Virtuoso no BG form |
| 6 | Inspiring Movement | Reaction: move half speed, an ally moves too | No BG form | – | no reactions to movement / OAs |
| 6 | Tandem Footwork | BI to initiative for you and allies | No BG form | – | no initiative |
| 14 | Leading Evasion | Evasion for you and creatures within 5 ft | Implemented | EvasionListener | |

#### College of Glamour (lua/B24XBRD.lua; JESTER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Beguiling Magic | Charm Person + Mirror Image prepared; after an Enchant/Illusion spell, Wis save or Charmed/Frightened 1 min; 1/LR or BI | Approximated | innate B24GBEGU: frighten only | not tied to a spell; no charm; the two spells not granted |
| 3 | Mantle of Inspiration | BI: Cha-mod allies gain 2×die temp HP and may move | Implemented | innate B24GMANT | move part no BG form |
| 6 | Mantle of Majesty | Command prepared; 1 min bonus-action Command each turn; 1/LR or 3rd+ slot | Approximated | B24GMAJE + B24GCMND: Wis save or prone | Grovel only; no slot restore; charmed auto-fail missing |
| 14 | Unbreakable Majesty | 1 min: first hit on you each turn, attacker Cha save or it misses | Approximated | B24GUNBR: GRANTS_DIS 60 s, 1/SR | disadvantage instead of save-or-miss |

#### College of Valor (lua/B24XBRD.lua; SKALD kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Combat Inspiration | BI holder: add die to damage, or to AC as reaction | Approximated | damage listener adds die to next hit | Defense option missing |
| 3 | Martial Training | Martial weapons, medium armor, shields, weapon as focus | Approximated | WeaponProficiencyListener | armor/shields follow BG kit rules |
| 6 | Extra Attack | Two attacks; one may be a cantrip | Implemented | permanent op1 +1 attack | cantrip swap n/a |
| 14 | Battle Magic | After casting a spell, bonus-action weapon attack | Implemented | SpellCastListener: +1 attack that round | |

### Cleric

#### Life Domain (SRD — lua/B24CLER.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Life Domain Spells | Aid, Bless, Cure Wounds, Lesser Restoration; Mass Healing Word, Revivify; Aura of Life, Death Ward; Greater Restoration, Mass Cure Wounds | Missing | – | "domain spells follow"; most exist in BG/mod |
| 3 | Disciple of Life | Healing spell heals +2 + slot level | Implemented | HealBonusListener | spell level, not slot level |
| 3 | Preserve Life | CD: 5×level HP among Bloodied creatures in 30 ft, up to half max | Implemented | innate B24PRSLF | party only |
| 6 | Blessed Healer | Healing another heals you 2 + slot level | Implemented | HealBonusListener | |
| 17 | Supreme Healing | Healing dice roll maximum | Implemented | MaxHealListener | |

#### Light Domain (lua/B24XCLR.lua; LATHANDER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Light Domain Spells | Burning Hands, Faerie Fire, Scorching Ray, See Invisibility; Daylight, Fireball; Arcane Eye, Wall of Fire; Flame Strike, Scrying | Missing | – | "not granted yet" |
| 3 | Radiance of the Dawn | CD: dispel magical darkness; foes in 30 ft Con save 2d10+level radiant, half | Implemented | innate B24LRADI | darkness part no BG form |
| 3 | Warding Flare | Reaction: disadvantage on one attack vs you/ally in 30 ft; Wis-mod/LR | Approximated | innate B24LWARD: GRANTS_DIS for a round | pre-emptive, whole round |
| 6 | Improved Warding Flare | Back on short rest; target gains 2d6+Wis temp HP | Implemented | shortRest + TempHP | |
| 17 | Corona of Light | 1 min: foes in 60 ft disadv. on saves vs Radiance and fire/radiant spells | Approximated | B24LCORO + SaveAdvantageListener | applies to all the cleric's spells |

#### Trickery Domain (lua/B24XCLR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Trickery Domain Spells | Charm Person, Disguise Self, Invisibility, Pass without Trace; Hypnotic Pattern, Nondetection; Confusion, Dimension Door; Dominate Person, Modify Memory | Missing | – | |
| 3 | Blessing of the Trickster | Adv. on Stealth for you or a creature in 30 ft until long rest | Approximated | B24TBLES: +25 stealth (op59, op275) 1 h | 1 use/LR, touch |
| 3 | Invoke Duplicity | CD: illusory double 1 min; adv. vs foes near both; cast from it | Approximated | B24TDUPL: ATTACK_ADV 60 s | no double; adv. vs everyone |
| 6 | Trickster's Transposition | Teleport, swapping places with the illusion | Missing | – | "no BG effect"; needs a real double (BG has Mislead/Project Image) |
| 17 | Improved Duplicity | Allies adv. vs foes near illusion; heal = level when it ends | Approximated | AdvantageAgainstListener near cleric; tick heal | uses cleric's position |

#### War Domain (lua/B24XCLR.lua; OHTEMPUS kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | War Domain Spells | Guiding Bolt, Magic Weapon, Shield of Faith, Spiritual Weapon; Crusader's Mantle, Spirit Guardians; Fire Shield, Freedom of Movement; Hold Monster, Steel Wind Strike | Missing | – | Guiding Bolt, Spirit Guardians exist as mod spells |
| 3 | Guided Strike | CD after a miss by you or creature in 30 ft: +10 to that roll | Approximated | B24WGSTR self (+10 to hit this round); ally only via level-6 B24WGBLS | pre-emptive, not after a miss |
| 3 | War Priest | Bonus-action attack, Wis-mod/SR | Implemented | B24WPRST +1 attack this round | |
| 6 | War God's Blessing | CD: Shield of Faith or Spiritual Weapon without slot or concentration | Missing | B24WGBLS is the 2014 feature (Guided Strike for an ally) | Spiritual Hammer exists in BG |
| 17 | Avatar of Battle | Resistance to B/P/S | Implemented | permanent op86-89 | |

### Druid

#### Circle of the Land (SRD — lua/B24DRUID.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Circle of the Land Spells | Land type each long rest; always-prepared spells per land | Missing | land type option B24LAND (once) | design doc says "Native": wrong, no spells granted |
| 3 | Land's Aid | Wild Shape use: 10-ft sphere Con save 2d6 necrotic, one creature heals 2d6 (3d6/4d6) | Approximated | innate B24LAID | own pool (2/3/4, one on SR) instead of Wild Shape uses |
| 6 | Natural Recovery | One circle spell free/LR; short rest: slots ≤ half level back, 1/LR | Approximated | ShortRestListener restores slots | free circle spell missing |
| 10 | Nature's Ward | Immune to Poisoned; resistance by land | Implemented | op101(25) + resistance opcode | |
| 14 | Nature's Sanctuary | Wild Shape: placeable 15-ft cube, half cover, allies share Ward resistance | Approximated | B24NSANC: +2 AC + resistance around the druid 1 min | not placeable/movable |

#### Circle of the Moon (lua/B24XDRU.lua; SHAPESHIFTER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Circle of the Moon Spells | Cure Wounds, Moonbeam, Starry Wisp; Conjure Animals; Fount of Moonlight; Mass Cure Wounds; castable in Wild Shape | Missing | – | casting in shape no BG form |
| 3 | Circle Forms | CR = level/3; AC ≥ 13+Wis; temp HP 3×level | Approximated | Form tier 3 (CR 1) at 3 and 4 (CR 2) at 6; AC floor and temp HP in B24DRUID.lua | No beast with a BG animation above CR 2, so forms stop at CR 2. |
| 6 | Improved Circle Forms | Radiant option for form attacks; +Wis to Con saves | Approximated | SaveBonusListener | Lunar Radiance missing |
| 10 | Moonlight Step | Teleport 30 ft + adv. on next attack; Wis-mod/LR, 2nd+ slot restores | Approximated | resource MOONLIGHT_STEP → B24MSTEP | no advantage, no slot restore |
| 14 | Lunar Form | +2d10 radiant once per turn in form; Moonlight Step takes an ally | Approximated | damage listener while shifted | Shared Moonlight missing |

#### Circle of the Sea (lua/B24XDRU.lua; BEAST_FRIEND kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Circle of the Sea Spells | Fog Cloud, Gust of Wind, Ray of Frost, Shatter, Thunderwave; Lightning Bolt, Water Breathing; Control Water, Ice Storm; Conjure Elemental, Hold Monster | Missing | – | |
| 3 | Wrath of the Sea | Wild Shape: 10 min aura, Con save Wis-mod d6 cold + push 15 ft | Implemented | B24SWRAT + tick | automatic once per round |
| 6 | Aquatic Affinity | Aura 10 ft; swim speed | Implemented | range 120 | swim no BG form |
| 10 | Stormborn | While Wrath: fly; resist cold, lightning, thunder | Implemented | op28/op29 10 min | flight no BG form |
| 14 | Oceanic Gift | Wrath aura on a willing ally (both for 2 uses) | Missing | – | "no BG effect"; aura could tick from an ally |

#### Circle of the Stars (lua/B24XDRU.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Star Map | Guidance + Guiding Bolt prepared; free Guiding Bolt Wis-mod/LR | Approximated | resource STAR_MAP → B24GBOLT | Guidance missing |
| 3 | Starry Form | Wild Shape, 10 min: Archer arrow 1d8+Wis, Chalice heal 1d8+Wis, Dragon min 10 on concentration/Int/Wis | Implemented | B24STARC/STCHL/STDRG, B24STARW | Dragon covers all Con saves |
| 6 | Cosmic Omen | Weal +d6 ally / Woe −d6 foe on a D20 test; Wis-mod/LR | Approximated | SaveFailedListener +1d6 ally save | Woe missing; saves only |
| 10 | Twinkling Constellations | 2d8; Dragon flight; change form each turn | Implemented | starDice, forms re-granted | flight no BG form |
| 14 | Full of Stars | Resistance B/P/S in Starry Form | Implemented | op86-89 | |

### Fighter

#### Champion (SRD — lua/B24FIGHT.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Improved Critical | Crit on 19-20 | Implemented | op301 | |
| 3 | Remarkable Athlete | Adv. on initiative and Athletics; move after crit | No BG form | – | design doc says Approximated; code has nothing |
| 7 | Additional Fighting Style | Second Fighting Style | Implemented | STYLE = 2 | |
| 10 | Heroic Warrior | Heroic Inspiration each turn in combat | Implemented | tick listener | |
| 15 | Superior Critical | Crit on 18-20 | Implemented | op301 | |
| 18 | Survivor | Defy Death (adv. death saves, 18-20 = 20) + Heroic Rally (5+Con per turn while Bloodied) | Approximated | tick Heroic Rally | Defy Death missing; B24DYING has death saves |

#### Battle Master (lua/B24XFIG.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Combat Superiority | 4 d8 dice (SR), 3 of 20 maneuvers; 5/7/9 maneuvers, 5/6 dice | Approximated | resource SUPERIORITY, pick MANEUVERS (15 innates B24M*) | Ambush, Bait and Switch, Commanding Presence, Maneuvering Attack, Riposte, Tactical Assessment missing; readied before the hit |
| 3 | Student of War | One artisan tool + one Fighter skill | Missing | – | skill grant possible (GrantedSkillListener) |
| 7 | Know Your Enemy | Learn immunities/resistances/vulnerabilities | Missing | – | could be printed to the log |
| 10 | Improved Combat Superiority | d10 dice | Implemented | SuperiorityDie | |
| 15 | Relentless | Once per turn use 1d8 instead of a die | Approximated | superiorityRoll | only when no dice are left |
| 18 | Ultimate Combat Superiority | d12 dice | Implemented | SuperiorityDie | |

#### Eldritch Knight (lua/B24XFIG.lua, B24XCOM.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Spellcasting | Third caster, Wizard list, Int; 2 cantrips (3 at 10) | Implemented | B24X.AddThirdCaster (innates on own slots) | |
| 3 | War Bond | Bonded weapons can't be disarmed, summon to hand | No BG form | – | |
| 7 | War Magic | Replace one attack with a cantrip | Missing | – | "no BG effect"; Valor Battle Magic pattern fits |
| 10 | Eldritch Strike | Hit → disadv. on next save vs your spell | Implemented | DamageListener + SaveAdvantageListener | |
| 15 | Arcane Charge | Teleport 30 ft on Action Surge | Missing | – | teleport possible |
| 18 | Improved War Magic | Replace two attacks with a level 1-2 spell | Missing | – | |

#### Psi Warrior (lua/B24XFIG.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Psionic Power | Dice 4d6 → 12d12; one back on SR, all on LR | Implemented | resource PSI_WARRIOR_DICE, B24X.PsionicDice | |
| 3 | Protective Field | Reaction: reduce damage to you/ally in 30 ft by die + Int | Implemented | damage listener once/round | automatic |
| 3 | Psionic Strike | After a hit: die + Int force damage | Implemented | B24PSTRK readied | readied before the hit |
| 3 | Telekinetic Movement | Move a Large-or-smaller creature/object 30 ft | Missing | – | push/pull (op235) possible |
| 7 | Telekinetic Adept | Psi-Powered Leap (fly); Telekinetic Thrust (Psionic Strike: Str save or prone/pushed 10 ft) | Missing | – | Thrust easy (KnockProne/op235); Leap no BG form |
| 10 | Guarded Mind | Resist psychic; spend die to end Charmed/Frightened | Approximated | B24PGMND op161 (fear only) | granted at 7; charm not ended |
| 15 | Bulwark of Force | Half cover for you + Int-mod allies 1 min; 1/LR or die | Implemented | B24PBULW +2 AC | granted at 10 |
| 18 | Telekinetic Master | Telekinesis free 1/LR; bonus attack while concentrating | No BG form | – | no Telekinesis in BG |

### Monk

#### Warrior of the Open Hand (SRD — lua/B24MONK.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Open Hand Technique | Flurry hit: Addle, Push (Str save 15 ft) or Topple (Dex save) | Approximated | damage listener during FLURRY: Topple only | Push missing; Addle no BG form |
| 6 | Wholeness of Body | Heal MA die + Wis, Wis-mod/LR | Implemented | innate B24WHOLE | |
| 11 | Fleet Step | Step of the Wind after any other bonus action | Missing | – | "no BG effect yet"; B24STEPW exists |
| 17 | Quivering Palm | 4 Focus on hit, later end: Con save 10d12 force, half | Approximated | touch innate B24QPALM | immediate, no delayed trigger |

#### Warrior of Mercy (lua/B24XMNK.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Hand of Harm | 1 Focus on unarmed hit: MA die + Wis necrotic | Implemented | B24MHARM readied | |
| 3 | Hand of Healing | 1 Focus touch: MA die + Wis; replaces a Flurry strike for free | Approximated | B24MHHEL | Flurry substitution missing |
| 3 | Implements of Mercy | Insight, Medicine, Herbalism Kit | Implemented | GrantedSkillListener | kit no BG form |
| 6 | Physician's Touch | Harm poisons; Healing ends Blinded/Deafened/Paralyzed/Poisoned/Stunned | Implemented | ATTACK_DIS 6 s; op11/75/81/162 | Stunned not cured |
| 11 | Flurry of Healing and Harm | Free Healing/Harm in Flurry, Wis-mod/LR | Approximated | free Hand of Harm once/round in Flurry | healing part and use limit missing |
| 17 | Hand of Ultimate Mercy | 5 Focus 1/LR: revive dead ≤ 24 h with 4d10+Wis | Implemented | B24MULTM | |

#### Warrior of Shadow (lua/B24XMNK.lua; DARK_MOON kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Shadow Arts | 1 Focus Darkness you see through; darkvision; Minor Illusion | Approximated | B24MSART invisibility 1 min | no Darkness spell in BG |
| 6 | Shadow Step | In dim light/dark: teleport 60 ft + adv. on next melee attack | Approximated | B24MSSTP adv. + speed burst | no teleport, no light check |
| 11 | Improved Shadow Step | 1 Focus ignores light; unarmed strike after teleport | Missing | – | extra attack possible |
| 17 | Cloak of Shadows | 3 Focus 1 min: Invisible, pass through creatures, free Flurry | Approximated | B24MCLOA improved invisibility | free Flurry missing |

#### Warrior of the Elements (lua/B24XMNK.lua; SUN_SOUL kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Elemental Attunement | 1 Focus 10 min: +10 ft reach; chosen elemental damage, Str save push 10 ft | Approximated | B24MATTN: cold only, push away | no type choice, no reach |
| 3 | Manipulate Elements | Elementalism cantrip | No BG form | – | |
| 6 | Elemental Burst | 2 Focus: 20-ft sphere, Dex save 3 MA dice | Implemented | B24MBRST | cold only |
| 11 | Stride of the Elements | Fly/swim while attuned | No BG form | – | |
| 17 | Elemental Epitome | Resistance (chosen); Destructive Stride; +MA die once per turn | Approximated | op28 cold + extra MA die | Destructive Stride missing |

### Paladin

#### Oath of Devotion (SRD — lua/B24PALA.lua; UNDEAD_HUNTER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Oath of Devotion Spells | PfE&G, Shield of Faith; Aid, Zone of Truth; Beacon of Hope, Dispel Magic; Freedom of Movement, Guardian of Faith; Commune, Flame Strike | Missing | – | "follow with the spell updates" |
| 3 | Sacred Weapon | CD: +Cha to attacks 10 min, radiant option | Implemented | B24SACWP op54 | radiant option missing |
| 7 | Aura of Devotion | Immune to Charmed in aura | Implemented | tick op101(5) | |
| 15 | Smite of Protection | Divine Smite: half cover in aura | Implemented | +2 AC 6 s on smite | |
| 20 | Holy Nimbus | Adv. saves vs fiends/undead; Cha+PB radiant per turn in aura; 1/LR or 5th slot | Approximated | B24NIMBS + tick damage | Holy Ward missing |

#### Oath of Glory (lua/B24XPAL.lua; CAVALIER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Oath of Glory Spells | Guiding Bolt, Heroism; Enhance Ability, Magic Weapon; Haste, Protection from Energy; Compulsion, Freedom of Movement; Legend Lore, Yolande's Regal Presence | Missing | – | |
| 3 | Inspiring Smite | After Divine Smite, CD: share 2d8+level temp HP in 30 ft | Approximated | innate B24GINSP | standalone, split evenly |
| 3 | Peerless Athlete | CD: adv. Athletics/Acrobatics, jumps | No BG form | – | |
| 7 | Aura of Alacrity | +10 ft speed; allies in aura +10 ft | Implemented | op176 + aura tick | |
| 15 | Glorious Defense | Reaction: +Cha AC vs hit in 10 ft, counterattack on miss; Cha-mod/LR | Approximated | BlockWeaponHitListener, chance-based miss | no counterattack |
| 20 | Living Legend | 1 min: miss → hit once per turn; reroll failed save; 1/LR or 5th slot | Approximated | B24GLEGD once/round save reroll | miss → hit missing |

#### Oath of the Ancients (lua/B24XPAL.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Oath of the Ancients Spells | Ensnaring Strike, Speak with Animals; Misty Step, Moonbeam; Plant Growth, Protection from Energy; Ice Storm, Stoneskin; Commune with Nature, Tree Stride | Missing | – | |
| 3 | Nature's Wrath | CD: Str save or Restrained 1 min, save each turn | Implemented | B24ANWRA ApplyCondition RESTRAINED | |
| 7 | Aura of Warding | Resist necrotic/psychic/radiant in aura | Implemented | op31 tick | as magic damage |
| 15 | Undying Sentinel | Drop to 1 HP and regain 3×level HP, 1/LR | Approximated | op208 + DownSaver | 3×level heal missing |
| 20 | Elder Champion | 1 min: foes disadv. on saves; 10 HP per turn; action spells as bonus action | Approximated | B24AELDR | Swift Spells missing |

#### Oath of Vengeance (lua/B24XPAL.lua; INQUISITOR, BLACKGUARD kits)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Oath of Vengeance Spells | Bane, Hunter's Mark; Hold Person, Misty Step; Haste, Protection from Energy; Banishment, Dimension Door; Hold Monster, Scrying | Missing | – | |
| 3 | Vow of Enmity | CD: adv. vs one creature 1 min; moves on if it drops | Implemented | B24VVOWE + AdvantageAgainstListener | no transfer |
| 7 | Relentless Avenger | OA hit: speed 0, you move half | No BG form | – | no opportunity attacks |
| 15 | Soul of Vengeance | Reaction: melee attack when the Vowed creature attacks | Missing | – | automatable like Glorious Defense |
| 20 | Avenging Angel | 10 min: fly; aura Wis save or Frightened, attacks vs them adv. | Implemented | B24VANGL tick 30 ft | flight no BG form |

### Ranger

#### Hunter (SRD — lua/B24RANGR.lua; FERALAN kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Hunter's Lore | Know marked target's immunities/resistances/vulnerabilities | Missing | – | could be printed to the log |
| 3 | Hunter's Prey | Colossus Slayer or Horde Breaker, switch on rest | Approximated | Colossus Slayer once/round | Horde Breaker missing |
| 7 | Defensive Tactics | Escape the Horde or Multiattack Defense | Implemented | option B24DTACT | Escape the Horde no effect (no OAs) |
| 11 | Superior Hunter's Prey | Mark damage also to a second creature in 30 ft | Implemented | mark damage listener | |
| 15 | Superior Hunter's Defense | Reaction: resistance to that damage type this turn | Implemented | damage hook: first damage each round | automatic |

#### Beast Master (lua/B24XRNG.lua; BEASTMASTER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Primal Companion | Beast of Land/Sea/Sky, scaling, revive with a slot | Approximated | B24BEAST: wolf B24BST03-19 (lib/b24_fighter.tpa), 1/LR | land only, fixed AC, no revive |
| 7 | Exceptional Training | Beast Dash/Disengage/Dodge/Help; hits deal force | Approximated | +1 magical bite | |
| 11 | Bestial Fury | Beast attacks twice; + Hunter's Mark damage | Approximated | 2 attacks from band 11 | mark damage missing |
| 15 | Share Spells | Self-target spell also affects the beast | Missing | – | "no BG effect"; spell copy to summon possible |

#### Fey Wanderer (lua/B24XRNG.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Dreadful Strikes | +1d4 psychic per hit, once per turn per creature (1d6 at 11) | Implemented | damage listener | once per round total |
| 3 | Fey Wanderer Spells | Charm Person; Misty Step; Summon Fey; Dimension Door; Mislead | Missing | – | most exist in BG/mod |
| 3 | Otherworldly Glamour | +Wis to Cha checks; Deception/Performance/Persuasion | Missing | – | skill grant possible; checks no BG form |
| 7 | Beguiling Twist | Adv. vs charm/fear; reaction to charm/frighten another | Approximated | SaveAdvantageListener | reaction part missing |
| 11 | Fey Reinforcements | Summon Fey free 1/LR | Missing | – | stand-in summon possible (as Illusionist) |
| 15 | Misty Wanderer | Misty Step Wis-mod/LR, bring an ally | Approximated | resource → B24MSTEP | ally missing |

#### Gloom Stalker (lua/B24XRNG.lua; STALKER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Gloom Stalker Spells | Disguise Self; Rope Trick; Fear; Greater Invisibility; Seeming | Missing | – | |
| 3 | Dread Ambusher | +10 ft first turn; Dreadful Strike 2d6 psychic Wis-mod/LR; +Wis initiative | Implemented | round-1 speed; damage listener | initiative no BG form; spends automatically |
| 3 | Umbral Sight | Darkvision; unseen by darkvision | No BG form | – | |
| 7 | Iron Mind | Wis save proficiency | Implemented | SaveProficiencyListener | Int/Cha alternative missing |
| 11 | Stalker's Flurry | Dreadful Strike 2d8 + Sudden Strike or Mass Fear | Approximated | +1 attack after Dreadful Strike | still 2d6, no Mass Fear |
| 15 | Shadowy Dodge | Reaction: disadv. on an attack; teleport 30 ft | Approximated | 50% chance first hit each round misses | |

### Rogue

#### Thief (SRD — lua/B24ROGUE.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Fast Hands | Cunning Action: Sleight of Hand, tools, Utilize | No BG form | – | no bonus actions |
| 3 | Second-Story Work | Climb speed, Dex jumps | No BG form | – | |
| 9 | Supreme Sneak | Cunning Strike "Stealth Attack" (1d6): attack keeps Invisible from Hide | Approximated | SkillBonusListener Stealth +5 | 2014 rule |
| 13 | Use Magic Device | 4 attunements; charge kept on d6=6; any scroll | Approximated | op302 use any item | charge saving missing |
| 17 | Thief's Reflexes | Two turns in the first round | Approximated | improved haste round 1 | |

#### Arcane Trickster (lua/B24XROG.lua, B24XCOM.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Spellcasting | Third caster, Wizard list; Mage Hand + 2 cantrips | Implemented | B24X.AddThirdCaster | Mage Hand no BG form |
| 3 | Mage Hand Legerdemain | Invisible hand steals/disarms at range | No BG form | – | |
| 9 | Magical Ambush | Invisible caster: target has disadv. on save | Implemented | SpellCastListener + SaveAdvantageListener | |
| 13 | Versatile Trickster | Trip Cunning Strike also on a creature by Mage Hand | Missing | – | second-target trip possible (B24RCTRP) |
| 17 | Spell Thief | Reaction: negate spell vs you, steal it 8 h; 1/LR | Missing | – | negation possible as a one-time spell block |

#### Assassin (lua/B24XROG.lua; ASSASIN kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Assassinate | Round 1: adv. vs creatures that haven't acted; Sneak Attack + Rogue level | Approximated | round-1 ATTACK_ADV; first hit + level | any hit, any creature |
| 3 | Assassin's Tools | Disguise and Poisoner's Kits | No BG form | – | |
| 9 | Infiltration Expertise | Masterful Mimicry; Roving Aim (move after Steady Aim) | Missing | – | "no BG effect"; Roving Aim possible (B24STAIM sets speed 0) |
| 13 | Envenom Weapons | Poison Cunning Strike also 2d6 poison | Approximated | every Sneak Attack + 2d6 poison, Con save or ATTACK_DIS | not tied to B24RCPOI; comment stale |
| 17 | Death Strike | Round-1 Sneak Attack: Con save or double damage | Approximated | any round-1 hit | not limited to Sneak Attack |

#### Soulknife (lua/B24XROG.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Psionic Power | Dice (as Psi Warrior), one back on SR | Implemented | resource SOULKNIFE_DICE | |
| 3 | Psi-Bolstered Knack | Die on a failed skill check | No BG form | – | BG reports no failed checks |
| 3 | Psychic Whispers | Telepathy | No BG form | – | |
| 3 | Psychic Blades | 1d6 psychic finesse thrown blade; bonus-action 1d4 second blade | Approximated | B24PSBLA → item B24PSBLD 1 h | no thrown, no second blade |
| 9 | Soul Blades | Homing Strikes (die on miss); Psychic Teleportation | Missing | – | "BG reports no misses", but B24WPN.MissListeners exists; teleport possible |
| 13 | Psychic Veil | Invisible 1 h; 1/LR or die | Implemented | B24PSVEL op20 | |
| 17 | Rend Mind | Blade Sneak Attack: Wis save or Stunned 1 min (save each turn) | Approximated | op45 60 s | no repeated save |

### Sorcerer

#### Draconic Sorcery (SRD — lua/B24SORC.lua; DRAGON_DISCIPLE kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Draconic Spells | Alter Self, Chromatic Orb, Command, Dragon's Breath; Fear, Fly; Arcane Eye, Charm Monster; Legend Lore, Summon Dragon | Missing | – | "follow with the spell updates" |
| 3 | Draconic Resilience | +1 HP per level; AC 10+Dex+Cha | Implemented | B24SORC.lua | |
| 6 | Elemental Affinity | Resist chosen type; +Cha to damage | Implemented | ancestry option + spell damage hook | |
| 14 | Dragon Wings | Fly 60 ft 1 h; 1/LR or 3 SP | Approximated | B24DRWNG: faster, immune web/entangle/grease | no SP restore |
| 18 | Dragon Companion | Summon Dragon free 1/LR | Missing | – | "no BG form"; stand-in summon possible |

#### Aberrant Sorcery (lua/B24XSOR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Psionic Spells | Arms of Hadar, Calm Emotions, Detect Thoughts, Dissonant Whispers, Mind Sliver; Hunger of Hadar, Sending; Black Tentacles, Summon Aberration; Telepathic Bond, Telekinesis | Missing | – | "no BG form" (none exist), but the mod makes new spells elsewhere |
| 3 | Telepathic Speech | Telepathy | No BG form | – | |
| 6 | Psionic Defenses | Resist psychic; adv. vs charm/fear | Implemented | SaveAdvantageListener | |
| 6 | Psionic Sorcery | Psionic Spells for SP, no V/S | Missing | – | needs the spells |
| 14 | Revelation in Flesh | SP, 10 min: one benefit per point (swim, fly, see invisible, squeeze) | Approximated | B24AREVL: see invisible + speed | |
| 18 | Warping Implosion | Teleport 120 ft; Str save 3d10 force + pull; 1/LR or 5 SP | Approximated | B24AWARP around caster | no teleport/pull |

#### Clockwork Sorcery (lua/B24XSOR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Clockwork Spells | Aid, Alarm, Lesser Restoration, PfE&G; Dispel Magic, Prot. from Energy; Freedom of Movement, Summon Construct; Greater Restoration, Wall of Force | Approximated | innate copies 1/LR each (B24XS.CLOCKWORK_SPELLS) | not on slots; 3 spells absent |
| 3 | Restore Balance | Reaction: cancel adv./disadv. on a d20 roll; PB/LR | Approximated | B24CBALN: no adv. vs an ally for a round | |
| 6 | Bastion of Law | 1-5 SP: ward of d8s that absorbs damage | Approximated | B24CBAST temp HP | always spends max points |
| 14 | Trance of Order | 1 min: no adv. vs you; D20 tests min 10 | Approximated | saves only | |
| 18 | Clockwork Cavalcade | Heal 100, repair, dispel spells ≤ 6 | Approximated | B24CCAVL heal only | dispel missing |

#### Wild Magic Sorcery (lua/B24XSOR.lua)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Wild Magic Surge | d20 = 20 after a sorcerer spell → d100 surge table | Approximated | B24XS.SURGES (10 entries) | own short table |
| 3 | Tides of Chaos | Adv. on one D20 test; next spell surges and restores | Approximated | B24WTIDE: adv. attacks and saves for a round | |
| 6 | Bend Luck | Reaction, 1 SP: ±1d4 to another creature's D20 test | Approximated | ally failed save +1d4 | no penalty to foes |
| 14 | Controlled Chaos | Roll the surge twice, choose | Implemented | B24XS.Surge | kinder result |
| 18 | Tamed Surge | Choose the surge after a spell, 1/LR | Implemented | B24WTAME | |

### Warlock (no Warlock class in BG or the mod; nothing implemented)

#### Archfey Patron

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Archfey Spells | Calm Emotions, Faerie Fire, Misty Step, Phantasmal Force, Sleep; Blink, Plant Growth; Dominate Beast, Greater Invisibility; Dominate Person, Seeming | Missing | – | no Warlock class |
| 3 | Steps of the Fey | Free Misty Step Cha-mod/LR + Refreshing/Taunting Step | Missing | – | no Warlock class |
| 6 | Misty Escape | Misty Step as reaction when damaged + Disappearing/Dreadful Step | Missing | – | no Warlock class |
| 10 | Beguiling Defenses | Immune to charm; reaction: halve damage, attacker takes psychic | Missing | – | no Warlock class |
| 14 | Bewitching Magic | Free Misty Step after an Enchant/Illusion spell | Missing | – | no Warlock class |

#### Celestial Patron

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Celestial Spells | Aid, Cure Wounds, Guiding Bolt, Lesser Restoration, Light, Sacred Flame; Daylight, Revivify; Guardian of Faith, Wall of Fire; Greater Restoration, Summon Celestial | Missing | – | no Warlock class |
| 3 | Healing Light | Pool of d6s (1 + level) to heal | Missing | – | no Warlock class |
| 6 | Radiant Soul | Resist radiant; +Cha to radiant/fire spell damage | Missing | – | no Warlock class |
| 10 | Celestial Resilience | Temp HP for you and 5 allies after rests | Missing | – | no Warlock class |
| 14 | Searing Vengeance | On a death save: half HP, radiant burst, blind | Missing | – | no Warlock class |

#### Fiend Patron (SRD)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Fiend Spells | Burning Hands, Command, Scorching Ray, Suggestion; Fireball, Stinking Cloud; Fire Shield, Wall of Fire; Geas, Insect Plague | Missing | – | no Warlock class |
| 3 | Dark One's Blessing | Temp HP Cha + level when a foe drops near you | Missing | – | no Warlock class |
| 6 | Dark One's Own Luck | +d10 to a check or save, Cha-mod/LR | Missing | – | no Warlock class |
| 10 | Fiendish Resilience | Chosen resistance after each rest | Missing | – | no Warlock class |
| 14 | Hurl Through Hell | On hit: Cha save or 8d10 psychic + Incapacitated | Missing | – | no Warlock class |

#### Great Old One Patron

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Great Old One Spells | Detect Thoughts, Dissonant Whispers, Phantasmal Force, Hideous Laughter; Clairvoyance, Hunger of Hadar; Confusion, Summon Aberration; Modify Memory, Telekinesis | Missing | – | no Warlock class |
| 3 | Awakened Mind | Telepathic bond | No BG form | – | telepathy |
| 3 | Psychic Spells | Enchant/Illusion spells deal psychic, no V/S | Missing | – | no Warlock class |
| 6 | Clairvoyant Combatant | Bond: Wis save or adv. for you, disadv. for it | Missing | – | no Warlock class |
| 10 | Eldritch Hex | Hex always prepared; hexed target disadv. on chosen saves | Missing | – | no Warlock class |
| 10 | Thought Shield | Resist psychic; psychic damage reflected | Missing | – | no Warlock class |
| 14 | Create Thrall | Summon Aberration free, bonus temp HP | Missing | – | no Warlock class |

### Wizard

#### Evoker (SRD — lua/B24WIZ.lua; INVOKER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Evocation Savant | Free evocation spells in the spellbook | Missing | – | "no BG effect"; free scribing possible |
| 3 | Potent Cantrip | Half damage on a missed/saved cantrip | Implemented | PotentCantripListener | |
| 6 | Sculpt Spells | 1 + spell level creatures auto-succeed, no damage | Implemented | SaveAutoSuccessListener | every party member, no count |
| 10 | Empowered Evocation | +Int to evocation damage | Implemented | B24SP.DamageListeners | |
| 14 | Overchannel | Max damage; later uses cost escalating d12s | Implemented | innate B24OVCHN | |

#### Abjurer (lua/B24XWIZ.lua; ABJURER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Abjuration Savant | Free abjuration spells in the spellbook | Missing | – | "no BG effect" |
| 3 | Arcane Ward | Ward 2×level+Int; abjuration spells restore 2×level | Implemented | SpellCastListener + damage hook | bonus-action slot recharge missing |
| 6 | Projected Ward | Reaction: ward absorbs damage of a creature in 30 ft | Implemented | wardFor() | automatic |
| 10 | Spell Breaker | Counterspell/Dispel prepared; Dispel as bonus action + PB | Missing | – | "no BG effect"; Dispel Magic exists |
| 14 | Spell Resistance | Adv. on saves vs spells; resist spell damage | Implemented | SaveAdvantageListener + damage hook | |

#### Diviner (lua/B24XWIZ.lua; DIVINER kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Divination Savant | Free divination spells in the spellbook | Missing | – | "no BG effect" |
| 3 | Portent | Two d20s replace any D20 test of a visible creature | Approximated | innate B24PORTN | saves only |
| 6 | Expert Divination | Level 2+ divination spell restores a lower slot | Implemented | op261 | |
| 10 | The Third Eye | Darkvision / read languages / see invisible until rest | Implemented | B24THEYE op193 1 h, 1/SR | only BG-relevant option |
| 14 | Greater Portent | Three dice | Implemented | portentCount | |

#### Illusionist (lua/B24XWIZ.lua; ILLUSIONIST kit)

| Level | Feature | 2024 rule (one short line) | Status | Game mechanic / where | Note |
|---|---|---|---|---|---|
| 3 | Illusion Savant | Free illusion spells in the spellbook | Missing | – | |
| 3 | Improved Illusions | No V components; +60 ft range; bonus-action Minor Illusion | Missing | – | "no BG effect"; casting while silenced/range patch possible |
| 6 | Phantasmal Creatures | Summon Beast and Summon Fey free 1/LR each | Approximated | B24IPHAN: Primal Companion wolf 1 h | Fey missing, full HP |
| 10 | Illusory Self | Reaction: a hit misses; 1/SR or 2nd slot | Implemented | damage listener | |
| 14 | Illusory Reality | Make an illusory object real | No BG form | – | |

---

### Summary

Counts per subclass (one row per feature row above; subclass spell lists count as one row each). No feature is "BG native": everything that works is applied by mod code.

| Class | Subclass | Implemented | Approximated | BG native | No BG form | Missing | Total |
|---|---|---|---|---|---|---|---|
| Barbarian | Path of the Berserker | 2 | 1 | 0 | 0 | 1 | 4 |
| Barbarian | Path of the Wild Heart | 0 | 2 | 0 | 3 | 0 | 5 |
| Barbarian | Path of the World Tree | 1 | 2 | 0 | 0 | 1 | 4 |
| Barbarian | Path of the Zealot | 4 | 1 | 0 | 0 | 0 | 5 |
| **Barbarian** | **class total** | **7** | **6** | **0** | **3** | **2** | **18** |
| Bard | College of Lore | 1 | 3 | 0 | 0 | 0 | 4 |
| Bard | College of Dance | 1 | 1 | 0 | 2 | 0 | 4 |
| Bard | College of Glamour | 1 | 3 | 0 | 0 | 0 | 4 |
| Bard | College of Valor | 2 | 2 | 0 | 0 | 0 | 4 |
| **Bard** | **class total** | **5** | **9** | **0** | **2** | **0** | **16** |
| Cleric | Life Domain | 4 | 0 | 0 | 0 | 1 | 5 |
| Cleric | Light Domain | 2 | 2 | 0 | 0 | 1 | 5 |
| Cleric | Trickery Domain | 0 | 3 | 0 | 0 | 2 | 5 |
| Cleric | War Domain | 2 | 1 | 0 | 0 | 2 | 5 |
| **Cleric** | **class total** | **8** | **6** | **0** | **0** | **6** | **20** |
| Druid | Circle of the Land | 1 | 3 | 0 | 0 | 1 | 5 |
| Druid | Circle of the Moon | 0 | 4 | 0 | 0 | 1 | 5 |
| Druid | Circle of the Sea | 3 | 0 | 0 | 0 | 2 | 5 |
| Druid | Circle of the Stars | 3 | 2 | 0 | 0 | 0 | 5 |
| **Druid** | **class total** | **7** | **9** | **0** | **0** | **4** | **20** |
| Fighter | Champion | 4 | 1 | 0 | 1 | 0 | 6 |
| Fighter | Battle Master | 2 | 2 | 0 | 0 | 2 | 6 |
| Fighter | Eldritch Knight | 2 | 0 | 0 | 1 | 3 | 6 |
| Fighter | Psi Warrior | 4 | 1 | 0 | 1 | 2 | 8 |
| **Fighter** | **class total** | **12** | **4** | **0** | **3** | **7** | **26** |
| Monk | Warrior of the Open Hand | 1 | 2 | 0 | 0 | 1 | 4 |
| Monk | Warrior of Mercy | 4 | 2 | 0 | 0 | 0 | 6 |
| Monk | Warrior of Shadow | 0 | 3 | 0 | 0 | 1 | 4 |
| Monk | Warrior of the Elements | 1 | 2 | 0 | 2 | 0 | 5 |
| **Monk** | **class total** | **6** | **9** | **0** | **2** | **2** | **19** |
| Paladin | Oath of Devotion | 3 | 1 | 0 | 0 | 1 | 5 |
| Paladin | Oath of Glory | 1 | 3 | 0 | 1 | 1 | 6 |
| Paladin | Oath of the Ancients | 2 | 2 | 0 | 0 | 1 | 5 |
| Paladin | Oath of Vengeance | 2 | 0 | 0 | 1 | 2 | 5 |
| **Paladin** | **class total** | **8** | **6** | **0** | **2** | **5** | **21** |
| Ranger | Hunter | 3 | 1 | 0 | 0 | 1 | 5 |
| Ranger | Beast Master | 0 | 3 | 0 | 0 | 1 | 4 |
| Ranger | Fey Wanderer | 1 | 2 | 0 | 0 | 3 | 6 |
| Ranger | Gloom Stalker | 2 | 2 | 0 | 1 | 1 | 6 |
| **Ranger** | **class total** | **6** | **8** | **0** | **1** | **6** | **21** |
| Rogue | Thief | 0 | 3 | 0 | 2 | 0 | 5 |
| Rogue | Arcane Trickster | 2 | 0 | 0 | 1 | 2 | 5 |
| Rogue | Assassin | 0 | 3 | 0 | 1 | 1 | 5 |
| Rogue | Soulknife | 2 | 2 | 0 | 2 | 1 | 7 |
| **Rogue** | **class total** | **4** | **8** | **0** | **6** | **4** | **22** |
| Sorcerer | Draconic Sorcery | 2 | 1 | 0 | 0 | 2 | 5 |
| Sorcerer | Aberrant Sorcery | 1 | 2 | 0 | 1 | 2 | 6 |
| Sorcerer | Clockwork Sorcery | 0 | 5 | 0 | 0 | 0 | 5 |
| Sorcerer | Wild Magic Sorcery | 2 | 3 | 0 | 0 | 0 | 5 |
| **Sorcerer** | **class total** | **5** | **11** | **0** | **1** | **4** | **21** |
| Warlock | Archfey Patron | 0 | 0 | 0 | 0 | 5 | 5 |
| Warlock | Celestial Patron | 0 | 0 | 0 | 0 | 5 | 5 |
| Warlock | Fiend Patron | 0 | 0 | 0 | 0 | 5 | 5 |
| Warlock | Great Old One Patron | 0 | 0 | 0 | 1 | 6 | 7 |
| **Warlock** | **class total** | **0** | **0** | **0** | **1** | **21** | **22** |
| Wizard | Evoker | 4 | 0 | 0 | 0 | 1 | 5 |
| Wizard | Abjurer | 3 | 0 | 0 | 0 | 2 | 5 |
| Wizard | Diviner | 3 | 1 | 0 | 0 | 1 | 5 |
| Wizard | Illusionist | 1 | 1 | 0 | 1 | 2 | 5 |
| **Wizard** | **class total** | **11** | **2** | **0** | **1** | **6** | **20** |
| **All** | **overall (48 subclasses)** | **79** | **78** | **0** | **22** | **67** | **246** |
| **All but Warlock** | **44 subclasses** | **79** | **78** | **0** | **21** | **46** | **224** |


## BG 2024 Rules Mod: coverage of feats, species, backgrounds and core rules

Audit of `C:\BG\bg2024` (commit 70347c2), judged from the code (lua/, lib/, tables/). Status values:
**Implemented** (works as the 2024 rule), **Approximated** (exists, differs), **BG native** (the
unmodified engine already does it the 2024 way), **No BG form** (cannot exist in BG), **Missing**
(feasible in BG, not done).

General notes that apply to many rows:
- "Once per turn" is implemented as "once per 6-second round" (`B24LV.OncePerRound`, 90 ticks).
- Bonus actions and reactions do not exist (design decision, Design Document "Out of scope"); bonus-action
  features are innate abilities, reaction features are passive triggers or nothing.
- BG has no d20 ability checks: skills feed thief-skill percentages, Lore and dialogue ability scores
  (`lua/B24PROF.lua`). Anything that gives advantage on "checks" has no effect.
- Radiant/necrotic/psychic/force map to BG magic damage, thunder to electricity (`B24SPEC.DAMAGE`).

### Feats

#### Origin feats (10)

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Alert | +PB to Initiative; Initiative Swap | Approximated | `B24FEAT.lua` grant ALERT: permanent op189/op190 (+1 casting and weapon speed) | No initiative in real time; the turn-based mode rolls initiative (`B24TURN.lua` rollInitiative) but does not add Alert's PB, and has no swap |
| Crafter | 3 artisan's tools, 20% discount on nonmagical gear, fast crafting | Approximated | `B24PROF.lua` SocialScoreBonus: Charisma +2 while a dialogue/store is open | Tools and crafting have no BG form |
| Healer | Battle Medic (Utilize + healer's kit: target spends a HD, regains roll + PB); Healing Rerolls | Approximated | `B24FEAT.lua` B24HEALR innate (touch), `B24SPELL.lua` B24HEAL rerolls 1s | Battle Medic limited to once per short rest instead of by kit uses |
| Lucky | PB Luck Points per long rest: advantage on a D20 test or disadvantage on an attack against you | Approximated | `B24FEAT.lua` SaveFailedListener: automatic reroll of a failed save while points remain | Saves only, automatic, no use on attacks/against attackers |
| Magic Initiate (Cleric/Druid/Wizard) | 2 cantrips + one level 1 spell (free once per long rest, also with slots), choice of ability | Approximated | `B24FEAT.lua` + `lib/b24_chargen.tpa`: fixed innate Cure Light Wounds / Entangle / Magic Missile, once per long rest | No cantrips, no spell choice, no casting with slots |
| Musician | 3 instruments; after a short/long rest PB allies gain Heroic Inspiration | Implemented | `B24FEAT.lua` encourage() on short and long rest | Instruments: no BG form |
| Savage Attacker | Once per turn, roll weapon damage dice twice, use either | Implemented | `B24FEAT.lua` damage hook, once per round, keeps the higher roll | |
| Skilled | Proficiency in any 3 skills/tools; repeatable | Implemented | `B24FEAT.lua` listener + chargen choice (local B24SKFT) | Only Thieves' Tools exists as a tool |
| Tavern Brawler | Unarmed 1d4+Str, reroll 1s, push 5 ft once per turn, improvised weapons | Implemented | `B24FEAT.lua` B24WPN.DamageListeners for fists (item type 28), op235 push once per round | Improvised weapons: no BG form |
| Tough | +2 HP per character level | Implemented | `B24FEAT.lua` stat listener | Bug: the listener returns early when `B24BG == 0`, so a companion (no background) who takes Tough at an ASI gets nothing |

#### General feats (43, incl. Ability Score Improvement)

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Ability Score Improvement | +2 to one or +1 to two abilities, max 20 | Implemented | `B24LEVEL.lua` ASI popup (asiMode), feats offered in the same popup (`B24GF.Rows`) | |
| Actor | +1 Cha; advantage on Deception/Performance in disguise; mimicry | Approximated | `B24GFEAT.lua` + `B24PROF.lua`: Charisma +2 in dialogues | |
| Athlete | +1 Str/Dex; climb speed, stand up for 5 ft, running jump | Approximated | Ability increase only | Standing from prone could be made cheaper (prone halves speed in `B24COND.lua`) |
| Charger | +1 Str/Dex; Dash +10 ft; after 10 ft straight move, hit: +1d8 or push 10 ft | Approximated | `B24GFEAT.lua`: +1d8 once per round after moving (B24RD.moving) | No push option, no Dash bonus |
| Chef | +1 Con/Wis; short rest +1d8 HP for PB+4 creatures; bolstering treats (temp HP) | Approximated | `B24GFEAT.lua` restBenefits: whole party +1d8 after every rest | No treats; also fires on long rests |
| Crossbow Expert | +1 Dex; ignore Loading; no disadvantage in melee; dual-wield crossbow damage | Approximated | `EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty` for crossbows | Loading/dual-wield parts absent |
| Crusher | +1 Str/Con; push 5 ft once per turn; crit: attacks against target have advantage | Implemented | `B24GFEAT.lua` damage listener (op235, GRANTS_ADV 6 s) | |
| Defensive Duelist | Reaction: +PB AC with a finesse weapon | Approximated | Passive +1 AC with a finesse weapon | Weak stand-in for a reaction |
| Dual Wielder | Extra attack with non-Light weapon; draw two weapons | Missing | Not in `B24GF.FEATS` | BG already lets most one-handed weapons go in the off hand, so the feat would need the Light rule first |
| Durable | +1 Con; advantage on death saves; bonus action: spend HD to heal | Approximated | `B24GFEAT.lua` Speedy Recovery innate once per short rest (adds Con mod) | Defy Death (advantage on death saves) missing although death saves exist (`B24DYING.lua`) |
| Elemental Adept | +1 mental; ignore resistance to one type; 1s count as 2 | Approximated | `B24GFEAT.lua` B24SP.DamageListeners (1 → 2) | Resistance-ignoring part missing |
| Fey Touched | +1 mental; Misty Step + one level 1 Divination/Enchantment spell | Approximated | Innates B24MSTEP and SPPR102 (Command), once per long rest | Fixed spell, no slot casting |
| Grappler | +1 Str/Dex; Punch and Grab; advantage vs grappled; move grappled creature | Approximated | `B24GFEAT.lua` B24GGRAP innate (once per round, save or GRAPPLED), advantage listener | Grapple as an action, not with an unarmed hit |
| Great Weapon Master | +1 Str; +PB damage with Heavy weapons; Hew (bonus attack on crit or kill) | Approximated | Two-handed melee hit: +PB once per round; crit: +1 attack for 6 s | 2024 adds PB on every hit; no extra attack on a kill; Heavy = BG two-handed flag |
| Heavily Armored | +1 Con/Str; heavy armor training | Missing | Excluded ("armor training") | Armor training is class usability in BG; would need an armor-proficiency system |
| Heavy Armor Master | +1 Str/Con; reduce B/P/S damage by PB in heavy armor | Implemented | `B24GFEAT.lua` damage listener while ARMOR_HEAVY | Weapon damage only |
| Inspiring Leader | +1 Wis/Cha; after a rest, 6 creatures gain temp HP = level + mod | Implemented | `B24GFEAT.lua` restBenefits → B24LV.TempHP | |
| Keen Mind | +1 Int; proficiency/expertise in a knowledge skill; Study as bonus action | Approximated | Investigation + History proficiency | |
| Lightly Armored | +1 Str/Dex; light armor + shield training | Missing | Excluded | See Heavily Armored |
| Mage Slayer | +1 Str/Dex; Concentration Breaker; Guarded Mind | Approximated | `B24GFEAT.lua` Guarded Mind (failed Int/Wis/Cha save → success, once per short rest) | Concentration Breaker (disadvantage on the target's concentration save) missing, feasible with `B24CONC.lua` |
| Martial Weapon Training | +1 Str/Dex; martial weapons; light/medium armor and shields | Implemented | `B24.AddWeaponProficiencyListener` | Armor part not modelled |
| Medium Armor Master | +1 Str/Dex; Dex bonus up to +3 in medium armor | Implemented | `B24GFEAT.lua` stat listener on top of the +2 cap in `B24ADV.lua` | |
| Moderately Armored | +1 Str/Dex; medium armor + shield training | Missing | Excluded | See Heavily Armored |
| Mounted Combatant | Mounted bonuses | No BG form | — | No mounts |
| Observant | +1 Int/Wis; proficiency/expertise in Insight/Investigation/Perception; Search as bonus action | Approximated | Perception proficiency | |
| Piercer | +1 Str/Dex; reroll one damage die once per turn; crit +1 die | Approximated | 1s count as 2 for all dice once per round; crit +1 die | Different reroll mechanic |
| Poisoner | +1 Dex/Int; poison ignores resistance; brew poison (Con save or 2d8 + poisoned) | Missing | — | Feasible with BG poison effects (op25) |
| Polearm Master | +1 Str/Dex; bonus attack d4 butt end; Reactive Strike | Approximated | +1 attack per round with halberd, spear, quarterstaff (`B24GFEAT.lua` tick) | Full weapon damage; no reaction |
| Resilient | +1 ability; save proficiency in it | Implemented | `B24.AddSaveProficiencyListener` | |
| Ritual Caster | +1 mental; ritual spells, quick ritual | Missing | — | No ritual casting at all (see Spellcasting) |
| Sentinel | Reactions: stop movement on OA, attack when ally is hit | No BG form | — | Real time has no OA/reactions; feasible only in the turn-based mode (see Action economy) |
| Shadow Touched | +1 mental; Invisibility + one Illusion/Necromancy spell | Approximated | Innate SPWI206 once per long rest | Second spell missing |
| Sharpshooter | +1 Dex; ignore cover; no disadvantage in melee or at long range | Implemented | `ShouldIgnoreMeleeingWithRangedPenalty` | Cover and long range don't exist in BG |
| Shield Master | +1 Str; Shield Bash (push or prone); Interpose Shield (no damage on a Dex save success) | Approximated | Once per round Str save or prone on melee hit; passive Evasion with a shield | Bash: no push option; Evasion also halves on a failed save (more than 2024) |
| Skill Expert | +1 ability; one skill proficiency; one expertise | Missing | — | Easy: the skill/expertise system exists |
| Skulker | +1 Dex; Blindsight 10 ft; advantage on Stealth in combat; misses don't reveal | Approximated | +15% Hide in Shadows / Move Silently | |
| Slasher | +1 Str/Dex; slashing hit −10 ft speed; crit: disadvantage on attacks | Implemented | `B24GFEAT.lua` damage listener (op176, ATTACK_DIS) | |
| Speedy | +1 Dex/Con; +10 ft speed; Dash over difficult terrain; OA disadvantage | Implemented | op176 133% movement | Other parts have no BG form |
| Spell Sniper | +1 mental; ignore cover, no melee disadvantage, +60 ft range | Missing | — | Range increase feasible |
| Telekinetic | +1 mental; Mage Hand; Telekinetic Shove | Implemented | B24GTELE innate once per round | Mage Hand: no BG form |
| Telepathic | +1 mental; telepathy; Detect Thoughts | No BG form | — | |
| War Caster | +1 mental; advantage on concentration; reactive spell; somatic with hands full | Implemented | `B24.AddSaveAdvantageListener` for CONCENTRATION | Other parts have no BG form |
| Weapon Master | +1 Str/Dex; one more weapon mastery | Implemented | `B24.MasteryCount` +1 per pick | |

#### Fighting Style feats (10)

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Archery | +2 to ranged attack rolls | Implemented | `B24LEVEL.lua` STYLES, THAC0 −2 with a ranged ability | |
| Blind Fighting | Blindsight 10 ft | Missing | — | Feasible: ignore blind/invisible disadvantage within 10 ft |
| Defense | +1 AC in armor | Implemented | `B24LEVEL.lua` | |
| Dueling | +2 damage with a one-handed melee weapon and no other weapon | Missing | — | Easy damage listener |
| Great Weapon Fighting | Damage dice 1–2 count as 3 (two-handed/versatile) | Implemented | `B24WPN.RollDiceInto(effect, 3)` | |
| Interception | Reaction: reduce damage to an ally by 1d10 + PB | Missing | — | Could follow the "Glorious Defense" passive-trigger precedent |
| Protection | Reaction with a shield: impose disadvantage on an attack vs adjacent ally | Missing | — | Feasible as a passive DisadvantageAgainst listener |
| Thrown Weapon Fighting | +2 damage with thrown weapons | Missing | — | Easy |
| Two-Weapon Fighting | Add ability modifier to the extra attack's damage | Implemented | `B24WPN.OffhandModifierListeners` | |
| Unarmed Fighting | Unarmed d6 (d8 with free hands), 1d4 to grappled creature | Missing | — | Easy for fists (item type 28) |

#### Epic Boon feats (12)

Level 19 offers the boons in the improvement popup (a boon or another feat); past level 20 (the level cap) each level BG's XP table would have given brings one more choice (B24EPXP.2DA). Boons raise an ability up to 25 (BG's maximum; 2024: 30). High Level Abilities are off (HLA tables at minimum level 99).

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Boon of Combat Prowess | Once per turn turn a miss into a hit | Approximated | `B24GFEAT.lua` AttackAdvantageListener | advantage until the first hit each round (BG reports no misses) |
| Boon of Dimensional Travel | Teleport 30 ft after Attack/Magic action | Implemented | innate B24BDIMT (Dimension Door copy, 30 ft), once per round | |
| Boon of Energy Resistance | Two resistances, redirect damage | Approximated | permanent resistances, four fixed pairs | no redirect; Con +1 |
| Boon of Fate | Add/subtract 2d4 to a D20 test once per short rest | Approximated | SaveFailedListener: +2d4 on a party member's failed save | saves only |
| Boon of Fortitude | +40 HP; extra healing | Approximated | permanent +40 max HP | no extra healing |
| Boon of Irresistible Offense | Ignore B/P/S resistance; d20 roll of 20 adds ability score damage | Approximated | critical hits add Str or Dex score | resistances stay |
| Boon of Recovery | Last Stand (drop to 1 HP once); pool of 10d10 healing | Implemented | DownSaver (half HP, once per long rest), innate B24BRCVR (1d10, 10 uses) | |
| Boon of Skill | Proficiency in all skills, expertise in one | Approximated | GrantedSkillListener: all skills | no Expertise |
| Boon of Speed | +30 ft speed; Disengage as bonus action | Approximated | permanent double movement | no bonus Disengage |
| Boon of Spell Recall | Cast a level 1–4 spell without a slot | Approximated | innate B24BSPRC: a spent slot of level 1-4 back, once per long rest | |
| Boon of the Night Spirit | Invisible in dim light/darkness; resistance in darkness | Approximated | innate B24BNIGH: invisibility once per round | no light levels in BG; no resistance |
| Boon of Truesight | Truesight 60 ft | Approximated | permanent see invisible (op193) | |

### Species

All species: no ability bonuses (`abracead.2da` zeroed, ABRACERQ/ABCLASRQ removed), every species may take every class (`clsrcreq.2da`). Traits are applied once per party member (`B24SPEC.lua` setup). Bodies: Aasimar/Tiefling human; Dragonborn, Goliath, Orc half-orc (`body = R_HALF_ORC`; the Goliath description wrongly says "human").

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Species choice (10 species) | Pick one of 10 species | Implemented | CHARGEN_RACE patched to list `B24SPEC.SPECIES` (`lib/b24_chargen.tpa`), lineage popup | Half-elves count as elves, half-orcs as orcs (companions) |
| No species ability increases | Abilities come from the background | Implemented | `abracead.2da` zeroed | |
| Creature type (Humanoid) | All species are Humanoids | BG native | Party creatures are GENERAL=HUMANOID | |
| Size (Small/Medium) | Gnome, Halfling Small; others Medium (Aasimar/Human/Tiefling choice) | No BG form | — | Engine has no size categories; size-dependent rules (Heavy weapons for Small) not modelled |
| Speed (30 ft; Goliath 35 ft) | Base walking speed | Approximated | All same BG walking speed; combat move limit 3 s/round (`B24ROUND.lua`) | Goliath (and Wood Elf) +5 ft missing |
| Aasimar: Celestial Resistance | Resistance to necrotic and radiant | Approximated | 50% magic damage resistance (op31) | Magic damage ≠ necrotic/radiant only |
| Aasimar: Darkvision 60 ft | See in darkness | Approximated | op63 infravision | Infravision has little BG gameplay effect |
| Aasimar: Healing Hands | Magic action, PB d4 healing, once per long rest | Implemented | Innate B24HEALH (touch) | |
| Aasimar: Light Bearer | Light cantrip | Missing | — | Light cantrip not in the catalog |
| Aasimar: Celestial Revelation (level 3) | Heavenly Wings / Inner Radiance / Necrotic Shroud, 1 minute | Missing | — | Damage riders and fear aura feasible; flight has no BG form |
| Dragonborn: Draconic Ancestry | Choose dragon → damage type | Implemented | Lineage popup (10 dragons) | |
| Dragonborn: Breath Weapon | Replaces one attack; 15-ft cone or 30-ft line; 1d10→4d10; Dex save DC 8+Con+PB; PB uses per long rest | Approximated | `b24_create_breath` (Burning Hands cone, tiers 1/5/11/17), DC with Con (`CASTING_ABILITY_PREFIXES`) | Fixed 2 uses (not PB); cone only; separate action, not inside the Attack action |
| Dragonborn: Damage Resistance | Resistance to ancestry type | Implemented | op27–30/173 50% | |
| Dragonborn: Darkvision 60 ft | | Approximated | Half-orc body's engine infravision | |
| Dragonborn: Draconic Flight (level 5) | Bonus action: fly speed for 10 minutes | No BG form | — | No flying in the engine |
| Dwarf: Darkvision 120 ft | | Approximated | Engine dwarf infravision | |
| Dwarf: Dwarven Resilience | Poison resistance; advantage on saves vs Poisoned | Implemented | op173 50% + save advantage on POISON (op25) | |
| Dwarf: Dwarven Toughness | +1 HP per level | Implemented | Stat listener | |
| Dwarf: Stonecunning | Bonus action: tremorsense 60 ft, PB/long rest | Missing | — | Could approximate as short see-invisible/detection |
| Elf: Darkvision 60 ft | | Approximated | Engine elf infravision | |
| Elf: Elven Lineage (Drow, High, Wood) | Cantrip + level 3/5 spells; Drow 120 ft darkvision, Wood Elf 35 ft | Missing | — | No elf lineage choice at all ("arrives with the spell updates") |
| Elf: Fey Ancestry | Advantage on saves to avoid/end Charmed | Implemented | Save advantage on CHARM (op5/op241) | |
| Elf: Keen Senses | Proficiency in Insight, Perception or Survival | Approximated | Fixed Perception | No choice |
| Elf: Trance | No sleep; magic can't put you to sleep; 4-hour long rest | Implemented | op101 immunity to sleep (op39) | Rest length: no BG form |
| Gnome: Darkvision 60 ft | | Approximated | Engine gnome infravision | |
| Gnome: Gnomish Cunning | Advantage on Int/Wis/Cha saves | Implemented | Save advantage listener | |
| Gnome: Gnomish Lineage (Forest, Rock) | Minor Illusion + Speak with Animals / Mending + Prestidigitation | Missing | — | Mostly utility spells without BG form |
| Goliath: Giant Ancestry | One boon, PB uses per long rest (Cloud's Jaunt, Fire's Burn, Frost's Chill, Hill's Tumble, Stone's Endurance, Storm's Thunder) | Approximated | `B24SPEC.lua` innates B24GL*: Dimension Door copy; next hit +1d10 fire / +1d6 cold & slow / prone; next damage −1d12+Con; next attacker 1d8 | Fixed 2 uses; reactions (Stone, Storm) armed in advance; thunder → electricity |
| Goliath: Large Form (level 5) | Bonus action: Large, advantage on Str checks, +10 ft speed, 10 min | Missing | — | Speed part feasible |
| Goliath: Powerful Build | Advantage to end Grappled; carry as one size larger | Missing | — | Grapple-escape advantage and weight allowance feasible |
| Halfling: Brave | Advantage on saves vs Frightened | Implemented | Save advantage on FEAR (op24) | |
| Halfling: Halfling Nimbleness | Move through larger creatures' space | No BG form | — | Engine pathing |
| Halfling: Luck | Reroll a 1 on a D20 test | Approximated | `B24.AddSaveRerollOnOneListener` | Saves only, not attack rolls |
| Halfling: Naturally Stealthy | Can Hide behind larger creatures | Approximated | +10% Hide in Shadows / Move Silently | Halflings keep engine infravision (2024 halflings have none) |
| Human: Resourceful | Heroic Inspiration after each long rest | Implemented | `B24SPEC.lua` long-rest listener | |
| Human: Skillful | One skill proficiency | Implemented | Chargen choice (local B24SKHUM) | |
| Human: Versatile | One extra origin feat | Implemented | Background popup, local B24FEAT2 | |
| Orc: Adrenaline Rush | Bonus action Dash + temp HP = PB; PB uses per short/long rest | Approximated | Innate B24ADREN: 150% speed for a round + op18 PB HP | Fixed 2 uses, refreshed on long rest only |
| Orc: Darkvision 120 ft | | Approximated | Half-orc body infravision | |
| Orc: Relentless Endurance | Drop to 1 HP instead of 0, once per long rest | Implemented | op208 + `B24.AddDownSaver` | |
| Tiefling: Darkvision 60 ft | | Approximated | op63 | |
| Tiefling: Fiendish Legacy resistance | Poison / necrotic / fire resistance | Approximated | op173 / op31 (magic) / op30 | Chthonic necrotic → magic |
| Tiefling: Fiendish Legacy spells | Cantrip at 1; level 3 and 5 spells | Missing | — | Poison Spray, Chill Touch, Fire Bolt, Ray of Sickness, Hellish Rebuke, etc. |
| Tiefling: Otherworldly Presence | Thaumaturgy cantrip | Missing | — | Utility; little BG form |

### Backgrounds

All 16 PHB 2024 backgrounds exist in `B24CG.BACKGROUNDS` (`lua/B24CHGEN.lua`) with the correct three abilities, origin feat and two skills; skills in `B24FEAT.BACKGROUND_SKILLS`. Ability increases are chosen in the popup (+2/+1 or +1/+1/+1, cap 20). Only Thieves' Tools exists as a tool; no background equipment or 50 GP is handed out (the engine's starting gold and class kit stay).

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Ability increases | +2/+1 or +1/+1/+1 among the background's three abilities | Implemented | Background popup, written into base scores | |
| Skill proficiencies | Two fixed skills | Approximated | `B24FEAT.BACKGROUND_SKILLS` → `B24PROF.lua` | Half of the skills have no BG use (see Core rules) |
| Tool proficiency | One tool | Approximated | Only Thieves' Tools modelled | Others no BG form |
| Origin feat | One fixed origin feat | Implemented | `B24FEAT.ApplyBackground` | |
| Starting equipment / 50 GP | Background equipment package or 50 GP | Missing | — | Feasible: give items or gold at party setup |
| Acolyte | Int/Wis/Cha; Magic Initiate (Cleric); Insight, Religion; Calligrapher's Supplies | Approximated | As above | No tool, no equipment |
| Artisan | Str/Dex/Int; Crafter; Investigation, Persuasion; artisan's tools | Approximated | As above | |
| Charlatan | Dex/Con/Cha; Skilled; Deception, Sleight of Hand; Forgery Kit | Approximated | As above | |
| Criminal | Dex/Con/Int; Alert; Sleight of Hand, Stealth; Thieves' Tools | Approximated | As above | Tool present; only equipment missing |
| Entertainer | Str/Dex/Cha; Musician; Acrobatics, Performance; instrument | Approximated | As above | |
| Farmer | Str/Con/Wis; Tough; Animal Handling, Nature; Carpenter's Tools | Approximated | As above | |
| Guard | Str/Int/Wis; Alert; Athletics, Perception; gaming set | Approximated | As above | |
| Guide | Dex/Con/Wis; Magic Initiate (Druid); Stealth, Survival; Cartographer's Tools | Approximated | As above | |
| Hermit | Con/Wis/Cha; Healer; Medicine, Religion; Herbalism Kit | Approximated | As above | |
| Merchant | Con/Int/Cha; Lucky; Animal Handling, Persuasion; Navigator's Tools | Approximated | As above | |
| Noble | Str/Int/Cha; Skilled; History, Persuasion; gaming set | Approximated | As above | |
| Sage | Con/Int/Wis; Magic Initiate (Wizard); Arcana, History; Calligrapher's Supplies | Approximated | As above | |
| Sailor | Str/Dex/Wis; Tavern Brawler; Acrobatics, Perception; Navigator's Tools | Approximated | As above | |
| Scribe | Dex/Int/Wis; Skilled; Investigation, Perception; Calligrapher's Supplies | Approximated | As above | |
| Soldier | Str/Dex/Con; Savage Attacker; Athletics, Intimidation; gaming set | Approximated | As above | |
| Wayfarer | Dex/Wis/Cha; Lucky; Insight, Stealth; Thieves' Tools | Approximated | As above | Bug: Thieves' Tools missing from `BACKGROUND_SKILLS[16]` although it has a BG form |

### Core rules

| Element | 2024 rule (one short line) | Status | Game mechanic / where | Note |
| --- | --- | --- | --- | --- |
| Ability modifiers | (score − 10) / 2 | Implemented | STRMOD/STRMODEX/DEXMOD/HPCONBON rewritten (`lib/b24_core_tables.tpa`), `B24.AbilityMod` | No 18/xx |
| Ability score generation | Point buy 27 / standard array / 4d6 drop lowest; cap 20 | Implemented | `B24CHGEN.lua` | 4d6 limited to 3 rerolls per visit |
| Proficiency bonus | +2…+6 by total character level | Implemented | THAC0.2DA = 20 − PB, `B24.ProfBonus`; multiclass uses total level (`B24MULTI.lua`) | |
| Ability checks | d20 + mod (+PB) vs DC | Approximated | No d20 checks in BG; skills → thief %, Lore, dialogue scores | Advantage/disadvantage on checks (Poisoned, Exhaustion, many features) can't apply |
| Skills: Stealth, Sleight of Hand, Perception, Investigation | Skill checks | Approximated | Hide/Move Silently, Pick Pockets, find traps, Detect Illusion % = 25 + 5 × bonus | |
| Skills: Arcana, History | Knowledge checks | Approximated | Raise Lore | |
| Skills: Persuasion, Deception, Intimidation, Insight | Social checks | Approximated | Dialogue Cha/Wis/Int raised during dialogues (`B24PROF.lua` social) | |
| Skills: Athletics, Acrobatics | Physical checks | Approximated | Escape grapple only (`B24COND.lua` B24ESCGR) | |
| Skills: Medicine, Nature, Religion, Survival, Animal Handling, Performance | Checks | No BG form | Proficiencies are tracked but nothing reads them | Medicine could stabilize the dying (`B24DYING.lua`) |
| Expertise | Double PB | Implemented | `B24.SkillBonus` | |
| Tool proficiencies | Proficiency with tools | Approximated | Only Thieves' Tools (Open Locks, Set/Disarm Traps; thieving button needs it) | |
| Saving throws | d20 + mod + PB if proficient, six abilities | Implemented | `B24SAVE.lua` op403 screen replaces 2e saves; DC 8 + PB + mod; save-for-half | Per-spell ability via B24SAVES.2DA, else category default |
| Monster saves | Statblock saves | Approximated | Two proficient saves by GENERAL.IDS group (`B24.MonsterSaves`) | |
| Advantage/disadvantage (attacks) | Roll 2d20 | Implemented | `B24ADV.lua`: +5 bump then probabilistic hit filter = exact 2024 chance | Sources: invisible, blinded, poisoned, frightened, prone, restrained, paralyzed, stunned, unconscious, Sap/Vex, features |
| Advantage/disadvantage (saves) | Roll 2d20 | Implemented | `B24.RollD20` in `B24.RollSave` | |
| Heroic Inspiration | Spend to reroll any die just rolled | Approximated | `B24REST.lua`: automatic reroll of a failed save only | Not usable on attack rolls; player can't choose |
| Action: Attack | Weapon attacks, Extra Attack | BG native | Engine attack rounds; Extra Attack via attack table / op1 | |
| Action: Dash | Extra movement | Missing | `B24RD.GrantMovement` exists but only class features use it | Generic innate feasible |
| Action: Disengage | No OA for the turn | No BG form | — | No opportunity attacks |
| Action: Dodge | Attacks against you have disadvantage, Dex save advantage | Missing | Only Patient Defense uses GRANTS_DIS | Generic innate feasible |
| Action: Help | Ally gets advantage | Missing | — | Feasible (ATTACK_ADV / GRANTS_ADV timed keys) |
| Action: Hide | Stealth check DC 15 → Invisible | Approximated | BG Stealth button; given to Stealth-proficient characters (`PROFICIENCY_BUTTONS`) | 2024 lets anyone Hide |
| Action: Influence | Social check | Approximated | Dialogue score bonuses | |
| Action: Magic | Cast a spell / use a magic feature | BG native | Engine casting | |
| Action: Ready | Prepare a triggered action (reaction) | No BG form | — | Real time; possible only in the turn-based mode (not built) |
| Action: Search | Wis check (Perception etc.) | Approximated | Find Traps button via Perception, Detect Illusion via Investigation | |
| Action: Study | Int check | Approximated | Lore via Arcana/History | |
| Action: Utilize | Use an object | BG native | Use item, doors, containers | |
| Bonus actions | One per turn | Approximated | No action types; bonus-action features are innates, often once per round | Design decision; see Action economy |
| Reactions | One per round (Shield, Counterspell, Hellish Rebuke...) | Missing | Reaction features → passive triggers (e.g. Glorious Defense) or "no BG effect"; Shield = +5 AC buff | Feasible in the turn-based mode |
| Opportunity Attacks | Leaving reach provokes | Missing | — | Feasible in the turn-based mode; see below |
| Two-weapon fighting / Light | Extra attack with a second Light weapon, no ability mod to damage | Approximated | 2e TWF penalties removed; off-hand loses positive Str to damage (`B24WPN.lua`) | Light not required; off-hand attack is automatic every round |
| Unarmed strike | 1 + Str bludgeoning | Approximated | BG fists (1d2), monk fists by Martial Arts | |
| Grappling | Unarmed Strike option: save or Grappled | Approximated | Only via the Grappler feat innate (B24GGRAP) | Not available to everyone |
| Shoving | Unarmed Strike option: push 5 ft or prone | Missing | Only feature-based pushes (Tavern Brawler, Crusher, Telekinetic) | |
| Weapon: Ammunition | Needs ammunition | BG native | | |
| Weapon: Finesse | Str or Dex | Implemented | `B24.FinesseBonus` (attack and damage) | |
| Weapon: Heavy | Disadvantage if Str/Dex < 13 | Missing | B24WEAP.2DA has no Heavy column | |
| Weapon: Light | Light weapons for TWF | Approximated | LIGHT column used for proficiency (Monk/Rogue), not TWF | |
| Weapon: Loading | One shot per action | BG native | Crossbows 1 attack per round | |
| Weapon: Range | Normal/long range, disadvantage at long range | Approximated | Item range only | |
| Weapon: Reach | +5 ft reach | Approximated | Engine melee range per item; unchanged | |
| Weapon: Thrown | Throw melee weapons | BG native | Throwing daggers/axes/darts | |
| Weapon: Two-Handed | Needs two hands | BG native | | |
| Weapon: Versatile | Bigger die two-handed | Missing | Left out explicitly (`b24_core_items.tpa`) | |
| Weapon dice / proficiency | 2024 damage dice; Simple/Martial | Implemented | `b24_core_items.tpa` dice; `B24.IsWeaponProficient` | |
| Mastery: Cleave | Hit → attack a 2nd creature within 5 ft, no mod damage, once per turn | Implemented | `B24WPN.lua` scripted second attack once per round | Second target within 5 ft of the attacker |
| Mastery: Graze | Miss → ability-mod damage | Approximated | `B24WPN.OnMiss` | Only misses caused by the mod's disadvantage filter (engine misses aren't reported); always Str |
| Mastery: Nick | Light extra attack inside the Attack action | BG native | Off-hand attack is part of every BG round | |
| Mastery: Push | Push 10 ft (Large or smaller) | Implemented | B24.ForceMove (op124 to the nearest open spot 10 ft away) | Size from the selection circle (B24.Size) |
| Mastery: Sap | Target has disadvantage on next attack | Implemented | `B24WPN.IsSapped` | |
| Mastery: Slow | −10 ft speed | Implemented | op176 67% for a round | |
| Mastery: Topple | Con save or Prone | Implemented | `B24.RollSave` + `B24.KnockProne` | |
| Mastery: Vex | Advantage on next attack vs target | Implemented | `B24WPN.VexTarget` | |
| Armor Class | Armor base AC, Dex caps (medium +2, heavy 0), shield +2 | Implemented | `b24_core_items.tpa`, Dex cap in `B24ADV.lua` | Enchantments kept up to +5 (BG story items; 2024 stops at +3) |
| Armor training | Untrained: disadvantage on Str/Dex tests, no spellcasting | Approximated | BG class usability flags | |
| Heavy armor Str requirement / Stealth disadvantage | −10 ft speed below Str 13/15; disadvantage on Stealth | Missing | — | |
| Cover | +2/+5 AC, total cover | No BG form | — | Engine has only line of sight |
| Critical hits | Natural 20; double the dice | Implemented | `B24WPN.lua` onCritical (flat bonus once); auto-crit vs paralyzed/unconscious within 5 ft | |
| Damage types | 13 types | Approximated | BG types; radiant/necrotic/psychic/force → magic, thunder → electricity | |
| Resistance / vulnerability / immunity | Half / double / none; don't stack | Approximated | BG percentage resistances (50% = resistance) | Percentages can stack; magic resistance (2e) kept |
| Temporary hit points | Separate buffer, don't stack | Approximated | `B24LV.TempHP`: op18 raises max and current HP for a time, replaces older | Healing can refill them |
| Hit points | Max die at 1, fixed average + Con per level | Implemented | HP tables, HPCONBON, `B24MULTI.lua` per-class dice and Con fix | |
| Hit Point Dice | Pool = level; spend on short rest; all back on long rest | Approximated | `B24.HitDice_Spend` (automatic until full) | Multiclasses use one die size (class row) |
| Short rest | 1 hour, spend HD | Approximated | Short Rest innate on the protagonist, 1 hour, no enemies near | Capped at 2 per long rest (house rule); dice spent automatically |
| Long rest | 8 hours: all HP, all HD, −1 Exhaustion | Implemented | Engine rest + `B24_OnPartyRested` | |
| Dying and death saves | 0 HP: Unconscious, death saves, massive damage | Implemented | `B24DYING.lua` (party); monsters die at 0; turn-based: death save at the start of the creature's turn | No stabilizing with Medicine/Help/Spare the Dying (Revivify exists) |
| Exhaustion | −2 per level to D20 tests, −5 ft per level, death at 6 | Approximated | `B24.Exhaustion_Set`: −2 attacks (op54) and saves, speed −17%/level, death at 6 | Nothing in the game inflicts it (BG fatigue unmapped); only Ranger Tireless and long rests lower it |
| Blinded | Can't see; disadvantage on attacks, attacks against have advantage | Implemented | STATE_BLIND; engine −4 removed (`B24COND.lua`) | |
| Charmed | Can't attack charmer; charmer has social advantage | Approximated | BG charm/domination (switches sides); save advantage vs charm | |
| Deafened | Can't hear | Approximated | BG deafness (op80, 2e spell failure) unchanged | |
| Frightened | Disadvantage while source in sight; can't approach | Approximated | BG panic (flees) + attack disadvantage | |
| Grappled | Speed 0; disadvantage vs others; escape DC | Implemented | `B24.ApplyCondition` GRAPPLED, Escape Grapple innate | Applied only by features |
| Incapacitated | No actions/reactions; concentration ends | Approximated | Engine states (stun/sleep/held) block actions; concentration ends on sleep/stun/helpless | Held (paralyzed) doesn't end concentration in `Conc_OnListsResolved` |
| Invisible | Advantage on attacks; attacks against have disadvantage | Implemented | `B24ADV.lua` (INVISIBLE, IMPROVEDINVISIBILITY) | |
| Paralyzed | Incapacitated; Str/Dex saves fail; advantage; auto-crit within 5 ft | Implemented | HELD without web/entangle | |
| Petrified | Incapacitated, resistance to all damage, not dead | Approximated | BG stone death (counts as dead until Greater Restoration or Stone to Flesh); petrifying effects restrain first, petrify after failed Con saves (`B24COND.lua`) | Not resistant, counts as dead |
| Poisoned | Disadvantage on attacks and checks | Implemented | STATE_POISONED → attack disadvantage | Checks n/a |
| Prone | Disadvantage on attacks; adjacent advantage, ranged disadvantage; crawl/stand | Implemented | Spell state PRONE (`B24.KnockProne`), half speed | |
| Restrained | Speed 0; disadvantage on attacks and Dex saves; advantage against | Implemented | Web/entangle/RESTRAINED state | |
| Stunned | Incapacitated; Str/Dex saves fail; advantage against | Implemented | STATE_STUNNED | |
| Unconscious | Paralyzed rules + prone | Implemented | Sleep/helpless: advantage, auto-crit, Str/Dex fail | |
| Speed | 30 ft per turn | Approximated | Combat move limit: 3 s of walking per 6-s round (`B24ROUND.lua`) | Out of combat unlimited |
| Difficult terrain | Double movement cost | No BG form | — | No terrain costs in the engine |
| Climbing, swimming, jumping | Movement modes | No BG form | — | |
| Flying | Fly speed, falling | No BG form | — | No vertical axis |
| Teleportation | Instant relocation | BG native | Dimension Door, Misty Step (B24MSTEP copy) | |
| Darkvision | Dim light as bright within range | Approximated | Engine infravision (op63) | Light levels have almost no BG effect |
| Blindsight | Perceive without sight within range | Missing | — | Feasible as "no blind/invisible disadvantage within X" |
| Truesight | See invisible, through illusions, true forms | Approximated | BG True Seeing spells | |
| Light / obscured areas | Dim light, darkness, heavily obscured = blinded | No BG form | — | No light-level or obscurement rules |
| Concentration | One spell; Con save DC max(10, half damage), max 30; ends when incapacitated | Implemented | `B24CONC.lua` + B24CONC.2DA | State held in a Lua table (not saved with the game) |
| Spell components | V, S, M | Approximated | Engine: Silence blocks casting; no somatic/material rules | |
| Casting time | Action / bonus action / reaction / long | Approximated | Spell casting speed set to 1 except long-cast spells; damage while casting → Con save (`B24_CASTDISRUPT`) | 2024 has no casting disruption |
| Ritual casting | Cast ritual spells without a slot (+10 min) | Missing | Wizard "Ritual Adept (no rituals in BG)" | |
| Upcasting | Higher slot, stronger effect | Approximated | Option A: copies per higher slot (B24UPCST.2DA, arcane) | Priest lists stop at 7 in the engine |
| One spell with a slot per turn | Bonus-action spell rule | Approximated | Engine casts one spell per round (casting speed) | Haste/Alacrity-style effects can exceed it |
| Spell save DC / spell attack | 8 + PB + mod; PB + mod | Implemented | `B24.SpellSaveDC`, B24SATK spell attacks | |
| Cantrips | At will, scale at 5/11/17 | Implemented | `B24SPELL.lua` B24CANT innates | Utility cantrips missing from catalog |
| Prepared spells | Prepared list, cast from any slot | Approximated | Engine memorization per slot | |
| Initiative | d20 + Dex at start of combat | Approximated | Turn-based mode only (`B24TURN.lua`); real time has none | No Alert PB, no advantage features (Remarkable Athlete), ties by Dex |
| Surprise | Surprised: disadvantage on initiative | Missing | — | Feasible in the turn-based mode |
| Rounds and turns | 6-s rounds, sequential turns | Approximated | Real time with auto-pause per round (`B24ROUND.lua`), optional turn-based mode | |
| Creature types (14) | Aberration, Beast, Celestial, Construct, Dragon, Elemental, Fey, Fiend, Giant, Humanoid, Monstrosity, Ooze, Plant, Undead | Approximated | Only GENERAL.IDS (HUMANOID, ANIMAL, MONSTER, UNDEAD, GIANTHUMANOID, PLANT) read; RACE.IDS not mapped | Used for monster save proficiencies and Turn Undead only |
| Undead-dependent features | Turn/Sear Undead | Implemented | `B24CLER.lua` isUndead (GENERAL = 4) | |
| Fiend/undead-dependent features | Divine Smite +1d8 vs fiends/undead, Protection from Evil and Good types, Divine Sense types | Missing | Smite dice ignore type; PfE keeps BG's alignment-based version | Needs a RACE.IDS → 2024 type map |
| Humanoid-only spells | Charm/Hold Person etc. | BG native | Engine target checks of the spells | |
| Sizes | Tiny…Gargantuan; size limits (Push, grapple, Heavy for Small) | Approximated | `B24.Size` (B24CORE.lua) | From the selection circle: Medium up to 3, Large up to 5, Huge up to 9, Gargantuan above; Small and Tiny not told apart from Medium. Pushes and pulls (B24.ForceMove) check the 2024 limits |
| Multiclassing | Level by level any class; total level; 13 prerequisites; combined slots | Approximated | Dual-class → multiclass, BG multiclasses with 2024 math, level-ups held to XP, class choice per level-up (`B24MULTI.lua`) | Only BG class combinations, one switch for dual-class; wizard/priest slots stay separate |
| Carrying capacity | Str × 15 lb | Approximated | BG STRMOD weight column unchanged | |

### Action economy in the turn-based mode

What `lua/B24TURN.lua` does: when the protagonist's Turn-Based Combat switch is on (global `B24_TURNS`), every combatant rolls d20 + Dex, and exactly one creature acts while the engine's Time Stop (`m_nTimeStopCaster/m_nTimeStop`) freezes everyone else. A turn ends when the creature's action finishes (`turn.started` and action ID back to 0), when an attack cycle wraps after a swing (a full BG attack round, so Extra Attack fits in one turn), on End Turn, after 180 ticks (two rounds), or at once if it can't act. Movement per turn comes from `B24RD.StartTurn` / `TrackTurn` (3 s of walking).

Consequences for 2024 action economy:
- **One action per turn, movement folded in.** A move order is itself an action: when the walk ends, `turnDone` sees action 0 and ends the turn. Move-then-act only works when the action includes the approach (attack or cast at a target out of range). Bonus actions do not exist: using an innate (Second Wind, Cunning Action, Adrenaline Rush) is a spell action and ends the turn just like a main action; Action Surge (an innate) ends the turn and its extra attacks land in the next one.
- **Bonus actions: feasible.** Keep a per-turn budget in `B24TB.turn` (`action`, `bonus`, `moveTicks`). Mark bonus-action resources with a table of resrefs (B24SWIND, B24ASURG as free, cantrip/flurry innates, off-hand attack...). In `turnDone`, when the finished action was a bonus-action resref and the bonus is unused, set `bonus = true` and reset `turn.started` instead of ending the turn; a second bonus action is cancelled in the started-action listener (`EEex_Action_AddSpriteStartedActionListener`). A move order should likewise only spend movement (end the turn when movement and action are both spent, or on End Turn). This is bookkeeping on top of the existing structure, no engine change.
- **Reactions: feasible with Lua-resolved reactions.** All other creatures are frozen during a turn, so a reaction can't be a real engine action without handing the Time Stop over. Two ways: (a) resolve reactions in Lua inside the hooks that already run during the turn (hit filter `EEex_Sprite_AddBlockWeaponHitListener` for Shield/Defensive Duelist/Protection/Interception, damage hooks for Hellish Rebuke, Stone's/Storm's Thunder, `B24.RollSave` for Counterspell-like checks), with a per-round `reactionUsed` flag reset at the creature's turn start; for party members either automatic rules (as the mod already does for Indomitable/Heroic Inspiration) or a pause plus a yes/no popup; (b) briefly hand the freeze to the reacting creature (`freeze(reactor)`), queue its attack/spell, then return to the mover — closer to 2024, but the engine attack animation and target selection make it fragile.
- **Opportunity Attacks: feasible via (a).** `B24RD.TrackTurn` already samples the moving creature's position several times a second; when it leaves the 5-ft reach (`B24.Adjacent`, 80 units) of a hostile that has its reaction, roll a scripted melee attack (d20 + attack bonus vs AC, weapon dice via op12) exactly like the Cleave mastery code in `B24WPN.lua`, and apply damage. Disengage (an innate that sets a per-turn flag), Sentinel (speed 0 on hit), Polearm Master's Reactive Strike, Mobile-style effects and War Caster's reactive spell then follow naturally.
- **Ready, surprise, initiative features:** Ready = a stored trigger checked in the same position/turn hooks; surprise = disadvantage on the initiative roll for creatures that hadn't seen the party (`rollInitiative`); Alert (+PB, swap) and Remarkable Athlete (advantage) are one-line additions to `rollInitiative`.
- In real-time play (the default) none of this applies; the design document keeps action economy out of scope there.

### Summary

| Section | Implemented | Approximated | BG native | No BG form | Missing | Total |
| --- | --- | --- | --- | --- | --- | --- |
| Feats (10 origin, 43 general, 10 styles, 12 boons) | 22 | 24 | 0 | 3 | 26 | 75 |
| Species | 15 | 16 | 1 | 3 | 9 | 44 |
| Backgrounds | 2 | 18 | 0 | 0 | 1 | 21 |
| Core rules | 33 | 45 | 10 | 9 | 13 | 110 |
| **Total** | **72** | **103** | **11** | **15** | **49** | **250** |

Feats by group: origin 5 Implemented / 5 Approximated; general 13 / 19 / 8 Missing / 3 No BG form; fighting styles 4 Implemented / 6 Missing; epic boons 12 Missing.

#### Most important Missing or weak Approximated items

1. ~~Epic Boons~~: added 2026-10-28 (B24GFEAT.lua), with the level cap at 20 and no HLAs.
2. **Reactions and Opportunity Attacks**: absent; the turn-based mode could carry them (see above). Sentinel, Interception, Protection, Shield/Counterspell as reactions depend on it.
3. **Six of ten Fighting Styles missing**: Dueling, Thrown Weapon, Unarmed, Blind Fighting (easy), Interception, Protection (reaction stand-ins).
4. **Generic actions Dash, Dodge, Help, and Shove/Grapple for everyone**: only class features or feats grant them, though the mechanics (`B24RD.GrantMovement`, GRANTS_DIS, `B24.ApplyCondition`) exist.
5. **Species spells and level-gated traits**: Elf and Gnome lineages, Tiefling legacy spells, Aasimar Light Bearer and Celestial Revelation, Goliath Large Form; uses fixed at 2 instead of PB (Breath Weapon, Giant Ancestry, Adrenaline Rush).
6. **Heroic Inspiration, Lucky, Halfling Luck only for saves**: no use on attack rolls; Inspiration is spent automatically.
7. **Missing general feats**: Skill Expert, Spell Sniper, Poisoner, Ritual Caster (easy to medium); the armor-training feats need an armor-proficiency system.
8. **Exhaustion has no source**: the mechanic works, but nothing in the game inflicts it (BG fatigue is not mapped).
9. **Creature types**: only GENERAL.IDS groups are used; Divine Smite's fiend/undead bonus and type-based effects need a RACE.IDS → 2024 type map.
10. **Weapon properties Heavy and Versatile, armor Str requirement/Stealth**: not modelled; Graze fires only on mod-caused misses.

Bugs found on the way: Tough taken at an ASI does nothing for characters without a background (`B24FEAT.lua` stat listener checks `B24BG == 0`); Wayfarer lacks Thieves' Tools (`B24FEAT.BACKGROUND_SKILLS[16]`); Goliath description says "Body: human" but the code uses the half-orc body (and so gives it infravision); concentration is kept in a Lua table and is lost on save/load.


## PHB 2024 spell coverage — BG 2024 Rules Mod

Every spell of the PHB 2024 class spell lists (cantrips and levels 1–9; Bard, Cleric, Druid,
Paladin, Ranger, Sorcerer, Warlock, Wizard) and how the game has it with the mod installed.
Sources: `lua/B24SPELL.lua`, `tables/b24spell.2da`, `lib/b24_spells.tpa`, the class Lua files, and
the installed spell files of C:\BG\BGEE and C:\BG\BG2EE (names, levels, priest list flags,
HIDESPL.2DA, B24MOVED.2DA, descriptions). 2024 class lists are from the PHB 2024 (from memory;
a few list memberships may be off by one class).

**Status**

- **Implemented** — the mod's own spell, or a BG spell whose effect the mod changed to the 2024 rules.
- **Approximated** — present, but it plays differently from 2024 (mostly the 2e effect kept; the
  catalog still gives it the 2024 level, save ability, concentration and casting time).
- **BG native** — the mod leaves the BG effect alone (apart from catalog level/save/concentration/name),
  and that already matches 2024 closely.
- **No BG form** — exploration, social, travel, planar, light, 3D movement, reactions or dynamic
  walls: nothing for it to do in the Infinity Engine.
- **Missing** — would work in BG, but the game has no such spell.

**Columns**

- *2024 lists*: B Bard, C Cleric, D Druid, P Paladin, R Ranger, S Sorcerer, Wl Warlock, Wz Wizard.
- *In game as*: resref of the original BG spell (catalog-relevelled spells are re-filed under a new
  name, e.g. Hold Person SPWI306 → SPWI227; B24MOVED.2DA has the full mapping) or the mod's spell.
- *BG:EE / BG2:EE*: every catalogued BG spell file exists in both games (BG:EE ships the BG2 spell
  set). † = levels 7–9: present in BG:EE too, but BG:EE's XP cap (500,000) keeps casters at about
  6th-level wizard / 5th-level cleric spells.
- *Lists* (in Note): the classes that can actually get the spell in game, compared with 2024.
  How the game files spells to classes:
  - Arcane (SPWI) spells are one shared list: Wizards, Sorcerers and Bards all see every non-hidden
    mage spell (Bards up to 9th level with the mod's slot table). The catalog's LISTS column for
    arcane spells is only used by the Wizard's Spellbook choice and Magical Secrets; it does not
    keep Sorcerers or Bards off Wizard-only spells.
  - Priest (SPPR) spells use the cleric/druid exclusion flags the catalog writes; Paladins get every
    Cleric-flagged spell and Rangers every Druid-flagged spell up to 5th level (engine-shared lists).
  - Warlock: there is no Warlock class in BG; Wl is ignored in the list check.
  - The mod's new arcane spells are learned automatically by the classes named in
    B24SP.NEW_ARCANE; bard copies of healing spells exist for Bards only.

### Cantrips (34)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Acid Splash | S Wz | Implemented | B24CACID (mod cantrip) | both | Dex save 1d6, scales at 5/11/17; one target (2024: 5-ft sphere, up to 2 creatures). Lists ok |
| Blade Ward | B S Wl Wz | Missing | – | – | Simple buff (−1d4 to attacks against you); fits the cantrip runtime |
| Chill Touch | S Wl Wz | Implemented | B24CCHIL (mod cantrip; BG SPWI117 dropped) | both | Melee spell attack 1d10 (magic = necrotic); no "can't regain HP" rider. Lists ok |
| Dancing Lights | B S Wz | No BG form | SPWI126 exists (BG:EE, hidden by the game) | BG:EE file only (hidden) | Light has no rules effect in BG |
| Druidcraft | D | No BG form | – | – | Cosmetic |
| Eldritch Blast | Wl | Missing | – | – | No Warlock class in BG (Warlock-only) |
| Elementalism | D S Wz | No BG form | – | – | Cosmetic/utility |
| Fire Bolt | S Wz | Implemented | B24CFIRE (mod cantrip) | both | Spell attack 1d10 fire. Lists ok |
| Friends | B S Wl Wz | Approximated | SPWI107 Friends (catalog KEEP) | both | 2e spell kept as a level-1 slot spell (+Charisma), not a cantrip. Lists ok |
| Guidance | C D | Missing | – | – | +1d4 to a check; Asset list lists it as open (utility cantrips) |
| Light | B C S Wz | No BG form | – | – | Light has no rules effect (Aasimar trait text promises it) |
| Mage Hand | B S Wl Wz | No BG form | – | – | Object manipulation |
| Mending | B C D S Wz | No BG form | – | – | Repairs objects |
| Message | B D S Wz | No BG form | – | – | Communication |
| Mind Sliver | S Wl Wz | Missing | – | – | Int save 1d6 psychic, −1d4 to next save: fits the cantrip runtime |
| Minor Illusion | B S Wl Wz | No BG form | – | – | Exploration/deception |
| Poison Spray | D S Wl Wz | Implemented | B24CPOIS (mod cantrip) | both | Ranged spell attack 1d12 poison. Lists ok |
| Prestidigitation | B S Wl Wz | No BG form | – | – | Cosmetic |
| Produce Flame | D | Implemented | B24CFLAM (mod cantrip) | both | Spell attack 1d8 fire (light part dropped). Lists ok |
| Ray of Frost | S Wz | Implemented | B24CFROS (mod cantrip) | both | Spell attack 1d8 cold, slowed 1 round. Lists ok |
| Resistance | C D | Missing | – | – | Reduce one damage type by 1d4: doable |
| Sacred Flame | C | Implemented | B24CSACR (mod cantrip) | both | Dex save 1d8 radiant (magic). Lists ok |
| Shillelagh | D | Missing | SPPR110 Shillelagh (2e level 1) is DROPped | – | A 2024 cantrip version (Wis for club/staff, d8+ force) would fit |
| Shocking Grasp | S Wz | Implemented | B24CSHOC (mod cantrip; BG SPWI115 dropped) | both | Melee spell attack 1d8 lightning (no OAs in BG). Lists ok |
| Sorcerous Burst | S | Approximated | B24CBURS (mod cantrip) | both | 1d8 fire only: no damage-type choice, no exploding 8s. Lists ok |
| Spare the Dying | C D | Missing | – | – | The mod has 2024 death saves (B24DYING): a stabilise cantrip fits |
| Starry Wisp | B D | Implemented | B24CWISP (mod cantrip) | both | Spell attack 1d8 radiant; no anti-invisibility rider. Lists ok |
| Thaumaturgy | C | No BG form | – | – | Cosmetic (Tiefling trait text promises it) |
| Thorn Whip | D | Approximated | B24CTHRN (mod cantrip) | both | Spell attack 1d6 piercing, range 20; no pull. Lists ok |
| Thunderclap | B D S Wl Wz | Missing | – | – | Con save 1d6 around the caster: same shape as Word of Radiance |
| Toll the Dead | C Wl Wz | Implemented | B24CTOLL (mod cantrip) | both | Wis save 1d8, 1d12 if hurt. Lists ok |
| True Strike | B S Wl Wz | Missing | – | – | Weapon attack with casting ability (+radiant at 5): weapon-damage hook exists |
| Vicious Mockery | B | Implemented | B24CMOCK (mod cantrip) | both | Wis save 1d6 psychic + disadvantage on next attack. Lists ok |
| Word of Radiance | C | Implemented | B24CWORD (mod cantrip) | both | Con save 1d6 to enemies around the caster. Lists ok |

### Level 1 (64)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Alarm | R Wz | No BG form | – | – | Camp/exploration; rest ambushes are scripted |
| Animal Friendship | B D R | Missing | – | – | Charm a beast: doable |
| Armor of Agathys | Wl | Missing | – | – | Warlock-only |
| Arms of Hadar | Wl | Missing | – | – | Warlock-only |
| Bane | B C | Approximated | SPPR113 | both | One target, −2 flat to attacks and saves (2024: −1d4, up to 3), Cha save (`b24_spells.tpa`), conc. Lists: +P −B |
| Bless | C P | Approximated | SPPR101 | both | +2 flat to attacks and saves (2024: +1d4), conc; BG area of allies. Lists ok |
| Burning Hands | S Wz | Implemented | SPWI103 | both | 3d6 Dex half, upcast +1d6 (arcane copies). Lists: +B |
| Charm Person | B D S Wl Wz | Approximated | SPWI104; SPPR204 (druid, re-filed at L1) | both | Wis save; BG charm turns the target into a temporary ally (2024: only friendly). Lists: +R |
| Chromatic Orb | S Wz | Approximated | SPWI118 | both | 3d8 (+1d8 upcast) but no spell attack, BG's level-based side effects, no leap. Lists: +B |
| Color Spray | B S Wz | Approximated | SPWI105 | both | Con save; 2e unconscious 5 rounds for ≤4 HD (2024: blinded 1 round, no HD cap). Lists ok |
| Command | B C P | Approximated | SPPR102 | both | Wis save, no hit dice limit; "die" only (asleep 1 round), no other commands. Lists: −B |
| Compelled Duel | P | Missing | – | – | Paladin spells not done |
| Comprehend Languages | B S Wl Wz | No BG form | – | – | Dialogue/text only |
| Create or Destroy Water | C D | No BG form | – | – | Utility |
| Cure Wounds | B C D P R | Implemented | SPPR103; B24CWBRD (bard copy) | both | 2d8 + mod, priest upcast copies to L7; bard copy has no upcast. Lists ok |
| Detect Evil and Good | C P | Approximated | SPPR104 | both | 2e: evil creatures nearby glow (no celestials/fiends/undead sense, no consecrated places). Lists ok |
| Detect Magic | B C D P R S Wz | No BG form | – | – | No magic auras to sense (items are identified otherwise) |
| Detect Poison and Disease | C D P R | No BG form | – | – | Exploration |
| Disguise Self | B S Wz | No BG form | – | – | Social |
| Dissonant Whispers | B | Missing | – | – | 3d6 psychic Wis save + flee: doable |
| Divine Favor | P | Missing | – | – | +1d4 radiant on weapon hits: weapon-damage hook exists |
| Divine Smite | P | Approximated | Paladin's Smite feature (B24SMITE toggle) | both | Class feature: uses per long rest instead of slots, 2d8 (+dice by Paladin level), first melee hit per round. Lists ok |
| Ensnaring Strike | R | Missing | – | – | Ranger spells not done |
| Entangle | D R | BG native | SPPR105 | both | Str save, conc. Lists ok |
| Expeditious Retreat | S Wl Wz | Missing | – | – | Dash-type speed buff: doable |
| Faerie Fire | B D | Missing | SPPR116 Faerie Fire (BG:EE only; hidden by the game, not in the catalog) | BG:EE file only (hidden) | Advantage + outlines invisible creatures: doable |
| False Life | S Wz | Missing | – | – | Temporary hit points: doable |
| Feather Fall | B S Wz | No BG form | – | – | No falling |
| Find Familiar | Wz | BG native | SPWI123 | both | BG familiar (protagonist only); long cast kept. Lists: +B +S |
| Fog Cloud | D R S Wz | Missing | – | – | Obscuring cloud: doable |
| Goodberry | D R | BG native | SPPR207 (re-filed at L1) | both | Berries heal 1 HP each. Lists ok |
| Grease | S Wz | Approximated | SPWI101 | both | Dex save; 2e slips/slows movement instead of prone. Lists: +B |
| Guiding Bolt | C | Implemented | B24GBOLT (mod spell, priest list) | both | 4d6 radiant spell attack, next attack has advantage; no upcast. Lists: +P |
| Hail of Thorns | R | Missing | – | – | Ranger spells not done |
| Healing Word | B C D | Implemented | B24HWORD (priest), B24HWBRD (bard copy) | both | 2d4 + mod at range; action, not bonus action; no upcast. Lists: +P +R |
| Hellish Rebuke | Wl | Missing | – | – | Reaction; Warlock-only (Tiefling legacy promises it) |
| Heroism | B P | Missing | – | – | Fear immunity + temp HP each round: doable |
| Hex | Wl | Missing | – | – | Warlock-only |
| Hunter's Mark | R | Approximated | Ranger Favored Enemy innate (B24HMARK) | both | 2–6 free uses per long rest, +1d6 on weapon hits, 1 hour, no concentration, no slot casting. Lists ok |
| Ice Knife | D S Wz | Missing | – | – | Attack + small Dex-save burst: doable |
| Identify | B Wz | BG native | SPWI110 | both | Long cast kept. Lists: +S |
| Illusory Script | B Wl Wz | No BG form | – | – | Text |
| Inflict Wounds | C | Approximated | SPPR414 (re-filed at L1) | both | Mod made it the 2014 version (melee spell attack 3d10); 2024: Con save 2d10, half on success; upcast copies. Lists: +P |
| Jump | D R S Wz | No BG form | – | – | No vertical movement |
| Longstrider | B D R Wz | Missing | – | – | +10 ft speed: trivial |
| Mage Armor | S Wz | Implemented | SPWI102 | both | Base AC 13 + Dex. Lists: +B |
| Magic Missile | S Wz | Approximated | SPWI112 | both | 2e: 1–5 missiles by caster level (1d4+1 each), not 3 darts +1 per slot level. Lists: +B |
| Protection from Evil and Good | C P Wl Wz | Approximated | SPWI113, SPPR107 | both | Conc; 2e −2 to evil attackers, blocks summoned demons (2024: disadvantage from 6 creature types, charm/fear immunity). Lists: +B +S |
| Purify Food and Drink | C D P | No BG form | – | – | Utility |
| Ray of Sickness | S Wz | Missing | – | – | Spell attack 2d8 poison + poisoned: doable |
| Sanctuary | C | Approximated | SPPR109 | both | 2e: enemies ignore the target (like invisibility); Wis save added. Lists: +P |
| Searing Smite | P | Missing | – | – | Paladin spells not done |
| Shield | S Wz | Implemented | SPWI114 | both | +5 AC for a round, MM immunity; cast as an action (no reactions). Lists: +B |
| Shield of Faith | C P | Approximated | SPPR111 (BG Armor of Faith) | both | 2e: absorbs 5–25% of damage (2024: +2 AC); conc. Lists ok |
| Silent Image | B S Wz | No BG form | – | – | Illusion/deception |
| Sleep | B S Wz | Approximated | SPWI116 | both | Wis save, conc; 2e sleep (HD caps) instead of incapacitated → unconscious. Lists ok |
| Speak with Animals | B D R | No BG form | – | – | Dialogue |
| Tasha's Hideous Laughter | B Wl Wz | Missing | – | – | Prone + incapacitated, Wis save: doable |
| Tenser's Floating Disk | Wz | No BG form | – | – | Carrying |
| Thunderous Smite | P | Missing | – | – | Paladin spells not done |
| Thunderwave | B D S Wz | Implemented | B24THWAV (arcane, auto-learned), B24THWVD (druid) | both | 2d8 Con half + push, around the caster (2024: 15-ft cube); no upcast. Lists: +R |
| Unseen Servant | B Wl Wz | No BG form | – | – | Utility |
| Witch Bolt | S Wl Wz | Missing | – | – | Doable (sustained damage) |
| Wrathful Smite | P | Missing | – | – | Paladin spells not done |

### Level 2 (62)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Aid | B C D P R | Approximated | SPPR201 | both | +5 max and current HP for 8 hours, one target (2024: up to 3; no upcasting). Lists: −B |
| Alter Self | S Wz | Missing | – | – | Natural weapons option doable; rest exploration |
| Animal Messenger | B D R | No BG form | – | – | Communication |
| Arcane Lock | Wz | No BG form | – | – | Doors |
| Arcane Vigor | S Wz | Missing | – | – | Spend Hit Dice to heal: doable with the mod's rests |
| Augury | C D Wz | No BG form | – | – | Divination |
| Barkskin | D R | Implemented | SPPR202 | both | AC can't be below 17, no save bonuses, no conc. Lists ok |
| Blindness/Deafness | B C S Wz | Approximated | SPWI106 (re-filed at L2) | both | Con save; blinds only; repeat save each turn (`B24COND.lua`). Lists: −C |
| Blur | S Wz | Implemented | SPWI201 | both | Attacks against you have disadvantage, conc. Lists: +B |
| Calm Emotions | B C | Missing | – | – | Suppress charm/fear in an area: doable |
| Cloud of Daggers | B S Wl Wz | Missing | – | – | Damage zone: doable |
| Continual Flame | C D Wz | No BG form | – | – | Light |
| Cordon of Arrows | R | Missing | – | – | Ranger spells not done |
| Crown of Madness | B S Wl Wz | Missing | – | – | Charm-to-attack: doable |
| Darkness | S Wl Wz | Missing | SPWI228 Darkness 15' Radius (BG:EE, hidden by the game) | BG:EE file only (hidden) | Blinding sphere: doable |
| Darkvision | D R S Wz | BG native | SPWI111 (re-filed at L2) | both | Infravision. Lists: +B −D −R |
| Detect Thoughts | B S Wz | No BG form | – | – | Dialogue |
| Dragon's Breath | S Wz | Missing | – | – | (BG2 SPWI922 Dragon's Breath is an unrelated HLA) |
| Enhance Ability | B C D R S Wz | Approximated | SPWI214 (BG Strength) | both | 2e Strength spell: Str becomes 18/50 (2024: advantage on one ability's checks, Bear's Endurance temp HP). Lists: −C −D −R |
| Enlarge/Reduce | B D S Wz | Implemented | B24ENLRG, B24REDUC (+ druid copies) | both | Two spells (BG has no choice at casting); size step (B24.Size), Str save adv/disadv, weapon +1d4/-1d4; no Strength checks or bigger look in BG |
| Enthrall | B Wl | No BG form | – | – | Perception debuff, social |
| Find Steed | P | Missing | – | – | Paladin "Faithful Steed (not yet)"; no mounts in BG, only as a summon |
| Find Traps | C D R | BG native | SPPR205 | both | Reveals traps (more than 2024's sense). Lists: +P |
| Flame Blade | D S | Approximated | SPPR206 | both | 2e flaming weapon (1d4 + fire) instead of 3d6 melee spell attack; conc. Lists: +R −S |
| Flaming Sphere | D S Wz | Missing | – | – | Moving damage sphere: doable as a summon |
| Gentle Repose | C P Wz | No BG form | – | – | Corpses |
| Gust of Wind | D R S Wz | Missing | – | – | Push in a line: doable |
| Heat Metal | B D | Missing | – | – | Damage over time: doable |
| Hold Person | B C D S Wl Wz | BG native | SPWI306 (re-filed at L2), SPPR208 | both | Wis save, paralysed, conc; repeat save each turn (`B24COND.lua`). Lists: +P +R |
| Invisibility | B S Wl Wz | BG native | SPWI206 | both | Conc added. Lists ok |
| Knock | B S Wz | BG native | SPWI207 | both | Lists ok |
| Lesser Restoration | B C D P R | BG native | SPPR417 (re-filed at L2) | both | Lists: −B |
| Levitate | S Wz | No BG form | – | – | Vertical movement |
| Locate Animals or Plants | B D R | No BG form | – | – | Exploration |
| Locate Object | B C D P R Wz | No BG form | – | – | Exploration |
| Magic Mouth | B Wz | No BG form | – | – | Utility |
| Magic Weapon | P R S Wz | Approximated | SPWI417 (re-filed at L2) | both | 2e: wielded weapons count as +3 for what they can hit (2024: +1 attack and damage, more upcast). Lists: +B −P −R |
| Melf's Acid Arrow | Wz | Approximated | SPWI211 (Acid Arrow) | both | 2e: 2d4 + 2d4 per round by caster level, no attack roll (2024: attack 4d4 + 2d4, half on miss). Lists: +B +S |
| Mind Spike | S Wl Wz | Missing | – | – | Wis save 3d8 psychic: doable |
| Mirror Image | B S Wl Wz | BG native | SPWI212 | both | BG images absorb attacks. Lists ok |
| Misty Step | S Wl Wz | Implemented | B24MSTEP (Dimension Door copy at L2; auto-learned) | both | Teleport; an action, not a bonus action; also Moonlight Step/feat. Lists ok |
| Moonbeam | D | Missing | – | – | Named as "New" in the design doc; not built |
| Nystul's Magic Aura | Wz | No BG form | – | – | Deception |
| Pass without Trace | D R | Missing | – | – | +10 Stealth: a stealth bonus would do |
| Phantasmal Force | B S Wz | Missing | – | – | Int save 1d8 psychic per round: doable |
| Prayer of Healing | C P | Missing | – | – | Out-of-combat group heal 2d8 + mod: doable |
| Protection from Poison | C D P R | BG native | SPPR212 | both | Poison immunity (more than resistance + advantage). Lists ok |
| Ray of Enfeeblement | Wl Wz | Approximated | SPWI221 | both | Con save, conc, repeat save each turn; 2e Str 5 (2024: disadvantage on Str rolls, −1d8 weapon damage). Lists: +B +S |
| Rope Trick | Wz | No BG form | – | – | Resting |
| Scorching Ray | S Wz | Approximated | SPWI217 (BG Agannazar's-style jet) | both | 2e: one target 3d6 twice, no attack rolls (2024: 3 rays, 2d6 each, attacks, +1 ray upcast). Lists: +B |
| See Invisibility | B S Wz | BG native | SPWI203 | both | Lists ok |
| Shatter | B S Wl Wz | Implemented | B24SHATR (arcane, auto-learned) | both | 3d8 Con half in 10 ft; no upcast. Lists ok |
| Shining Smite | P | Missing | – | – | Paladin spells not done |
| Silence | B C R | Approximated | SPPR211 | both | 2e: Wis save at −5 silences creatures, no lasting zone (2024: sphere zone, no save); conc. Lists: +P −B −R |
| Spider Climb | S Wl Wz | No BG form | – | – | Vertical movement |
| Spike Growth | D R | Missing | – | – | Damaging ground zone: doable |
| Spiritual Weapon | C | Approximated | SPPR213 (BG Spiritual Hammer) | both | 2e: a hammer the caster wields (1d4+1 +bonus) (2024: floating 1d8 + mod force attacks, conc). Lists: +P |
| Suggestion | B S Wl Wz | Missing | – | – | Mostly social; combat use as a charm/flee effect |
| Summon Beast | D R | Missing | – | – | BG Animal Summoning dropped |
| Warding Bond | C P | Missing | – | – | +1 AC/saves, resistance, shared damage: doable |
| Web | S Wz | Approximated | SPWI215 | both | Dex save, conc; 2e held in web. Lists: +B |
| Zone of Truth | B C P | No BG form | – | – | Social |

### Level 3 (52)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Animate Dead | C Wz | Approximated | SPPR301; SPWI501 (re-filed at L3) | both | 2e: a temporary undead summon (2024: lasting servants from corpses, re-cast to keep). Lists: +B +P +S |
| Aura of Vitality | C D P | Missing | – | – | Bonus-action heals 2d6: doable as an aura |
| Beacon of Hope | C | Missing | – | – | Advantage on Wis/death saves, max healing: doable |
| Bestow Curse | B C Wz | Missing | – | – | BG curse spells (Greater Malison etc.) dropped |
| Blinding Smite | P | Missing | – | – | Paladin spells not done |
| Blink | S Wz | Missing | – | – | Ethereal 50% per round: doable (miss chance) |
| Call Lightning | D | Implemented | SPPR302 | both | 3d10 Dex half per bolt, conc, upcast copies to L7; BG: outdoors only. Lists: +R |
| Clairvoyance | B C S Wz | BG native | SPWI301 | both | Reveals a distant area; long cast kept. Lists: −C |
| Conjure Animals | D R | Approximated | SPPR604 (re-filed at L3) | both | 2e: 1–2 controllable bears (2024: spectral pack, Dex save 3d10 aura). Lists ok |
| Conjure Barrage | R | Missing | – | – | Ranger spells not done |
| Counterspell | S Wl Wz | No BG form | – | – | Reaction; the design doc rules reactions out |
| Create Food and Water | C P | No BG form | – | – | Food is not tracked |
| Crusader's Mantle | P | Missing | – | – | +1d4 radiant aura on weapon hits: doable |
| Daylight | C D P R S | No BG form | – | – | Light |
| Dispel Magic | B C D P S Wl Wz | BG native | SPWI302, SPPR303 | both | 2e caster-level roll (2024: automatic up to the slot level, check above). Lists: +R |
| Elemental Weapon | D P R | Missing | – | – | +1 and +1d4 elemental on a weapon: doable |
| Fear | B S Wl Wz | BG native | SPWI205 (re-filed at L3) | both | Wis save, conc; panic (2024 cone); repeat save each turn. Lists ok |
| Feign Death | B C D Wz | No BG form | – | – | Utility |
| Fireball | S Wz | Implemented | SPWI304 | both | 8d6 Dex half, upcast +1d6. Lists: +B |
| Fly | S Wl Wz | No BG form | – | – | No flight |
| Gaseous Form | S Wl Wz | No BG form | – | – | Exploration (BG Wraithform dropped) |
| Glyph of Warding | B C Wz | Approximated | SPPR304 | both | 2e damaging glyph trap, Dex save, long cast kept (no stored-spell option). Lists: +P −B −Wz |
| Haste | S Wz | Implemented | SPWI305 | both | One target, conc 1 min: double speed, extra attack (BG haste), +2 AC, Dex save advantage, lethargy (stunned a round) when it ends (`B24SPELL.lua`). Lists: +B |
| Hunger of Hadar | Wl | Missing | – | – | Warlock-only |
| Hypnotic Pattern | B S Wl Wz | Missing | – | – | Area charm/incapacitate: doable |
| Leomund's Tiny Hut | B Wz | No BG form | – | – | Resting is the engine's |
| Lightning Arrow | R | Missing | – | – | Ranger spells not done |
| Lightning Bolt | S Wz | Implemented | SPWI308 | both | 8d6 Dex half, upcast +1d6. Lists: +B |
| Magic Circle | C P Wl Wz | Missing | – | – | BG Protection from Evil 10' Radius dropped |
| Major Image | B S Wl Wz | No BG form | – | – | Illusion |
| Mass Healing Word | B C | Implemented | B24MHWRD (priest), B24MHWBD (bard copy) | both | 2d4 + mod to the caster and every party member in range (2024: 6 creatures); no upcast. Lists: +P |
| Meld into Stone | C D R | No BG form | – | – | Exploration |
| Nondetection | B R Wz | BG native | SPWI310 | both | Divination immunity. Lists: +S −R |
| Phantom Steed | Wz | No BG form | – | – | Travel |
| Plant Growth | B D R | Missing | – | – | Slowing zone: doable |
| Protection from Energy | C D P R S Wz | Approximated | SPPR210 (L3), SPPR306, SPPR407 (L3); SPWI319, SPWI320, SPWI512 (L3), SPWI517 (L3) | both | One BG spell per element, conc; BG resistance amounts (e.g. 50%) instead of resistance; SPPR210 (fire and cold) lasts an hour. Lists: +B |
| Remove Curse | C P Wl Wz | BG native | SPPR307; SPWI410 (re-filed at L3) | both | Lists: +B +S |
| Revivify | C D P R | Implemented | B24REVIV (Raise Dead copy) | both | Within a minute of death (Lua). Lists ok |
| Sending | B C Wz | No BG form | – | – | Communication |
| Sleet Storm | D S Wz | Missing | – | – | Slowing/prone zone: doable |
| Slow | B S Wz | Implemented | SPWI312 | both | −2 AC, halved speed and attacks, Wis save, conc; repeat save each turn. Lists ok |
| Speak with Dead | B C Wz | No BG form | – | – | Dialogue |
| Speak with Plants | B D R | No BG form | – | – | Dialogue |
| Spirit Guardians | C | Implemented | B24SPGRD (mod spell) | both | 3d8 Wis half per round around the caster, 1 min; no slowing, not concentration, no upcast. Lists: +P |
| Stinking Cloud | B S Wz | Approximated | SPWI213 (re-filed at L3) | both | Con save, conc; 2e unconscious/nauseated (2024: poisoned, loses action). Lists ok |
| Summon Fey | D R Wl Wz | Missing | – | – | Nearest: Monster Summoning I (catalog KEEP L3, generic monsters) |
| Summon Undead | Wl Wz | Missing | – | – | Nearest: Animate Dead |
| Tongues | B C S Wl Wz | No BG form | – | – | Dialogue |
| Vampiric Touch | S Wl Wz | Approximated | SPWI314 | both | Melee spell attack 3d6 necrotic (BG magic), heal half, upcast +1d6 (B24SATK); one touch per casting (2024: again each turn while concentrating). Lists: +B |
| Water Breathing | D R S Wz | No BG form | – | – | No water |
| Water Walk | C D R S | No BG form | – | – | No water |
| Wind Wall | D R | Missing | – | – | Missile-blocking wall: doable as a zone |

### Level 4 (40)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Arcane Eye | Wz | BG native | SPWI425 | both | Scouting eye. Lists: +B +S |
| Aura of Life | C P | Missing | – | – | Necrotic resistance aura: doable |
| Aura of Purity | C P | Missing | – | – | Poison resistance + save advantage aura: doable |
| Banishment | C P S Wl Wz | Missing | – | – | Removes a creature for the duration: doable |
| Blight | D S Wl Wz | Missing | – | – | Con save 8d8 necrotic: doable |
| Charm Monster | B D S Wl Wz | Missing | – | – | BG Dire Charm/Mental Domination dropped |
| Compulsion | B | Missing | – | – | Forced movement: doable |
| Confusion | B D S Wz | BG native | SPWI401; SPPR709 (re-filed at L4, druid) | both | Wis save, conc; random behaviour; repeat save each turn. Lists: +R |
| Conjure Minor Elementals | D Wz | Missing | – | – | Damage aura (2024): doable |
| Conjure Woodland Beings | D R | Approximated | SPPR410 | both | 2e: summons a spellcasting nymph (2024: fey blades aura, Wis save 5d8). Lists ok |
| Control Water | C D Wz | No BG form | – | – | No water |
| Death Ward | C P | Implemented | SPPR409 | both | 8 hours: the first drop to 0 HP leaves 1 and ends it (`B24DYING.lua`, party); BG immunity to death magic stays for the duration. Lists ok |
| Dimension Door | B S Wl Wz | BG native | SPWI402 (hidden by the game) | both | Teleport; HIDESPL hides it from Sorcerer/Bard picks; Wizards via scroll or the Spellbook choice. Lists: −B −S |
| Divination | C D Wz | No BG form | – | – | Divination |
| Dominate Beast | D R S | Missing | – | – | Domination of beasts: doable |
| Evard's Black Tentacles | Wz | Missing | – | – | Restraining damage zone: doable |
| Fabricate | Wz | No BG form | – | – | Crafting |
| Fire Shield | D S Wz | BG native | SPWI403 (Chill), SPWI418 (Warm) | both | Retaliation damage + resistance (BG amounts). Lists: +B −D |
| Freedom of Movement | B C D R | BG native | SPPR403 | both | Lists: +P −B |
| Giant Insect | D | Missing | – | – | BG Spider Spawn (SPWI423) dropped |
| Grasping Vine | D R | Missing | – | – | Pull + restrain: doable |
| Greater Invisibility | B S Wz | BG native | SPWI405 | both | Conc added. Lists ok |
| Guardian of Faith | C | Missing | – | – | Damaging guardian: doable as a summon |
| Hallucinatory Terrain | B D Wl Wz | No BG form | – | – | Terrain illusion |
| Ice Storm | D S Wz | Approximated | SPWI404 | both | 2d10 bludgeoning + 4d6 cold once, Dex half (B24AREA); no difficult terrain, no upcasting. Lists: +B −D |
| Leomund's Secret Chest | Wz | No BG form | – | – | Storage |
| Locate Creature | B C D P R Wz | No BG form | – | – | Exploration |
| Mordenkainen's Faithful Hound | Wz | Missing | – | – | Guarding summon: doable |
| Mordenkainen's Private Sanctum | Wz | No BG form | – | – | Warding |
| Otiluke's Resilient Sphere | Wz | BG native | SPWI413 | both | Dex save, conc. Lists: +B +S |
| Phantasmal Killer | B Wz | Missing | – | – | Wis save 4d10 psychic per round: doable |
| Polymorph | B D S Wz | Approximated | SPWI415 (other), SPWI416 (self) | both | Wis save, conc; BG fixed forms (2024: any beast up to CR). Lists: −D |
| Staggering Smite | P | Missing | – | – | Paladin spells not done |
| Stone Shape | C D Wz | No BG form | – | – | Terrain |
| Stoneskin | D R S Wz | Implemented | SPWI408; SPPR506 (re-filed at L4, druid) | both | Touch, 1 hour, conc: 50% resistance to slashing, crushing, piercing and missile (also magical weapons). Lists: +B |
| Summon Aberration | Wl Wz | Missing | – | – | Nearest: Monster Summoning II (catalog KEEP L4) |
| Summon Construct | Wz | Missing | – | – | Summon: doable |
| Summon Elemental | D R Wz | Missing | – | – | Nearest: BG Conjure Elemental (L5) |
| Vitriolic Sphere | S Wz | Missing | – | – | Dex save 10d4 acid: doable |
| Wall of Fire | D S Wz | Missing | – | – | Damaging line/ring: doable as a zone |

### Level 5 (48)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Animate Objects | B S Wz | Missing | – | – | Summons: doable |
| Antilife Shell | D | Missing | – | – | Keeps creatures away: hard (pathing) |
| Awaken | B D | No BG form | – | – | Utility |
| Banishing Smite | P | Missing | – | – | Paladin spells not done |
| Bigby's Hand | S Wz | Approximated | SPWI818 Arcane Hand (re-filed at L5) | both | 2e crushing hand: 3d6 → 6d6 + hold over 4 rounds (2024: four modes, 4d8 force). Lists: +B |
| Circle of Power | C P Wl Wz | Missing | – | – | Save advantage aura: doable |
| Cloudkill | S Wz | Implemented | SPWI502 | both | Con save for half, conc; 5d8 poison per round in the cloud, upcast +1d8 (BG cloud does not move). Lists: +B |
| Commune | C P | No BG form | – | – | Divination |
| Commune with Nature | D R | No BG form | – | – | Exploration |
| Cone of Cold | D S Wz | Implemented | SPWI503 | both | 8d8 Con half, upcast +1d8. Lists: +B −D |
| Conjure Elemental | D Wz | Approximated | SPWI516/520/521 + SPWI620/621/622 (re-filed at L5); SPPR605, SPPR702 (re-filed at L5, druid) | both | 2e: a controllable elemental (2024: an elemental spirit restraining/damaging in an area); two arcane versions of each element at L5. Lists: +B +R +S |
| Conjure Volley | R | Missing | – | – | Ranger spells not done |
| Contact Other Plane | Wl Wz | No BG form | – | – | Divination |
| Contagion | C D | Missing | – | – | BG wizard Contagion (SPWI409) dropped |
| Creation | S Wz | No BG form | – | – | Item creation |
| Destructive Wave | P | Missing | – | – | Paladin spells not done |
| Dispel Evil and Good | C P | Missing | – | – | Doable (protection + banishing touch) |
| Dominate Person | B S Wz | BG native | SPWI506 | both | Wis save, conc. Lists ok |
| Dream | B Wl Wz | No BG form | – | – | Communication |
| Flame Strike | C | Approximated | SPPR503 | both | 5d6 fire Dex half, upcast +1d6; 2024 adds 5d6 radiant (half the damage missing). Lists: +P |
| Geas | B C D P Wz | No BG form | – | – | Social |
| Greater Restoration | B C D P R | BG native | SPPR713 (re-filed at L5) | both | Lists: −B |
| Hallow | C Wl | No BG form | – | – | Area warding over days |
| Hold Monster | B S Wl Wz | BG native | SPWI507 | both | Wis save, conc; repeat save each turn. Lists ok |
| Insect Plague | C D S | Approximated | SPPR517 | both | Con save, conc; 2e swarm (spell failure, 1 HP per round) (2024: 4d10 piercing zone). Lists: +P +R −S |
| Jallarzi's Storm of Radiance | Wl Wz | Missing | – | – | Damage zone: doable |
| Legend Lore | B C Wz | No BG form | – | – | Divination |
| Mass Cure Wounds | B C D | Implemented | SPPR514 | both | 5d8 + mod, upcast copies; no bard copy. Lists: +P +R −B |
| Mislead | B Wl Wz | BG native | SPWI607 (re-filed at L5) | both | Invisible + decoy double. Lists: +S |
| Modify Memory | B Wz | No BG form | – | – | Social |
| Passwall | Wz | No BG form | – | – | Terrain |
| Planar Binding | B C D Wl Wz | No BG form | – | – | Binding over days |
| Raise Dead | B C P | BG native | SPPR504 | both | Long cast kept. Lists: −B |
| Rary's Telepathic Bond | B Wz | No BG form | – | – | Communication |
| Reincarnate | D | Missing | – | – | Druid raise-dead variant possible (species change has no BG form) |
| Scrying | B C D Wl Wz | No BG form | – | – | Divination |
| Seeming | B S Wz | No BG form | – | – | Disguise |
| Steel Wind Strike | R Wz | Missing | – | – | Five melee spell attacks + teleport: doable |
| Summon Celestial | C P | Missing | – | – | BG Summon Deva is an HLA |
| Summon Dragon | Wz | Missing | – | – | Summon: doable |
| Swift Quiver | R | Missing | – | – | Ranger spells not done |
| Synaptic Static | B S Wl Wz | Missing | – | – | Int save 8d6 + debuff: doable |
| Telekinesis | S Wz | No BG form | – | – | Object/creature moving |
| Teleportation Circle | B S Wz | No BG form | – | – | Travel |
| Tree Stride | D R | No BG form | – | – | Travel |
| Wall of Force | Wz | No BG form | – | – | Engine can't add walls to pathing |
| Wall of Stone | D S Wz | No BG form | – | – | Engine can't add walls to pathing |
| Yolande's Regal Presence | B Wz | Missing | – | – | Psychic aura + push: doable |

### Level 6 (34)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Arcane Gate | S Wl Wz | No BG form | – | – | Portals |
| Blade Barrier | C | Approximated | SPPR603 | both | Dex save, conc; 2e blade ring around the caster, 8d8 (2024: wall 6d10). Lists ok |
| Chain Lightning | S Wz | Implemented | SPWI615 | both | 10d8 Dex half; no upcast (extra targets). Lists: +B |
| Circle of Death | S Wl Wz | Missing | – | – | BG Death Spell (different) dropped |
| Conjure Fey | D Wl | Missing | – | – | Summon/teleporting attacker: doable |
| Contingency | Wz | BG native | SPWI617 | both | BG contingency, long cast. Lists: +B +S |
| Create Undead | C Wl Wz | Missing | – | – | Summon: doable |
| Disintegrate | S Wz | Implemented | SPWI616 | both | 10d6+40 force (magic), Dex negates, upcast +3d6 (no instant death). Lists: +B |
| Drawmij's Instant Summons | Wz | No BG form | – | – | Items |
| Eyebite | B S Wl Wz | Missing | – | – | Sleep/panic/sicken per round: doable |
| Find the Path | B C D | No BG form | – | – | Travel |
| Flesh to Stone | D S Wl Wz | Approximated | SPWI604 | both | Con save, conc; restrained, petrified after 3 failed saves, ends after 3 successes (`B24COND.lua`). Lists: +B −D |
| Forbiddance | C | No BG form | – | – | Area warding |
| Globe of Invulnerability | S Wz | BG native | SPWI602 | both | Blocks spells of level ≤5, conc. Lists: +B |
| Guards and Wards | B Wz | No BG form | – | – | Area warding |
| Harm | C | Approximated | SPPR608 | both | 2e: touch reduces to 1 HP, Con save added (2024: 14d6 necrotic Con half, max HP cut). Lists ok |
| Heal | C D | Implemented | SPPR607 | both | 70 HP, upcast +10 (L7 copy). Lists ok |
| Heroes' Feast | B C D | Missing | – | – | Long cast buff (immunities, +2d10 max HP): doable |
| Magic Jar | Wz | No BG form | – | – | Possession |
| Mass Suggestion | B S Wl Wz | Missing | – | – | Mostly social; combat use as a charm/flee effect |
| Move Earth | D S Wz | No BG form | – | – | Terrain |
| Otiluke's Freezing Sphere | S Wz | Missing | – | – | Con save 10d6 cold: doable |
| Otto's Irresistible Dance | B Wz | Missing | – | – | Doable (disadvantage, can't move) |
| Planar Ally | C | Missing | – | – | Summon a celestial: doable |
| Programmed Illusion | B Wz | No BG form | – | – | Illusion |
| Summon Fiend | Wl Wz | Missing | – | – | BG Summon Fiend (SPWI807, L8) and Cacofiend (SPWI707) dropped |
| Sunbeam | C D S Wz | Approximated | SPPR707 (re-filed at L6, druid) | both | 6d8 Con half + blinded, conc; 2e one burst around the caster (2024: a line each round). Lists: −C −S −Wz |
| Tasha's Bubbling Cauldron | Wl Wz | No BG form | – | – | Potion creation |
| Transport via Plants | D | No BG form | – | – | Travel |
| True Seeing | B C S Wl Wz | BG native | SPWI609; SPPR505 (re-filed at L6) | both | Lists ok |
| Wall of Ice | Wz | No BG form | – | – | Engine can't add walls to pathing |
| Wall of Thorns | D | Missing | – | – | Damaging zone version doable |
| Wind Walk | D | No BG form | – | – | Travel |
| Word of Recall | C | No BG form | – | – | Travel |

### Level 7 (21)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Conjure Celestial | C | Missing | – | – | BG Summon Deva is an HLA |
| Delayed Blast Fireball | S Wz | Implemented | SPWI712 | both† | 12d6 Dex half, conc, upcast +1d6. Lists: +B |
| Divine Word | C | BG native | SPPR710 | both† | Cha save; HP-tiered effects. Lists ok |
| Etherealness | B C S Wl Wz | No BG form | – | – | Planes |
| Finger of Death | S Wl Wz | Implemented | SPWI713 | both† | 7d8+30 Con half (no rising zombie). Lists: +B |
| Fire Storm | C D S | Implemented | SPPR705 | both† | 7d10 Dex half (BG storm area). Lists: −S |
| Forcecage | B Wl Wz | Missing | – | – | Imprisoning cage: doable (no wall needed) |
| Mirage Arcane | B D Wz | No BG form | – | – | Terrain illusion |
| Mordenkainen's Magnificent Mansion | B Wz | No BG form | – | – | Resting |
| Mordenkainen's Sword | B Wz | Approximated | SPWI716 Arcane Sword | both† | 2e: a +4 sword (5d4) the caster wields (2024: floating sword 4d12 force). Lists: +S |
| Plane Shift | C D S Wl Wz | No BG form | – | – | Planes |
| Power Word Fortify | B C | Missing | – | – | 120 temp HP split: doable |
| Prismatic Spray | B S Wz | Approximated | SPWI714 | both† | Dex save; 2e random rays/blindness (2024: 12d6 per colour ray). Lists ok |
| Project Image | B Wz | BG native | SPWI703 | both† | Conc. Lists: +S |
| Regenerate | B C D | BG native | SPPR711 (Regeneration) | both† | Lists: −B |
| Resurrection | B C | BG native | SPPR712 | both† | Long cast kept. Lists: −B |
| Reverse Gravity | D S Wz | No BG form | – | – | Vertical movement |
| Sequester | Wz | No BG form | – | – | Hiding |
| Simulacrum | Wz | BG native | SPWI804 (re-filed at L7) | both† | Long cast kept. Lists: +B +S |
| Symbol | B C D Wz | Approximated | SPWI811/816/817 (re-filed at L7); SPPR706, SPPR718, SPPR719 | both† | 2e instant area Fear/Stun/Death, not a triggered glyph. Lists: +S −D |
| Teleport | B S Wz | No BG form | – | – | Travel is the world map |

### Level 8 (18)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Animal Shapes | D | Missing | – | – | Mass polymorph into beasts: doable |
| Antimagic Field | C Wz | Missing | – | – | Spell-blocking aura: doable |
| Antipathy/Sympathy | B D Wz | No BG form | – | – | Attraction/aversion over days |
| Befuddlement | B D Wl Wz | Approximated | SPWI509 Feeblemind (catalog KEEP, re-filed at L8) | both† | Int save; 2e Feeblemind (Int/Wis 3) (2024: 10d12 psychic, can't cast). Lists: +S −D |
| Clone | Wz | No BG form | – | – | Downtime |
| Control Weather | C D Wz | No BG form | – | – | Weather |
| Demiplane | S Wl Wz | No BG form | – | – | Planes |
| Dominate Monster | B S Wl Wz | Missing | – | – | Domination of any creature: doable |
| Earthquake | C D S | Approximated | SPPR720 | both† | Dex save, conc; 2e three tremors with knockdown; filed at L7 (priest limit). Lists: −S |
| Glibness | B Wl | No BG form | – | – | Social |
| Holy Aura | C | Missing | – | – | Ally advantage aura + blinding: doable |
| Incendiary Cloud | D S Wz | Approximated | SPWI810 | both† | Dex save for half, conc; 10d8 fire per round (BG cloud does not move). Lists: +B −D |
| Maze | Wz | BG native | SPWI813 | both† | Conc. Lists: +B +S |
| Mind Blank | B Wz | Missing | – | – | Psychic/charm immunity: doable |
| Power Word Stun | B S Wl Wz | Implemented | SPWI715 (re-filed at L8) | both† | ≤150 HP: stunned, Con save at the end of each turn (B24PWS, `B24COND.lua`); otherwise speed 0 for a round. Lists ok |
| Sunburst | C D S Wz | Missing | – | – | Con save 12d6 radiant + blind: doable (BG Sunfire dropped) |
| Telepathy | Wz | No BG form | – | – | Communication |
| Tsunami | D | No BG form | – | – | Moving wall of water |

### Level 9 (17)

| Spell | 2024 lists | Status | In game as | BG:EE / BG2:EE | Note |
| --- | --- | --- | --- | --- | --- |
| Astral Projection | C Wl Wz | No BG form | – | – | Planes |
| Foresight | B D Wl Wz | Missing | – | – | Advantage on everything for 8 hours: doable |
| Gate | C S Wl Wz | Approximated | SPWI905; SPPR703 (priest L7) | both† | 2e: summons a fiend (2024: portal, can call a named creature). Lists: +B |
| Imprisonment | Wl Wz | BG native | SPWI910 | both† | Wis save. Lists: +B +S |
| Mass Heal | C | Missing | – | – | 700 HP split: doable |
| Mass Polymorph | B S Wz | Missing | – | – | Doable with BG forms |
| Meteor Swarm | S Wz | Implemented | SPWI911 | both† | 20d6 fire + 20d6 bludgeoning, Dex half, once per creature (B24AREA). Lists: +B |
| Power Word Heal | B C | Missing | – | – | Full heal + conditions: doable (Words of Creation notes it is missing) |
| Power Word Kill | B S Wl Wz | Implemented | SPWI912 | both† | ≤100 HP dies, otherwise 12d12 psychic (BG magic; B24PWK). Lists ok |
| Prismatic Wall | B Wz | Missing | – | – | Wall form impossible; a globe version would be doable |
| Shapechange | D Wz | Approximated | SPWI916 | both† | BG fixed forms, conc. Lists: +B +S −D |
| Storm of Vengeance | D | Missing | SPPR722 (catalogued at L7, but HIDESPL hides it: a BG2 druid HLA) | – | Not on the druid spell list; BG2:EE HLA only |
| Time Stop | S Wz | BG native | SPWI909 | both† | Lists: +B |
| True Polymorph | B Wl Wz | Missing | – | – | Doable with BG forms |
| True Resurrection | C D | Missing | – | – | BG Resurrection already restores fully |
| Weird | Wl Wz | Missing | – | – | Wis save 4d10 psychic + frightened: doable |
| Wish | S Wz | Approximated | SPWI919 | both† | BG wish menu (random by Wisdom). Lists: +B |

### Summary

| Level | Implemented | Approximated | BG native | No BG form | Missing | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Cantrips | 12 | 3 | 0 | 10 | 9 | 34 |
| Level 1 | 7 | 16 | 4 | 14 | 23 | 64 |
| Level 2 | 4 | 11 | 9 | 15 | 23 | 62 |
| Level 3 | 7 | 7 | 5 | 16 | 17 | 52 |
| Level 4 | 0 | 5 | 7 | 8 | 20 | 40 |
| Level 5 | 2 | 5 | 5 | 20 | 16 | 48 |
| Level 6 | 3 | 4 | 3 | 13 | 11 | 34 |
| Level 7 | 3 | 3 | 5 | 7 | 3 | 21 |
| Level 8 | 0 | 4 | 1 | 7 | 6 | 18 |
| Level 9 | 0 | 5 | 2 | 1 | 9 | 17 |
| **Total** | **38** | **63** | **41** | **111** | **137** | **390** |

"In game" (Implemented + Approximated + BG native) = 142 of 390 (36%); of the 279 spells that
could work in BG (all but No BG form), 142 are in (51%), and 38 of those (14%) play as in 2024.

### Most important gaps

**Popular 2024 spells that are missing**

- Cantrips: Guidance, Eldritch Blast (no Warlock class), True Strike, Mind Sliver, Thunderclap,
  Blade Ward, Resistance, Spare the Dying, Shillelagh (BG's level-1 Shillelagh SPPR110 is DROPped).
  Bards and Clerics run out of cantrips to choose (Asset list already notes it).
- Level 1–2: Faerie Fire (BG:EE even has a hidden SPPR116), Heroism, Tasha's Hideous Laughter,
  Dissonant Whispers, Ice Knife, False Life, Fog Cloud, Ray of Sickness, Moonbeam (named as "New"
  in the design doc), Spike Growth, Darkness, Pass without Trace, Prayer of Healing, Warding Bond,
  Heat Metal, Cloud of Daggers, Mind Spike, Enlarge/Reduce.
- Level 3–5: Hypnotic Pattern, Banishment, Wall of Fire, Polymorph (only 2e), Bestow Curse, Blink,
  Beacon of Hope, Aura of Vitality, Magic Circle, Elemental Weapon, Sleet Storm, Evard's Black
  Tentacles, Phantasmal Killer, Charm Monster, Contagion (BG's wizard Contagion SPWI409 is
  DROPped), Synaptic Static, Animate Objects, Steel Wind Strike.
- Level 6–9: Otiluke's Freezing Sphere, Circle of Death, Eyebite, Otto's Irresistible Dance,
  Heroes' Feast, Sunburst, Dominate Monster, Mind Blank, Antimagic Field, Forcecage, Foresight,
  Power Word Heal, Mass Heal, Weird, True Polymorph.
- Whole groups: every Paladin smite spell (Searing, Thunderous, Wrathful, Shining, Blinding,
  Staggering, Banishing) and Divine Favor, Compelled Duel, Crusader's Mantle, Find Steed; every
  Ranger-only spell (Ensnaring Strike, Hail of Thorns, Cordon of Arrows, Lightning Arrow, Conjure
  Barrage, Conjure Volley, Swift Quiver); all 2024 Summon spells (Beast, Fey, Undead, Aberration,
  Construct, Elemental, Celestial, Dragon, Fiend); every Warlock-only spell (no Warlock class).

**Badly approximated (2e effect under the 2024 name)**

- Inflict Wounds is the 2014 version (melee spell attack 3d10), not 2024's Con save 2d10 / half.
- Shield of Faith is BG's Armor of Faith (5–25% damage absorption), not +2 AC.
- Haste: BG's party-area double speed + extra attack, much stronger than 2024's single target.
- Magic Missile, Scorching Ray, Melf's Acid Arrow, Chromatic Orb: 2e numbers and no attack rolls or
  slot-based darts/rays.
- Sleep, Color Spray, Command: 2e HD caps and "sleep 1 round"; Bless/Bane flat ±2 instead of 1d4.
- Spiritual Weapon, Flame Blade, Mordenkainen's Sword: weapons the caster wields, not the 2024
  spell attacks; Flame Strike lacks the 5d6 radiant half; Harm reduces to 1 HP; Meteor Swarm,
  Power Word Kill, Ice Storm, Cloudkill, Incendiary Cloud keep 2e damage/thresholds.
- Hunter's Mark and Divine Smite are class-feature innates with free uses, not spells (no
  concentration, no slots, no upcasting).

### Data issues found

- **Storm of Vengeance** (SPPR722) is catalogued (SRD, L7, Druid) but the game's own HIDESPL.2DA
  hides it (it is a BG2 druid HLA), so the catalog row has no effect.
- **Dimension Door** (SPWI402) is catalogued for W/S/B, but the game's HIDESPL.2DA hides it: Sorcerers
  and Bards can never pick it; Wizards get it from scrolls or the Spellbook choice. Misty Step
  (B24MSTEP) is its level-2 copy.
- **Conjure Elemental** exists twice per element at level 5 for arcane casters (SPWI516/520/521 and
  the re-filed SPWI620/621/622 → SPWI525–527): six spellbook entries with the same names.
- **Spirit Guardians** (B24SPGRD) is not in B24CONC (not catalogued), so it is not concentration.
- The mod's new spells (Healing Word, Guiding Bolt, Thunderwave, Shatter, Spirit Guardians, Mass
  Healing Word, bard copies) have no upcast versions; upcasting exists only for catalog rows with
  an UPCAST value (Burning Hands, Chromatic Orb, Fireball, Lightning Bolt, Cone of Cold,
  Disintegrate, Delayed Blast Fireball, Cure Wounds, Mass Cure Wounds, Heal, Inflict Wounds, Call
  Lightning, Flame Strike).
- **Class lists:** arcane spells are not filtered per class, so Bards and Sorcerers get Wizard-only
  spells (Find Familiar, Animate Dead, Contingency, Simulacrum, Maze, Imprisonment, Acid Arrow...),
  and Bards get Sorcerer/Wizard blasting spells (Fireball, Magic Missile, Disintegrate...).
  Priest flags give Paladins every Cleric spell ≤5 (Animate Dead, Inflict Wounds, Guiding Bolt,
  Spirit Guardians, Spiritual Weapon, Flame Strike, Glyph of Warding, Mass Healing Word...) and
  Rangers every Druid spell ≤5 (Call Lightning, Insect Plague, Confusion, Conjure Elemental,
  Thunderwave, Charm Person...). Missing from lists: Bard has no Aid, Command, Bane, Lesser/Greater
  Restoration, Raise Dead, Regenerate, Resurrection, Mass Cure Wounds, Freedom of Movement (Magical
  Secrets only); Druid has no Fire Shield, Ice Storm, Cone of Cold, Polymorph, Flesh to Stone,
  Incendiary Cloud, Shapechange, Symbol (arcane-only in BG); Sunbeam is Druid-only (2024 also C S Wz).
- **Reusable BG files not used:** Faerie Fire (SPPR116, BG:EE), Darkness (SPWI228, BG:EE), Shillelagh
  (SPPR110), Contagion (SPWI409), Summon Fiend (SPWI807) / Cacofiend (SPWI707), Spider Spawn
  (SPWI423, for Giant Insect), Protection from Evil 10' Radius (SPPR408, for Magic Circle).
- **Catalog KEEP rows with no PHB 2024 counterpart:** Flame Arrow (SPWI303), Monster Summoning I–III
  (SPWI309/407/504), Magical Stone (SPPR106), Tenser's Transformation (SPWI603), Abi-Dalzim's
  Horrid Wilting (SPWI812) — these stay as extra non-2024 spells (Friends and Feeblemind→Befuddlement
  are the KEEP rows that do map).

