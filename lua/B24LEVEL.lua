-- BG 2024 Rules Mod: class levels, class resources and level-up choices (Fighter component, used
-- by later class components too).
--
-- Class features are applied by Lua from the class level whenever it changes (party setup), so
-- created characters, companions and level-ups are handled the same way.
--
-- Resources: innate abilities with uses per rest. Uses are counted in creature locals; on a rest
-- the innate is removed and granted again once per remaining use.
--
-- Choices: subclass, Ability Score Improvement, Fighting Style and Weapon Mastery picks the
-- character has earned but not made. After a level-up the B24_LEVELUP popup opens by itself for
-- each pending kind; a cancelled choice stays available as an innate ability.
--   B24LVAPP  class levels the features were last applied for
--   B24LVASK  class levels the choice popups last opened for
--   B24SC*    chosen subclass per class (index into the class's subclass list, see SubclassLocal)
--   picks     B24LV.AddPick lists keep one local per pick (prefix + number = list index)
--   B24ASIDN  Ability Score Improvements taken
--   B24FSTY   Fighting Styles chosen (mask over B24LV.STYLES)
--   B24MSSET  1 once Weapon Masteries were chosen outside character creation

B24LV = {}

B24LV.LEVEL_STATS = { B24.Stat.LEVEL, B24.Stat.LEVEL2, B24.Stat.LEVEL3 }
B24LV.SOURCE_RES = "B24LEVEL"

-- Class index (1-3) of a 2024 class in the creature's BG class (multiclasses list their classes
-- in level order). The Barbarian kit stands for the Barbarian class, not the Fighter.
local function classIndex(sprite, classKey)
	-- Story creatures (Wilson) have no 2024 class levels: no features, subclass or choices.
	if B24.IsStoryCreature(sprite) then return nil end
	local map = B24.CLASS_MAP[B24.ClassID(sprite)]
	if map == nil then return nil end
	local barbarian = sprite:getStat(B24.Stat.KIT) == B24.KIT_BARBARIAN
	for i, class in ipairs(map.weapons) do
		if barbarian and class == "FIGHTER" then class = "BARBARIAN" end
		if class == classKey then return i end
	end
end

-- Creature flags (CRE 0x10, m_storeFlags): bit 9 fallen paladin, bit 10 fallen ranger. A fallen
-- paladin or ranger has no 2024 class features of that class until redeemed.
function B24LV.Fallen(sprite)
	local ok, flags = pcall(function() return sprite.m_baseStats.m_storeFlags end)
	if not ok or type(flags) ~= "number" then return false, false end
	return EEex_IsBitSet(flags, 9), EEex_IsBitSet(flags, 10)
end

function B24LV.ClassLevel(sprite, classKey)
	if classKey == "PALADIN" or classKey == "RANGER" then
		local paladin, ranger = B24LV.Fallen(sprite)
		if (classKey == "PALADIN" and paladin) or (classKey == "RANGER" and ranger) then return 0 end
	end
	local i = classIndex(sprite, classKey)
	return i and sprite:getStat(B24LV.LEVEL_STATS[i]) or 0
end

-- Class levels (two digits each), plus 1000000 for a fallen paladin and 2000000 for a fallen ranger.
local function levelSignature(sprite)
	local paladin, ranger = B24LV.Fallen(sprite)
	return sprite:getStat(B24.Stat.LEVEL) * 10000 + sprite:getStat(B24.Stat.LEVEL2) * 100 + sprite:getStat(B24.Stat.LEVEL3)
		+ (paladin and 1000000 or 0) + (ranger and 2000000 or 0)
end

-- Class level the features were last applied for (0 if never).
function B24LV.AppliedClassLevel(sprite, classKey)
	local i = classIndex(sprite, classKey)
	if i == nil then return 0 end
	local signature = sprite:getLocalInt("B24LVAPP")
	return math.floor(signature / ({ 10000, 100, 1 })[i]) % 100
end

---------------
-- Resources --
---------------

-- key -> { spell, localName, max = function(sprite), shortRest = "one" | "all" | nil }
B24LV.RESOURCES = {}

function B24LV.AddResource(key, resource)
	B24LV.RESOURCES[key] = resource
end

function B24LV.Remaining(sprite, key)
	local resource = B24LV.RESOURCES[key]
	return math.max(0, resource.max(sprite) - sprite:getLocalInt(resource.localName))
end

function B24LV.Rebuild(sprite, key)
	local resource = B24LV.RESOURCES[key]
	if resource.powers then
		B24LV.RefreshPowers(sprite, key)
		return
	end
	if resource.spell == nil then return end
	B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = resource.spell })
	for i = 1, B24LV.Remaining(sprite, key) do
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = resource.spell })
	end
end

-- Spends one use; returns false if none was left.
function B24LV.Use(sprite, key)
	local resource = B24LV.RESOURCES[key]
	if B24LV.Remaining(sprite, key) <= 0 then return false end
	sprite:setLocalInt(resource.localName, sprite:getLocalInt(resource.localName) + 1)
	if resource.powers then B24LV.RefreshPowers(sprite, key) end
	return true
end

-- Pools: a resource that several innates spend (Superiority Dice, Psionic Energy Dice, ...).
-- resource.powers = { { res, cost = 1 (default), when = function(sprite) (optional) } }: each
-- power is granted while the pool has its cost left and its condition holds.
function B24LV.RefreshPowers(sprite, key)
	local resource = B24LV.RESOURCES[key]
	local left = B24LV.Remaining(sprite, key)
	for _, power in ipairs(resource.powers or {}) do
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = power.res })
		local allowed = power.when == nil or power.when(sprite)
		if allowed and (left >= (power.cost or 1) or (power.free and power.free(sprite))) then
			B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = power.res })
		end
	end
end

-- Spends n uses of a pool; returns false (and spends nothing) if fewer are left.
function B24LV.Spend(sprite, key, n)
	local resource = B24LV.RESOURCES[key]
	n = n or 1
	if B24LV.Remaining(sprite, key) < n then return false end
	sprite:setLocalInt(resource.localName, sprite:getLocalInt(resource.localName) + n)
	if resource.powers then B24LV.RefreshPowers(sprite, key) end
	return true
