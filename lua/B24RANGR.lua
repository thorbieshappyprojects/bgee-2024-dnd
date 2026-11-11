-- BG 2024 Rules Mod: the 2024 Ranger with the Hunter (SRD subclass). BG's ranger class abilities
-- (CLABRN01) are removed at install time. Ranger spells follow with the spell updates; Hunter's
-- Mark is an innate ability until then.
--
--   1  Favored Enemy (Hunter's Mark: 2 free uses; 3 at 5, 4 at 9, 5 at 13, 6 at 17), Weapon
--      Mastery (2)
--   2  Deft Explorer (Expertise in one skill), Fighting Style
--   3  Subclass: Hunter (Hunter's Prey: Colossus Slayer; Hunter's Lore: no BG effect)
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Extra Attack (engine table)
--   6  Roving (+10 ft speed)
--   7  Hunter: Defensive Tactics (Multiattack Defense; Escape the Horde has no BG effect),
--      11 Superior Hunter's Prey (the mark's damage also hits a second enemy), 15 Superior Hunter's
--      Defense (no reactions in BG: the first damage each round gives resistance to its type)
--   9  Expertise (two more)
--   10 Tireless (temporary hit points; a short rest also lowers exhaustion)
--   13 Relentless Hunter (no BG effect: Hunter's Mark is no concentration spell here)
--   14 Nature's Veil (invisible until the end of the next round)
--   17 Precise Hunter (advantage against the marked creature)
--   18 Feral Senses (see invisible creatures nearby)
--   20 Foe Slayer (Hunter's Mark deals 1d10)
--
-- Locals: B24HMUSE (Hunter's Mark), B24TLUSE (Tireless), B24NVUSE (Nature's Veil).

B24RA = {}

B24RA.MARK_SECONDS = 3600

function B24RA.Level(sprite)
	return B24LV.ClassLevel(sprite, "RANGER")
end

B24LV.AddSubclasses("RANGER", 3, {
	{ key = "HUNTER", name = "Hunter",
	  desc = "Hunters protect the borderlands from monsters.\n\nLevel 3: Hunter's Prey (Colossus Slayer: once per round, +1d8 damage against a creature that is missing hit points); Hunter's Lore (no BG effect).\nLevel 7: Defensive Tactics (Multiattack Defense: a creature that hits you has disadvantage on its other attacks against you that round; Escape the Horde has no BG effect).\nLevel 11: Superior Hunter's Prey (once per round, Hunter's Mark's extra damage also hits another enemy within 30 ft).\nLevel 15: Superior Hunter's Defense (the first damage you take each round gives you resistance to that damage type until the round ends).",
	  features = { [3] = "Hunter's Prey (Colossus Slayer)", [7] = "Defensive Tactics", [11] = "Superior Hunter's Prey", [15] = "Superior Hunter's Defense" } },
})

local function isHunter(sprite)
	return B24LV.Subclass(sprite, "RANGER") == "HUNTER"
end

local function wis(sprite)
	return math.max(1, B24.AbilityModOf(sprite, "WIS"))
end

B24LV.AddResource("HUNTERS_MARK", { spell = "B24HMARK", localName = "B24HMUSE",
	max = function(sprite)
		local level = B24RA.Level(sprite)
		return level >= 17 and 6 or level >= 13 and 5 or level >= 9 and 4 or level >= 5 and 3 or level >= 1 and 2 or 0
	end })

B24LV.AddResource("TIRELESS", { spell = "B24TIRLS", localName = "B24TLUSE",
	max = function(sprite) return B24RA.Level(sprite) >= 10 and wis(sprite) or 0 end })

B24LV.AddResource("NATURES_VEIL", { spell = "B24NVEIL", localName = "B24NVUSE",
	max = function(sprite) return B24RA.Level(sprite) >= 14 and wis(sprite) or 0 end })

B24RA.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24RA.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24RA.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	return { ASI = asi, STYLE = level >= 2 and 1 or 0, MASTERY = B24.MasteryCount(sprite),
		EXPERTISE = (level >= 9 and 3) or (level >= 2 and 1) or 0 }
end)

B24RA.FEATURES = {
	[1] = "Favored Enemy (Hunter's Mark, 2 uses), Weapon Mastery (2 weapons)",
	[2] = "Deft Explorer (Expertise), Fighting Style",
	[3] = "Subclass",
	[4] = "Ability Score Improvement",
	[5] = "Extra Attack, Hunter's Mark (3 uses)",
	[6] = "Roving",
	[8] = "Ability Score Improvement",
	[9] = "Expertise (two more skills), Hunter's Mark (4 uses)",
	[10] = "Tireless",
	[12] = "Ability Score Improvement",
	[13] = "Relentless Hunter, Hunter's Mark (5 uses)",
	[14] = "Nature's Veil",
	[16] = "Ability Score Improvement",
	[17] = "Precise Hunter, Hunter's Mark (6 uses)",
	[18] = "Feral Senses",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Foe Slayer",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24RA.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "RANGER") + 1, level do
		if B24RA.FEATURES[l] then table.insert(lines, string.format("Ranger %d: %s", l, B24RA.FEATURES[l])) end
	end
	return lines
end)

B24LV.AddApplyListener(function(sprite)
	local level = B24RA.Level(sprite)
	if level >= 6 then
		B24LV.Permanent(sprite, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5 })
	end
	if level >= 18 then
		B24LV.Permanent(sprite, { ["effectID"] = 193 }) -- see invisible
	end
end)

