-- BG 2024 Rules Mod: the 2024 Rogue with the Thief (SRD subclass), in BG the Thief class. BG's
-- backstab multiplier is removed at install time; Sneak Attack replaces it.
--
--   1  Expertise (character creation), Sneak Attack (1d6 per two levels), Thieves' Cant (no
--      BG effect), Weapon Mastery (2)
--   2  Cunning Action (in BG: Dash and Disengage for the round: faster, no Opportunity Attacks)
--   3  Subclass: Thief (Fast Hands, Second-Story Work: no BG effect), Steady Aim
--   4, 8, 10, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Uncanny Dodge, Cunning Strike (Poison, Trip, Withdraw; see below)
--   6  Expertise (two more)
--   7  Evasion, Reliable Talent (BG skills are passive: no extra effect)
--   9  Thief: Supreme Sneak (Stealth +5, as advantage)
--   11 Improved Cunning Strike (two effects), 14 Devious Strikes (Daze, Knock Out, Obscure)
--   13 Thief: Use Magic Device (use any item), 17 Thief's Reflexes (improved haste in the
--      first round of a fight)
--   15 Slippery Mind (Wisdom and Charisma save proficiency)
--   18 Elusive
--   20 Stroke of Luck
--
-- Locals: B24SLUSE (Stroke of Luck).

B24RO = {}

function B24RO.Level(sprite)
	return B24LV.ClassLevel(sprite, "ROGUE")
end

B24LV.AddSubclasses("ROGUE", 3, {
	{ key = "THIEF", name = "Thief",
	  desc = "Thieves hone their skills in larceny and agility.\n\nLevel 3: Fast Hands, Second-Story Work (no BG effect).\nLevel 9: Supreme Sneak (Stealth +5, standing in for advantage).\nLevel 13: Use Magic Device (you can use any magic item, scrolls included, whatever its class or species limits).\nLevel 17: Thief's Reflexes (in the first round of a fight you are improved-hasted: twice the attacks).",
	  features = { [3] = "Fast Hands, Second-Story Work (no BG effect)", [9] = "Supreme Sneak", [13] = "Use Magic Device", [17] = "Thief's Reflexes" } },
})

local function isThief(sprite)
	return B24LV.Subclass(sprite, "ROGUE") == "THIEF"
end

B24LV.AddResource("STROKE_OF_LUCK", { localName = "B24SLUSE", shortRest = "all",
	max = function(sprite) return B24RO.Level(sprite) >= 20 and 1 or 0 end })

B24RO.ASI_LEVELS = { 4, 8, 10, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24RO.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24RO.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, MASTERY = B24.MasteryCount(sprite), EXPERTISE = level >= 6 and 2 or 0 }
end)

B24RO.FEATURES = {
	[1] = "Expertise, Sneak Attack (1d6), Weapon Mastery (2 weapons)",
	[2] = "Cunning Action",
	[3] = "Subclass, Steady Aim, Sneak Attack (2d6)",
	[4] = "Ability Score Improvement",
	[5] = "Uncanny Dodge, Cunning Strike, Sneak Attack (3d6)",
	[6] = "Expertise (two more skills)",
	[7] = "Evasion, Reliable Talent, Sneak Attack (4d6)",
	[8] = "Ability Score Improvement",
	[9] = "Sneak Attack (5d6)",
	[10] = "Ability Score Improvement",
	[11] = "Improved Cunning Strike (two effects), Sneak Attack (6d6)",
	[12] = "Ability Score Improvement",
	[13] = "Sneak Attack (7d6)",
	[14] = "Devious Strikes (Daze, Knock Out, Obscure)",
	[15] = "Slippery Mind (Wisdom and Charisma saves), Sneak Attack (8d6)",
	[16] = "Ability Score Improvement",
	[17] = "Sneak Attack (9d6)",
	[18] = "Elusive",
	[19] = "Epic Boon (an Epic Boon feat or another feat), Sneak Attack (10d6)",
	[20] = "Stroke of Luck",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24RO.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "ROGUE") + 1, level do
		if B24RO.FEATURES[l] then table.insert(lines, string.format("Rogue %d: %s", l, B24RO.FEATURES[l])) end
	end
	return lines
