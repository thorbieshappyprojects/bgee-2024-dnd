-- BG 2024 Rules Mod: six ability saving throws.
--
-- Every creature carries an op403 (EEex ScreenEffects) effect that calls B24SCRN for each
-- effect added to it. Effects with an engine saving throw are resolved here instead:
-- d20 + ability modifier + proficiency (if proficient) + save bonuses vs the caster's DC.
-- A failed save strips the engine save so the effect lands; a successful save blocks it,
-- or halves the damage of "save for half" damage effects.

B24.SaveOverrides = B24.LoadTable("B24SAVES")

-- Engine save category bit -> default 2024 ability, bonus opcode for that category.
B24.SaveCategories = {
	{ bit = 0x01, ability = "WIS", opcode = 37 }, -- spells
	{ bit = 0x02, ability = "DEX", opcode = 36 }, -- breath
	{ bit = 0x04, ability = "CON", opcode = 33 }, -- paralyze / poison / death
	{ bit = 0x08, ability = "DEX", opcode = 34 }, -- wands
	{ bit = 0x10, ability = "CON", opcode = 35 }, -- petrify / polymorph
}

B24.OP_DAMAGE = 12
B24.OP_ALL_SAVES = 325
B24.SAVE_FOR_HALF = 0x100

-- One roll per target, source, spell and ability per game tick, so all effects of one
-- spell share the same result.
B24.SaveCache = { tick = -1, results = {} }

local function saveCategory(savingThrow)
	for _, category in ipairs(B24.SaveCategories) do
		if B24.HasBit(savingThrow, category.bit) then return category end
	end
end

-- Sum of increment-mode save bonuses (op33-37 for the category, op325 for all saves) from
-- items and spells. Racial and class save tables are deliberately ignored.
function B24.SaveEffectBonus(sprite, category)
	local bonus = 0
	local add = function(effect)
		local opcode = effect.m_effectId
		if (opcode == category.opcode or opcode == B24.OP_ALL_SAVES) and effect.m_dWFlags == 0 then
			bonus = bonus + effect.m_effectAmount
		end
	end
	EEex_Utility_IterateCPtrList(sprite.m_equipedEffectList, add)
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, add)
	return bonus
end

function B24.AutoFailsSave(sprite, ability)
	if ability ~= "STR" and ability ~= "DEX" then return false end
	local g = B24.GState
	return B24.GState_Has(sprite, g.HELPLESS) or B24.GState_Has(sprite, g.STUNNED)
		or B24.GState_Has(sprite, g.SLEEPING)
		or (B24.IsParalyzed ~= nil and B24.IsParalyzed(sprite)) -- held, but not webbed (B24COND.lua)
end

-- Conditions a save protects against, derived from the opcodes of the effect and of its spell.
-- Species traits and other features give advantage against some of them.
B24.SaveConditionOpcodes = {
	[5] = "CHARM", [241] = "CHARM", [24] = "FEAR", [25] = "POISON", [39] = "SLEEP",
}
local spellConditionCache = {}

local function spellConditions(res)
	local cached = spellConditionCache[res]
	if cached then return cached end
	local conditions = {}
	local header = res ~= "" and EEex_Resource_Demand(res, "SPL")
	if header then
		local base = EEex_UDToPtr(header)
		for a = 0, header.abilityCount - 1 do
			local ability = header:getAbility(a)
			for e = 0, ability.effectCount - 1 do
				local opcode = EEex_ReadU16(base + header.effectsOffset + 0x30 * (ability.startingEffect + e))
				local condition = B24.SaveConditionOpcodes[opcode]
				if condition then conditions[condition] = true end
			end
		end
	end
	spellConditionCache[res] = conditions
	return conditions
end

function B24.EffectSaveConditions(effect)
	local conditions = {}
	for condition in pairs(spellConditions(effect.m_sourceRes:get():upper())) do conditions[condition] = true end
	local own = B24.SaveConditionOpcodes[effect.m_effectId]
	if own then conditions[own] = true end
	-- Who is behind the save (for features against "your spells").
	conditions.SOURCE = effect.m_sourceId
	conditions.RES = effect.m_sourceRes:get():upper()
	return conditions
end

