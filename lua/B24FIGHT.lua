-- BG 2024 Rules Mod: the 2024 Fighter (Fighter component), with the Champion subclass (the SRD
-- Fighter subclass, which companions take automatically). The other subclasses are in B24XFIG.lua.
--
--   1  Fighting Style, Second Wind, Weapon Mastery (3; 4 at 4, 5 at 10, 6 at 16)
--   2  Action Surge (2 uses at 17), Tactical Mind (no ability checks in BG: no effect)
--   3  Champion: Improved Critical (19-20), Remarkable Athlete (no initiative in BG: no effect)
--   4, 6, 8, 12, 14, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Extra Attack (engine table), Tactical Shift
--   7  Champion: Additional Fighting Style
--   9  Indomitable (2 uses at 13, 3 at 17), Tactical Master
--   10 Champion: Heroic Warrior
--   11 Two Extra Attacks; 20 Three Extra Attacks
--   13 Studied Attacks
--   15 Champion: Superior Critical (18-20)
--   18 Champion: Survivor
--
-- Locals: B24SWUSE (Second Wind uses spent), B24ASUSE (Action Surge), B24INUSE (Indomitable),
-- B24TMST (Tactical Master property: 0 none, 1 Push, 2 Sap, 3 Slow).

B24FI = {}

function B24FI.Level(sprite)
	return B24LV.ClassLevel(sprite, "FIGHTER")
end

-- The SRD subclass comes first: companions without a choice take it.
B24LV.AddSubclasses("FIGHTER", 3, {
	{ key = "CHAMPION", name = "Champion",
	  desc = "A Champion pursues physical excellence in combat.\n\nLevel 3: Improved Critical (critical hits on 19-20), Remarkable Athlete (no BG effect).\nLevel 7: Additional Fighting Style.\nLevel 10: Heroic Warrior (Heroic Inspiration every round in combat).\nLevel 15: Superior Critical (critical hits on 18-20).\nLevel 18: Survivor (regain hit points each round while bloodied).",
	  features = { [3] = "Improved Critical (critical hits on 19-20)", [7] = "Additional Fighting Style", [10] = "Heroic Warrior",
		[15] = "Superior Critical (critical hits on 18-20)", [18] = "Survivor" } },
})

function B24FI.IsChampion(sprite)
	return B24LV.Subclass(sprite, "FIGHTER") == "CHAMPION"
end

B24FI.FEATURES = {
	[1] = "Fighting Style, Second Wind (2 uses), Weapon Mastery (3 weapons)",
	[2] = "Action Surge (1 use per short rest), Tactical Mind (no BG effect)",
	[3] = "Subclass",
	[4] = "Ability Score Improvement, Weapon Mastery (4 weapons), Second Wind (3 uses)",
	[5] = "Extra Attack (2 attacks), Tactical Shift",
	[6] = "Ability Score Improvement",
	[8] = "Ability Score Improvement",
	[9] = "Indomitable (1 use), Tactical Master",
	[10] = "Weapon Mastery (5 weapons), Second Wind (4 uses)",
	[11] = "Two Extra Attacks (3 attacks)",
	[12] = "Ability Score Improvement",
	[13] = "Studied Attacks, Indomitable (2 uses)",
	[14] = "Ability Score Improvement",
	[16] = "Ability Score Improvement, Weapon Mastery (6 weapons)",
	[17] = "Action Surge (2 uses), Indomitable (3 uses)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Three Extra Attacks (4 attacks)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24FI.Level(sprite)
	local from = B24LV.AppliedClassLevel(sprite, "FIGHTER")
	local lines = {}
	for l = from + 1, level do
		if B24FI.FEATURES[l] then table.insert(lines, string.format("Fighter %d: %s", l, B24FI.FEATURES[l])) end
	end
	return lines
end)

local function atLeast(sprite, level)
	return B24FI.Level(sprite) >= level
end

