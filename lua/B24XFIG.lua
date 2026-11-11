-- BG 2024 Rules Mod: Fighter subclasses beyond the SRD (Battle Master, Eldritch Knight, Psi
-- Warrior). Feature texts are this mod's own wording.
--
-- Battle Master
--   3  Combat Superiority (4 Superiority Dice d8; 5 at 7, 6 at 15; d10 at 10, d12 at 18; all
--      return on a short rest), maneuvers (3; 5 at 7, 7 at 10, 9 at 15), Student of War (no BG
--      effect)
--   7  Know Your Enemy (no BG effect)
--   15 Relentless (once per round a maneuver without dice left uses a d8)
--   Maneuvers are innate abilities. Strikes ready the maneuver for the next weapon hit this round;
--   the save DC is 8 + Proficiency Bonus + Strength or Dexterity modifier.
-- Eldritch Knight
--   3  Spellcasting (third caster, wizard list, B24XCOM.lua), cantrips (2; 3 at 10), War Bond (no
--      BG effect)
--   7  War Magic (no BG effect: BG attacks and spells don't share an action)
--   10 Eldritch Strike (a creature you hit has disadvantage on its next save against your spells
--      before the end of your next round)
--   15 Arcane Charge, 18 Improved War Magic (no BG effect)
-- Psi Warrior
--   3  Psionic Power (Psionic Energy Dice; one returns on a short rest, all on a long rest):
--      Protective Field (once per round a hit against you or an ally within 30 ft loses one die +
--      Intelligence modifier), Psionic Strike (ready: the next hit deals one die + Intelligence
--      modifier force damage), Telekinetic Movement (no BG effect)
--   7  Telekinetic Adept (no BG effect)
--   10 Guarded Mind (spend a die to end fear on yourself)
--   15 Bulwark of Force (allies around you get +2 AC for a minute; once per long rest, or a die)
--   18 Telekinetic Master (no BG effect)
--
-- Locals: B24SDUSE (Superiority Dice spent), B24MNV1.. (maneuvers), B24EKS* (Eldritch Knight
-- spells and slots), B24PEUSE (Psionic Energy Dice spent), B24BWUSE (Bulwark of Force).

B24XF = {}

local function level(sprite) return B24FI.Level(sprite) end

local function isBattleMaster(sprite, l) return B24LV.Is(sprite, "FIGHTER", "BATTLE_MASTER", l or 3) end
local function isEldritch(sprite, l) return B24LV.Is(sprite, "FIGHTER", "ELDRITCH_KNIGHT", l or 3) end
local function isPsi(sprite, l) return B24LV.Is(sprite, "FIGHTER", "PSI_WARRIOR", l or 3) end

B24LV.AddMoreSubclasses("FIGHTER", {
	{ key = "BATTLE_MASTER", name = "Battle Master",
	  desc = "A Battle Master turns tactics into technique: special maneuvers fuelled by Superiority Dice.\n\nLevel 3: Combat Superiority (4 Superiority Dice, d8; they return on a short rest), three maneuvers.\nLevel 7: two more maneuvers, a fifth die.\nLevel 10: d10 dice, two more maneuvers.\nLevel 15: Relentless (a maneuver once per round with a d8 when no dice are left), two more maneuvers, a sixth die.\nLevel 18: d12 dice.\nStudent of War and Know Your Enemy have no BG effect.",
	  features = { [3] = "Combat Superiority (4 d8 dice, 3 maneuvers)", [7] = "5 dice, 5 maneuvers",
		[10] = "d10 dice, 7 maneuvers", [15] = "Relentless, 6 dice, 9 maneuvers", [18] = "d12 dice" } },
	{ key = "ELDRITCH_KNIGHT", name = "Eldritch Knight",
	  desc = "An Eldritch Knight mixes swordplay with wizard magic.\n\nLevel 3: Spellcasting (wizard spells with Intelligence; 2024 third-caster slots; spells appear as innate abilities while you have a slot of their level), two wizard cantrips.\nLevel 10: Eldritch Strike (a creature you hit has disadvantage on its next save against your spells for a round), a third cantrip.\nSpell levels 2 at 7, 3 at 13, 4 at 19.\nWar Bond, War Magic, Arcane Charge and Improved War Magic have no BG effect.",
	  features = { [3] = "Spellcasting (wizard spells), 2 cantrips", [7] = "level 2 spells", [10] = "Eldritch Strike, 3 cantrips",
		[13] = "level 3 spells", [19] = "level 4 spells" } },
	{ key = "PSI_WARRIOR", name = "Psi Warrior",
	  desc = "A Psi Warrior fights with the power of the mind, spending Psionic Energy Dice.\n\nLevel 3: Psionic Power (4 d6 dice; one returns on a short rest, all on a long rest): Protective Field (once per round, a hit against you or a nearby ally loses a die + Intelligence modifier), Psionic Strike (your next hit deals a die + Intelligence modifier force damage).\nLevel 10: Guarded Mind (spend a die to shake off fear).\nLevel 15: Bulwark of Force (allies around you get +2 AC for a minute).\nDice: 6d8 at 5, 8d8 at 9, 8d10 at 11, 10d10 at 13, 12d12 at 17.\nTelekinetic features have no BG effect.",
	  features = { [3] = "Psionic Power (Protective Field, Psionic Strike)", [10] = "Guarded Mind", [15] = "Bulwark of Force" } },
})

-------------------
-- Battle Master --
-------------------

function B24XF.SuperiorityDie(sprite)
	local l = level(sprite)
	return l >= 18 and 12 or l >= 10 and 10 or 8
end

-- Maneuvers: strike = readied for the next hit (on(target, fighter, roll, dc, context)); else
-- use(target, fighter, roll) runs at once (target = the creature the innate is used on).
B24XF.MANEUVERS = {
	{ key = "TRIP", res = "B24MTRIP", name = "Trip Attack", strike = true,
	  desc = "Your next hit this round deals one Superiority Die extra damage, and the target makes a Strength save or falls prone.",
	  on = function(target, fighter, roll, dc)
		if not B24.RollSave(target, "STR", dc, nil, " (Trip Attack)") then
			B24.KnockProne(target, fighter)
		end
	  end },
	{ key = "PUSH", res = "B24MPUSH", name = "Pushing Attack", strike = true,
	  desc = "Your next hit this round deals one Superiority Die extra damage, and the target makes a Strength save or is pushed 15 feet away.",
	  on = function(target, fighter, roll, dc)
		if not B24.RollSave(target, "STR", dc, nil, " (Pushing Attack)") then
			B24.ForceMove(target, fighter, 15, false, B24.SIZE.LARGE)
		end
	  end },
	{ key = "MENACE", res = "B24MMENA", name = "Menacing Attack", strike = true,
	  desc = "Your next hit this round deals one Superiority Die extra damage, and the target makes a Wisdom save or is frightened until the end of your next round.",
	  on = function(target, fighter, roll, dc)
		if not B24.RollSave(target, "WIS", dc, nil, " (Menacing Attack)", { FEAR = true }) then
			B24.ApplyEffect(target, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 12, ["sourceID"] = fighter.m_id })
		end
	  end },
	{ key = "DISARM", res = "B24MDISA", name = "Disarming Attack", strike = true,
	  desc = "Your next hit this round deals one Superiority Die extra damage, and the target makes a Strength save or loses its grip. In BG: its attacks have disadvantage until the end of the next round.",
	  on = function(target, fighter, roll, dc)
		if not B24.RollSave(target, "STR", dc, nil, " (Disarming Attack)") then B24.SetTimed(target, "ATTACK_DIS", 12) end
	  end },
	{ key = "DISTRACT", res = "B24MDIST", name = "Distracting Strike", strike = true,
	  desc = "Your next hit this round deals one Superiority Die extra damage, and the next attack against the target by someone else before your next round has advantage.",
	  on = function(target) B24.SetTimed(target, "GRANTS_ADV", 6) end },
	{ key = "GOAD", res = "B24MGOAD", name = "Goading Attack", strike = true,
	  desc = "Your next hit this round deals one Superiority Die extra damage, and the target makes a Wisdom save or has disadvantage on attacks against anyone but you until the end of your next round.",
	  on = function(target, fighter, roll, dc)
		if not B24.RollSave(target, "WIS", dc, nil, " (Goading Attack)") then
			B24.Aux(target).B24_Goaded = { by = fighter.m_id, untilTick = B24.GameTick() + 180 }
		end
	  end },
	{ key = "FEINT", res = "B24MFEIN", name = "Feinting Attack", strike = true, advantage = true,
	  desc = "Your next attack this round has advantage, and a hit deals one Superiority Die extra damage." },
	{ key = "PRECISION", res = "B24MPREC", name = "Precision Attack",
	  desc = "Add one Superiority Die to your attack rolls this round. In BG the die is rolled at once and added for the whole round.",
	  use = function(target, fighter, roll)
		B24.ApplyEffect(fighter, { ["effectID"] = 54, ["effectAmount"] = roll, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
		B24.Log(string.format("%s: Precision Attack +%d to hit", B24.Name(fighter), roll))
	  end },
	{ key = "LUNGE", res = "B24MLUNG", name = "Lunging Attack", strike = true,
	  desc = "You move 5 feet faster this round, and your next hit deals one Superiority Die extra damage.",
	  ready = function(fighter)
		B24.ApplyEffect(fighter, { ["effectID"] = 176, ["effectAmount"] = 117, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 6 })
	  end },
	{ key = "SWEEP", res = "B24MSWEE", name = "Sweeping Attack", strike = true, sweep = true,
	  desc = "Your next melee hit this round also deals one Superiority Die of damage to another enemy next to the target." },
	{ key = "PARRY", res = "B24MPARR", name = "Parry",
	  desc = "The next melee hit against you this round loses one Superiority Die + your Strength or Dexterity modifier damage.",
	  use = function(target, fighter, roll)
		B24.Aux(fighter).B24_Parry = { amount = roll + B24.AbilityModOf(fighter, B24X.MartialAbility(fighter)), untilTick = B24.GameTick() + 90 }
	  end },
	{ key = "RALLY", res = "B24MRALY", name = "Rally", touch = true,
	  desc = "An ally (or you) gains temporary hit points equal to one Superiority Die + your Charisma modifier.",
	  use = function(target, fighter, roll)
		B24LV.TempHP(target, math.max(1, roll + B24.AbilityModOf(fighter, "CHA")), 3600)
	  end },
	{ key = "EVASIVE", res = "B24MEVAS", name = "Evasive Footwork",
	  desc = "Add one Superiority Die to your Armor Class this round.",
	  use = function(target, fighter, roll)
		B24.ApplyEffect(fighter, { ["effectID"] = 0, ["effectAmount"] = roll, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
	  end },
	{ key = "COMMAND", res = "B24MCOMM", name = "Commander's Strike", touch = true,
	  desc = "An ally makes one extra attack this round, and its next hit deals one Superiority Die extra damage. In BG you keep your own attacks.",
	  use = function(target, fighter, roll)
		B24.ApplyEffect(target, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
		B24X.Ready(target, "COMMANDED", { roll = roll })
	  end },
}

B24LV.AddPick({ key = "MANEUVERS", prefix = "B24MNV", title = "Maneuver",
	help = "Choose a maneuver. Maneuvers are innate abilities that spend a Superiority Die.",
	list = function() return B24XF.MANEUVERS end,
	count = function(sprite)
		if not isBattleMaster(sprite) then return 0 end
		local l = level(sprite)
		return l >= 15 and 9 or l >= 10 and 7 or l >= 7 and 5 or 3
	end })

local function maneuverPowers()
	local powers = {}
	for _, maneuver in ipairs(B24XF.MANEUVERS) do
		table.insert(powers, { res = maneuver.res,
			when = function(sprite) return isBattleMaster(sprite) and B24LV.HasPicked(sprite, "MANEUVERS", maneuver.key) end,
			free = function(sprite) return level(sprite) >= 15 end })
	end
	return powers
end

B24LV.AddResource("SUPERIORITY", { localName = "B24SDUSE", shortRest = "all", powers = maneuverPowers(),
	max = function(sprite)
		if not isBattleMaster(sprite) then return 0 end
		local l = level(sprite)
		return l >= 15 and 6 or l >= 7 and 5 or 4
	end })

-- Spends a die (or, with Relentless, the free d8 of the round); returns the roll or nil.
local function superiorityRoll(fighter)
	if B24LV.Spend(fighter, "SUPERIORITY", 1) then return B24.Roll(B24XF.SuperiorityDie(fighter)) end
	if level(fighter) >= 15 and B24LV.OncePerRound(fighter, "RELENTLESS") then
		return B24.Roll(8)
	end
end

for _, maneuver in ipairs(B24XF.MANEUVERS) do
	_G[maneuver.res] = function(op402, target)
		EEex_Utility_TryIgnore(function()
			local fighter = B24.GetSprite(op402.m_sourceId) or target
			local roll = superiorityRoll(fighter)
			-- The innates are granted again either way (an unused Relentless keeps them available).
			B24LV.RefreshPowers(fighter, "SUPERIORITY")
			if roll == nil then return end
			if maneuver.strike then
				B24X.Ready(fighter, "MANEUVER", { key = maneuver.key, roll = roll })
				if maneuver.advantage then B24.SetTimed(fighter, "ATTACK_ADV", 6) end
				if maneuver.ready then maneuver.ready(fighter) end
				B24.Log(string.format("%s readies %s (d%d: %d)", B24.Name(fighter), maneuver.name, B24XF.SuperiorityDie(fighter), roll))
			else
				maneuver.use(target, fighter, roll)
				B24.Log(string.format("%s: %s (%d)", B24.Name(fighter), maneuver.name, roll))
			end
		end)
	end
end

local function maneuverByKey(key)
	for _, maneuver in ipairs(B24XF.MANEUVERS) do
		if maneuver.key == key then return maneuver end
	end
end

table.insert(B24WPN.DamageListeners, function(context)
	local attacker, target = context.attacker, context.target
	local key = B24X.PeekReady(attacker)
	if key ~= "MANEUVER" and key ~= "COMMANDED" then return end
	local _, data = B24X.TakeReady(attacker)
	if key == "COMMANDED" then
		context.effect.m_effectAmount = context.effect.m_effectAmount + data.roll
		B24.Log(string.format("%s: Commander's Strike +%d", B24.Name(attacker), data.roll))
		return
	end
	local maneuver = maneuverByKey(data.key)
	if maneuver.sweep then
		if context.launcher then return end
		for _, enemy in ipairs(B24X.Enemies(target, B24.ADJACENT)) do
			if enemy.m_id ~= target.m_id then
				B24X.Damage(enemy, attacker, data.roll, 0)
				B24.Log(string.format("%s: Sweeping Attack hits %s for %d", B24.Name(attacker), B24.Name(enemy), data.roll))
				break
			end
		end
		return
	end
	context.effect.m_effectAmount = context.effect.m_effectAmount + data.roll
	B24.Log(string.format("%s: %s +%d", B24.Name(attacker), maneuver.name, data.roll))
	if maneuver.on then maneuver.on(target, attacker, data.roll, B24X.DC(attacker, B24X.MartialAbility(attacker)), context) end
end)

-- Parry: the next melee hit against the fighter loses the parry amount.
table.insert(B24WPN.DamageListeners, function(context)
	local aux = B24.Aux(context.target)
	local parry = aux.B24_Parry
	if parry == nil or context.launcher then return end
	aux.B24_Parry = nil
	if B24.GameTick() > parry.untilTick then return end
	B24WPN.RollDiceInto(context.effect)
	context.effect.m_effectAmount = math.max(0, context.effect.m_effectAmount - parry.amount)
	B24.Log(string.format("%s parries %d damage", B24.Name(context.target), parry.amount))
end)

-- Goading Attack: disadvantage against anyone but the fighter.
table.insert(B24.DisadvantageAgainstListeners, function(attacker, target)
	local goaded = B24.Aux(attacker).B24_Goaded
	return goaded ~= nil and B24.GameTick() <= goaded.untilTick and goaded.by ~= target.m_id
end)

---------------------
-- Eldritch Knight --
---------------------

B24X.AddThirdCaster({ class = "FIGHTER", subclass = "ELDRITCH_KNIGHT", prefix = "B24EKS", title = "Eldritch Knight Spell",
	cantrips = function(l) return l >= 10 and 3 or 2 end })

-- Eldritch Strike (10): weapon hits mark the target for a round and a half.
table.insert(B24WPN.DamageListeners, function(context)
	if not isEldritch(context.attacker, 10) then return end
	B24.Aux(context.target).B24_EldritchStrike = { by = context.attacker.m_id, untilTick = B24.GameTick() + 135 }
end)

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	local mark = B24.Aux(sprite).B24_EldritchStrike
	if mark == nil or conditions.SOURCE ~= mark.by or B24.GameTick() > mark.untilTick then return false, false end
	B24.Aux(sprite).B24_EldritchStrike = nil
	return false, true
end)

-----------------
-- Psi Warrior --
-----------------

local function psionicDie(sprite)
	local _, die = B24X.PsionicDice(level(sprite))
	return die
end

local function int(sprite) return B24.AbilityModOf(sprite, "INT") end

B24LV.AddResource("PSI_WARRIOR_DICE", { localName = "B24PEUSE", shortRest = "one",
	powers = {
		{ res = "B24PSTRK", when = function(sprite) return isPsi(sprite) end },
		{ res = "B24PGMND", when = function(sprite) return isPsi(sprite, 10) end },
	},
	max = function(sprite)
		if not isPsi(sprite) then return 0 end
		local count = B24X.PsionicDice(level(sprite))
		return count
	end })

B24LV.AddResource("BULWARK", { spell = "B24PBULW", localName = "B24BWUSE",
	max = function(sprite) return isPsi(sprite, 15) and 1 or 0 end })

-- Psionic Strike: the next hit this round deals one die + Intelligence modifier force damage.
function B24PSTRK(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Spend(sprite, "PSI_WARRIOR_DICE", 1) then return end
		B24X.Ready(sprite, "PSIONIC_STRIKE", {})
		B24.Log(string.format("%s readies a Psionic Strike", B24.Name(sprite)))
	end)
end

table.insert(B24WPN.DamageListeners, function(context)
	local attacker = context.attacker
	if B24X.PeekReady(attacker) ~= "PSIONIC_STRIKE" then return end
	B24X.TakeReady(attacker)
	local damage = math.max(1, B24.Roll(psionicDie(attacker)) + int(attacker))
	B24X.Damage(context.target, attacker, damage, B24X.MAGIC)
	B24.Log(string.format("%s: Psionic Strike, %d force damage", B24.Name(attacker), damage))
end)

-- Protective Field: once per round, a hit against the Psi Warrior or an ally within 30 ft loses
-- one die + Intelligence modifier (spends a die).
table.insert(B24WPN.DamageListeners, function(context)
	local target = context.target
	if not B24.InParty(target) then return end
	for _, fighter in ipairs(B24.Party()) do
		if isPsi(fighter) and B24LV.Remaining(fighter, "PSI_WARRIOR_DICE") > 0 then
			local near = false
			for _, ally in ipairs(B24X.Allies(fighter, B24.Feet(30))) do near = near or ally.m_id == target.m_id end
			if near and B24LV.OncePerRound(fighter, "PROTECTIVE_FIELD") then
				B24LV.Spend(fighter, "PSI_WARRIOR_DICE", 1)
				B24WPN.RollDiceInto(context.effect)
				local reduction = math.max(1, B24.Roll(psionicDie(fighter)) + int(fighter))
				context.effect.m_effectAmount = math.max(0, context.effect.m_effectAmount - reduction)
				B24.Log(string.format("%s: Protective Field, -%d damage", B24.Name(fighter), reduction))
				return
			end
		end
	end
end)

-- Guarded Mind (7): ends fear on the Psi Warrior.
function B24PGMND(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Spend(sprite, "PSI_WARRIOR_DICE", 1) then return end
		B24.ApplyEffect(sprite, { ["effectID"] = 161 })
		B24.Log(string.format("%s: Guarded Mind", B24.Name(sprite)))
	end)
end

-- Bulwark of Force (10): the Psi Warrior and up to Intelligence modifier allies within 30 ft get
-- +2 AC (half cover) for a minute. Once per long rest; later uses spend a die.
function B24PBULW(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Use(sprite, "BULWARK") and not B24LV.Spend(sprite, "PSI_WARRIOR_DICE", 1) then return end
		local count = math.max(1, int(sprite)) + 1
		for _, ally in ipairs(B24X.Allies(sprite, B24.Feet(30))) do
			if count <= 0 then break end
			count = count - 1
			B24.ApplyEffect(ally, { ["effectID"] = 0, ["effectAmount"] = 2, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60 })
		end
		B24LV.Grant(sprite, "B24PBULW", isPsi(sprite, 15) and B24LV.Remaining(sprite, "PSI_WARRIOR_DICE") > 0)
		B24.Log(string.format("%s: Bulwark of Force", B24.Name(sprite)))
	end)
end
