-- BG 2024 Rules Mod: dropping to 0 hit points, death saves and Revivify.
--
-- A party member who drops to 0 hit points falls unconscious instead of dying: op208 keeps it at
-- 1 hit point, which stands for 0. While down it makes a death save every round (in turn-based
-- combat at the start of each of its turns, B24DY.TurnStart): 10 or more is a
-- success, a 1 counts as two failures, a 20 brings it back with 1 hit point. Three successes make
-- it stable (it wakes with 1 hit point after 1d4 minutes), three failures kill it. Damage while
-- down is a failed save, two from an attacker next to it (a critical hit against the
-- unconscious). Healing wakes it with what it healed. Damage that is still as much as its hit
-- point maximum after taking it to 0 kills outright.
-- The protagonist's death ends the game, so after its third failure it stays down for a minute
-- in which Revivify or healing brings it back; it dies when the minute is over or when it is hit
-- again. Each step shows over the creature's head (B24.HeadText).
-- Revivify (B24REVIV.SPL) brings back a creature that died within the last minute.
--
-- Monsters die at 0 as before. Features that keep a creature at 1 hit point (Relentless
-- Endurance, Relentless Rage, Undying Sentinel) go first: B24.AddDownSaver; then Death Ward.
--
-- Locals: B24DYDN (0 up, 1 dying, 2 stable, 3 protagonist after the third failure), B24DYSUC and
-- B24DYFAI (death saves), B24DYAT (game tick of the next death save, of waking when stable, of
-- dying for good), B24DYDTH (game tick of death, for Revivify).

B24DY = {}
B24DY.MIN_HP_RES = "B24DYING"
B24DY.DOWN_RES = "B24DOWN"
B24DY.ROUND = 90
B24DY.REVIVIFY_TICKS = 60 * 15
B24DY.UP, B24DY.DYING, B24DY.STABLE, B24DY.BEYOND = 0, 1, 2, 3

-- listener(sprite) returns true while a feature of its own will catch the next drop to 0.
B24DY.Savers = {}
function B24.AddDownSaver(listener) table.insert(B24DY.Savers, listener) end

local function state(sprite) return sprite:getLocalInt("B24DYDN") end

function B24.IsDown(sprite) return state(sprite) ~= B24DY.UP end

local function isDead(sprite) return B24.GState_Has(sprite, B24.GState.DEAD) end

local function isProtagonist(sprite)
	local protagonist = B24.Protagonist()
	return protagonist ~= nil and protagonist.m_id == sprite.m_id
end

local function protect(sprite, on)
	B24.RemoveEffectsBySource(sprite, B24DY.MIN_HP_RES)
	if on then
		B24.ApplyEffect(sprite, { ["effectID"] = 208, ["effectAmount"] = 1, ["durationType"] = 9,
			["m_sourceRes"] = B24DY.MIN_HP_RES })
	end
end

local function setState(sprite, st, at)
	sprite:setLocalInt("B24DYDN", st)
	sprite:setLocalInt("B24DYAT", at or 0)
	if st == B24DY.UP or st == B24DY.DYING then
		sprite:setLocalInt("B24DYSUC", 0)
		sprite:setLocalInt("B24DYFAI", 0)
	end
end

-- Text over the creature's head (B24.HeadText from B24STATE.lua: strings installed by the mod).
local function head(sprite, key)
	local ref = B24.HeadText and B24.HeadText[key]
	if ref == nil then return end
	EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format("DisplayStringHead(Myself,%d)", ref), sprite)
end