end

-- Grants an innate once (again) if the condition holds, removes it otherwise.
function B24LV.Grant(sprite, res, condition)
	B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = res })
	if condition then B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = res }) end
end

-- Temporary hit points, in BG extra maximum and current hit points for a while (they don't
-- stack: new ones replace the old).
function B24LV.TempHP(sprite, amount, seconds)
	if amount <= 0 then return end
	B24.RemoveEffectsBySource(sprite, "B24TMPHP")
	B24.ApplyEffect(sprite, { ["effectID"] = 18, ["effectAmount"] = amount, ["dwFlags"] = 0,
		["durationType"] = 0, ["duration"] = seconds or 3600, ["m_sourceRes"] = "B24TMPHP" })
	B24.Log(string.format("%s gains %d temporary hit points", B24.Name(sprite), amount))
end

-- Dice rolled as a total, e.g. B24LV.Dice(3, 6).
function B24LV.Dice(n, size)
	local total = 0
	for i = 1, n do total = total + B24.Roll(size) end
	return total
end

-- True once per round (6 seconds) for each key and creature.
function B24LV.OncePerRound(sprite, key)
	local aux = B24.Aux(sprite)
	aux.B24_Once = aux.B24_Once or {}
	local now = B24.GameTick()
	local last = aux.B24_Once[key]
	if last and now - last < 90 and now >= last then return false end
	aux.B24_Once[key] = now
	return true
end

local function rebuildAll(sprite)
	for key in pairs(B24LV.RESOURCES) do B24LV.Rebuild(sprite, key) end
end

B24.AddLongRestListener(function(sprite)
	for key, resource in pairs(B24LV.RESOURCES) do
		sprite:setLocalInt(resource.localName, 0)
		B24LV.Rebuild(sprite, key)
	end
end)

B24.AddShortRestListener(function(sprite)
	for key, resource in pairs(B24LV.RESOURCES) do
		local used = sprite:getLocalInt(resource.localName)
		local mode = resource.shortRest
		if type(mode) == "function" then mode = mode(sprite) end
		if mode == "all" then used = 0
		elseif mode == "one" then used = math.max(0, used - 1) end
		if used ~= sprite:getLocalInt(resource.localName) then
			sprite:setLocalInt(resource.localName, used)
			B24LV.Rebuild(sprite, key)
		end
	end
end)

--------------------
-- Fighting Style --
--------------------

B24LV.STYLES = {
	{ key = "ARCHERY", name = "Archery",
	  desc = "+2 to attack rolls with ranged weapons." },
	{ key = "DEFENSE", name = "Defense",
	  desc = "+1 to Armor Class while you wear armor." },
	{ key = "GWF", name = "Great Weapon Fighting",
	  desc = "With a two-handed melee weapon, each damage die that rolls 1 or 2 counts as a 3." },
	{ key = "TWF", name = "Two-Weapon Fighting",
	  desc = "When you fight with two weapons, your off-hand attack adds your ability modifier to its damage." },
}

function B24LV.HasStyle(sprite, key)
	for i, style in ipairs(B24LV.STYLES) do
		if style.key == key then return EEex_IsBitSet(sprite:getLocalInt("B24FSTY"), i - 1) end
	end
	return false
end

local function styleCount(sprite)
	local n = 0
	for i = 1, #B24LV.STYLES do
		if EEex_IsBitSet(sprite:getLocalInt("B24FSTY"), i - 1) then n = n + 1 end
	end
	return n
end

local function selectedWeapon(sprite)
	local equipment = sprite.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	return item, item and item:getAbility(equipment.m_selectedWeaponAbility)
end

local function isRangedAbility(ability)
	-- Ability type 2 = ranged, 4 = launcher.
	return ability ~= nil and (ability.type == 2 or ability.type == 4)
end

local function wearsArmor(sprite)
	local armor = sprite.m_equipment.m_items:get(1)
	return armor ~= nil and armor.pRes.pHeader.itemType == 2
end

B24.AddStatListener(function(sprite)
	if sprite:getLocalInt("B24FSTY") == 0 then return end
	local stats = sprite:getActiveStats()
	if B24LV.HasStyle(sprite, "ARCHERY") then
		local _, ability = selectedWeapon(sprite)
		if isRangedAbility(ability) then stats.m_nTHAC0 = stats.m_nTHAC0 - 2 end
	end
	if B24LV.HasStyle(sprite, "DEFENSE") and wearsArmor(sprite) then
		stats.m_nArmorClass = stats.m_nArmorClass - 1
	end
end)

table.insert(B24WPN.OffhandModifierListeners, function(attacker)
	return B24LV.HasStyle(attacker, "TWF")
end)

-- Item header flag bit 1: two-handed.
table.insert(B24WPN.DamageListeners, function(context)
	if context.launcher or not B24LV.HasStyle(context.attacker, "GWF") then return end
	local weapon = context.weapon
	if weapon == nil or not EEex_IsBitSet(weapon.pRes.pHeader.itemFlags, 1) then return end
	if context.effect.m_numDice > 0 then B24WPN.RollDiceInto(context.effect, 3) end
end)

----------------
-- Subclasses --
----------------

-- classKey -> { level = n, list = { { key, name, desc } } }
B24LV.SUBCLASSES = {}

function B24LV.AddSubclasses(classKey, level, list)
	B24LV.SUBCLASSES[classKey] = { level = level, list = list }
end

-- Companions (no 2024 character creation) take the first subclass without asking.
local function playerCreated(sprite)
	return sprite:getLocalInt("B24SKSET") == 1
end

-- Each class keeps its subclass in its own local (B24SC + first three letters of the class), so
-- multiclass characters have one per class. B24SUBC is the older shared local: it only ever held
-- 1 (the SRD subclass, still first in every list).
function B24LV.SubclassLocal(classKey)
	return "B24SC" .. classKey:sub(1, 3)
end

----------
-- Kits --
----------

