-- BG 2024 Rules Mod: Bard subclasses beyond the SRD (College of Dance, College of Glamour, College
-- of Valor). Feature texts are this mod's own wording.
--
-- Dance
--   3  Dazzling Footwork (without armor or shield: AC 10 + Dexterity + Charisma; unarmed strikes
--      use Dexterity and roll your Bardic Inspiration die for damage; Dance Virtuoso: no BG effect)
--   6  Inspiring Movement, Tandem Footwork (no BG effect: no reactions or initiative)
--   14 Leading Evasion (Evasion for you and allies next to you)
-- Glamour
--   3  Beguiling Magic (in BG an innate ability, once per long rest or for a Bardic Inspiration
--      use: a creature makes a Wisdom save or is frightened for a minute), Mantle of Inspiration
--      (a Bardic Inspiration use: up to Charisma modifier allies gain twice a die roll in temporary
--      hit points)
--   6  Mantle of Majesty (once per long rest: for a minute, each round, a creature makes a Wisdom
--      save or falls prone, standing in for the Command spell)
--   14 Unbreakable Majesty (once per short rest: attacks against you have disadvantage for a minute)
-- Valor
--   3  Combat Inspiration (a creature with your Bardic Inspiration also adds the die to the damage
--      of its next hit), Martial Training (martial weapons)
--   6  Extra Attack
--   14 Battle Magic (casting a spell gives you an extra attack that round)
--
-- Locals: B24GBUSE (Beguiling Magic), B24GMUSE (Mantle of Majesty), B24GUUSE (Unbreakable Majesty).

local function level(sprite) return B24BD.Level(sprite) end
local function cha(sprite) return B24.AbilityModOf(sprite, "CHA") end

local function isDance(sprite, l) return B24LV.Is(sprite, "BARD", "DANCE", l or 3) end
local function isGlamour(sprite, l) return B24LV.Is(sprite, "BARD", "GLAMOUR", l or 3) end
local function isValor(sprite, l) return B24LV.Is(sprite, "BARD", "VALOR", l or 3) end

B24LV.AddMoreSubclasses("BARD", {
	{ key = "DANCE", name = "College of Dance",
	  desc = "Your magic flows from movement.\n\nLevel 3: Dazzling Footwork (without armor or shield: AC 10 + Dexterity + Charisma; your unarmed strikes use Dexterity and deal your Bardic Inspiration die).\nLevel 14: Leading Evasion (Evasion for you and allies next to you).\nInspiring Movement and Tandem Footwork have no BG effect.",
	  features = { [3] = "Dazzling Footwork", [6] = "Inspiring Movement, Tandem Footwork (no BG effect)", [14] = "Leading Evasion" } },
	{ key = "GLAMOUR", name = "College of Glamour",
	  desc = "Fey charm weaves through your performance.\n\nLevel 3: Beguiling Magic (a creature makes a Wisdom save or is frightened for a minute; once per long rest, then for Bardic Inspiration), Mantle of Inspiration (spend Bardic Inspiration: allies gain temporary hit points).\nLevel 6: Mantle of Majesty (for a minute you can command a creature each round: Wisdom save or it falls prone).\nLevel 14: Unbreakable Majesty (attacks against you have disadvantage for a minute, once per short rest).",
	  features = { [3] = "Beguiling Magic, Mantle of Inspiration", [6] = "Mantle of Majesty", [14] = "Unbreakable Majesty" } },
	{ key = "VALOR", name = "College of Valor",
	  desc = "Skalds who sing of deeds and fight beside the heroes.\n\nLevel 3: Combat Inspiration (your Bardic Inspiration also adds to the damage of the next hit), Martial Training (martial weapons).\nLevel 6: Extra Attack.\nLevel 14: Battle Magic (casting a spell gives you an extra attack that round).",
	  features = { [3] = "Combat Inspiration, Martial Training", [6] = "Extra Attack", [14] = "Battle Magic" } },
})

