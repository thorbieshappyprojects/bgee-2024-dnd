-- BG 2024 Rules Mod: short and long rests, Hit Dice, exhaustion, Heroic Inspiration.
--
-- State is kept in creature locals so it survives saving:
--   B24HDUSE  Hit Dice spent since the last long rest
--   B24EXH    exhaustion level (0-6)
--   B24INSP   1 if the creature has Heroic Inspiration
--   B24SETUP  version of the party setup that has been applied
-- and in one global, since short rests belong to the whole party:
--   B24SRUSE  short rests taken since the last long rest

B24.SHORT_REST_RES = "B24SREST"
B24.SHORT_REST_GLOBAL = "B24SRUSE"
B24.EXHAUSTION_RES = "B24EXH"
B24.SETUP_VERSION = 6

------------------
-- Hit Dice pool --
------------------

function B24.HitDice_Remaining(sprite)
	return math.max(0, B24.Level(sprite) - sprite:getLocalInt("B24HDUSE"))
end

function B24.Heal(sprite, amount)
	if amount > 0 then
		B24.ApplyEffect(sprite, { ["effectID"] = 17, ["effectAmount"] = amount, ["dwFlags"] = 0 })
	end
end

-- Spends Hit Dice until the creature is at full health or out of dice.
function B24.HitDice_Spend(sprite)
	local missing = sprite:getStat(B24.Stat.MAXHP) - sprite.m_baseStats.m_hitPoints
	local remaining = B24.HitDice_Remaining(sprite)
	local die = B24.HitDie(sprite)
	local conMod = B24.AbilityModOf(sprite, "CON")
	local spent, healed = 0, 0
	while healed < missing and spent < remaining do
		healed = healed + math.max(1, B24.Roll(die) + conMod)
		spent = spent + 1
	end
	if spent > 0 then
		sprite:setLocalInt("B24HDUSE", sprite:getLocalInt("B24HDUSE") + spent)
		B24.Heal(sprite, healed)
	end
	return spent, math.min(healed, missing)
end

----------------
-- Exhaustion --
----------------

function B24.Exhaustion_Get(sprite)
	return sprite:getLocalInt("B24EXH")
end

-- Each level: -2 to attack rolls (here) and saves (B24SAVE), slower movement. Level 6 kills.
function B24.Exhaustion_Set(sprite, level)
	level = math.max(0, math.min(6, level))
	sprite:setLocalInt("B24EXH", level)
	B24.RemoveEffectsBySource(sprite, B24.EXHAUSTION_RES)
	if level == 0 then
		B24.Log(string.format("%s is no longer exhausted", B24.Name(sprite)))
		return
	end
	local effect = function(args)
		args.durationType = 1
		args.m_sourceRes = B24.EXHAUSTION_RES
		B24.ApplyEffect(sprite, args)
	end
	effect({ ["effectID"] = 54, ["effectAmount"] = -2 * level, ["dwFlags"] = 0 })
	effect({ ["effectID"] = 176, ["effectAmount"] = 100 - B24.Config.exhaustionSpeedPercent * level, ["dwFlags"] = 5 })
	B24.Log(string.format("%s has exhaustion level %d", B24.Name(sprite), level))
	if level >= 6 then
		B24.ApplyEffect(sprite, { ["effectID"] = 13, ["dwFlags"] = 4 })
	end
end

function B24.Exhaustion_Add(sprite, levels)
	B24.Exhaustion_Set(sprite, B24.Exhaustion_Get(sprite) + (levels or 1))
end

------------------------
-- Heroic Inspiration --
------------------------

function B24.Inspiration_Has(sprite)
	return sprite:getLocalInt("B24INSP") > 0
end

function B24.Inspiration_Grant(sprite)
	if not B24.Inspiration_Has(sprite) then
		sprite:setLocalInt("B24INSP", 1)
		B24.Log(string.format("%s gains Heroic Inspiration", B24.Name(sprite)))
	end
end

-- Consumes inspiration; returns true if there was one to use.
function B24.Inspiration_Use(sprite)
	if not B24.Inspiration_Has(sprite) then return false end
	sprite:setLocalInt("B24INSP", 0)
	return true
end

----------------
-- Short rest --
----------------

local function enemiesNear(sprite)
	local enemies = EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[ENEMY]", B24.Config.shortRestEnemyRange, true)
	return enemies ~= nil and #enemies > 0
end

-- The protagonist (Player1) carries the party's Short Rest innate.
function B24.Protagonist()
	local sprite = EEex_GameObject_Get(EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_characters:get(0))
	return B24.IsSprite(sprite) and sprite or nil
end

function B24.ShortRests_Remaining()
	return math.max(0, B24.Config.shortRestsPerLongRest - EEex_GameState_GetGlobalInt(B24.SHORT_REST_GLOBAL))
end

