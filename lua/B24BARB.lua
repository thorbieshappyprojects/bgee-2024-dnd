-- BG 2024 Rules Mod: the 2024 Barbarian with the Path of the Berserker (SRD subclass), in BG the
-- Fighter class with the Barbarian kit (its 2e kit abilities are removed at install time).
--
--   1  Rage (2 uses; 3 at 3, 4 at 6, 5 at 12, 6 at 17), Unarmored Defense, Weapon Mastery (2;
--      3 at 4, 4 at 10)
--   2  Danger Sense, Reckless Attack
--   3  Primal Knowledge (no BG effect), subclass: Berserker Frenzy
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Extra Attack (engine table), Fast Movement
--   6  Berserker: Mindless Rage
--   7  Feral Instinct, Instinctive Pounce (no initiative in BG: no effect)
--   9  Brutal Strike (2d10 at 17); rage damage +3 (+4 at 16)
--   10 Berserker: Retaliation (no reactions in BG: no effect)
--   11 Relentless Rage
--   14 Berserker: Intimidating Presence
--   15 Persistent Rage, 18 Indomitable Might (no BG effect)
--   20 Primal Champion
--
-- Locals: B24RGUSE (rages spent), B24IPUSE (Intimidating Presence).

B24BA = {}

B24BA.RAGE_SECONDS = 60

-- listener(sprite) runs when the Barbarian starts raging (subclass features).
B24BA.RageListeners = {}

function B24BA.Level(sprite)
	return B24LV.ClassLevel(sprite, "BARBARIAN")
end

function B24BA.IsRaging(sprite)
	return B24.HasTimed(sprite, "RAGE")
end

function B24BA.RageDamage(sprite)
	local level = B24BA.Level(sprite)
	return level >= 16 and 4 or level >= 9 and 3 or 2
end

B24LV.AddSubclasses("BARBARIAN", 3, {
	{ key = "BERSERKER", name = "Path of the Berserker",
	  desc = "Berserkers channel their rage into violent fury.\n\nLevel 3: Frenzy (while raging, Reckless Attack adds d6s equal to your rage damage to your first hit each round).\nLevel 6: Mindless Rage (immune to being charmed or frightened while raging).\nLevel 10: Retaliation (no reactions in BG: no effect).\nLevel 14: Intimidating Presence (enemies around you make a Wisdom save or are frightened, once per long rest).",
	  features = { [3] = "Frenzy", [6] = "Mindless Rage", [10] = "Retaliation (no BG effect)", [14] = "Intimidating Presence" } },
})

local function isBerserker(sprite)
	return B24LV.Subclass(sprite, "BARBARIAN") == "BERSERKER"
end

B24LV.AddResource("RAGE", { spell = "B24RAGE", localName = "B24RGUSE", shortRest = "one",
	max = function(sprite)
		local level = B24BA.Level(sprite)
		return level >= 17 and 6 or level >= 12 and 5 or level >= 6 and 4 or level >= 3 and 3 or level >= 1 and 2 or 0
	end })

B24LV.AddResource("INTIMIDATING_PRESENCE", { spell = "B24INTIM", localName = "B24IPUSE",
	max = function(sprite)
		return (B24BA.Level(sprite) >= 14 and isBerserker(sprite)) and 1 or 0
	end })

local originalMasteryCount = B24.MasteryCount
function B24.MasteryCount(sprite)
	local level = B24BA.Level(sprite)
	if level > 0 then return level >= 10 and 4 or level >= 4 and 3 or 2 end
	return originalMasteryCount(sprite)
end

B24BA.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24BA.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24BA.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, MASTERY = B24.MasteryCount(sprite) }
end)

