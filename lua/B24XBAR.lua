-- BG 2024 Rules Mod: Barbarian subclasses beyond the SRD (Path of the Wild Heart, Path of the World
-- Tree, Path of the Zealot). Feature texts are this mod's own wording.
--
-- Wild Heart
--   3  Rage of the Wilds (chosen once in BG): Bear (resistance to acid, cold, fire, lightning and
--      poison while raging), Eagle (faster while raging, standing in for Dash), Wolf (allies have
--      advantage against enemies next to you while raging); Animal Speaker (no BG effect)
--   6  Aspect of the Wilds, 10 Nature Speaker (no BG effect)
--   14 Power of the Wilds (chosen once): Lion (enemies next to you have disadvantage attacking
--      anyone else while you rage), Ram (your melee hits knock enemies prone while you rage)
-- World Tree
--   3  Vitality of the Tree: temporary hit points equal to your level when you rage; each round
--      of rage, the most hurt ally within 10 ft gains rage damage d6 temporary hit points
--   6  Branches of the Tree (while raging, once per round: a creature within 30 ft makes a
--      Strength save or is pulled next to you and can't move for a round)
--   10 Battering Roots (hits with a Heavy or Versatile melee weapon also Topple: Constitution save
--      or prone; a creature already prone is pushed 10 ft instead; the extra reach has no BG form)
--   14 Travel Along the Tree (while raging, once per round: teleport up to 60 ft; the group
--      teleport has no BG form)
-- Zealot
--   3  Divine Fury (while raging, the first hit each round deals 1d6 + half your level radiant
--      damage), Warrior of the Gods (a pool of d12s to heal yourself: 4; 5 at 6, 6 at 12, 7 at 17)
--   6  Fanatical Focus (once per rage, reroll a failed save with your rage damage as a bonus)
--   10 Zealous Presence (you and allies within 60 ft have advantage on attacks and saves for a
--      round; once per long rest)
--   14 Rage of the Gods (once per long rest when you rage: resistance to magic damage for the rage;
--      the flight and revival parts have no BG effect)
--
-- Locals: B24WRAGE (Rage of the Wilds), B24WPOWR (Power of the Wilds), B24ZWUSE (Warrior of the
-- Gods dice spent), B24ZPUSE (Zealous Presence), B24ZRUSE (Rage of the Gods).

local function level(sprite) return B24BA.Level(sprite) end
local function raging(sprite) return B24BA.IsRaging(sprite) end

local function isWild(sprite, l) return B24LV.Is(sprite, "BARBARIAN", "WILD_HEART", l or 3) end
local function isTree(sprite, l) return B24LV.Is(sprite, "BARBARIAN", "WORLD_TREE", l or 3) end
local function isZealot(sprite, l) return B24LV.Is(sprite, "BARBARIAN", "ZEALOT", l or 3) end

B24LV.AddMoreSubclasses("BARBARIAN", {
	{ key = "WILD_HEART", name = "Path of the Wild Heart",
	  desc = "Your rage draws on the spirits of beasts.\n\nLevel 3: Rage of the Wilds - choose Bear (resistance to acid, cold, fire, lightning and poison while raging), Eagle (faster while raging) or Wolf (allies have advantage against enemies next to you while you rage). In BG the choice is made once.\nLevel 14: Power of the Wilds - choose Lion (enemies next to you have disadvantage attacking anyone else) or Ram (your melee hits knock enemies prone) while you rage.\nAnimal Speaker, Aspect of the Wilds and Nature Speaker have no BG effect.",
	  features = { [3] = "Rage of the Wilds", [14] = "Power of the Wilds" } },
	{ key = "WORLD_TREE", name = "Path of the World Tree",
	  desc = "Your rage taps the life force of the cosmic tree.\n\nLevel 3: Vitality of the Tree (temporary hit points equal to your level when you rage; each round of rage the most hurt ally near you gains temporary hit points).\nLevel 6: Branches of the Tree (while raging, hold a creature in place: Strength save or it can't move for a round).\nLevel 10: Battering Roots (while raging, a melee hit each round can knock the target prone).\nTravel Along the Tree has no BG effect.",
	  features = { [3] = "Vitality of the Tree", [6] = "Branches of the Tree", [10] = "Battering Roots", [14] = "Travel Along the Tree" } },
	{ key = "ZEALOT", name = "Path of the Zealot",
	  desc = "A god's fury fills your rage.\n\nLevel 3: Divine Fury (while raging, your first hit each round deals 1d6 + half your Barbarian level radiant damage); Warrior of the Gods (d12s to heal yourself: 4, more at 6, 12 and 17).\nLevel 6: Fanatical Focus (once per rage, reroll a failed save with a bonus).\nLevel 10: Zealous Presence (you and your allies have advantage on attacks and saves for a round, once per long rest).\nLevel 14: Rage of the Gods (once per long rest, a rage also gives resistance to magic damage).",
	  features = { [3] = "Divine Fury, Warrior of the Gods", [6] = "Fanatical Focus", [10] = "Zealous Presence", [14] = "Rage of the Gods" } },
})

----------------
-- Wild Heart --
----------------

B24LV.AddOption({ key = "RAGE_OF_THE_WILDS", localName = "B24WRAGE", class = "BARBARIAN", level = 3, title = "Rage of the Wilds",
	subclass = "WILD_HEART",
	list = {
		{ key = "BEAR", name = "Bear", desc = "While raging you also resist acid, cold, fire, lightning and poison damage." },
		{ key = "EAGLE", name = "Eagle", desc = "While raging you move half again as fast (standing in for a free Dash)." },
		{ key = "WOLF", name = "Wolf", desc = "While you rage, your allies have advantage on attacks against enemies next to you." },
	} })

B24LV.AddOption({ key = "POWER_OF_THE_WILDS", localName = "B24WPOWR", class = "BARBARIAN", level = 14, title = "Power of the Wilds",
	subclass = "WILD_HEART",
	list = {
		{ key = "LION", name = "Lion", desc = "While you rage, enemies next to you have disadvantage on attacks against anyone but you." },
		{ key = "RAM", name = "Ram", desc = "While you rage, your melee hits knock enemies prone." },
	} })

local function wild(sprite, key) return isWild(sprite) and B24LV.Option(sprite, "RAGE_OF_THE_WILDS") == key end
local function power(sprite, key) return isWild(sprite, 14) and B24LV.Option(sprite, "POWER_OF_THE_WILDS") == key end

table.insert(B24BA.RageListeners, function(sprite)
	local timed = function(opcode, amount, param2)
		B24.ApplyEffect(sprite, { ["effectID"] = opcode, ["effectAmount"] = amount, ["dwFlags"] = param2 or 0,
			["durationType"] = 0, ["duration"] = B24BA.RAGE_SECONDS, ["m_sourceRes"] = "B24RAGE" })
	end
	if wild(sprite, "BEAR") then
		for _, opcode in ipairs({ 27, 28, 29, 30, 173 }) do timed(opcode, 50) end
	elseif wild(sprite, "EAGLE") then
		timed(176, 150, 5)
	end
	if isTree(sprite) then B24LV.TempHP(sprite, level(sprite), B24BA.RAGE_SECONDS) end
	if isZealot(sprite) then B24.Aux(sprite).B24_FanaticalFocus = true end
	if isZealot(sprite, 14) and B24LV.Use(sprite, "RAGE_OF_THE_GODS") then
		timed(31, 50)
		B24.Log(string.format("%s: Rage of the Gods", B24.Name(sprite)))
	end
end)

-- The Wild Heart barbarians raging next to a creature.
local function ragingNext(target, filter)
	for _, barbarian in ipairs(B24.Party()) do
		if raging(barbarian) and filter(barbarian) then
			for _, enemy in ipairs(B24X.Enemies(barbarian, B24.ADJACENT)) do
				if enemy.m_id == target.m_id then return barbarian end
			end
		end
	end
end

-- Wolf: allies' attacks against enemies next to the raging barbarian have advantage.
table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	if not B24.InParty(attacker) then return false end
	local barbarian = ragingNext(target, function(b) return wild(b, "WOLF") end)
	return barbarian ~= nil and barbarian.m_id ~= attacker.m_id
end)

