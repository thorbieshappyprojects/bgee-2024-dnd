-- BG 2024 Rules Mod: spell runtime (Spells component).
--
-- Healing: catalog healing spells call B24HEAL (op402: parameter 1 dice, parameter 2 die size,
-- special = flat amount); the casting ability modifier is added for dice-based healing, and
-- class features add theirs through B24SP.HealBonusListeners (Life Domain).
--
-- Cantrips: innate abilities usable at will (B24C* spells call B24CANT with the cantrip's index);
-- damage grows at character levels 5, 11 and 17. Spell attacks roll d20 + Proficiency Bonus +
-- casting ability modifier against the 2024 Armor Class; saves use the caster's spell save DC.
-- Chosen cantrips are stored in the local B24CANT (mask over B24SP.CANTRIPS).
--
-- New 2024 spells without a BG counterpart call B24NSPL with their index in B24SP.SPELLS.
--
-- Arcane upcast versions (B24UPCST.2DA) are learned automatically when the base spell is known;
-- the bard-only arcane copies of healing spells are kept only by bards.

B24SP = {}

local function signed(n) return n >= 0 and ("+" .. n) or tostring(n) end

local function castingMod(caster, res)
	return B24.AbilityModOf(caster, B24.CastingAbility(caster, res or ""))
end

local function rollDice(n, size)
	local total = 0
	for i = 1, n do total = total + B24.Roll(size) end
	return total
end

-- Spell level from the SPL header (offset 0x34).
local levelCache = {}
function B24SP.SpellLevel(res)
	res = res:upper()
	if levelCache[res] == nil then
		local header = EEex_Resource_Demand(res, "SPL")
		levelCache[res] = header and EEex_Read32(EEex_UDToPtr(header) + 0x34) or 1
	end
	return levelCache[res]
end

-------------
-- Healing --
-------------

-- listener(caster, target, spellLevel) returns extra hit points (e.g. Disciple of Life).
B24SP.HealBonusListeners = {}
-- listener(caster) returns true if the caster's healing dice count as their maximum (Supreme
-- Healing).
B24SP.MaxHealListeners = {}

function B24HEAL(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId) or target
		local res = op402.m_sourceRes:get()
		local dice, size, flat = op402.m_effectAmount, op402.m_dWFlags, op402.m_special
		local maximum = false
		for _, listener in ipairs(B24SP.MaxHealListeners) do
			local ok, result = pcall(listener, caster)
			maximum = maximum or (ok and result == true)
		end
		-- Healer feat (B24FEAT.lua): healing dice that roll 1 are rolled again.
		local rerolls = B24FEAT ~= nil and B24FEAT.Has(caster, "HEALER")
		local rolled = 0
		for i = 1, dice do
			local roll = B24.Roll(size)
			if roll == 1 and rerolls then roll = B24.Roll(size) end
			rolled = rolled + roll
		end
		local healed = flat + (maximum and dice * size or rolled)
		if dice > 0 then healed = healed + castingMod(caster, res) end
		local level = B24SP.SpellLevel(res)
		for _, listener in ipairs(B24SP.HealBonusListeners) do
			local ok, extra = pcall(listener, caster, target, level)
			if ok and extra then healed = healed + extra end
		end
		healed = math.max(1, healed)
		B24.Heal(target, healed)
		B24.Log(string.format("%s heals %s for %d", B24.Name(caster), B24.Name(target), healed))
	end)
end

-----------------------------
-- Attack rolls and damage --
-----------------------------

function B24SP.CantripDice(caster)
	local level = B24.Level(caster)
	return 1 + (level >= 5 and 1 or 0) + (level >= 11 and 1 or 0) + (level >= 17 and 1 or 0)
end

-- listener(caster, target, res) returns true to reroll a missed spell attack once (the Sorcerer's
-- Seeking Spell).
B24SP.AttackRerollListeners = {}

local function rerollMiss(caster, target, res)
	for _, listener in ipairs(B24SP.AttackRerollListeners) do
		local ok, result = pcall(listener, caster, target, res)
		if ok and result then return true end
	end
	return false
end

-- A ranged spell attack: the spell reaches farther than touch (range over 1 ft; Chill Touch and
-- Shocking Grasp are melee spell attacks). Without the spell's data: the target isn't adjacent.
local function rangedSpell(caster, target, res)
	local ok, range = pcall(function() return EEex_Resource_Demand(res, "SPL"):getAbility(0).range end)
	if ok and type(range) == "number" then return range > 1 end
	return not B24.Adjacent(caster, target)
end

-- Returns hit, critical.
function B24SP.SpellAttack(caster, target, res, label)
	local advantage = B24.AttackerHasAdvantage(caster) or B24.TargetGrantsAdvantage(target)
		or B24.AttackerHasAdvantageAgainst(caster, target)
		or B24.HasTimed(caster, "SPELL_ADV")
	-- The ranged-in-melee rule (B24ADV.lua) asks what kind of attack this is.
	B24.spellAttackRanged = rangedSpell(caster, target, res)
	local ok, disadvantage = pcall(function()
		return B24.AttackerHasDisadvantage(caster) or B24.TargetGrantsDisadvantage(target)
			or B24.AttackerHasDisadvantageAgainst(caster, target)
	end)
	B24.spellAttackRanged = nil
	if not ok then error(disadvantage) end
	local roll = B24.RollD20(advantage, disadvantage)
	local bonus = B24.ProfOf(caster) + castingMod(caster, res)
	local ac = 20 - target:getActiveStats().m_nArmorClass
	local hit = roll == 20 or (roll ~= 1 and roll + bonus >= ac)
	if not hit and rerollMiss(caster, target, res) then
		local again = B24.RollD20(advantage, disadvantage)
		B24.Log(string.format("%s rerolls the missed %s attack: %d", B24.Name(caster), label, again + bonus))
		roll = again
		hit = roll == 20 or (roll ~= 1 and roll + bonus >= ac)
	end
	B24.Log(string.format("%s: %s attack %d (%d%s) vs AC %d - %s", B24.Name(caster), label, roll + bonus, roll,
		signed(bonus), ac, hit and (roll == 20 and "critical hit" or "hit") or "miss"))
	return hit, roll == 20
end

function B24SP.Damage(target, caster, dice, size, damageType, flat, res)
	B24.ApplyEffect(target, { ["effectID"] = 12, ["numDice"] = dice, ["diceSize"] = size,
		["effectAmount"] = flat or 0, ["dwFlags"] = damageType, ["sourceID"] = caster.m_id, ["m_sourceRes"] = res or "" })
end

