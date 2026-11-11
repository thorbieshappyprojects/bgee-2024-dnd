-- BG 2024 Rules Mod: 2024 multiclassing on top of BG's multiclass and dual-class characters.
--
-- - Character level is the sum of the class levels (B24.Level): proficiency bonus, cantrips, Tough
--   and the like follow it. The engine's attack bonus (THAC0 table) is read per class level, so
--   multiclasses get the difference to the total level's proficiency bonus here.
-- - Hit points: the maximum hit die of the starting class at level 1, then each class's fixed 2024
--   value (die / 2 + 1) per level in it, plus the Constitution modifier per character level. The
--   engine's averaged multiclass tables are replaced (m_maxHitPointsBase, which includes Con).
-- - Dual-classed characters become multiclasses: the "original class" flags are cleared, so the
--   old class stays active (2024) and both classes keep gaining levels.
-- - Level-ups: the total level never runs ahead of the XP. A multiclass may gain a level once its
--   XP gives a single-class character of its starting class a higher level than its total, and the
--   player picks the class that gains it (B24_LEVELUP popup, kind CLASS in B24LEVEL.lua). The mod
--   raises that class level itself; the engine's level-up screen is not used for multiclasses (its
--   gains, weapon proficiencies and skill points, come from the 2024 rules here). The engine keeps
--   the real XP, which game scripts read.
-- - A character who joins with more levels than its XP allows is rebuilt once: the starting class
--   keeps its levels where it can, the others give levels back.
--
-- Locals: B24MCMAIN (index 1-3 of the starting class), B24MCFIT (checked after joining), B24MCSGL
-- (seen as a single class in the party).

B24MC = {}

-- CRE flags of a dual-classed character: which class it started as.
B24MC.ORIGINAL_CLASS = { [0x8] = "FIGHTER", [0x10] = "WIZARD", [0x20] = "CLERIC", [0x40] = "ROGUE",
	[0x80] = "DRUID", [0x100] = "RANGER" }
B24MC.ORIGINAL_MASK = 0x1F8

-- 2024 class -> XPLEVEL.2DA row, hit die, name.
B24MC.XP_ROW = { FIGHTER = "FIGHTER", WIZARD = "MAGE", CLERIC = "CLERIC", ROGUE = "THIEF", DRUID = "DRUID",
	RANGER = "RANGER", BARBARIAN = "FIGHTER" }
B24MC.HIT_DIE = { FIGHTER = 10, WIZARD = 6, CLERIC = 8, ROGUE = 8, DRUID = 8, RANGER = 10, BARBARIAN = 12 }
B24MC.NAME = { FIGHTER = "Fighter", WIZARD = "Wizard", CLERIC = "Cleric", ROGUE = "Rogue", DRUID = "Druid",
	RANGER = "Ranger", BARBARIAN = "Barbarian" }
B24MC.MAX_LEVEL = 20

local LEVEL_STATS = { B24.Stat.LEVEL, B24.Stat.LEVEL2, B24.Stat.LEVEL3 }
local LEVEL_FIELDS = { "m_level1", "m_level2", "m_level3" }

local xpTable
local function thresholds(classKey)
	xpTable = xpTable or B24.LoadTable("XPLEVEL")
	local row = xpTable[B24MC.XP_ROW[classKey] or "FIGHTER"]
	local list = {}
	for level = 1, 50 do
		local value = row and tonumber(row[tostring(level)])
		if value == nil then break end
		list[level] = value
	end
	return list
end

-- Level a single class reaches with this much XP.
local function levelFor(classKey, xp)
	local list, level = thresholds(classKey), 1
	for l = 2, #list do
		if xp >= list[l] then level = l else break end
	end
	return level
end

function B24MC.Classes(sprite)
	local id = B24.ClassID(sprite)
	local count = B24.MulticlassCount[id]
	if count == nil then return nil end
	return B24.CLASS_MAP[id].weapons, count
end

function B24MC.IsMulti(sprite) return B24MC.Classes(sprite) ~= nil end

