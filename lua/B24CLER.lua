-- BG 2024 Rules Mod: the 2024 Cleric with the Life Domain (SRD subclass). Cleric spells use the
-- Spells component (2024 slots and spell list).
--
--   1  Spellcasting, Divine Order (Protector: martial weapons, heavy armor; Thaumaturge: one more
--      cantrip, Wisdom to Arcana and Religion), cantrips (3; 4 at 4, 5 at 10)
--   2  Channel Divinity (2 uses; 3 at 6, 4 at 18): Divine Spark, Turn Undead
--   3  Subclass: Life: Disciple of Life, Preserve Life (Channel Divinity)
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Sear Undead
--   6  Life: Blessed Healer
--   7  Blessed Strikes (Divine Strike: +1d8 radiant once per round with weapons; or Potent
--      Spellcasting: Wisdom modifier to cantrip damage); 14 Improved Blessed Strikes (2d8)
--   10 Divine Intervention, 20 Greater Divine Intervention (see below)
--   17 Life: Supreme Healing
--
-- Locals: B24CCUSE (Channel Divinity spent), B24ORDER (Divine Order), B24BLSTR (Blessed Strikes).

B24CL = {}

function B24CL.Level(sprite)
	return B24LV.ClassLevel(sprite, "CLERIC")
end

B24LV.AddSubclasses("CLERIC", 3, {
	{ key = "LIFE", name = "Life Domain",
	  desc = "Clerics of Life channel positive energy to heal.\n\nLevel 3: Disciple of Life (your healing spells heal 2 + spell level extra), Preserve Life (Channel Divinity: heal allies near you).\nLevel 6: Blessed Healer (healing others also heals you).\nLevel 17: Supreme Healing (healing dice roll their maximum).\nDomain spells follow with the spell updates.",
	  features = { [3] = "Disciple of Life, Preserve Life", [6] = "Blessed Healer", [17] = "Supreme Healing" } },
})

local function isLife(sprite)
	return B24LV.Subclass(sprite, "CLERIC") == "LIFE"
end

B24LV.AddOption({ key = "DIVINE_ORDER", localName = "B24ORDER", class = "CLERIC", level = 1, title = "Divine Order",
	list = {
		{ key = "PROTECTOR", name = "Protector", desc = "Trained for battle: proficiency with martial weapons and training with heavy armor." },
		{ key = "THAUMATURGE", name = "Thaumaturge", desc = "One extra cantrip, and your Wisdom modifier (at least +1) adds to Arcana and Religion." },
	} })

B24LV.AddOption({ key = "BLESSED_STRIKES", localName = "B24BLSTR", class = "CLERIC", level = 7, title = "Blessed Strikes",
	list = {
		{ key = "DIVINE_STRIKE", name = "Divine Strike", desc = "Once per round, a weapon hit deals 1d8 extra radiant damage (2d8 from level 14)." },
		{ key = "POTENT_SPELLCASTING", name = "Potent Spellcasting", desc = "Your cleric cantrips add your Wisdom modifier to their damage." },
	} })

local function wis(sprite) return B24.AbilityModOf(sprite, "WIS") end

B24LV.AddResource("CLERIC_CHANNEL", { localName = "B24CCUSE", shortRest = "one",
	max = function(sprite)
		local level = B24CL.Level(sprite)
		return level >= 18 and 4 or level >= 6 and 3 or level >= 2 and 2 or 0
	end })

-- Channel Divinity options of the subclasses: { res, when = function(sprite) }.
B24CL.CHANNEL_POWERS = {}

local function refreshChannel(sprite)
	local level = B24CL.Level(sprite)
	local left = B24LV.Remaining(sprite, "CLERIC_CHANNEL") > 0
	local entries = { { "B24DSPRK", level >= 2 }, { "B24TURNU", level >= 2 }, { "B24PRSLF", level >= 3 and isLife(sprite) } }
	for _, power in ipairs(B24CL.CHANNEL_POWERS) do table.insert(entries, { power.res, power.when(sprite) }) end
	for _, entry in ipairs(entries) do
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = entry[1] })
		if entry[2] and left then B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = entry[1] }) end
	end
end

local function useChannel(sprite)
	if not B24LV.Use(sprite, "CLERIC_CHANNEL") then return false end
	refreshChannel(sprite)
	return true
end
B24CL.UseChannel = useChannel
B24CL.RefreshChannel = refreshChannel

B24.AddShortRestListener(function(sprite) if B24CL.Level(sprite) > 0 then refreshChannel(sprite) end end)
B24.AddLongRestListener(function(sprite) if B24CL.Level(sprite) > 0 then refreshChannel(sprite) end end)

