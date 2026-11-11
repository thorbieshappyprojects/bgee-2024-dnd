-- BG 2024 Rules Mod: 2024 numbers on the character and inventory screens.
--
-- The engine keeps BG values internally (AC 4 = 2024 AC 16, THAC0 15 = attack bonus +5; see
-- B24CORE.lua). The UI shows them through the characters[id] table and a few helper functions in
-- UI.MENU; this file overrides those helpers, and the character record's text is built from 2024
-- values (Armor Class, attack bonus, saving throws, proficiencies). UI.MENU loads after the M_*.lua
-- files, so the overrides are installed once it has loaded.

B24UI = {}

function B24UI.ToAC(bgAC)
	local n = tonumber(bgAC)
	return n and (20 - n) or bgAC
end

local function signed(n)
	return n >= 0 and ("+" .. n) or tostring(n)
end

function B24UI.ToAttack(thac0)
	local n = tonumber(thac0)
	return n and signed(20 - n) or thac0
end

local function spriteOf(id)
	local sprite = EEex_GameObject_Get(id)
	return B24.IsSprite(sprite) and sprite or nil
end

---------------------
-- Detail texts --
---------------------

function B24UI.ACDetails(id)
	local char = characters[id]
	if char == nil then return "" end
	local lines = {
		string.format("Armor Class %s (2024 rules: higher is better).", B24UI.ToAC(char.AC.current)),
		"Armor sets the base AC (light, medium and heavy armor add the Dexterity modifier up to their limits), shields add +2, magic items add their bonus.",
	}
	local sprite = spriteOf(id)
	if sprite then
		if sprite:getSpellState(B24.SplState.ARMOR_HEAVY) then
			table.insert(lines, "Heavy armor: no Dexterity modifier.")
		elseif sprite:getSpellState(B24.SplState.ARMOR_MEDIUM) then
			table.insert(lines, "Medium armor: Dexterity modifier at most +2.")
		end
	end
	return table.concat(lines, "\n")
end

local function weaponAbility(sprite)
	local equipment = sprite.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	if item == nil then return "STR" end
	local ability = item:getAbility(equipment.m_selectedWeaponAbility)
	-- Ability type 2 = ranged, 4 = launcher.
	if ability and (ability.type == 2 or ability.type == 4) then return "DEX" end
	return "STR"
end

local function attackLine(sprite, thac0, label)
	local total = 20 - thac0
	local profType = B24.SelectedWeaponProfType(sprite)
	local proficient = profType == nil or B24.IsWeaponProficient(sprite, profType)
	local pb = proficient and B24.ProfOf(sprite) or 0
	local ability = weaponAbility(sprite)
	local mod = B24.AbilityModOf(sprite, ability)
	local other = total - pb - mod
	local parts = { string.format("proficiency %s%s", signed(pb), proficient and "" or " (not proficient with this weapon)"),
		string.format("%s %s", ability == "DEX" and "Dexterity" or "Strength", signed(mod)) }
	if other ~= 0 then table.insert(parts, string.format("weapon, items and effects %s", signed(other))) end
	return string.format("%sAttack bonus %s: %s.", label or "", signed(total), table.concat(parts, ", "))
end

function B24UI.AttackDetails(id)
	local char = characters[id]
	local sprite = spriteOf(id)
	if char == nil then return "" end
	if sprite == nil then return "Attack bonus " .. B24UI.ToAttack(char.THAC0.current) end
	local lines = { attackLine(sprite, tonumber(char.THAC0.current) or 20, char.THAC0.offhand and "Main hand: " or nil) }
	if char.THAC0.offhand then
		table.insert(lines, string.format("Off hand: attack bonus %s.", B24UI.ToAttack(char.THAC0.offhand)))
	end
	table.insert(lines, "An attack hits if d20 + attack bonus reaches the target's Armor Class.")
	return table.concat(lines, "\n")
end

local SAVE_NAMES = { STR = "Strength", DEX = "Dexterity", CON = "Constitution", INT = "Intelligence", WIS = "Wisdom", CHA = "Charisma" }

function B24UI.SaveText(sprite)
	local lines = {}
	for _, ability in ipairs({ "STR", "DEX", "CON", "INT", "WIS", "CHA" }) do
		table.insert(lines, string.format("%s %s%s", SAVE_NAMES[ability], signed(B24.SaveModifier(sprite, ability)),
			B24.IsSaveProficient(sprite, ability) and " (proficient)" or ""))
	end
	table.insert(lines, "A save succeeds if d20 + modifier reaches the DC of the effect. Item and spell bonuses to saves are added when the save is rolled.")
	return table.concat(lines, "\n")
end

