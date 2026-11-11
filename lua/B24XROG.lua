-- BG 2024 Rules Mod: Rogue subclasses beyond the SRD (Arcane Trickster, Assassin, Soulknife).
-- Feature texts are this mod's own wording.
--
-- Arcane Trickster
--   3  Spellcasting (third caster, wizard list, B24XCOM.lua), cantrips (2; 3 at 10), Mage Hand
--      Legerdemain (no BG effect)
--   9  Magical Ambush (a spell you start casting while invisible gives disadvantage on its saves)
--   13 Versatile Trickster, 17 Spell Thief (no BG effect)
-- Assassin
--   3  Assassinate (in the first round of combat: advantage on attacks, and the first hit deals
--      extra damage equal to your Rogue level), Assassin's Tools (no BG effect)
--   9  Infiltration Expertise (no BG effect)
--   13 Envenom Weapons (once per round a Sneak Attack also deals 2d6 poison damage, and the target
--      makes a Constitution save or its attacks have disadvantage for a minute, standing in for
--      poisoned; Cunning Strike itself is not in yet)
--   17 Death Strike (in the first round of combat a hit forces a Constitution save or deals double
--      damage)
-- Soulknife
--   3  Psionic Power (Psionic Energy Dice, as the Psi Warrior), Psychic Blades (an at-will innate
--      creates a psychic blade for an hour: 1d6, finesse, magical), Psi-Bolstered Knack and
--      Psychic Whispers (no BG effect)
--   9  Soul Blades (no BG effect: BG reports no misses)
--   13 Psychic Veil (a die or once per long rest: invisible for an hour or until you attack)
--   17 Rend Mind (once per long rest, or 3 dice: a Sneak Attack with a psychic blade forces a
--      Wisdom save or stuns the target for a minute)
--
-- Locals: B24ATS* (Arcane Trickster spells and slots), B24SKUSE (Psionic Energy Dice), B24PVUSE
-- (Psychic Veil), B24RMUSE (Rend Mind).

local function level(sprite) return B24RO.Level(sprite) end

local function isTrickster(sprite, l) return B24LV.Is(sprite, "ROGUE", "ARCANE_TRICKSTER", l or 3) end
local function isAssassin(sprite, l) return B24LV.Is(sprite, "ROGUE", "ASSASSIN", l or 3) end
local function isSoulknife(sprite, l) return B24LV.Is(sprite, "ROGUE", "SOULKNIFE", l or 3) end

B24LV.AddMoreSubclasses("ROGUE", {
	{ key = "ARCANE_TRICKSTER", name = "Arcane Trickster",
	  desc = "You add wizard magic to stealth and trickery.\n\nLevel 3: Spellcasting (wizard spells with Intelligence; 2024 third-caster slots; spells appear as innate abilities while you have a slot of their level), two wizard cantrips.\nLevel 9: Magical Ambush (spells you start while invisible give disadvantage on their saves).\nLevel 10: a third cantrip. Spell levels 2 at 7, 3 at 13, 4 at 19.\nMage Hand Legerdemain, Versatile Trickster and Spell Thief have no BG effect.",
	  features = { [3] = "Spellcasting (wizard spells), 2 cantrips", [7] = "level 2 spells", [9] = "Magical Ambush",
		[10] = "3 cantrips", [13] = "level 3 spells", [19] = "level 4 spells" } },
	{ key = "ASSASSIN", name = "Assassin",
	  desc = "You strike before your foes know the fight has started.\n\nLevel 3: Assassinate (in the first round of combat: advantage on attacks; the first hit deals extra damage equal to your Rogue level).\nLevel 13: Envenom Weapons (Sneak Attacks also poison: 2d6 poison damage, Constitution save or weakened attacks).\nLevel 17: Death Strike (first round: Constitution save or double damage).\nAssassin's Tools and Infiltration Expertise have no BG effect.",
	  features = { [3] = "Assassinate", [9] = "Infiltration Expertise (no BG effect)", [13] = "Envenom Weapons", [17] = "Death Strike" } },
	{ key = "SOULKNIFE", name = "Soulknife",
	  desc = "Blades of psychic energy appear in your hands.\n\nLevel 3: Psionic Power (Psionic Energy Dice), Psychic Blades (create a magical psychic blade, 1d6, finesse).\nLevel 13: Psychic Veil (invisible for an hour, once per long rest or for a die).\nLevel 17: Rend Mind (a Sneak Attack with a psychic blade can stun for a minute, Wisdom save).\nPsi-Bolstered Knack, Psychic Whispers and Soul Blades have no BG effect.",
	  features = { [3] = "Psionic Power, Psychic Blades", [9] = "Soul Blades (no BG effect)", [13] = "Psychic Veil", [17] = "Rend Mind" } },
})

local function firstRound()
	return B24RD ~= nil and B24RD.roundStart ~= nil and B24RD.round == 1
end

local function sneakAttackNow(rogue)
	return B24.Aux(rogue).B24_SneakTick == B24.GameTick()
end

----------------------
-- Arcane Trickster --
----------------------

B24X.AddThirdCaster({ class = "ROGUE", subclass = "ARCANE_TRICKSTER", prefix = "B24ATS", title = "Arcane Trickster Spell",
	cantrips = function(l) return l >= 10 and 3 or 2 end })

