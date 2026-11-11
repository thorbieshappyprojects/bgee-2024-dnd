-- BG 2024 Rules Mod: helpers shared by the subclass files (B24X*.lua) beyond the SRD subclasses.
--
-- Third casters (Eldritch Knight, Arcane Trickster): Intelligence casters with the 2024 third-caster
-- slots. Their spells are picked from the wizard list of the spell catalog (B24SPELL.2DA, levels
-- as the Spells component sets them) and granted as innate abilities while a slot of the spell's
-- level or higher is left; casting one spends the lowest such slot. Slots return on a long rest.
-- BG has no upcasting for them. Locals: <prefix>1.. (spells picked), <prefix>S1..S4 (slots spent).
--
-- Psionic Energy Dice (Psi Warrior, Soulknife): 4d6 at 3, 6d8 at 5, 8d8 at 9, 8d10 at 11,
-- 10d10 at 13, 12d12 at 17.

B24X = {}

function B24X.DC(sprite, ability)
	return 8 + B24.ProfOf(sprite) + B24.AbilityModOf(sprite, ability)
end

-- The better of Strength and Dexterity (maneuvers, martial features).
function B24X.MartialAbility(sprite)
	return B24.AbilityModOf(sprite, "DEX") > B24.AbilityModOf(sprite, "STR") and "DEX" or "STR"
end

function B24X.Enemies(sprite, range)
	return EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[ENEMY]", range, true) or {}
end

-- Party members within range, the creature itself included.
function B24X.Allies(sprite, range)
	local allies = EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[PC]", range, true) or {}
	local found = false
	for _, ally in ipairs(allies) do found = found or ally.m_id == sprite.m_id end
	if not found then table.insert(allies, sprite) end
	return allies
end

function B24X.Damage(target, source, amount, damageType)
	if amount <= 0 then return end
	B24.ApplyEffect(target, { ["effectID"] = 12, ["effectAmount"] = amount, ["dwFlags"] = damageType or 0x400000,
		["sourceID"] = source.m_id })
end

B24X.FIRE, B24X.COLD, B24X.LIGHTNING, B24X.ACID, B24X.POISON, B24X.MAGIC = 0x80000, 0x20000, 0x40000, 0x10000, 0x200000, 0x400000

-- Readied effects for the creature's next weapon hit within a round: B24X.Ready(sprite, key, data)
-- and B24X.TakeReady(sprite) -> key, data (or nil once used or expired).
function B24X.Ready(sprite, key, data)
	B24.Aux(sprite).B24_Ready = { key = key, data = data or {}, untilTick = B24.GameTick() + 90 }
end

function B24X.TakeReady(sprite)
	local aux = B24.Aux(sprite)
	local ready = aux.B24_Ready
	aux.B24_Ready = nil
	if ready and B24.GameTick() <= ready.untilTick then return ready.key, ready.data end
end

function B24X.PeekReady(sprite)
	local ready = B24.Aux(sprite).B24_Ready
	if ready and B24.GameTick() <= ready.untilTick then return ready.key end
end

---------------------------
-- Psionic Energy Dice --
---------------------------

function B24X.PsionicDice(level)
	if level >= 17 then return 12, 12 elseif level >= 13 then return 10, 10 elseif level >= 11 then return 8, 10
	elseif level >= 9 then return 8, 8 elseif level >= 5 then return 6, 8 elseif level >= 3 then return 4, 6 end
	return 0, 6
end

------------------
-- Third casters --
------------------

