-- BG 2024 Rules Mod: feats at the Ability Score Improvement levels (Classes component). Each
-- improvement can be taken as the Ability Score Improvement or as a feat the character qualifies
-- for: the PHB 2024 general feats that have a BG effect (own wording) and the origin feats.
-- Feats that need BG-less mechanics (mounts, opportunity attacks, rituals, telepathy, armor
-- training) are left out. Feats that raise an ability (+1, at most 20) are offered once per
-- ability; Resilient once per ability, Elemental Adept once per damage type.
--
-- Locals: B24GFN (feats taken), B24GF1.. (feat index * 100 + variant), B24GFDUR (Speedy Recovery
-- used), B24GFMSL (Mage Slayer used), B24GFST1/2 (Fey/Shadow Touched spells used).

B24GF = {}

local STR, DEX, CON, INT, WIS, CHA = "STR", "DEX", "CON", "INT", "WIS", "CHA"
B24GF.ABILITIES = { STR, DEX, CON, INT, WIS, CHA }
B24GF.ABILITY_NAMES = { STR = "Strength", DEX = "Dexterity", CON = "Constitution", INT = "Intelligence", WIS = "Wisdom", CHA = "Charisma" }
B24GF.ABILITY_OPCODES = { STR = 44, DEX = 15, CON = 10, INT = 19, WIS = 49, CHA = 6 }
local MENTAL = { INT, WIS, CHA }

B24GF.ELEMENTS = {
	{ key = "ACID", name = "acid", flag = 0x10000 }, { key = "COLD", name = "cold", flag = 0x20000 },
	{ key = "FIRE", name = "fire", flag = 0x80000 }, { key = "LIGHTNING", name = "lightning", flag = 0x40000 },
}

local function score(sprite, ability) return B24.AbilityScore(sprite, ability) end
local function atLeast13(...)
	local abilities = { ... }
	return function(sprite)
		for _, ability in ipairs(abilities) do
			if score(sprite, ability) >= 13 then return true end
		end
		return false
	end
end