B24LV.AddResource("SECOND_WIND", { spell = "B24SWIND", localName = "B24SWUSE", shortRest = "one",
	max = function(sprite)
		local level = B24FI.Level(sprite)
		return level >= 10 and 4 or level >= 4 and 3 or level >= 1 and 2 or 0
	end })

B24LV.AddResource("ACTION_SURGE", { spell = "B24ASURG", localName = "B24ASUSE", shortRest = "all",
	max = function(sprite)
		local level = B24FI.Level(sprite)
		return level >= 17 and 2 or level >= 2 and 1 or 0
	end })

B24LV.AddResource("INDOMITABLE", { localName = "B24INUSE",
	max = function(sprite)
		local level = B24FI.Level(sprite)
		return level >= 17 and 3 or level >= 13 and 2 or level >= 9 and 1 or 0
	end })

-- Weapon Mastery grows with Fighter level.
local originalMasteryCount = B24.MasteryCount
function B24.MasteryCount(sprite)
	local level = B24FI.Level(sprite)
	if level > 0 then
		return math.max(originalMasteryCount(sprite), level >= 16 and 6 or level >= 10 and 5 or level >= 4 and 4 or 3)
	end
	return originalMasteryCount(sprite)
end

B24FI.ASI_LEVELS = { 4, 6, 8, 12, 14, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24FI.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24FI.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, STYLE = (level >= 7 and B24FI.IsChampion(sprite)) and 2 or 1, MASTERY = B24.MasteryCount(sprite) }
end)

-- Passive features for the current level.
B24LV.AddApplyListener(function(sprite)
	local level = B24FI.Level(sprite)
	if level <= 0 then return end
	-- Champion: critical hits on 19-20, and 18-20 from level 15.
	local champion = B24FI.IsChampion(sprite)
	local critical = champion and ((level >= 15 and 2) or 1) or 0
	if critical > 0 then
		B24LV.Permanent(sprite, { ["effectID"] = 301, ["effectAmount"] = critical })
	end
	-- Two and Three Extra Attacks (Extra Attack at 5 comes from the engine's attack table).
	local extra = (level >= 20 and 2) or (level >= 11 and 1) or 0
	if extra > 0 then
		B24LV.Permanent(sprite, { ["effectID"] = 1, ["effectAmount"] = extra, ["dwFlags"] = 0 })
	end
	B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = "B24TMAST" })
	if level >= 9 then
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = "B24TMAST" })
	end
end)

-----------------
-- Second Wind --
-----------------

-- op402 entry point of B24SWIND.SPL: regain 1d10 + Fighter level hit points; Tactical Shift
-- (level 5) adds a round of faster movement.
function B24SWIND(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "SECOND_WIND")
		local level = B24FI.Level(sprite)
		local healed = B24.Roll(10) + level
		B24.Heal(sprite, healed)
		if level >= 5 then
			B24.ApplyEffect(sprite, { ["effectID"] = 176, ["effectAmount"] = 150, ["dwFlags"] = 5,
				["durationType"] = 0, ["duration"] = 6 })
		end
		B24.Log(string.format("%s: Second Wind, %d hit points (%d left)", B24.Name(sprite), healed,
			B24LV.Remaining(sprite, "SECOND_WIND")))
	end)
end

------------------
-- Action Surge --
------------------

-- op402 entry point of B24ASURG.SPL: one more round of attacks (as many as the Fighter makes).
-- In turn-based combat the turn gives the extra action itself (B24TURN.lua): no extra attacks then,
-- or the surge would count twice.
function B24ASURG(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "ACTION_SURGE")
		if B24TB and B24TB.InTurns(sprite) then
			B24.Log(string.format("%s: Action Surge, one more action this turn", B24.Name(sprite)))
			return
		end
		local level = B24FI.Level(sprite)
		local attacks = 1 + (level >= 5 and 1 or 0) + (level >= 11 and 1 or 0) + (level >= 20 and 1 or 0)
		B24.ApplyEffect(sprite, { ["effectID"] = 1, ["effectAmount"] = attacks, ["dwFlags"] = 0,
			["durationType"] = 0, ["duration"] = 6 })
		B24.ApplyEffect(sprite, { ["effectID"] = 189, ["effectAmount"] = 5, ["dwFlags"] = 0,
			["durationType"] = 0, ["duration"] = 6 })
		B24.Log(string.format("%s: Action Surge, +%d attacks this round", B24.Name(sprite), attacks))
	end)