local function unarmored(sprite)
	local items = sprite.m_equipment.m_items
	local armor, shield = items:get(1), items:get(9)
	return not ((armor ~= nil and armor.pRes.pHeader.itemType == 2) or (shield ~= nil and shield.pRes.pHeader.itemType == 12))
end

local function isFist(item)
	return item ~= nil and item.pRes.pHeader.itemType == 28
end

-----------
-- Dance --
-----------

B24.AddStatListener(function(sprite)
	if not isDance(sprite) or not unarmored(sprite) then return end
	local stats = sprite:getActiveStats()
	stats.m_nArmorClass = stats.m_nArmorClass - B24.AbilityMod(stats.m_nCHR)
end)

B24.AddFinesseListener(function(sprite, item)
	return isDance(sprite) and isFist(item)
end)

table.insert(B24WPN.DamageListeners, function(context)
	local bard = context.attacker
	if not isDance(bard) or not isFist(context.weapon) then return end
	local die = B24BD.Die(bard)
	if context.effect.m_diceSize < die then
		context.effect.m_diceSize = die
		context.effect.m_numDice = math.max(1, context.effect.m_numDice)
	end
end)

B24.AddEvasionListener(function(sprite)
	if not B24.InParty(sprite) then return false end
	for _, bard in ipairs(B24.Party()) do
		if isDance(bard, 14) then
			for _, ally in ipairs(B24X.Allies(bard, B24.ADJACENT)) do
				if ally.m_id == sprite.m_id then return true end
			end
		end
	end
	return false
end)

-------------
-- Glamour --
-------------

B24LV.AddResource("BEGUILING_MAGIC", { localName = "B24GBUSE",
	max = function(sprite) return isGlamour(sprite) and 1 or 0 end })
B24LV.AddResource("MANTLE_OF_MAJESTY", { spell = "B24GMAJE", localName = "B24GMUSE",
	max = function(sprite) return isGlamour(sprite, 6) and 1 or 0 end })
B24LV.AddResource("UNBREAKABLE_MAJESTY", { spell = "B24GUNBR", localName = "B24GUUSE", shortRest = "all",
	max = function(sprite) return isGlamour(sprite, 14) and 1 or 0 end })

local function refreshGlamour(sprite)
	local inspiration = B24LV.Remaining(sprite, "BARDIC_INSPIRATION") > 0
	B24LV.Grant(sprite, "B24GBEGU", isGlamour(sprite) and (B24LV.Remaining(sprite, "BEGUILING_MAGIC") > 0 or inspiration))
	B24LV.Grant(sprite, "B24GMANT", isGlamour(sprite) and inspiration)
	B24LV.Grant(sprite, "B24GCMND", isGlamour(sprite, 6) and B24.HasTimed(sprite, "MANTLE_OF_MAJESTY"))
end

B24LV.AddApplyListener(refreshGlamour)
B24.AddLongRestListener(function(sprite) if isGlamour(sprite) then refreshGlamour(sprite) end end)
B24.AddShortRestListener(function(sprite) if isGlamour(sprite) then refreshGlamour(sprite) end end)

-- Spends the free use first, then Bardic Inspiration.
local function spendBeguiling(bard)
	if B24LV.Use(bard, "BEGUILING_MAGIC") then return true end
	if B24LV.Use(bard, "BARDIC_INSPIRATION") then
		B24LV.Rebuild(bard, "BARDIC_INSPIRATION")
		return true
	end
	return false
end

function B24GBEGU(op402, target)
	EEex_Utility_TryIgnore(function()
		local bard = B24.GetSprite(op402.m_sourceId)
		if bard == nil or not spendBeguiling(bard) then return end
		local dc = B24.SpellSaveDC(bard, "SPWI000")
		if not B24.RollSave(target, "WIS", dc, nil, " (Beguiling Magic)", { FEAR = true, SOURCE = bard.m_id }) then
			B24.ApplyEffect(target, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 60, ["sourceID"] = bard.m_id })
		end
		refreshGlamour(bard)
	end)
