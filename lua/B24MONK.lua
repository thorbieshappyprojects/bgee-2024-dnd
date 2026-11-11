-- BG 2024 Rules Mod: the 2024 Monk with the Warrior of the Open Hand (SRD subclass). BG's monk
-- class abilities (CLABMO01) are removed at install time; the fists follow the Martial Arts die
-- (MONKFIST.2DA -> B24MF* items).
--
--   1  Martial Arts (d6; d8 at 5, d10 at 11, d12 at 17; Dexterity; a bonus unarmed strike),
--      Unarmored Defense (10 + Dexterity + Wisdom)
--   2  Monk's Focus (Focus Points = Monk level: Flurry of Blows, Patient Defense, Step of the
--      Wind), Unarmored Movement, Uncanny Metabolism
--   3  Deflect Attacks, subclass: Open Hand Technique
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Extra Attack, Stunning Strike
--   6  Empowered Strikes (magical fists), Self-Restoration (immune to charm and fear)
--   14 Disciplined Survivor (all saves; spend 1 Focus to reroll a failed save)
--   17 Open Hand: Quivering Palm
--   18 Superior Defense
--   20 Body and Mind (Dexterity and Wisdom +4)
--   Slow Fall, Acrobatic Movement, Deflect Energy, Perfect Focus, Fleet Step: no BG effect yet.
--
-- Locals: B24FPUSE (Focus spent), B24UMUSE (Uncanny Metabolism), B24WBUSE (Wholeness of Body).

B24MO = {}

function B24MO.Level(sprite)
	return B24LV.ClassLevel(sprite, "MONK")
end

function B24MO.Die(sprite)
	local level = B24MO.Level(sprite)
	return level >= 17 and 12 or level >= 11 and 10 or level >= 5 and 8 or 6
end

B24LV.AddSubclasses("MONK", 3, {
	{ key = "OPEN_HAND", name = "Warrior of the Open Hand",
	  desc = "Masters of unarmed combat.\n\nLevel 3: Open Hand Technique (your Flurry of Blows hits can knock targets prone: Dexterity save).\nLevel 6: Wholeness of Body (heal yourself, Wisdom modifier times per long rest).\nLevel 11: Fleet Step (no BG effect yet).\nLevel 17: Quivering Palm (Constitution save or 10d12 force damage).",
	  features = { [3] = "Open Hand Technique", [6] = "Wholeness of Body", [11] = "Fleet Step (no BG effect)", [17] = "Quivering Palm" } },
})

local function isOpenHand(sprite)
	return B24LV.Subclass(sprite, "MONK") == "OPEN_HAND"
end

local function wearsArmorOrShield(sprite)
	local items = sprite.m_equipment.m_items
	local armor, shield = items:get(1), items:get(9)
	return (armor ~= nil and armor.pRes.pHeader.itemType == 2) or (shield ~= nil and shield.pRes.pHeader.itemType == 12)
end

-- Focus Points: one innate per Focus ability, present while points remain.
B24MO.FOCUS_SPELLS = { "B24FLURY", "B24PDEF", "B24STEPW" }

B24LV.AddResource("FOCUS", { localName = "B24FPUSE", shortRest = "all",
	max = function(sprite)
		local level = B24MO.Level(sprite)
		return level >= 2 and level or 0
	end })

B24LV.AddResource("UNCANNY_METABOLISM", { spell = "B24UMETA", localName = "B24UMUSE",
	max = function(sprite) return B24MO.Level(sprite) >= 2 and 1 or 0 end })

B24LV.AddResource("WHOLENESS", { spell = "B24WHOLE", localName = "B24WBUSE",
	max = function(sprite)
		if B24MO.Level(sprite) < 6 or not isOpenHand(sprite) then return 0 end
		return math.max(1, B24.AbilityModOf(sprite, "WIS"))
	end })

-- Focus abilities of the subclasses: { res, cost, when = function(sprite) }.
B24MO.FOCUS_POWERS = {}

local function refreshFocus(sprite)
	local level = B24MO.Level(sprite)
	local left = B24LV.Remaining(sprite, "FOCUS")
	local abilities = { { 2, "B24FLURY" }, { 2, "B24PDEF" }, { 2, "B24STEPW" }, { 5, "B24STUN" }, { 17, "B24QPALM" }, { 18, "B24SUPDF" } }
	local costs = { B24QPALM = 4, B24SUPDF = 3 }
	for _, entry in ipairs(abilities) do
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = entry[2] })
		local needsSubclass = entry[2] == "B24QPALM" and not isOpenHand(sprite)
		if level >= entry[1] and left >= (costs[entry[2]] or 1) and not needsSubclass then
			B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = entry[2] })
		end
	end
	for _, power in ipairs(B24MO.FOCUS_POWERS) do
		B24LV.Grant(sprite, power.res, power.when(sprite) and (left >= (power.cost or 1) or (power.free and power.free(sprite))))
	end