-- listener(caster, cantrip) returns true if creatures that save against the cantrip still take half
-- damage (the Evoker's Potent Cantrip).
B24SP.PotentCantripListeners = {}

local function potent(caster, entry)
	for _, listener in ipairs(B24SP.PotentCantripListeners) do
		local ok, result = pcall(listener, caster, entry)
		if ok and result then return true end
	end
	return false
end

--------------
-- Cantrips --
--------------

local ACID, COLD, FIRE, LIGHTNING, POISON, MAGIC, PIERCING = 0x10000, 0x20000, 0x80000, 0x40000, 0x200000, 0x400000, 0x100000

B24SP.CANTRIPS = {
	{ key = "ACID_SPLASH", res = "B24CACID", name = "Acid Splash", lists = "SW", save = "DEX", die = 6, damage = ACID },
	{ key = "CHILL_TOUCH", res = "B24CCHIL", name = "Chill Touch", lists = "SW", attack = true, die = 10, damage = MAGIC },
	{ key = "FIRE_BOLT", res = "B24CFIRE", name = "Fire Bolt", lists = "SW", attack = true, die = 10, damage = FIRE },
	{ key = "POISON_SPRAY", res = "B24CPOIS", name = "Poison Spray", lists = "SWD", attack = true, die = 12, damage = POISON },
	{ key = "RAY_OF_FROST", res = "B24CFROS", name = "Ray of Frost", lists = "SW", attack = true, die = 8, damage = COLD, slow = true },
	{ key = "SHOCKING_GRASP", res = "B24CSHOC", name = "Shocking Grasp", lists = "SW", attack = true, die = 8, damage = LIGHTNING },
	{ key = "SORCEROUS_BURST", res = "B24CBURS", name = "Sorcerous Burst", lists = "S", attack = true, die = 8, damage = FIRE },
	{ key = "SACRED_FLAME", res = "B24CSACR", name = "Sacred Flame", lists = "C", save = "DEX", die = 8, damage = MAGIC },
	{ key = "TOLL_THE_DEAD", res = "B24CTOLL", name = "Toll the Dead", lists = "CW", save = "WIS", die = 8, damage = MAGIC, toll = true },
	{ key = "WORD_OF_RADIANCE", res = "B24CWORD", name = "Word of Radiance", lists = "C", save = "CON", die = 6, damage = MAGIC, aura = true },
	{ key = "PRODUCE_FLAME", res = "B24CFLAM", name = "Produce Flame", lists = "D", attack = true, die = 8, damage = FIRE },
	{ key = "THORN_WHIP", res = "B24CTHRN", name = "Thorn Whip", lists = "D", attack = true, die = 6, damage = PIERCING, pull = 10 },
	{ key = "STARRY_WISP", res = "B24CWISP", name = "Starry Wisp", lists = "BD", attack = true, die = 8, damage = MAGIC },
	{ key = "VICIOUS_MOCKERY", res = "B24CMOCK", name = "Vicious Mockery", lists = "B", save = "WIS", die = 6, damage = MAGIC, mockery = true },
}

local function regrant(caster, res)
	B24.ApplyEffect(caster, { ["effectID"] = 172, ["res"] = res })
	B24.ApplyEffect(caster, { ["effectID"] = 171, ["res"] = res })
end

local function cantripHit(caster, target, entry)
	local dice = B24SP.CantripDice(caster)
	local size = entry.die
	if entry.toll and target.m_baseStats.m_hitPoints < target:getStat(B24.Stat.MAXHP) then size = 12 end
	if entry.attack then
		local hit, critical = B24SP.SpellAttack(caster, target, entry.res, entry.name)
		if not hit then return end
		B24SP.Damage(target, caster, critical and dice * 2 or dice, size, entry.damage, 0, entry.res)
	else
		local dc = B24.SpellSaveDC(caster, entry.res)
		if B24.RollSave(target, entry.save, dc, nil, " (" .. entry.name .. ")") then
			if potent(caster, entry) then
				B24SP.Damage(target, caster, 0, 0, entry.damage, math.floor(rollDice(dice, size) / 2), entry.res)
			end
			return
		end
		B24SP.Damage(target, caster, dice, size, entry.damage, 0, entry.res)
	end
	-- Thorn Whip: pulled up to 10 ft toward the caster (Large or smaller).
	if entry.pull then B24.ForceMove(target, caster, entry.pull, true, B24.SIZE.LARGE) end
	if entry.slow then
		B24.ApplyEffect(target, { ["effectID"] = 176, ["effectAmount"] = 67, ["dwFlags"] = 5,
			["durationType"] = 0, ["duration"] = 6, ["sourceID"] = caster.m_id })
	end
	if entry.mockery and B24WPN then
		B24.Aux(target).B24_SappedUntil = B24.GameTick() + 90
	end
end

-- op402 entry point of the cantrip innates.
function B24CANT(op402, target)
	EEex_Utility_TryIgnore(function()
		local entry = B24SP.CANTRIPS[op402.m_effectAmount]
		local caster = B24.GetSprite(op402.m_sourceId)
		if entry == nil or caster == nil then return end
		if entry.aura then
			for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(caster, "[ENEMY]", B24.ADJACENT, true) or {}) do
				cantripHit(caster, enemy, entry)
			end
		else
			cantripHit(caster, target, entry)
		end
		regrant(caster, entry.res)
	end)
end

-- Chosen cantrips are granted as innates whenever the class features are applied.
function B24SP.KnownCantrips(sprite)
	local known = {}
	local mask = sprite:getLocalInt("B24CANT")
	for i, entry in ipairs(B24SP.CANTRIPS) do
		if EEex_IsBitSet(mask, i - 1) then table.insert(known, entry) end
	end
	return known
end

B24SP.ClassHooks = B24SP.ClassHooks or {}
table.insert(B24SP.ClassHooks, function()
	B24LV.AddApplyListener(function(sprite)
		for _, entry in ipairs(B24SP.KnownCantrips(sprite)) do regrant(sprite, entry.res) end
	end)
end)

----------------
-- New spells --
----------------

B24SP.SPELLS = {
	{ key = "GUIDING_BOLT", name = "Guiding Bolt", attack = true, dice = 4, die = 6, damage = MAGIC, grantsAdvantage = true, level = 1, up = 1 },
	{ key = "THUNDERWAVE", name = "Thunderwave", save = "CON", dice = 2, die = 8, damage = 0, aura = B24.Feet(15), push = true, half = true, level = 1, up = 1 },
	{ key = "SHATTER", name = "Shatter", save = "CON", dice = 3, die = 8, damage = 0, around = 80, half = true, level = 2, up = 1 },
	{ key = "SPIRIT_GUARDIANS", name = "Spirit Guardians", guardians = true, dice = 3, level = 3, up = 1 },
}

-- Dice of a new spell cast with a higher slot: its upcast copies (B24U..., b24_spells.tpa) have
-- their slot level as spell level.
function B24SP.UpcastDice(entry, res)
	return entry.dice + math.max(0, B24SP.SpellLevel(res) - (entry.level or 1)) * (entry.up or 0)
end

local function newSpellHit(caster, target, entry, res)
	local dice = B24SP.UpcastDice(entry, res)
	if entry.attack then
		local hit, critical = B24SP.SpellAttack(caster, target, res, entry.name)
		if not hit then return end
		B24SP.Damage(target, caster, critical and dice * 2 or dice, entry.die, entry.damage, 0, res)
		if entry.grantsAdvantage then B24.SetTimed(target, "GRANTS_ADV", 6) end
		return
	end
	local dc = B24.SpellSaveDC(caster, res)
	local saved = B24.RollSave(target, entry.save, dc, nil, " (" .. entry.name .. ")")
	local damage = rollDice(dice, entry.die)
	if saved then
		if not entry.half then return end
		damage = math.floor(damage / 2)
	elseif entry.push then
		B24.ForceMove(target, caster, 10)
	end
	B24SP.Damage(target, caster, 0, 0, entry.damage, damage, res)
end