-- listener(sprite, ability, conditions) returns advantage, disadvantage.
B24.SaveAdvantageListeners = {}
function B24.AddSaveAdvantageListener(listener) table.insert(B24.SaveAdvantageListeners, listener) end

-- listener(sprite) returns true if the creature rerolls a natural 1 on a save (halfling Luck).
B24.SaveRerollOnOneListeners = {}
function B24.AddSaveRerollOnOneListener(listener) table.insert(B24.SaveRerollOnOneListeners, listener) end

-- listener(effect, sprite) returns true if the creature succeeds on the effect's save and is
-- not affected at all (e.g. Sculpt Spells).
B24.SaveAutoSuccessListeners = {}
function B24.AddSaveAutoSuccessListener(listener) table.insert(B24.SaveAutoSuccessListeners, listener) end

-- listener(sprite) returns true if the creature has Evasion (Rogue, Monk).
B24.EvasionListeners = {}
function B24.AddEvasionListener(listener) table.insert(B24.EvasionListeners, listener) end

function B24.HasEvasion(sprite)
	for _, listener in ipairs(B24.EvasionListeners) do
		local ok, result = pcall(listener, sprite)
		if ok and result then return true end
	end
	return false
end

-- listener(sprite, ability, dc, total, mod) returns a new total for a failed save, or nil
-- (class features such as the Fighter's Indomitable). Runs before Heroic Inspiration.
B24.SaveFailedListeners = {}
function B24.AddSaveFailedListener(listener) table.insert(B24.SaveFailedListeners, listener) end

function B24.SaveAdvantage(sprite, ability, conditions)
	local advantage, disadvantage = false, false
	if ability == "DEX" and B24.IsRestrained ~= nil and B24.IsRestrained(sprite) then
		disadvantage = true -- restrained (B24COND.lua)
	end
	for _, listener in ipairs(B24.SaveAdvantageListeners) do
		local ok, adv, dis = pcall(listener, sprite, ability, conditions or {})
		if ok then
			advantage = advantage or adv == true
			disadvantage = disadvantage or dis == true
		end
	end
	return advantage, disadvantage
end

local function rerollsOnOne(sprite)
	for _, listener in ipairs(B24.SaveRerollOnOneListeners) do
		local ok, result = pcall(listener, sprite)
		if ok and result then return true end
	end
	return false
end

-- listener(sprite, ability) returns a bonus to the creature's saves from others (e.g. a Paladin's
-- Aura of Protection).
B24.SaveBonusListeners = {}
function B24.AddSaveBonusListener(listener) table.insert(B24.SaveBonusListeners, listener) end

-- Saving throw modifier of a creature for one ability (without the d20).
function B24.SaveModifier(sprite, ability, category)
	local mod = B24.AbilityModOf(sprite, ability)
	for _, listener in ipairs(B24.SaveBonusListeners) do
		local ok, bonus = pcall(listener, sprite, ability)
		if ok and bonus then mod = mod + bonus end
	end
	if B24.IsSaveProficient(sprite, ability) then
		mod = mod + B24.ProfOf(sprite)
	end
	if category then
		mod = mod + B24.SaveEffectBonus(sprite, category)
	end
	return mod - 2 * B24.Exhaustion_Get(sprite)
end

