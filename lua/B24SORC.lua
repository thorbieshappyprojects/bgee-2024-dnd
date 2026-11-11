-- BG 2024 Rules Mod: the 2024 Sorcerer with Draconic Sorcery (SRD subclass). Sorcerer spells use
-- the Spells component (2024 slots and spells known).
--
--   1  Spellcasting, Innate Sorcery (2 uses per long rest: +1 spell save DC and advantage on
--      spell attacks for a minute), cantrips (4; 5 at 4, 6 at 10)
--   2  Font of Magic (Sorcery Points = Sorcerer level; Create Spell Slot innates restore a spent
--      spell of level 1-5 for 2/3/5/6/7 points; turning slots into points has no BG form),
--      Metamagic (two options; four at 10, six at 17; see Metamagic below)
--   3  Subclass: Draconic: Draconic Resilience (+1 hit point per level; AC 10 + Dexterity +
--      Charisma without armor), dragon ancestry
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Sorcerous Restoration (once per long rest, a short rest returns half your level in points)
--   7  Sorcery Incarnate (Innate Sorcery for 2 Sorcery Points once its uses are gone; two Metamagic
--      options per spell while it is active)
--   6  Draconic: Elemental Affinity (Charisma modifier to spell damage of your ancestry's type,
--      resistance to it)
--   14 Draconic: Dragon Wings (no flying in BG: faster, and webs, entangling plants and grease
--      can't hold you, for an hour, once per long rest); 18 Dragon Companion (no BG form: there is no
--      Summon Dragon spell); 20 Arcane Apotheosis (while Innate Sorcery is active, one Metamagic
--      option per round costs nothing)
--
-- Locals: B24ISUSE (Innate Sorcery), B24DRAGN (dragon ancestry), B24SPUSE (Sorcery Points spent),
-- B24SRUS2 (Sorcerous Restoration used).

B24SO = {}

function B24SO.Level(sprite)
	return B24LV.ClassLevel(sprite, "SORCERER")
end

B24LV.AddSubclasses("SORCERER", 3, {
	{ key = "DRACONIC", name = "Draconic Sorcery",
	  desc = "Your magic comes from a dragon ancestor.\n\nLevel 3: Draconic Resilience (+1 hit point per Sorcerer level; AC 10 + Dexterity + Charisma without armor), choice of dragon ancestry.\nLevel 6: Elemental Affinity (Charisma modifier to spell damage of your ancestry's type, resistance to it).\nLevel 14: Dragon Wings (in BG: faster, and webs, entangling plants and grease can't hold you, for an hour, once per long rest).\nLevel 18: Dragon Companion has no BG form (BG has no Summon Dragon spell).\nDraconic spells follow with the spell updates.",
	  features = { [3] = "Draconic Resilience, dragon ancestry", [6] = "Elemental Affinity", [14] = "Dragon Wings", [18] = "Dragon Companion (no BG form)" } },
})

local function isDraconic(sprite)
	return B24LV.Subclass(sprite, "SORCERER") == "DRACONIC"
end

-- Ancestry: op12 damage type and resistance opcode.
B24SO.ANCESTRIES = {
	{ key = "ACID", name = "Acid (black or copper dragon)", desc = "Elemental Affinity with acid.", damage = 0x10000, resist = 27 },
	{ key = "COLD", name = "Cold (silver or white dragon)", desc = "Elemental Affinity with cold.", damage = 0x20000, resist = 28 },
	{ key = "FIRE", name = "Fire (brass, gold or red dragon)", desc = "Elemental Affinity with fire.", damage = 0x80000, resist = 30 },
	{ key = "LIGHTNING", name = "Lightning (blue or bronze dragon)", desc = "Elemental Affinity with lightning.", damage = 0x40000, resist = 29 },
	{ key = "POISON", name = "Poison (green dragon)", desc = "Elemental Affinity with poison.", damage = 0x200000, resist = 173 },
}
B24LV.AddOption({ key = "DRAGON_ANCESTRY", localName = "B24DRAGN", class = "SORCERER", level = 3, title = "Dragon Ancestry",
	subclass = "DRACONIC",
	list = B24SO.ANCESTRIES })

local function ancestry(sprite)
	local key = B24LV.Option(sprite, "DRAGON_ANCESTRY")
	for _, entry in ipairs(B24SO.ANCESTRIES) do
		if entry.key == key then return entry end
	end
end

B24LV.AddResource("INNATE_SORCERY", { spell = "B24INSOR", localName = "B24ISUSE",
	max = function(sprite) return B24SO.Level(sprite) >= 1 and 2 or 0 end })

