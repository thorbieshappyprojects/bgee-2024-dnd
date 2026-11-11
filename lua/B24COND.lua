-- BG 2024 Rules Mod: 2024 conditions.
--
-- BG states and how they count (attack and save effects in B24ADV.lua and B24SAVE.lua):
--   Blinded      STATE_BLIND. The engine's own -4 to attacks and AC per blindness effect is taken
--                back here; disadvantage and advantage replace it.
--   Paralyzed    held (stat HELD) without web or entangle: attacks against it have advantage,
--                STR/DEX saves fail, melee hits from within 5 ft are critical hits
--   Unconscious  sleeping or helpless: as paralyzed
--   Stunned      STATE_STUNNED: attacks against it have advantage, STR/DEX saves fail
--   Restrained   web (op157), entangle (op154) or this mod's RESTRAINED: its attacks have
--                disadvantage, attacks against it advantage, its DEX saves disadvantage; webs
--                hold through the engine, but no longer count as paralyzed
--   Prone        spell state PRONE (B24.KnockProne, a round): half speed (crawling or standing
--                up), its attacks have disadvantage; attacks against it have
--                advantage from within 5 ft and disadvantage from farther away
--   Grappled     this mod's GRAPPLED: speed 0, disadvantage on attacks against anyone but the
--                grappler; Escape Grapple (an action) or, for non-party creatures, a try each round
--   Frightened   BG panic (the creature flees) with disadvantage on its attacks; Charmed stays BG's
--                domination; Poisoned gives disadvantage on attacks; Invisible gives advantage and
--                makes attacks against it worse; Exhaustion is in B24REST.lua.
-- Install time (b24_core_conditions.tpa) removes the 2e attack and AC penalties spells and items
-- add on top of these states.
--
-- Conditions this mod applies (ApplyCondition) can allow a repeat save at the end of each round
-- (ability + DC) and end early on a success. Their effects carry the source resource in B24CD.RES.
-- Spells with a 2024 repeat save (B24CD.REPEAT_SAVE_SPELLS) work the same way. In turn-based
-- combat the repeat saves come at the end of the creature's turn instead (B24CD.TurnEnd).

B24CD = { active = {} }

B24CD.RES = { RESTRAINED = "B24RSTRN", GRAPPLED = "B24GRAPL" }

-- Within 5 ft (the mod's melee distance).
function B24.Adjacent(a, b)
	if a.m_id == b.m_id then return true end
	for _, other in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(a, "[ANYONE]", B24.ADJACENT, false) or {}) do
		if other.m_id == b.m_id then return true end
	end
	return false
end

local function hasTimedOpcode(sprite, opcode)
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == opcode then found = true return true end
	end)
	return found
end

local function countTimedOpcode(sprite, opcode)
	local n = 0
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_effectId == opcode then n = n + 1 end
	end)
	return n
end

function B24.IsWebbed(sprite)
	return hasTimedOpcode(sprite, 157) or hasTimedOpcode(sprite, 154)
end

function B24.IsRestrained(sprite)
	return sprite:getSpellState(B24.SplState.HELD) or B24.IsWebbed(sprite)
end

function B24.IsParalyzed(sprite)
	return sprite:getStat(B24.Stat.HELD) > 0 and not B24.IsWebbed(sprite)
end

function B24.IsUnconscious(sprite)
	local g = B24.GState
	return B24.GState_Has(sprite, g.SLEEPING) or B24.GState_Has(sprite, g.HELPLESS)
end

---------------------------------
-- Conditions this mod applies --
---------------------------------

local function applyEffects(target, key, seconds, source)
	local res = B24CD.RES[key]
	local timed = function(args)
		args.durationType, args.duration, args.m_sourceRes = 0, seconds, res
		args.sourceID = source and source.m_id or nil
		B24.ApplyEffect(target, args)
	end
	timed({ ["effectID"] = 176, ["effectAmount"] = 0, ["dwFlags"] = 5 })
	if key == "RESTRAINED" then
		timed({ ["effectID"] = 328, ["dwFlags"] = B24.SplState.HELD, ["special"] = 1 })
	end
end

-- The grappled creature gets the Escape Grapple innate for as long as the grapple lasts.
local function grantEscape(target, on)
	B24.ApplyEffect(target, { ["effectID"] = 172, ["res"] = B24CD.ESCAPE_RES })
	if on then B24.ApplyEffect(target, { ["effectID"] = 171, ["res"] = B24CD.ESCAPE_RES }) end