local function goDown(sprite)
	setState(sprite, B24DY.DYING, B24.GameTick() + B24DY.ROUND)
	-- Unconscious until woken (op39 type 1: damage doesn't wake it).
	B24.ApplyEffect(sprite, { ["effectID"] = 39, ["dwFlags"] = 1, ["durationType"] = 9, ["m_sourceRes"] = B24DY.DOWN_RES })
	B24.Log(string.format("%s drops to 0 hit points and is dying", B24.Name(sprite)))
	head(sprite, "DYING")
end

-- hp: hit points to wake with (BG's 1 stands for 0, so healing adds one too many).
local function wake(sprite, hp, why)
	setState(sprite, B24DY.UP)
	B24.RemoveEffectsBySource(sprite, B24DY.DOWN_RES)
	sprite.m_baseStats.m_hitPoints = math.max(1, hp)
	B24.Log(string.format("%s %s with %d hit point%s", B24.Name(sprite), why, math.max(1, hp), hp > 1 and "s" or ""))
	head(sprite, "WAKE")
end

-- A minimum hit point of its own (op208 not from the dying rules): plot items that keep a companion
-- alive (Hexxat's amulet, Imoen's belt in BG2's first chapter, SoD Imoen's plot item). Such a
-- creature can't be killed: the deadly blow (finish) would meet the floor every second for good.
local function ownMinimumHP(sprite)
	local found = false
	local test = function(effect)
		if effect.m_effectId == 208 and effect.m_sourceRes:get():upper() ~= B24DY.MIN_HP_RES then
			found = true
			return true
		end
	end
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, test)
	if not found then EEex_Utility_IterateCPtrList(sprite.m_equipedEffectList, test) end
	return found
end

local function die(sprite, why)
	if ownMinimumHP(sprite) then
		-- Kept alive by its own item: stable instead (wakes with 1 hit point after 1d4 minutes).
		setState(sprite, B24DY.STABLE, B24.GameTick() + B24.Roll(4) * 60 * 15)
		B24.Log(string.format("%s would die (%s), but a minimum hit point of its own holds: stable", B24.Name(sprite), why))
		head(sprite, "STABLE")
		return
	end
	setState(sprite, B24DY.UP)
	protect(sprite, false)
	B24.RemoveEffectsBySource(sprite, B24DY.DOWN_RES)
	B24.Log(string.format("%s dies (%s)", B24.Name(sprite), why))
	head(sprite, "DIES")
	-- The deadly blow follows on the next tick, once the minimum hit point is gone (B24DY.Tick).
	sprite:setLocalInt("B24DYKIL", 1)
end

local function finish(sprite)
	B24.ApplyEffect(sprite, { ["effectID"] = 12, ["effectAmount"] = sprite.m_baseStats.m_hitPoints + 100,
		["dwFlags"] = 0, ["durationType"] = 1 })
end

local function threeFailures(sprite)
	if isProtagonist(sprite) then
		setState(sprite, B24DY.BEYOND, B24.GameTick() + B24DY.REVIVIFY_TICKS)
		B24.Log(string.format("%s fails the third death save: a minute left for Revivify or healing; another hit kills", B24.Name(sprite)))
		head(sprite, "LAST")
	else
		die(sprite, "three failed death saves")
	end
end

local function failSaves(sprite, count, why)
	local failures = sprite:getLocalInt("B24DYFAI") + count
	sprite:setLocalInt("B24DYFAI", failures)
	if failures < 3 then head(sprite, "FAIL" .. failures) end
	B24.Log(string.format("%s: %s, %d failed death save%s", B24.Name(sprite), why, math.min(3, failures), failures > 1 and "s" or ""))
	if failures >= 3 then threeFailures(sprite) end
end

-- Death save; B24DY.TestRoll fixes the roll for the in-game test.
local function deathSave(sprite)
	local roll = B24DY.TestRoll or B24.RollD20(false, false)
	B24DY.TestRoll = nil
	if roll == 20 then
		wake(sprite, 1, "rolls a 20 on the death save and wakes")
	elseif roll == 1 then
		failSaves(sprite, 2, "rolls a 1 on the death save")
	elseif roll >= 10 then
		local successes = sprite:getLocalInt("B24DYSUC") + 1
		sprite:setLocalInt("B24DYSUC", successes)
		if successes < 3 then head(sprite, "SAVE" .. successes) end
		B24.Log(string.format("%s: death save %d, %d success%s", B24.Name(sprite), roll, successes, successes > 1 and "es" or ""))
		if successes >= 3 then
			setState(sprite, B24DY.STABLE, B24.GameTick() + B24.Roll(4) * 60 * 15)
			B24.Log(string.format("%s is stable", B24.Name(sprite)))
			head(sprite, "STABLE")
		end
	else
		failSaves(sprite, 1, string.format("death save %d", roll))
	end
end

-- Once a second for each party member (B24CD.Tick).
function B24DY.Tick(sprite)
	local now = B24.GameTick()
	if isDead(sprite) then
		sprite:setLocalInt("B24DYKIL", 0)
		if sprite:getLocalInt("B24DYDTH") == 0 then sprite:setLocalInt("B24DYDTH", now) end
		if state(sprite) ~= B24DY.UP then setState(sprite, B24DY.UP) end
		return
	end
	if sprite:getLocalInt("B24DYKIL") == 1 then
		finish(sprite)
		return
	end
	if sprite:getLocalInt("B24DYDTH") ~= 0 then sprite:setLocalInt("B24DYDTH", 0) end
	if not B24.HasEffectSource(sprite, 208, B24DY.MIN_HP_RES) then protect(sprite, true) end
	local st = state(sprite)
	if st == B24DY.UP then return end
	local hp = sprite.m_baseStats.m_hitPoints
	if hp > 1 then
		wake(sprite, hp - 1, "is healed and wakes")
	elseif now >= sprite:getLocalInt("B24DYAT") then
		if st == B24DY.DYING then
			-- In turn-based combat the save comes with the creature's turn (B24DY.TurnStart).
			if B24TB and B24TB.InTurns and B24TB.InTurns(sprite) then return end
			sprite:setLocalInt("B24DYAT", now + B24DY.ROUND)
			deathSave(sprite)
		elseif st == B24DY.STABLE then
			wake(sprite, 1, "wakes")
		elseif st == B24DY.BEYOND then
			die(sprite, "no one brought them back")
		end
	end
end

-- Turn-based combat (B24TURN.lua): a dying creature makes its death save at the start of each of
-- its turns instead of every 6 seconds (afterwards the timed saves go on a round later).
function B24DY.TurnStart(sprite)
	if isDead(sprite) or state(sprite) ~= B24DY.DYING or sprite.m_baseStats.m_hitPoints > 1 then return end
	sprite:setLocalInt("B24DYAT", B24.GameTick() + B24DY.ROUND)
	deathSave(sprite)
end

-- Turn-based combat counts time in rounds (B24TURN.lua): waking when stable and the protagonist's
-- last minute move with it.
function B24DY.ShiftClock(sprite, ticks)
	local st = state(sprite)
	if st == B24DY.STABLE or st == B24DY.BEYOND then
		sprite:setLocalInt("B24DYAT", sprite:getLocalInt("B24DYAT") + ticks)
	end
end

-- A creature that left the party keeps no minimum hit point.
function B24DY.Release(sprite)
	if B24.HasEffectSource(sprite, 208, B24DY.MIN_HP_RES) then protect(sprite, false) end
end

------------------
-- Damage hooks --
------------------

local pending = {}

local function onDamageStart(effect, source, target)
	if not B24.InParty(target) then
		-- Left the party: dies at 0 like everyone else from the next hit on.
		B24DY.Release(target)
		return
	end
	if isDead(target) then return end
	if target:getLocalInt("B24DYKIL") == 1 then return end
	-- Only plain damage (mode 0); the dice are rolled here so the amount is known.
	if EEex_BAnd(effect.m_dWFlags, 0xFFFF) ~= 0 then return end
	B24WPN.RollDiceInto(effect)
	local amount = effect.m_effectAmount
	if amount <= 0 then return end
	local st = state(target)
	if st == B24DY.BEYOND then
		-- The last minute only lasts while no one strikes the body again.
		die(target, "struck again after the third failed death save")
		return
	end
	if st == B24DY.DYING or st == B24DY.STABLE then
		-- One failure per attacker and moment: an attack's damage parts count once.
		local aux, key = B24.Aux(target), tostring(B24.GameTick()) .. ":" .. tostring(source and source.m_id)
		if aux.B24_DyLastHit == key then return end
		aux.B24_DyLastHit = key
		if st == B24DY.STABLE then setState(target, B24DY.DYING, B24.GameTick() + B24DY.ROUND) end
		local adjacent = B24.IsSprite(source) and source.m_id ~= target.m_id and B24.Adjacent(source, target)
		failSaves(target, adjacent and 2 or 1, adjacent and "hit while down from up close" or "hit while down")
		return
	end
	if st ~= B24DY.UP then return end
	for _, saver in ipairs(B24DY.Savers) do
		local ok, saves = pcall(saver, target)
		if ok and saves then return end
	end
	pending[target.m_id] = { before = target.m_baseStats.m_hitPoints, amount = amount }
end

-- Death Ward (SPPR409, also as an innate copy): the first drop to 0 hit points leaves the creature
-- at 1 instead and ends the spell. Returns the resource of the ward's effects.
B24DY.DEATH_WARD = "SPPR409"
local function deathWard(sprite)
	local found = nil
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		local res = effect.m_sourceRes:get():upper()
		if res ~= "" and B24.OriginalSpellRes(res):upper() == B24DY.DEATH_WARD then found = res return true end
	end)
	return found
