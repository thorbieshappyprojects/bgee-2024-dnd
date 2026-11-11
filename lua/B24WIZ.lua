-- BG 2024 Rules Mod: the 2024 Wizard with the Evoker (SRD subclass). Wizard spells use the Spells
-- component (2024 slots and spell list).
--
--   1  Spellcasting, Ritual Adept (no rituals in BG), Arcane Recovery (after a short rest, once per
--      long rest: spent slots worth half the Wizard level, none above 5th), cantrips (3; 4 at 4, 5 at 10)
--   2  Scholar (Expertise in one skill)
--   3  Subclass: Evoker: Evocation Savant (no BG effect), Potent Cantrip (creatures that save
--      against your cantrips still take half damage)
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Memorize Spell (after a short rest, one newly prepared spell becomes ready)
--   6  Evoker: Sculpt Spells (party members automatically succeed against your evocation spells
--      and take no damage)
--   10 Evoker: Empowered Evocation (Intelligence modifier to evocation spell damage)
--   14 Evoker: Overchannel (maximum damage; later uses hurt), 18 Spell Mastery (a 1st- and a
--      2nd-level spell at will), 20 Signature Spells (two 3rd-level spells once per short rest)

B24WZ = {}

function B24WZ.Level(sprite)
	return B24LV.ClassLevel(sprite, "WIZARD")
end

B24LV.AddSubclasses("WIZARD", 3, {
	{ key = "EVOKER", name = "Evoker",
	  desc = "Evokers shape raw elemental power.\n\nLevel 3: Potent Cantrip (creatures that save against your cantrips still take half damage); Evocation Savant (no BG effect).\nLevel 6: Sculpt Spells (party members succeed against your evocation spells and take no damage).\nLevel 10: Empowered Evocation (Intelligence modifier to the damage of your evocation spells).\nLevel 14: Overchannel (your next wizard spell of level 1-5 deals maximum damage; after the first use per long rest it costs you necrotic damage).",
	  features = { [3] = "Potent Cantrip", [6] = "Sculpt Spells", [10] = "Empowered Evocation", [14] = "Overchannel" } },
})

local function isEvoker(sprite)
	return B24LV.Subclass(sprite, "WIZARD") == "EVOKER"
end

B24WZ.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24WZ.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24WZ.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, CANTRIP = 3 + (level >= 4 and 1 or 0) + (level >= 10 and 1 or 0),
		EXPERTISE = level >= 2 and 1 or 0 }
end)

B24WZ.FEATURES = {
	[1] = "Spellcasting, Arcane Recovery, cantrips (3)",
	[2] = "Scholar (Expertise in one skill)",
	[3] = "Subclass",
	[4] = "Ability Score Improvement, cantrips (4)",
	[5] = "Memorize Spell",
	[8] = "Ability Score Improvement",
	[10] = "cantrips (5)",
	[12] = "Ability Score Improvement",
	[16] = "Ability Score Improvement",
	[18] = "Spell Mastery (a 1st- and a 2nd-level spell at will)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Signature Spells (two 3rd-level spells once per short rest)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24WZ.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "WIZARD") + 1, level do
		if B24WZ.FEATURES[l] then table.insert(lines, string.format("Wizard %d: %s", l, B24WZ.FEATURES[l])) end
	end
	return lines
end)

B24LV.WhenSpells(function()
	-- Potent Cantrip (3).
	table.insert(B24SP.PotentCantripListeners, function(caster)
		return B24WZ.Level(caster) >= 3 and isEvoker(caster)
	end)

	-- Sculpt Spells (6): party members are unaffected by the evoker's evocation spells.
	B24.AddSaveAutoSuccessListener(function(effect, sprite)
		local caster = B24.GetSprite(effect.m_sourceId)
		if caster == nil or caster.m_id == sprite.m_id or not B24.InParty(sprite) then return false end
		if B24WZ.Level(caster) < 6 or not isEvoker(caster) then return false end
		local res = effect.m_sourceRes:get()
		return res:sub(1, 4) == "SPWI" and B24SP.SpellSchool(res) == B24SP.EVOCATION
	end)

	-- Empowered Evocation (10): Intelligence modifier to wizard evocation spell damage.
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if B24WZ.Level(caster) < 10 or not isEvoker(caster) then return end
		if res:sub(1, 4) ~= "SPWI" or B24SP.SpellSchool(res) ~= B24SP.EVOCATION then return end
		effect.m_effectAmount = effect.m_effectAmount + math.max(0, B24.AbilityModOf(caster, "INT"))
	end)
