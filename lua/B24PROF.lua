-- BG 2024 Rules Mod: skill, tool and weapon proficiencies.
--
-- Skills: the 2024 skills plus Thieves' Tools. A creature is proficient through its class choice,
-- background, species and feats; Expertise doubles the proficiency bonus. The BG thief skills are
-- derived from the 2024 check bonus (ability modifier + proficiency):
--   Stealth -> Hide in Shadows, Move Silently   Sleight of Hand -> Pick Pockets
--   Thieves' Tools -> Open Locks, Set Traps, disarming traps
--   Perception -> finding traps                 Investigation -> Detect Illusion
--   Arcana / History -> bonus to Lore
--
-- Weapons: the class decides Simple/Martial proficiency (B24WEAP.2DA classifies BG weapon types).
-- Attacks with a weapon the class isn't proficient with lose the proficiency bonus.
--
-- Chosen skills are stored in creature locals by character creation (bit i = B24.SKILLS[i]):
--   B24SKILL  class skill choices     B24SKEXP  Expertise choices     B24SKSET  1 once chosen
-- Characters without a choice (companions, older saves) get the class defaults below.

B24.SKILLS = {
	{ key = "ACROBATICS",      name = "Acrobatics",      ability = "DEX" },
	{ key = "ANIMAL_HANDLING", name = "Animal Handling", ability = "WIS" },
	{ key = "ARCANA",          name = "Arcana",          ability = "INT" },
	{ key = "ATHLETICS",       name = "Athletics",       ability = "STR" },
	{ key = "DECEPTION",       name = "Deception",       ability = "CHA" },
	{ key = "HISTORY",         name = "History",         ability = "INT" },
	{ key = "INSIGHT",         name = "Insight",         ability = "WIS" },
	{ key = "INTIMIDATION",    name = "Intimidation",    ability = "CHA" },
	{ key = "INVESTIGATION",   name = "Investigation",   ability = "INT" },
	{ key = "MEDICINE",        name = "Medicine",        ability = "WIS" },
	{ key = "NATURE",          name = "Nature",          ability = "INT" },
	{ key = "PERCEPTION",      name = "Perception",      ability = "WIS" },
	{ key = "PERFORMANCE",     name = "Performance",     ability = "CHA" },
	{ key = "PERSUASION",      name = "Persuasion",      ability = "CHA" },
	{ key = "RELIGION",        name = "Religion",        ability = "INT" },
	{ key = "SLEIGHT_OF_HAND", name = "Sleight of Hand", ability = "DEX" },
	{ key = "STEALTH",         name = "Stealth",         ability = "DEX" },
	{ key = "SURVIVAL",        name = "Survival",        ability = "WIS" },
	{ key = "THIEVES_TOOLS",   name = "Thieves' Tools",  ability = "DEX", tool = true },
}
B24.SkillIndex = {}
for i, skill in ipairs(B24.SKILLS) do B24.SkillIndex[skill.key] = i end

local ALL_SKILLS = {}
for _, skill in ipairs(B24.SKILLS) do
	if not skill.tool then table.insert(ALL_SKILLS, skill.key) end
end