end)

B24LV.AddApplyListener(function(sprite)
	local level = B24RO.Level(sprite)
	if level <= 0 then return end
	for _, entry in ipairs({ { 2, "B24CUNNG" }, { 3, "B24STAIM" } }) do
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = entry[2] })
		if level >= entry[1] then B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = entry[2] }) end
	end
end)

------------------
-- Sneak Attack --
------------------

-- Once per round, with a finesse or ranged weapon, when the attack has advantage or another
-- party member stands next to the target (and the attack has no disadvantage).
local function allyNextTo(attacker, target)
	for _, member in ipairs(B24.Party()) do
		if member.m_id ~= attacker.m_id and not B24.GState_Has(member, B24.GState.DEAD) then
			local near = EEex_Sprite_GetAllOfTypeStringInRange(member, "[ENEMY]", B24.ADJACENT, true) or {}
			for _, enemy in ipairs(near) do
				if enemy.m_id == target.m_id then return true end
			end
		end
	end
	return false
end

local function finesseOrRanged(context)
	if context.launcher then return true end
	local weapon = context.weapon
	local info = weapon and B24.WeaponInfo(weapon.pRes.pHeader.proficiencyType)
	if info and info.FINESSE == "1" then return true end
	local ability = context.ability
	return ability ~= nil and ability.type == 2
end

table.insert(B24WPN.DamageListeners, function(context)
	local attacker, target = context.attacker, context.target
	local level = B24RO.Level(attacker)
	if level <= 0 or not finesseOrRanged(context) then return end
	local aux = B24.Aux(attacker)
	local now = B24.GameTick()
	if aux.B24_SneakTick and now - aux.B24_SneakTick < 90 then return end
	local advantage = B24.AttackerHasAdvantage(attacker) or B24.TargetGrantsAdvantage(target)
		or B24.AttackerHasAdvantageAgainst(attacker, target)
	local disadvantage = B24.AttackerHasDisadvantage(attacker) or B24.TargetGrantsDisadvantage(target)
		or B24.AttackerHasDisadvantageAgainst(attacker, target)
	if not ((advantage and not disadvantage) or (not disadvantage and allyNextTo(attacker, target))) then return end
	aux.B24_SneakTick = now
	local dice = math.ceil(level / 2) * (context.isCritical and 2 or 1)
	-- Cunning Strike (5): readied effects take their dice first.
	local chosen = {}
	if level >= 5 and B24RO.TakeCunning then dice, chosen = B24RO.TakeCunning(attacker, dice) end
	local total = 0
	for i = 1, dice do total = total + B24.Roll(6) end
	context.effect.m_effectAmount = context.effect.m_effectAmount + total
	B24.Log(string.format("%s: Sneak Attack %dd6 = %d", B24.Name(attacker), dice, total))
	if #chosen > 0 then B24RO.ApplyCunning(attacker, target, chosen) end
end)

-------------------------------
-- Cunning Action, Steady Aim --
-------------------------------

local function regrant(sprite, res)
	B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = res })
	B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = res })
end

-- op402 entry point of B24CUNNG.SPL: Dash and Disengage, faster movement and no Opportunity Attacks
-- for a round. Usable every round.
function B24CUNNG(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24RD.GrantMovement(sprite)
		-- Dash and Disengage: no Opportunity Attacks this round (B24TURN.lua).
		B24.SetTimed(sprite, "DISENGAGE", 6)
		B24.ApplyEffect(sprite, { ["effectID"] = 176, ["effectAmount"] = 200, ["dwFlags"] = 5,
			["durationType"] = 0, ["duration"] = 6 })
		regrant(sprite, "B24CUNNG")
	end)
end

-- op402 entry point of B24STAIM.SPL: advantage on the next attack this round; you stand still.
function B24STAIM(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24.SetTimed(sprite, "ATTACK_ADV", 6)
		B24.ApplyEffect(sprite, { ["effectID"] = 176, ["effectAmount"] = 0, ["dwFlags"] = 5,
			["durationType"] = 0, ["duration"] = 2 })
		regrant(sprite, "B24STAIM")
		B24.Log(string.format("%s takes steady aim", B24.Name(sprite)))
	end)
