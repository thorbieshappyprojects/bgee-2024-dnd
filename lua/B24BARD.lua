-- BG 2024 Rules Mod: the 2024 Bard with the College of Lore (SRD subclass). Bard spells use the
-- Spells component (2024 slots; the bard keeps learning arcane spells, with bard-only copies of
-- the healing spells).
--
--   1  Bardic Inspiration (Charisma modifier uses; d6, d8 at 5, d10 at 10, d12 at 15),
--      Spellcasting, cantrips (2; 3 at 4, 4 at 10)
--   2  Expertise (2), Jack of All Trades
--   3  Subclass: Lore: Bonus Proficiencies (3 skills), Cutting Words
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Font of Inspiration (short rests restore Bardic Inspiration)
--   6  Lore: Magical Discoveries (two more Magical Secrets)
--   7  Countercharm
--   9  Expertise (2 more)
--   10 Magical Secrets (Cleric and Druid spells as innates; see below)
--   14 Lore: Peerless Skill (Bardic Inspiration on its own failed saves)
--   18 Superior Inspiration (two uses when a fight starts), 20 Words of Creation (Power Word Kill)
--
-- Bardic Inspiration: an ally keeps the die for an hour and adds it to its next failed save (BG
-- has no ability checks and reports no misses). Cutting Words: once per round the first weapon
-- hit against a party member near the bard loses one inspiration die of damage.
-- Locals: B24BIUSE (Bardic Inspiration spent).

B24BD = {}

function B24BD.Level(sprite)
	return B24LV.ClassLevel(sprite, "BARD")
end

function B24BD.Die(sprite)
	local level = B24BD.Level(sprite)
	return level >= 15 and 12 or level >= 10 and 10 or level >= 5 and 8 or 6
end

B24LV.AddSubclasses("BARD", 3, {
	{ key = "LORE", name = "College of Lore",
	  desc = "Bards of Lore collect knowledge from every source.\n\nLevel 3: Bonus Proficiencies (three skills), Cutting Words (spend Bardic Inspiration to reduce a hit against an ally).\nLevel 6: Magical Discoveries (two more Cleric or Druid spells).\nLevel 14: Peerless Skill (spend Bardic Inspiration on your own failed saves; BG reports no failed checks or missed attacks).",
	  features = { [3] = "Bonus Proficiencies, Cutting Words", [6] = "Magical Discoveries", [14] = "Peerless Skill" } },
})

local function isLore(sprite)
	return B24LV.Subclass(sprite, "BARD") == "LORE"
end

B24LV.AddResource("BARDIC_INSPIRATION", { spell = "B24BINSP", localName = "B24BIUSE",
	max = function(sprite)
		if B24BD.Level(sprite) <= 0 then return 0 end
		return math.max(1, B24.AbilityModOf(sprite, "CHA"))
	end })

-- Font of Inspiration from level 5: short rests restore all uses (before, only long rests).
B24.AddShortRestListener(function(sprite)
	if B24BD.Level(sprite) >= 5 then
		sprite:setLocalInt("B24BIUSE", 0)
		B24LV.Rebuild(sprite, "BARDIC_INSPIRATION")
	end
end)

B24BD.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24BD.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24BD.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, CANTRIP = 2 + (level >= 4 and 1 or 0) + (level >= 10 and 1 or 0),
		EXPERTISE = (level >= 9 and 4) or (level >= 2 and 2) or 0 }
end)

