-- BG 2024 Rules Mod: critical hits and Weapon Mastery.
--
-- Both run in EEex's base weapon damage hook (EEex_Sprite_AddAlterBaseWeaponDamageListener),
-- which gets the attacker, target, weapon, launcher, the weapon's ability, the attack roll, whether
-- the engine counts the hit as critical, and the damage effect before it is applied.
--
-- Critical hits: 2024 doubles the damage dice, not the flat bonuses. The engine doubles the
-- whole damage; when its damage effect shows doubled dice, the flat part is halved back.
--
-- Weapon Mastery: a creature uses a weapon's mastery property if its class has Weapon Mastery and
-- it mastered the weapon (local B24MAST over B24.MASTERY_WEAPONS; companions without a choice
-- master the weapons they have most proficiency stars in). Properties:
--   Cleave  once per round, an attack roll against a second enemy next to the target, weapon dice
--   Graze   a miss still deals the ability modifier (only for misses caused by this mod's
--           advantage/disadvantage rolls; the engine reports no other misses)
--   Nick    no effect: BG already makes the off-hand attack part of every round
--   Push    the target is pushed away
--   Sap     the target has disadvantage on its next attack (one round)
--   Slow    the target's speed drops by 10 ft for a round
--   Topple  Constitution save (DC 8 + ability modifier + proficiency) or prone for a round
--   Vex     advantage on the next attack against the target (one round)

B24WPN = {}

B24WPN.SOURCE_RES = "B24MAST"
B24WPN.ROUND = 90 -- ticks (15 per second)
B24WPN.CLEAVE_RANGE = B24.ADJACENT

-- ITM extended header offsets.
local AB_DICE_SIZE, AB_DICE_COUNT, AB_DAMAGE_BONUS, AB_DAMAGE_TYPE = 0x16, 0x18, 0x1a, 0x1c
-- ITM damage type -> op12 damage type.
local DAMAGE_TYPE = { [0] = 0, [1] = 0x100000, [2] = 0, [3] = 0x1000000, [4] = 0x800000, [5] = 0 }

local function abilityDice(ability)
	if ability == nil then return 0, 0, 0, 0 end
	local ptr = EEex_UDToPtr(ability)
	return EEex_ReadU8(ptr + AB_DICE_COUNT), EEex_ReadU8(ptr + AB_DICE_SIZE),
		EEex_Read16(ptr + AB_DAMAGE_BONUS), EEex_ReadU16(ptr + AB_DAMAGE_TYPE)
end

local function signedMod(sprite, ability)
	return B24.AbilityModOf(sprite, ability)
end

-------------------
-- Critical hits --
-------------------

local function onCritical(context)
	local effect = context.effect
	local count = abilityDice(context.ability)
	if count <= 0 then return end
	local before = string.format("%dd%d+%d", effect.m_numDice, effect.m_diceSize, effect.m_effectAmount)
	if effect.m_numDice == 2 * count then
		-- Engine doubled dice and bonus: keep the doubled dice, the bonus once.
		effect.m_effectAmount = math.floor(effect.m_effectAmount / 2)
	elseif effect.m_numDice == count then
		-- Engine will double later, or not at all: double the dice here (logged for checking).
		effect.m_numDice = 2 * count
	end
	B24.Log(string.format("%s: critical hit, damage %s -> %dd%d+%d", B24.Name(context.attacker), before,
		effect.m_numDice, effect.m_diceSize, effect.m_effectAmount))
end

--------------------
-- Weapon Mastery --
--------------------

-- 2024 weapon key of an item, from its BG proficiency type.
local function weaponKey(item)
	if item == nil then return nil end
	local info = B24.WeaponInfo(item.pRes.pHeader.proficiencyType)
	return info and info.WEAPON
end
B24WPN.WeaponKey = weaponKey

