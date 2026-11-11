-- BG 2024 Rules Mod: origin feats and background proficiencies (component 3).
--
-- Character creation stores the background and a human's extra feat in creature locals (see
-- B24CHGEN.lua); the in-game party setup turns the feats into effects once (background skills are
-- proficiencies, read by B24PROF.lua):
--   B24BGSET  1 once the background's feat has been applied
--
-- Loaded after both B24CORE (core rules) and B24CHGEN (feat and background data).

B24FEAT = {}

B24FEAT.SOURCE_RES = "B24BG"
B24FEAT.MAGIC_INITIATE_CLERIC = "B24MICL"
B24FEAT.MAGIC_INITIATE_WIZARD = "B24MIWZ"
B24FEAT.MAGIC_INITIATE_DRUID = "B24MIDR"
B24FEAT.BATTLE_MEDIC = "B24HEALR"
-- Savage Attacker works once per round (6 seconds of game time at 15 ticks per second).
B24FEAT.SAVAGE_INTERVAL = 90

-- Skill and tool proficiencies per background (see B24PROF.lua for what they do in BG).
B24FEAT.BACKGROUND_SKILLS = {
	[1] = { "INSIGHT", "RELIGION" },                          -- Acolyte
	[2] = { "SLEIGHT_OF_HAND", "STEALTH", "THIEVES_TOOLS" },  -- Criminal
	[3] = { "ARCANA", "HISTORY" },                            -- Sage
	[4] = { "ATHLETICS", "INTIMIDATION" },                    -- Soldier
	[5] = { "INVESTIGATION", "PERSUASION" },                  -- Artisan
	[6] = { "DECEPTION", "SLEIGHT_OF_HAND" },                 -- Charlatan
	[7] = { "ACROBATICS", "PERFORMANCE" },                    -- Entertainer
	[8] = { "ANIMAL_HANDLING", "NATURE" },                    -- Farmer
	[9] = { "ATHLETICS", "PERCEPTION" },                      -- Guard
	[10] = { "STEALTH", "SURVIVAL" },                         -- Guide
	[11] = { "MEDICINE", "RELIGION" },                        -- Hermit
	[12] = { "ANIMAL_HANDLING", "PERSUASION" },               -- Merchant
	[13] = { "HISTORY", "PERSUASION" },                       -- Noble
	[14] = { "ACROBATICS", "PERCEPTION" },                    -- Sailor
	[15] = { "INVESTIGATION", "PERCEPTION" },                 -- Scribe
	[16] = { "INSIGHT", "STEALTH", "THIEVES_TOOLS" },          -- Wayfarer
}
-- Skilled: three proficiencies, chosen in character creation (local B24SKFT, a skill mask);
-- without a choice the first three of this list the character isn't proficient in yet.
B24FEAT.SKILLED_DEFAULTS = { "PERCEPTION", "STEALTH", "INSIGHT", "ATHLETICS", "PERSUASION", "ARCANA" }

local function permanent(sprite, opcode, amount, param2)
	B24.ApplyEffect(sprite, {
		["effectID"] = opcode, ["effectAmount"] = amount, ["dwFlags"] = param2 or 0,
		["durationType"] = 9, ["m_sourceRes"] = B24FEAT.SOURCE_RES,
	})
end

-- Feat ids are indices of B24CG.FEATS.
function B24FEAT.FeatsOf(sprite)
	local feats = {}
	local bg = B24CG.BACKGROUNDS[sprite:getLocalInt("B24BG")]
	if bg then table.insert(feats, bg.feat) end
	local extra = sprite:getLocalInt("B24FEAT2")
	if B24CG.FEATS[extra] then table.insert(feats, extra) end
	return feats
end

function B24FEAT.Has(sprite, key)
	for _, id in ipairs(B24FEAT.FeatsOf(sprite)) do
		if B24CG.FEATS[id].key == key then return true end
	end
	-- Origin feats taken at an Ability Score Improvement (B24GFEAT.lua, Classes component).
	return B24GF ~= nil and B24GF.Has(sprite, key)
end