-------------------
-- Hunter's Mark --
-------------------

-- op402 entry point of B24HMARK.SPL (cast on a creature): marks it for an hour; weapon hits
-- against it deal 1d6 extra damage (1d10 at 20). One mark at a time. The marked creature shows it:
-- "Hunter's Mark" over its head, then a steady green glow while the mark lasts (B24RA.MARK_GLOW_RES;
-- a solid glow, op50: the pulsing one, op9, stood still in its dark phase while the turn-based
-- freeze held the creature; a new mark takes it off the old target), and its tile in the
-- initiative bar names the ranger (below).
-- Moving the mark (2024): when the marked creature drops to 0 hit points while the mark lasts, the
-- ranger may move it to another creature as a bonus action. The ranger gets one cast of Hunter's
-- Mark for that (B24RA.MarkTick), which spends no use, and the mark keeps its end.
B24RA.MARK_GLOW_RES = "B24HMRKV"
B24RA.MARK_GLOW = 0x00FF0000

local function markDown(mark)
	local target = mark and B24.GetSprite(mark.target)
	return target == nil or B24.GState_Has(target, B24.GState.DEAD) or B24.GState_Has(target, B24.GState.STONE_DEATH)
		or target.m_baseStats.m_hitPoints <= 0
end

function B24HMARK(op402, target)
	EEex_Utility_TryIgnore(function()
		local ranger = B24.GetSprite(op402.m_sourceId)
		if ranger == nil then return end
		local now = B24.GameTick()
		local old = B24.Aux(ranger).B24_Mark
		local moving = old ~= nil and old.movable and now <= old.untilTick
		if not moving then B24LV.Use(ranger, "HUNTERS_MARK") end
		local oldTarget = old and B24.GetSprite(old.target)
		if oldTarget then B24.RemoveEffectsBySource(oldTarget, B24RA.MARK_GLOW_RES) end
		local untilTick = moving and old.untilTick or now + B24RA.MARK_SECONDS * 15
		B24.Aux(ranger).B24_Mark = { target = target.m_id, untilTick = untilTick }
		B24.ApplyEffect(target, { ["effectID"] = 50, ["effectAmount"] = B24RA.MARK_GLOW, ["dwFlags"] = 0,
			["durationType"] = 0, ["duration"] = math.max(1, math.ceil((untilTick - now) / 15)), ["m_sourceRes"] = B24RA.MARK_GLOW_RES })
		local ref = B24.HeadText and B24.HeadText.MARKED
		if ref then EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format("DisplayStringHead(Myself,%d)", ref), target) end
		B24.Log(string.format("%s %s %s", B24.Name(ranger), moving and "moves the mark to" or "marks", B24.Name(target)))
		-- The count of casts as the uses say (a move's extra cast is spent).
		if moving then B24LV.Rebuild(ranger, "HUNTERS_MARK") end
	end)