B24BD.FEATURES = {
	[1] = "Bardic Inspiration (d6), Spellcasting, cantrips (2)",
	[2] = "Expertise (2 skills), Jack of All Trades",
	[3] = "Subclass",
	[4] = "Ability Score Improvement, cantrips (3)",
	[5] = "Bardic Inspiration (d8), Font of Inspiration",
	[7] = "Countercharm",
	[8] = "Ability Score Improvement",
	[9] = "Expertise (2 more skills)",
	[10] = "Bardic Inspiration (d10), cantrips (4), Magical Secrets (two Cleric or Druid spells)",
	[12] = "Ability Score Improvement",
	[14] = "Magical Secrets (four spells)",
	[15] = "Bardic Inspiration (d12)",
	[16] = "Ability Score Improvement",
	[18] = "Superior Inspiration, Magical Secrets (six spells)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Words of Creation (Power Word Kill always prepared)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24BD.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "BARD") + 1, level do
		if B24BD.FEATURES[l] then table.insert(lines, string.format("Bard %d: %s", l, B24BD.FEATURES[l])) end
	end
	return lines
end)

------------------------
-- Bardic Inspiration --
------------------------

-- op402 entry point of B24BINSP.SPL (cast on an ally): the ally keeps an inspiration die for an
-- hour.
function B24BINSP(op402, target)
	EEex_Utility_TryIgnore(function()
		local bard = B24.GetSprite(op402.m_sourceId)
		if bard == nil then return end
		B24LV.Use(bard, "BARDIC_INSPIRATION")
		B24.Aux(target).B24_Inspired = { die = B24BD.Die(bard), by = bard.m_id, untilTick = B24.GameTick() + 54000 }
		B24.Log(string.format("%s inspires %s (d%d)", B24.Name(bard), B24.Name(target), B24BD.Die(bard)))
	end)
end

B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	local inspired = B24.Aux(sprite).B24_Inspired
	if inspired == nil or B24.GameTick() > inspired.untilTick then return nil end
	B24.Aux(sprite).B24_Inspired = nil
	local roll = B24.Roll(inspired.die)
	B24.Log(string.format("%s adds Bardic Inspiration to the %s save: +%d", B24.Name(sprite), ability, roll))
	return total + roll
end)

-- Cutting Words (Lore): once per round, a hit against a party member near the bard loses one
-- inspiration die of damage (spends a use).
table.insert(B24WPN.DamageListeners, function(context)
	local target = context.target
	if not B24.InParty(target) then return end
	for _, bard in ipairs(B24.Party()) do
		if B24BD.Level(bard) >= 3 and isLore(bard) and B24LV.Remaining(bard, "BARDIC_INSPIRATION") > 0 then
			local aux = B24.Aux(bard)
			local now = B24.GameTick()
			local near = bard.m_id == target.m_id
			if not near then
				for _, ally in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(bard, "[PC]", B24.Feet(60), true) or {}) do
					if ally.m_id == target.m_id then near = true break end
				end
			end
			if near and (aux.B24_CuttingTick == nil or now - aux.B24_CuttingTick >= 90) then
				aux.B24_CuttingTick = now
				B24LV.Use(bard, "BARDIC_INSPIRATION")
				B24WPN.RollDiceInto(context.effect)
				local cut = B24.Roll(B24BD.Die(bard))
				context.effect.m_effectAmount = math.max(0, context.effect.m_effectAmount - cut)
				B24.Log(string.format("%s: Cutting Words, -%d damage", B24.Name(bard), cut))
				return
			end
		end
	end
end)

-------------------------------------------------------
-- Jack of All Trades, Lore proficiencies, Countercharm --
-------------------------------------------------------

-- Jack of All Trades: half the Proficiency Bonus to skills without proficiency.
B24.AddSkillBonusListener(function(sprite, key)
	if B24BD.Level(sprite) < 2 then return 0 end
	local proficient = B24.Proficiencies(sprite)
	if proficient[key] then return 0 end
	return math.floor(B24.ProfOf(sprite) / 2)
end)