end

-- options = { seconds = 60, source = sprite, ability = "STR", dc = 13, label = "Nature's Wrath" }
function B24.ApplyCondition(target, key, options)
	local seconds = options.seconds or 60
	B24.RemoveEffectsBySource(target, B24CD.RES[key])
	applyEffects(target, key, seconds, options.source)
	B24CD.active[target.m_id .. key] = { id = target.m_id, key = key, ability = options.ability, dc = options.dc,
		label = options.label or key, source = options.source and options.source.m_id or nil,
		untilTick = B24.GameTick() + seconds * 15, nextSave = B24.GameTick() + 90 }
	if key == "GRAPPLED" then grantEscape(target, true) end
	B24.Log(string.format("%s is %s", B24.Name(target), key:lower()))
end

function B24.EndCondition(target, key)
	B24CD.active[target.m_id .. key] = nil
	B24.RemoveEffectsBySource(target, B24CD.RES[key])
	if key == "GRAPPLED" then grantEscape(target, false) end
end

-- Escape a grapple (innate B24ESCGR, an action): a Strength (Athletics) or Dexterity (Acrobatics)
-- check, whichever is better, against the grapple's escape DC (8 + the grappler's Strength
-- modifier and proficiency bonus). Raging gives advantage on the Athletics check.
B24CD.ESCAPE_RES = "B24ESCGR"
function B24ESCGR(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local entry = B24CD.active[sprite.m_id .. "GRAPPLED"]
		if entry == nil or B24.GameTick() > entry.untilTick then
			B24.EndCondition(sprite, "GRAPPLED")
			return
		end
		local grappler = entry.source and B24.GetSprite(entry.source)
		local dc = entry.dc or (grappler and 8 + B24.ProfOf(grappler) + B24.AbilityModOf(grappler, "STR")) or 10
		local proficient, expert = B24.Proficiencies(sprite)
		local athletics = B24.SkillBonus(sprite, "ATHLETICS", proficient, expert)
		local acrobatics = B24.SkillBonus(sprite, "ACROBATICS", proficient, expert)
		local raging = B24.HasTimed(sprite, "RAGE")
		local useAthletics = athletics >= acrobatics or raging
		local bonus = useAthletics and athletics or acrobatics
		local roll = B24.RollD20(useAthletics and raging, false)
		local total = roll + bonus
		B24.Log(string.format("%s tries to escape the grapple (%s): %d + %d = %d against DC %d", B24.Name(sprite),
			useAthletics and "Athletics" or "Acrobatics", roll, bonus, total, dc))
		if total >= dc then
			B24.EndCondition(sprite, "GRAPPLED")
			B24.Log(string.format("%s breaks free", B24.Name(sprite)))
		end
	end)
end

-- Spells whose 2024 target repeats the save at the end of each of its turns and shakes the spell
-- off on a success: Blindness/Deafness, Fear, Ray of Enfeeblement, Hold Person, Slow, Confusion,
-- Hold Monster (BG's Power Word Stun has no save to start from). A creature that fails the first
-- save gets an entry (key
-- "SPELL:" .. res); a success removes the spell's effects from it (op321). Upcast, innate and
-- re-filed copies (B24MOVED.2DA: Hold Person SPWI306 is SPWI227) count as their catalog spell.
B24CD.REPEAT_SAVE_SPELLS = {
	SPWI106 = true, SPWI205 = true, SPWI221 = true, SPWI306 = true, SPPR208 = true, SPWI312 = true,
	SPWI401 = true, SPPR709 = true, SPWI507 = true,
}

local movedBack = nil
local function catalogSpell(res)
	res = (res or ""):upper()
	if B24.OriginalSpellRes then res = (B24.OriginalSpellRes(res) or res):upper() end
	if B24SP and B24SP.BaseSpell then res = B24SP.BaseSpell(res) end
	if movedBack == nil then
		movedBack = {}
		for old, new in pairs(B24SP and B24SP.MOVED or {}) do movedBack[new:upper()] = old:upper() end
	end
	return movedBack[res] or res
end

local spellNames = {}
local function spellName(res)
	if spellNames[res] == nil then
		local ok, name = pcall(function() return Infinity_FetchString(EEex_Resource_Demand(res, "SPL").genericName) end)
		spellNames[res] = (ok and name and name ~= "") and name or res
	end
	return spellNames[res]
end

local function hasEffectsFrom(sprite, res)
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_sourceRes:get():upper() == res then found = true return true end
	end)
	return found