B24GF.FEATS = {
	{ key = "ACTOR", name = "Actor", abilities = { CHA }, require = atLeast13(CHA),
	  desc = "You slip into other roles with ease.\nIn BG: dialogues and stores count your Charisma 2 higher on top of your social skills." },
	{ key = "ATHLETE", name = "Athlete", abilities = { STR, DEX }, require = atLeast13(STR, DEX),
	  desc = "Climbing, jumping and getting up are second nature to you.\nIn BG: the ability increase (BG has no climbing or jumping)." },
	{ key = "CHARGER", name = "Charger", abilities = { STR, DEX }, require = atLeast13(STR, DEX),
	  desc = "You hit hardest on the move.\nIn BG: once per round, a hit after you have moved this round deals 1d8 extra damage." },
	{ key = "CHEF", name = "Chef", abilities = { CON, WIS },
	  desc = "Your cooking restores the body.\nIn BG: after a short rest, every party member regains 1d8 extra hit points." },
	{ key = "CROSSBOW_EXPERT", name = "Crossbow Expert", abilities = { DEX }, require = atLeast13(DEX),
	  desc = "You handle crossbows with deadly speed.\nIn BG: no penalty for shooting a crossbow at enemies next to you." },
	{ key = "CRUSHER", name = "Crusher", abilities = { STR, CON },
	  desc = "Your blunt weapons send foes reeling.\nIn BG: once per round a bludgeoning hit pushes a target no more than one size larger than you 5 ft; after a critical bludgeoning hit, attacks against the target have advantage for a round." },
	{ key = "DEFENSIVE_DUELIST", name = "Defensive Duelist", abilities = { DEX }, require = atLeast13(DEX),
	  desc = "You parry with a nimble blade.\nIn BG: +1 AC while you wield a finesse weapon (standing in for the reaction)." },
	{ key = "DURABLE", name = "Durable", abilities = { CON },
	  desc = "Hardy and resilient.\nIn BG: Speedy Recovery, an innate ability once per short rest: spend one Hit Point Die and regain that many hit points." },
	{ key = "ELEMENTAL_ADEPT", name = "Elemental Adept", abilities = MENTAL, elements = true, require = function(sprite)
		return B24LV.CasterLetters(sprite) ~= "" end,
	  desc = "Your spells of one element burn through.\nIn BG: damage dice of your spells of that type count a 1 as 2. The ability increase goes to your best casting ability." },
	{ key = "FEY_TOUCHED", name = "Fey Touched", abilities = MENTAL,
	  desc = "The Feywild's magic touched you.\nIn BG: Misty Step and Command as innate abilities, each once per long rest." },
	{ key = "GRAPPLER", name = "Grappler", abilities = { STR, DEX }, require = atLeast13(STR, DEX),
	  desc = "You are a wrestler.\nIn BG: Grapple, an innate ability once per round: a creature next to you makes a Strength or Dexterity save or is grappled (no movement; it saves again each round); you have advantage on attacks against creatures you grapple." },
	{ key = "GREAT_WEAPON_MASTER", name = "Great Weapon Master", abilities = { STR }, require = atLeast13(STR),
	  desc = "You swing heavy weapons with brutal force.\nIn BG: once per round a hit with a two-handed melee weapon deals extra damage equal to your Proficiency Bonus; a critical hit gives one extra attack that round." },
	{ key = "HEAVY_ARMOR_MASTER", name = "Heavy Armor Master", abilities = { STR, CON },
	  desc = "Your armor turns blows.\nIn BG: while you wear heavy armor, weapon damage against you is reduced by your Proficiency Bonus." },
	{ key = "INSPIRING_LEADER", name = "Inspiring Leader", abilities = { WIS, CHA }, require = atLeast13(WIS, CHA),
	  desc = "Your words steel your companions.\nIn BG: after a short or long rest, up to six party members gain temporary hit points equal to your level + your Wisdom or Charisma modifier." },
	{ key = "KEEN_MIND", name = "Keen Mind", abilities = { INT }, require = atLeast13(INT),
	  desc = "Your mind misses nothing.\nIn BG: proficiency in Investigation and History." },
	{ key = "MAGE_SLAYER", name = "Mage Slayer", abilities = { STR, DEX },
	  desc = "You are trained against spellcasters.\nIn BG: Guarded Mind, once per short rest a failed Intelligence, Wisdom or Charisma save succeeds." },
	{ key = "MARTIAL_WEAPON_TRAINING", name = "Martial Weapon Training", abilities = { STR, DEX },
	  desc = "You learned to fight with real weapons.\nIn BG: proficiency with martial weapons." },
	{ key = "MEDIUM_ARMOR_MASTER", name = "Medium Armor Master", abilities = { STR, DEX },
	  desc = "You move freely in medium armor.\nIn BG: medium armor lets you add up to +3 Dexterity to your AC instead of +2." },
	{ key = "OBSERVANT", name = "Observant", abilities = { INT, WIS }, require = atLeast13(INT, WIS),
	  desc = "Quick to notice details.\nIn BG: proficiency in Perception." },
	{ key = "PIERCER", name = "Piercer", abilities = { STR, DEX },
	  desc = "Your thrusts find the gaps.\nIn BG: once per round, damage dice of a piercing hit count a 1 as 2; a critical piercing hit deals one extra die." },
	{ key = "POLEARM_MASTER", name = "Polearm Master", abilities = { STR, DEX }, require = atLeast13(STR, DEX),
	  desc = "You strike with both ends of your weapon.\nIn BG: one extra attack per round with a halberd, spear or quarterstaff." },
	{ key = "RESILIENT", name = "Resilient", abilities = B24GF.ABILITIES, resilient = true,
	  desc = "You harden yourself against one kind of threat.\nIn BG: proficiency in the saving throws of the chosen ability, which also rises by 1." },
	{ key = "SHADOW_TOUCHED", name = "Shadow Touched", abilities = MENTAL,
	  desc = "The Shadowfell's magic clings to you.\nIn BG: Invisibility as an innate ability once per long rest." },
	{ key = "SHARPSHOOTER", name = "Sharpshooter", abilities = { DEX }, require = atLeast13(DEX),
	  desc = "Your shots find their mark.\nIn BG: no penalty for shooting at enemies next to you." },
	{ key = "SHIELD_MASTER", name = "Shield Master", abilities = { STR }, require = atLeast13(STR),
	  desc = "Your shield is a weapon and a wall.\nIn BG: with a shield, Dexterity saves for half damage take none on a success; once per round a melee hit makes the target save (Strength) or fall prone." },
	{ key = "SKULKER", name = "Skulker", abilities = { DEX }, require = atLeast13(DEX),
	  desc = "You keep to the shadows.\nIn BG: better at hiding and moving silently (+15%)." },
	{ key = "SLASHER", name = "Slasher", abilities = { STR, DEX },
	  desc = "Your cuts hamper foes.\nIn BG: once per round a slashing hit slows the target by 10 ft for a round; a critical slashing hit gives it disadvantage on attacks for a round." },
	{ key = "SPEEDY", name = "Speedy", abilities = { DEX, CON }, require = atLeast13(DEX, CON),
	  desc = "You are fast on your feet.\nIn BG: your speed rises by 10 ft." },
	{ key = "TELEKINETIC", name = "Telekinetic", abilities = MENTAL,
	  desc = "You move things with your mind.\nIn BG: Telekinetic Shove, an innate ability once per round: a creature within 30 ft makes a Strength save or is pushed 5 ft." },
	{ key = "WAR_CASTER", name = "War Caster", abilities = MENTAL, require = function(sprite)
		return B24LV.CasterLetters(sprite) ~= "" end,
	  desc = "You keep your spells going in the thick of battle.\nIn BG: advantage on Constitution saves to keep concentration." },
	{ key = "WEAPON_MASTER", name = "Weapon Master", abilities = { STR, DEX },
	  desc = "You master another weapon.\nIn BG: one more Weapon Mastery." },
}

-- Origin feats (character creation component) can be taken at an improvement too.
local function originFeats()
	local list = {}
	for i, feat in ipairs(B24CG and B24CG.FEATS or {}) do
		table.insert(list, { key = feat.key, name = feat.name, desc = feat.desc, origin = i, repeatable = feat.repeatable })
	end
	return list
end

-- All feats in a stable order: the general feats, the origin feats, then the Epic Boons (the
-- order keeps the numbers of feats already taken).
function B24GF.All()
	if B24GF.ALL == nil then
		B24GF.ALL = {}
		for _, feat in ipairs(B24GF.FEATS) do table.insert(B24GF.ALL, feat) end
		for _, feat in ipairs(originFeats()) do table.insert(B24GF.ALL, feat) end
		for _, feat in ipairs(B24GF.BOONS or {}) do table.insert(B24GF.ALL, feat) end
	end
	return B24GF.ALL
end

