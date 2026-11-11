-- BG 2024 Rules Mod: advantage and disadvantage on attack rolls, armor Dex caps.
--
-- The engine rolls one d20 and EEex cannot replace that roll, so advantage is built from two
-- steps that together give the exact 2024 hit chance:
--   1. Before the roll, a creature with an advantage source gets +5 to hit (attacker side),
--      or attacks against it get +5 (target side). +5 is always enough to reach the
--      advantage hit chance.
--   2. When the engine reports a hit, B24.OnWeaponHit keeps it with probability
--      wanted / actual chance and turns it into a miss otherwise.
-- Disadvantage needs no bonus: hits are kept with probability p, so the chance becomes p * p.

B24.ADVANTAGE_BONUS = 5

-- Timed conditions set by class features, e.g. Reckless Attack: aux B24_Timed[key] = game tick
-- until which it lasts. Keys: ATTACK_ADV (the creature's attacks have advantage), GRANTS_ADV
-- (attacks against it have advantage).
function B24.SetTimed(sprite, key, seconds)
	local aux = B24.Aux(sprite)
	aux.B24_Timed = aux.B24_Timed or {}
	aux.B24_Timed[key] = B24.GameTick() + seconds * 15
	-- Re-resolve the stats so the advantage bump applies right away.
	B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 0 })
end

function B24.HasTimed(sprite, key)
	local timed = B24.Aux(sprite).B24_Timed
	return timed ~= nil and timed[key] ~= nil and B24.GameTick() <= timed[key]
end

function B24.ClearTimed(sprite, key)
	local timed = B24.Aux(sprite).B24_Timed
	if timed then timed[key] = nil end
end

-- listener(sprite) returns true if attacks against the creature never have advantage (Elusive).
B24.NoAdvantageAgainstListeners = {}

-- Conditions on the attacker.
-- listener(sprite) returns true for advantage on all the creature's attacks (spell effects,
-- e.g. Tenser's Transformation).
B24.AttackAdvantageListeners = {}

local function anyListener(listeners, ...)
	for _, listener in ipairs(listeners) do
		local ok, result = pcall(listener, ...)
		if ok and result then return true end
	end
	return false
end

function B24.AttackerHasAdvantage(sprite)
	local g = B24.GState
	return B24.GState_Has(sprite, g.INVISIBLE) or B24.GState_Has(sprite, g.IMPROVEDINVISIBILITY)
		or B24.HasTimed(sprite, "ATTACK_ADV")
		or anyListener(B24.AttackAdvantageListeners, sprite)
end

function B24.AttackerHasDisadvantage(sprite)
	local g = B24.GState
	return B24.GState_Has(sprite, g.BLIND) or B24.GState_Has(sprite, g.POISONED)
		or B24.GState_Has(sprite, g.PANIC) or sprite:getSpellState(B24.SplState.PRONE)
		or sprite:getStat(B24.Stat.HELD) > 0
		or (B24.IsRestrained ~= nil and B24.IsRestrained(sprite)) -- restrained (B24COND.lua)
		or B24.HasTimed(sprite, "ATTACK_DIS")
		or (B24WPN ~= nil and B24WPN.IsSapped(sprite)) -- Sap mastery
end

