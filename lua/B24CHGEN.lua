-- BG 2024 Rules Mod: character creation.
--
-- Replaces the engine's ability roll with the 2024 methods (point-buy, standard array, 4d6 drop
-- lowest with a few rerolls) and adds the background step. As in 2024, the background comes first:
-- its popup opens when the ability screen is reached, and its increases show on every ability row.
--
-- At install time the CHARGEN_ABILITIES menu in UI.MENU is patched to call the B24CG_* functions
-- below, and B24CHGEN.menu adds the B24_BACKGROUND popup.
--
-- The chosen background and feats are stored in creature locals for the in-game setup:
--   B24BG     background id (B24CG.BACKGROUNDS index)
--   B24FEAT2  extra origin feat id of a human (Versatile), 0 otherwise

B24 = B24 or {}
B24CG = B24CG or {}

-- Rows of chargen.ability, in the engine's order.
B24CG.ABILITIES = {
	{ key = "STR", field = "m_STRBase", short = "Str" },
	{ key = "DEX", field = "m_DEXBase", short = "Dex" },
	{ key = "CON", field = "m_CONBase", short = "Con" },
	{ key = "INT", field = "m_INTBase", short = "Int" },
	{ key = "WIS", field = "m_WISBase", short = "Wis" },
	{ key = "CHA", field = "m_CHRBase", short = "Cha" },
}
local STR, DEX, CON, INT, WIS, CHA = 1, 2, 3, 4, 5, 6

