-- BG 2024 Rules Mod: Wizard subclasses beyond the SRD (Abjurer, Diviner, Illusionist). Feature
-- texts are this mod's own wording.
--
-- Abjurer
--   3  Arcane Ward (the first level 1+ abjuration spell you start casting after a long rest raises a
--      ward of 2 x Wizard level + Intelligence modifier hit points that takes damage for you; later
--      abjuration spells restore 2 x their level), Abjuration Savant (no BG effect)
--   6  Projected Ward (the ward also takes damage for allies within 30 ft)
--   10 Spell Breaker (no BG effect)
--   14 Spell Resistance (advantage on saves against spells, half damage from spells)
-- Diviner
--   3  Portent (after a long rest roll two d20s, three from 14; the Portent innate on a creature
--      makes its next save use one of them: the lowest for enemies, the highest for allies),
--      Divination Savant (no BG effect)
--   6  Expert Divination (starting a level 2+ divination spell restores a spent spell one level
--      lower, at most level 5)
--   10 The Third Eye (once per short rest: see invisible creatures for an hour)
--   14 Greater Portent (three dice)
-- Illusionist
--   3  Improved Illusions (no BG effect)
--   6  Phantasmal Creatures (an illusory beast once per long rest)
--   10 Illusory Self (once per short rest the first weapon hit against you misses)
--   14 Illusory Reality (no BG effect)
--
-- Locals: B24AWHP (ward hit points), B24AWMAD (ward raised since the long rest), B24PRT1..3
-- (Portent rolls, 0 = used), B24TEUSE (The Third Eye), B24ISUSE2 (Illusory Self).

local function level(sprite) return B24WZ.Level(sprite) end
local function int(sprite) return B24.AbilityModOf(sprite, "INT") end

local function isAbjurer(sprite, l) return B24LV.Is(sprite, "WIZARD", "ABJURER", l or 3) end
local function isDiviner(sprite, l) return B24LV.Is(sprite, "WIZARD", "DIVINER", l or 3) end
local function isIllusionist(sprite, l) return B24LV.Is(sprite, "WIZARD", "ILLUSIONIST", l or 3) end

B24LV.AddMoreSubclasses("WIZARD", {
	{ key = "ABJURER", name = "Abjurer",
	  desc = "You specialise in magic that shields and wards.\n\nLevel 3: Arcane Ward (your first abjuration spell after a long rest raises a ward of 2 x your Wizard level + Intelligence modifier hit points that takes damage for you; later abjuration spells restore it).\nLevel 6: Projected Ward (the ward protects nearby allies too).\nLevel 14: Spell Resistance (advantage on saves against spells, half damage from them).\nAbjuration Savant and Spell Breaker have no BG effect.",
	  features = { [3] = "Arcane Ward", [6] = "Projected Ward", [10] = "Spell Breaker (no BG effect)", [14] = "Spell Resistance" } },
	{ key = "DIVINER", name = "Diviner",
	  desc = "Glimpses of the future guide your hand.\n\nLevel 3: Portent (after a long rest roll two d20s; use them for the next save of an ally or an enemy).\nLevel 6: Expert Divination (divination spells of level 2+ give back a spent lower-level spell).\nLevel 10: The Third Eye (see invisible creatures for an hour, once per short rest).\nLevel 14: Greater Portent (three dice).\nDivination Savant has no BG effect.",
	  features = { [3] = "Portent", [6] = "Expert Divination", [10] = "The Third Eye", [14] = "Greater Portent" } },
	{ key = "ILLUSIONIST", name = "Illusionist",
	  desc = "You weave magic that fools the senses.\n\nLevel 10: Illusory Self (once per short rest, the first weapon hit against you misses).\nImproved Illusions and Illusory Reality have no BG effect; Level 6: Phantasmal Creatures (once per long rest, an illusory beast for an hour).",
	  features = { [3] = "Improved Illusions (no BG effect)", [6] = "Phantasmal Creatures", [10] = "Illusory Self",
		[14] = "Illusory Reality (no BG effect)" } },
})

local ABJURATION, DIVINATION = 1, 3