-- Rolls a save; returns success, total, roll. Used by effects and by concentration checks.
function B24.RollSave(sprite, ability, dc, category, label, conditions)
	if B24.AutoFailsSave(sprite, ability) then
		B24.Log(string.format("%s automatically fails the %s save%s", B24.Name(sprite), ability, label or ""))
		return false, 0, 0
	end
	local advantage, disadvantage = B24.SaveAdvantage(sprite, ability, conditions)
	local mod = B24.SaveModifier(sprite, ability, category)
	local roll = B24.RollD20(advantage, disadvantage)
	-- A roll fixed in advance (the Diviner's Portent) replaces the d20.
	local aux = B24.Aux(sprite)
	if aux.B24_ForcedSave then
		roll = aux.B24_ForcedSave
		aux.B24_ForcedSave = nil
		label = (label or "") .. " (Portent)"
	end
	if roll == 1 and rerollsOnOne(sprite) then
		roll = B24.Roll(20)
		B24.Log(string.format("%s rolls a 1 and rerolls (Luck): %d", B24.Name(sprite), roll))
	end
	if advantage ~= disadvantage then
		label = (label or "") .. (advantage and " (advantage)" or " (disadvantage)")
	end
	local total = roll + mod
	local success = total >= dc
	for _, listener in ipairs(B24.SaveFailedListeners) do
		if success then break end
		local ok, newTotal = pcall(listener, sprite, ability, dc, total, mod)
		if ok and newTotal then
			total = newTotal
			success = total >= dc
		end
	end
	if not success and B24.InParty(sprite) and B24.Inspiration_Use(sprite) then
		local reroll = B24.Roll(20)
		B24.Log(string.format("%s uses Heroic Inspiration: rerolls %d", B24.Name(sprite), reroll))
		roll, total = reroll, reroll + mod
		success = total >= dc
	end
	B24.Log(string.format("%s: %s save %d (%d%+d) vs DC %d%s - %s", B24.Name(sprite), ability, total, roll,
		mod, dc, label or "", success and "success" or "failure"))
	return success, total, roll
end

-- Wands (item type 35): the save DC is the better of 15 and the user's spell save DC (a wand's
-- spell may come from a cast-spell effect, so the user counts as using a wand for 6 seconds after
-- starting the action: UseItem 34, UseItemPoint 97; the item by name or by quick slot).
B24.WAND_DC = 15
B24.WandUse = {}
local ITEM_ACTIONS = { [34] = true, [97] = true }
EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	if not ITEM_ACTIONS[action.m_actionID] then return end
	EEex_Utility_TryIgnore(function()
		local item
		local res = action.m_string1.m_pchData:get()
		if res ~= nil and res ~= "" then
			local header = EEex_Resource_Demand(res, "ITM")
			item = header and { type = header.itemType }
		else
			local slotItem = sprite.m_equipment.m_items:get(action.m_specificID)
			item = slotItem and { type = slotItem.pRes.pHeader.itemType }
		end
		if item and item.type == 35 then B24.WandUse[sprite.m_id] = B24.GameTick() end
	end)
end)

function B24.EffectSaveDC(effect, ability, category)
	local source = B24.GetSprite(effect.m_sourceId)
	local spellRes = effect.m_sourceRes:get()
	local dc
	if source then
		-- Breath weapons and other innate monster attacks use Constitution.
		local castAbility = nil
		if category.bit == 0x02 and B24.IsMonster(source) then castAbility = "CON" end
		dc = B24.SpellSaveDC(source, spellRes, castAbility)
		local wand = B24.WandUse[source.m_id]
		if wand and B24.GameTick() >= wand and B24.GameTick() - wand <= 90 then dc = math.max(B24.WAND_DC, dc) end
	else
		-- Traps and other sourceless effects: assume a +2 casting modifier.
		dc = 8 + B24.ProfBonus(math.max(1, effect.m_casterLevel), true) + 2
	end
	-- The 2e save bonus/penalty of the effect shifts the DC (a -2 penalty means DC +2).
	dc = dc - effect.m_saveMod
	return math.max(5, math.min(30, dc))
end

function B24.EffectSaveAbility(effect, category)
	local override = B24.SaveOverrides[effect.m_sourceRes:get():upper()]
	if override and B24.AbilityStat[override.ABILITY] then
		return override.ABILITY
	end
	return category.ability
end

function B24.ResolveEffectSave(effect, sprite, category)
	local tick = B24.GameTick()
	local cache = B24.SaveCache
	if cache.tick ~= tick then
		cache.tick = tick
		cache.results = {}
	end
	local ability = B24.EffectSaveAbility(effect, category)
	local key = string.format("%d|%d|%s|%s", sprite.m_id, effect.m_sourceId, effect.m_sourceRes:get(), ability)
	local result = cache.results[key]
	if result == nil then
		local dc = B24.EffectSaveDC(effect, ability, category)
		result = B24.RollSave(sprite, ability, dc, category, nil, B24.EffectSaveConditions(effect))
		cache.results[key] = result
	end
	return result
end

local function clearEngineSave(effect)
	local savingThrow = effect.m_savingThrow
	effect.m_savingThrow = savingThrow - (savingThrow % 32)
end