end

-------------------
-- Uncanny Dodge --
-------------------

-- Once per round, the first weapon hit against the Rogue deals half damage.
table.insert(B24WPN.DamageListeners, function(context)
	local target = context.target
	if B24RO.Level(target) < 5 then return end
	local aux = B24.Aux(target)
	local now = B24.GameTick()
	if aux.B24_DodgeTick and now - aux.B24_DodgeTick < 90 then return end
	aux.B24_DodgeTick = now
	local effect = context.effect
	B24WPN.RollDiceInto(effect)
	effect.m_effectAmount = math.floor(effect.m_effectAmount / 2)
	B24.Log(string.format("%s: Uncanny Dodge halves the damage", B24.Name(target)))
end)

---------------------------------------------
-- Evasion, Slippery Mind, Elusive, Luck --
---------------------------------------------

B24.AddEvasionListener(function(sprite) return B24RO.Level(sprite) >= 7 end)

B24.AddSaveProficiencyListener(function(sprite, ability)
	return B24RO.Level(sprite) >= 15 and (ability == "WIS" or ability == "CHA")
end)

table.insert(B24.NoAdvantageAgainstListeners, function(sprite)
	return B24RO.Level(sprite) >= 18 and not B24.GState_Has(sprite, B24.GState.HELPLESS)
end)

-- Stroke of Luck: a failed save becomes a success once per short rest.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if B24RO.Level(sprite) < 20 or not B24LV.Use(sprite, "STROKE_OF_LUCK") then return nil end
	B24.Log(string.format("%s: Stroke of Luck turns the %s save into a success", B24.Name(sprite), ability))
	return dc
end)

-- Supreme Sneak: Stealth +5 for the Thief, standing in for advantage.
B24.AddSkillBonusListener(function(sprite, key)
	if key == "STEALTH" and B24RO.Level(sprite) >= 9 and isThief(sprite) then return 5 end
	return 0
end)

--------------------
-- Cunning Strike --
--------------------

-- Cunning Strike (5): the options are innates that ready an effect for the next Sneak Attack,
-- which gives up dice for it (DC 8 + Dexterity modifier + proficiency bonus). One option per Sneak
-- Attack; two from 11 (Improved Cunning Strike); Devious Strikes adds three options at 14.
B24RO.CUNNING = {
	{ key = "POISON", res = "B24RCPOI", name = "Poison", dice = 1, level = 5,
	  apply = function(target, rogue, dc)
		if not B24.RollSave(target, "CON", dc, nil, " (Cunning Strike: Poison)") then
			B24.ApplyEffect(target, { ["effectID"] = 25, ["effectAmount"] = 0, ["dwFlags"] = 0, ["durationType"] = 0,
				["duration"] = 60, ["sourceID"] = rogue.m_id })
			return "poisoned"
		end
	  end },
	{ key = "TRIP", res = "B24RCTRP", name = "Trip", dice = 1, level = 5,
	  apply = function(target, rogue, dc)
		if not B24.RollSave(target, "DEX", dc, nil, " (Cunning Strike: Trip)") then
			B24.KnockProne(target, rogue)
			return "prone"
		end
	  end },
	{ key = "WITHDRAW", res = "B24RCWTH", name = "Withdraw", dice = 1, level = 5,
	  apply = function(target, rogue)
		if B24RD and B24RD.GrantMovement then B24RD.GrantMovement(rogue) end
		return "the rogue withdraws"
	  end },
	{ key = "DAZE", res = "B24RCDAZ", name = "Daze", dice = 2, level = 14,
	  apply = function(target, rogue, dc)
		if not B24.RollSave(target, "CON", dc, nil, " (Devious Strikes: Daze)") then
			-- Only a move or an action next turn: in BG, slowed for a round.
			B24.ApplyEffect(target, { ["effectID"] = 40, ["durationType"] = 0, ["duration"] = 6, ["sourceID"] = rogue.m_id })
			return "dazed"
		end
	  end },
	{ key = "KNOCKOUT", res = "B24RCKNO", name = "Knock Out", dice = 6, level = 14,
	  apply = function(target, rogue, dc)
		if not B24.RollSave(target, "CON", dc, nil, " (Devious Strikes: Knock Out)") then
			-- Unconscious for a minute; damage wakes it (op39 type 0).
			B24.ApplyEffect(target, { ["effectID"] = 39, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60,
				["sourceID"] = rogue.m_id })
			return "knocked out"
		end
	  end },
	{ key = "OBSCURE", res = "B24RCOBS", name = "Obscure", dice = 3, level = 14,
	  apply = function(target, rogue, dc)
		if not B24.RollSave(target, "DEX", dc, nil, " (Devious Strikes: Obscure)") then
			B24.ApplyEffect(target, { ["effectID"] = 74, ["durationType"] = 0, ["duration"] = 6, ["sourceID"] = rogue.m_id })
			return "blinded"
		end
	  end },
}