B24CL.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24CL.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24CL.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	local cantrips = 3 + (level >= 4 and 1 or 0) + (level >= 10 and 1 or 0)
		+ (B24LV.Option(sprite, "DIVINE_ORDER") == "THAUMATURGE" and 1 or 0)
	return { ASI = asi, CANTRIP = cantrips }
end)

B24CL.FEATURES = {
	[1] = "Spellcasting, Divine Order, cantrips (3)",
	[2] = "Channel Divinity (2 uses: Divine Spark, Turn Undead)",
	[3] = "Subclass",
	[4] = "Ability Score Improvement, cantrips (4)",
	[5] = "Sear Undead",
	[6] = "Channel Divinity (3 uses)",
	[7] = "Blessed Strikes",
	[8] = "Ability Score Improvement",
	[10] = "Divine Intervention (a Cleric spell of level 1-5 once per long rest), cantrips (5)",
	[12] = "Ability Score Improvement",
	[14] = "Improved Blessed Strikes",
	[16] = "Ability Score Improvement",
	[18] = "Channel Divinity (4 uses)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Greater Divine Intervention (Wish, where the game has it)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24CL.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "CLERIC") + 1, level do
		if B24CL.FEATURES[l] then table.insert(lines, string.format("Cleric %d: %s", l, B24CL.FEATURES[l])) end
	end
	return lines
end)

B24LV.AddApplyListener(function(sprite)
	if B24CL.Level(sprite) > 0 then refreshChannel(sprite) end
end)

------------------
-- Divine Order --
------------------

B24.AddWeaponProficiencyListener(function(sprite)
	return B24CL.Level(sprite) > 0 and B24LV.Option(sprite, "DIVINE_ORDER") == "PROTECTOR"
end)

B24.AddSkillBonusListener(function(sprite, key)
	if (key == "ARCANA" or key == "RELIGION") and B24CL.Level(sprite) > 0
		and B24LV.Option(sprite, "DIVINE_ORDER") == "THAUMATURGE" then
		return math.max(1, wis(sprite))
	end
	return 0
end)

----------------------
-- Channel Divinity --
----------------------

local function isUndead(sprite)
	return sprite.m_typeAI.m_General == 4
end

-- Divine Spark (cast on a creature): an ally regains 1d8 + Wisdom modifier hit points; an enemy
-- makes a Constitution save or takes that much radiant damage (half on a success). 2d8 at 7,
-- 3d8 at 13, 4d8 at 18.
function B24DSPRK(op402, target)
	EEex_Utility_TryIgnore(function()
		local cleric = B24.GetSprite(op402.m_sourceId)
		if cleric == nil or not useChannel(cleric) then return end
		local level = B24CL.Level(cleric)
		local dice = level >= 18 and 4 or level >= 13 and 3 or level >= 7 and 2 or 1
		local amount = wis(cleric)
		for i = 1, dice do amount = amount + B24.Roll(8) end
		if B24.InParty(target) then
			B24.Heal(target, math.max(1, amount))
			B24.Log(string.format("%s: Divine Spark heals %s for %d", B24.Name(cleric), B24.Name(target), amount))
		else
			local dc = 8 + B24.ProfOf(cleric) + wis(cleric)
			if B24.RollSave(target, "CON", dc, nil, " (Divine Spark)") then amount = math.floor(amount / 2) end
			B24.ApplyEffect(target, { ["effectID"] = 12, ["effectAmount"] = math.max(0, amount), ["dwFlags"] = 0x400000,
				["sourceID"] = cleric.m_id })
		end
	end)
end

-- Turn Undead: undead nearby make a Wisdom save or are turned (frightened) for a minute; Sear
-- Undead (5) adds Wisdom modifier d8 radiant damage to those that fail.
function B24TURNU(op402, cleric)
	EEex_Utility_TryIgnore(function()
		if not useChannel(cleric) then return end
		local dc = 8 + B24.ProfOf(cleric) + wis(cleric)
		for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(cleric, "[ENEMY]", B24.Feet(30), true) or {}) do
			if isUndead(enemy) and not B24.RollSave(enemy, "WIS", dc, nil, " (Turn Undead)", { FEAR = true }) then
				B24.ApplyEffect(enemy, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 60, ["sourceID"] = cleric.m_id })
				if B24CL.Level(cleric) >= 5 then
					local damage = 0
					for i = 1, math.max(1, wis(cleric)) do damage = damage + B24.Roll(8) end
					B24.ApplyEffect(enemy, { ["effectID"] = 12, ["effectAmount"] = damage, ["dwFlags"] = 0x400000,
						["sourceID"] = cleric.m_id })
				end
			end
		end
	end)