end)

----------------
-- Spellbook --
----------------

-- 2024: the spellbook holds six spells at level 1 and two more for every Wizard level after that.
-- BG's character creation gives fewer, and BG wizards otherwise learn only from scrolls: the
-- Spellbook choice (B24LEVEL.lua) tops the book up to that size with wizard spells of levels the
-- Wizard can cast. Spells copied from scrolls count toward it; upcast copies don't.
local catalog = nil

local function wizardSpells()
	if catalog then return catalog end
	catalog = {}
	for res, row in pairs(B24.LoadTable("B24SPELL")) do
		local level = tonumber(row.LEVEL)
		if level and (row.ACTION == "SRD" or row.ACTION == "KEEP") and row.LISTS:find("W", 1, true) then
			local actual = B24SP.MOVED[res] or res
			local ok, name = pcall(function() return Infinity_FetchString(EEex_Resource_Demand(actual, "SPL").genericName) end)
			if ok then table.insert(catalog, { res = actual, level = level, name = name }) end
		end
	end
	table.sort(catalog, function(a, b) return a.level < b.level or (a.level == b.level and a.name < b.name) end)
	return catalog
end

-- Known wizard spells (set) and how many count toward the spellbook.
local function knownSpells(sprite)
	local known, count = {}, 0
	for _, _, res in EEex_Sprite_GetKnownMageSpellsIterator(sprite, 1, 9) do
		res = res:upper()
		known[res] = true
		if B24SP.UPCAST[res] == nil then count = count + 1 end
	end
	return known, count
end