-- BG kits: their 2e abilities are removed (install time, B24KITAB.2DA lists them for characters
-- that already have them); kits with a PHB 2024 counterpart are that subclass (B24KITS.2DA).
local kitNames = nil

-- The creature's KITLIST row name (e.g. "STALKER"), nil without a kit.
function B24LV.KitName(sprite)
	if kitNames == nil then
		kitNames = {}
		local ok, kits = pcall(B24.LoadTable, "KITLIST")
		for _, row in pairs(ok and kits or {}) do
			local ids = tonumber(row.KITIDS or "")
			if ids and ids ~= 0 then kitNames[ids] = (row.ROWNAME or ""):upper() end
		end
	end
	local base = sprite.m_baseStats
	local ids = EEex_BOr(EEex_LShift(base.m_mageSpecUpperWord, 16), base.m_mageSpecialization)
	return kitNames[ids]
end

local kitSubclasses = nil
function B24LV.KitSubclass(sprite, classKey)
	if kitSubclasses == nil then
		local ok, rows = pcall(B24.LoadTable, "B24KITS")
		kitSubclasses = ok and rows or {}
	end
	local kit = B24LV.KitName(sprite)
	local row = kit and kitSubclasses[kit]
	if row and row.CLASS == classKey then return row.SUBCLASS end
end

local kitAbilities = nil
function B24LV.RemoveKitAbilities(sprite)
	if kitAbilities == nil then
		kitAbilities = {}
		local ok, rows = pcall(B24.LoadTable, "B24KITAB")
		for _, row in pairs(ok and rows or {}) do
			kitAbilities[row.KIT] = kitAbilities[row.KIT] or {}
			table.insert(kitAbilities[row.KIT], row.RES)
		end
	end
	local kit = B24LV.KitName(sprite)
	for _, res in ipairs(kit and kitAbilities[kit] or {}) do
		B24.RemoveEffectsBySource(sprite, res)
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = res })
	end
end

function B24LV.Subclass(sprite, classKey)
	local entry = B24LV.SUBCLASSES[classKey]
	if entry == nil or B24LV.ClassLevel(sprite, classKey) < entry.level then return nil end
	local kitSubclass = B24LV.KitSubclass(sprite, classKey)
	if kitSubclass then return kitSubclass end
	local index = sprite:getLocalInt(B24LV.SubclassLocal(classKey))
	if index == 0 and sprite:getLocalInt("B24SUBC") == 1 then index = 1 end
	local chosen = entry.list[index]
	if chosen then return chosen.key end
	if not playerCreated(sprite) then return entry.list[1].key end
	return nil
end

-- The subclass entry { key, name, desc, features } a class has chosen, or nil.
function B24LV.SubclassEntry(sprite, classKey)
	local key = B24LV.Subclass(sprite, classKey)
	for _, subclass in ipairs(key and B24LV.SUBCLASSES[classKey].list or {}) do
		if subclass.key == key then return subclass end
	end
end

-- Adds subclasses to a class's list (subclass components and files beyond the SRD one).
function B24LV.AddMoreSubclasses(classKey, list)
	local entry = B24LV.SUBCLASSES[classKey]
	for _, subclass in ipairs(list) do table.insert(entry.list, subclass) end
end

-- True if the creature has at least `level` levels in the class and chose this subclass.
function B24LV.Is(sprite, classKey, subclassKey, level)
	return B24LV.ClassLevel(sprite, classKey) >= (level or 0) and B24LV.Subclass(sprite, classKey) == subclassKey
end

-- Class options: one-time choices of a class feature (Divine Order, Primal Order, ...).
-- B24LV.OPTIONS[i] = { key, localName, class, level, title, list = { { key, name, desc } } }.
B24LV.OPTIONS = {}

function B24LV.AddOption(option)
	table.insert(B24LV.OPTIONS, option)
end

-- An option with a subclass field belongs to that subclass only.
local function optionApplies(sprite, option)
	if B24LV.ClassLevel(sprite, option.class) < option.level then return false end
	return option.subclass == nil or B24LV.Subclass(sprite, option.class) == option.subclass
end

-- The chosen option key, nil if not chosen (companions take the first option).
function B24LV.Option(sprite, key)
	for _, option in ipairs(B24LV.OPTIONS) do
		if option.key == key then
			if not optionApplies(sprite, option) then return nil end
			local chosen = option.list[sprite:getLocalInt(option.localName)]
			if chosen then return chosen.key end
			if not playerCreated(sprite) then return option.list[1].key end
			return nil
		end
	end
end

local function optionPending(sprite)
	for _, option in ipairs(B24LV.OPTIONS) do
		if optionApplies(sprite, option) and B24LV.Option(sprite, option.key) == nil then
			return option
		end
	end
end

-- Picks: several choices from one list (maneuvers, spells known of a third caster, ...).
-- B24LV.AddPick({ key, prefix, title, help, list = function() -> stable list of { key, name, desc },
--   count = function(sprite) -> picks earned, allowed = function(sprite, entry) (optional) }).
-- Pick n is kept in the local prefix .. n as the entry's index in the list.
B24LV.PICKS = {}

function B24LV.AddPick(pick)
	table.insert(B24LV.PICKS, pick)
end

local function pickByKey(key)
	for _, pick in ipairs(B24LV.PICKS) do
		if pick.key == key then return pick end
	end
end

local function pickCount(sprite, pick)
	local ok, n = pcall(pick.count, sprite)
	return ok and n or 0
end

-- Chosen entries of a pick, in the order they were chosen.
function B24LV.Picked(sprite, key)
	local pick = pickByKey(key)
	local picked = {}
	if pick == nil then return picked end
	local list = pick.list()
	for n = 1, pickCount(sprite, pick) do
		local entry = list[sprite:getLocalInt(pick.prefix .. n)]
		if entry then table.insert(picked, entry) end
	end
	return picked
end

function B24LV.HasPicked(sprite, key, entryKey)
	for _, entry in ipairs(B24LV.Picked(sprite, key)) do
		if entry.key == entryKey then return true end
	end
	return false
end

