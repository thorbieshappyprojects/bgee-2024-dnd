-- BG 2024 Rules Mod: Monk subclasses beyond the SRD (Warrior of Mercy, Warrior of Shadow, Warrior
-- of the Elements). Feature texts are this mod's own wording. Their abilities spend Focus Points.
--
-- Mercy
--   3  Hand of Harm (1 Focus: your next unarmed hit this round deals a Martial Arts die + Wisdom
--      modifier necrotic damage), Hand of Healing (1 Focus, touch: heal a Martial Arts die + Wisdom
--      modifier), Implements of Mercy (Insight and Medicine)
--   6  Physician's Touch (Hand of Harm also makes the target's attacks worse for a round, standing
--      in for poisoned; Hand of Healing also cures poison, blindness, deafness and paralysis)
--   11 Flurry of Healing and Harm (during Flurry of Blows, the first Hand of Harm each round is free)
--   17 Hand of Ultimate Mercy (5 Focus, once per long rest: bring back a creature dead for less than
--      24 hours)
-- Shadow
--   3  Shadow Arts (1 Focus: invisible for a minute or until you attack, standing in for Darkness;
--      darkvision and Minor Illusion have no BG effect)
--   6  Shadow Step (each round: advantage on your next melee attack and a burst of speed; the
--      teleport has no BG effect)
--   11 Improved Shadow Step (no further BG effect)
--   17 Cloak of Shadows (3 Focus: improved invisibility for a minute)
-- Elements
--   3  Elemental Attunement (1 Focus, 10 minutes: unarmed hits deal cold damage, and the target
--      makes a Strength save or is pushed 10 ft), Manipulate Elements (no BG effect)
--   6  Elemental Burst (2 Focus: creatures around a target make a Dexterity save or take three
--      Martial Arts dice of cold damage, half on a success)
--   11 Stride of the Elements (no BG effect)
--   17 Elemental Epitome (while attuned: resistance to cold, and once per round an unarmed hit
--      deals an extra Martial Arts die)

local function level(sprite) return B24MO.Level(sprite) end
local function wis(sprite) return B24.AbilityModOf(sprite, "WIS") end
local function dc(sprite) return B24X.DC(sprite, "WIS") end

local function isMercy(sprite, l) return B24LV.Is(sprite, "MONK", "MERCY", l or 3) end
local function isShadow(sprite, l) return B24LV.Is(sprite, "MONK", "SHADOW", l or 3) end
local function isElements(sprite, l) return B24LV.Is(sprite, "MONK", "ELEMENTS", l or 3) end

B24LV.AddMoreSubclasses("MONK", {
	{ key = "MERCY", name = "Warrior of Mercy",
	  desc = "Your hands can mend or end a life.\n\nLevel 3: Hand of Harm (1 Focus: your next unarmed hit deals extra necrotic damage), Hand of Healing (1 Focus: heal by touch), Implements of Mercy (Insight and Medicine).\nLevel 6: Physician's Touch (Hand of Harm weakens the target's attacks; Hand of Healing cures poison, blindness, deafness and paralysis).\nLevel 11: Flurry of Healing and Harm (a free Hand of Harm each round during Flurry of Blows).\nLevel 17: Hand of Ultimate Mercy (5 Focus, once per long rest: a creature dead for less than 24 hours returns with 4d10 + Wisdom modifier hit points).",
	  features = { [3] = "Hand of Harm, Hand of Healing, Implements of Mercy", [6] = "Physician's Touch",
		[11] = "Flurry of Healing and Harm", [17] = "Hand of Ultimate Mercy" } },
	{ key = "SHADOW", name = "Warrior of Shadow",
	  desc = "You strike from darkness and vanish into it.\n\nLevel 3: Shadow Arts (1 Focus: invisible for a minute or until you attack).\nLevel 6: Shadow Step (each round: advantage on your next melee attack and a burst of speed).\nLevel 17: Cloak of Shadows (3 Focus: improved invisibility for a minute).\nDarkvision, Minor Illusion, the teleport and Improved Shadow Step have no BG effect.",
	  features = { [3] = "Shadow Arts", [6] = "Shadow Step", [11] = "Improved Shadow Step (no BG effect)", [17] = "Cloak of Shadows" } },
	{ key = "ELEMENTS", name = "Warrior of the Elements",
	  desc = "You channel the elements through your strikes.\n\nLevel 3: Elemental Attunement (1 Focus, 10 minutes: unarmed hits deal cold damage and push the target, Strength save).\nLevel 6: Elemental Burst (2 Focus: cold burst around a creature, Dexterity save for half).\nLevel 17: Elemental Epitome (while attuned, resistance to cold and an extra Martial Arts die once per round).\nManipulate Elements and Stride of the Elements have no BG effect.",
	  features = { [3] = "Elemental Attunement", [6] = "Elemental Burst", [11] = "Stride of the Elements (no BG effect)", [17] = "Elemental Epitome" } },
})