function B24NSPL(op402, target)
	EEex_Utility_TryIgnore(function()
		local entry = B24SP.SPELLS[op402.m_effectAmount]
		local caster = B24.GetSprite(op402.m_sourceId)
		if entry == nil or caster == nil then return end
		local res = op402.m_sourceRes:get()
		if entry.guardians then
			B24.SetTimed(caster, "SPIRIT_GUARDIANS", 60)
			B24.Aux(caster).B24_GuardianDC = B24.SpellSaveDC(caster, res)
			B24.Aux(caster).B24_GuardianDice = B24SP.UpcastDice(entry, res)
			B24.Log(string.format("%s: Spirit Guardians", B24.Name(caster)))
		elseif entry.aura then
			for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(caster, "[ENEMY]", entry.aura, true) or {}) do
				newSpellHit(caster, enemy, entry, res)
			end
		elseif entry.around then
			newSpellHit(caster, target, entry, res)
			for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(target, "[ENEMY]", entry.around, true) or {}) do
				if enemy.m_id ~= target.m_id then newSpellHit(caster, enemy, entry, res) end
			end
		else
			newSpellHit(caster, target, entry, res)
		end
	end)
end

-- Catalog spells that became a spell attack (Inflict Wounds): op402 parameter 1 dice, parameter 2
-- die size, special = flat damage; upcast versions carry more dice (b24_spells.tpa). Necrotic and
-- radiant damage are magic damage in BG.
-- The catalog spell an upcast version belongs to (SPWI2113 = Acid Arrow cast at level 3).
local function baseSpell(res)
	res = (res or ""):upper()
	local row = B24SP.UPCAST and B24SP.UPCAST[res]
	return row and row.BASE:upper() or res
end
B24SP.BaseSpell = baseSpell

-- Damage types of the spell attacks (magic damage stands for force, necrotic and radiant).
-- CHOICE: the caster picks (Chromatic Orb): the type the target resists least.
B24SP.ATTACK_TYPE = { SPWI118 = "CHOICE", SPWI211 = ACID, SPWI217 = FIRE }
-- Damage type and its resistance stat (STATS.IDS: RESISTFIRE 14, RESISTCOLD 15, RESISTELECTRICITY
-- 16, RESISTACID 17, RESISTPOISON 74).
local CHOICE_TYPES = { { FIRE, 14 }, { COLD, 15 }, { LIGHTNING, 16 }, { ACID, 17 }, { POISON, 74 } }

local function attackType(res, target)
	local damageType = B24SP.ATTACK_TYPE[baseSpell(res)] or MAGIC
	if damageType ~= "CHOICE" then return damageType end
	local best, lowest = FIRE, math.huge
	for _, entry in ipairs(CHOICE_TYPES) do
		local value = target:getStat(entry[2])
		if value < lowest then best, lowest = entry[1], value end
	end
	return best
end

function B24SATK(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		local res = op402.m_sourceRes:get()
		local dice, size = op402.m_effectAmount, op402.m_dWFlags
		local damageType = attackType(res, target)
		local hit, critical = B24SP.SpellAttack(caster, target, res, res)
		if baseSpell(res) == "SPWI211" then
			-- Acid Arrow: 4d4 acid on a hit and 2d4 (+1d4 per level above 2) a round later, half the
			-- first part on a miss.
			if not hit then
				B24SP.Damage(target, caster, 0, 0, damageType, math.floor(rollDice(dice, size) / 2), res)
				return
			end
			B24SP.Damage(target, caster, critical and dice * 2 or dice, size, damageType, 0, res)
			B24.ApplyEffect(target, { ["effectID"] = 12, ["numDice"] = dice - 2, ["diceSize"] = size, ["dwFlags"] = damageType,
				["durationType"] = 4, ["duration"] = 6, ["sourceID"] = caster.m_id, ["m_sourceRes"] = res })
			return
		end
		-- Vampiric Touch (the spell, concentration): the touch can be made again each round (B24VTAGN).
		if baseSpell(res) == "SPWI314" then B24SP.VampiricReady(caster, dice, size) end
		if not hit then return end
		if baseSpell(res) == "SPWI314" or res:upper() == "SPIN106" then
			-- Vampiric Touch (and the Bhaalspawn power of that name): the caster regains half the
			-- necrotic damage.
			local damage = rollDice(critical and dice * 2 or dice, size)
			B24SP.Damage(target, caster, 0, 0, damageType, damage, res)
			B24.Heal(caster, math.floor(damage / 2))
			return
		end
		B24SP.Damage(target, caster, critical and dice * 2 or dice, size, damageType, op402.m_special, res)
	end)
end

-- Vampiric Touch again (2024: the touch can be repeated each turn while the spell lasts): an innate
-- (B24VTAGN) while the caster concentrates on Vampiric Touch, once per round, with the dice of the
-- slot it was cast with; it goes when the concentration ends.
B24SP.VAMPIRIC_AGAIN = "B24VTAGN"
function B24SP.VampiricReady(caster, dice, size)
	B24.Aux(caster).B24_Vampiric = { dice = dice, size = size }
	B24.ApplyEffect(caster, { ["effectID"] = 172, ["res"] = B24SP.VAMPIRIC_AGAIN })
	B24.ApplyEffect(caster, { ["effectID"] = 171, ["res"] = B24SP.VAMPIRIC_AGAIN })
end

local function vampiricActive(caster)
	local record = B24.Concentration and B24.Concentration[caster.m_id]
	return record ~= nil and baseSpell(B24.OriginalSpellRes(record.res)) == "SPWI314" and B24.Aux(caster).B24_Vampiric ~= nil
end

function B24VTAGN(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		if not vampiricActive(caster) then
			B24.ApplyEffect(caster, { ["effectID"] = 172, ["res"] = B24SP.VAMPIRIC_AGAIN })
			return
		end
		local aux, now = B24.Aux(caster), B24.GameTick()
		-- Back for the next round either way.
		B24.ApplyEffect(caster, { ["effectID"] = 171, ["res"] = B24SP.VAMPIRIC_AGAIN })
		if aux.B24_VampiricTick and now >= aux.B24_VampiricTick and now - aux.B24_VampiricTick < 90 then
			B24.Log(string.format("%s: Vampiric Touch again only once per round", B24.Name(caster)))
			return
		end
		aux.B24_VampiricTick = now
		local v = aux.B24_Vampiric
		local hit, critical = B24SP.SpellAttack(caster, target, "SPWI314", "Vampiric Touch")
		if not hit then return end
		local damage = rollDice(critical and v.dice * 2 or v.dice, v.size)
		B24SP.Damage(target, caster, 0, 0, MAGIC, damage, "SPWI314")
		B24.Heal(caster, math.floor(damage / 2))
	end)
end

table.insert(B24.ConcEndListeners, function(casterID, res)
	if baseSpell(B24.OriginalSpellRes(res)) ~= "SPWI314" then return end
	local caster = B24.GetSprite(casterID)
	if caster == nil then return end
	B24.Aux(caster).B24_Vampiric = nil
	B24.ApplyEffect(caster, { ["effectID"] = 172, ["res"] = B24SP.VAMPIRIC_AGAIN })
end)