-- Lion: enemies next to the raging barbarian have disadvantage attacking anyone else.
table.insert(B24.DisadvantageAgainstListeners, function(attacker, target)
	if B24.InParty(attacker) then return false end
	local barbarian = ragingNext(attacker, function(b) return power(b, "LION") end)
	return barbarian ~= nil and barbarian.m_id ~= target.m_id
end)

----------------
-- World Tree --
----------------

-- Life-Giving Force: each round of rage, the most hurt ally within 10 ft.
B24LV.AddTickListener(function(sprite)
	if not isTree(sprite) or not raging(sprite) or not B24LV.OncePerRound(sprite, "LIFE_GIVING_FORCE") then return end
	local best, missing = nil, 0
	for _, ally in ipairs(B24X.Allies(sprite, B24.Feet(10))) do
		local gap = ally:getStat(B24.Stat.MAXHP) - ally.m_baseStats.m_hitPoints
		if ally.m_id ~= sprite.m_id and gap > missing then best, missing = ally, gap end
	end
	if best then B24LV.TempHP(best, B24LV.Dice(B24BA.RageDamage(sprite), 6), 6) end
end)

B24LV.AddApplyListener(function(sprite)
	B24LV.Grant(sprite, "B24WTBRN", isTree(sprite, 6))
end)