end

local function spendFocus(sprite, points)
	local resource = B24LV.RESOURCES.FOCUS
	if B24LV.Remaining(sprite, "FOCUS") < points then return false end
	sprite:setLocalInt(resource.localName, sprite:getLocalInt(resource.localName) + points)
	refreshFocus(sprite)
	return true
end

B24MO.SpendFocus = spendFocus
B24MO.RefreshFocus = refreshFocus

B24.AddShortRestListener(refreshFocus)
B24.AddLongRestListener(refreshFocus)

B24MO.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24MO.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24MO.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi }
end)

B24MO.FEATURES = {
	[1] = "Martial Arts (d6), Unarmored Defense",
	[2] = "Monk's Focus (Flurry of Blows, Patient Defense, Step of the Wind), Unarmored Movement, Uncanny Metabolism",
	[3] = "Subclass, Deflect Attacks",
	[4] = "Ability Score Improvement",
	[5] = "Extra Attack, Stunning Strike, Martial Arts (d8)",
	[6] = "Empowered Strikes",
	[7] = "Evasion",
	[8] = "Ability Score Improvement",
	[10] = "Heightened Focus, Self-Restoration",
	[11] = "Martial Arts (d10)",
	[12] = "Ability Score Improvement",
	[14] = "Disciplined Survivor",
	[16] = "Ability Score Improvement",
	[17] = "Martial Arts (d12)",
	[18] = "Superior Defense",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Body and Mind (Dexterity and Wisdom +4)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24MO.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "MONK") + 1, level do
		if B24MO.FEATURES[l] then table.insert(lines, string.format("Monk %d: %s", l, B24MO.FEATURES[l])) end
	end
	return lines
end)

-- BG's 2e monk features stored in a companion's creature file (Rasaad from SoD on): speed (op176),
-- extra attacks (op190), poison resistance (op173), immunity to haste, slow, poison, disease and
-- charm (op206, op101, op296) with their messages and icons (op267, op169, op142). The class table
-- no longer grants them (emptied at install time), but the file has them as permanent effects
-- without a source; on top of the 2024 monk they would stack. Marked, then removed by source.
-- The mod's own effects always carry a source, so they stay.
B24MO.OLD_FEATURE_OPCODES = { [101] = true, [142] = true, [169] = true, [173] = true, [176] = true, [190] = true,
	[206] = true, [267] = true, [296] = true }
B24MO.OLD_FEATURES_RES = "B24MOOLD"
local function removeOldFeatures(sprite)
	local found = 0
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_durationType == 9 and B24MO.OLD_FEATURE_OPCODES[effect.m_effectId]
			and effect.m_sourceRes:get() == "" then
			effect.m_sourceRes:set(B24MO.OLD_FEATURES_RES)
			found = found + 1
		end
	end)
	if found == 0 then return end
	B24.RemoveEffectsBySource(sprite, B24MO.OLD_FEATURES_RES)
	B24.Log(string.format("%s: %d effects of BG's monk class removed (the 2024 monk's features replace them)", B24.Name(sprite), found))
end

-- Unarmored Movement: +10 ft at 2, +15 at 6, +20 at 10, +25 at 14, +30 at 18 (of 30 ft).
B24LV.AddApplyListener(function(sprite)
	local level = B24MO.Level(sprite)
	if level <= 0 then return end
	removeOldFeatures(sprite)
	-- The bonus unarmed strike of Martial Arts, and Extra Attack at 5.
	B24LV.Permanent(sprite, { ["effectID"] = 1, ["effectAmount"] = level >= 5 and 2 or 1, ["dwFlags"] = 0 })
	local speed = level >= 18 and 200 or level >= 14 and 183 or level >= 10 and 167 or level >= 6 and 150 or level >= 2 and 133 or 100
	if speed > 100 then B24LV.Permanent(sprite, { ["effectID"] = 176, ["effectAmount"] = speed, ["dwFlags"] = 5 }) end
	if level >= 10 then
		B24LV.Permanent(sprite, { ["effectID"] = 101, ["dwFlags"] = 5 })
		B24LV.Permanent(sprite, { ["effectID"] = 101, ["dwFlags"] = 24 })
	end
	if level >= 20 then
		B24LV.Permanent(sprite, { ["effectID"] = 15, ["effectAmount"] = 4, ["dwFlags"] = 0 })
		B24LV.Permanent(sprite, { ["effectID"] = 49, ["effectAmount"] = 4, ["dwFlags"] = 0 })
	end
	refreshFocus(sprite)
end)