B24BA.FEATURES = {
	[1] = "Rage (2 uses), Unarmored Defense, Weapon Mastery (2 weapons)",
	[2] = "Danger Sense, Reckless Attack",
	[3] = "Subclass, Rage (3 uses)",
	[4] = "Ability Score Improvement, Weapon Mastery (3 weapons)",
	[5] = "Extra Attack, Fast Movement",
	[6] = "Rage (4 uses)",
	[7] = "Feral Instinct, Instinctive Pounce (no BG effect)",
	[8] = "Ability Score Improvement",
	[9] = "Brutal Strike, rage damage +3",
	[10] = "Weapon Mastery (4 weapons)",
	[11] = "Relentless Rage",
	[12] = "Ability Score Improvement, Rage (5 uses)",
	[16] = "Ability Score Improvement, rage damage +4",
	[17] = "Improved Brutal Strike (2d10), Rage (6 uses)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Primal Champion (Strength and Constitution +4)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24BA.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "BARBARIAN") + 1, level do
		if B24BA.FEATURES[l] then table.insert(lines, string.format("Barbarian %d: %s", l, B24BA.FEATURES[l])) end
	end
	return lines
end)

B24LV.AddApplyListener(function(sprite)
	local level = B24BA.Level(sprite)
	if level <= 0 then return end
	B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = "B24RECKL" })
	if level >= 2 then B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = "B24RECKL" }) end
	if level >= 5 then
		B24LV.Permanent(sprite, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5 }) -- +10 ft
	end
	if level >= 20 then
		B24LV.Permanent(sprite, { ["effectID"] = 44, ["effectAmount"] = 4, ["dwFlags"] = 0 })
		B24LV.Permanent(sprite, { ["effectID"] = 10, ["effectAmount"] = 4, ["dwFlags"] = 0 })
	end
end)

-----------
-- Rage --
-----------

-- op402 entry point of B24RAGE.SPL: one minute of rage.
function B24RAGE(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "RAGE")
		B24.SetTimed(sprite, "RAGE", B24BA.RAGE_SECONDS)
		local timed = function(opcode, amount, param2)
			B24.ApplyEffect(sprite, { ["effectID"] = opcode, ["effectAmount"] = amount, ["dwFlags"] = param2 or 0,
				["durationType"] = 0, ["duration"] = B24BA.RAGE_SECONDS, ["m_sourceRes"] = "B24RAGE" })
		end
		-- Resistance to slashing, bludgeoning (crushing) and piercing damage.
		timed(86, 50)
		timed(87, 50)
		timed(88, 50)
		if B24BA.Level(sprite) >= 6 and isBerserker(sprite) then
			timed(101, 5)  -- Mindless Rage: charm
			timed(101, 24) -- and fear
		end
		if B24BA.Level(sprite) >= 11 then
			B24.Aux(sprite).B24_RelentlessRage = true
			B24.ApplyEffect(sprite, { ["effectID"] = 208, ["effectAmount"] = 1, ["durationType"] = 0,
				["duration"] = B24BA.RAGE_SECONDS, ["m_sourceRes"] = "B24RRAGE" })
		end
		for _, listener in ipairs(B24BA.RageListeners) do EEex_Utility_TryIgnore(listener, sprite) end
		B24.Log(string.format("%s rages (+%d damage, %d rages left)", B24.Name(sprite), B24BA.RageDamage(sprite),
			B24LV.Remaining(sprite, "RAGE")))
	end)
end

-- Rage damage on Strength (melee) attacks; Frenzy and Brutal Strike with Reckless Attack.
table.insert(B24WPN.DamageListeners, function(context)
	local attacker = context.attacker
	if B24BA.Level(attacker) <= 0 or context.launcher then return end
	local effect = context.effect
	if B24BA.IsRaging(attacker) then
		effect.m_effectAmount = effect.m_effectAmount + B24BA.RageDamage(attacker)
	end
	if not B24.HasTimed(attacker, "RECKLESS") then return end
	local aux = B24.Aux(attacker)
	local now = B24.GameTick()
	if aux.B24_RecklessHit and now - aux.B24_RecklessHit < 90 then return end
	aux.B24_RecklessHit = now
	local extra, parts = 0, {}
	if B24BA.IsRaging(attacker) and isBerserker(attacker) then
		local frenzy = 0
		for i = 1, B24BA.RageDamage(attacker) do frenzy = frenzy + B24.Roll(6) end
		extra = extra + frenzy
		table.insert(parts, "Frenzy " .. frenzy)
	end
	if B24BA.Level(attacker) >= 9 then
		local brutal = B24.Roll(10) + (B24BA.Level(attacker) >= 17 and B24.Roll(10) or 0)
		extra = extra + brutal
		table.insert(parts, "Brutal Strike " .. brutal)
	end
	if extra > 0 then
		effect.m_effectAmount = effect.m_effectAmount + extra
		B24.Log(string.format("%s: %s", B24.Name(attacker), table.concat(parts, ", ")))
	end
end)