-- 2024 class skill choices: how many, from which list, and the defaults for characters that
-- never chose (first entries = what a companion of that class gets).
B24.CLASS_SKILLS = {
	BARBARIAN = { count = 2, list = { "ATHLETICS", "PERCEPTION", "ANIMAL_HANDLING", "INTIMIDATION", "NATURE", "SURVIVAL" } },
	BARD      = { count = 3, list = ALL_SKILLS, defaults = { "PERCEPTION", "SLEIGHT_OF_HAND", "PERSUASION" } },
	CLERIC    = { count = 2, list = { "INSIGHT", "RELIGION", "HISTORY", "MEDICINE", "PERSUASION" } },
	DRUID     = { count = 2, list = { "NATURE", "PERCEPTION", "ARCANA", "ANIMAL_HANDLING", "INSIGHT", "MEDICINE", "RELIGION", "SURVIVAL" } },
	FIGHTER   = { count = 2, list = { "ATHLETICS", "PERCEPTION", "ACROBATICS", "ANIMAL_HANDLING", "HISTORY", "INSIGHT", "INTIMIDATION", "PERSUASION", "SURVIVAL" } },
	MONK      = { count = 2, list = { "STEALTH", "ACROBATICS", "ATHLETICS", "HISTORY", "INSIGHT", "RELIGION" } },
	PALADIN   = { count = 2, list = { "ATHLETICS", "PERSUASION", "INSIGHT", "INTIMIDATION", "MEDICINE", "RELIGION" } },
	RANGER    = { count = 3, list = { "STEALTH", "PERCEPTION", "SURVIVAL", "ANIMAL_HANDLING", "ATHLETICS", "INSIGHT", "INVESTIGATION", "NATURE" } },
	ROGUE     = { count = 4, list = { "STEALTH", "SLEIGHT_OF_HAND", "PERCEPTION", "INVESTIGATION", "ACROBATICS", "ATHLETICS", "DECEPTION", "INSIGHT", "INTIMIDATION", "PERSUASION" },
	              tools = { "THIEVES_TOOLS" }, expertise = 2, expertiseDefaults = { "STEALTH", "THIEVES_TOOLS" } },
	SORCERER  = { count = 2, list = { "ARCANA", "PERSUASION", "DECEPTION", "INSIGHT", "INTIMIDATION", "RELIGION" } },
	WIZARD    = { count = 2, list = { "ARCANA", "INVESTIGATION", "HISTORY", "INSIGHT", "MEDICINE", "NATURE", "RELIGION" } },
}

-- CLASS.IDS -> 2024 class for skills (multiclasses use their first class, as in 2024 where the
-- skill choice comes from the starting class), and weapon proficiency (multiclasses combine).
B24.CLASS_MAP = {
	[1]  = { skills = "WIZARD",   weapons = { "WIZARD" } },
	[2]  = { skills = "FIGHTER",  weapons = { "FIGHTER" } },
	[3]  = { skills = "CLERIC",   weapons = { "CLERIC" } },
	[4]  = { skills = "ROGUE",    weapons = { "ROGUE" } },
	[5]  = { skills = "BARD",     weapons = { "BARD" } },
	[6]  = { skills = "PALADIN",  weapons = { "PALADIN" } },
	[7]  = { skills = "FIGHTER",  weapons = { "FIGHTER", "WIZARD" } },
	[8]  = { skills = "FIGHTER",  weapons = { "FIGHTER", "CLERIC" } },
	[9]  = { skills = "FIGHTER",  weapons = { "FIGHTER", "ROGUE" } },
	[10] = { skills = "FIGHTER",  weapons = { "FIGHTER", "WIZARD", "ROGUE" } },
	[11] = { skills = "DRUID",    weapons = { "DRUID" } },
	[12] = { skills = "RANGER",   weapons = { "RANGER" } },
	[13] = { skills = "WIZARD",   weapons = { "WIZARD", "ROGUE" } },
	[14] = { skills = "CLERIC",   weapons = { "CLERIC", "WIZARD" } },
	[15] = { skills = "CLERIC",   weapons = { "CLERIC", "ROGUE" } },
	[16] = { skills = "FIGHTER",  weapons = { "FIGHTER", "DRUID" } },
	[17] = { skills = "FIGHTER",  weapons = { "FIGHTER", "WIZARD", "CLERIC" } },
	[18] = { skills = "CLERIC",   weapons = { "CLERIC", "RANGER" } },
	[19] = { skills = "SORCERER", weapons = { "SORCERER" } },
	[20] = { skills = "MONK",     weapons = { "MONK" } },
	[21] = { skills = "DRUID",    weapons = { "DRUID" } },
}

