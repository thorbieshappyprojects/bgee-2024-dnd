-- BG 2024 Rules Mod: automated character creation test (loaded by B24TEST.lua when
-- B24TEST_MODE is "chargen"; tools/ingame-test.ps1 -Mode Chargen).
--
-- Starts a new game and goes through character creation the way a player would: every click of
-- the test script runs one step (what the menu's own buttons run), and the screen after each step
-- is saved as a screenshot ("[B24TEST] SHOT <name>"). In the game it logs what the new character
-- got (class, species, background, scores, skills, masteries, HP, AC).

B24TCG = B24TCG or {}

-- The test module's out keeps track of CLICKS ON/OFF (B24T.clicks): one record of what the test
-- script was last told.
local function out(text)
	if text == "CLICKS ON" then B24T.clicks = true elseif text == "CLICKS OFF" then B24T.clicks = false end
	print("[B24TEST] " .. text)
end

-- Point-buy 15/14/13/12/10/8 in this order (27 points), best score first for the class.
local ORDERS = {
	Wizard   = { "INT", "CON", "DEX", "WIS", "CHA", "STR" },
	Cleric   = { "WIS", "CON", "STR", "DEX", "CHA", "INT" },
	Druid    = { "WIS", "CON", "DEX", "INT", "CHA", "STR" },
	Sorcerer = { "CHA", "CON", "DEX", "WIS", "INT", "STR" },
	Bard     = { "CHA", "DEX", "CON", "WIS", "INT", "STR" },
	Paladin  = { "STR", "CHA", "CON", "WIS", "DEX", "INT" },
	Rogue    = { "DEX", "CON", "INT", "WIS", "CHA", "STR" },
	Ranger   = { "DEX", "WIS", "CON", "STR", "INT", "CHA" },
	Monk     = { "DEX", "WIS", "CON", "STR", "INT", "CHA" },
}

-- The character to create.
B24TCG.SPEC = B24TCG.SPEC or {
	name = "Test", gender = 1, species = B24TEST_SPECIES or "HUMAN",
	-- The class from the test script's -Classes (first name), Fighter by default.
	class = (B24TEST_CLASSES or ""):match("^([^,]+)") or "Fighter",
}
B24TCG.SPEC.order = B24TCG.SPEC.order or ORDERS[B24TCG.SPEC.class] or { "STR", "CON", "DEX", "WIS", "CHA", "INT" }
-- Spells to pick first where offered (then the list order).
local SPELL_PREFERENCE = { "Magic Missile", "Shield", "Sleep", "Burning Hands", "Mage Armor", "Chromatic Orb" }

-- Row numbers of chargen.choose_spell, preferred spells first.
-- book: the UI's spell table of the screen (spellBook or mageSpells).
local function spellRows(book)
	local rows, ranked = {}, {}
	for i, entry in ipairs(chargen.choose_spell or {}) do
		local ok, name = pcall(function()
			return Infinity_FetchString(book[chargen.currentSpellLevelChoice][entry.key].name)
		end)
		local rank = 100 + i
		for r, wanted in ipairs(SPELL_PREFERENCE) do
			if ok and name == wanted then rank = r end
		end
		table.insert(rows, i)
		ranked[i] = rank
	end
	table.sort(rows, function(a, b) return ranked[a] < ranked[b] end)
	return rows
end
local ABILITY_INDEX ={ STR = 1, DEX = 2, CON = 3, INT = 4, WIS = 5, CHA = 6 }
local SCORES = { 15, 14, 13, 12, 10, 8 }

B24TCG.step = 0          -- screenshot counter
B24TCG.menuState = {}    -- [menu] = number of actions done since it opened
B24TCG.lastMenu = nil

local function shot(menu, what)
	B24TCG.step = B24TCG.step + 1
	out(string.format("SHOT %02d-%s-%s", B24TCG.step, menu, what))
end

-- Topmost menu the test knows (popups first).
local MENUS = {
	"CHAPTER", "WORLD_DIALOG", "B24_LEVELUP", "CHARGEN_IMPORT", "CHARACTER_SELECT", "POPUP_TWOBUTTON", "POPUP_THREEBUTTON", "B24_LINEAGE", "B24_BACKGROUND", "CHARGEN_DIFFICULTY", "CHARGEN_NAME", "CHARGEN_BIO", "CHARGEN_HATEDRACE",
	"CHARGEN_CUSTOMSOUNDS", "CHARGEN_MEMORIZE_PRIEST", "CHARGEN_MEMORIZE_MAGE", "CHARGEN_CHOOSE_SPELLS",
	"CHARGEN_PROFICIENCIES", "CHARGEN_ABILITIES", "CHARGEN_ALIGNMENT", "CHARGEN_KIT", "CHARGEN_CLASS",
	"CHARGEN_RACE", "CHARGEN_PORTRAIT", "CHARGEN_GENDER", "CHARACTER_COLOR", "CHARGEN", "START_SP", "START", "CHARACTER",
}
B24TCG.MENUS = MENUS

local function topMenu()
	for _, name in ipairs(MENUS) do
		if Infinity_IsMenuOnStack(name) then return name end
	end
end

local function done()
	Infinity_PopMenu()
	createCharScreen:OnDoneButtonClick()
end

local function findRow(rows, test)
	for i, row in ipairs(rows or {}) do
		if test(row) then return i end
	end
end

-- Per menu: the first call selects (n == 0), later calls finish it. Returns a short label.
local ACTIONS = {
	START = function()
		-- BG2:EE's start screen picks the campaign first (as its Shadows of Amn button does): without one
		-- the engine caps the XP at BG1's 161000.
		if B24TEST_GAME == "BG2:EE" then
			-- Throne of Bhaal (B24TEST_CAMPAIGN = "TOB"): its new game starts with ToB's XP.
			if B24TEST_CAMPAIGN == "TOB" then startEngine:OnToBButtonClick(true) else startEngine:OnSoAButtonClick(true) end
		end
		startEngine:OnNewGameButtonClick()
		return "new-game"
	end,
	START_SP = function()
		Infinity_PopMenu()
		startEngine:OnNewGameButtonClick()
		return "new-game"
	end,
	CHARGEN = function()
		-- Import (B24TEST_IMPORT): the exported character instead of a new one.
		-- The import moves character creation on to its last step (with one file, BG2:EE takes it
		-- without the list); pressing Import there again crashes the game. Again only on step 0.
		if B24TEST_IMPORT and B24TCG.imported == "open" and createCharScreen:GetCurrentStep() ~= 0 then
			B24TCG.imported = true
			out("imported " .. B24TEST_IMPORT)
		end
		if B24TEST_IMPORT and B24TCG.imported ~= true and (B24TCG.importClicks or 0) < 4
			and createCharScreen:GetCurrentStep() == 0 then
			B24TCG.importClicks = (B24TCG.importClicks or 0) + 1
			B24TCG.imported = "open"
			out(string.format("import: screen %s, step %s", tostring(Infinity_GetCurrentScreenName()), tostring(createCharScreen:GetCurrentStep())))
			createCharScreen:OnImportCharacterButtonClick()
			return "import"
		end
		if B24TEST_IMPORT and B24TCG.imported ~= true then error("the import list did not open") end
		if createCharScreen:IsChargenComplete() then
			-- The new game's intro movies follow (a marker in the log).
			out("MOVIES")
			createCharScreen:AcceptCharacter(-1)
			return "accept"
		end
		local step = createCharScreen:GetCurrentStep()
		if step == B24CG.STEP_ABILITIES and not B24CG_BackgroundDone() then
			B24CG_OpenBackground()
			return "background"
		end
		createCharScreen:OnMenuButtonClick()
		return "step" .. step
	end,
	-- BG2:EE's import list (characters with portrait and description): the exported one, then Done
	-- as the menu's button does.
	-- During the import BG2:EE asks whether to import a saved game or a character: the character
	-- (the button whose text says so), as the popup's own button does.
	POPUP_TWOBUTTON = function() return B24TCG.PopupChoice(2) end,
	POPUP_THREEBUTTON = function() return B24TCG.PopupChoice(3) end,
	CHARACTER_SELECT = function(n)
		-- Second click: Done, as a player presses it after choosing.
		if n > 0 then
			if selectedCharacter == nil or selectedCharacter == 0 then error("no character chosen in the import list") end
			createCharScreen:OnDoneButtonClick()
			Infinity_PopMenu("CHARACTER_SELECT")
			B24TCG.imported = true
			out("imported " .. B24TEST_IMPORT)
			return "done"
		end
		local index, names = nil, {}
		for i, row in ipairs(character_select or {}) do
			local text = tostring(row.name) .. " " .. tostring(row.desc)
			table.insert(names, (text:gsub("\n", " ")))
			-- The list shows character names, not file names: the exported test character is "Test".
			if index == nil and (text:upper():find(B24TEST_IMPORT:upper(), 1, true) or text:find("^Test %-")) then index = i end
		end
		out("import list: " .. table.concat(names, " | "))
		if index == nil then error("no " .. B24TEST_IMPORT .. " in the import list") end
		selectedCharacter = index
		Infinity_OnCharacterImportItemSelect(index - 1)
		return "select"
	end,
	CHARGEN_IMPORT = function()
		local index
		for i, name in ipairs(list_GUICG_20_2 or {}) do
			if tostring(name):upper():find(B24TEST_IMPORT:upper(), 1, true) then index = i end
		end
		if index == nil then error("no " .. B24TEST_IMPORT .. " in the import list") end
		Infinity_OnCharacterImportItemSelect(index - 1)
		Infinity_PopMenu("CHARGEN_IMPORT")
		createCharScreen:OnDoneButtonClick()
		B24TCG.imported = true
		return "imported"
	end,
	CHARGEN_GENDER = function(n)
		if n == 0 then
			createCharScreen:OnGenderSelectButtonClick(B24TCG.SPEC.gender)
			return "select"
		end
		done()
		return "done"
	end,
	-- Selecting a species with lineages opens the lineage popup; back on this screen the species
	-- stays selected.
	CHARGEN_RACE = function(n)
		if not B24TCG.speciesSelected then
			B24TCG.speciesSelected = true
			local row = findRow(B24SPEC.SPECIES, function(s) return s.key == B24TCG.SPEC.species end)
			currentChargenRace = row
			B24CG_SpeciesSelect(row)
			return "select-" .. B24TCG.SPEC.species
		end
		if not B24CG_SpeciesReady() then return "not-ready" end
		done()
		return "done"
	end,
	B24_LINEAGE = function(n)
		if n == 0 then
			b24cgLineageRow = 1
			B24CG_LineageSelect(1)
			return "select"
		end
		B24CG_LineageDone()
		return "done"
	end,
	CHARGEN_CLASS = function(n)
		if n == 0 then
			local row = findRow(B24CG.CLASS_ROWS, function(c) return c.name == B24TCG.SPEC.class end)
			if row == nil then return "class-not-offered" end
			currentChargenClass = row
			B24CG_ClassSelect(row)
			return "select-" .. B24TCG.SPEC.class
		end
		createCharScreen:OnDoneButtonClick()
		Infinity_PopMenu("CHARGEN_CLASS")
		return "done"
	end,
	-- The chapter text after Venture Forth: Done once it can be clicked.
	CHAPTER = function()
		if not chapterScreen:IsDoneButtonClickable() then return "wait" end
		chapterScreen:OnDoneButtonClick()
		return "done"
	end,
	-- Appearance colors: the menu's Done keeps the default colors.
	CHARACTER_COLOR = function(n)
		-- Diagnostics: the skin value the screen shows and the size of its skin list.
		if n == 0 then
			out(string.format("appearance: skin slider %s, character skin %s, skin list size %s", tostring(SLIDER_color_skin),
				tostring(characters and id and characters[id] and characters[id].colors.skin),
				tostring(pcall(function() return game:GetPaletteSize(3) end) and game:GetPaletteSize(3))))
			return "look"
		end
		SLIDER_color_hair_start = SLIDER_color_hair
		SLIDER_color_skin_start = SLIDER_color_skin
		SLIDER_color_major_start = SLIDER_color_major
		SLIDER_color_minor_start = SLIDER_color_minor
		createCharScreen:OnDoneButtonClick()
		Infinity_PopMenu("CHARACTER_COLOR", 0, 0)
		return "done"
	end,
	CHARGEN_KIT = function()
		done()
		return "done"
	end,
	CHARGEN_ALIGNMENT = function(n)
		if n == 0 then
			for i, alignment in ipairs(chargen.alignment or {}) do
				currentChargenAlignment = i
				createCharScreen:OnAlignmentSelectButtonClick(alignment.id)
				if createCharScreen:IsDoneButtonClickable() then return "select-" .. i end
			end
			return "no-alignment"
		end
		done()
		return "done"
	end,
	B24_BACKGROUND = function(n)
		if n == 0 then return "default" end
		B24CG_BgDone()
		return "done"
	end,
	CHARGEN_ABILITIES = function(n)
		if n == 0 then
			for k, key in ipairs(B24TCG.SPEC.order) do
				for _ = 9, SCORES[k] do B24CG_PlusMinus(ABILITY_INDEX[key], true) end
			end
			return "point-buy"
		end
		if not B24CG_DoneClickable() then return "not-done" end
		B24CG_Done()
		done()
		return "done"
	end,
	-- Skills, Skillful, Skilled, Fighting Style, Weapon Mastery: one step per click, picking the
	-- first rows that can be chosen.
	CHARGEN_PROFICIENCIES = function()
		if not B24CG_ProfDoneClickable() then
			for row = 1, #B24CG.PROF_ROWS do
				B24CG_ProfRowClick(row)
				if B24CG_ProfDoneClickable() then break end
			end
			return "pick-" .. (B24CG_ProfLeftLabel():gsub("[^%w]+", "_"))
		end
		if B24CG_ProfDone() then createCharScreen:OnDoneButtonClick() end
		return "next"
	end,
	-- Spellbook: learn spells (preferred ones first) until none are left, then Done (the engine
	-- closes the screen itself).
	CHARGEN_CHOOSE_SPELLS = function(n)
		if n == 0 then
			-- The engine picks spells when the screen opens; unlearn them (the Learn button
			-- toggles) so the spellbook is the same in every run.
			for row, entry in ipairs(chargen.choose_spell or {}) do
				if entry.enabled and not entry.known then
					currentChargenChooseMageSpell = row
					createCharScreen:OnLearnMageSpellButtonClick(row)
				end
			end
			local learned = {}
			for _, row in ipairs(spellRows(spellBook)) do
				if (chargen.extraSpells or 0) <= 0 then break end
				local entry = chargen.choose_spell[row]
				if not entry.known and not entry.enabled then
					currentChargenChooseMageSpell = row
					createCharScreen:OnLearnMageSpellButtonClick(row)
					table.insert(learned, row)
				end
			end
			return "learn-" .. #learned
		end
		if not createCharScreen:IsDoneButtonClickable() then return "not-done" end
		createCharScreen:OnDoneButtonClick()
		return "done"
	end,
	-- Prepared spells: one of each (preferred first) until Done can be clicked.
	CHARGEN_MEMORIZE_MAGE = function(n)
		if n == 0 then
			local count = 0
			for _, row in ipairs(spellRows(mageSpells)) do
				currentChargenMemorizeMageSpell = row
				createCharScreen:OnMemorizeMageSpellButtonClick(row, 1)
				count = count + 1
			end
			return "memorize-" .. count
		end
		if not createCharScreen:IsDoneButtonClickable() then return "not-done" end
		createCharScreen:OnDoneButtonClick()
		return "done"
	end,
	-- Priests (Cleric, Druid): Done only works once spells are memorized; without them the engine
	-- stays inside the Skills step.
	CHARGEN_MEMORIZE_PRIEST = function(n)
		if n == 0 then
			local count = 0
			for row = 1, #(chargen.choose_spell or {}) do
				currentChargenMemorizePriestSpell = row
				createCharScreen:OnMemorizePriestSpellButtonClick(row, 1)
				count = count + 1
			end
			return "memorize-" .. count
		end
		if not createCharScreen:IsDoneButtonClickable() then return "not-done" end
		createCharScreen:OnDoneButtonClick()
		return "done"
	end,
	CHARGEN_HATEDRACE = function(n)
		if n == 0 and chargen.hatedRace and chargen.hatedRace[1] then
			currentChargenHatedRace = 1
			createCharScreen:OnRacialEnemySelectButtonClick(chargen.hatedRace[1].id)
			return "select"
		end
		done()
		return "done"
	end,
	CHARGEN_NAME = function(n)
		if n == 0 then
			charNameEdit = B24TCG.SPEC.name
			return "name"
		end
		done()
		return "done"
	end,
	CHARGEN_DIFFICULTY = function()
		Infinity_PopMenu()
		createCharScreen:AcceptCharacter(currentDifficulty or 3)
		B24TCG.started = true
		return "venture-forth"
	end,
}

-- Menus without an entry above only need Done (portrait, sounds, biography, ...).
local function defaultAction()
	done()
	return "done"
end

-- One click of the test script.
function B24TCG.Click()
	local menu = topMenu()
	if menu == nil then
		B24TCG.lastKey = nil
		if not B24TCG.lv then out("chargen: no known menu on top") end
		return
	end
	-- The spell screens open once per spell level: each level counts as a screen of its own.
	local key = menu
	if menu:find("SPELLS", 1, true) or menu:find("MEMORIZE", 1, true) then
		key = menu .. "-" .. tostring(chargen.currentSpellLevelChoice)
	end
	-- Choice popups follow each other: each one counts from its first click.
	if menu == "B24_LEVELUP" then key = menu .. "-" .. B24LV_Title() end
	if key ~= B24TCG.lastKey then B24TCG.menuState[key] = 0 end
	B24TCG.lastKey = key
	B24TCG.lastMenu = menu
	local n = B24TCG.menuState[key] or 0
	-- Character creation screens (the level-ups set their own status).
	if not B24TCG.lv then B24T.SetStatus(string.format("character creation (%s): %s", B24TCG.SPEC.class, menu)) end
	local ok, label = pcall(ACTIONS[menu] or defaultAction, n)
	B24TCG.menuState[key] = n + 1
	if not ok then
		out("FAIL chargen " .. menu .. ": " .. tostring(label))
		B24T.failed = B24T.failed + 1
		return
	end
	shot(menu, label or "?")
	-- A conversation runs through many lines on the same screen.
	if n > (menu == "WORLD_DIALOG" and 80 or 12) then
		out("FAIL chargen stuck on " .. menu)
		B24T.failed = B24T.failed + 1
		B24T.Finish()
	end
end

-- Diagnostics: calls of both lists-resolved listener types for the protagonist, with the AC each
-- call sees (B24TCG.trace is switched on for a moment by Report).
B24TCG.trace = nil
local function traceCall(kind)
	return function(sprite)
		local t = B24TCG.trace
		if t == nil or sprite.m_id ~= t.id or #t.calls >= 24 then return end
		table.insert(t.calls, string.format("%s(allow %d, derived AC %d HP %d marker %d, temp AC %d)", kind,
			sprite.m_bAllowEffectListCall, sprite.m_derivedStats.m_nArmorClass, sprite.m_derivedStats.m_nMaxHitPoints,
			sprite.m_derivedStats[B24.STATS_MARKER_FIELD], sprite.m_tempStats.m_nArmorClass))
	end
end
EEex_Opcode_AddListsResolvedListener(traceCall("L"))
EEex_Opcode_AddDeferredListsResolvedListener(traceCall("D"))

-- Stat adjustments must not add up when the engine resolves the stats again: AC and maximum HP
-- are noted, the stats resolved a few more times, and compared in EndTrace.
function B24TCG.StartTrace(sprite)
	local s = B24.Stat
	B24TCG.trace = { id = sprite.m_id, calls = {}, sprite = sprite, ac = sprite:getStat(s.AC), hp = sprite:getStat(s.MAXHP) }
	-- An instant AC +0 effect makes the engine resolve the lists again.
	for _ = 1, 3 do
		B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 0 })
	end