table.insert(B24.SpellCastListeners, function(sprite, res)
	if not isTrickster(sprite, 9) then return end
	local g = B24.GState
	if B24.GState_Has(sprite, g.INVISIBLE) or B24.GState_Has(sprite, g.IMPROVEDINVISIBILITY) then
		B24.Aux(sprite).B24_AmbushCast = B24.GameTick()
	end
end)

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	if conditions.SOURCE == nil then return false, false end
	local caster = B24.GetSprite(conditions.SOURCE)
	local cast = caster and B24.Aux(caster).B24_AmbushCast
	return false, cast ~= nil and B24.GameTick() - cast <= 150
end)

--------------
-- Assassin --
--------------

B24LV.AddTickListener(function(rogue)
	if not isAssassin(rogue) or not firstRound() then return end
	local aux = B24.Aux(rogue)
	if aux.B24_AssassinRound ~= B24RD.roundStart then
		aux.B24_AssassinRound = B24RD.roundStart
		aux.B24_AssassinateHit = nil
		B24.SetTimed(rogue, "ATTACK_ADV", 6)
	end
end)

table.insert(B24WPN.DamageListeners, function(context)
	local rogue, target = context.attacker, context.target
	if not isAssassin(rogue) then return end
	local aux = B24.Aux(rogue)
	if firstRound() then
		if not aux.B24_AssassinateHit then
			aux.B24_AssassinateHit = true
			context.effect.m_effectAmount = context.effect.m_effectAmount + level(rogue)
			B24.Log(string.format("%s: Assassinate +%d", B24.Name(rogue), level(rogue)))
		end
		if isAssassin(rogue, 17) and not B24.RollSave(target, "CON", B24X.DC(rogue, "DEX"), nil, " (Death Strike)") then
			B24WPN.RollDiceInto(context.effect)
			context.effect.m_effectAmount = context.effect.m_effectAmount * 2
			B24.Log(string.format("%s: Death Strike doubles the damage", B24.Name(rogue)))
		end
	end
	if isAssassin(rogue, 13) and sneakAttackNow(rogue) then
		B24X.Damage(target, rogue, B24LV.Dice(2, 6), B24X.POISON)
		if not B24.RollSave(target, "CON", B24X.DC(rogue, "DEX"), nil, " (Envenom Weapons)", { POISON = true }) then
			B24.SetTimed(target, "ATTACK_DIS", 60)
		end
	end
end)

---------------
-- Soulknife --
---------------

B24LV.AddResource("SOULKNIFE_DICE", { localName = "B24SKUSE", shortRest = "one",
	powers = { { res = "B24PSVEL", when = function(s) return isSoulknife(s, 13) end,
		free = function(s) return B24LV.Remaining(s, "PSYCHIC_VEIL") > 0 end } },
	max = function(sprite)
		if not isSoulknife(sprite) then return 0 end
		local count = B24X.PsionicDice(level(sprite))
		return count
	end })

B24LV.AddResource("PSYCHIC_VEIL", { localName = "B24PVUSE",
	max = function(sprite) return isSoulknife(sprite, 13) and 1 or 0 end })
B24LV.AddResource("REND_MIND", { localName = "B24RMUSE",
	max = function(sprite) return isSoulknife(sprite, 17) and 1 or 0 end })

B24LV.AddApplyListener(function(sprite)
	B24LV.Grant(sprite, "B24PSBLA", isSoulknife(sprite))
end)

-- Psychic Blades: an at-will innate that creates the blade for an hour (op111).
-- The blade item, recognised by its loaded resource header.
local function isPsychicBlade(item)
	local header = EEex_Resource_Demand("B24PSBLD", "ITM")
	return header ~= nil and item.pRes ~= nil and EEex_UDToPtr(item.pRes.pHeader) == EEex_UDToPtr(header)
end

function B24PSBLA(op402, rogue)
	EEex_Utility_TryIgnore(function()
		B24LV.Grant(rogue, "B24PSBLA", true)
		B24.ApplyEffect(rogue, { ["effectID"] = 111, ["res"] = "B24PSBLD", ["durationType"] = 0, ["duration"] = 3600 })
		B24.Log(string.format("%s: Psychic Blade", B24.Name(rogue)))
	end)
end

function B24PSVEL(op402, rogue)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Use(rogue, "PSYCHIC_VEIL") and not B24LV.Spend(rogue, "SOULKNIFE_DICE", 1) then return end
		B24LV.RefreshPowers(rogue, "SOULKNIFE_DICE")
		B24.ApplyEffect(rogue, { ["effectID"] = 20, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 3600 })
		B24.Log(string.format("%s: Psychic Veil", B24.Name(rogue)))
	end)
end

table.insert(B24WPN.DamageListeners, function(context)
	local rogue, target = context.attacker, context.target
	local weapon = context.weapon
	if not isSoulknife(rogue, 17) or weapon == nil or not sneakAttackNow(rogue) then return end
	if not isPsychicBlade(weapon) then return end
	if not B24LV.Use(rogue, "REND_MIND") and not B24LV.Spend(rogue, "SOULKNIFE_DICE", 3) then return end
	local dc = B24X.DC(rogue, "DEX")
	if not B24.RollSave(target, "WIS", dc, nil, " (Rend Mind)") then
		B24.ApplyEffect(target, { ["effectID"] = 45, ["durationType"] = 0, ["duration"] = 60, ["sourceID"] = rogue.m_id })
		B24.Log(string.format("%s: Rend Mind stuns %s", B24.Name(rogue), B24.Name(target)))
	end
end)