function B24UI.WeaponText(sprite)
	local lines = {}
	local map = B24.CLASS_MAP[B24.ClassID(sprite)]
	if map == nil then
		table.insert(lines, "Proficient with all weapons.")
	else
		local martial = false
		local partial = nil
		local classes = map.weapons
		if sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN then classes = { "BARBARIAN" } end
		for _, class in ipairs(classes) do
			local m = B24.CLASS_WEAPONS[class].martial
			if m == true then martial = true elseif m then partial = m end
		end
		if martial then
			table.insert(lines, "Proficient with simple and martial weapons.")
		elseif partial == "LIGHT_OR_FINESSE" then
			table.insert(lines, "Proficient with simple weapons and martial weapons that have the Finesse or Light property.")
		elseif partial == "LIGHT" then
			table.insert(lines, "Proficient with simple weapons and martial weapons that have the Light property.")
		else
			table.insert(lines, "Proficient with simple weapons.")
		end
	end
	local mastered = {}
	local mask = sprite:getLocalInt("B24MAST")
	for i, weapon in ipairs(B24.MASTERY_WEAPONS) do
		if EEex_IsBitSet(mask, i - 1) then table.insert(mastered, string.format("%s (%s)", weapon.name, weapon.mastery)) end
	end
	if #mastered > 0 then
		table.insert(lines, "Weapon Mastery: " .. table.concat(mastered, ", ") .. ".")
	end
	return table.concat(lines, "\n")
end

-- The 2024 Fighting Styles in place of BG's weapon styles (two-handed, sword and shield, ...),
-- which have no 2024 effect. Empty without a style (the record then leaves the line out).
function B24UI.StyleText(sprite)
	if B24LV == nil then return "" end
	local names = {}
	for _, style in ipairs(B24LV.STYLES) do
		if B24LV.HasStyle(sprite, style.key) then table.insert(names, style.name .. ": " .. style.desc) end
	end
	return table.concat(names, "\n")
end

function B24UI.SkillText(sprite)
	local proficient, expert = B24.Proficiencies(sprite)
	local lines = { "2024 skill and tool proficiencies:" }
	for _, skill in ipairs(B24.SKILLS) do
		if proficient[skill.key] then
			table.insert(lines, string.format("%s %s%s", skill.name,
				signed(B24.SkillBonus(sprite, skill.key, proficient, expert)), expert[skill.key] and " (Expertise)" or ""))
		end
	end
	if #lines == 1 then table.insert(lines, "none") end
	table.insert(lines, "")
	table.insert(lines, "The thief skills above come from these: Stealth (Hide in Shadows, Move Silently), Sleight of Hand (Pick Pockets), Thieves' Tools (Open Locks, Set Traps, disarming), Perception (Find Traps), Investigation (Detect Illusion); Arcana and History add to Lore.")
	return table.concat(lines, "\n")
end

------------------------------
-- Class features (tab 10) --
------------------------------

-- The record's Features tab: each class with its subclass and the features of every level so far,
-- the uses left of each class resource, the options and picks chosen, and the choices still open.
B24UI.FEATURES_TAB = 10

-- Class key, the table with its FEATURES[level] texts (B24<class>.lua).
local CLASS_TABLES = {
	{ "BARBARIAN", "B24BA" }, { "BARD", "B24BD" }, { "CLERIC", "B24CL" }, { "DRUID", "B24DR" },
	{ "FIGHTER", "B24FI" }, { "MONK", "B24MO" }, { "PALADIN", "B24PA" }, { "RANGER", "B24RA" },
	{ "ROGUE", "B24RO" }, { "SORCERER", "B24SO" }, { "WIZARD", "B24WZ" },
}

-- Resource keys whose words don't make the name.
local RESOURCE_NAMES = {
	CLERIC_CHANNEL = "Channel Divinity", FOCUS = "Focus Points", LANDS_AID = "Land's Aid",
	HUNTERS_MARK = "Hunter's Mark (free casts)", NATURES_VEIL = "Nature's Veil", SUPERIORITY = "Superiority Dice",
	PSI_WARRIOR_DICE = "Psionic Energy Dice", SOULKNIFE_DICE = "Psionic Energy Dice", FEAT_STEP = "Fey Step",
	FEAT_COMMAND = "Command (Fey Touched)", FEAT_INVISIBILITY = "Invisibility (Shadow Touched)",
	INTIMIDATING_PRESENCE = "Intimidating Presence",
}

local function className(classKey)
	return classKey:sub(1, 1) .. classKey:sub(2):lower()
end

local function resourceName(key, resource)
	if resource.name then return resource.name end
	if RESOURCE_NAMES[key] then return RESOURCE_NAMES[key] end
	return (key:lower():gsub("_", " "):gsub("(%a)(%a*)", function(a, b) return a:upper() .. b end))
end