end

-- Preserve Life (Life): party members near the cleric regain up to 5 x Cleric level hit points in
-- total, none above half its maximum.
function B24PRSLF(op402, cleric)
	EEex_Utility_TryIgnore(function()
		if not useChannel(cleric) then return end
		local pool = 5 * B24CL.Level(cleric)
		local allies = EEex_Sprite_GetAllOfTypeStringInRange(cleric, "[PC]", B24.Feet(30), true) or {}
		table.insert(allies, cleric)
		for _, ally in ipairs(allies) do
			local half = math.floor(ally:getStat(B24.Stat.MAXHP) / 2)
			local missing = half - ally.m_baseStats.m_hitPoints
			local amount = math.min(pool, math.max(0, missing))
			if amount > 0 then
				B24.Heal(ally, amount)
				pool = pool - amount
			end
		end
		B24.Log(string.format("%s: Preserve Life", B24.Name(cleric)))
	end)
end

---------------------
-- Blessed Strikes --
---------------------

table.insert(B24WPN.DamageListeners, function(context)
	local cleric = context.attacker
	local level = B24CL.Level(cleric)
	if level < 7 or B24LV.Option(cleric, "BLESSED_STRIKES") ~= "DIVINE_STRIKE" then return end
	local aux = B24.Aux(cleric)
	local now = B24.GameTick()
	if aux.B24_DivineStrike and now - aux.B24_DivineStrike < 90 then return end
	aux.B24_DivineStrike = now
	local extra = B24.Roll(8) + (level >= 14 and B24.Roll(8) or 0)
	context.effect.m_effectAmount = context.effect.m_effectAmount + extra
	B24.Log(string.format("%s: Divine Strike %d", B24.Name(cleric), extra))
end)

------------------------------------------
-- Spell features (Spells component) --
------------------------------------------

B24LV.WhenSpells(function()
	-- Disciple of Life: healing spells of level 1+ heal 2 + spell level more; Blessed Healer (6):
	-- healing someone else also heals the cleric 2 + spell level.
	table.insert(B24SP.HealBonusListeners, function(caster, target, spellLevel)
		if B24CL.Level(caster) < 3 or not isLife(caster) or spellLevel < 1 then return 0 end
		if B24CL.Level(caster) >= 6 and caster.m_id ~= target.m_id then
			B24.Heal(caster, 2 + spellLevel)
		end
		return 2 + spellLevel
	end)

	-- Supreme Healing (17).
	table.insert(B24SP.MaxHealListeners, function(caster)
		return B24CL.Level(caster) >= 17 and isLife(caster)
	end)

	-- Potent Spellcasting: Wisdom modifier to cleric cantrip damage.
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if not B24SP.IsCantrip(res) or B24CL.Level(caster) < 7 then return end
		if B24LV.Option(caster, "BLESSED_STRIKES") ~= "POTENT_SPELLCASTING" then return end
		effect.m_effectAmount = effect.m_effectAmount + math.max(0, wis(caster))
	end)
end)

-------------------------
-- Divine Intervention --
-------------------------

-- Divine Intervention (10), once per long rest: the Divine Intervention innate opens a choice of
-- the Cleric spells of level 5 or lower; the chosen spell is granted as an innate for one cast
-- (an innate copy, no slot) and taken away again once cast or at the next long rest. Greater Divine Intervention
-- (20): Wish too, where the game has it (BG2); after a Wish, Divine Intervention returns only
-- after 2d4 long rests. Locals: B24DIUSE (used), B24DIWSH (long rests until it returns after a Wish),
-- B24DIGRT (the granted spell).
B24CL.WISH = "SPWI914"

B24LV.AddResource("DIVINE_INTERVENTION", { spell = "B24CDIVI", localName = "B24DIUSE",
	max = function(sprite)
		if B24CL.Level(sprite) < 10 or sprite:getLocalInt("B24DIWSH") > 0 then return 0 end
		return 1
	end })

local clericSpells
local function spellName(res)
	local header = EEex_Resource_Demand(res, "SPL")
	local ref = header and EEex_Read32(EEex_UDToPtr(header) + 0x8) or -1
	return ref > 0 and Infinity_FetchString(ref) or res
end

