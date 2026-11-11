-- BG 2024 Rules Mod: concentration and casting disruption.
--
-- A caster concentrates on one spell from B24CONC.2DA at a time. Starting another
-- concentration spell ends the first; damage forces a Constitution save (DC 10 or half the
-- damage, max 30); incapacitation ends it. Ending removes the spell's effects from every
-- creature it reached (op321).
--
-- Casting disruption (CONCENTR.2DA points the engine at B24_CASTDISRUPT) uses the same
-- Constitution save instead of the engine's automatic interruption.

B24.ConcSpells = B24.LoadTable("B24CONC")

-- [casterID] = { res = "SPWI305", targets = { [spriteID] = true } }
B24.Concentration = {}
-- [casterID] = resref of the concentration spell being cast right now
B24.ConcPending = {}

B24.SpellActions = {
	[31] = true, [95] = true, [113] = true, [114] = true, [181] = true, [191] = true,
	[192] = true, [240] = true, [476] = true, [477] = true, [478] = true, [479] = true,
}

local SPELL_ID_PREFIX = { [1] = "SPPR", [2] = "SPWI", [3] = "SPIN", [4] = "SPCL" }

local function actionSpellRes(action)
	local res = action.m_string1.m_pchData:get()
	if res ~= nil and res ~= "" then return res:upper() end
	local id = action.m_specificID
	local prefix = SPELL_ID_PREFIX[math.floor(id / 1000)]
	if prefix == nil then return nil end
	return string.format("%s%03d", prefix, id % 1000)
end
-- The spell (or innate) a spell action casts; nil for other actions (B24TURN.lua uses it too).
function B24.ActionSpellRes(action)
	if not B24.SpellActions[action.m_actionID] then return nil end
	return actionSpellRes(action)
end

function B24.IsConcentrationSpell(res)
	return res ~= nil and B24.ConcSpells[B24.OriginalSpellRes(res):upper()] ~= nil
end

function B24.Conc_Get(sprite)
	return B24.Concentration[sprite.m_id]
end

-- listener(casterID, res, targets, affected) runs when a concentration ends, after the spell's
-- effects are gone; affected: the targets that still had some of them (Flesh to Stone in
-- B24COND.lua: its restraint and petrification are no effects of the spell; Haste's lethargy).
B24.ConcEndListeners = {}

local function hasEffectsFrom(sprite, res)
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_sourceRes:get():upper() == res then found = true return true end
	end)
	return found
end

-- The spell a caster concentrates on, kept in two of its variables (4 letters each) so a saved
-- game keeps it: after loading, B24.Conc_Restore finds the creatures it still affects.
local function packLetters(text)
	local n = 0
	for i = 1, 4 do n = n * 256 + (text:byte(i) or 0) end
	return n
end
local function unpackLetters(n)
	local letters = {}
	for i = 4, 1, -1 do
		local byte = n % 256
		if byte > 0 then table.insert(letters, 1, string.char(byte)) end
		n = math.floor(n / 256)
	end
	return table.concat(letters)
end
local function storeConcentration(caster, res)
	caster:setLocalInt("B24CONC1", res and packLetters(res:sub(1, 4)) or 0)
	caster:setLocalInt("B24CONC2", res and packLetters(res:sub(5, 8)) or 0)
end

function B24.Conc_Restore(caster)
	if B24.Concentration[caster.m_id] or caster:getLocalInt("B24CONC1") == 0 then return end
	local res = unpackLetters(caster:getLocalInt("B24CONC1")) .. unpackLetters(caster:getLocalInt("B24CONC2"))
	local record = { res = res, targets = {} }
	for _, other in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(caster, "[ANYONE]", 30000, false) or {}) do
		EEex_Utility_IterateCPtrList(other.m_timedEffectList, function(effect)
			if effect.m_sourceRes:get():upper() == res and effect.m_sourceId == caster.m_id then
				record.targets[other.m_id] = true
				return true
			end
		end)
	end
	if hasEffectsFrom(caster, res) then record.targets[caster.m_id] = true end
	if next(record.targets) == nil then
		storeConcentration(caster, nil)
		return
	end
	B24.Concentration[caster.m_id] = record
	B24.Log(string.format("%s keeps concentrating on %s (loaded)", B24.Name(caster), res))
end

function B24.Conc_End(casterID, reason)
	local record = B24.Concentration[casterID]
	if record == nil then return end
	B24.Concentration[casterID] = nil
	local endedCaster = B24.GetSprite(casterID)
	if endedCaster then storeConcentration(endedCaster, nil) end
	local affected = {}
	for targetID in pairs(record.targets) do
		local target = B24.GetSprite(targetID)
		if target then
			if hasEffectsFrom(target, record.res) then affected[targetID] = true end
			B24.RemoveEffectsBySource(target, record.res)
		end
	end
	for _, listener in ipairs(B24.ConcEndListeners) do
		EEex_Utility_TryIgnore(listener, casterID, record.res, record.targets, affected)
	end
	local caster = B24.GetSprite(casterID)
	if caster then
		B24.Log(string.format("%s loses concentration on %s (%s)", B24.Name(caster), record.res, reason))
	end
