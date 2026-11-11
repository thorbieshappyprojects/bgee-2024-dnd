-- BG 2024 Rules Mod: shared rules math and helpers used by the other B24 scripts.

B24 = B24 or {}

B24.Config = {
	-- Print save throws, concentration and rest results to the message log.
	verboseLog = true,
	-- Short rest is refused while an enemy is within this range of the resting character.
	shortRestEnemyRange = 400,
	-- Short rests the party can take between two long rests.
	shortRestsPerLongRest = 2,
	-- BG thief skill percentage = base + perPoint * 2024 check bonus (ability modifier + proficiency).
	skillPercentBase = 25,
	skillPercentPerPoint = 5,
	-- Pause at the start of combat and of every 6-second round while it lasts (B24ROUND.lua).
	roundPause = true,
	-- In combat, seconds of movement per round (B24ROUND.lua): about 30 ft at BG's walking pace.
	moveLimit = true,
	moveSecondsPerRound = 3,
	-- Turn-based combat (B24TURN.lua) can be switched on in game (the button on the game screen);
	-- false turns the option off altogether.
	turnBased = true,
	-- Ranged attacks in melee (B24ADV.lua): disadvantage while an enemy is within 5 ft (2024);
	-- false keeps the engine's penalty for shooting at an adjacent target.
	rangedInMelee2024 = true,
	-- Movement multiplier lost per exhaustion level (2024: -5 ft of 30 ft).
	exhaustionSpeedPercent = 17,
}

-- Distances in world units (area coordinates, the same at any screen resolution). A foot is 6.4
-- units: the engine's spell ranges are in feet (5 ft = 32, measured with the RangeProbe test), and
-- a creature sees 448 (70 ft). "Within N feet" counts from the creature's edge, the range searches
-- from its centre: half a medium creature's selection circle (16) is added.
B24.FOOT = 6.4
function B24.Feet(feet) return math.floor(feet * B24.FOOT + 16 + 0.5) end
-- Next to a creature (5 ft, melee): centre to centre, generous enough for large creatures' circles.
B24.ADJACENT = 80

B24.Stat = {
	MAXHP = 1, AC = 2, THAC0 = 7, LEVEL = 34, STR = 36, STREX = 37, INT = 38, WIS = 39,
	DEX = 40, CON = 41, CHA = 42, HELD = 58, LEVEL2 = 68, LEVEL3 = 69, KIT = 152,
}

B24.AbilityStat = { STR = 36, DEX = 40, CON = 41, INT = 38, WIS = 39, CHA = 42 }

-- STATE.IDS bits
B24.GState = {
	SLEEPING = 0x1, PANIC = 0x4, STUNNED = 0x8, INVISIBLE = 0x10, HELPLESS = 0x20,
	STONE_DEATH = 0x80, DEAD = 0x800, CHARMED = 0x2000, POISONED = 0x4000, BLIND = 0x40000,
	IMPROVEDINVISIBILITY = 0x400000,
}

-- KIT stat value (KIT.IDS) of the Barbarian kit; 0x4000 is TRUECLASS (no kit).
B24.KIT_BARBARIAN = 0x40000000

----------------
-- Ability math --
----------------

function B24.AbilityMod(score)
	return math.floor((score - 10) / 2)
end

-- Proficiency bonus by level: +2 at 1, +6 at 17. Characters stop at 20; monsters use the
-- CR table, which keeps rising to +9 at 29.
function B24.ProfBonus(level, isMonster)
	level = math.max(1, level)
	level = math.min(level, isMonster and 30 or 20)
	return 2 + math.floor((level - 1) / 4)
end

function B24.HasBit(value, bit)
	return value % (bit * 2) >= bit
end

function B24.Roll(sides)
	return math.random(1, sides)
end

function B24.RollD20(advantage, disadvantage)
	local a = B24.Roll(20)
	if advantage == disadvantage then return a end
	local b = B24.Roll(20)
	return advantage and math.max(a, b) or math.min(a, b)
end

------------
-- Sprites --
------------

function B24.IsSprite(object)
	return object ~= nil and EEex_GameObject_IsSprite(object, true)
end