-- Darts and rays (Magic Missile, Scorching Ray): the first one goes to the target of the cast. A
-- party member aims the others: for a round they are innates (B24MDART, B24SRAY) that cost no
-- action, each aimed like a spell (also in the turn-based mode, where they don't end the turn).
-- The ones not aimed go to the first target when the caster starts something else or the round
-- is over (to the nearest enemy if that target is gone). Other casters send all at the target.
B24SP.VOLLEY_INNATES = { DART = "B24MDART", RAY = "B24SRAY" }
B24SP.FREE_INNATES = { B24MDART = true, B24SRAY = true }
B24SP.volleys = {}

local function volleyShot(caster, target, volley)
	if volley.kind == "DART" then
		B24SP.Damage(target, caster, 1, volley.size, MAGIC, volley.flat, volley.res)
	else
		local hit, critical = B24SP.SpellAttack(caster, target, volley.res,
			string.format("%s (ray %d)", volley.res, volley.total - volley.left))
		if hit then
			B24SP.Damage(target, caster, critical and volley.dice * 2 or volley.dice, volley.size,
				attackType(volley.res, target), 0, volley.res)
		end
	end
end

local function endVolley(caster)
	local volley = B24SP.volleys[caster.m_id]
	if volley == nil then return end
	B24SP.volleys[caster.m_id] = nil
	B24.ApplyEffect(caster, { ["effectID"] = 172, ["res"] = B24SP.VOLLEY_INNATES[volley.kind] })
end

-- The darts or rays not aimed: at the first target, or at the nearest enemy in sight.
local function flushVolley(caster)
	local volley = B24SP.volleys[caster.m_id]
	if volley == nil then return end
	local target = B24.GetSprite(volley.target)
	if target == nil or B24.GState_Has(target, B24.GState.DEAD) then
		target = (B24X and B24X.Enemies or function(s, r)
			return EEex_Sprite_GetAllOfTypeStringInRange(s, "[ENEMY]", r, true) or {}
		end)(caster, 448)[1]
	end
	if target and volley.left > 0 then
		B24.Log(string.format("%s: %d %s left, at %s", B24.Name(caster), volley.left,
			volley.kind == "DART" and "darts" or "rays", B24.Name(target)))
		while volley.left > 0 do
			volley.left = volley.left - 1
			volleyShot(caster, target, volley)
		end
	end
	endVolley(caster)
end
B24SP.FlushVolley = flushVolley

function B24SP.HasVolley(sprite)
	local volley = B24SP.volleys[sprite.m_id]
	return volley ~= nil and volley.left > 0
end

-- The first shot at the target; the rest aimed (party) or all at the target.
local function startVolley(caster, target, volley)
	flushVolley(caster)
	volley.total, volley.left, volley.target = volley.count, volley.count - 1, target.m_id
	volleyShot(caster, target, volley)
	if volley.left == 0 then return end
	if not B24.InParty(caster) then
		while volley.left > 0 do
			volley.left = volley.left - 1
			volleyShot(caster, target, volley)
		end
		return
	end
	volley.untilTick = B24.GameTick() + 90
	B24SP.volleys[caster.m_id] = volley
	local innate = B24SP.VOLLEY_INNATES[volley.kind]
	B24.ApplyEffect(caster, { ["effectID"] = 172, ["res"] = innate })
	for _ = 1, volley.left do B24.ApplyEffect(caster, { ["effectID"] = 171, ["res"] = innate }) end
	B24.Log(string.format("%s: %d more %s to aim this round", B24.Name(caster), volley.left,
		volley.kind == "DART" and "darts" or "rays"))
end

-- An aimed dart or ray (the innates).
local function aimed(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		local volley = caster and B24SP.volleys[caster.m_id]
		if volley == nil or volley.left <= 0 then return end
		volley.left = volley.left - 1
		volleyShot(caster, target, volley)
		if volley.left == 0 then endVolley(caster) end
	end)
end
B24MDARX = aimed
B24SRAYX = aimed

-- Casting anything else sends the rest; so does the end of the round (party tick) or the turn.
table.insert(B24.SpellCastListeners, function(sprite, res)
	if B24SP.volleys[sprite.m_id] and not B24SP.FREE_INNATES[res:upper()] then flushVolley(sprite) end
end)
table.insert(B24TB.TurnEndListeners, function(sprite) flushVolley(sprite) end)
table.insert(B24SP.ClassHooks, function()
	B24LV.AddTickListener(function(sprite)
		local volley = B24SP.volleys[sprite.m_id]
		if volley == nil then return end
		-- In the turn-based mode the turn's end sends them (game time stands still during a turn).
		if B24TB.InTurns and B24TB.InTurns(sprite) then return end
		if B24.GameTick() > volley.untilTick then flushVolley(sprite) end
	end)
end)

-- Scorching Ray: parameter 1 rays (3, one more per level above 2), each a spell attack for
-- <special>d<parameter 2> fire (2d6).
function B24RAYS(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		startVolley(caster, target, { kind = "RAY", count = op402.m_effectAmount, size = op402.m_dWFlags,
			dice = math.max(1, op402.m_special), res = op402.m_sourceRes:get() })
	end)
end

-- Magic Missile: parameter 1 darts (3, one more per level above 1) of 1d<parameter 2> + <special>
-- force damage each, no attack roll. A projectile with several missiles calls this for each; only
-- the first within the same cast counts.
B24SP.dartCasts = {}
function B24DART(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		local key = caster.m_id .. ":" .. target.m_id
		local now = B24.GameTick()
		if B24SP.dartCasts[key] and now - B24SP.dartCasts[key] < 30 then return end
		B24SP.dartCasts[key] = now
		startVolley(caster, target, { kind = "DART", count = op402.m_effectAmount, size = op402.m_dWFlags,
			flat = op402.m_special, res = op402.m_sourceRes:get() })
	end)
end

-- Area spells whose BG projectile reaches a creature several times (Meteor Swarm's meteors, Ice
-- Storm's rounds of hail) but whose 2024 damage comes once: each damage part { dice, size, type }
-- (BG crushing 0 for bludgeoning), a save for half (Evasion: none on a success, half on a
-- failure); a creature counts once per caster within window ticks.
B24SP.AREA = {
	SPWI911 = { label = "Meteor Swarm", ability = "DEX", window = 60, parts = { { 20, 6, FIRE }, { 20, 6, 0 } } },
	SPWI404 = { label = "Ice Storm", ability = "DEX", window = 450, parts = { { 2, 10, 0 }, { 4, 6, COLD } } },
}
B24SP.areaCasts = {}
function B24AREA(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		local res = op402.m_sourceRes:get()
		local entry = B24SP.AREA[baseSpell(B24.OriginalSpellRes(res))]
		if caster == nil or entry == nil then return end
		local key = caster.m_id .. ":" .. target.m_id .. ":" .. entry.label
		local now = B24.GameTick()
		if B24SP.areaCasts[key] and now - B24SP.areaCasts[key] < entry.window then return end
		B24SP.areaCasts[key] = now
		local saved = B24.RollSave(target, entry.ability, B24.SpellSaveDC(caster, res), nil, " (" .. entry.label .. ")")
		local evasion = entry.ability == "DEX" and B24.HasEvasion(target)
		for _, part in ipairs(entry.parts) do
			local damage = rollDice(part[1], part[2])
			if saved then damage = evasion and 0 or math.floor(damage / 2)
			elseif evasion then damage = math.floor(damage / 2) end
			if damage > 0 then B24SP.Damage(target, caster, 0, 0, part[3], damage, res) end
		end
	end)
end

-- Power Word Kill: a creature with 100 hit points or fewer dies; any other takes 12d12 psychic
-- damage (BG magic damage).
B24SP.PWK_HP, B24SP.PWS_HP = 100, 150
function B24PWK(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		local res = op402.m_sourceRes:get()
		if target.m_baseStats.m_hitPoints <= B24SP.PWK_HP then
			B24.ApplyEffect(target, { ["effectID"] = 13, ["dwFlags"] = 8, ["durationType"] = 1, ["sourceID"] = caster.m_id,
				["m_sourceRes"] = res })
			B24.Log(string.format("Power Word Kill: %s dies", B24.Name(target)))
		else
			B24SP.Damage(target, caster, 12, 12, MAGIC, 0, res)
		end
	end)
end

-- Power Word Stun: a creature with 150 hit points or fewer is stunned and repeats a Constitution
-- save at the end of each of its turns (every round outside turn-based combat; B24COND.lua); any
-- other can't move until the caster's next turn (a round).
function B24PWS(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		local res = op402.m_sourceRes:get()
		if target.m_baseStats.m_hitPoints <= B24SP.PWS_HP then
			B24.ApplyEffect(target, { ["effectID"] = 45, ["durationType"] = 0, ["duration"] = 600, ["sourceID"] = caster.m_id,
				["m_sourceRes"] = res })
			if B24CD and B24CD.AddRepeatSave then
				B24CD.AddRepeatSave(target, res, "CON", B24.SpellSaveDC(caster, res), caster.m_id)
			end
			B24.Log(string.format("Power Word Stun: %s is stunned", B24.Name(target)))
		else
			B24.ApplyEffect(target, { ["effectID"] = 176, ["effectAmount"] = 0, ["dwFlags"] = 5, ["durationType"] = 0,
				["duration"] = 6, ["sourceID"] = caster.m_id, ["m_sourceRes"] = res })
		end
	end)
end

-- Haste: advantage on Dexterity saves while it lasts; when concentration breaks before the minute
-- is over the creature is stunned for a round (lethargy; at the minute's end the spell's own
-- delayed effect does it, b24_spells.tpa).
B24SP.HASTE = "SPWI305"
local function hasteRes(res) return baseSpell(B24.OriginalSpellRes(res or "")) == B24SP.HASTE end

B24.AddSaveAdvantageListener(function(sprite, ability)
	if ability ~= "DEX" then return false, false end
	local hasted = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == 16 and hasteRes(effect.m_sourceRes:get():upper()) then hasted = true return true end
	end)
	return hasted, false
end)

local function lethargy(target)
	B24.ApplyEffect(target, { ["effectID"] = 45, ["durationType"] = 0, ["duration"] = 6, ["m_sourceRes"] = "B24LETHA" })
	B24.Log(string.format("%s: Haste ends, lethargic for a round", B24.Name(target)))
end

-- The spell's delayed effect at the end of the minute.
function B24LETHA(op402, target)
	EEex_Utility_TryIgnore(lethargy, target)
end

if B24.ConcEndListeners then
	table.insert(B24.ConcEndListeners, function(casterID, res, targets, affected)
		if not hasteRes(res) then return end
		for targetID in pairs(affected or {}) do
			local target = B24.GetSprite(targetID)
			if target then lethargy(target) end
		end
	end)
end

-- Spirit Guardians: enemies near the caster take 3d8 radiant damage every round (Wisdom save for
-- half) for a minute (driven by the class component's tick).
-- Spirit Guardians and its upcast copies (B24USPG4..7), under their own or their priest list names.
function B24SP.IsGuardians(res)
	for _, name in ipairs({ "B24SPGRD", "B24USPG4", "B24USPG5", "B24USPG6", "B24USPG7" }) do
		if res == name or res == (B24SP.MOVED[name] or ""):upper() then return true end
	end
	return false
end
-- It is a concentration spell (B24CONC.2DA): when concentration ends, so do the guardians.
table.insert(B24.ConcEndListeners, function(casterID, res)
	res = res:upper()
	if not B24SP.IsGuardians(res) then return end
	local caster = B24.GetSprite(casterID)
	local timed = caster and B24.Aux(caster).B24_Timed
	if timed then timed.SPIRIT_GUARDIANS = nil end
end)
table.insert(B24SP.ClassHooks, function()
	B24LV.AddTickListener(function(caster)
		if not B24.HasTimed(caster, "SPIRIT_GUARDIANS") then return end
		local aux = B24.Aux(caster)
		local now = B24.GameTick()
		if aux.B24_GuardianTick and now - aux.B24_GuardianTick < 90 then return end
		aux.B24_GuardianTick = now
		for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(caster, "[ENEMY]", B24.Feet(15), true) or {}) do
			local damage = rollDice(aux.B24_GuardianDice or 3, 8)
			if B24.RollSave(enemy, "WIS", aux.B24_GuardianDC or 13, nil, " (Spirit Guardians)") then
				damage = math.floor(damage / 2)
			end
			B24SP.Damage(enemy, caster, 0, 0, MAGIC, damage, "B24SPGRD")
		end
	end)
end)

-------------------------------------------
-- Arcane upcast versions, bard copies --
-------------------------------------------

B24SP.UPCAST = B24.LoadTable("B24UPCST")

-- New arcane spells (no scrolls exist): learned by the classes whose 2024 lists hold them once
-- they have slots of the spell's level. Bard-only copies are removed from everyone else.
B24SP.NEW_ARCANE = {
	B24THWAV = { level = 1, lists = "WSB" },
	B24SHATR = { level = 2, lists = "WSB" },
	B24MSTEP = { level = 2, lists = "WS" },
	B24ENLRG = { level = 2, lists = "WSB" },
	B24REDUC = { level = 2, lists = "WSB" },
	B24HWBRD = { level = 1, lists = "B", bardOnly = true },
	B24CWBRD = { level = 1, lists = "B", bardOnly = true },
	B24MHWBD = { level = 3, lists = "B", bardOnly = true },
}
local ARCANE_CLASSES = { W = "WIZARD", S = "SORCERER", B = "BARD" }

-- Highest spell level a full caster of this class level can cast.
local function maxSpellLevel(classLevel)
	return math.min(9, math.floor((classLevel + 1) / 2))
end

local function knownMageSpells(sprite)
	local known = {}
	for _, _, res in EEex_Sprite_GetKnownMageSpellsIterator(sprite, 1, 9) do known[res:upper()] = true end
	return known
end

-- Spells filed again under a name with their 2024 level (B24MOVED.2DA, b24_spells.tpa): old -> new.
B24SP.MOVED = {}
do
	local ok, rows = pcall(B24.LoadTable, "B24MOVED")
	for old, row in pairs(ok and rows or {}) do B24SP.MOVED[old] = row.NEW end
end

local function knownPriestSpells(sprite)
	local known = {}
	for _, _, res in EEex_Sprite_GetKnownPriestSpellsIterator(sprite, 1, 7) do known[res:upper()] = true end
	return known
end

-- Characters made before the re-filing (and companions) know the old names: they learn the new
-- ones and lose the old.
local function migrateMoved(sprite)
	for _, known in ipairs({ knownMageSpells(sprite), knownPriestSpells(sprite) }) do
		for old, new in pairs(B24SP.MOVED) do
			if known[old] then
				if not known[new] then B24.ApplyEffect(sprite, { ["effectID"] = 147, ["res"] = new }) end
				B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = old })
				B24.Log(string.format("%s: %s is now %s", B24.Name(sprite), old, new))
			end
		end
	end
