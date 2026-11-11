-- BG 2024 Rules Mod: Sorcerer subclasses beyond the SRD (Aberrant Sorcery, Clockwork Sorcery, Wild
-- Magic Sorcery). Feature texts and the surge table are this mod's own. Subclass spells are not
-- granted yet. Several features spend Sorcery Points (Font of Magic, B24SORC.lua).
--
-- Aberrant
--   3  Psionic Spells (no BG form: BG has none of these spells), Telepathic Speech (no BG effect)
--   6  Psychic Defenses (advantage on saves against charm and fear; psychic resistance has no BG
--      damage type), Psionic Sorcery (no BG effect)
--   14 Revelation in Flesh (1 Sorcery Point: see invisible creatures and move faster for 10 minutes)
--   18 Warping Implosion (once per long rest or 5 points: enemies within 30 ft make a Strength
--      save or take 3d10 force damage, half on a success)
-- Clockwork
--   3  Restore Balance (Proficiency Bonus uses per long rest: for a round, attacks against an ally
--      can't have advantage), Clockwork Spells (the BG versions; see below)
--   6  Bastion of Law (1-5 Sorcery Points: an ally gains that many d8 temporary hit points; in BG
--      the innate spends as many points as you have, up to 5)
--   14 Trance of Order (once per long rest or 5 points, a minute: attacks against you can't have
--      advantage, and your saves count a d20 of 9 or less as 10)
--   18 Clockwork Cavalcade (once per long rest or 7 points: up to 100 hit points of healing shared
--      among allies within 30 ft)
-- Wild Magic
--   3  Wild Magic Surge (after you start casting a level 1+ wizard spell, a d20 of 20 - or any
--      roll after Tides of Chaos - sets off a surge), Tides of Chaos (once per long rest:
--      advantage on your attacks and saves for a round; a surge restores it)
--   6  Bend Luck (1 Sorcery Point, once per round: an ally's failed save gets +1d4)
--   14 Controlled Chaos (a surge rolls twice and takes the kinder result)
--   18 Tamed Surge (once per long rest, choose the surge after casting a spell)
--
-- Locals: B24RBUSE (Restore Balance), B24TOUSE (Trance of Order), B24CCUSE2 (Clockwork Cavalcade),
-- B24WIUSE (Warping Implosion), B24TCUSE (Tides of Chaos).

local function level(sprite) return B24SO.Level(sprite) end
local function cha(sprite) return B24.AbilityModOf(sprite, "CHA") end
local function pointsLeft(sprite) return B24LV.Remaining(sprite, "SORCERY_POINTS") end

local function isAberrant(sprite, l) return B24LV.Is(sprite, "SORCERER", "ABERRANT", l or 3) end
local function isClockwork(sprite, l) return B24LV.Is(sprite, "SORCERER", "CLOCKWORK", l or 3) end
local function isWild(sprite, l) return B24LV.Is(sprite, "SORCERER", "WILD_MAGIC", l or 3) end

B24LV.AddMoreSubclasses("SORCERER", {
	{ key = "ABERRANT", name = "Aberrant Sorcery",
	  desc = "Something from beyond the stars touched your mind.\n\nLevel 6: Psychic Defenses (advantage on saves against charm and fear).\nLevel 14: Revelation in Flesh (1 Sorcery Point: see invisible creatures and move faster for 10 minutes).\nLevel 18: Warping Implosion (enemies around you take 3d10 force damage, Strength save for half).\nPsionic Spells (none of them exist in BG), Telepathic Speech and Psionic Sorcery have no BG effect.",
	  features = { [3] = "Psionic Spells and Telepathic Speech (no BG form)", [6] = "Psychic Defenses",
		[14] = "Revelation in Flesh", [18] = "Warping Implosion" } },
	{ key = "CLOCKWORK", name = "Clockwork Sorcery",
	  desc = "The order of Mechanus runs through your magic.\n\nLevel 3: Restore Balance (for a round, attacks against an ally can't have advantage).\nLevel 6: Bastion of Law (spend Sorcery Points: an ally gains d8s of temporary hit points).\nLevel 14: Trance of Order (for a minute, attacks against you lose advantage and your saves don't roll below 10).\nLevel 18: Clockwork Cavalcade (share up to 100 hit points of healing among nearby allies).\nClockwork Spells: the subclass spells BG has, each once per long rest without a slot (Protection from Evil and Good, Aid, Lesser Restoration, Dispel Magic, Protection from Energy, Freedom of Movement, Greater Restoration).",
	  features = { [3] = "Restore Balance", [6] = "Bastion of Law", [14] = "Trance of Order", [18] = "Clockwork Cavalcade" } },
	{ key = "WILD_MAGIC", name = "Wild Magic Sorcery",
	  desc = "Your magic is chaos barely held in check.\n\nLevel 3: Wild Magic Surge (casting a spell can set off a random magical effect), Tides of Chaos (advantage on your attacks and saves for a round, once per long rest; a surge restores it).\nLevel 6: Bend Luck (spend 1 Sorcery Point: an ally's failed save gets +1d4).\nLevel 14: Controlled Chaos (surges roll twice, the kinder result is used).\nLevel 18: Tamed Surge (once per long rest, right after casting a spell, choose the surge).",
	  features = { [3] = "Wild Magic Surge, Tides of Chaos", [6] = "Bend Luck", [14] = "Controlled Chaos", [18] = "Tamed Surge" } },
})

-- Features that cost a long rest use or Sorcery Points.
local function useOrPoints(sprite, key, points)
	if B24LV.Use(sprite, key) then return true end
	return B24SO.SpendPoints(sprite, points)
end

-- The point-costing innates are powers of the Sorcery Points pool (free = a long rest use left).
local function left(key) return function(sprite) return B24LV.Remaining(sprite, key) > 0 end end
for _, power in ipairs({
	{ res = "B24AREVL", cost = 1, when = function(s) return isAberrant(s, 14) end },
	{ res = "B24AWARP", cost = 5, when = function(s) return isAberrant(s, 18) end, free = left("WARPING_IMPLOSION") },
	{ res = "B24CBAST", cost = 1, when = function(s) return isClockwork(s, 6) end },
	{ res = "B24CTRAN", cost = 5, when = function(s) return isClockwork(s, 14) end, free = left("TRANCE_OF_ORDER") },
	{ res = "B24CCAVL", cost = 7, when = function(s) return isClockwork(s, 18) end, free = left("CLOCKWORK_CAVALCADE") },
}) do table.insert(B24LV.RESOURCES.SORCERY_POINTS.powers, power) end

local function refresh(sprite)
	B24LV.RefreshPowers(sprite, "SORCERY_POINTS")
end

--------------
-- Aberrant --
--------------

B24LV.AddResource("WARPING_IMPLOSION", { localName = "B24WIUSE",
	max = function(sprite) return isAberrant(sprite, 18) and 1 or 0 end })

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	return isAberrant(sprite, 6) and (conditions.CHARM or conditions.FEAR) or false, false
end)

function B24AREVL(op402, sorcerer)
	EEex_Utility_TryIgnore(function()
		if not B24SO.SpendPoints(sorcerer, 1) then return end
		B24.ApplyEffect(sorcerer, { ["effectID"] = 193, ["durationType"] = 0, ["duration"] = 600 })
		B24.ApplyEffect(sorcerer, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 600 })
		refresh(sorcerer)
		B24.Log(string.format("%s: Revelation in Flesh", B24.Name(sorcerer)))
	end)