-- Advantage on Strength saves while raging; Danger Sense: advantage on Dexterity saves.
B24.AddSaveAdvantageListener(function(sprite, ability)
	local level = B24BA.Level(sprite)
	if level <= 0 then return false end
	if ability == "STR" and B24BA.IsRaging(sprite) then return true end
	if ability == "DEX" and level >= 2 then
		local g = B24.GState
		return not (B24.GState_Has(sprite, g.HELPLESS) or B24.GState_Has(sprite, g.STUNNED) or B24.GState_Has(sprite, g.SLEEPING))
	end
	return false
end)

---------------------
-- Reckless Attack --
---------------------

-- op402 entry point of B24RECKL.SPL: advantage on your attacks for a round, attacks against you
-- have advantage too. Usable every round.
function B24RECKL(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24.SetTimed(sprite, "RECKLESS", 6)
		B24.SetTimed(sprite, "ATTACK_ADV", 6)
		B24.SetTimed(sprite, "GRANTS_ADV", 6)
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = "B24RECKL" })
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = "B24RECKL" })
		B24.Log(string.format("%s attacks recklessly", B24.Name(sprite)))
	end)
end

-----------------------
-- Unarmored Defense --
-----------------------

-- AC 10 + Dexterity + Constitution without armor (a shield is allowed).
B24.AddStatListener(function(sprite)
	if B24BA.Level(sprite) <= 0 then return end
	local armor = sprite.m_equipment.m_items:get(1)
	if armor ~= nil and armor.pRes.pHeader.itemType == 2 then return end
	local stats = sprite:getActiveStats()
	stats.m_nArmorClass = stats.m_nArmorClass - B24.AbilityMod(stats.m_nCON)
end)

---------------------
-- Relentless Rage --
---------------------

-- While raging (level 11), op208 keeps the Barbarian at 1 hit point once; the damage hook notices
-- when it caught a hit and ends it for this rage.
local hitPointsBefore = {}
local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
local originalDamageDone = EEex_Sprite_Hook_OnDamageEffectDone

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	if B24.Aux(targetSprite).B24_RelentlessRage then
		hitPointsBefore[targetSprite.m_id] = targetSprite.m_baseStats.m_hitPoints
	end
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)
	originalDamageDone(effect, sourceSprite, targetSprite)
	local before = hitPointsBefore[targetSprite.m_id]
	hitPointsBefore[targetSprite.m_id] = nil
	if before and before > 1 and targetSprite.m_baseStats.m_hitPoints == 1 then
		B24.Aux(targetSprite).B24_RelentlessRage = nil
		-- The rage goes on; only its minimum hit point effect ends.
		B24.RemoveEffectsBySource(targetSprite, "B24RRAGE")
		B24.Log(string.format("%s: Relentless Rage, stays at 1 hit point", B24.Name(targetSprite)))
	end
end

---------------------------
-- Intimidating Presence --
---------------------------

-- op402 entry point of B24INTIM.SPL: enemies within 30 ft make a Wisdom save (DC 8 + Strength
-- modifier + Proficiency Bonus) or are frightened for one minute.
function B24INTIM(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "INTIMIDATING_PRESENCE")
		local dc = 8 + B24.AbilityModOf(sprite, "STR") + B24.ProfOf(sprite)
		for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[ENEMY]", B24.Feet(30), true) or {}) do
			if not B24.RollSave(enemy, "WIS", dc, nil, " (Intimidating Presence)", { FEAR = true }) then
				B24.ApplyEffect(enemy, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 60, ["sourceID"] = sprite.m_id })
			end
		end
	end)
end

-- Relentless Rage catches a drop to 0 before the dying rules (B24DYING.lua).
B24.AddDownSaver(function(sprite) return B24.Aux(sprite).B24_RelentlessRage == true end)