local grant = {
	-- No initiative in BG: faster casting and attacks instead.
	ALERT = function(sprite)
		permanent(sprite, 189, 1, 0)
		permanent(sprite, 190, 1, 0)
	end,
	MI_CLERIC = function(sprite)
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = B24FEAT.MAGIC_INITIATE_CLERIC })
	end,
	MI_WIZARD = function(sprite)
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = B24FEAT.MAGIC_INITIATE_WIZARD })
	end,
	MI_DRUID = function(sprite)
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = B24FEAT.MAGIC_INITIATE_DRUID })
	end,
	HEALER = function(sprite)
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = B24FEAT.BATTLE_MEDIC })
	end,
	-- Run time features (below; Crafter is part of the social bonus in B24PROF.lua).
	CRAFTER = function(sprite) end,
	LUCKY = function(sprite) end,
	MUSICIAN = function(sprite) end,
	TAVERN_BRAWLER = function(sprite) end,
	TOUGH = function(sprite) end,
	-- Checked in the damage hook below.
	SAVAGE = function(sprite) end,
	-- Proficiencies, see the listener below.
	SKILLED = function(sprite) end,
}
B24FEAT.GRANT = grant

B24.AddGrantedSkillListener(function(sprite, proficient)
	for _, key in ipairs(B24FEAT.BACKGROUND_SKILLS[sprite:getLocalInt("B24BG")] or {}) do
		proficient[key] = true
	end
	if B24FEAT.Has(sprite, "SKILLED") then
		local chosen = sprite:getLocalInt("B24SKFT")
		if chosen ~= 0 then
			for i, skill in ipairs(B24.SKILLS) do
				if EEex_IsBitSet(chosen, i - 1) then proficient[skill.key] = true end
			end
		else
			local added = 0
			for _, key in ipairs(B24FEAT.SKILLED_DEFAULTS) do
				if added < 3 and not proficient[key] then
					proficient[key] = true
					added = added + 1
				end
			end
		end
	end
end)

local function needsBackground(sprite)
	return sprite:getLocalInt("B24BG") > 0 and sprite:getLocalInt("B24BGSET") == 0
end

function B24FEAT.ApplyBackground(sprite)
	sprite:setLocalInt("B24BGSET", 1)
	local bgID = sprite:getLocalInt("B24BG")
	local bg = B24CG.BACKGROUNDS[bgID]
	local names = {}
	for _, id in ipairs(B24FEAT.FeatsOf(sprite)) do
		local feat = B24CG.FEATS[id]
		grant[feat.key](sprite)
		table.insert(names, feat.name)
	end
	B24.Log(string.format("%s: %s background, %s", B24.Name(sprite), bg.name, table.concat(names, ", ")))
end

-- Runs from the same global script block as the core party setup.
local originalNeedsSetup = B24_PartyNeedsSetup
local originalSetup = B24_SetupParty

function B24_PartyNeedsSetup()
	if originalNeedsSetup() then return true end
	for _, member in ipairs(B24.Party()) do
		if needsBackground(member) then return true end
	end
	return false
end

function B24_SetupParty()
	originalSetup()
	for _, member in ipairs(B24.Party()) do
		if needsBackground(member) then
			EEex_Utility_TryIgnore(B24FEAT.ApplyBackground, member)
		end
	end
end

---------------------
-- Savage Attacker --
---------------------

local function isAttacking(sprite)
	local id = sprite.m_curAction.m_actionID
	return id == 3 or id == 94 or id == 98 or id == 105 or id == 134
end

-- Rolls the weapon's damage dice twice and keeps the higher roll, once per round.
function B24FEAT.SavageAttack(effect, source)
	if effect.m_numDice <= 0 or effect.m_diceSize <= 0 or not isAttacking(source) then return end
	if not B24FEAT.Has(source, "SAVAGE") then return end
	local aux = B24.Aux(source)
	local now = B24.GameTick()
	if aux.B24_SavageTick and now - aux.B24_SavageTick < B24FEAT.SAVAGE_INTERVAL then return end
	aux.B24_SavageTick = now
	local function roll()
		local total = 0
		for i = 1, effect.m_numDice do total = total + B24.Roll(effect.m_diceSize) end
		return total
	end
	local a, b = roll(), roll()
	effect.m_effectAmount = effect.m_effectAmount + math.max(a, b)
	effect.m_numDice = 0
	B24.Log(string.format("%s: Savage Attacker rolls %d and %d, keeps %d", B24.Name(source), a, b, math.max(a, b)))
end

local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	if B24.IsSprite(sourceSprite) then
		EEex_Utility_TryIgnore(B24FEAT.SavageAttack, effect, sourceSprite)
	end
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

------------------------------------------------------------
-- Healer, Lucky, Musician, Tavern Brawler, Tough        --
------------------------------------------------------------