-- listener(attacker, target) returns true for disadvantage against one target (e.g. a Wild Heart
-- barbarian's Lion aspect for enemies attacking someone else).
B24.DisadvantageAgainstListeners = {}

function B24.AttackerHasDisadvantageAgainst(attacker, target)
	for _, listener in ipairs(B24.DisadvantageAgainstListeners) do
		local ok, result = pcall(listener, attacker, target)
		if ok and result then return true end
	end
	return false
end

-- Ranged attacks in melee (2024): a ranged attack roll has disadvantage while a hostile creature
-- within 5 ft can see the attacker and isn't incapacitated, whoever the target is. This replaces
-- the engine's penalty for shooting at an adjacent target (switched off below). Weapon attacks
-- are ranged with a ranged or launcher ability; spell attacks say so (B24.spellAttackRanged, set
-- by B24SP.SpellAttack). listener(attacker, crossbow) returns true when a feat lifts it
-- (Sharpshooter, Crossbow Expert: B24GFEAT.lua).
B24.RangedInMeleeExemptListeners = {}

local function incapacitated(sprite)
	local g = B24.GState
	return B24.GState_Has(sprite, g.DEAD) or B24.GState_Has(sprite, g.SLEEPING) or B24.GState_Has(sprite, g.STUNNED)
		or B24.GState_Has(sprite, g.HELPLESS) or sprite:getStat(B24.Stat.HELD) > 0
		or (B24.IsDown ~= nil and B24.IsDown(sprite))
end

-- The weapon attack's kind: ranged, and whether a crossbow shoots it (item type 27).
local function rangedWeapon(attacker)
	local equipment = attacker.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	local ability = item and item:getAbility(equipment.m_selectedWeaponAbility)
	if ability == nil or (ability.type ~= 2 and ability.type ~= 4) then return false, false end
	local launcher = attacker:getLauncher(ability) or item
	return true, launcher.pRes.pHeader.itemType == 27
end

function B24.EnemyInMelee(attacker)
	local ok, ea = pcall(function() return attacker.m_typeAI.m_EnemyAlly end)
	-- Hostile to the party (EVILCUTOFF and up) or on its side.
	local foes = (ok and ea >= 200) and "[GOODCUTOFF]" or "[EVILCUTOFF]"
	local g = B24.GState
	local unseen = B24.GState_Has(attacker, g.INVISIBLE) or B24.GState_Has(attacker, g.IMPROVEDINVISIBILITY)
	if unseen then return false end
	for _, foe in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(attacker, foes, B24.ADJACENT, false) or {}) do
		if foe.m_id ~= attacker.m_id and not incapacitated(foe) and not B24.GState_Has(foe, g.BLIND) then return true end
	end
	return false
end

table.insert(B24.DisadvantageAgainstListeners, function(attacker, target)
	if B24.Config.rangedInMelee2024 == false then return false end
	local ranged, crossbow
	if B24.spellAttackRanged ~= nil then
		ranged, crossbow = B24.spellAttackRanged, false
	else
		ranged, crossbow = rangedWeapon(attacker)
	end
	if not ranged or not B24.EnemyInMelee(attacker) then return false end
	return not anyListener(B24.RangedInMeleeExemptListeners, attacker, crossbow)
end)

local originalIgnoreRangedPenalty = EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty
function EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty(sprite, item, abilityNum)
	if B24.Config.rangedInMelee2024 ~= false then return true end
	return originalIgnoreRangedPenalty(sprite, item, abilityNum)
end

-- listener(attacker, target) returns true for advantage against one target (e.g. the Ranger's
-- Precise Hunter against the marked creature).
B24.AdvantageAgainstListeners = {}

-- Advantage against one target only (Vex mastery, listeners).
function B24.AttackerHasAdvantageAgainst(attacker, target)
	if B24WPN ~= nil and B24WPN.VexTarget(attacker) == target.m_id then return true end
	for _, listener in ipairs(B24.AdvantageAgainstListeners) do
		local ok, result = pcall(listener, attacker, target)
		if ok and result then return true end
	end
	return false
end

-- Conditions on the target.
function B24.TargetGrantsAdvantage(sprite)
	local g = B24.GState
	for _, listener in ipairs(B24.NoAdvantageAgainstListeners) do
		local ok, result = pcall(listener, sprite)
		if ok and result then return false end
	end
	return B24.HasTimed(sprite, "GRANTS_ADV") or B24.GState_Has(sprite, g.BLIND) or B24.GState_Has(sprite, g.STUNNED)
		or B24.GState_Has(sprite, g.HELPLESS) or B24.GState_Has(sprite, g.SLEEPING)
		or sprite:getStat(B24.Stat.HELD) > 0
		or (B24.IsRestrained ~= nil and B24.IsRestrained(sprite))
end