end

-- Mantle of Inspiration: up to Charisma modifier allies within 60 ft (the bard first).
function B24GMANT(op402, bard)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Use(bard, "BARDIC_INSPIRATION") then return end
		B24LV.Rebuild(bard, "BARDIC_INSPIRATION")
		local amount = 2 * B24.Roll(B24BD.Die(bard))
		local count = math.max(1, cha(bard))
		for _, ally in ipairs(B24X.Allies(bard, B24.Feet(60))) do
			if count <= 0 then break end
			count = count - 1
			B24LV.TempHP(ally, amount, 3600)
		end
		refreshGlamour(bard)
		B24.Log(string.format("%s: Mantle of Inspiration, %d temporary hit points", B24.Name(bard), amount))
	end)
end

function B24GMAJE(op402, bard)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(bard, "MANTLE_OF_MAJESTY")
		B24.SetTimed(bard, "MANTLE_OF_MAJESTY", 60)
		refreshGlamour(bard)
		B24.Log(string.format("%s: Mantle of Majesty", B24.Name(bard)))
	end)
end

-- Command (Mantle of Majesty): once per round, Wisdom save or prone for a round.
function B24GCMND(op402, target)
	EEex_Utility_TryIgnore(function()
		local bard = B24.GetSprite(op402.m_sourceId)
		if bard == nil then return end
		refreshGlamour(bard)
		if not B24LV.OncePerRound(bard, "MAJESTY_COMMAND") then return end
		local dc = B24.SpellSaveDC(bard, "SPWI000")
		if not B24.RollSave(target, "WIS", dc, nil, " (Command)", { SOURCE = bard.m_id }) then
			B24.KnockProne(target, bard)
		end
	end)
end

function B24GUNBR(op402, bard)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(bard, "UNBREAKABLE_MAJESTY")
		B24.SetTimed(bard, "GRANTS_DIS", 60)
		B24.Log(string.format("%s: Unbreakable Majesty", B24.Name(bard)))
	end)
end

-- Mantle of Majesty ends after a minute.
B24LV.AddTickListener(function(sprite)
	if not isGlamour(sprite, 6) then return end
	local aux = B24.Aux(sprite)
	local active = B24.HasTimed(sprite, "MANTLE_OF_MAJESTY")
	if aux.B24_MajestyActive ~= active then
		aux.B24_MajestyActive = active
		refreshGlamour(sprite)
	end
end)

-----------
-- Valor --
-----------

B24.AddWeaponProficiencyListener(function(sprite)
	return isValor(sprite)
end)

B24LV.AddApplyListener(function(sprite)
	if isValor(sprite, 6) then B24LV.Permanent(sprite, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0 }) end
end)

-- Combat Inspiration: a Valor bard's inspiration also adds the die to the next hit's damage.
table.insert(B24WPN.DamageListeners, function(context)
	local attacker = context.attacker
	local inspired = B24.Aux(attacker).B24_Inspired
	if inspired == nil or inspired.by == nil or B24.GameTick() > inspired.untilTick then return end
	local bard = B24.GetSprite(inspired.by)
	if bard == nil or not isValor(bard) then return end
	B24.Aux(attacker).B24_Inspired = nil
	local roll = B24.Roll(inspired.die)
	context.effect.m_effectAmount = context.effect.m_effectAmount + roll
	B24.Log(string.format("%s adds Bardic Inspiration to the damage: +%d", B24.Name(attacker), roll))
end)

-- Battle Magic: an extra attack in the round the bard casts a spell.
table.insert(B24.SpellCastListeners, function(sprite, res)
	if not isValor(sprite, 14) then return end
	local prefix = res:sub(1, 4)
	if prefix ~= "SPWI" and prefix ~= "SPPR" and prefix ~= "B24C" then return end
	B24.ApplyEffect(sprite, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
	B24.Log(string.format("%s: Battle Magic", B24.Name(sprite)))
end)
