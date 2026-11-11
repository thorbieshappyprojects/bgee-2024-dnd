# Icon briefs

One icon per spell, cantrip and innate ability the mod adds. Today each borrows a vanilla icon
(last column), so some look like other spells. Every row is one PNG to make.

## Workflow

1. Draw or generate the icon as a PNG (square, 64x64 or larger, transparent or dark background).
2. Save it as `art/icons/<PNG file>` with the exact name from the table (it is the spell's resref).
3. Run `perl tools/png2bam.pl art/icons icons`. It scales the PNG down to 32x32, reduces it to the
   game's palette and writes `icons/<RESREF>.bam` with a normal and a darker pressed frame.
4. Install as usual (`.\deploy.ps1`): the spell or ability uses its new icon in the spellbook and on
   the action bar. Icons without a PNG keep their borrowed icon, so the work can go one at a time.

Spell icons are the same in BG:EE and BG2:EE, so one icon serves both games.

## Style

- Match the game's own spell icons: hand-painted look, one strong motif in the middle, high
  contrast, soft edges, no text or letters. The icon must read at 32x32 pixels.
- Background transparent (or very dark): the action bar and spellbook draw their own frame.
- Colors by theme help players tell abilities apart at a glance:
  fire orange-red, cold pale blue, lightning white-blue, acid and poison green, radiant gold-white,
  necrotic sickly green-black, psychic violet, thunder grey-blue, healing green-white,
  martial abilities steel and red, nature abilities brown-green.
- Variants of one feature (the five "Create Spell Slot" levels, Starry Form's three forms) share a
  motif and differ by a number of pips or by color.

## Prompt template (for an AI image tool)

> Fantasy RPG ability icon in the style of Baldur's Gate spellbook icons, hand-painted, square,
> one centered motif: **<motif from "What it does">**, transparent dark background, soft vignette,
> no text, high contrast, readable when shrunk to 32x32 pixels.

Generate at 256x256 or 512x512 and let `tools/png2bam.pl` shrink it; small details vanish at 32x32,
so prefer one bold shape over a scene.

## Species and origin feats (8)

| PNG file | Name | What it does | Icon today |
| --- | --- | --- | --- |
| B24ADREN.png | Adrenaline Rush | Orc trait: for one round you move half again as fast, and you gain temporary hit points equal to your Proficiency Bonus for one minute (added to your maximum and current hit points). | SPWI305B |
| B24HEALR.png | Battle Medic | Healer feat: you tend a creature's wounds. | SPPR317C |
| B24HEALH.png | Healing Hands | Aasimar trait: touch a creature; it regains a number of d4 hit points equal to your Proficiency Bonus. | SPCL815C |
| B24GLFIR.png | Fire's Burn | Goliath trait (fire giant ancestry): your next weapon hit within one round deals an extra 1d10 fire damage. | SPWI418C |
| B24GLFRO.png | Frost's Chill | Goliath trait (frost giant ancestry): your next weapon hit within one round deals an extra 1d6 cold damage and slows the target for one round. | SPWI404C |
| B24GLHIL.png | Hill's Tumble | Goliath trait (hill giant ancestry): your next weapon hit within one round knocks the target prone for one round. | SPPR312C |
| B24GLSTO.png | Stone's Endurance | Goliath trait (stone giant ancestry): the next damage you take within one round is reduced by 1d12 + your Constitution modifier. | SPPR506C |
| B24GLSTM.png | Storm's Thunder | Goliath trait (storm giant ancestry): the next creature that damages you within one round takes 1d8 thunder damage (in BG: lightning). | SPCL721C |

## Core rules (1)

| PNG file | Name | What it does | Icon today |
| --- | --- | --- | --- |
| B24SREST.png | Short Rest | The party rests for one hour. | SPPR103B |

## Class features (38)

| PNG file | Name | What it does | Icon today |
| --- | --- | --- | --- |
| B24SWIND.png | Second Wind | Fighter feature: you regain 1d10 + your Fighter level hit points. | SPPR315C |
| B24ASURG.png | Action Surge | Fighter feature: for one round you make another full set of attacks, and your spells are cast faster. | SPWI613C |
| B24TMAST.png | Tactical Master | Fighter feature (level 9): switch the mastery property your mastered weapons use: their own, Push, Sap or Slow. | ENCHAXEC |
| B24ASI.png | Ability Score Improvement | Raise one ability score by 2, or two ability scores by 1 each, to at most 20. | SPWI408B |
| B24FSTY.png | Fighting Style | Choose a Fighting Style feat: Archery, Defense, Great Weapon Fighting or Two-Weapon Fighting. | SPDWD02C |
| B24WMAS.png | Weapon Mastery | Choose another weapon whose mastery property you can use. | ENCHSSWC |
| B24SUBC.png | Subclass | Choose your subclass (Fighter: level 3). | SPWI515C |
| B24RAGE.png | Rage | Barbarian feature: for one minute you deal extra damage with Strength (melee) attacks, resist slashing, crushing and piercing damage, and have advantage on Strength saving throws. | SPCL152B |
| B24RECKL.png | Reckless Attack | Barbarian feature: for one round your attacks have advantage, and attacks against you have advantage too. | SPIN117C |
| B24INTIM.png | Intimidating Presence | Berserker feature (level 14): enemies around you make a Wisdom saving throw or are frightened for one minute. | SPPR416C |
| B24CUNNG.png | Cunning Action | Rogue feature: you Dash, moving twice as fast for a round. | SPPR403C |
| B24STAIM.png | Steady Aim | Rogue feature (level 3): you stand still and aim; your next attack this round has advantage. | SPWI424C |
| B24EXPRT.png | Expertise | Choose a skill or tool you are proficient in; your proficiency bonus is doubled for it. | SPWI110C |
| B24FLURY.png | Flurry of Blows | Monk feature (1 Focus Point): extra unarmed strikes this round (two from level 10). | SPCL238C |
| B24PDEF.png | Patient Defense | Monk feature (1 Focus Point): attacks against you have disadvantage for a round. | SPCL522C |
| B24STEPW.png | Step of the Wind | Monk feature (1 Focus Point): you move twice as fast for a round. | SPWI921C |
| B24STUN.png | Stunning Strike | Monk feature (level 5, 1 Focus Point): your next hit this round forces a Constitution save or stuns the target for a round. | SPCL811C |
| B24UMETA.png | Uncanny Metabolism | Monk feature (level 2): regain all Focus Points and heal your Martial Arts die + Monk level. | SPPR711C |
| B24WHOLE.png | Wholeness of Body | Warrior of the Open Hand (level 6): heal your Martial Arts die + Wisdom modifier. | SPPR502C |
| B24SUPDF.png | Superior Defense | Monk feature (level 18, 3 Focus Points): resistance to all damage except force for one minute. | SPWI408C |
| B24QPALM.png | Quivering Palm | Warrior of the Open Hand (level 17, 4 Focus Points): touch a creature; it makes a Constitution save or takes 10d12 force damage (half on a success). | SPCL820C |
| B24LOH.png | Lay on Hands | Paladin feature: touch a creature to heal it from your pool of healing (5 x Paladin level hit points per long rest). | SPCL815B |
| B24SMITE.png | Divine Smite | Paladin feature (level 2): switch Divine Smite on or off. | SPPR313C |
| B24SACWP.png | Sacred Weapon | Oath of Devotion (Channel Divinity): add your Charisma modifier (at least +1) to attack rolls for 10 minutes. | SPPR206C |
| B24ABJUR.png | Abjure Foes | Paladin feature (level 9, Channel Divinity): enemies around you make a Wisdom save or are frightened for one minute. | SPPR515C |
| B24NIMBS.png | Holy Nimbus | Oath of Devotion (level 20): for 10 minutes, enemies near you take radiant damage equal to your Charisma modifier + Proficiency Bonus every round. | SPCL237B |
| B24HMARK.png | Hunter's Mark | Ranger feature (Favored Enemy): mark a creature for an hour; your weapon hits against it deal 1d6 extra damage (1d10 at level 20). | SPPR415C |
| B24TIRLS.png | Tireless | Ranger feature (level 10): gain 1d8 + Wisdom modifier temporary hit points. | SPPR201C |
| B24NVEIL.png | Nature's Veil | Ranger feature (level 14): you become invisible until the end of your next round. | SPWI307C |
| B24BINSP.png | Bardic Inspiration | Bard feature: inspire an ally; it adds your Bardic Inspiration die (d6, d8 at level 5, d10 at 10, d12 at 15) to its next failed saving throw within an hour. | SPENBARB |
| B24DSPRK.png | Divine Spark | Cleric feature (Channel Divinity): an ally regains 1d8 + Wisdom modifier hit points, or an enemy makes a Constitution save and takes that much radiant damage (half on a success). | SPPR612C |
| B24TURNU.png | Turn Undead | Cleric feature (Channel Divinity): undead near you make a Wisdom save or are turned for a minute. | SPWI324C |
| B24PRSLF.png | Preserve Life | Life Domain (Channel Divinity): party members near you regain up to 5 x Cleric level hit points in total, but none above half its maximum. | SPPR607C |
| B24LAID.png | Land's Aid | Circle of the Land: enemies around the target make a Constitution save or take 2d6 necrotic damage (half on a success), and the target (if it is an ally) or you regain 2d6 hit points. | SPPR704C |
| B24INSOR.png | Innate Sorcery | Sorcerer feature: for one minute your spell save DC rises by 1 and your spell attacks have advantage. | SPWI222C |
| B24OPTN.png | Class Feature | Choose an option of a class feature (for example Divine Order or Primal Order). | SPWI419C |
| B24CANTP.png | Cantrip | Choose a cantrip. Cantrips are innate abilities you can use at will. | SPWI112B |
| B24SPBK.png | Spellbook | Add a wizard spell to your spellbook. | SPWI110B |

## Spells (10)

| PNG file | Name | What it does | Icon today |
| --- | --- | --- | --- |
| B24HWORD.png | Healing Word | Level 1, Casting Time: 1 action A creature you can see regains 2d4 + your spellcasting ability modifier hit points. | SPPR401C |
| B24HWBRD.png | Healing Word | Level 1, Casting Time: 1 action A creature you can see regains 2d4 + your spellcasting ability modifier hit points. | SPPR401C |
| B24CWBRD.png | Cure Wounds | Level 1, Casting Time: 1 action A creature you touch regains 2d8 + your spellcasting ability modifier hit points. | SPPR103B |
| B24GBOLT.png | Guiding Bolt | Level 1, Casting Time: 1 action Make a ranged spell attack: 4d6 radiant damage, and the next attack against the target before the end of the next round has advantage. | SPPR614C |
| B24THWAV.png | Thunderwave | Level 1, Casting Time: 1 action Enemies around you make a Constitution saving throw: 2d8 thunder damage and pushed away on a failure, half damage on a success. | SPWI621C |
| B24THWVD.png | Thunderwave | Level 1, Casting Time: 1 action Enemies around you make a Constitution saving throw: 2d8 thunder damage and pushed away on a failure, half damage on a success. | SPWI621C |
| B24SHATR.png | Shatter | Level 2, Casting Time: 1 action The target and enemies near it make a Constitution saving throw: 3d8 thunder damage, half on a success. | SPWI913C |
| B24SPGRD.png | Spirit Guardians | Level 3, Casting Time: 1 action For one minute, enemies near you make a Wisdom saving throw every round: 3d8 radiant damage, half on a success. | SPPR150C |
| B24MHWRD.png | Mass Healing Word | Level 3, Casting Time: 1 action You and your allies nearby regain 2d4 + your spellcasting ability modifier hit points. | SPPR514C |
| B24MHWBD.png | Mass Healing Word | Level 3, Casting Time: 1 action You and your allies nearby regain 2d4 + your spellcasting ability modifier hit points. | SPPR514C |

## Cantrips (14)

| PNG file | Name | What it does | Icon today |
| --- | --- | --- | --- |
| B24CACID.png | Acid Splash | A creature makes a Dexterity saving throw or takes 1d6 acid damage (more dice at character levels 5, 11 and 17). | SPWI313C |
| B24CCHIL.png | Chill Touch | Make a melee spell attack: 1d10 necrotic damage (more dice at character levels 5, 11 and 17). | SPWI117C |
| B24CFIRE.png | Fire Bolt | Make a ranged spell attack: 1d10 fire damage (more dice at character levels 5, 11 and 17). | SPPR106C |
| B24CPOIS.png | Poison Spray | Make a ranged spell attack: 1d12 poison damage (more dice at character levels 5, 11 and 17). | SPWI213C |
| B24CFROS.png | Ray of Frost | Make a ranged spell attack: 1d8 cold damage and the target is slowed for a round (more dice at character levels 5, 11 and 17). | SPWI320C |
| B24CSHOC.png | Shocking Grasp | Make a melee spell attack: 1d8 lightning damage (more dice at character levels 5, 11 and 17). | SPWI115C |
| B24CBURS.png | Sorcerous Burst | Make a ranged spell attack: 1d8 fire damage (more dice at character levels 5, 11 and 17). | SPWI112C |
| B24CSACR.png | Sacred Flame | A creature makes a Dexterity saving throw or takes 1d8 radiant damage (more dice at character levels 5, 11 and 17). | SPPR450C |
| B24CTOLL.png | Toll the Dead | A creature makes a Wisdom saving throw or takes 1d8 necrotic damage, 1d12 if it is missing hit points (more dice at character levels 5, 11 and 17). | SPWI119C |
| B24CWORD.png | Word of Radiance | Enemies next to you make a Constitution saving throw or take 1d6 radiant damage (more dice at character levels 5, 11 and 17). | SPCL236C |
| B24CFLAM.png | Produce Flame | Make a ranged spell attack: 1d8 fire damage (more dice at character levels 5, 11 and 17). | SPPR503C |
| B24CTHRN.png | Thorn Whip | Make a melee spell attack at reach: 1d6 piercing damage (more dice at character levels 5, 11 and 17). | SPPR105C |
| B24CWISP.png | Starry Wisp | Make a ranged spell attack: 1d8 radiant damage (more dice at character levels 5, 11 and 17). | SPPR751C |
| B24CMOCK.png | Vicious Mockery | A creature makes a Wisdom saving throw or takes 1d6 psychic damage and has disadvantage on its next attack (more dice at character levels 5, 11 and 17). | SPWI411C |

## Subclass features (72)

| PNG file | Name | What it does | Icon today |
| --- | --- | --- | --- |
| B24PICK.png | Class Feature Choice | Opens the choice of a class feature you have earned but not chosen yet (maneuvers, spells known). | SPWI420C |
| B24MTRIP.png | Trip Attack | Battle Master maneuver (one Superiority Die): your next hit this round deals the die as extra damage, and the target makes a Strength save or falls prone. | SPWI101C |
| B24MPUSH.png | Pushing Attack | Battle Master maneuver (one Superiority Die): your next hit this round deals the die as extra damage, and the target makes a Strength save or is pushed 15 feet away. | SPWI212B |
| B24MMENA.png | Menacing Attack | Battle Master maneuver (one Superiority Die): your next hit this round deals the die as extra damage, and the target makes a Wisdom save or is frightened until the end of your next round. | SPWI204B |
| B24MDISA.png | Disarming Attack | Battle Master maneuver (one Superiority Die): your next hit this round deals the die as extra damage, and the target makes a Strength save or fumbles its weapon (its attacks have disadvantage until the end of the next ro... | SPWI207C |
| B24MDIST.png | Distracting Strike | Battle Master maneuver (one Superiority Die): your next hit this round deals the die as extra damage, and the next attack against the target by someone else this round has advantage. | SPWI105C |
| B24MGOAD.png | Goading Attack | Battle Master maneuver (one Superiority Die): your next hit this round deals the die as extra damage, and the target makes a Wisdom save or has disadvantage on attacks against anyone but you until the end of your next ro... | SPWI123B |
| B24MFEIN.png | Feinting Attack | Battle Master maneuver (one Superiority Die): your next attack this round has advantage, and a hit deals the die as extra damage. | SPWI120C |
| B24MPREC.png | Precision Attack | Battle Master maneuver (one Superiority Die): roll the die and add it to your attack rolls for the rest of this round. | SPCL121B |
| B24MLUNG.png | Lunging Attack | Battle Master maneuver (one Superiority Die): you move faster this round, and your next hit deals the die as extra damage. | SPPR507C |
| B24MSWEE.png | Sweeping Attack | Battle Master maneuver (one Superiority Die): when your next melee attack this round hits, another enemy next to the target takes the die as damage. | SPCL900B |
| B24MPARR.png | Parry | Battle Master maneuver (one Superiority Die): the next melee hit against you this round deals the die plus your Strength or Dexterity modifier less damage. | SPWI114C |
| B24MRALY.png | Rally | Battle Master maneuver (one Superiority Die): an ally or you gains temporary hit points equal to the die plus your Charisma modifier. | SPPR108C |
| B24MEVAS.png | Evasive Footwork | Battle Master maneuver (one Superiority Die): add the die to your Armor Class for the rest of this round. | SPWI201B |
| B24MCOMM.png | Commander's Strike | Battle Master maneuver (one Superiority Die): an ally makes one extra attack this round, and its next hit deals the die as extra damage. | SPPR412C |
| B24PSTRK.png | Psionic Strike | Psi Warrior (one Psionic Energy Die): your next weapon hit this round deals the die plus your Intelligence modifier in force damage. | SPWI705C |
| B24PGMND.png | Guarded Mind | Psi Warrior (one Psionic Energy Die): you shake off fear. | SPPR350C |
| B24PBULW.png | Bulwark of Force | Psi Warrior: you and up to your Intelligence modifier allies within 30 feet gain +2 Armor Class for a minute. | SPWI602C |
| B24WTBRN.png | Branches of the Tree | Path of the World Tree, while raging, once per round: a creature within 30 feet makes a Strength save or can't move for a round. | SPWI215C |
| B24ZWARG.png | Warrior of the Gods | Path of the Zealot: spend one of your d12s and regain that many hit points. | SPPR409C |
| B24ZPRES.png | Zealous Presence | Path of the Zealot: you and your allies within 60 feet have advantage on attacks and saves for a round. | OHTYR1C |
| B24GBEGU.png | Beguiling Magic | College of Glamour: a creature within 60 feet makes a Wisdom save against your spell save DC or is frightened for a minute. | SPWI104B |
| B24GMANT.png | Mantle of Inspiration | College of Glamour (one Bardic Inspiration): up to your Charisma modifier allies within 60 feet gain twice a roll of your Bardic Inspiration die as temporary hit points. | SPPR201B |
| B24GMAJE.png | Mantle of Majesty | College of Glamour: for a minute you can command a creature each round (the Command innate). | SPWI407B |
| B24GCMND.png | Command | Mantle of Majesty, once per round: a creature makes a Wisdom save against your spell save DC or falls prone for a round. | SPPR102B |
| B24GUNBR.png | Unbreakable Majesty | College of Glamour: for a minute attacks against you have disadvantage. | SPPR613C |
| B24LRADI.png | Radiance of the Dawn | Light Domain (Channel Divinity): enemies within 30 feet make a Constitution save or take 2d10 + your Cleric level radiant damage, half on a success. | SPPR707C |
| B24LWARD.png | Warding Flare | Light Domain: for a round, attacks against you or an ally within 30 feet have disadvantage. | SPPR105B |
| B24LCORO.png | Corona of Light | Light Domain: for a minute, enemies within 60 feet have disadvantage on saves against your spells and Channel Divinity. | SPPR113B |
| B24TBLES.png | Blessing of the Trickster | Trickery Domain: a creature you touch gets better at moving silently and hiding for an hour (standing in for advantage on Stealth). | SPWI205B |
| B24TDUPL.png | Invoke Duplicity | Trickery Domain (Channel Divinity): an illusory double of you flickers next to your foes; for a minute you have advantage on attacks. | SPWI211B |
| B24WGSTR.png | Guided Strike | War Domain (Channel Divinity): +10 to your attack rolls this round. | SPPR212B |
| B24WGBLS.png | War God's Blessing | War Domain (Channel Divinity): an ally within 30 feet gets +10 to its attack rolls this round. | OHTYR2C |
| B24WPRST.png | War Priest | War Domain: one extra attack this round. | OHTMPS2C |
| B24SWRAT.png | Wrath of the Sea | Circle of the Sea (one Wild Shape use): for 10 minutes, each round an enemy next to you makes a Constitution save or takes cold damage (Wisdom modifier d6) and is pushed away. | SPPR209B |
| B24STARC.png | Starry Form: Archer | Circle of the Stars (one Wild Shape use): for 10 minutes you shine with the Archer; each round you can loose a Luminous Arrow. | SPCL239C |
| B24STCHL.png | Starry Form: Chalice | Circle of the Stars (one Wild Shape use): for 10 minutes you shine with the Chalice; your healing spells also heal the most hurt ally near you. | SPPR611C |
| B24STDRG.png | Starry Form: Dragon | Circle of the Stars (one Wild Shape use): for 10 minutes you shine with the Dragon; a Constitution save never counts its d20 below 10. | SPWI922C |
| B24STARW.png | Luminous Arrow | Starry Form (Archer), once per round: a ranged spell attack that deals 1d8 + your Wisdom modifier radiant damage (2d8 from level 10). | SPWI615C |
| B24MHARM.png | Hand of Harm | Warrior of Mercy (one Focus Point): your next unarmed hit this round deals a Martial Arts die + your Wisdom modifier necrotic damage. | SPPR109B |
| B24MHHEL.png | Hand of Healing | Warrior of Mercy (one Focus Point): the creature you touch regains a Martial Arts die + your Wisdom modifier hit points. | SPPR103C |
| B24MSART.png | Shadow Arts | Warrior of Shadow (one Focus Point): shadows hide you; you are invisible for a minute or until you attack. | SPWI815C |
| B24MCLOA.png | Cloak of Shadows | Warrior of Shadow (three Focus Points): improved invisibility for a minute. | SPWI405B |
| B24MSSTP.png | Shadow Step | Warrior of Shadow, once per round: you slip through the shadows, move fast for a moment and have advantage on your next melee attack. | SPSD02C |
| B24MATTN.png | Elemental Attunement | Warrior of the Elements (one Focus Point): for 10 minutes your unarmed hits deal cold damage and push the target 10 feet (Strength save). | SPWI702C |
| B24MBRST.png | Elemental Burst | Warrior of the Elements (two Focus Points): a creature and those around it make a Dexterity save or take three Martial Arts dice of cold damage, half on a success. | SPWI404B |
| B24GINSP.png | Inspiring Smite | Oath of Glory (Channel Divinity): you and your allies within 30 feet share 2d8 + your Paladin level temporary hit points. | SPPR101B |
| B24ANWRA.png | Nature's Wrath | Oath of the Ancients (Channel Divinity): enemies within 15 feet make a Strength save or are restrained by spectral vines for a minute (a new save at the end of each round). | SPPR108B |
| B24VVOWE.png | Vow of Enmity | Oath of Vengeance (Channel Divinity): for a minute you have advantage on attacks against the creature. | SPPR511C |
| B24GLEGD.png | Living Legend | Oath of Glory: for a minute, once per round you reroll a failed save. | SPPR203B |
| B24AELDR.png | Elder Champion | Oath of the Ancients: for a minute you regain 10 hit points each round, and enemies in your aura have disadvantage on saves against your spells and Channel Divinity. | SPPR202B |
| B24VANGL.png | Avenging Angel | Oath of Vengeance: for 10 minutes, enemies that come within 30 feet make a Wisdom save or are frightened for a minute; attacks against them have advantage. | SPPR727C |
| B24BEAST.png | Primal Companion | Beast Master: summon your beast of the land, a wolf whose strength grows with your Ranger level. | PLYWOLFB |
| B24PSBLA.png | Psychic Blades | Soulknife: a blade of psychic energy forms in your hand for an hour (1d6, finesse, magical). | SPWI518C |
| B24PSVEL.png | Psychic Veil | Soulknife: you are invisible for an hour or until you attack. | SPWI721C |
| B24FOM1.png | Create Spell Slot (1) | Font of Magic (2 Sorcery Points): a spent level 1 spell slot returns. | SPWI590C |
| B24FOM2.png | Create Spell Slot (2) | Font of Magic (3 Sorcery Points): a spent level 2 spell slot returns. | SPWI591C |
| B24FOM3.png | Create Spell Slot (3) | Font of Magic (5 Sorcery Points): a spent level 3 spell slot returns. | SPWI592C |
| B24FOM4.png | Create Spell Slot (4) | Font of Magic (6 Sorcery Points): a spent level 4 spell slot returns. | SPWI593C |
| B24FOM5.png | Create Spell Slot (5) | Font of Magic (7 Sorcery Points): a spent level 5 spell slot returns. | SPWI594C |
| B24AREVL.png | Revelation in Flesh | Aberrant Sorcery (one Sorcery Point): for 10 minutes you see invisible creatures and move faster. | SPWI203B |
| B24AWARP.png | Warping Implosion | Aberrant Sorcery: space folds around you; enemies within 30 feet make a Strength save or take 3d10 force damage, half on a success. | SPWI402B |
| B24CBALN.png | Restore Balance | Clockwork Sorcery: for a round, attacks against an ally within 30 feet can't have advantage. | SPPR104B |
| B24CBAST.png | Bastion of Law | Clockwork Sorcery: spend up to 5 Sorcery Points; an ally within 30 feet gains that many d8 temporary hit points. | SPWI406B |
| B24CTRAN.png | Trance of Order | Clockwork Sorcery: for a minute, attacks against you can't have advantage and your saves never count their d20 below 10. | SPWI414C |
| B24CCAVL.png | Clockwork Cavalcade | Clockwork Sorcery: allies within 30 feet share up to 100 hit points of healing. | SPPR605C |
| B24WTIDE.png | Tides of Chaos | Wild Magic Sorcery: advantage on your attacks and saves for a round. | SPWI208B |
| B24PORTN.png | Portent | Diviner: the creature's next save uses one of your Portent rolls (the lowest for enemies, the highest for allies). | SPWI301B |
| B24THEYE.png | The Third Eye | Diviner: you see invisible creatures for an hour. | SPWI425C |
| B24GDURB.png | Speedy Recovery | Durable feat, once per short rest: spend one of your Hit Point Dice and regain its roll plus your Constitution modifier in hit points. | SPPR550C |
| B24GGRAP.png | Grapple | Grappler feat, once per round: a creature next to you makes a Strength or Dexterity save or is grappled (it can't move and saves again at the end of each round). | SPCL811B |
| B24GTELE.png | Telekinetic Shove | Telekinetic feat, once per round: a creature within 30 feet makes a Strength save against your spell save DC or is pushed 5 feet. | SPWI212C |