local function pickPending(sprite)
	for _, pick in ipairs(B24LV.PICKS) do
		local count = pickCount(sprite, pick)
		for n = 1, count do
			if sprite:getLocalInt(pick.prefix .. n) == 0 then return pick, n end
		end
	end
end

local function subclassPending(sprite)
	for classKey, entry in pairs(B24LV.SUBCLASSES) do
		if B24LV.ClassLevel(sprite, classKey) >= entry.level and B24LV.Subclass(sprite, classKey) == nil then
			return classKey
		end
	end
end

-------------
-- Choices --
-------------

-- listener(sprite) returns { ASI = earned, STYLE = earned, MASTERY = earned } for its class.
B24LV.ChoiceListeners = {}
function B24LV.AddChoiceListener(listener) table.insert(B24LV.ChoiceListeners, listener) end

B24LV.CHOICE_ORDER = { "SUBCLASS", "OPTION", "PICK", "CANTRIP", "SPELLBOOK", "ASI", "STYLE", "MASTERY", "EXPERTISE" }
B24LV.CHOICE_SPELLS = { SUBCLASS = "B24SUBC", OPTION = "B24OPTN", PICK = "B24PICK", ASI = "B24ASI", STYLE = "B24FSTY", MASTERY = "B24WMAS",
	EXPERTISE = "B24EXPRT", CANTRIP = "B24CANTP", SPELLBOOK = "B24SPBK" }
B24LV.CHOICE_TITLES = { SUBCLASS = "Subclass", OPTION = "Class Feature", PICK = "Class Feature", ASI = "Ability Score Improvement", STYLE = "Fighting Style",
	MASTERY = "Weapon Mastery", EXPERTISE = "Expertise", CANTRIP = "Cantrip", SPELLBOOK = "Spellbook", CLASS = "Level Up" }

-- Spells a class adds to its spellbook by choice (the Wizard, B24WIZ.lua): Pending(sprite) is the
-- number still to choose, Options(sprite) the spells offered ({ res, name, level }).
B24LV.Spellbook = nil

local function spellbookPending(sprite)
	if B24LV.Spellbook == nil then return 0 end
	local ok, n = pcall(B24LV.Spellbook.Pending, sprite)
	return ok and n or 0
end

local function maskCount(mask, size)
	local n = 0
	for i = 1, size do
		if EEex_IsBitSet(mask, i - 1) then n = n + 1 end
	end
	return n
end

local function masteryChosen(sprite)
	local n = 0
	for i = 1, #B24.MASTERY_WEAPONS do
		if EEex_IsBitSet(sprite:getLocalInt("B24MAST"), i - 1) then n = n + 1 end
	end
	return n
end

local function masteryExplicit(sprite)
	return sprite:getLocalInt("B24SKSET") == 1 or sprite:getLocalInt("B24MSSET") == 1
end

-- Cantrips of the caster's lists not known yet (the rows the Cantrip popup offers).
local function cantripsLeft(sprite)
	local letters, known, n = B24LV.CasterLetters(sprite), sprite:getLocalInt("B24CANT"), 0
	for i, cantrip in ipairs(B24SP.CANTRIPS) do
		local onList = false
		for letter in letters:gmatch(".") do onList = onList or cantrip.lists:find(letter, 1, true) ~= nil end
		if onList and not EEex_IsBitSet(known, i - 1) then n = n + 1 end
	end
	return n
end

function B24LV.Pending(sprite)
	local earned = { ASI = 0, STYLE = 0, MASTERY = 0, EXPERTISE = 0, CANTRIP = 0 }
	for _, listener in ipairs(B24LV.ChoiceListeners) do
		local ok, result = pcall(listener, sprite)
		if ok and result then
			for kind, n in pairs(result) do earned[kind] = (earned[kind] or 0) + n end
		end
	end
	return {
		SUBCLASS = subclassPending(sprite) and 1 or 0,
		OPTION = optionPending(sprite) and 1 or 0,
		PICK = pickPending(sprite) and 1 or 0,
		ASI = math.max(0, earned.ASI - sprite:getLocalInt("B24ASIDN")),
		STYLE = math.max(0, earned.STYLE - styleCount(sprite)),
		-- Companions keep their default masteries until they pick one themselves.
		MASTERY = masteryExplicit(sprite) and math.max(0, earned.MASTERY - masteryChosen(sprite)) or 0,
		-- Expertise after level 1 (level 1 Expertise is chosen in character creation).
		EXPERTISE = math.max(0, earned.EXPERTISE - maskCount(sprite:getLocalInt("B24SKEX2"), #B24.SKILLS)),
		-- Cantrips need the Spells component (B24SP).
		-- At most as many as the caster's lists still offer (the catalog is shorter than some class
		-- lists: a choice with nothing to choose would never close).
		CANTRIP = B24SP and math.min(cantripsLeft(sprite),
			math.max(0, earned.CANTRIP - maskCount(sprite:getLocalInt("B24CANT"), #B24SP.CANTRIPS))) or 0,
		SPELLBOOK = spellbookPending(sprite),
	}
end

local function rebuildChoices(sprite)
	local pending = B24LV.Pending(sprite)
	for kind, spell in pairs(B24LV.CHOICE_SPELLS) do
		B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = spell })
		if pending[kind] > 0 then
			B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = spell })
		end
	end
end

-----------------------------
-- Applying class features --
-----------------------------

-- listener(sprite) re-applies a class's passive features for its current level.
B24LV.ApplyListeners = {}
function B24LV.AddApplyListener(listener) table.insert(B24LV.ApplyListeners, listener) end
B24LV.AddApplyListener(B24LV.RemoveKitAbilities)

-- listener(sprite) returns lines describing what a class gains since its features were last
-- applied (shown on the level-up screen, before the new levels are applied).
B24LV.FeatureTextListeners = {}
function B24LV.AddFeatureTextListener(listener) table.insert(B24LV.FeatureTextListeners, listener) end