B24LV.WhenSpells(function()
	B24LV.Spellbook = {
		Options = function(sprite)
			local maxLevel = math.min(9, math.floor((B24WZ.Level(sprite) + 1) / 2))
			local known = knownSpells(sprite)
			local options = {}
			for _, spell in ipairs(wizardSpells()) do
				if spell.level <= maxLevel and not known[spell.res] then table.insert(options, spell) end
			end
			return options
		end,
		Pending = function(sprite)
			local level = B24WZ.Level(sprite)
			if level <= 0 then return 0 end
			local _, count = knownSpells(sprite)
			local missing = 6 + 2 * (level - 1) - count
			if missing <= 0 then return 0 end
			return math.min(missing, #B24LV.Spellbook.Options(sprite))
		end,
	}
end)

----------------------------------------
-- Arcane Recovery and Memorize Spell --
----------------------------------------

-- Wizard spells cast since the last long rest (aux), to tell spent slots from newly prepared
-- spells that are not memorized yet.
table.insert(B24.SpellCastListeners, function(sprite, res)
	if B24WZ.Level(sprite) <= 0 or res:upper():sub(1, 4) ~= "SPWI" then return end
	local aux = B24.Aux(sprite)
	aux.B24_CastToday = aux.B24_CastToday or {}
	aux.B24_CastToday[res:upper()] = true
end)

-- Arcane Recovery (1): once per long rest, after a short rest, spent slots worth up to half the
-- Wizard level (rounded up) come back, none above 5th level, the highest first. Local B24ARUSE.
-- Memorize Spell (5): after a short rest, one newly prepared spell (memorized in the spellbook but
-- not yet ready, and not cast today) becomes ready, as if prepared at the rest.
B24.AddShortRestListener(function(sprite)
	local level = B24WZ.Level(sprite)
	if level <= 0 or B24SP == nil or B24SP.UnreadyEntries == nil then return end
	local castToday = B24.Aux(sprite).B24_CastToday or {}
	if level >= 5 then
		for spellLevel = 9, 1, -1 do
			local done = false
			for _, entry in ipairs(B24SP.UnreadyEntries(sprite, true, spellLevel)) do
				local res = entry.m_spellId:get():upper()
				if not castToday[res] then
					B24SP.Restore(entry)
					B24.Log(string.format("%s: Memorize Spell (%s)", B24.Name(sprite), res))
					done = true
					break
				end
			end
			if done then break end
		end
	end
	if sprite:getLocalInt("B24ARUSE") == 1 then return end
	local budget, restored = math.ceil(level / 2), {}
	for spellLevel = math.min(5, budget), 1, -1 do
		for _, entry in ipairs(B24SP.UnreadyEntries(sprite, true, spellLevel)) do
			local res = entry.m_spellId:get():upper()
			if budget >= spellLevel and castToday[res] then
				B24SP.Restore(entry)
				budget = budget - spellLevel
				table.insert(restored, spellLevel)
			end
		end
	end
	if #restored > 0 then
		sprite:setLocalInt("B24ARUSE", 1)
		B24.Log(string.format("%s: Arcane Recovery (spell slots of level %s)", B24.Name(sprite), table.concat(restored, ", ")))
	end
end)

B24.AddLongRestListener(function(sprite)
	sprite:setLocalInt("B24ARUSE", 0)
	B24.Aux(sprite).B24_CastToday = nil
end)

-----------------
-- Overchannel --
-----------------

-- Overchannel (Evoker 14): the Overchannel innate readies the next wizard spell of level 1-5 to
-- deal its maximum damage. The first use after a long rest is free; each later one costs the
-- wizard 2d12 necrotic damage per spell level, one d12 more per level for every further use
-- (it ignores resistance; in BG: magic damage). Local B24OVCH (uses since the long rest).
local function readyOverchannel(sprite)
	local over = B24.Aux(sprite).B24_Overchannel
	return over and B24.GameTick() <= (over.untilTick or over.readyUntil) and over or nil
end

function B24OVCHN(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24.Aux(sprite).B24_Overchannel = { readyUntil = B24.GameTick() + 90 }
		B24LV.Grant(sprite, "B24OVCHN", true)
		B24.Log(string.format("%s readies Overchannel", B24.Name(sprite)))
	end)
end

table.insert(B24.SpellCastListeners, function(sprite, res)
	local over = readyOverchannel(sprite)
	if over == nil or over.res then return end
	res = res:upper()
	local level = B24SP and B24SP.SpellLevel(res) or 0
	if res:sub(1, 4) ~= "SPWI" or level < 1 or level > 5 then return end
	over.res, over.untilTick = res, B24.GameTick() + 15 * 15
	local uses = sprite:getLocalInt("B24OVCH")
	sprite:setLocalInt("B24OVCH", uses + 1)
	if uses >= 1 then
		local dice = (uses + 1) * level
		local damage = 0
		for _ = 1, dice do damage = damage + B24.Roll(12) end
		B24.ApplyEffect(sprite, { ["effectID"] = 12, ["effectAmount"] = damage, ["dwFlags"] = 0x400000, ["durationType"] = 1 })
		B24.Log(string.format("%s: Overchannel costs %dd12 = %d damage", B24.Name(sprite), dice, damage))
	end
end)

B24LV.WhenSpells(function()
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		local over = readyOverchannel(caster)
		if over == nil or over.res ~= res or effect.m_numDice <= 0 then return end
		effect.m_effectAmount = effect.m_effectAmount + effect.m_numDice * effect.m_diceSize
		effect.m_numDice = 0
	end)
end)

B24.AddLongRestListener(function(sprite) sprite:setLocalInt("B24OVCH", 0) end)

B24LV.AddApplyListener(function(sprite)
	B24LV.Grant(sprite, "B24OVCHN", B24WZ.Level(sprite) >= 14 and isEvoker(sprite))
end)

----------------------------------------
-- Spell Mastery and Signature Spells --
----------------------------------------

-- Spell Mastery (18): a 1st- and a 2nd-level spell from the spellbook, cast at will (innate copies
-- B24IW..., granted again after each cast). Signature Spells (20): two 3rd-level spells from the
-- spellbook, each once per short rest without a slot. Only spells under their own SPWI resref
-- (not the ones the Spells component moved to another level) have copies.
local function spellbookChoices(spellLevel)
	return function()
		local list = {}
		for _, spell in ipairs(wizardSpells()) do
			if spell.level == spellLevel and spell.res:sub(1, 4) == "SPWI" and B24SP.SpellLevel(spell.res) == spellLevel
				and EEex_Resource_Demand(B24.InnateCopy(spell.res), "SPL") then
				table.insert(list, { key = spell.res, res = spell.res, level = spellLevel,
					name = string.format("%s (level %d)", spell.name, spellLevel) })
			end
		end
		return list
	end