-- Martial weapons a class may use with proficiency: true = all, or a property the weapon needs.
B24.CLASS_WEAPONS = {
	BARBARIAN = { martial = true }, FIGHTER = { martial = true }, PALADIN = { martial = true },
	RANGER = { martial = true }, ROGUE = { martial = "LIGHT_OR_FINESSE" }, MONK = { martial = "LIGHT" },
	BARD = {}, CLERIC = {}, DRUID = {}, SORCERER = {}, WIZARD = {},
}

-- Rogue class components of BG multiclasses, for Thieves' Tools and Expertise.
function B24.ClassHasRogue(classID)
	for _, class in ipairs((B24.CLASS_MAP[classID] or {}).weapons or {}) do
		if class == "ROGUE" then return true end
	end
	return false
end

function B24.SkillClass(sprite)
	-- A story creature has no 2024 class (no features applied, B24LEVEL.lua).
	if B24.IsStoryCreature(sprite) then return nil end
	if sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN then return "BARBARIAN" end
	local map = B24.CLASS_MAP[B24.ClassID(sprite)]
	return map and map.skills
end

------------
-- Skills --
------------

local function addAll(set, keys)
	for _, key in ipairs(keys or {}) do set[key] = true end
end

local function maskToSet(mask, set)
	for i, skill in ipairs(B24.SKILLS) do
		if EEex_IsBitSet(mask, i - 1) then set[skill.key] = true end
	end
end

function B24.SkillsToMask(keys)
	local mask = 0
	for key in pairs(keys) do mask = EEex_BOr(mask, EEex_LShift(1, B24.SkillIndex[key] - 1)) end
	return mask
end

-- Proficiencies granted without a choice: background, species, class tools. Other components
-- (character creation) add theirs through listeners: listener(sprite, set).
B24.GrantedSkillListeners = {}
function B24.AddGrantedSkillListener(listener) table.insert(B24.GrantedSkillListeners, listener) end

-- Returns { [key] = true } of proficient skills and tools, and the same for Expertise.
function B24.Proficiencies(sprite)
	local proficient, expert = {}, {}
	local classKey = B24.SkillClass(sprite)
	local class = classKey and B24.CLASS_SKILLS[classKey]
	if sprite:getLocalInt("B24SKSET") == 1 then
		maskToSet(sprite:getLocalInt("B24SKILL"), proficient)
		maskToSet(sprite:getLocalInt("B24SKEXP"), expert)
	elseif class then
		local defaults = class.defaults or class.list
		for i = 1, class.count do proficient[defaults[i]] = true end
		addAll(expert, class.expertiseDefaults)
	end
	-- Expertise picked on level-ups (B24LEVEL.lua) adds to the class choice.
	maskToSet(sprite:getLocalInt("B24SKEX2"), expert)
	if class then addAll(proficient, class.tools) end
	if B24.ClassHasRogue(B24.ClassID(sprite)) then
		proficient.THIEVES_TOOLS = true
		if sprite:getLocalInt("B24SKSET") ~= 1 then addAll(expert, B24.CLASS_SKILLS.ROGUE.expertiseDefaults) end
	end
	for _, listener in ipairs(B24.GrantedSkillListeners) do
		pcall(listener, sprite, proficient)
	end
	for key in pairs(expert) do
		if not proficient[key] then expert[key] = nil end
	end
	return proficient, expert
end