function B24LV.FeatureLines(sprite)
	local lines = {}
	for _, listener in ipairs(B24LV.FeatureTextListeners) do
		local ok, result = pcall(listener, sprite)
		if ok and result then
			for _, line in ipairs(result) do table.insert(lines, line) end
		end
	end
	-- Features of the chosen subclasses (subclass.features[level] = text).
	for classKey in pairs(B24LV.SUBCLASSES) do
		local subclass = B24LV.SubclassEntry(sprite, classKey)
		if subclass and subclass.features then
			local className = classKey:sub(1, 1) .. classKey:sub(2):lower()
			for l = B24LV.AppliedClassLevel(sprite, classKey) + 1, B24LV.ClassLevel(sprite, classKey) do
				if subclass.features[l] then
					table.insert(lines, string.format("%s %d: %s: %s", className, l, subclass.name, subclass.features[l]))
				end
			end
		end
	end
	return lines
end

function B24LV.Apply(sprite)
	sprite:setLocalInt("B24LVAPP", levelSignature(sprite))
	B24.RemoveEffectsBySource(sprite, B24LV.SOURCE_RES)
	for _, listener in ipairs(B24LV.ApplyListeners) do EEex_Utility_TryIgnore(listener, sprite) end
	rebuildAll(sprite)
	rebuildChoices(sprite)
end

-- Permanent effect owned by the class features (removed and re-added on every level change).
function B24LV.Permanent(sprite, args)
	args.durationType = 9
	args.m_sourceRes = B24LV.SOURCE_RES
	B24.ApplyEffect(sprite, args)
end

local function needsApply(sprite)
	return B24.SkillClass(sprite) ~= nil and sprite:getLocalInt("B24LVAPP") ~= levelSignature(sprite)
end

-- listener(sprite) runs about once per second for every party member (class features that act
-- over time).
B24LV.TickListeners = {}
function B24LV.AddTickListener(listener) table.insert(B24LV.TickListeners, listener) end
local lastTick = -1000

local originalNeedsSetup = B24_PartyNeedsSetup
local originalSetup = B24_SetupParty

function B24_PartyNeedsSetup()
	local now = B24.GameTick()
	if now - lastTick >= 15 or now < lastTick then
		lastTick = now
		for _, member in ipairs(B24.Party()) do
			for _, listener in ipairs(B24LV.TickListeners) do EEex_Utility_TryIgnore(listener, member) end
		end
	end
	if originalNeedsSetup() then return true end
	for _, member in ipairs(B24.Party()) do
		if needsApply(member) then return true end
	end
	return false
end

function B24_SetupParty()
	originalSetup()
	for _, member in ipairs(B24.Party()) do
		if needsApply(member) then EEex_Utility_TryIgnore(B24LV.Apply, member) end
	end
end

-------------------
-- Choice popup --
-------------------

-- The innate abilities B24SUBC, B24ASI, B24FSTY and B24WMAS call these (op402); the tick below
-- also opens the popup by itself after a level-up.
B24LV.ROWS = {}
local popup = nil

local ABILITY_ROWS = {
	{ key = "STR", name = "Strength", opcode = 44 }, { key = "DEX", name = "Dexterity", opcode = 15 },
	{ key = "CON", name = "Constitution", opcode = 10 }, { key = "INT", name = "Intelligence", opcode = 19 },
	{ key = "WIS", name = "Wisdom", opcode = 49 }, { key = "CHA", name = "Charisma", opcode = 6 },
}

-- The improvement raises the base score (permanent effects): the popup shows and caps that, not the
-- current score with temporary bonuses (potions, spells, the social skills of B24PROF.lua).
local BASE_FIELDS = { STR = "m_STRBase", DEX = "m_DEXBase", CON = "m_CONBase", INT = "m_INTBase", WIS = "m_WISBase", CHA = "m_CHRBase" }
local function baseScore(sprite, key)
	return sprite.m_baseStats[BASE_FIELDS[key]]
end

local function setRows(rows)
	for i = #B24LV.ROWS, 1, -1 do B24LV.ROWS[i] = nil end
	for i, row in ipairs(rows) do B24LV.ROWS[i] = row end
	B24LV.rowsHaveIcons = nil
end

-- The game pauses while a choice popup is open (and runs on afterwards if the popup paused it).
local function gamePaused()
	local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	return ok and (paused == true or paused == 1)
end

local function resumeIfPaused()
	if popup and popup.pausedHere and gamePaused() then EEex_GameState_TogglePause(false, false) end
end