B24SO.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24SO.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24SO.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, CANTRIP = 4 + (level >= 4 and 1 or 0) + (level >= 10 and 1 or 0) }
end)

B24SO.FEATURES = {
	[1] = "Spellcasting, Innate Sorcery, cantrips (4)",
	[2] = "Font of Magic (Sorcery Points, Create Spell Slot), Metamagic (two options)",
	[5] = "Sorcerous Restoration",
	[7] = "Sorcery Incarnate (Innate Sorcery for 2 Sorcery Points; two Metamagic options per spell while it lasts)",
	[20] = "Arcane Apotheosis (one free Metamagic option per round while Innate Sorcery lasts)",
	[3] = "Subclass",
	[4] = "Ability Score Improvement, cantrips (5)",
	[8] = "Ability Score Improvement",
	[10] = "cantrips (6), Metamagic (four options)",
	[12] = "Ability Score Improvement",
	[16] = "Ability Score Improvement",
	[17] = "Metamagic (six options)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24SO.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "SORCERER") + 1, level do
		if B24SO.FEATURES[l] then table.insert(lines, string.format("Sorcerer %d: %s", l, B24SO.FEATURES[l])) end
	end
	return lines
end)

B24LV.AddApplyListener(function(sprite)
	if B24SO.Level(sprite) < 6 or not isDraconic(sprite) then return end
	local entry = ancestry(sprite)
	if entry then B24LV.Permanent(sprite, { ["effectID"] = entry.resist, ["effectAmount"] = 50 }) end
end)

--------------------
-- Innate Sorcery --
--------------------

local function startInnateSorcery(sprite, how)
	B24.SetTimed(sprite, "INNATE_SORCERY", 60)
	B24.SetTimed(sprite, "SPELL_ADV", 60)
	-- Sorcery Incarnate and Arcane Apotheosis change which Metamagic innates are available.
	if B24LV.RESOURCES.SORCERY_POINTS then B24LV.RefreshPowers(sprite, "SORCERY_POINTS") end
	B24.Log(string.format("%s: Innate Sorcery%s", B24.Name(sprite), how or ""))
end

function B24INSOR(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "INNATE_SORCERY")
		startInnateSorcery(sprite)
	end)
end

-- Sorcery Incarnate (7): with no Innate Sorcery uses left, 2 Sorcery Points start it (innate
-- B24INSO2, a power of the Sorcery Points pool; see Font of Magic).
function B24INSO2(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24SO.SpendPoints(sprite, 2) then return end
		startInnateSorcery(sprite, " (Sorcery Incarnate, 2 Sorcery Points)")
	end)
end

-- Dragon Wings (Draconic 14), once per long rest: BG has no flying; for an hour you move faster
-- and webs, entangling plants and grease can't hold you.
B24LV.AddResource("DRAGON_WINGS", { spell = "B24DRWNG", localName = "B24DWUSE",
	max = function(sprite) return (B24SO.Level(sprite) >= 14 and isDraconic(sprite)) and 1 or 0 end })

function B24DRWNG(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "DRAGON_WINGS")
		local hour = { ["durationType"] = 0, ["duration"] = 3600, ["m_sourceRes"] = "B24DRWNG" }
		local function timed(args)
			for k, v in pairs(hour) do args[k] = v end
			B24.ApplyEffect(sprite, args)
		end
		timed({ ["effectID"] = 176, ["effectAmount"] = 150, ["dwFlags"] = 5 })
		for _, opcode in ipairs({ 154, 157, 158 }) do timed({ ["effectID"] = 101, ["dwFlags"] = opcode }) end
		B24.Log(string.format("%s: Dragon Wings", B24.Name(sprite)))
	end)
end

B24.AddSpellDCListener(function(sprite)
	return B24.HasTimed(sprite, "INNATE_SORCERY") and 1 or 0
end)

--------------------------
-- Draconic Resilience --
--------------------------

B24.AddStatListener(function(sprite)
	local level = B24SO.Level(sprite)
	if level < 3 or not isDraconic(sprite) then return end
	local stats = sprite:getActiveStats()
	stats.m_nMaxHitPoints = stats.m_nMaxHitPoints + level
	local armor = sprite.m_equipment.m_items:get(1)
	if armor == nil or armor.pRes.pHeader.itemType ~= 2 then
		-- AC 10 + Dexterity + Charisma: the engine already counts Dexterity.
		stats.m_nArmorClass = stats.m_nArmorClass - B24.AbilityMod(stats.m_nCHR)
	end
end)