local function masteryIndex(key)
	for i, weapon in ipairs(B24.MASTERY_WEAPONS) do
		if weapon.key == key then return i, weapon end
	end
end

-- Companions without a choice: the weapons with the most proficiency stars.
local function defaultMasteries(sprite, count)
	local scored = {}
	for profType, info in pairs(B24.Weapons) do
		local stars = sprite:getStat(tonumber(profType))
		if stars > 1 then table.insert(scored, { key = info.WEAPON, stars = stars }) end
	end
	table.sort(scored, function(a, b) return a.stars > b.stars end)
	local chosen = {}
	for _, entry in ipairs(scored) do
		if #chosen >= count then break end
		if not chosen[entry.key] then
			chosen[entry.key] = true
			table.insert(chosen, entry.key)
		end
	end
	return chosen
end

function B24WPN.HasMastery(sprite, key)
	if key == nil or B24.IsMonster(sprite) then return false end
	local count = B24.MasteryCount(sprite)
	if count <= 0 then return false end
	local index = masteryIndex(key)
	if index == nil then return false end
	if sprite:getLocalInt("B24SKSET") == 1 or sprite:getLocalInt("B24MSSET") == 1 then
		return EEex_IsBitSet(sprite:getLocalInt("B24MAST"), index - 1)
	end
	return defaultMasteries(sprite, count)[key] == true
end

-- The weapon whose mastery applies: the launcher for ranged attacks.
-- listener(attacker) returns a property that replaces the weapon's own (Fighter Tactical Master).
B24WPN.PropertyOverrideListeners = {}

local function masteredProperty(attacker, weapon, launcher)
	local key = weaponKey(launcher) or weaponKey(weapon)
	if not B24WPN.HasMastery(attacker, key) then return nil end
	local _, entry = masteryIndex(key)
	for _, listener in ipairs(B24WPN.PropertyOverrideListeners) do
		local ok, property = pcall(listener, attacker)
		if ok and property then return property, entry end
	end
	return entry.mastery:upper(), entry
end

local function reresolve(sprite)
	B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 0 })
end

local function now()
	return B24.GameTick()
end

local function attackAbility(launcher)
	return launcher and "DEX" or "STR"
end

local function applyTimed(target, attacker, args)
	args.durationType = 0
	args.duration = args.duration or 6
	args.sourceID = attacker.m_id
	args.m_sourceRes = B24WPN.SOURCE_RES
	B24.ApplyEffect(target, args)
end

local properties = {}

function properties.TOPPLE(context)
	local attacker, target = context.attacker, context.target
	local dc = 8 + B24.ProfOf(attacker) + signedMod(attacker, attackAbility(context.launcher))
	if not B24.RollSave(target, "CON", dc, nil, " (Topple)") then
		B24.KnockProne(target, attacker)
		B24.Log(string.format("%s is knocked prone (Topple)", B24.Name(target)))
	end
end

function properties.SLOW(context)
	-- Not cumulative: the previous Slow from mastery is replaced.
	B24.RemoveEffectsBySource(context.target, B24WPN.SOURCE_RES)
	applyTimed(context.target, context.attacker, { ["effectID"] = 176, ["effectAmount"] = 67, ["dwFlags"] = 5 })
end

function properties.PUSH(context)
	-- 2024: 10 ft away, Large or smaller.
	B24.ForceMove(context.target, context.attacker, 10, false, B24.SIZE.LARGE)
end

function properties.SAP(context)
	B24.Aux(context.target).B24_SappedUntil = now() + B24WPN.ROUND
end

function properties.VEX(context)
	B24.Aux(context.attacker).B24_Vex = { target = context.target.m_id, untilTick = now() + B24WPN.ROUND }
	reresolve(context.attacker)
end