end

-- A repeat save against the effects of spell res on sprite: a success removes them (Lua spells
-- such as Power Word Stun register theirs directly).
-- A saved game keeps the repeat save in the target's variable B24RSDC (DC * 10 + ability 1-6);
-- after loading, B24CD.RestoreRepeatSave finds the spell's effect on the creature again.
B24CD.SAVE_ABILITIES = { "STR", "DEX", "CON", "INT", "WIS", "CHA" }
local function storeRepeatSave(sprite, ability, dc)
	local index = 0
	for i, a in ipairs(B24CD.SAVE_ABILITIES) do if a == ability then index = i end end
	sprite:setLocalInt("B24RSDC", (ability and dc) and (dc * 10 + index) or 0)
end

function B24CD.AddRepeatSave(sprite, res, ability, dc, sourceID)
	res = res:upper()
	local key = "SPELL:" .. res
	if B24CD.active[sprite.m_id .. key] then return end
	storeRepeatSave(sprite, ability, dc)
	B24CD.active[sprite.m_id .. key] = { id = sprite.m_id, key = key, res = res, ability = ability, dc = dc,
		label = spellName(res), source = sourceID, untilTick = math.huge, nextSave = B24.GameTick() + 90 }
end

-- From B24.ScreenSave: an effect's save just failed (ability and DC as rolled).
function B24CD.OnFailedSave(effect, sprite, ability, dc)
	local res = effect.m_sourceRes:get():upper()
	if not B24CD.REPEAT_SAVE_SPELLS[catalogSpell(res)] then return end
	B24CD.AddRepeatSave(sprite, res, ability, dc, effect.m_sourceId)
end

local function endEntry(target, entry)
	if entry.res then
		B24CD.active[target.m_id .. entry.key] = nil
		storeRepeatSave(target, nil)
		B24.ApplyEffect(target, { ["effectID"] = 321, ["res"] = entry.res, ["durationType"] = 1 })
		B24.Log(string.format("%s shakes off %s", B24.Name(target), entry.label))
	else
		B24.EndCondition(target, entry.key)
	end
end

local function over(target, entry, now)
	if target == nil or now > entry.untilTick or B24.GState_Has(target, B24.GState.DEAD) then return true end
	return entry.res ~= nil and not hasEffectsFrom(target, entry.res)
end

-- The repeat save of one entry (a grappled party member escapes with its action instead).
local function repeatSave(target, entry, now)
	if not entry.ability or (entry.key == "GRAPPLED" and B24.InParty(target)) then return end
	entry.nextSave = now + 90
	local success = B24.RollSave(target, entry.ability, entry.dc, nil, " (" .. entry.label .. ", repeat)")
	if entry.onSave then
		entry.onSave(target, entry, success)
	elseif success then
		endEntry(target, entry)
	end
end