-- Lore Bonus Proficiencies: three skills (the first of this list the bard isn't proficient in).
B24BD.LORE_SKILLS = { "ARCANA", "HISTORY", "INSIGHT", "PERCEPTION", "INVESTIGATION", "NATURE", "RELIGION" }
B24.AddGrantedSkillListener(function(sprite, proficient)
	if B24BD.Level(sprite) < 3 or not isLore(sprite) then return end
	local added = 0
	for _, key in ipairs(B24BD.LORE_SKILLS) do
		if added < 3 and not proficient[key] then
			proficient[key] = true
			added = added + 1
		end
	end
end)

-- Countercharm (7): party members near the bard have advantage on saves against charm and fear.
B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	if not (conditions.CHARM or conditions.FEAR) or not B24.InParty(sprite) then return false end
	for _, bard in ipairs(B24.Party()) do
		if B24BD.Level(bard) >= 7 and not B24.GState_Has(bard, B24.GState.DEAD) then
			if bard.m_id == sprite.m_id then return true end
			for _, ally in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(bard, "[PC]", B24.Feet(30), true) or {}) do
				if ally.m_id == sprite.m_id then return true end
			end
		end
	end
	return false
end)

-- Portrait icon while the creature holds an unused Bardic Inspiration die.
B24.AddIconListener(function(sprite, keys)
	local inspired = B24.Aux(sprite).B24_Inspired
	if inspired ~= nil and B24.GameTick() <= inspired.untilTick then keys.BINS = true end
end)

-----------------------
-- Magical Secrets --
-----------------------

-- Magical Secrets (10) and the Lore Bard's Magical Discoveries (6): Cleric and Druid spells (the
-- bard learns every wizard spell from scrolls already). BG keeps priest spells out of the arcane
-- spellbook, so the picked spells are innate copies (B24IP...), granted while the bard has a ready
-- (memorized, unused) spell of their level or higher; casting one spends the lowest such slot,
-- with Charisma. 2024 opens these lists for every spell the bard prepares; here two spells at 10,
-- four at 14 and six at 18, and two more for Magical Discoveries. Words of Creation (20): Power
-- Word Kill always in the spellbook (Power Word Heal has no BG spell).
-- Locals: B24BMS1.. (spells picked).

local priestSpells
local function spellLevel(res)
	local header = EEex_Resource_Demand(res, "SPL")
	return header and EEex_Read32(EEex_UDToPtr(header) + 0x34) or 0
end

local function spellDescription(res)
	local header = EEex_Resource_Demand(res, "SPL")
	local ref = header and EEex_Read32(EEex_UDToPtr(header) + 0x50) or -1
	return ref > 0 and Infinity_FetchString(ref) or ""
end

-- Cleric and druid spells of the catalog, sorted by resref (the order picks are stored in).
function B24BD.PriestSpells()
	if priestSpells then return priestSpells end
	priestSpells = {}
	local ok, catalog = pcall(B24.LoadTable, "B24SPELL")
	if not ok or catalog == nil then return priestSpells end
	local keys = {}
	for res, row in pairs(catalog) do
		local lists = row.LISTS or ""
		if res:sub(1, 4) == "SPPR" and row.ACTION ~= "DROP" and (lists:find("C", 1, true) or lists:find("D", 1, true))
			and EEex_Resource_Demand(res, "SPL") then
			table.insert(keys, res)
		end
	end
	table.sort(keys)
	for _, res in ipairs(keys) do
		local level = spellLevel(res)
		local name = (catalog[res].NAME or res):gsub("_", " ")
		table.insert(priestSpells, { key = res, res = res, level = level, name = string.format("%s (level %d)", name, level) })
	end
	for _, entry in ipairs(priestSpells) do entry.desc = spellDescription(entry.res) end
	return priestSpells
end

local function secretsCount(sprite)
	local level = B24BD.Level(sprite)
	local count = level >= 18 and 6 or level >= 14 and 4 or level >= 10 and 2 or 0
	if level >= 6 and isLore(sprite) then count = count + 2 end
	return count
end

B24LV.AddPick({ key = "SECRETS", prefix = "B24BMS", title = "Magical Secrets",
	help = "Choose a Cleric or Druid spell. You cast it as an innate ability with your own spell slots (Charisma).",
	list = B24BD.PriestSpells,
	count = function(sprite)
		if #B24BD.PriestSpells() == 0 then return 0 end
		return secretsCount(sprite)
	end,
	allowed = function(sprite, entry)
		return entry.level >= 1 and B24SP and entry.level <= B24SP.MageSlotLevel(sprite)
	end })