-- Battle Medic (B24HEALR, cast on a creature, once per short rest): the creature spends one of its
-- Hit Point Dice and regains the roll plus the healer's Proficiency Bonus. Healing Rerolls are in
-- B24SPELL.lua (B24HEAL).
function B24HEALR(op402, target)
	EEex_Utility_TryIgnore(function()
		local healer = B24.GetSprite(op402.m_sourceId) or target
		if B24.HitDice_Remaining(target) <= 0 then
			B24.Log(string.format("%s has no Hit Point Dice left", B24.Name(target)))
		else
			target:setLocalInt("B24HDUSE", target:getLocalInt("B24HDUSE") + 1)
			local roll = B24.Roll(B24.HitDie(target))
			if roll == 1 then roll = B24.Roll(B24.HitDie(target)) end
			local healed = math.max(1, roll + B24.ProfOf(healer))
			B24.Heal(target, healed)
			B24.Log(string.format("%s: Battle Medic, %s regains %d hit points", B24.Name(healer), B24.Name(target), healed))
		end
	end)
end

local function regrantMedic(sprite)
	if not B24FEAT.Has(sprite, "HEALER") then return end
	B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = B24FEAT.BATTLE_MEDIC })
	B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = B24FEAT.BATTLE_MEDIC })
end

-- Lucky: Proficiency Bonus Luck Points per long rest (local B24LKUSE spent); a failed save is
-- rolled again while points are left.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not B24FEAT.Has(sprite, "LUCKY") or sprite:getLocalInt("B24LKUSE") >= B24.ProfOf(sprite) then return nil end
	sprite:setLocalInt("B24LKUSE", sprite:getLocalInt("B24LKUSE") + 1)
	local roll = B24.Roll(20)
	B24.Log(string.format("%s: Lucky, rerolls the %s save: %d", B24.Name(sprite), ability, roll + mod))
	return roll + mod
end)

-- Musician: after a rest, up to Proficiency Bonus party members gain Heroic Inspiration.
local function encourage(sprite)
	if not B24FEAT.Has(sprite, "MUSICIAN") then return end
	local left = B24.ProfOf(sprite)
	for _, member in ipairs(B24.Party()) do
		if left <= 0 then break end
		if not B24.Inspiration_Has(member) then
			B24.Inspiration_Grant(member)
			left = left - 1
		end
	end
end

B24.AddShortRestListener(function(sprite)
	regrantMedic(sprite)
	encourage(sprite)
end)
B24.AddLongRestListener(function(sprite)
	sprite:setLocalInt("B24LKUSE", 0)
	regrantMedic(sprite)
	encourage(sprite)
end)

-- Tavern Brawler: fists deal at least 1d4, dice that roll 1 are rolled again, and once per round a
-- hit pushes the target 5 feet.
table.insert(B24WPN.DamageListeners, function(context)
	local weapon = context.weapon
	if weapon == nil or weapon.pRes.pHeader.itemType ~= 28 or not B24FEAT.Has(context.attacker, "TAVERN_BRAWLER") then return end
	local effect = context.effect
	if effect.m_diceSize < 4 then
		effect.m_diceSize = 4
		effect.m_numDice = math.max(1, effect.m_numDice)
	end
	local total = 0
	for i = 1, effect.m_numDice do
		local roll = B24.Roll(effect.m_diceSize)
		if roll == 1 then roll = B24.Roll(effect.m_diceSize) end
		total = total + roll
	end
	effect.m_effectAmount = effect.m_effectAmount + total
	effect.m_numDice = 0
	local aux = B24.Aux(context.attacker)
	local now = B24.GameTick()
	if aux.B24_BrawlTick == nil or now - aux.B24_BrawlTick >= 90 or now < aux.B24_BrawlTick then
		aux.B24_BrawlTick = now
		B24.ForceMove(context.target, context.attacker, 5)
	end
end)

-- Tough: twice the character level in extra maximum hit points.
B24.AddStatListener(function(sprite)
	-- Characters without a background (companions) may take Tough at an improvement (B24GFN).
	if (sprite:getLocalInt("B24BG") == 0 and sprite:getLocalInt("B24GFN") == 0) or not B24FEAT.Has(sprite, "TOUGH") then return end
	local stats = sprite:getActiveStats()
	stats.m_nMaxHitPoints = stats.m_nMaxHitPoints + 2 * B24.Level(sprite)
end)