end

local function onDamageDone(target)
	local entry = pending[target.m_id]
	pending[target.m_id] = nil
	if entry == nil or target.m_baseStats.m_hitPoints ~= 1 or entry.amount < entry.before then return end
	local ward = deathWard(target)
	if ward then
		B24.RemoveEffectsBySource(target, ward)
		B24.Log(string.format("%s: Death Ward holds at 1 hit point and ends", B24.Name(target)))
		return
	end
	-- The amount before resistances reached 0; what is left over may kill outright.
	if entry.amount - entry.before >= target:getActiveStats().m_nMaxHitPoints then
		die(target, "massive damage")
	else
		goDown(target)
	end
end

local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
local originalDamageDone = EEex_Sprite_Hook_OnDamageEffectDone

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	EEex_Utility_TryIgnore(onDamageStart, effect, sourceSprite, targetSprite)
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)
	originalDamageDone(effect, sourceSprite, targetSprite)
	EEex_Utility_TryIgnore(onDamageDone, targetSprite)
end

--------------
-- Revivify --
--------------

-- op402 of B24REVIV.SPL on the target: a creature dead for at most a minute comes back with 1
-- hit point; a protagonist past its third failed death save (or still dying) wakes with 1.
function B24REVIV(op402, target)
	EEex_Utility_TryIgnore(function()
		if isDead(target) then
			local died = target:getLocalInt("B24DYDTH")
			if died == 0 or B24.GameTick() - died > B24DY.REVIVIFY_TICKS then
				B24.Log(string.format("Revivify: %s has been dead for more than a minute", B24.Name(target)))
				return
			end
			B24.ApplyEffect(target, { ["effectID"] = 32, ["durationType"] = 1 })
			-- op17 type 1: hit points set to 1.
			B24.ApplyEffect(target, { ["effectID"] = 17, ["effectAmount"] = 1, ["dwFlags"] = 1, ["durationType"] = 1 })
			B24.Log(string.format("Revivify: %s returns to life with 1 hit point", B24.Name(target)))
		elseif B24.IsDown(target) then
			wake(target, 1, "is brought back by Revivify")
		else
			B24.Log(string.format("Revivify: %s is not dead", B24.Name(target)))
		end
	end)
end

-- Portrait icons: dying (or past the third failure), stable.
B24.AddIconListener(function(sprite, keys)
	local st = state(sprite)
	if st == B24DY.DYING or st == B24DY.BEYOND then keys.DYIN = true end
	if st == B24DY.STABLE then keys.STAB = true end
end)
