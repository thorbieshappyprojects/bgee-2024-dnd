-- BG 2024 Rules Mod: the 2024 Paladin with the Oath of Devotion (SRD subclass). BG's paladin class
-- abilities (CLABPA01) are removed at install time. Paladin spells follow with the spell updates.
--
--   1  Lay on Hands (a pool of 5 x Paladin level hit points), Weapon Mastery (2)
--   2  Fighting Style, Paladin's Smite (Divine Smite, switched on and off; uses per long rest
--      stand in for spending spell slots)
--   3  Channel Divinity (2 uses; 3 at 11), subclass: Devotion: Sacred Weapon
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Extra Attack (engine table), Faithful Steed (a spell: not yet)
--   6  Aura of Protection (allies within 10 ft add your Charisma modifier to saves)
--   7  Devotion: Aura of Devotion (immune to charm in the aura)
--   9  Abjure Foes
--   10 Aura of Courage (immune to fear in the aura)
--   11 Radiant Strikes (+1d8 on melee weapon hits)
--   14 Restoring Touch (Lay on Hands ends conditions, 5 points each), 15 Devotion: Smite of
--      Protection (a Divine Smite gives you and your aura +2 AC until your next turn)
--   18 Aura Expansion (30 ft)
--   20 Devotion: Holy Nimbus
--
-- Locals: B24LHUSE (Lay on Hands points spent), B24SMUSE (smites), B24CDUSE (Channel
-- Divinity), B24HNUSE (Holy Nimbus).

B24PA = {}

function B24PA.Level(sprite)
	return B24LV.ClassLevel(sprite, "PALADIN")
end

B24LV.AddSubclasses("PALADIN", 3, {
	{ key = "DEVOTION", name = "Oath of Devotion",
	  desc = "Paladins of Devotion follow the ideals of justice and order.\n\nLevel 3: Sacred Weapon (Channel Divinity: your Charisma modifier to attack rolls for 10 minutes); Oath spells follow with the spell updates.\nLevel 7: Aura of Devotion (you and allies in your aura can't be charmed).\nLevel 15: Smite of Protection (a Divine Smite gives you and the allies in your aura +2 AC until your next turn).\nLevel 20: Holy Nimbus (radiant aura that damages enemies, once per long rest).",
	  features = { [3] = "Sacred Weapon", [7] = "Aura of Devotion", [15] = "Smite of Protection", [20] = "Holy Nimbus" } },
})

local function isDevotion(sprite)
	return B24LV.Subclass(sprite, "PALADIN") == "DEVOTION"
end

local function cha(sprite)
	return B24.AbilityModOf(sprite, "CHA")
end

B24LV.AddResource("LAY_ON_HANDS", { localName = "B24LHUSE",
	max = function(sprite) return 5 * B24PA.Level(sprite) end })

-- Divine Smite uses until spell slots follow the 2024 table: the free use plus the number of
-- 2024 Paladin spell slots.
B24PA.SLOTS = { 2, 2, 3, 3, 6, 6, 7, 7, 9, 9, 10, 10, 11, 11, 12, 12, 14, 14, 15, 15 }
B24LV.AddResource("SMITE", { localName = "B24SMUSE",
	max = function(sprite)
		local level = B24PA.Level(sprite)
		return level >= 2 and (1 + B24PA.SLOTS[math.min(20, level)]) or 0
	end })

B24LV.AddResource("CHANNEL_DIVINITY", { localName = "B24CDUSE", shortRest = "one",
	max = function(sprite)
		local level = B24PA.Level(sprite)
		return level >= 11 and 3 or level >= 3 and 2 or 0
	end })

B24LV.AddResource("HOLY_NIMBUS", { spell = "B24NIMBS", localName = "B24HNUSE",
	max = function(sprite) return (B24PA.Level(sprite) >= 20 and isDevotion(sprite)) and 1 or 0 end })

-- Channel Divinity options of the subclasses: { res, when = function(sprite) }.
B24PA.CHANNEL_POWERS = {}

-- Lay on Hands and the Channel Divinity abilities stay granted while their pool has uses.
local function refreshPools(sprite)
	local level = B24PA.Level(sprite)
	local entries = {
		{ "B24LOH", level >= 1 and B24LV.Remaining(sprite, "LAY_ON_HANDS") > 0 },
		{ "B24SACWP", level >= 3 and isDevotion(sprite) and B24LV.Remaining(sprite, "CHANNEL_DIVINITY") > 0 },
		{ "B24ABJUR", level >= 9 and B24LV.Remaining(sprite, "CHANNEL_DIVINITY") > 0 },
	}
	for _, power in ipairs(B24PA.CHANNEL_POWERS) do
		table.insert(entries, { power.res, power.when(sprite) and B24LV.Remaining(sprite, "CHANNEL_DIVINITY") > 0 })
	end
	for _, entry in ipairs(entries) do
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = entry[1] })
		if entry[2] then B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = entry[1] }) end
	end