function B24.GetSprite(id)
	if id == nil or id == -1 then return nil end
	local object = EEex_GameObject_Get(id)
	return B24.IsSprite(object) and object or nil
end

function B24.Name(sprite)
	local ok, name = pcall(EEex_Sprite_GetName, sprite)
	return ok and name or "?"
end

function B24.AbilityScore(sprite, ability)
	return sprite:getStat(B24.AbilityStat[ability])
end

function B24.AbilityModOf(sprite, ability)
	return B24.AbilityMod(B24.AbilityScore(sprite, ability))
end

function B24.ClassID(sprite)
	return sprite.m_typeAI.m_Class
end

-- CLASS.IDS values above 21 are monster classes.
-- Story creatures: companions that the story makes something other than their class (Wilson, a
-- bear on the Fighter class with the GRIZZLY_BEAR kit). They keep their BG statistics and
-- abilities (claws, attacks, regeneration, Strength, hit points): no 2024 conversion, class
-- features, subclass or level-up choices; they count as monsters for the rules (no weapon
-- proficiency or mastery). Level-ups still raise hit points and the proficiency bonus.
-- KIT.IDS lists GRIZZLY_BEAR as 0x4027; the stat may come with the words swapped (see B24.KIT_BARBARIAN).
B24.STORY_CREATURE_KITS = { [0x4027] = "bear", [0x40270000] = "bear" }

function B24.IsStoryCreature(sprite)
	-- The creature file's kit first: the derived stat is still empty right after a creature
	-- appears (the companion conversion ran before it was set, and rebuilt Wilson).
	local ok, kit = pcall(function()
		local base = sprite.m_baseStats
		return EEex_BOr(EEex_LShift(base.m_mageSpecUpperWord, 16), base.m_mageSpecialization)
	end)
	if ok and B24.STORY_CREATURE_KITS[kit] ~= nil then return true end
	ok, kit = pcall(function() return sprite:getStat(B24.Stat.KIT) end)
	return ok and B24.STORY_CREATURE_KITS[kit] ~= nil
end

function B24.IsMonster(sprite)
	local class = B24.ClassID(sprite)
	return class == 0 or class > 21 or B24.IsStoryCreature(sprite)
end

-- CLASS.IDS multiclass values -> number of classes. Other creatures only use the first
-- level field (the others often hold junk).
B24.MulticlassCount = { [7] = 2, [8] = 2, [9] = 2, [10] = 3, [13] = 2, [14] = 2, [15] = 2, [16] = 2, [17] = 3, [18] = 2 }

-- Character level: as in 2024, the sum of the class levels (multiclasses and dual-classes, see
-- B24MULTI.lua).
function B24.Level(sprite)
	local s = B24.Stat
	local level = sprite:getStat(s.LEVEL)
	local classes = B24.MulticlassCount[B24.ClassID(sprite)] or 1
	if classes >= 2 then level = level + sprite:getStat(s.LEVEL2) end
	if classes >= 3 then level = level + sprite:getStat(s.LEVEL3) end
	return math.max(1, level)
end