-- GRANTS_DIS: attacks against the creature have disadvantage (e.g. the Monk's Patient Defense).
-- listener(sprite) returns true if attacks against the creature have disadvantage (Blur,
-- displacement).
B24.TargetDisadvantageListeners = {}

function B24.TargetGrantsDisadvantage(sprite)
	local g = B24.GState
	return B24.GState_Has(sprite, g.INVISIBLE) or B24.GState_Has(sprite, g.IMPROVEDINVISIBILITY)
		or B24.HasTimed(sprite, "GRANTS_DIS")
		or anyListener(B24.TargetDisadvantageListeners, sprite)
end

-- True if the creature's attacks need the +5 bump: general advantage, a pending Vex, or advantage
-- against the creature it is attacking now.
function B24.WantsAttackBump(sprite)
	if B24.AttackerHasAdvantage(sprite) or (B24WPN ~= nil and B24WPN.VexTarget(sprite) ~= nil) then return true end
	-- Creatures in character generation have no area (and no target).
	if sprite.m_pArea == nil then return false end
	local target = B24.GetSprite(sprite.m_targetId)
	return target ~= nil and target.m_id ~= sprite.m_id and B24.AttackerHasAdvantageAgainst(sprite, target)
end

-- Runs after every effect-list resolution; adjusts the freshly derived stats.
function B24.OnListsResolved(sprite)
	B24.QueueScreen(sprite)

	local stats = sprite:getActiveStats()
	local aux = B24.Aux(sprite)

	-- Armor Dex caps: heavy armor ignores Dex, medium armor caps it at +2. The engine adds
	-- the full DEXMOD bonus, so the excess is taken back here (lower AC is better).
	local dexMod = B24.AbilityMod(stats.m_nDEX)
	if aux.B24_Form ~= nil then
		-- Wild Shape (B24DRUID.lua): the beast's AC; worn armor merges into the form.
	elseif sprite:getSpellState(B24.SplState.ARMOR_HEAVY) then
		stats.m_nArmorClass = stats.m_nArmorClass + dexMod
	elseif sprite:getSpellState(B24.SplState.ARMOR_MEDIUM) and dexMod > 2 then
		stats.m_nArmorClass = stats.m_nArmorClass + (dexMod - 2)
	end

	-- 2024 proficiencies: weapon proficiency bonus and BG thief skills from 2024 skill bonuses.
	EEex_Utility_TryIgnore(B24.ApplyWeaponProficiency, sprite)
	EEex_Utility_TryIgnore(B24.ApplySkillStats, sprite)

	-- The bump also covers a pending Vex and advantage against the current target; against other
	-- targets it is taken out again (B24COND.lua resolves the stats again when the target changes).
	aux.B24_attackBump = B24.WantsAttackBump(sprite)
	if aux.B24_attackBump then
		stats.m_nTHAC0 = stats.m_nTHAC0 - B24.ADVANTAGE_BONUS
	end

	aux.B24_targetBump = B24.TargetGrantsAdvantage(sprite)
	if aux.B24_targetBump then
		stats.m_nArmorClass = stats.m_nArmorClass + B24.ADVANTAGE_BONUS
	end
end

-- Asking EEex for a hit chance (B24.HitChance, the Attack Info module's chances on hover, every
-- frame) can run the block-hit listeners as if a swing had hit: while a chance is only asked, the
-- listeners must decide nothing (no miss, no message, no Vex or Sap used up). Hovering over an enemy
-- printed "misses ... (disadvantage)" every frame.
B24.hitQueries = 0
function B24.InHitQuery() return B24.hitQueries > 0 end

local function hitChance(attacker, target, weapon)
	local equipment = attacker.m_equipment
	local offhand = equipment.m_items:get(9)
	local leftHand = offhand ~= nil and weapon ~= nil and EEex_UDEqual(offhand, weapon)
	local slot = leftHand and 9 or equipment.m_selectedWeapon
	local ability = leftHand and 0 or equipment.m_selectedWeaponAbility
	B24.hitQueries = B24.hitQueries + 1
	local ok, chance = pcall(EEex.GetWeaponHitChance, attacker, target, equipment.m_items:get(slot), ability, leftHand)
	B24.hitQueries = B24.hitQueries - 1
	if not ok then error(chance) end
	return chance
end
B24.HitChance = hitChance

-- The real hit chance (0-100) of an attack, from the engine's chance, which includes the +5
-- advantage bumps applied in OnListsResolved: the bumps are taken out again, and advantage or
-- disadvantage roll the d20 twice.
function B24.EffectiveHitChance(attacker, target, engineChance)
	local advantage = B24.AttackerHasAdvantage(attacker) or B24.TargetGrantsAdvantage(target)
		or B24.AttackerHasAdvantageAgainst(attacker, target)
	local disadvantage = B24.AttackerHasDisadvantage(attacker) or B24.TargetGrantsDisadvantage(target)
		or B24.AttackerHasDisadvantageAgainst(attacker, target)
	local bumps = (B24.Aux(attacker).B24_attackBump and 1 or 0) + (B24.Aux(target).B24_targetBump and 1 or 0)
	local base = math.max(0.05, math.min(0.95, (engineChance - 5 * B24.ADVANTAGE_BONUS * bumps) / 100))
	if advantage and not disadvantage then
		base = 1 - (1 - base) * (1 - base)
	elseif disadvantage and not advantage then
		base = base * base
	end
	return base * 100
end

-- Returns true to turn the hit into a miss.
function B24.OnWeaponHit(context)
	local attacker, target = context.attackingSprite, context.targetSprite
	if B24.InHitQuery() or not B24.IsSprite(attacker) or not B24.IsSprite(target) then return false end

	local advantage = B24.AttackerHasAdvantage(attacker) or B24.TargetGrantsAdvantage(target)
		or B24.AttackerHasAdvantageAgainst(attacker, target)
	local disadvantage = B24.AttackerHasDisadvantage(attacker) or B24.TargetGrantsDisadvantage(target)
		or B24.AttackerHasDisadvantageAgainst(attacker, target)
	local bumps = (B24.Aux(attacker).B24_attackBump and 1 or 0) + (B24.Aux(target).B24_targetBump and 1 or 0)
	if not advantage and not disadvantage and bumps == 0 then return false end

	local ok, chance = pcall(hitChance, attacker, target, context.weapon)
	if not ok or chance == nil or chance <= 0 then return false end

	local actual = math.min(1, chance / 100)
	local wanted = B24.EffectiveHitChance(attacker, target, chance) / 100
	-- Sap and Vex last for one attack.
	if B24WPN then EEex_Utility_TryIgnore(B24WPN.ConsumeAttack, attacker, target) end
	if math.random() * actual > wanted then
		B24.Log(string.format("%s misses %s (%s)", B24.Name(attacker), B24.Name(target),
			disadvantage and not advantage and "disadvantage" or "advantage roll"))
		if B24WPN then EEex_Utility_TryIgnore(B24WPN.OnMiss, attacker, target, context.weapon) end
		return true
	end
	return false
end

B24.AddStatListener(B24.OnListsResolved)
EEex_Sprite_AddBlockWeaponHitListener(B24.OnWeaponHit)

-- EEex Attack Info module (hit chances on hover): show the real chances, with advantage and
-- disadvantage. The module may load before or after this file, so the wrapper is installed now
-- and again once UI.MENU has loaded.
local function wrapAttackInfo()
	if B3AttackInfo_Private_GetWeaponHitChance == nil or B24_AttackInfoWrapped then return end
	B24_AttackInfoWrapped = true
	local original = B3AttackInfo_Private_GetWeaponHitChance
	function B3AttackInfo_Private_GetWeaponHitChance(sourceSprite, targetSprite, leftHand)
		B24.hitQueries = B24.hitQueries + 1
		local ok, chance, isImmune, reasoning = pcall(original, sourceSprite, targetSprite, leftHand)
		B24.hitQueries = B24.hitQueries - 1
		if not ok then error(chance) end
		if type(chance) == "number" and chance > 0 then
			local ok, effective = pcall(B24.EffectiveHitChance, sourceSprite, targetSprite, chance)
			if ok then chance = math.floor(effective + 0.5) end
		end
		return chance, isImmune, reasoning
	end
end
wrapAttackInfo()
EEex_Menu_AddAfterMainFileLoadedListener(wrapAttackInfo)