local function open(kind, sprite)
	-- Companions that choose their first mastery start from the masteries they had by default.
	if kind == "MASTERY" and not masteryExplicit(sprite) then
		local mask = 0
		for i, weapon in ipairs(B24.MASTERY_WEAPONS) do
			if B24WPN.HasMastery(sprite, weapon.key) then mask = EEex_BOr(mask, EEex_LShift(1, i - 1)) end
		end
		sprite:setLocalInt("B24MAST", mask)
		sprite:setLocalInt("B24MSSET", 1)
	end
	popup = { kind = kind, spriteID = sprite.m_id, bonus = {}, pick = nil }
	if not gamePaused() then
		EEex_GameState_TogglePause(false, false)
		popup.pausedHere = true
	end
	local rows = {}
	if kind == "OPTION" then
		local option = optionPending(sprite)
		popup.option = option
		for i, choice in ipairs(option and option.list or {}) do
			table.insert(rows, { index = i, subclass = choice })
		end
	elseif kind == "PICK" then
		local pick, n = pickPending(sprite)
		popup.pick_ = pick
		popup.pickNumber = n
		if pick then
			local taken = {}
			for _, entry in ipairs(B24LV.Picked(sprite, pick.key)) do taken[entry.key] = true end
			for i, choice in ipairs(pick.list()) do
				if not taken[choice.key] and (pick.allowed == nil or pick.allowed(sprite, choice)) then
					table.insert(rows, { index = i, subclass = choice })
				end
			end
		end
	elseif kind == "SUBCLASS" then
		local classKey = subclassPending(sprite)
		popup.classKey = classKey
		for i, subclass in ipairs(classKey and B24LV.SUBCLASSES[classKey].list or {}) do
			table.insert(rows, { index = i, subclass = subclass })
		end
	elseif kind == "ASI" then
		-- The improvement or a feat (B24GFEAT.lua); without the feat list, the improvement directly.
		if B24GF then
			table.insert(rows, { asiChoice = true })
			for _, row in ipairs(B24GF.Rows(sprite)) do table.insert(rows, row) end
		else
			popup.asiMode = true
			for _, ability in ipairs(ABILITY_ROWS) do table.insert(rows, ability) end
		end
	elseif kind == "STYLE" then
		for i, style in ipairs(B24LV.STYLES) do
			if not EEex_IsBitSet(sprite:getLocalInt("B24FSTY"), i - 1) then table.insert(rows, { index = i, style = style }) end
		end
	elseif kind == "CANTRIP" then
		local letters = B24LV.CasterLetters(sprite)
		for i, cantrip in ipairs(B24SP.CANTRIPS) do
			local onList = false
			for letter in letters:gmatch(".") do onList = onList or cantrip.lists:find(letter, 1, true) ~= nil end
			if onList and not EEex_IsBitSet(sprite:getLocalInt("B24CANT"), i - 1) then
				table.insert(rows, { index = i, cantrip = cantrip })
			end
		end
	elseif kind == "SPELLBOOK" then
		for _, spell in ipairs(B24LV.Spellbook and B24LV.Spellbook.Options(sprite) or {}) do
			table.insert(rows, { spell = spell })
		end
	elseif kind == "EXPERTISE" then
		local proficient, expert = B24.Proficiencies(sprite)
		for i, skill in ipairs(B24.SKILLS) do
			if proficient[skill.key] and not expert[skill.key] then table.insert(rows, { index = i, skill = skill }) end
		end
	elseif kind == "CLASS" then
		-- Multiclass level-up (B24MULTI.lua): which class gains the level.
		for _, choice in ipairs(B24MC.LevelUpChoices(sprite)) do table.insert(rows, { classChoice = choice }) end
	elseif kind == "CHOICE" then
		-- A one-off choice of a class feature (B24LV.OpenChoice).
		popup.choiceSpec = B24LV.pendingChoice
		B24LV.pendingChoice = nil
		for _, choice in ipairs(popup.choiceSpec and popup.choiceSpec.list or {}) do table.insert(rows, { oneOff = choice }) end
	elseif kind == "MASTERY" then
		for i, weapon in ipairs(B24.MASTERY_WEAPONS) do
			local profType = B24.MasteryWeaponProfType(weapon.key)
			local proficient = profType == nil or B24.IsWeaponProficient(sprite, profType)
			if proficient and not EEex_IsBitSet(sprite:getLocalInt("B24MAST"), i - 1) then
				table.insert(rows, { index = i, weapon = weapon })
			end
		end
	end
	setRows(rows)
	b24lvRow = nil
	Infinity_PushMenu("B24_LEVELUP")
end

function B24OPTN(op402, sprite) EEex_Utility_TryIgnore(open, "OPTION", sprite) end
function B24PICK(op402, sprite) EEex_Utility_TryIgnore(open, "PICK", sprite) end
function B24SUBC(op402, sprite) EEex_Utility_TryIgnore(open, "SUBCLASS", sprite) end
function B24CANTP(op402, sprite) EEex_Utility_TryIgnore(open, "CANTRIP", sprite) end
function B24SPBK(op402, sprite) EEex_Utility_TryIgnore(open, "SPELLBOOK", sprite) end
function B24EXPRT(op402, sprite) EEex_Utility_TryIgnore(open, "EXPERTISE", sprite) end
function B24ASI(op402, sprite) EEex_Utility_TryIgnore(open, "ASI", sprite) end
function B24FSTY(op402, sprite) EEex_Utility_TryIgnore(open, "STYLE", sprite) end
function B24WMAS(op402, sprite) EEex_Utility_TryIgnore(open, "MASTERY", sprite) end

-- Multiclass level-up (B24MULTI.lua): the class choice popup.
function B24LV.OpenClassChoice(sprite) open("CLASS", sprite) end

-- A one-off choice of a class feature in the same popup: spec = { title, help, list = { { name, desc, ... } },
-- onChoose = function(sprite, choice) }. Cancel leaves it unchosen.
function B24LV.OpenChoice(sprite, spec)
	B24LV.pendingChoice = spec
	open("CHOICE", sprite)
end

-- After a level-up, the pending choices of one party member at a time open by themselves (on the
-- game screen, never on top of another menu).
B24LV.AddTickListener(function(sprite)
	if popup ~= nil or Infinity_IsMenuOnStack("B24_LEVELUP") then return end
	if worldScreen == nil or e:GetActiveEngine() ~= worldScreen then return end
	if B24.InNormalPlay and not B24.InNormalPlay() then return end
	if sprite:getLocalInt("B24LVASK") == levelSignature(sprite) or needsApply(sprite) then return end
	local pending = B24LV.Pending(sprite)
	for _, kind in ipairs(B24LV.CHOICE_ORDER) do
		if pending[kind] > 0 then
			open(kind, sprite)
			return
		end
	end
	sprite:setLocalInt("B24LVASK", levelSignature(sprite))
end)

local function popupSprite()
	return popup and B24.GetSprite(popup.spriteID)
end

