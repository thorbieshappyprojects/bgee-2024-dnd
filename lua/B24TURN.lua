-- BG 2024 Rules Mod: turn-based combat (switched on and off with the button on the game screen;
-- saved with the game in the global B24_TURNS, off by default).
--
-- When combat starts, every creature in it rolls initiative (d20 + Dexterity modifier). In that
-- order exactly one creature acts while everyone else is frozen: the engine's own Time Stop
-- (m_nTimeStopCaster, m_nTimeStop) is handed from creature to creature, without the spell's grey
-- screen. A turn ends when the creature's action is done:
--   - its action finishes (a spell, a one-round attack; for other creatures also a move: a party
--     member's move leaves the turn open for its action),
--   - an attack round is over (the attack cycle starts over after a swing),
--   - it uses End Turn (the button under the switch, while a party member has its turn),
--   - at once when it can't act (dead, down, asleep, held, stunned),
--   - after two rounds' time: for other creatures from the turn's start, for party members only
--     once an action has started (no time limit while the player decides).
-- A creature that can't act still has its turn, at once: a dying one makes its death save at its
-- start, repeat saves (Hold Person, the mod's conditions) come at its end (TurnStartListeners,
-- TurnEndListeners). When no one can act, time runs for a round before the order goes on.
-- Effect durations count in rounds (see "Durations in rounds" below).
-- Party members wait for orders and are selected on their turn, alone (the selection stays on
-- them while the turn lasts, so an order reaches no one else). One the player can't control
-- (afraid, berserk, confused, charmed) has its turn like the other creatures, played by the engine. Other creatures act with their own
-- AI and lose the turn if they start nothing within three seconds. Every creature's action ends
-- with its turn (an attack doesn't go on into the next one), and once the action is over nothing
-- new starts while the turn waits for its spell to play out.
-- Movement per turn follows the round limit of B24ROUND.lua. Dialogs and cutscenes run in real
-- time; a real Time Stop spell suspends the turns until it ends. A turn whose missiles, rays or
-- arrows are still in the air when its action ends waits for them to land (up to six seconds).
--
-- Action economy: a turn has one action and one bonus action (bonus-action abilities and spells,
-- B24TB.BONUS_*, don't end the turn; Action Surge gives one more action). Every creature has one
-- reaction per round: Opportunity Attacks when an enemy leaves its reach on its turn (2024 reach:
-- 5 ft, 10 ft with Reach weapons), Shield and Uncanny Dodge after a hit. Party members are asked
-- in a short prompt with the game paused; other creatures react at once.

B24TB = { active = false }
B24TB.GLOBAL = "B24_TURNS"
B24TB.TOGGLE_RES = "B24TURNS"
B24TB.END_RES = "B24TEND"
B24TB.SIGHT = 450
B24TB.TURN_TICKS = 180
B24TB.ROUND_TICKS = 90
B24TB.AI_IDLE_TICKS = 45
B24TB.FREEZE_TICKS = 15 * 30

function B24TB.Enabled()
	return B24.Config.turnBased ~= false and EEex_GameState_GetGlobalInt(B24TB.GLOBAL) == 1
end

local function game() return EngineGlobals.g_pBaldurChitin.m_pObjectGame end

-- Dead, also turned to stone or frozen solid (the engine's stone and frozen deaths: no DEAD bit).
B24TB.STATE_FROZEN_DEATH = 0x40
local function isDead(sprite)
	return B24.GState_Has(sprite, B24.GState.DEAD) or B24.GState_Has(sprite, B24.GState.STONE_DEATH)
		or B24.GState_Has(sprite, B24TB.STATE_FROZEN_DEATH)
end

-- A party member the player can't give orders to: the engine plays it (fear runs it off,
-- berserk, confusion, an enemy's charm). Its turn runs as another creature's does: it ends with
-- its action or the turn's time limit, instead of waiting for orders that can't come.
B24TB.UNCONTROLLED_STATES = { 0x2, B24.GState.PANIC, B24.GState.CHARMED, 0x8000 }  -- berserk, panic, charmed, confused
local function playerControls(sprite)
	if not B24.InParty(sprite) then return false end
	for _, bit in ipairs(B24TB.UNCONTROLLED_STATES) do
		if B24.GState_Has(sprite, bit) then return false end
	end
	return true
end

-- Only this creature acts (nil: everyone again).
local function freeze(sprite)
	local g = game()
	-- B24TBACT marks the creature this mod froze the others for (B24TB.AfterLoad).
	local previous = B24TB.caster and B24.GetSprite(B24TB.caster)
	if previous and (sprite == nil or previous.m_id ~= sprite.m_id) then previous:setLocalInt("B24TBACT", 0) end
	if sprite then sprite:setLocalInt("B24TBACT", 1) end
	g.m_nTimeStopCaster = sprite and sprite.m_id or -1
	g.m_nTimeStop = sprite and B24TB.FREEZE_TICKS or 0
	B24TB.caster = sprite and sprite.m_id or nil
end

local function cannotAct(sprite)
	local g = B24.GState
	return isDead(sprite) or (B24.IsDown and B24.IsDown(sprite)) or B24.GState_Has(sprite, g.SLEEPING)
		or B24.GState_Has(sprite, g.STUNNED) or B24.GState_Has(sprite, g.HELPLESS)
		or sprite:getStat(B24.Stat.HELD) > 0
end

------------------
-- Combatants --
------------------

local function enemiesInSight()
	local list, seen = {}, {}
	for _, member in ipairs(B24.Party()) do
		if not isDead(member) then
			for _, enemy in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(member, "[ENEMY]", B24TB.SIGHT, true) or {}) do
				if not seen[enemy.m_id] and not isDead(enemy) then
					seen[enemy.m_id] = true
					table.insert(list, enemy)
				end
			end
		end
	end
	return list
end

local function rollInitiative(sprite)
	local dex = B24.AbilityModOf(sprite, "DEX")
	local roll = B24.Roll(20)
	return { id = sprite.m_id, total = roll + dex, dex = dex, name = B24.Name(sprite) }
end

-- Initiative order: the higher total first, then the higher Dexterity modifier.
local function before(a, b)
	if a.total ~= b.total then return a.total > b.total end
	if a.dex ~= b.dex then return a.dex > b.dex end
	return a.id < b.id
end

local function sortOrder(order)
	table.sort(order, before)
end

local function listOrder(order)
	local parts = {}
	for _, entry in ipairs(order) do table.insert(parts, string.format("%s %d", entry.name, entry.total)) end
	return table.concat(parts, ", ")
end

-- Creatures that came into sight roll initiative and take their place in the order at once (the
-- bar shows them): a place after the current turn acts this round, one before it from the next.
local function addNewcomers()
	local known = {}
	for _, entry in ipairs(B24TB.order) do known[entry.id] = true end
	local added = {}
	local candidates = enemiesInSight()
	for _, member in ipairs(B24.Party()) do table.insert(candidates, member) end
	for _, sprite in ipairs(candidates) do
		if not known[sprite.m_id] and not isDead(sprite) then
			known[sprite.m_id] = true
			local entry = rollInitiative(sprite)
			local place = #B24TB.order + 1
			for i, other in ipairs(B24TB.order) do
				if before(entry, other) then place = i break end
			end
			table.insert(B24TB.order, place, entry)
			if place <= B24TB.index then B24TB.index = B24TB.index + 1 end
			table.insert(added, string.format("%s %d", entry.name, entry.total))
		end
	end
	if #added > 0 then B24.Log("Joins the fight: " .. table.concat(added, ", ")) end
end

local function grantEndTurn(on)
	for _, member in ipairs(B24.Party()) do
		-- End Turn is the button on the game screen only: the innate (from older versions) goes.
		B24.ApplyEffect(member, { ["effectID"] = 172, ["res"] = B24TB.END_RES })
	end
end

-----------
-- Turns --
-----------

-- listener(sprite) at the start and at the end of each creature's turn. A creature that can't act
-- still has its turn, both at once: a dying one makes its death save at the start (B24DYING.lua),
-- a held one its repeat save at the end (B24COND.lua).
B24TB.TurnStartListeners = {
	function(sprite) if B24DY and B24DY.TurnStart then B24DY.TurnStart(sprite) end end,
}
B24TB.TurnEndListeners = {
	function(sprite) if B24CD and B24CD.TurnEnd then B24CD.TurnEnd(sprite) end end,
}

local function notify(listeners, sprite)
	for _, listener in ipairs(listeners) do EEex_Utility_TryIgnore(listener, sprite) end
end

-- Durations in rounds: game time runs through every creature's turn, so a 6-second effect could
-- end before its target's next turn, or last several. While a turn runs, the timed effects and
-- timers of everyone in the fight stand still (their ends move with the clock); at the end of each
-- turn they move on by the turn's share of a round (6 seconds / the creatures in the order). A
-- round thus takes 6 seconds of effect time, however long its turns take. Timed effects are those
-- the engine keeps with an absolute end (timing 4096, game ticks); the mod's own timers follow
-- through B24TB.ClockListeners (listener(sprite, ticks): move this creature's ends by ticks).
B24TB.ABSOLUTE_TIMING = 4096
B24TB.ClockListeners = {
	function(sprite, ticks)
		local timed = B24.Aux(sprite).B24_Timed
		if timed then for key, untilTick in pairs(timed) do timed[key] = untilTick + ticks end end
	end,
	function(sprite, ticks) if B24DY and B24DY.ShiftClock then B24DY.ShiftClock(sprite, ticks) end end,
	function(sprite, ticks) if B24CD and B24CD.ShiftClock then B24CD.ShiftClock(sprite, ticks) end end,
}

local function shiftClock(ticks)
	if ticks == 0 then return end
	for _, entry in ipairs(B24TB.order or {}) do
		local sprite = B24.GetSprite(entry.id)
		if sprite then
			EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
				if effect.m_durationType == B24TB.ABSOLUTE_TIMING then effect.m_duration = effect.m_duration + ticks end
			end)
			for _, listener in ipairs(B24TB.ClockListeners) do EEex_Utility_TryIgnore(listener, sprite, ticks) end
		end
	end
end

-- Every frame of a fight: the time since the last frame doesn't count for the effects.
local function holdClock()
	local now = B24.GameTick()
	if B24TB.clockAt and now > B24TB.clockAt then shiftClock(now - B24TB.clockAt) end
	B24TB.clockAt = now
end

-- The end of a turn: the effects move on by the turn's share of a round (fractions are carried,
-- so a full round is 90 ticks).
local function advanceClock()
	local count = math.max(1, #(B24TB.order or {}))
	B24TB.clockFraction = (B24TB.clockFraction or 0) + B24TB.ROUND_TICKS / count
	local whole = math.floor(B24TB.clockFraction)
	B24TB.clockFraction = B24TB.clockFraction - whole
	shiftClock(-whole)
end

-- Whether the creature takes turns in the current fight (its timed saves wait for them).
function B24TB.InTurns(sprite)
	if not B24TB.active or B24TB.suspended or sprite == nil then return false end
	for _, entry in ipairs(B24TB.order) do
		if entry.id == sprite.m_id then return true end
	end
	return false
end

-- The game screen itself: the game menu (Esc), the record, the inventory and other screens are
-- engines of their own (the menus pushed on the game screen still show over them).
local function onGameScreen()
	return worldScreen ~= nil and e:GetActiveEngine() == worldScreen
end

-- The party member whose turn it is, selected alone. A portrait click (EEex_Keybinds_SelectPortrait)
-- selects nothing while a target cursor is up, and the group selected before would take the order:
-- the cursor goes back to normal and the selection is set directly. Only on the game screen:
-- the record screen has a selection of its own (opening the record on a party member's turn
-- crashed the game while this ran every frame).
local function selectOnly(sprite)
	if not onGameScreen() then return end
	local g = game()
	local members = g.m_group.m_memberList
	if members.m_nCount == 1 and members.m_pNodeHead.data == sprite.m_id then return end
	if g.m_nState ~= 0 then g.m_nState = 0 end
	g:UnselectAll()
	g:SelectCharacter(sprite.m_id, false)
	g:SelectToolbar()
end

local function startTurn(entry)
	local sprite = B24.GetSprite(entry.id)
	B24TB.idleUntil, B24TB.resolving = nil, nil
	B24TB.turn = { id = entry.id, start = B24.GameTick(), started = false, swings = 0,
		lastFrame = sprite and sprite.m_attackFrame or 0, lastSwing = sprite and sprite.m_startedSwing or 0 }
	if sprite == nil then return end
	freeze(sprite)
	if B24RD and B24RD.StartTurn then B24RD.StartTurn(sprite) end
	if playerControls(sprite) then EEex_Utility_TryIgnore(selectOnly, sprite) end
	B24.Log(string.format("Round %d: %s's turn", B24TB.round, entry.name))
end

local function nextTurn()
	local order = B24TB.order
	B24TB.index = B24TB.index + 1
	local newRounds = 0
	while true do
		if B24TB.index > #order then
			-- A whole round in which no one could act (its turns moved effect time on by the round):
			-- the order waits a round of game time before it tries again (B24TB.Tick).
			newRounds = newRounds + 1
			if newRounds > 1 then
				B24TB.turn, B24TB.idleUntil, B24TB.resolving = nil, B24.GameTick() + B24TB.ROUND_TICKS, nil
				freeze(nil)
				return
			end
			-- New round: the dead leave the order, newcomers join it.
			local kept = {}
			for _, entry in ipairs(order) do
				local sprite = B24.GetSprite(entry.id)
				if sprite and not isDead(sprite) then table.insert(kept, entry) end
			end
			for _, entry in ipairs(B24TB.pending) do table.insert(kept, entry) end
			B24TB.pending = {}
			sortOrder(kept)
			B24TB.order, order = kept, kept
			B24TB.index = 1
			B24TB.round = B24TB.round + 1
			if #order == 0 then return end
		end
		local entry = order[B24TB.index]
		local sprite = B24.GetSprite(entry.id)
		if sprite and not isDead(sprite) then
			notify(B24TB.TurnStartListeners, sprite)
			-- Still able to act after the start (a death save of 20 wakes it): a normal turn.
			if not cannotAct(sprite) then
				startTurn(entry)
				return
			end
			notify(B24TB.TurnEndListeners, sprite)
		end
		-- Every place in the order takes its share of the round, acting or not.
		EEex_Utility_TryIgnore(advanceClock)
		B24TB.index = B24TB.index + 1
	end
end

-- The mode switched off in a fight keeps its order (B24TB.kept): switched on again in the same
-- fight (one of its creatures still in sight), the order goes on where it stopped, with the round
-- and the initiative rolled before; newcomers roll as they join (addNewcomers).
local function keptOrder()
	local kept = B24TB.kept
	B24TB.kept = nil
	if kept == nil then return nil end
	local inSight = {}
	for _, enemy in ipairs(enemiesInSight()) do inSight[enemy.m_id] = true end
	local order, same = {}, false
	for _, entry in ipairs(kept.order) do
		local sprite = B24.GetSprite(entry.id)
		if sprite and not isDead(sprite) then
			table.insert(order, entry)
			same = same or inSight[entry.id] == true
		end
	end
	if not same then return nil end
	-- The turn that was running starts over (its creature hadn't finished it).
	local index = math.min(kept.index, #order + 1) - 1
	for i, entry in ipairs(order) do
		if entry.id == kept.turnId then index = i - 1 break end
	end
	return order, kept.round, math.max(0, index)
end

local function startCombat()
	local order, round, index = keptOrder()
	if order then
		B24.Log(string.format("Turn-based combat again, round %d. Initiative: %s", round, listOrder(order)))
	else
		order, round, index = {}, 1, 0
		for _, member in ipairs(B24.Party()) do
			if not isDead(member) then table.insert(order, rollInitiative(member)) end
		end
		for _, enemy in ipairs(enemiesInSight()) do table.insert(order, rollInitiative(enemy)) end
		sortOrder(order)
		B24.Log("Turn-based combat. Initiative: " .. listOrder(order))
	end
	B24TB.active, B24TB.order, B24TB.pending, B24TB.round, B24TB.index = true, order, {}, round, index
	B24TB.idleUntil = nil
	B24.CombatStarted()
	grantEndTurn(true)
	nextTurn()
end

-- keep: the mode was switched off mid-fight, the order is kept for when it comes back on.
function B24TB.Stop(why, keep)
	if not B24TB.active then return end
	B24TB.kept = keep and { order = B24TB.order, round = B24TB.round, index = B24TB.index,
		turnId = B24TB.turn and B24TB.turn.id } or nil
	B24TB.active, B24TB.turn, B24TB.resolving = false, nil, nil
	freeze(nil)
	grantEndTurn(false)
	if B24RD and B24RD.EndTurns then B24RD.EndTurns() end
	B24.Log("Combat ends" .. (why and (" (" .. why .. ")") or ""))
end

--------------------
-- Bonus actions --
--------------------

-- A turn is one action and one bonus action (and the movement of B24ROUND.lua). A bonus action
-- doesn't end the turn; a second one in the same turn counts as the action. Action Surge gives
-- one more action. Bonus actions are the mod's innates below and the spells named below (their
-- BG versions and the mod's own, also the innate copies of B24.InnateCopy).
B24TB.BONUS_INNATES = {
	B24RAGE = true, B24SWIND = true, B24CUNNG = true, B24BINSP = true, B24FLURY = true, B24PDEF = true,
	B24STEPW = true, B24LOH = true, B24STAIM = true, B24INSOR = true, B24INSO2 = true, B24FOM1 = true,
	B24FOM2 = true, B24FOM3 = true, B24FOM4 = true, B24FOM5 = true, B24HMARK = true, B24SMITE = true,
	B24STARC = true, B24STCHL = true, B24STDRG = true, B24STARW = true, B24MSSTP = true, B24WHOLE = true,
	B24WPRST = true, B24SWRAT = true, B24INTIM = true, B24PBULW = true, B24GTELE = true, B24GDURB = true,
	B24GMANT = true, B24GMAJE = true, B24MRALY = true, B24MCOMM = true, B24NVEIL = true, B24VANGL = true,
	B24GLEGD = true, B24AELDR = true, B24NIMBS = true, B24ZPRES = true, B24ZWARG = true, B24DRWNG = true,
	B24AREVL = true, B24CTRAN = true, B24TDUPL = true, B24THEYE = true, B24NMAGI = true, B24WTTRV = true,
}
B24TB.BONUS_SPELLS = {
	["Healing Word"] = true, ["Mass Healing Word"] = true, ["Misty Step"] = true, ["Spiritual Weapon"] = true,
	["Shield of Faith"] = true, ["Sanctuary"] = true, ["Hunter's Mark"] = true, ["Hex"] = true,
	["Divine Favor"] = true, ["Expeditious Retreat"] = true, ["Flame Blade"] = true, ["Shillelagh"] = true,
	["Magic Weapon"] = true, ["Searing Smite"] = true, ["Thunderous Smite"] = true, ["Wrathful Smite"] = true,
	["Branding Smite"] = true, ["Blinding Smite"] = true, ["Staggering Smite"] = true, ["Banishing Smite"] = true,
	["Ensnaring Strike"] = true, ["Hail of Thorns"] = true, ["Compelled Duel"] = true, ["Swift Quiver"] = true,
	["Lightning Arrow"] = true, ["Zephyr Strike"] = true, ["Spirit Shroud"] = true, ["Shadow Blade"] = true,
	["Holy Weapon"] = true, ["Divine Smite"] = true,
}
B24TB.ACTION_SURGE = "B24ASURG"

-- Innates that cost nothing on a turn: the level-up choices (choosing doesn't act) and End Turn.
-- Class files add their own (the Wild Shape list, B24DRUID.lua).
B24TB.FREE_INNATES = {
	B24TEND = true, B24ASI = true, B24PICK = true, B24OPTN = true, B24CANTP = true, B24SUBC = true,
	B24FSTY = true, B24WMAS = true, B24EXPRT = true, B24SPBK = true,
}

local bonusCache = {}
function B24TB.IsBonusAction(res)
	if res == nil then return false end
	res = res:upper()
	if bonusCache[res] ~= nil then return bonusCache[res] end
	local original = (B24.OriginalSpellRes and B24.OriginalSpellRes(res) or res):upper()
	local bonus = B24TB.BONUS_INNATES[res] == true or B24TB.BONUS_INNATES[original] == true
	if not bonus then
		local ok, name = pcall(function() return Infinity_FetchString(EEex_Resource_Demand(original, "SPL").genericName) end)
		bonus = ok and B24TB.BONUS_SPELLS[name] == true
	end
	bonusCache[res] = bonus
	return bonus
end

-- A spell or innate starts on someone's turn: a bonus action (the first of the turn), Action Surge,
-- or the turn's action.
table.insert(B24.SpellCastListeners, function(sprite, res)
	local turn = B24TB.active and B24TB.turn
	if not turn or turn.id ~= sprite.m_id then return end
	-- Free: aimed darts and rays (B24SPELL.lua) and the innates above cost nothing.
	if B24TB.FREE_INNATES[res:upper()] or (B24SP and B24SP.FREE_INNATES and B24SP.FREE_INNATES[res:upper()]) then
		turn.current = "free"
		return
	end
	if res:upper() == B24TB.ACTION_SURGE then
		turn.current = "surge"
	elseif not turn.bonusUsed and B24TB.IsBonusAction(res) then
		turn.current = "bonus"
	elseif turn.spellCast and (turn.extraActions or 0) == 0 then
		-- A second spell as the action (an AI script queues them back to back, with no idle frame
		-- for the turn to end in): the turn's action is spent, the next frame stops it.
		turn.cancel = true
	else
		turn.current = nil
		turn.started = true
		turn.spellCast = res:upper()
	end
end)

-- Whether the current turn is over (sampled every frame, so no swing is missed).
-- Movement (MoveToObject, MoveToPoint and their variants): for a party member it doesn't end the
-- turn, the action is still to come (the round's movement limit, B24ROUND.lua, holds).
B24TB.RESOLVE_TICKS = 20
B24TB.PROJECTILE_WAIT_TICKS = 90
B24TB.MOVE_ACTIONS = { [22] = true, [23] = true, [90] = true, [107] = true, [180] = true, [207] = true, [208] = true }
-- Attack, GroupAttack, AttackNoSound, AttackReevaluate.
B24TB.ATTACK_ACTIONS = { [3] = true, [94] = true, [98] = true, [134] = true }

-- The end of an action: Time Stop freezes the acting creature's own missiles too, and a frozen
-- creature takes no damage and plays no hit or death animation until it moves again (TurnProbe's
-- missile probe: Magic Missile's darts stayed on the caster, and a dart handed the Time Stop hit a
-- frozen wolf without damage). So once the action is over the freeze is lifted for a moment
-- (B24TB.resolving): missiles fly, damage lands, the hit and dying animations play; everyone else
-- in the fight is held (its actions cleared every frame, B24TB.Frame), so no one acts out of turn.
local function resolve(on, sprite)
	B24TB.resolving = on or nil
	freeze(not on and sprite or nil)
end

-- Whether a projectile of the creature is still in the area (a missile in flight, a ray, an arrow).
local function projectileInFlight(sprite)
	local area = sprite.m_pArea
	if area == nil then return false end
	local found = false
	for _, list in ipairs({ area.m_lVertSortFlight, area.m_lVertSortFlightAdd, area.m_lVertSort, area.m_lVertSortAdd }) do
		EEex_Utility_IterateCPtrList(list, function(id)
			local object = EEex_GameObject_Get(id)
			local ok, source = pcall(function() return object.m_sourceId end)
			found = ok and source == sprite.m_id and object.m_objectType ~= CGameObjectType.SPRITE
			return found
		end)
		if found then return true end
	end
	return false
end

-- A party member's turn has no time limit while it waits for orders: it ends when its action is
-- done or with End Turn. Only an action that has started runs against the clock (a stuck one).
-- Other creatures lose the turn after a while either way.
local function turnDone(sprite, turn, now)
	if cannotAct(sprite) or turn.endRequested then return true end
	local party = playerControls(sprite)
	local action = sprite.m_curAction.m_actionID
	-- The action is over and the turn only waits for it to play out: the AI (or a click) starts
	-- nothing more (an enemy wizard cast Mirror Image, then Haste in the wait).
	if action ~= 0 and (turn.ending or turn.cancel) then
		if turn.cancel then B24.Log(string.format("%s: no second action this turn", B24.Name(sprite))) end
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", sprite)
		turn.cancel, action = nil, 0
	end
	if action ~= 0 then
		turn.lastAction = action
		turn.actionStart = turn.actionStart or now
	end
	-- A bonus action, or Action Surge, keeps the turn going (turn.current is set when the spell or
	-- innate starts, see the cast listener below: an instant one may start and end between frames).
	if action == 0 and turn.current then
		-- The bonus action (or Action Surge) is done: the turn goes on, its action still to come.
		if turn.current == "bonus" then
			turn.bonusUsed = true
			B24.Log(string.format("%s: bonus action used", B24.Name(sprite)))
		elseif turn.current == "free" then
			-- A free innate (an aimed dart or ray, a choice, the Wild Shape list): nothing used.
		else
			turn.extraActions = (turn.extraActions or 0) + 1
			B24.Log(string.format("%s: Action Surge, one more action", B24.Name(sprite)))
		end
		turn.current = nil
		turn.start, turn.actionStart, turn.idleFrom = now, nil, nil
		return false
	end
	if action ~= 0 and not turn.current then turn.started = true end
	if sprite.m_startedSwing ~= 0 and turn.lastSwing == 0 then turn.swings = turn.swings + 1 end
	turn.lastSwing = sprite.m_startedSwing
	local frame = sprite.m_attackFrame
	local wrapped = frame < turn.lastFrame
	turn.lastFrame = frame
	-- The action is over: it plays out unfrozen (resolve: RESOLVE_TICKS, longer while its missiles
	-- fly, at most PROJECTILE_WAIT_TICKS: a lasting cloud doesn't hold the turn), then the turn ends,
	-- unless Action Surge left another action.
	local function actionOver()
		if not turn.ending then
			turn.ending, turn.resolveFrom = true, now
			resolve(true)
		end
		local elapsed = now - turn.resolveFrom
		if elapsed < B24TB.RESOLVE_TICKS then return false end
		if projectileInFlight(sprite) then
			if elapsed < B24TB.PROJECTILE_WAIT_TICKS then return false end
			B24.Log(string.format("%s: missiles still in the air after %d ticks, the turn passes", B24.Name(sprite),
				B24TB.PROJECTILE_WAIT_TICKS))
		end
		turn.ending, turn.resolveFrom, turn.spellCast, turn.inFlight = nil, nil, nil, nil
		resolve(false, sprite)
		if (turn.extraActions or 0) == 0 then return true end
		turn.extraActions = turn.extraActions - 1
		turn.started, turn.swings, turn.start, turn.actionStart, turn.idleFrom = false, 0, now, nil, nil
		return false
	end
	if turn.ending then return actionOver() end
	-- Darts or rays still to aim (B24SPELL.lua): the turn waits for them (for other creatures the
	-- turn's time limit holds).
	if B24SP and B24SP.HasVolley and B24SP.HasVolley(sprite) and action == 0
		and (party or now - turn.start <= B24TB.TURN_TICKS) then
		return false
	end
	if turn.swings > 0 and wrapped then
		turn.overWhy = turn.overWhy or "swing done"
		return actionOver()
	end
	if turn.started and action == 0 then
		if party and B24TB.MOVE_ACTIONS[turn.lastAction] then
			turn.started, turn.actionStart, turn.lastAction = false, nil, nil
			return false
		end
		-- An attack that ended before its first swing: AttackReevaluate (most AI scripts) ends every
		-- few ticks for the script to look again, and the script picks the next action. The turn
		-- goes on until a swing or its time limit (it isn't idle: the AI did start something).
		if not party and turn.swings == 0 and B24TB.ATTACK_ACTIONS[turn.lastAction] then
			-- Back to waiting for the AI's next action: not started (otherwise the next idle frame
			-- counted as the end of an action, and the turn ended anyway, with whatever came next
			-- cleared, e.g. a queued spell), the idle limit counting from now.
			turn.lastAction, turn.started, turn.actionStart, turn.idleFrom = nil, false, nil, now
			return now - turn.start > B24TB.TURN_TICKS
		end
		-- Why the action counts as over (read by the in-game test's trace).
		turn.overWhy = turn.overWhy or string.format("action %s done (spell cast %s)", tostring(turn.lastAction),
			tostring(turn.spellCast))
		return actionOver()
	end
	if party then
		if turn.actionStart and now - turn.actionStart > B24TB.TURN_TICKS then return true end
	elseif now - turn.start > B24TB.TURN_TICKS then
		return true
	end
	if not turn.started and not party and now - (turn.idleFrom or turn.start) > B24TB.AI_IDLE_TICKS then return true end
	return false
end

---------------
-- Reactions --
---------------

-- Every creature has one reaction per round. Party members are asked (a short prompt, the game
-- paused; B24.Config.reactionPrompts = false: always yes); other creatures always react.
B24TB.reacted = {}     -- [id] = round of the last reaction
B24TB.questions = {}   -- prompts waiting to be shown
B24TB.REACH_NEAR = B24.ADJACENT  -- 5 ft: B24.Adjacent's melee distance
B24TB.REACH_FAR = B24.ADJACENT + B24.Feet(5) - 16  -- 10 ft: a 2024 Reach weapon (B24WEAP.2DA REACH)
B24TB.TELEPORT = 60    -- farther in one frame: a teleport, which provokes nothing

function B24TB.CanReact(sprite)
	return not cannotAct(sprite) and B24TB.reacted[sprite.m_id] ~= B24TB.round
end

function B24TB.UseReaction(sprite)
	B24TB.reacted[sprite.m_id] = B24TB.round
end

local function isPaused()
	local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	return ok and (paused == true or paused == 1)
end

-- The prompt: the game's own two- or three-button popup (BG1 and BG2 look), choices then No.
local POPUPS = { "POPUP_TWOBUTTON", "POPUP_THREEBUTTON" }

local function showNextQuestion()
	if B24TB.asking or #B24TB.questions == 0 then return end
	local q = table.remove(B24TB.questions, 1)
	B24TB.asking = q
	if not isPaused() then
		EEex_GameState_TogglePause(false, false)
		q.pausedHere = true
	end
	-- Labels that are not UI string keys show as they are (registered, so the UI logs nothing).
	for _, choice in ipairs(q.choices) do
		if uiStrings and uiStrings[choice.label] == nil then uiStrings[choice.label] = choice.label end
	end
	local function pick(i) return function() B24TB.Answer(i) end end
	if #q.choices == 1 then
		popup2Button(q.text, q.choices[1].label, pick(1), "NO_BUTTON", pick(nil))
	else
		popup3Button(q.text, q.choices[1].label, pick(1), q.choices[2].label, pick(2), "NO_BUTTON", pick(nil))
	end
end

-- The answer to the open prompt: the number of the choice taken, nil for No (the popup's buttons;
-- the in-game test answers the same way).
function B24TB.Answer(index)
	local q = B24TB.asking
	if q == nil then return end
	B24TB.asking = nil
	for _, menu in ipairs(POPUPS) do
		if Infinity_IsMenuOnStack(menu) then Infinity_PopMenu(menu) end
	end
	local choice = index and q.choices[index]
	if choice then EEex_Utility_TryIgnore(choice.fn) elseif q.no then EEex_Utility_TryIgnore(q.no) end
	if q.pausedHere and #B24TB.questions == 0 and isPaused() then EEex_GameState_TogglePause(false, false) end
	if #B24TB.questions > 0 and q.pausedHere then B24TB.questions[1].pausedHere = true end
	showNextQuestion()
end

-- A reaction of a party member is asked first; others take the first choice at once.
-- choices = { { label, fn }, ... } (one or two); onNo (optional) runs when declined.
function B24TB.ReactChoice(reactor, text, choices, onNo)
	if B24.InParty(reactor) and B24.Config.reactionPrompts ~= false then
		table.insert(B24TB.questions, { text = text, choices = choices, no = onNo, reactor = reactor.m_id })
		showNextQuestion()
	else
		EEex_Utility_TryIgnore(choices[1].fn)
	end
end

function B24TB.React(reactor, text, onYes, onNo)
	B24TB.ReactChoice(reactor, text, { { label = "YES_BUTTON", fn = onYes } }, onNo)
end

local function head(sprite, key)
	local ref = B24.HeadText and B24.HeadText[key]
	if ref then EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format("DisplayStringHead(Myself,%d)", ref), sprite) end
end

-- Opportunity Attacks: a creature that leaves an enemy's reach on its turn (moving; not by
-- teleport, not after Disengage, not unseen) gets attacked by it, if that enemy has its reaction
-- and a melee weapon (or fights unarmed).
local function reachOf(sprite)
	local equipment = sprite.m_equipment
	local item = equipment.m_items:get(equipment.m_selectedWeapon)
	local ability = item and item:getAbility(equipment.m_selectedWeaponAbility)
	if ability and ability.type ~= 1 then return nil end
	local profType = B24.SelectedWeaponProfType and B24.SelectedWeaponProfType(sprite)
	local weapon = profType and B24.Weapons and B24.Weapons[tostring(profType)]
	return (weapon and tonumber(weapon.REACH) == 1) and B24TB.REACH_FAR or B24TB.REACH_NEAR
end
B24TB.ReachOf = reachOf

local function distance(a, b)
	local dx, dy = a.m_pos.x - b.m_pos.x, a.m_pos.y - b.m_pos.y
	return math.sqrt(dx * dx + dy * dy)
end

local function unseen(sprite)
	local g = B24.GState
	return B24.GState_Has(sprite, g.INVISIBLE) or B24.GState_Has(sprite, g.IMPROVEDINVISIBILITY)
end

function B24TB.OpportunityAttack(reactor, mover)
	B24TB.UseReaction(reactor)
	head(reactor, "OPPORTUNITY")
	B24WPN.ScriptedAttack(reactor, mover, "Opportunity Attack")
end

local function watchReach(mover, turn)
	local x, y = mover.m_pos.x, mover.m_pos.y
	local jumped = turn.lastX ~= nil and ((x - turn.lastX) ^ 2 + (y - turn.lastY) ^ 2) > B24TB.TELEPORT ^ 2
	turn.lastX, turn.lastY = x, y
	local before, now = turn.inReach or {}, {}
	local free = jumped or B24.HasTimed(mover, "DISENGAGE") or unseen(mover)
	for _, reactor in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(mover, "[ENEMY]", 400, false) or {}) do
		local reach = reactor.m_id ~= mover.m_id and not isDead(reactor) and reachOf(reactor)
		if reach then
			if distance(reactor, mover) <= reach then
				now[reactor.m_id] = true
			elseif before[reactor.m_id] and not free and B24TB.CanReact(reactor) then
				local r, m = reactor, mover
				-- Taken now, so a second step out of reach in the same moment asks nothing more.
				B24TB.UseReaction(r)
				B24TB.React(r, string.format("%s: Opportunity Attack on %s?", B24.Name(r), B24.Name(m)), function()
					if not isDead(m) then B24TB.OpportunityAttack(r, m) end
				end, function()
					-- Declined: the reaction stays.
					B24TB.reacted[r.m_id] = nil
				end)
			end
		end
	end
	turn.inReach = now
end

-- Reactions to a weapon hit on another creature's turn, decided once the damage is in (the hit
-- points it took come back as far as the reaction undoes it):
--   Shield (a memorized Shield, SPWI114): +5 AC for the round; the engine doesn't tell its d20
--     roll, so a hit with chance p would have missed with 25 points of it (p - 25 at +5 AC);
--   Uncanny Dodge (Rogue 5): half the damage.
B24TB.SHIELD = "SPWI114"
B24TB.pendingHits = {}

local function shieldReady(sprite)
	return B24SP ~= nil and B24SP.SpendSpell ~= nil and B24SP.SpendSpell(sprite, true, 1, B24TB.SHIELD, true)
end

local function canDodge(sprite)
	return B24LV ~= nil and B24LV.ClassLevel(sprite, "ROGUE") >= 5
end

table.insert(B24WPN.DamageListeners, function(context)
	local target, attacker = context.target, context.attacker
	local turn = B24TB.active and B24TB.turn
	if not turn or turn.id == target.m_id or not B24.InParty(target) or not B24TB.CanReact(target) then return end
	if not (shieldReady(target) or canDodge(target)) then return end
	local ok, chance = pcall(B24.HitChance, attacker, target, context.weapon)
	chance = (ok and chance and chance > 0) and chance or 50
	table.insert(B24TB.pendingHits, { target = target.m_id, attacker = attacker.m_id, hp = target.m_baseStats.m_hitPoints,
		tick = B24.GameTick(), shieldMisses = math.random() * chance < 25 })
end)

local function askHitReactions()
	local now = B24.GameTick()
	local kept = {}
	for _, hit in ipairs(B24TB.pendingHits) do
		local target, attacker = B24.GetSprite(hit.target), B24.GetSprite(hit.attacker)
		if now <= hit.tick then
			table.insert(kept, hit)
		elseif target and attacker and not isDead(target) and B24TB.CanReact(target) then
			local damage = hit.hp - target.m_baseStats.m_hitPoints
			local choices = {}
			if damage > 0 and shieldReady(target) then
				table.insert(choices, { label = "Shield", fn = function()
					B24SP.SpendSpell(target, true, 1, B24TB.SHIELD)
					B24.ApplyEffect(target, { ["effectID"] = 0, ["effectAmount"] = 5, ["durationType"] = 0, ["duration"] = 6 })
					if hit.shieldMisses then B24.Heal(target, damage) end
					B24.Log(string.format("%s: Shield (+5 AC)%s", B24.Name(target), hit.shieldMisses and ", the hit misses" or ""))
				end })
			end
			if damage > 1 and canDodge(target) then
				table.insert(choices, { label = "Uncanny Dodge", fn = function()
					B24.Heal(target, math.floor(damage / 2))
					B24.Log(string.format("%s: Uncanny Dodge, %d damage less", B24.Name(target), math.floor(damage / 2)))
				end })
			end
			if #choices > 0 then
				B24TB.UseReaction(target)
				B24TB.ReactChoice(target, string.format("%s is hit by %s for %d damage. Reaction?", B24.Name(target),
					B24.Name(attacker), damage), choices, function() B24TB.reacted[target.m_id] = nil end)
			end
		end
	end
	B24TB.pendingHits = kept
end

-- While an action plays out unfrozen (resolve): no one else near starts anything, in the order or
-- not yet (a creature that just came into sight joins it on the next AI update; a spawned gnoll
-- took steps in the window).
B24TB.HOLD_RANGE = 2 * B24TB.SIGHT
local function holdOthers(actor)
	local area = actor.m_pArea
	if area == nil then return end
	local x, y = actor.m_pos.x, actor.m_pos.y
	EEex_Utility_IterateCPtrList(area.m_lVertSort, function(id)
		local other = id ~= actor.m_id and EEex_GameObject_Get(id)
		if other and B24.IsSprite(other) and not isDead(other) and other.m_curAction.m_actionID ~= 0 then
			local dx, dy = other.m_pos.x - x, other.m_pos.y - y
			if dx * dx + dy * dy <= B24TB.HOLD_RANGE * B24TB.HOLD_RANGE then
				EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", other)
			end
		end
	end)
end

-- A missile of the acting creature is out (an arrow from its bow, a bolt): the freeze is lifted
-- while it flies (it would hang in the air until the action is over), the others held as in the
-- resolve window.
local function watchFlight(sprite, turn)
	if turn.ending then return end
	local flying = projectileInFlight(sprite)
	if flying and not B24TB.resolving then
		turn.inFlight = true
		resolve(true)
	elseif not flying and turn.inFlight then
		turn.inFlight = nil
		resolve(false, sprite)
	end
end

-- The dead leave the order at once (the bar shows the living); the place of the current turn
-- stays where it is.
local function pruneDead()
	local order, kept = B24TB.order or {}, {}
	for i, entry in ipairs(order) do
		local sprite = B24.GetSprite(entry.id)
		if sprite and not isDead(sprite) then
			table.insert(kept, entry)
		elseif i <= B24TB.index then
			B24TB.index = B24TB.index - 1
		end
	end
	if #kept ~= #order then B24TB.order = kept end
end

-- Off the game screen (the record, the inventory, the game menu) a turn-based fight stands still:
-- the game is paused while another screen is up and goes on when the game screen is back (unless
-- it was paused before). The turns are only taken on the game screen.
local function pauseOffScreen()
	if not B24TB.active then
		B24TB.pausedOffScreen = nil
		return false
	end
	if not onGameScreen() then
		if not B24TB.pausedOffScreen and not isPaused() then
			EEex_GameState_TogglePause(false, false)
			B24TB.pausedOffScreen = true
		end
		return true
	end
	if B24TB.pausedOffScreen then
		B24TB.pausedOffScreen = nil
		if isPaused() then EEex_GameState_TogglePause(false, false) end
	end
	return false
end

-- Every frame (the portraits ask for the number of characters on most screens). Not again from
-- inside itself: engine calls made here (a selection) can draw the portraits again.
function B24TB.Frame()
	if B24TB.inFrame then return end
	B24TB.inFrame = true
	local ok, err = pcall(B24TB.FrameBody)
	B24TB.inFrame = nil
	if not ok then error(err) end
end

function B24TB.FrameBody()
	if pauseOffScreen() then return end
	-- Outside the fight (and in scenes, during a real Time Stop) effect time runs with the clock.
	-- In a round no one can act in, the skipped turns have moved it on by the round already.
	if not B24TB.active or B24TB.suspended then B24TB.clockAt = nil end
	if not B24TB.active or B24TB.suspended or B24TB.asking then return end
	EEex_Utility_TryIgnore(holdClock)
	if #B24TB.pendingHits > 0 then EEex_Utility_TryIgnore(askHitReactions) end
	local turn = B24TB.turn
	if turn == nil then return end
	local sprite = B24.GetSprite(turn.id)
	EEex_Utility_TryIgnore(pruneDead)
	if sprite and not isDead(sprite) then
		EEex_Utility_TryIgnore(watchFlight, sprite, turn)
		if B24TB.resolving then EEex_Utility_TryIgnore(holdOthers, sprite) end
		EEex_Utility_TryIgnore(watchReach, sprite, turn)
	end
	-- A party member's turn: the selection stays on it alone.
	if sprite and playerControls(sprite) and not turn.ending then EEex_Utility_TryIgnore(selectOnly, sprite) end
	if sprite == nil or turnDone(sprite, turn, B24.GameTick()) then
		if sprite and not isDead(sprite) then notify(B24TB.TurnEndListeners, sprite) end
		-- The action ends with the turn (an attack doesn't go on into the next one, where it would
		-- start mid-swing): the next turn starts with a new order, or for other creatures with what
		-- their AI picks then.
		if sprite and not isDead(sprite) then
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", sprite)
		end
		EEex_Utility_TryIgnore(advanceClock)
		nextTurn()
	end
end

-- Every AI update (global script hook): starts and ends combat, keeps the freeze up.
-- Party AI (the lantern button) gives party members orders of its own every round: off while
-- turn-based combat is on, back on when it is switched off if it was on before (global B24_TBAI,
-- saved with the game).
B24TB.AI_GLOBAL = "B24_TBAI"
-- The UI's global game object (game() above is the engine's CInfGame and has no party AI calls;
-- the local name hid the global, so the switch never ran).
local uiGame = function() return _G.game end

function B24TB.PartyAI(restore)
	local ok, aiOn = pcall(function() return uiGame():GetPartyAI() end)
	if not ok then
		if not B24TB.aiWarned then B24.Log("Turn-based combat: party AI can't be switched: " .. tostring(aiOn)) end
		B24TB.aiWarned = true
		return
	end
	if restore then
		if EEex_GameState_GetGlobalInt(B24TB.AI_GLOBAL) == 1 then
			EEex_GameState_SetGlobalInt(B24TB.AI_GLOBAL, 0)
			if not aiOn then pcall(function() uiGame():ToggleAI() end) end
		end
	elseif aiOn then
		pcall(function() uiGame():ToggleAI() end)
		EEex_GameState_SetGlobalInt(B24TB.AI_GLOBAL, 1)
		B24.Log("Turn-based combat: party AI off")
	end
end

function B24TB.Tick()
	if worldScreen == nil or e:GetActiveEngine() ~= worldScreen then return end
	if not B24TB.loadChecked then
		B24TB.loadChecked = true
		B24TB.AfterLoad()
	end
	local wasEngaged = B24TB.engaged
	B24TB.engaged = B24TB.active or #enemiesInSight() > 0
	-- "Always Start Turn-Based" (B24OPT.lua): as a fight begins, the mode switches on by itself;
	-- switched back to real time, it stays so for the rest of that fight.
	if B24.Config.alwaysTurnBased and B24.Config.turnBased ~= false and B24TB.engaged and not wasEngaged
		and B24.InNormalPlay() and EEex_GameState_GetGlobalInt(B24TB.GLOBAL) ~= 1 then
		EEex_GameState_SetGlobalInt(B24TB.GLOBAL, 1)
		B24.Log("Turn-based combat: on (the fight began; Always Start Turn-Based)")
	end
	if not B24TB.Enabled() then
		B24TB.Stop("turn-based combat switched off", true)
		B24TB.PartyAI(true)
		return
	end
	B24TB.PartyAI(false)
	if not B24.InNormalPlay() then
		-- Dialogs and cutscenes in real time.
		if B24TB.active and not B24TB.suspended then
			B24TB.suspended = "scene"
			freeze(nil)
		end
		return
	end
	local g = game()
	if B24TB.active and B24TB.caster and g.m_nTimeStop > 0 and g.m_nTimeStopCaster ~= B24TB.caster then
		-- Someone cast a real Time Stop: it runs its course first.
		B24TB.suspended, B24TB.caster = "time stop", nil
		return
	end
	if B24TB.suspended then
		if B24TB.suspended == "time stop" and g.m_nTimeStop > 0 then return end
		B24TB.suspended = nil
		local sprite = B24TB.turn and B24.GetSprite(B24TB.turn.id)
		if sprite then freeze(sprite) end
	end
	if not B24TB.active then
		if #enemiesInSight() > 0 then startCombat() end
		return
	end
	if #enemiesInSight() == 0 then
		B24TB.Stop()
		return
	end
	addNewcomers()
	local sprite = B24TB.turn and B24.GetSprite(B24TB.turn.id)
	if sprite and B24TB.resolving then
		-- An action playing out (resolve): no freeze until it is done.
	elseif sprite then
		freeze(sprite)
		if B24RD and B24RD.TrackTurn then B24RD.TrackTurn(sprite) end
	elseif B24.GameTick() >= (B24TB.idleUntil or 0) then
		nextTurn()
	end
end

-- After a load: a freeze from before the save belongs to no turn any more.
function B24TB.AfterLoad()
	if B24TB.active then return end
	local g = game()
	local caster = g.m_nTimeStopCaster ~= -1 and B24.GetSprite(g.m_nTimeStopCaster)
	if caster and caster:getLocalInt("B24TBACT") == 1 then
		caster:setLocalInt("B24TBACT", 0)
		freeze(nil)
	end
end

--------------
-- Innates --
--------------

-- Turn-Based Combat (protagonist): switches the mode on or off.
function B24TURNS(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local on = EEex_GameState_GetGlobalInt(B24TB.GLOBAL) ~= 1
		EEex_GameState_SetGlobalInt(B24TB.GLOBAL, on and 1 or 0)
		B24.Log(on and "Turn-based combat: on" or "Turn-based combat: off")
		if not on then B24TB.Stop("turn-based combat switched off", true) end
	end)
end

-- End Turn (party members in combat).
function B24TEND(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local turn = B24TB.turn
		if turn and turn.id == sprite.m_id then turn.endRequested = true end
	end)
end

-- Portrait icon on the party member whose turn it is.
B24.AddIconListener(function(sprite, keys)
	if B24TB.active and B24TB.turn and B24TB.turn.id == sprite.m_id then keys.TURN = true end
end)

local originalHasPendingScreens = B24_HasPendingScreens
function B24_HasPendingScreens()
	EEex_Utility_TryIgnore(B24TB.Tick)
	return originalHasPendingScreens()
end

-- The switch on the game screen (B24TURN.menu), the only one (B24TURNS). Under it End Turn, while
-- a party member has its turn.
-- The button says what a click does (the mode it switches to); the tooltip says the mode now. It
-- is there only while the party is engaged (enemies in sight, or a turn-based fight running;
-- B24TB.engaged, set by B24TB.Tick).

function B24TB.ButtonShown()
	return B24TB.engaged == true and onGameScreen()
end

function B24TB.ButtonText()
	return B24TB.Enabled() and "Switch to Real-Time" or "Switch to Turn-Based"
end

function B24TB.ButtonTooltip()
	return B24TB.Enabled()
		and "Combat is turn-based now. Switched back during this fight, the initiative order goes on where it stopped."
		or "Combat is real-time now. Turn-based: initiative, one creature acts at a time."
end

function B24TB.ToggleButton()
	local protagonist = B24.Protagonist()
	if protagonist then B24TURNS(nil, protagonist) end
end

local function partyTurnSprite()
	local turn = B24TB.active and not B24TB.suspended and B24TB.turn
	local sprite = turn and B24.GetSprite(turn.id) or nil
	return sprite ~= nil and B24.InParty(sprite) and sprite or nil
end

function B24TB.EndTurnShown()
	return partyTurnSprite() ~= nil and onGameScreen()
end

function B24TB.EndTurnText()
	local sprite = partyTurnSprite()
	return sprite and ("End Turn: " .. B24.Name(sprite)) or ""
end

function B24TB.EndTurnButton()
	local sprite = partyTurnSprite()
	if sprite then B24TEND(nil, sprite) end
end

-- Initiative bar (B24TURN.menu): the round, then the initiative order as it stands (up to ten
-- places; with more, the ten that include the current turn). The gold frame marks whose turn it is.
local function trackerStart()
	local order, index = B24TB.order or {}, B24TB.index or 1
	return math.max(1, math.min(index - 9, #order - 9))
end

local function trackerEntry(i)
	if not B24TB.active or B24TB.suspended or not onGameScreen() then return nil end
	return (B24TB.order or {})[trackerStart() + i - 1]
end

local function trackerSprite(i)
	local entry = trackerEntry(i)
	return entry and B24.GetSprite(entry.id) or nil
end

function B24TB.TrackerShown(i) return trackerEntry(i) ~= nil end
function B24TB.TrackerCurrent(i)
	return B24TB.turn ~= nil and trackerEntry(i) ~= nil and trackerStart() + i - 1 == B24TB.index
end

function B24TB.TrackerParty(i)
	local sprite = trackerSprite(i)
	return sprite ~= nil and B24.InParty(sprite)
end

function B24TB.TrackerOther(i)
	return trackerEntry(i) ~= nil and not B24TB.TrackerParty(i)
end

function B24TB.TrackerPortrait(i)
	local sprite = trackerSprite(i)
	if sprite == nil or not B24.InParty(sprite) then return "" end
	local ok, res = pcall(function() return sprite.m_baseStats.m_portraitSmall:get() end)
	return ok and res or ""
end

function B24TB.TrackerName(i)
	local entry = trackerEntry(i)
	if entry == nil then return "" end
	local name = entry.name or "?"
	return #name > 10 and (name:sub(1, 9) .. ".") or name
end

-- A note in the middle of a tile without a portrait (marks on the creature: "Marked by Kivan").
-- listener(sprite) returns a line or nil (B24RANGR.lua: Hunter's Mark).
B24TB.TileNoteListeners = {}

function B24TB.TrackerNote(i)
	local sprite = trackerSprite(i)
	if sprite == nil or B24.InParty(sprite) then return "" end
	local lines = {}
	for _, listener in ipairs(B24TB.TileNoteListeners) do
		local ok, line = pcall(listener, sprite)
		if ok and line then table.insert(lines, line) end
	end
	return table.concat(lines, "\n")
end

-- The place in the order (top left of the tile) and the initiative rolled (top right).
function B24TB.TrackerPlace(i)
	return trackerEntry(i) and tostring(trackerStart() + i - 1) or ""
end

function B24TB.TrackerInitiative(i)
	local entry = trackerEntry(i)
	return entry and tostring(entry.total) or ""
end

function B24TB.RoundText()
	return B24TB.active and ("Round " .. B24TB.round) or ""
end

function B24TB.ShowButton()
	if B24.Config.turnBased == false or worldScreen == nil or e:GetActiveEngine() ~= worldScreen then return end
	if not Infinity_IsMenuOnStack("B24_TURNBUTTON") then Infinity_PushMenu("B24_TURNBUTTON") end
	if not Infinity_IsMenuOnStack("B24_TURNTRACKER") then Infinity_PushMenu("B24_TURNTRACKER") end
end

-- The party portraits ask for the number of characters every frame on the game screen.
if Infinity_GetNumCharacters then
	local originalNumCharacters = Infinity_GetNumCharacters
	function Infinity_GetNumCharacters(...)
		EEex_Utility_TryIgnore(B24TB.ShowButton)
		EEex_Utility_TryIgnore(B24TB.Frame)
		return originalNumCharacters(...)
	end
end

-- Loading a save or quitting ends the session: its turns are gone (the freeze is checked again
-- after the next load, see B24TB.AfterLoad).
EEex_GameState_AddDestroyedListener(function()
	B24TB.reacted, B24TB.questions, B24TB.asking, B24TB.pendingHits = {}, {}, nil, {}
	B24TB.active, B24TB.turn, B24TB.caster, B24TB.suspended, B24TB.loadChecked = false, nil, nil, nil, false
	B24TB.idleUntil, B24TB.clockAt, B24TB.clockFraction, B24TB.engaged, B24TB.kept = nil, nil, nil, false, nil
	B24TB.pausedOffScreen, B24TB.inFrame = nil, nil
end)
