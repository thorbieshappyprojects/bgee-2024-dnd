# BG 2024 Rules Mod – Asset list and open work

What the mod's new content still borrows from the game, and what is not built yet. Generated from
the install scripts (lib/*.tpa) and the runtime (lua/*.lua) on 2026-10-26.

Everything new works today with art and sound borrowed from vanilla spells. Nothing below blocks
playing; it is what makes new content look and sound like its own thing. Each asset is needed in
**two styles** where it appears in the UI: BG1 for BG:EE, BG2 for BG2:EE (spell and ability icons
are shared by both games and need one version).

## Summary

| Kind | Count | Today |
| --- | --- | --- |
| Spell and cantrip icons | 21 (14 cantrips, 7 spells) | Borrowed vanilla icons, some shared by two features |
| Ability icons (innates) | 118 | Borrowed vanilla spell icons |
| Portrait (status) icons | 20 states | Done: pixel art in art/portraits (generator in art/portrait-generator) |
| Projectiles and hit effects | 21 spells and cantrips, about 10 class features | Spells and cantrips: borrowed from a fitting vanilla spell (lib/b24_spells.tpa, b24_looks); class features: none |
| Sounds | 21 spells and cantrips, a few class features | Spells and cantrips: borrowed with the look; class features: none |

Cheapest route first: most visuals and sounds can **reuse existing vanilla projectiles, VVC effects
and sounds** (a fire projectile for Fire Bolt, the lightning bolt effect for Shocking Grasp, a bell
sound for Toll the Dead). Only icons really need new art, since a borrowed icon looks like another
spell in the spellbook.

## 1. Icons

Icons are 32x32 BAM files. The mod's own icons go through tools/png2bam.pl (see docs/Icon briefs.md:
one brief per icon, workflow and style). Like the game's own spells, each has two versions: the
glyph alone (art/icons/B24*.png, the spellbook and the description) and the glyph carved into a
stone for the action bar (art/icons-stone/B2B*.png, made by `perl tools/stone-icons.pl art/icons art/icons-stone`,
then png2bam; every icon gets its own stone). Every row below still borrows the
icon of an existing spell, so two different abilities can look the same.

### Cantrips (14)

| Cantrip | Resref | Icon now (borrowed) | Visual needed (projectile, hit effect) | Sound |
| --- | --- | --- | --- | --- |
| Acid Splash | B24CACID | SPWI313C | acid burst on the target(s) | acid sizzle |
| Chill Touch | B24CCHIL | SPWI117C | spectral hand on the target | cold touch |
| Fire Bolt | B24CFIRE | SPPR106C | fire projectile, fire hit | fire whoosh |
| Poison Spray | B24CPOIS | SPWI213C | green spray, poison hit | hiss |
| Ray of Frost | B24CFROS | SPWI320C | blue ray, frost hit | ice crackle |
| Shocking Grasp | B24CSHOC | SPWI115C | lightning arc on touch | zap |
| Sorcerous Burst | B24CBURS | SPWI112C | coloured bolt (element varies) | magic burst |
| Sacred Flame | B24CSACR | SPPR450C | radiant flame falling on the target | holy flame |
| Toll the Dead | B24CTOLL | SPWI119C | spectral bell over the target | bell toll |
| Word of Radiance | B24CWORD | SPCL236C | radiant flash around the caster | holy burst |
| Produce Flame | B24CFLAM | SPPR503C | thrown flame, fire hit | fire whoosh |
| Thorn Whip | B24CTHRN | SPPR105C | vine lash, pull | whip crack |
| Starry Wisp | B24CWISP | SPPR751C | star mote projectile | chime |
| Vicious Mockery | B24CMOCK | SPWI411C | psychic flash on the target | voice (insult bark) |

### New spells (7)

| Spell | Resrefs | Icon now (borrowed) | Visual needed | Sound |
| --- | --- | --- | --- | --- |
| Healing Word | B24HWORD, B24HWBRD | SPPR401C | healing sparkle on the target (no projectile) | short healing chime |
| Cure Wounds (bard copy) | B24CWBRD | SPPR103B | as Cure Wounds | as Cure Wounds |
| Guiding Bolt | B24GBOLT | SPPR614C | radiant bolt, glowing target | radiant impact |
| Thunderwave | B24THWAV, B24THWVD | SPWI621C | shockwave cone/burst from the caster | thunder clap |
| Shatter | B24SHATR | SPWI913C | sonic burst at the point | glass shatter |
| Spirit Guardians | B24SPGRD | SPPR150C | spirit aura around the caster (lasting) | choir loop |
| Mass Healing Word | B24MHWRD, B24MHWBD | SPPR514C | healing sparkle on all allies | healing chime |

Misty Step (B24MSTEP) is a copy of a vanilla spell and keeps its art.

### Abilities (118 innates)

Grouped by where they come from. The icon column is the vanilla icon used today.

#### Species and origin feats (8)

| Ability | Resref | Icon now (borrowed) |
| --- | --- | --- |
| Adrenaline Rush | B24ADREN | SPWI305B |
| Battle Medic | B24HEALR | SPPR317C |
| Healing Hands | B24HEALH | SPCL815C |
| Fire's Burn | B24GLFIR | SPWI418C |
| Frost's Chill | B24GLFRO | SPWI404C |
| Hill's Tumble | B24GLHIL | SPPR312C |
| Stone's Endurance | B24GLSTO | SPPR506C |
| Storm's Thunder | B24GLSTM | SPCL721C |

#### Core rules (1)

| Ability | Resref | Icon now (borrowed) |
| --- | --- | --- |
| Short Rest | B24SREST | SPPR103B |

#### Class features (37)

| Ability | Resref | Icon now (borrowed) |
| --- | --- | --- |
| Second Wind | B24SWIND | SPPR315C |
| Action Surge | B24ASURG | SPWI613C |
| Tactical Master | B24TMAST | ENCHAXEC |
| Ability Score Improvement | B24ASI | SPWI408B |
| Fighting Style | B24FSTY | SPDWD02C |
| Weapon Mastery | B24WMAS | ENCHSSWC |
| Subclass | B24SUBC | SPWI515C |
| Rage | B24RAGE | SPCL152B |
| Reckless Attack | B24RECKL | SPIN117C |
| Intimidating Presence | B24INTIM | SPPR416C |
| Cunning Action | B24CUNNG | SPPR403C |
| Steady Aim | B24STAIM | SPWI424C |
| Expertise | B24EXPRT | SPWI110C |
| Flurry of Blows | B24FLURY | SPCL238C |
| Patient Defense | B24PDEF | SPCL522C |
| Step of the Wind | B24STEPW | SPWI921C |
| Stunning Strike | B24STUN | SPCL811C |
| Uncanny Metabolism | B24UMETA | SPPR711C |
| Wholeness of Body | B24WHOLE | SPPR502C |
| Superior Defense | B24SUPDF | SPWI408C |
| Quivering Palm | B24QPALM | SPCL820C |
| Lay on Hands | B24LOH | SPCL815B |
| Divine Smite | B24SMITE | SPPR313C |
| Sacred Weapon | B24SACWP | SPPR206C |
| Abjure Foes | B24ABJUR | SPPR515C |
| Holy Nimbus | B24NIMBS | SPCL237B |
| Hunter's Mark | B24HMARK | SPPR415C |
| Tireless | B24TIRLS | SPPR201C |
| Nature's Veil | B24NVEIL | SPWI307C |
| Bardic Inspiration | B24BINSP | SPENBARB |
| Divine Spark | B24DSPRK | SPPR612C |
| Turn Undead | B24TURNU | SPWI324C |
| Preserve Life | B24PRSLF | SPPR607C |
| Land's Aid | B24LAID | SPPR704C |
| Innate Sorcery | B24INSOR | SPWI222C |
| Class Feature | B24OPTN | SPWI419C |
| Cantrip | B24CANTP | SPWI112B |

#### Subclass features (72)

| Ability | Resref | Icon now (borrowed) |
| --- | --- | --- |
| Class Feature Choice | B24PICK | SPWI420C |
| Trip Attack | B24MTRIP | SPWI101C |
| Pushing Attack | B24MPUSH | SPWI212B |
| Menacing Attack | B24MMENA | SPWI204B |
| Disarming Attack | B24MDISA | SPWI207C |
| Distracting Strike | B24MDIST | SPWI105C |
| Goading Attack | B24MGOAD | SPWI123B |
| Feinting Attack | B24MFEIN | SPWI120C |
| Precision Attack | B24MPREC | SPCL121B |
| Lunging Attack | B24MLUNG | SPPR507C |
| Sweeping Attack | B24MSWEE | SPCL900B |
| Parry | B24MPARR | SPWI114C |
| Rally | B24MRALY | SPPR108C |
| Evasive Footwork | B24MEVAS | SPWI201B |
| Commander's Strike | B24MCOMM | SPPR412C |
| Psionic Strike | B24PSTRK | SPWI705C |
| Guarded Mind | B24PGMND | SPPR350C |
| Bulwark of Force | B24PBULW | SPWI602C |
| Branches of the Tree | B24WTBRN | SPWI215C |
| Warrior of the Gods | B24ZWARG | SPPR409C |
| Zealous Presence | B24ZPRES | OHTYR1C |
| Beguiling Magic | B24GBEGU | SPWI104B |
| Mantle of Inspiration | B24GMANT | SPPR201B |
| Mantle of Majesty | B24GMAJE | SPWI407B |
| Command | B24GCMND | SPPR102B |
| Unbreakable Majesty | B24GUNBR | SPPR613C |
| Radiance of the Dawn | B24LRADI | SPPR707C |
| Warding Flare | B24LWARD | SPPR105B |
| Corona of Light | B24LCORO | SPPR113B |
| Blessing of the Trickster | B24TBLES | SPWI205B |
| Invoke Duplicity | B24TDUPL | SPWI211B |
| Guided Strike | B24WGSTR | SPPR212B |
| War God's Blessing | B24WGBLS | OHTYR2C |
| War Priest | B24WPRST | OHTMPS2C |
| Wrath of the Sea | B24SWRAT | SPPR209B |
| Starry Form: Archer | B24STARC | SPCL239C |
| Starry Form: Chalice | B24STCHL | SPPR611C |
| Starry Form: Dragon | B24STDRG | SPWI922C |
| Luminous Arrow | B24STARW | SPWI615C |
| Hand of Harm | B24MHARM | SPPR109B |
| Hand of Healing | B24MHHEL | SPPR103C |
| Shadow Arts | B24MSART | SPWI815C |
| Cloak of Shadows | B24MCLOA | SPWI405B |
| Shadow Step | B24MSSTP | SPSD02C |
| Elemental Attunement | B24MATTN | SPWI702C |
| Elemental Burst | B24MBRST | SPWI404B |
| Inspiring Smite | B24GINSP | SPPR101B |
| Nature's Wrath | B24ANWRA | SPPR108B |
| Vow of Enmity | B24VVOWE | SPPR511C |
| Living Legend | B24GLEGD | SPPR203B |
| Elder Champion | B24AELDR | SPPR202B |
| Avenging Angel | B24VANGL | SPPR727C |
| Primal Companion | B24BEAST | PLYWOLFB |
| Psychic Blades | B24PSBLA | SPWI518C |
| Psychic Veil | B24PSVEL | SPWI721C |
| Create Spell Slot (1) | B24FOM1 | SPWI590C |
| Create Spell Slot (2) | B24FOM2 | SPWI591C |
| Create Spell Slot (3) | B24FOM3 | SPWI592C |
| Create Spell Slot (4) | B24FOM4 | SPWI593C |
| Create Spell Slot (5) | B24FOM5 | SPWI594C |
| Revelation in Flesh | B24AREVL | SPWI203B |
| Warping Implosion | B24AWARP | SPWI402B |
| Restore Balance | B24CBALN | SPPR104B |
| Bastion of Law | B24CBAST | SPWI406B |
| Trance of Order | B24CTRAN | SPWI414C |
| Clockwork Cavalcade | B24CCAVL | SPPR605C |
| Tides of Chaos | B24WTIDE | SPWI208B |
| Portent | B24PORTN | SPWI301B |
| The Third Eye | B24THEYE | SPWI425C |
| Speedy Recovery | B24GDURB | SPPR550C |
| Grapple | B24GGRAP | SPCL811B |
| Telekinetic Shove | B24GTELE | SPWI212C |

### Portrait (status) icons

BG shows states as small icons on the portraits (op142 with a STATDESC entry). The mod's states
have their own icons and status texts (STATDESC rows 207 and up, B24.UpdateIcons once a second for
the party). The images are 13x13 pixel art in `art/portraits` (prompts in
`docs/Portrait icon prompts.md`), converted by `perl tools/png2bam.pl --portrait art/portraits portraits`.

| State | File | Where it comes from |
| --- | --- | --- |
| Concentrating (on a spell) | B24PCONC | B24CONC.lua |
| Raging | B24PRAGE | Barbarian |
| Reckless Attack | B24PRECK | Barbarian |
| Exhaustion (any level) | B24PEXHA | B24REST.lua |
| Prone | B24PPRON | conditions (B24COND.lua) |
| Grappled | B24PGRAP | conditions |
| Restrained (this mod's own; web and entangle have BG icons) | B24PREST | conditions |
| Hunter's Mark (on the ranger, while a mark is up) | B24PHMRK | Ranger |
| Bardic Inspiration (holder) | B24PBINS | Bard |
| Divine Smite ready (toggle) | B24PSMIT | Paladin |
| Sacred Weapon | B24PSACW | Paladin |
| Holy Nimbus | B24PNIMB | Paladin |
| Dodging (attacks against have disadvantage) | B24PDODG | Monk and others |
| Starry Form | B24PSTAR | Druid, Circle of the Stars |
| Innate Sorcery | B24PINSO | Sorcerer |
| Temporary hit points | B24PTHP | several features |
| Portent rolls held | B24PPORT | Wizard, Diviner |
| Dying (death saves running) | B24PDYIN | B24DYING.lua |
| Stable | B24PSTAB | B24DYING.lua |

Left out: Weapon Mastery effects (Sap, Slow, Vex, Topple) land on enemies, which have no
portraits; advantage on the next attack has no lasting state to show.

## 2. Animations and visual effects for class features

The innates above fire with the generic casting glow. These would gain the most from a visual:

| Feature | Visual |
| --- | --- |
| Rage | red aura on the barbarian while raging |
| Divine Smite | radiant flash on the hit |
| Sneak Attack | small hit flash (so players see when it triggers) |
| Stunning Strike, Quivering Palm | hit flash, stun stars |
| Second Wind, Lay on Hands, Wholeness of Body | healing sparkle |
| Action Surge | short haste-like flash |
| Wild Shape | BG's polymorph look; the forms use BG's shapeshift and spirit animal icons |
| Starry Form | star constellation aura |
| Spirit Guardians | lasting spirit aura (see spells) |
| Psychic Blades, Psionic Strike | psychic flash |
| Elemental Burst (Monk) | elemental burst at the point |

## 3. Sounds

Besides the spell sounds listed above: a rage shout (Barbarian), a short sting for Bardic Inspiration,
a radiant hit for Divine Smite. All of them can start as vanilla sounds.

## 4. User interface

Done: the level-up choice popup and the character creation popups have a BG1 and a BG2 version
(BG2:EE uses the high-level ability window). Rule from now on: every new menu gets both versions,
checked by screenshot (tools/ingame-test.ps1).

Done (2026-10-27, `tools/ingame-test.ps1 -Mode Record`, screenshots in both games):
- The character record has a Features tab (lua/B24UI.lua): each class with its subclass and the
  features of every level so far, the uses left of each class resource and how they come back, the
  options and picks chosen, and the choices still waiting. Stats, Biography and Features share the
  row above the record's text panel.
- The B24_LEVELUP popup shows an icon per row where the choice has one: weapon masteries a plain
  weapon of the type, spells, cantrips and innate choices their spell icon. Lists without icons
  (subclasses, fighting styles, ability scores) keep the full-width names.
- BG:EE character creation, skills step: the lists follow the columns of the screen's art (the
  choice state in the middle panel, the source of each proficiency in the narrow box on the right).

Open:
- Subclasses and fighting styles have no icons of their own (the popup shows none for them).

## 5. What else is missing

### Found by the automated tests (2026-10-26)

| Item | Status |
| --- | --- |
| Wizards learn no spells on level-up (2024: two per level) | Done: the Spellbook choice tops the book up to 6 + 2 per level (scrolls count toward it) |
| A level 1 Wizard learns 3 spells in character creation (2024: 6) | Done: the Spellbook choice adds the missing ones at the start of the game |
| Cantrips are not chosen in character creation | Done: a Cantrips step on the skills screen of character creation |
| Multiclassing: not offered in character creation; the model (design options A–C) and the proficiency rule (highest class level vs total level) are undecided | Decided (design document): dual-class as 2024 multiclass for the player, BG multiclasses for companions, proficiency from total level, level-ups held back to the XP level; to build |
| Upcast copies of every known spell appeared at all spell levels (a level 3 Wizard's spellbook listed "Burning Hands (level 9)") | Done: copies only up to the highest level the caster has slots for; higher ones are removed |
| Monster pass skips creatures embedded in area files | Open |
| BG2: the character creation gender screen logs "attempt to call a nil value" every frame | Open, harmless so far; not from the mod's menu patches (every function the gender and main character creation menus call exists) |
| SoD item BDBLUN01: its school save bonus (op346) is not applied by B24SAVE.lua | Known |

### Found by the testing round (2026-10-27)

New test modes: Chargen with -LevelTo for every class (creation and level-ups 1–5 through the real
screens), Joining (companion copies join, are converted, and level up twice: single class through
the engine, multiclass through the class choice), SaveLoad (a pending choice and a pending level-up
are saved, loaded and compared; the test save is deleted).

| Item | Status |
| --- | --- |
| Cantrip choice with nothing to choose: the catalog has 2 Bard and 3 Cleric cantrips, fewer than a Bard or Cleric earns at level 4; the popup stayed open with an empty list | Fixed: the pending count is capped by the cantrips left on the caster's lists. Open: the catalog lacks the utility cantrips (Guidance, Light, Mending, Thaumaturgy, True Strike, ...) |
| Hit points: past the 2e limit the engine adds no Constitution modifier per level (BG2 Korgan, level 13: +6), and a higher modifier (Ability Score Improvement) did not count for earlier levels | Fixed: single classes get what is missing each second (B24MULTI.lua), permanent bonuses stay |
| Test drivers: priests' spell memorization, conversations (answered, and story dialogues switched off in world tests), the watchdog unpausing under choice popups | Fixed in the tests |

### Class features (2026-10-27)

Done (in-game test: `tools/ingame-test.ps1 -Mode Features`): Arcane Recovery, Memorize Spell,
Overchannel, Spell Mastery, Signature Spells (Wizard); Metamagic (7 of 10 options), Sorcery
Incarnate, Arcane Apotheosis, Dragon Wings, Clockwork Spells, Tamed Surge (Sorcerer); Magical
Secrets, Magical Discoveries, Peerless Skill, Superior Inspiration, Words of Creation (Bard); Divine
Intervention, Greater Divine Intervention (Cleric); Wild Companion, Wild Resurgence, Natural
Recovery, Nature's Sanctuary, Archdruid (Druid); Restoring Touch, Smite of Protection, Glorious
Defense (Paladin); Defensive Tactics, Superior Hunter's Prey, Superior Hunter's Defense, Exceptional
Training (Ranger); Cunning Strike, Improved Cunning Strike, Devious Strikes, Use Magic Device,
Thief's Reflexes (Rogue); Hand of Ultimate Mercy (Monk); Phantasmal Creatures (Wizard).

No BG form: Distant, Subtle and Twinned Spell (fixed ranges, components and targets); Dragon
Companion (no Summon Dragon spell); Psionic Spells
(none of these spells exist in BG); Escape the Horde (no opportunity attacks).

Approximated where BG has no reactions: Glorious Defense and Superior Hunter's Defense trigger by
themselves once per round; Peerless Skill works on saves (BG reports no failed checks or misses).

Fixed on the way: op101 immunities (Aura of Devotion and Courage, Nature's Ward, Monk, Elven Trance)
gave immunity to AC bonuses instead of to charm, fear, poison and sleep; summons (Primal Companion)
never appeared, as op67 had no target point.

### To do (from the 2024 coverage audit, docs/2024 Coverage.md)

- Take out BG's 2e Turn Undead (the engine's turning mode of Clerics and Paladins); the 2024 Turn
  Undead (Channel Divinity, B24TURNU) replaces it.
- Ritual spells: a ritual spell castable without a slot, with 10 minutes more casting time (in BG:
  a slow, slotless copy usable outside combat), for Wizards (Ritual Adept), Clerics, Druids, Bards
  and the Ritual Caster feat.
- Faerie Fire and the other missing spells of the audit (spells section).
- 2e spells in their 2024 form. Done (2026-10-27, `tools/ingame-test.ps1 -Mode Spells`): Magic
  Missile (3 darts +1 per level, B24DART), Chromatic Orb (spell attack, the type the target resists
  least), Scorching Ray (3 rays, each an attack, B24RAYS), Acid Arrow (attack, 4d4 + 2d4 later,
  half on a miss), Inflict Wounds (Con save, 2d10), Harm (14d6, Con save), Flame Strike (+5d6
  radiant), Shield of Faith (+2 AC on a creature), Color Spray (blinded a round) and Sleep (no hit
  dice limit). Second batch (2026-10-28, Spells test for Haste, Aid, Vampiric Touch, Ice Storm, Meteor
  Swarm and Power Word Kill): Haste (one target, +2 AC, Dex save advantage,
  lethargy), Aid (+5 HP), Stoneskin (B/P/S resistance), Death Ward (drop to 1 HP once), Protection
  from Energy (SPPR210 an hour), Command (no hit dice limit), Ice Storm and Meteor Swarm (B24AREA,
  once per creature), Cloudkill (5d8 poison), Incendiary Cloud (10d8), Power Word Kill (B24PWK) and
  Stun (B24PWS, repeat save), Bane (Cha save), Vampiric Touch (spell attack, heals half). Done later
  (2026-10-28): Aid on up to three creatures with upcasting (B24AID), Vampiric Touch again each round
  while concentrating (B24VTAGN). Protection from Energy: BG has one spell per element (the choice).
- Conditions in rounds. Done (Dying, Turns and Icons tests, 2026-10-28): in turn-based combat a dying creature
  makes its death save at the start of its turn, repeat saves come at the end of the creature's
  turn; Hold Person, Hold Monster, Blindness/Deafness, Fear, Ray of Enfeeblement, Slow and
  Confusion allow a repeat save each round (B24COND.lua); petrification restrains first and
  petrifies after failed Con saves (Flesh to Stone: 3 failures, gazes: 1), Greater Restoration
  cures it; Flesh to Stone ends with the caster's concentration (the stone stays only after the
  full minute). In turn-based combat effect durations count in rounds: effect time stands still
  during a turn and moves on by the turn's share of 6 seconds at its end (engine effects with an
  absolute end, timing 4096, and the mod's timers; Turns test checks it). Done later (2026-10-28):
  Greater Restoration no longer heals; repeat saves survive save and load (target variable B24RSDC,
  B24CD.RestoreRepeatSave). Power Word Stun has no save in BG (the mod adds one in Lua).
- The bugs of the audit: done (2026-10-28, see 2024 Coverage.md) (Tough for companions, concentration on save and load, Spirit Guardians
  concentration, hidden catalog spells, upcasting of the mod's new spells, War God's Blessing,
  Psi Warrior levels).

### To do (from the testing round, 2026-10-28)

- Magic Missile and Scorching Ray: done (2026-10-28): the first dart or ray hits the target, the
  others are free innates for a round (B24MDART, B24SRAY), aimed one by one. Not yet tried by hand.
- Spell ranges: done (2026-10-28): the catalog's RANGE column gives 113 spells their 2024 range.
  Measured (`-Mode RangeProbe`): a range unit is a foot of 6.4 world units (area coordinates, the same at any screen resolution; 5 ft = 32; touch stops
  at 33 between centres, range 60 at 382); a creature's sight is 448 = 70 ft, and casting
  needs the target in sight, so longer 2024 ranges work up to 70 ft.
- The mod's own distances: done (2026-10-28): auras and areas use B24.Feet(ft) (6.4 units per foot
  plus half a selection circle, B24CORE.lua) with each feature's 2024 radius (Intimidating
  Presence, Turn Undead, Preserve Life 30 ft; Cutting Words, Abjure Foes, Mantle of Inspiration
  60 ft; Spirit Guardians, Thunderwave 15 ft; Paladin aura 10/30 ft; ...). Melee adjacency stays
  80 (B24.ADJACENT, generous for large creatures' circles); a Reach weapon is 112. Searches for
  "enemies in sight" keep 400-450. Open: movement per round (B24.Config.moveSecondsPerRound,
  "about 30 ft") was not measured on this scale.
- Size, pushes and pulls: done (2026-10-28): B24.Size from the selection circle (Medium up to 3,
  Large up to 5, Huge up to 9, Gargantuan above; Enlarge/Reduce will shift it one step);
  B24.ForceMove moves a creature an exact 5, 10 or 15 ft (op124 to the nearest open spot) with the
  2024 size limits: Push mastery, Pushing Attack, Wrath of the Sea and Thorn Whip's 10-ft pull only
  Large or smaller, Crusher one size above the attacker; Thunderwave, Tavern Brawler, Telekinetic
  and Elemental Attunement any size. The circle thresholds are a guess, not measured.
- Enlarge/Reduce: done (2026-10-28): two spells (B24ENLRG, B24REDUC; druid copies SPPR219,
  SPPR220), concentration a minute, Constitution save for the other side: one size step,
  advantage or disadvantage on Strength saves, weapon hits +1d4 or -1d4 (at least 1). No Strength
  checks and no bigger look in BG. Polymorph and Shapechange take the size of their BG form.
- Path of the World Tree: done (2026-10-28). Vitality Surge was there already. Branches of the
  Tree pulls the creature next to the barbarian (an innate, not a reaction); Battering Roots
  Topples with Heavy or Versatile melee weapons (a prone target is pushed 10 ft; no extra reach);
  Travel Along the Tree is a 60-ft Dimension Door copy while raging, once per round (no group
  teleport).
- Moving a character from BG:EE to BG2:EE: done (2026-10-28). An export only carried the variables
  of the save the game was loaded from (EE keeps creature variables as op187 effects, written when
  saving), so choices made since were lost. Now the record screen's Done on the Export panel
  (B24_RecordDone) writes every mod variable used in the session into the character as permanent
  op402 effects (B24LOCL), removed again right after; in BG2:EE they restore the variables on import
  and are removed. Tested: `-Mode Export` (BG:EE) and `-Mode Chargen -Import B24TEXP` (BG2:EE):
  subclass, skills, background and species arrive. The game drops scroll cases, bags of holding and
  gem bags on import.
- Green ability scores on the record screen: done (2026-10-28). Not the mod's increases (they go
  into the base scores) but the social skills' dialogue bonus (B24PROF.lua: Charisma, Wisdom and
  Intelligence raised while a dialogue runs), which also starts when an NPC only tries to talk
  (Candlekeep's Imoen) and lasts up to 10 seconds. Opening the character record now ends it
  (B24_RecordOpened in the record's onopen).
- Level cap, Epic Boons, no HLAs: done (2026-10-28). XPLEVEL.2DA: levels 21-40 unreachable
  (original in B24EPXP.2DA); the 12 Epic Boons (B24GFEAT.lua) from level 19 in the improvement
  popup; past 20 each old BG level's XP brings one more choice; HLA tables at minimum level 99 (the
  ToB level-up screen waited for an HLA pick). Tested: `-Mode Chargen -Game BG2EE -Campaign ToB
  -LevelTo 20` (Fighter 18 to 20, 60 boon rows, no level 21, 3500000 XP = 2 boons pending).
  Open: characters already above 20 in old saves keep their levels; ToB joinable NPCs above 20
  in their CRE files (not checked); the record screen's next-level XP shows 99999999 at level 20.
- Tests: done (2026-10-28). SaveLoad waits for a conversation to end and finds BG2:EE's main menu
  after quitting (START_MAIN); both pass. BG2:EE's intro movies don't skip on Escape (they play to
  their end, about 80 s per new game); a faster Escape was tried and dropped, as Escape in the game
  world opens the game menu: the "menu over the game" seen in the tests. The one at Dying step 14
  in BG2:EE is probably the same (not confirmed: that run's log shows no Escape).

### Story (from the research, 2026-10-27)

- Level cap: done (2026-10-28, see above); was: single classes go past level 20; cap at 20 and give
  Epic Boons for XP beyond it.
- Dialogue checks on Strength and Dexterity: done (2026-10-28): the dialogue bonus (B24PROF.lua)
  also raises Strength by Athletics and Dexterity by the best of Acrobatics, Sleight of Hand and
  Stealth.
- The Wish dialogue: done (2026-10-28): BG2's genie offers better wishes above Wisdom 15; in its
  dialogue the party's Wisdom counts as at least 16 (B24PROF.lua, the dialogue bonus), so every
  wish is open as in 2024. Not tested in the game (needs a Wish cast).
- Slayer form and level drain: tested (2026-10-28). `-Mode Slayer` (BG2:EE): SPIN823 turns the
  protagonist into the Slayer, SPIN718A ends it (SPIN822 only opens the dialogue that does);
  level, class and proficiency stay, and everything is as before afterwards. In the form: 2024 AC
  22 (was 29: now held at most 22 like monsters, B24.IsSlayer by its animation), Strength 25, max
  HP +40, claws SLAYERW3, size Large. `-Mode Drain`:
  BG's level drain lowers level and features, Restoration brings them back (kept as in BG).
- Bhaalspawn powers: done (2026-10-28). Cure Light Wounds (SPIN101) heals as Cure Wounds (2d8 +
  casting modifier, B24HEAL); Vampiric Touch (SPIN106) is the 2024 spell (melee spell attack, 3d6,
  half back; Spells test). Slow Poison, Draw Upon Holy Might, Larloch's Minor Drain and Horror stay
  as in BG. The ability tomes stay as in BG (decided 2026-10-28).

### From the design document

- Out of scope by design: full 5e monster statblocks. (Bonus actions and reactions are in the
  turn-based mode since 2026-10-27.)

### Testing still to do

- Playtest the fights the balance report flags (`perl tools/balance.pl --areas`).