end

function B24AWARP(op402, sorcerer)
	EEex_Utility_TryIgnore(function()
		if not useOrPoints(sorcerer, "WARPING_IMPLOSION", 5) then return end
		local dc = B24.SpellSaveDC(sorcerer, "SPWI000")
		for _, enemy in ipairs(B24X.Enemies(sorcerer, B24.Feet(30))) do
			local damage = B24LV.Dice(3, 10)
			if B24.RollSave(enemy, "STR", dc, nil, " (Warping Implosion)", { SOURCE = sorcerer.m_id }) then damage = math.floor(damage / 2) end
			B24X.Damage(enemy, sorcerer, damage, B24X.MAGIC)
		end
		refresh(sorcerer)
		B24.Log(string.format("%s: Warping Implosion", B24.Name(sorcerer)))
	end)
end

---------------
-- Clockwork --
---------------

B24LV.AddResource("RESTORE_BALANCE", { spell = "B24CBALN", localName = "B24RBUSE",
	max = function(sprite) return isClockwork(sprite) and B24.ProfOf(sprite) or 0 end })
B24LV.AddResource("TRANCE_OF_ORDER", { localName = "B24TOUSE",
	max = function(sprite) return isClockwork(sprite, 14) and 1 or 0 end })
B24LV.AddResource("CLOCKWORK_CAVALCADE", { localName = "B24CCUS2",
	max = function(sprite) return isClockwork(sprite, 18) and 1 or 0 end })