-- listener(sprite, key) returns an extra bonus to a skill (e.g. the Thief's Supreme Sneak).
B24.SkillBonusListeners = {}
function B24.AddSkillBonusListener(listener) table.insert(B24.SkillBonusListeners, listener) end

function B24.SkillBonus(sprite, key, proficient, expert)
	local skill = B24.SKILLS[B24.SkillIndex[key]]
	local bonus = B24.AbilityModOf(sprite, skill.ability)
	if proficient[key] then
		bonus = bonus + B24.ProfOf(sprite) * (expert[key] and 2 or 1)
	end
	for _, listener in ipairs(B24.SkillBonusListeners) do
		local ok, extra = pcall(listener, sprite, key)
		if ok and extra then bonus = bonus + extra end
	end
	return bonus
end

-- BG thief skill percentage from a 2024 check bonus.
function B24.SkillPercent(bonus)
	return math.max(0, B24.Config.skillPercentBase + B24.Config.skillPercentPerPoint * bonus)
end

-- Active stat, base stat, skill. The engine's own value (base points and Dexterity table) is
-- replaced; bonuses from items and spells (the rest of the active value) are kept.
B24.THIEF_SKILLS = {
	{ stat = "m_nHideInShadows", base = "m_hideInShadowsBase", skill = "STEALTH" },
	{ stat = "m_nMoveSilently",  base = "m_moveSilentlyBase",  skill = "STEALTH" },
	{ stat = "m_nPickPocket",    base = "m_pickPocketBase",    skill = "SLEIGHT_OF_HAND" },
	{ stat = "m_nLockPicking",   base = "m_lockPickingBase",   skill = "THIEVES_TOOLS" },
	{ stat = "m_nSetTraps",      base = "m_setTrapsBase",      skill = "THIEVES_TOOLS" },
	{ stat = "m_nTraps",         base = "m_trapsBase",         skill = "PERCEPTION", disarm = "THIEVES_TOOLS" },
	{ stat = "m_nDetectIllusion", base = "m_detectIllusionBase", skill = "INVESTIGATION" },
}

B24.ACTION_REMOVE_TRAPS = 28

function B24.IsDisarming(sprite)
	return sprite.m_curAction.m_actionID == B24.ACTION_REMOVE_TRAPS
end

function B24.ApplySkillStats(sprite)
	if B24.SkillClass(sprite) == nil then return end
	local stats = sprite:getActiveStats()
	local proficient, expert = B24.Proficiencies(sprite)
	local disarming = B24.IsDisarming(sprite)
	for _, entry in ipairs(B24.THIEF_SKILLS) do
		local key = (disarming and entry.disarm) or entry.skill
		local extra = stats[entry.stat] - sprite.m_baseStats[entry.base]
		-- Skills stay in the engine's range (effects can push the bonus far out of it).
		stats[entry.stat] = math.max(0, math.min(255, B24.SkillPercent(B24.SkillBonus(sprite, key, proficient, expert)) + extra))
	end
	-- Lore keeps its engine value; Arcana or History proficiency adds to it.
	local lore = math.max(proficient.ARCANA and 1 or 0, proficient.HISTORY and 1 or 0)
	if lore > 0 then
		local double = (proficient.ARCANA and expert.ARCANA) or (proficient.HISTORY and expert.HISTORY)
		stats.m_nLore = stats.m_nLore + B24.Config.skillPercentPerPoint * B24.ProfOf(sprite) * (double and 2 or 1)
	end
end

-- The trap value switches to Thieves' Tools for the disarm attempt: re-resolve the stats when a
-- RemoveTraps action starts.
EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	if action.m_actionID == B24.ACTION_REMOVE_TRAPS and B24.SkillClass(sprite) then
		B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 0 })
		local proficient, expert = B24.Proficiencies(sprite)
		B24.Log(string.format("%s disarms with Thieves' Tools (%d%%)", B24.Name(sprite),
			B24.SkillPercent(B24.SkillBonus(sprite, "THIEVES_TOOLS", proficient, expert))))
	end
end)

-------------
-- Weapons --
-------------

B24.Weapons = B24.LoadTable("B24WEAP")