-- Feats taken: { { feat, variant } }.
function B24GF.Taken(sprite)
	local taken = {}
	local all = B24GF.All()
	for n = 1, sprite:getLocalInt("B24GFN") do
		local code = sprite:getLocalInt("B24GF" .. n)
		local feat = all[math.floor(code / 100)]
		if feat then table.insert(taken, { feat = feat, variant = code % 100 }) end
	end
	return taken
end

function B24GF.Has(sprite, key)
	for _, entry in ipairs(B24GF.Taken(sprite)) do
		if entry.feat.key == key then return true, entry.variant end
	end
	return false
end

local function variantsOf(sprite, key)
	local variants = {}
	for _, entry in ipairs(B24GF.Taken(sprite)) do
		if entry.feat.key == key then variants[entry.variant] = true end
	end
	return variants
end

local function bestCasting(sprite)
	local best, bestScore = INT, -1
	for _, ability in ipairs(MENTAL) do
		if score(sprite, ability) > bestScore then best, bestScore = ability, score(sprite, ability) end
	end
	return best
end

local function originTaken(sprite, feat)
	return B24FEAT ~= nil and B24FEAT.Has(sprite, feat.key)
end

-- Popup rows for the improvement popup (B24LEVEL.lua): { feat, variant, ability, label }.
function B24GF.Rows(sprite)
	local rows = {}
	for index, feat in ipairs(B24GF.All()) do
		local ok, qualifies = true, true
		if feat.require then ok, qualifies = pcall(feat.require, sprite) end
		local taken = variantsOf(sprite, feat.key)
		if ok and qualifies then
			if feat.origin then
				if feat.repeatable or not originTaken(sprite, feat) then
					table.insert(rows, { feat = feat, index = index, variant = 0, label = feat.name .. " (origin feat)" })
				end
			elseif feat.pairs then
				-- Boon of Energy Resistance: a pair of resistances, Constitution +1.
				if next(taken) == nil then
					for i, pair in ipairs(feat.pairs) do
						table.insert(rows, { feat = feat, index = index, variant = i, ability = CON,
							label = string.format("%s (%s, +1 Constitution)", feat.name, pair.name) })
					end
				end
			elseif feat.elements then
				for i, element in ipairs(B24GF.ELEMENTS) do
					if not taken[i] then
						table.insert(rows, { feat = feat, index = index, variant = i, ability = bestCasting(sprite),
							label = string.format("%s (%s)", feat.name, element.name) })
					end
				end
			elseif next(taken) == nil or feat.resilient then
				for i, ability in ipairs(B24GF.ABILITIES) do
					local allowed = false
					for _, a in ipairs(feat.abilities) do allowed = allowed or a == ability end
					if allowed and not taken[i] and (score(sprite, ability) < (feat.boon and B24GF.BOON_MAX or 20) or feat.resilient) then
						local label = feat.resilient and string.format("%s (%s)", feat.name, B24GF.ABILITY_NAMES[ability])
							or string.format("%s (+1 %s)", feat.name, B24GF.ABILITY_NAMES[ability])
						table.insert(rows, { feat = feat, index = index, variant = i, ability = ability, label = label })
					end
				end
			end
		end
	end
	return rows
end

-- Takes a feat from a popup row: +1 to its ability, one-time grants, then the features apply.
function B24GF.Take(sprite, row)
	local n = sprite:getLocalInt("B24GFN") + 1
	sprite:setLocalInt("B24GFN", n)
	sprite:setLocalInt("B24GF" .. n, row.index * 100 + row.variant)
	if row.ability and score(sprite, row.ability) < (row.feat.boon and B24GF.BOON_MAX or 20) then
		B24.ApplyEffect(sprite, { ["effectID"] = B24GF.ABILITY_OPCODES[row.ability], ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 1 })
	end
	if row.feat.origin and B24FEAT and B24FEAT.GRANT and B24FEAT.GRANT[row.feat.key] then
		EEex_Utility_TryIgnore(B24FEAT.GRANT[row.feat.key], sprite)
	end
end

local function has(sprite, key) return B24GF.Has(sprite, key) end

------------------------
-- Weapons and armor --
------------------------

local PIERCING, BLUDGEONING, SLASHING, MISSILE = 1, 2, 3, 4

local function damageType(context)
	local _, _, _, kind = B24WPN.AbilityDice(context.ability)
	return kind
end