end

-- Highest arcane spell level the creature has slots for (the engine's memorization info: an array
-- of pointers to CRE entries of spell level, slots, ...), 0 without any.
function B24SP.MageSlotLevel(sprite)
	local highest = 0
	for level = 1, 9 do
		local ok, slots = pcall(function()
			local entry = EEex_ReadPtr(EEex_UDToPtr(sprite.m_memorizedSpellsLevelMage) + (level - 1) * 8)
			if EEex_ReadU16(entry) ~= level - 1 then return 0 end
			return EEex_ReadU16(entry + 2)
		end)
		if ok and slots > 0 then highest = level end
	end
	return highest
end

function B24SP.UpdateSpellbook(sprite)
	if B24.SkillClass(sprite) == nil then return end
	EEex_Utility_TryIgnore(migrateMoved, sprite)
	local known = knownMageSpells(sprite)
	-- Upcast copies of known spells, up to the highest level the caster has slots for (copies of
	-- higher levels, from before this limit, are removed).
	local maxLevel = B24SP.MageSlotLevel(sprite)
	for variant, row in pairs(B24SP.UPCAST) do
		local level = tonumber(row.LEVEL) or 0
		if known[row.BASE] and not known[variant] and level <= maxLevel then
			B24.ApplyEffect(sprite, { ["effectID"] = 147, ["res"] = variant })
		elseif known[variant] and level > maxLevel then
			B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = variant })
		end
	end
	if B24LV == nil then return end
	for res, spell in pairs(B24SP.NEW_ARCANE) do
		local allowed = false
		for letter, class in pairs(ARCANE_CLASSES) do
			if spell.lists:find(letter, 1, true) and maxSpellLevel(B24LV.ClassLevel(sprite, class)) >= spell.level then
				allowed = true
			end
		end
		if allowed and not known[res] then
			B24.ApplyEffect(sprite, { ["effectID"] = 147, ["res"] = res })
		elseif spell.bardOnly and known[res] and B24LV.ClassLevel(sprite, "BARD") <= 0 then
			B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = res })
		end
	end