end

-- listener(sprite, res) runs when a creature starts casting a spell (Arcane Ward, Portent's
-- Expert Divination, Wild Magic Surge, third-caster spell slots).
B24.SpellCastListeners = {}
-- [caster id] = id of the creature its last spell aimed at.
B24.LastSpellTarget = {}

function B24.OnSpriteStartedAction(sprite, action)
	if not B24.SpellActions[action.m_actionID] then return end
	local res = actionSpellRes(action)
	if res then
		-- The creature the spell aims at, while the action still holds it (gone by the time the
		-- spell's effects land; Dispel Magic reads it, B24SPELL.lua).
		local ok, id = pcall(function() return action.m_acteeID.m_Instance end)
		B24.LastSpellTarget[sprite.m_id] = (ok and id and id ~= -1) and id or nil
		for _, listener in ipairs(B24.SpellCastListeners) do EEex_Utility_TryIgnore(listener, sprite, res) end
	end
	if B24.IsConcentrationSpell(res) then
		B24.ConcPending[sprite.m_id] = res
	end
end

-- Called from B24SCRN for every effect added to any creature.
function B24.Conc_OnEffectAdded(effect, sprite)
	local res = effect.m_sourceRes:get():upper()
	if not B24.IsConcentrationSpell(res) then return end
	local casterID = effect.m_sourceId
	if B24.ConcPending[casterID] == res then
		-- First effect of a new casting: the previous concentration ends now.
		B24.ConcPending[casterID] = nil
		B24.Conc_End(casterID, "cast " .. res)
		B24.Concentration[casterID] = { res = res, targets = {} }
		local caster = B24.GetSprite(casterID)
		if caster then storeConcentration(caster, res) end
	end
	local record = B24.Concentration[casterID]
	if record and record.res == res then
		record.targets[sprite.m_id] = true
	end
end

function B24.ConcentrationSaveDC(damage)
	return math.min(30, math.max(10, math.floor(damage / 2)))
end

function B24.Conc_OnDamage(target, damage)
	if B24.Concentration[target.m_id] == nil or damage <= 0 then return end
	local success = B24.RollSave(target, "CON", B24.ConcentrationSaveDC(damage), nil, " (concentration)", { CONCENTRATION = true })
	if not success then
		B24.Conc_End(target.m_id, "damage")
	end
end

-- Incapacitated or dead casters stop concentrating.
-- Paralysed and held creatures (Hold Person, op175: the HELD stat) are incapacitated too.
function B24.Conc_OnListsResolved(sprite)
	if B24.Concentration[sprite.m_id] == nil then
		if sprite:getLocalInt("B24CONC1") == 0 then return end
		B24.Conc_Restore(sprite)
		if B24.Concentration[sprite.m_id] == nil then return end
	end
	local g = B24.GState
	if B24.GState_Has(sprite, g.DEAD) or B24.GState_Has(sprite, g.SLEEPING) or B24.GState_Has(sprite, g.STUNNED)
		or B24.GState_Has(sprite, g.HELPLESS) or B24.GState_Has(sprite, g.STONE_DEATH) or sprite:getStat(B24.Stat.HELD) ~= 0 then
		B24.Conc_End(sprite.m_id, "incapacitated")
	end
end

-- Casting disruption: called by EEex once per damage instance taken while casting.
function B24_CASTDISRUPT(sprite, damageData)
	local dc = B24.ConcentrationSaveDC(damageData.damageTaken)
	return not B24.RollSave(sprite, "CON", dc, nil, " (casting)")
end

-- Track hit point loss from every damage effect. EEex only calls these hooks while CONCENTR.2DA
-- points at a Lua function, which this mod sets up.
local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
local originalDamageDone = EEex_Sprite_Hook_OnDamageEffectDone
local hitPointsBefore = {}

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	hitPointsBefore[targetSprite.m_id] = targetSprite.m_baseStats.m_hitPoints
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)
	originalDamageDone(effect, sourceSprite, targetSprite)
	local before = hitPointsBefore[targetSprite.m_id]
	hitPointsBefore[targetSprite.m_id] = nil
	if before then
		EEex_Utility_TryIgnore(B24.Conc_OnDamage, targetSprite, before - targetSprite.m_baseStats.m_hitPoints)
	end
end

EEex_Action_AddSpriteStartedActionListener(B24.OnSpriteStartedAction)
EEex_Opcode_AddListsResolvedListener(B24.Conc_OnListsResolved)
