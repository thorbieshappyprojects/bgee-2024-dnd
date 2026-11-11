-- BG 2024 Rules Mod: companions converted to the 2024 rules when they join the party.
--
-- A companion is a joinable NPC of PDIALOG.2DA (by script name). When one is first seen in the
-- party (local B24NPCFIT, per creature, so every chapter version of a companion gets it):
--   - ability scores in the 2024 range: exceptional Strength (18/xx) counts as 18, and no base score
--     is above 20 (items and story effects still raise them);
--   - single classes get the 2024 hit points: the maximum hit die at level 1, then the fixed value
--     (die / 2 + 1) per level, plus the Constitution modifier per level, as player characters get
--     them from the hit point tables; multiclasses get theirs from B24MULTI.lua;
--   - a kit without a 2024 counterpart (B24KITS.2DA) takes the class's first subclass, the SRD one,
--     instead of asking.
-- Class features, saves, skills and proficiencies follow from class and level, as for every
-- character.

B24NPC = {}

B24NPC.HIT_DIE = { FIGHTER = 10, BARBARIAN = 12, PALADIN = 10, RANGER = 10, CLERIC = 8, DRUID = 8, ROGUE = 8,
	BARD = 8, MONK = 8, SORCERER = 6, WIZARD = 6 }

B24NPC.EXTRA_NAMES = { "GLINT", "VOGHILN", "MKHIIN" }

local npcNames
local function companionNames()
	if npcNames == nil then
		npcNames = {}
		local ok, rows = pcall(B24.LoadTable, "PDIALOG")
		for name in pairs(ok and rows or {}) do npcNames[name:upper()] = true end
		-- Siege of Dragonspear's own companions: PDIALOG names them by their dialogs (BDGLINT,
		-- BDVOGHIL, BDMKHIIN), their creatures carry other script names.
		for _, name in ipairs(B24NPC.EXTRA_NAMES) do npcNames[name] = true end
	end
	return npcNames
end

function B24NPC.ScriptName(sprite)
	for _, get in ipairs({
		function() return sprite.m_scriptName:get() end,
		function() return sprite.m_typeAI.m_name:get() end,
	}) do
		local ok, name = pcall(get)
		if ok and type(name) == "string" and name ~= "" then return name:upper() end
	end
end

function B24NPC.IsCompanion(sprite)
	local protagonist = B24.Protagonist()
	if protagonist and protagonist.m_id == sprite.m_id then return false end
	local name = B24NPC.ScriptName(sprite)
	return name ~= nil and companionNames()[name] == true
end

local ABILITY_FIELDS = { "m_STRBase", "m_DEXBase", "m_CONBase", "m_INTBase", "m_WISBase", "m_CHRBase" }

local function abilities(sprite)
	local base, changed = sprite.m_baseStats, {}
	if base.m_STRExtraBase ~= 0 then
		base.m_STRExtraBase = 0
		table.insert(changed, "exceptional Strength")
	end
	for _, field in ipairs(ABILITY_FIELDS) do
		if base[field] > 20 then
			table.insert(changed, string.format("%s %d", field:sub(3, 5), base[field]))
			base[field] = 20
		end
	end
	return changed
end

local function hitPoints(sprite)
	local die = B24NPC.HIT_DIE[B24.SkillClass(sprite) or ""] or B24.HitDie(sprite)
	local level = B24.Level(sprite)
	local con = B24.AbilityModOf(sprite, "CON")
	local wanted = math.max(1, die + (level - 1) * (math.floor(die / 2) + 1) + con * level)
	local base = sprite.m_baseStats
	local old = base.m_maxHitPointsBase
	base.m_maxHitPointsBase = wanted
	base.m_hitPoints = wanted
	return old, wanted
end

-- Kits without a 2024 subclass: the class's first subclass.
local function defaultSubclasses(sprite)
	local set = {}
	for classKey, entry in pairs(B24LV.SUBCLASSES) do
		if B24LV.ClassLevel(sprite, classKey) >= entry.level and B24LV.Subclass(sprite, classKey) == nil then
			sprite:setLocalInt(B24LV.SubclassLocal(classKey), 1)
			table.insert(set, entry.list[1].name)
		end
	end
	return set
end

function B24NPC.Convert(sprite)
	-- Story creatures (Wilson) keep their BG statistics.
	if B24.IsStoryCreature(sprite) then
		sprite:setLocalInt("B24NPCFIT", 2)
		B24.Log(string.format("%s joins as in the story: BG statistics and abilities kept", B24.Name(sprite)))
		return
	end
	sprite:setLocalInt("B24NPCFIT", 1)
	-- The hit points are rebuilt here: the Constitution check (B24MULTI.lua) starts from them anew.
	sprite:setLocalInt("B24HPLV", 0)
	local changed = abilities(sprite)
	local hp
	if not (B24MC and B24MC.IsMulti(sprite)) then
		local old, wanted = hitPoints(sprite)
		hp = string.format("%d hit points (was %d)", wanted, old)
	end
	local subclasses = defaultSubclasses(sprite)
	-- The engine recomputes the stats from the base values once an effect is removed.
	B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60,
		["m_sourceRes"] = "B24NPCRF" })
	B24.RemoveEffectsBySource(sprite, "B24NPCRF")
	local parts = {}
	if hp then table.insert(parts, hp) end
	if #changed > 0 then table.insert(parts, "abilities: " .. table.concat(changed, ", ") .. " to the 2024 range") end
	if #subclasses > 0 then table.insert(parts, "subclass " .. table.concat(subclasses, ", ")) end
	B24.Log(string.format("%s joins under the 2024 rules: %s", B24.Name(sprite), #parts > 0 and table.concat(parts, "; ") or "no changes"))
end

B24LV.AddTickListener(function(sprite)
	if sprite:getLocalInt("B24NPCFIT") ~= 0 or B24.GState_Has(sprite, B24.GState.DEAD) then return end
	if not B24NPC.IsCompanion(sprite) or B24.IsMonster(sprite) then
		-- The protagonist and player-made characters are built under the 2024 rules already; shapes
		-- like Cernd's bear form keep their monster statistics.
		sprite:setLocalInt("B24NPCFIT", 2)
		return
	end
	EEex_Utility_TryIgnore(B24NPC.Convert, sprite)
end)
