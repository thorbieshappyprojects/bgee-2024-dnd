-- BG 2024 Rules Mod: Cleric subclasses beyond the SRD (Light Domain, Trickery Domain, War Domain).
-- Feature texts are this mod's own wording. Domain spells are not granted yet (as for Life).
--
-- Light
--   3  Radiance of the Dawn (Channel Divinity: enemies within 30 ft make a Constitution save or
--      take 2d10 + Cleric level radiant damage, half on a success), Warding Flare (Wisdom modifier
--      uses per long rest: attacks against you or an ally have disadvantage for a round)
--   6  Improved Warding Flare (uses return on a short rest; the ally also gains 2d6 + Wisdom
--      modifier temporary hit points)
--   17 Corona of Light (Wisdom modifier uses per long rest: for a minute, enemies within 60 ft
--      have disadvantage on saves against your spells and Channel Divinity)
-- Trickery
--   3  Blessing of the Trickster (an ally gets better at stealth for an hour), Invoke Duplicity
--      (Channel Divinity: for a minute you have advantage on attacks, standing in for the illusory
--      double next to your foes)
--   6  Trickster's Transposition (no BG effect)
--   17 Improved Duplicity (allies also have advantage against enemies next to you while it lasts;
--      when it ends the most hurt ally regains hit points equal to your Cleric level)
-- War
--   3  Guided Strike (Channel Divinity: +10 to your attack rolls this round), War Priest (Wisdom
--      modifier uses per short rest: one extra attack this round)
--   6  War God's Blessing (Channel Divinity: Shield of Faith on a creature, no concentration)
--   17 Avatar of Battle (resistance to bludgeoning, piercing and slashing damage)
--
-- Locals: B24LWUSE (Warding Flare), B24LCUSE (Corona of Light), B24TBUSE (Blessing of the
-- Trickster), B24WPUSE (War Priest).

local function level(sprite) return B24CL.Level(sprite) end
local function wis(sprite) return B24.AbilityModOf(sprite, "WIS") end

local function isLight(sprite, l) return B24LV.Is(sprite, "CLERIC", "LIGHT", l or 3) end
local function isTrickery(sprite, l) return B24LV.Is(sprite, "CLERIC", "TRICKERY", l or 3) end
local function isWar(sprite, l) return B24LV.Is(sprite, "CLERIC", "WAR", l or 3) end

B24LV.AddMoreSubclasses("CLERIC", {
	{ key = "LIGHT", name = "Light Domain",
	  desc = "Your god's light burns away darkness and lies.\n\nLevel 3: Radiance of the Dawn (Channel Divinity: enemies within 30 ft take 2d10 + your Cleric level radiant damage, Constitution save for half), Warding Flare (Wisdom modifier uses: attacks against you or an ally have disadvantage for a round).\nLevel 6: Improved Warding Flare (back on a short rest, adds temporary hit points).\nLevel 17: Corona of Light (for a minute, enemies near you have disadvantage on saves against your spells).\nDomain spells follow later.",
	  features = { [3] = "Radiance of the Dawn, Warding Flare", [6] = "Improved Warding Flare", [17] = "Corona of Light" } },
	{ key = "TRICKERY", name = "Trickery Domain",
	  desc = "Your god delights in mischief and deception.\n\nLevel 3: Blessing of the Trickster (an ally gets better at stealth for an hour), Invoke Duplicity (Channel Divinity: advantage on your attacks for a minute).\nLevel 17: Improved Duplicity (allies share the advantage against enemies next to you; healing when it ends).\nTrickster's Transposition has no BG effect. Domain spells follow later.",
	  features = { [3] = "Blessing of the Trickster, Invoke Duplicity", [6] = "Trickster's Transposition (no BG effect)", [17] = "Improved Duplicity" } },
	{ key = "WAR", name = "War Domain",
	  desc = "Your god champions battle and those who win it.\n\nLevel 3: Guided Strike (Channel Divinity: +10 to your attack rolls this round), War Priest (extra attacks, Wisdom modifier times per short rest).\nLevel 6: War God's Blessing (Channel Divinity: Shield of Faith, +2 AC for a minute, on a creature without concentration; Spiritual Weapon has no BG form here).\nLevel 17: Avatar of Battle (resistance to bludgeoning, piercing and slashing damage).\nDomain spells follow later.",
	  features = { [3] = "Guided Strike, War Priest", [6] = "War God's Blessing", [17] = "Avatar of Battle" } },
})