-- 2024 weapons that BG weapon types map to (WEAPON column of B24WEAP.2DA), with their mastery
-- property. Weapon Mastery is chosen per 2024 weapon, so one mastery can cover several BG types
-- (Longsword: long swords, bastard swords, katanas). In BG terms: BG weapon types the entry covers.
-- icon: a plain weapon of the type (the same item in BG:EE and BG2:EE), for choice lists.
B24.MASTERY_WEAPONS = {
	{ key = "LONGSWORD",      name = "Longsword",           mastery = "Sap",    bg = "long swords, bastard swords, katanas", icon = "ISW1H04" },
	{ key = "SHORTSWORD",     name = "Shortsword",          mastery = "Vex",    bg = "short swords", icon = "ISW1H07" },
	{ key = "SCIMITAR",       name = "Scimitar",            mastery = "Nick",   bg = "scimitars, wakizashis, ninja-tos", icon = "ISW1H20" },
	{ key = "GREATSWORD",     name = "Greatsword",          mastery = "Graze",  bg = "two-handed swords", icon = "ISW2H01" },
	{ key = "BATTLEAXE",      name = "Battleaxe",           mastery = "Topple", bg = "axes", icon = "IAX1H01" },
	{ key = "DAGGER",         name = "Dagger",              mastery = "Nick",   bg = "daggers", icon = "IDAGG01" },
	{ key = "WARHAMMER",      name = "Warhammer",           mastery = "Push",   bg = "war hammers", icon = "IHAMM01" },
	{ key = "SPEAR",          name = "Spear",               mastery = "Sap",    bg = "spears", icon = "ISPER01" },
	{ key = "HALBERD",        name = "Halberd",             mastery = "Cleave", bg = "halberds", icon = "IHALB01" },
	{ key = "FLAIL",          name = "Flail / Morningstar", mastery = "Sap",    bg = "flails, morning stars", icon = "IBLUN02" },
	{ key = "MACE",           name = "Mace",                mastery = "Sap",    bg = "maces", icon = "IBLUN04" },
	{ key = "QUARTERSTAFF",   name = "Quarterstaff",        mastery = "Topple", bg = "quarterstaves", icon = "ISTAF01" },
	{ key = "LIGHT_CROSSBOW", name = "Light Crossbow",      mastery = "Slow",   bg = "crossbows", icon = "IXBOW01" },
	{ key = "LONGBOW",        name = "Longbow",             mastery = "Slow",   bg = "long bows", icon = "IBOW01" },
	{ key = "SHORTBOW",       name = "Shortbow",            mastery = "Vex",    bg = "short bows", icon = "IBOW05" },
	{ key = "DART",           name = "Dart",                mastery = "Vex",    bg = "darts", icon = "IDART01" },
	{ key = "SLING",          name = "Sling",               mastery = "Slow",   bg = "slings", icon = "ISLNG01" },
	{ key = "CLUB",           name = "Club",                mastery = "Slow",   bg = "clubs, blackjacks", icon = "IBLUN01" },
}

-- The BG weapon type standing for a 2024 weapon (first match), for proficiency checks.
function B24.MasteryWeaponProfType(key)
	for profType, weapon in pairs(B24.Weapons) do
		if weapon.WEAPON == key then return tonumber(profType) end
	end
end

-- Weapon Mastery at level 1. Masteries are stored as a mask over B24.MASTERY_WEAPONS in the
-- local B24MAST; the mastery properties themselves arrive with the Fighter component.
B24.MASTERY_COUNT = { FIGHTER = 3, BARBARIAN = 2, PALADIN = 2, RANGER = 2, ROGUE = 2 }

function B24.MasteryCount(sprite)
	local map = B24.CLASS_MAP[B24.ClassID(sprite)]
	if map == nil then return 0 end
	local classes = map.weapons
	if sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN then classes = { "BARBARIAN" } end
	local count = 0
	for _, class in ipairs(classes) do count = math.max(count, B24.MASTERY_COUNT[class] or 0) end
	return count
end

function B24.WeaponInfo(profType)
	return B24.Weapons[tostring(profType)]
end

