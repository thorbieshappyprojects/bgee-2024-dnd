# BG 2024 Rules Mod – Design Document

Oct 23, 2026 · @Thorben

## Goals and scope

The mod brings BG:EE and BG2:EE as close to the D&D 2024 rules as the Infinity Engine allows, starting with Fighter, Wizard and Druid as the MVP.

| Area | In MVP | Later | Out of scope |
| --- | --- | --- | --- |
| Games | BG:EE, BG2:EE (one WeiDU package, per-game branches) | EET support | Classic 1998/2000 versions |
| Core rules | Ability mods, proficiency, AC/attack, HP, six saves, advantage, concentration, rests, exhaustion | Action economy in the turn-based mode (bonus actions, Opportunity Attacks, reactions) | Action economy in real time |
| Classes | Fighter, Wizard, Druid | Remaining classes, one by one |  |
| Spells | Wizard and Druid 2024 lists, levels 0–9 | Cleric, Bard, Sorcerer, Warlock, Paladin, Ranger lists; upcasting |  |
| Party NPCs | Every companion of BG:EE and BG2:EE, converted when it first joins |  |  |
| Multiclassing | Prepare data structures | Dual-class as 2024 multiclass for the player, BG multiclasses with 2024 math for companions, level-ups held back to the XP level | True 5e level-by-level multiclassing |
| Monsters | Light math pass (AC, attack, saves) |  | Full 5e statblock conversion |