end

-----------------
-- Indomitable --
-----------------

B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	local level = B24FI.Level(sprite)
	if level < 9 or not B24.InParty(sprite) or not B24LV.Use(sprite, "INDOMITABLE") then return nil end
	local roll = B24.Roll(20)
	local newTotal = roll + mod + level
	B24.Log(string.format("%s: Indomitable, rerolls the %s save: %d (%d%+d%+d)", B24.Name(sprite), ability,
		newTotal, roll, mod, level))
	return newTotal
end)

---------------------
-- Tactical Master --
---------------------

B24FI.TACTICAL = { "PUSH", "SAP", "SLOW" }

-- op402 entry point of B24TMAST.SPL: cycles the property mastered weapons use (own, Push, Sap, Slow).
function B24TMAST(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local mode = (sprite:getLocalInt("B24TMST") + 1) % 4
		sprite:setLocalInt("B24TMST", mode)
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = "B24TMAST" })
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = "B24TMAST" })
		local name = B24FI.TACTICAL[mode]
		B24.Log(string.format("%s: Tactical Master, mastered weapons use %s", B24.Name(sprite),
			name and (name:sub(1, 1) .. name:sub(2):lower()) or "their own property"))
	end)
end

table.insert(B24WPN.PropertyOverrideListeners, function(attacker)
	if B24FI.Level(attacker) < 9 then return nil end
	return B24FI.TACTICAL[attacker:getLocalInt("B24TMST")]
end)

---------------------
-- Studied Attacks --
---------------------

-- After a miss, advantage on the next attack against that target (like Vex).
table.insert(B24WPN.MissListeners, function(attacker, target)
	if B24FI.Level(attacker) < 13 then return end
	B24.Aux(attacker).B24_Vex = { target = target.m_id, untilTick = B24.GameTick() + 90 }
	B24.ApplyEffect(attacker, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 0 })
end)

------------------------------------------
-- Champion: Heroic Warrior, Survivor --
------------------------------------------

local function inCombat(sprite)
	local enemies = EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[ENEMY]", 400, true)
	return enemies ~= nil and #enemies > 0
end

-- Heroic Warrior: Heroic Inspiration at the start of each round in combat; Survivor: regain
-- 5 + Constitution modifier hit points each round while bloodied (half hit points or fewer).
B24LV.AddTickListener(function(sprite)
	local level = B24FI.Level(sprite)
	if level < 10 or not B24FI.IsChampion(sprite) or B24.GState_Has(sprite, B24.GState.DEAD) then return end
	local aux = B24.Aux(sprite)
	local now = B24.GameTick()
	if aux.B24_ChampionRound and now - aux.B24_ChampionRound < 90 then return end
	if not inCombat(sprite) then return end
	aux.B24_ChampionRound = now
	if not B24.Inspiration_Has(sprite) then B24.Inspiration_Grant(sprite) end
	if level >= 18 then
		local hp, max = sprite.m_baseStats.m_hitPoints, sprite:getStat(B24.Stat.MAXHP)
		if hp > 0 and hp <= max / 2 then
			local healed = math.max(1, 5 + B24.AbilityModOf(sprite, "CON"))
			B24.Heal(sprite, healed)
			B24.Log(string.format("%s: Survivor, %d hit points", B24.Name(sprite), healed))
		end
	end
end)