end

B24.AddShortRestListener(function(sprite) if B24PA.Level(sprite) > 0 then refreshPools(sprite) end end)
B24.AddLongRestListener(function(sprite) if B24PA.Level(sprite) > 0 then refreshPools(sprite) end end)

B24PA.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24PA.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24PA.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, STYLE = level >= 2 and 1 or 0, MASTERY = B24.MasteryCount(sprite) }
end)

B24PA.FEATURES = {
	[1] = "Lay on Hands, Weapon Mastery (2 weapons)",
	[2] = "Fighting Style, Paladin's Smite (Divine Smite)",
	[3] = "Channel Divinity (2 uses), subclass",
	[4] = "Ability Score Improvement",
	[5] = "Extra Attack",
	[6] = "Aura of Protection",
	[8] = "Ability Score Improvement",
	[9] = "Abjure Foes",
	[10] = "Aura of Courage",
	[11] = "Radiant Strikes, Channel Divinity (3 uses)",
	[12] = "Ability Score Improvement",
	[14] = "Restoring Touch (Lay on Hands ends conditions, 5 points each)",
	[16] = "Ability Score Improvement",
	[18] = "Aura Expansion (30 ft)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24PA.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "PALADIN") + 1, level do
		if B24PA.FEATURES[l] then table.insert(lines, string.format("Paladin %d: %s", l, B24PA.FEATURES[l])) end
	end
	return lines
end)

-- Ajantis' creature files carry BG's 2e Lay on Hands as an innate (SPIN109), beside the 2024 one
-- (B24LOH): the old one goes.
B24PA.OLD_LAY_ON_HANDS = "SPIN109"

B24LV.AddApplyListener(function(sprite)
	if B24PA.Level(sprite) <= 0 then return end
	refreshPools(sprite)
	local known = false
	local node = B24.InnateList(sprite.m_knownSpellsInnate).m_pNodeHead
	while node and not known do
		local ok, res = pcall(function() return node.data.m_knownSpellId:get():upper() end)
		known = ok and res == B24PA.OLD_LAY_ON_HANDS
		node = node.pNext
	end
	if known then
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = B24PA.OLD_LAY_ON_HANDS })
		B24.Log(string.format("%s: BG's Lay on Hands removed (the 2024 Lay on Hands replaces it)", B24.Name(sprite)))
	end
end)

------------------
-- Lay on Hands --
------------------

-- op402 entry point of B24LOH.SPL (touch): heals the target from the pool, as much as it misses.
function B24LOH(op402, target)
	EEex_Utility_TryIgnore(function()
		local paladin = B24.GetSprite(op402.m_sourceId) or target
		local missing = target:getStat(B24.Stat.MAXHP) - target.m_baseStats.m_hitPoints
		local amount = math.min(math.max(0, missing), B24LV.Remaining(paladin, "LAY_ON_HANDS"))
		if amount > 0 then
			paladin:setLocalInt("B24LHUSE", paladin:getLocalInt("B24LHUSE") + amount)
			B24.Heal(target, amount)
		end
		if B24PA.Level(paladin) >= 14 then EEex_Utility_TryIgnore(B24PA.RestoringTouch, paladin, target) end
		refreshPools(paladin)
		B24.Log(string.format("%s: Lay on Hands, %d hit points to %s (%d left)", B24.Name(paladin), amount,
			B24.Name(target), B24LV.Remaining(paladin, "LAY_ON_HANDS")))
	end)
end

-- Restoring Touch (14): Lay on Hands also ends Blinded, Charmed, Deafened, Frightened, Paralyzed
-- and Stunned, 5 points of the pool each (op337 removes the effects of the opcode behind each).
local function hasEffect(sprite, opcode)
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == opcode then found = true return true end
	end)
	return found
end

B24PA.RESTORING_TOUCH = {
	{ name = "blinded", has = function(s) return B24.GState_Has(s, B24.GState.BLIND) end, opcodes = { 74 } },
	{ name = "charmed", has = function(s) return B24.GState_Has(s, B24.GState.CHARMED) end, opcodes = { 5 } },
	{ name = "deafened", has = function(s) return hasEffect(s, 80) end, opcodes = { 80 } },
	{ name = "frightened", has = function(s) return B24.GState_Has(s, B24.GState.PANIC) end, opcodes = { 24 } },
	{ name = "paralyzed", has = function(s) return s:getStat(B24.Stat.HELD) > 0 end, opcodes = { 109, 175, 185 } },
	{ name = "stunned", has = function(s) return B24.GState_Has(s, B24.GState.STUNNED) end, opcodes = { 45 } },
}