-- Petrification (op134 with a save) in its 2024 form: a failed save restrains the creature
-- instead, and it makes Constitution saves again (as the repeat saves above). Flesh to Stone:
-- three failures petrify it, three successes end the spell. Other sources (a basilisk's gaze):
-- the next failure petrifies it, a success ends it. Petrified is BG's stone state; Greater
-- Restoration (op43, b24_spells.tpa) and Stone to Flesh cure it.
B24CD.FLESH_TO_STONE = "SPWI604"
B24CD.PETRIFY_SECONDS = 60
B24CD.restrainNext = {}
-- [target id] = { caster, res, untilTick }: petrified by Flesh to Stone, concentration still running
B24CD.stone = {}

local function petrifySave(target, entry, success)
	if success then entry.successes = entry.successes + 1 else entry.failures = entry.failures + 1 end
	B24.Log(string.format("%s: %d failed, %d successful saves against %s", B24.Name(target), entry.failures,
		entry.successes, entry.label))
	if entry.failures >= entry.needed then
		B24CD.active[target.m_id .. entry.key] = nil
		B24.EndCondition(target, "RESTRAINED")
		B24.ApplyEffect(target, { ["effectID"] = 134, ["durationType"] = 1, ["sourceID"] = entry.source })
		B24.Log(string.format("%s turns to stone", B24.Name(target)))
		-- Flesh to Stone: the stone lasts for good only once the caster has concentrated for the
		-- whole minute; lost concentration before that frees the target (B24CD.OnConcEnd).
		if entry.fleshToStone then
			B24CD.stone[target.m_id] = { caster = entry.source, res = entry.fromRes, untilTick = entry.untilTick }
		end
	elseif entry.successes >= entry.needed then
		B24CD.active[target.m_id .. entry.key] = nil
		B24.EndCondition(target, "RESTRAINED")
		B24.Log(string.format("%s shakes off %s", B24.Name(target), entry.label))
	end
end

-- From B24.ScreenSave: op134 whose save just failed. Returns true: the effect is blocked.
function B24CD.StartPetrify(effect, sprite, ability, dc)
	local res = effect.m_sourceRes:get():upper()
	local fleshToStone = catalogSpell(res) == B24CD.FLESH_TO_STONE
	-- Restrained from the next tick on: no effects are added while the engine adds this one.
	table.insert(B24CD.restrainNext, { id = sprite.m_id, source = effect.m_sourceId })
	B24CD.active[sprite.m_id .. "PETRIFY"] = { id = sprite.m_id, key = "PETRIFY", ability = ability, dc = dc,
		label = fleshToStone and "Flesh to Stone" or (res ~= "" and spellName(res) or "petrification"),
		source = effect.m_sourceId, untilTick = B24.GameTick() + B24CD.PETRIFY_SECONDS * 15,
		nextSave = B24.GameTick() + 90, failures = 0, successes = 0, needed = fleshToStone and 3 or 1,
		onSave = petrifySave, fromRes = res, startTick = B24.GameTick(), fleshToStone = fleshToStone }
	B24.Log(string.format("%s is restrained and begins to turn to stone", B24.Name(sprite)))
	return true
end

-- Flesh to Stone ends with the caster's concentration: a target still turning is free again, a
-- petrified one too unless the minute was over (then the stone stays until cured).
function B24CD.OnConcEnd(casterID, res, targets)
	if catalogSpell(res) ~= B24CD.FLESH_TO_STONE then return end
	local now = B24.GameTick()
	for targetID in pairs(targets) do
		local target = B24.GetSprite(targetID)
		local entry = B24CD.active[targetID .. "PETRIFY"]
		if target and entry and entry.source == casterID then
			B24CD.active[targetID .. "PETRIFY"] = nil
			B24.EndCondition(target, "RESTRAINED")
			B24.Log(string.format("%s: Flesh to Stone ends", B24.Name(target)))
		end
		local stone = B24CD.stone[targetID]
		if target and stone and stone.caster == casterID then
			B24CD.stone[targetID] = nil
			if now <= stone.untilTick then
				B24.ApplyEffect(target, { ["effectID"] = 43, ["durationType"] = 1 })
				B24.Log(string.format("%s: Flesh to Stone ends, the stone turns back to flesh", B24.Name(target)))
			end
		end
	end
end
table.insert(B24.ConcEndListeners, B24CD.OnConcEnd)

-- The grey stone colour (op61) that comes with the petrification: only once it is petrified (the
-- engine's stone state has its own look).
function B24CD.BlockedWithPetrify(effect, sprite)
	if effect.m_effectId ~= 61 then return false end
	local entry = B24CD.active[sprite.m_id .. "PETRIFY"]
	return entry ~= nil and entry.startTick == B24.GameTick() and entry.fromRes == effect.m_sourceRes:get():upper()
end

-- Turn-based combat counts time in rounds (B24TURN.lua): condition ends and Flesh to Stone's
-- minute move with it.
function B24CD.ShiftClock(sprite, ticks)
	for _, entry in pairs(B24CD.active) do
		if entry.id == sprite.m_id and entry.untilTick ~= math.huge then entry.untilTick = entry.untilTick + ticks end
	end
	local stone = B24CD.stone[sprite.m_id]
	if stone then stone.untilTick = stone.untilTick + ticks end
end

-- Turn-based combat (B24TURN.lua): the repeat saves come at the end of the creature's turn.
function B24CD.TurnEnd(sprite)
	local now = B24.GameTick()
	for id, entry in pairs(B24CD.active) do
		if entry.id == sprite.m_id and B24CD.active[id] == entry and not over(sprite, entry, now) then
			repeatSave(sprite, entry, now)
		end
	end
end

function B24.HasCondition(target, key)
	local entry = B24CD.active[target.m_id .. key]
	return entry ~= nil and B24.GameTick() <= entry.untilTick
end

-- Prone for a round. A prone creature either crawls (every foot costs two) or stands up (half its
-- speed); both leave it half its movement for the round, so it moves at half speed while prone.
B24CD.PRONE_RES = "B24PRONE"
function B24.KnockProne(target, source, seconds)
	B24.RemoveEffectsBySource(target, B24CD.PRONE_RES)
	local timed = function(args)
		args.durationType, args.duration, args.m_sourceRes = 0, seconds or 6, B24CD.PRONE_RES
		args.sourceID = source and source.m_id or nil
		B24.ApplyEffect(target, args)
	end
	timed({ ["effectID"] = 328, ["dwFlags"] = B24.SplState.PRONE, ["special"] = 1 })
	timed({ ["effectID"] = 176, ["effectAmount"] = 50, ["dwFlags"] = 5 })
end

--------------------------
-- Attacks and criticals --
--------------------------

-- Prone: advantage from within 5 ft, disadvantage from farther away.
table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	return target:getSpellState(B24.SplState.PRONE) and B24.Adjacent(attacker, target)
end)

table.insert(B24.DisadvantageAgainstListeners, function(attacker, target)
	if target:getSpellState(B24.SplState.PRONE) and not B24.Adjacent(attacker, target) then return true end
	-- Grappled: disadvantage against anyone but the grappler.
	local grapple = B24CD.active[attacker.m_id .. "GRAPPLED"]
	return grapple ~= nil and B24.GameTick() <= grapple.untilTick and grapple.source ~= nil and grapple.source ~= target.m_id
end)

-- Paralyzed and unconscious: a melee hit from within 5 ft is a critical hit (the 2024 rule doubles
-- the weapon dice). Runs before the class listeners, which read isCritical for their own dice.
table.insert(B24WPN.DamageListeners, function(context)
	if context.isCritical or context.launcher then return end
	local target = context.target
	if not (B24.IsParalyzed(target) or B24.IsUnconscious(target)) or not B24.Adjacent(context.attacker, target) then return end
	local count = B24WPN.AbilityDice(context.ability)
	if count > 0 and context.effect.m_numDice == count then context.effect.m_numDice = 2 * count end
	context.isCritical = true
	B24.Log(string.format("%s: critical hit against a helpless target", B24.Name(context.attacker)))
end)

-- Blindness: the engine's -4 to attacks and AC per effect is taken back.
B24.AddStatListener(function(sprite)
	if not B24.GState_Has(sprite, B24.GState.BLIND) then return end
	local n = countTimedOpcode(sprite, 74)
	if n == 0 then return end
	local stats = sprite:getActiveStats()
	stats.m_nTHAC0 = stats.m_nTHAC0 - 4 * n
	stats.m_nArmorClass = stats.m_nArmorClass - 4 * n
end)

-----------
-- Ticks --
-----------

-- The +5 attack bump (B24ADV.lua) depends on the attacker's current target; when that changes
-- (a new target, a target falling prone), the attacker's stats are resolved again.
local function refreshBump(sprite)
	local aux = B24.Aux(sprite)
	if aux.B24_attackBump == nil then return end
	if B24.WantsAttackBump(sprite) ~= aux.B24_attackBump then
		B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 0 })
	end