------------------------
-- Elemental Affinity --
------------------------

B24LV.WhenSpells(function()
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if B24SO.Level(caster) < 6 or not isDraconic(caster) then return end
		local entry = ancestry(caster)
		if entry and EEex_BAnd(effect.m_dWFlags, entry.damage) ~= 0 then
			effect.m_effectAmount = effect.m_effectAmount + math.max(0, B24.AbilityModOf(caster, "CHA"))
		end
	end)
end)

-------------------
-- Font of Magic --
-------------------

-- Create Spell Slot: one innate per slot level 1-5, granted while the points and the slot level
-- allow; op261 restores one spent (cast) spell of that level.
B24SO.SLOT_COSTS = { 2, 3, 5, 6, 7 }

local function slotPowers()
	local powers = {}
	for spellLevel, cost in ipairs(B24SO.SLOT_COSTS) do
		table.insert(powers, { res = "B24FOM" .. spellLevel, cost = cost,
			when = function(sprite) return math.floor((B24SO.Level(sprite) + 1) / 2) >= spellLevel end })
	end
	return powers
end

B24LV.AddResource("SORCERY_POINTS", { localName = "B24SPUSE", powers = slotPowers(),
	max = function(sprite)
		local level = B24SO.Level(sprite)
		return level >= 2 and level or 0
	end })

function B24SO.SpendPoints(sprite, points)
	return B24LV.Spend(sprite, "SORCERY_POINTS", points)
end

-- Sorcery Incarnate (7): Innate Sorcery for 2 points once its uses are gone.
table.insert(B24LV.RESOURCES.SORCERY_POINTS.powers, { res = "B24INSO2", cost = 2,
	when = function(sprite) return B24SO.Level(sprite) >= 7 and B24LV.Remaining(sprite, "INNATE_SORCERY") == 0 end })

for spellLevel, cost in ipairs(B24SO.SLOT_COSTS) do
	_G["B24FOM" .. spellLevel] = function(op402, sprite)
		EEex_Utility_TryIgnore(function()
			if not B24SO.SpendPoints(sprite, cost) then return end
			B24.ApplyEffect(sprite, { ["effectID"] = 261, ["effectAmount"] = spellLevel, ["dwFlags"] = 0 })
			B24.Log(string.format("%s: Create Spell Slot (level %d, %d Sorcery Points left)", B24.Name(sprite), spellLevel,
				B24LV.Remaining(sprite, "SORCERY_POINTS")))
		end)
	end
end

-- Sorcerous Restoration (5): once per long rest, a short rest returns half the level in points.
B24.AddShortRestListener(function(sprite)
	local level = B24SO.Level(sprite)
	if level < 5 or sprite:getLocalInt("B24SRUS2") == 1 then return end
	sprite:setLocalInt("B24SRUS2", 1)
	sprite:setLocalInt("B24SPUSE", math.max(0, sprite:getLocalInt("B24SPUSE") - math.floor(level / 2)))
	B24LV.RefreshPowers(sprite, "SORCERY_POINTS")
end)

B24.AddLongRestListener(function(sprite) sprite:setLocalInt("B24SRUS2", 0) end)

---------------
-- Metamagic --
---------------

-- Metamagic (2): options learned at 2 (two), 10 (four) and 17 (six). Each is an innate that
-- spends Sorcery Points and readies the option for the next spell cast within a round; one option
-- per spell. Distant, Subtle and Twinned Spell have no BG form (ranges, components and target
-- counts are fixed per spell). Heightened Spell gives every target of the spell disadvantage (2024:
-- one target); Transmuted Spell picks the elemental damage type the target resists least.
B24SO.METAMAGIC = {
	{ key = "CAREFUL", res = "B24MMCAR", name = "Careful Spell", cost = 1,
	  desc = "1 Sorcery Point: your allies automatically succeed on their saves against your next spell and take no damage from it if they would take half." },
	{ key = "EMPOWERED", res = "B24MMEMP", name = "Empowered Spell", cost = 1,
	  desc = "1 Sorcery Point: when your next spell deals damage, up to your Charisma modifier of its low damage dice are rolled again." },
	{ key = "EXTENDED", res = "B24MMEXT", name = "Extended Spell", cost = 1,
	  desc = "1 Sorcery Point: your next spell lasts twice as long, and you have advantage on saves to keep concentrating on it." },
	{ key = "HEIGHTENED", res = "B24MMHEI", name = "Heightened Spell", cost = 2,
	  desc = "2 Sorcery Points: creatures make their saves against your next spell with disadvantage (in BG: every target)." },
	{ key = "QUICKENED", res = "B24MMQUI", name = "Quickened Spell", cost = 2,
	  desc = "2 Sorcery Points: you cast your next spell much faster (2024: as a bonus action)." },
	{ key = "SEEKING", res = "B24MMSEE", name = "Seeking Spell", cost = 1,
	  desc = "1 Sorcery Point: if your next spell's attack roll misses, roll it again." },
	{ key = "TRANSMUTED", res = "B24MMTRA", name = "Transmuted Spell", cost = 1,
	  desc = "1 Sorcery Point: acid, cold, fire, lightning or poison damage of your next spell turns into the type the target resists least." },
}