end

-- Enlarge/Reduce (concentration, a minute; BG has two spells for the two choices): one size up or
-- down (B24.Size), advantage or disadvantage on Strength saves, weapon hits +1d4 or -1d4 (at least
-- 1). A marker effect (op0 of 0) from the spell carries it, so concentration ends it. A creature
-- of the other side makes a Constitution save. Parameter 1: 1 Enlarge, 2 Reduce.
B24SP.SIZE_SPELLS = { B24ENLRG = 1, B24ENLDR = 1, B24REDUC = -1, B24REDDR = -1 }
-- The druid versions are filed under SPPR names (B24MOVED.2DA).
for old, new in pairs(B24SP.MOVED) do
	if B24SP.SIZE_SPELLS[old:upper()] then B24SP.SIZE_SPELLS[new:upper()] = B24SP.SIZE_SPELLS[old:upper()] end
end

function B24.SizeShiftOf(sprite)
	local shift = 0
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		local step = effect.m_effectId == 0 and B24SP.SIZE_SPELLS[effect.m_sourceRes:get():upper()]
		if step then
			shift = step
			return true
		end
	end)
	return shift
end

function B24SIZE(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		local res = op402.m_sourceRes:get():upper()
		local enlarge = op402.m_effectAmount == 1
		local name = enlarge and "Enlarge" or "Reduce"
		if B24.InParty(target) ~= B24.InParty(caster)
			and B24.RollSave(target, "CON", B24.SpellSaveDC(caster, res), nil, " (" .. name .. ")", { SOURCE = caster.m_id }) then
			return
		end
		for other in pairs(B24SP.SIZE_SPELLS) do
			if other ~= res then B24.RemoveEffectsBySource(target, other) end
		end
		B24.ApplyEffect(target, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60,
			["sourceID"] = caster.m_id, ["m_sourceRes"] = res })
		B24.Log(string.format("%s: %s on %s", B24.Name(caster), name, B24.Name(target)))
	end)
end

B24.AddSaveAdvantageListener(function(sprite, ability)
	if ability ~= "STR" then return false, false end
	local shift = B24.SizeShiftOf(sprite)
	return shift > 0, shift < 0
end)

table.insert(B24WPN.DamageListeners, function(context)
	local shift = B24.SizeShiftOf(context.attacker)
	if shift == 0 then return end
	local die = B24.Roll(4)
	if shift > 0 then
		context.effect.m_effectAmount = context.effect.m_effectAmount + die
	else
		-- The weapon's dice first, so the minimum of 1 counts the whole damage.
		B24WPN.RollDiceInto(context.effect)
		context.effect.m_effectAmount = math.max(1, context.effect.m_effectAmount - die)
	end
	B24.Log(string.format("%s: %s %d", B24.Name(context.attacker), shift > 0 and "Enlarge +" or "Reduce -", die))
end)

