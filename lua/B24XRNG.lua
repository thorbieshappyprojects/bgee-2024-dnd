-- BG 2024 Rules Mod: Ranger subclasses beyond the SRD (Beast Master, Fey Wanderer, Gloom Stalker).
-- Feature texts are this mod's own wording.
--
-- Beast Master
--   3  Primal Companion (once per long rest, summon your beast of the land, a wolf in BG: hit
--      points 5 + 5 x Ranger level, AC about 13 + Wisdom modifier, attack bonus of your spells;
--      the companions B24BST03 ... B24BST19 are made at install time per level band)
--   7  Exceptional Training (the companion's attacks are magical: a +1 bite from this band on)
--   11 Bestial Fury (the beast attacks twice)
--   15 Share Spells (no BG effect)
-- Fey Wanderer
--   3  Dreadful Strikes (once per round a weapon hit deals 1d4 extra psychic damage, 1d6 from 11;
--      psychic counts as magic damage in BG), Otherworldly Glamour (no BG effect)
--   7  Beguiling Twist (advantage on saves against charm and fear; the reaction has no BG effect)
--   11 Fey Reinforcements (no BG effect)
--   15 Misty Wanderer (Misty Step, Wisdom modifier times per long rest; needs the Spells component)
-- Gloom Stalker
--   3  Dread Ambusher (in the first round of combat +10 ft speed; Dreadful Strike: Wisdom modifier
--      times per long rest, the first hit each round deals 2d6 extra psychic damage), Umbral Sight
--      (no BG effect)
--   7  Iron Mind (Wisdom save proficiency; the Intelligence/Charisma alternative is not in BG yet)
--   11 Stalker's Flurry (a Dreadful Strike gives one extra attack that round)
--   15 Shadowy Dodge (once per round the first hit against you has a 50% chance to miss, standing
--      in for disadvantage)
--
-- Locals: B24BMUSE (Primal Companion), B24FWUSE (Misty Wanderer), B24GSUSE (Dreadful Strike).

local function level(sprite) return B24RA.Level(sprite) end
local function wis(sprite) return math.max(1, B24.AbilityModOf(sprite, "WIS")) end

local function isBeast(sprite, l) return B24LV.Is(sprite, "RANGER", "BEAST_MASTER", l or 3) end
local function isFey(sprite, l) return B24LV.Is(sprite, "RANGER", "FEY_WANDERER", l or 3) end
local function isGloom(sprite, l) return B24LV.Is(sprite, "RANGER", "GLOOM_STALKER", l or 3) end

B24LV.AddMoreSubclasses("RANGER", {
	{ key = "BEAST_MASTER", name = "Beast Master",
	  desc = "A primal beast fights at your side.\n\nLevel 3: Primal Companion (summon your beast once per long rest; in BG a wolf whose hit points, armor and attack grow with your Ranger level).\nLevel 11: Bestial Fury (the beast attacks twice).\nExceptional Training makes its attacks magical; Share Spells has no BG effect.",
	  features = { [3] = "Primal Companion", [7] = "Exceptional Training", [11] = "Bestial Fury", [15] = "Share Spells (no BG effect)" } },
	{ key = "FEY_WANDERER", name = "Fey Wanderer",
	  desc = "The Feywild's magic clings to you.\n\nLevel 3: Dreadful Strikes (once per round a weapon hit deals 1d4 extra psychic damage, 1d6 from level 11).\nLevel 7: Beguiling Twist (advantage on saves against charm and fear).\nLevel 15: Misty Wanderer (Misty Step, Wisdom modifier times per long rest).\nOtherworldly Glamour and Fey Reinforcements have no BG effect.",
	  features = { [3] = "Dreadful Strikes", [7] = "Beguiling Twist", [11] = "Fey Reinforcements (no BG effect)", [15] = "Misty Wanderer" } },
	{ key = "GLOOM_STALKER", name = "Gloom Stalker",
	  desc = "You hunt in the darkness and strike first.\n\nLevel 3: Dread Ambusher (faster in the first round of combat; Dreadful Strike: the first hit each round deals 2d6 extra psychic damage, Wisdom modifier times per long rest).\nLevel 7: Iron Mind (Wisdom save proficiency).\nLevel 11: Stalker's Flurry (a Dreadful Strike gives an extra attack).\nLevel 15: Shadowy Dodge (the first hit against you each round may miss).\nUmbral Sight has no BG effect.",
	  features = { [3] = "Dread Ambusher", [7] = "Iron Mind", [11] = "Stalker's Flurry", [15] = "Shadowy Dodge" } },
})

------------------
-- Beast Master --
------------------

B24LV.AddResource("PRIMAL_COMPANION", { spell = "B24BEAST", localName = "B24BMUSE",
	max = function(sprite) return isBeast(sprite) and 1 or 0 end })

B24XR = {}
B24XR.BEAST_BANDS = { 19, 17, 15, 13, 11, 9, 7, 5, 3 }

function B24BEAST(op402, ranger)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(ranger, "PRIMAL_COMPANION")
		local band = 3
		for _, l in ipairs(B24XR.BEAST_BANDS) do
			if level(ranger) >= l then band = l break end
		end
		B24.Summon(ranger, string.format("B24BST%02d", band), 7200)
		B24.Log(string.format("%s summons the Primal Companion", B24.Name(ranger)))
	end)