local function spellDescription(res)
	local header = EEex_Resource_Demand(res, "SPL")
	local ref = header and EEex_Read32(EEex_UDToPtr(header) + 0x50) or -1
	return ref > 0 and Infinity_FetchString(ref) or ""
end

-- Cleric spells of level 1-5 of the catalog, by level and name.
function B24CL.InterventionSpells()
	if clericSpells then return clericSpells end
	clericSpells = {}
	local ok, catalog = pcall(B24.LoadTable, "B24SPELL")
	if not ok or catalog == nil then return clericSpells end
	for res, row in pairs(catalog) do
		local level = tonumber(row.LEVEL)
		if res:sub(1, 4) == "SPPR" and row.ACTION ~= "DROP" and (row.LISTS or ""):find("C", 1, true)
			and level and level >= 1 and level <= 5 and EEex_Resource_Demand(res, "SPL") then
			table.insert(clericSpells, { res = res, level = level })
		end
	end
	table.sort(clericSpells, function(a, b)
		if a.level ~= b.level then return a.level < b.level end
		return a.res < b.res
	end)
	for _, entry in ipairs(clericSpells) do
		entry.name = string.format("%s (level %d)", spellName(entry.res), entry.level)
		entry.desc = spellDescription(entry.res)
	end
	return clericSpells
end

-- The granted spell is kept in the local B24DIGRT (its index in the list, 999 for Wish), so it
-- survives saving and loading.
local function grantedRes(sprite)
	local index = sprite:getLocalInt("B24DIGRT")
	if index == 999 then return B24CL.WISH end
	local entry = B24CL.InterventionSpells()[index]
	return entry and entry.res
end

local function grant(sprite, choice)
	local index = 999
	for i, entry in ipairs(B24CL.InterventionSpells()) do
		if entry.res == choice.res then index = i end
	end
	sprite:setLocalInt("B24DIGRT", index)
	B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = B24.InnateCopy(choice.res) })
end

local function takeBack(sprite)
	local res = grantedRes(sprite)
	if res then B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = B24.InnateCopy(res) }) end
	sprite:setLocalInt("B24DIGRT", 0)
	B24.Aux(sprite).B24_DIRemoveAt = nil
end

function B24CDIVI(op402, sprite)
	EEex_Utility_TryIgnore(function()
		-- The innate stays until a spell is chosen (Cancel keeps Divine Intervention).
		B24LV.Rebuild(sprite, "DIVINE_INTERVENTION")
		local list = {}
		for _, entry in ipairs(B24CL.InterventionSpells()) do table.insert(list, entry) end
		if B24CL.Level(sprite) >= 20 and EEex_Resource_Demand(B24CL.WISH, "SPL") then
			table.insert(list, { res = B24CL.WISH, level = 9, wish = true, name = spellName(B24CL.WISH) .. " (Greater Divine Intervention)",
				desc = "Greater Divine Intervention: cast Wish. Afterwards Divine Intervention returns only after 2d4 long rests.\n\n" .. spellDescription(B24CL.WISH) })
		end
		B24LV.OpenChoice(sprite, { title = "Divine Intervention", list = list,
			help = "Choose a Cleric spell of level 5 or lower. You can cast it once, without a spell slot.",
			onChoose = function(cleric, choice)
				B24LV.Use(cleric, "DIVINE_INTERVENTION")
				if choice.wish then cleric:setLocalInt("B24DIWSH", B24.Roll(4) + B24.Roll(4)) end
				grant(cleric, choice)
				B24.Log(string.format("%s: Divine Intervention grants %s", B24.Name(cleric), choice.name))
			end })
	end)
end

-- The granted spell goes once it has been cast.
table.insert(B24.SpellCastListeners, function(sprite, res)
	if sprite:getLocalInt("B24DIGRT") ~= 0 and grantedRes(sprite) == B24.OriginalSpellRes(res):upper() then
		B24.Aux(sprite).B24_DIRemoveAt = B24.GameTick() + 90
	end
end)

B24LV.AddTickListener(function(sprite)
	local aux = B24.Aux(sprite)
	if aux.B24_DIRemoveAt and B24.GameTick() >= aux.B24_DIRemoveAt then takeBack(sprite) end
end)

B24.AddLongRestListener(function(sprite)
	if sprite:getLocalInt("B24DIGRT") ~= 0 then takeBack(sprite) end
	local wait = sprite:getLocalInt("B24DIWSH")
	if wait > 0 then sprite:setLocalInt("B24DIWSH", wait - 1) end
	if B24CL.Level(sprite) >= 10 then B24LV.Rebuild(sprite, "DIVINE_INTERVENTION") end
end)