local function classLines(sprite, lines)
	for _, entry in ipairs(CLASS_TABLES) do
		local classKey, module = entry[1], _G[entry[2]]
		local level = B24LV.ClassLevel(sprite, classKey)
		if level > 0 then
			local subclass = B24LV.SubclassEntry(sprite, classKey)
			table.insert(lines, string.format("^M%s %d%s^-", className(classKey), level, subclass and (": " .. subclass.name) or ""))
			for l = 1, level do
				local base = module and module.FEATURES and module.FEATURES[l]
				local sub = subclass and subclass.features and subclass.features[l]
				if base then table.insert(lines, string.format("%d: %s", l, base)) end
				if sub then table.insert(lines, string.format("%d: %s: %s", l, subclass.name, sub)) end
			end
			table.insert(lines, "")
		end
	end
end

local function resourceLines(sprite, lines)
	local rows = {}
	for key, resource in pairs(B24LV.RESOURCES) do
		local ok, max = pcall(resource.max, sprite)
		if ok and max and max > 0 then
			local rest = resource.shortRest == "all" and "all back on a short rest"
				or resource.shortRest == "one" and "one back on a short rest, all on a long rest" or "back on a long rest"
			table.insert(rows, string.format("%s: %d of %d (%s)", resourceName(key, resource), B24LV.Remaining(sprite, key), max, rest))
		end
	end
	if #rows == 0 then return end
	table.sort(rows)
	table.insert(lines, "^MUses left^-")
	for _, row in ipairs(rows) do table.insert(lines, row) end
	table.insert(lines, "")
end

local function choiceLines(sprite, lines)
	local rows = {}
	for _, option in ipairs(B24LV.OPTIONS) do
		local key = B24LV.Option(sprite, option.key)
		for _, entry in ipairs(key and option.list or {}) do
			if entry.key == key then table.insert(rows, string.format("%s: %s", option.title, entry.name)) end
		end
	end
	for _, pick in ipairs(B24LV.PICKS) do
		local names = {}
		for _, entry in ipairs(B24LV.Picked(sprite, pick.key)) do table.insert(names, entry.name) end
		if #names > 0 then table.insert(rows, string.format("%s: %s", pick.title or pick.key, table.concat(names, ", "))) end
	end
	if #rows > 0 then
		table.insert(lines, "^MChosen^-")
		for _, row in ipairs(rows) do table.insert(lines, row) end
		table.insert(lines, "")
	end
	local pending = B24LV.Pending(sprite)
	local open = {}
	for _, kind in ipairs(B24LV.CHOICE_ORDER) do
		if (pending[kind] or 0) > 0 then table.insert(open, B24LV.CHOICE_TITLES[kind]) end
	end
	if #open > 0 then
		table.insert(lines, "^MChoices waiting^-")
		table.insert(lines, table.concat(open, ", ") .. ". Choose them with the abilities of the same name (innate abilities).")
	end
end

function B24UI.FeaturesText(sprite)
	if B24LV == nil then return "The Classes component is not installed." end
	local lines = {}
	classLines(sprite, lines)
	resourceLines(sprite, lines)
	choiceLines(sprite, lines)
	if #lines == 0 then return "No 2024 class features." end
	return table.concat(lines, "\n")
end

function B24UI_FeaturesTabLabel()
	return "Features"
end

------------------------
-- UI.MENU overrides --
------------------------