end

local lastTick = -1000
function B24CD.Tick()
	local now = B24.GameTick()
	-- Imported characters whose variables came back (B24.RestoreLocals): the carrier effects go.
	for id in pairs(B24.CarrierCleanup or {}) do
		local sprite = B24.GetSprite(id)
		if sprite then B24.RemoveEffectsBySource(sprite, B24.LOCALS_RES) end
	end
	B24.CarrierCleanup = {}
	-- Creatures that began to turn to stone (B24CD.StartPetrify).
	if #B24CD.restrainNext > 0 then
		local list = B24CD.restrainNext
		B24CD.restrainNext = {}
		for _, item in ipairs(list) do
			local target = B24.GetSprite(item.id)
			if target and B24CD.active[item.id .. "PETRIFY"] then
				B24.ApplyCondition(target, "RESTRAINED", { seconds = B24CD.PETRIFY_SECONDS,
					source = item.source and B24.GetSprite(item.source) or nil, label = "Petrification" })
			end
		end
	end
	if now - lastTick < 15 and now >= lastTick then return end
	lastTick = now
	-- Repeat saves at the end of each round (in turn-based combat at the end of the creature's
	-- turn, B24CD.TurnEnd).
	for id, entry in pairs(B24CD.active) do
		local target = B24.GetSprite(entry.id)
		if over(target, entry, now) then
			B24CD.active[id] = nil
			if target and entry.res and target:getLocalInt("B24RSDC") ~= 0 then storeRepeatSave(target, nil) end
			if target and entry.key == "GRAPPLED" then grantEscape(target, false) end
		-- Only entries with a save repeat it (an entry without one just runs out).
		elseif entry.ability and now >= (entry.nextSave or now) and not (B24TB and B24TB.InTurns and B24TB.InTurns(target)) then
			repeatSave(target, entry, now)
		end
	end
	-- Attack bumps of the party and the enemies around it.
	local seen = {}
	for _, member in ipairs(B24.Party()) do
		if not seen[member.m_id] then
			seen[member.m_id] = true
			EEex_Utility_TryIgnore(refreshBump, member)
		end
		EEex_Utility_TryIgnore(B24DY.Tick, member)
		EEex_Utility_TryIgnore(B24MC.Tick, member)
		EEex_Utility_TryIgnore(B24.UpdateIcons, member)
		for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(member, "[ENEMY]", 450, false) or {}) do
			if not seen[enemy.m_id] then
				seen[enemy.m_id] = true
				EEex_Utility_TryIgnore(refreshBump, enemy)
			end
		end
	end