function B24PA.RestoringTouch(paladin, target)
	local ended = {}
	for _, condition in ipairs(B24PA.RESTORING_TOUCH) do
		if condition.has(target) and B24LV.Remaining(paladin, "LAY_ON_HANDS") >= 5 then
			paladin:setLocalInt("B24LHUSE", paladin:getLocalInt("B24LHUSE") + 5)
			for _, opcode in ipairs(condition.opcodes) do
				B24.ApplyEffect(target, { ["effectID"] = 337, ["dwFlags"] = opcode, ["durationType"] = 1 })
			end
			table.insert(ended, condition.name)
		end
	end
	if #ended > 0 then
		B24.Log(string.format("%s: Restoring Touch ends %s on %s", B24.Name(paladin), table.concat(ended, ", "), B24.Name(target)))
	end
end

------------------
-- Divine Smite --
------------------

-- Divine Smite is switched on or off (op402 entry point of B24SMITE.SPL, local B24SMTOG). While
-- it is on, the first melee hit of each round smites: 2d8 extra radiant damage (more dice at
-- higher levels, standing in for higher spell slots), spending a use. A miss costs nothing, and
-- the paladin's attacks go on uninterrupted.
function B24SMITE(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local on = sprite:getLocalInt("B24SMTOG") == 0
		sprite:setLocalInt("B24SMTOG", on and 1 or 0)
		B24LV.Grant(sprite, "B24SMITE", true)
		B24.Log(string.format("%s: Divine Smite %s (%d uses left)", B24.Name(sprite), on and "on" or "off",
			B24LV.Remaining(sprite, "SMITE")))
	end)
end

B24LV.AddApplyListener(function(sprite)
	B24LV.Grant(sprite, "B24SMITE", B24PA.Level(sprite) >= 2)
end)

local function smiteDice(level)
	return 2 + (level >= 17 and 3 or level >= 13 and 2 or level >= 9 and 2 or level >= 5 and 1 or 0)
end

