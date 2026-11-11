-- BG 2024 Rules Mod: Paladin subclasses beyond the SRD (Oath of Glory, Oath of the Ancients, Oath
-- of Vengeance). Feature texts are this mod's own wording. Oath spells are not granted yet.
--
-- Glory
--   3  Inspiring Smite (Channel Divinity: 2d8 + Paladin level temporary hit points shared among
--      you and allies within 30 ft), Peerless Athlete (no BG effect)
--   7  Aura of Alacrity (+10 ft speed for you and allies in your aura)
--   15 Glorious Defense (no reactions in BG: once per round a hit near you can become a miss)
--   20 Living Legend (once per long rest, for a minute: once per round reroll a failed save)
-- Ancients
--   3  Nature's Wrath (Channel Divinity: enemies within 15 ft make a Strength save or are
--      restrained for a minute; a new save at the end of each round)
--   7  Aura of Warding (you and allies in your aura resist magic damage, standing in for necrotic,
--      psychic and radiant)
--   15 Undying Sentinel (once per long rest you drop to 1 hit point instead of 0)
--   20 Elder Champion (once per long rest, for a minute: regain 10 hit points each round; enemies
--      in your aura have disadvantage on saves against your spells and Channel Divinity)
-- Vengeance
--   3  Vow of Enmity (Channel Divinity on a creature: advantage on attacks against it for a minute)
--   7  Relentless Avenger, 15 Soul of Vengeance (no BG effect: no opportunity attacks or reactions)
--   20 Avenging Angel (once per long rest, for 10 minutes: enemies that come within 30 ft make a
--      Wisdom save or are frightened for a minute; flight has no BG effect)
--
-- Locals: B24LLUSE (Living Legend), B24USUSE (Undying Sentinel), B24ECUSE (Elder Champion),
-- B24AAUSE (Avenging Angel).

local function level(sprite) return B24PA.Level(sprite) end
local function cha(sprite) return B24.AbilityModOf(sprite, "CHA") end

local function isGlory(sprite, l) return B24LV.Is(sprite, "PALADIN", "GLORY", l or 3) end
local function isAncients(sprite, l) return B24LV.Is(sprite, "PALADIN", "ANCIENTS", l or 3) end
local function isVengeance(sprite, l) return B24LV.Is(sprite, "PALADIN", "VENGEANCE", l or 3) end

B24LV.AddMoreSubclasses("PALADIN", {
	{ key = "GLORY", name = "Oath of Glory",
	  desc = "You strive for heroic deeds and inspire others to them.\n\nLevel 3: Inspiring Smite (Channel Divinity: you and nearby allies share 2d8 + your Paladin level temporary hit points).\nLevel 7: Aura of Alacrity (you and allies in your aura are faster).\nLevel 15: Glorious Defense (Charisma modifier times per long rest: once per round, a hit against you or an ally next to you may miss against your Charisma modifier added to AC; BG has no reactions, so no counterattack).\nLevel 20: Living Legend (for a minute, reroll failed saves).\nPeerless Athlete has no BG effect. Oath spells follow later.",
	  features = { [3] = "Inspiring Smite", [7] = "Aura of Alacrity", [15] = "Glorious Defense", [20] = "Living Legend" } },
	{ key = "ANCIENTS", name = "Oath of the Ancients",
	  desc = "You guard the light of life and the green world.\n\nLevel 3: Nature's Wrath (Channel Divinity: nearby enemies are restrained by vines, Strength save, new save each round).\nLevel 7: Aura of Warding (you and allies in your aura resist magic damage).\nLevel 15: Undying Sentinel (drop to 1 hit point instead of 0, once per long rest).\nLevel 20: Elder Champion (for a minute: regain hit points each round; enemies near you resist your magic worse).\nOath spells follow later.",
	  features = { [3] = "Nature's Wrath", [7] = "Aura of Warding", [15] = "Undying Sentinel", [20] = "Elder Champion" } },
	{ key = "VENGEANCE", name = "Oath of Vengeance",
	  desc = "You hunt down those who committed grave wrongs.\n\nLevel 3: Vow of Enmity (Channel Divinity on a creature: advantage on attacks against it for a minute).\nLevel 20: Avenging Angel (for 10 minutes, enemies that come near you are frightened, Wisdom save).\nRelentless Avenger and Soul of Vengeance have no BG effect. Oath spells follow later.",
	  features = { [3] = "Vow of Enmity", [7] = "Relentless Avenger (no BG effect)", [15] = "Soul of Vengeance (no BG effect)", [20] = "Avenging Angel" } },
})