table.insert(B24WPN.DamageListeners, function(context)
	local attacker, target, effect = context.attacker, context.target, context.effect
	if attacker:getLocalInt("B24GFN") == 0 then return end
	local kind = damageType(context)
	local pb = B24.ProfOf(attacker)
	-- Charger: once per round after moving.
	if has(attacker, "CHARGER") and B24RD and B24RD.moving[attacker.m_id] and B24RD.moving[attacker.m_id].moved >= 15
		and B24LV.OncePerRound(attacker, "CHARGER") then
		effect.m_effectAmount = effect.m_effectAmount + B24.Roll(8)
	end
	-- Crusher.
	if has(attacker, "CRUSHER") and kind == BLUDGEONING then
		if B24LV.OncePerRound(attacker, "CRUSHER") then
			-- No more than one size larger than the attacker.
			B24.ForceMove(target, attacker, 5, false, B24.Size(attacker) + 1)
		end
		if context.isCritical then B24.SetTimed(target, "GRANTS_ADV", 6) end
	end
	-- Great Weapon Master: two-handed melee weapons.
	local weapon = context.weapon
	if has(attacker, "GREAT_WEAPON_MASTER") and not context.launcher and weapon and EEex_IsBitSet(weapon.pRes.pHeader.itemFlags, 1) then
		if B24LV.OncePerRound(attacker, "GREAT_WEAPON_MASTER") then effect.m_effectAmount = effect.m_effectAmount + pb end
		if context.isCritical then
			B24.ApplyEffect(attacker, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
		end
	end
	-- Piercer.
	if has(attacker, "PIERCER") and (kind == PIERCING or kind == MISSILE) and B24LV.OncePerRound(attacker, "PIERCER") then
		local size = effect.m_diceSize
		B24WPN.RollDiceInto(effect, 2)
		if context.isCritical and size > 0 then effect.m_effectAmount = effect.m_effectAmount + B24.Roll(size) end
	end
	-- Slasher.
	if has(attacker, "SLASHER") and kind == SLASHING and B24LV.OncePerRound(attacker, "SLASHER") then
		B24.ApplyEffect(target, { ["effectID"] = 176, ["effectAmount"] = 67, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 6, ["sourceID"] = attacker.m_id })
		if context.isCritical then B24.SetTimed(target, "ATTACK_DIS", 6) end
	end
	-- Shield Master: shield bash.
	if has(attacker, "SHIELD_MASTER") and not context.launcher and B24GF.HasShield(attacker) and B24LV.OncePerRound(attacker, "SHIELD_BASH") then
		local dc = 8 + B24.ProfOf(attacker) + B24.AbilityModOf(attacker, STR)
		if not B24.RollSave(target, STR, dc, nil, " (Shield Master)") then
			B24.KnockProne(target, attacker)
		end
	end
end)

function B24GF.HasShield(sprite)
	local shield = sprite.m_equipment.m_items:get(9)
	return shield ~= nil and shield.pRes.pHeader.itemType == 12
end

-- Heavy Armor Master: weapon damage against the wearer of heavy armor.
table.insert(B24WPN.DamageListeners, function(context)
	local target = context.target
	if target:getLocalInt("B24GFN") == 0 or not has(target, "HEAVY_ARMOR_MASTER") then return end
	if not target:getSpellState(B24.SplState.ARMOR_HEAVY) then return end
	B24WPN.RollDiceInto(context.effect)
	context.effect.m_effectAmount = math.max(0, context.effect.m_effectAmount - B24.ProfOf(target))
end)

B24.AddStatListener(function(sprite)
	if sprite:getLocalInt("B24GFN") == 0 then return end
	local stats = sprite:getActiveStats()
	-- Defensive Duelist: +1 AC with a finesse weapon.
	if has(sprite, "DEFENSIVE_DUELIST") then
		local equipment = sprite.m_equipment
		local item = equipment.m_items:get(equipment.m_selectedWeapon)
		if item and B24.IsFinesse(sprite, item) then stats.m_nArmorClass = stats.m_nArmorClass - 1 end
	end
	-- Medium Armor Master: Dexterity up to +3 in medium armor (B24ADV.lua caps it at +2).
	if has(sprite, "MEDIUM_ARMOR_MASTER") and sprite:getSpellState(B24.SplState.ARMOR_MEDIUM) and B24.AbilityMod(stats.m_nDEX) >= 3 then
		stats.m_nArmorClass = stats.m_nArmorClass - 1
	end
end)

-- Sharpshooter (ranged weapons) and Crossbow Expert (crossbows): an enemy within 5 ft imposes no
-- disadvantage (B24ADV.lua's ranged attacks in melee); with the engine's penalty instead
-- (rangedInMelee2024 = false), no penalty for shooting at adjacent enemies.
local function firesInMelee(sprite, crossbow)
	if sprite:getLocalInt("B24GFN") == 0 then return false end
	return has(sprite, "SHARPSHOOTER") or (crossbow and has(sprite, "CROSSBOW_EXPERT"))
end

table.insert(B24.RangedInMeleeExemptListeners, function(sprite, crossbow)
	-- Spell attacks: neither feat covers them.
	return B24.spellAttackRanged == nil and firesInMelee(sprite, crossbow)
end)

local originalIgnore = EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty
function EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty(sprite, item, abilityNum)
	local ok, result = pcall(function()
		local crossbow = false
		if item ~= nil then
			local launcher = sprite:getLauncher(item:getAbility(abilityNum)) or item
			crossbow = launcher.pRes.pHeader.itemType == 27
		end
		return firesInMelee(sprite, crossbow)
	end)
	if ok and result then return true end
	return originalIgnore(sprite, item, abilityNum)
end

-- Martial Weapon Training.
B24.AddWeaponProficiencyListener(function(sprite)
	return sprite:getLocalInt("B24GFN") > 0 and has(sprite, "MARTIAL_WEAPON_TRAINING")
end)

-- Weapon Master: one more mastery per pick.
local originalMasteryCount = B24.MasteryCount
function B24.MasteryCount(sprite)
	local count = originalMasteryCount(sprite)
	if sprite:getLocalInt("B24GFN") == 0 then return count end
	for _, entry in ipairs(B24GF.Taken(sprite)) do
		if entry.feat.key == "WEAPON_MASTER" then count = count + 1 end
	end
	return count
end

-- Polearm Master: an extra attack while a halberd, spear or quarterstaff is in hand.
B24GF.POLEARMS = { [98] = true, [99] = true, [102] = true }
B24LV.AddTickListener(function(sprite)
	if sprite:getLocalInt("B24GFN") == 0 or not has(sprite, "POLEARM_MASTER") then return end
	B24.RemoveEffectsBySource(sprite, "B24POLE")
	if B24GF.POLEARMS[B24.SelectedWeaponProfType(sprite)] then
		B24.ApplyEffect(sprite, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 2,
			["m_sourceRes"] = "B24POLE" })
	end
end)

---------------------
-- Saves and skills --
---------------------

-- Resilient: save proficiency in the chosen abilities.
B24.AddSaveProficiencyListener(function(sprite, ability)
	if sprite:getLocalInt("B24GFN") == 0 then return false end
	for _, entry in ipairs(B24GF.Taken(sprite)) do
		if entry.feat.key == "RESILIENT" and B24GF.ABILITIES[entry.variant] == ability then return true end
	end
	return false
end)

-- War Caster: advantage on concentration saves.
B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	return conditions.CONCENTRATION == true and sprite:getLocalInt("B24GFN") > 0 and has(sprite, "WAR_CASTER"), false
end)