local function channelLeft(sprite)
	return B24LV.Remaining(sprite, "CLERIC_CHANNEL") > 0
end

table.insert(B24CL.CHANNEL_POWERS, { res = "B24LRADI", when = function(s) return isLight(s) end })
table.insert(B24CL.CHANNEL_POWERS, { res = "B24TDUPL", when = function(s) return isTrickery(s) end })
table.insert(B24CL.CHANNEL_POWERS, { res = "B24WGSTR", when = function(s) return isWar(s) end })
table.insert(B24CL.CHANNEL_POWERS, { res = "B24WGBLS", when = function(s) return isWar(s, 6) end })

-----------
-- Light --
-----------

B24LV.AddResource("WARDING_FLARE", { spell = "B24LWARD", localName = "B24LWUSE",
	shortRest = function(sprite) return isLight(sprite, 6) and "all" or nil end,
	max = function(sprite) return isLight(sprite) and math.max(1, wis(sprite)) or 0 end })

B24LV.AddResource("CORONA_OF_LIGHT", { spell = "B24LCORO", localName = "B24LCUSE",
	max = function(sprite) return isLight(sprite, 17) and math.max(1, wis(sprite)) or 0 end })

function B24LRADI(op402, cleric)
	EEex_Utility_TryIgnore(function()
		if not B24CL.UseChannel(cleric) then return end
		local dc = B24.SpellSaveDC(cleric, "SPPR000")
		for _, enemy in ipairs(B24X.Enemies(cleric, B24.Feet(30))) do
			local damage = B24LV.Dice(2, 10) + level(cleric)
			if B24.RollSave(enemy, "CON", dc, nil, " (Radiance of the Dawn)", { SOURCE = cleric.m_id }) then
				damage = math.floor(damage / 2)
			end
			B24X.Damage(enemy, cleric, damage, B24X.MAGIC)
		end
		B24.Log(string.format("%s: Radiance of the Dawn", B24.Name(cleric)))
	end)
end

function B24LWARD(op402, target)
	EEex_Utility_TryIgnore(function()
		local cleric = B24.GetSprite(op402.m_sourceId) or target
		B24LV.Use(cleric, "WARDING_FLARE")
		B24.SetTimed(target, "GRANTS_DIS", 6)
		if isLight(cleric, 6) then B24LV.TempHP(target, B24LV.Dice(2, 6) + wis(cleric), 3600) end
		B24.Log(string.format("%s: Warding Flare on %s", B24.Name(cleric), B24.Name(target)))
	end)
end

function B24LCORO(op402, cleric)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(cleric, "CORONA_OF_LIGHT")
		B24.SetTimed(cleric, "CORONA_OF_LIGHT", 60)
		B24.Log(string.format("%s: Corona of Light", B24.Name(cleric)))
	end)
end

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	if conditions.SOURCE == nil or B24.InParty(sprite) then return false, false end
	local cleric = B24.GetSprite(conditions.SOURCE)
	if cleric == nil or not B24.HasTimed(cleric, "CORONA_OF_LIGHT") then return false, false end
	for _, enemy in ipairs(B24X.Enemies(cleric, B24.Feet(60))) do
		if enemy.m_id == sprite.m_id then return false, true end
	end
	return false, false
end)

--------------
-- Trickery --
--------------

B24LV.AddResource("TRICKSTER_BLESSING", { spell = "B24TBLES", localName = "B24TBUSE",
	max = function(sprite) return isTrickery(sprite) and 1 or 0 end })