end

-- Every second (class tick): the marked creature is down while the mark lasts: one cast to move it;
-- the mark over: no extra cast left.
function B24RA.MarkTick(ranger)
	local mark = B24.Aux(ranger).B24_Mark
	if mark == nil then return end
	if B24.GameTick() > mark.untilTick then
		B24.Aux(ranger).B24_Mark = nil
		if mark.movable then B24LV.Rebuild(ranger, "HUNTERS_MARK") end
		return
	end
	if not mark.movable and markDown(mark) then
		mark.movable = true
		B24.ApplyEffect(ranger, { ["effectID"] = 171, ["res"] = "B24HMARK" })
		B24.Log(string.format("%s: the marked creature is down, Hunter's Mark can move (bonus action)", B24.Name(ranger)))
	end
end

B24LV.AddTickListener(function(sprite) if B24RA.Level(sprite) > 0 then B24RA.MarkTick(sprite) end end)

local function marked(ranger, target)
	local mark = B24.Aux(ranger).B24_Mark
	return mark ~= nil and mark.target == target.m_id and B24.GameTick() <= mark.untilTick
end

table.insert(B24WPN.DamageListeners, function(context)
	local ranger, target = context.attacker, context.target
	local level = B24RA.Level(ranger)
	if level <= 0 then return end
	local extra, parts = 0, {}
	if marked(ranger, target) then
		local mark = B24.Roll(level >= 20 and 10 or 6)
		extra = extra + mark
		table.insert(parts, "Hunter's Mark " .. mark)
		-- Superior Hunter's Prey (Hunter 11): once per round the mark's damage also hits another
		-- enemy within 30 ft of the target (force; in BG: magic damage).
		if level >= 11 and isHunter(ranger) and B24LV.OncePerRound(ranger, "SUPERIOR_PREY") then
			for _, other in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(ranger, "[ENEMY]", B24.Feet(60), true) or {}) do
				local dx, dy = other.m_pos.x - target.m_pos.x, other.m_pos.y - target.m_pos.y
				if other.m_id ~= target.m_id and dx * dx + dy * dy <= B24.Feet(30) * B24.Feet(30) and not B24.GState_Has(other, B24.GState.DEAD) then
					B24.ApplyEffect(other, { ["effectID"] = 12, ["effectAmount"] = mark, ["dwFlags"] = 0x400000,
						["durationType"] = 1, ["sourceID"] = ranger.m_id })
					table.insert(parts, string.format("Superior Hunter's Prey %d to %s", mark, B24.Name(other)))
					break
				end
			end
		end
	end
	-- Colossus Slayer: once per round against a creature missing hit points.
	if level >= 3 and isHunter(ranger) and target.m_baseStats.m_hitPoints < target:getStat(B24.Stat.MAXHP) then
		local aux = B24.Aux(ranger)
		local now = B24.GameTick()
		if aux.B24_ColossusTick == nil or now - aux.B24_ColossusTick >= 90 then
			aux.B24_ColossusTick = now
			local slayer = B24.Roll(8)
			extra = extra + slayer
			table.insert(parts, "Colossus Slayer " .. slayer)
		end
	end
	if extra > 0 then
		context.effect.m_effectAmount = context.effect.m_effectAmount + extra
		B24.Log(string.format("%s: %s", B24.Name(ranger), table.concat(parts, ", ")))
	end
end)

-- The initiative bar's tile of the marked creature names the ranger (B24TURN.lua).
if B24TB and B24TB.TileNoteListeners then
	table.insert(B24TB.TileNoteListeners, function(sprite)
		for _, ranger in ipairs(B24.Party()) do
			if marked(ranger, sprite) then return "Marked by\n" .. B24.Name(ranger) end
		end
	end)
end

-- Precise Hunter: advantage against the marked creature.
table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	return B24RA.Level(attacker) >= 17 and marked(attacker, target)
end)

-------------------------------
-- Tireless, Nature's Veil --
-------------------------------