-- Mage Slayer: Guarded Mind, once per short rest.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if ability ~= INT and ability ~= WIS and ability ~= CHA then return nil end
	if sprite:getLocalInt("B24GFN") == 0 or not has(sprite, "MAGE_SLAYER") or sprite:getLocalInt("B24GFMSL") == 1 then return nil end
	sprite:setLocalInt("B24GFMSL", 1)
	B24.Log(string.format("%s: Guarded Mind turns the %s save into a success", B24.Name(sprite), ability))
	return dc
end)

-- Shield Master: Evasion with a shield.
B24.AddEvasionListener(function(sprite)
	return sprite:getLocalInt("B24GFN") > 0 and has(sprite, "SHIELD_MASTER") and B24GF.HasShield(sprite)
end)

-- Keen Mind and Observant.
B24.AddGrantedSkillListener(function(sprite, proficient)
	if sprite:getLocalInt("B24GFN") == 0 then return end
	if has(sprite, "KEEN_MIND") then
		proficient.INVESTIGATION = true
		proficient.HISTORY = true
	end
	if has(sprite, "OBSERVANT") then proficient.PERCEPTION = true end
end)

-- Skulker and Speedy.
B24LV.AddApplyListener(function(sprite)
	if sprite:getLocalInt("B24GFN") == 0 then return end
	if has(sprite, "SKULKER") then
		B24LV.Permanent(sprite, { ["effectID"] = 59, ["effectAmount"] = 15, ["dwFlags"] = 0 })
		B24LV.Permanent(sprite, { ["effectID"] = 275, ["effectAmount"] = 15, ["dwFlags"] = 0 })
	end
	if has(sprite, "SPEEDY") then
		B24LV.Permanent(sprite, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5 })
	end
end)

-- Elemental Adept: spell damage dice of the element count a 1 as 2.
B24LV.WhenSpells(function()
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if caster:getLocalInt("B24GFN") == 0 then return end
		for _, entry in ipairs(B24GF.Taken(caster)) do
			local element = entry.feat.key == "ELEMENTAL_ADEPT" and B24GF.ELEMENTS[entry.variant]
			if element and EEex_BAnd(effect.m_dWFlags, element.flag) ~= 0 then
				B24WPN.RollDiceInto(effect, 2)
				return
			end
		end
	end)
end)

---------------------------------------
-- Rests, innate abilities, spells --
---------------------------------------

B24LV.AddResource("FEAT_STEP", { spell = "B24MSTEP", localName = "B24GFST1",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "FEY_TOUCHED")) and 1 or 0 end })
-- Command and Invisibility as innate copies (B24IP102, B24IW206): a rebuild removes the resource's
-- spell (op172), which would take the real spell out of a cleric's or wizard's spellbook.
B24LV.AddResource("FEAT_COMMAND", { spell = B24.InnateCopy("SPPR102"), localName = "B24GFST2",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "FEY_TOUCHED")) and 1 or 0 end })
B24LV.AddResource("FEAT_INVISIBILITY", { spell = B24.InnateCopy("SPWI206"), localName = "B24GFST3",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "SHADOW_TOUCHED")) and 1 or 0 end })
B24LV.AddResource("SPEEDY_RECOVERY", { spell = "B24GDURB", localName = "B24GFDUR", shortRest = "all",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "DURABLE")) and 1 or 0 end })

B24LV.AddApplyListener(function(sprite)
	local feats = sprite:getLocalInt("B24GFN") > 0
	B24LV.Grant(sprite, "B24GGRAP", feats and has(sprite, "GRAPPLER"))
	B24LV.Grant(sprite, "B24GTELE", feats and has(sprite, "TELEKINETIC"))
end)

local function restBenefits(sprite, long)
	if sprite:getLocalInt("B24GFN") == 0 then return end
	sprite:setLocalInt("B24GFMSL", 0)
	if has(sprite, "CHEF") then
		for _, member in ipairs(B24.Party()) do B24.Heal(member, B24.Roll(8)) end
	end
	if has(sprite, "INSPIRING_LEADER") then
		local mod = math.max(B24.AbilityModOf(sprite, WIS), B24.AbilityModOf(sprite, CHA))
		local count = 0
		for _, member in ipairs(B24.Party()) do
			if count < 6 then
				count = count + 1
				B24LV.TempHP(member, math.max(1, B24.Level(sprite) + mod), 28800)
			end
		end
	end
end