B24X.THIRD_SLOTS = {
	[3] = { 2 }, [4] = { 3 }, [5] = { 3 }, [6] = { 3 }, [7] = { 4, 2 }, [8] = { 4, 2 }, [9] = { 4, 2 },
	[10] = { 4, 3 }, [11] = { 4, 3 }, [12] = { 4, 3 }, [13] = { 4, 3, 2 }, [14] = { 4, 3, 2 }, [15] = { 4, 3, 2 },
	[16] = { 4, 3, 3 }, [17] = { 4, 3, 3 }, [18] = { 4, 3, 3 }, [19] = { 4, 3, 3, 1 }, [20] = { 4, 3, 3, 1 },
}
B24X.THIRD_KNOWN = { [3] = 3, [4] = 4, [5] = 4, [6] = 4, [7] = 5, [8] = 6, [9] = 6, [10] = 7, [11] = 8, [12] = 8,
	[13] = 9, [14] = 10, [15] = 10, [16] = 11, [17] = 11, [18] = 11, [19] = 12, [20] = 13 }

local wizardSpells = nil

local function spellLevel(res)
	local header = EEex_Resource_Demand(res, "SPL")
	return header and EEex_Read32(EEex_UDToPtr(header) + 0x34) or 0
end

local function spellDescription(res)
	local header = EEex_Resource_Demand(res, "SPL")
	local ref = header and EEex_Read32(EEex_UDToPtr(header) + 0x50) or -1
	return ref > 0 and Infinity_FetchString(ref) or ""
end

-- Wizard spells of the catalog, sorted by resref (the order picks are stored in).
function B24X.WizardSpells()
	if wizardSpells then return wizardSpells end
	wizardSpells = {}
	local ok, catalog = pcall(B24.LoadTable, "B24SPELL")
	if not ok or catalog == nil then return wizardSpells end
	local keys = {}
	for res, row in pairs(catalog) do
		if res:sub(1, 4) == "SPWI" and row.ACTION ~= "DROP" and (row.LISTS or ""):find("W", 1, true)
			and EEex_Resource_Demand(res, "SPL") then
			table.insert(keys, res)
		end
	end
	table.sort(keys)
	for _, res in ipairs(keys) do
		local level = spellLevel(res)
		local name = (catalog[res].NAME or res):gsub("_", " ")
		table.insert(wizardSpells, { key = res, res = res, level = level,
			name = string.format("%s (level %d)", name, level), desc = nil })
	end
	-- Descriptions are fetched when the list is first shown.
	for _, entry in ipairs(wizardSpells) do entry.desc = spellDescription(entry.res) end
	return wizardSpells
end

local function maxSpellLevel(level)
	local slots = B24X.THIRD_SLOTS[math.min(20, level)]
	return slots and #slots or 0
end

local function knownMageSpells(sprite)
	local known = {}
	for _, _, res in EEex_Sprite_GetKnownMageSpellsIterator(sprite, 1, 9) do known[res:upper()] = true end
	return known
end

B24X.THIRD_CASTERS = {}

-- caster = { class, subclass, prefix (≤ 6 letters), title, cantrips = function(level) }
function B24X.AddThirdCaster(caster)
	table.insert(B24X.THIRD_CASTERS, caster)
	local function level(sprite)
		return B24LV.Is(sprite, caster.class, caster.subclass, 3) and B24LV.ClassLevel(sprite, caster.class) or 0
	end
	caster.level = level

	B24LV.AddPick({ key = caster.prefix, prefix = caster.prefix, title = caster.title,
		help = "Choose a wizard spell. You cast it with your third-caster spell slots (Intelligence).",
		list = B24X.WizardSpells,
		count = function(sprite)
			local l = level(sprite)
			if l < 3 or #B24X.WizardSpells() == 0 then return 0 end
			return B24X.THIRD_KNOWN[math.min(20, l)]
		end,
		allowed = function(sprite, entry)
			return entry.level >= 1 and entry.level <= maxSpellLevel(level(sprite)) and not knownMageSpells(sprite)[entry.res]
		end })

	B24LV.AddChoiceListener(function(sprite)
		local l = level(sprite)
		if l < 3 then return nil end
		return { CANTRIP = caster.cantrips(l) }
	end)
	table.insert(B24LV.CasterLetterListeners, function(sprite)
		return level(sprite) >= 3 and "W" or nil
	end)
	B24LV.AddApplyListener(function(sprite) B24X.RefreshThirdCaster(sprite, caster) end)
	B24.AddLongRestListener(function(sprite)
		if level(sprite) < 3 then return end
		for l = 1, 4 do sprite:setLocalInt(caster.prefix .. "S" .. l, 0) end
		B24X.RefreshThirdCaster(sprite, caster)
	end)