B24BD.WORDS_OF_CREATION = "SPWI912"

-- { res, level } of every spell the bard casts this way.
local function secrets(sprite)
	local list = {}
	if B24BD.Level(sprite) <= 0 then return list end
	for _, entry in ipairs(B24LV.Picked(sprite, "SECRETS")) do table.insert(list, entry) end
	return list
end

function B24BD.RefreshSecrets(sprite)
	if B24SP == nil or B24SP.ReadySlotLevel == nil then return end
	for _, entry in ipairs(secrets(sprite)) do
		B24LV.Grant(sprite, B24.InnateCopy(entry.res), B24SP.ReadySlotLevel(sprite, true, entry.level) ~= nil)
	end
	-- Words of Creation (20): Power Word Kill in the spellbook, always there to prepare.
	if B24BD.Level(sprite) >= 20 and EEex_Resource_Demand(B24BD.WORDS_OF_CREATION, "SPL") then
		B24.ApplyEffect(sprite, { ["effectID"] = 147, ["res"] = B24BD.WORDS_OF_CREATION })
	end
end

local function secretSpell(sprite, res)
	res = B24.OriginalSpellRes(res)
	for _, entry in ipairs(secrets(sprite)) do
		if entry.res == res then return entry end
	end
end

-- Casting one spends the lowest ready slot of its level; the innates follow once the cast is over.
table.insert(B24.SpellCastListeners, function(sprite, res)
	local entry = secretSpell(sprite, res:upper())
	if entry == nil or B24SP == nil then return end
	local slot = B24SP.SpendSlot(sprite, true, entry.level)
	if slot then B24.Log(string.format("%s casts %s with a level %d slot", B24.Name(sprite), entry.name, slot)) end
	B24.Aux(sprite).B24_SecretsRefresh = B24.GameTick() + 120
end)

B24LV.AddTickListener(function(sprite)
	local aux = B24.Aux(sprite)
	if aux.B24_SecretsRefresh and B24.GameTick() >= aux.B24_SecretsRefresh then
		aux.B24_SecretsRefresh = nil
		B24BD.RefreshSecrets(sprite)
	end
end)

B24LV.AddApplyListener(function(sprite) B24BD.RefreshSecrets(sprite) end)
B24.AddLongRestListener(function(sprite) B24BD.RefreshSecrets(sprite) end)

table.insert(B24.CastingAbilityListeners, function(sprite, res)
	if B24BD.Level(sprite) > 0 and secretSpell(sprite, res:upper()) then return "CHA" end
	return nil
end)

-- Peerless Skill (Lore 14): BG reports no missed attacks or failed checks; the bard spends a
-- Bardic Inspiration die on its own failed save instead.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if B24BD.Level(sprite) < 14 or not isLore(sprite) then return nil end
	if total + B24BD.Die(sprite) < dc or not B24LV.Spend(sprite, "BARDIC_INSPIRATION", 1) then return nil end
	local roll = B24.Roll(B24BD.Die(sprite))
	B24.Log(string.format("%s: Peerless Skill on the %s save, +%d", B24.Name(sprite), ability, roll))
	return total + roll
end)

-- Superior Inspiration (18): a fight starts with at least two Bardic Inspiration uses.
B24.AddCombatStartListener(function(sprite)
	if B24BD.Level(sprite) < 18 or B24LV.Remaining(sprite, "BARDIC_INSPIRATION") >= 2 then return end
	local max = B24LV.RESOURCES.BARDIC_INSPIRATION.max(sprite)
	sprite:setLocalInt("B24BIUSE", math.max(0, max - 2))
	B24LV.Rebuild(sprite, "BARDIC_INSPIRATION")
	B24.Log(string.format("%s: Superior Inspiration", B24.Name(sprite)))
end)