-- The highest single class level (what the engine's per-class tables, e.g. THAC0, are read at).
function B24.HighestClassLevel(sprite)
	local s = B24.Stat
	local level = sprite:getStat(s.LEVEL)
	local classes = B24.MulticlassCount[B24.ClassID(sprite)] or 1
	if classes >= 2 then level = math.max(level, sprite:getStat(s.LEVEL2)) end
	if classes >= 3 then level = math.max(level, sprite:getStat(s.LEVEL3)) end
	return math.max(1, level)
end

function B24.ProfOf(sprite)
	return B24.ProfBonus(B24.Level(sprite), B24.IsMonster(sprite))
end

function B24.InParty(sprite)
	return EEex_Sprite_GetPortraitIndex(sprite) ~= -1
end

function B24.Party()
	local party = {}
	for i = 0, 5 do
		local sprite = EEex_Sprite_GetInPortrait(i)
		if B24.IsSprite(sprite) then
			table.insert(party, sprite)
		end
	end
	return party
end

function B24.GState_Has(sprite, bit)
	return B24.HasBit(sprite:getState(), bit)
end

function B24.Aux(sprite)
	return EEex_GetUDAux(sprite)
end

function B24.GameTick()
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
end

function B24.Log(text)
	if B24.Config.verboseLog then
		Infinity_DisplayString("BG2024: " .. text)
	end
end

---------------
-- Data tables --
---------------

-- Reads a 2DA into { [ROWLABEL] = { [COLUMNLABEL] = "value" } }.
function B24.LoadTable(resref)
	local array = EEex_Resource_Load2DA(resref)
	local sizeX, sizeY = array:getDimensions()
	local rows = {}
	for y = 0, sizeY - 1 do
		local row = {}
		for x = 0, sizeX - 1 do
			row[array:getColumnLabel(x):upper()] = array:getAtPoint(x, y)
		end
		rows[array:getRowLabel(y):upper()] = row
	end
	return rows
end

B24.ClassData = B24.LoadTable("B24CLASS")

function B24.ClassRow(sprite)
	if sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN then
		return B24.ClassData["BARBARIAN"]
	end
	return B24.ClassData[tostring(B24.ClassID(sprite))]
end

function B24.HitDie(sprite)
	local row = B24.ClassRow(sprite)
	return row and tonumber(row.HIT_DIE) or 8
end

-- listener(sprite, ability) returns true for save proficiencies from class features (e.g. the
-- Rogue's Slippery Mind).
B24.SaveProficiencyListeners = {}
function B24.AddSaveProficiencyListener(listener) table.insert(B24.SaveProficiencyListeners, listener) end

function B24.IsSaveProficient(sprite, ability)
	local row = B24.ClassRow(sprite)
	if row then
		if row.SAVE1 == ability or row.SAVE2 == ability then return true end
		for _, listener in ipairs(B24.SaveProficiencyListeners) do
			local ok, result = pcall(listener, sprite, ability)
			if ok and result then return true end
		end
		return false
	end
	return B24.MonsterSaveProficient(sprite, ability)
end

-- Monsters are proficient in two saves chosen by creature type (GENERAL.IDS).
B24.MonsterSaves = {
	[1]   = { "DEX", "WIS" }, -- HUMANOID without a class row
	[2]   = { "STR", "DEX" }, -- ANIMAL
	[4]   = { "DEX", "WIS" }, -- UNDEAD
	[5]   = { "STR", "CON" }, -- GIANTHUMANOID
	[7]   = { "CON", "WIS" }, -- PLANT
	[255] = { "CON", "WIS" }, -- MONSTER
}

function B24.MonsterSaveProficient(sprite, ability)
	local saves = B24.MonsterSaves[sprite.m_typeAI.m_General] or B24.MonsterSaves[255]
	return saves[1] == ability or saves[2] == ability
end

-- Casting ability for a spell resource. Arcane (SPWI) and divine (SPPR) spells use the class
-- table; innate abilities and monsters use their best mental score.
-- Spells whose DC uses a fixed ability, by resref prefix (e.g. the Dragonborn breath weapon: Con).
B24.CASTING_ABILITY_PREFIXES = {}
-- listener(sprite, spellRes) returns an ability key to use instead (e.g. Intelligence for the
-- Eldritch Knight's wizard spells), or nil.
B24.CastingAbilityListeners = {}

-- Innate copies of spells (B24IP101 for SPPR101, B24IW914 for SPWI914, made by the Spells
-- component for Divine Intervention and Magical Secrets) count as the spell they copy.
function B24.OriginalSpellRes(res)
	local prefix = res and res:upper():sub(1, 5)
	if prefix == "B24IP" then return "SPPR" .. res:sub(6):upper() end
	if prefix == "B24IW" then return "SPWI" .. res:sub(6):upper() end
	return res
end

function B24.InnateCopy(res)
	res = res:upper()
	if res:sub(1, 4) == "SPPR" then return "B24IP" .. res:sub(5) end
	if res:sub(1, 4) == "SPWI" then return "B24IW" .. res:sub(5) end
	return res
end

function B24.CastingAbility(sprite, spellRes)
	for _, listener in ipairs(B24.CastingAbilityListeners) do
		local ok, ability = pcall(listener, sprite, spellRes or "")
		if ok and ability then return ability end
	end
	for prefix, ability in pairs(B24.CASTING_ABILITY_PREFIXES) do
		if spellRes:upper():sub(1, #prefix) == prefix then return ability end
	end
	local row = not B24.IsMonster(sprite) and B24.ClassRow(sprite) or nil
	if row then
		local prefix = B24.OriginalSpellRes(spellRes):sub(1, 4)
		local ability = (prefix == "SPWI" and row.ARCANE) or (prefix == "SPPR" and row.DIVINE) or nil
		if ability == nil or ability == "NONE" then
			ability = (row.ARCANE ~= "NONE" and row.ARCANE) or (row.DIVINE ~= "NONE" and row.DIVINE) or nil
		end
		if ability and ability ~= "NONE" then return ability end
	end
	local best, bestScore = "INT", -1
	for _, ability in ipairs({ "INT", "WIS", "CHA" }) do
		local score = B24.AbilityScore(sprite, ability)
		if score > bestScore then best, bestScore = ability, score end
	end
	return best
end

-- 8 + proficiency + casting ability modifier.
-- listener(sprite, spellRes) returns a bonus to the spell save DC (e.g. the Sorcerer's Innate
-- Sorcery).
B24.SpellDCListeners = {}
function B24.AddSpellDCListener(listener) table.insert(B24.SpellDCListeners, listener) end

function B24.SpellSaveDC(sprite, spellRes, ability)
	ability = ability or B24.CastingAbility(sprite, spellRes)
	local dc = 8 + B24.ProfOf(sprite) + B24.AbilityModOf(sprite, ability)
	for _, listener in ipairs(B24.SpellDCListeners) do
		local ok, bonus = pcall(listener, sprite, spellRes)
		if ok and bonus then dc = dc + bonus end
	end
	return dc
end

-------------
-- Effects --
-------------

function B24.ApplyEffect(sprite, args)
	args.sourceID = args.sourceID or sprite.m_id
	args.sourceTarget = args.sourceTarget or sprite.m_id
	sprite:applyEffect(args)
end

-- Summons a creature next to the sprite for a while (op67 places it at the effect's target point,
-- which ApplyEffect would otherwise leave at -1, -1).
function B24.Summon(sprite, res, seconds)
	B24.ApplyEffect(sprite, { ["effectID"] = 67, ["res"] = res, ["dwFlags"] = 0, ["durationType"] = 0,
		["duration"] = seconds, ["targetX"] = sprite.m_pos.x + 40, ["targetY"] = sprite.m_pos.y })
end

-- BG2's Slayer form (SPIN823: polymorph into SLAYER.CRE): told by its animation. While it lasts
-- the 2024 AC stays at most 22 (engine AC -2; the monster pass holds creatures to 10-22, the form
-- would add the character's own AC bonuses on top), and it counts as Large (B24.Size).
B24.SLAYER_ANIMATION = 0x7F32
B24.SLAYER_MIN_ENGINE_AC = -2
function B24.IsSlayer(sprite)
	local ok, id = pcall(function() return sprite.m_animation.m_animation.m_animationID end)
	return ok and id == B24.SLAYER_ANIMATION
end

-- Creature size (the engine has none): from the selection circle (personal space: 3 for humans,
-- larger for ogres, giants and dragons), one step up or down for Enlarge/Reduce (B24.SizeShiftOf,
-- B24SPELL.lua).
B24.SIZE = { TINY = 1, SMALL = 2, MEDIUM = 3, LARGE = 4, HUGE = 5, GARGANTUAN = 6 }
function B24.Size(sprite)
	local ok, space = pcall(EEex_Sprite_GetPersonalSpace, sprite)
	space = ok and space or 3
	local size = space <= 3 and B24.SIZE.MEDIUM or space <= 5 and B24.SIZE.LARGE or space <= 9 and B24.SIZE.HUGE
		or B24.SIZE.GARGANTUAN
	-- The Slayer form (B24.IsSlayer) is Large at least.
	if B24.IsSlayer(sprite) and size < B24.SIZE.LARGE then size = B24.SIZE.LARGE end
	local shift = B24.SizeShiftOf and B24.SizeShiftOf(sprite) or 0
	return math.max(B24.SIZE.TINY, math.min(B24.SIZE.GARGANTUAN, size + shift))
end

-- Forced movement: the target moves feet away from the source (pull: toward it, stopping next to
-- it), to the nearest open spot, at once (op124 to the effect's point). maxSize: only creatures of
-- that size or smaller move (2024 "Large or smaller"). Returns true if it moved.
function B24.ForceMove(target, source, feet, pull, maxSize)
	if target == nil or source == nil or target.m_id == source.m_id then return false end
	if maxSize and B24.Size(target) > maxSize then
		B24.Log(string.format("%s is too big to be moved", B24.Name(target)))
		return false
	end
	local dx, dy = target.m_pos.x - source.m_pos.x, target.m_pos.y - source.m_pos.y
	local length = math.sqrt(dx * dx + dy * dy)
	if length < 1 then dx, dy, length = 1, 0, 1 end
	local step = feet * B24.FOOT
	if pull then step = -math.min(step, math.max(0, length - B24.Feet(5))) end
	if step == 0 then return false end
	local x, y = target.m_pos.x + dx / length * step, target.m_pos.y + dy / length * step
	local ok, ox, oy = pcall(EEex_Area_GetNearestOpenPosition, target.m_pArea, math.floor(x), math.floor(y),
		select(2, pcall(EEex_Sprite_GetPersonalSpace, target)) or 3)
	if ok and ox and oy then x, y = ox, oy end
	B24.ApplyEffect(target, { ["effectID"] = 124, ["targetX"] = math.floor(x), ["targetY"] = math.floor(y),
		["sourceID"] = source.m_id })
	B24.Log(string.format("%s is %s %d ft", B24.Name(target), pull and "pulled" or "pushed", feet))
	return true
end

-- The mod's choices live in creature variables (subclass, feats, masteries, skills...). A save
-- keeps them, but an exported character (BG:EE to BG2:EE) gets only the variables of the save it
-- was loaded from. So on Export (B24_RecordDone, the record screen's Done) every mod variable used
-- in this session goes into the character as a permanent op402 effect (B24LOCL: value, name in
-- res2 + res3); in the game that imports it, the effect restores the variable and is removed.
B24.LOCALS_RES = "B24LOCL"
B24.UsedLocals = {}
do
	local getInt, setInt = CGameSprite.getLocalInt, CGameSprite.setLocalInt
	CGameSprite.getLocalInt = function(sprite, name, ...)
		if name:sub(1, 3) == "B24" then B24.UsedLocals[name] = true end
		return getInt(sprite, name, ...)
	end
	CGameSprite.setLocalInt = function(sprite, name, ...)
		if name:sub(1, 3) == "B24" then B24.UsedLocals[name] = true end
		return setInt(sprite, name, ...)
	end
end

function B24.WriteLocalCarriers(sprite)
	B24.RemoveEffectsBySource(sprite, B24.LOCALS_RES)
	B24.WritingCarriers = true
	local n = 0
	for name in pairs(B24.UsedLocals) do
		B24.ApplyEffect(sprite, { ["effectID"] = 402, ["res"] = B24.LOCALS_RES, ["effectAmount"] = sprite:getLocalInt(name),
			["durationType"] = 9, ["m_res2"] = name:sub(1, 8), ["m_res3"] = name:sub(9, 16), ["m_sourceRes"] = B24.LOCALS_RES })
		n = n + 1
	end
	B24.WritingCarriers = false
	B24.Log(string.format("%s: %d mod variables go with the exported character", B24.Name(sprite), n))
end

function B24LOCL(op402, sprite)
	if B24.WritingCarriers then return end
	EEex_Utility_TryIgnore(function()
		local name = op402.m_res2:get() .. op402.m_res3:get()
		if name == "" then return end
		sprite:setLocalInt(name, op402.m_effectAmount)
		B24.CarrierCleanup = B24.CarrierCleanup or {}
		B24.CarrierCleanup[sprite.m_id] = true
	end)
end

-- The record screen's Done button (all its panels): on the Export panel the character takes its
-- mod variables along, which are taken off again once the file is written.
function B24_RecordDone()
	local sprite = currentPanelID ~= nil and const ~= nil and currentPanelID == const.EXPORT_ID and B24.GetSprite(currentID)
	if sprite then EEex_Utility_TryIgnore(B24.WriteLocalCarriers, sprite) end
	characterScreen:OnDoneButtonClick()
	if sprite then B24.RemoveEffectsBySource(sprite, B24.LOCALS_RES) end
end

-- Removes every effect that was applied with the given source resource.
-- Puts innate abilities at the front of the innate bar, in the order given. The bar follows the
-- order of the known and the memorized innate lists (the order they were gained), so their entries
-- for these resrefs move to the head: the list nodes stay, their data pointers are reordered. A
-- node layout other than the expected one (data at +0x10) leaves the list untouched.
local function innatesFirst(list, resOf, order)
	local nodes, node = {}, list.m_pNodeHead
	while node do
		local address = EEex_UDToPtr(node) + 0x10
		if EEex_ReadPtr(address) ~= EEex_UDToPtr(node.data) then return end
		table.insert(nodes, { address = address, data = EEex_ReadPtr(address), res = resOf(node.data):upper() })
		node = node.pNext
	end
	local sorted = {}
	for _, res in ipairs(order) do
		for _, entry in ipairs(nodes) do
			if entry.res == res then table.insert(sorted, entry) end
		end
	end
	if #sorted == 0 then return end
	local wanted = {}
	for _, entry in ipairs(order) do wanted[entry] = true end
	for _, entry in ipairs(nodes) do
		if not wanted[entry.res] then table.insert(sorted, entry) end
	end
	for i, entry in ipairs(nodes) do
		if sorted[i].data ~= entry.data then EEex_WritePtr(entry.address, sorted[i].data) end
	end
end

-- The innate lists are one-entry arrays in the bindings (like the mage and priest lists per level).
function B24.InnateList(field)
	local ok, list = pcall(function() return field:getReference(0) end)
	return ok and list or field
end

function B24.InnatesFirst(sprite, order)
	innatesFirst(B24.InnateList(sprite.m_knownSpellsInnate), function(spell) return spell.m_knownSpellId:get() end, order)
	innatesFirst(B24.InnateList(sprite.m_memorizedSpellsInnate), function(spell) return spell.m_spellId:get() end, order)
end

function B24.RemoveEffectsBySource(sprite, res)
	B24.ApplyEffect(sprite, { ["effectID"] = 321, ["res"] = res })
end

-- Portrait icons of the mod's states (B24.PortraitIcon from B24STATE.lua; keys like RAGE, CONC).
-- ShowIcon(sprite, key, seconds) shows the icon for that many seconds, or without seconds until
-- HideIcon. Each state's icon effect has its own source resource, so hiding removes nothing else.
function B24.IconRes(key) return "B24I" .. key end

function B24.ShowIcon(sprite, key, seconds)
	local icon = B24.PortraitIcon and B24.PortraitIcon[key]
	if icon == nil then return end
	B24.RemoveEffectsBySource(sprite, B24.IconRes(key))
	B24.ApplyEffect(sprite, { ["effectID"] = 142, ["dwFlags"] = icon, ["durationType"] = seconds and 0 or 9,
		["duration"] = seconds or 0, ["m_sourceRes"] = B24.IconRes(key) })
end

function B24.HideIcon(sprite, key)
	if B24.PortraitIcon and B24.PortraitIcon[key] then B24.RemoveEffectsBySource(sprite, B24.IconRes(key)) end
end

-- Icons that follow a state: listener(sprite, keys) sets keys[key] = true for each state the
-- creature is in. B24.UpdateIcons (party members, once a second from B24CD.Tick) shows and hides
-- only the icons that changed. The shown set lives in aux, which a loaded game starts without, so
-- the first update after a load hides every icon whose state is gone.
B24.IconListeners = {}
function B24.AddIconListener(listener) table.insert(B24.IconListeners, listener) end

function B24.UpdateIcons(sprite)
	if B24.PortraitIcon == nil then return end
	local keys = {}
	for _, listener in ipairs(B24.IconListeners) do pcall(listener, sprite, keys) end
	local aux = B24.Aux(sprite)
	local shown = aux.B24_Icons or B24.PortraitIcon
	for key in pairs(keys) do
		if aux.B24_Icons == nil or not shown[key] then B24.ShowIcon(sprite, key) end
	end
	for key in pairs(shown) do
		if not keys[key] then B24.HideIcon(sprite, key) end
	end
	aux.B24_Icons = keys
end

function B24.HasEffectSource(sprite, opcode, sourceRes)
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == opcode and effect.m_sourceRes:get() == sourceRes then
			found = true
			return true
		end
	end)
	return found
end

function B24.HasEffect(sprite, opcode, res)
	local found = false
	local test = function(effect)
		if effect.m_effectId == opcode and effect.m_res:get() == res then
			found = true
			return true
		end
	end
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, test)
	return found
end

----------------------
-- Stat adjustments --
----------------------

-- When an effect is added, the engine resolves a creature's effect lists again without resetting
-- its stats first; a lists-resolved listener that adds to a stat would add a second time. Stat
-- listeners registered here run on every resolution: what they changed in the last one is taken
-- back first, unless the engine has reset the stats since (the marker below is then gone).
-- listener(sprite) changes sprite:getActiveStats().
B24.StatListeners = {}
function B24.AddStatListener(listener) table.insert(B24.StatListeners, listener) end

-- The Slayer form's AC: at most 2024 AC 22 (B24.IsSlayer).
B24.AddStatListener(function(sprite)
	if not B24.IsSlayer(sprite) then return end
	local stats = sprite:getActiveStats()
	if stats.m_nArmorClass < B24.SLAYER_MIN_ENGINE_AC then stats.m_nArmorClass = B24.SLAYER_MIN_ENGINE_AC end
end)

-- The fields stat listeners may change.
B24.ADJUSTED_FIELDS = {
	"m_nArmorClass", "m_nMaxHitPoints", "m_nTHAC0", "m_nSTR", "m_nDEX", "m_nCON", "m_nLore", "m_nHideInShadows", "m_nMoveSilently",
	"m_nPickPocket", "m_nLockPicking", "m_nSetTraps", "m_nTraps", "m_nDetectIllusion",
}
-- EXTRAPROFICIENCY20 is unused by the games; the engine resets it with the other stats.
B24.STATS_MARKER_FIELD = "m_nExtraProficiency20"
B24.STATS_MARKER = 99

function B24.OnStatsResolved(sprite)
	local stats = sprite:getActiveStats()
	local aux = B24.Aux(sprite)
	if stats[B24.STATS_MARKER_FIELD] == B24.STATS_MARKER and aux.B24_StatDeltas then
		for field, delta in pairs(aux.B24_StatDeltas) do stats[field] = stats[field] - delta end
	end
	local before = {}
	for _, field in ipairs(B24.ADJUSTED_FIELDS) do before[field] = stats[field] end
	for _, listener in ipairs(B24.StatListeners) do
		EEex_Utility_TryIgnore(listener, sprite)
	end
	local deltas = {}
	for _, field in ipairs(B24.ADJUSTED_FIELDS) do
		if stats[field] ~= before[field] then deltas[field] = stats[field] - before[field] end
	end
	aux.B24_StatDeltas = deltas
	stats[B24.STATS_MARKER_FIELD] = B24.STATS_MARKER
end
EEex_Opcode_AddListsResolvedListener(B24.OnStatsResolved)

------------
-- Events --
------------

B24.ShortRestListeners = {}
B24.LongRestListeners = {}

-- Class components register here to restore their resources: listener(sprite).
function B24.AddShortRestListener(listener) table.insert(B24.ShortRestListeners, listener) end
function B24.AddLongRestListener(listener) table.insert(B24.LongRestListeners, listener) end

function B24.Fire(listeners, ...)
	for _, listener in ipairs(listeners) do
		EEex_Utility_TryIgnore(listener, ...)
	end
end