-- Returns true if the effect is blocked.
function B24.ScreenSave(effect, sprite)
	local category = saveCategory(effect.m_savingThrow)
	if category == nil then return false end

	-- Some features let creatures succeed automatically and take no damage (the Evoker's Sculpt
	-- Spells for allies).
	for _, listener in ipairs(B24.SaveAutoSuccessListeners) do
		local ok, result = pcall(listener, effect, sprite)
		if ok and result then
			clearEngineSave(effect)
			return true
		end
	end
	local saved = B24.ResolveEffectSave(effect, sprite, category)
	clearEngineSave(effect)
	-- Spells the target may shake off later with repeat saves; petrification restrains first and
	-- petrifies only after more failed saves (B24COND.lua).
	if not saved and B24CD and B24CD.OnFailedSave then
		local ability = B24.EffectSaveAbility(effect, category)
		local dc = B24.EffectSaveDC(effect, ability, category)
		if effect.m_effectId == 134 then
			local ok, blocked = pcall(B24CD.StartPetrify, effect, sprite, ability, dc)
			if ok and blocked then return true end
		end
		local ok, blocked = pcall(B24CD.BlockedWithPetrify, effect, sprite)
		if ok and blocked then return true end
		EEex_Utility_TryIgnore(B24CD.OnFailedSave, effect, sprite, ability, dc)
	end
	local halfDamage = effect.m_effectId == B24.OP_DAMAGE and B24.HasBit(effect.m_special, B24.SAVE_FOR_HALF)

	-- Evasion: Dexterity saves for half damage take none on a success and half on a failure.
	if halfDamage and B24.EffectSaveAbility(effect, category) == "DEX" and B24.HasEvasion(sprite) then
		if saved then return true end
		if effect.m_numDice > 0 then effect.m_numDice = math.floor(effect.m_numDice / 2) end
		effect.m_effectAmount = math.floor(effect.m_effectAmount / 2)
		return false
	end
	if not saved then return false end

	if halfDamage then
		if effect.m_numDice > 0 then
			effect.m_numDice = math.floor(effect.m_numDice / 2)
		end
		effect.m_effectAmount = math.floor(effect.m_effectAmount / 2)
		return false
	end
	return true
end

-- listener(effect, sprite) runs for every effect added to a creature, before it is applied (e.g.
-- the Sorcerer's Extended Spell doubles durations).
B24.EffectAddedListeners = {}

-- op403 entry point for every creature (see B24.EnsureScreen).
function B24SCRN(op403, effect, sprite)
	local ok, blocked = pcall(function()
		B24.Conc_OnEffectAdded(effect, sprite)
		for _, listener in ipairs(B24.EffectAddedListeners) do EEex_Utility_TryIgnore(listener, effect, sprite) end
		return B24.ScreenSave(effect, sprite)
	end)
	if not ok then
		print("[BG2024] B24SCRN error: " .. tostring(blocked))
		return false
	end
	return blocked
end

B24.SCREEN_RES = "B24SCRN"

-- Creatures seen by the stats listener that may still lack the screen effect. Effects are not
-- applied from inside the listener: creatures in character generation have no area yet, and
-- adding effects mid-resolution is unsafe. The global script drains the queue instead.
B24.PendingScreens = {}

function B24.QueueScreen(sprite)
	if not B24.Aux(sprite).B24_screened then
		B24.PendingScreens[sprite.m_id] = true
	end
end

function B24_HasPendingScreens()
	return next(B24.PendingScreens) ~= nil
end

function B24_ProcessPendingScreens()
	for id in pairs(B24.PendingScreens) do
		local sprite = B24.GetSprite(id)
		if sprite == nil then
			B24.PendingScreens[id] = nil
		elseif sprite.m_pArea ~= nil then
			B24.PendingScreens[id] = nil
			EEex_Utility_TryIgnore(B24.EnsureScreen, sprite)
		end
	end
end

-- Gives a creature the op403 screen effect once. Timing 9 keeps it through death and
-- resurrection, and it cannot be dispelled.
function B24.EnsureScreen(sprite)
	local aux = B24.Aux(sprite)
	if aux.B24_screened then return end
	aux.B24_screened = true
	if not B24.HasEffect(sprite, 403, B24.SCREEN_RES) then
		sprite:applyEffect({
			["effectID"] = 403,
			["durationType"] = 9,
			["res"] = B24.SCREEN_RES,
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
			["m_sourceRes"] = B24.SCREEN_RES,
			["immediateResolve"] = 0,
		})
	end
end