function properties.CLEAVE(context)
	local attacker, target = context.attacker, context.target
	local aux = B24.Aux(attacker)
	if aux.B24_CleaveTick and now() - aux.B24_CleaveTick < B24WPN.ROUND then return end
	local enemies = EEex_Sprite_GetAllOfTypeStringInRange(attacker, "[ENEMY]", B24WPN.CLEAVE_RANGE, true) or {}
	local second = nil
	for _, enemy in ipairs(enemies) do
		if enemy.m_id ~= target.m_id and not B24.GState_Has(enemy, B24.GState.DEAD) then
			second = enemy
			break
		end
	end
	if second == nil then return end
	aux.B24_CleaveTick = now()
	local roll = B24.Roll(20)
	local attack = 20 - attacker:getActiveStats().m_nTHAC0
	local ac = 20 - second:getActiveStats().m_nArmorClass
	if roll == 20 or (roll ~= 1 and roll + attack >= ac) then
		local count, size, bonus, damageType = abilityDice(context.ability)
		B24.ApplyEffect(second, { ["effectID"] = 12, ["numDice"] = count, ["diceSize"] = size,
			["effectAmount"] = math.max(0, bonus), ["dwFlags"] = DAMAGE_TYPE[damageType] or 0,
			["sourceID"] = attacker.m_id })
		B24.Log(string.format("%s cleaves into %s (%d%+d vs AC %d)", B24.Name(attacker), B24.Name(second), roll, attack, ac))
	else
		B24.Log(string.format("%s cleaves at %s and misses (%d%+d vs AC %d)", B24.Name(attacker), B24.Name(second), roll, attack, ac))
	end
end

-- A weapon attack made by script, outside the engine's attack rounds (Opportunity Attacks): the
-- weapon in hand (or an unarmed strike), the engine's hit chance with the 2024 advantage rules
-- (B24.EffectiveHitChance), a critical hit on 5% of all attacks; on a hit the weapon's dice, its
-- bonus and the Strength modifier (Dexterity with Finesse, B24.FinesseBonus). Returns the hit.
function B24WPN.ScriptedAttack(attacker, target, label)
	local equipment = attacker.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	local ability = item and item:getAbility(equipment.m_selectedWeaponAbility)
	local chance = 50
	local ok, engine = pcall(B24.HitChance, attacker, target, item)
	if ok and engine then chance = B24.EffectiveHitChance(attacker, target, engine) end
	local hit = B24.Roll(100) <= chance
	local critical = hit and math.random() * chance < 5
	if hit then
		local count, size, bonus, damageType = 1, 1, 0, nil
		if ability then count, size, bonus, damageType = abilityDice(ability) end
		bonus = bonus + B24.AbilityModOf(attacker, "STR")
		if item and ability and B24.FinesseBonus then bonus = bonus + (B24.FinesseBonus(attacker, item, ability) or 0) end
		if critical then count = count * 2 end
		B24.ApplyEffect(target, { ["effectID"] = 12, ["numDice"] = count, ["diceSize"] = size,
			["effectAmount"] = math.max(0, bonus), ["dwFlags"] = DAMAGE_TYPE[damageType] or 0,
			["sourceID"] = attacker.m_id })
	end
	B24.Log(string.format("%s: %s on %s, %s (%d%% to hit)", B24.Name(attacker), label or "attack", B24.Name(target),
		critical and "critical hit" or hit and "hit" or "miss", math.floor(chance + 0.5)))
	return hit
end

local function onMasteryHit(context)
	local property = masteredProperty(context.attacker, context.weapon, context.launcher)
	local handler = property and properties[property]
	if handler then handler(context) end
end

-- Graze: called by B24.OnWeaponHit when it turns a hit into a miss.
-- listener(attacker, target, weapon) for misses this mod causes (Fighter Studied Attacks).
B24WPN.MissListeners = {}