B24.AddShortRestListener(function(sprite) restBenefits(sprite, false) end)
B24.AddLongRestListener(function(sprite) restBenefits(sprite, true) end)

-- Speedy Recovery (Durable): spend a Hit Point Die and regain that much.
function B24GDURB(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "SPEEDY_RECOVERY")
		if B24.HitDice_Remaining(sprite) <= 0 then return end
		sprite:setLocalInt("B24HDUSE", sprite:getLocalInt("B24HDUSE") + 1)
		local healed = math.max(1, B24.Roll(B24.HitDie(sprite)) + B24.AbilityModOf(sprite, CON))
		B24.Heal(sprite, healed)
		B24.Log(string.format("%s: Speedy Recovery, %d hit points", B24.Name(sprite), healed))
	end)
end

-- Grapple (Grappler): once per round, a creature next to the grappler.
function B24GGRAP(op402, target)
	EEex_Utility_TryIgnore(function()
		local grappler = B24.GetSprite(op402.m_sourceId)
		if grappler == nil then return end
		B24LV.Grant(grappler, "B24GGRAP", true)
		if not B24LV.OncePerRound(grappler, "GRAPPLE") then return end
		local dc = 8 + B24.ProfOf(grappler) + B24.AbilityModOf(grappler, STR)
		local ability = B24.AbilityModOf(target, DEX) > B24.AbilityModOf(target, STR) and DEX or STR
		if not B24.RollSave(target, ability, dc, nil, " (Grapple)") then
			B24.ApplyCondition(target, "GRAPPLED", { seconds = 60, source = grappler, ability = ability, dc = dc, label = "Grapple" })
		end
	end)
end

table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	if attacker:getLocalInt("B24GFN") == 0 or not has(attacker, "GRAPPLER") then return false end
	local grapple = B24CD.active[target.m_id .. "GRAPPLED"]
	return grapple ~= nil and grapple.source == attacker.m_id and B24.GameTick() <= grapple.untilTick
end)

-- Telekinetic Shove: once per round, Strength save or pushed 5 ft.
function B24GTELE(op402, target)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId)
		if caster == nil then return end
		B24LV.Grant(caster, "B24GTELE", true)
		if not B24LV.OncePerRound(caster, "TELEKINETIC") then return end
		local dc = B24.SpellSaveDC(caster, "SPWI000", bestCasting(caster))
		if not B24.RollSave(target, STR, dc, nil, " (Telekinetic Shove)") then
			B24.ForceMove(target, caster, 5)
		end
	end)
end

-----------------
-- Epic Boons --
-----------------