table.insert(B24WPN.DamageListeners, function(context)
	local paladin = context.attacker
	local level = B24PA.Level(paladin)
	if level <= 0 or context.launcher then return end
	local extra, parts = 0, {}
	if paladin:getLocalInt("B24SMTOG") == 1 and level >= 2 and B24LV.Remaining(paladin, "SMITE") > 0
		and B24LV.OncePerRound(paladin, "DIVINE_SMITE") then
		B24LV.Use(paladin, "SMITE")
		local dice = smiteDice(level) * (context.isCritical and 2 or 1)
		local smite = 0
		for i = 1, dice do smite = smite + B24.Roll(8) end
		extra = extra + smite
		table.insert(parts, string.format("Divine Smite %dd8 = %d", dice, smite))
		-- Smite of Protection (Devotion 15): you and the allies in your aura get +2 AC (half cover)
		-- until your next turn.
		if level >= 15 and isDevotion(paladin) then
			local allies = EEex_Sprite_GetAllOfTypeStringInRange(paladin, "[PC]", B24PA.AuraRange(level), true) or {}
			table.insert(allies, paladin)
			local seen = {}
			for _, ally in ipairs(allies) do
				if not seen[ally.m_id] then
					seen[ally.m_id] = true
					-- Once per round; the engine doesn't add an AC effect with a source resource, nor
					-- a second identical one (cover doesn't stack in 2024 either).
					B24.ApplyEffect(ally, { ["effectID"] = 0, ["effectAmount"] = 2, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
				end
			end
			table.insert(parts, "Smite of Protection")
		end
	end
	if level >= 11 then
		local radiant = B24.Roll(8)
		extra = extra + radiant
		table.insert(parts, "Radiant Strikes " .. radiant)
	end
	if extra > 0 then
		context.effect.m_effectAmount = context.effect.m_effectAmount + extra
		B24.Log(string.format("%s: %s", B24.Name(paladin), table.concat(parts, ", ")))
	end
end)

-----------------------
-- Channel Divinity --
-----------------------

local function useChannel(sprite)
	if not B24LV.Use(sprite, "CHANNEL_DIVINITY") then return false end
	refreshPools(sprite)
	return true
end
B24PA.UseChannel = useChannel

-- Sacred Weapon: Charisma modifier (at least +1) to attack rolls for 10 minutes.
function B24SACWP(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not useChannel(sprite) then return end
		B24.ApplyEffect(sprite, { ["effectID"] = 54, ["effectAmount"] = math.max(1, cha(sprite)), ["dwFlags"] = 0,
			["durationType"] = 0, ["duration"] = 600, ["m_sourceRes"] = "B24SACWP" })
		B24.Log(string.format("%s: Sacred Weapon (+%d to attack rolls)", B24.Name(sprite), math.max(1, cha(sprite))))
	end)
end

-- Abjure Foes: up to Charisma modifier enemies within 60 ft make a Wisdom save or are frightened
-- for a minute.
function B24ABJUR(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not useChannel(sprite) then return end
		local dc = 8 + cha(sprite) + B24.ProfOf(sprite)
		local count = math.max(1, cha(sprite))
		for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[ENEMY]", B24.Feet(60), true) or {}) do
			if count <= 0 then break end
			count = count - 1
			if not B24.RollSave(enemy, "WIS", dc, nil, " (Abjure Foes)", { FEAR = true }) then
				B24.ApplyEffect(enemy, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 60, ["sourceID"] = sprite.m_id })
			end
		end
	end)
end

-----------
-- Auras --
-----------

local function auraRange(level)
	return level >= 18 and B24.Feet(30) or B24.Feet(10)
end
B24PA.AuraRange = auraRange

-- Paladins whose aura (6+) covers the creature: the party member itself or nearby party members.
local function aurasCovering(sprite)
	local covering = {}
	for _, paladin in ipairs(B24.Party()) do
		local level = B24PA.Level(paladin)
		if level >= 6 and not B24.GState_Has(paladin, B24.GState.DEAD) and not B24.GState_Has(paladin, B24.GState.HELPLESS) then
			if paladin.m_id == sprite.m_id then
				table.insert(covering, paladin)
			else
				for _, ally in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(paladin, "[PC]", auraRange(level), true) or {}) do
					if ally.m_id == sprite.m_id then table.insert(covering, paladin) break end
				end
			end
		end
	end
	return covering
end

-- Aura of Protection: the best Charisma modifier (at least +1) of the auras covering the creature.
B24.AddSaveBonusListener(function(sprite)
	if not B24.InParty(sprite) then return 0 end
	local best = 0
	for _, paladin in ipairs(aurasCovering(sprite)) do best = math.max(best, math.max(1, cha(paladin))) end
	return best
end)

-- Aura of Devotion (7, Devotion) and Aura of Courage (10): immunity to charm and fear inside the
-- aura, renewed every second; Holy Nimbus damages enemies in it every round.
B24LV.AddTickListener(function(paladin)
	local level = B24PA.Level(paladin)
	if level < 7 or B24.GState_Has(paladin, B24.GState.DEAD) then return end
	local allies = EEex_Sprite_GetAllOfTypeStringInRange(paladin, "[PC]", auraRange(level), true) or {}
	table.insert(allies, paladin)
	for _, ally in ipairs(allies) do
		if isDevotion(paladin) then
			B24.ApplyEffect(ally, { ["effectID"] = 101, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 2 })
		end
		if level >= 10 then
			B24.ApplyEffect(ally, { ["effectID"] = 101, ["dwFlags"] = 24, ["durationType"] = 0, ["duration"] = 2 })
		end
	end
	if B24.HasTimed(paladin, "HOLY_NIMBUS") then
		local aux = B24.Aux(paladin)
		local now = B24.GameTick()
		if aux.B24_NimbusTick == nil or now - aux.B24_NimbusTick >= 90 then
			aux.B24_NimbusTick = now
			for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(paladin, "[ENEMY]", auraRange(level), true) or {}) do
				B24.ApplyEffect(enemy, { ["effectID"] = 12, ["effectAmount"] = cha(paladin) + B24.ProfOf(paladin),
					["dwFlags"] = 0x400000, ["sourceID"] = paladin.m_id })
			end
		end
	end
end)

-- Holy Nimbus: 10 minutes of radiant aura.
function B24NIMBS(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "HOLY_NIMBUS")
		B24.SetTimed(sprite, "HOLY_NIMBUS", 600)
		B24.Log(string.format("%s: Holy Nimbus", B24.Name(sprite)))
	end)
end

-- Portrait icons: Divine Smite switched on, Sacred Weapon active.
B24.AddIconListener(function(sprite, keys)
	if sprite:getLocalInt("B24SMTOG") == 1 then keys.SMIT = true end
	if B24.HasEffectSource(sprite, 54, "B24SACWP") then keys.SACW = true end
end)