-- A short rest for the whole party (an hour): everyone spends Hit Dice until healed (or out of
-- them), and the features that come back on a short rest do (B24.ShortRestListeners). Refused
-- messages show in the message log, not only in the verbose one.
function B24.ShortRest(sprite)
	sprite = sprite or B24.Protagonist()
	if sprite == nil then return end
	if B24.ShortRests_Remaining() <= 0 then
		Infinity_DisplayString("BG2024: The party has no short rests left; take a long rest")
		return
	end
	-- Not in a fight: enemies near, or a turn-based fight running (B24TURN.lua; its enemies can
	-- stand farther off than shortRestEnemyRange).
	if enemiesNear(sprite) or (B24TB and (B24TB.active or B24TB.engaged)) then
		Infinity_DisplayString("BG2024: You cannot take a short rest during a fight")
		return
	end
	EEex_GameState_SetGlobalInt(B24.SHORT_REST_GLOBAL, EEex_GameState_GetGlobalInt(B24.SHORT_REST_GLOBAL) + 1)
	local left = B24.ShortRests_Remaining()
	B24.Log(string.format("The party takes a short rest (%d left until the next long rest)", left))
		for _, member in ipairs(B24.Party()) do
			if not B24.GState_Has(member, B24.GState.DEAD) then
				local spent, healed = B24.HitDice_Spend(member)
				if spent > 0 then
					B24.Log(string.format("%s spends %d Hit %s and regains %d HP (%d left)", B24.Name(member), spent,
						spent == 1 and "Die" or "Dice", healed, B24.HitDice_Remaining(member)))
				end
				B24.Fire(B24.ShortRestListeners, member)
			end
		end
		EEex_Action_QueueResponseStringOnAIBase("FadeToColor([20.0],0) Wait(2) AdvanceTime(300) FadeFromColor([20.0],0)", sprite)
end

-- op402 entry point of the old Short Rest innate (B24SREST.SPL; saves from before setup version 6
-- may still have it until the setup runs).
function B24SREST(op402, sprite)
	EEex_Utility_TryIgnore(B24.ShortRest, sprite)
end

-- The Rest button (UI.MENU, patched at install): which rest? A short rest (the party, an hour,
-- Hit Dice; the rests left until the next long rest), a long rest (the engine's own), or none.
function B24_RestButton()
	local ok = pcall(function()
		local left = B24.ShortRests_Remaining()
		local text = string.format("Short Rest: the party rests for an hour; everyone spends Hit Dice to heal and "
			.. "regains short-rest features (%d left until a long rest).\n\nLong Rest: the party sleeps; everything comes back.", left)
		for _, label in ipairs({ "Short Rest", "Long Rest" }) do
			if uiStrings and uiStrings[label] == nil then uiStrings[label] = label end
		end
		popup3Button(text, "Short Rest", function() EEex_Utility_TryIgnore(B24.ShortRest) end,
			"Long Rest", function() e:GetActiveEngine():OnRestButtonClick() end,
			"CANCEL_BUTTON", function() end)
	end)
	-- Without the popup: the engine's rest, as before.
	if not ok then e:GetActiveEngine():OnRestButtonClick() end
end

---------------
-- Long rest --
---------------

-- Called from the global script when the party has rested (PartyRested()).
function B24_OnPartyRested()
	EEex_GameState_SetGlobalInt(B24.SHORT_REST_GLOBAL, 0)
	for _, member in ipairs(B24.Party()) do
		if not B24.GState_Has(member, B24.GState.DEAD) then
			member:setLocalInt("B24HDUSE", 0)
			B24.Heal(member, member:getStat(B24.Stat.MAXHP))
			if B24.Exhaustion_Get(member) > 0 then
				B24.Exhaustion_Add(member, -1)
			end
			B24.Conc_End(member.m_id, "rest")
			B24.Fire(B24.LongRestListeners, member)
		end
	end
end

-----------------
-- Party setup --
-----------------

function B24_PartyNeedsSetup()
	for _, member in ipairs(B24.Party()) do
		if member:getLocalInt("B24SETUP") < B24.SETUP_VERSION then return true end
	end
	return false
end

-- Short Rest is no innate any more (version 6): the Rest button asks for a short or a long rest
-- (B24_RestButton). Version 1 gave the innate to every member, version 2-5 to the protagonist.
function B24_SetupParty()
	local protagonist = B24.Protagonist()
	for _, member in ipairs(B24.Party()) do
		if member:getLocalInt("B24SETUP") < B24.SETUP_VERSION then
			member:setLocalInt("B24SETUP", B24.SETUP_VERSION)
			-- Version 1 cast a permanent op402 that re-ran the rest on every effect re-evaluation.
			B24.RemoveEffectsBySource(member, B24.SHORT_REST_RES)
			B24.ApplyEffect(member, { ["effectID"] = 172, ["res"] = B24.SHORT_REST_RES })
			if protagonist and member.m_id == protagonist.m_id then
				-- Version 5: no Turn-Based Combat innate any more (version 4 gave it; the switch is the button
				-- on the game screen, B24TURN.menu).
				B24.ApplyEffect(member, { ["effectID"] = 172, ["res"] = "B24TURNS" })
			end
			-- Version 3: no engine non-proficiency penalty (see B24PROF.lua).
			B24.GrantWeaponStars(member)
		end
	end
end