Each rule in this document is marked **native** (engine supports it directly), **native (in Lua, EEex)** (the 2024 rule as written, carried out by the mod's Lua), **approximated** (close, with known deviations) or **dropped**.

## Technical foundation

The mod is one WeiDU package for both games, with EEex as a hard dependency for the rules the engine cannot express in data.

**Toolchain (Windows)**

- **WeiDU** for installation and all data patching (`.tp2` scripts, 2DA tables, `.SPL`, `.ITM`, `.CRE`, `.EFF` files).
- **EEex** for Lua hooks into saves, attack rolls and resource tracking. It must be installed before this mod.
- **Near Infinity** for inspecting and testing game files.
- **IESDP** as the reference for file formats and effect opcodes.
- **Git** for version control of the mod source.

**Game build**

- Target the newest game build that the current EEex release supports. Check this before the first line of code.
- If EEex lags behind the latest patch, pin the Steam install to the supported version through the Betas tab, then copy it to the working folder.

**Working setup**

- Steam library outside Program Files; clean copies in `C:\BG\BGEE-clean` and `C:\BG\BG2EE-clean`.
- Modding happens in separate working copies, reset from the clean copies whenever an install needs a fresh start.

**Mod folder layout**

```
bg2024/
  bg2024.tp2          install script, one component per system
  lib/                shared WeiDU macros (save remap, spell builder, CRE patcher)
  lua/                EEex scripts (saves, advantage, concentration, mastery, rests)
  tables/             2DA sources (THAC0, ability mods, HP, slots, CLAB)
  spells/data/        one data file per spell, including upcast scaling
  spells/generated/   SPL files built from the data at install time
  kits/               subclass definitions
  npc/                companion conversions
  tra/                text, English first
```

**Install components** (each can be installed separately, in this order)

1. Core rules
2. Monster math pass
3. Character creation (ability scores, backgrounds)
4. Fighter
5. Wizard and wizard spell list
6. Druid and druid spell list
7. Party NPC conversions

**Compatibility:** install after content mods and before tweak mods that change the same tables. Known conflicts are documented as they come up.

## Core rules

The core rules are installed once and apply to every creature; class components build on top of them.

| 2024 rule | Implementation | Status |
| --- | --- | --- |
| Ability modifiers: (score − 10) / 2 | Rewrite STRMOD, STRMODEX, DEXMOD, CONMOD, INTMOD, WISXPMOD and related tables; remove 18/xx exceptional Strength | Native |
| Proficiency bonus +2 to +6 by level | THAC0 tables per class: THAC0 = 20 − (proficiency + ability mod), ability part applied through STRMOD/DEXMOD | Native |
| Armor Class (5e scale) | Engine AC = 20 − 5e AC. Armor, shields and Dex caps (medium armor max +2, heavy armor none) patched on every armor item | Approximated: Dex cap needs EEex or per-armor effects |
| Bounded accuracy for items | Enchantments kept up to +5 (decided 2026-10-28: +4 and +5 story items keep their bonus and name; 2024 stops at +3), remove stacking AC bonuses beyond 5e rules. Exception (decided 2026-11-08, story over rules): items forged or assembled from components (Cespenar, Cromwell, the de'Arnise forge, Darcin Cole, Taerom, Jegg) and a story creature's natural weapons keep their BG values untouched, even past +5 (tables/b24itemkeep.2da) | Native (large patch job) |
| Hit points: class hit die + Con mod per level, max at level 1 | HPxxx tables plus CONMOD; 2024 fixed values per level (average rounded up) | Native |
| Six saving throws: d20 + ability mod + proficiency if proficient | EEex hook replaces the five 2e save categories; each spell/effect is tagged with its 5e save ability | Approximated: needs EEex, every save-causing effect must be retagged |
| Advantage and disadvantage | EEex hook rolls two d20 on attacks and saves; sources set flags (blinded, invisible, prone, etc.) | Approximated: needs EEex |
| Critical hits on natural 20, double dice | Engine already crits on 20; damage doubling via EEex | Approximated |
| Concentration | One concentration spell per caster; casting another ends the first; Con save on damage (DC 10 or half damage) | Approximated: needs EEex |
| Short rest | Innate "Short Rest" ability, 1 hour of game time, restores tagged resources, spend Hit Dice | Approximated |
| Long rest | Engine rest, extended to restore all Hit Dice and clear 1 Exhaustion level | Native |
| Exhaustion: −2 per level to d20 tests, −5 ft speed per level, death at 6 | Spell state plus EEex modifier on d20 rolls; speed reduction via movement-rate effect | Approximated |
| Heroic Inspiration | Token granted by triggers; one reroll of a failed d20 test | Approximated: needs EEex |
| Conditions (prone, grappled, restrained, etc.) | Map to existing engine states where they exist; others via spell states | Approximated |
| Rounds | Real time: 6-second rounds, no action types. Turn-based mode (switchable, B24TURN.lua): initiative, one creature acts at a time with one action, one bonus action and its movement; Opportunity Attacks and reactions; death saves at the start and repeat saves at the end of the creature's turn; effect durations counted in rounds | Turn-based mode built; real time unchanged |

## Classes

Each class is capped at level 20. Class features are applied at run time from the class level (lua/B24<class>.lua), so created characters, companions and level-ups work the same way. The subclass is chosen at level 3 in a popup; every class has its SRD subclass plus the other PHB 2024 subclasses (lua/B24X*.lua, own wording, approximations listed in each file's header).

**BG kits** (decided 2026-10-24): 2e kit abilities are removed (install time from the kit's CLAB table, keeping entries shared with the base class; at run time from existing characters, B24KITAB.2DA). Kits with a PHB 2024 counterpart are that subclass (tables/b24kits.2da, e.g. Stalker = Gloom Stalker, Invoker = Evoker, Shapeshifter = Circle of the Moon); the others are flavour and choose a subclass at level 3. Kit item and spell-school restrictions stay. Wilson's bear kit is left alone.

**Fallen Paladins and Rangers** (decided 2026-10-28): BG's fall stays, and stays consequential. While fallen, the class level counts as 0 for the mod: no class or subclass features, no new ASIs or feats; hit points and the proficiency bonus keep following the character level, and earlier choices stay. No second class is offered as a way out. A Paladin regains the class in BG2 through Garren Windspear (after rescuing his child) or the Radiant Heart stronghold's last duty (`RegainPaladinHood()`), and then gets everything back at the current level, missed ASIs as pending choices. A fallen Ranger has no way back in BG2 (no dialogue or script uses `RegainRangerHood()`).

Shared for all three: Ability Score Improvement or feat at 4, 8, 12, 16 (Fighter also 6 and 14), Epic Boon at 19. The feat choice is offered through a level-up dialogue, since the engine has no feat picker.

### Fighter (subclass: Champion)

| Level | Feature | Implementation | Status |
| --- | --- | --- | --- |
| 1 | Fighting Style | Kit-style choice via level-up dialogue (Archery, Defense, Great Weapon Fighting, Two-Weapon Fighting, etc.) | Native (in Lua, EEex) |
| 1 | Second Wind (2 uses, more at 4 and 10) | Innate heal 1d10 + level, recharged on short and long rest | Native (in Lua, EEex) |
| 1 | Weapon Mastery (3 weapons, 4 at 4, 5 at 10, 6 at 16) | See Weapon Mastery section | Approximated |
| 2 | Action Surge (2 uses at 17) | Innate: extra attacks and casting speed for one round | Approximated |
| 2 | Tactical Mind | Spend Second Wind to add 1d10 to a failed ability check (EEex) | Approximated |
| 5 / 11 / 20 | Extra Attack (2 / 3 / 4 attacks) | Attacks per round in class progression | Native |
| 5 | Tactical Shift | Movement bonus after Second Wind | Approximated |
| 9 | Indomitable (more uses at 13, 17) | Reroll a failed save, + Fighter level (EEex) | Approximated |
| 9 | Tactical Master | Swap a weapon's mastery to Push, Sap or Slow per attack | Approximated (toggle ability) |
| 13 | Studied Attacks | Advantage on next attack after a miss (EEex) | Approximated |
| 3 | Champion: Improved Critical (19–20) | Critical-hit range effect | Native |
| 3 | Champion: Remarkable Athlete | Advantage on initiative and athletics checks | Approximated |
| 7 | Champion: Additional Fighting Style | Second style choice | Native (in Lua, EEex) |
| 10 | Champion: Heroic Warrior | Heroic Inspiration at start of each combat | Approximated |
| 15 | Champion: Superior Critical (18–20) | Critical-hit range effect | Native |
| 18 | Champion: Survivor | Regeneration below half HP; advantage on death saves | Approximated (no death saves) |

### Wizard (subclass: Evoker)

| Level | Feature | Implementation | Status |
| --- | --- | --- | --- |
| 1 | Spellcasting (Int, prepared spells from spellbook) | Engine memorization is close to 5e preparation; slots from 5e table | Approximated: engine memorizes per slot, 5e prepares a list |
| 1 | Ritual Adept | Ritual spells castable without a slot but with long casting time | Approximated |
| 1 | Arcane Recovery | Innate after short rest: restore slots totalling half Wizard level | Approximated |
| 2 | Scholar | Expertise in one knowledge skill; maps to Lore | Approximated |
| 5 | Memorize Spell | Swap one prepared spell on short rest | Approximated |
| 18 | Spell Mastery | One level 1 and one level 2 spell castable at will | Native (in Lua, EEex) |
| 20 | Signature Spells | Two level 3 spells, one free cast each per short rest | Native (in Lua, EEex) |
| 3 | Evoker: Evocation Savant, Potent Cantrip | Cheaper evocation scribing; half damage on cantrip miss/save | Approximated |
| 6 | Evoker: Sculpt Spells | Allies auto-succeed and take no damage from own evocations | Approximated (EEex) |
| 10 | Evoker: Empowered Evocation | + Int mod to evocation damage | Native (in Lua, EEex) |
| 14 | Evoker: Overchannel | Max damage on level 1–5 spell, self-damage on repeat | Approximated |

### Druid (subclass: Circle of the Land)

| Level | Feature | Implementation | Status |
| --- | --- | --- | --- |
| 1 | Spellcasting (Wis, prepared from full druid list) | Separate druid spell list (split from shared priest list) | Native |
| 1 | Primal Order: Magician or Warden | Choice at creation: extra cantrip and Wis to checks, or martial weapons and medium armor | Native (in Lua, EEex) |
$1Bonus-action innate opens the beast list; temp HP = druid level; forms up to CR 1/4, 1/2 at 4, 1 at 8 (Moon: 1 at 3, 2 at 6); the beast's Str/Dex/Con, AC and attacks, the druid's HP and mental scores | Approximated: 13 beasts with BG animations (2024 SRD stat blocks), every form of the tier usable instead of 4/6/8 known forms, no flying forms |
| 2 | Wild Companion | Spend Wild Shape use to cast Find Familiar | Native (in Lua, EEex) |
| 5 | Wild Resurgence | Swap slot and Wild Shape use once per long rest | Approximated |
| 7 | Elemental Fury: Potent Spellcasting or Primal Strike | Choice: + Wis to cantrip damage, or +1d8 elemental on weapon hits | Native (in Lua, EEex) |
| 15 | Improved Elemental Fury | Upgrade of chosen option | Native (in Lua, EEex) |
| 18 | Beast Spells | Cast spells while in Wild Shape | Native (in Lua, EEex): the form blocks no spellcasting from 18 |
| 20 | Archdruid | Regain Wild Shape use; convert Wild Shape into slots | Approximated |
| 3 | Land: Circle Spells, Land's Aid | Land type chosen at creation (arid, polar, temperate, tropical); always-prepared spells; Land's Aid as innate AoE damage plus heal | Approximated: Land's Aid built; the always-prepared circle spells are missing (subclass spell lists are not granted yet) |
| 6 | Land: Natural Recovery | Slot recovery on short rest | Approximated |
| 10 | Land: Nature's Ward | Poison immunity plus one resistance by land | Native (in Lua, EEex) |
| 14 | Land: Nature's Sanctuary | Innate area that grants cover and resistance | Approximated |

## Weapon Mastery

Each weapon type gets its 2024 mastery property as an on-hit effect that only fires when the wielder has mastered that weapon type; six of the eight properties fit the engine well.

| Property | 2024 effect | Implementation | Status |
| --- | --- | --- | --- |
| Graze | Miss still deals ability-mod damage | EEex hook on miss | Approximated |
| Push | Push target 10 ft | Exact 10-ft push on hit (B24.ForceMove), Large or smaller | Native (in Lua, EEex) |
| Sap | Target has disadvantage on its next attack | Short spell state read by the advantage hook | Approximated |
| Slow | −10 ft speed until next turn | Movement-rate effect, 1 round | Native (in Lua, EEex) |
| Topple | Con save or prone | Save (EEex) then knockdown effect | Approximated |
| Vex | Advantage on next attack against the target | Spell state read by the advantage hook | Approximated |
| Cleave | Extra attack on an adjacent creature | Hard: needs an EEex-scripted second attack on a nearby enemy | Approximated, may be dropped |
| Nick | Light-weapon extra attack folds into the Attack action | Off-hand attack bonus with light weapons | Approximated |

**How mastery is tracked:** one spell state per mastered weapon type (for example `MASTERY_LONGSWORD`). Each weapon's item file gets a conditional on-hit effect checking that state. Choosing or swapping masteries happens on long rest through a dialogue.

**Weapon list:** every BG weapon category (long sword, short sword, axe, bow, flail, halberd, etc.) is mapped to its closest 2024 weapon and property. Weapons that don't exist in 2024 (for example katana, ninja-to, bastard sword) get the property of their closest equivalent.

## Spellcasting

Spells are generated from data files at install time, so that upcasting can later be added by generating more versions rather than rewriting spells.

**Slots:** MXSPLWIZ and MXSPLDRU tables follow the 2024 full-caster progression (levels 1–9). The 2e bonus slots for high Int/Wis are removed.

**Cantrips:** level 0 spells as innate abilities with unlimited uses, refreshed every round. Damage cantrips scale at character levels 5, 11 and 17, through level-gated effects in the same spell.

**Spell attack and save DC:** spell attack = proficiency + casting ability mod; save DC = 8 + proficiency + casting ability mod. Both are computed by EEex at cast time, since the engine stores fixed save bonuses per spell.

**Preparation:** engine memorization stays (a spell fills a slot of its level). The 2024 "prepared list, cast from any slot" model is approximated. With upcasting later, a prepared spell can be cast from higher slots.

**Concentration:** spells flagged `concentration` in their data apply a caster state; the core concentration hook handles breaking.

**Spell data format** (one file per spell, the foundation for upcasting):

```
spell:         fireball
level:         3
school:        evocation
lists:         wizard, sorcerer
concentration: no
save:          dex, half
area:          20 ft radius
duration:      instant
effects:
  damage:      8d6 fire
upcast:
  per_level:   +1d6 fire
base_resource: SPWI304   (existing BG spell reused, or new)
```

The WeiDU spell builder reads these files and writes the SPL. Upcast levels are a later switch in the same builder (see Deferred features).

## Spell lists

The Wizard and Druid lists are rebuilt to their 2024 contents; every 2024 spell is mapped to one of four outcomes before any spell is written.

| Outcome | Meaning | Typical examples |
| --- | --- | --- |
| Reuse | BG spell already matches 2024 closely; adjust numbers only | Magic Missile, Fireball, Haste |
| Modify | BG spell exists but differs in damage, duration, save or targeting | Sleep, Web, Stoneskin |
| New | 2024 spell has no BG equivalent; built from scratch | Shield, Misty Step, Moonbeam |
| Drop | Spell makes no sense in the engine (exploration, social, downtime) | Comprehend Languages, Find the Path, Teleportation Circle |

**Druid list split:** BG shares one priest spell list between clerics and druids, separated by class flags. The druid list gets its own flags, so that druid-only and cleric-only spells are cleanly separated.

**BG spells not in 2024:** spells that exist only in BG (for example Spell Trap, Ruby Ray of Reversal) are removed from the Wizard and Druid lists. They stay available as scroll or item effects where the game's story needs them. Enemies keep casting them (their scripts call them directly). Protections come off the 2024 way (decided 2026-11-08): Dispel Magic, for one creature, ends every spell of the slot's level or lower and makes an ability check (DC 10 + level) against each higher one; BG's spell protections can't stop it (its working effect lands on the caster, B24DISPL), only a Globe of Invulnerability holds off a Dispel Magic of level 5 or lower, which then can only try to end the Globe.

**Licensing:** only spells from the free 2024 rules (SRD 5.2, CC-BY 4.0) are reproduced with their 2024 names and text. Non-SRD spells are approximated under their BG names or left out.

**Deliverable before coding:** a spell mapping table (spell, level, list, outcome, BG resource, notes) for all Wizard and Druid spells. This is the largest single work item in the MVP and should be its own working tab.

## Species and backgrounds

The engine's race choice becomes the 2024 species (traits only, no ability bonuses). The background, with its ability increases and origin feat, is chosen on the character creation ability screen.

**Species:** the engine's races (human, elf, half-elf, dwarf, halfling, gnome, half-orc) keep their names but lose racial ability adjustments, and their traits are rewritten to 2024 versions (for example Human: Resourceful and Skillful plus an origin feat; Elf: Darkvision, Trance, Fey Ancestry). Half-elf and half-orc have no 2024 equivalent and are treated as variants of Elf and Orc. New 2024 species (Dragonborn, Tiefling, Goliath, Orc, Aasimar) are not in the MVP. Race ability limits (ABRACERQ) and class ability minimums (ABCLASRQ) are removed, since 2024 has neither.

**Backgrounds:** the SRD 5.2 backgrounds Acolyte, Criminal, Sage and Soldier, picked in a popup from the ability screen (more can be added later). Each grants:

- +2/+1 or +1/+1/+1 to the background's three abilities, written into the base scores when the ability step is done
- one origin feat (Alert, Magic Initiate, Savage Attacker; humans also pick one through Versatile, including Skilled) as innate effects
- skill proficiencies, mapped to engine skills where they exist (Lore, Stealth, etc.); the rest are dropped

**Ability score generation:** the ability screen offers three methods, replacing the engine's unlimited rerolls:

- point-buy: 27 points, scores 8 to 15
- standard array: 15, 14, 13, 12, 10, 8, distributed from a pool (abilities start empty)
- 4d6 drop the lowest, six values distributed the same way, with 3 rerolls each time the screen is opened

Unlimited rerolls were dropped because they push most characters to 18 in the main ability and well above the 2024 range elsewhere, which breaks bounded accuracy against the monster math pass. Point-buy starts at 8 in every ability. As in 2024, the background comes first: its popup opens when the ability screen is reached, with the background that fits the class best preselected, and each ability row shows base score and increase (for example 15+2).

**Status:** approximated. The engine's CHARGEN_ABILITIES menu is patched in UI.MENU (only that menu) to call Lua; UI mods that replace this menu are incompatible.

## Party NPCs

Every joinable companion (PDIALOG.2DA, by script name) is converted once, the first time it is in the party (lua/B24NPC.lua; local B24NPCFIT per creature, so every chapter version of a companion gets it). Multiclass companions keep their BG multiclass with the 2024 math (see Deferred features: multiclassing) and are rebuilt to their XP level on joining. Shapes like Cernd's bear form keep their monster statistics.

**Conversion rules**

- Ability scores: exceptional Strength (18/xx) counts as 18, and no base score is above 20 (items and story effects still raise them).
- Hit points: single classes get the 2024 hit points (maximum hit die at level 1, then the fixed value per level, plus the Constitution modifier per level); multiclasses get them from the multiclass rules. Saves, proficiency and spells come from the 2024 class rules at run time already.
- 2e kits follow the kit rules in Classes: a kit with a PHB 2024 counterpart is that subclass, other kits choose (companions take the class's first, SRD, subclass).
- NPC scripts that check old class features, such as specific spells, are patched as needed.

Tested in both games (tools/ingame-test.ps1 -Mode Companions: each companion's highest version is spawned without dialogue or scripts, converted and checked). Subclasses after conversion:

| Companion | Game | Class | Subclass |
| --- | --- | --- | --- |
| Khalid, Kagain, Shar-Teel, Korgan, Mazzy, Sarevok | BG1, BG2 | Fighter | Champion (from level 3; Korgan's Berserker kit is a fighter kit, the 2024 Berserker a Barbarian path) |
| Wilson | BG2 | none (story creature) | Stays a bear (decided 2026-11-08, story over rules): BG statistics, claws, attacks, regeneration and Strength kept; no 2024 class features, subclass or choices; level-ups add hit points and the proficiency bonus (B24.IsStoryCreature, tables/b24itemkeep.2da) |
| Ajantis | BG1 | Paladin | Oath of Devotion |
| Keldorn, Dorn | BG1, BG2 | Paladin (Inquisitor, Blackguard) | Oath of Vengeance |
| Dynaheir, Xzar, Edwin, Xan, Neera | BG1, BG2 | Wizard | Evoker (Dynaheir's Invoker kit; the others by default) — Neera's Wild Mage kit is flavour, BG's surges stay |
| Baeloth | BG1 | Sorcerer | Draconic Sorcery |
| Faldorn | BG1 | Druid | Circle of the Land |
| Cernd | BG2 | Druid (Shapeshifter) | Circle of the Moon |
| Viconia, Branwen | BG1, BG2 | Cleric | Life (Branwen: War) |
| Kivan, Minsc, Corwin, Valygar | BG1, BG2 | Ranger | Hunter (Valygar's Stalker kit: Gloom Stalker) |
| Imoen, Safana, Skie, Alora, Hexxat, Yoshimo | BG1, BG2 | Rogue | Thief |
| Garrick, Eldoth, Haer'Dalis | BG1, BG2 | Bard | Lore (Haer'Dalis' Blade kit: Dance) |
| Rasaad | BG1, BG2 | Monk (Sun Soul) | Warrior of the Elements |
| Jaheira, Coran, Yeslick, Quayle, Tiax, Montaron, Nalia, Aerie, Jan Jansen, Anomen | BG1, BG2 | Multiclass | Keep their BG multiclass (2024 math); each class past its subclass level gets one |

## Monsters: light math pass

Monsters keep their 2e abilities, scripts and HP, but their attack, AC and saves are translated so they fight fairly against 5e-scaled characters.

A WeiDU patch macro runs over every `.CRE` file that is not a party member and applies:

| Value | Rule | Notes |
| --- | --- | --- |
| AC | Engine AC → 5e AC (20 − engine AC), then capped to the 10–22 range | Prevents unhittable bosses under bounded accuracy |
| Attack bonus (THAC0) | Derived from level/HD as a proficiency-like bonus plus a fixed ability mod estimate, capped around +14 | Keeps hit chances near 5e expectations |
| Saving throws | 2e saves → six ability saves using ability mods; proficient in two saves chosen by creature type (for example Dex and Wis for undead) | Requires the EEex save hook |
| Ability scores | Kept, except 18/xx and above-25 values, which are normalized |  |
| Spell save DCs on monster spells | Recomputed as 8 + proficiency + casting mod |  |
| HP, damage, special abilities, AI scripts | HP × 1.5 (tools/balance.pl); damage, special abilities and AI scripts unchanged | Full conversion is out of scope |
| HP and Constitution | The engine adds HPCONBON.2DA (now the 2024 modifier) × level when it loads a creature; every creature, party NPCs too, keeps at least 1 hit point per level after that | Without it, BG:EE's Xan (CON 7) and the downed trolls arrived dead |

The exact formulas are tuned in playtesting; the macro takes them as parameters so they can be changed without rewriting the patch. Special creatures (dragons, liches, story bosses) get a manual review list.

## Deferred features: upcasting and multiclassing

Neither is built in the MVP, but both shape decisions now: spells are data-driven for upcasting, and class features are tracked by class level for multiclassing.

### Upcasting

| Option | How it works | Effort | Player experience |
| --- | --- | --- | --- |
| A: Generated variants | The spell builder creates one SPL per slot level (Fireball 3, 4, 5…); each appears in its own slot level | Low once the builder exists; more spellbook entries | Clear but cluttered spellbook |
| B: Cast-time choice | Casting opens a sub-menu (like Nahal's or Wild Shape forms) to pick the slot level | Medium: sub-spell menus per upcastable spell | Close to 2024 |
| C: EEex slot hook | EEex reads which slot was spent and scales the spell | High: depends on EEex internals | Closest to 2024 |

**MVP requirement:** every spell file carries an `upcast` field; the builder must be able to emit variants even if the switch stays off.

### Multiclassing

| Option | How it works | Fidelity | Effort |
| --- | --- | --- | --- |
| A: Keep 2e multi/dual-class, 5e math underneath | Existing combinations (Fighter/Mage, Fighter/Druid, etc.) stay; slots, HP and proficiency are recomputed | Low: XP split and simultaneous leveling remain | Low |
| B: Fixed combinations as kits | Selected 5e-style builds (for example "Fighter 2 / Wizard X") packaged as kits with a fixed feature schedule | Medium | Medium |
| C: Dual-class as 5e multiclass | Use dual-classing as the "take levels in a new class" mechanic, but without the 2e restriction that old class features are disabled | Medium-high | High, needs EEex |
| D: Full level-by-level choice | Pick any class at each level-up | High | Not feasible in this engine |

**MVP requirement:** class features check the level of the class that grants them (Fighter level, Wizard level), never total character level, and multiclass spell slots follow the 2024 combined-caster table. This keeps options A to C open.

**Decision (2026-10-26): C for the player, A for the companions.**

- **Player characters multiclass by dual-classing (C).** Dual-classing is the engine's "take levels in a new class" step and the closest match to 2024 multiclassing: the old class keeps its levels, the new class starts at level 1, and the character level is the sum. The mod changes the BG rules to the 2024 ones:
  - the old class's features stay active (in BG they are switched off until the new class passes the old one; needs EEex);
  - every species can dual-class (BG: humans only; to be tested whether the engine allows it);
  - the requirement is 13 in the main ability of both classes (BG: 15 in the old one, 17 in the new one).
  
  Approximated: one switch only, after which the old class takes no more levels (engine limit). Level-by-level choice between two classes (option D) stays out of reach.
- **No multiclass in character creation.** As in 2024, a character starts in one class; the engine's multiclass entries stay hidden in character creation.
- **BG multiclasses stay for the companions who are one (A):** Jaheira, Coran, Yeslick, Nalia, Aerie, Jan Jansen, Anomen and the like keep their BG class (scripts, dialogue and level-up screen keep working), with the 2024 math below.
- **2024 math for both routes:**
  - proficiency bonus from the total character level (the sum of the class levels);
  - hit points: the hit die of each class for each level in it, plus the Constitution modifier per level;
  - spell slots from the 2024 multiclass caster table (full casters' levels, plus half of the Paladin and Ranger levels); spells known and prepared stay per class;
  - features that don't stack (Extra Attack, Unarmored Defense, Channel Divinity uses and the like) count once: the better one applies.
- **Level-ups are held back to match the XP.** In BG both routes reach more total levels than a single class with the same XP: multiclasses split their XP and level every class on its own table, and a dual-classed character's new class starts over at the cheap low levels. For example, at 64,000 XP a Fighter is level 7 but a BG Fighter/Mage is Fighter 6 / Mage 5 (level 11). The mod holds back a level-up as long as the character's total level would exceed the level a single-class character of its main class has with the same XP. The total level always matches 2024's "one character level per XP threshold".

**How it is built (B24MULTI.lua):**

- **Dual-class becomes multiclass.** A dual-classed character already has a multiclass class ID (Fighter→Mage becomes FIGHTER_MAGE); clearing the CRE's "original class" flags turns it into an ordinary multiclass. The old class stays active and both classes keep gaining levels, which is closer to 2024 than BG's dual-class (where the old class never levels again). Dual-classing hands out the new class's level 1 at once, so the character is one level ahead of its XP until it catches up: it took its next level early.
- **The mod does multiclass level-ups.** The engine keeps the real XP (game scripts read it; BG2 raises a companion's XP when it looks too low). The record screen's Level Up button and the world screen's level-up buttons follow the 2024 rule, and a level-up asks which class gains the level (B24_LEVELUP popup, kind CLASS) — 2024's level-by-level choice within BG's class combinations. The mod raises that class level; hit points, proficiency and class features follow from the rules above. The engine's level-up screen is not used for multiclasses: its other gains (weapon proficiencies, thief skill points) come from the 2024 rules already.
- **Rebuild on joining.** A companion who joins with more total levels than its XP allows (BG2's Imoen: Thief 7 / Mage 8 at 160,000 XP, level 10 by XP) is rebuilt once: the starting class keeps its levels where it can, the others give levels back (Imoen: Thief 7 / Mage 3).
- **Dual-classing for every species,** with 13 in the main abilities (ABDCSCRQ/ABDCDSRQ.2DA); the record screen's button checks it. Fighters need Strength 13 (the table can't say "Strength or Dexterity").
- **Approximated:** the engine still draws its "+" on the portrait when its own per-class XP check passes, also while the mod holds the level-up back (the Level Up button stays off).
- **Spell slots** are set by the mod for multiclasses (the engine only updates them in its own level-up): one casting class uses its own table at its level; two (Cleric/Mage, Fighter/Mage/Cleric, Cleric/Ranger) use the full caster table at the combined level, split between the wizard and priest slots in the proportion each class has on its own. Slot levels neither class reaches alone go to the wizard slots, where upcast copies use them; priest slots above 7th count as 7th. Approximated: 2024 lets any slot cast any prepared spell, BG keeps wizard and priest slots apart.

## Out of scope

Two areas are explicitly not part of this project:

- **Monster conversion to 5e statblocks.** Only the light math pass above. HP, damage, abilities and AI stay 2e.
- **Action economy.** In real time: no bonus actions, reactions or Opportunity Attacks; features that cost a bonus action in 2024 are innate abilities with a short cooldown, and a few reactions are automatic (Glorious Defense, Cutting Words, Superior Hunter's Defense). In the turn-based mode (B24TURN.lua): one action and one bonus action per turn (bonus-action abilities and spells don't end the turn; Action Surge gives one more action), Opportunity Attacks with the 2024 reach (5 ft; 10 ft with Reach weapons, B24WEAP.2DA; Disengage, teleports and unseen movers provoke none) and one reaction per round; party members are asked in a short prompt (the game's own popup), others react at once. Reactions so far: Opportunity Attack, Shield (a memorized Shield: +5 AC, a hit it would have stopped is undone) and Uncanny Dodge (half the damage back), decided right after the hit.

## Milestones

The MVP is built in seven phases, each ending with a test you can play; no dates are set yet.

&#91;embedded content: MVP roadmap · 6 phases, each with its exit test\]

The monster math pass comes with the core rules in phase 1, because testing the new character math against unconverted monsters would give misleading results.

**Revised order:** character creation is moved up to phase 2, so every later phase is tested in game with characters built to the 2024 rules. The phases of the roadmap above after phase 1 move back by one (its phase 2 becomes phase 3, and so on).

| Phase | Content | Exit test |
| --- | --- | --- |
| 1 | Core rules and monster math pass | Done |
| 2 | Character creation: ability score generation (standard array / point-buy), species traits without racial ability adjustments, background dialogue with ability increases, origin feat and skills | Create a new character of each species; the scores, traits, background bonuses and feat match the 2024 rules |
| 3–7 | The roadmap's former phases 2–6 | As in the roadmap |

## Open questions

- [ ] Which game build does the current EEex release support, and do we pin Steam to it?
- [x] Ability scores: point-buy, standard array and 4d6 drop lowest with 3 rerolls per visit of the ability screen.
- [ ] Cleave: build it with EEex or drop it?
- [x] Upcasting: option A (a copy of the spell per higher slot level).
- [x] Multiclassing: C (dual-class as 2024 multiclass) for player characters, A (BG multiclass, 2024 math) for multiclass companions, no multiclass in character creation, level-ups held back to the XP level (see Deferred features).
- [x] Subclasses outside the free 2024 rules: all PHB 2024 subclasses, under their original names, with this mod's own wording.
- [ ] Text language: English only, or German from the start?

## Cross-check of game data (2026-10-24)

A data audit of all spells and items of both games (BIFF plus the installed override) against the 2024 logic. Fixed:

- 2e save wording in item and spell texts becomes the 2024 ability save the mod rolls ("save vs. spell" → "Wisdom save"; catalog spells show their own save, e.g. "Saving Throw: Dexterity (half)").
- 2e buffs: Bless (+2 attacks and saves, for +1d4), Mage Armor (13 + Dexterity), Barkskin (AC at least 17), Shield (+5 AC for a round), Blur (attacks against you have disadvantage), Slow (−2 AC, no attack penalty), Tenser's Transformation (advantage instead of +9 to hit).
- Weapons, shields and armor keep enchantments up to +5 (above +5 renamed +5); full plate counts as plate (AC 18).
- Racial weapon attack bonuses (elves, halflings) and the base druid's 2e immunities and resistances are removed; kits as above.

Kept on purpose, transferring 1:1: attack, AC and save bonuses of items and spells (save bonuses apply to the 2e category they name, which maps to an ability save), damage bonuses, magic resistance, extra spell slots, Strength-setting items at their BG values.

Still 2e, for later: 15 damage spells keep BG's damage structure (Magic Stone, Glyph of Warding, Earthquake, Storm of Vengeance, Acid Arrow, Scorching Ray, Flame Arrow, Ice Storm, Cloudkill, Prismatic Spray, Incendiary Cloud, Abi-Dalzim's Horrid Wilting, Arcane Hand, Meteor Swarm, Magic Missile's count), the ranger's racial enemy, Throne of Bhaal high-level abilities, and monster abilities' casting times.