B24LV.AddPick({ key = "METAMAGIC", prefix = "B24MM", title = "Metamagic",
	help = "Choose a Metamagic option. Each is an innate ability that spends Sorcery Points and changes your next spell.",
	list = function() return B24SO.METAMAGIC end,
	count = function(sprite)
		local level = B24SO.Level(sprite)
		return level >= 17 and 6 or level >= 10 and 4 or level >= 2 and 2 or 0
	end })

-- The options are powers of the Sorcery Points pool.
for _, option in ipairs(B24SO.METAMAGIC) do
	table.insert(B24LV.RESOURCES.SORCERY_POINTS.powers, { res = option.res, cost = option.cost,
		when = function(sprite) return B24SO.Level(sprite) >= 2 and B24LV.HasPicked(sprite, "METAMAGIC", option.key) end })
end

local META_RES = {}
for _, option in ipairs(B24SO.METAMAGIC) do META_RES[option.res] = true end

-- Options per spell: one; two while Innate Sorcery is active from level 7 (Sorcery Incarnate).
local function optionsPerSpell(sprite)
	return (B24SO.Level(sprite) >= 7 and B24.HasTimed(sprite, "INNATE_SORCERY")) and 2 or 1
end

-- Arcane Apotheosis (20): while Innate Sorcery is active, one option per round costs nothing.
local function apotheosis(sprite)
	return B24SO.Level(sprite) >= 20 and B24.HasTimed(sprite, "INNATE_SORCERY")
end

-- Readied options (aux B24_Meta: a list of { key, readyUntil, res, untilTick }).
for _, option in ipairs(B24SO.METAMAGIC) do
	_G[option.res] = function(op402, sprite)
		EEex_Utility_TryIgnore(function()
			local free = apotheosis(sprite) and B24LV.OncePerRound(sprite, "APOTHEOSIS")
			if not free and not B24SO.SpendPoints(sprite, option.cost) then return end
			B24LV.RefreshPowers(sprite, "SORCERY_POINTS")
			local aux = B24.Aux(sprite)
			local now = B24.GameTick()
			local ready = {}
			for _, entry in ipairs(aux.B24_Meta or {}) do
				if entry.res == nil and now <= entry.readyUntil and entry.key ~= option.key then table.insert(ready, entry) end
			end
			while #ready >= optionsPerSpell(sprite) do table.remove(ready, 1) end
			table.insert(ready, { key = option.key, readyUntil = now + 90 })
			aux.B24_Meta = ready
			if option.key == "QUICKENED" then
				-- op189: casting time reduced for the round.
				B24.ApplyEffect(sprite, { ["effectID"] = 189, ["effectAmount"] = 10, ["durationType"] = 0, ["duration"] = 6 })
			end
			B24.Log(string.format("%s readies %s (%s)", B24.Name(sprite), option.name,
				free and "Arcane Apotheosis" or (B24LV.Remaining(sprite, "SORCERY_POINTS") .. " Sorcery Points left")))
		end)
	end
end