-- Level 19 of every class is an Epic Boon: a boon or another feat (the improvement popup offers
-- them from level 19 on). Past level 20 (the level cap, XPLEVEL.2DA in b24_core_runtime.tpa) every
-- level the XP would have reached on BG's own table (B24EPXP.2DA) brings one more such choice.
-- Boons raise an ability by 1 up to 25 (2024: 30; BG's scores stop at 25). Own wording; BG
-- versions: Combat Prowess gives advantage until the first hit each round (BG reports no misses);
-- Irresistible Offense adds the ability score to critical hits (resistances stay); Night Spirit is
-- an invisibility innate (BG has no light levels); Skill gives no Expertise.
B24GF.BOON_MAX = 25
local function boonLevel(sprite) return B24.Level(sprite) >= 19 end
local function anyAbility() return { STR, DEX, CON, INT, WIS, CHA } end
B24GF.BOONS = {
	{ key = "BOON_COMBAT_PROWESS", name = "Boon of Combat Prowess", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "Your strikes find their mark.\nIn BG: advantage on your attacks each round until the first one hits." },
	{ key = "BOON_DIMENSIONAL_TRAVEL", name = "Boon of Dimensional Travel", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "You step through space.\nIn BG: an innate teleport of up to 30 feet, once per round." },
	{ key = "BOON_ENERGY_RESISTANCE", name = "Boon of Energy Resistance", boon = true, require = boonLevel,
	  pairs = { { name = "fire and cold", opcodes = { 30, 28 } }, { name = "acid and lightning", opcodes = { 27, 29 } },
		{ name = "fire and lightning", opcodes = { 30, 29 } }, { name = "cold and poison", opcodes = { 28, 173 } } },
	  desc = "You shrug off the elements.\nIn BG: resistance to two damage types (the chosen pair); Constitution +1." },
	{ key = "BOON_FATE", name = "Boon of Fate", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "You bend fortune.\nIn BG: once per short rest, when you or a party member fails a save, 2d4 are added to it." },
	{ key = "BOON_FORTITUDE", name = "Boon of Fortitude", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "Your body is hardened.\nIn BG: +40 maximum hit points." },
	{ key = "BOON_IRRESISTIBLE_OFFENSE", name = "Boon of Irresistible Offense", boon = true, abilities = { STR, DEX }, require = boonLevel,
	  desc = "Your blows land with crushing force.\nIn BG: critical hits deal extra damage equal to your Strength or Dexterity score." },
	{ key = "BOON_RECOVERY", name = "Boon of Recovery", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "You refuse to fall.\nIn BG: once per long rest, dropping to 0 hit points leaves you at half your maximum instead; Recovery Dice innate: 1d10 healing, 10 uses per long rest." },
	{ key = "BOON_SKILL", name = "Boon of Skill", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "You master every craft.\nIn BG: proficiency in all skills." },
	{ key = "BOON_SPEED", name = "Boon of Speed", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "You move with blinding speed.\nIn BG: double movement speed." },
	{ key = "BOON_SPELL_RECALL", name = "Boon of Spell Recall", boon = true, abilities = { INT, WIS, CHA },
	  require = function(sprite) return boonLevel(sprite) and B24SP ~= nil and B24LV.CasterLetters(sprite) ~= "" end,
	  desc = "Your magic returns to you.\nIn BG: Spell Recall innate, once per long rest: a spent spell slot of level 1 to 4 comes back." },
	{ key = "BOON_NIGHT_SPIRIT", name = "Boon of the Night Spirit", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "Shadows wrap around you.\nIn BG: Merge with Shadows innate, once per round: you turn invisible until you attack or cast." },
	{ key = "BOON_TRUESIGHT", name = "Boon of Truesight", boon = true, abilities = anyAbility(), require = boonLevel,
	  desc = "Nothing is hidden from you.\nIn BG: you see invisible creatures." },
}

-- XP table rows of the classes (XPLEVEL.2DA), by the mod's class keys.
local XP_ROWS = { FIGHTER = "FIGHTER", BARBARIAN = "FIGHTER", PALADIN = "PALADIN", RANGER = "RANGER", CLERIC = "CLERIC",
	DRUID = "DRUID", ROGUE = "THIEF", BARD = "BARD", SORCERER = "SORCERER", MONK = "MONK", WIZARD = "MAGE" }
local epicTable

-- Epic Boons past level 20: the levels 21 and up whose old XP threshold the character has reached
-- (multiclasses: their starting class).
function B24GF.BoonsPastTwenty(sprite)
	if B24.Level(sprite) < 20 then return 0 end
	local classKey = B24.SkillClass(sprite)
	if B24MC and B24MC.IsMulti(sprite) then
		local classes = B24MC.Classes(sprite)
		local main = sprite:getLocalInt("B24MCMAIN")
		classKey = classes[main > 0 and main or 1]
	end
	if epicTable == nil then
		local ok, loaded = pcall(B24.LoadTable, "B24EPXP")
		epicTable = ok and loaded or {}
	end
	local row = epicTable[XP_ROWS[classKey or ""] or "FIGHTER"]
	if row == nil then return 0 end
	local xp, n = sprite.m_baseStats.m_xp, 0
	for level = 21, 50 do
		local threshold = tonumber(row[tostring(level)])
		if threshold == nil then break end
		if xp >= threshold then n = n + 1 end
	end
	return n
end

-- XP the character needs for its n-th boon past level 20 (tests, the record screen).
function B24GF.XPForBoon(sprite, n)
	local classKey = B24.SkillClass(sprite)
	if B24MC and B24MC.IsMulti(sprite) then
		local main = sprite:getLocalInt("B24MCMAIN")
		classKey = B24MC.Classes(sprite)[main > 0 and main or 1]
	end
	if epicTable == nil then
		local ok, loaded = pcall(B24.LoadTable, "B24EPXP")
		epicTable = ok and loaded or {}
	end
	local row = epicTable[XP_ROWS[classKey or ""] or "FIGHTER"]
	return row and tonumber(row[tostring(20 + n)])
end

B24LV.AddChoiceListener(function(sprite)
	local n = B24GF.BoonsPastTwenty(sprite)
	if n > 0 then return { ASI = n } end
end)

-- Combat Prowess: advantage until the round's first hit.
local function prowessReady(sprite)
	local hit = B24.Aux(sprite).B24_ProwessHit
	return hit == nil or B24.GameTick() - hit >= 90 or B24.GameTick() < hit
end
table.insert(B24.AttackAdvantageListeners, function(sprite)
	return sprite:getLocalInt("B24GFN") > 0 and has(sprite, "BOON_COMBAT_PROWESS") and prowessReady(sprite)
end)

table.insert(B24WPN.DamageListeners, function(context)
	local attacker = context.attacker
	if attacker:getLocalInt("B24GFN") == 0 then return end
	if has(attacker, "BOON_COMBAT_PROWESS") and prowessReady(attacker) then
		B24.Aux(attacker).B24_ProwessHit = B24.GameTick()
	end
	-- Irresistible Offense: critical hits add the Strength or Dexterity score.
	if context.isCritical and has(attacker, "BOON_IRRESISTIBLE_OFFENSE") then
		local extra = math.max(score(attacker, STR), score(attacker, DEX))
		context.effect.m_effectAmount = context.effect.m_effectAmount + extra
		B24.Log(string.format("%s: Irresistible Offense +%d", B24.Name(attacker), extra))
	end
end)

-- Fate: once per short rest, 2d4 on a party member's failed save.
B24LV.AddResource("BOON_FATE", { localName = "B24BFATE", shortRest = "all",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "BOON_FATE")) and 1 or 0 end })
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not B24.InParty(sprite) then return nil end
	for _, member in ipairs(B24.Party()) do
		if B24LV.Remaining(member, "BOON_FATE") > 0 then
			local roll = B24.Roll(4) + B24.Roll(4)
			if total + roll >= dc then
				B24LV.Use(member, "BOON_FATE")
				B24.Log(string.format("%s: Boon of Fate +%d for %s", B24.Name(member), roll, B24.Name(sprite)))
				return true
			end
		end
	end
	return nil
end)