function B24CBALN(op402, target)
	EEex_Utility_TryIgnore(function()
		local sorcerer = B24.GetSprite(op402.m_sourceId) or target
		B24LV.Use(sorcerer, "RESTORE_BALANCE")
		B24.SetTimed(target, "BALANCED", 6)
		B24.Log(string.format("%s: Restore Balance on %s", B24.Name(sorcerer), B24.Name(target)))
	end)
end

table.insert(B24.NoAdvantageAgainstListeners, function(sprite)
	return B24.HasTimed(sprite, "BALANCED") or B24.HasTimed(sprite, "TRANCE_OF_ORDER")
end)

-- Bastion of Law: up to 5 points (as many as are left).
function B24CBAST(op402, target)
	EEex_Utility_TryIgnore(function()
		local sorcerer = B24.GetSprite(op402.m_sourceId) or target
		local points = math.min(5, pointsLeft(sorcerer))
		if points <= 0 or not B24SO.SpendPoints(sorcerer, points) then return end
		B24LV.TempHP(target, B24LV.Dice(points, 8), 28800)
		refresh(sorcerer)
		B24.Log(string.format("%s: Bastion of Law (%d points) on %s", B24.Name(sorcerer), points, B24.Name(target)))
	end)
end

function B24CTRAN(op402, sorcerer)
	EEex_Utility_TryIgnore(function()
		if not useOrPoints(sorcerer, "TRANCE_OF_ORDER", 5) then return end
		B24.SetTimed(sorcerer, "TRANCE_OF_ORDER", 60)
		refresh(sorcerer)
		B24.Log(string.format("%s: Trance of Order", B24.Name(sorcerer)))
	end)
end

B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not B24.HasTimed(sprite, "TRANCE_OF_ORDER") or total - mod >= 10 then return nil end
	return 10 + mod
end)

function B24CCAVL(op402, sorcerer)
	EEex_Utility_TryIgnore(function()
		if not useOrPoints(sorcerer, "CLOCKWORK_CAVALCADE", 7) then return end
		local pool = 100
		for _, ally in ipairs(B24X.Allies(sorcerer, B24.Feet(30))) do
			local missing = ally:getStat(B24.Stat.MAXHP) - ally.m_baseStats.m_hitPoints
			local amount = math.min(pool, math.max(0, missing))
			if amount > 0 then
				B24.Heal(ally, amount)
				pool = pool - amount
			end
		end
		refresh(sorcerer)
		B24.Log(string.format("%s: Clockwork Cavalcade", B24.Name(sorcerer)))
	end)
end

----------------
-- Wild Magic --
----------------

B24LV.AddResource("TIDES_OF_CHAOS", { spell = "B24WTIDE", localName = "B24TCUSE",
	max = function(sprite) return isWild(sprite) and 1 or 0 end })

function B24WTIDE(op402, sorcerer)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sorcerer, "TIDES_OF_CHAOS")
		B24.SetTimed(sorcerer, "ATTACK_ADV", 6)
		B24.SetTimed(sorcerer, "SAVE_ADV", 6)
		B24.Aux(sorcerer).B24_TidesUsed = true
		B24.Log(string.format("%s: Tides of Chaos", B24.Name(sorcerer)))
	end)
end