-- Tireless: 1d8 + Wisdom modifier temporary hit points (for an hour, as extra hit points).
function B24TIRLS(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "TIRELESS")
		local amount = B24.Roll(8) + wis(sprite)
		B24.ApplyEffect(sprite, { ["effectID"] = 18, ["effectAmount"] = amount, ["dwFlags"] = 0,
			["durationType"] = 0, ["duration"] = 3600 })
		B24.Log(string.format("%s: Tireless, %d temporary hit points", B24.Name(sprite), amount))
	end)
end

B24.AddShortRestListener(function(sprite)
	if B24RA.Level(sprite) >= 10 and B24.Exhaustion_Get(sprite) > 0 then
		B24.Exhaustion_Add(sprite, -1)
	end
end)

-- Nature's Veil: invisible until the end of the next round.
function B24NVEIL(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "NATURES_VEIL")
		B24.ApplyEffect(sprite, { ["effectID"] = 20, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 12 })
		B24.Log(string.format("%s: Nature's Veil", B24.Name(sprite)))
	end)
end

-- Portrait icon while the ranger's Hunter's Mark is on someone.
B24.AddIconListener(function(sprite, keys)
	local mark = B24.Aux(sprite).B24_Mark
	if mark ~= nil and B24.GameTick() <= mark.untilTick then keys.HMRK = true end
end)

------------------------------------------------------
-- Defensive Tactics, Superior Hunter's Defense --
------------------------------------------------------

-- Defensive Tactics (Hunter 7): Multiattack Defense (a creature that hits you has disadvantage on
-- its other attacks against you this round) or Escape the Horde (no BG effect: no opportunity
-- attacks). Local B24DTACT.
B24LV.AddOption({ key = "DEFENSIVE_TACTICS", localName = "B24DTACT", class = "RANGER", level = 7, title = "Defensive Tactics",
	subclass = "HUNTER",
	list = {
		{ key = "MULTIATTACK", name = "Multiattack Defense", desc = "A creature that hits you has disadvantage on its other attack rolls against you for the rest of the round." },
		{ key = "HORDE", name = "Escape the Horde", desc = "Opportunity attacks against you have disadvantage. BG has no opportunity attacks, so this has no effect." },
	} })

local function multiattackDefense(sprite)
	return B24RA.Level(sprite) >= 7 and isHunter(sprite) and B24LV.Option(sprite, "DEFENSIVE_TACTICS") == "MULTIATTACK"
end

table.insert(B24WPN.DamageListeners, function(context)
	local target = context.target
	if not multiattackDefense(target) then return end
	local aux = B24.Aux(target)
	aux.B24_Multiattack = aux.B24_Multiattack or {}
	aux.B24_Multiattack[context.attacker.m_id] = B24.GameTick() + 90
end)

table.insert(B24.DisadvantageAgainstListeners, function(attacker, target)
	local record = B24.Aux(target).B24_Multiattack
	local untilTick = record and record[attacker.m_id]
	return untilTick ~= nil and B24.GameTick() <= untilTick
end)

-- Superior Hunter's Defense (Hunter 15): BG has no reactions; the first damage the ranger takes
-- each round gives resistance to its type for the rest of the round, the triggering damage
-- included.
local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	EEex_Utility_TryIgnore(function()
		if B24RA.Level(targetSprite) < 15 or not isHunter(targetSprite) then return end
		local damageType = EEex_BAnd(effect.m_dWFlags, 0xFFFF0000)
		local aux = B24.Aux(targetSprite)
		local now = B24.GameTick()
		local defense = aux.B24_HunterDefense
		if defense == nil or now > defense.untilTick then
			defense = { type = damageType, untilTick = now + 90 }
			aux.B24_HunterDefense = defense
			B24.Log(string.format("%s: Superior Hunter's Defense", B24.Name(targetSprite)))
		end
		if defense.type == damageType then
			B24WPN.RollDiceInto(effect)
			effect.m_effectAmount = math.floor(effect.m_effectAmount / 2)
		end
	end)
	return originalDamageStart(effect, sourceSprite, targetSprite)
end
