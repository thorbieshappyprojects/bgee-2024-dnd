-- BG 2024 Rules Mod: round-based combat.
--
-- The engine runs in real time with pause. As the closest stable form of 2024 turns, the game
-- pauses by itself when combat starts and at the start of every 6-second round while it lasts, so
-- every character can be given its action for the round. Combat = an enemy within sight of a
-- party member, in normal play (never in dialogs or cutscenes). Switched off with
-- B24.Config.roundPause = false.

B24RD = { roundStart = nil, round = 0 }

B24RD.ROUND_TICKS = 90
B24RD.SIGHT = 450

local function isPaused()
	local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	return ok and (paused == true or paused == 1)
end

local function inCombat()
	for _, member in ipairs(B24.Party()) do
		if not B24.GState_Has(member, B24.GState.DEAD) then
			local enemies = EEex_Sprite_GetAllOfTypeStringInRange(member, "[ENEMY]", B24RD.SIGHT, true)
			for _, enemy in ipairs(enemies or {}) do
				if not B24.GState_Has(enemy, B24.GState.DEAD) then return true end
			end
		end
	end
	return false
end

-- Normal play: no dialog, cutscene or other scripted input mode (story scenes are never paused).
function B24.InNormalPlay()
	local ok, mode = pcall(EEex_GameState_GetInputMode)
	if not ok or mode == nil then return true end
	local m = EEex_GameState_InputMode
	return mode ~= m.VALUE_FULL_CUTSCENE and mode ~= m.VALUE_LIGHT_CUTSCENE and mode ~= m.VALUE_DIALOG_NO_CONTROL
		and mode ~= m.VALUE_DIALOG_IN_CONTROL and mode ~= m.VALUE_DEATH
end

local function pause(text)
	if isPaused() then return end
	EEex_GameState_TogglePause(true, true)
	B24.Log(text)
end

-------------------------
-- Movement per round --
-------------------------

-- In combat a creature moves for at most B24.Config.moveSecondsPerRound seconds of each round
-- (about its 2024 speed of 30 ft at BG's walking pace); then it stands until the next round.
-- Faster movement (Dash, Haste, Unarmored Movement) covers more ground in that time, slower
-- movement less. Party members and enemies near the party are tracked, sampled 3 times a second.
B24RD.moving = {}   -- [id] = { x, y, moved (ticks), stopped }

local function trackedCreatures()
	local list, seen = {}, {}
	for _, member in ipairs(B24.Party()) do
		if not seen[member.m_id] then seen[member.m_id] = true table.insert(list, member) end
		for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(member, "[ENEMY]", B24RD.SIGHT, false) or {}) do
			if not seen[enemy.m_id] then seen[enemy.m_id] = true table.insert(list, enemy) end
		end
	end
	return list
end

local function releaseAll()
	for id, entry in pairs(B24RD.moving) do
		local sprite = entry.stopped and B24.GetSprite(id)
		if sprite then B24.RemoveEffectsBySource(sprite, "B24MOVE") end
	end
	B24RD.moving = {}
end

local lastSample = -1000
local function trackMovement(now)
	if now - lastSample < 5 and now >= lastSample then return end
	local elapsed = math.min(15, math.max(0, now - lastSample))
	lastSample = now
	local budget = (B24.Config.moveSecondsPerRound or 3) * 15
	for _, sprite in ipairs(trackedCreatures()) do
		local pos = sprite.m_pos
		local entry = B24RD.moving[sprite.m_id]
		if entry == nil then
			B24RD.moving[sprite.m_id] = { x = pos.x, y = pos.y, moved = 0 }
		else
			local dx, dy = pos.x - entry.x, pos.y - entry.y
			if dx * dx + dy * dy > 16 then entry.moved = entry.moved + elapsed end
			entry.x, entry.y = pos.x, pos.y
			if not entry.stopped and entry.moved >= budget then
				entry.stopped = true
				local left = math.max(1, math.ceil((B24RD.ROUND_TICKS - (now - B24RD.roundStart)) / 15))
				B24.ApplyEffect(sprite, { ["effectID"] = 176, ["effectAmount"] = 0, ["dwFlags"] = 5,
					["durationType"] = 0, ["duration"] = left, ["m_sourceRes"] = "B24MOVE" })
				B24.Log(string.format("%s has used its movement this round", B24.Name(sprite)))
			end
		end
	end
end

-- Turn-based combat (B24TURN.lua): no pauses, movement counted per turn. Each turn starts with a
-- fresh round's movement for that creature; only it moves while it is its turn.
function B24RD.StartTurn(sprite)
	local entry = B24RD.moving[sprite.m_id]
	if entry and entry.stopped then B24.RemoveEffectsBySource(sprite, "B24MOVE") end
	B24RD.moving[sprite.m_id] = nil
	B24RD.roundStart = B24.GameTick()
end

function B24RD.TrackTurn(sprite)
	if B24.Config.moveLimit ~= false and not isPaused() then trackMovement(B24.GameTick()) end
end

function B24RD.EndTurns()
	releaseAll()
	B24RD.roundStart = nil
end

-- listener(sprite) runs for every party member when a fight starts (2024: "when you roll
-- initiative"), in real time and in turn-based combat (B24TURN.lua).
B24.CombatStartListeners = {}
function B24.AddCombatStartListener(listener) table.insert(B24.CombatStartListeners, listener) end

function B24.CombatStarted()
	for _, member in ipairs(B24.Party()) do
		for _, listener in ipairs(B24.CombatStartListeners) do EEex_Utility_TryIgnore(listener, member) end
	end
end

-- Called from the global script hook (see B24_HasPendingScreens).
function B24RD.Tick()
	if worldScreen == nil or e:GetActiveEngine() ~= worldScreen then return end
	if not B24.InNormalPlay() then return end
	if B24TB and (B24TB.active or B24TB.Enabled()) then return end
	if not inCombat() then
		if B24RD.roundStart ~= nil then releaseAll() end
		B24RD.roundStart = nil
		return
	end
	local now = B24.GameTick()
	local pauses = B24.Config.roundPause ~= false
	if B24RD.roundStart == nil then
		B24RD.roundStart, B24RD.round = now, 1
		releaseAll()
		B24.CombatStarted()
		if pauses then pause("Combat: round 1") end
	elseif now - B24RD.roundStart >= B24RD.ROUND_TICKS then
		B24RD.roundStart, B24RD.round = now, B24RD.round + 1
		releaseAll()
		if pauses then pause("Round " .. B24RD.round) end
	end
	if B24.Config.moveLimit ~= false and not isPaused() then trackMovement(now) end
end

local originalHasPendingScreens = B24_HasPendingScreens
function B24_HasPendingScreens()
	EEex_Utility_TryIgnore(B24RD.Tick)
	return originalHasPendingScreens()
end

-- Dash and similar features (Cunning Action, Step of the Wind): another round's worth of movement.
function B24RD.GrantMovement(sprite)
	local entry = B24RD.moving[sprite.m_id]
	if entry == nil then return end
	entry.moved = entry.moved - (B24.Config.moveSecondsPerRound or 3) * 15
	if entry.stopped then
		entry.stopped = false
		B24.RemoveEffectsBySource(sprite, "B24MOVE")
	end
end