-- listener(sprite, weapon) returns true for weapon proficiency from class features (e.g. the
-- Cleric's Divine Order: Protector, martial weapons).
B24.WeaponProficiencyListeners = {}
function B24.AddWeaponProficiencyListener(listener) table.insert(B24.WeaponProficiencyListeners, listener) end

-- Monsters and creatures without a 2024 class count as proficient with everything.
function B24.IsWeaponProficient(sprite, profType)
	local weapon = B24.WeaponInfo(profType)
	if weapon == nil or weapon.CATEGORY == "SIMPLE" then return true end
	for _, listener in ipairs(B24.WeaponProficiencyListeners) do
		local ok, result = pcall(listener, sprite, weapon)
		if ok and result then return true end
	end
	local map = B24.CLASS_MAP[B24.ClassID(sprite)]
	if map == nil then return true end
	local classes = map.weapons
	if sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN then classes = { "BARBARIAN" } end
	for _, class in ipairs(classes) do
		local martial = B24.CLASS_WEAPONS[class].martial
		if martial == true then return true end
		if martial == "LIGHT" and weapon.LIGHT == "1" then return true end
		if martial == "LIGHT_OR_FINESSE" and (weapon.LIGHT == "1" or weapon.FINESSE == "1") then return true end
	end
	return false
end

function B24.SelectedWeaponProfType(sprite)
	local equipment = sprite.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	if item == nil then return nil end
	return item.pRes.pHeader.proficiencyType
end

-- listener(sprite, item) returns true if a melee weapon may use Dexterity (the Monk's Martial
-- Arts for unarmed strikes and monk weapons).
B24.FinesseListeners = {}
function B24.AddFinesseListener(listener) table.insert(B24.FinesseListeners, listener) end

-- Finesse weapons use the better of Strength and Dexterity (BG always uses Strength in melee).
function B24.IsFinesse(sprite, item)
	if item == nil then return false end
	local info = B24.WeaponInfo(item.pRes.pHeader.proficiencyType)
	if info and info.FINESSE == "1" then return true end
	for _, listener in ipairs(B24.FinesseListeners) do
		local ok, result = pcall(listener, sprite, item)
		if ok and result then return true end
	end
	return false
end

-- How much better Dexterity is than Strength for a finesse melee attack (0 if not).
function B24.FinesseBonus(sprite, item, ability)
	if ability ~= nil and (ability.type == 2 or ability.type == 4) then return 0 end
	if not B24.IsFinesse(sprite, item) then return 0 end
	return math.max(0, B24.AbilityModOf(sprite, "DEX") - B24.AbilityModOf(sprite, "STR"))
end

-- Called from B24.OnListsResolved: no proficiency bonus with a non-proficient weapon; finesse
-- weapons attack with Dexterity when it is better.
function B24.ApplyWeaponProficiency(sprite)
	if B24.IsMonster(sprite) then return end
	local stats = sprite:getActiveStats()
	local profType = B24.SelectedWeaponProfType(sprite)
	if profType and not B24.IsWeaponProficient(sprite, profType) then
		stats.m_nTHAC0 = stats.m_nTHAC0 + B24.ProfOf(sprite)
	end
	local equipment = sprite.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	if item then
		stats.m_nTHAC0 = stats.m_nTHAC0 - B24.FinesseBonus(sprite, item, item:getAbility(equipment.m_selectedWeaponAbility))
	end
end

-- The engine's own non-proficiency penalty would stack with the missing proficiency bonus, so
-- every party member gets one star in every weapon type (stars give no bonus since WSPECIAL is
-- zeroed). Two stars later mark a mastered weapon type.
B24.WEAPON_PROF_STATS = { 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 115 }

function B24.GrantWeaponStars(sprite)
	for _, stat in ipairs(B24.WEAPON_PROF_STATS) do
		if sprite:getStat(stat) < 1 then
			B24.ApplyEffect(sprite, { ["effectID"] = 233, ["effectAmount"] = 1, ["dwFlags"] = stat, ["durationType"] = 1 })
		end
	end
end

----------------
-- Action bar --
----------------

-- 2024: whoever is proficient can sneak, steal, pick locks and search for traps. Characters get
-- the matching BG buttons by proficiency; buttons the class already has stay. New buttons take
-- empty slots first, then the last quick slots.
B24.PROFICIENCY_BUTTONS = {
	{ button = "STEALTH",    skills = { "STEALTH" } },
	{ button = "THIEVING",   skills = { "SLEIGHT_OF_HAND", "THIEVES_TOOLS" } },
	{ button = "FIND_TRAPS", skills = { "PERCEPTION" } },
}
local FREE_SLOT_ORDER = { "NONE", "QUICK_WEAPON_4", "QUICK_ITEM_3", "QUICK_SPELL_3", "QUICK_WEAPON_3", "QUICK_ITEM_2" }

local function addProficiencyButtons()
	local sprite = EEex_Sprite_GetSelected()
	if sprite == nil or B24.SkillClass(sprite) == nil then return end
	local proficient = B24.Proficiencies(sprite)
	local types = EEex_Actionbar_GetArray().m_buttonTypes
	local present = {}
	for i = 0, 11 do present[types:get(i)] = true end
	for _, entry in ipairs(B24.PROFICIENCY_BUTTONS) do
		local wanted = EEex_Actionbar_ButtonType[entry.button]
		local hasSkill = false
		for _, key in ipairs(entry.skills) do hasSkill = hasSkill or proficient[key] == true end
		if hasSkill and not present[wanted] then
			for _, freeName in ipairs(FREE_SLOT_ORDER) do
				local free = EEex_Actionbar_ButtonType[freeName]
				local slot = nil
				for i = 11, 0, -1 do
					if types:get(i) == free then slot = i break end
				end
				if slot then
					EEex_Actionbar_SetButton(slot, wanted)
					present[wanted] = true
					present[free] = nil
					break
				end
			end
		end
	end
end

EEex_Actionbar_AddListener(function(config, state)
	if state >= 1 and state <= 21 then
		EEex_Utility_TryIgnore(addProficiencyButtons)
	end
end)

-- Picking locks and disarming traps (not just picking pockets) needs Thieves' Tools.
local originalHasFullThieving = EEex_Actionbar_Hook_HasFullThieving
function EEex_Actionbar_Hook_HasFullThieving(sprite)
	if B24.SkillClass(sprite) == nil then return originalHasFullThieving(sprite) end
	local proficient = B24.Proficiencies(sprite)
	return proficient.THIEVES_TOOLS == true
end

-------------------
-- Social skills --
-------------------

-- BG's dialogues check raw ability scores (mostly Charisma, Wisdom and Intelligence, some Strength
-- and Dexterity), and store prices follow the speaker's Charisma. While a dialogue runs, every party
-- member gets those scores raised by what its 2024 skills add on top of the ability modifier, as
-- score points (+1 to a check = +2 points):
--   Charisma      best of Persuasion, Deception, Intimidation
--   Wisdom        Insight
--   Intelligence  best of Investigation, Arcana, History
--   Strength      Athletics (forcing, lifting, climbing in dialogues)
--   Dexterity     best of Acrobatics, Sleight of Hand, Stealth
-- The bonus starts with the dialogue action, lasts through stores opened from it and ends back in
-- normal play; reputation keeps its BG role. Effects carry the source B24SOCIA.
B24.SOCIAL_SKILLS = {
	{ ability = "CHA", opcode = 6,  skills = { "PERSUASION", "DECEPTION", "INTIMIDATION" } },
	{ ability = "WIS", opcode = 49, skills = { "INSIGHT" } },
	{ ability = "INT", opcode = 19, skills = { "INVESTIGATION", "ARCANA", "HISTORY" } },
	{ ability = "STR", opcode = 44, skills = { "ATHLETICS" } },
	{ ability = "DEX", opcode = 15, skills = { "ACROBATICS", "SLEIGHT_OF_HAND", "STEALTH" } },
}
B24.DIALOGUE_ACTIONS = { [8] = true, [137] = true, [139] = true, [198] = true, [266] = true, [267] = true }