local function install()
	local originalGetStat, originalGetTempStat = getStat, getTempStat
	local converters = { AC = B24UI.ToAC, THAC0 = B24UI.ToAttack }

	function getStat(old, newName, coeff)
		local convert = converters[newName]
		if convert then return convert(old) end
		return originalGetStat(old, newName, coeff)
	end

	-- Both values are BG values where lower is better; the 2024 values are higher-is-better.
	function getTempStat(old, newName, coeff)
		local convert = converters[newName]
		if convert == nil then return originalGetTempStat(old, newName, coeff) end
		if tempStats[id] == nil then return "-" end
		local new = tempStats[id][newName]
		local score = (tonumber(old) or 0) - (tonumber(new) or 0)
		if score == 0 then return "-" end
		return (score < 0 and "^R" or "^G") .. convert(new) .. "^-"
	end

	function displayCompiledAC()
		return tostring(B24UI.ToAC(characters[currentID].AC.current))
	end

	function displayTHAC()
		local char = characters[currentID]
		local text = B24UI.ToAttack(char.THAC0.current)
		if char.THAC0.offhand then text = text .. "\n" .. B24UI.ToAttack(char.THAC0.offhand) end
		return text
	end

	function getInventoryTHAC0()
		local char = characters[id]
		local text = B24UI.ToAttack(char.THAC0.current)
		if char.THAC0.offhand then text = text .. "\n" .. B24UI.ToAttack(char.THAC0.offhand) end
		return text
	end

	function getInventoryTHAC0Details()
		return B24UI.AttackDetails(id)
	end

	-- The record's tabs read characters[currentID] directly: the combat stats tab (9) gets 2024
	-- values swapped in while it builds its text, the skills tab (3) gets the 2024 proficiencies.
	local originalUpdateAttrTable = updateAttrTable
	function updateAttrTable()
		local char = characters[currentID]
		local sprite = char and spriteOf(currentID)
		if char == nil or sprite == nil then return originalUpdateAttrTable() end
		local saved = {
			thac0 = char.THAC0.current, offhand = char.THAC0.offhand, details = char.THAC0.details,
			detailsOffhand = char.THAC0.detailsOffhand, acDetails = char.AC.details,
			weapons = char.proficiencies.weapons.current, saves = char.proficiencies.savingThrows,
			styles = char.proficiencies.fightingstyles and char.proficiencies.fightingstyles.current,
		}
		local ok = pcall(function()
			char.THAC0.current = B24UI.ToAttack(saved.thac0)
			char.THAC0.offhand = saved.offhand and B24UI.ToAttack(saved.offhand)
			char.THAC0.details = B24UI.AttackDetails(currentID)
			char.THAC0.detailsOffhand = nil
			char.AC.details = B24UI.ACDetails(currentID)
			char.proficiencies.weapons.current = B24UI.WeaponText(sprite)
			char.proficiencies.savingThrows = B24UI.SaveText(sprite)
			if char.proficiencies.fightingstyles then char.proficiencies.fightingstyles.current = B24UI.StyleText(sprite) end
		end)
		local result = { pcall(originalUpdateAttrTable) }
		char.THAC0.current, char.THAC0.offhand, char.THAC0.details = saved.thac0, saved.offhand, saved.details
		char.THAC0.detailsOffhand, char.AC.details = saved.detailsOffhand, saved.acDetails
		char.proficiencies.weapons.current, char.proficiencies.savingThrows = saved.weapons, saved.saves
		if char.proficiencies.fightingstyles then char.proficiencies.fightingstyles.current = saved.styles end
		if ok and currentTab == 3 then
			helpTextString = (helpTextString or "") .. "\n" .. B24UI.SkillText(sprite)
		end
		-- The engine has no tab 10: its text is the 2024 class features.
		if result[1] and currentTab == B24UI.FEATURES_TAB then
			showJustText = characterViewable == true
			showStats = false
			local built, text = pcall(B24UI.FeaturesText, sprite)
			helpTextString = built and text or ""
		end
		-- The overview text lists the engine's weapon proficiency stars; the 2024 text replaces it.
		if ok and type(helpTextString) == "string" then
			local start = helpTextString:find("Weapon Proficiencies", 1, true)
			if start then
				local stop = helpTextString:find("\n%s*\n", start)
				local after = stop and helpTextString:sub(stop) or ""
				helpTextString = helpTextString:sub(1, start - 1) .. "Weapon Proficiencies\n"
					.. B24UI.WeaponText(sprite) .. after
			end
		end
		if not result[1] then error(result[2]) end
		return table.unpack(result, 2)
	end
end

-- Labels in the 2024 wording (uiStrings comes from the translation file).
local function relabel()
	if uiStrings == nil then return end
	uiStrings.THAC0_LABEL = "Attack Bonus"
	uiStrings.MAIN_HAND_THAC0 = "Main-Hand Attack Bonus"
	uiStrings.OFF_HAND_THAC0 = "Off-Hand Attack Bonus"
	-- Other UI texts (help, difficulty descriptions) in 2024 terms, as for dialog.tlk.
	for key, text in pairs(uiStrings) do
		if type(text) == "string" and text:find("THAC0") then
			uiStrings[key] = text:gsub("improved THAC0", "improved attack rolls"):gsub("THAC0", "attack bonus")
		end
	end
end

EEex_Menu_AddAfterMainFileLoadedListener(function()
	EEex_Utility_TryIgnore(install)
	EEex_Utility_TryIgnore(relabel)
end)
EEex_Menu_AddTranslationLoadedListener(function()
	EEex_Utility_TryIgnore(relabel)
end)

-- Called from patched UI.MENU items (B24_UI patch in b24_core_runtime.tpa); a failure falls back
-- to the engine's text.
function B24UI_AC(bgAC)
	local ok, value = pcall(B24UI.ToAC, bgAC)
	return ok and value or bgAC
end

function B24UI_ACDetails(charID)
	local ok, text = pcall(B24UI.ACDetails, charID)
	return ok and text or (characters[charID] and characters[charID].AC.details or "")
end

function B24UI_AttackDetails(charID)
	local ok, text = pcall(B24UI.AttackDetails, charID)
	return ok and text or (characters[charID] and characters[charID].THAC0.details or "")
end