-- Blessing of the Trickster (touch): +25% to stealth for an hour, standing in for advantage.
function B24TBLES(op402, target)
	EEex_Utility_TryIgnore(function()
		local cleric = B24.GetSprite(op402.m_sourceId) or target
		B24LV.Use(cleric, "TRICKSTER_BLESSING")
		for _, opcode in ipairs({ 59, 275 }) do
			B24.ApplyEffect(target, { ["effectID"] = opcode, ["effectAmount"] = 25, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 3600 })
		end
		B24.Log(string.format("%s blesses %s with stealth", B24.Name(cleric), B24.Name(target)))
	end)
end

function B24TDUPL(op402, cleric)
	EEex_Utility_TryIgnore(function()
		if not B24CL.UseChannel(cleric) then return end
		B24.SetTimed(cleric, "ATTACK_ADV", 60)
		B24.SetTimed(cleric, "DUPLICITY", 60)
		B24.Aux(cleric).B24_DuplicityActive = true
		B24.Log(string.format("%s: Invoke Duplicity", B24.Name(cleric)))
	end)
end

-- Improved Duplicity: allies have advantage against enemies next to the cleric.
table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	if not B24.InParty(attacker) then return false end
	for _, cleric in ipairs(B24.Party()) do
		if cleric.m_id ~= attacker.m_id and isTrickery(cleric, 17) and B24.HasTimed(cleric, "DUPLICITY") then
			for _, enemy in ipairs(B24X.Enemies(cleric, B24.ADJACENT)) do
				if enemy.m_id == target.m_id then return true end
			end
		end
	end
	return false
end)

B24LV.AddTickListener(function(cleric)
	local aux = B24.Aux(cleric)
	if not aux.B24_DuplicityActive or B24.HasTimed(cleric, "DUPLICITY") then return end
	aux.B24_DuplicityActive = nil
	if not isTrickery(cleric, 17) then return end
	local best, missing = nil, 0
	for _, ally in ipairs(B24X.Allies(cleric, B24.Feet(30))) do
		local gap = ally:getStat(B24.Stat.MAXHP) - ally.m_baseStats.m_hitPoints
		if gap > missing then best, missing = ally, gap end
	end
	if best then B24.Heal(best, level(cleric)) end
end)

---------
-- War --
---------

B24LV.AddResource("WAR_PRIEST", { spell = "B24WPRST", localName = "B24WPUSE", shortRest = "all",
	max = function(sprite) return isWar(sprite) and math.max(1, wis(sprite)) or 0 end })

local function guide(target)
	B24.ApplyEffect(target, { ["effectID"] = 54, ["effectAmount"] = 10, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
	B24.Log(string.format("%s: Guided Strike (+10 to hit this round)", B24.Name(target)))
end

function B24WGSTR(op402, cleric)
	EEex_Utility_TryIgnore(function()
		if B24CL.UseChannel(cleric) then guide(cleric) end
	end)
end

-- War God's Blessing (6): a Channel Divinity use casts Shield of Faith (+2 AC) on a creature, for a
-- minute and without concentration (2024; Spiritual Weapon, the other choice, is left out).
function B24WGBLS(op402, target)
	EEex_Utility_TryIgnore(function()
		local cleric = B24.GetSprite(op402.m_sourceId) or target
		if not B24CL.UseChannel(cleric) then return end
		B24.RemoveEffectsBySource(target, "B24WGBLS")
		B24.ApplyEffect(target, { ["effectID"] = 0, ["effectAmount"] = 2, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60,
			["sourceID"] = cleric.m_id, ["m_sourceRes"] = "B24WGBLS" })
		B24.Log(string.format("%s: War God's Blessing (Shield of Faith on %s)", B24.Name(cleric), B24.Name(target)))
	end)
end

function B24WPRST(op402, cleric)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(cleric, "WAR_PRIEST")
		B24.ApplyEffect(cleric, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
		B24.Log(string.format("%s: War Priest attack", B24.Name(cleric)))
	end)
end

B24LV.AddApplyListener(function(sprite)
	if not isWar(sprite, 17) then return end
	for _, opcode in ipairs({ 86, 87, 88, 89 }) do
		B24LV.Permanent(sprite, { ["effectID"] = opcode, ["effectAmount"] = 50, ["dwFlags"] = 0 })
	end
end)