function B24.SocialScoreBonus(sprite, entry)
	local proficient, expert = B24.Proficiencies(sprite)
	local best = 0
	for _, key in ipairs(entry.skills) do
		local extra = B24.SkillBonus(sprite, key, proficient, expert) - B24.AbilityModOf(sprite, entry.ability)
		if extra > best then best = extra end
	end
	-- Crafter (better prices) and Actor: Charisma 2 higher each.
	local extra = 0
	if entry.ability == "CHA" then
		if B24FEAT ~= nil and B24FEAT.Has(sprite, "CRAFTER") then extra = extra + 2 end
		if B24GF ~= nil and B24GF.Has(sprite, "ACTOR") then extra = extra + 2 end
	end
	return 2 * best + extra
end

local social = nil -- { start = tick, sawDialogue = bool, applied = tick, starter = sprite id }
-- [sprite id] = tick: a creature whose dialogue action opened no dialogue is ignored until then
-- (NPCs retry Dialogue() every few seconds while it can't start, e.g. Imoen in the prologue).
local retryAfter = {}
B24.SOCIAL_RETRY_TICKS = 450

-- The Wish spell's genie (WISH01, WISH02) offers better wishes to a wiser caster (WIS above 15 for
-- all of them); 2024 Wish has no such limit: in its dialogue Wisdom counts as at least 16.
B24.WISH_CREATURES = { WISH01 = true, WISH02 = true }