table.insert(B24PA.CHANNEL_POWERS, { res = "B24GINSP", when = function(s) return isGlory(s) end })
table.insert(B24PA.CHANNEL_POWERS, { res = "B24ANWRA", when = function(s) return isAncients(s) end })
table.insert(B24PA.CHANNEL_POWERS, { res = "B24VVOWE", when = function(s) return isVengeance(s) end })

B24LV.AddResource("LIVING_LEGEND", { spell = "B24GLEGD", localName = "B24LLUSE",
	max = function(sprite) return isGlory(sprite, 20) and 1 or 0 end })
B24LV.AddResource("UNDYING_SENTINEL", { localName = "B24USUSE",
	max = function(sprite) return isAncients(sprite, 15) and 1 or 0 end })
B24LV.AddResource("ELDER_CHAMPION", { spell = "B24AELDR", localName = "B24ECUSE",
	max = function(sprite) return isAncients(sprite, 20) and 1 or 0 end })
B24LV.AddResource("AVENGING_ANGEL", { spell = "B24VANGL", localName = "B24AAUSE",
	max = function(sprite) return isVengeance(sprite, 20) and 1 or 0 end })

-- Allies in the paladin's aura (the paladin included).
local function inAura(paladin)
	return B24X.Allies(paladin, B24PA.AuraRange(level(paladin)))
end

-----------
-- Glory --
-----------

function B24GINSP(op402, paladin)
	EEex_Utility_TryIgnore(function()
		if not B24PA.UseChannel(paladin) then return end
		local allies = B24X.Allies(paladin, B24.Feet(30))
		local pool = B24LV.Dice(2, 8) + level(paladin)
		local share = math.max(1, math.floor(pool / #allies))
		for _, ally in ipairs(allies) do B24LV.TempHP(ally, share, 3600) end
		B24.Log(string.format("%s: Inspiring Smite, %d temporary hit points each", B24.Name(paladin), share))
	end)
end

B24LV.AddApplyListener(function(sprite)
	if isGlory(sprite, 7) then B24LV.Permanent(sprite, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5 }) end
end)

function B24GLEGD(op402, paladin)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(paladin, "LIVING_LEGEND")
		B24.SetTimed(paladin, "LIVING_LEGEND", 60)
		B24.Log(string.format("%s: Living Legend", B24.Name(paladin)))
	end)
end

B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not B24.HasTimed(sprite, "LIVING_LEGEND") or not B24LV.OncePerRound(sprite, "LIVING_LEGEND") then return nil end
	local roll = B24.Roll(20)
	B24.Log(string.format("%s: Living Legend, rerolls the %s save: %d", B24.Name(sprite), ability, roll + mod))
	return roll + mod
end)

--------------
-- Ancients --
--------------

function B24ANWRA(op402, paladin)
	EEex_Utility_TryIgnore(function()
		if not B24PA.UseChannel(paladin) then return end
		local dc = B24.SpellSaveDC(paladin, "SPPR000")
		for _, enemy in ipairs(B24X.Enemies(paladin, B24.Feet(15))) do
			if not B24.RollSave(enemy, "STR", dc, nil, " (Nature's Wrath)", { SOURCE = paladin.m_id }) then
				B24.ApplyCondition(enemy, "RESTRAINED", { seconds = 60, source = paladin, ability = "STR", dc = dc, label = "Nature's Wrath" })
			end
		end
		B24.Log(string.format("%s: Nature's Wrath", B24.Name(paladin)))
	end)
end

function B24AELDR(op402, paladin)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(paladin, "ELDER_CHAMPION")
		B24.SetTimed(paladin, "ELDER_CHAMPION", 60)
		B24.Log(string.format("%s: Elder Champion", B24.Name(paladin)))
	end)