-- Aid (SPPR201 and its upcast copies): the target and up to two more party members near it gain 5
-- maximum and current hit points for 8 hours, 5 more per spell level above 2. A new Aid replaces
-- the old one (source B24AIDHP).
B24SP.AID_RANGE = B24.Feet(30)
function B24AID(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId) or target
		local res = op402.m_sourceRes:get()
		local amount = 5 + 5 * math.max(0, B24SP.SpellLevel(res) - 2)
		local chosen = { target }
		for _, ally in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(target, "[PC]", B24SP.AID_RANGE, true) or {}) do
			if #chosen >= 3 then break end
			if ally.m_id ~= target.m_id then table.insert(chosen, ally) end
		end
		for _, creature in ipairs(chosen) do
			B24.RemoveEffectsBySource(creature, "B24AIDHP")
			B24.ApplyEffect(creature, { ["effectID"] = 18, ["effectAmount"] = amount, ["dwFlags"] = 0, ["durationType"] = 0,
				["duration"] = 28800, ["sourceID"] = caster.m_id, ["m_sourceRes"] = "B24AIDHP" })
		end
		B24.Log(string.format("%s: Aid +%d hit points for %d creatures", B24.Name(caster), amount, #chosen))
	end)
end

-- Mass Healing Word (B24MHEAL, cast on the caster): the caster and nearby party members heal.
function B24MHEAL(op402, caster)
	EEex_Utility_TryIgnore(function()
		local res = op402.m_sourceRes:get()
		local targets = EEex_Sprite_GetAllOfTypeStringInRange(caster, "[PC]", B24.Feet(60), true) or {}
		table.insert(targets, caster)
		for _, target in ipairs(targets) do
			local healed = math.max(1, rollDice(op402.m_effectAmount, op402.m_dWFlags) + castingMod(caster, res))
			B24.Heal(target, healed)
		end
		B24.Log(string.format("%s: Mass Healing Word", B24.Name(caster)))
	end)
end

B24.AddLongRestListener(function(sprite) EEex_Utility_TryIgnore(B24SP.UpdateSpellbook, sprite) end)
table.insert(B24SP.ClassHooks, function()
	B24LV.AddApplyListener(function(sprite) EEex_Utility_TryIgnore(B24SP.UpdateSpellbook, sprite) end)
end)

-- Hooks into the class component (B24LEVEL.lua), which may load before or after this file
-- (M_B24FI.lua calls this too).
function B24SP.AttachClasses()
	if B24SP.ClassesAttached or B24LV == nil then return end
	B24SP.ClassesAttached = true
	for _, hook in ipairs(B24SP.ClassHooks) do hook() end
end

-------------------
-- Spell damage --
-------------------

-- School of a spell (SPL offset 0x25): 1 abjuration ... 6 evocation ... 8 transmutation.
local schoolCache = {}
function B24SP.SpellSchool(res)
	res = res:upper()
	if schoolCache[res] == nil then
		local header = EEex_Resource_Demand(res, "SPL")
		schoolCache[res] = header and EEex_ReadU8(EEex_UDToPtr(header) + 0x25) or 0
	end
	return schoolCache[res]
end
B24SP.EVOCATION = 6

local NEW_SPELL_RES = { B24GBOLT = true, B24THWAV = true, B24THWVD = true, B24SHATR = true, B24SPGRD = true }

local function isSpell(res)
	local prefix = res:sub(1, 4)
	return prefix == "SPWI" or prefix == "SPPR" or prefix == "B24C" or NEW_SPELL_RES[res] == true or res:match("^B24U%u%u%u%d$") ~= nil or res:sub(1, 5) == "B24IP" or res:sub(1, 5) == "B24IW"
end

function B24SP.IsCantrip(res)
	return res:sub(1, 4) == "B24C"
end

-- listener(effect, caster, target, res) can change spell damage before it is applied (Elemental
-- Affinity, Empowered Evocation, Potent Spellcasting). Cantrip damage counts as spell damage.
B24SP.DamageListeners = {}

local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	local res = effect.m_sourceRes:get():upper()
	if B24.IsSprite(sourceSprite) and isSpell(res) then
		for _, listener in ipairs(B24SP.DamageListeners) do
			EEex_Utility_TryIgnore(listener, effect, sourceSprite, targetSprite, res)
		end
	end
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

------------------------------
-- 2024 prepared casting --
------------------------------

-- Wizards, clerics, druids, bards, paladins and rangers cast like 2024 prepared casters: the spells
-- memorized at a level are the prepared spells, and each memorized entry stands for one slot of
-- that level. When a cast uses up the last ready entry of a spell while another spell of the same
-- level still has a ready entry, the two swap, so the cast spell stays ready as long as the level
-- has slots left. (BG needs an entry per slot, so memorizing a spell twice fills a slot.)
-- Sorcerers and shamans are spontaneous casters in the engine already.
B24SP.PREPARED_CLASSES = { WIZARD = true, CLERIC = true, DRUID = true, BARD = true, PALADIN = true, RANGER = true }

local function preparedCaster(sprite)
	for class in pairs(B24SP.PREPARED_CLASSES) do
		if B24LV and B24LV.ClassLevel(sprite, class) > 0 then return true end
	end
	return false
end

-- The memorized spells of one level (CCreatureFileMemorizedSpell entries), nil if the engine
-- structures can't be reached.
local function memorizedEntries(sprite, mage, level)
	local field = mage and sprite.m_memorizedSpellsMage or sprite.m_memorizedSpellsPriest
	local list
	-- The field is an array binding: getReference(i) gives the list of level i + 1.
	for _, get in ipairs({ function() return field:getReference(level - 1) end, function() return field:get(level - 1) end }) do
		local ok, result = pcall(get)
		if ok and result ~= nil then list = result break end
	end
	if list == nil then return nil end
	local entries = {}
	local ok = pcall(EEex_Utility_IterateCPtrList, list, function(entry) table.insert(entries, entry) end)
	return ok and entries or nil
end

local function ready(entry) return EEex_IsBitSet(entry.m_flags, 0) end

-- A memorized (prepared) spell that is still ready counts as a free slot of its level. Features that
-- cast with the creature's own slots (the Bard's Magical Secrets) check and spend them here.
function B24SP.ReadySlotLevel(sprite, mage, minLevel)
	for level = math.max(1, minLevel), mage and 9 or 7 do
		for _, entry in ipairs(memorizedEntries(sprite, mage, level) or {}) do
			if ready(entry) then return level end
		end
	end
end

-- Memorized entries of a level that are not ready: cast since the last long rest, or newly
-- prepared and not memorized yet. Restore makes one ready again (the Wizard's Arcane Recovery
-- and Memorize Spell). An entry's spell: entry.m_spellId:get().
function B24SP.UnreadyEntries(sprite, mage, level)
	local list = {}
	for _, entry in ipairs(memorizedEntries(sprite, mage, level) or {}) do
		if not ready(entry) then table.insert(list, entry) end
	end
	return list
end

function B24SP.Restore(entry)
	entry.m_flags = EEex_BOr(entry.m_flags, 1)
end

-- Spends the lowest ready slot of at least minLevel; returns its level or nil.
function B24SP.SpendSlot(sprite, mage, minLevel)
	for level = math.max(1, minLevel), mage and 9 or 7 do
		for _, entry in ipairs(memorizedEntries(sprite, mage, level) or {}) do
			if ready(entry) then
				entry.m_flags = EEex_BAnd(entry.m_flags, EEex_BNot(1))
				return level
			end
		end
	end
end

-- Spends a ready memorized entry of one spell (a reaction spell such as Shield, B24TURN.lua);
-- returns true if there was one. check = true: only looks.
function B24SP.SpendSpell(sprite, mage, level, res, check)
	for _, entry in ipairs(memorizedEntries(sprite, mage, level) or {}) do
		if ready(entry) and entry.m_spellId:get():upper() == res then
			if not check then entry.m_flags = EEex_BAnd(entry.m_flags, EEex_BNot(1)) end
			return true
		end
	end
	return false
end