local function applySocial()
	local starter = social and B24.GetSprite(social.starter)
	local wish = starter ~= nil and B24.WISH_CREATURES[starter.m_resref:get():upper()] == true
	for _, member in ipairs(B24.Party()) do
		B24.RemoveEffectsBySource(member, "B24SOCIA")
		if B24.SkillClass(member) ~= nil then
			for _, entry in ipairs(B24.SOCIAL_SKILLS) do
				local bonus = B24.SocialScoreBonus(member, entry)
				if wish and entry.ability == "WIS" then
					bonus = math.max(bonus, 16 - member.m_baseStats.m_WISBase)
				end
				if bonus > 0 then
					B24.ApplyEffect(member, { ["effectID"] = entry.opcode, ["effectAmount"] = bonus, ["dwFlags"] = 0,
						["durationType"] = 0, ["duration"] = 60, ["m_sourceRes"] = "B24SOCIA" })
				end
			end
		end
	end
end

local function endSocial()
	social = nil
	for _, member in ipairs(B24.Party()) do B24.RemoveEffectsBySource(member, "B24SOCIA") end
end

-- The character record (its onopen, patched in b24_core_runtime.tpa) is no dialogue: a bonus still
-- running ends, so the scores show their own values (no green from the social skills).
function B24_RecordOpened()
	if social then EEex_Utility_TryIgnore(endSocial) end
end

-- The bonus is in place before the first dialogue node is evaluated: it starts with the action
-- (the speaker may still walk up), not with the dialogue screen.
-- A running bonus is not restarted by further dialogue actions. None while the party is engaged
-- (enemies in sight, B24TURN.lua): a dialogue attempt in a fight (banter, an NPC that retries
-- until it can talk) would raise the scores the fight uses.
EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	if social or not B24.DIALOGUE_ACTIONS[action.m_actionID] then return end
	if B24TB and B24TB.engaged then return end
	local now = B24.GameTick()
	local retry = retryAfter[sprite.m_id]
	if retry and now < retry and retry - now <= B24.SOCIAL_RETRY_TICKS then return end
	social = { start = now, sawDialogue = false, applied = now, starter = sprite.m_id }
	EEex_Utility_TryIgnore(applySocial)
end)

-- It lasts while the dialogue (or a store from it) is open, and ends once normal play is back
-- after the dialogue, or 10 seconds after the action if no dialogue opened.
local originalHasPendingScreens = B24_HasPendingScreens
function B24_HasPendingScreens()
	if social then
		local now = B24.GameTick()
		local normal = B24.InNormalPlay == nil or B24.InNormalPlay()
		if not normal then social.sawDialogue = true end
		if normal and (social.sawDialogue or now - social.start > 150) then
			if not social.sawDialogue then retryAfter[social.starter] = now + B24.SOCIAL_RETRY_TICKS end
			EEex_Utility_TryIgnore(endSocial)
		elseif now - social.applied > 600 then
			social.applied = now
			EEex_Utility_TryIgnore(applySocial)
		end
	end
	return originalHasPendingScreens()
end