for _, power in ipairs({
	{ res = "B24MHARM", when = function(s) return isMercy(s) end, free = function(s) return isMercy(s, 11) and B24.HasTimed(s, "FLURRY") end },
	{ res = "B24MHHEL", when = function(s) return isMercy(s) end },
	{ res = "B24MSART", when = function(s) return isShadow(s) end },
	{ res = "B24MCLOA", cost = 3, when = function(s) return isShadow(s, 17) end },
	{ res = "B24MATTN", when = function(s) return isElements(s) end },
	{ res = "B24MBRST", cost = 2, when = function(s) return isElements(s, 6) end },
}) do table.insert(B24MO.FOCUS_POWERS, power) end

local function isFist(item)
	return item ~= nil and item.pRes.pHeader.itemType == 28
end

-----------
-- Mercy --
-----------

B24.AddGrantedSkillListener(function(sprite, proficient)
	if isMercy(sprite) then
		proficient.INSIGHT = true
		proficient.MEDICINE = true
	end
end)

function B24MHARM(op402, monk)
	EEex_Utility_TryIgnore(function()
		local free = isMercy(monk, 11) and B24.HasTimed(monk, "FLURRY") and B24LV.OncePerRound(monk, "FLURRY_OF_HARM")
		if not free and not B24MO.SpendFocus(monk, 1) then return end
		B24X.Ready(monk, "HAND_OF_HARM", {})
		B24MO.RefreshFocus(monk)
		B24.Log(string.format("%s readies Hand of Harm", B24.Name(monk)))
	end)
end

function B24MHHEL(op402, target)
	EEex_Utility_TryIgnore(function()
		local monk = B24.GetSprite(op402.m_sourceId) or target
		if not B24MO.SpendFocus(monk, 1) then return end
		local healed = math.max(1, B24.Roll(B24MO.Die(monk)) + wis(monk))
		B24.Heal(target, healed)
		if isMercy(monk, 6) then
			for _, opcode in ipairs({ 11, 75, 81, 162 }) do B24.ApplyEffect(target, { ["effectID"] = opcode }) end
		end
		B24.Log(string.format("%s: Hand of Healing, %d hit points to %s", B24.Name(monk), healed, B24.Name(target)))
	end)
end

table.insert(B24WPN.DamageListeners, function(context)
	local monk = context.attacker
	if B24X.PeekReady(monk) ~= "HAND_OF_HARM" or not isFist(context.weapon) then return end
	B24X.TakeReady(monk)
	local damage = math.max(1, B24.Roll(B24MO.Die(monk)) + wis(monk))
	B24X.Damage(context.target, monk, damage, B24X.MAGIC)
	if isMercy(monk, 6) then B24.SetTimed(context.target, "ATTACK_DIS", 6) end
	B24.Log(string.format("%s: Hand of Harm, %d necrotic damage", B24.Name(monk), damage))
end)

------------
-- Shadow --
------------

function B24MSART(op402, monk)
	EEex_Utility_TryIgnore(function()
		if not B24MO.SpendFocus(monk, 1) then return end
		B24.ApplyEffect(monk, { ["effectID"] = 20, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60 })
		B24.Log(string.format("%s: Shadow Arts", B24.Name(monk)))
	end)
end

function B24MCLOA(op402, monk)
	EEex_Utility_TryIgnore(function()
		if not B24MO.SpendFocus(monk, 3) then return end
		B24.ApplyEffect(monk, { ["effectID"] = 20, ["dwFlags"] = 1, ["durationType"] = 0, ["duration"] = 60 })
		B24.Log(string.format("%s: Cloak of Shadows", B24.Name(monk)))
	end)
end

B24LV.AddApplyListener(function(sprite)
	B24LV.Grant(sprite, "B24MSSTP", isShadow(sprite, 6))
end)

-- Shadow Step: usable every round.
function B24MSSTP(op402, monk)
	EEex_Utility_TryIgnore(function()
		B24LV.Grant(monk, "B24MSSTP", true)
		if not B24LV.OncePerRound(monk, "SHADOW_STEP") then return end
		B24.SetTimed(monk, "ATTACK_ADV", 6)
		B24.ApplyEffect(monk, { ["effectID"] = 176, ["effectAmount"] = 200, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 3 })
		B24.Log(string.format("%s: Shadow Step", B24.Name(monk)))
	end)