------------------
-- Martial Arts --
------------------

-- Unarmed strikes (fists, item type 28) and monk weapons (simple melee weapons and martial weapons
-- with the Light property) can use Dexterity.
-- Fists and other hand-to-hand weapons (item type 28).
local function isFist(item)
	return item.pRes.pHeader.itemType == 28
end

B24.AddFinesseListener(function(sprite, item)
	if B24MO.Level(sprite) <= 0 or wearsArmorOrShield(sprite) then return false end
	if isFist(item) then return true end
	local info = B24.WeaponInfo(item.pRes.pHeader.proficiencyType)
	return info ~= nil and (info.CATEGORY == "SIMPLE" or info.LIGHT == "1")
end)

-- Unarmored Defense: AC 10 + Dexterity + Wisdom without armor or shield.
B24.AddStatListener(function(sprite)
	if B24MO.Level(sprite) <= 0 or wearsArmorOrShield(sprite) then return end
	local stats = sprite:getActiveStats()
	stats.m_nArmorClass = stats.m_nArmorClass - B24.AbilityMod(stats.m_nWIS)
end)

-------------------
-- Focus actions --
-------------------

-- op402 entry points of the Focus innates.
function B24FLURY(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not spendFocus(sprite, 1) then return end
		local extra = B24MO.Level(sprite) >= 10 and 2 or 1
		B24.ApplyEffect(sprite, { ["effectID"] = 1, ["effectAmount"] = extra, ["dwFlags"] = 0,
			["durationType"] = 0, ["duration"] = 6 })
		B24.SetTimed(sprite, "FLURRY", 6)
		B24.Log(string.format("%s: Flurry of Blows (+%d attacks, %d Focus left)", B24.Name(sprite), extra,
			B24LV.Remaining(sprite, "FOCUS")))
	end)
end

function B24PDEF(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not spendFocus(sprite, 1) then return end
		B24.SetTimed(sprite, "GRANTS_DIS", 6)
		B24.Log(string.format("%s: Patient Defense", B24.Name(sprite)))
	end)
end

function B24STEPW(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not spendFocus(sprite, 1) then return end
		B24RD.GrantMovement(sprite)
		-- Dash and Disengage: no Opportunity Attacks this round (B24TURN.lua).
		B24.SetTimed(sprite, "DISENGAGE", 6)
		B24.ApplyEffect(sprite, { ["effectID"] = 176, ["effectAmount"] = 200, ["dwFlags"] = 5,
			["durationType"] = 0, ["duration"] = 6 })
		B24.Log(string.format("%s: Step of the Wind", B24.Name(sprite)))
	end)
end

-- Stunning Strike: the next hit this round forces a Constitution save (DC 8 + Wisdom + PB) or
-- stuns the target for a round; on a success its speed is halved and the next attack against it
-- has advantage.
function B24STUN(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not spendFocus(sprite, 1) then return end
		B24.SetTimed(sprite, "STUNNING_STRIKE", 6)
		B24.Log(string.format("%s readies a Stunning Strike", B24.Name(sprite)))
	end)
end

-- Uncanny Metabolism: regain all Focus Points and heal Martial Arts die + Monk level.
function B24UMETA(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "UNCANNY_METABOLISM")
		sprite:setLocalInt("B24FPUSE", 0)
		refreshFocus(sprite)
		local healed = B24.Roll(B24MO.Die(sprite)) + B24MO.Level(sprite)
		B24.Heal(sprite, healed)
		B24.Log(string.format("%s: Uncanny Metabolism, %d hit points, Focus restored", B24.Name(sprite), healed))
	end)
end

-- Wholeness of Body: heal Martial Arts die + Wisdom modifier.
function B24WHOLE(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "WHOLENESS")
		local healed = math.max(1, B24.Roll(B24MO.Die(sprite)) + B24.AbilityModOf(sprite, "WIS"))
		B24.Heal(sprite, healed)
		B24.Log(string.format("%s: Wholeness of Body, %d hit points", B24.Name(sprite), healed))
	end)
end