end

function B24TCG.EndTrace()
	local t = B24TCG.trace
	B24TCG.trace = nil
	if t == nil then return end
	out("lists resolved (L normal, D deferred): " .. table.concat(t.calls, " "))
	local s = B24.Stat
	local ac, hp = t.sprite:getStat(s.AC), t.sprite:getStat(s.MAXHP)
	if ac ~= t.ac or hp ~= t.hp then
		out(string.format("FAIL stats changed when resolved again: AC %d -> %d, max HP %d -> %d", 20 - t.ac, 20 - ac, t.hp, hp))
		B24T.failed = B24T.failed + 1
	else
		out(string.format("ok stats stable when resolved again (AC %d, max HP %d)", 20 - ac, hp))
		B24T.passed = B24T.passed + 1
	end
end

-- After the game has started: what the character got.
function B24TCG.Report(sprite)
	local s = B24.Stat
	local function mask(name) return sprite:getLocalInt(name) end
	local base = sprite.m_baseStats
	out(string.format("character %s: class %d, kit stat 0x%X (base words 0x%X/0x%X, kit %s), mod class %s, level %d, HP %d, 2024 AC %d, proficiency +%d",
		B24.Name(sprite), B24.ClassID(sprite), sprite:getStat(s.KIT), base.m_mageSpecUpperWord, base.m_mageSpecialization,
		tostring(B24LV and B24LV.KitName(sprite)), tostring(B24.SkillClass(sprite)), sprite:getStat(s.LEVEL),
		sprite:getStat(s.MAXHP), 20 - sprite:getStat(s.AC), B24.ProfOf(sprite)))
	local scores = {}
	for _, key in ipairs({ "STR", "DEX", "CON", "INT", "WIS", "CHA" }) do
		table.insert(scores, string.format("%s %d", key, sprite:getStat(B24.AbilityStat[key])))
	end
	out("scores: " .. table.concat(scores, ", "))
	out(string.format("species %d, lineage %d, background %d, skills %d, Skillful %d, Skilled %d, expertise %d, masteries %d, styles %d",
		mask("B24SPC"), mask("B24LIN"), mask("B24BG"), mask("B24SKILL"), mask("B24SKHUM"), mask("B24SKFT"),
		mask("B24SKEXP"), mask("B24MAST"), mask("B24FSTY")))
	local saves = {}
	for _, key in ipairs({ "STR", "DEX", "CON", "INT", "WIS", "CHA" }) do
		local ok, mod = pcall(B24.SaveModifier, sprite, key)
		table.insert(saves, string.format("%s %s%s", key, ok and (mod >= 0 and "+" or "") .. mod or "?",
			B24.IsSaveProficient(sprite, key) and "*" or ""))
	end
	out("saves (* proficient): " .. table.concat(saves, ", "))
	for _, book in ipairs({ { "mage", "Mage", 9 }, { "priest", "Priest", 7 } }) do
		for level = 1, book[3] do
			local known = {}
			for _, _, res in EEex_Sprite_Private_GetKnownSpellsItr(sprite, level, level, CGameSprite["GetKnownSpell" .. book[2]]) do
				table.insert(known, B24TCG.SpellName(res))
			end
			local memorized = B24TCG.SpellList(sprite["m_memorizedSpells" .. book[2]], level)
			if #known > 0 or #memorized > 0 then
				out(string.format("%s spells level %d: known %d (%s), prepared %d (%s)", book[1], level, #known,
					table.concat(known, ", "), #memorized, table.concat(memorized, ", ")))
			end
		end
	end
end

-- 2024 prepared casting (B24SPELL.lua): with Shield and Magic Missile prepared in the two level 1
-- slots, casting Shield keeps it ready and uses the Magic Missile slot instead. Returns false if
-- the character can't take the test (not a prepared caster with both spells).
B24TCG.CAST = { res = "SPWI114", other = "SPWI112" }

local function preparedState(sprite)
	local state = {}
	local ok, list = pcall(function() return sprite.m_memorizedSpellsMage:getReference(0) end)
	if not ok or list == nil then return state end
	EEex_Utility_IterateCPtrList(list, function(entry)
		local res = entry.m_spellId:get():upper()
		state[res] = (state[res] or 0) + (EEex_IsBitSet(entry.m_flags, 0) and 1 or 0)
	end)
	return state
end

function B24TCG.StartCast(sprite)
	local state = preparedState(sprite)
	if state[B24TCG.CAST.res] ~= 1 or state[B24TCG.CAST.other] ~= 1 then return false end
	local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	if ok and (paused == true or paused == 1) then EEex_GameState_TogglePause(false, false) end
	EEex_Action_QueueResponseStringOnAIBase(string.format('SpellRES("%s",Myself)', B24TCG.CAST.res), sprite)
	out("casting " .. B24TCG.SpellName(B24TCG.CAST.res))
	B24TCG.castTick = B24.GameTick()
	return true
end

function B24TCG.CheckCast(sprite)
	local state = preparedState(sprite)
	local cast, other = state[B24TCG.CAST.res] or 0, state[B24TCG.CAST.other] or 0
	local detail = string.format("ready after the cast: %s %d, %s %d", B24TCG.CAST.res, cast,
		B24TCG.CAST.other, other)
	-- The cast only goes off where the character can act (not during BG2's opening cutscene).
	local effects = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_sourceRes:get():upper() == B24TCG.CAST.res then effects = true return true end
	end)
	if not effects then
		out("skipped prepared casting: the spell was not cast (" .. detail .. ")")
	elseif cast == 1 and other == 0 then
		out("ok prepared casting: the cast spell stayed ready (" .. detail .. ")")
		B24T.passed = B24T.passed + 1
	else
		out("FAIL prepared casting: " .. detail .. " (expected 1 and 0)")
		B24T.failed = B24T.failed + 1
	end
end

-- Spell names (resref: name) of one level of a sprite's known or memorized spell lists.
function B24TCG.SpellList(field, level)
	local names = {}
	-- An array binding: getReference(i) gives the list of level i + 1 (as in B24SPELL.lua).
	local ok, list = pcall(function() return field:getReference(level - 1) end)
	if not ok or list == nil then return { "NOT REACHABLE" } end
	local ok, err = pcall(EEex_Utility_IterateCPtrList, list, function(entry)
		local ready = EEex_IsBitSet(entry.m_flags, 0) and "" or " (used)"
		table.insert(names, B24TCG.SpellName(entry.m_spellId:get()) .. ready)
	end)
	if not ok then table.insert(names, "ERROR " .. tostring(err)) end
	return names
end

function B24TCG.SpellName(res)
	res = res:upper()
	local ok, name = pcall(function() return Infinity_FetchString(EEex_Resource_Demand(res, "SPL").genericName) end)
	return res .. " " .. (ok and name or "?")
end

----------------
-- Level-ups --
----------------

-- With B24TEST_LEVELUP (target level), the created character levels up one level at a time the
-- way a player does it: XP up to the next threshold, the record screen's Level Up button, the
-- engine's level-up screens, then the mod's choice popups (first rows until Done can be clicked).
-- After each level: level, applied class features, no pending choices, HP gain against the HP
-- table, proficiency bonus and, for casters, the spell slots the engine computed.

-- Rows of XPLEVEL and HPCLASS, and the slot table (spell list, spell levels), by test class name.
local LEVEL_ROWS = { Fighter = "FIGHTER", Barbarian = "FIGHTER", Wizard = "MAGE", Cleric = "CLERIC", Rogue = "THIEF",
	Bard = "BARD", Paladin = "PALADIN", Ranger = "RANGER", Druid = "DRUID", Sorcerer = "SORCERER", Monk = "MONK" }
local SLOT_TABLES = {
	Wizard = { "MXSPLWIZ", "Mage", 9 }, Sorcerer = { "MXSPLSRC", "Mage", 9 }, Bard = { "MXSPLBRD", "Mage", 9 },
	Cleric = { "MXSPLPRS", "Priest", 7 }, Druid = { "MXSPLDRU", "Priest", 7 }, Paladin = { "MXSPLPAL", "Priest", 7 },
	Ranger = { "MXSPLRAN", "Priest", 7 },
}

local function paused()
	local ok, p = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	return ok and (p == true or p == 1)
end

local function inWorld()
	return worldScreen ~= nil and e:GetActiveEngine() == worldScreen
end

local function popupOpen()
	return B24LV_Title ~= nil and B24LV_Title() ~= ""
end

local function clicks(on)
	if B24T.clicks == on then return end
	out(on and "CLICKS ON" or "CLICKS OFF")
end

-- Spell slots per spell level the engine computed (pointers to CRE memorization entries).
local function slotCount(sprite, list, spellLevel)
	local ok, have = pcall(function()
		local entry = EEex_ReadPtr(EEex_UDToPtr(sprite["m_memorizedSpellsLevel" .. list]) + (spellLevel - 1) * 8)
		if EEex_ReadU16(entry) ~= spellLevel - 1 then return nil end
		return EEex_ReadU16(entry + 2)
	end)
	return ok and have or nil
end

B24TCG.scriptRuns = 0

-- opts (the Joining mode's companions): portrait (party slot, 0 = protagonist), class (test class
-- name of a single class), multi (a multiclass: the mod's level-up, the level counts all classes),
-- target (level to reach).
-- The level a multiclass counts (all its classes; the engine keeps junk in the level slots a
-- two-class creature doesn't use).
local function totalLevel(sprite)
	local s = B24.Stat
	local _, count = B24MC.Classes(sprite)
	local total = 0
	for i, stat in ipairs({ s.LEVEL, s.LEVEL2, s.LEVEL3 }) do
		if i <= (count or 1) then total = total + sprite:getStat(stat) end
	end
	return total
end
B24TCG.TotalLevel = totalLevel

function B24TCG.StartLevelUps(sprite, opts)
	opts = opts or {}
	local target = opts.target or tonumber(B24TEST_LEVELUP) or 0
	local level = opts.multi and totalLevel(sprite) or sprite:getStat(B24.Stat.LEVEL)
	if target <= level then return false end
	B24TCG.lv = { target = target, level = level + 1, state = "give", frames = 0, portrait = opts.portrait or 0,
		class = opts.class or B24TCG.SPEC.class, multi = opts.multi, id = sprite.m_id }
	out(string.format("level-ups: %s (%s) from %d to %d", B24.Name(sprite), opts.multi and "multiclass" or B24TCG.lv.class, level, target))
	return true
end

-- Every frame (also on the record and level-up screens). Returns true when the test is over.
function B24TCG.LevelFrame(sprite)
	local lv = B24TCG.lv
	lv.frames = lv.frames + 1
	-- Conversations are answered by clicks (WORLD_DIALOG); the level-up waits for them.
	if Infinity_IsMenuOnStack("WORLD_DIALOG") then
		clicks(true)
		lv.quiet, lv.quietSince = 0, nil
		return false
	end
	if lv.state == "give" then
		-- Choices still open before the first level-up (a ToB character starts at level 18 with all of
		-- them): the popups are answered by the clicks, as during a level-up.
		if popupOpen() then
			clicks(true)
			return false
		end
		if not inWorld() then return false end
		local row = LEVEL_ROWS[lv.class]
		local ok, xp
		if lv.multi then
			-- The mod's threshold for the next total level (B24MULTI.lua).
			ok, xp = pcall(function() return select(2, B24MC.XPProgress(sprite)) end)
		else
			ok, xp = pcall(function() return tonumber(B24.LoadTable("XPLEVEL")[row][tostring(lv.level)]) end)
		end
		if not ok or xp == nil then
			out("FAIL level-up: no XP threshold for " .. tostring(row) .. " level " .. lv.level)
			B24T.failed = B24T.failed + 1
			return true
		end
		-- Base hit points: the engine adds its own Constitution adjustment to the active value.
		lv.hpBefore = sprite.m_baseStats.m_maxHitPointsBase
		lv.baseBefore, lv.conScoreBefore = sprite.m_baseStats.m_maxHitPointsBase, sprite.m_baseStats.m_CONBase
		lv.conBefore = B24.AbilityModOf(sprite, "CON")
		-- The active XP as well (the record screen reads it).
		sprite.m_baseStats.m_xp, sprite.m_derivedStats.m_nXP, sprite.m_tempStats.m_nXP = xp, xp, xp
		-- Removing an effect makes the engine recompute the stats from the new XP.
		B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60,
			["m_sourceRes"] = "B24TREF" })
		B24.RemoveEffectsBySource(sprite, "B24TREF")
		out(string.format("level %d: XP %d", lv.level, xp))
		B24T.SetStatus(string.format("%s, level-up to %d (of %d)", B24.Name(sprite), lv.level, lv.target))
		lv.scriptRunsAtStart = B24TCG.scriptRuns
		lv.state, lv.frames = "open", 0
	elseif lv.state == "open" then
		-- The record screen is opened from script context (LevelScript): the game must run.
		if paused() then EEex_GameState_TogglePause(false, false) end
	elseif lv.state == "popups" then
		if popupOpen() then
			lv.quiet, lv.quietSince = 0, nil
			return false
		end
		if not inWorld() then return false end
		if paused() then EEex_GameState_TogglePause(false, false) end
		lv.quiet = (lv.quiet or 0) + 1
		lv.quietSince = lv.quietSince or B24.GameTick()
		if lv.quiet == 30 then clicks(false) end
		local pending = 0
		for _, n in pairs(B24LV.Pending(sprite)) do pending = pending + n end
		-- The runtime applies class features from the global script: at least 3 seconds of game
		-- time, and until they are applied (at most 20 seconds).
		local waited = B24.GameTick() - lv.quietSince
		local applied
		if lv.multi then
			-- The level signature the runtime stores once it has applied the class features.
			local s = B24.Stat
			applied = totalLevel(sprite) == lv.level and sprite:getLocalInt("B24LVAPP")
				== sprite:getStat(s.LEVEL) * 10000 + sprite:getStat(s.LEVEL2) * 100 + sprite:getStat(s.LEVEL3)
		else
			-- Also once the Constitution check (B24MULTI.lua) has seen the new level.
			applied = B24LV.AppliedClassLevel(sprite, lv.class:upper()) == lv.level and sprite:getLocalInt("B24HPLV") == lv.level
		end
		if (pending == 0 and waited >= 45 and (applied or waited >= 300)) or lv.quiet >= 6000 then
			if lv.multi then B24TCG.MultiVerify(sprite, pending) else B24TCG.LevelVerify(sprite, pending) end
			if lv.level >= lv.target then
				if B24TEST_MODE == "chargen" then B24TCG.Report(sprite) end
				return true
			end
			lv.level, lv.state, lv.quiet = lv.level + 1, "give", 0
		end
	end
	return false
end

-- Script context (the global script, while the game runs).
function B24TCG.LevelScript(sprite)
	local lv = B24TCG.lv
	B24TCG.scriptRuns = B24TCG.scriptRuns + 1
	if lv == nil or lv.state ~= "open" or not inWorld() or popupOpen() then return end
	-- Only once the engine offers the level-up (the portrait's level-up mark; BG2 takes a while).
	if not lv.multi and Infinity_CanLevelUp and not Infinity_CanLevelUp(lv.portrait) and lv.frames < 1500 then return end
	lv.state = "record"
	clicks(true)
	-- The record screen shows the selected character: select the protagonist alone first (BG2 starts
	-- with Imoen in the party).
	Infinity_OnPortraitLClick(lv.portrait)
	e:GetActiveEngine():OnLeftPanelButtonClick(4)
end

-- A multiclass level: the total level, the 2024 multiclass hit points (B24MC.HitPoints), the
-- class features applied, no choice pending, proficiency from the total level.
function B24TCG.MultiVerify(sprite, pending)
	local lv = B24TCG.lv
	local s = B24.Stat
	local failures = {}
	local function check(ok, text) if not ok then table.insert(failures, text) end end
	local total = totalLevel(sprite)
	check(total == lv.level, "total level " .. total)
	local hp, want = sprite.m_baseStats.m_maxHitPointsBase, B24MC.HitPoints(sprite)
	check(hp == want, string.format("hit points %d, multiclass rules say %d", hp, want))
	check(sprite:getLocalInt("B24LVAPP") == sprite:getStat(s.LEVEL) * 10000 + sprite:getStat(s.LEVEL2) * 100 + sprite:getStat(s.LEVEL3),
		"class features not applied")
	check(pending == 0, pending .. " choices still pending")
	local prof = 2 + math.floor((lv.level - 1) / 4)
	check(B24.ProfOf(sprite) == prof, "proficiency +" .. B24.ProfOf(sprite) .. ", expected +" .. prof)
	out(string.format("%s level %d: levels %d/%d/%d, HP %d, proficiency +%d", B24.Name(sprite), lv.level, sprite:getStat(s.LEVEL),
		sprite:getStat(s.LEVEL2), sprite:getStat(s.LEVEL3), hp, B24.ProfOf(sprite)))
	out(string.format("SHOT lv%02d-%s", lv.level, B24.Name(sprite):gsub("[^%w]", "")))
	if #failures == 0 then
		out(string.format("PASS %s level %d", B24.Name(sprite), lv.level))
		B24T.passed = B24T.passed + 1
	else
		out(string.format("FAIL %s level %d: %s", B24.Name(sprite), lv.level, table.concat(failures, "; ")))
		B24T.failed = B24T.failed + 1
	end
end

function B24TCG.LevelVerify(sprite, pending)
	local lv = B24TCG.lv
	local s = B24.Stat
	local failures = {}
	local function check(ok, text) if not ok then table.insert(failures, text) end end
	local key = lv.class:upper()
	local level = sprite:getStat(s.LEVEL)
	check(level == lv.level, "level " .. level)
	-- A story creature (Wilson) has no 2024 class features: only hit points and proficiency grow.
	if B24.IsStoryCreature(sprite) then
		check(B24LV.AppliedClassLevel(sprite, key) == 0, "a story creature got class features")
	elseif B24LV.AppliedClassLevel(sprite, key) ~= lv.level then
		local okNeeds, needs = pcall(B24_PartyNeedsSetup)
		check(false, string.format("features applied for level %d (B24LVAPP %d, levels %d/%d/%d, global script ran %d times "
			.. "since the level-up, B24_PartyNeedsSetup() = %s)", B24LV.AppliedClassLevel(sprite, key),
			sprite:getLocalInt("B24LVAPP"), level, sprite:getStat(s.LEVEL2), sprite:getStat(s.LEVEL3),
			B24TCG.scriptRuns - (lv.scriptRunsAtStart or 0), okNeeds and tostring(needs) or ("error " .. tostring(needs))))
	end
	check(pending == 0, pending .. " choices still pending")
	local prof = 2 + math.floor((lv.level - 1) / 4)
	check(B24.ProfOf(sprite) == prof, "proficiency +" .. B24.ProfOf(sprite) .. ", expected +" .. prof)
	-- HP: the installed HP table (ROLLS = fixed value, SIDES 1) plus the Con modifier; a higher Con
	-- modifier (an ASI at this level) also counts for every earlier level.
	local hp = sprite.m_baseStats.m_maxHitPointsBase
	local expected
	pcall(function()
		local hpClass = B24.LoadTable("HPCLASS")
		local hpRow = hpClass[key] or hpClass[LEVEL_ROWS[lv.class]]
		local row = B24.LoadTable(hpRow.TABLE)[tostring(lv.level)]
		if tonumber(row.SIDES) == 1 then
			local con = B24.AbilityModOf(sprite, "CON")
			expected = tonumber(row.ROLLS) + tonumber(row.MODIFIER) + con + (con - lv.conBefore) * (lv.level - 1)
		end
	end)
	if expected then
		check(hp - lv.hpBefore == expected, string.format("HP +%d, HP table says +%d (base HP %d > %d, CON %d > %d)", hp - lv.hpBefore, expected,
			lv.baseBefore or 0, sprite.m_baseStats.m_maxHitPointsBase, lv.conScoreBefore or 0, sprite.m_baseStats.m_CONBase))
	end
	-- Spell slots against the installed slot table.
	local slots, slotText = SLOT_TABLES[lv.class], {}
	if slots then
		local ok, rows = pcall(B24.LoadTable, slots[1])
		local row = ok and rows[tostring(lv.level)]
		for spellLevel = 1, slots[3] do
			local want = row and tonumber(row[tostring(spellLevel)] or "0") or 0
			local have = slotCount(sprite, slots[2], spellLevel)
			if want > 0 or (have or 0) > 0 then
				table.insert(slotText, string.format("%d:%s", spellLevel, tostring(have)))
				check(have == want, string.format("spell level %d: %s slots, %s says %d", spellLevel, tostring(have), slots[1], want))
			end
		end
	end
	out(string.format("level %d: HP %d > %d, proficiency +%d, subclass %s%s (global script ran %d times)", lv.level,
		lv.hpBefore, hp, B24.ProfOf(sprite), tostring(B24LV.Subclass(sprite, key)),
		#slotText > 0 and (", slots " .. table.concat(slotText, " ")) or "", B24TCG.scriptRuns - (lv.scriptRunsAtStart or 0)))
	out(string.format("SHOT lv%02d-world", lv.level))
	if #failures == 0 then
		out(string.format("PASS level %d", lv.level))
		B24T.passed = B24T.passed + 1
	else
		out(string.format("FAIL level %d: %s", lv.level, table.concat(failures, "; ")))
		B24T.failed = B24T.failed + 1
	end
end

-- The record screen: Level Up once, then back to the game, where the choice popups open.
ACTIONS.CHARACTER = function(n)
	local lv = B24TCG.lv
	if lv == nil then return "no-level-up-test" end
	if lv.state == "record" then
		if B24MC_LevelUpClickable() then
			lv.state = "engine"
			B24MC_OnLevelUp()
			return "level-up"
		end
		-- The record screen may show another party member (BG2's Imoen): the protagonist's portrait,
		-- as a click on it would.
		if n < 6 then
			Infinity_OnPortraitLClick(lv.portrait)
			return "select-protagonist"
		end
		local sprite = EEex_Sprite_GetInPortrait(lv.portrait)
		-- XP effects that could hold the active value.
		local xpEffects = {}
		for _, list in ipairs(sprite and { sprite.m_timedEffectList, sprite.m_equipedEffectList } or {}) do
			EEex_Utility_IterateCPtrList(list, function(effect)
				if effect.m_effectId == 104 then
					table.insert(xpEffects, string.format("%d/%d/t%d/%s", effect.m_effectAmount, effect.m_dWFlags,
						effect.m_durationType, effect.m_sourceRes:get()))
				end
			end)
		end
		out(string.format("FAIL level %d: the record screen offers no level-up (XP base %s, stat %s, can level up %s, waited %d frames, XP effects: %s)",
			lv.level, tostring(sprite and sprite.m_baseStats.m_xp), tostring(sprite and sprite:getStat(44)),
			tostring(Infinity_CanLevelUp and Infinity_CanLevelUp(lv.portrait)), lv.frames,
			#xpEffects > 0 and table.concat(xpEffects, " ") or "none"))
		B24T.failed = B24T.failed + 1
	end
	lv.state, lv.quiet = "popups", 0
	e:GetActiveEngine():OnLeftPanelButtonClick(0)
	return "back-to-game"
end

-- A conversation (BG2's Imoen at the start): the first answer, or Continue, as the dialogue
-- button of the UI does it.
ACTIONS.WORLD_DIALOG = function()
	if worldPlayerDialogChoices and #worldPlayerDialogChoices > 0 then
		worldScreen:OnDialogReplyClick(worldPlayerDialogChoices[1].marker)
		return "answer-1"
	end
	worldScreen:StepDialog()
	return "continue"
end

-- A choice popup: rows in order until Done can be clicked.
ACTIONS.B24_LEVELUP = function(n)
	if B24LV_Ready() then
		local choice = B24LV_Choice()
		-- A spellbook pick must leave the list: the same spell twice means it was not learned.
		local spell = choice == "Spellbook" and B24LV.ROWS[b24lvRow] and B24LV.ROWS[b24lvRow].spell
		if spell then
			out(string.format("spellbook pick: %s %s (level %d)", spell.res, spell.name, spell.level))
			if B24TCG.lastSpellbookPick == spell.res then
				out("FAIL spellbook offers " .. spell.res .. " again after it was picked")
				-- Diagnostics: the known spells of its level, then op147 directly.
				local p = EEex_Sprite_GetInPortrait(0)
				local list = {}
				for _, _, res in EEex_Sprite_GetKnownMageSpellsIterator(p, spell.level, spell.level) do table.insert(list, res) end
				out(string.format("known level %d (%d): %s", spell.level, #list, table.concat(list, " ")))
				B24.ApplyEffect(p, { ["effectID"] = 147, ["res"] = spell.res })
				local found = false
				for _, _, res in EEex_Sprite_GetKnownMageSpellsIterator(p, 1, 9) do found = found or res:upper() == spell.res end
				local ok, header = pcall(function()
					local spl = EEex_Resource_Demand(spell.res, "SPL")
					return string.format("type %d, level %d, exclusion 0x%X", spl.itemType, spl.spellLevel, spl.notUsableBy)
				end)
				out(string.format("op147 %s directly: known afterwards %s; INT %d, kit 0x%X; SPL %s", spell.res, tostring(found),
					p:getStat(38), p:getStat(152), ok and header or tostring(header)))
				B24T.failed = B24T.failed + 1
				B24T.Finish()
			end
			B24TCG.lastSpellbookPick = spell.res
		end
		B24LV_Done()
		-- The next popup may have the same title: it counts from its own first click.
		B24TCG.lastKey = nil
		return "done-" .. choice:gsub("[^%w]+", "_")
	end
	b24lvRow = n + 1
	B24LV_RowClick(n + 1)
	return "pick-" .. (n + 1)
end

-- Choice popups open on the game screen: the clicks go on while one is up.
local originalPushMenuTCG = Infinity_PushMenu
function Infinity_PushMenu(name, ...)
	if name == "B24_LEVELUP" and B24TCG.lv then clicks(true) end
	return originalPushMenuTCG(name, ...)
end

-- A two- or three-button popup during the import: logs it and presses the button that names the
-- character import (Popup2Button / Popup3Button, filled by the engine).
function B24TCG.PopupChoice(count)
	local popup = count == 2 and Popup2Button or Popup3Button
	if popup == nil then error("no popup data") end
	local buttons = count == 2
		and { { "ok", popup.okText or "DONE_BUTTON", popup.okFunc }, { "cancel", popup.cancelText or "CANCEL_BUTTON", popup.cancelFunc } }
		or { { "left", popup.leftText, popup.leftFunc }, { "mid", popup.midText, popup.midFunc }, { "right", popup.rightText, popup.rightFunc } }
	local parts, pick = {}, nil
	for _, b in ipairs(buttons) do
		local ok, text = pcall(getUiString, b[2])
		text = ok and tostring(text) or tostring(b[2])
		table.insert(parts, b[1] .. "=" .. text)
		if pick == nil and B24TEST_IMPORT and text:upper():find("CHARACTER", 1, true) then pick = b end
	end
	local okInfo, info = pcall(getStringFromAmbiguousSource, popup.info)
	out(string.format("popup: %s [%s]", okInfo and tostring(info):gsub("\n", " ") or "?", table.concat(parts, ", ")))
	if pick == nil and B24TEST_IMPORT then error("no character button in the popup") end
	-- Outside the import: the first button (OK or the left one).
	pick = pick or buttons[1]
	Infinity_PopMenu()
	if pick[3] then pick[3]() end
	return "popup-" .. pick[1]
end