B24CG.POINT_BUY_TOTAL = 27
B24CG.POINT_COST = { [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9 }
B24CG.ARRAY = { 15, 14, 13, 12, 10, 8 }
B24CG.REROLLS = 3
B24CG.SCORE_CAP = 20


B24CG.METHOD_POINT_BUY, B24CG.METHOD_ARRAY, B24CG.METHOD_ROLL = 1, 2, 3
B24CG.METHODS = {
	{ label = "Point Buy",
	  help = "Every score starts at 8. Spend 27 points to raise scores up to 15: each step costs 1 point up to 13; 14 and 15 cost 2 points each." },
	{ label = "Standard Array",
	  help = "Distribute 15, 14, 13, 12, 10 and 8, one value per ability. + on an empty ability takes the highest value left, and steps up to the next free value; - puts the value back into the pool." },
	{ label = "Roll 4d6",
	  help = "Six values are rolled, each 4d6 with the lowest die dropped, and distributed like the standard array. Reroll replaces all six values and clears the abilities." },
}

B24CG.FEATS = {
	{ key = "ALERT", name = "Alert",
	  desc = "2024: add your Proficiency Bonus to Initiative.\nIn BG, which has no Initiative, you act faster instead: better weapon speed and casting speed." },
	{ key = "MI_CLERIC", name = "Magic Initiate (Cleric)",
	  desc = "2024: two Cleric cantrips and one level 1 Cleric spell you can cast once per Long Rest without a spell slot.\nIn BG: Cure Light Wounds (standing in for Cure Wounds) as an innate ability once per Long Rest. Cantrips follow with the spell list phases." },
	{ key = "MI_WIZARD", name = "Magic Initiate (Wizard)",
	  desc = "2024: two Wizard cantrips and one level 1 Wizard spell you can cast once per Long Rest without a spell slot.\nIn BG: Magic Missile as an innate ability once per Long Rest. Cantrips follow with the spell list phases." },
	{ key = "SAVAGE", name = "Savage Attacker",
	  desc = "2024: once per turn when you hit with a weapon, roll its damage dice twice and use either roll.\nIn BG: once per round, weapon damage dice are rolled twice and the higher roll counts." },
	{ key = "SKILLED", name = "Skilled", repeatable = true,
	  desc = "2024: proficiency in any three skills or tools.\nIn BG, Stealth, Sleight of Hand, Perception, Investigation and Thieves' Tools set the thief abilities; Arcana and History raise Lore." },
	{ key = "MI_DRUID", name = "Magic Initiate (Druid)",
	  desc = "2024: two Druid cantrips and one level 1 Druid spell you can cast once per Long Rest without a spell slot.\nIn BG: Entangle as an innate ability once per Long Rest." },
	{ key = "CRAFTER", name = "Crafter",
	  desc = "2024: proficiency with three artisan's tools, a 20% discount on nonmagical gear, and fast crafting.\nIn BG: better prices in stores (your Charisma counts 2 higher while you trade)." },
	{ key = "HEALER", name = "Healer",
	  desc = "2024: Battle Medic (tend a creature with a healer's kit: it spends a Hit Point Die and regains that much plus your Proficiency Bonus) and Healing Rerolls (healing dice that roll 1 are rolled again).\nIn BG: Battle Medic as an innate ability once per short rest, and the rerolls for your healing spells and abilities." },
	{ key = "LUCKY", name = "Lucky",
	  desc = "2024: Luck Points equal to your Proficiency Bonus per Long Rest, for advantage on a d20 test or disadvantage on an attack against you.\nIn BG: a failed save is rolled again while you have Luck Points." },
	{ key = "MUSICIAN", name = "Musician",
	  desc = "2024: proficiency with three instruments; after a rest, up to your Proficiency Bonus allies who hear your song gain Heroic Inspiration.\nIn BG: after a short or long rest, that many party members gain Heroic Inspiration." },
	{ key = "TAVERN_BRAWLER", name = "Tavern Brawler",
	  desc = "2024: your unarmed strikes deal 1d4 + Strength, damage dice that roll 1 are rolled again, and once per turn a hit can push the target 5 feet.\nIn BG: the same for your fists." },
	{ key = "TOUGH", name = "Tough",
	  desc = "2024: your maximum hit points rise by twice your character level.\nIn BG: the same." },
}
B24CG.FEAT_SKILLED = 5

B24CG.BACKGROUNDS = {
	{ name = "Acolyte", abilities = { INT, WIS, CHA }, feat = 2, skills = "Insight, Religion",
	  desc = "You devoted yourself to service in a temple, learning its rites and the magic of your faith." },
	{ name = "Criminal", abilities = { DEX, CON, INT }, feat = 1, skills = "Sleight of Hand, Stealth, Thieves' Tools",
	  desc = "You made a living in dark alleys, cutting purses and burgling shops." },
	{ name = "Sage", abilities = { CON, INT, WIS }, feat = 3, skills = "Arcana, History",
	  desc = "You spent your formative years among manuscripts and scrolls, studying the lore of the multiverse." },
	{ name = "Soldier", abilities = { STR, DEX, CON }, feat = 4, skills = "Athletics, Intimidation",
	  desc = "You trained for war from your youth and learned to survive on the battlefield." },
	-- The other PHB 2024 backgrounds (own wording; indices 1-4 stay as they are for existing
	-- characters).
	{ name = "Artisan", abilities = { STR, DEX, INT }, feat = 7, skills = "Investigation, Persuasion",
	  desc = "You learned a craft in a workshop, shaping wood, metal or cloth, and dealing with demanding customers." },
	{ name = "Charlatan", abilities = { DEX, CON, CHA }, feat = 5, skills = "Deception, Sleight of Hand",
	  desc = "You sold fake cures and false hopes in every tavern from Waterdeep to Amn, and moved on before anyone noticed." },
	{ name = "Entertainer", abilities = { STR, DEX, CHA }, feat = 10, skills = "Acrobatics, Performance",
	  desc = "You grew up with travelling players, earning your bread with songs, tumbling and stories." },
	{ name = "Farmer", abilities = { STR, CON, WIS }, feat = 12, skills = "Animal Handling, Nature",
	  desc = "You worked the fields and tended livestock, and hard seasons made you tough and patient." },
	{ name = "Guard", abilities = { STR, INT, WIS }, feat = 1, skills = "Athletics, Perception",
	  desc = "You stood watch on city walls and at gates, always on the lookout for trouble." },
	{ name = "Guide", abilities = { DEX, CON, WIS }, feat = 6, skills = "Stealth, Survival",
	  desc = "You led travellers through wild country and learned the old magic of the land along the way." },
	{ name = "Hermit", abilities = { CON, WIS, CHA }, feat = 8, skills = "Medicine, Religion",
	  desc = "You lived apart from the world, tending herbs and pondering the mysteries of creation." },
	{ name = "Merchant", abilities = { CON, INT, CHA }, feat = 9, skills = "Animal Handling, Persuasion",
	  desc = "You drove caravans and haggled in markets, where fortune favours the bold and the lucky." },
	{ name = "Noble", abilities = { STR, INT, CHA }, feat = 5, skills = "History, Persuasion",
	  desc = "You were raised in a wealthy house, schooled in etiquette, history and the art of command." },
	{ name = "Sailor", abilities = { STR, DEX, WIS }, feat = 11, skills = "Acrobatics, Perception",
	  desc = "You sailed the Sword Coast and learned to brawl in every harbour tavern along it." },
	{ name = "Scribe", abilities = { DEX, INT, WIS }, feat = 5, skills = "Investigation, Perception",
	  desc = "You copied books and records in a scriptorium, with an eye for detail and errors." },
	{ name = "Wayfarer", abilities = { DEX, WIS, CHA }, feat = 9, skills = "Insight, Stealth, Thieves' Tools",
	  desc = "You grew up on the streets, living by your wits, your luck and the kindness of strangers." },
}

-- Ability priority per class (CLASS.IDS), highest first, following the 2024 class suggestions.
-- Decides which background is preselected and where its +2 and +1 go by default.
B24CG.CLASS_PRIORITY = {
	[1]  = { INT, CON, DEX, WIS, CHA, STR }, -- Mage
	[2]  = { STR, CON, DEX, WIS, CHA, INT }, -- Fighter
	[3]  = { WIS, CON, STR, CHA, INT, DEX }, -- Cleric
	[4]  = { DEX, CON, INT, WIS, CHA, STR }, -- Thief
	[5]  = { CHA, DEX, CON, WIS, INT, STR }, -- Bard
	[6]  = { STR, CHA, CON, WIS, DEX, INT }, -- Paladin
	[7]  = { STR, INT, CON, DEX, WIS, CHA }, -- Fighter/Mage
	[8]  = { STR, WIS, CON, DEX, CHA, INT }, -- Fighter/Cleric
	[9]  = { DEX, STR, CON, WIS, INT, CHA }, -- Fighter/Thief
	[10] = { DEX, INT, STR, CON, WIS, CHA }, -- Fighter/Mage/Thief
	[11] = { WIS, CON, DEX, INT, CHA, STR }, -- Druid
	[12] = { DEX, WIS, CON, STR, INT, CHA }, -- Ranger
	[13] = { DEX, INT, CON, WIS, CHA, STR }, -- Mage/Thief
	[14] = { WIS, INT, CON, DEX, CHA, STR }, -- Cleric/Mage
	[15] = { DEX, WIS, CON, INT, CHA, STR }, -- Cleric/Thief
	[16] = { STR, WIS, CON, DEX, INT, CHA }, -- Fighter/Druid
	[17] = { STR, INT, WIS, CON, DEX, CHA }, -- Fighter/Mage/Cleric
	[18] = { WIS, DEX, CON, STR, INT, CHA }, -- Cleric/Ranger
	[19] = { CHA, CON, DEX, WIS, INT, STR }, -- Sorcerer
	[20] = { DEX, WIS, CON, STR, INT, CHA }, -- Monk
	[21] = { WIS, CON, CHA, DEX, INT, STR }, -- Shaman
}

-- 2024 descriptions of the six abilities for the ability screen (the engine's texts describe the
-- 2e tables and leave their minimum and maximum fields empty without the engine's roll).
B24CG.ABILITY_HELP = {
	"STRENGTH measures physical might. Its modifier adds to attack and damage rolls with melee weapons and to Strength saving throws, and the score decides how much you can carry.",
	"DEXTERITY measures agility, reflexes and balance. Its modifier adds to attack rolls with ranged and finesse weapons, to Armor Class (up to +2 in medium armor, none in heavy armor) and to Dexterity saving throws.",
	"CONSTITUTION measures health and stamina. Its modifier adds to your hit points at every level, to the hit points regained with each Hit Die and to Constitution saving throws, including the saves that keep up your concentration.",
	"INTELLIGENCE measures reasoning and memory. It is the spellcasting ability of wizards, and its modifier adds to Intelligence saving throws and to Lore.",
	"WISDOM measures perception and insight. It is the spellcasting ability of clerics, druids and rangers, and its modifier adds to Wisdom saving throws.",
	"CHARISMA measures force of personality. It is the spellcasting ability of bards, paladins and sorcerers, and its modifier adds to Charisma saving throws and influences how others react to you.",
}

-- 2024 wording of the race step and the kit step on the main screen.
B24CG.SPECIES_HELP = "Choose your species. In the 2024 rules a species gives traits such as Darkvision or Fey Ancestry, but no ability score increases: those come from your background.\n\nHalf-elves and half-orcs have no separate 2024 species; they use the elf and orc traits."
B24CG.SUBCLASS_HELP = "In the 2024 rules you choose your subclass at level 3, not at character creation. Your character starts with the base class; a Barbarian gets the Barbarian kit, which stands for the Barbarian class in BG.\n\nThe subclass choice at level 3 arrives with the class updates of this mod; until then characters stay in their base class."

B24CG.TEXT = {
	TITLE = "Abilities",
	BG_BUTTON = "BACKGROUND",
	SPECIES_BUTTON = "SPECIES",
	SPECIES_TITLE = "Species",
	SUBCLASS_TITLE = "Subclass",
	CHANGE_METHOD = "Change Method",
	RESET = "Reset",
	BG_TITLE = "Background",
	BG_BONUS = "Ability increases (+2 and +1, or +1 to all three):",
	BG_BONUS_INVALID = "Give +2 to one ability and +1 to another, or +1 to all three.",
	BG_FEAT = "Versatile (Human): an extra origin feat",
	BG_FEAT_DUPLICATE = "The extra feat can't repeat the background's feat.",
	DONE = "Done",
	CANCEL = "Cancel",
	TOTAL = "Total",
	LEFT = "Left",
	POINTS = "Points",
	REROLLS = "Rerolls",
	UNASSIGNED = "-",
}

function B24CG_Text(key)
	return B24CG.TEXT[key] or key
end

-----------
-- State --
-----------

-- One state per character in creation; rerolls are reset each time the screen opens.
local state = nil

local function chargenSprite()
	local screen = EngineGlobals.g_pBaldurChitin.m_pEngineCreateChar
	if screen == nil then return nil end
	return EEex_GameObject_Get(screen.m_nGameSprite)
end

local function spriteInfo(sprite)
	if sprite == nil then return 0, 0, 0 end
	return sprite.m_id, sprite.m_typeAI.m_Class, sprite.m_typeAI.m_Race
end

local function rankOf(priority)
	local rank = {}
	for r, ability in ipairs(priority) do rank[ability] = r end
	return rank
end

local function roll4d6DropLowest()
	local dice = {}
	for i = 1, 4 do dice[i] = math.random(1, 6) end
	table.sort(dice)
	return dice[2] + dice[3] + dice[4]
end

local function rollSet()
	local values = {}
	for i = 1, 6 do values[i] = roll4d6DropLowest() end
	table.sort(values, function(a, b) return a > b end)
	return values
end

-- +2 on the background ability the class needs most, +1 on the next.
local function defaultBonus(s, bg)
	local abilities = { table.unpack(B24CG.BACKGROUNDS[bg].abilities) }
	table.sort(abilities, function(a, b) return s.rank[a] < s.rank[b] end)
	s.bonus = { 0, 0, 0, 0, 0, 0 }
	s.bonus[abilities[1]] = 2
	s.bonus[abilities[2]] = 1
end

local function defaultBackground(s)
	local best, bestScore = 1, -1
	for i, bg in ipairs(B24CG.BACKGROUNDS) do
		local ranks = {}
		for _, ability in ipairs(bg.abilities) do table.insert(ranks, s.rank[ability]) end
		table.sort(ranks)
		local score = 2 * (7 - ranks[1]) + (7 - ranks[2])
		if score > bestScore then best, bestScore = i, score end
	end
	return best
end

local function defaultExtraFeat(bg)
	return B24CG.BACKGROUNDS[bg].feat == B24CG.FEAT_SKILLED and 1 or B24CG.FEAT_SKILLED
end

-- Point-buy keeps a score per ability; array and roll keep a pool of values and which ability
-- holds which value (nil = not assigned yet).
local function newState(key, class, race)
	local s = { key = key, race = race, method = B24CG.METHOD_POINT_BUY, rerolls = B24CG.REROLLS,
		bgConfirmed = false }
	s.priority = B24CG.CLASS_PRIORITY[class] or { STR, DEX, CON, INT, WIS, CHA }
	s.rank = rankOf(s.priority)
	s.points = { 8, 8, 8, 8, 8, 8 }
	s.pool = { [B24CG.METHOD_ARRAY] = B24CG.ARRAY }
	s.assign = { [B24CG.METHOD_ARRAY] = {}, [B24CG.METHOD_ROLL] = {} }
	s.bg = defaultBackground(s)
	defaultBonus(s, s.bg)
	s.feat2 = defaultExtraFeat(s.bg)
	return s
end

local function isPointBuy()
	return state.method == B24CG.METHOD_POINT_BUY
end

-- Base score of ability i, or nil while it has no value assigned.
local function base(i)
	if isPointBuy() then return state.points[i] end
	return state.assign[state.method][i]
end

local function final(i)
	local b = base(i)
	return b and math.min(B24CG.SCORE_CAP, b + state.bonus[i])
end

local function pointsLeft()
	local spent = 0
	for i = 1, 6 do spent = spent + B24CG.POINT_COST[state.points[i]] end
	return B24CG.POINT_BUY_TOTAL - spent
end

-- Values of the current pool not held by any ability other than skip, sorted high to low.
local function freeValues(skip)
	local free = { table.unpack(state.pool[state.method]) }
	for j = 1, 6 do
		local v = state.assign[state.method][j]
		if j ~= skip and v ~= nil then
			for k, w in ipairs(free) do
				if w == v then table.remove(free, k) break end
			end
		end
	end
	return free
end

local function allAssigned()
	for i = 1, 6 do
		if base(i) == nil then return false end
	end
	return true
end

local function isHuman()
	return B24CG_SpeciesKey() == "HUMAN"
end

local function signed(n)
	return n >= 0 and ("+" .. n) or tostring(n)
end

local function modifier(score)
	return math.floor((score - 10) / 2)
end

local function newRoll()
	state.pool[B24CG.METHOD_ROLL] = rollSet()
	state.assign[B24CG.METHOD_ROLL] = {}
end

------------------
-- Screen state --
------------------

-- Starts over whenever the character in creation, its class or its race changes.
local function syncState()
	local sprite = chargenSprite()
	local id, class, race = spriteInfo(sprite)
	local key = string.format("%d:%d:%d", id, class, race)
	if state == nil or state.key ~= key then
		state = newState(key, class, race)
	end
	return state
end

function B24CG_Open()
	syncState()
	state.rerolls = B24CG.REROLLS
	currentChargenAbility = nil
end

-----------------
-- Main screen --
-----------------

-- The background is its own step on the main screen, between Alignment and Abilities (2024 order:
-- background before ability scores). Abilities unlocks once a background is confirmed.
B24CG.STEP_ABILITIES = 8

-- Going back to an earlier step asks for the background again (the choice itself is kept).
function B24CG_BackgroundDone()
	local s = syncState()
	if createCharScreen:GetCurrentStep() < B24CG.STEP_ABILITIES then s.bgConfirmed = false end
	return s.bgConfirmed
end

function B24CG_OpenBackground()
	syncState()
	Infinity_PushMenu("B24_BACKGROUND")
end

local bonusSummary

-- The engine's summary of the character, plus the background once it is chosen.
function B24CG_Information()
	local info = B24CG_SpeciesInformation(chargen.information or "")
	if state == nil or not state.bgConfirmed then return info end
	local bg = B24CG.BACKGROUNDS[state.bg]
	local lines = { info, "", "Background: " .. bg.name, bonusSummary(), "Origin feat: " .. B24CG.FEATS[bg.feat].name }
	if isHuman() then table.insert(lines, "Versatile: " .. B24CG.FEATS[state.feat2].name) end
	return table.concat(lines, "\n")
end

--------------------------
-- Kit and species steps --
--------------------------

-- Kit step: subclasses come at level 3, so the base class (the first entry of the engine's kit
-- list) is selected and the list is hidden.
function B24CG_KitOpen()
	if chargen.kit and chargen.kit[1] then
		currentChargenKit = 1
		createCharScreen:OnKitSelectButtonClick(chargen.kit[1].id)
	end
end

function B24CG_KitHelp()
	return B24CG.SUBCLASS_HELP
end

-- The race step's general help (shown before a species is picked) is defined in UI.MENU, which
-- loads after this file.
EEex_Menu_AddAfterMainFileLoadedListener(function()
	function raceOrGeneralHelp()
		local race = chargen.races[currentChargenRace]
		if race then return Infinity_FetchString(race.desc) end
		return B24CG.SPECIES_HELP
	end
end)

--------------------
-- Ability screen --
--------------------

function B24CG_Active()
	return state ~= nil
end

function B24CG_Title()
	if state == nil then return B24CG_Text("TITLE") end
	return B24CG_Text("TITLE") .. ": " .. B24CG.METHODS[state.method].label
end

-- Base score and background increase, e.g. "15+2"; "-" while no value is assigned.
function B24CG_RowText(i)
	if state == nil then return "" end
	local b = base(i)
	if b == nil then return B24CG_Text("UNASSIGNED") end
	if state.bonus[i] > 0 then return b .. "+" .. state.bonus[i] end
	return tostring(b)
end

function B24CG_PlusMinus(i, plus)
	if state == nil or i == nil then return end
	if isPointBuy() then
		local b = state.points[i]
		local new = b + (plus and 1 or -1)
		if new < 8 or new > 15 then return end
		if B24CG.POINT_COST[new] - B24CG.POINT_COST[b] > pointsLeft() then return end
		state.points[i] = new
		return
	end
	local assign = state.assign[state.method]
	local current = assign[i]
	local free = freeValues(i) -- high to low, includes the current value
	local pick = nil
	if plus then
		for _, v in ipairs(free) do
			if current == nil then pick = pick or v
			elseif v > current then pick = v end
		end
	else
		-- Minus gives the value back to the pool in one step.
		assign[i] = nil
		return
	end
	if pick ~= nil then assign[i] = pick end
end

-- While values are waiting to be distributed, the total row lists them instead of "Total".
function B24CG_TotalLabel()
	if state ~= nil and not isPointBuy() then
		local free = freeValues(nil)
		if #free > 0 then return B24CG_Text("LEFT") .. " " .. table.concat(free, " ") end
	end
	return B24CG_Text("TOTAL")
end

-- Sum of the final scores; values not assigned yet count as they will once placed.
function B24CG_TotalValue()
	if state == nil then return "" end
	local total = 0
	for i = 1, 6 do total = total + (final(i) or state.bonus[i]) end
	if not isPointBuy() then
		for _, v in ipairs(freeValues(nil)) do total = total + v end
	end
	return tostring(total)
end

function B24CG_ExtraValue()
	if state == nil then return "" end
	if isPointBuy() then return B24CG_Text("POINTS") .. " " .. pointsLeft() end
	if state.method == B24CG.METHOD_ROLL then return B24CG_Text("REROLLS") .. " " .. state.rerolls end
	return ""
end

function B24CG_MethodLabel()
	return B24CG_Text("CHANGE_METHOD")
end

function B24CG_NextMethod()
	if state == nil then return end
	state.method = state.method % #B24CG.METHODS + 1
	if state.method == B24CG.METHOD_ROLL and state.pool[B24CG.METHOD_ROLL] == nil then
		newRoll()
	end
end

-- Reset (the Recall button's place): point buy back to 8 everywhere, array and roll unassigned.
function B24CG_CanReset()
	if state == nil then return false end
	for i = 1, 6 do
		if isPointBuy() and state.points[i] ~= 8 or not isPointBuy() and state.assign[state.method][i] ~= nil then
			return true
		end
	end
	return false
end

function B24CG_Reset()
	if state == nil then return end
	if isPointBuy() then
		state.points = { 8, 8, 8, 8, 8, 8 }
	else
		state.assign[state.method] = {}
	end
	currentChargenAbility = nil
end

function B24CG_CanReroll()
	return state ~= nil and state.method == B24CG.METHOD_ROLL and state.rerolls > 0
end

function B24CG_Reroll()
	if not B24CG_CanReroll() then return end
	state.rerolls = state.rerolls - 1
	newRoll()
end

function B24CG_BackgroundLabel()
	return B24CG_Text("BG_TITLE")
end

function bonusSummary()
	local parts = {}
	for _, ability in ipairs(B24CG.BACKGROUNDS[state.bg].abilities) do
		if state.bonus[ability] > 0 then
			table.insert(parts, B24CG.ABILITIES[ability].short .. " +" .. state.bonus[ability])
		end
	end
	return table.concat(parts, ", ")
end

-- Always shown at the top of the help panel.
local function status()
	local method = B24CG.METHODS[state.method].label
	local lines = {}
	if isPointBuy() then
		table.insert(lines, string.format("%s: %d of %d points left", method, pointsLeft(), B24CG.POINT_BUY_TOTAL))
	else
		local free = freeValues(nil)
		local left = #free > 0 and table.concat(free, ", ") or "none"
		table.insert(lines, string.format("%s: values left to assign: %s", method, left))
		if state.method == B24CG.METHOD_ROLL then
			table.insert(lines, string.format("Rerolls left: %d", state.rerolls))
		end
	end
	local bg = B24CG.BACKGROUNDS[state.bg]
	table.insert(lines, string.format("Background: %s (%s), origin feat %s", bg.name, bonusSummary(),
		B24CG.FEATS[bg.feat].name))
	if isHuman() then
		table.insert(lines, "Versatile (Human): " .. B24CG.FEATS[state.feat2].name)
	end
	return table.concat(lines, "\n")
end

function B24CG_Help()
	if state == nil then return "" end
	local lines = { status(), "" }
	local i = currentChargenAbility
	local ability = i and chargen.ability[i]
	if ability == nil then
		table.insert(lines, B24CG.METHODS[state.method].help)
		table.insert(lines, "")
		table.insert(lines, "Each row shows the base score and the background's increase, e.g. 15+2. Change Method switches between point buy, the standard array and rolling. The background is chosen in the Background step of the main screen.")
	else
		local score = final(i)
		if score then
			table.insert(lines, string.format("%s %d (modifier %s): base %d, background %s", B24CG.ABILITIES[i].short,
				score, signed(modifier(score)), base(i), signed(state.bonus[i])))
		else
			table.insert(lines, string.format("%s: no value assigned yet, background %s", B24CG.ABILITIES[i].short,
				signed(state.bonus[i])))
		end
		table.insert(lines, "")
		table.insert(lines, B24CG.ABILITY_HELP[i])
	end
	return table.concat(lines, "\n")
end

local function bonusValid(bonus, bg)
	local values = {}
	for _, ability in ipairs(B24CG.BACKGROUNDS[bg].abilities) do table.insert(values, bonus[ability]) end
	table.sort(values)
	local a, b, c = values[1], values[2], values[3]
	return (a == 1 and b == 1 and c == 1) or (a == 0 and b == 1 and c == 2)
end

local function featValid(s)
	if B24CG_SpeciesKey() ~= "HUMAN" then return true end
	local bgFeat = B24CG.BACKGROUNDS[s.bg].feat
	return s.feat2 ~= bgFeat or B24CG.FEATS[bgFeat].repeatable == true
end

function B24CG_DoneClickable()
	return state ~= nil and allAssigned() and bonusValid(state.bonus, state.bg) and featValid(state)
		and (not isPointBuy() or pointsLeft() == 0)
end

-- Writes the final scores to the character in creation before the engine's Done handler runs.
function B24CG_Done()
	if state == nil or not allAssigned() then return end
	EEex_Utility_TryIgnore(function()
		local sprite = chargenSprite()
		if sprite == nil then return end
		for i, ability in ipairs(B24CG.ABILITIES) do
			sprite.m_baseStats[ability.field] = final(i)
		end
		sprite.m_baseStats.m_STRExtraBase = 0
		EngineGlobals.g_pBaldurChitin.m_pEngineCreateChar.m_nExtraAbilityPoints = 0
		sprite:setLocalInt("B24BG", state.bg)
		sprite:setLocalInt("B24FEAT2", isHuman() and state.feat2 or 0)
	end)
end

function B24CG_Noop()
end

----------------------
-- Background popup --
----------------------

local snapshot = nil

function B24CG_BgOpen()
	if state == nil then return end
	snapshot = { bg = state.bg, bonus = { table.unpack(state.bonus) }, feat2 = state.feat2 }
	b24cgBgRow = state.bg
end

function B24CG_BgName(row)
	return B24CG.BACKGROUNDS[row].name
end

function B24CG_BgSelect(row)
	if state == nil or B24CG.BACKGROUNDS[row] == nil or row == state.bg then return end
	state.bg = row
	defaultBonus(state, row)
	if not featValid(state) then state.feat2 = defaultExtraFeat(row) end
end

function B24CG_BgHelp()
	if state == nil then return "" end
	local bg = B24CG.BACKGROUNDS[state.bg]
	local names = {}
	for _, ability in ipairs(bg.abilities) do table.insert(names, B24CG.ABILITIES[ability].short) end
	local feat = B24CG.FEATS[bg.feat]
	local lines = {
		bg.name, "", bg.desc, "",
		"Ability scores: " .. table.concat(names, ", "),
		"Skills: " .. bg.skills,
		"Origin feat: " .. feat.name, feat.desc,
	}
	if isHuman() then
		local extra = B24CG.FEATS[state.feat2]
		table.insert(lines, "")
		table.insert(lines, "Versatile: " .. extra.name)
		table.insert(lines, extra.desc)
	end
	return table.concat(lines, "\n")
end

function B24CG_BonusText(k)
	if state == nil then return "" end
	local ability = B24CG.BACKGROUNDS[state.bg].abilities[k]
	return B24CG.ABILITIES[ability].short .. " +" .. state.bonus[ability]
end

function B24CG_CycleBonus(k)
	if state == nil then return end
	local ability = B24CG.BACKGROUNDS[state.bg].abilities[k]
	state.bonus[ability] = (state.bonus[ability] + 1) % 3
end

function B24CG_BgStatus()
	if state == nil then return "" end
	if not bonusValid(state.bonus, state.bg) then return B24CG_Text("BG_BONUS_INVALID") end
	if not featValid(state) then return B24CG_Text("BG_FEAT_DUPLICATE") end
	return ""
end

function B24CG_IsHuman()
	return state ~= nil and isHuman()
end

function B24CG_FeatText()
	if state == nil then return "" end
	return B24CG.FEATS[state.feat2].name
end

function B24CG_CycleFeat()
	if state == nil then return end
	repeat
		state.feat2 = state.feat2 % #B24CG.FEATS + 1
	until featValid(state)
end

function B24CG_BgDone()
	if state == nil or B24CG_BgStatus() ~= "" then return end
	state.bgConfirmed = true
	Infinity_PopMenu("B24_BACKGROUND")
end

-- Cancel keeps the previous choice; the first time that is the preselected background.
function B24CG_BgCancel()
	if state ~= nil and snapshot ~= nil then
		state.bg, state.bonus, state.feat2 = snapshot.bg, snapshot.bonus, snapshot.feat2
		state.bgConfirmed = true
	end
	Infinity_PopMenu("B24_BACKGROUND")
end

------------------------
-- Proficiency screen --
------------------------

-- In character creation the engine's weapon slots and thief points are replaced by the 2024
-- choices, one source per step: class skills, the human's Skillful skill, the Skilled feat,
-- Expertise (on skills already chosen) and Weapon Mastery. Only the steps that apply are shown.
-- The left list holds the current step, the right list all proficiencies so far. Done moves to
-- the next step, Back to the previous one. Level-up keeps the engine's screen.

B24CG.SKILL_HELP = {
	ACROBATICS = "Staying on your feet, tumbling and balancing.",
	ANIMAL_HANDLING = "Calming and controlling animals.",
	ARCANA = "Knowledge of spells, magic items and the planes. In BG it adds to Lore.",
	ATHLETICS = "Climbing, jumping, swimming and grappling.",
	DECEPTION = "Hiding the truth convincingly.",
	HISTORY = "Knowledge of past events, people and legends. In BG it adds to Lore.",
	INSIGHT = "Reading the intentions of others.",
	INTIMIDATION = "Influencing others through threats.",
	INVESTIGATION = "Finding clues and making deductions. In BG it sets Detect Illusion.",
	MEDICINE = "Stabilizing the dying and diagnosing illness.",
	NATURE = "Knowledge of terrain, plants, animals and weather.",
	PERCEPTION = "Spotting, hearing and noticing things. In BG it sets Find Traps and gives the Find Traps button.",
	PERFORMANCE = "Delighting an audience with music, dance or acting.",
	PERSUASION = "Influencing others with tact and goodwill.",
	RELIGION = "Knowledge of deities, rites and holy symbols.",
	SLEIGHT_OF_HAND = "Picking pockets and other manual trickery. In BG it sets Pick Pockets and gives the Thieving button.",
	STEALTH = "Moving unseen and unheard. In BG it sets Hide in Shadows and Move Silently and gives the Stealth button.",
	SURVIVAL = "Tracking, hunting and finding your way in the wild.",
	THIEVES_TOOLS = "Tool proficiency: picking locks and disarming traps. In BG it sets Open Locks, Set Traps and the disarm roll, and allows locks and traps with the Thieving button.",
}

B24CG.MASTERY_HELP = {
	Cleave = "Cleave: once per round, after a hit you also attack a second enemy next to you; it takes the weapon's dice without your ability modifier.",
	Graze = "Graze: when you miss, the target still takes damage equal to your Strength modifier (in BG only for misses caused by disadvantage).",
	Nick = "Nick: the extra off-hand attack is part of your attacks (BG already works this way).",
	Push = "Push: a hit pushes the target away from you.",
	Sap = "Sap: a hit gives the target disadvantage on its next attack.",
	Slow = "Slow: a hit reduces the target's speed by 10 feet for a round.",
	Topple = "Topple: a hit forces a Constitution save (DC 8 + your ability modifier + Proficiency Bonus), or the target falls prone for a round.",
	Vex = "Vex: a hit gives you advantage on your next attack against that target.",
}

B24CG.PROF_STEPS = {
	CLASS = { title = "Class skills",
	          help = "Choose the skills your class training gives you, from your class's list." },
	SKILLFUL = { title = "Skillful (Human)",
	             help = "Humans gain proficiency in one skill of their choice." },
	SKILLED = { title = "Skilled (feat)",
	            help = "The Skilled feat gives proficiency in three skills or tools of your choice." },
	EXPERTISE = { title = "Expertise",
	              help = "Choose skills or tools you are proficient in; Expertise doubles your proficiency bonus for them." },
	STYLE = { title = "Fighting Style",
	          help = "Fighters start with a Fighting Style feat. Champions gain a second one at level 7." },
	CANTRIP = { title = "Cantrips",
	            help = "Cantrips are spells you can cast at will, as often as you like. Choose them from your class's spell list; more come at higher levels." },
	MASTERY = { title = "Weapon Mastery",
	            help = "Choose weapons whose mastery property you can use. Each 2024 weapon covers the matching BG weapon types. A mastered weapon uses its property on every hit (Graze: on misses caused by disadvantage only)." },
}

-- Tables read by name by the two list widgets; their contents are rebuilt in place.
B24CG.PROF_ROWS = {}
B24CG.PROF_SUMMARY = {}

local function countKeys(set)
	local n = 0
	for _ in pairs(set) do n = n + 1 end
	return n
end

local function profState()
	if state.prof == nil then
		state.prof = { step = 1, class = {}, skillful = nil, skilled = {}, expertise = {}, mastery = {}, cantrip = {} }
	end
	return state.prof
end

local function hasFeat(key)
	local bgFeat = B24CG.FEATS[B24CG.BACKGROUNDS[state.bg].feat].key
	return bgFeat == key or (isHuman() and B24CG.FEATS[state.feat2].key == key)
end

local function skillClass()
	local sprite = chargenSprite()
	local key = sprite and B24.SkillClass(sprite)
	return key and B24.CLASS_SKILLS[key]
end

local function hasRogue()
	local sprite = chargenSprite()
	return sprite ~= nil and B24.ClassHasRogue(B24.ClassID(sprite))
end

local function expertiseCount()
	local class = skillClass()
	return (class and class.expertise) or (hasRogue() and 2 or 0)
end

local function masteryCount()
	local sprite = chargenSprite()
	return sprite and B24.MasteryCount(sprite) or 0
end

-- Proficiencies the character has without choosing, with their source.
local function grantedSkills()
	local granted = {}
	local class = skillClass()
	for _, key in ipairs(class and class.tools or {}) do granted[key] = "Class" end
	if hasRogue() then granted.THIEVES_TOOLS = "Class" end
	for _, key in ipairs((B24FEAT and B24FEAT.BACKGROUND_SKILLS[state.bg]) or {}) do granted[key] = "Background" end
	if B24CG_SpeciesKey() == "ELF" then granted.PERCEPTION = "Species" end
	return granted
end

-- Source of a proficiency, or nil.
local function sourceOf(key)
	local p = profState()
	return grantedSkills()[key] or (p.class[key] and "Class") or (p.skillful == key and "Skillful")
		or (p.skilled[key] and "Skilled")
end

-- Fighting Style at level 1 (Fighter component installed).
local function isFighter()
	local sprite = chargenSprite()
	return sprite ~= nil and B24.SkillClass(sprite) == "FIGHTER"
end

-- Cantrips of level 1 (Spells component installed): the count the in-game choice would ask for,
-- from the class's spell lists.
local function cantripCount()
	local sprite = chargenSprite()
	if sprite == nil or B24LV == nil or B24SP == nil then return 0 end
	local ok, pending = pcall(B24LV.Pending, sprite)
	return ok and pending.CANTRIP or 0
end

local function cantripOptions()
	local sprite = chargenSprite()
	local options = {}
	if sprite == nil or B24LV == nil or B24SP == nil then return options end
	local letters = B24LV.CasterLetters(sprite)
	for i, cantrip in ipairs(B24SP.CANTRIPS) do
		for letter in letters:gmatch(".") do
			if cantrip.lists:find(letter, 1, true) then
				table.insert(options, { cantrip = cantrip, index = i })
				break
			end
		end
	end
	return options
end

local function steps()
	local list = {}
	if B24LV and isFighter() then table.insert(list, "STYLE") end
	if skillClass() then table.insert(list, "CLASS") end
	if isHuman() then table.insert(list, "SKILLFUL") end
	if hasFeat("SKILLED") then table.insert(list, "SKILLED") end
	if expertiseCount() > 0 then table.insert(list, "EXPERTISE") end
	if masteryCount() > 0 then table.insert(list, "MASTERY") end
	if cantripCount() > 0 then table.insert(list, "CANTRIP") end
	return list
end

local function currentStep()
	local list = steps()
	local p = profState()
	p.step = math.max(1, math.min(p.step, #list))
	return list[p.step], p.step, #list
end

local function classOptions()
	local class = skillClass()
	return class and class.list or {}
end

-- Choices still to make in a step; a step whose options are all taken counts as done.
local function stepLeft(step)
	local p = profState()
	if step == "STYLE" then
		return p.style and 0 or 1
	elseif step == "CLASS" then
		local class = skillClass()
		local open = 0
		for _, key in ipairs(classOptions()) do
			if p.class[key] or not sourceOf(key) then open = open + 1 end
		end
		return math.max(0, math.min(class.count, open) - countKeys(p.class))
	elseif step == "SKILLFUL" then
		return p.skillful and 0 or 1
	elseif step == "SKILLED" then
		return math.max(0, 3 - countKeys(p.skilled))
	elseif step == "EXPERTISE" then
		return math.max(0, expertiseCount() - countKeys(p.expertise))
	elseif step == "MASTERY" then
		return math.max(0, masteryCount() - countKeys(p.mastery))
	elseif step == "CANTRIP" then
		return math.max(0, cantripCount() - countKeys(p.cantrip))
	end
	return 0
end

local function setRows(rows)
	for i = #B24CG.PROF_ROWS, 1, -1 do B24CG.PROF_ROWS[i] = nil end
	for i, row in ipairs(rows) do B24CG.PROF_ROWS[i] = row end
end

local function refreshSummary()
	local p = profState()
	for i = #B24CG.PROF_SUMMARY, 1, -1 do B24CG.PROF_SUMMARY[i] = nil end
	for _, skill in ipairs(B24.SKILLS) do
		local source = sourceOf(skill.key)
		if source then
			table.insert(B24CG.PROF_SUMMARY, { text = skill.name,
				note = p.expertise[skill.key] and "Expertise" or source })
		end
	end
	if p.style and B24LV then
		for _, style in ipairs(B24LV.STYLES) do
			if style.key == p.style then table.insert(B24CG.PROF_SUMMARY, { text = style.name, note = "Style" }) end
		end
	end
	for _, weapon in ipairs(B24.MASTERY_WEAPONS) do
		if p.mastery[weapon.key] then
			table.insert(B24CG.PROF_SUMMARY, { text = string.format("%s (%s)", weapon.name, weapon.mastery), note = "Mastery" })
		end
	end
	for i, cantrip in ipairs(B24SP and B24SP.CANTRIPS or {}) do
		if p.cantrip[i] then table.insert(B24CG.PROF_SUMMARY, { text = cantrip.name, note = "Cantrip" }) end
	end
end

-- Rebuilds the left list for the current step and drops choices an earlier change invalidated.
local function refresh()
	local p = profState()
	for key in pairs(p.expertise) do
		if not sourceOf(key) then p.expertise[key] = nil end
	end
	local step = currentStep()
	local rows = {}
	if step == "STYLE" then
		for _, style in ipairs(B24LV.STYLES) do table.insert(rows, { style = style }) end
	elseif step == "CLASS" then
		for _, key in ipairs(classOptions()) do table.insert(rows, { skill = key }) end
	elseif step == "SKILLFUL" or step == "SKILLED" or step == "EXPERTISE" then
		for _, skill in ipairs(B24.SKILLS) do
			local allowed = (step == "SKILLED") or (step == "SKILLFUL" and not skill.tool)
				or (step == "EXPERTISE" and sourceOf(skill.key) ~= nil)
			if allowed then table.insert(rows, { skill = skill.key }) end
		end
	elseif step == "MASTERY" then
		for _, weapon in ipairs(B24.MASTERY_WEAPONS) do table.insert(rows, { weapon = weapon }) end
	elseif step == "CANTRIP" then
		rows = cantripOptions()
	end
	setRows(rows)
	refreshSummary()
end

-- Level-up: the screen lists what the new levels give (B24LEVEL.lua) instead of weapon slots and
-- thief points; the choices (subclass, ability scores, ...) open in game afterwards.
local function levelUpRows()
	local sprite = chargenSprite()
	local rows, summary = {}, {}
	if sprite and B24LV then
		for _, line in ipairs(B24LV.FeatureLines(sprite)) do table.insert(rows, { text = line }) end
		local pending = B24LV.Pending(sprite)
		for _, kind in ipairs(B24LV.CHOICE_ORDER) do
			if pending[kind] > 0 then table.insert(summary, { text = B24LV.CHOICE_TITLES[kind] }) end
		end
	end
	if #rows == 0 then table.insert(rows, { text = "The new level gives no class feature that needs your attention here." }) end
	if #summary == 0 then table.insert(summary, { text = "none" }) end
	setRows(rows)
	for i = #B24CG.PROF_SUMMARY, 1, -1 do B24CG.PROF_SUMMARY[i] = nil end
	for i, row in ipairs(summary) do B24CG.PROF_SUMMARY[i] = row end
end

function B24CG_ProfOpen()
	if chargen.levelingUp then
		b24cgSkillRow = nil
		EEex_Utility_TryIgnore(levelUpRows)
		return
	end
	syncState()
	profState().step = 1
	b24cgSkillRow = nil
	refresh()
end

function B24CG_ProfLeftLabel()
	if chargen.levelingUp then return "New at this level:" end
	if state == nil then return "" end
	local step, index, total = currentStep()
	if step == nil then return "No proficiency choices" end
	return string.format("%s (step %d of %d), choices left:", B24CG.PROF_STEPS[step].title, index, total)
end

function B24CG_ProfLeftValue()
	if chargen.levelingUp then return "" end
	if state == nil then return "" end
	return tostring(stepLeft(currentStep()))
end

function B24CG_ProfRightLabel()
	if chargen.levelingUp then return "Choices after the level-up:" end
	return "Your proficiencies"
end

function B24CG_ProfRightValue()
	return ""
end

function B24CG_SummaryText(row)
	local entry = B24CG.PROF_SUMMARY[row]
	return entry and entry.text or ""
end

-- The source of a summary row (Background, Class, Expertise, ...), in the narrow box on the right.
function B24CG_SummaryNote(row)
	local entry = B24CG.PROF_SUMMARY[row]
	return entry and entry.note or ""
end

local function weaponProficient(weapon)
	local sprite = chargenSprite()
	local profType = B24.MasteryWeaponProfType(weapon.key)
	return sprite == nil or profType == nil or B24.IsWeaponProficient(sprite, profType)
end

function B24CG_ProfRowName(row)
	local entry = B24CG.PROF_ROWS[row]
	if entry == nil then return "" end
	if entry.text then return entry.text end
	if entry.style then return entry.style.name end
	if entry.weapon then return string.format("%s (%s)", entry.weapon.name, entry.weapon.mastery) end
	if entry.cantrip then return entry.cantrip.name end
	return B24.SKILLS[B24.SkillIndex[entry.skill]].name
end

function B24CG_ProfRowState(row)
	local entry = B24CG.PROF_ROWS[row]
	if entry == nil or state == nil then return "" end
	if entry.text then return "" end
	local p = profState()
	local step = currentStep()
	if entry.style then return p.style == entry.style.key and "Chosen" or "" end
	if entry.cantrip then return p.cantrip[entry.index] and "Chosen" or "" end
	if entry.weapon then
		if p.mastery[entry.weapon.key] then return "Mastered" end
		return weaponProficient(entry.weapon) and "" or "not proficient"
	end
	local key = entry.skill
	if step == "EXPERTISE" then
		return p.expertise[key] and "Expertise" or ""
	end
	local chosenHere = (step == "CLASS" and p.class[key]) or (step == "SKILLFUL" and p.skillful == key)
		or (step == "SKILLED" and p.skilled[key])
	if chosenHere then return "Chosen" end
	local source = sourceOf(key)
	return source and ("already: " .. source) or ""
end

function B24CG_ProfRowClick(row)
	local entry = B24CG.PROF_ROWS[row]
	if entry == nil or state == nil then return end
	if entry.text then return end
	local p = profState()
	local step = currentStep()
	if step == "STYLE" then
		p.style = (p.style ~= entry.style.key) and entry.style.key or nil
	elseif step == "MASTERY" then
		local key = entry.weapon.key
		if p.mastery[key] then
			p.mastery[key] = nil
		elseif weaponProficient(entry.weapon) and stepLeft(step) > 0 then
			p.mastery[key] = true
		end
	elseif step == "CANTRIP" then
		if p.cantrip[entry.index] then
			p.cantrip[entry.index] = nil
		elseif stepLeft(step) > 0 then
			p.cantrip[entry.index] = true
		end
	elseif step == "EXPERTISE" then
		local key = entry.skill
		if p.expertise[key] then
			p.expertise[key] = nil
		elseif stepLeft(step) > 0 then
			p.expertise[key] = true
		end
	else
		local key = entry.skill
		local pool = (step == "CLASS" and p.class) or (step == "SKILLED" and p.skilled) or nil
		if step == "SKILLFUL" then
			if p.skillful == key then
				p.skillful = nil
			elseif not sourceOf(key) then
				p.skillful = key
			end
		elseif pool[key] then
			pool[key] = nil
		elseif not sourceOf(key) and stepLeft(step) > 0 then
			pool[key] = true
		end
	end
	refresh()
end

local function profHelp()
	local step = currentStep()
	local lines = {}
	local entry = b24cgSkillRow and B24CG.PROF_ROWS[b24cgSkillRow]
	if entry and entry.style then
		table.insert(lines, entry.style.name .. ": " .. entry.style.desc)
		table.insert(lines, "")
	elseif entry and entry.skill then
		local skill = B24.SKILLS[B24.SkillIndex[entry.skill]]
		table.insert(lines, string.format("%s (%s)", skill.name, skill.ability))
		table.insert(lines, B24CG.SKILL_HELP[skill.key])
		table.insert(lines, "")
	elseif entry and entry.cantrip then
		table.insert(lines, entry.cantrip.name .. ": " .. Infinity_FetchString(B24LV.CantripDescription(entry.cantrip)))
		table.insert(lines, "")
	elseif entry and entry.weapon then
		table.insert(lines, string.format("%s, mastery property %s. In BG: %s.", entry.weapon.name,
			entry.weapon.mastery, entry.weapon.bg))
		table.insert(lines, B24CG.MASTERY_HELP[entry.weapon.mastery] or "")
		table.insert(lines, "")
	end
	if step then
		table.insert(lines, B24CG.PROF_STEPS[step].title .. ": " .. B24CG.PROF_STEPS[step].help)
	end
	table.insert(lines, "")
	table.insert(lines, "Background and species proficiencies are already set and listed on the right. Click a choice again to remove it. Done continues to the next step, Back returns to the previous one.")
	table.insert(lines, "")
	table.insert(lines, "Weapons: your class makes you proficient with its weapons; with other weapons you attack without your proficiency bonus.")
	return table.concat(lines, "\n")
end

EEex_Menu_AddAfterMainFileLoadedListener(function()
	local original = proficiencyOrGeneralHelp
	function proficiencyOrGeneralHelp()
		if chargen.levelingUp or state == nil then return original() end
		return profHelp()
	end
end)

function B24CG_ProfDoneClickable()
	if chargen.levelingUp then return true end
	if state == nil then return false end
	return stepLeft(currentStep()) == 0
end

function B24CG_ProfDoneText()
	if chargen.levelingUp or state == nil then return getUiString("DONE_BUTTON") end
	local _, index, total = currentStep()
	return getUiString(index < total and "NEXT_BUTTON" or "DONE_BUTTON")
end

-- Back: previous step if there is one (returns true), otherwise the engine's Back.
function B24CG_ProfBack()
	if chargen.levelingUp or state == nil then return false end
	local p = profState()
	if p.step > 1 then
		p.step = p.step - 1
		b24cgSkillRow = nil
		refresh()
		return true
	end
	return false
end

-- The engine still hands out weapon slots and thief points; they are spent here so its Done
-- check passes (stars and points have no effect in this mod).
local function spendEnginePoints(countField, rowsField, click)
	for _ = 1, 200 do
		local before = chargen[countField] or 0
		if before <= 0 then return end
		for _, row in ipairs(chargen[rowsField] or {}) do
			click(row.id)
			if (chargen[countField] or 0) < before then break end
		end
		if (chargen[countField] or 0) >= before then return end
	end
end

local function spendAllEnginePoints()
	spendEnginePoints("extraProficiencySlots", "proficiency", function(id)
		createCharScreen:OnProficiencyPlusMinusButtonClick(id, true)
	end)
	spendEnginePoints("extraSkillPoints", "thief_skill", function(id)
		createCharScreen:OnThiefSkillPlusMinusButtonClick(id, true)
	end)
end

local function writeChoices()
	local sprite = chargenSprite()
	if sprite == nil then return end
	local p = profState()
	sprite:setLocalInt("B24SKSET", 1)
	sprite:setLocalInt("B24SKILL", B24.SkillsToMask(p.class))
	sprite:setLocalInt("B24SKEXP", B24.SkillsToMask(p.expertise))
	sprite:setLocalInt("B24SKHUM", p.skillful and B24.SkillIndex[p.skillful] or 0)
	sprite:setLocalInt("B24SKFT", B24.SkillsToMask(p.skilled))
	local mastery = 0
	for i, weapon in ipairs(B24.MASTERY_WEAPONS) do
		if p.mastery[weapon.key] then mastery = EEex_BOr(mastery, EEex_LShift(1, i - 1)) end
	end
	sprite:setLocalInt("B24MAST", mastery)
	local cantrips = 0
	for i in pairs(p.cantrip or {}) do cantrips = EEex_BOr(cantrips, EEex_LShift(1, i - 1)) end
	sprite:setLocalInt("B24CANT", cantrips)
	local styles = 0
	for i, style in ipairs(B24LV and B24LV.STYLES or {}) do
		if style.key == p.style then styles = EEex_LShift(1, i - 1) end
	end
	if B24LV then sprite:setLocalInt("B24FSTY", styles) end
end

-- Done: next step (returns false), or after the last step store the choices and let the engine
-- finish the screen (returns true).
function B24CG_ProfDone()
	if chargen.levelingUp then
		EEex_Utility_TryIgnore(spendAllEnginePoints)
		return true
	end
	if state == nil then return true end
	local p = profState()
	local _, index, total = currentStep()
	if index < total then
		p.step = p.step + 1
		b24cgSkillRow = nil
		refresh()
		return false
	end
	EEex_Utility_TryIgnore(writeChoices)
	EEex_Utility_TryIgnore(spendAllEnginePoints)
	return true
end

-------------------
-- Species step --
-------------------

-- The race step lists the ten 2024 species (B24SPEC.SPECIES). Picking one selects its body race
-- in the engine and stores the species on the character; species with lineages (Dragonborn,
-- Goliath, Tiefling) open the B24_LINEAGE popup.

-- Chosen species per character in creation: [sprite id] = { species = index, lineage = index }.
local chosenSpecies = {}

local ENGINE_RACE_NAMES = { [1] = "human", [2] = "elf", [4] = "dwarf", [5] = "halfling", [6] = "gnome", [7] = "half-orc" }

local function speciesChoice()
	local sprite = chargenSprite()
	return sprite and chosenSpecies[sprite.m_id]
end

-- Species key of the character in creation (from the choice, else from its engine race).
function B24CG_SpeciesKey()
	local choice = speciesChoice()
	if choice then return B24SPEC.SPECIES[choice.species].key end
	local sprite = chargenSprite()
	return sprite and B24SPEC.FROM_RACE[sprite.m_typeAI.m_Race]
end

local function writeSpecies()
	local sprite, choice = chargenSprite(), speciesChoice()
	if sprite == nil or choice == nil then return end
	sprite:setLocalInt("B24SPC", choice.species)
	sprite:setLocalInt("B24LIN", choice.lineage or 0)
end

function B24CG_SpeciesName(row)
	local species = B24SPEC.SPECIES[row]
	return species and species.name or ""
end

-- Finds the engine's race entry for a body race: by id, else by name.
local function engineRace(body)
	for _, race in ipairs(chargen.races or {}) do
		if race.id == body then return race end
	end
	for _, race in ipairs(chargen.races or {}) do
		if Infinity_FetchString(race.name):lower() == ENGINE_RACE_NAMES[body] then return race end
	end
end

function B24CG_SpeciesSelect(row)
	local species = B24SPEC.SPECIES[row]
	local sprite = chargenSprite()
	if species == nil or sprite == nil then return end
	local race = engineRace(species.body)
	if race == nil then return end
	createCharScreen:OnRaceSelectButtonClick(race.id)
	sprite = chargenSprite()
	chosenSpecies[sprite.m_id] = { species = row, lineage = nil }
	EEex_Utility_TryIgnore(writeSpecies)
	if species.lineages then
		Infinity_PushMenu("B24_LINEAGE")
	end
end

-- The appearance screen (CHARACTER_COLOR, onOpen; b24_chargen.tpa) opening for the first time
-- after a species was chosen: a species whose body race has the wrong default skin (the Goliath on
-- the half-orc body) starts with its own skin color. The player can still change it there.
function B24CG_DefaultSkin()
	if e:GetActiveEngine() ~= createCharScreen then return end
	local sprite = chargenSprite()
	local choice = sprite and chosenSpecies[sprite.m_id]
	if choice == nil or choice.skinSet then return end
	choice.skinSet = true
	local skin = B24SPEC.SPECIES[choice.species].skin
	if skin == nil then return end
	SLIDER_color_skin = skin
	SLIDER_color_skin_start = skin
	Infinity_SetSkinColor(skin)
end

-- Done on the race step needs a species and, if it has lineages, a lineage.
function B24CG_SpeciesReady()
	local choice = speciesChoice()
	if choice == nil then return false end
	return B24SPEC.SPECIES[choice.species].lineages == nil or choice.lineage ~= nil
end

local function speciesLabel()
	local choice = speciesChoice()
	if choice == nil then return nil end
	local species = B24SPEC.SPECIES[choice.species]
	local lineage = species.lineages and species.lineages[choice.lineage or 0]
	return lineage and string.format("%s (%s)", species.name, lineage.name) or species.name
end

-- The engine's character summary names the body race; it shows the species instead.
function B24CG_SpeciesInformation(info)
	local label = speciesLabel()
	if label == nil then return (info:gsub("Race:", "Species:")) end
	return (info:gsub("Race:[^\n]*", "Species: " .. label))
end

EEex_Menu_AddAfterMainFileLoadedListener(function()
	function raceOrGeneralHelp()
		local species = B24SPEC.SPECIES[currentChargenRace or 0]
		if species then return species.desc end
		return B24CG.SPECIES_HELP
	end
end)

----------------------
-- Lineage popup --
----------------------

B24CG.LINEAGE_ROWS = {}

local function lineageSpecies()
	local choice = speciesChoice()
	return choice and B24SPEC.SPECIES[choice.species]
end

function B24CG_LineageOpen()
	for i = #B24CG.LINEAGE_ROWS, 1, -1 do B24CG.LINEAGE_ROWS[i] = nil end
	local species = lineageSpecies()
	for i, lineage in ipairs(species and species.lineages or {}) do B24CG.LINEAGE_ROWS[i] = lineage end
	local choice = speciesChoice()
	b24cgLineageRow = choice and choice.lineage
end

function B24CG_LineageTitle()
	local species = lineageSpecies()
	return species and species.lineageTitle or ""
end

function B24CG_LineageName(row)
	local lineage = B24CG.LINEAGE_ROWS[row]
	return lineage and lineage.name or ""
end

function B24CG_LineageSelect(row)
	local choice = speciesChoice()
	if choice and B24CG.LINEAGE_ROWS[row] then
		choice.lineage = row
		EEex_Utility_TryIgnore(writeSpecies)
	end
end

function B24CG_LineageHelp()
	local species = lineageSpecies()
	if species == nil then return "" end
	local lineage = B24CG.LINEAGE_ROWS[b24cgLineageRow or 0]
	local lines = { species.name .. ": " .. species.lineageTitle, "" }
	if lineage then
		table.insert(lines, lineage.name)
		if lineage.damage then
			table.insert(lines, string.format("Damage type: %s.", B24SPEC.DAMAGE[lineage.damage].name))
		end
		if lineage.desc then table.insert(lines, lineage.desc) end
	else
		table.insert(lines, "Choose one.")
	end
	return table.concat(lines, "\n")
end

function B24CG_LineageDone()
	local choice = speciesChoice()
	if choice == nil or choice.lineage == nil then return end
	Infinity_PopMenu("B24_LINEAGE")
end

-----------------
-- Class step --
-----------------

-- The 2024 classes BG has, under their 2024 names. Barbarian is the Fighter class with the
-- Barbarian kit, picked automatically on the kit step. Multiclasses and the Shaman are not
-- offered (multiclassing is decided later). The dual-class screen keeps the engine's list.
B24CG.CLASSES = {
	{ name = "Barbarian", id = 2, barbarian = true,
	  desc = "BARBARIAN: A fierce warrior of primal rage. Hit die d12, proficient with simple and martial weapons, Weapon Mastery.\n\nIn BG: the Fighter class with the Barbarian kit. 2024 class features arrive with the class updates of this mod." },
	{ name = "Bard", id = 5,
	  desc = "BARD: An inspiring magician whose power echoes the music of creation. Hit die d8, simple weapons, three skills of your choice.\n\nIn BG: the Bard class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Cleric", id = 3,
	  desc = "CLERIC: A priestly champion who wields divine magic in service of a god. Hit die d8, simple weapons.\n\nIn BG: the Cleric class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Druid", id = 11,
	  desc = "DRUID: A priest of the Old Faith, wielding the powers of nature and taking on animal forms. Hit die d8, simple weapons.\n\nIn BG: the Druid class. Its 2024 class features are part of this mod's MVP." },
	{ name = "Fighter", id = 2,
	  desc = "FIGHTER: A master of all arms and armor. Hit die d10, proficient with simple and martial weapons, Weapon Mastery.\n\nIn BG: the Fighter class. Its 2024 class features are part of this mod's MVP." },
	{ name = "Monk", id = 20,
	  desc = "MONK: A martial artist who harnesses the power of the body. Hit die d8, simple and light martial weapons.\n\nIn BG: the Monk class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Paladin", id = 6,
	  desc = "PALADIN: A holy warrior bound to a sacred oath. Hit die d10, proficient with simple and martial weapons, Weapon Mastery.\n\nIn BG: the Paladin class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Ranger", id = 12,
	  desc = "RANGER: A warrior who combats threats on the edges of civilization. Hit die d10, proficient with simple and martial weapons, Weapon Mastery.\n\nIn BG: the Ranger class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Rogue", id = 4,
	  desc = "ROGUE: A scoundrel who uses stealth and trickery to overcome obstacles. Hit die d8, simple weapons and martial weapons with the Finesse or Light property, Thieves' Tools, Expertise, Weapon Mastery.\n\nIn BG: the Thief class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Sorcerer", id = 19,
	  desc = "SORCERER: A spellcaster who draws on inherent magic from a gift or bloodline. Hit die d6, simple weapons.\n\nIn BG: the Sorcerer class. 2024 class features arrive with the class updates of this mod." },
	{ name = "Wizard", id = 1,
	  desc = "WIZARD: A scholarly magic-user capable of manipulating the structures of reality. Hit die d6, simple weapons.\n\nIn BG: the Mage class. Its 2024 class features are part of this mod's MVP." },
}

B24CG.CLASS_ROWS = {}

-- Barbarian choice per character in creation: [sprite id] = true.
local chosenBarbarian = {}

local function dualClassing()
	return createCharScreen:GetCurrentStep() == const.STEP_DUALCLASS_CLASS
end

-- Rebuilds the list: the 2024 classes the engine offers for this character, or the engine's own
-- list while dual-classing.
function B24CG_ClassOpen()
	for i = #B24CG.CLASS_ROWS, 1, -1 do B24CG.CLASS_ROWS[i] = nil end
	if dualClassing() then
		for _, class in ipairs(chargen.class or {}) do
			table.insert(B24CG.CLASS_ROWS, { name = Infinity_FetchString(class.name), id = class.id,
				desc = Infinity_FetchString(class.desc) })
		end
		return
	end
	local offered = {}
	for _, class in ipairs(chargen.class or {}) do offered[class.id] = true end
	for _, class in ipairs(B24CG.CLASSES) do
		if offered[class.id] then table.insert(B24CG.CLASS_ROWS, class) end
	end
end

function B24CG_ClassName(row)
	local class = B24CG.CLASS_ROWS[row]
	return class and class.name or ""
end

function B24CG_ClassSelect(row)
	local class = B24CG.CLASS_ROWS[row]
	if class == nil then return end
	createCharScreen:OnClassSelectButtonClick(class.id)
	local sprite = chargenSprite()
	if sprite then chosenBarbarian[sprite.m_id] = class.barbarian == true end
end

EEex_Menu_AddAfterMainFileLoadedListener(function()
	function classOrGeneralHelp()
		local class = B24CG.CLASS_ROWS[currentChargenClass or 0]
		if class then return class.desc end
		return "Choose your class. The classes are the 2024 classes this game has; each lists what its 2024 version gives at level 1, and which parts of it are already in this mod."
	end
end)

-- Kit step: the Barbarian choice picks the Barbarian kit, everything else the base class.
local function barbarianKit()
	for i, kit in ipairs(chargen.kit or {}) do
		if Infinity_FetchString(kit.name):lower():find("barbarian") then return i, kit end
	end
end

local originalKitOpen = B24CG_KitOpen
function B24CG_KitOpen()
	local sprite = chargenSprite()
	if sprite and chosenBarbarian[sprite.m_id] then
		local index, kit = barbarianKit()
		if kit then
			currentChargenKit = index
			createCharScreen:OnKitSelectButtonClick(kit.id)
			return
		end
	end
	originalKitOpen()
end