-- The surge table: kind = how welcome the result is (Controlled Chaos keeps the higher one).
B24XS = {}
B24XS.SURGES = {
	{ kind = 1, text = "a burst of flame engulfs everyone within 10 ft (2d6 fire, Dexterity save for half)",
	  run = function(s)
		local dc = B24.SpellSaveDC(s, "SPWI000")
		local victims = B24X.Enemies(s, B24.Feet(10))
		for _, ally in ipairs(B24X.Allies(s, B24.Feet(10))) do table.insert(victims, ally) end
		for _, victim in ipairs(victims) do
			local damage = B24LV.Dice(2, 6)
			if B24.RollSave(victim, "DEX", dc, nil, " (Wild Magic Surge)") then damage = math.floor(damage / 2) end
			B24X.Damage(victim, s, damage, B24X.FIRE)
		end
	  end },
	{ kind = 1, text = "you glow brightly: attacks against you have advantage for a minute",
	  run = function(s) B24.SetTimed(s, "GRANTS_ADV", 60) end },
	{ kind = 1, text = "you are slowed for a minute",
	  run = function(s) B24.ApplyEffect(s, { ["effectID"] = 176, ["effectAmount"] = 50, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 60 }) end },
	{ kind = 2, text = "you turn invisible for a minute",
	  run = function(s) B24.ApplyEffect(s, { ["effectID"] = 20, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60 }) end },
	{ kind = 2, text = "you move twice as fast for a minute",
	  run = function(s) B24.ApplyEffect(s, { ["effectID"] = 176, ["effectAmount"] = 200, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 60 }) end },
	{ kind = 2, text = "you regain 2d10 hit points",
	  run = function(s) B24.Heal(s, B24LV.Dice(2, 10)) end },
	{ kind = 3, text = "lightning leaps to the nearest enemy (4d10 lightning, Dexterity save for half)",
	  run = function(s)
		local enemy = B24X.Enemies(s, B24.Feet(60))[1]
		if enemy == nil then return end
		local damage = B24LV.Dice(4, 10)
		if B24.RollSave(enemy, "DEX", B24.SpellSaveDC(s, "SPWI000"), nil, " (Wild Magic Surge)") then damage = math.floor(damage / 2) end
		B24X.Damage(enemy, s, damage, B24X.LIGHTNING)
	  end },
	{ kind = 3, text = "enemies within 30 ft make a Wisdom save or are frightened for a round",
	  run = function(s)
		local dc = B24.SpellSaveDC(s, "SPWI000")
		for _, enemy in ipairs(B24X.Enemies(s, B24.Feet(30))) do
			if not B24.RollSave(enemy, "WIS", dc, nil, " (Wild Magic Surge)", { FEAR = true }) then
				B24.ApplyEffect(enemy, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 6, ["sourceID"] = s.m_id })
			end
		end
	  end },
	{ kind = 3, text = "allies within 30 ft gain 2d6 temporary hit points",
	  run = function(s) for _, ally in ipairs(B24X.Allies(s, B24.Feet(30))) do B24LV.TempHP(ally, B24LV.Dice(2, 6), 600) end end },
	{ kind = 3, text = "a spent level 1 spell returns",
	  run = function(s) B24.ApplyEffect(s, { ["effectID"] = 261, ["effectAmount"] = 1, ["dwFlags"] = 0 }) end },
}