local function levels(sprite, count)
	local list = {}
	for i = 1, count do list[i] = sprite:getStat(LEVEL_STATS[i]) end
	return list
end

local function sum(list)
	local total = 0
	for _, v in ipairs(list) do total = total + v end
	return total
end

local function mainIndex(sprite)
	local index = sprite:getLocalInt("B24MCMAIN")
	return index > 0 and index or 1
end

local function mainClass(sprite)
	local classes = B24MC.Classes(sprite)
	return classes[mainIndex(sprite)]
end

-- Total level a single class of the starting class has with this XP (2024: one character level per
-- XP threshold).
function B24MC.AllowedLevel(sprite, xp)
	return math.min(B24MC.MAX_LEVEL, levelFor(mainClass(sprite), xp or sprite.m_baseStats.m_xp))
end

-- Removing an effect makes the engine recompute the stats from the base values (the script action
-- ChangeClass would reset the XP and the levels).
local function refresh(sprite)
	B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60,
		["m_sourceRes"] = "B24MCREF" })
	B24.RemoveEffectsBySource(sprite, "B24MCREF")
end

------------------------------
-- Dual-class -> multiclass --
------------------------------

local function convertDual(sprite)
	local flags = sprite.m_baseStats.m_flags
	local original = EEex_BAnd(flags, B24MC.ORIGINAL_MASK)
	if original == 0 then return false end
	local classes = B24MC.Classes(sprite)
	local key = B24MC.ORIGINAL_CLASS[original]
	for i, class in ipairs(classes) do
		if class == key then sprite:setLocalInt("B24MCMAIN", i) end
	end
	sprite.m_baseStats.m_flags = EEex_BAnd(flags, EEex_BNot(B24MC.ORIGINAL_MASK))
	refresh(sprite)
	B24.Log(string.format("%s: dual-class becomes a 2024 multiclass (%s keeps its levels and stays active)",
		B24.Name(sprite), key and B24MC.NAME[key] or "the old class"))
	return true
end

-- Levels beyond the XP: the starting class keeps its levels where it can, the others give theirs
-- back (the highest first).
local function rebuild(sprite)
	local classes, count = B24MC.Classes(sprite)
	local current = levels(sprite, count)
	local allowed = B24MC.AllowedLevel(sprite)
	if sum(current) <= allowed then return false end
	local main = mainIndex(sprite)
	local target = {}
	for i = 1, count do target[i] = current[i] end
	while sum(target) > math.max(allowed, count) do
		local pick
		for i = 1, count do
			if i ~= main and target[i] > 1 and (pick == nil or target[i] > target[pick]) then pick = i end
		end
		if pick == nil then
			if target[main] <= 1 then break end
			pick = main
		end
		target[pick] = target[pick] - 1
	end
	for i = 1, count do sprite.m_baseStats[LEVEL_FIELDS[i]] = target[i] end
	refresh(sprite)
	local parts = {}
	for i = 1, count do table.insert(parts, string.format("%s %d", B24MC.NAME[classes[i]] or classes[i], target[i])) end
	B24.Log(string.format("%s's levels are rebuilt to fit the XP (level %d): %s", B24.Name(sprite), sum(target),
		table.concat(parts, ", ")))
	return true
end

----------------
-- Hit points --
----------------

local function hitPoints(sprite, classes, count, current)
	local main = mainIndex(sprite)
	local con = B24.AbilityModOf(sprite, "CON")
	local total = 0
	for i = 1, count do
		local die = B24MC.HIT_DIE[classes[i]] or 8
		local n = current[i]
		if i == main and n > 0 then
			total = total + die + (n - 1) * (math.floor(die / 2) + 1)
		else
			total = total + n * (math.floor(die / 2) + 1)
		end
	end
	return math.max(1, total + con * sum(current))
end

-- 2024 maximum hit points of a multiclass (Constitution included).
function B24MC.HitPoints(sprite)
	local classes, count = B24MC.Classes(sprite)
	return hitPoints(sprite, classes, count, levels(sprite, count))
end