-- Superior Defense: resistance to all damage but force for a minute.
function B24SUPDF(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not spendFocus(sprite, 3) then return end
		for _, opcode in ipairs({ 27, 28, 29, 30, 31, 86, 87, 88, 89, 173 }) do
			B24.ApplyEffect(sprite, { ["effectID"] = opcode, ["effectAmount"] = 50, ["dwFlags"] = 0,
				["durationType"] = 0, ["duration"] = 60 })
		end
		B24.Log(string.format("%s: Superior Defense", B24.Name(sprite)))
	end)
end

-- Quivering Palm (touch): Constitution save or 10d12 force damage, half on a success.
function B24QPALM(op402, target)
	EEex_Utility_TryIgnore(function()
		local monk = B24.GetSprite(op402.m_sourceId)
		if monk == nil or not spendFocus(monk, 4) then return end
		local dc = 8 + B24.AbilityModOf(monk, "WIS") + B24.ProfOf(monk)
		local damage = 0
		for i = 1, 10 do damage = damage + B24.Roll(12) end
		if B24.RollSave(target, "CON", dc, nil, " (Quivering Palm)") then damage = math.floor(damage / 2) end
		B24.ApplyEffect(target, { ["effectID"] = 12, ["effectAmount"] = damage, ["dwFlags"] = 0x400000,
			["sourceID"] = monk.m_id })
		B24.Log(string.format("%s: Quivering Palm, %d damage", B24.Name(monk), damage))
	end)
end

------------------------------
-- Hits: strikes and Topple --
------------------------------

table.insert(B24WPN.DamageListeners, function(context)
	local monk, target = context.attacker, context.target
	if B24MO.Level(monk) <= 0 then return end
	if B24.HasTimed(monk, "STUNNING_STRIKE") then
		B24.ClearTimed(monk, "STUNNING_STRIKE")
		local dc = 8 + B24.AbilityModOf(monk, "WIS") + B24.ProfOf(monk)
		if B24.RollSave(target, "CON", dc, nil, " (Stunning Strike)") then
			B24.ApplyEffect(target, { ["effectID"] = 176, ["effectAmount"] = 50, ["dwFlags"] = 5,
				["durationType"] = 0, ["duration"] = 6, ["sourceID"] = monk.m_id })
			B24.SetTimed(target, "GRANTS_ADV", 6)
		else
			B24.ApplyEffect(target, { ["effectID"] = 45, ["durationType"] = 0, ["duration"] = 6, ["sourceID"] = monk.m_id })
			B24.Log(string.format("%s is stunned", B24.Name(target)))
		end
	end
	-- Open Hand Technique: Flurry of Blows hits knock the target prone (Dexterity save).
	if B24.HasTimed(monk, "FLURRY") and isOpenHand(monk) and B24MO.Level(monk) >= 3 then
		local dc = 8 + B24.AbilityModOf(monk, "WIS") + B24.ProfOf(monk)
		if not B24.RollSave(target, "DEX", dc, nil, " (Open Hand Technique)") then
			B24.KnockProne(target, monk)
			B24.Log(string.format("%s is knocked prone", B24.Name(target)))
		end
	end
end)

-- Deflect Attacks: once per round, a weapon hit against the Monk loses 1d10 + Dexterity + Monk
-- level damage.
table.insert(B24WPN.DamageListeners, function(context)
	local monk = context.target
	local level = B24MO.Level(monk)
	if level < 3 then return end
	local aux = B24.Aux(monk)
	local now = B24.GameTick()
	if aux.B24_DeflectTick and now - aux.B24_DeflectTick < 90 then return end
	aux.B24_DeflectTick = now
	local effect = context.effect
	B24WPN.RollDiceInto(effect)
	local reduction = B24.Roll(10) + B24.AbilityModOf(monk, "DEX") + level
	effect.m_effectAmount = math.max(0, effect.m_effectAmount - reduction)
	B24.Log(string.format("%s deflects %d damage", B24.Name(monk), reduction))
end)

--------------------------------------------
-- Evasion, Disciplined Survivor --
--------------------------------------------

B24.AddEvasionListener(function(sprite) return B24MO.Level(sprite) >= 7 end)

B24.AddSaveProficiencyListener(function(sprite) return B24MO.Level(sprite) >= 14 end)

B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if B24MO.Level(sprite) < 14 or not B24.InParty(sprite) or not spendFocus(sprite, 1) then return nil end
	local roll = B24.Roll(20)
	B24.Log(string.format("%s: Disciplined Survivor, rerolls the %s save: %d", B24.Name(sprite), ability, roll + mod))
	return roll + mod
end)