-- Branches of the Tree (innate on a creature, usable each round while raging): Strength save or
-- the creature is pulled next to the barbarian (2024: teleported) and can't move for a round.
function B24WTBRN(op402, target)
	EEex_Utility_TryIgnore(function()
		local barbarian = B24.GetSprite(op402.m_sourceId)
		if barbarian == nil then return end
		B24LV.Grant(barbarian, "B24WTBRN", true)
		if not raging(barbarian) then
			B24.Log(string.format("%s: Branches of the Tree only works while raging", B24.Name(barbarian)))
			return
		end
		if not B24LV.OncePerRound(barbarian, "BRANCHES") then return end
		if not B24.RollSave(target, "STR", B24X.DC(barbarian, "STR"), nil, " (Branches of the Tree)") then
			B24.ForceMove(target, barbarian, 30, true)
			B24.ApplyCondition(target, "GRAPPLED", { seconds = 6, source = barbarian, label = "Branches of the Tree" })
		end
	end)
end

-- Battering Roots (World Tree 10): hits with a Heavy or Versatile melee weapon also Topple
-- (Constitution save or prone; a target already prone is pushed 10 ft, Large or smaller). Ram
-- (Wild Heart 14): melee hits while raging knock prone.
local ROOTS_WEAPONS = { GREATSWORD = true, HALBERD = true, BATTLEAXE = true, LONGSWORD = true, QUARTERSTAFF = true,
	SPEAR = true, WARHAMMER = true }
table.insert(B24WPN.DamageListeners, function(context)
	local barbarian, target = context.attacker, context.target
	if context.launcher then return end
	if raging(barbarian) and power(barbarian, "RAM") then
		B24.KnockProne(target, barbarian)
		B24.Log(string.format("%s knocks %s prone", B24.Name(barbarian), B24.Name(target)))
		return
	end
	if not isTree(barbarian, 10) or not ROOTS_WEAPONS[B24WPN.WeaponKey(context.weapon) or ""] then return end
	if target:getSpellState(B24.SplState.PRONE) then
		B24.ForceMove(target, barbarian, 10, false, B24.SIZE.LARGE)
	elseif not B24.RollSave(target, "CON", B24X.DC(barbarian, "STR"), nil, " (Battering Roots)") then
		B24.KnockProne(target, barbarian)
		B24.Log(string.format("%s: Battering Roots topple %s", B24.Name(barbarian), B24.Name(target)))
	end
end)