-- Checked every second: the engine changes the base hit points itself after a level change.
local function rebuildHitPoints(sprite)
	local classes, count = B24MC.Classes(sprite)
	local current = levels(sprite, count)
	local base = sprite.m_baseStats
	local wanted = hitPoints(sprite, classes, count, current)
	local delta = wanted - base.m_maxHitPointsBase
	if delta == 0 then return end
	base.m_maxHitPointsBase = wanted
	base.m_hitPoints = math.max(1, math.min(wanted, base.m_hitPoints + delta))
	B24.Log(string.format("%s: %d hit points (2024 multiclass)", B24.Name(sprite), wanted))
end

---------------
-- Level-ups --
---------------

function B24MC.CanLevelUp(sprite)
	if not B24MC.IsMulti(sprite) or B24.GState_Has(sprite, B24.GState.DEAD) then return false end
	return #B24MC.LevelUpChoices(sprite) > 0
end

-- { index, key, name, level, total } of every class that can take the next level.
function B24MC.LevelUpChoices(sprite)
	local classes, count = B24MC.Classes(sprite)
	local current = levels(sprite, count)
	local total = sum(current)
	local choices = {}
	if total >= B24MC.AllowedLevel(sprite) then return choices end
	for i = 1, count do
		if current[i] < B24MC.MAX_LEVEL then
			table.insert(choices, { index = i, key = classes[i], name = B24MC.NAME[classes[i]] or classes[i],
				level = current[i], total = total })
		end
	end
	return choices
end

function B24MC.LevelUp(sprite, index)
	local field = LEVEL_FIELDS[index]
	sprite.m_baseStats[field] = sprite.m_baseStats[field] + 1
	refresh(sprite)
end

-- Record screen Level Up button (UI.MENU, patched in b24_core_runtime.tpa).
local function recordSprite()
	local sprite = EEex_GameObject_Get(currentID)
	return B24.IsSprite(sprite) and sprite or nil
end

function B24MC_LevelUpClickable()
	local ok, result = pcall(function()
		local sprite = recordSprite()
		if sprite and B24MC.IsMulti(sprite) then return B24MC.CanLevelUp(sprite) end
		return characterScreen:IsLevelUpButtonClickable()
	end)
	return ok and result == true
end

function B24MC_OnLevelUp()
	local sprite = recordSprite()
	if sprite == nil or not B24MC.IsMulti(sprite) then
		characterScreen:OnLevelUpButtonClick()
		return
	end
	local choices = B24MC.LevelUpChoices(sprite)
	if #choices == 0 then return end
	if B24LV and B24LV.OpenClassChoice and #choices > 1 then
		B24LV.OpenClassChoice(sprite)
	else
		B24MC.LevelUp(sprite, choices[1].index)
		B24.Log(string.format("%s: level %d in %s", B24.Name(sprite), choices[1].level + 1, choices[1].name))
	end
end

-- The world screen's level-up buttons (Infinity_CanLevelUp) follow the same rule.
if Infinity_CanLevelUp then
	local originalCanLevelUp = Infinity_CanLevelUp
	function Infinity_CanLevelUp(portrait, ...)
		local ok, sprite = pcall(EEex_Sprite_GetInPortrait, portrait)
		if ok and B24.IsSprite(sprite) and B24MC.IsMulti(sprite) then return B24MC.CanLevelUp(sprite) end
		return originalCanLevelUp(portrait, ...)
	end
end

-----------------
-- Spell slots --
-----------------