end

------------------
-- Fey Wanderer --
------------------

B24LV.AddResource("MISTY_WANDERER", { spell = "B24MSTEP", localName = "B24FWUSE",
	max = function(sprite) return isFey(sprite, 15) and wis(sprite) or 0 end })

table.insert(B24WPN.DamageListeners, function(context)
	local ranger = context.attacker
	if not isFey(ranger) or not B24LV.OncePerRound(ranger, "DREADFUL_STRIKES") then return end
	local damage = B24.Roll(isFey(ranger, 11) and 6 or 4)
	B24X.Damage(context.target, ranger, damage, B24X.MAGIC)
	B24.Log(string.format("%s: Dreadful Strikes, %d psychic damage", B24.Name(ranger), damage))
end)

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	return isFey(sprite, 7) and (conditions.CHARM or conditions.FEAR) or false, false
end)

-------------------
-- Gloom Stalker --
-------------------

B24LV.AddResource("DREADFUL_STRIKE", { localName = "B24GSUSE",
	max = function(sprite) return isGloom(sprite) and wis(sprite) or 0 end })

-- Ambusher's Leap: faster in the first round of combat.
B24LV.AddTickListener(function(ranger)
	if not isGloom(ranger) or B24RD == nil then return end
	local aux = B24.Aux(ranger)
	local start = B24RD.roundStart
	if start and B24RD.round == 1 and aux.B24_AmbushRound ~= start then
		aux.B24_AmbushRound = start
		B24.ApplyEffect(ranger, { ["effectID"] = 176, ["effectAmount"] = 133, ["dwFlags"] = 5, ["durationType"] = 0, ["duration"] = 6 })
	end
end)

table.insert(B24WPN.DamageListeners, function(context)
	local ranger = context.attacker
	if not isGloom(ranger) or B24LV.Remaining(ranger, "DREADFUL_STRIKE") <= 0 then return end
	if not B24LV.OncePerRound(ranger, "DREADFUL_STRIKE") then return end
	B24LV.Use(ranger, "DREADFUL_STRIKE")
	local damage = B24LV.Dice(2, 6)
	B24X.Damage(context.target, ranger, damage, B24X.MAGIC)
	if isGloom(ranger, 11) then
		B24.ApplyEffect(ranger, { ["effectID"] = 1, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 6 })
	end
	B24.Log(string.format("%s: Dreadful Strike, %d psychic damage", B24.Name(ranger), damage))
end)

-- Iron Mind: Wisdom save proficiency (2024 offers Intelligence or Charisma instead if the ranger
-- already has it; not in BG yet).
B24.AddSaveProficiencyListener(function(sprite, ability)
	if not isGloom(sprite, 7) then return false end
	return ability == "WIS"
end)

table.insert(B24WPN.DamageListeners, function(context)
	local ranger = context.target
	if not isGloom(ranger, 15) or not B24LV.OncePerRound(ranger, "SHADOWY_DODGE") then return end
	if math.random() < 0.5 then
		B24WPN.RollDiceInto(context.effect)
		context.effect.m_effectAmount = 0
		B24.Log(string.format("%s: Shadowy Dodge, the hit misses", B24.Name(ranger)))
	end
end)