-- Travel Along the Tree (World Tree 14): a 60-ft teleport (B24WTTRV, BG's Dimension Door) while
-- raging, once per round.
B24LV.AddTickListener(function(sprite)
	local aux, now = B24.Aux(sprite), B24.GameTick()
	local used = aux.B24_TravelTick and now >= aux.B24_TravelTick and now - aux.B24_TravelTick < 90
	local want = isTree(sprite, 14) and raging(sprite) and not used
	if want and not aux.B24_TravelReady then
		B24LV.Grant(sprite, "B24WTTRV", true)
		aux.B24_TravelReady = true
	elseif not want and aux.B24_TravelReady then
		B24LV.Grant(sprite, "B24WTTRV", false)
		aux.B24_TravelReady = nil
	end
end)

function B24WTTRV(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local aux = B24.Aux(sprite)
		aux.B24_TravelTick, aux.B24_TravelReady = B24.GameTick(), nil
		B24.Log(string.format("%s travels along the tree", B24.Name(sprite)))
	end)
end

------------
-- Zealot --
------------

B24LV.AddResource("WARRIOR_OF_THE_GODS", { localName = "B24ZWUSE",
	powers = { { res = "B24ZWARG", when = function(sprite) return isZealot(sprite) end } },
	max = function(sprite)
		if not isZealot(sprite) then return 0 end
		local l = level(sprite)
		return l >= 17 and 7 or l >= 12 and 6 or l >= 6 and 5 or 4
	end })

B24LV.AddResource("ZEALOUS_PRESENCE", { spell = "B24ZPRES", localName = "B24ZPUSE",
	max = function(sprite) return isZealot(sprite, 10) and 1 or 0 end })

B24LV.AddResource("RAGE_OF_THE_GODS", { localName = "B24ZRUSE",
	max = function(sprite) return isZealot(sprite, 14) and 1 or 0 end })

-- Warrior of the Gods: spend one die, heal that much.
function B24ZWARG(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Spend(sprite, "WARRIOR_OF_THE_GODS", 1) then return end
		local healed = B24.Roll(12)
		B24.Heal(sprite, healed)
		B24.Log(string.format("%s: Warrior of the Gods, %d hit points", B24.Name(sprite), healed))
	end)
end

-- Divine Fury: the first hit each round while raging.
table.insert(B24WPN.DamageListeners, function(context)
	local barbarian = context.attacker
	if not isZealot(barbarian) or not raging(barbarian) or not B24LV.OncePerRound(barbarian, "DIVINE_FURY") then return end
	local damage = B24.Roll(6) + math.floor(level(barbarian) / 2)
	B24X.Damage(context.target, barbarian, damage, B24X.MAGIC)
	B24.Log(string.format("%s: Divine Fury, %d radiant damage", B24.Name(barbarian), damage))
end)

-- Fanatical Focus: once per rage.
B24.AddSaveFailedListener(function(sprite, ability, dc, total, mod)
	if not isZealot(sprite, 6) or not raging(sprite) or not B24.Aux(sprite).B24_FanaticalFocus then return nil end
	B24.Aux(sprite).B24_FanaticalFocus = nil
	local roll = B24.Roll(20)
	local newTotal = roll + mod + B24BA.RageDamage(sprite)
	B24.Log(string.format("%s: Fanatical Focus, rerolls the %s save: %d", B24.Name(sprite), ability, newTotal))
	return newTotal
end)

-- Zealous Presence: advantage on attacks and saves for a round.
function B24ZPRES(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "ZEALOUS_PRESENCE")
		for _, ally in ipairs(B24X.Allies(sprite, B24.Feet(60))) do
			B24.SetTimed(ally, "ATTACK_ADV", 6)
			B24.SetTimed(ally, "SAVE_ADV", 6)
		end
		B24.Log(string.format("%s: Zealous Presence", B24.Name(sprite)))
	end)
end