-- The mod does multiclass level-ups itself, so it also sets their spell slots (the base count of
-- the engine's memorization info, an array of pointers to CRE entries: spell level, base slots,
-- slots with bonuses, ...). One casting class: its own table at its level. Two (Cleric/Mage,
-- Fighter/Mage/Cleric, Cleric/Ranger): the 2024 multiclass spellcaster table, i.e. the full caster
-- table at the combined level (full casters' levels plus half the Ranger levels), split between
-- the wizard and the priest slots in the proportion each class has on its own; slot levels
-- neither class reaches yet go to the wizard slots (upcast copies use them), and priest slots
-- above 7th count as 7th, as in the priest tables.
B24MC.SLOT_TABLE = { WIZARD = "MXSPLWIZ", CLERIC = "MXSPLPRS", DRUID = "MXSPLDRU", RANGER = "MXSPLRAN" }
B24MC.FULL_CASTER = { WIZARD = true, CLERIC = true, DRUID = true }

local slotTables = {}
local function tableSlots(name, level, spellLevel)
	if level <= 0 then return 0 end
	slotTables[name] = slotTables[name] or B24.LoadTable(name)
	local row = slotTables[name][tostring(math.min(level, 20))]
	return row and tonumber(row[tostring(spellLevel)]) or 0
end

-- { mage = { [1..9] }, priest = { [1..7] } } wanted for a multiclass.
function B24MC.WantedSlots(sprite)
	local classes, count = B24MC.Classes(sprite)
	local current = levels(sprite, count)
	local mage, priest = {}, {}
	for l = 1, 9 do mage[l] = 0 end
	for l = 1, 7 do priest[l] = 0 end
	local wizardLevel, divine, divineLevel, combined, casters = 0, nil, 0, 0, 0
	for i = 1, count do
		local key = classes[i]
		if B24MC.SLOT_TABLE[key] then
			casters = casters + 1
			combined = combined + (B24MC.FULL_CASTER[key] and current[i] or math.floor(current[i] / 2))
			if key == "WIZARD" then
				wizardLevel = current[i]
			elseif divine == nil or B24MC.FULL_CASTER[key] then
				-- Cleric/Ranger: the priest slots follow the cleric table.
				divine, divineLevel = key, current[i]
			end
		end
	end
	if casters <= 1 or (wizardLevel == 0 and divine == nil) then
		for l = 1, 9 do mage[l] = tableSlots("MXSPLWIZ", wizardLevel, l) end
		for l = 1, 7 do priest[l] = divine and tableSlots(B24MC.SLOT_TABLE[divine], divineLevel, l) or 0 end
		return { mage = mage, priest = priest }
	end
	for l = 1, 9 do
		local total = tableSlots("MXSPLWIZ", combined, l)
		local w0 = tableSlots("MXSPLWIZ", wizardLevel, l)
		local p0 = (divine and l <= 7) and tableSlots(B24MC.SLOT_TABLE[divine], divineLevel, l) or 0
		local w
		if wizardLevel == 0 then
			w = 0
		elseif w0 + p0 == 0 then
			w = total
		else
			w = math.floor(total * w0 / (w0 + p0) + 0.5)
		end
		mage[l] = w
		local p = total - w
		priest[math.min(l, 7)] = priest[math.min(l, 7)] + p
	end
	return { mage = mage, priest = priest }
end

-- Writes the base slot counts; the counts with bonuses move by the same amount.
local function writeSlots(info, wanted, levelsCount)
	local changed = false
	for l = 1, levelsCount do
		local entry = EEex_ReadPtr(EEex_UDToPtr(info) + (l - 1) * 8)
		if entry ~= 0 and EEex_ReadU16(entry) == l - 1 then
			local base, withBonus = EEex_ReadU16(entry + 2), EEex_ReadU16(entry + 4)
			if base ~= wanted[l] then
				EEex_WriteU16(entry + 2, wanted[l])
				EEex_WriteU16(entry + 4, math.max(0, withBonus + wanted[l] - base))
				changed = true
			end
		end
	end
	return changed
end

function B24MC.UpdateSlots(sprite)
	local wanted = B24MC.WantedSlots(sprite)
	local a = writeSlots(sprite.m_memorizedSpellsLevelMage, wanted.mage, 9)
	local b = writeSlots(sprite.m_memorizedSpellsLevelPriest, wanted.priest, 7)
	return a or b
end

----------
-- Tick --
----------

-- Single classes: the engine adds the Constitution modifier only up to the class's 2e limit
-- (BG2's Korgan gained 6 at level 13, without his +5) and leaves the earlier levels alone when the
-- modifier rises (an Ability Score Improvement). In 2024 the modifier counts for every level.
-- Each second, against the base values (the engine writes level and hit points together):
--   - one level more (a level-up): what is missing of half the hit die + 1 and the modifier, and
--     of the modifier's change for every earlier level, is added (permanent bonuses from items or
--     quests stay);
--   - the same level, another modifier (an Ability Score Improvement, a permanent loss): the hit
--     points follow the change, up or down;
--   - anything else (levels set by the console or the tests, level drain) starts the count anew.
-- Locals: B24HPLV (level), B24HPCM (Constitution modifier + 100), B24HPBS (base hit points).
local function keepConHitPoints(sprite)
	local base = sprite.m_baseStats
	local level = base.m_level1
	local con = B24.AbilityMod(base.m_CONBase)
	local lastLevel, lastCon = sprite:getLocalInt("B24HPLV"), sprite:getLocalInt("B24HPCM") - 100
	local gained = base.m_maxHitPointsBase - sprite:getLocalInt("B24HPBS")
	local change = 0
	if lastLevel > 0 and level == lastLevel + 1 then
		local die = B24.HitDie(sprite)
		change = math.max(0, math.floor(die / 2) + 1 + con + (con - lastCon) * lastLevel - gained)
	elseif lastLevel > 0 and level == lastLevel and con ~= lastCon then
		change = (con - lastCon) * level - gained
	end
	if change ~= 0 then
		base.m_maxHitPointsBase = math.max(1, base.m_maxHitPointsBase + change)
		base.m_hitPoints = math.max(1, math.min(base.m_maxHitPointsBase, base.m_hitPoints + change))
		B24.Log(string.format("%s: %+d hit points for Constitution (2024 rule)", B24.Name(sprite), change))
	end
	sprite:setLocalInt("B24HPLV", level)
	sprite:setLocalInt("B24HPCM", con + 100)
	sprite:setLocalInt("B24HPBS", base.m_maxHitPointsBase)
end

-- Once a second for each party member (B24CD.Tick).
function B24MC.Tick(sprite)
	if B24.GState_Has(sprite, B24.GState.DEAD) then return end
	if not B24MC.IsMulti(sprite) then
		if sprite:getLocalInt("B24MCSGL") == 0 then sprite:setLocalInt("B24MCSGL", 1) end
		keepConHitPoints(sprite)
		return
	end
	convertDual(sprite)
	if sprite:getLocalInt("B24MCFIT") == 0 then
		sprite:setLocalInt("B24MCFIT", 1)
		-- The XP the levels were fitted to (the game may give a joining companion more XP later).
		sprite:setLocalInt("B24MCFXP", sprite.m_baseStats.m_xp)
		-- Companions who join with too many levels are rebuilt; a character who dual-classed in the
		-- party took its next level early and keeps it.
		if sprite:getLocalInt("B24MCSGL") == 0 and rebuild(sprite) then return end
	end
	rebuildHitPoints(sprite)
	EEex_Utility_TryIgnore(B24MC.UpdateSlots, sprite)
	-- The engine's level-up flag (the "+" on the portrait) follows the 2024 rule too.
	local flag = B24MC.CanLevelUp(sprite) and 1 or 0
	if sprite.m_bLevelUp ~= flag then sprite.m_bLevelUp = flag end
end

-- Attack bonus: the engine reads THAC0 at the highest class level; 2024 uses the total level.
B24.AddStatListener(function(sprite)
	if not B24MC.IsMulti(sprite) then return end
	local monster = B24.IsMonster(sprite)
	local extra = B24.ProfBonus(B24.Level(sprite), monster) - B24.ProfBonus(B24.HighestClassLevel(sprite), monster)
	if extra ~= 0 then
		local stats = sprite:getActiveStats()
		stats.m_nTHAC0 = stats.m_nTHAC0 - extra
	end
end)

--------------------
-- Record screen --
--------------------

-- XP of the next total level (the engine would count the classes' own tables).
function B24MC.XPProgress(sprite)
	local list = thresholds(mainClass(sprite))
	local _, count = B24MC.Classes(sprite)
	local nextLevel = math.min(B24MC.MAX_LEVEL, sum(levels(sprite, count)) + 1)
	return sprite.m_baseStats.m_xp, list[nextLevel] or list[#list]
end

local function multiSprite(id)
	local sprite = EEex_GameObject_Get(id)
	return B24.IsSprite(sprite) and B24MC.IsMulti(sprite) and sprite or nil
end

-- Progress bar of the record screen (UI.MENU item patched in b24_core_runtime.tpa).
function B24MC_XPPercent(id)
	local sprite = multiSprite(id)
	local c = characters[id]
	if sprite == nil then return c and getPercent(c.level.xp, c.level.nextLvlXp) or 0 end
	local xp, nextXP = B24MC.XPProgress(sprite)
	return getPercent(xp, nextXP)
end

EEex_Menu_AddAfterMainFileLoadedListener(function()
	local original = getNextLevelString
	if original == nil then return end
	function getNextLevelString()
		local ok, sprite = pcall(multiSprite, currentID)
		if not ok or sprite == nil then return original() end
		local xp, nextXP = B24MC.XPProgress(sprite)
		if nextXP - xp <= 0 then return getUiString("READY_TO_LEVEL_LABEL") end
		return getUiString("NEXT_LEVEL_LABEL") .. " " .. (nextXP - xp) .. " " .. getUiString("XP_LABEL")
	end
end)

------------------
-- Dual-classing --
------------------

-- Dual-class button (UI.MENU, patched in b24_core_runtime.tpa): BG allows it for humans only; in
-- 2024 every species may multiclass. A single-class character of level 2 or more whose class
-- may dual-class (DUALCLAS.2DA) and who has the abilities ABDCSCRQ.2DA asks for (13 in the main
-- ones) may. The new class's first level is a character level (the old class stays, see
-- convertDual): only with the XP for the next level, as a 2024 multiclass takes it at a level-up.
local DUAL_ROW = { [1] = "MAGE", [2] = "FIGHTER", [3] = "CLERIC", [4] = "THIEF", [11] = "DRUID", [12] = "RANGER" }
local ABILITY_COLUMNS = { MIN_STR = "STR", MIN_DEX = "DEX", MIN_CON = "CON", MIN_INT = "INT", MIN_WIS = "WIS", MIN_CHR = "CHA" }
local dualTables

local function nextLevelReady(sprite, row)
	xpTable = xpTable or B24.LoadTable("XPLEVEL")
	local need = tonumber((xpTable[row] or {})[tostring(sprite:getStat(B24.Stat.LEVEL) + 1)])
	return need ~= nil and sprite.m_baseStats.m_xp >= need
end

function B24MC.CanDualClass(sprite)
	local row = DUAL_ROW[B24.ClassID(sprite)]
	if row == nil or sprite:getStat(B24.Stat.LEVEL) < 2 or not nextLevelReady(sprite, row) then return false end
	if sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN then return false end
	dualTables = dualTables or { allowed = B24.LoadTable("DUALCLAS"), requirements = B24.LoadTable("ABDCSCRQ") }
	local any = false
	for _, value in pairs(dualTables.allowed[row] or {}) do
		if tonumber(value) == 1 then any = true end
	end
	if not any then return false end
	local requirements = dualTables.requirements[row] or {}
	for column, ability in pairs(ABILITY_COLUMNS) do
		if sprite:getStat(B24.AbilityStat[ability]) < (tonumber(requirements[column]) or 0) then return false end
	end
	return true
end

function B24MC_CanDualClass()
	local ok, result = pcall(function()
		local sprite = recordSprite()
		if sprite == nil then return false end
		local row = DUAL_ROW[B24.ClassID(sprite)]
		if characterScreen:IsDualClassButtonClickable() and row and nextLevelReady(sprite, row) then return true end
		return B24MC.CanDualClass(sprite)
	end)
	return ok and result == true
end