local reported = false
local function swapIn(sprite, pending)
	local entries = memorizedEntries(sprite, pending.mage, pending.level)
	if not reported then
		reported = true
		print(string.format("[BG2024] prepared casting: memorized spell lists %s", entries and "reachable" or "NOT reachable"))
	end
	if entries == nil then return true end
	local usedOwn, spare = nil, nil
	for _, entry in ipairs(entries) do
		local res = entry.m_spellId:get():upper()
		if res == pending.res then
			if ready(entry) then return false end -- still ready (or the cast hasn't used it yet)
			usedOwn = usedOwn or entry
		elseif ready(entry) then
			spare = spare or entry
		end
	end
	if usedOwn and spare then
		usedOwn.m_flags = EEex_BOr(usedOwn.m_flags, 1)
		spare.m_flags = EEex_BAnd(spare.m_flags, EEex_BNot(1))
		local function name(res)
			local ok, text = pcall(function() return Infinity_FetchString(EEex_Resource_Demand(res, "SPL").genericName) end)
			return ok and text ~= "" and text or res
		end
		B24.Log(string.format("%s: %s stays prepared (the slot of %s is used)", B24.Name(sprite), name(pending.res),
			name(spare.m_spellId:get():upper())))
	end
	return true
end

table.insert(B24.SpellCastListeners, function(sprite, res)
	local prefix = res:sub(1, 4)
	if (prefix ~= "SPWI" and prefix ~= "SPPR") or not preparedCaster(sprite) then return end
	local level = B24SP.SpellLevel(res)
	if level < 1 then return end
	-- The engine marks the entry used when the cast goes off; look again for up to 3 seconds.
	B24.Aux(sprite).B24_Prepared = { res = res:upper(), mage = prefix == "SPWI", level = level,
		untilTick = B24.GameTick() + 45 }
end)

table.insert(B24SP.ClassHooks, function()
	B24LV.AddTickListener(function(sprite)
		local aux = B24.Aux(sprite)
		local pending = aux.B24_Prepared
		if pending == nil then return end
		local done = swapIn(sprite, pending)
		if done or B24.GameTick() > pending.untilTick then aux.B24_Prepared = nil end
	end)
end)

-----------------------------
-- 2e buffs in 2024 terms --
-----------------------------

-- True if the creature has a timed effect with the opcode (from a spell whose resref starts with
-- prefix, if given).
local function hasEffect(sprite, opcode, prefix)
	local found = false
	local test = function(effect)
		if effect.m_effectId == opcode and (prefix == nil or effect.m_sourceRes:get():upper():sub(1, #prefix) == prefix) then
			found = true
			return true
		end
	end
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, test)
	if not found then EEex_Utility_IterateCPtrList(sprite.m_equipedEffectList, test) end
	return found
end

-- Barkskin (b24_spells.tpa leaves its set-base-AC effect as a marker): AC can't be lower than 17.
B24.AddStatListener(function(sprite)
	if not hasEffect(sprite, 0, "SPPR202") then return end
	local stats = sprite:getActiveStats()
	if stats.m_nArmorClass > 3 then stats.m_nArmorClass = 3 end
end)

-- Blur and displacement (op65): attacks against the creature have disadvantage.
table.insert(B24.TargetDisadvantageListeners, function(sprite)
	return hasEffect(sprite, 65)
end)

-- Tenser's Transformation: advantage on attacks.
table.insert(B24.AttackAdvantageListeners, function(sprite)
	return hasEffect(sprite, 145, "SPWI603")
end)

------------------
-- Dispel Magic --
------------------

-- 2024 Dispel Magic (SPWI302, SPPR303 and their upcast versions; b24_spells.tpa): every spell on
-- the target of the slot's level or lower ends; for each higher one, an ability check with the
-- caster's spellcasting ability against DC 10 + its level. This is how protections come off in
-- 2024: no Breach or Spellstrike, but Dispel Magic, cast in a higher slot for higher spells.
-- The spell's only working effect lands on the caster (B24DISPL below), so BG's spell protections
-- on the target (Spell Immunity, Spell Turning, Spell Trap, Minor Globe), spells 2024 doesn't
-- have, can't stop it; they are spells to end like any other. A Globe of Invulnerability still
-- blocks a Dispel Magic of level 5 or lower, as in 2024: then only the Globe itself can be ended
-- (the check against its level).
B24SP.GLOBE_OF_INVULNERABILITY = "SPWI602"
B24SP.GLOBE_BLOCKS_UP_TO = 5
-- Timings with an end: 0 (seconds), 3 and 4 (delayed), 10 (ticks) and 4096, what the engine turns
-- a timed effect into once applied (an absolute end in game ticks, see B24TURN.lua).
B24SP.DISPELLABLE_TIMINGS = { [0] = true, [3] = true, [4] = true, [10] = true, [4096] = true }

-- Spell type of an SPL (header 0x1c): 1 wizard, 2 priest, 4 innate; 0 if none.
local spellTypeCache = {}
local function spellType(res)
	if spellTypeCache[res] == nil then
		local ok, header = pcall(EEex_Resource_Demand, res, "SPL")
		spellTypeCache[res] = (ok and header) and EEex_Read16(EEex_UDToPtr(header) + 0x1c) or 0
	end
	return spellTypeCache[res]
end

-- The ongoing spells on a creature: { [res] = level } for wizard and priest spells with a
-- duration (the mod's innates, class features and items are not spells).
function B24SP.OngoingSpells(sprite)
	local spells = {}
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		local res = effect.m_sourceRes:get():upper()
		if res ~= "" and spells[res] == nil and B24SP.DISPELLABLE_TIMINGS[effect.m_durationType] then
			local kind = spellType(res)
			if kind == 1 or kind == 2 then spells[res] = B24SP.SpellLevel(res) end
		end
	end)
	return spells
end

-- The creature the caster's spell action aims at (the spell's effect is on the caster).
local function dispelTarget(caster)
	local recorded = B24.LastSpellTarget and B24.LastSpellTarget[caster.m_id]
	local target = recorded and B24.GetSprite(recorded) or nil
	if target then return target end
	local ok, id = pcall(function() return caster.m_curAction.m_acteeID.m_Instance end)
	target = ok and id and id ~= -1 and B24.GetSprite(id) or nil
	if target == nil then target = B24.GetSprite(caster.m_targetId) end
	return target
end

-- [caster id] = game tick of its last Dispel Magic: the effect on the caster (timing 1; with
-- timing 0 it never ran) can be applied more than once a cast, a tick apart.
B24SP.lastDispel = {}

function B24DISPL(op402, caster)
	local ok, err = pcall(function()
		local now = B24.GameTick()
		local last = B24SP.lastDispel[caster.m_id]
		if last and now - last < 15 then return end
		B24SP.lastDispel[caster.m_id] = now
		local res = op402.m_sourceRes:get():upper()
		-- The effect stays on the caster (timing 1) and would run again each time the engine
		-- applies the caster's effects anew (seen 16 to 30 ticks later): it goes now. The spell's
		-- other effects are all on the target.
		B24.RemoveEffectsBySource(caster, res)
		local slot = B24SP.SpellLevel(res)
		local target = dispelTarget(caster)
		if target == nil then
			B24.Log(string.format("%s: Dispel Magic finds no target", B24.Name(caster)))
			return
		end
		local spells = B24SP.OngoingSpells(target)
		spells[res] = nil
		local listed = {}
		for spell, level in pairs(spells) do table.insert(listed, spell .. ":" .. level) end
		B24.Log(string.format("%s: Dispel Magic (level %d) aims at %s, ongoing spells: %s", B24.Name(caster), slot,
			B24.Name(target), #listed > 0 and table.concat(listed, " ") or "none"))
		local mod = castingMod(caster, res)
		local ended, held = {}, {}
		local function name(spell)
			local ok, text = pcall(function() return Infinity_FetchString(EEex_Resource_Demand(spell, "SPL").genericName) end)
			return (ok and text and text ~= "") and text or spell
		end
		local function check(spell, level)
			local roll = B24.Roll(20)
			local dc = 10 + level
			local success = roll + mod >= dc
			B24.Log(string.format("Dispel Magic against %s (level %d): %d + %d against DC %d, %s", name(spell), level,
				roll, mod, dc, success and "ended" or "holds"))
			return success
		end
		local function endSpell(spell)
			B24.RemoveEffectsBySource(target, spell)
			table.insert(ended, name(spell))
		end
		-- A Globe of Invulnerability shields everything else from a Dispel Magic of level 5 or lower.
		local globe = nil
		for spell, level in pairs(spells) do
			if B24.OriginalSpellRes(spell):sub(1, 7) == B24SP.GLOBE_OF_INVULNERABILITY then globe = spell end
		end
		if globe and slot <= B24SP.GLOBE_BLOCKS_UP_TO then
			if check(globe, spells[globe]) then endSpell(globe) else table.insert(held, name(globe)) end
			B24.Log(string.format("%s: Dispel Magic (level %d) on %s meets the Globe of Invulnerability: %s", B24.Name(caster), slot,
				B24.Name(target), #ended > 0 and "the Globe ends, the spells inside stay" or "it holds"))
			return
		end
		for spell, level in pairs(spells) do
			if level <= slot or check(spell, level) then endSpell(spell) else table.insert(held, name(spell)) end
		end
		B24.Log(string.format("%s: Dispel Magic (level %d) on %s: %s%s", B24.Name(caster), slot, B24.Name(target),
			#ended > 0 and ("ends " .. table.concat(ended, ", ")) or "no spell ends",
			#held > 0 and ("; holding: " .. table.concat(held, ", ")) or ""))
	end)
	-- Errors are printed (the game log): the spell would fail silently otherwise.
	if not ok then print("[BG2024] Dispel Magic: " .. tostring(err)) end
end

-- Last: every class hook above is registered by now.
B24SP.AttachClasses()

-- Class features waiting for the spell runtime (B24LV.WhenSpells).
B24SP.Loaded = true
for _, hook in ipairs(B24_SpellHooks or {}) do EEex_Utility_TryIgnore(hook) end
B24_SpellHooks = {}