local function spellInfo(res)
	local header = EEex_Resource_Demand(res, "SPL")
	if header == nil then return nil end
	local ptr = EEex_UDToPtr(header)
	return EEex_Read32(ptr + 0x34), EEex_ReadU8(ptr + 0x25)
end

-------------
-- Abjurer --
-------------

local function wardMax(sprite) return 2 * level(sprite) + int(sprite) end

table.insert(B24.SpellCastListeners, function(sprite, res)
	if res:sub(1, 4) ~= "SPWI" then return end
	local spellLevel, school = spellInfo(res)
	if spellLevel == nil or spellLevel < 1 then return end
	if school == ABJURATION and isAbjurer(sprite) then
		local hp = sprite:getLocalInt("B24AWHP")
		if sprite:getLocalInt("B24AWMAD") == 0 then
			sprite:setLocalInt("B24AWMAD", 1)
			hp = wardMax(sprite)
		else
			hp = math.min(wardMax(sprite), hp + 2 * spellLevel)
		end
		sprite:setLocalInt("B24AWHP", hp)
		B24.Log(string.format("%s: Arcane Ward %d/%d", B24.Name(sprite), hp, wardMax(sprite)))
	elseif school == DIVINATION and isDiviner(sprite, 6) and spellLevel >= 2 then
		B24.ApplyEffect(sprite, { ["effectID"] = 261, ["effectAmount"] = math.min(5, spellLevel - 1), ["dwFlags"] = 0 })
		B24.Log(string.format("%s: Expert Divination restores a level %d spell", B24.Name(sprite), math.min(5, spellLevel - 1)))
	end
end)

B24.AddLongRestListener(function(sprite)
	if isAbjurer(sprite) then
		sprite:setLocalInt("B24AWMAD", 0)
		sprite:setLocalInt("B24AWHP", 0)
	end
end)

-- The abjurer whose ward covers a creature: itself, or a party member within 30 ft (6+).
local function wardFor(target)
	if isAbjurer(target) and target:getLocalInt("B24AWHP") > 0 then return target end
	if not B24.InParty(target) then return nil end
	for _, wizard in ipairs(B24.Party()) do
		if isAbjurer(wizard, 6) and wizard:getLocalInt("B24AWHP") > 0 then
			for _, ally in ipairs(B24X.Allies(wizard, B24.Feet(30))) do
				if ally.m_id == target.m_id then return wizard end
			end
		end
	end
end

local function isSpellRes(res)
	local prefix = res:sub(1, 4)
	return prefix == "SPWI" or prefix == "SPPR" or prefix == "B24C"
end

local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	EEex_Utility_TryIgnore(function()
		if not B24.IsSprite(targetSprite) then return end
		local res = effect.m_sourceRes:get():upper()
		-- Spell Resistance (14): half damage from spells.
		if isAbjurer(targetSprite, 14) and isSpellRes(res) then
			B24WPN.RollDiceInto(effect)
			effect.m_effectAmount = math.floor(effect.m_effectAmount / 2)
		end
		local wizard = wardFor(targetSprite)
		if wizard == nil then return end
		B24WPN.RollDiceInto(effect)
		local ward = wizard:getLocalInt("B24AWHP")
		local absorbed = math.min(ward, effect.m_effectAmount)
		if absorbed <= 0 then return end
		effect.m_effectAmount = effect.m_effectAmount - absorbed
		wizard:setLocalInt("B24AWHP", ward - absorbed)
		B24.Log(string.format("%s's Arcane Ward absorbs %d (%d left)", B24.Name(wizard), absorbed, ward - absorbed))
	end)
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	return isAbjurer(sprite, 14) and conditions.RES ~= nil and isSpellRes(conditions.RES) or false, false
end)

-------------
-- Diviner --
-------------

local function portentCount(sprite) return isDiviner(sprite, 14) and 3 or 2 end

local function portentRolls(sprite)
	local rolls = {}
	for i = 1, 3 do
		local roll = sprite:getLocalInt("B24PRT" .. i)
		if roll > 0 then table.insert(rolls, { index = i, roll = roll }) end
	end
	return rolls