-- Recovery: the first drop to 0 each long rest leaves half the maximum; Recovery Dice innate.
B24.AddDownSaver(function(sprite)
	if sprite:getLocalInt("B24GFN") == 0 or not has(sprite, "BOON_RECOVERY") or sprite:getLocalInt("B24BRLST") == 1 then return false end
	sprite:setLocalInt("B24BRLST", 1)
	B24.Heal(sprite, math.floor(sprite:getStat(B24.Stat.MAXHP) / 2))
	B24.Log(string.format("%s: Boon of Recovery (half the hit points back)", B24.Name(sprite)))
	return true
end)
B24.AddLongRestListener(function(sprite)
	if sprite:getLocalInt("B24BRLST") ~= 0 then sprite:setLocalInt("B24BRLST", 0) end
end)
B24LV.AddResource("BOON_RECOVERY_DICE", { spell = "B24BRCVR", localName = "B24BRCDU",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "BOON_RECOVERY")) and 10 or 0 end })
function B24BRCVR(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Use(sprite, "BOON_RECOVERY_DICE") then return end
		local heal = B24.Roll(10)
		B24.Heal(sprite, heal)
		B24.Log(string.format("%s: Recovery Dice, %d hit points", B24.Name(sprite), heal))
	end)
end

-- Spell Recall: once per long rest, a spent slot of level 1-4 (the highest) comes back.
B24LV.AddResource("BOON_SPELL_RECALL", { spell = "B24BSPRC", localName = "B24BSPRU",
	max = function(sprite) return (sprite:getLocalInt("B24GFN") > 0 and has(sprite, "BOON_SPELL_RECALL")) and 1 or 0 end })
function B24BSPRC(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if B24SP == nil or B24SP.UnreadyEntries == nil then return end
		for level = 4, 1, -1 do
			for _, mage in ipairs({ true, false }) do
				local entry = B24SP.UnreadyEntries(sprite, mage, level)[1]
				if entry then
					if not B24LV.Use(sprite, "BOON_SPELL_RECALL") then return end
					B24SP.Restore(entry)
					B24.Log(string.format("%s: Spell Recall (%s)", B24.Name(sprite), entry.m_spellId:get():upper()))
					return
				end
			end
		end
		B24.Log(string.format("%s: Spell Recall finds no spent slot of level 1 to 4", B24.Name(sprite)))
	end)
end

-- Skill: proficiency in all skills.
B24.AddGrantedSkillListener(function(sprite, proficient)
	if sprite:getLocalInt("B24GFN") == 0 or not has(sprite, "BOON_SKILL") then return end
	for _, skill in ipairs(B24.SKILLS) do proficient[skill.key] = true end
end)

-- Passive boons.
B24LV.AddApplyListener(function(sprite)
	if sprite:getLocalInt("B24GFN") == 0 then return end
	if has(sprite, "BOON_FORTITUDE") then B24LV.Permanent(sprite, { ["effectID"] = 18, ["effectAmount"] = 40, ["dwFlags"] = 0 }) end
	if has(sprite, "BOON_SPEED") then B24LV.Permanent(sprite, { ["effectID"] = 176, ["effectAmount"] = 200, ["dwFlags"] = 5 }) end
	if has(sprite, "BOON_TRUESIGHT") then B24LV.Permanent(sprite, { ["effectID"] = 193 }) end
	local ok, variant = has(sprite, "BOON_ENERGY_RESISTANCE")
	local pair = ok and B24GF.BOONS[3].pairs[variant]
	for _, opcode in ipairs(pair and pair.opcodes or {}) do
		B24LV.Permanent(sprite, { ["effectID"] = opcode, ["effectAmount"] = 50, ["dwFlags"] = 0 })
	end
end)

-- Dimensional Travel (B24BDIMT) and Merge with Shadows (B24BNIGH): once per round.
local ROUND_INNATES = { { feat = "BOON_DIMENSIONAL_TRAVEL", res = "B24BDIMT" }, { feat = "BOON_NIGHT_SPIRIT", res = "B24BNIGH" } }
B24LV.AddTickListener(function(sprite)
	if sprite:getLocalInt("B24GFN") == 0 then return end
	local aux, now = B24.Aux(sprite), B24.GameTick()
	aux.B24_BoonReady = aux.B24_BoonReady or {}
	aux.B24_BoonUsed = aux.B24_BoonUsed or {}
	for _, innate in ipairs(ROUND_INNATES) do
		local used = aux.B24_BoonUsed[innate.res]
		local want = has(sprite, innate.feat) and not (used and now >= used and now - used < 90)
		if want and not aux.B24_BoonReady[innate.res] then
			B24LV.Grant(sprite, innate.res, true)
			aux.B24_BoonReady[innate.res] = true
		elseif not want and aux.B24_BoonReady[innate.res] then
			B24LV.Grant(sprite, innate.res, false)
			aux.B24_BoonReady[innate.res] = nil
		end
	end
end)

local function roundInnateUsed(sprite, res)
	local aux = B24.Aux(sprite)
	aux.B24_BoonUsed = aux.B24_BoonUsed or {}
	aux.B24_BoonReady = aux.B24_BoonReady or {}
	aux.B24_BoonUsed[res], aux.B24_BoonReady[res] = B24.GameTick(), nil
end
function B24BDIMT(op402, sprite) EEex_Utility_TryIgnore(roundInnateUsed, sprite, "B24BDIMT") end
function B24BNIGH(op402, sprite)
	EEex_Utility_TryIgnore(function()
		roundInnateUsed(sprite, "B24BNIGH")
		B24.ApplyEffect(sprite, { ["effectID"] = 20, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60 })
	end)
end