end

local function inSpellbook(sprite, entry)
	return knownSpells(sprite)[entry.res] == true
end

B24LV.WhenSpells(function()
	B24LV.AddPick({ key = "MASTERY1", prefix = "B24WSM1", title = "Spell Mastery (level 1)",
		help = "Choose a 1st-level spell from your spellbook. You can cast it at will.",
		list = spellbookChoices(1), allowed = inSpellbook,
		count = function(sprite) return B24WZ.Level(sprite) >= 18 and 1 or 0 end })
	B24LV.AddPick({ key = "MASTERY2", prefix = "B24WSM2", title = "Spell Mastery (level 2)",
		help = "Choose a 2nd-level spell from your spellbook. You can cast it at will.",
		list = spellbookChoices(2), allowed = inSpellbook,
		count = function(sprite) return B24WZ.Level(sprite) >= 18 and 1 or 0 end })
	B24LV.AddPick({ key = "SIGNATURE", prefix = "B24WSIG", title = "Signature Spells",
		help = "Choose a 3rd-level spell from your spellbook. You can cast it once per short rest without a spell slot.",
		list = spellbookChoices(3), allowed = inSpellbook,
		count = function(sprite) return B24WZ.Level(sprite) >= 20 and 2 or 0 end })
end)

local function masterySpells(sprite)
	local list = {}
	for _, key in ipairs({ "MASTERY1", "MASTERY2" }) do
		for _, entry in ipairs(B24LV.Picked(sprite, key)) do table.insert(list, entry) end
	end
	return list
end

-- Signature Spells used since the last short rest: local B24WSGU (bit per pick).
local function grantSignature(sprite)
	for i, entry in ipairs(B24LV.Picked(sprite, "SIGNATURE")) do
		B24LV.Grant(sprite, B24.InnateCopy(entry.res), not EEex_IsBitSet(sprite:getLocalInt("B24WSGU"), i - 1))
	end
end

function B24WZ.RefreshMastery(sprite)
	if B24WZ.Level(sprite) < 18 then return end
	for _, entry in ipairs(masterySpells(sprite)) do B24LV.Grant(sprite, B24.InnateCopy(entry.res), true) end
	grantSignature(sprite)
end

table.insert(B24.SpellCastListeners, function(sprite, res)
	if B24WZ.Level(sprite) < 18 then return end
	res = res:upper()
	for _, entry in ipairs(masterySpells(sprite)) do
		if B24.InnateCopy(entry.res) == res then B24.Aux(sprite).B24_MasteryRefresh = B24.GameTick() + 90 end
	end
	for i, entry in ipairs(B24LV.Picked(sprite, "SIGNATURE")) do
		if B24.InnateCopy(entry.res) == res then
			sprite:setLocalInt("B24WSGU", EEex_BOr(sprite:getLocalInt("B24WSGU"), EEex_LShift(1, i - 1)))
		end
	end
end)

B24LV.AddTickListener(function(sprite)
	local aux = B24.Aux(sprite)
	if aux.B24_MasteryRefresh and B24.GameTick() >= aux.B24_MasteryRefresh then
		aux.B24_MasteryRefresh = nil
		for _, entry in ipairs(masterySpells(sprite)) do B24LV.Grant(sprite, B24.InnateCopy(entry.res), true) end
	end
end)

B24LV.AddApplyListener(function(sprite) B24WZ.RefreshMastery(sprite) end)
B24.AddShortRestListener(function(sprite)
	sprite:setLocalInt("B24WSGU", 0)
	B24WZ.RefreshMastery(sprite)
end)
B24.AddLongRestListener(function(sprite)
	sprite:setLocalInt("B24WSGU", 0)
	B24WZ.RefreshMastery(sprite)
end)