end

local function refreshPortent(sprite)
	B24LV.Grant(sprite, "B24PORTN", isDiviner(sprite) and #portentRolls(sprite) > 0)
end

B24.AddLongRestListener(function(sprite)
	if not isDiviner(sprite) then return end
	local shown = {}
	for i = 1, 3 do
		local roll = i <= portentCount(sprite) and B24.Roll(20) or 0
		sprite:setLocalInt("B24PRT" .. i, roll)
		if roll > 0 then table.insert(shown, tostring(roll)) end
	end
	refreshPortent(sprite)
	Infinity_DisplayString(string.format("%s: Portent %s", B24.Name(sprite), table.concat(shown, ", ")))
end)

B24LV.AddApplyListener(refreshPortent)

-- Portent (cast on a creature): its next save uses a stored roll.
function B24PORTN(op402, target)
	EEex_Utility_TryIgnore(function()
		local wizard = B24.GetSprite(op402.m_sourceId) or target
		local rolls = portentRolls(wizard)
		if #rolls == 0 then return end
		local ally = B24.InParty(target)
		table.sort(rolls, function(a, b) return a.roll < b.roll end)
		local chosen = ally and rolls[#rolls] or rolls[1]
		wizard:setLocalInt("B24PRT" .. chosen.index, 0)
		B24.Aux(target).B24_ForcedSave = chosen.roll
		refreshPortent(wizard)
		B24.Log(string.format("%s: Portent %d on %s", B24.Name(wizard), chosen.roll, B24.Name(target)))
	end)
end

B24LV.AddResource("THIRD_EYE", { spell = "B24THEYE", localName = "B24TEUSE", shortRest = "all",
	max = function(sprite) return isDiviner(sprite, 10) and 1 or 0 end })

function B24THEYE(op402, wizard)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(wizard, "THIRD_EYE")
		B24.ApplyEffect(wizard, { ["effectID"] = 193, ["durationType"] = 0, ["duration"] = 3600 })
		B24.Log(string.format("%s: The Third Eye", B24.Name(wizard)))
	end)
end

-----------------
-- Illusionist --
-----------------

B24LV.AddResource("ILLUSORY_SELF", { localName = "B24ISUS2", shortRest = "all",
	max = function(sprite) return isIllusionist(sprite, 10) and 1 or 0 end })

table.insert(B24WPN.DamageListeners, function(context)
	local wizard = context.target
	if not isIllusionist(wizard, 10) or not B24LV.Use(wizard, "ILLUSORY_SELF") then return end
	B24WPN.RollDiceInto(context.effect)
	context.effect.m_effectAmount = 0
	B24.Log(string.format("%s: Illusory Self, the attack strikes an illusion", B24.Name(wizard)))
end)

-- Portrait icon while the diviner has Portent rolls left.
B24.AddIconListener(function(sprite, keys)
	if isDiviner(sprite) and #portentRolls(sprite) > 0 then keys.PORT = true end
end)

--------------------------
-- Phantasmal Creatures --
--------------------------

-- Phantasmal Creatures (Illusionist 6): once per long rest, Summon Beast without a spell slot, as
-- an illusion: in BG the beast of the Ranger's Primal Companion for your Wizard level, for an hour.
-- BG has no fey creature for Summon Fey. Local B24PCUSE.
B24LV.AddResource("PHANTASMAL_CREATURES", { spell = "B24IPHAN", localName = "B24PCUSE",
	max = function(sprite) return isIllusionist(sprite, 6) and 1 or 0 end })

function B24IPHAN(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.Use(sprite, "PHANTASMAL_CREATURES")
		local band = 3
		for _, l in ipairs((B24XR and B24XR.BEAST_BANDS) or { 19, 17, 15, 13, 11, 9, 7, 5, 3 }) do
			if B24LV.ClassLevel(sprite, "WIZARD") >= l then band = l break end
		end
		B24.Summon(sprite, string.format("B24BST%02d", band), 3600)
		B24.Log(string.format("%s: Phantasmal Creatures (an illusory beast)", B24.Name(sprite)))
	end)
end
