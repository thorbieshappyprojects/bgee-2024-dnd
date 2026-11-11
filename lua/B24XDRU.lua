-- BG 2024 Rules Mod: Druid subclasses beyond the SRD (Circle of the Moon, Circle of the Sea, Circle
-- of the Stars). Feature texts are this mod's own wording. Circle spells are not granted yet.
--
-- Moon (works with the 2024 Wild Shape in B24DRUID.lua)
--   3  Circle Forms (forms up to Challenge Rating 1, 2 from level 6; AC at least 13 + Wisdom
--      modifier; temporary hit points of three times the Druid level; both in B24DRUID.lua)
--   6  Improved Circle Forms (Wisdom modifier to Constitution saves while shapeshifted)
--   10 Moonlight Step (Misty Step, Wisdom modifier times per long rest; needs the Spells component)
--   14 Lunar Form (once per round, a hit while shapeshifted deals 2d10 extra radiant damage)
-- Sea (spends this mod's Wild Shape uses: 2 at 2, 3 at 6, 4 at 17; one returns on a short rest)
--   3  Wrath of the Sea (a Wild Shape use: for 10 minutes, once per round an enemy within 5 ft -
--      10 ft from level 6 - makes a Constitution save or takes Wisdom modifier d6 cold damage and is
--      pushed away)
--   6  Aquatic Affinity (the bigger aura; swimming has no BG effect)
--   10 Stormborn (resistance to cold and lightning while the Wrath lasts; flight has no BG effect)
--   14 Oceanic Gift (no BG effect)
-- Stars
--   3  Star Map (Guiding Bolt, Wisdom modifier times per long rest; needs the Spells component),
--      Starry Form (a Wild Shape use, 10 minutes): Archer (Luminous Arrow: a ranged spell attack
--      each round, 1d8 + Wisdom modifier radiant), Chalice (your healing spells also heal the most
--      hurt ally nearby for 1d8 + Wisdom modifier), Dragon (Constitution saves count a d20 of 9 or
--      less as 10)
--   6  Cosmic Omen (Wisdom modifier uses: a nearby ally's failed save gets +1d6)
--   10 Twinkling Constellations (2d8; change the constellation while the form lasts)
--   14 Full of Stars (resistance to bludgeoning, piercing and slashing in Starry Form)
--
-- Locals: B24WSUSE (Wild Shape uses), B24MSUSE (Moonlight Step), B24SMUSE2 (Star Map), B24OMUSE
-- (Cosmic Omen).

local function wis(sprite) return B24.AbilityModOf(sprite, "WIS") end

local function isMoon(sprite, l) return B24LV.Is(sprite, "DRUID", "MOON", l or 3) end
local function isSea(sprite, l) return B24LV.Is(sprite, "DRUID", "SEA", l or 3) end
local function isStars(sprite, l) return B24LV.Is(sprite, "DRUID", "STARS", l or 3) end

B24LV.AddMoreSubclasses("DRUID", {
	{ key = "MOON", name = "Circle of the Moon",
	  desc = "You take the shapes of beasts and the moon's power with them (through Wild Shape).\n\nLevel 3: Circle Forms (beast forms up to Challenge Rating 1, and 2 from level 6; in beast form your AC is at least 13 + Wisdom modifier; three times your Druid level in temporary hit points).\nLevel 6: Improved Circle Forms (Wisdom modifier to Constitution saves while shapeshifted).\nLevel 10: Moonlight Step (Misty Step, Wisdom modifier times per long rest).\nLevel 14: Lunar Form (once per round a hit in beast form deals 2d10 extra radiant damage).\nCircle spells follow later.",
	  features = { [3] = "Circle Forms", [6] = "Improved Circle Forms", [10] = "Moonlight Step", [14] = "Lunar Form" } },
	{ key = "SEA", name = "Circle of the Sea",
	  desc = "The tides and storms answer you.\n\nLevel 3: Wrath of the Sea (spend a Wild Shape use: for 10 minutes, each round an enemy next to you makes a Constitution save or takes cold damage and is pushed away).\nLevel 6: Aquatic Affinity (the aura reaches 10 ft).\nLevel 10: Stormborn (resistance to cold and lightning while the Wrath lasts).\nOceanic Gift has no BG effect. Circle spells follow later.",
	  features = { [3] = "Wrath of the Sea", [6] = "Aquatic Affinity", [10] = "Stormborn", [14] = "Oceanic Gift (no BG effect)" } },
	{ key = "STARS", name = "Circle of the Stars",
	  desc = "You read the constellations and take their shapes.\n\nLevel 3: Star Map (free Guiding Bolts), Starry Form (spend a Wild Shape use: Archer - a radiant arrow each round; Chalice - your healing spells heal an extra ally; Dragon - Constitution saves don't roll below 10).\nLevel 6: Cosmic Omen (add 1d6 to an ally's failed save).\nLevel 10: Twinkling Constellations (2d8, change constellation while the form lasts).\nLevel 14: Full of Stars (resistance to weapon damage in Starry Form).",
	  features = { [3] = "Star Map, Starry Form", [6] = "Cosmic Omen", [10] = "Twinkling Constellations", [14] = "Full of Stars" } },
})

-- The Wild Shape pool belongs to every Druid (B24DRUID.lua); these circles add their powers to it.
for _, power in ipairs({
	{ res = "B24SWRAT", when = function(s) return isSea(s) end },
	{ res = "B24STARC", when = function(s) return isStars(s) end },
	{ res = "B24STCHL", when = function(s) return isStars(s) end },
	{ res = "B24STDRG", when = function(s) return isStars(s) end },
}) do
	table.insert(B24LV.RESOURCES.WILD_SHAPE.powers, power)
end

----------
-- Moon --
----------

B24LV.AddResource("MOONLIGHT_STEP", { spell = "B24MSTEP", localName = "B24MSUSE",
	max = function(sprite) return isMoon(sprite, 10) and math.max(1, wis(sprite)) or 0 end })

B24.AddSaveBonusListener(function(sprite, ability)
	if ability ~= "CON" or not isMoon(sprite, 6) or B24.Aux(sprite).B24_Form == nil then return 0 end
	return math.max(0, wis(sprite))
end)

table.insert(B24WPN.DamageListeners, function(context)
	local druid = context.attacker
	if not isMoon(druid, 14) or B24.Aux(druid).B24_Form == nil or not B24LV.OncePerRound(druid, "LUNAR_FORM") then return end
	local damage = B24LV.Dice(2, 10)
	B24X.Damage(context.target, druid, damage, B24X.MAGIC)
	B24.Log(string.format("%s: Lunar Form, %d radiant damage", B24.Name(druid), damage))
end)

---------
-- Sea --
---------

function B24SWRAT(op402, druid)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Spend(druid, "WILD_SHAPE", 1) then return end
		B24.SetTimed(druid, "WRATH_OF_THE_SEA", 600)
		if isSea(druid, 10) then
			for _, opcode in ipairs({ 28, 29 }) do
				B24.ApplyEffect(druid, { ["effectID"] = opcode, ["effectAmount"] = 50, ["dwFlags"] = 0,
					["durationType"] = 0, ["duration"] = 600, ["m_sourceRes"] = "B24SWRAT" })
			end
		end
		B24.Log(string.format("%s: Wrath of the Sea", B24.Name(druid)))
	end)
end

B24LV.AddTickListener(function(druid)
	if not B24.HasTimed(druid, "WRATH_OF_THE_SEA") or not B24LV.OncePerRound(druid, "WRATH_OF_THE_SEA") then return end
	local enemy = B24X.Enemies(druid, isSea(druid, 6) and 120 or 80)[1]
	if enemy == nil then return end
	local dc = B24.SpellSaveDC(druid, "SPPR000")
	if not B24.RollSave(enemy, "CON", dc, nil, " (Wrath of the Sea)", { SOURCE = druid.m_id }) then
		B24X.Damage(enemy, druid, B24LV.Dice(math.max(1, wis(druid)), 6), B24X.COLD)
		B24.ForceMove(enemy, druid, 15, false, B24.SIZE.LARGE)
	end
end)

-----------
-- Stars --
-----------

B24LV.AddResource("STAR_MAP", { spell = "B24GBOLT", localName = "B24SMUS2",
	max = function(sprite) return isStars(sprite) and math.max(1, wis(sprite)) or 0 end })

B24LV.AddResource("COSMIC_OMEN", { localName = "B24OMUSE",
	max = function(sprite) return isStars(sprite, 6) and math.max(1, wis(sprite)) or 0 end })

local function starDice(druid) return isStars(druid, 10) and 2 or 1 end

local function constellation(druid)
	return B24.HasTimed(druid, "STARRY_FORM") and B24.Aux(druid).B24_Constellation or nil
end

local function refreshStars(druid)
	B24LV.RefreshPowers(druid, "WILD_SHAPE")
	local active = constellation(druid) ~= nil
	-- Twinkling Constellations: the forms stay available to switch while one lasts.
	if active and isStars(druid, 10) then
		for _, res in ipairs({ "B24STARC", "B24STCHL", "B24STDRG" }) do B24LV.Grant(druid, res, true) end
	end
	B24LV.Grant(druid, "B24STARW", constellation(druid) == "ARCHER")
end

local function takeForm(druid, key)
	if constellation(druid) and isStars(druid, 10) then
		-- Switching keeps the form's remaining time.
	elseif not B24LV.Spend(druid, "WILD_SHAPE", 1) then
		return
	else
		B24.SetTimed(druid, "STARRY_FORM", 600)
		if isStars(druid, 14) then
			for _, opcode in ipairs({ 86, 87, 88, 89 }) do
				B24.ApplyEffect(druid, { ["effectID"] = opcode, ["effectAmount"] = 50, ["dwFlags"] = 0,
					["durationType"] = 0, ["duration"] = 600, ["m_sourceRes"] = "B24STARF" })
			end
		end
	end
	B24.Aux(druid).B24_Constellation = key
	refreshStars(druid)
	B24.Log(string.format("%s: Starry Form (%s)", B24.Name(druid), key:sub(1, 1) .. key:sub(2):lower()))
end

function B24STARC(op402, druid) EEex_Utility_TryIgnore(takeForm, druid, "ARCHER") end
function B24STCHL(op402, druid) EEex_Utility_TryIgnore(takeForm, druid, "CHALICE") end
function B24STDRG(op402, druid) EEex_Utility_TryIgnore(takeForm, druid, "DRAGON") end

-- Luminous Arrow (Archer): once per round, a ranged spell attack.
function B24STARW(op402, target)
	EEex_Utility_TryIgnore(function()
		local druid = B24.GetSprite(op402.m_sourceId)
		if druid == nil then return end
		refreshStars(druid)
		if constellation(druid) ~= "ARCHER" or not B24LV.OncePerRound(druid, "LUMINOUS_ARROW") then return end
		local hit, critical = B24SP and B24SP.SpellAttack(druid, target, "SPPR000", "Luminous Arrow")
		if not hit then return end
		local dice = starDice(druid) * (critical and 2 or 1)
		B24X.Damage(target, druid, B24LV.Dice(dice, 8) + wis(druid), B24X.MAGIC)
	end)
end

-- The form ends: take the arrow away again.
B24LV.AddTickListener(function(druid)
	if not isStars(druid) then return end
	local aux = B24.Aux(druid)
	local active = constellation(druid) ~= nil
	if aux.B24_StarActive ~= active then
		aux.B24_StarActive = active
		refreshStars(druid)
	end
end)

-- Chalice: healing spells also heal the most hurt ally within 30 ft.
B24LV.WhenSpells(function()
	table.insert(B24SP.HealBonusListeners, function(caster, target, spellLevel)
		if constellation(caster) ~= "CHALICE" or spellLevel < 1 then return 0 end
		local best, missing = nil, 0
		for _, ally in ipairs(B24X.Allies(caster, B24.Feet(30))) do
			local gap = ally:getStat(B24.Stat.MAXHP) - ally.m_baseStats.m_hitPoints
			if ally.m_id ~= target.m_id and gap > missing then best, missing = ally, gap end
		end
		if best then B24.Heal(best, B24LV.Dice(starDice(caster), 8) + wis(caster)) end
		return 0
	end)
end)

-- Dragon: a Constitution save's d20 of 9 or less counts as 10.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if ability ~= "CON" or constellation(sprite) ~= "DRAGON" then return nil end
	if total - mod >= 10 then return nil end
	B24.Log(string.format("%s: Dragon constellation, the d20 counts as 10", B24.Name(sprite)))
	return 10 + mod
end)

-- Cosmic Omen: once per round, a party member near the druid adds 1d6 to a failed save.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not B24.InParty(sprite) then return nil end
	for _, druid in ipairs(B24.Party()) do
		if isStars(druid, 6) and B24LV.Remaining(druid, "COSMIC_OMEN") > 0 then
			for _, ally in ipairs(B24X.Allies(druid, B24.Feet(30))) do
				if ally.m_id == sprite.m_id and B24LV.OncePerRound(druid, "COSMIC_OMEN") then
					B24LV.Use(druid, "COSMIC_OMEN")
					local roll = B24.Roll(6)
					B24.Log(string.format("%s: Cosmic Omen, +%d", B24.Name(druid), roll))
					return total + roll
				end
			end
		end
	end
	return nil
end)