-- Who chooses, and what (BG2's window shows them apart: name on top, choice in the list header).
function B24LV_Name()
	local sprite = popupSprite()
	return sprite and B24.Name(sprite) or ""
end

function B24LV_Choice()
	if popup == nil then return "" end
	return popup.option and popup.option.title or (popup.pick_ and popup.pick_.title) or (popup.choiceSpec and popup.choiceSpec.title) or B24LV.CHOICE_TITLES[popup.kind]
end

function B24LV_Title()
	if popup == nil then return "" end
	return string.format("%s: %s", B24LV_Name(), B24LV_Choice())
end

-- The icon of a spell or innate: its first ability's icon, as on the action bar.
local function spellIcon(res)
	if res == nil or res == "" then return nil end
	local ok, icon = pcall(function()
		local header = EEex_Resource_Demand(res, "SPL")
		return header and header:getAbility(0).quickSlotIcon:get()
	end)
	return ok and icon ~= "" and icon or nil
end

local function rowIcon(entry)
	if entry.weapon then return entry.weapon.icon end
	local thing = entry.cantrip or entry.spell or entry.subclass or entry.oneOff or entry.feat
	if thing == nil then return nil end
	return thing.icon or spellIcon(thing.res)
end

-- Row icons (BG's own choice lists show one): masteries a plain weapon of the type, spells,
-- cantrips and choices of innates their icon. Lists without any icon keep the full-width names.
function B24LV_RowIcon(row)
	local entry = B24LV.ROWS[row]
	if entry == nil then return "" end
	if entry.iconRes == nil then entry.iconRes = rowIcon(entry) or false end
	return entry.iconRes or ""
end

function B24LV_HasIcons()
	if B24LV.rowsHaveIcons == nil then
		B24LV.rowsHaveIcons = false
		for i = 1, #B24LV.ROWS do
			if B24LV_RowIcon(i) ~= "" then B24LV.rowsHaveIcons = true end
		end
	end
	return B24LV.rowsHaveIcons
end

function B24LV_RowName(row)
	local entry = B24LV.ROWS[row]
	if entry == nil or popup == nil then return "" end
	local chosen = ""
	if entry.feat then
		return entry.label
	elseif entry.asiChoice then
		return "Ability Score Improvement"
	elseif popup.kind == "ASI" then
		local sprite = popupSprite()
		local score = sprite and baseScore(sprite, entry.key) or 0
		local bonus = popup.bonus[entry.key] or 0
		return string.format("%s %d%s", entry.name, score + bonus, bonus > 0 and (" (+" .. bonus .. ")") or "")
	elseif entry.subclass then
		return entry.subclass.name .. chosen
	elseif entry.cantrip then
		return entry.cantrip.name .. chosen
	elseif entry.spell then
		return string.format("%s (level %d)", entry.spell.name, entry.spell.level)
	elseif entry.skill then
		return entry.skill.name .. chosen
	elseif entry.style then
		return entry.style.name .. chosen
	elseif entry.classChoice then
		return string.format("%s (level %d)", entry.classChoice.name, entry.classChoice.level + 1)
	elseif entry.oneOff then
		return entry.oneOff.name
	else
		return string.format("%s (%s)", entry.weapon.name, entry.weapon.mastery)
	end
end

local function asiTotal()
	local total = 0
	for _, n in pairs(popup.bonus) do total = total + n end
	return total
end

function B24LV_RowClick(row)
	local entry = B24LV.ROWS[row]
	if entry == nil or popup == nil then return end
	if entry.asiChoice then
		-- The improvement itself: the ability rows follow.
		popup.asiMode = true
		popup.pick = nil
		local rows = {}
		for _, ability in ipairs(ABILITY_ROWS) do table.insert(rows, ability) end
		setRows(rows)
		b24lvRow = nil
	elseif popup.kind == "ASI" and popup.asiMode then
		local sprite = popupSprite()
		local current = popup.bonus[entry.key] or 0
		local nextBonus = (current + 1) % 3
		if sprite and baseScore(sprite, entry.key) + nextBonus > 20 then nextBonus = 0 end
		if asiTotal() - current + nextBonus > 2 then nextBonus = 0 end
		popup.bonus[entry.key] = nextBonus
	else
		popup.pick = row
	end
end

function B24LV_Help()
	if popup == nil then return "" end
	local entry = B24LV.ROWS[b24lvRow or popup.pick or 0]
	if popup.kind == "OPTION" then
		if entry then return entry.subclass.name .. "\n\n" .. entry.subclass.desc end
		return "Choose one."
	elseif popup.kind == "PICK" then
		if entry then return entry.subclass.name .. "\n\n" .. (entry.subclass.desc or "") end
		return (popup.pick_ and popup.pick_.help) or "Choose one."
	elseif popup.kind == "SUBCLASS" then
		if entry then return entry.subclass.name .. "\n\n" .. entry.subclass.desc end
		return "Choose your subclass."
	elseif popup.kind == "ASI" then
		if entry and entry.feat then return entry.label .. "\n\n" .. entry.feat.desc end
		if popup.asiMode then
			return "Raise one ability score by 2, or two ability scores by 1 each (to at most 20). Click an ability to cycle +0, +1, +2."
		end
		return "Choose the Ability Score Improvement (+2 to one ability or +1 to two) or a feat you qualify for. Feats that raise an ability are listed once per ability they can raise."
	elseif popup.kind == "CANTRIP" then
		if entry then return entry.cantrip.name .. ": " .. Infinity_FetchString(B24LV.CantripDescription(entry.cantrip)) end
		return "Choose a cantrip. Cantrips are innate abilities you can use at will."
	elseif popup.kind == "SPELLBOOK" then
		if entry then
			local ok, desc = pcall(function()
				return Infinity_FetchString(EEex_Read32(EEex_UDToPtr(EEex_Resource_Demand(entry.spell.res, "SPL")) + 0x50))
			end)
			return entry.spell.name .. "\n\n" .. (ok and desc or "")
		end
		return "Add a spell of a level you can cast to your spellbook. A wizard's spellbook holds at least six spells at level 1 and two more for every level after that; scrolls you copy count toward it."
	elseif popup.kind == "EXPERTISE" then
		return "Choose a skill or tool you are proficient in; Expertise doubles your proficiency bonus for it."
	elseif popup.kind == "STYLE" then
		if entry then return entry.style.name .. ": " .. entry.style.desc end
		return "Choose a Fighting Style."
	elseif popup.kind == "CHOICE" then
		local spec = popup.choiceSpec or {}
		if entry then return entry.oneOff.name .. "\n\n" .. (entry.oneOff.desc or "") end
		return spec.help or "Choose one."
	elseif popup.kind == "CLASS" then
		if entry then
			return string.format("%s %d to %d. Your character level becomes %d.", entry.classChoice.name, entry.classChoice.level,
				entry.classChoice.level + 1, entry.classChoice.total + 1)
		end
		return "Choose the class that gains this level. As in 2024, your character level is the sum of your class levels, and each class gains its features at its own level."
	else
		if entry then
			return string.format("%s, mastery property %s. In BG: %s.", entry.weapon.name, entry.weapon.mastery, entry.weapon.bg)
		end
		return "Choose a weapon to master."
	end
end

function B24LV_Ready()
	if popup == nil then return false end
	if popup.kind == "ASI" and popup.asiMode then return asiTotal() == 2 end
	return popup.pick ~= nil
end

local function finish(sprite)
	local entry = B24LV.ROWS[popup.pick or 0]
	local what = B24LV.CHOICE_TITLES[popup.kind]
	if popup.kind == "OPTION" then
		sprite:setLocalInt(popup.option.localName, entry.index)
		what = popup.option.title .. ": " .. entry.subclass.name
	elseif popup.kind == "PICK" then
		sprite:setLocalInt(popup.pick_.prefix .. popup.pickNumber, entry.index)
		what = popup.pick_.title .. ": " .. entry.subclass.name
	elseif popup.kind == "SUBCLASS" then
		sprite:setLocalInt(B24LV.SubclassLocal(popup.classKey), entry.index)
		what = entry.subclass.name
	elseif popup.kind == "ASI" and not popup.asiMode then
		-- A feat instead of the improvement (B24GFEAT.lua).
		B24GF.Take(sprite, entry)
		sprite:setLocalInt("B24ASIDN", sprite:getLocalInt("B24ASIDN") + 1)
		what = "Feat " .. entry.label
	elseif popup.kind == "ASI" then
		for _, ability in ipairs(ABILITY_ROWS) do
			local bonus = popup.bonus[ability.key] or 0
			if bonus > 0 then
				B24.ApplyEffect(sprite, { ["effectID"] = ability.opcode, ["effectAmount"] = bonus, ["dwFlags"] = 0, ["durationType"] = 1 })
			end
		end
		sprite:setLocalInt("B24ASIDN", sprite:getLocalInt("B24ASIDN") + 1)
	elseif popup.kind == "CANTRIP" then
		sprite:setLocalInt("B24CANT", EEex_BOr(sprite:getLocalInt("B24CANT"), EEex_LShift(1, entry.index - 1)))
		what = "Cantrip " .. entry.cantrip.name
	elseif popup.kind == "SPELLBOOK" then
		B24.ApplyEffect(sprite, { ["effectID"] = 147, ["res"] = entry.spell.res })
		what = "Spellbook: " .. entry.spell.name
	elseif popup.kind == "EXPERTISE" then
		sprite:setLocalInt("B24SKEX2", EEex_BOr(sprite:getLocalInt("B24SKEX2"), EEex_LShift(1, entry.index - 1)))
		what = "Expertise in " .. entry.skill.name
	elseif popup.kind == "CHOICE" then
		local spec = popup.choiceSpec or {}
		if spec.onChoose then spec.onChoose(sprite, entry.oneOff) end
		what = (spec.title or "Choice") .. ": " .. entry.oneOff.name
	elseif popup.kind == "CLASS" then
		B24MC.LevelUp(sprite, entry.classChoice.index)
		what = string.format("level %d in %s", entry.classChoice.level + 1, entry.classChoice.name)
	elseif popup.kind == "STYLE" then
		sprite:setLocalInt("B24FSTY", EEex_BOr(sprite:getLocalInt("B24FSTY"), EEex_LShift(1, entry.index - 1)))
		what = "Fighting Style " .. entry.style.name
	else
		sprite:setLocalInt("B24MAST", EEex_BOr(sprite:getLocalInt("B24MAST"), EEex_LShift(1, entry.index - 1)))
		sprite:setLocalInt("B24MSSET", 1)
		what = "Weapon Mastery " .. entry.weapon.name
	end
	B24.Log(string.format("%s: %s", B24.Name(sprite), what))
	-- Features that depend on the choice (subclass features) are applied right away.
	B24LV.Apply(sprite)
end

function B24LV_Done()
	if not B24LV_Ready() then return end
	local sprite = popupSprite()
	if sprite then EEex_Utility_TryIgnore(finish, sprite) end
	resumeIfPaused()
	popup = nil
	Infinity_PopMenu("B24_LEVELUP")
end

-- Cancel keeps the choice pending as an innate ability; the popups don't open again by themselves
-- until the next level-up.
function B24LV_Cancel()
	local sprite = popupSprite()
	if sprite then
		sprite:setLocalInt("B24LVASK", levelSignature(sprite))
		EEex_Utility_TryIgnore(rebuildChoices, sprite)
	end
	resumeIfPaused()
	popup = nil
	Infinity_PopMenu("B24_LEVELUP")
end

-- Spell list letters of the creature's caster classes (W, S, B, C, D), for cantrip choices.
B24LV.CASTER_LETTERS = { WIZARD = "W", SORCERER = "S", BARD = "B", CLERIC = "C", DRUID = "D" }

-- listener(sprite) returns extra list letters (the Eldritch Knight and Arcane Trickster: "W").
B24LV.CasterLetterListeners = {}

function B24LV.CasterLetters(sprite)
	local letters = ""
	for class, letter in pairs(B24LV.CASTER_LETTERS) do
		if B24LV.ClassLevel(sprite, class) > 0 then letters = letters .. letter end
	end
	for _, listener in ipairs(B24LV.CasterLetterListeners) do
		local ok, extra = pcall(listener, sprite)
		if ok and extra then letters = letters .. extra end
	end
	return letters
end

-- Description strref of a cantrip, read from its SPL (offset 0x50).
function B24LV.CantripDescription(cantrip)
	local header = EEex_Resource_Demand(cantrip.res, "SPL")
	return header and EEex_Read32(EEex_UDToPtr(header) + 0x50) or -1
end

-- Runs fn once the Spells component's runtime (B24SP) is loaded: now, or when B24SPELL.lua runs
-- the queued functions. Class features that depend on spells register through this.
B24_SpellHooks = B24_SpellHooks or {}
function B24LV.WhenSpells(fn)
	if B24SP and B24SP.Loaded then
		EEex_Utility_TryIgnore(fn)
	else
		table.insert(B24_SpellHooks, fn)
	end
end