end

--------------
-- Elements --
--------------

function B24MATTN(op402, monk)
	EEex_Utility_TryIgnore(function()
		if not B24MO.SpendFocus(monk, 1) then return end
		B24.SetTimed(monk, "ELEMENTAL_ATTUNEMENT", 600)
		if isElements(monk, 17) then
			B24.ApplyEffect(monk, { ["effectID"] = 28, ["effectAmount"] = 50, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 600 })
		end
		B24.Log(string.format("%s: Elemental Attunement", B24.Name(monk)))
	end)
end

table.insert(B24WPN.DamageListeners, function(context)
	local monk, target = context.attacker, context.target
	if not isElements(monk) or not isFist(context.weapon) or not B24.HasTimed(monk, "ELEMENTAL_ATTUNEMENT") then return end
	context.effect.m_dWFlags = B24X.COLD
	if not B24.RollSave(target, "STR", dc(monk), nil, " (Elemental Attunement)") then
		B24.ForceMove(target, monk, 10)
	end
	if isElements(monk, 17) and B24LV.OncePerRound(monk, "ELEMENTAL_EPITOME") then
		context.effect.m_effectAmount = context.effect.m_effectAmount + B24.Roll(B24MO.Die(monk))
	end
end)

-- Elemental Burst (cast on a creature): it and the creatures around it.
function B24MBRST(op402, target)
	EEex_Utility_TryIgnore(function()
		local monk = B24.GetSprite(op402.m_sourceId)
		if monk == nil or not B24MO.SpendFocus(monk, 2) then return end
		local victims = { target }
		for _, enemy in ipairs(B24X.Enemies(target, B24.Feet(20))) do
			if enemy.m_id ~= target.m_id then table.insert(victims, enemy) end
		end
		for _, victim in ipairs(victims) do
			local damage = B24LV.Dice(3, B24MO.Die(monk))
			if B24.RollSave(victim, "DEX", dc(monk), nil, " (Elemental Burst)") then damage = math.floor(damage / 2) end
			B24X.Damage(victim, monk, damage, B24X.COLD)
		end
		B24.Log(string.format("%s: Elemental Burst", B24.Name(monk)))
	end)
end

-----------------------------
-- Hand of Ultimate Mercy --
-----------------------------

-- Hand of Ultimate Mercy (Mercy 17), once per long rest, 5 Focus, touch: a creature that died less
-- than 24 hours ago returns to life with 4d10 + Wisdom modifier hit points (raising also ends its
-- conditions). Local B24HUMUS.
local ULTIMATE_MERCY_TICKS = 24 * 60 * 60 * 15
table.insert(B24MO.FOCUS_POWERS, { res = "B24MULTM", cost = 5,
	when = function(s) return isMercy(s, 17) and s:getLocalInt("B24HUMUS") == 0 end })

function B24MULTM(op402, target)
	EEex_Utility_TryIgnore(function()
		local monk = B24.GetSprite(op402.m_sourceId)
		if monk == nil then return end
		if not B24.GState_Has(target, B24.GState.DEAD) then
			B24.Log(string.format("Hand of Ultimate Mercy: %s is not dead", B24.Name(target)))
			B24LV.RefreshPowers(monk, "FOCUS")
			return
		end
		local died = target:getLocalInt("B24DYDTH")
		if died ~= 0 and B24.GameTick() - died > ULTIMATE_MERCY_TICKS then
			B24.Log(string.format("Hand of Ultimate Mercy: %s has been dead too long", B24.Name(target)))
			B24LV.RefreshPowers(monk, "FOCUS")
			return
		end
		if not B24LV.Spend(monk, "FOCUS", 5) then return end
		monk:setLocalInt("B24HUMUS", 1)
		B24LV.RefreshPowers(monk, "FOCUS")
		local hp = math.max(1, B24LV.Dice(4, 10) + B24.AbilityModOf(monk, "WIS"))
		B24.ApplyEffect(target, { ["effectID"] = 32, ["durationType"] = 1 })
		B24.ApplyEffect(target, { ["effectID"] = 17, ["effectAmount"] = hp, ["dwFlags"] = 1, ["durationType"] = 1 })
		B24.Log(string.format("%s: Hand of Ultimate Mercy brings %s back with %d hit points", B24.Name(monk), B24.Name(target), hp))
	end)
end

B24.AddLongRestListener(function(sprite) sprite:setLocalInt("B24HUMUS", 0) end)