end

-- Aura of Warding and Alacrity are renewed every second; Elder Champion heals each round.
B24LV.AddTickListener(function(paladin)
	if B24.GState_Has(paladin, B24.GState.DEAD) then return end
	if isAncients(paladin, 7) then
		for _, ally in ipairs(inAura(paladin)) do
			B24.RemoveEffectsBySource(ally, "B24AWARD")
			B24.ApplyEffect(ally, { ["effectID"] = 31, ["effectAmount"] = 50, ["dwFlags"] = 0, ["durationType"] = 0,
				["duration"] = 2, ["m_sourceRes"] = "B24AWARD" })
		end
	end
	if isGlory(paladin, 7) then
		for _, ally in ipairs(inAura(paladin)) do
			if ally.m_id ~= paladin.m_id then
				B24.RemoveEffectsBySource(ally, "B24ALACR")
				B24.ApplyEffect(ally, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5, ["durationType"] = 0,
					["duration"] = 2, ["m_sourceRes"] = "B24ALACR" })
			end
		end
	end
	if B24.HasTimed(paladin, "ELDER_CHAMPION") and B24LV.OncePerRound(paladin, "ELDER_CHAMPION") then
		B24.Heal(paladin, 10)
	end
end)

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	if conditions.SOURCE == nil or B24.InParty(sprite) then return false, false end
	local paladin = B24.GetSprite(conditions.SOURCE)
	if paladin == nil or not B24.HasTimed(paladin, "ELDER_CHAMPION") then return false, false end
	for _, enemy in ipairs(B24X.Enemies(paladin, B24PA.AuraRange(level(paladin)))) do
		if enemy.m_id == sprite.m_id then return false, true end
	end
	return false, false
end)

-- Undying Sentinel: a minimum of 1 hit point while the use is left; the damage hook notices when
-- it caught a blow and spends the use.
B24LV.AddApplyListener(function(sprite)
	B24.RemoveEffectsBySource(sprite, "B24UNDYS")
	if isAncients(sprite, 15) and B24LV.Remaining(sprite, "UNDYING_SENTINEL") > 0 then
		B24.ApplyEffect(sprite, { ["effectID"] = 208, ["effectAmount"] = 1, ["durationType"] = 9, ["m_sourceRes"] = "B24UNDYS" })
		B24.Aux(sprite).B24_UndyingSentinel = true
	end
end)

B24.AddLongRestListener(function(sprite)
	if not isAncients(sprite, 15) then return end
	B24.RemoveEffectsBySource(sprite, "B24UNDYS")
	B24.ApplyEffect(sprite, { ["effectID"] = 208, ["effectAmount"] = 1, ["durationType"] = 9, ["m_sourceRes"] = "B24UNDYS" })
	B24.Aux(sprite).B24_UndyingSentinel = true
end)

local hitPointsBefore = {}
local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
local originalDamageDone = EEex_Sprite_Hook_OnDamageEffectDone

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	if B24.Aux(targetSprite).B24_UndyingSentinel then
		hitPointsBefore[targetSprite.m_id] = targetSprite.m_baseStats.m_hitPoints
	end
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)
	originalDamageDone(effect, sourceSprite, targetSprite)
	local before = hitPointsBefore[targetSprite.m_id]
	hitPointsBefore[targetSprite.m_id] = nil
	if before and before > 1 and targetSprite.m_baseStats.m_hitPoints == 1 then
		B24.Aux(targetSprite).B24_UndyingSentinel = nil
		B24LV.Use(targetSprite, "UNDYING_SENTINEL")
		B24.RemoveEffectsBySource(targetSprite, "B24UNDYS")
		B24.Log(string.format("%s: Undying Sentinel, stays at 1 hit point", B24.Name(targetSprite)))
	end
end

---------------
-- Vengeance --
---------------

function B24VVOWE(op402, target)
	EEex_Utility_TryIgnore(function()
		local paladin = B24.GetSprite(op402.m_sourceId)
		if paladin == nil or not B24PA.UseChannel(paladin) then return end
		B24.Aux(paladin).B24_Vow = { target = target.m_id, untilTick = B24.GameTick() + 900 }
		B24.Log(string.format("%s swears a Vow of Enmity against %s", B24.Name(paladin), B24.Name(target)))
	end)