-- The readied options bind to the next spell the sorcerer starts casting (the Font of Magic and
-- Metamagic innates themselves don't count).
table.insert(B24.SpellCastListeners, function(sprite, res)
	local aux = B24.Aux(sprite)
	res = res:upper()
	if aux.B24_Meta == nil or META_RES[res] or res:sub(1, 6) == "B24FOM" or res:sub(1, 7) == "B24INSO" then return end
	local now, bound = B24.GameTick(), {}
	for _, entry in ipairs(aux.B24_Meta) do
		if entry.res == nil and now <= entry.readyUntil then
			entry.res, entry.untilTick = res, now + 15 * 15
			if entry.key == "EXTENDED" then aux.B24_ExtendedConc = res end
			table.insert(bound, entry)
		end
	end
	aux.B24_Meta = #bound > 0 and bound or nil
end)

local function metaFor(caster, res, key)
	if not B24.IsSprite(caster) or res == nil then return false end
	res = res:upper()
	for _, entry in ipairs(B24.Aux(caster).B24_Meta or {}) do
		if entry.key == key and entry.res == res and B24.GameTick() <= (entry.untilTick or 0) then return true end
	end
	return false
end
B24SO.MetaFor = metaFor

-- Arcane Apotheosis: the options stay available while their cost is free this round.
for _, power in ipairs(B24LV.RESOURCES.SORCERY_POINTS.powers) do
	if META_RES[power.res] then
		power.free = function(sprite) return apotheosis(sprite) end
	end
end

local function goodSide(sprite)
	local ok, ea = pcall(function() return sprite.m_typeAI.m_EnemyAlly end)
	if ok and ea then return ea <= 30 end
	return B24.InParty(sprite)
end

local function allies(a, b) return goodSide(a) == goodSide(b) end

-- Careful Spell: allies succeed and are not affected.
B24.AddSaveAutoSuccessListener(function(effect, sprite)
	local caster = B24.GetSprite(effect.m_sourceId)
	return caster ~= nil and caster.m_id ~= sprite.m_id and allies(caster, sprite)
		and metaFor(caster, effect.m_sourceRes:get(), "CAREFUL")
end)

-- Heightened Spell: other creatures save with disadvantage. Extended Spell: advantage on
-- concentration saves for the extended spell.
B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	if conditions.CONCENTRATION then
		local record = B24.Conc_Get(sprite)
		local extended = B24.Aux(sprite).B24_ExtendedConc
		return record ~= nil and extended ~= nil and record.res == extended, false
	end
	local caster = conditions.SOURCE and B24.GetSprite(conditions.SOURCE)
	if caster and not allies(caster, sprite) and metaFor(caster, conditions.RES, "HEIGHTENED") then
		return false, true
	end
	return false, false
end)

-- Extended Spell: effects of the spell last twice as long.
table.insert(B24.EffectAddedListeners, function(effect, sprite)
	if effect.m_durationType ~= 0 or effect.m_duration <= 0 then return end
	local caster = B24.GetSprite(effect.m_sourceId)
	if metaFor(caster, effect.m_sourceRes:get(), "EXTENDED") then
		effect.m_duration = effect.m_duration * 2
	end
end)

B24SO.TRANSMUTE_TYPES = {
	{ flag = 0x10000, stat = "m_nResistAcid" }, { flag = 0x20000, stat = "m_nResistCold" },
	{ flag = 0x80000, stat = "m_nResistFire" }, { flag = 0x40000, stat = "m_nResistElectricity" },
	{ flag = 0x200000, stat = "m_nResistPoison" },
}

B24LV.WhenSpells(function()
	-- Empowered Spell: up to Charisma modifier dice below average are rolled again.
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if effect.m_numDice <= 0 or not metaFor(caster, res, "EMPOWERED") then return end
		local rerolls = math.max(1, B24.AbilityModOf(caster, "CHA"))
		local size, total = effect.m_diceSize, 0
		for _ = 1, effect.m_numDice do
			local roll = B24.Roll(size)
			if rerolls > 0 and roll * 2 < size + 1 then
				rerolls = rerolls - 1
				roll = B24.Roll(size)
			end
			total = total + roll
		end
		effect.m_numDice = 0
		effect.m_effectAmount = effect.m_effectAmount + total
	end)
	-- Transmuted Spell: the elemental type the target resists least.
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if not metaFor(caster, res, "TRANSMUTED") then return end
		local current = EEex_BAnd(effect.m_dWFlags, 0xFFFF0000)
		local elemental = false
		for _, entry in ipairs(B24SO.TRANSMUTE_TYPES) do
			if entry.flag == current then elemental = true end
		end
		if not elemental then return end
		local stats, best = target:getActiveStats(), nil
		for _, entry in ipairs(B24SO.TRANSMUTE_TYPES) do
			if best == nil or stats[entry.stat] < stats[best.stat] then best = entry end
		end
		effect.m_dWFlags = EEex_BOr(EEex_BAnd(effect.m_dWFlags, 0xFFFF), best.flag)
	end)
	-- Seeking Spell: a missed spell attack is rolled again.
	table.insert(B24SP.AttackRerollListeners, function(caster, target, res)
		return metaFor(caster, res, "SEEKING")
	end)
end)