function B24XS.Surge(sorcerer)
	local surge = B24XS.SURGES[B24.Roll(#B24XS.SURGES)]
	if isWild(sorcerer, 14) then
		local other = B24XS.SURGES[B24.Roll(#B24XS.SURGES)]
		if other.kind > surge.kind then surge = other end
	end
	B24.Log(string.format("%s: Wild Magic Surge - %s", B24.Name(sorcerer), surge.text))
	EEex_Utility_TryIgnore(surge.run, sorcerer)
	-- A surge restores Tides of Chaos.
	sorcerer:setLocalInt("B24TCUSE", 0)
	B24LV.Rebuild(sorcerer, "TIDES_OF_CHAOS")
	B24.Aux(sorcerer).B24_TidesUsed = nil
end

table.insert(B24.SpellCastListeners, function(sprite, res)
	if not isWild(sprite) or res:sub(1, 4) ~= "SPWI" then return end
	local header = EEex_Resource_Demand(res, "SPL")
	if header == nil or EEex_Read32(EEex_UDToPtr(header) + 0x34) < 1 then return end
	if not B24LV.OncePerRound(sprite, "WILD_SURGE") then return end
	local aux = B24.Aux(sprite)
	if aux.B24_TidesUsed or B24.Roll(20) == 20 then B24XS.Surge(sprite) end
end)

-- Bend Luck: once per round, 1 point: +1d4 to an ally's failed save.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not B24.InParty(sprite) then return nil end
	for _, sorcerer in ipairs(B24.Party()) do
		if sorcerer.m_id ~= sprite.m_id and isWild(sorcerer, 6) and pointsLeft(sorcerer) > 0 then
			for _, ally in ipairs(B24X.Allies(sorcerer, B24.Feet(30))) do
				if ally.m_id == sprite.m_id and B24LV.OncePerRound(sorcerer, "BEND_LUCK") then
					local roll = B24.Roll(4)
					if total + roll < dc then return nil end
					B24SO.SpendPoints(sorcerer, 1)
					B24.Log(string.format("%s: Bend Luck, +%d", B24.Name(sorcerer), roll))
					return total + roll
				end
			end
		end
	end
	return nil
end)

----------------------
-- Clockwork Spells --
----------------------

-- Clockwork Spells (Clockwork 3): the subclass spells BG has, as innate copies, each once per long
-- rest (the engine adds no spells to a sorcerer's known spells, and sorcerer slots can't be
-- spent from here): Protection from Evil and Good, Aid and Lesser Restoration at 3; Dispel Magic
-- and Protection from Energy (fire, cold) at 5; Freedom of Movement at 7; Greater Restoration at
-- 9. Alarm, Summon Construct and Wall of Force have no BG spell. Local B24CKSU (used, a bit each).
B24XS.CLOCKWORK_SPELLS = { { res = "SPWI113", level = 3 }, { res = "SPPR201", level = 3 }, { res = "SPPR417", level = 3 },
	{ res = "SPWI302", level = 5 }, { res = "SPWI319", level = 5 }, { res = "SPWI320", level = 5 },
	{ res = "SPPR403", level = 7 }, { res = "SPPR713", level = 9 } }

function B24XS.RefreshClockwork(sprite)
	if not isClockwork(sprite) then return end
	local l = level(sprite)
	local used = sprite:getLocalInt("B24CKSU")
	for i, spell in ipairs(B24XS.CLOCKWORK_SPELLS) do
		local copy = B24.InnateCopy(spell.res)
		if EEex_Resource_Demand(copy, "SPL") then
			B24LV.Grant(sprite, copy, l >= spell.level and not EEex_IsBitSet(used, i - 1))
		end
	end
end

table.insert(B24.SpellCastListeners, function(sprite, res)
	if not isClockwork(sprite) then return end
	res = res:upper()
	for i, spell in ipairs(B24XS.CLOCKWORK_SPELLS) do
		if B24.InnateCopy(spell.res) == res then
			sprite:setLocalInt("B24CKSU", EEex_BOr(sprite:getLocalInt("B24CKSU"), EEex_LShift(1, i - 1)))
		end
	end
end)

B24LV.AddApplyListener(function(sprite) B24XS.RefreshClockwork(sprite) end)
B24.AddLongRestListener(function(sprite)
	sprite:setLocalInt("B24CKSU", 0)
	B24XS.RefreshClockwork(sprite)
end)

-----------------
-- Tamed Surge --
-----------------

-- Tamed Surge (Wild Magic 18), once per long rest: right after casting a spell (within a round),
-- the Tamed Surge innate lets you choose the surge instead of rolling it. Local B24TSUSE.
B24LV.AddResource("TAMED_SURGE", { spell = "B24WTAME", localName = "B24TSUSE",
	max = function(sprite) return isWild(sprite, 18) and 1 or 0 end })

table.insert(B24.SpellCastListeners, function(sprite, res)
	if isWild(sprite, 18) and res:upper():sub(1, 4) == "SPWI" then B24.Aux(sprite).B24_LastSpellTick = B24.GameTick() end
end)

function B24WTAME(op402, sprite)
	EEex_Utility_TryIgnore(function()
		-- The innate stays until a surge is chosen.
		B24LV.Rebuild(sprite, "TAMED_SURGE")
		local last = B24.Aux(sprite).B24_LastSpellTick
		if last == nil or B24.GameTick() - last > 90 then
			B24.Log(string.format("%s: Tamed Surge works only right after you cast a spell", B24.Name(sprite)))
			return
		end
		local list = {}
		for i, surge in ipairs(B24XS.SURGES) do
			table.insert(list, { index = i, name = surge.text:sub(1, 1):upper() .. surge.text:sub(2), desc = "Wild Magic Surge: " .. surge.text .. "." })
		end
		B24LV.OpenChoice(sprite, { title = "Tamed Surge", list = list,
			help = "Choose the Wild Magic Surge that your spell sets off.",
			onChoose = function(sorcerer, choice)
				B24LV.Use(sorcerer, "TAMED_SURGE")
				local surge = B24XS.SURGES[choice.index]
				B24.Log(string.format("%s: Tamed Surge - %s", B24.Name(sorcerer), surge.text))
				EEex_Utility_TryIgnore(surge.run, sorcerer)
				sorcerer:setLocalInt("B24TCUSE", 0)
				B24LV.Rebuild(sorcerer, "TIDES_OF_CHAOS")
			end })
	end)
end