function B24WPN.OnMiss(attacker, target, weapon)
	for _, listener in ipairs(B24WPN.MissListeners) do pcall(listener, attacker, target, weapon) end
	local equipment = attacker.m_equipment
	local launcher = nil
	local property = masteredProperty(attacker, weapon, launcher)
	if property ~= "GRAZE" then return end
	local mod = signedMod(attacker, "STR")
	if mod <= 0 then return end
	local _, _, _, damageType = abilityDice(weapon and weapon:getAbility(equipment.m_selectedWeaponAbility))
	B24.ApplyEffect(target, { ["effectID"] = 12, ["effectAmount"] = mod, ["dwFlags"] = DAMAGE_TYPE[damageType] or 0,
		["sourceID"] = attacker.m_id })
	B24.Log(string.format("%s grazes %s for %d", B24.Name(attacker), B24.Name(target), mod))
end

-- Sap and Vex in the advantage rules (B24ADV.lua).
function B24WPN.IsSapped(sprite)
	local untilTick = B24.Aux(sprite).B24_SappedUntil
	return untilTick ~= nil and now() <= untilTick
end

function B24WPN.VexTarget(sprite)
	local vex = B24.Aux(sprite).B24_Vex
	if vex == nil or now() > vex.untilTick then return nil end
	return vex.target
end

function B24WPN.ConsumeAttack(attacker, target)
	local aux = B24.Aux(attacker)
	aux.B24_SappedUntil = nil
	if aux.B24_Vex and aux.B24_Vex.target == target.m_id then aux.B24_Vex = nil end
end

-----------
-- Hook --
-----------

-- listener(attacker) returns true if off-hand attacks add the ability modifier to damage
-- (Two-Weapon Fighting style).
B24WPN.OffhandModifierListeners = {}

-- listener(context) can change the damage effect after critical hits (Great Weapon Fighting).
B24WPN.DamageListeners = {}

-- 2024: the off-hand attack of two-weapon fighting adds no positive ability modifier to damage.
local function offhandDamage(context)
	if not context.isLeftHand then return end
	local mod = B24.AbilityModOf(context.attacker, "STR")
	if mod <= 0 then return end
	for _, listener in ipairs(B24WPN.OffhandModifierListeners) do
		local ok, adds = pcall(listener, context.attacker)
		if ok and adds then return end
	end
	context.effect.m_effectAmount = math.max(0, context.effect.m_effectAmount - mod)
end

-- Rolls the effect's dice now (min = lowest value a die may show) and adds them to the flat part.
function B24WPN.RollDiceInto(effect, minimum)
	local total = 0
	for i = 1, effect.m_numDice do total = total + math.max(minimum or 1, B24.Roll(effect.m_diceSize)) end
	effect.m_effectAmount = effect.m_effectAmount + total
	effect.m_numDice = 0
	return total
end

function B24WPN.AbilityDice(ability)
	return abilityDice(ability)
end

-- 2024 ability modifier to damage: ranged weapons (launchers) add Dexterity, which BG doesn't;
-- finesse melee weapons swap Strength for Dexterity when it is better.
local function abilityDamage(context)
	local attacker = context.attacker
	if B24.IsMonster(attacker) then return end
	if context.launcher then
		context.effect.m_effectAmount = context.effect.m_effectAmount + B24.AbilityModOf(attacker, "DEX")
		return
	end
	if context.isLeftHand then return end
	context.effect.m_effectAmount = context.effect.m_effectAmount + B24.FinesseBonus(attacker, context.weapon, context.ability)
end

EEex_Sprite_AddAlterBaseWeaponDamageListener(function(context)
	if not B24.IsSprite(context.attacker) or not B24.IsSprite(context.target) then return end
	if context.isCritical then EEex_Utility_TryIgnore(onCritical, context) end
	EEex_Utility_TryIgnore(abilityDamage, context)
	EEex_Utility_TryIgnore(offhandDamage, context)
	for _, listener in ipairs(B24WPN.DamageListeners) do EEex_Utility_TryIgnore(listener, context) end
	EEex_Utility_TryIgnore(onMasteryHit, context)
end)