end

table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	local vow = B24.Aux(attacker).B24_Vow
	return vow ~= nil and vow.target == target.m_id and B24.GameTick() <= vow.untilTick
end)

function B24VANGL(op402, paladin)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(paladin, "AVENGING_ANGEL")
		B24.SetTimed(paladin, "AVENGING_ANGEL", 600)
		B24.Aux(paladin).B24_AngelSaved = {}
		B24.Log(string.format("%s: Avenging Angel", B24.Name(paladin)))
	end)
end

-- Each enemy saves once when it first comes within 30 ft.
B24LV.AddTickListener(function(paladin)
	if not B24.HasTimed(paladin, "AVENGING_ANGEL") then return end
	local saved = B24.Aux(paladin).B24_AngelSaved or {}
	B24.Aux(paladin).B24_AngelSaved = saved
	local dc = B24.SpellSaveDC(paladin, "SPPR000")
	for _, enemy in ipairs(B24X.Enemies(paladin, B24.Feet(30))) do
		if not saved[enemy.m_id] then
			saved[enemy.m_id] = true
			if not B24.RollSave(enemy, "WIS", dc, nil, " (Avenging Angel)", { FEAR = true, SOURCE = paladin.m_id }) then
				B24.ApplyEffect(enemy, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 60, ["sourceID"] = paladin.m_id })
				B24.SetTimed(enemy, "GRANTS_ADV", 60)
			end
		end
	end
end)

-- Undying Sentinel catches a drop to 0 before the dying rules (B24DYING.lua).
B24.AddDownSaver(function(sprite) return B24.Aux(sprite).B24_UndyingSentinel == true end)

----------------------
-- Glorious Defense --
----------------------

-- Glorious Defense (Glory 15), Charisma modifier uses per long rest: BG has no reactions; once per
-- round, the first weapon hit against the paladin or an ally within 10 ft is checked against an
-- Armor Class higher by the paladin's Charisma modifier and may turn into a miss (the share of hits
-- that 5 x Charisma modifier percent less hit chance takes away). The counterattack has no BG
-- form. Local B24GDUSE.
B24LV.AddResource("GLORIOUS_DEFENSE", { localName = "B24GDUSE",
	max = function(sprite) return isGlory(sprite, 15) and math.max(1, cha(sprite)) or 0 end })

local function defender(target)
	for _, paladin in ipairs(B24.Party()) do
		if isGlory(paladin, 15) and B24LV.Remaining(paladin, "GLORIOUS_DEFENSE") > 0
			and not B24.GState_Has(paladin, B24.GState.DEAD) and not B24.GState_Has(paladin, B24.GState.HELPLESS) then
			if paladin.m_id == target.m_id then return paladin end
			for _, ally in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(paladin, "[PC]", B24.Feet(10), true) or {}) do
				if ally.m_id == target.m_id then return paladin end
			end
		end
	end
end

EEex_Sprite_AddBlockWeaponHitListener(function(context)
	local attacker, target = context.attackingSprite, context.targetSprite
	-- Only a real hit (not a hit chance asked, B24.InHitQuery).
	if (B24.InHitQuery and B24.InHitQuery()) or not B24.IsSprite(attacker) or not B24.IsSprite(target) or not B24.InParty(target) then return false end
	local paladin = defender(target)
	if paladin == nil or not B24LV.OncePerRound(paladin, "GLORIOUS_DEFENSE") then return false end
	local ok, chance = pcall(B24.HitChance, attacker, target, context.weapon)
	if not ok or chance == nil or chance <= 0 then return false end
	B24LV.Use(paladin, "GLORIOUS_DEFENSE")
	local lowered = math.max(0, chance - 5 * math.max(1, cha(paladin)))
	if math.random() * chance >= lowered then
		B24.Log(string.format("%s: Glorious Defense turns %s's hit on %s into a miss", B24.Name(paladin),
			B24.Name(attacker), B24.Name(target)))
		return true
	end
	return false
end)