end

local function slotsLeft(sprite, caster, spellLevel)
	local slots = B24X.THIRD_SLOTS[math.min(20, caster.level(sprite))] or {}
	return math.max(0, (slots[spellLevel] or 0) - sprite:getLocalInt(caster.prefix .. "S" .. spellLevel))
end

local function lowestSlot(sprite, caster, spellLevel)
	for l = math.max(1, spellLevel), 4 do
		if slotsLeft(sprite, caster, l) > 0 then return l end
	end
end

function B24X.RefreshThirdCaster(sprite, caster)
	if caster.level(sprite) < 3 then return end
	local known = knownMageSpells(sprite)
	for _, entry in ipairs(B24LV.Picked(sprite, caster.prefix)) do
		if not known[entry.res] then
			B24LV.Grant(sprite, entry.res, lowestSlot(sprite, caster, entry.level) ~= nil)
		end
	end
end

-- The caster's picked spells, by resref.
local function pickedSpell(sprite, caster, res)
	for _, entry in ipairs(B24LV.Picked(sprite, caster.prefix)) do
		if entry.res == res then return entry end
	end
end

table.insert(B24.SpellCastListeners, function(sprite, res)
	for _, caster in ipairs(B24X.THIRD_CASTERS) do
		local entry = caster.level(sprite) >= 3 and pickedSpell(sprite, caster, res)
		if entry and not knownMageSpells(sprite)[res] then
			local slot = lowestSlot(sprite, caster, entry.level)
			if slot then
				sprite:setLocalInt(caster.prefix .. "S" .. slot, sprite:getLocalInt(caster.prefix .. "S" .. slot) + 1)
				B24.Log(string.format("%s casts %s with a level %d slot", B24.Name(sprite), entry.name, slot))
			end
			-- Once the cast is over (the innate is used up), grant the spells that still have slots.
			B24.Aux(sprite).B24_ThirdRefresh = B24.GameTick() + 120
		end
	end
end)

B24LV.AddTickListener(function(sprite)
	local aux = B24.Aux(sprite)
	if aux.B24_ThirdRefresh and B24.GameTick() >= aux.B24_ThirdRefresh then
		aux.B24_ThirdRefresh = nil
		for _, caster in ipairs(B24X.THIRD_CASTERS) do B24X.RefreshThirdCaster(sprite, caster) end
	end
end)

-- Their spells use Intelligence.
table.insert(B24.CastingAbilityListeners, function(sprite, res)
	if res:upper():sub(1, 4) ~= "SPWI" then return nil end
	for _, caster in ipairs(B24X.THIRD_CASTERS) do
		if caster.level(sprite) >= 3 and pickedSpell(sprite, caster, res:upper()) then return "INT" end
	end
	return nil
end)

-- Timed SAVE_ADV: advantage on saves (e.g. the Zealot's Zealous Presence).
B24.AddSaveAdvantageListener(function(sprite)
	return B24.HasTimed(sprite, "SAVE_ADV"), false
end)

-- Wild Shape uses for the subclass features that spend them (Circle of the Sea and Stars): 2 at
-- Druid level 2, 3 at 6, 4 at 17; one returns on a short rest. BG's own shapeshifting is separate.
function B24X.WildShapeMax(sprite)
	local level = B24LV.ClassLevel(sprite, "DRUID")
	return level >= 17 and 4 or level >= 6 and 3 or level >= 2 and 2 or 0
end