end

-- Portrait icons of the core states; class files add their own (B24.AddIconListener).
local TIMED_ICONS = { RAGE = "RAGE", RECKLESS = "RECK", HOLY_NIMBUS = "NIMB", INNATE_SORCERY = "INSO",
	STARRY_FORM = "STAR", GRANTS_DIS = "DODG" }
B24.AddIconListener(function(sprite, keys)
	for timed, key in pairs(TIMED_ICONS) do
		if B24.HasTimed(sprite, timed) then keys[key] = true end
	end
	if B24.Conc_Get(sprite) ~= nil then keys.CONC = true end
	if B24.Exhaustion_Get(sprite) > 0 then keys.EXHA = true end
	if sprite:getSpellState(B24.SplState.PRONE) then keys.PRON = true end
	if B24.HasCondition(sprite, "GRAPPLED") then keys.GRAP = true end
	if B24.HasCondition(sprite, "RESTRAINED") then keys.REST = true end
	if B24.HasEffectSource(sprite, 18, "B24TMPHP") then keys.THP = true end
end)

local originalHasPendingScreens = B24_HasPendingScreens
function B24_HasPendingScreens()
	EEex_Utility_TryIgnore(B24CD.Tick)
	return originalHasPendingScreens()
end

-- After loading: a creature whose variable says it had a repeat save gets it back from the spell's
-- effect still on it (the spell would otherwise run its BG duration).
function B24CD.RestoreRepeatSave(sprite)
	local stored = sprite:getLocalInt("B24RSDC")
	if stored == 0 then return end
	for _, entry in pairs(B24CD.active) do
		if entry.id == sprite.m_id and entry.res then return end
	end
	local found = nil
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		local res = effect.m_sourceRes:get():upper()
		if res ~= "" and B24CD.REPEAT_SAVE_SPELLS[catalogSpell(res)] then
			found = { res = res, source = effect.m_sourceId }
			return true
		end
	end)
	if found == nil then
		sprite:setLocalInt("B24RSDC", 0)
		return
	end
	B24CD.AddRepeatSave(sprite, found.res, B24CD.SAVE_ABILITIES[stored % 10], math.floor(stored / 10), found.source)
	B24.Log(string.format("%s still has %s (loaded): repeat saves go on", B24.Name(sprite), spellName(found.res)))
end
EEex_Opcode_AddListsResolvedListener(function(sprite)
	if sprite:getLocalInt("B24RSDC") ~= 0 then EEex_Utility_TryIgnore(B24CD.RestoreRepeatSave, sprite) end
end)