local function cunningPerAttack(sprite) return B24RO.Level(sprite) >= 11 and 2 or 1 end

function B24RO.RefreshCunning(sprite)
	local level = B24RO.Level(sprite)
	for _, option in ipairs(B24RO.CUNNING) do B24LV.Grant(sprite, option.res, level >= option.level) end
end

B24LV.AddApplyListener(function(sprite) B24RO.RefreshCunning(sprite) end)

for _, option in ipairs(B24RO.CUNNING) do
	_G[option.res] = function(op402, sprite)
		EEex_Utility_TryIgnore(function()
			local aux = B24.Aux(sprite)
			local ready = {}
			for _, key in ipairs(aux.B24_Cunning or {}) do
				if key ~= option.key then table.insert(ready, key) end
			end
			while #ready >= cunningPerAttack(sprite) do table.remove(ready, 1) end
			table.insert(ready, option.key)
			aux.B24_Cunning = ready
			-- At will: the innate comes back at once.
			B24LV.Grant(sprite, option.res, true)
			B24.Log(string.format("%s readies Cunning Strike: %s", B24.Name(sprite), option.name))
		end)
	end
end

local function cunningOption(key)
	for _, option in ipairs(B24RO.CUNNING) do
		if option.key == key then return option end
	end
end

-- Called by Sneak Attack with its dice; returns the dice left to roll and the readied effects.
function B24RO.TakeCunning(rogue, dice)
	local aux = B24.Aux(rogue)
	local chosen = {}
	for _, key in ipairs(aux.B24_Cunning or {}) do
		local option = cunningOption(key)
		if option and option.dice <= dice and B24RO.Level(rogue) >= option.level then
			dice = dice - option.dice
			table.insert(chosen, option)
		end
	end
	aux.B24_Cunning = nil
	return dice, chosen
end

function B24RO.ApplyCunning(rogue, target, chosen)
	local dc = 8 + B24.AbilityModOf(rogue, "DEX") + B24.ProfOf(rogue)
	for _, option in ipairs(chosen) do
		local result = option.apply(target, rogue, dc)
		B24.Log(string.format("%s: Cunning Strike %s%s", B24.Name(rogue), option.name, result and (" - " .. result) or " - saved"))
	end
end

-------------------------------------------------
-- Use Magic Device, Thief's Reflexes (Thief) --
-------------------------------------------------

-- Use Magic Device (Thief 13): the engine's "use any item" (op302): no class or species limits on
-- magic items, spell scrolls included. (The d6 to keep an item's charge has no BG hook.)
B24LV.AddApplyListener(function(sprite)
	if B24RO.Level(sprite) >= 13 and isThief(sprite) then
		B24LV.Permanent(sprite, { ["effectID"] = 302, ["dwFlags"] = 0 })
	end
end)

-- Thief's Reflexes (Thief 17): two turns in the first round of a fight; in BG, improved haste
-- (twice the attacks, faster) for that round.
B24.AddCombatStartListener(function(sprite)
	if B24RO.Level(sprite) < 17 or not isThief(sprite) then return end
	B24.ApplyEffect(sprite, { ["effectID"] = 16, ["dwFlags"] = 1, ["durationType"] = 0, ["duration"] = 6 })
	B24.Log(string.format("%s: Thief's Reflexes", B24.Name(sprite)))
end)
