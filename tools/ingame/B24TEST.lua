-- BG 2024 Rules Mod: automated in-game smoke test (tools/ingame-test.ps1 installs it for one run;
-- it is not part of the mod).
--
-- 1. From the start menu, opens "Load Game" and loads the save named in B24TEST_SAVE.
-- 2. In the world, steps the protagonist through every class (and some multiclasses) at several
--    levels with ChangeClass / ChangeStat, waits until the runtime has re-applied the class
--    features (B24_SetupParty, as after a real level-up), and checks the results. At level 20,
--    every subclass of the class is applied once.
-- 3. Every Lua error that reaches EEex_Utility_TryIgnore during the run counts as a failure of
--    the current step.
-- Output: "[B24TEST] ..." lines in the game log; the last one is "[B24TEST] DONE <passed> <failed>".
-- The save is never written; the script that started the game closes it.

-- Loaded again after a UI reload: only the menu functions are new.
local loaded = B24T
if loaded then
	loaded.HookMenus()
	return
end

B24T = { steps = {}, step = 0, phase = "menu", frames = 0, errors = {}, passed = 0, failed = 0, hooked = {}, injected = {}, verbose = false }

local function out(text)
	-- The test script clicks while the last of these was CLICKS ON (kept for conversations).
	if text == "CLICKS ON" then B24T.clicks = true elseif text == "CLICKS OFF" then B24T.clicks = false end
	print("[B24TEST] " .. text)
end

-- The status line at the top of the screen (B24TEST.menu): test mode and game, then what the test
-- does right now (B24T.SetStatus), so what is on the screen can be named while the tests run.
function B24T.SetStatus(text)
	B24T.status = text
end

-- Heartbeat for the test script (its own tag, not a test line), from everything drawn each frame
-- (status line, party portraits, start menus): it stops while a movie plays, and the script then
-- presses Escape.
function B24T.Alive()
	local clock = Infinity_GetClockTicks()
	if clock - (B24T.aliveAt or 0) >= 5000 then
		B24T.aliveAt = clock
		print("[B24TEST-ALIVE]")
	end
end

function B24T.StatusText()
	pcall(B24T.Alive)
	local text = string.format("Test: %s %s", tostring(B24TEST_MODE_NAME or B24TEST_MODE), tostring(B24TEST_GAME or ""))
	if B24T.status and B24T.status ~= "" then
		text = text .. ": " .. B24T.status
	elseif B24T.phase == "menu" or B24T.phase == "loading" then
		text = text .. ": loading"
	else
		-- Modes without a status of their own: their step.
		text = text .. ": step " .. tostring(B24T.dyingStep or B24T.mcStep or B24T.turnStep or B24T.iconStep or B24T.step)
	end
	if B24T.popupShownAt and Infinity_IsMenuOnStack("B24_LEVELUP") and not B24T.leveling and B24T.phase ~= "record" then
		text = text .. " (choice popup shown for the screenshot, closes in a few seconds)"
	elseif Infinity_IsMenuOnStack("WORLD_DIALOG") then
		text = text .. " (answering a conversation)"
	end
	return text
end

-- Errors the runtime swallows are recorded for the current step.
function EEex_Utility_TryIgnore(func, ...)
	local result = EEex_Utility_TryCatch(func, ...)
	if not result[1] then
		table.insert(B24T.errors, tostring(result[2]))
		print(result[2])
		return
	end
	return select(2, table.unpack(result))
end

---------------------
-- Test definition --
---------------------

-- CLASS.IDS value, BG class name, 2024 class keys (in level order), save proficiencies.
local CLASSES = {
	{ id = 2,  name = "Fighter",   keys = { "FIGHTER" },  saves = { "STR", "CON" } },
	{ id = 2,  name = "Barbarian", keys = { "BARBARIAN" }, saves = { "STR", "CON" }, barbarian = true },
	{ id = 4,  name = "Rogue",     keys = { "ROGUE" },    saves = { "DEX", "INT" } },
	{ id = 20, name = "Monk",      keys = { "MONK" },     saves = { "STR", "DEX" } },
	{ id = 6,  name = "Paladin",   keys = { "PALADIN" },  saves = { "WIS", "CHA" } },
	{ id = 12, name = "Ranger",    keys = { "RANGER" },   saves = { "STR", "DEX" } },
	{ id = 5,  name = "Bard",      keys = { "BARD" },     saves = { "DEX", "CHA" } },
	{ id = 3,  name = "Cleric",    keys = { "CLERIC" },   saves = { "WIS", "CHA" } },
	{ id = 11, name = "Druid",     keys = { "DRUID" },    saves = { "INT", "WIS" } },
	{ id = 19, name = "Sorcerer",  keys = { "SORCERER" }, saves = { "CON", "CHA" } },
	{ id = 1,  name = "Wizard",    keys = { "WIZARD" },   saves = { "INT", "WIS" } },
	{ id = 7,  name = "Fighter/Mage",  keys = { "FIGHTER", "WIZARD" } },
	{ id = 16, name = "Fighter/Druid", keys = { "FIGHTER", "DRUID" } },
	{ id = 13, name = "Mage/Thief",    keys = { "WIZARD", "ROGUE" } },
}
local LEVELS = { 1, 2, 3, 4, 5, 6, 11, 17, 20 }
local MULTI_LEVELS = { 1, 3, 5, 11 }
local ABILITIES = { "STR", "DEX", "CON", "INT", "WIS", "CHA" }

local function buildSteps()
	for _, class in ipairs(CLASSES) do
		local levels = #class.keys > 1 and MULTI_LEVELS or LEVELS
		for _, level in ipairs(levels) do
			table.insert(B24T.steps, { class = class, level = level, subclass = 0 })
		end
		-- Every subclass at level 20 (single classes; index into the class's subclass list).
		local entry = #class.keys == 1 and B24LV and B24LV.SUBCLASSES[class.keys[1]]
		for i = 1, entry and #entry.list or 0 do
			table.insert(B24T.steps, { class = class, level = 20, subclass = i })
		end
	end
	-- B24TEST_CLASSES (optional): only the classes whose names it lists, e.g. "Fighter,Barbarian".
	if B24TEST_CLASSES and B24TEST_CLASSES ~= "" then
		local wanted = {}
		for name in B24TEST_CLASSES:gmatch("[^,]+") do wanted[name] = true end
		for i = #B24T.steps, 1, -1 do
			if not wanted[B24T.steps[i].class.name] then table.remove(B24T.steps, i) end
		end
	end
end

-- Diagnostics: dialogue actions of any creature (the social skill bonus starts with them).
local DIALOGUE_ACTIONS = { [8] = true, [137] = true, [139] = true, [198] = true, [266] = true, [267] = true }
local dialogueLogged = {}
EEex_Action_AddSpriteStartedActionListener(function(sprite, action)
	if not DIALOGUE_ACTIONS[action.m_actionID] then return end
	local key = B24.Name(sprite) .. ":" .. action.m_actionID
	dialogueLogged[key] = (dialogueLogged[key] or 0) + 1
	local n = dialogueLogged[key]
	if n <= 3 or n == 10 or n == 100 or n == 1000 then
		out(string.format("dialogue action %d by %s (%d times)", action.m_actionID, B24.Name(sprite), n))
	end
end)

----------------
-- Menu phase --
----------------

-- Called every frame from functions the start and load menus evaluate. Only notes the state:
-- loading a game from inside a menu's rendering crashes the engine, so the actions run from the
-- full-screen button of B24TEST.menu (the test script clicks into the window every second).
function B24T.MenuTick()
	pcall(B24T.Alive)
	pcall(B24T.GameOverCheck)
	if B24T.phase ~= "menu" then return end
	B24T.HookWorld()
	B24T.frames = B24T.frames + 1
	if B24T.frames == 1 then out("menu reached") end
end

function B24T.MenuKey()
	-- Joining: a companion's level-up goes through the same screens as in character creation.
	if B24TEST_MODE == "joining" and B24T.leveling then
		B24T.InjectMissing()
		B24TCG.Click()
		return
	end
	if B24TEST_MODE ~= "chargen" and Infinity_IsMenuOnStack("WORLD_DIALOG") then
		B24T.AnswerDialog()
		return
	end
	if B24T.phase == "record" then
		B24T.RecordKey()
		return
	end
	if B24T.phase == "saveload" then
		B24T.SaveLoadKey()
		return
	end
	if B24T.phase == "export" then
		B24T.ExportKey()
		return
	end
	if (B24T.phase ~= "menu" and not (B24TEST_MODE == "chargen" and B24T.phase == "loading")) or B24T.frames < 30 then return end
	if B24TEST_MODE == "chargen" then
		B24T.InjectMissing()
		B24TCG.Click()
		if B24TCG.started then B24T.phase = "loading" end
		return
	end
	if not B24T.loadOpened then
		B24T.loadOpened = true
		B24T.loadFrame = B24T.frames
		out("opening Load Game")
		startEngine:OnLoadGameButtonClick()
	elseif gameSaves and gameSaves.files then
		for _, file in ipairs(gameSaves.files) do
			if file.slotName == B24TEST_SAVE or file.fileName == B24TEST_SAVE then
				out("loading save " .. tostring(file.fileName))
				out("CLICKS OFF")
				B24T.phase = "loading"
				loadScreen:LoadGame(file.fileName)
				return
			end
		end
		if B24T.frames - B24T.loadFrame > 600 then
			local names = {}
			for _, file in ipairs(gameSaves.files) do
				local fields = {}
				for k, v in pairs(file) do table.insert(fields, tostring(k) .. "=" .. tostring(v)) end
				table.insert(names, "{" .. table.concat(fields, " ") .. "}")
			end
			out("FAIL save not found: " .. tostring(B24TEST_SAVE) .. " (have: " .. table.concat(names, ", ") .. ")")
			B24T.failed = B24T.failed + 1
			B24T.Finish()
		end
	end
end

-- Wraps functions the start and load menus call every frame (BG:EE and BG2:EE menus differ). Runs
-- again whenever UI.MENU is (re)loaded, since that defines the functions anew.
function B24T.HookMenus()
	for _, name in ipairs({ "getSidebarFrame", "startThreeBookHighlight", "getLoadMenuTitle", "getCampaignButtonSequence" }) do
		local original = _G[name]
		if type(original) == "function" and not B24T.hooked[original] then
			local wrapped = function(...)
				pcall(B24T.MenuTick)
				return original(...)
			end
			B24T.hooked[wrapped] = true
			_G[name] = wrapped
		end
	end
	-- The full-screen click button (B24TEST.menu) in the menus the test drives.
	B24T.injected = {}
	local ok, err = pcall(EEex_Menu_LoadFile, "B24TEST")
	if not ok then print("[B24TEST] menu file: " .. tostring(err)) end
	B24T.InjectMissing()
end

-- Injects the click button into every driven menu that exists and doesn't have it yet (menus of
-- other files, such as the mod's popups, may load later).
function B24T.InjectMissing()
	-- START_MAIN: BG2:EE's main menu after quitting a game (the campaign is chosen by then).
	local menus = { "START", "START_MAIN", "START_SP", "LOAD", "WORLD_DIALOG" }
	if B24TEST_MODE == "chargen" then menus = B24TCG.MENUS end
	-- Joining: the level-up screens and popups of the companions too.
	if B24TEST_MODE == "joining" then
		for _, menu in ipairs(B24TCG.MENUS) do table.insert(menus, menu) end
	end
	for _, menu in ipairs(menus) do
		if not B24T.injected[menu] and EEex_Menu_Find(menu) then
			-- The conversation box sits at the bottom of the screen: its button reaches past it, so the
			-- click in the middle of the window lands on it too.
			local big = menu == "WORLD_DIALOG"
			local ok, err = pcall(EEex_Menu_InjectTemplate, menu, "B24TEST_Key", big and -2000 or 0, big and -2000 or 0, big and 5000 or 1024, big and 5000 or 768)
			if ok then B24T.injected[menu] = true else print("[B24TEST] inject " .. menu .. ": " .. tostring(err)) end
			pcall(EEex_Menu_InjectTemplate, menu, "B24TEST_Status", 0, 0, 1024, 32)
		end
	end
end

-----------------
-- World phase --
-----------------

local function protagonist() return EEex_Sprite_GetInPortrait(0) end

local function queue(sprite, actions)
	EEex_Action_QueueResponseStringOnAIBase(actions, sprite)
end

local function signature(levels)
	return (levels[1] or 0) * 10000 + (levels[2] or 0) * 100 + (levels[3] or 0)
end

local function check(cond, text, failures)
	if not cond then table.insert(failures, text) end
end

local function prof(level) return 2 + math.floor((math.max(1, math.min(20, level)) - 1) / 4) end

-- Sets class, kit, levels and subclass for the step.
local function setUp(sprite, step)
	local class = step.class
	local levels = {}
	for i = 1, 3 do levels[i] = i <= #class.keys and step.level or 0 end
	step.levels = levels
	step.signature = signature(levels)
	-- No level-up popups during the test: the runtime only opens them while B24LVASK differs.
	sprite:setLocalInt("B24LVASK", step.signature)
	for _, key in ipairs(class.keys) do
		sprite:setLocalInt(B24LV.SubclassLocal(key), step.subclass)
	end
	sprite:setLocalInt("B24SUBC", 0)
	-- Levels written directly come without hit points: the Constitution check (B24MULTI.lua) starts
	-- anew instead of adding them.
	sprite:setLocalInt("B24HPLV", 0)
	-- ChangeStat can't set levels: levels and kit are written directly, and ChangeClass makes the
	-- engine recompute the stats from them. The KIT stat is (upper word << 16) | lower word: the
	-- Barbarian kit (0x40000000) is upper word 0x4000, no kit (TRUECLASS 0x4000) lower word 0x4000.
	local ok, err = pcall(function()
		sprite.m_baseStats.m_level1 = levels[1]
		sprite.m_baseStats.m_level2 = levels[2]
		sprite.m_baseStats.m_level3 = levels[3]
		sprite.m_baseStats.m_mageSpecUpperWord = class.barbarian and 0x4000 or 0
		sprite.m_baseStats.m_mageSpecialization = class.barbarian and 0 or 0x4000
	end)
	if not ok then table.insert(B24T.errors, "setup: " .. tostring(err)) end
	-- The levels change now, the class only when the action runs: features applied in between are
	-- the old class's at the new level, and the level signature doesn't see the class change
	-- (settle() applies them again once the class has changed).
	queue(sprite, string.format("ChangeClass(Myself,%d)", class.id))
	-- ChangeClass to the class the creature already has changes nothing: removing an effect makes
	-- the engine recompute the stats from the base values (adding one only resolves the new effect).
	B24.ApplyEffect(sprite, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60,
		["m_sourceRes"] = "B24TREF" })
	B24.RemoveEffectsBySource(sprite, "B24TREF")
end

-- Base ability scores and AC: only the level changes between steps, so these must stay as they
-- were when the test started (class features that add to them must not stack on re-apply). The base
-- hit points too: levels written directly come without any (the Constitution check, B24MULTI.lua,
-- must not add them either).
local function baseStats(sprite)
	local b = sprite.m_baseStats
	return { STR = b.m_STRBase, DEX = b.m_DEXBase, CON = b.m_CONBase, INT = b.m_INTBase, WIS = b.m_WISBase,
		CHA = b.m_CHRBase, AC = b.m_armorClass, HP = b.m_maxHitPointsBase }
end

local function statLine(sprite)
	local base = baseStats(sprite)
	local parts = {}
	for _, key in ipairs({ "STR", "DEX", "CON", "INT", "WIS", "CHA" }) do
		table.insert(parts, string.format("%s %d/%d", key, base[key], sprite:getStat(B24.AbilityStat[key])))
	end
	table.insert(parts, string.format("AC base %d, engine %d (2024 AC %d)", base.AC, sprite:getStat(B24.Stat.AC),
		20 - sprite:getStat(B24.Stat.AC)))
	table.insert(parts, string.format("base HP %d", base.HP))
	return table.concat(parts, ", ")
end

-- Once the queued ChangeClass has run: the class features again, for the new class (an apply
-- between the level change and the class change was the old class's).
local function settle(sprite, step)
	if not step.settled and B24.ClassID(sprite) == step.class.id then
		step.settled = true
		sprite:setLocalInt("B24LVAPP", 0)
	end
end

local function ready(sprite, step)
	return B24.ClassID(sprite) == step.class.id
		and sprite:getStat(B24.Stat.LEVEL) == step.levels[1]
		and (#step.class.keys < 2 or sprite:getStat(B24.Stat.LEVEL2) == step.levels[2])
		and (step.class.barbarian == nil) == (B24.SkillClass(sprite) ~= "BARBARIAN")
		and sprite:getLocalInt("B24LVAPP") == step.signature
end

local function verify(sprite, step)
	local failures = {}
	for _, err in ipairs(B24T.errors) do table.insert(failures, "Lua error: " .. err:gsub("\n.*", "")) end
	local class = step.class
	for _, key in ipairs(class.keys) do
		check(B24LV.ClassLevel(sprite, key) == step.level, key .. " level " .. B24LV.ClassLevel(sprite, key), failures)
		check(B24LV.AppliedClassLevel(sprite, key) == step.level, key .. " applied level " .. B24LV.AppliedClassLevel(sprite, key), failures)
		local entry = B24LV.SUBCLASSES[key]
		if step.subclass > 0 and entry then
			local want = entry.list[step.subclass].key
			check(B24LV.Subclass(sprite, key) == want, string.format("%s subclass %s, expected %s", key, tostring(B24LV.Subclass(sprite, key)), want), failures)
		end
	end
	-- 2024: proficiency from the character level, the sum of the class levels.
	local characterLevel = step.levels[1] + step.levels[2] + step.levels[3]
	check(B24.ProfOf(sprite) == prof(characterLevel), "proficiency +" .. B24.ProfOf(sprite) .. ", expected +" .. prof(characterLevel), failures)


	-- No stacking: base scores and AC as at the start; current scores and AC in sane ranges.
	local base = baseStats(sprite)
	for key, value in pairs(B24T.startStats) do
		if key ~= "HP" then
			check(base[key] == value, string.format("base %s %d, was %d at the start", key, base[key], value), failures)
		end
	end
	-- Hit points: the engine adds the Constitution modifier per level when the steps change the
	-- level, so they move; they must not run away (no class gets more than 12 per level).
	local total = sprite:getStat(B24.Stat.LEVEL) + sprite:getStat(B24.Stat.LEVEL2) + sprite:getStat(B24.Stat.LEVEL3)
	local cap = B24T.startStats.HP + 12 * total
	check(base.HP <= cap, string.format("base HP %d, more than %d (%d at the start + 12 per level)", base.HP, cap,
		B24T.startStats.HP), failures)
	for _, key in ipairs(ABILITIES) do
		local score = sprite:getStat(B24.AbilityStat[key])
		check(score >= 3 and score <= 30, string.format("%s %d", key, score), failures)
	end
	local ac = 20 - sprite:getStat(B24.Stat.AC)
	check(ac >= 5 and ac <= 30, "2024 AC " .. ac, failures)

	-- Saves: modifiers compute; the class's proficient saves (below the levels where features add more).
	for _, ability in ipairs(ABILITIES) do
		local ok, mod = pcall(B24.SaveModifier, sprite, ability)
		check(ok and type(mod) == "number", ability .. " save modifier: " .. tostring(mod), failures)
	end
	if class.saves and step.level < 14 then
		for _, ability in ipairs(class.saves) do
			check(B24.IsSaveProficient(sprite, ability), "not proficient in " .. ability .. " saves", failures)
		end
	end

	-- Resources, feature texts, pending choices and UI helpers run without errors.
	for key, resource in pairs(B24LV.RESOURCES) do
		local ok, max = pcall(resource.max, sprite)
		check(ok and type(max) == "number", "resource " .. key .. " max: " .. tostring(max), failures)
		if ok then
			local ok2, left = pcall(B24LV.Remaining, sprite, key)
			check(ok2, "resource " .. key .. " remaining: " .. tostring(left), failures)
		end
	end
	local calls = {
		{ "FeatureLines", B24LV.FeatureLines, sprite },
		{ "Pending", B24LV.Pending, sprite },
		{ "B24UI_ACDetails", B24UI_ACDetails, 0 },
		{ "B24UI_AttackDetails", B24UI_AttackDetails, 0 },
	}
	for _, call in ipairs(calls) do
		if call[2] then
			local ok, err = pcall(call[2], call[3])
			check(ok, call[1] .. ": " .. tostring(err), failures)
		end
	end
	return failures
end

local function stepName(step)
	local name = string.format("%s %d", step.class.name, step.level)
	if step.subclass > 0 then
		local entry = B24LV.SUBCLASSES[step.class.keys[1]]
		name = name .. " (" .. (entry and entry.list[step.subclass].name or ("subclass " .. step.subclass)) .. ")"
	end
	return name
end

function B24T.Finish()
	B24T.phase = "done"
	out(string.format("popups suppressed: %d", B24T.popups or 0))
	out(string.format("DONE %d %d", B24T.passed, B24T.failed))
end

local function nextStep(sprite)
	B24T.step = B24T.step + 1
	local step = B24T.steps[B24T.step]
	if step == nil then
		B24T.Finish()
		return
	end
	B24T.errors = {}
	B24T.SetStatus(string.format("%s (step %d of %d)", stepName(step), B24T.step, #B24T.steps))
	step.start = B24.GameTick()
	setUp(sprite, step)
end

-- Called from the global script (B24_HasPendingScreens) on every AI update.
-- Character creation test in the game: driven by frames, since a new game starts paused (and a
-- paused game runs no scripts). Clicks go on while the chapter text is up.
function B24T.FrameTick()
	-- Joining: the companion's level-ups, frame by frame like the protagonist's in character creation.
	if B24TEST_MODE == "joining" and B24T.leveling then
		local sprite = B24.GetSprite(B24TCG.lv.id)
		if sprite == nil or B24TCG.LevelFrame(sprite) then
			B24T.leveling = false
			out("CLICKS OFF")
		end
		return
	end
	if B24TEST_MODE ~= "chargen" or B24T.phase ~= "loading" then return end
	-- Level-ups (B24TEST_LEVELUP) run across the record and level-up screens: B24TCG counts frames.
	if B24T.leveling then
		local sprite = protagonist()
		if sprite and B24TCG.LevelFrame(sprite) then 
			-- The level cap: past 20 no engine level-up, Epic Boons instead (B24GFEAT.lua). Only for runs
			-- that level up to 20 (ToB).
			if B24GF and B24GF.BoonsPastTwenty and B24.Level(sprite) >= 20 then
				local pending = B24LV.Pending(sprite)
				local boonRows = 0
				for _, row in ipairs(B24GF.Rows(sprite)) do if row.feat.boon then boonRows = boonRows + 1 end end
				out(string.format("Epic Boon rows offered in the feat list: %d", boonRows))
				out(string.format("after the level-ups: level %d, XP %d, engine level-up %s, boons past 20: %d, choices pending: ASI %d",
					B24.Level(sprite), sprite.m_baseStats.m_xp, tostring(Infinity_CanLevelUp and Infinity_CanLevelUp(0)),
					B24GF.BoonsPastTwenty(sprite), pending.ASI))
				-- XP of what was level 22 for the class (a Fighter: 3500000): two boons, no engine level-up.
				local xp22 = B24GF.XPForBoon(sprite, 2) or 3500000
				sprite.m_baseStats.m_xp, sprite.m_derivedStats.m_nXP, sprite.m_tempStats.m_nXP = xp22, xp22, xp22
				local later = B24LV.Pending(sprite)
				out(string.format("with %d XP: boons past 20: %d, choices pending: ASI %d, engine level-up %s", xp22, B24GF.BoonsPastTwenty(sprite),
					later.ASI, tostring(Infinity_CanLevelUp and Infinity_CanLevelUp(0))))
				B24T.ConditionCheck("level cap and Epic Boons", { level20 = B24.Level(sprite) == 20, boonRows = boonRows > 0, boons = B24GF.BoonsPastTwenty(sprite) == 2,
					pending = later.ASI >= 2 })
			end
			B24T.Finish()
		end
		return
	end
	if worldScreen == nil or e:GetActiveEngine() ~= worldScreen or Infinity_IsMenuOnStack("CHAPTER") then
		B24T.worldFrames = 0
		return
	end
	B24T.worldFrames = (B24T.worldFrames or 0) + 1
	local sprite = protagonist()
	if B24T.worldFrames == 1 then
		out("game started")
	elseif B24T.worldFrames == 60 and sprite then
		B24TCG.StartTrace(sprite)
	elseif B24T.worldFrames == 120 and sprite and B24TEST_IMPORT then
		-- An imported character (Export run in BG:EE): its mod variables came along (B24CORE.lua
		-- B24.WriteLocalCarriers): Fighter 4, Champion, and the skills, background and species in the
		-- character file (B24TEST_IMPORT_LOCALS, read by the test script; they are the BG:EE save's
		-- protagonist's and differ between runs).
		B24TCG.Report(sprite)
		local parts = {}
		for _, name in ipairs({ "B24LVAPP", "B24SKILL", "B24BG", "B24SPC", "B24SETUP", "B24SCFIG", "B24ASIDN" }) do
			table.insert(parts, string.format("%s=%d", name, sprite:getLocalInt(name)))
		end
		out("imported locals: " .. table.concat(parts, " "))
		local file = B24TEST_IMPORT_LOCALS or {}
		out(string.format("in the character file: B24SKILL=%s B24BG=%s B24SPC=%s", tostring(file.B24SKILL), tostring(file.B24BG), tostring(file.B24SPC)))
		B24T.ConditionCheck("imported character keeps the mod's choices", { subclass = B24LV.Subclass(sprite, "FIGHTER") == "CHAMPION",
			skills = file.B24SKILL ~= nil and sprite:getLocalInt("B24SKILL") == file.B24SKILL,
			background = file.B24BG ~= nil and sprite:getLocalInt("B24BG") == file.B24BG,
			species = file.B24SPC ~= nil and sprite:getLocalInt("B24SPC") == file.B24SPC,
			carriersGone = not B24.HasEffectSource(sprite, 402, B24.LOCALS_RES) })
		out("SHOT 99-imported")
		B24T.Finish()
	elseif B24T.worldFrames == 120 and sprite then
		B24TCG.EndTrace()
		B24TCG.Report(sprite)
		out("SHOT 99-world")
		out("CLICKS OFF")
	elseif B24T.worldFrames == 150 and sprite and B24TEST_LEVELUP then
		B24T.leveling = B24TCG.StartLevelUps(sprite)
	elseif B24T.worldFrames == 150 and sprite then
		B24T.casting = B24TCG.StartCast(sprite)
	elseif B24T.casting == true and sprite and (B24.GameTick() >= B24TCG.castTick + 20 or B24T.worldFrames >= 20000) then
		-- 20 ticks of game time after the cast (the runtime checks every 15).
		B24T.casting = "checked"
		B24T.checkedFrame = B24T.worldFrames
		B24TCG.CheckCast(sprite)
		B24TCG.Report(sprite)
		out("SHOT 98-after-cast")
	elseif (B24T.casting == "checked" and B24T.worldFrames == B24T.checkedFrame + 100)
		or (not B24T.casting and B24T.worldFrames == 240) then
		B24T.Finish()
	end
end

-- Every frame on the game screen (scripts don't run while the game is paused): a pause is lifted,
-- so the test goes on. Menus are left alone here (changing them while the screen renders is not
-- safe); WorldTick closes choice popups.
-- The protagonist's death (Dying mode) ends the game: the game clock stops, so this runs per
-- frame, on the game screen and the menus after it.
-- Modes in which the protagonist may die on purpose (and come back): their own checks decide.
local DEATH_MODES = { dying = true, downhits = true }

function B24T.GameOverCheck()
	if B24T.phase == "done" then return end
	-- An unexpected death ends the test (the game would wait on its death screen): a failure, and
	-- the test script closes the game.
	if not B24T.expectGameOver and not DEATH_MODES[B24TEST_MODE] and B24T.phase ~= "menu" then
		local p = B24.Protagonist()
		if p ~= nil and B24.GState_Has(p, B24.GState.DEAD) then
			out(string.format("FAIL the protagonist died (%s)", tostring(B24T.status or B24T.phase)))
			out("SHOT 98-protagonist-died")
			B24T.failed = B24T.failed + 1
			B24T.Finish()
		end
		return
	end
	if not B24T.expectGameOver then return end
	if not B24T.gameOverAt then
		local p = B24.Protagonist()
		if p == nil or not B24.GState_Has(p, B24.GState.DEAD) then return end
		B24T.gameOverAt = Infinity_GetClockTicks()
		B24T.passed = B24T.passed + 1
		out("PASS " .. (B24T.gameOverLabel or "protagonist dies when the minute runs out"))
		out("SHOT 65-protagonist-dead")
	elseif not B24T.gameOverShot and Infinity_GetClockTicks() - B24T.gameOverAt > 6000 then
		B24T.gameOverShot = true
		out("SHOT 66-game-over")
	elseif Infinity_GetClockTicks() - B24T.gameOverAt > 9000 then
		B24T.Finish()
	end
end

-- Stall report: when the test step has not moved for 10 seconds, what the game is doing (every 10
-- seconds; per frame, so it also runs when the game clock stands still).
function B24T.StallReport()
	if not B24T.InWorldPhase() or B24T.phase == "report" then return end
	local now = Infinity_GetClockTicks()
	local marker = tostring(B24T.step) .. ":" .. tostring(B24T.phase) .. ":" .. tostring(B24T.mcStep) .. ":" .. tostring(B24T.dyingStep)
		.. ":" .. tostring(B24T.fStep) .. ":" .. tostring(B24T.companions and B24T.companions.index)
		.. ":" .. tostring(B24T.joining and B24T.joining.index) .. ":" .. tostring(B24T.turnStep)
	-- A level-up (Joining) moves on by itself: its level, state and quiet frames count as progress.
	local lv = B24T.leveling and B24TCG and B24TCG.lv
	if lv then marker = marker .. string.format(":%d:%s:%d", lv.level, lv.state, math.floor((lv.quiet or 0) / 60)) end
	if marker ~= B24T.stallMarker then
		B24T.stallMarker, B24T.stallSince, B24T.stallLast = marker, now, now
		return
	end
	if now - B24T.stallSince < 10000 or now - B24T.stallLast < 10000 then return end
	B24T.stallLast = now
	local ok, mode = pcall(EEex_GameState_GetInputMode)
	local okP, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	local parts = { string.format("STALL step %s for %ds: game tick %d, input mode %s, paused %s, screen %s", tostring(B24T.step),
		math.floor((now - B24T.stallSince) / 1000), B24.GameTick(), tostring(ok and mode), tostring(okP and paused),
		tostring(e:GetActiveEngine() == worldScreen and "world" or "other")) }
	for i = 0, 5 do
		local s = EEex_Sprite_GetInPortrait(i)
		if B24.IsSprite(s) then
			table.insert(parts, string.format("%s action %d at %d.%d", B24.Name(s), s.m_curAction.m_actionID, s.m_pos.x, s.m_pos.y))
		end
	end
	local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	table.insert(parts, string.format("time stop %d", g.m_nTimeStop))
	out(table.concat(parts, "; "))
end

function B24T.Watchdog()
	if B24T.expectGameOver then return end
	if B24T.ChoiceDriven() then return end
	if not B24T.InWorldPhase() then return end
	if B24T.popupShownAt and Infinity_GetClockTicks() - B24T.popupShownAt < 4000 then return end
	-- A choice popup pauses the game as in play (no script, so no conversation, starts over it): once
	-- its screenshot time is over, the watchdog closes it, which runs the game on (the world tick,
	-- which closed it before, stands still under it). The level-up driver and the Record mode handle
	-- their popups themselves.
	if B24T.leveling or B24T.phase == "record" then return end
	-- A reaction prompt of the turn-based mode (B24TURN.lua): a screenshot, then the answer a player
	-- would give (B24T.reactionAnswer: the choice's number, nil for No; Yes by default).
	if B24TB and B24TB.asking then
		local clock = Infinity_GetClockTicks()
		if not B24T.promptSeen then
			B24T.promptSeen = clock
			B24T.prompts = (B24T.prompts or 0) + 1
			out(string.format("reaction prompt: %s", tostring(B24TB.asking.text)))
			out(string.format("SHOT 81-reaction-prompt-%d", B24T.prompts))
		elseif clock - B24T.promptSeen > 2500 then
			B24T.promptSeen = nil
			local answer = B24T.reactionAnswer
			if answer == nil then answer = 1 elseif answer == false then answer = nil end
			B24TB.Answer(answer)
		end
		return
	end
	if Infinity_IsMenuOnStack("B24_LEVELUP") then
		B24LV_Cancel()
		out("closed a choice popup (step " .. B24T.step .. ")")
		return
	end
	local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
	if ok and (paused == true or paused == 1) then
		EEex_GameState_TogglePause(false, false)
		B24T.unpaused = (B24T.unpaused or 0) + 1
		if B24T.unpaused <= 5 then out("watchdog: game was paused (step " .. B24T.step .. "), unpaused") end
	end
end

function B24T.WorldTick()
	-- Conversations off, again every 5 seconds: creatures walking in later (Candlekeep's watchers)
	-- would start theirs too.
	if B24TEST_MODE ~= "chargen" and B24T.InWorldPhase() and B24.GameTick() - (B24T.silencedAt or -1000) >= 75 then
		B24T.silencedAt = B24.GameTick()
		pcall(B24T.SilenceDialogs)
	end
	-- The status line on the game screen (B24TEST.menu).
	if worldScreen and e:GetActiveEngine() == worldScreen and not Infinity_IsMenuOnStack("B24TEST_STATUS") then
		Infinity_PushMenu("B24TEST_STATUS")
	end
	if B24TEST_MODE == "joining" and B24T.leveling then
		local sprite = B24.GetSprite(B24TCG.lv.id)
		if sprite then B24TCG.LevelScript(sprite) end
		return
	end
	if B24TEST_MODE == "chargen" then
		-- Script context: the level-up test opens the record screen from here.
		if B24T.leveling then
			local sprite = protagonist()
			if sprite then B24TCG.LevelScript(sprite) end
		end
		return
	end
	-- A choice popup still open (the one shown for the screenshot): its Cancel closes it.
	if B24T.InWorldPhase() and B24LV_Title and B24LV_Title() ~= ""
		and not B24T.ChoiceDriven()
		and not (B24T.popupShownAt and Infinity_GetClockTicks() - B24T.popupShownAt < 4000) then
		B24LV_Cancel()
		out("closed a choice popup (step " .. B24T.step .. ")")
	end
	if B24T.phase == "loading" or B24T.phase == "menu" then
		if worldScreen == nil or e:GetActiveEngine() ~= worldScreen then return end
		B24T.phase = "world"
		B24T.worldStart = B24.GameTick()
		B24.Config.roundPause = false
		out(B24TEST_MODE == "chargen" and "game started" or "save loaded")
		-- Conversations go off once the area has settled (B24T.SilenceDialogs, in the world tick).
		B24T.silencedAt = nil
		out("CLICKS OFF")
		return
	end
	if B24T.phase == "report" then
		-- Time for the screenshot of the game screen.
		if B24.GameTick() - B24T.reportAt > 45 then B24T.Finish() end
		return
	end
	if B24T.phase ~= "world" and B24T.phase ~= "steps" then return end
	local sprite = protagonist()
	if sprite == nil then return end
	local now = B24.GameTick()
	if B24T.phase == "world" then
		if now - B24T.worldStart < 30 then return end
		if B24TEST_MODE == "icons" then
			B24T.IconTick(sprite, now)
			return
		end
		if B24TEST_MODE == "companions" then
			B24T.CompanionsTick(sprite, now)
			return
		end
		if B24TEST_MODE == "slayer" then
			B24T.SlayerTick(sprite, now)
			return
		end
		if B24TEST_MODE == "wildshape" then
			B24T.WildShapeTick(sprite, now)
			return
		end
		if B24TEST_MODE == "turnplay" then
			B24T.TurnPlayTick(sprite, now)
			return
		end
		if B24TEST_MODE == "petrify" then
			B24T.PetrifyTick(sprite, now)
			return
		end
		if B24TEST_MODE == "drain" then
			B24T.DrainTick(sprite, now)
			return
		end
		if B24TEST_MODE == "export" then
			B24T.ExportTick(sprite, now)
			return
		end
		if B24TEST_MODE == "rangeprobe" then
			B24T.RangeProbeTick(sprite, now)
			return
		end
		if B24TEST_MODE == "xpcap" then
			B24T.XPCapTick(sprite, now)
			return
		end
		if B24TEST_MODE == "record" then
			B24T.RecordTick(sprite, now)
			return
		end
		if B24TEST_MODE == "saveload" then
			B24T.SaveLoadTick(sprite, now)
			return
		end
		if B24TEST_MODE == "spells" then
			B24T.SpellsTick(sprite, now)
			return
		end
		if B24TEST_MODE == "joining" then
			B24T.JoiningTick(sprite, now)
			return
		end
		if B24TEST_MODE == "features" then
			B24T.FeaturesTick(sprite, now)
			return
		end
		if B24TEST_MODE == "multiclass" then
			B24T.MulticlassTick(sprite, now)
			return
		end
		if B24TEST_MODE == "downhits" then
			B24T.DownHitsTick(sprite, now)
			return
		end
		if B24TEST_MODE == "turns" then
			B24T.TurnsTick(sprite, now)
			return
		end
		if B24TEST_MODE == "turncombat" then
			B24T.CombatTick(sprite, now)
			return
		end
		if B24TEST_MODE == "turnprobe" then
			B24T.ProbeTick(sprite, now)
			return
		end
		if B24TEST_MODE == "dying" then
			B24T.DyingTick(sprite, now)
			return
		end
		if B24TEST_MODE == "chargen" then
			B24TCG.Report(sprite)
			out("SHOT 99-world")
			B24T.phase = "report"
			B24T.reportAt = now
			return
		end
		buildSteps()
		B24T.startStats = baseStats(sprite)
		out("start: " .. statLine(sprite))
		out(string.format("%d steps on %s", #B24T.steps, B24.Name(sprite)))
		B24T.phase = "steps"
		nextStep(sprite)
		return
	end
	local step = B24T.steps[B24T.step]
	if B24T.verbose and now ~= B24T.lastBeat and now % 15 == 0 then
		B24T.lastBeat = now
		out(string.format("tick %d step %d: class %d, level %d/%d, kit %d, applied %d", now, B24T.step, B24.ClassID(sprite),
			sprite:getStat(B24.Stat.LEVEL), sprite:getStat(B24.Stat.LEVEL2), sprite:getStat(B24.Stat.KIT), sprite:getLocalInt("B24LVAPP")))
	end
	if not step.applied then
		if ready(sprite, step) then
			step.applied = now
		elseif now - step.start > 150 then
			out(string.format("FAIL %s: setup not applied (class %d, levels %d/%d (base %s), kit %d, applied %d, expected %d; %s)",
				stepName(step), B24.ClassID(sprite), sprite:getStat(B24.Stat.LEVEL), sprite:getStat(B24.Stat.LEVEL2),
				tostring(sprite.m_baseStats.m_level1), sprite:getStat(B24.Stat.KIT), sprite:getLocalInt("B24LVAPP"),
				step.signature, table.concat(B24T.errors, " | ")))
			B24T.failed = B24T.failed + 1
			nextStep(sprite)
		end
		return
	end
	-- Let the per-second class feature ticks run a couple of times before checking.
	if now - step.applied < 35 then return end
	local failures = verify(sprite, step)
	if #failures == 0 then
		B24T.passed = B24T.passed + 1
		out("PASS " .. stepName(step) .. " | " .. statLine(sprite))
	else
		B24T.failed = B24T.failed + 1
		out("FAIL " .. stepName(step) .. ": " .. table.concat(failures, "; ") .. " | " .. statLine(sprite))
	end
	nextStep(sprite)
end

-- Icons mode: puts the protagonist into each state that has a portrait icon (Prone and Portent
-- need a spell state or a diviner, so they are left out), checks that the icons appear, takes a
-- screenshot, then clears the states and checks that the icons go away.
local ICON_KEYS = { "CONC", "RAGE", "RECK", "EXHA", "GRAP", "REST", "HMRK", "BINS", "SMIT", "SACW", "NIMB", "DODG",
	"STAR", "INSO", "THP" }

local function iconStates(sprite, on)
	local now, aux = B24.GameTick(), B24.Aux(sprite)
	for _, key in ipairs({ "RAGE", "RECKLESS", "HOLY_NIMBUS", "INNATE_SORCERY", "STARRY_FORM", "GRANTS_DIS" }) do
		if on then B24.SetTimed(sprite, key, 120) else B24.ClearTimed(sprite, key) end
	end
	B24.Exhaustion_Set(sprite, on and 1 or 0)
	B24.Concentration[sprite.m_id] = on and { res = "B24TEST", targets = {} } or nil
	for _, key in ipairs({ "GRAPPLED", "RESTRAINED" }) do
		B24CD.active[sprite.m_id .. key] = on and { id = sprite.m_id, key = key, untilTick = now + 1800 } or nil
	end
	aux.B24_Mark = on and { target = sprite.m_id, untilTick = now + 1800 } or nil
	aux.B24_Inspired = on and { die = 6, by = sprite.m_id, untilTick = now + 1800 } or nil
	sprite:setLocalInt("B24SMTOG", on and 1 or 0)
	if on then
		B24LV.TempHP(sprite, 5, 120)
		B24.ApplyEffect(sprite, { ["effectID"] = 54, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 0,
			["duration"] = 120, ["m_sourceRes"] = "B24SACWP" })
	else
		B24.RemoveEffectsBySource(sprite, "B24TMPHP")
		B24.RemoveEffectsBySource(sprite, "B24SACWP")
	end
end

local function checkIcons(sprite, want)
	local wrong = {}
	for _, key in ipairs(ICON_KEYS) do
		if B24.HasEffectSource(sprite, 142, B24.IconRes(key)) ~= want then table.insert(wrong, key) end
	end
	if #wrong == 0 then
		B24T.passed = B24T.passed + 1
		out(string.format("PASS icons %s (%d)", want and "shown" or "hidden", #ICON_KEYS))
	else
		B24T.failed = B24T.failed + 1
		out(string.format("FAIL icons %s: %s", want and "not shown" or "still shown", table.concat(wrong, ", ")))
	end
end

local function knowsInnate(sprite, res)
	for _, _, known in EEex_Sprite_GetKnownInnateSpellsIterator(sprite) do
		if known:upper() == res then return true end
	end
	return false
end

-- checks = { name = bool }: one PASS or FAIL line listing the checks that failed.
local function conditionCheck(label, checks)
	local wrong = {}
	for name, ok in pairs(checks) do
		if not ok then table.insert(wrong, name) end
	end
	if #wrong == 0 then
		B24T.passed = B24T.passed + 1
		out("PASS " .. label)
	else
		B24T.failed = B24T.failed + 1
		out("FAIL " .. label .. ": " .. table.concat(wrong, ", "))
	end
end
-- For code above this point (the chargen world steps).
B24T.ConditionCheck = conditionCheck

function B24T.IconTick(sprite, now)
	local t = now - B24T.worldStart
	if B24T.iconStep == nil then
		out("icon states on")
		iconStates(sprite, true)
		B24T.iconStep = 1
	elseif B24T.iconStep == 1 and t > 80 then
		checkIcons(sprite, true)
		out("SHOT 50-icons")
		B24T.iconStep = 2
	elseif B24T.iconStep == 2 and t > 130 then
		out("icon states off")
		iconStates(sprite, false)
		B24T.iconStep = 3
	elseif B24T.iconStep == 3 and t > 180 then
		checkIcons(sprite, false)
		out("SHOT 51-no-icons")
		-- Then the conditions: prone (half speed for a round) and the Escape Grapple action.
		B24.KnockProne(sprite, nil)
		B24.ApplyCondition(sprite, "GRAPPLED", { seconds = 60, source = sprite, ability = "STR", dc = 1, label = "Test" })
		B24.ApplyCondition(sprite, "RESTRAINED", { seconds = 6, label = "Test" })
		B24T.iconStep = 4
	elseif B24T.iconStep == 4 and t > 200 then
		conditionCheck("prone, grappled, restrained", {
			prone = sprite:getSpellState(B24.SplState.PRONE),
			halfSpeed = B24.HasEffectSource(sprite, 176, "B24PRONE"),
			grappled = B24.HasCondition(sprite, "GRAPPLED"),
			escapeInnate = knowsInnate(sprite, "B24ESCGR"),
			restrainedHeld = sprite:getSpellState(B24.SplState.HELD),
		})
		out("SHOT 52-conditions")
		B24ESCGR(nil, sprite)
		B24T.iconStep = 5
	elseif B24T.iconStep == 5 and t > 230 then
		conditionCheck("escaped", { notGrappled = not B24.HasCondition(sprite, "GRAPPLED"),
			noEscapeInnate = not knowsInnate(sprite, "B24ESCGR") })
		B24T.iconStep = 6
	elseif B24T.iconStep == 6 and t > 290 then
		conditionCheck("stood up", { notProne = not sprite:getSpellState(B24.SplState.PRONE),
			fullSpeed = not B24.HasEffectSource(sprite, 176, "B24PRONE") })
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Dying mode: drops the protagonist to 0 and walks through death saves, stable, healing and the
-- minute after the third failure (Revivify); then a companion (if any) dies, is revived by casting
-- Revivify, and dies outright from massive damage.
local function hit(sprite, amount, source)
	B24.ApplyEffect(sprite, { ["effectID"] = 12, ["effectAmount"] = amount, ["dwFlags"] = 0, ["durationType"] = 1,
		["sourceID"] = source and source.m_id or nil })
end
local function dyState(sprite) return sprite:getLocalInt("B24DYDN") end
local function hp(sprite) return sprite.m_baseStats.m_hitPoints end
-- Down to 0 and no further: what goes past 0 kills outright once it reaches the hit point maximum
-- (8 for a level 1 BG:EE protagonist), so a fixed 10 would be massive damage there.
local function knockDown(sprite, source) hit(sprite, hp(sprite) + 1, source) end
local function asleep(sprite) return B24.GState_Has(sprite, B24.GState.SLEEPING) end
local function dead(sprite) return B24.GState_Has(sprite, B24.GState.DEAD) end
local function companion()
	return B24T.companionID and B24.GetSprite(B24T.companionID)
end

local DYING_STEPS = {
	-- Party AI off: in BG2:EE the protagonist's AI heals a downed party member with its Bhaalspawn
	-- Cure Wounds (SPIN101), which the checks below don't expect. The test doesn't save the game.
	{ 40, function(p)
		local ok, aiOn = pcall(function() return game:GetPartyAI() end)
		if ok and aiOn then pcall(function() game:ToggleAI() end) end
		out(string.format("party AI was %s, now off", tostring(aiOn)))
	end },
	{ 60, function(p) p.m_baseStats.m_hitPoints = 3 knockDown(p) end },
	{ 80, function(p)
		conditionCheck("drops to 0", { down = dyState(p) == 1, oneHP = hp(p) == 1, asleep = asleep(p), alive = not dead(p) })
		out("SHOT 60-dying")
		B24DY.TestRoll = 15
		p:setLocalInt("B24DYAT", 0)
	end },
	{ 100, function(p)
		conditionCheck("death save success", { success = p:getLocalInt("B24DYSUC") == 1, stillDown = dyState(p) == 1 })
		p:setLocalInt("B24DYSUC", 2)
		B24DY.TestRoll = 12
		p:setLocalInt("B24DYAT", 0)
	end },
	{ 120, function(p)
		conditionCheck("stable", { stable = dyState(p) == 2, asleep = asleep(p) })
		p:setLocalInt("B24DYAT", 0)
	end },
	{ 140, function(p)
		conditionCheck("wakes when stable", { up = dyState(p) == 0, oneHP = hp(p) == 1, awake = not asleep(p) })
		knockDown(p)
	end },
	{ 160, function(p)
		conditionCheck("drops to 0 from 1 hit point", { down = dyState(p) == 1 })
		B24.ApplyEffect(p, { ["effectID"] = 17, ["effectAmount"] = 5, ["dwFlags"] = 0, ["durationType"] = 1 })
	end },
	{ 180, function(p)
		out(string.format("after healing 5: hit points %d, dying state %d (level %d, class %d, Second Wind uses %d)", hp(p), dyState(p),
			p:getStat(B24.Stat.LEVEL), p.m_typeAI.m_Class, p:getLocalInt("B24SWUSE")))
		conditionCheck("healing wakes", { up = dyState(p) == 0, healed = hp(p) == 5, awake = not asleep(p) })
		p.m_baseStats.m_hitPoints = 2
		knockDown(p)
	end },
	{ 200, function(p)
		p:setLocalInt("B24DYFAI", 2)
		hit(p, 5)
	end },
	{ 220, function(p)
		conditionCheck("protagonist past the third failure", { beyond = dyState(p) == 3, alive = not dead(p), asleep = asleep(p) })
		out("SHOT 61-beyond")
		B24REVIV(nil, p)
	end },
	{ 240, function(p)
		conditionCheck("Revivify brings the protagonist back", { up = dyState(p) == 0, oneHP = hp(p) == 1, awake = not asleep(p) })
	end },
	-- Companion steps: the mod's wolf (B24BST03, no dialogue, in both games) joins the party without its
	-- scripts. Story companions like BG2's Imoen leave the party rather than die.
	{ 250, function(p)
		queue(p, 'CreateCreatureObject("B24BST03",Myself,0,0,0)')
	end },
	{ 265, function(p)
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" and not B24.InParty(s) then B24T.companionID = s.m_id break end
		end
		local c = companion()
		if c == nil then
			out("FAIL companion: no B24BST03 created")
			B24T.failed = B24T.failed + 1
			return
		end
		-- Scripts off first, so it doesn't act on its own.
		queue(c, 'SetDialog("") ChangeAIScript("",OVERRIDE) ChangeAIScript("",CLASS) ChangeAIScript("",RACE) ChangeAIScript("",GENERAL) ChangeAIScript("",DEFAULT) SetDialog("")')
	end },
	{ 285, companion = true, function(p, c)
		queue(c, 'JoinParty()')
	end },
	{ 315, companion = true, function(p, c)
		conditionCheck("companion joins", { inParty = B24.InParty(c), minimumHP = B24.HasEffectSource(c, 208, B24DY.MIN_HP_RES) })
		c.m_baseStats.m_hitPoints = 3
		knockDown(c, p)
	end },
	{ 320, companion = true, function(p, c)
		conditionCheck("companion drops to 0", { down = dyState(c) == 1 })
		c:setLocalInt("B24DYFAI", 2)
		hit(c, 5)
	end },
	{ 360, companion = true, function(p, c)
		conditionCheck("companion dies on the third failure", { dead = dead(c), deathTime = c:getLocalInt("B24DYDTH") ~= 0 })
		out("SHOT 62-companion-dead")
		queue(p, string.format('ReallyForceSpellRES("B24REVIV",Player%d)', EEex_Sprite_GetPortraitIndex(c) + 1))
		B24T.healWatch = { id = c.m_id, reports = 0, hp = hp(c) }
	end },
	{ 420, companion = true, function(p, c)
		out(string.format("after Revivify (cast): companion %s, hit points %d of %d, dying state %d", B24.Name(c), hp(c),
			c:getActiveStats().m_nMaxHitPoints, dyState(c)))
		conditionCheck("Revivify (cast) brings the companion back", { alive = not dead(c), oneHP = hp(c) == 1 })
		out("SHOT 63-revived")
		c.m_baseStats.m_hitPoints = 3
		hit(c, 3 + c:getActiveStats().m_nMaxHitPoints + 1, p)
	end },
	{ 460, companion = true, function(p, c)
		conditionCheck("massive damage kills outright", { dead = dead(c), notDown = dyState(c) == 0 })
		-- Too late: Revivify only works within a minute of death.
		c:setLocalInt("B24DYDTH", B24.GameTick() - B24DY.REVIVIFY_TICKS - 15)
		queue(p, string.format('ReallyForceSpellRES("B24REVIV",Player%d)', EEex_Sprite_GetPortraitIndex(c) + 1))
	end },
	{ 520, companion = true, function(p, c)
		conditionCheck("Revivify fails after a minute", { stillDead = dead(c) })
		-- Raise Dead (as in a temple) has no time limit.
		queue(p, string.format('ReallyForceSpellRES("SPPR504",Player%d)', EEex_Sprite_GetPortraitIndex(c) + 1))
	end },
	{ 650, companion = true, function(p, c)
		conditionCheck("Raise Dead brings the companion back", { alive = not dead(c),
			minimumHP = B24.HasEffectSource(c, 208, B24DY.MIN_HP_RES), deathTimeCleared = c:getLocalInt("B24DYDTH") == 0 })
		out("SHOT 64-raised")
		c.m_baseStats.m_hitPoints = 3
		knockDown(c, p)
	end },
	{ 670, companion = true, function(p, c)
		conditionCheck("raised companion drops to 0 again", { down = dyState(c) == 1, alive = not dead(c) })
	end },
	-- Last: the protagonist goes down, fails three death saves, no one helps within the minute,
	-- and the game ends.
	{ 690, function(p)
		p.m_baseStats.m_hitPoints = 3
		knockDown(p)
		B24T.healWatch = { id = p.m_id, reports = 0, hp = hp(p) }
		out(string.format("protagonist knocked down: hit points %d, dying state %d", hp(p), dyState(p)))
	end },
	{ 710, function(p)
		p:setLocalInt("B24DYFAI", 2)
		hit(p, 5)
	end },
	{ 730, function(p)
		out(string.format("protagonist after the second knock-down: hit points %d, dying state %d, failures %d, dead %s", hp(p),
			dyState(p), p:getLocalInt("B24DYFAI"), tostring(dead(p))))
		conditionCheck("protagonist past the third failure (again)", { beyond = dyState(p) == 3 })
		-- The minute runs out. Death stops the game clock: B24T.GameOverCheck (per frame) takes over.
		p:setLocalInt("B24DYAT", 0)
		B24T.expectGameOver = true
	end },
	{ 1500, function(p)
		conditionCheck("protagonist dies when the minute runs out", { dead = dead(p) })
		return true
	end },
}

-- Diagnostics: who heals a creature that should stay at 0 or 1 hit points (BG2:EE healed the
-- revived companion and the downed protagonist to full). Every rise in its hit points is printed
-- with what the party members are doing and the effects on the creature.
local function watchHealing(sprite, now)
	local w = B24T.healWatch
	if w == nil then return end
	local target = B24.GetSprite(w.id)
	if target == nil then return end
	local hp = target.m_baseStats.m_hitPoints
	if w.hp and hp > w.hp and w.reports < 4 then
		w.reports = w.reports + 1
		local parts = {}
		for i = 0, 5 do
			local s = EEex_Sprite_GetInPortrait(i)
			if B24.IsSprite(s) then
				table.insert(parts, string.format("%s action %d %s", B24.Name(s), s.m_curAction.m_actionID,
					tostring(B24.ActionSpellRes(s.m_curAction))))
			end
		end
		local effects = {}
		EEex_Utility_IterateCPtrList(target.m_timedEffectList, function(e)
			if #effects < 12 then table.insert(effects, string.format("op%d %s", e.m_effectId, e.m_sourceRes:get())) end
		end)
		out(string.format("healing watch: %s %d -> %d at tick %d; %s; effects: %s", B24.Name(target), w.hp, hp, now,
			table.concat(parts, ", "), table.concat(effects, " ")))
	end
	w.hp = hp
end

function B24T.DyingTick(sprite, now)
	local okWatch, errWatch = pcall(watchHealing, sprite, now)
	if not okWatch and not B24T.watchError then
		B24T.watchError = true
		out("healing watch error: " .. tostring(errWatch))
	end
	local t = now - B24T.worldStart
	B24T.dyingStep = B24T.dyingStep or 1
	local step = DYING_STEPS[B24T.dyingStep]
	if step == nil or t <= step[1] then return end
	B24T.dyingStep = B24T.dyingStep + 1
	local c = companion()
	local ok, result = true, nil
	if not step.companion or c ~= nil then ok, result = pcall(step[2], sprite, c) end
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL dying step " .. (B24T.dyingStep - 1) .. ": " .. tostring(result))
	end
	if result == true or DYING_STEPS[B24T.dyingStep] == nil then
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Turnprobe mode (feasibility of turn-based combat): makes one creature the engine's Time Stop
-- caster, orders both the protagonist and a companion to walk, and checks that only the caster
-- moves. Then the other way round.
local function game() return EngineGlobals.g_pBaldurChitin.m_pObjectGame end
local function pos(s) return s.m_pos.x, s.m_pos.y end
local function moved(s, from) local x, y = pos(s) return math.abs(x - from[1]) + math.abs(y - from[2]) > 20 end
local function walk(s, dx) local x, y = pos(s) queue(s, string.format("MoveToPoint([%d.%d])", x + dx, y)) end

local function timeStop(caster, ticks)
	local g = game()
	g.m_nTimeStopCaster = caster and caster.m_id or -1
	g.m_nTimeStop = ticks
end

local PROBE_STEPS = {
	{ 40, function(p, c)
		local g = game()
		out(string.format("probe: m_nTimeStop %s, m_nTimeStopCaster %s, companion %s", tostring(g.m_nTimeStop),
			tostring(g.m_nTimeStopCaster), c and B24.Name(c) or "none"))
		timeStop(p, 15 * 60)
		B24T.probe = { pFrom = { pos(p) }, cFrom = c and { pos(c) }, clock = Infinity_GetClockTicks(), tick = B24.GameTick() }
		walk(p, 150)
		if c then walk(c, -150) end
	end },
	{ 120, function(p, c)
		local g, pr = game(), B24T.probe
		out(string.format("probe: after 80 ticks m_nTimeStop %s, game ticks %d", tostring(g.m_nTimeStop), B24.GameTick() - pr.tick))
		conditionCheck("time stop: caster moves", { casterMoved = moved(p, pr.pFrom) })
		if c then conditionCheck("time stop: the others stay frozen", { companionStill = not moved(c, pr.cFrom) }) end
		out("SHOT 70-timestop-protagonist")
		-- Without a companion: on to the missile probe.
		if c == nil then timeStop(nil, 0) return end
		timeStop(c, 15 * 60)
		pr.pFrom, pr.cFrom = { pos(p) }, { pos(c) }
		walk(c, -150)
		walk(p, -150)
	end },
	{ 200, function(p, c)
		local pr = B24T.probe
		if c == nil then return end
		conditionCheck("time stop handed over: new caster moves", { companionMoved = moved(c, pr.cFrom) })
		conditionCheck("time stop handed over: old caster frozen", { protagonistStill = not moved(p, pr.pFrom) })
		out("SHOT 71-timestop-companion")
		timeStop(nil, 0)
		pr.pFrom = { pos(p) }
		walk(p, 150)
	end },
	{ 260, function(p, c)
		if c then conditionCheck("time stop off: everyone moves again", { protagonistMoved = moved(p, B24T.probe.pFrom) }) end
		queue(p, 'CreateCreatureObjectOffset("B24BST03",Myself,[250.0])')
	end },
	-- Missiles under Time Stop (turn-based mode, B24TURN.lua): the caster's Magic Missile, with the
	-- caster as the Time Stop caster (does it fly?), then with the missile itself as the Time Stop
	-- caster, then without Time Stop. Logs the missiles, where they are, and the wolf's hit points.
	{ 280, function(p, c)
		local pr = B24T.probe
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" then pr.wolf = s.m_id break end
		end
		local w = pr.wolf and B24.GetSprite(pr.wolf)
		if w == nil then error("no wolf created") end
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ChangeEnemyAlly(Myself,ENEMY)", w)
		timeStop(p, 15 * 60)
		pr.wolfHP, pr.stage, pr.since = w.m_baseStats.m_hitPoints, "caster", B24.GameTick()
		queue(p, 'ForceSpellRES("SPWI112",NearestEnemyOf(Myself))')
	end },
	{ 281, function(p, c)
		local pr, g = B24T.probe, game()
		local w = B24.GetSprite(pr.wolf)
		local missiles = {}
		local area = p.m_pArea
		for _, list in ipairs({ area.m_lVertSortFlight, area.m_lVertSortFlightAdd, area.m_lVertSort, area.m_lVertSortAdd }) do
			EEex_Utility_IterateCPtrList(list, function(id)
				local object = EEex_GameObject_Get(id)
				local ok, source = pcall(function() return object.m_sourceId end)
				if ok and source == p.m_id and object.m_objectType ~= CGameObjectType.SPRITE then
					table.insert(missiles, { id = id, x = object.m_pos.x, y = object.m_pos.y, type = object.m_objectType })
				end
			end)
		end
		local parts = {}
		for _, m in ipairs(missiles) do table.insert(parts, string.format("%d type %d at %d,%d", m.id, m.type, m.x, m.y)) end
		local text = string.format("%s: %d missiles [%s], wolf %d hit points (was %d), time stop caster %d, action %d", pr.stage,
			#missiles, table.concat(parts, "; "), w and w.m_baseStats.m_hitPoints or -1, pr.wolfHP, g.m_nTimeStopCaster,
			p.m_curAction.m_actionID)
		if text ~= pr.lastText then
			pr.lastText = text
			out(string.format("missile probe %d: %s", B24.GameTick() - pr.since, text))
		end
		local elapsed = B24.GameTick() - pr.since
		if pr.stage == "caster" and (elapsed > 120 or (#missiles > 0 and elapsed > 60)) then
			-- The missile as the Time Stop caster (the first one found; the caster stays frozen).
			pr.stage, pr.since = "missile", B24.GameTick()
			if missiles[1] then g.m_nTimeStopCaster = missiles[1].id end
		elseif pr.stage == "missile" and elapsed > 75 then
			pr.stage, pr.since = "no time stop", B24.GameTick()
			timeStop(nil, 0)
		elseif pr.stage == "no time stop" and elapsed > 45 then
			-- Friendly again, so it doesn't kill the protagonist before the test ends.
			if w then EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ChangeEnemyAlly(Myself,NEUTRAL) ClearActions(Myself)", w) end
			conditionCheck("missile probe: the wolf took the damage at some point", { damaged = w ~= nil and w.m_baseStats.m_hitPoints < pr.wolfHP })
			return true
		end
		B24T.probeStep = B24T.probeStep - 1
	end },
}

function B24T.ProbeTick(sprite, now)
	local t = now - B24T.worldStart
	B24T.probeStep = B24T.probeStep or 1
	local step = PROBE_STEPS[B24T.probeStep]
	if step == nil or t <= step[1] then return end
	B24T.probeStep = B24T.probeStep + 1
	local ok, result = pcall(step[2], sprite, EEex_Sprite_GetInPortrait(1))
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL probe step " .. (B24T.probeStep - 1) .. ": " .. tostring(result))
	end
	if result == true or not ok or PROBE_STEPS[B24T.probeStep] == nil then
		pcall(timeStop, nil, 0)
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Turncombat mode (feasibility, part 2): a hostile wolf, turns handed over through Time Stop. The
-- protagonist attacks for one round (AttackOneRound), then the wolf's own AI gets its turn.
-- Logs the swing fields to find a reliable "turn done" signal.
local function swingState(s)
	return string.format("action %d swing %s just %s frame %s", s.m_curAction.m_actionID, tostring(s.m_startedSwing),
		tostring(s.m_bJustAttacked), tostring(s.m_attackFrame))
end

local function watch(label, s)
	local now, text = B24.GameTick(), swingState(s)
	B24T.watchLast = B24T.watchLast or {}
	if B24T.watchLast[label] ~= text then
		B24T.watchLast[label] = text
		out(string.format("  %d %s: %s, hp %d", now - B24T.worldStart, label, text, s.m_baseStats.m_hitPoints))
	end
end

local function wolf() return B24T.wolfID and B24.GetSprite(B24T.wolfID) end

local COMBAT_STEPS = {
	{ 40, function(p) queue(p, 'CreateCreatureObjectOffset("B24BST03",Myself,[60.0])') end },
	{ 55, function(p)
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" then B24T.wolfID = s.m_id break end
		end
		local w = wolf()
		if w == nil then error("no wolf created") end
		queue(w, 'ChangeEnemyAlly(Myself,ENEMY)')
	end },
	{ 60, function(p)
		local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
		g.m_nTimeStopCaster, g.m_nTimeStop = p.m_id, 15 * 120
		B24T.wolfHP, B24T.pHP = wolf().m_baseStats.m_hitPoints, p.m_baseStats.m_hitPoints
		out("turn: protagonist, AttackOneRound")
		queue(p, 'AttackOneRound(NearestEnemyOf(Myself))')
		B24T.watching = true
	end },
	{ 180, function(p)
		local w = wolf()
		conditionCheck("protagonist's turn ends by itself", { idle = p.m_curAction.m_actionID == 0 })
		conditionCheck("wolf frozen during the protagonist's turn", { wolfDidNotAct = p.m_baseStats.m_hitPoints == B24T.pHP })
		local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
		g.m_nTimeStopCaster, g.m_nTimeStop = w.m_id, 15 * 120
		out("turn: wolf (own AI)")
		B24T.pFrom = { p.m_pos.x, p.m_pos.y }
		B24T.pHP = p.m_baseStats.m_hitPoints
	end },
	{ 300, function(p)
		local w = wolf()
		conditionCheck("wolf acts on its turn", { wolfActing = w.m_curAction.m_actionID ~= 0 or p.m_baseStats.m_hitPoints < B24T.pHP })
		local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
		g.m_nTimeStopCaster, g.m_nTimeStop = -1, 0
		B24T.watching = false
		out("SHOT 72-turncombat")
		return true
	end },
}

function B24T.CombatTick(sprite, now)
	if not B24T.logMirrored then
		B24T.MirrorLog()
		-- This mode is about turns, not dying: the wolf, which now takes its whole turn, killed the
		-- level 1 protagonist (8 hit points) in one run. 200 more hit points (not a minimum: the
		-- dying rules' own one wins over it, see the Turns mode).
		B24.ApplyEffect(sprite, { ["effectID"] = 18, ["effectAmount"] = 200, ["dwFlags"] = 0, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		B24.ApplyEffect(sprite, { ["effectID"] = 17, ["effectAmount"] = 200, ["dwFlags"] = 0, ["durationType"] = 1, ["m_sourceRes"] = "B24TEST" })
	end
	if B24T.watching then
		watch("protagonist", sprite)
		if wolf() then watch("wolf", wolf()) end
	end
	local t = now - B24T.worldStart
	B24T.combatStep = B24T.combatStep or 1
	local step = COMBAT_STEPS[B24T.combatStep]
	if step == nil or t <= step[1] then return end
	B24T.combatStep = B24T.combatStep + 1
	local ok, result = pcall(step[2], sprite)
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL combat step " .. (B24T.combatStep - 1) .. ": " .. tostring(result))
	end
	if result == true or not ok or COMBAT_STEPS[B24T.combatStep] == nil then
		pcall(function()
			local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
			g.m_nTimeStopCaster, g.m_nTimeStop = -1, 0
		end)
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Turns mode: turn-based combat (B24TURN.lua) against a spawned wolf. Switches it on, checks
-- initiative, alternating turns with the other side frozen, End Turn, the end of combat, and
-- switching it off.
local function turnWolf() return B24T.wolfID and B24.GetSprite(B24T.wolfID) end

-- Every tick: notes each new turn and whether the waiting creature stayed frozen.
local function watchTurns(p)
	-- The 6-second marker (step 90): the round in which it ran out.
	if B24T.durRound and not B24T.durGoneRound and not B24.HasEffectSource(p, 0, "B24TDUR") then
		B24T.durGoneRound, B24T.durGoneTicks = B24TB.round, B24.GameTick() - B24T.durTick
	end
	-- Diagnostics: how the engine keeps the marker (timing 4096 = absolute end in game ticks).
	if B24T.durRound and not B24T.durTiming then
		EEex_Utility_IterateCPtrList(p.m_timedEffectList, function(effect)
			if effect.m_sourceRes:get():upper() == "B24TDUR" then
				B24T.durTiming = string.format("timing %d, end %d at tick %d", effect.m_durationType, effect.m_duration, B24.GameTick())
				return true
			end
		end)
	end
	local turn = B24TB.turn
	if not B24TB.active or turn == nil then return end
	local w = turnWolf()
	if w == nil then return end
	-- A party member's turn waits for orders (no time limit, no order carried over): the
	-- protagonist attacks the wolf once per turn, as a player would order it.
	if turn.id == p.m_id and B24T.orderedTurn ~= turn and p.m_curAction.m_actionID == 0 then
		B24T.orderedTurn = turn
		queue(p, 'Attack(NearestEnemyOf(Myself))')
	end
	local log = B24T.turns
	local last = log[#log]
	if last == nil or last.id ~= turn.id or last.start ~= turn.start then
		local other = turn.id == p.m_id and w or p
		table.insert(log, { id = turn.id, start = turn.start, other = other, frame = other.m_attackFrame,
			x = other.m_pos.x, y = other.m_pos.y, frozen = true, round = B24TB.round })
		out(string.format("turn %d: round %d, %s", #log, B24TB.round, turn.id == p.m_id and "protagonist" or "wolf"))
		if turn.id == p.m_id and #log <= 2 then queue(p, 'Attack(NearestEnemyOf(Myself))') end
	else
		local o = last.other
		-- While the action plays out unfrozen (B24TB.resolving) the waiting creature is held: it may
		-- animate but not move; otherwise it is frozen.
		-- Pushed aside without an action of its own (the engine parting overlapping creatures, a
		-- hit's push) while the action plays out: not acting out of turn (a just-spawned wolf moved
		-- 32 px with no action in turn 1 of one run).
		-- Held (B24TURN.lua holdOthers) means its actions are cleared every frame: between two
		-- clears an attack can still take one step (8 px in one run). Up to 16 px (half a creature's
		-- circle) is a step, not acting out of turn.
		local dx, dy = o.m_pos.x - last.x, o.m_pos.y - last.y
		local moved = (dx ~= 0 or dy ~= 0) and (not B24TB.resolving
			or (o.m_curAction.m_actionID ~= 0 and dx * dx + dy * dy > 16 * 16))
		local animated = not B24TB.resolving and o.m_attackFrame ~= last.frame
		if (moved or animated) and last.frozen then
			out(string.format("turn %d: the waiting creature %s (resolving %s, action %d, frame %d to %d, position %d,%d to %d,%d)", #log,
				moved and "moved" or "animated", tostring(B24TB.resolving), o.m_curAction.m_actionID, last.frame, o.m_attackFrame,
				last.x, last.y, o.m_pos.x, o.m_pos.y))
			last.frozen = false
		end
		last.frame = o.m_attackFrame
	end
end

local TURN_STEPS = {
	{ 30, function(p)
		EEex_GameState_SetGlobalInt("B24_TURNS", 1)
		-- The protagonist must not go down: this test is about turns, not dying. 200 more hit
		-- points, not a minimum (op208): the dying rules' own minimum of 1 hit point (B24DYING.lua)
		-- won over the test's 8, the protagonist dropped, lost its turn and was "healed" again.
		B24.ApplyEffect(p, { ["effectID"] = 18, ["effectAmount"] = 200, ["dwFlags"] = 0, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		B24.ApplyEffect(p, { ["effectID"] = 17, ["effectAmount"] = 200, ["dwFlags"] = 0, ["durationType"] = 1, ["m_sourceRes"] = "B24TEST" })
		B24T.turns = {}
	end },
	{ 50, function(p)
		conditionCheck("no switch innate (the switch is the button on the game screen)", { gone = not knowsInnate(p, "B24TURNS") })
		queue(p, 'CreateCreatureObjectOffset("B24BST03",Myself,[150.0])')
	end },
	{ 60, function(p)
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" then B24T.wolfID = s.m_id break end
		end
		if turnWolf() == nil then error("no wolf created") end
		B24.ApplyEffect(turnWolf(), { ["effectID"] = 208, ["effectAmount"] = 5, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		queue(turnWolf(), 'ChangeEnemyAlly(Myself,ENEMY)')
	end },
	{ 90, function(p)
		conditionCheck("combat starts in turns", { active = B24TB.active, two = B24TB.order and #B24TB.order == 2,
			noEndTurnInnate = not knowsInnate(p, "B24TEND"), endTurnButton = (B24TB.turn and B24TB.turn.id ~= p.m_id) or B24TB.EndTurnShown() })
		-- Durations in rounds: a 6-second effect lasts one round of turns, however long they take.
		B24.ApplyEffect(p, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 6,
			["m_sourceRes"] = "B24TDUR" })
		B24T.durRound, B24T.durTick = B24TB.round, B24.GameTick()
		B24T.watchingTurns = true
	end },
	{ 1200, function(p)
		B24T.watchingTurns = false
		local log, alternate, frozen = B24T.turns, true, true
		for i = 2, #log do
			if log[i].id == log[i - 1].id then alternate = false end
		end
		for i = 1, #log - 1 do
			if not log[i].frozen then frozen = false end
		end
		out(string.format("turns: %d in %d rounds", #log, B24TB.round or 0))
		conditionCheck("turns alternate over several rounds", { atLeastFour = #log >= 4, alternate = alternate })
		conditionCheck("the waiting creature stays frozen (held while an action plays out)", { frozen = frozen })
		out(string.format("6-second effect from round %s: gone in round %s after %s game ticks (%s)",
			tostring(B24T.durRound), tostring(B24T.durGoneRound), tostring(B24T.durGoneTicks), tostring(B24T.durTiming)))
		conditionCheck("a 6-second effect lasts a round of turns", { gone = B24T.durGoneRound ~= nil,
			nextRound = B24T.durGoneRound ~= nil and B24T.durGoneRound >= B24T.durRound + 1 and B24T.durGoneRound <= B24T.durRound + 2 })
		out("SHOT 80-turns")
		-- End Turn on the protagonist's turn, or wait for it.
		B24T.endTurnAt = nil
	end },
	-- The record opens and closes on a party member's turn (the game crashed when it opened during a
	-- turn-based fight): opened as the sidebar button does, closed with its Done after two seconds
	-- (by the clock: the game's own ticks may stand still while the record is up).
	{ 1205, function(p)
		local turn = B24TB.turn
		if not (turn and turn.id == p.m_id) then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		local frame = B24TB.Frame
		B24T.recordOpenAt, B24T.recordClosed, B24T.recordUnselected = Infinity_GetClockTicks(), nil, nil
		B24T.recordTurn = turn
		function B24TB.Frame(...)
			if B24T.recordOpenAt and not B24T.recordClosed and e:GetActiveEngine() == characterScreen then
				-- The selection no longer the acting member's (the record's own selection; in the game
				-- that hung it, the turn's selection was redone every frame on the record screen).
				if not B24T.recordUnselected then
					B24T.recordUnselected, B24T.recordTick = true, B24.GameTick()
					EngineGlobals.g_pBaldurChitin.m_pObjectGame:UnselectAll()
					out("record screen up, selection cleared")
				elseif Infinity_GetClockTicks() - B24T.recordOpenAt > 2000 then
					B24T.recordClosed, B24T.recordTicks = true, B24.GameTick() - B24T.recordTick
					-- The turn as the record closes (after it the protagonist's queued attack may end it).
					B24T.recordTurnAtClose = B24TB.turn
					out(string.format("record screen up for two seconds (%d game ticks passed): back to the game screen", B24T.recordTicks))
					e:SelectEngine(worldScreen)
				end
			end
			return frame(...)
		end
		worldScreen:OnLeftPanelButtonClick(4)
	end },
	{ 1207, function(p)
		if not B24T.recordClosed or e:GetActiveEngine() ~= worldScreen then
			if Infinity_GetClockTicks() - B24T.recordOpenAt < 15000 then
				B24T.turnStep = B24T.turnStep - 1
				return
			end
		end
		conditionCheck("the record opens and closes on a party member's turn", { closed = B24T.recordClosed == true,
			back = e:GetActiveEngine() == worldScreen })
		-- The fight stood still while the record was up (B24TURN.lua pauses it off the game screen).
		conditionCheck("a turn-based fight waits while another screen is up", { paused = (B24T.recordTicks or 99) <= 2,
			stillMyTurn = B24T.recordTurnAtClose == B24T.recordTurn })
		-- The protagonist selected again for the steps after this one.
		EEex_Utility_TryIgnore(function()
			local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
			g:SelectCharacter(p.m_id, false)
			g:SelectToolbar()
		end)
	end },
	{ 1210, function(p)
		local turn = B24TB.turn
		if turn and turn.id == p.m_id then
			B24TEND(nil, p)
			B24T.endTurnAt = B24.GameTick()
		else
			B24T.turnStep = B24T.turnStep - 1
		end
	end },
	{ 1220, function(p)
		conditionCheck("End Turn passes the turn", { wolfsTurn = B24TB.turn ~= nil and B24TB.turn.id == B24T.wolfID })
	end },
	-- A bonus action (Second Wind) on the protagonist's next turn keeps the turn; the attack after it
	-- ends it.
	{ 1222, function(p)
		-- Still the wolf's turn: the protagonist's attack from the earlier turns stops, so its next turn
		-- starts with no action (orders given while it waits are dropped when its turn begins).
		B24LV.Grant(p, "B24SWIND", true)
		p:setLocalInt("B24SWUSE", 0)
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", p)
	end },
	{ 1225, function(p)
		local turn = B24TB.turn
		if not (turn and turn.id == p.m_id) then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		-- The protagonist's turn: Second Wind first, as a player would order it.
		queue(p, 'ForceSpellRES("B24SWIND",Myself)')
		B24T.bonusTurn = turn
		B24T.bonusAt = B24.GameTick()
	end },
	{ 1260, function(p)
		if B24.GameTick() - B24T.bonusAt < 45 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		local turn = B24TB.turn
		local action = p.m_curAction
		out(string.format("bonus action turn: started %s, current %s, last action %s, bonus used %s; action now %d (%s), Second Wind uses %d",
			tostring(turn and turn.started), tostring(turn and turn.current), tostring(turn and turn.lastAction),
			tostring(turn and turn.bonusUsed), action.m_actionID, tostring(B24.ActionSpellRes(action)), p:getLocalInt("B24SWUSE")))
		conditionCheck("a bonus action keeps the turn", { sameTurn = turn == B24T.bonusTurn, bonusUsed = turn ~= nil and turn.bonusUsed == true })
		queue(p, 'Attack(NearestEnemyOf(Myself))')
	end },
	{ 1300, function(p)
		local turn = B24TB.turn
		-- The attack may first walk to the wolf: up to 200 ticks for the turn to pass.
		B24T.attackAt = B24T.attackAt or B24.GameTick()
		if turn == B24T.bonusTurn and B24.GameTick() - B24T.attackAt < 200 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		conditionCheck("the action after the bonus action ends the turn", { passed = turn ~= B24T.bonusTurn })
	end },
	-- Opportunity Attacks: the protagonist runs from the wolf on its turn (the wolf reacts at once),
	-- then the wolf runs from the protagonist (the protagonist is asked; the test answers Yes).
	{ 1301, function(p)
		-- The wolf's turn: the protagonist's attack stops, so its turn starts idle.
		local turn = B24TB.turn
		if not (turn and turn.id == B24T.wolfID) then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", p)
	end },
	{ 1302, function(p)
		local turn = B24TB.turn
		if not (turn and turn.id == p.m_id) then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		B24TB.reacted = {}
		out(string.format("before running: %d apart, wolf's reach %s", math.floor(math.sqrt((p.m_pos.x - turnWolf().m_pos.x) ^ 2
			+ (p.m_pos.y - turnWolf().m_pos.y) ^ 2)), tostring(B24TB.ReachOf(turnWolf()))))
		queue(p, 'RunAwayFrom(NearestEnemyOf(Myself),60)')
		B24T.oaAt = B24.GameTick()
	end },
	{ 1304, function(p)
		local w = turnWolf()
		if B24TB.reacted[w.m_id] == nil and B24.GameTick() - B24T.oaAt < 150 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		conditionCheck("an enemy takes an Opportunity Attack when the protagonist leaves its reach", { reacted = B24TB.reacted[w.m_id] ~= nil })
	end },
	-- A party member's reaction is asked first (the step above tested the detection with real
	-- movement; the wolf's AI can't be made to walk off on cue): the Yes/No prompt of an
	-- Opportunity Attack, then the three-button prompt of a hit (Shield / Uncanny Dodge / No).
	{ 1306, function(p)
		B24T.promptsBefore = B24T.prompts or 0
		B24T.reactionAnswer, B24T.reactedWith = nil, nil
		B24TB.React(p, string.format("%s: Opportunity Attack on %s?", B24.Name(p), B24.Name(turnWolf())), function()
			B24T.reactedWith = "yes"
		end)
		B24T.oaAt = B24.GameTick()
		B24T.askedAt = Infinity_GetClockTicks()
	end },
	{ 1307, function(p)
		if B24T.reactedWith == nil and Infinity_GetClockTicks() - B24T.askedAt < 8000 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
		conditionCheck("a party member's reaction is asked, Yes takes it", { asked = (B24T.prompts or 0) > B24T.promptsBefore,
			taken = B24T.reactedWith == "yes", resumed = not (ok and (paused == true or paused == 1)) })
		B24T.reactionAnswer, B24T.reactedWith = 2, nil
		B24TB.ReactChoice(p, string.format("%s is hit by %s for 5 damage. Reaction?", B24.Name(p), B24.Name(turnWolf())), {
			{ label = "Shield", fn = function() B24T.reactedWith = "Shield" end },
			{ label = "Uncanny Dodge", fn = function() B24T.reactedWith = "Uncanny Dodge" end },
		})
		B24T.askedAt = Infinity_GetClockTicks()
	end },
	{ 1308, function(p)
		if B24T.reactedWith == nil and Infinity_GetClockTicks() - B24T.askedAt < 8000 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		conditionCheck("a reaction with two choices takes the one chosen", { second = B24T.reactedWith == "Uncanny Dodge" })
		B24T.reactionAnswer = nil
		B24.RemoveEffectsBySource(turnWolf(), "B24TEST")
	end },
	-- A spell's missile lands before the turn passes (the next creature's Time Stop would freeze it
	-- in the air, its damage coming rounds later): the wolf casts Magic Missile on its turn, and the
	-- protagonist has the damage when the wolf's turn ends.
	{ 1308.5, function(p)
		-- The wolf's next turn starts with the spell: queued by a turn-start listener (it runs as the
		-- turn begins, before the wolf's AI acts; the test steps run on AI updates and could miss the
		-- first frames of the turn).
		if not B24T.mmArmed then
			B24T.mmArmed = true
			local w = turnWolf()
			-- Without its scripts from now on: removed at its turn's start, they still had it swing once
			-- (its AttackReevaluate came first; a swing is the turn's action, the spell never came).
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly('ChangeAIScript("",OVERRIDE) ChangeAIScript("",CLASS) '
				.. 'ChangeAIScript("",RACE) ChangeAIScript("",GENERAL) ChangeAIScript("",DEFAULT)', w)
			table.insert(B24TB.TurnStartListeners, function(sprite)
				if B24T.mmArmed ~= true or sprite.m_id ~= B24T.wolfID then return end
				B24T.mmArmed = "queued"
				B24.ApplyEffect(sprite, { ["effectID"] = 208, ["effectAmount"] = 5, ["durationType"] = 9, ["m_sourceRes"] = "B24TMM" })
				-- Full hit points (200 extra, step 30): the damage shows as fewer.
				p.m_baseStats.m_hitPoints = p:getStat(B24.Stat.MAXHP)
				B24T.mmHP, B24T.mmAt, B24T.mmActions = p.m_baseStats.m_hitPoints, B24.GameTick(), {}
				EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", sprite)
				queue(sprite, 'ForceSpellRES("SPWI112",Player1)')
				B24T.mmSpellStarted = nil
				-- Every frame of the wolf's turn and a second after: its action, the freeze, its
				-- missiles, the protagonist's hit points (on change).
				local frame = B24TB.Frame
				local untilTick = B24.GameTick() + 150
				function B24TB.Frame(...)
					-- The attack the wolf had going when its turn began (ClearActions doesn't stop the
					-- current action at once): its swing would count as the turn's action and end the
					-- turn, and the ending turn clears the queued spell (B24TURN.lua turnDone). Until
					-- the spell starts, the attack isn't the turn's action.
					local wturn, wolf = B24TB.turn, turnWolf()
					if not B24T.mmSpellStarted and wturn and wolf and wturn.id == wolf.m_id then
						local action = wolf.m_curAction.m_actionID
						if B24TB.ATTACK_ACTIONS[action] or action == 0 then
							if B24TB.ATTACK_ACTIONS[action] then
								wturn.swings, wturn.started, wturn.lastAction, wturn.actionStart = 0, false, nil, nil
							end
							wturn.lastSwing, wturn.lastFrame = wolf.m_startedSwing, wolf.m_attackFrame
						else
							B24T.mmSpellStarted = true
							out(string.format("  mm %d: the wolf's spell action %d starts", B24.GameTick() - B24T.mmAt, action))
						end
					end
					local result = frame(...)
					if B24.GameTick() <= untilTick then
						local wolf, g = turnWolf(), EngineGlobals.g_pBaldurChitin.m_pObjectGame
						local missiles = 0
						local area = wolf and wolf.m_pArea
						if area then
							for _, list in ipairs({ area.m_lVertSortFlight, area.m_lVertSortFlightAdd, area.m_lVertSort, area.m_lVertSortAdd }) do
								EEex_Utility_IterateCPtrList(list, function(id)
									local object = EEex_GameObject_Get(id)
									local ok, source = pcall(function() return object.m_sourceId end)
									if ok and source == wolf.m_id and object.m_objectType ~= CGameObjectType.SPRITE then missiles = missiles + 1 end
								end)
							end
						end
						local turn = B24TB.turn
						-- Printed on a change (the Time Stop counter changes every frame: not compared).
						local text = string.format("turn %s, wolf action %d, swings %s, last action %s, spell %s, over: %s, resolving %s, ending %s, time stop by %s, missiles %d, protagonist %d hit points",
							turn and (turn.id == B24T.wolfID and "wolf" or "other") or "none", wolf and wolf.m_curAction.m_actionID or -1,
							tostring(turn and turn.swings), tostring(turn and turn.lastAction), tostring(turn and turn.spellCast),
							tostring(turn and turn.overWhy),
							tostring(B24TB.resolving), tostring(turn and turn.ending),
							g.m_nTimeStop > 0 and (g.m_nTimeStopCaster == B24T.wolfID and "wolf" or tostring(g.m_nTimeStopCaster)) or "none",
							missiles, p.m_baseStats.m_hitPoints)
						if text ~= B24T.mmTrace then
							B24T.mmTrace = text
							out(string.format("  mm %d: %s", B24.GameTick() - B24T.mmAt, text))
						end
					end
					return result
				end
			end)
		end
		local turn = B24TB.turn
		if not (B24T.mmArmed == "queued" and turn and turn.id == B24T.wolfID) then
			-- The protagonist's turn passes (no order waits for it any more).
			if turn and turn.id == p.m_id then B24TEND(nil, p) end
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		B24T.mmTurn = turn
	end },	{ 1309, function(p)
		local w = turnWolf()
		local action = w and w.m_curAction.m_actionID or -1
		if action ~= 0 and B24T.mmActions[#B24T.mmActions] ~= action then table.insert(B24T.mmActions, action) end
		if B24TB.turn == B24T.mmTurn and B24.GameTick() - B24T.mmAt < 400 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		local hp = p.m_baseStats.m_hitPoints
		B24T.mmEndHP, B24T.mmEndAt = hp, B24.GameTick()
		out(string.format("Magic Missile from the wolf: hit points %d before, %d when its turn ended after %d ticks (wolf actions %s)",
			B24T.mmHP, hp, B24.GameTick() - B24T.mmAt, table.concat(B24T.mmActions, ",")))
		conditionCheck("an enemy's spell lands before its turn passes", { passed = B24TB.turn ~= B24T.mmTurn, damaged = hp < B24T.mmHP })
	end },
	{ 1309.5, function(p)
		if B24.GameTick() - B24T.mmEndAt < 75 then
			B24T.turnStep = B24T.turnStep - 1
			return
		end
		out(string.format("Magic Missile from the wolf: hit points %d five seconds after its turn", p.m_baseStats.m_hitPoints))
		B24.RemoveEffectsBySource(turnWolf(), "B24TMM")
		p.m_baseStats.m_hitPoints = p:getStat(B24.Stat.MAXHP)
	end },
	{ 1310, function(p)
		B24.ApplyEffect(turnWolf(), { ["effectID"] = 12, ["effectAmount"] = 500, ["dwFlags"] = 0, ["durationType"] = 1 })
	end },
	{ 1340, function(p)
		local g = EngineGlobals.g_pBaldurChitin.m_pObjectGame
		conditionCheck("combat ends with the last enemy", { inactive = not B24TB.active, unfrozen = g.m_nTimeStop == 0 })
		B24TURNS(nil, p)
	end },
	{ 1360, function(p)
		conditionCheck("switched off", { off = EEex_GameState_GetGlobalInt("B24_TURNS") == 0 })
		return true
	end },
}

function B24T.TurnsTick(sprite, now)
	-- The mod's messages in the log file too (whose turn starts, why one ends).
	if not B24T.logMirrored then B24T.MirrorLog() end
	if B24T.watchingTurns then pcall(watchTurns, sprite) end
	local t = now - B24T.worldStart
	B24T.turnStep = B24T.turnStep or 1
	local step = TURN_STEPS[B24T.turnStep]
	if step == nil or t <= step[1] then return end
	B24T.turnStep = B24T.turnStep + 1
	local ok, result = pcall(step[2], sprite)
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL turns step " .. (B24T.turnStep - 1) .. ": " .. tostring(result))
	end
	if result == true or not ok or TURN_STEPS[B24T.turnStep] == nil then
		pcall(EEex_GameState_SetGlobalInt, "B24_TURNS", 0)
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Downhits mode: a hostile wolf attacks the protagonist, who is down; its weapon hits must count
-- as failed death saves (B24DYING.lua).
local DOWN_STEPS = {
	{ 40, function(p)
		queue(p, 'CreateCreatureObjectOffset("B24BST03",Myself,[60.0])')
	end },
	{ 55, function(p)
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" then B24T.wolfID = s.m_id break end
		end
		local w = B24T.wolfID and B24.GetSprite(B24T.wolfID)
		if w == nil then error("no wolf created") end
		p.m_baseStats.m_hitPoints = 3
		B24.ApplyEffect(p, { ["effectID"] = 12, ["effectAmount"] = 10, ["dwFlags"] = 0, ["durationType"] = 1 })
		-- No death saves of its own during the test: only the wolf's hits count.
		p:setLocalInt("B24DYAT", B24.GameTick() + 100000)
		queue(w, 'ChangeEnemyAlly(Myself,ENEMY)')
	end },
	{ 75, function(p)
		conditionCheck("protagonist down", { down = p:getLocalInt("B24DYDN") == 1 })
		p:setLocalInt("B24DYAT", B24.GameTick() + 100000)
		-- Three failed saves from the wolf, then its next hit kills: the game ends (B24T.GameOverCheck).
		B24T.expectGameOver = true
		B24T.gameOverLabel = "weapon hits while down are failed saves, and a hit in the last minute kills"
	end },
	{ 1500, function(p)
		out(string.format("after the wolf's attacks: %d failures, state %d", p:getLocalInt("B24DYFAI"), p:getLocalInt("B24DYDN")))
		conditionCheck("the wolf's hits kill the downed protagonist", { dead = false })
		return true
	end },
}

function B24T.DownHitsTick(sprite, now)
	local t = now - B24T.worldStart
	B24T.downStep = B24T.downStep or 1
	local step = DOWN_STEPS[B24T.downStep]
	if step == nil or t <= step[1] then return end
	B24T.downStep = B24T.downStep + 1
	local ok, result = pcall(step[2], sprite)
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL downhits step " .. (B24T.downStep - 1) .. ": " .. tostring(result))
	end
	if result == true or not ok or DOWN_STEPS[B24T.downStep] == nil then
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Multiclass mode: the 2024 multiclass rules (proficiency from total level, hit points per class
-- level, XP held back to the single-class level, dual-classing).
local function describe(s)
	local b = s.m_baseStats
	return string.format("%s: class %d, levels %d/%d/%d, kit %d, xp %d, hp %d/%d (base max %d), con %d, prof %d, thac0 %d, dual flags %x",
		B24.Name(s), B24.ClassID(s), s:getStat(B24.Stat.LEVEL), s:getStat(B24.Stat.LEVEL2), s:getStat(B24.Stat.LEVEL3),
		s:getStat(B24.Stat.KIT), b.m_xp, b.m_hitPoints, s:getActiveStats().m_nMaxHitPoints, b.m_maxHitPointsBase, s:getStat(B24.Stat.CON),
		B24.ProfOf(s), s:getActiveStats().m_nTHAC0, b.m_flags)
end

local function companion1() return EEex_Sprite_GetInPortrait(1) end
local function classLevels(s) return { s:getStat(B24.Stat.LEVEL), s:getStat(B24.Stat.LEVEL2), s:getStat(B24.Stat.LEVEL3) } end
local function setXP(s, xp) s.m_baseStats.m_xp, s.m_derivedStats.m_nXP, s.m_tempStats.m_nXP = xp, xp, xp end

-- Base slot counts of the engine's memorization info (see B24MC.UpdateSlots).
local function baseSlots(info, count)
	local list = {}
	for l = 1, count do
		local entry = EEex_ReadPtr(EEex_UDToPtr(info) + (l - 1) * 8)
		list[l] = EEex_ReadU16(entry + 2)
	end
	return list
end

local function wizardRow(level)
	local row = B24.LoadTable("MXSPLWIZ")[tostring(level)]
	local list = {}
	for l = 1, 9 do list[l] = tonumber(row[tostring(l)]) or 0 end
	return list
end

local MC_STEPS = {
	{ 40, function(p)
		for _, s in ipairs(B24.Party()) do out("state " .. describe(s)) end
		conditionCheck("single class untouched", { notMulti = not B24MC.IsMulti(p), level = B24.Level(p) == p:getStat(B24.Stat.LEVEL) })
		local c = companion1()
		if c == nil or not B24MC.IsMulti(c) then
			out("no multiclass companion in this save")
			B24T.mcStep = 5
			return
		end
		-- BG2: Imoen joins as a dual-classed Thief 7 / Mage 8 (single-class Thief with her XP: level 10).
		local lv = classLevels(c)
		-- The levels fit the XP she joined with; XP the game gives her afterwards is a normal level-up.
		local fitXP = c:getLocalInt("B24MCFXP")
		local grown = B24MC.AllowedLevel(c) > B24MC.AllowedLevel(c, fitXP)
		out(string.format("joining XP %d, now %d: level %d, allowed %d at joining, %d now", fitXP, c.m_baseStats.m_xp,
			B24.Level(c), B24MC.AllowedLevel(c, fitXP), B24MC.AllowedLevel(c)))
		conditionCheck("joining multiclass rebuilt to its XP", {
			dualFlagsCleared = EEex_BAnd(c.m_baseStats.m_flags, 0x1F8) == 0,
			totalFitsXP = B24.Level(c) == B24MC.AllowedLevel(c, fitXP),
			oldClassKept = lv[2] == 7,
			noLevelUp = grown or (not B24MC.CanLevelUp(c) and not Infinity_CanLevelUp(1)),
			noPlus = grown or c.m_bLevelUp == 0,
		})
		local want = 8 + 6 * 5 + lv[1] * 4 + B24.AbilityModOf(c, "CON") * B24.Level(c)
		out(string.format("companion: level %d (%d/%d), max hp %d (2024: %d), prof %d", B24.Level(c), lv[1], lv[2],
			c:getActiveStats().m_nMaxHitPoints, want, B24.ProfOf(c)))
		conditionCheck("2024 multiclass hit points and proficiency", { hp = c.m_baseStats.m_maxHitPointsBase == want,
			prof = B24.ProfOf(c) == B24.ProfBonus(B24.Level(c), false) })
		-- One casting class: the wizard table at the wizard level.
		local slots, row = baseSlots(c.m_memorizedSpellsLevelMage, 9), wizardRow(lv[1])
		out("companion wizard slots " .. table.concat(slots, ",") .. " (table " .. table.concat(row, ",") .. ")")
		conditionCheck("multiclass wizard slots follow the wizard level", { slots = table.concat(slots, ",") == table.concat(row, ",") })
		-- Two casting classes: Cleric 5 / Mage 5 casts as a level 10 full caster, split between the pools.
		local fake = { m_typeAI = { m_Class = 14 }, getStat = function(self, stat) return (stat == B24.Stat.LEVEL or stat == B24.Stat.LEVEL2) and 5 or 0 end }
		local wanted, full = B24MC.WantedSlots(fake), wizardRow(10)
		local sums = true
		for l = 1, 7 do
			local priest = wanted.priest[l]
			if l == 7 then priest = priest - (full[8] - wanted.mage[8]) - (full[9] - wanted.mage[9]) end
			if wanted.mage[l] + priest ~= full[l] then sums = false end
		end
		out("cleric 5 / mage 5: wizard " .. table.concat(wanted.mage, ",") .. ", priest " .. table.concat(wanted.priest, ",") .. " (level 10 " .. table.concat(full, ",") .. ")")
		conditionCheck("cleric/mage slots: the combined caster table, split", { sums = sums, splitLevel1 = wanted.mage[1] > 0 and wanted.priest[1] > 0,
			level5ToWizard = wanted.mage[5] == full[5] })
		-- Exactly the XP of the next single-class level: one level, in a class of her choice.
		out("SHOT 89-held-back")
		B24T.mcLevels = lv
		local thief = B24.LoadTable("XPLEVEL").THIEF
		setXP(c, tonumber(thief[tostring(B24.Level(c) + 1)]))
	end },
	{ 55, function(p)
		local c = companion1()
		local choices = B24MC.LevelUpChoices(c)
		conditionCheck("next XP threshold: one level-up, either class", { canLevel = B24MC.CanLevelUp(c) and Infinity_CanLevelUp(1),
			twoChoices = #choices == 2 })
		-- The class choice popup; the mage (row 1) gains the level.
		B24T.allowPopup = true
		-- Kept open (not closed as a stray popup) while the game runs on to the next step.
		B24T.popupShownAt = Infinity_GetClockTicks() + 60000
		B24LV.OpenClassChoice(c)
		EEex_GameState_TogglePause(false, false)
		out("SHOT 90-class-choice")
	end },
	{ 75, function(p)
		conditionCheck("class choice popup lists both classes", { rows = #B24LV.ROWS == 2, title = B24LV_Choice() == "Level Up" })
		B24LV_RowClick(1)
		B24LV_Done()
		B24T.popupShownAt = nil
	end },
	{ 100, function(p)
		local c = companion1()
		local lv = classLevels(c)
		out("after level-up: " .. describe(c))
		local want = 8 + 6 * 5 + lv[1] * 4 + B24.AbilityModOf(c, "CON") * B24.Level(c)
		conditionCheck("the chosen class gains the level, then no more", { mage = lv[1] == B24T.mcLevels[1] + 1,
			thief = lv[2] == B24T.mcLevels[2], heldBack = not B24MC.CanLevelUp(c), hp = c.m_baseStats.m_maxHitPointsBase == want,
			slots = table.concat(baseSlots(c.m_memorizedSpellsLevelMage, 9), ",") == table.concat(wizardRow(lv[1]), ",") })
	end },
	{ 105, function(p)
		-- The protagonist dual-classes (as the engine leaves it): Fighter -> Fighter/Mage with
		-- "original class: fighter" and mage level 1.
		-- The new class's first level is a character level: allowed only with the XP for it.
		if p:getStat(B24.Stat.LEVEL) < 2 then return true end
		local row = ({ [1] = "MAGE", [2] = "FIGHTER", [3] = "CLERIC", [4] = "THIEF", [11] = "DRUID", [12] = "RANGER" })[B24.ClassID(p)]
		local need = tonumber(B24.LoadTable("XPLEVEL")[row][tostring(p:getStat(B24.Stat.LEVEL) + 1)])
		local short = p.m_baseStats.m_xp < need
		local before = B24MC.CanDualClass(p)
		if short then setXP(p, need) end
		conditionCheck("dual-class allowed only with the XP for the next level", { notBefore = not (short and before),
			canDual = B24MC.CanDualClass(p) })
		B24T.pXP, B24T.pLevel = p.m_baseStats.m_xp, p:getStat(B24.Stat.LEVEL)
		queue(p, "ChangeClass(Myself,7)")
	end },
	{ 120, function(p)
		-- ChangeClass resets XP and levels; put back what a real dual-class leaves.
		local b = p.m_baseStats
		b.m_level1, b.m_level2 = B24T.pLevel, 1
		b.m_flags = EEex_BOr(b.m_flags, 0x8)
		setXP(p, B24T.pXP)
		B24.ApplyEffect(p, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60, ["m_sourceRes"] = "B24TREF" })
		B24.RemoveEffectsBySource(p, "B24TREF")
	end },
	{ 150, function(p)
		local lv = classLevels(p)
		out("after dual-class: " .. describe(p))
		conditionCheck("own dual-class becomes a multiclass with the level its XP gave", {
			multi = B24MC.IsMulti(p), flagsCleared = EEex_BAnd(p.m_baseStats.m_flags, 0x1F8) == 0,
			fighter = lv[1] == B24T.pLevel, mage = lv[2] == 1, total = B24.Level(p) == B24T.pLevel + 1,
			noLevelUp = not B24MC.CanLevelUp(p), xpKept = p.m_baseStats.m_xp >= B24T.pXP,
			mageSlots = table.concat(baseSlots(p.m_memorizedSpellsLevelMage, 9), ",") == table.concat(wizardRow(1), ",") })
		return true
	end },
}

function B24T.MulticlassTick(sprite, now)
	local t = now - B24T.worldStart
	B24T.mcStep = B24T.mcStep or 1
	local steps = MC_STEPS
	local step = steps[B24T.mcStep]
	if step == nil or t <= step[1] then return end
	B24T.mcStep = B24T.mcStep + 1
	local ok, result = pcall(step[2], sprite)
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL multiclass step " .. (B24T.mcStep - 1) .. ": " .. tostring(result))
	end
	if result == true or not ok or steps[B24T.mcStep] == nil then
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Features mode: class features of the second round (Metamagic, ...). The protagonist becomes a
-- class at a level (as in the rules steps), a spawned wolf serves as ally or enemy, and each
-- feature's hooks are called directly.
local function spawnWolf(p)
	queue(p, 'CreateCreatureObjectOffset("B24BST03",Myself,[80.0])')
end

local function findWolf(p)
	for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
		if s.m_resref:get():upper() == "B24BST03" then return s end
	end
end

local function fakeEffect(caster, res, dice, size)
	return { m_sourceId = caster.m_id, m_sourceRes = { get = function() return res end },
		m_numDice = dice or 0, m_diceSize = size or 6, m_effectAmount = 0, m_dWFlags = 0 }
end

-- Readies a Metamagic option and lets the protagonist "start casting" a spell.
local function metamagic(p, res, spell)
	_G[res](nil, p)
	for _, listener in ipairs(B24.SpellCastListeners) do pcall(listener, p, spell) end
end

local function pickIndex(list, key)
	for i, entry in ipairs(list) do
		if entry.key == key then return i end
	end
end

local FEATURE_STEPS = {
	{ 30, function(p)
		-- Features like Overchannel hurt the protagonist; this test is not about dying.
		B24.ApplyEffect(p, { ["effectID"] = 208, ["effectAmount"] = 10, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		spawnWolf(p)
		B24T.featureStep = { class = { id = 19, name = "Sorcerer", keys = { "SORCERER" } }, level = 20,
			subclass = pickIndex(B24LV.SUBCLASSES.SORCERER.list, "DRACONIC") }
		setUp(p, B24T.featureStep)
	end },
	{ 60, function(p)
		local w = findWolf(p)
		if w == nil then error("no wolf created") end
		B24T.wolfID = w.m_id
		conditionCheck("draconic sorcerer 20 set up", { ready = ready(p, B24T.featureStep) })
		-- Four options known: Careful, Empowered, Heightened, Seeking.
		for n, key in ipairs({ "CAREFUL", "EMPOWERED", "HEIGHTENED", "SEEKING" }) do
			p:setLocalInt("B24MM" .. n, pickIndex(B24SO.METAMAGIC, key))
		end
		p:setLocalInt("B24SPUSE", 0)
		B24LV.RefreshPowers(p, "SORCERY_POINTS")
	end },
	{ 75, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		conditionCheck("metamagic options as innates", { careful = knowsInnate(p, "B24MMCAR"), heightened = knowsInnate(p, "B24MMHEI"),
			notTransmuted = not knowsInnate(p, "B24MMTRA") })
		local points = B24LV.Remaining(p, "SORCERY_POINTS")
		-- Careful Spell: the ally (the wolf, on the party's side) succeeds.
		queue(w, "ChangeEnemyAlly(Myself,ALLY)")
		B24T.points = points
	end },
	{ 85, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		metamagic(p, "B24MMCAR", "SPWI304")
		local auto = false
		for _, listener in ipairs(B24.SaveAutoSuccessListeners) do
			local ok, result = pcall(listener, fakeEffect(p, "SPWI304"), w)
			auto = auto or (ok and result == true)
		end
		local otherSpell = false
		for _, listener in ipairs(B24.SaveAutoSuccessListeners) do
			local ok, result = pcall(listener, fakeEffect(p, "SPWI203"), w)
			otherSpell = otherSpell or (ok and result == true)
		end
		conditionCheck("Careful Spell: ally succeeds against that spell only", { ally = auto, onlyThatSpell = not otherSpell,
			pointSpent = B24LV.Remaining(p, "SORCERY_POINTS") == B24T.points - 1 })
		-- Empowered Spell: ten d6 are rolled into a flat amount with low dice rerolled.
		metamagic(p, "B24MMEMP", "SPWI304")
		local effect = fakeEffect(p, "SPWI304", 10, 6)
		for _, listener in ipairs(B24SP.DamageListeners) do pcall(listener, effect, p, w, "SPWI304") end
		out(string.format("Empowered Spell: 10d6 became %d", effect.m_effectAmount))
		conditionCheck("Empowered Spell: dice rolled with rerolls", { rolled = effect.m_numDice == 0,
			inRange = effect.m_effectAmount >= 10 and effect.m_effectAmount <= 60 })
		-- Heightened Spell: an enemy saves with disadvantage.
		queue(w, "ChangeEnemyAlly(Myself,ENEMY)")
	end },
	{ 95, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		metamagic(p, "B24MMHEI", "SPWI304")
		local adv, dis = B24.SaveAdvantage(w, "DEX", { SOURCE = p.m_id, RES = "SPWI304" })
		local _, disOther = B24.SaveAdvantage(w, "DEX", { SOURCE = p.m_id, RES = "SPWI203" })
		conditionCheck("Heightened Spell: enemy saves with disadvantage", { disadvantage = dis and not adv, onlyThatSpell = not disOther,
			pointsSpent = B24LV.Remaining(p, "SORCERY_POINTS") == B24T.points - 4 })
		-- Sorcery Incarnate: no Innate Sorcery uses left, 2 points start it.
		p:setLocalInt("B24ISUSE", 2)
		B24LV.Rebuild(p, "INNATE_SORCERY")
		B24LV.RefreshPowers(p, "SORCERY_POINTS")
	end },
	{ 105, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		local before = B24LV.Remaining(p, "SORCERY_POINTS")
		conditionCheck("Sorcery Incarnate innate when Innate Sorcery is used up", { incarnate = knowsInnate(p, "B24INSO2"),
			wings = knowsInnate(p, "B24DRWNG") })
		B24INSO2(nil, p)
		local active = B24.HasTimed(p, "INNATE_SORCERY")
		-- Two options on one spell; at 20 the first of the round is free (Arcane Apotheosis).
		B24MMCAR(nil, p)
		B24MMHEI(nil, p)
		for _, listener in ipairs(B24.SpellCastListeners) do pcall(listener, p, "SPWI305") end
		conditionCheck("Sorcery Incarnate: two options on one spell, Arcane Apotheosis", { active = active,
			careful = B24SO.MetaFor(p, "SPWI305", "CAREFUL"), heightened = B24SO.MetaFor(p, "SPWI305", "HEIGHTENED"),
			points = B24LV.Remaining(p, "SORCERY_POINTS") == before - 2 - 2 })
		-- Bard 18, College of Lore.
		B24T.featureStep = { class = { id = 5, name = "Bard", keys = { "BARD" } }, level = 18,
			subclass = pickIndex(B24LV.SUBCLASSES.BARD.list, "LORE") }
		setUp(p, B24T.featureStep)
	end },
	{ 145, function(p)
		local count
		for _, pick in ipairs(B24LV.PICKS) do
			if pick.key == "SECRETS" then count = pick.count(p) end
		end
		local list = B24BD.PriestSpells()
		local cure = pickIndex(list, "SPPR103")
		p:setLocalInt("B24BMS1", cure or 1)
		local ability
		for _, listener in ipairs(B24.CastingAbilityListeners) do
			local ok, result = pcall(listener, p, "SPPR103")
			if ok and result then ability = result end
		end
		out(string.format("Magical Secrets: %d picks, %d cleric and druid spells, casting ability %s", count or -1, #list, tostring(ability)))
		conditionCheck("Magical Secrets and Discoveries (Lore 18)", { picks = count == 8, list = #list > 10, charisma = ability == "CHA" })
		-- Superior Inspiration: a fight starts with at least two uses.
		local max = B24LV.RESOURCES.BARDIC_INSPIRATION.max(p)
		p:setLocalInt("B24BIUSE", max)
		B24.CombatStarted()
		conditionCheck("Superior Inspiration", { twoUses = B24LV.Remaining(p, "BARDIC_INSPIRATION") >= math.min(2, max) })
		-- Cleric 20.
		B24T.featureStep = { class = { id = 3, name = "Cleric", keys = { "CLERIC" } }, level = 19, subclass = 0 }
		setUp(p, B24T.featureStep)
	end },
	{ 170, function(p)
		conditionCheck("Divine Intervention innate", { known = knowsInnate(p, "B24CDIVI") })
		B24T.allowPopup = true
		B24T.popupShownAt = Infinity_GetClockTicks() + 60000
		B24CDIVI(nil, p)
		EEex_GameState_TogglePause(false, false)
		out("SHOT 95-divine-intervention")
	end },
	{ 190, function(p)
		local rows = #B24LV.ROWS
		local first = B24LV.ROWS[1] and B24LV.ROWS[1].oneOff
		B24LV_RowClick(1)
		B24LV_Done()
		B24T.popupShownAt = nil
		B24T.diRes = first and first.res
		conditionCheck("Divine Intervention: choice of cleric spells", { rows = rows > 10, title = first ~= nil })
	end },
	{ 205, function(p)
		conditionCheck("Divine Intervention grants the spell once", { granted = B24T.diRes ~= nil and knowsInnate(p, B24.InnateCopy(B24T.diRes)),
			used = B24LV.Remaining(p, "DIVINE_INTERVENTION") == 0, innateGone = not knowsInnate(p, "B24CDIVI") })
		for _, listener in ipairs(B24.SpellCastListeners) do pcall(listener, p, B24.InnateCopy(B24T.diRes)) end
	end },
	{ 340, function(p)
		-- A real cast of the granted spell after the test's own (the character's AI) starts the
		-- removal's countdown again: the check, and every later step, waits for it.
		local removeAt = B24.Aux(p).B24_DIRemoveAt
		if removeAt and B24.GameTick() < removeAt + 20 then
			B24T.fDelay = (B24T.fDelay or 0) + (removeAt + 20 - B24.GameTick())
			B24T.fStep = B24T.fStep - 1
			out(string.format("Divine Intervention: removal at tick %d, waiting", removeAt))
			return
		end
		conditionCheck("Divine Intervention spell taken back after the cast", { gone = not knowsInnate(p, B24.InnateCopy(B24T.diRes)),
			local0 = p:getLocalInt("B24DIGRT") == 0 })
		-- Wizard 20, Evoker.
		B24T.featureStep = { class = { id = 1, name = "Wizard", keys = { "WIZARD" } }, level = 20,
			subclass = pickIndex(B24LV.SUBCLASSES.WIZARD.list, "EVOKER") }
		setUp(p, B24T.featureStep)
	end },
	{ 380, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		out(string.format("wizard %d, subclass %s, applied %d", B24WZ.Level(p), tostring(B24LV.Subclass(p, "WIZARD")), B24LV.AppliedClassLevel(p, "WIZARD")))
		local known = knowsInnate(p, "B24OVCHN")
		if not known then
			out(string.format("Overchannel missing: class %d, applied signature %d (wanted %d), wizard %d, subclass %s; applies: %s; known changes: %s",
				B24.ClassID(p), p:getLocalInt("B24LVAPP"), B24T.featureStep.signature, B24WZ.Level(p), tostring(B24LV.Subclass(p, "WIZARD")),
				table.concat(B24T.applyLog or {}, ", "), table.concat(B24T.ovchLog or {}, ", ")))
			B24LV.Apply(p)
			out("Overchannel after applying again: " .. tostring(knowsInnate(p, "B24OVCHN")))
		end
		conditionCheck("Overchannel innate (Evoker 14)", { known = known, applied = ready(p, B24T.featureStep) })
		-- First use: maximum damage, free.
		p:setLocalInt("B24OVCH", 0)
		B24OVCHN(nil, p)
		for _, listener in ipairs(B24.SpellCastListeners) do pcall(listener, p, "SPWI304") end
		local effect = fakeEffect(p, "SPWI304", 8, 6)
		for _, listener in ipairs(B24SP.DamageListeners) do pcall(listener, effect, p, w, "SPWI304") end
		local hp = p.m_baseStats.m_hitPoints
		conditionCheck("Overchannel: maximum damage, the first use free", { max = effect.m_effectAmount >= 48 and effect.m_numDice == 0,
			uses = p:getLocalInt("B24OVCH") == 1 })
		-- Second use: necrotic damage to the wizard.
		p.m_baseStats.m_hitPoints = p:getActiveStats().m_nMaxHitPoints
		hp = p.m_baseStats.m_hitPoints
		B24T.hpBefore = hp
		B24.Aux(p).B24_Overchannel = nil
		B24OVCHN(nil, p)
		for _, listener in ipairs(B24.SpellCastListeners) do pcall(listener, p, "SPWI304") end
		-- Spell Mastery and Signature Spells: spells learned into the spellbook, then picked.
		local function pickList(key)
			for _, pick in ipairs(B24LV.PICKS) do if pick.key == key then return pick.list() end end
			return {}
		end
		B24T.m1, B24T.sig = pickList("MASTERY1")[1], pickList("SIGNATURE")[1]
		if B24T.m1 then B24.ApplyEffect(p, { ["effectID"] = 147, ["res"] = B24T.m1.res }) p:setLocalInt("B24WSM11", 1) end
		if B24T.sig then B24.ApplyEffect(p, { ["effectID"] = 147, ["res"] = B24T.sig.res }) p:setLocalInt("B24WSIG1", 1) end
		p:setLocalInt("B24WSGU", 0)
	end },
	{ 400, function(p)
		out(string.format("Overchannel: hit points %d (before %d), max %d active / %d base, feats %d, Tough %s", p.m_baseStats.m_hitPoints,
			B24T.hpBefore, p:getActiveStats().m_nMaxHitPoints, p.m_baseStats.m_maxHitPointsBase, p:getLocalInt("B24GFN"),
			tostring(B24FEAT and B24FEAT.Has(p, "TOUGH"))))
		conditionCheck("Overchannel: later uses hurt", { hurt = p.m_baseStats.m_hitPoints < B24T.hpBefore, uses = p:getLocalInt("B24OVCH") == 2 })
		B24WZ.RefreshMastery(p)
	end },
	{ 415, function(p)
		local m1 = B24T.m1 and B24.InnateCopy(B24T.m1.res)
		local sig = B24T.sig and B24.InnateCopy(B24T.sig.res)
		out(string.format("Spell Mastery %s, Signature Spell %s", tostring(m1), tostring(sig)))
		conditionCheck("Spell Mastery and Signature Spells as innates", { mastery = m1 ~= nil and knowsInnate(p, m1),
			signature = sig ~= nil and knowsInnate(p, sig) })
		for _, listener in ipairs(B24.SpellCastListeners) do pcall(listener, p, sig) end
		B24WZ.RefreshMastery(p)
	end },
	{ 430, function(p)
		local sig = B24T.sig and B24.InnateCopy(B24T.sig.res)
		local usedUp = not knowsInnate(p, sig)
		for _, listener in ipairs(B24.ShortRestListeners or {}) do pcall(listener, p) end
		B24T.sigUsedUp = usedUp
	end },
	{ 445, function(p)
		local sig = B24T.sig and B24.InnateCopy(B24T.sig.res)
		conditionCheck("Signature Spell: once per short rest", { usedUp = B24T.sigUsedUp, back = knowsInnate(p, sig) })
		-- Druid 20, Circle of the Land (arid).
		B24T.featureStep = { class = { id = 11, name = "Druid", keys = { "DRUID" } }, level = 20,
			subclass = pickIndex(B24LV.SUBCLASSES.DRUID.list, "LAND") }
		p:setLocalInt("B24LAND", pickIndex(B24DR.LANDS, "ARID"))
		setUp(p, B24T.featureStep)
	end },
	{ 490, function(p)
		p:setLocalInt("B24WSUSE", 0)
		B24LV.Rebuild(p, "WILD_SHAPE")
	end },
	{ 505, function(p)
		conditionCheck("druid 20 (Land) Wild Shape innates", { applied = ready(p, B24T.featureStep),
			uses = B24LV.Remaining(p, "WILD_SHAPE") == 4, companion = knowsInnate(p, "B24WCOMP"),
			sanctuary = knowsInnate(p, "B24NSANC"), magician = knowsInnate(p, "B24NMAGI") })
		local wolves = 0
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" then wolves = wolves + 1 end
		end
		B24T.wolves = wolves
		B24T.ac, B24T.fire = p:getActiveStats().m_nArmorClass, p:getActiveStats().m_nResistFire
		B24WCOMP(nil, p)
		B24NSANC(nil, p)
	end },
	{ 530, function(p)
		local wolves = 0
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper() == "B24BST03" then wolves = wolves + 1 end
		end
		local s = p:getActiveStats()
		conditionCheck("Wild Companion and Nature's Sanctuary", { wolf = wolves == B24T.wolves + 1,
			usesSpent = B24LV.Remaining(p, "WILD_SHAPE") == 2, ac = s.m_nArmorClass == B24T.ac - 2, fire = s.m_nResistFire >= B24T.fire + 50 })
		-- Evergreen Wild Shape: no uses left when a fight starts.
		p:setLocalInt("B24WSUSE", 4)
		B24LV.Rebuild(p, "WILD_SHAPE")
		B24.CombatStarted()
		conditionCheck("Archdruid: Evergreen Wild Shape", { oneBack = B24LV.Remaining(p, "WILD_SHAPE") == 1 })
		-- Nature's Sanctuary's +2 AC would keep the same bonus from Smite of Protection out.
		B24.ApplyEffect(p, { ["effectID"] = 337, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 1 })
		p:setLocalInt("B24WSUSE", 0)
		B24LV.Rebuild(p, "WILD_SHAPE")
	end },
	{ 545, function(p)
		-- Wild Shape: Druid 20 (Land) takes forms up to Challenge Rating 1 (tier 3: 11 forms).
		local listed = 0
		for _ in pairs(B24.LoadTable("B24WSL3")) do listed = listed + 1 end
		local moon = pickIndex(B24LV.SUBCLASSES.DRUID.list, "MOON")
		local land = p:getLocalInt(B24LV.SubclassLocal("DRUID"))
		p:setLocalInt(B24LV.SubclassLocal("DRUID"), moon)
		local moonTier = B24DR.FormTier(p)
		p:setLocalInt(B24LV.SubclassLocal("DRUID"), land)
		conditionCheck("Wild Shape innates and forms", { innate = knowsInnate(p, "B24WSHAP"), tier = B24DR.FormTier(p) == 3,
			moonTier = moonTier == 4, list = listed == 11, noBGShapes = not knowsInnate(p, "SPCL611") })
		local s = p:getActiveStats()
		B24T.shape = { str = B24.AbilityScore(p, "STR"), ac = s.m_nArmorClass, thac0 = s.m_nTHAC0, maxHP = s.m_nMaxHitPoints,
			anim = p.m_animation.m_animation.m_animationID }
		B24WFDWO(nil, p)
	end },
	{ 560, function(p)
		local s = p:getActiveStats()
		local form = B24DR.Form(p)
		if form == nil then
			local eq = p.m_equipment
			local item = eq.m_items:get(eq.m_selectedWeapon)
			local held = {}
			for slot = 0, 38 do
				local it = eq.m_items:get(slot)
				if it then table.insert(held, slot .. "=" .. it.cResRef:get()) end
			end
			out(string.format("Wild Shape: selected slot %d holds %s; items %s", eq.m_selectedWeapon,
				item and item.cResRef:get() or "nothing", table.concat(held, " ")))
		end
		local blocked = false
		local formEffects = {}
		EEex_Utility_IterateCPtrList(p.m_timedEffectList, function(e)
			if e.m_effectId == 145 then blocked = true end
			if e.m_sourceRes:get():upper() == B24DR.FORM_SOURCE or e.m_effectId == 111 then
				table.insert(formEffects, string.format("op%d %s dt%d", e.m_effectId, e.m_res:get(), e.m_durationType))
			end
		end)
		out(string.format("Wild Shape: THAC0 %d (natural %d, advantage %s); timed form effects: %s", s.m_nTHAC0,
			B24T.shape.thac0, tostring(B24.Aux(p).B24_attackBump), table.concat(formEffects, ", ")))
		-- Dire Wolf: AC 14, Strength 17 (+3), bite +5; engine THAC0 = 20 - (5 - 3), 5 less with advantage
		-- (Pack Tactics: the party stands next to the test wolf).
		conditionCheck("Wild Shape: Dire Wolf", { form = form ~= nil and form.key == "DIRE_WOLF",
			look = p.m_animation.m_animation.m_animationID == 0x7B02, str = B24.AbilityScore(p, "STR") == 17,
			ac = s.m_nArmorClass == 6, thac0 = s.m_nTHAC0 == 18 - (B24.Aux(p).B24_attackBump and B24.ADVANTAGE_BONUS or 0), tempHP = s.m_nMaxHitPoints == B24T.shape.maxHP + 20,
			used = B24LV.Remaining(p, "WILD_SHAPE") == 3, naturalForm = knowsInnate(p, "B24WSEND"),
			beastSpells = not blocked })
		B24T.shape.ac2, B24T.shape.thac02 = s.m_nArmorClass, s.m_nTHAC0
		-- The bite knocks a Large or smaller target prone.
		local w = B24.GetSprite(B24T.wolfID)
		if w then
			B24.RemoveEffectsBySource(w, "B24PRONE")
			local context = { attacker = p, target = w, effect = fakeEffect(p, "", 1, 10), isCritical = false }
			for _, listener in ipairs(B24WPN.DamageListeners) do pcall(listener, context) end
		end
	end },
	{ 575, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		local prone = false
		if w then EEex_Utility_IterateCPtrList(w.m_timedEffectList, function(e)
			if e.m_sourceRes:get():upper() == "B24PRONE" then prone = true end
		end) end
		conditionCheck("Wild Shape: Dire Wolf bite knocks prone", { wolf = w ~= nil, prone = prone })
		B24WSEND(nil, p)
	end },
	{ 590, function(p)
		local s = p:getActiveStats()
		local eq = p.m_equipment
		local held = eq.m_items:get(eq.m_selectedWeapon)
		out(string.format("Natural Form: selected slot %d holds %s", eq.m_selectedWeapon, held and held.cResRef:get() or "nothing"))
		conditionCheck("Wild Shape: Natural Form", { form = B24DR.Form(p) == nil, str = B24.AbilityScore(p, "STR") == B24T.shape.str,
			look = p.m_animation.m_animation.m_animationID == B24T.shape.anim, ac = s.m_nArmorClass == B24T.shape.ac,
			naturalForm = not knowsInnate(p, "B24WSEND") })
		-- A form whose time has run out ends by itself (the tick listener checks every second).
		B24WFWOL(nil, p)
		B24T.shape.timedForm = B24DR.Form(p) ~= nil
		p:setLocalInt("B24WSTIM", 1)
	end },
	{ 610, function(p)
		conditionCheck("Wild Shape: the form ends when its time runs out", { formed = B24T.shape.timedForm,
			ended = B24DR.Form(p) == nil, look = p.m_animation.m_animation.m_animationID == B24T.shape.anim })
		-- Paladin 15, Oath of Devotion.
		B24T.featureStep = { class = { id = 6, name = "Paladin", keys = { "PALADIN" } }, level = 15,
			subclass = pickIndex(B24LV.SUBCLASSES.PALADIN.list, "DEVOTION") }
		setUp(p, B24T.featureStep)
	end },
	{ 635, function(p)
		p:setLocalInt("B24LHUSE", 0)
		p:setLocalInt("B24SMUSE", 0)
		B24.ApplyEffect(p, { ["effectID"] = 74, ["durationType"] = 0, ["duration"] = 60 })
	end },
	{ 650, function(p)
		local blind = B24.GState_Has(p, B24.GState.BLIND)
		local pool = B24LV.Remaining(p, "LAY_ON_HANDS")
		B24LOH({ m_sourceId = p.m_id }, p)
		B24T.restore = { blind = blind, pool = pool }
	end },
	{ 665, function(p)
		-- Smite of Protection: a smiting hit gives the aura +2 AC.
		B24T.acBefore = p:getActiveStats().m_nArmorClass
		p:setLocalInt("B24SMTOG", 1)
		local w = B24.GetSprite(B24T.wolfID)
		local context = { attacker = p, target = w, effect = fakeEffect(p, "", 1, 8), isCritical = false }
		for _, listener in ipairs(B24WPN.DamageListeners) do pcall(listener, context) end
	end },
	{ 680, function(p)
		conditionCheck("Restoring Touch ends blindness", { wasBlind = B24T.restore.blind, cured = not B24.GState_Has(p, B24.GState.BLIND),
			fivePoints = B24LV.Remaining(p, "LAY_ON_HANDS") <= B24T.restore.pool - 5 })
		conditionCheck("Smite of Protection", { cover = p:getActiveStats().m_nArmorClass == B24T.acBefore - 2 })
		local charmImmune = false
		EEex_Utility_IterateCPtrList(p.m_timedEffectList, function(e) if e.m_effectId == 101 and e.m_dWFlags == 5 then charmImmune = true end end)
		conditionCheck("Aura of Devotion: immune to charm", { charm = charmImmune })
		p:setLocalInt(B24LV.SubclassLocal("PALADIN"), pickIndex(B24LV.SUBCLASSES.PALADIN.list, "GLORY"))
		conditionCheck("Glorious Defense uses (Glory 15)", { uses = B24LV.RESOURCES.GLORIOUS_DEFENSE.max(p) >= 1 })
		-- Ranger 15, Hunter (Multiattack Defense).
		B24T.featureStep = { class = { id = 12, name = "Ranger", keys = { "RANGER" } }, level = 15,
			subclass = pickIndex(B24LV.SUBCLASSES.RANGER.list, "HUNTER") }
		p:setLocalInt("B24DTACT", 1)
		setUp(p, B24T.featureStep)
	end },
	{ 725, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		-- Multiattack Defense: the wolf hits, then has disadvantage against the ranger.
		local before = B24.AttackerHasDisadvantageAgainst(w, p)
		local context = { attacker = w, target = p, effect = fakeEffect(w, "", 1, 6), isCritical = false }
		for _, listener in ipairs(B24WPN.DamageListeners) do pcall(listener, context) end
		conditionCheck("Multiattack Defense", { notBefore = not before, after = B24.AttackerHasDisadvantageAgainst(w, p) })
		-- Superior Hunter's Defense: the first damage of the round sets the type; that type is halved.
		B24.Aux(p).B24_HunterDefense = nil
		local fire1 = fakeEffect(w, "", 0, 0)
		fire1.m_effectAmount, fire1.m_dWFlags = 20, 0x80000
		EEex_Sprite_Hook_OnDamageEffectStartingCalculations(fire1, w, p)
		local cold = fakeEffect(w, "", 0, 0)
		cold.m_effectAmount, cold.m_dWFlags = 20, 0x20000
		EEex_Sprite_Hook_OnDamageEffectStartingCalculations(cold, w, p)
		conditionCheck("Superior Hunter's Defense", { fireHalved = fire1.m_effectAmount == 10, coldNot = cold.m_effectAmount == 20 })
		-- Rogue 17, Thief.
		B24T.featureStep = { class = { id = 4, name = "Rogue", keys = { "ROGUE" } }, level = 17,
			subclass = pickIndex(B24LV.SUBCLASSES.ROGUE.list, "THIEF") }
		setUp(p, B24T.featureStep)
	end },
	{ 770, function(p)
		local w = B24.GetSprite(B24T.wolfID)
		conditionCheck("Cunning Strike and Devious Strikes innates", { applied = ready(p, B24T.featureStep),
			poison = knowsInnate(p, "B24RCPOI"), knockOut = knowsInnate(p, "B24RCKNO") })
		B24RCTRP(nil, p)
		B24RCPOI(nil, p)
		local readied = #(B24.Aux(p).B24_Cunning or {})
		B24.SetTimed(p, "ATTACK_ADV", 6)
		B24.Aux(p).B24_SneakTick = nil
		local context = { attacker = p, target = w, effect = fakeEffect(p, "", 0, 0), isCritical = false, launcher = true }
		for _, listener in ipairs(B24WPN.DamageListeners) do pcall(listener, context) end
		local sneak = context.effect.m_effectAmount
		out(string.format("Sneak Attack with two Cunning Strikes: %d damage from 9d6 less 2d6", sneak))
		conditionCheck("Improved Cunning Strike: two effects spent by one Sneak Attack", { two = readied == 2,
			spent = B24.Aux(p).B24_Cunning == nil, sevenDice = sneak >= 7 and sneak <= 42 })
		local umd = false
		EEex_Utility_IterateCPtrList(p.m_timedEffectList, function(e) if e.m_effectId == 302 then umd = true end end)
		B24.CombatStarted()
		B24T.umd = umd
	end },
	{ 785, function(p)
		local hasted = false
		EEex_Utility_IterateCPtrList(p.m_timedEffectList, function(e) if e.m_effectId == 16 then hasted = true end end)
		conditionCheck("Use Magic Device and Thief's Reflexes", { umd = B24T.umd, reflexes = hasted })
		-- Sorcerer 9, Clockwork.
		B24T.featureStep = { class = { id = 19, name = "Sorcerer", keys = { "SORCERER" } }, level = 9,
			subclass = pickIndex(B24LV.SUBCLASSES.SORCERER.list, "CLOCKWORK") }
		setUp(p, B24T.featureStep)
	end },
	{ 830, function(p)
		conditionCheck("Clockwork Spells", { applied = ready(p, B24T.featureStep), wizardSpell = knowsInnate(p, "B24IW113"),
			aid = knowsInnate(p, "B24IP201"), greaterRestoration = knowsInnate(p, "B24IP713") })
		-- Sorcerer 18, Wild Magic: Tamed Surge.
		B24T.featureStep = { class = { id = 19, name = "Sorcerer", keys = { "SORCERER" } }, level = 18,
			subclass = pickIndex(B24LV.SUBCLASSES.SORCERER.list, "WILD_MAGIC") }
		setUp(p, B24T.featureStep)
	end },
	{ 875, function(p)
		conditionCheck("Tamed Surge innate", { applied = ready(p, B24T.featureStep), known = knowsInnate(p, "B24WTAME") })
		B24.Aux(p).B24_LastSpellTick = B24.GameTick()
		B24T.allowPopup = true
		B24T.popupShownAt = Infinity_GetClockTicks() + 60000
		B24WTAME(nil, p)
		EEex_GameState_TogglePause(false, false)
	end },
	{ 890, function(p)
		local rows = #B24LV.ROWS
		B24LV_RowClick(6)
		B24LV_Done()
		B24T.popupShownAt = nil
		conditionCheck("Tamed Surge: choose the surge", { rows = rows == #B24XS.SURGES, used = B24LV.Remaining(p, "TAMED_SURGE") == 0 })
		-- Monk 17, Warrior of Mercy.
		B24T.featureStep = { class = { id = 20, name = "Monk", keys = { "MONK" } }, level = 17,
			subclass = pickIndex(B24LV.SUBCLASSES.MONK.list, "MERCY") }
		setUp(p, B24T.featureStep)
	end },
	{ 935, function(p)
		p:setLocalInt("B24FPUSE", 0)
		B24LV.RefreshPowers(p, "FOCUS")
	end },
	{ 950, function(p)
		conditionCheck("Hand of Ultimate Mercy innate", { applied = ready(p, B24T.featureStep), known = knowsInnate(p, "B24MULTM") })
		-- Wizard 6, Illusionist.
		B24T.featureStep = { class = { id = 1, name = "Wizard", keys = { "WIZARD" } }, level = 6,
			subclass = pickIndex(B24LV.SUBCLASSES.WIZARD.list, "ILLUSIONIST") }
		setUp(p, B24T.featureStep)
	end },
	{ 995, function(p)
		local beasts = 0
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper():sub(1, 6) == "B24BST" then beasts = beasts + 1 end
		end
		B24T.beasts = beasts
		conditionCheck("Phantasmal Creatures innate", { applied = ready(p, B24T.featureStep), known = knowsInnate(p, "B24IPHAN") })
		B24IPHAN(nil, p)
	end },
	{ 1020, function(p)
		local beasts = 0
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if s.m_resref:get():upper():sub(1, 6) == "B24BST" then beasts = beasts + 1 end
		end
		conditionCheck("Phantasmal Creatures: an illusory beast", { summoned = beasts == B24T.beasts + 1 })
		return true
	end },
}

function B24T.FeaturesTick(sprite, now)
	-- Diagnostics for the Overchannel step: every apply on the protagonist, and every change of
	-- whether the innate is known.
	if not B24T.applyWrapped then
		B24T.applyWrapped, B24T.applyLog, B24T.ovchLog = true, {}, {}
		local originalApply = B24LV.Apply
		function B24LV.Apply(s, ...)
			local result = originalApply(s, ...)
			if s.m_id == sprite.m_id then
				table.insert(B24T.applyLog, string.format("%d class %d known %s", B24.GameTick(), B24.ClassID(s), tostring(knowsInnate(s, "B24OVCHN"))))
				if #B24T.applyLog > 8 then table.remove(B24T.applyLog, 1) end
			end
			return result
		end
	end
	local knownNow = knowsInnate(sprite, "B24OVCHN")
	if knownNow ~= B24T.ovchKnown then
		B24T.ovchKnown = knownNow
		table.insert(B24T.ovchLog, string.format("%d %s", now, tostring(knownNow)))
		if #B24T.ovchLog > 8 then table.remove(B24T.ovchLog, 1) end
	end
	local t = now - B24T.worldStart - (B24T.fDelay or 0)
	B24T.fStep = B24T.fStep or 1
	local step = FEATURE_STEPS[B24T.fStep]
	if step == nil or t <= step[1] then return end
	-- After a class change, wait (up to 20 seconds) until its features are applied; the later steps
	-- keep their spacing.
	if B24T.featureStep then settle(sprite, B24T.featureStep) end
	if B24T.featureStep and not ready(sprite, B24T.featureStep) and t - step[1] < 300 then
		B24T.fDelay = (B24T.fDelay or 0) + 1
		return
	end
	B24T.fStep = B24T.fStep + 1
	local fs = B24T.featureStep
	B24T.SetStatus(string.format("step %d of %d%s", B24T.fStep - 1, #FEATURE_STEPS,
		fs and string.format(" (%s %d)", fs.class.name, fs.level) or ""))
	local ok, result = pcall(step[2], sprite)
	if not ok then
		B24T.failed = B24T.failed + 1
		out("FAIL features step " .. (B24T.fStep - 1) .. ": " .. tostring(result))
	end
	if result == true or not ok or FEATURE_STEPS[B24T.fStep] == nil then
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Companions mode: every joinable NPC of the game (its highest-level version) is spawned without
-- dialogue or scripts, converted (B24NPC.lua) and checked: recognised by script name, abilities in
-- the 2024 range, 2024 hit points for single classes, a subclass for every class past its subclass
-- level. Then it is removed again.
-- The companions come from tools/ingame/companions.txt as copies without dialogue and scripts
-- (B24TEST_COMPANIONS: { copy, original }, written by tools/ingame-test.ps1).
local function companionList() return B24TEST_COMPANIONS or {} end

local function findSpawn(p, res)
	for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 900, false) or {}) do
		if s.m_resref:get():upper() == res and not B24.InParty(s) and s:getLocalInt("B24TSEEN") == 0 then return s end
	end
end

local function checkCompanion(s)
	local b = s.m_baseStats
	local abilitiesOk = b.m_STRExtraBase == 0
	for _, field in ipairs({ "m_STRBase", "m_DEXBase", "m_CONBase", "m_INTBase", "m_WISBase", "m_CHRBase" }) do
		if b[field] > 20 then abilitiesOk = false end
	end
	local multi = B24MC and B24MC.IsMulti(s)
	local hpOk = true
	if not multi then
		local die = B24NPC.HIT_DIE[B24.SkillClass(s) or ""] or B24.HitDie(s)
		local level = B24.Level(s)
		hpOk = b.m_maxHitPointsBase == math.max(1, die + (level - 1) * (math.floor(die / 2) + 1) + B24.AbilityModOf(s, "CON") * level)
	end
	local subclasses, subclassOk = {}, true
	for classKey, entry in pairs(B24LV.SUBCLASSES) do
		if B24LV.ClassLevel(s, classKey) >= entry.level then
			local sub = B24LV.Subclass(s, classKey)
			if sub == nil then subclassOk = false end
			table.insert(subclasses, classKey:lower() .. " " .. tostring(sub))
		end
	end
	-- A story creature (Wilson) keeps its BG statistics: left alone by the conversion, no subclass.
	if B24.IsStoryCreature(s) then
		abilitiesOk, hpOk = true, s:getLocalInt("B24NPCFIT") == 2
		subclassOk = #subclasses == 0
	end
	out(string.format("companion %s (%s): class %d, levels %d/%d/%d, hp %d (active %d), STR %d DEX %d CON %d INT %d WIS %d CHA %d, %s",
		B24.Name(s), tostring(B24NPC.ScriptName(s)), B24.ClassID(s), s:getStat(B24.Stat.LEVEL), s:getStat(B24.Stat.LEVEL2),
		s:getStat(B24.Stat.LEVEL3), b.m_maxHitPointsBase, s:getActiveStats().m_nMaxHitPoints, b.m_STRBase, b.m_DEXBase, b.m_CONBase, b.m_INTBase, b.m_WISBase,
		b.m_CHRBase, #subclasses > 0 and table.concat(subclasses, ", ") or "no subclass yet"))
	conditionCheck("companion " .. B24.Name(s), { companion = B24NPC.IsCompanion(s), abilities = abilitiesOk, hitPoints = hpOk,
		subclass = subclassOk })
end

function B24T.CompanionsTick(p, now)
	local c = B24T.companions
	if c == nil then
		if now - B24T.worldStart < 30 then return end
		-- The mod's messages in the log file too (what each conversion removed or changed).
		B24T.MirrorLog()
		c = { list = companionList(), index = 0, phase = "next", at = now }
		B24T.companions = c
	end
	if now < c.at then return end
	if c.phase == "next" then
		c.index = c.index + 1
		local entry = c.list[c.index]
		c.res = entry and entry.copy
		c.original = entry and entry.original
		B24T.SetStatus(string.format("%s (%d of %d)", tostring(c.original), c.index, #c.list))
		if c.res == nil then
			B24T.phase = "report"
			B24T.reportAt = now
			return
		end
		if EEex_Resource_Demand(c.res, "CRE") == nil then
			out("no creature file " .. c.res)
			c.at = now
			return
		end
		queue(p, string.format('CreateCreatureObjectOffset("%s",Myself,[160.0])', c.res))
		c.phase, c.at = "created", now + 8
	elseif c.phase == "created" then
		local s = findSpawn(p, c.res)
		if s == nil then
			if now - c.at > 60 then
				B24T.failed = B24T.failed + 1
				out("FAIL companion " .. c.original .. ": not created")
				c.phase = "next"
			end
			return
		end
		s:setLocalInt("B24TSEEN", 1)
		c.id = s.m_id
		out(string.format("companion %s before: hp %d of %d (base), %d (active), CON %d", c.original, s.m_baseStats.m_hitPoints,
			s.m_baseStats.m_maxHitPointsBase, s:getActiveStats().m_nMaxHitPoints, s.m_baseStats.m_CONBase))
		EEex_Utility_TryIgnore(B24NPC.Convert, s)
		c.phase, c.at = "check", now + 20
	elseif c.phase == "check" then
		local s = B24.GetSprite(c.id)
		if s then
			local ok, err = pcall(checkCompanion, s)
			if not ok then
				B24T.failed = B24T.failed + 1
				out("FAIL companion " .. c.original .. ": " .. tostring(err))
			end
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly("DestroySelf()", s)
		end
		c.phase, c.at = "next", now + 8
	end
end

-- Joining mode: companion copies (tools/ingame/companions.txt's Joining lines) join the party, are
-- converted on joining (B24NPC.lua; multiclasses rebuilt to their XP, B24MULTI.lua) and level up
-- twice through the record screen like a player does it (B24TCG's level-up driver).
local function portraitOf(sprite)
	for i = 0, 5 do
		local member = EEex_Sprite_GetInPortrait(i)
		if member and member.m_id == sprite.m_id then return i end
	end
end

function B24T.JoiningTick(p, now)
	local j = B24T.joining
	if j == nil then
		-- The mod's messages in the log file too (class features applied on joining).
		B24T.MirrorLog()
		j = { list = companionList(), index = 0, stage = "next", at = now }
		B24T.joining = j
	end
	if B24T.leveling or now < j.at then return end
	local function fail(text)
		B24T.failed = B24T.failed + 1
		out("FAIL joining " .. j.entry.original .. ": " .. text)
		j.stage = "next"
	end
	if j.stage == "next" then
		j.index = j.index + 1
		j.entry = j.list[j.index]
		if j.entry then B24T.SetStatus(string.format("%s joins (%d of %d)", j.entry.original, j.index, #j.list)) end
		if j.entry == nil then
			B24T.phase = "report"
			B24T.reportAt = now
			return
		end
		queue(p, string.format('CreateCreatureObjectOffset("%s",Myself,[120.0])', j.entry.copy))
		j.stage, j.at = "spawned", now + 8
	elseif j.stage == "spawned" then
		local s = findSpawn(p, j.entry.copy)
		if s == nil then
			if now - j.at > 60 then fail("not created") end
			return
		end
		s:setLocalInt("B24TSEEN", 1)
		j.id, j.since = s.m_id, now
		queue(s, "JoinParty()")
		j.stage = "joining"
	elseif j.stage == "joining" then
		local s = B24.GetSprite(j.id)
		if s == nil then return fail("gone") end
		-- Converted by the runtime once in the party; then a moment for the multiclass rebuild.
		-- A story creature (Wilson) is left as it is: B24NPCFIT 2.
		local fitted = B24.IsStoryCreature(s) and 2 or 1
		if not (B24.InParty(s) and s:getLocalInt("B24NPCFIT") == fitted) then
			if now - j.since > 300 then fail(string.format("not converted on joining (in party %s, B24NPCFIT %d)",
				tostring(B24.InParty(s)), s:getLocalInt("B24NPCFIT"))) end
			return
		end
		if not j.convertedAt then j.convertedAt = now return end
		if now - j.convertedAt < 45 then return end
		j.convertedAt = nil
		checkCompanion(s)
		local multi = B24MC.IsMulti(s)
		if multi then
			conditionCheck("joined multiclass " .. B24.Name(s) .. ": 2024 hit points",
				{ hitPoints = s.m_baseStats.m_maxHitPointsBase == B24MC.HitPoints(s) })
		end
		-- Two level-ups.
		local key = B24.SkillClass(s) or "FIGHTER"
		local level = B24TCG.TotalLevel(s)
		B24T.leveling = B24TCG.StartLevelUps(s, { portrait = portraitOf(s), multi = multi,
			class = key:sub(1, 1) .. key:sub(2):lower(), target = level + 2 })
		j.stage = "next"
	end
end

-- Spells mode: the spells changed to their 2024 form (b24_spells.tpa, B24SPELL.lua). A spawned
-- wolf with 1000 extra hit points, an ally, is the target of each, cast by the protagonist;
-- the damage must lie in the 2024 range (spell attacks: several casts, at least one hit, every
-- hit in range), the AC or state must change. fail = its save is forced to fail (a roll of 1,
-- B24_ForcedSave), so the full effect is seen.
local SPELL_CHECKS = {
	{ res = "SPWI112", label = "Magic Missile: 3 darts of 1d4+1, no roll", min = 6, max = 15 },
	{ res = "SPWI1123", label = "Magic Missile at level 3: 5 darts", min = 10, max = 25 },
	{ res = "SPWI118", label = "Chromatic Orb: spell attack, 3d8", min = 3, max = 48, casts = 4 },
	{ res = "SPWI217", label = "Scorching Ray: 3 rays, each 2d6 on a hit", min = 2, max = 72, casts = 3 },
	{ res = "SPWI211", label = "Acid Arrow: 4d4 and 2d4 later, half on a miss", min = 2, max = 40 },
	{ res = "SPPR414", label = "Inflict Wounds: 2d10 on a failed Con save", min = 2, max = 20, fail = true },
	{ res = "SPPR608", label = "Harm: 14d6 on a failed Con save", min = 14, max = 84, fail = true },
	{ res = "SPPR503", label = "Flame Strike: 5d6 fire and 5d6 radiant on a failed save", min = 10, max = 60, fail = true },
	{ res = "SPPR111", label = "Shield of Faith: +2 AC", ac = 2 },
	{ res = "SPWI105", label = "Color Spray: blinded on a failed save", state = "BLIND", fail = true, near = true, wait = 30 },
	{ res = "SPWI116", label = "Sleep: asleep on a failed save", state = "SLEEPING", fail = true, hostile = true },
	{ res = "SPWI305", label = "Haste: +2 AC on one creature", ac = 2 },
	{ res = "SPPR201", label = "Aid: +5 hit point maximum", maxhp = 5 },
	{ res = "SPWI314", label = "Vampiric Touch: melee spell attack, 3d6", min = 3, max = 36, casts = 4 },
	{ res = "SPWI404", label = "Ice Storm: 2d10 bludgeoning and 4d6 cold on a failed save", min = 6, max = 44, fail = true, hostile = true },
	{ res = "SPWI911", label = "Meteor Swarm: 20d6 fire and 20d6 bludgeoning on a failed save, once", min = 40, max = 240, fail = true, hostile = true },
	{ res = "SPWI912", label = "Power Word Kill: 12d12 above 100 hit points", min = 12, max = 144 },
	{ res = "B24USHA9", label = "Shatter at level 9: 10d8 (3d8 at most 24)", min = 25, max = 80, fail = true },
	{ res = "SPIN106", label = "Bhaalspawn Vampiric Touch: melee spell attack, 3d6", min = 3, max = 36, casts = 8 },
	{ res = "B24ENLRG", label = "Enlarge: one size larger", size = 4, fail = true },
	{ res = "B24REDUC", label = "Reduce: one size smaller", size = 2, fail = true },
	-- 2024 Dispel Magic (B24DISPL): cast for real (it reads its target from the caster's action);
	-- prep spells go on the wolf first, protect adds a protection from every spell level that
	-- would stop the spell itself.
	{ res = "SPWI3024", label = "Dispel Magic at level 4 ends Bless and Stoneskin, through a spell protection", force = true,
	  dispel = { prep = { "SPPR101", "SPWI408" }, protect = "SPWI408", gone = { "SPPR101", "SPWI408" } } },
	{ res = "SPWI3024", label = "Dispel Magic at level 4 doesn't reach past a Globe of Invulnerability", force = true,
	  dispel = { prep = { "SPPR101", "SPWI602" }, stays = { "SPPR101" } } },
	{ res = "SPWI3026", label = "Dispel Magic at level 6 ends the Globe and the spells it shields", force = true,
	  dispel = { prep = { "SPPR101", "SPWI602" }, gone = { "SPPR101", "SPWI602" } } },
}

-- Whether any of the creature's timed effects comes from this resource.
local function hasSource(sprite, res)
	local found = false
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_sourceRes:get():upper() == res then found = true return true end
	end)
	return found
end

function B24T.SpellsTick(p, now)
	local s = B24T.spellTest
	if s == nil then
		s = { stage = "spawn", index = 0 }
		B24T.spellTest = s
		-- The mod's messages in the log file too (Dispel Magic reports what it ends).
		B24T.MirrorLog()
		-- Diagnostics: which spells the protagonist started to cast (the mod's cast hook).
		s.started = {}
		table.insert(B24.SpellCastListeners, function(sprite, res)
			if sprite.m_id == p.m_id then s.started[res:upper()] = true end
		end)
		queue(p, 'CreateCreatureObjectOffset("B24BST03",Myself,[200.0])')
		s.at = now + 15
		return
	end
	-- Diagnostics: the actions the protagonist had between cast and measurement.
	if s.stage == "measure" then
		local id = p.m_curAction.m_actionID
		if id ~= 0 and s.actions[#s.actions] ~= id then table.insert(s.actions, id) end
	end
	if now < s.at then return end
	local w = s.wolf and B24.GetSprite(s.wolf)
	if s.stage == "spawn" then
		for _, c in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 600, false) or {}) do
			if c.m_resref:get():upper() == "B24BST03" then s.wolf = c.m_id end
		end
		w = s.wolf and B24.GetSprite(s.wolf)
		if w == nil then error("no wolf created") end
		-- An ally (a neutral creature turns hostile when a spell hits it, and fights back), many hit
		-- points, never below 10 of them; the protagonist doesn't go down either (more maximum hit
		-- points first: a level 1 maximum of 8 showed as 10/8).
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly('ChangeEnemyAlly(Myself,ALLY)', w)
		B24.ApplyEffect(p, { ["effectID"] = 18, ["effectAmount"] = 50, ["dwFlags"] = 0, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		B24.ApplyEffect(p, { ["effectID"] = 17, ["effectAmount"] = 50, ["dwFlags"] = 0, ["durationType"] = 1, ["m_sourceRes"] = "B24TEST" })
		B24.ApplyEffect(p, { ["effectID"] = 208, ["effectAmount"] = 10, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		B24.ApplyEffect(w, { ["effectID"] = 18, ["effectAmount"] = 1000, ["dwFlags"] = 0, ["durationType"] = 9 })
		B24.ApplyEffect(w, { ["effectID"] = 17, ["effectAmount"] = 1000, ["dwFlags"] = 0, ["durationType"] = 1 })
		B24.ApplyEffect(w, { ["effectID"] = 208, ["effectAmount"] = 10, ["durationType"] = 9 })
		s.stage, s.at = "next", now + 15
	elseif s.stage == "next" then
		s.index = s.index + 1
		local check = SPELL_CHECKS[s.index]
		if check == nil then
			-- Last: forced movement (B24.ForceMove), 10 ft away from the protagonist and back.
			s.stage, s.at, s.from = "pushed", now + 15, { w.m_pos.x, w.m_pos.y }
			out(string.format("sizes: protagonist %d, wolf %d", B24.Size(p), B24.Size(w)))
			B24.ForceMove(w, p, 10)
			return
		end
		B24T.SetStatus(string.format("%s (%d of %d)", check.label, s.index, #SPELL_CHECKS))
		s.check, s.cast, s.results = check, 0, {}
		s.stage = "cast"
	elseif s.stage == "pushed" or s.stage == "pulled" then
		local dx, dy = w.m_pos.x - s.from[1], w.m_pos.y - s.from[2]
		local moved = math.sqrt(dx * dx + dy * dy)
		out(string.format("%s: moved %.0f (10 ft = %.0f)", s.stage, moved, 10 * B24.FOOT))
		conditionCheck("forced movement: " .. s.stage .. " about 10 ft", { moved = moved >= 32 and moved <= 112 })
		if s.stage == "pushed" then
			s.stage, s.at, s.from = "pulled", now + 15, { w.m_pos.x, w.m_pos.y }
			B24.ForceMove(w, p, 10, true)
		else
			B24T.phase = "report"
			B24T.reportAt = now
		end
	elseif s.stage == "cast" then
		local check = s.check
		-- A fresh start: full hit points, no states or AC changes from the spell before.
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", w)
		B24.ApplyEffect(w, { ["effectID"] = 17, ["effectAmount"] = 2000, ["dwFlags"] = 0, ["durationType"] = 1 })
		s.hp, s.ac, s.maxhp = w.m_baseStats.m_hitPoints, w:getStat(B24.Stat.AC), w:getActiveStats().m_nMaxHitPoints
		if check.fail then B24.Aux(w).B24_ForcedSave = 1 end
		-- A short-ranged area (Color Spray's 15-foot cone): the wolf stands next to the protagonist.
		if check.near then EEex_Action_ExecuteResponseStringOnAIBaseInstantly("JumpToObject(Player1)", w) end
		-- Area spells that only reach enemies (Sleep): the wolf is hostile for this one.
		if check.hostile then EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ChangeEnemyAlly(Myself,ENEMY)", w) end
		-- The spell's effects go straight onto the wolf, with the protagonist as caster (ApplySpellRES
		-- at once; EEex_LuaObject is the script object EEex resolves to this creature). Not through
		-- the protagonist's action queue: Candlekeep's scripted talks can hold it for a whole run.
		EEex_LuaObject = w
		if check.dispel then
			-- The spells to dispel, cast by the wolf on itself; a protection from every spell level.
			for _, res in ipairs(check.dispel.prep) do
				EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format('ApplySpellRES("%s",Myself)', res), w)
			end
			if check.dispel.protect then
				for level = 1, 9 do
					B24.ApplyEffect(w, { ["effectID"] = 102, ["effectAmount"] = level, ["durationType"] = 0, ["duration"] = 600,
						["m_sourceRes"] = check.dispel.protect })
				end
			end
			local present = {}
			for _, res in ipairs(check.dispel.prep) do table.insert(present, res .. " " .. tostring(hasSource(w, res))) end
			out(string.format("%s: before the cast: %s", check.res, table.concat(present, ", ")))
		end
		if check.force then
			-- Dispel Magic reads its target from the cast's start (B24.LastSpellTarget, B24CONC.lua),
			-- its effect lands on the caster. A queued cast can be held up here (it didn't start in
			-- one run), so the target is set as a cast would set it and the spell applied to the caster.
			B24.LastSpellTarget[p.m_id] = w.m_id
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format('ApplySpellRES("%s",Myself)', check.res), p)
		else
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format('ApplySpellRES("%s",EEex_LuaObject)', check.res), p)
		end
		s.cast = s.cast + 1
		s.actions = {}
		-- Acid Arrow's second part comes a round later; effects of one round are looked at sooner.
		s.stage, s.at = "measure", now + (check.wait or 120)
	elseif s.stage == "measure" then
		local check = s.check
		local damage = s.hp - w.m_baseStats.m_hitPoints
		table.insert(s.results, damage)
		local acChange = s.ac - w:getStat(B24.Stat.AC)
		local inState = check.state and B24.GState_Has(w, B24.GState[check.state])
		if check.casts and s.cast < check.casts then
			s.stage = "cast"
			return
		end
		local ok
		local maxChange = w:getActiveStats().m_nMaxHitPoints - s.maxhp
		if check.dispel then
			local found = {}
			ok = true
			for _, res in ipairs(check.dispel.gone or {}) do
				if hasSource(w, res) then ok = false end
				table.insert(found, res .. (hasSource(w, res) and " still there" or " gone"))
			end
			for _, res in ipairs(check.dispel.stays or {}) do
				if not hasSource(w, res) then ok = false end
				table.insert(found, res .. (hasSource(w, res) and " stays" or " gone"))
			end
			out(string.format("%s: after the cast: %s", check.res, table.concat(found, ", ")))
			-- Clean up for the next check.
			for _, res in ipairs(check.dispel.prep) do B24.RemoveEffectsBySource(w, res) end
		elseif check.maxhp then
			ok = maxChange == check.maxhp
		elseif check.size then
			ok = B24.Size(w) == check.size
			out(string.format("%s: size %d", check.res, B24.Size(w)))
		elseif check.ac then
			ok = acChange == check.ac
		elseif check.state then
			ok = inState
		else
			local anyHit, allInRange = false, true
			for _, d in ipairs(s.results) do
				if d > 0 then anyHit = true end
				if d > 0 and (d < check.min or d > check.max) then allInRange = false end
			end
			ok = anyHit and allInRange
		end
		out(string.format("%s: %s, damage %s, AC change %d, max HP change %d, state %s (hp %d > %d, cast started %s, %d apart, spell file %s)",
			check.res, check.label, table.concat(s.results, "/"), acChange, maxChange, tostring(inState), s.hp, w.m_baseStats.m_hitPoints,
			tostring(s.started[check.res] == true), math.floor(math.sqrt((p.m_pos.x - w.m_pos.x) ^ 2 + (p.m_pos.y - w.m_pos.y) ^ 2)),
			tostring(EEex_Resource_Demand(check.res, "SPL") ~= nil)))
		conditionCheck(check.label, { result = ok })
		if check.hostile then EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ChangeEnemyAlly(Myself,ALLY)", w) end
		-- Remove what the spell left (Shield of Faith, blindness, sleep).
		B24.ApplyEffect(w, { ["effectID"] = 321, ["res"] = check.res, ["durationType"] = 1 })
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", w)
		s.stage, s.at = "next", now + 15
	end
end

-- SaveLoad mode: pending choices and a pending level-up survive saving and loading. The
-- protagonist becomes a Champion Fighter 4 with its Ability Score Improvement still to choose and
-- the XP for level 5, the game is saved as SAVELOAD_NAME (a new save; the test script deletes it
-- afterwards), the test quits to the main menu and loads that save, and compares. Saving and
-- quitting run from clicks (the test script's button in SAVE and ESC_MENU), as loading does.
local SAVELOAD_NAME = "B24 Test Pending"

-- The test script's full-screen click button in a menu.
local function inject(menu)
	local ok, err = pcall(EEex_Menu_InjectTemplate, menu, "B24TEST_Key", 0, 0, 1024, 768)
	if not ok then out("inject " .. menu .. ": " .. tostring(err)) end
	pcall(EEex_Menu_InjectTemplate, menu, "B24TEST_Status", 0, 0, 1024, 32)
end

local function saveLoadState(p)
	-- The pending level-up: level 4 with the XP for level 5.
	local want = tonumber(B24.LoadTable("XPLEVEL").FIGHTER["5"])
	return {
		subclass = tostring(B24LV.Subclass(p, "FIGHTER")),
		asi = B24LV.Pending(p).ASI,
		applied = B24LV.AppliedClassLevel(p, "FIGHTER"),
		asiInnate = knowsInnate(p, "B24ASI"),
		canLevel = p:getStat(B24.Stat.LEVEL) == 4 and p.m_baseStats.m_xp >= want,
		hp = p:getStat(B24.Stat.MAXHP),
		concentration = B24.Concentration[p.m_id] and B24.Concentration[p.m_id].res or "none",
	}
end

local function describe(s)
	return string.format("subclass %s, ASI pending %d, applied %d, ASI innate %s, level-up pending %s, HP %d, concentration %s",
		s.subclass, s.asi, s.applied, tostring(s.asiInnate), tostring(s.canLevel), s.hp, s.concentration)
end

function B24T.SaveLoadTick(p, now)
	local s = B24T.saveLoad
	if s == nil then
		s = { stage = "setup" }
		B24T.SetStatus("pending choice and level-up: setting up, then save, main menu, load")
		B24T.saveLoad = s
		for _, menu in ipairs({ "SAVE", "ESC_MENU" }) do inject(menu) end
		B24T.featureStep = { class = { id = 2, name = "Fighter", keys = { "FIGHTER" } }, level = 4,
			subclass = pickIndex(B24LV.SUBCLASSES.FIGHTER.list, "CHAMPION") }
		setUp(p, B24T.featureStep)
		s.at = now
	elseif s.stage == "setup" then
		settle(p, B24T.featureStep)
		if not ready(p, B24T.featureStep) and now - s.at < 300 then return end
		p:setLocalInt("B24ASIDN", 0)
		-- The XP for level 5, without the level-up.
		local xp = tonumber(B24.LoadTable("XPLEVEL").FIGHTER["5"])
		p.m_baseStats.m_xp = xp
		B24.ApplyEffect(p, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60, ["m_sourceRes"] = "B24TREF" })
		B24.RemoveEffectsBySource(p, "B24TREF")
		-- A concentration spell (Bless on itself): kept through saving and loading (B24CONC.lua).
		queue(p, 'ReallyForceSpellRES("SPPR101",Myself)')
		s.stage, s.at = "measure", now
	elseif s.stage == "measure" and now - s.at > 45 and not Infinity_IsMenuOnStack("WORLD_DIALOG") then
		-- Not during a conversation: the game refuses to save in dialogue mode.
		s.before = saveLoadState(p)
		out("before saving: " .. describe(s.before))
		conditionCheck("save and load: set up", { asiPending = s.before.asi == 1, champion = s.before.subclass == "CHAMPION",
			levelUpPending = s.before.canLevel, concentrating = s.before.concentration ~= "none" })
		s.stage = "saving"
		B24T.phase = "saveload"
		out("CLICKS ON")
		optionsScreen:SaveGame(0)
		s.at = now
	elseif s.stage == "saved" then
		-- Back in the game after saving: the pause menu, then Main Menu by click.
		s.stage = "quitting"
		B24T.phase = "saveload"
		Infinity_PushMenu("ESC_MENU")
		out("CLICKS ON")
	elseif s.stage == "loaded" and now - B24T.worldStart > 60 then
		local after = saveLoadState(p)
		out("after loading: " .. describe(after))
		local b = s.before
		conditionCheck("save and load: choices and level-up kept", { subclass = after.subclass == b.subclass,
			asiPending = after.asi == b.asi, applied = after.applied == b.applied, asiInnate = after.asiInnate == b.asiInnate,
			levelUpPending = after.canLevel == b.canLevel, hp = after.hp == b.hp , concentration = after.concentration == b.concentration })
		out("SHOT 01-after-load")
		s.stage = "done"
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- Clicks of the SaveLoad mode: save on the save screen, Main Menu in the pause menu.
function B24T.SaveLoadKey()
	local s = B24T.saveLoad
	if s.stage == "saving" and Infinity_IsMenuOnStack("SAVE") and gameSaves and gameSaves.files then
		out("saving as " .. SAVELOAD_NAME)
		s.stage = "saved"
		B24T.phase = "world"
		out("CLICKS OFF")
		saveScreen:SaveGame(#gameSaves.files, SAVELOAD_NAME)
	elseif s.stage == "saving" and not Infinity_IsMenuOnStack("SAVE") and not Infinity_IsMenuOnStack("WORLD_DIALOG")
		and B24.GameTick() - s.at > 150 then
		-- The game refused to save (a conversation started meanwhile; it is answered first): again.
		out("save screen not open after 10 s, asking again")
		optionsScreen:SaveGame(0)
		s.at = B24.GameTick()
	elseif s.stage == "quitting" and Infinity_IsMenuOnStack("ESC_MENU") then
		out("quitting to the main menu")
		s.stage = "loaded"
		-- The menu phase loads the new save like the first one.
		B24TEST_SAVE = SAVELOAD_NAME
		B24T.phase, B24T.frames, B24T.loadOpened = "menu", 0, false
		optionsScreen:QuitGame()
	end
end

-- Record mode: the character record's Features tab (B24UI.lua), then the choice popup's row icons
-- (B24LEVEL.menu). The game pauses on the record screen and under the popup, so those steps run
-- from clicks (the test script's full-screen button in CHARACTER and B24_LEVELUP). Each popup opens
-- from the world tick, which runs only while the game runs: the popup pauses the game itself and
-- its Cancel resumes it.

-- Opens one choice popup for the protagonist (open = B24WMAS, B24FSTY, ...).
local function openPopup(open)
	B24T.allowPopup = true
	B24T.popupShownAt = Infinity_GetClockTicks()
	open(nil, protagonist())
	return Infinity_IsMenuOnStack("B24_LEVELUP")
end

-- The popups in turn: each opens, checks its rows and names its screenshot.
local RECORD_POPUPS = {
	function()
		-- Weapon masteries: every row has a weapon icon.
		local shown = openPopup(B24WMAS)
		local first = B24LV.ROWS[1]
		conditionCheck("popup mastery icons", { shown = shown, hasIcons = B24LV_HasIcons(),
			icon = first ~= nil and B24LV_RowIcon(1) == first.weapon.icon })
		return "03-popup-mastery"
	end,
	function()
		-- Fighting styles have no icons: the names keep the full width.
		local shown = openPopup(B24FSTY)
		conditionCheck("popup style without icons", { shown = shown, noIcons = not B24LV_HasIcons(),
			rows = #B24LV.ROWS > 0 })
		return "04-popup-style"
	end,
	function()
		-- Spells: a one-off choice of three cantrips shows their spell icons.
		local list = {}
		for i = 1, 3 do
			local cantrip = B24SP.CANTRIPS[i]
			table.insert(list, { name = cantrip.name, desc = "", res = cantrip.res })
		end
		local shown = openPopup(function(_, sprite)
			B24LV.OpenChoice(sprite, { title = "Test", help = "Row icons of spells.", list = list, onChoose = function() end })
		end)
		local icon = B24LV_RowIcon(1)
		conditionCheck("popup spell icons", { shown = shown, icon = icon ~= "" and EEex_Resource_Demand(icon, "BAM") ~= nil,
			all = B24LV_RowIcon(3) ~= "" })
		return "05-popup-spells"
	end,
}

function B24T.RecordTick(p, now)
	local r = B24T.record
	if r == nil then
		B24T.record = { step = 0, popup = 0 }
		B24T.SetStatus("character record: Features tab, then choice popups with icons")
		inject("CHARACTER")
		inject("B24_LEVELUP")
		B24T.phase = "record"
		out("opening the character record")
		-- As the sidebar's record button does (the engine fills the characters table first).
		e:GetActiveEngine():OnLeftPanelButtonClick(4)
		out("CLICKS ON")
	elseif r.step == 3 then
		r.popup = r.popup + 1
		local open = RECORD_POPUPS[r.popup]
		if open == nil then
			B24T.phase = "report"
			B24T.reportAt = now
			return
		end
		out("SHOT " .. open())
		r.step, r.at = 4, Infinity_GetClockTicks()
		B24T.phase = "record"
		out("CLICKS ON")
	end
end

function B24T.RecordKey()
	local r = B24T.record
	local clock = Infinity_GetClockTicks()
	if r.step == 4 then
		-- The popup's screenshot is taken; Cancel closes it and resumes the game for the next one.
		if not Infinity_IsMenuOnStack("B24_LEVELUP") or clock - r.at < 3000 then return end
		B24LV_Cancel()
		out("CLICKS OFF")
		r.step = 3
		B24T.phase = "world"
		return
	end
	if not Infinity_IsMenuOnStack("CHARACTER") then return end
	-- The character the record shows (the selected one, not always the protagonist).
	local sprite = B24.GetSprite(currentID)
	if r.step == 0 then
		currentTab = 10
		updateAttrTable()
		local text = type(helpTextString) == "string" and helpTextString or ""
		local classKey = sprite and B24.SkillClass(sprite) or ""
		local classTitle = classKey:sub(1, 1) .. classKey:sub(2):lower()
		local level = sprite and B24LV.ClassLevel(sprite, classKey) or 0
		out("features tab: " .. text:gsub("\n", " | "):sub(1, 600))
		conditionCheck("record Features tab", {
			shown = showJustText == true,
			class = text:find(classTitle .. " " .. level, 1, true) ~= nil,
			features = text:find("\n1: ", 1, true) ~= nil,
			sameAsBuilder = text == B24UI.FeaturesText(sprite),
		})
		out("SHOT 01-record-features")
		r.step, r.at = 1, clock
	elseif r.step == 1 and clock - r.at > 3000 then
		-- Another tab afterwards shows its own text again.
		currentTab = 9
		updateAttrTable()
		local text = type(helpTextString) == "string" and helpTextString or ""
		conditionCheck("record other tab", { ownText = text ~= "" and text ~= B24UI.FeaturesText(sprite) })
		out("SHOT 02-record-combat")
		r.step, r.at = 2, clock
	elseif r.step == 2 and clock - r.at > 3000 then
		-- Back on the game screen the world tick opens the popups (step 3).
		out("CLICKS OFF")
		e:SelectEngine(worldScreen)
		r.step = 3
		B24T.phase = "world"
	end
end

-- The global script calls B24_HasPendingScreens (B24ROUND.lua) on every AI update. Wrapped once
-- the runtime has defined it (the engine may load this module before the mod's own files).
-- Conversations (BG2's Imoen and Jaheira talk in the dungeon) pause the game and wait for clicks:
-- while one is open the test script clicks, and each click answers with the first reply or steps
-- on (B24T.MenuKey). Afterwards the clicks are as before.
function B24T.DialogWatch()
	if B24TEST_MODE == "chargen" then return end
	local open = Infinity_IsMenuOnStack("WORLD_DIALOG")
	if open and not B24T.inDialog then
		B24T.inDialog = true
		B24T.clicksBeforeDialog = B24T.clicks
		out("conversation started")
		if not B24T.clicks then out("CLICKS ON") end
	elseif not open and B24T.inDialog then
		B24T.inDialog = false
		out("conversation ended")
		if not B24T.clicksBeforeDialog then out("CLICKS OFF") end
	end
end

-- Story conversations (BG2's Jaheira starts the same one again and again in the dungeon) would
-- otherwise be answered at random, with consequences: in a world test every creature of the area
-- but the protagonist loses its dialogue file (and outside the party its scripts), again every 5 seconds (only in the running game; the test
-- saves nothing but SaveLoad's own save, which is deleted).
function B24T.SilenceDialogs()
	local p = EEex_Sprite_GetInPortrait(0)
	if p == nil then return end
	-- Nobody can start a dialogue with the protagonist (area scripts still send Candlekeep's
	-- Imoen and Tethtoril to talk, which would interrupt its actions).
	EEex_Action_ExecuteResponseStringOnAIBaseInstantly("DialogInterrupt(FALSE)", p)
	local n = 0
	for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 30000, false) or {}) do
		if s.m_id ~= p.m_id then
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly('SetDialog("")', s)
			-- Outside the party they also stop acting on their own: starting a dialogue interrupts
			-- the protagonist's action even without a dialogue file (Candlekeep's Imoen). The test's
			-- own creatures (B24*: the wolf, companion copies) keep their scripts.
			if not B24.InParty(s) and s.m_resref:get():upper():sub(1, 3) ~= "B24" and s:getLocalInt("B24TQUIET") == 0 then
				s:setLocalInt("B24TQUIET", 1)
				EEex_Action_ExecuteResponseStringOnAIBaseInstantly('ClearActions(Myself) ChangeAIScript("",OVERRIDE) '
					.. 'ChangeAIScript("",CLASS) ChangeAIScript("",RACE) ChangeAIScript("",GENERAL) ChangeAIScript("",DEFAULT)', s)
			end
			n = n + 1
		end
	end
	if n ~= B24T.silencedCount then out(string.format("dialogues off for %d creatures", n)) end
	B24T.silencedCount = n
end

function B24T.AnswerDialog()
	if worldPlayerDialogChoices and #worldPlayerDialogChoices > 0 then
		worldScreen:OnDialogReplyClick(worldPlayerDialogChoices[1].marker)
	else
		worldScreen:StepDialog()
	end
end

function B24T.HookWorld()
	if B24T.worldHooked or type(B24_HasPendingScreens) ~= "function" then return end
	B24T.worldHooked = true
	-- The party portraits evaluate this every frame on the game screen.
	local originalNumCharacters = Infinity_GetNumCharacters
	function Infinity_GetNumCharacters(...)
		pcall(B24T.Alive)
		pcall(B24T.DialogWatch)
		pcall(B24T.FrameTick)
		pcall(B24T.Watchdog)
		pcall(B24T.StallReport)
		pcall(B24T.GameOverCheck)
		return originalNumCharacters(...)
	end
	local originalHasPendingScreens = B24_HasPendingScreens
	function B24_HasPendingScreens()
		pcall(B24T.WorldTick)
		-- The game must keep running for the test (no pauses, no popups).
		if B24T.phase == "steps" then
			local ok, paused = pcall(function() return EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_bPaused end)
			if ok and (paused == true or paused == 1) then EEex_GameState_TogglePause(false, false) end
		end
		return originalHasPendingScreens()
	end
end

-- The steps change levels like level-ups, so the runtime asks for subclasses, ASIs and masteries
-- for the protagonist and for companions (BG2's Imoen) from the moment the save is loaded. A popup
-- pauses the game, and a paused game runs no scripts, so the test would stop: the popups are
-- cancelled instead (the choices stay pending), except the first one during the steps, which is
-- shown for a screenshot and cancelled a few seconds later.
function B24T.InWorldPhase()
	return B24TEST_MODE ~= "chargen" and B24T.phase ~= "menu" and B24T.phase ~= "done"
end

local originalPushMenu = Infinity_PushMenu
function Infinity_PushMenu(name, ...)
	if name == "B24_LEVELUP" and B24T.leveling and B24TEST_MODE == "joining" then return originalPushMenu(name, ...) end
	if name == "B24_LEVELUP" and B24T.allowPopup then
		B24T.allowPopup = false
		return originalPushMenu(name, ...)
	end
	if name == "B24_LEVELUP" and B24T.InWorldPhase() then
		B24T.popups = (B24T.popups or 0) + 1
		if B24T.phase == "steps" and not B24T.popupShownAt then
			B24T.popupShownAt = Infinity_GetClockTicks()
			local result = originalPushMenu(name, ...)
			out(string.format("SHOT 50-choice-popup-step%d", B24T.step))
			return result
		end
		B24LV_Cancel()
		return
	end
	return originalPushMenu(name, ...)
end

if B24TEST_MODE == "chargen" or B24TEST_MODE == "joining" then Infinity_DoFile("B24TCG") end
B24T.HookMenus()
out("test module loaded, save: " .. tostring(B24TEST_SAVE))

-- XPCap: XP given the way the game gives it (AddXPObject) must reach the active XP; BG2:EE's
-- level-up test saw the active value held at 161000 (BG1's cap) while the base grew.
function B24T.XPCapTick(p, now)
	local x = B24T.xpCap
	local function report(label)
		local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
		local campaign = "?"
		pcall(function() campaign = string.format("%s/%d", game.m_sCurrentCampaign:get(), game.m_nActiveCampaign) end)
		out(string.format("%s: base %d, active %d, chapter %d, campaign %s", label, p.m_baseStats.m_xp, p:getStat(44),
			EEex_GameState_GetGlobalInt("CHAPTER"), campaign))
	end
	if x == nil then
		B24T.xpCap = { stage = "added", at = now }
		B24T.SetStatus("XP cap: AddXPObject 400000")
		report("before")
		EEex_Action_QueueResponseStringOnAIBase("AddXPObject(Myself,400000)", p)
	elseif x.stage == "added" and now - x.at > 90 then
		report("after AddXPObject 400000")
		conditionCheck("given XP reaches the active XP", { active = p:getStat(44) == p.m_baseStats.m_xp,
			above = p:getStat(44) > 161000 })
		x.stage = "done"
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- RangeProbe: what a spell range unit is in world units (area coordinates). A wolf is held in place, the protagonist jumps
-- far away from it and casts innates of known range at it (Shocking Grasp: touch, Fire Bolt 60, Magic
-- Missile's dart 120); the engine walks the caster until the wolf is in range, and the distance
-- where it stops is that range in world units.
local RANGE_PROBES = { { "B24CSHOC", "touch" }, { "B24CFIRE", 60 }, { "B24MDART", 120 } }
local RANGE_OFFSETS = { 2400, -2400 }
function B24T.RangeProbeTick(p, now)
	local r = B24T.rangeProbe
	if r == nil then
		r = { index = 1, side = 1, stage = "spawn", results = {} }
		B24T.rangeProbe = r
		local ok, visual = pcall(function() return p:virtual_GetVisualRange() end)
		out(string.format("visual range %s", ok and tostring(visual) or "?"))
	end
	local probe = RANGE_PROBES[r.index]
	if r.stage == "done" then return end
	if probe == nil then
		local parts = {}
		for _, res in ipairs(r.results) do table.insert(parts, string.format("%s: %.0f px", tostring(res.range), res.px)) end
		out("range scale: " .. table.concat(parts, ", "))
		conditionCheck("range probe measured every spell", { all = #r.results == #RANGE_PROBES })
		r.stage = "done"
		B24T.phase = "report"
		B24T.reportAt = now
		return
	end
	local function wolf() return r.wolfID and B24.GetSprite(r.wolfID) end
	if r.stage == "spawn" then
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", p)
		r.known = {}
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 30000, false) or {}) do r.known[s.m_id] = true end
		-- At once, not through the protagonist's queue (the queued spawn never ran in the 2026-11-08 batch).
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly('CreateCreatureObjectOffset("B24BST03",Myself,[60.0])', p)
		r.stage, r.at = "find", now
	elseif r.stage == "find" then
		for _, s in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(p, "[ANYONE]", 30000, false) or {}) do
			if not r.known[s.m_id] and s.m_resref:get():upper() == "B24BST03" then r.wolfID = s.m_id end
		end
		local w = wolf()
		if w then
			-- Held in place and quiet: no script, paralysed for a minute.
			EEex_Action_ExecuteResponseStringOnAIBaseInstantly('ClearActions(Myself) ChangeAIScript("",OVERRIDE) ChangeAIScript("",CLASS) '
				.. 'ChangeAIScript("",RACE) ChangeAIScript("",GENERAL) ChangeAIScript("",DEFAULT) SetDialog("")', w)
			B24.ApplyEffect(w, { ["effectID"] = 109, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60 })
			w.m_baseStats.m_hitPoints = 500
			-- The caster jumps away from it, then walks back into range.
			queue(p, string.format("JumpToPoint([%d.%d])", w.m_pos.x + RANGE_OFFSETS[r.side], w.m_pos.y))
			B24LV.Grant(p, probe[1], true)
			EEex_LuaObject = w
			queue(p, string.format('SpellRES("%s",EEex_LuaObject)', probe[1]))
			r.lastX, r.lastY, r.still, r.moved, r.at, r.stage = p.m_pos.x, p.m_pos.y, 0, false, now, "walk"
			out(string.format("%s: wolf at %d.%d, caster at %d.%d", probe[1], w.m_pos.x, w.m_pos.y, p.m_pos.x, p.m_pos.y))
		elseif now - r.at > 90 then
			out("no wolf appeared")
			r.index = r.index + 1
			r.stage = "spawn"
		end
	elseif r.stage == "walk" then
		local w = wolf()
		local x, y = p.m_pos.x, p.m_pos.y
		if x ~= r.lastX or y ~= r.lastY then r.moved, r.still = true, 0 elseif r.moved then r.still = r.still + 1 end
		r.lastX, r.lastY = x, y
		if w and r.moved and r.still >= 8 then
			local dx, dy = w.m_pos.x - x, w.m_pos.y - y
			local px = math.sqrt(dx * dx + dy * dy)
			out(string.format("%s range %s: stopped %.0f px from the wolf (dx %d, dy %d)", probe[1], tostring(probe[2]), px, dx, dy))
			table.insert(r.results, { range = probe[2], px = px })
			r.index = r.index + 1
		elseif w == nil or now - r.at > 600 or (not r.moved and now - r.at > 120) then
			out(string.format("%s: no measurement (moved %s, wolf %s)", probe[1], tostring(r.moved), tostring(w ~= nil)))
			if r.side < #RANGE_OFFSETS then r.side = r.side + 1 else r.index, r.side = r.index + 1, 1 end
		else
			return
		end
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly("ClearActions(Myself)", p)
		if w then EEex_Action_ExecuteResponseStringOnAIBaseInstantly("DestroySelf()", w) end
		r.wolfID, r.stage = nil, "spawn"
	end
end

-- Export: a character with the mod's choices (Fighter 4, Champion, an Ability Score Improvement
-- pending) is exported through the record screen's Export button as B24TEXP.CHR; the test script
-- looks into the file for the mod's local variables (do they reach a BG2 import?) and deletes it.
local EXPORT_LOCALS = { "B24SUBC", "B24ASIDN", "B24LVAPP", "B24SKILL", "B24MAST", "B24FSTY", "B24BG", "B24SPC",
	"B24GF", "B24SETUP", "B24LIN" }
function B24T.ExportTick(p, now)
	local s = B24T.export
	if s == nil then
		s = { stage = "setup", at = now }
		B24T.export = s
		B24T.SetStatus("export: setting up, then the record screen's Export")
		B24T.featureStep = { class = { id = 2, name = "Fighter", keys = { "FIGHTER" } }, level = 4,
			subclass = pickIndex(B24LV.SUBCLASSES.FIGHTER.list, "CHAMPION") }
		setUp(p, B24T.featureStep)
		for _, menu in ipairs({ "CHARACTER", "CHARACTER_EXPORT" }) do inject(menu) end
	elseif s.stage == "setup" then
		settle(p, B24T.featureStep)
		if not ready(p, B24T.featureStep) and now - s.at < 300 then return end
		local parts = {}
		for _, name in ipairs(EXPORT_LOCALS) do table.insert(parts, string.format("%s=%d", name, p:getLocalInt(name))) end
		out("locals before export: " .. table.concat(parts, " "))
		-- Record screen colours: green where the current score is above the base. An ASI-style +1
		-- Strength (op44, permanent) first.
		local function scores(label)
			local fields = { STR = "m_STRBase", DEX = "m_DEXBase", CON = "m_CONBase", INT = "m_INTBase", WIS = "m_WISBase", CHA = "m_CHRBase" }
			local list = {}
			for _, a in ipairs({ "STR", "DEX", "CON", "INT", "WIS", "CHA" }) do
				table.insert(list, string.format("%s %d/%d", a, p.m_baseStats[fields[a]], p:getStat(B24.AbilityStat[a])))
			end
			out(label .. " (base/current): " .. table.concat(list, ", "))
		end
		scores("scores")
		B24.ApplyEffect(p, { ["effectID"] = 44, ["effectAmount"] = 1, ["dwFlags"] = 0, ["durationType"] = 1 })
		scores("after +1 Strength (permanent)")
		s.stage = "record"
		B24T.phase = "export"
		out("CLICKS ON")
		e:GetActiveEngine():OnLeftPanelButtonClick(4)
	end
end

function B24T.ExportKey()
	local s = B24T.export
	if s.stage == "record" and Infinity_IsMenuOnStack("CHARACTER") then
		local p = EEex_Sprite_GetInPortrait(0)
		local list = {}
		for _, a in ipairs({ "STR", "DEX", "CON", "INT", "WIS", "CHA" }) do
			table.insert(list, string.format("%s %d/%d", a, p.m_baseStats[({ STR = "m_STRBase", DEX = "m_DEXBase", CON = "m_CONBase",
				INT = "m_INTBase", WIS = "m_WISBase", CHA = "m_CHRBase" })[a]], p:getStat(B24.AbilityStat[a])))
		end
		out("record open (base/current): " .. table.concat(list, ", "))
		B24T.ConditionCheck("record shows no social bonus", { noBonus = not B24.HasEffectSource(p, 6, "B24SOCIA") and not B24.HasEffectSource(p, 19, "B24SOCIA") })
		s.stage = "naming"
		characterScreen:OnExportButtonClick()
	elseif s.stage == "naming" and Infinity_IsMenuOnStack("CHARACTER_EXPORT") then
		characterExportCharacterEdit = "B24TEXP"
		Infinity_UpdateCharacterRecordExportPanel()
		-- The Done button as the menu calls it (the mod's variables go along, B24CORE.lua).
		B24_RecordDone()
		out("exported B24TEXP")
		s.stage = "done"
		out("CLICKS OFF")
		B24T.phase = "report"
		B24T.reportAt = B24.GameTick()
	end
end

-- Drain: BG's level drain (op216) takes levels, Restoration (op224) gives them back; the class
-- features follow the level both ways (B24LV.Apply on every level change).
function B24T.DrainTick(p, now)
	local d = B24T.drain
	local function state()
		return { level = p:getStat(B24.Stat.LEVEL), applied = B24LV.AppliedClassLevel(p, "FIGHTER"), prof = B24.ProfOf(p),
			maxhp = p:getStat(B24.Stat.MAXHP), subclass = tostring(B24LV.Subclass(p, "FIGHTER")) }
	end
	local function describe(s)
		return string.format("level %d, features for %d, proficiency +%d, max HP %d, subclass %s", s.level, s.applied, s.prof, s.maxhp, s.subclass)
	end
	if d == nil then
		d = { stage = "setup", at = now }
		B24T.drain = d
		B24T.SetStatus("level drain and Restoration")
		B24T.featureStep = { class = { id = 2, name = "Fighter", keys = { "FIGHTER" } }, level = 5,
			subclass = pickIndex(B24LV.SUBCLASSES.FIGHTER.list, "CHAMPION") }
		setUp(p, B24T.featureStep)
	elseif d.stage == "setup" then
		settle(p, B24T.featureStep)
		if not ready(p, B24T.featureStep) and now - d.at < 300 then return end
		d.before = state()
		out("before the drain: " .. describe(d.before))
		B24.ApplyEffect(p, { ["effectID"] = 216, ["effectAmount"] = 2, ["durationType"] = 1 })
		d.stage, d.at = "drained", now
	elseif d.stage == "drained" and now - d.at > 60 then
		d.drained = state()
		out("after draining 2 levels: " .. describe(d.drained))
		conditionCheck("level drain lowers the level and its features", { level = d.drained.level == d.before.level - 2,
			features = d.drained.applied == d.drained.level, prof = d.drained.prof == B24.ProfBonus(d.drained.level),
			hp = d.drained.maxhp < d.before.maxhp, subclass = d.drained.subclass == d.before.subclass })
		B24.ApplyEffect(p, { ["effectID"] = 224, ["durationType"] = 1 })
		d.stage, d.at = "restored", now
	elseif d.stage == "restored" and now - d.at > 60 then
		local after = state()
		out("after Restoration: " .. describe(after))
		conditionCheck("Restoration brings the levels and features back", { level = after.level == d.before.level,
			features = after.applied == d.before.applied, prof = after.prof == d.before.prof, hp = after.maxhp == d.before.maxhp })
		d.stage = "done"
		B24T.phase = "report"
		B24T.reportAt = now
	end
end

-- The WildShape mode drives the choice popup itself (its ASI check): nothing else closes it then.
function B24T.ChoiceDriven()
	return B24T.wildShape ~= nil and B24T.wildShape.asiStage ~= nil
end

-- TurnPlay: a turn-based fight to play by hand. The protagonist becomes a Fighter (Champion) or a
-- Wizard (Evoker) of level B24TEST_PLAYLEVEL (B24TEST_PLAYCLASS) with 2024 hit points for that
-- level, its main ability at least 16, the level's XP and a weapon; a Wizard also gets attack and
-- defense spells of the levels it can cast in its book. Companion copies (tools/ingame/companions.txt's
-- TurnPlay lines: Khalid and Kivan in BG:EE, Minsc in BG2:EE) join the party one by one and are
-- brought to the same level in their own class. The choices the levels bring (subclass, Fighting
-- Style, Weapon Mastery, Ability Score Improvements, ...) are taken for everyone through the choice
-- popup as a player would (turnPlayChoose). Turn-based combat goes on, and three enemies are
-- queued: a wizard, a fighter and a wolf (BG:EE: BPHBWZ1, ORC04, WOLF; BG2:EE: MAGE6A, DROW02,
-- WOLF01). When round 2 starts, a gnoll comes as a reinforcement (it joins the order from the
-- next round). A Fighter meets the enemies at once; a Wizard first memorizes its spells and rests,
-- and they appear when it wakes. Then the game is handed to the player (HANDOVER), as in
-- WildShape; the mod's combat messages (B24.Log) also go to the log file (b24debug.log, [B24LOG]).
local TURNPLAY_SPELLS = {
	{ "SPWI112", 1 }, { "SPWI118", 1 }, { "SPWI114", 1 }, { "SPWI116", 1 }, { "SPWI211", 2 },
	{ "SPWI212", 2 }, { "SPWI304", 3 }, { "SPWI308", 3 }, { "SPWI408", 4 }, { "SPWI502", 5 },
}

-- The ability an Ability Score Improvement raises, by class.
local TURNPLAY_MAIN = { FIGHTER = "STR", BARBARIAN = "STR", RANGER = "DEX", ROGUE = "DEX", WIZARD = "INT", CLERIC = "WIS", DRUID = "WIS" }
local ASI_ROWS = { STR = 1, DEX = 2, CON = 3, INT = 4, WIS = 5, CHA = 6 }

local function turnPlayEnemies(p)
	local bg1 = B24TEST_GAME == "BG:EE"
	queue(p, string.format('CreateCreatureObjectOffset("%s",Myself,[420.0]) CreateCreatureObjectOffset("%s",Myself,[380.0]) '
		.. 'CreateCreatureObjectOffset("%s",Myself,[340.0])', bg1 and "BPHBWZ1" or "MAGE6A", bg1 and "ORC04" or "DROW02",
		bg1 and "WOLF" or "WOLF01"))
end

-- Another enemy engages: a gnoll appears in sight at the start of round 2 (B24TB.TurnStartListeners;
-- once per game session).
local function turnPlayReinforcement(p)
	local id = p.m_id
	table.insert(B24TB.TurnStartListeners, function()
		if B24T.turnPlayReinforced or B24TB.round < 2 then return end
		local protagonist = B24.GetSprite(id)
		if protagonist == nil then return end
		B24T.turnPlayReinforced = true
		-- At once: the protagonist may be frozen (another creature's turn), its queue would wait.
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format('CreateCreatureObjectOffset("%s",Myself,[300.0])',
			B24TEST_GAME == "BG:EE" and "GNOLL" or "GNOLL01"), protagonist)
		B24.Log("Turn-based test: a gnoll joins the fight")
	end)
end

-- The mod's combat messages go to the log file too, so a playtest can be read afterwards.
local function turnPlayLogToFile()
	if B24T.logMirrored then return end
	B24T.logMirrored = true
	B24.Config.verboseLog = true
	local original = B24.Log
	function B24.Log(text)
		print(string.format("[B24LOG] %d %s", B24.GameTick(), tostring(text)))
		return original(text)
	end
end
B24T.MirrorLog = turnPlayLogToFile

-- 2024 hit points for the level (the hit die at level 1, its average rounded up per level after,
-- the Constitution modifier per level) and the level's XP; returns the hit points.
local function turnPlayLevelStats(s, level, classKey)
	local b = s.m_baseStats
	local die = B24.HitDie(s)
	local hp = die + (math.floor(die / 2) + 1) * (level - 1) + B24.AbilityMod(b.m_CONBase) * level
	b.m_maxHitPointsBase, b.m_hitPoints = hp, hp
	local xpRow = B24.LoadTable("XPLEVEL")[B24MC.XP_ROW[classKey] or "FIGHTER"]
	local xp = xpRow and tonumber(xpRow[tostring(level)])
	if xp then b.m_xp = xp end
	-- Removing an effect makes the engine recompute the stats from the new base values.
	B24.ApplyEffect(s, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60, ["m_sourceRes"] = "B24TREF" })
	B24.RemoveEffectsBySource(s, "B24TREF")
	return hp
end

-- One pending choice of the creature through its popup: the first row, the improvement as +2 to
-- the main ability (another ability if that is at 20). A choice still pending after three tries
-- is left to the player. Returns true when nothing is pending (or only skipped choices).
local function turnPlayChoose(s, main, tries)
	local pending = B24LV.Pending(s)
	local kind
	for _, k in ipairs(B24LV.CHOICE_ORDER) do
		if pending[k] > 0 and not tries.skipped[k] then kind = k break end
	end
	if kind == nil then return true end
	local key = kind .. pending[kind]
	tries[key] = (tries[key] or 0) + 1
	if tries[key] > 3 then
		tries.skipped[kind] = true
		out(string.format("%s: %s still pending after three tries, left to the player", B24.Name(s), B24LV.CHOICE_TITLES[kind]))
		return false
	end
	B24T.allowPopup = true
	_G[B24LV.CHOICE_SPELLS[kind]](nil, s)
	B24T.allowPopup = false
	if kind == "ASI" then
		if B24LV.ROWS[1] and B24LV.ROWS[1].asiChoice then B24LV_RowClick(1) end
		for _, ability in ipairs({ main, "CON", "DEX", "STR", "WIS", "INT", "CHA" }) do
			if B24LV_Ready() then break end
			B24LV_RowClick(ASI_ROWS[ability])
			B24LV_RowClick(ASI_ROWS[ability])
		end
	else
		B24LV_RowClick(1)
	end
	local title = B24LV_Choice()
	if B24LV_Ready() then
		B24LV_Done()
		out(string.format("%s: %s chosen", B24.Name(s), title))
	else
		B24LV_Cancel()
		out(string.format("%s: %s offered nothing to choose", B24.Name(s), title))
	end
	return false
end

function B24T.TurnPlayTick(p, now)
	local w = B24T.turnPlay
	if w == nil then
		local wizard = B24TEST_PLAYCLASS == "WIZARD"
		local level = B24TEST_PLAYLEVEL or 5
		local class = wizard and { id = 1, name = "Wizard", keys = { "WIZARD" } } or { id = 2, name = "Fighter", keys = { "FIGHTER" } }
		local subclasses = B24LV.SUBCLASSES[wizard and "WIZARD" or "FIGHTER"].list
		w = { wizard = wizard, level = level, started = now, stage = "self", at = now, members = {},
			step = { class = class, level = level, subclass = pickIndex(subclasses, wizard and "EVOKER" or "CHAMPION") } }
		B24T.turnPlay = w
		setUp(p, w.step)
		B24T.SetStatus(string.format("making a %s %d", class.name, level))
		return
	end
	if w.handedOver or now < w.at then return end
	local function fail(text)
		out("FAIL " .. text)
		B24T.failed = B24T.failed + 1
		B24T.Finish()
		w.handedOver = true
	end
	-- The companion being brought in (w.ci: its place in the TurnPlay list).
	local entry = companionList()[w.ci or 0]
	local member = w.members[#w.members]
	if w.stage == "self" then
		settle(p, w.step)
		if not ready(p, w.step) then
			if now - w.started > 600 then fail(string.format("the %s %d was not ready after 40 seconds", w.step.class.name, w.level)) end
			return
		end
		local b = p.m_baseStats
		if w.wizard then b.m_INTBase = math.max(b.m_INTBase, 16) else b.m_STRBase = math.max(b.m_STRBase, 16) end
		b.m_CONBase = math.max(b.m_CONBase, 14)
		w.hp = turnPlayLevelStats(p, w.level, w.wizard and "WIZARD" or "FIGHTER")
		queue(p, string.format('CreateItem("%s",0,0,0) EquipMostDamagingMelee()', w.wizard and "STAF01" or "SW1H01"))
		w.spells = {}
		if w.wizard then
			local castable = B24SP and B24SP.MageSlotLevel(p) or 1
			for _, spell in ipairs(TURNPLAY_SPELLS) do
				if spell[2] <= castable then
					B24.ApplyEffect(p, { ["effectID"] = 147, ["res"] = spell[1] })
					table.insert(w.spells, spell[1])
				end
			end
		end
		w.ci, w.stage = 0, "next"
	elseif w.stage == "next" then
		-- The next companion of the list, or the choices once all are in.
		w.ci = w.ci + 1
		entry = companionList()[w.ci]
		if entry == nil then
			w.stage = "choices"
			return
		end
		B24T.SetStatus(entry.original .. " joins")
		queue(p, string.format('CreateCreatureObjectOffset("%s",Myself,[%d.0])', entry.copy, 80 + 40 * w.ci))
		w.stage, w.since = "spawned", now
	elseif w.stage == "spawned" then
		local c = findSpawn(p, entry.copy)
		if c == nil then
			if now - w.since > 60 then fail("companion " .. entry.original .. " not created") end
			return
		end
		c:setLocalInt("B24TSEEN", 1)
		table.insert(w.members, { id = c.m_id })
		w.since = now
		queue(c, "JoinParty()")
		w.stage = "joining"
	elseif w.stage == "joining" then
		local c = B24.GetSprite(member.id)
		if c == nil then return fail("companion " .. entry.original .. " gone") end
		-- Converted by the runtime once in the party; then a moment for the conversion to finish.
		if not (B24.InParty(c) and c:getLocalInt("B24NPCFIT") == 1) then
			if now - w.since > 300 then fail("companion " .. entry.original .. " not converted on joining") end
			return
		end
		if not member.convertedAt then member.convertedAt = now return end
		if now - member.convertedAt < 45 then return end
		local key = B24.SkillClass(c) or "FIGHTER"
		if B24MC.IsMulti(c) then
			out(string.format("%s is multiclass: keeps its levels", B24.Name(c)))
			w.stage = "next"
			return
		end
		member.step = { class = { id = B24.ClassID(c), name = B24MC.NAME[key] or key, keys = { key },
			barbarian = key == "BARBARIAN" or nil }, level = w.level, subclass = 0 }
		setUp(c, member.step)
		w.stage, w.since = "companion", now
	elseif w.stage == "companion" then
		local c = B24.GetSprite(member.id)
		if c == nil then return fail("companion " .. entry.original .. " gone") end
		settle(c, member.step)
		if not ready(c, member.step) then
			if now - w.since > 600 then fail(string.format("companion %s %d not ready after 40 seconds", member.step.class.name, w.level)) end
			return
		end
		turnPlayLevelStats(c, w.level, member.step.class.keys[1])
		w.stage = "next"
	elseif w.stage == "choices" then
		-- One choice every half second, the protagonist's first, then each companion's.
		w.at = now + 8
		w.chooser = w.chooser or 0
		local s, main
		if w.chooser == 0 then
			s, main = p, w.wizard and "INT" or "STR"
		else
			local m = w.members[w.chooser]
			s = m and B24.GetSprite(m.id)
			if m and s == nil then w.chooser = w.chooser + 1 return end
			main = s and (TURNPLAY_MAIN[B24.SkillClass(s) or ""] or "CON")
		end
		if s == nil then
			w.stage = "fight"
			return
		end
		w.tries = w.tries or {}
		w.tries[s.m_id] = w.tries[s.m_id] or { skipped = {} }
		if turnPlayChoose(s, main, w.tries[s.m_id]) then w.chooser = w.chooser + 1 end
	elseif w.stage == "fight" then
		if not B24TB.Enabled() then B24TURNS(nil, p) end
		turnPlayLogToFile()
		turnPlayReinforcement(p)
		if w.wizard then
			-- The enemies come when the Wizard wakes from its rest (spells memorized by then).
			local id = p.m_id
			B24T.turnPlaySpawn = true
			B24.AddLongRestListener(function(sprite)
				if B24T.turnPlaySpawn and sprite.m_id == id then
					B24T.turnPlaySpawn = nil
					turnPlayEnemies(sprite)
					B24.Log("Turn-based test: enemies are coming")
				end
			end)
		else
			turnPlayEnemies(p)
		end
		local partners = {}
		for _, m in ipairs(w.members) do
			local c = B24.GetSprite(m.id)
			if c then
				table.insert(partners, string.format("%s %s %d, %d hit points", B24.Name(c), m.step and m.step.class.name or "",
					B24.Level(c), c.m_baseStats.m_maxHitPointsBase))
			end
		end
		local aiOk, partyAI = pcall(function() return _G.game:GetPartyAI() end)
		out(string.format("party AI %s", aiOk and tostring(partyAI) or ("unknown: " .. tostring(partyAI))))
		out(string.format("HANDOVER %s: %s %d, %d hit points, turn-based %s; spells in the book: %s; companions: %s; "
			.. "enemies: wizard, fighter, wolf, a gnoll in round 2%s", B24.Name(p), w.step.class.name, w.level, w.hp,
			tostring(B24TB.Enabled()), #w.spells > 0 and table.concat(w.spells, " ") or "none",
			#partners > 0 and table.concat(partners, "; ") or "none", w.wizard and " (after a rest)" or ""))
		B24T.SetStatus(w.wizard and "Turn-based test: memorize your spells and rest; the enemies come when you wake"
			or "Turn-based test: your turn (the test script has ended)")
		w.handedOver = true
		B24T.Finish()
	end
end

-- Petrify (BG:EE): a lesser basilisk (BASILL) in a turn-based fight with the protagonist and a
-- companion (PetrifyBGEE in companions.txt). Checks:
--   - the basilisk takes its turns in the order;
--   - a party member who panics (op24 at its turn's start) has its turn played by the game: it
--     ends without End Turn (B24TURN.lua, playerControls);
--   - the companion turned to stone (the basilisk's gaze within a few rounds, otherwise op134 by
--     the test, said so) leaves the order, and the turns go on without it.
-- The protagonist can't be petrified (op101 against op134: a party of one statue ends the game),
-- and everyone keeps at least a few hit points. Party members' turns are passed with End Turn,
-- as a player waiting for the basilisk would, except the panicking one's.
B24T.PETRIFY_GAZE_TICKS = 1500
B24T.PETRIFY_PANIC_TICKS = B24TB.TURN_TICKS + 90

local function petrified(sprite) return B24.GState_Has(sprite, B24.GState.STONE_DEATH) end

local function inOrder(id)
	for _, entry in ipairs(B24TB.order or {}) do
		if entry.id == id then return true end
	end
	return false
end

function B24T.PetrifyTick(p, now)
	local w = B24T.petrify
	if w == nil then
		w = { stage = "spawn", since = now, turns = {} }
		B24T.petrify = w
		B24.ApplyEffect(p, { ["effectID"] = 208, ["effectAmount"] = 8, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		B24.ApplyEffect(p, { ["effectID"] = 101, ["dwFlags"] = 134, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		turnPlayLogToFile()
		-- Every turn as it starts: whose, when; the panic goes on at the companion's turn.
		table.insert(B24TB.TurnStartListeners, function(sprite)
			table.insert(w.turns, { id = sprite.m_id, tick = B24.GameTick(), round = B24TB.round })
			if w.panicArmed and sprite.m_id == w.companion then
				w.panicArmed = nil
				B24.ApplyEffect(sprite, { ["effectID"] = 24, ["durationType"] = 0, ["duration"] = 12, ["m_sourceRes"] = "B24TPAN" })
				-- The turn itself starts after the listeners (B24TB.turn is set on the next tick).
				w.panicAt = B24.GameTick()
			end
		end)
		return
	end
	if w.done or now < (w.at or 0) then return end
	local function finish()
		w.done = true
		pcall(EEex_GameState_SetGlobalInt, "B24_TURNS", 0)
		B24T.phase = "report"
		B24T.reportAt = now
	end
	local function fail(text)
		out("FAIL " .. text)
		B24T.failed = B24T.failed + 1
		finish()
	end
	local entry = companionList()[1]
	local c = w.companion and B24.GetSprite(w.companion)
	local basilisk = w.basilisk and B24.GetSprite(w.basilisk)
	-- A party member's turn that the test doesn't watch: passed after a moment.
	local turn = B24TB.turn
	if w.panicAt and not w.panicTurn and turn and turn.id == w.companion and turn.start >= w.panicAt then w.panicTurn = turn end
	local watched = turn ~= nil and (turn == w.panicTurn or (w.panicAt and not w.panicTurn and turn.id == w.companion))
	if turn and B24TB.active and not watched and B24.GetSprite(turn.id) and B24.InParty(B24.GetSprite(turn.id))
		and now - turn.start > 20 and not turn.endRequested then
		B24TEND(nil, B24.GetSprite(turn.id))
	end
	if w.stage == "spawn" then
		if entry == nil then return fail("no companion in the PetrifyBGEE list") end
		queue(p, string.format('CreateCreatureObjectOffset("%s",Myself,[80.0])', entry.copy))
		w.stage, w.since = "spawned", now
	elseif w.stage == "spawned" then
		local s = findSpawn(p, entry.copy)
		if s == nil then
			if now - w.since > 60 then fail("companion " .. entry.original .. " not created") end
			return
		end
		s:setLocalInt("B24TSEEN", 1)
		w.companion = s.m_id
		queue(s, "JoinParty()")
		w.stage, w.since = "joining", now
	elseif w.stage == "joining" then
		if c == nil then return fail("companion gone") end
		if not (B24.InParty(c) and c:getLocalInt("B24NPCFIT") == 1) then
			if now - w.since > 300 then fail("companion " .. entry.original .. " not converted on joining") end
			return
		end
		B24.ApplyEffect(c, { ["effectID"] = 208, ["effectAmount"] = 8, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		EEex_GameState_SetGlobalInt("B24_TURNS", 1)
		queue(p, 'CreateCreatureObjectOffset("BASILL",Myself,[180.0])')
		w.stage, w.since, w.at = "basilisk", now, now + 45
	elseif w.stage == "basilisk" then
		local s = findSpawn(p, "BASILL")
		if s == nil then
			if now - w.since > 90 then fail("no basilisk created") end
			return
		end
		s:setLocalInt("B24TSEEN", 1)
		w.basilisk = s.m_id
		B24.ApplyEffect(s, { ["effectID"] = 208, ["effectAmount"] = 5, ["durationType"] = 9, ["m_sourceRes"] = "B24TEST" })
		queue(s, 'ChangeEnemyAlly(Myself,ENEMY)')
		w.stage, w.since = "combat", now
	elseif w.stage == "combat" then
		if not (B24TB.active and inOrder(w.basilisk) and inOrder(w.companion)) then
			if now - w.since > 150 then
				fail(string.format("combat in turns with the basilisk: active %s, order %d", tostring(B24TB.active), #(B24TB.order or {})))
			end
			return
		end
		conditionCheck("combat starts in turns with the basilisk", { three = #B24TB.order == 3 })
		w.panicArmed, w.stage, w.since = true, "panic", now
	elseif w.stage == "panic" then
		if w.panicTurn == nil then
			if now - w.since > 900 then fail("the companion's turn didn't come") end
			return
		end
		if B24TB.turn == w.panicTurn then
			if now - w.panicAt > B24T.PETRIFY_PANIC_TICKS then
				fail(string.format("a panicking party member's turn ends by itself: still on after %d ticks (action %d, panic %s)",
					now - w.panicAt, c and c.m_curAction.m_actionID or -1, tostring(c and B24.GState_Has(c, B24.GState.PANIC))))
			end
			return
		end
		out(string.format("panic turn: %d ticks, panic on %s", now - w.panicAt, tostring(c and B24.GState_Has(c, B24.GState.PANIC))))
		conditionCheck("a panicking party member's turn ends by itself", { passed = not w.panicTurn.endRequested })
		if c then B24.RemoveEffectsBySource(c, "B24TPAN") end
		w.panicTurn, w.stage, w.since = nil, "gaze", now
		w.basiliskTurns = 0
		for _, t in ipairs(w.turns) do if t.id == w.basilisk then w.basiliskTurns = w.basiliskTurns + 1 end end
	elseif w.stage == "gaze" then
		if c == nil or basilisk == nil then return fail("the companion or the basilisk is gone") end
		if not petrified(c) then
			if now - w.since < B24T.PETRIFY_GAZE_TICKS then return end
			out(string.format("the basilisk's gaze didn't petrify the companion in %d ticks: the test turns it to stone (op134)",
				B24T.PETRIFY_GAZE_TICKS))
			B24.ApplyEffect(c, { ["effectID"] = 134, ["durationType"] = 1 })
			w.forced = true
			w.at = now + 5
			return
		end
		if not w.stoneAt then
			w.stoneAt = now
			out(string.format("the companion is stone (%s) after %d ticks; basilisk turns so far %d", w.forced and "by the test" or "the basilisk's gaze",
				now - w.since, w.basiliskTurns))
		end
		if inOrder(w.companion) then
			if now - w.stoneAt > 30 then fail("a petrified party member leaves the order: still in it after 30 ticks") end
			return
		end
		conditionCheck("a petrified party member leaves the order", { gone = true })
		w.turnsAtStone, w.stage, w.since = #w.turns, "after", now
	elseif w.stage == "after" then
		-- Two rounds' worth of turns (protagonist and basilisk), none for the statue.
		if #w.turns - w.turnsAtStone < 4 then
			if now - w.since > 1200 then
				fail(string.format("the turns go on after the petrification: %d turns in %d ticks", #w.turns - w.turnsAtStone, now - w.since))
			end
			return
		end
		local statueTurns, basiliskTurns = 0, 0
		for i = w.turnsAtStone + 1, #w.turns do
			if w.turns[i].id == w.companion then statueTurns = statueTurns + 1 end
			if w.turns[i].id == w.basilisk then basiliskTurns = basiliskTurns + 1 end
		end
		local total = 0
		for _, t in ipairs(w.turns) do if t.id == w.basilisk then total = total + 1 end end
		conditionCheck("the turns go on without the statue", { noStatueTurn = statueTurns == 0, basilisk = basiliskTurns > 0 })
		conditionCheck("the basilisk takes its turns", { turns = total >= 2 })
		w.stage, w.since = "kill", now
	elseif w.stage == "kill" then
		-- The killing blow on the basilisk's own turn: out of its turn it stands frozen (Time Stop),
		-- and a frozen creature takes no damage until it moves again.
		local turn = B24TB.turn
		if not (turn and turn.id == w.basilisk) then
			if now - w.since > 600 then fail("combat ends with the basilisk: no basilisk turn in 600 ticks") end
			return
		end
		-- Its 5 hit point floor first: the removal (op321) takes a moment, damage in the same tick
		-- still met the floor.
		if not w.floorOffAt then
			B24.RemoveEffectsBySource(basilisk, "B24TEST")
			w.floorOffAt = now
			return
		end
		if now - w.floorOffAt < 5 then return end
		B24.ApplyEffect(basilisk, { ["effectID"] = 12, ["effectAmount"] = 500, ["dwFlags"] = 0, ["durationType"] = 1 })
		w.stage, w.since = "end", now
	elseif w.stage == "end" then
		if B24TB.active then
			if now - w.since > 300 then
				fail(string.format("combat ends with the basilisk: still on after 300 ticks (basilisk dead %s, %d hit points)",
					tostring(B24.GState_Has(basilisk, B24.GState.DEAD)), basilisk.m_baseStats.m_hitPoints))
			end
			return
		end
		conditionCheck("combat ends with the basilisk", { inactive = true })
		finish()
	end
end

-- WildShape: a Druid for trying Wild Shape by hand. The protagonist becomes a Druid of level
-- B24TEST_DRUIDLEVEL in B24TEST_CIRCLE (Land: temperate), with 2024 hit points for that level,
-- Wisdom at least 16, the level's XP and all Wild Shape uses; turn-based combat goes on with
-- B24TEST_TURNBASED. Then the pending Ability Score Improvements are taken through the choice popup
-- as a player would (the improvement, then a feat; screenshots, and the pending count after each),
-- three enemies appear, and the game is handed to the player: the test script ends without closing
-- it (HANDOVER), and the test module rests (the enemies keep their scripts, popups show again).
function B24T.WildShapeTick(p, now)
	local w = B24T.wildShape
	if w == nil then
		local level = B24TEST_DRUIDLEVEL or 8
		local circle = B24TEST_CIRCLE or "LAND"
		w = { level = level, circle = circle, started = now,
			step = { class = { id = 11, name = "Druid", keys = { "DRUID" } }, level = level,
				subclass = pickIndex(B24LV.SUBCLASSES.DRUID.list, circle) } }
		B24T.wildShape = w
		if circle == "LAND" then p:setLocalInt("B24LAND", pickIndex(B24DR.LANDS, "TEMPERATE")) end
		setUp(p, w.step)
		B24T.SetStatus(string.format("making a Druid %d (%s)", level, circle))
		return
	end
	if w.handedOver then return end
	settle(p, w.step)
	if not ready(p, w.step) then
		if now - w.started > 600 then
			out(string.format("FAIL the Druid %d was not ready after 40 seconds", w.level))
			B24T.failed = B24T.failed + 1
			B24T.Finish()
			w.handedOver = true
		end
		return
	end
	if not w.prepared then
		w.prepared = true
		local b = p.m_baseStats
		b.m_WISBase = math.max(b.m_WISBase, 16)
		-- 2024 Druid hit points: 8 at level 1, 5 per level after, the Constitution modifier per level.
		w.hp = 8 + 5 * (w.level - 1) + B24.AbilityMod(b.m_CONBase) * w.level
		b.m_maxHitPointsBase, b.m_hitPoints = w.hp, w.hp
		local xpRow = B24.LoadTable("XPLEVEL").DRUID
		local xp = xpRow and tonumber(xpRow[tostring(w.level)])
		if xp then b.m_xp = xp end
		p:setLocalInt("B24WSUSE", 0)
		B24LV.Rebuild(p, "WILD_SHAPE")
		-- Removing an effect makes the engine recompute the stats from the new base values.
		B24.ApplyEffect(p, { ["effectID"] = 0, ["effectAmount"] = 0, ["durationType"] = 0, ["duration"] = 60, ["m_sourceRes"] = "B24TREF" })
		B24.RemoveEffectsBySource(p, "B24TREF")
		if B24TEST_TURNBASED and not B24TB.Enabled() then B24TURNS(nil, p) end
		w.asiStage, w.asiAt = 0, Infinity_GetClockTicks()
		w.asiStart = { pending = B24LV.Pending(p).ASI, wis = B24.AbilityScore(p, "WIS"), done = p:getLocalInt("B24ASIDN") }
		out(string.format("ASI before: %d pending, B24ASIDN %d, Wisdom %d", w.asiStart.pending, w.asiStart.done, w.asiStart.wis))
		return
	end
	-- The Ability Score Improvement popup as a player uses it, a stage every 1.5 seconds (the game
	-- is paused while the popup is open, so the clock counts, not the game time).
	if w.asiStage ~= nil then
		if Infinity_GetClockTicks() - w.asiAt < 1500 then return end
		w.asiAt = Infinity_GetClockTicks()
		local stage = w.asiStage
		w.asiStage = stage + 1
		local function state(label)
			out(string.format("%s: popup %q, %d rows, row 1 %q, row 5 %q, ready %s, open %s; %d pending, B24ASIDN %d, feats %d",
				label, tostring(B24LV_Title and B24LV_Title()), #B24LV.ROWS, tostring(B24LV_RowName(1)), tostring(B24LV_RowName(5)),
				tostring(B24LV_Ready()), tostring(Infinity_IsMenuOnStack("B24_LEVELUP")), B24LV.Pending(p).ASI,
				p:getLocalInt("B24ASIDN"), p:getLocalInt("B24GFN")))
		end
		if stage == 0 then
			-- The improvement: +2 Wisdom.
			B24T.allowPopup = true
			B24ASI(nil, p)
			state("ASI opened")
			B24LV_RowClick(1)
			state("ASI row chosen")
			B24LV_RowClick(5)
			B24LV_RowClick(5)
			state("Wisdom +2")
			B24LV_Done()
			state("ASI done")
		elseif stage == 1 then
			-- A feat (the second row).
			B24T.allowPopup = true
			B24ASI(nil, p)
			state("feat list opened")
			B24LV_RowClick(2)
			state("feat chosen")
			B24LV_Done()
			state("feat done")
		else
			out(string.format("ASI end: %d pending (was %d), Wisdom %d (was %d)", B24LV.Pending(p).ASI, w.asiStart.pending,
				B24.AbilityScore(p, "WIS"), w.asiStart.wis))
			w.asiStage = nil
		end
		return
	end
	-- The enemies are queued now and appear after the test module has gone quiet, so they keep their
	-- scripts.
	local bg1 = B24TEST_GAME == "BG:EE"
	queue(p, string.format('CreateCreatureObjectOffset("%s",Myself,[300.0]) CreateCreatureObjectOffset("%s",Myself,[340.0]) '
		.. 'CreateCreatureObjectOffset("%s",Myself,[380.0])', bg1 and "WOLF" or "WOLF01", bg1 and "GNOLL" or "GNOLL01",
		bg1 and "OGRE" or "OGRE01"))
	out(string.format("HANDOVER %s: Druid %d (%s), %d hit points, Wild Shape uses %d, form tier %d, turn-based %s; enemies: wolf, gnoll, ogre",
		B24.Name(p), w.level, w.circle, w.hp, B24LV.Remaining(p, "WILD_SHAPE"), B24DR.FormTier(p), tostring(B24TB.Enabled())))
	-- The innate bar's first entries (Wild Shape should lead).
	B24.InnatesFirst(p, { "B24WSHAP", B24DR.NATURAL_FORM })
	local known, memorized = {}, {}
	EEex_Utility_IterateCPtrList(B24.InnateList(p.m_knownSpellsInnate), function(spell)
		if #known < 4 then table.insert(known, spell.m_knownSpellId:get()) end
	end)
	EEex_Utility_IterateCPtrList(B24.InnateList(p.m_memorizedSpellsInnate), function(spell)
		if #memorized < 4 then table.insert(memorized, spell.m_spellId:get()) end
	end)
	out(string.format("innates first: known %s; memorized %s", table.concat(known, " "), table.concat(memorized, " ")))
	B24T.SetStatus("Wild Shape test: your turn (the test script has ended)")
	w.handedOver = true
	B24T.Finish()
end

-- Slayer: BG2's Slayer change (SPIN823: the form, its claws SLAYERW3, damage from 20 seconds on) and
-- back (SPIN718A) on the protagonist; the mod's numbers before, in the form and after, and the form
-- undone completely.
function B24T.SlayerTick(p, now)
	local s = B24T.slayer
	local function state()
		local weapon = p.m_equipment.m_items:get(p.m_equipment.m_selectedWeapon)
		local weaponName = "none"
		if weapon then
			local ok, res = pcall(function() return weapon.pRes.resref:get() end)
			if not ok then ok, res = pcall(function() return weapon.pRes.cResRef:get() end) end
			weaponName = ok and tostring(res):upper() or ("type " .. weapon.pRes.pHeader.itemType)
		end
		return { class = B24.ClassID(p), level = B24.Level(p), prof = B24.ProfOf(p), ac = B24UI.ToAC(p:getStat(B24.Stat.AC)),
			maxhp = p:getStat(B24.Stat.MAXHP), str = p:getStat(B24.Stat.STR), size = B24.Size(p),
			weapon = weaponName, anim = select(2, pcall(function() return p.m_animation.m_animation.m_animationID end)) }
	end
	local function describe(t)
		return string.format("class %d, level %d, proficiency +%d, 2024 AC %d, max HP %d, STR %d, size %d, weapon %s, animation %s",
			t.class, t.level, t.prof, t.ac, t.maxhp, t.str, t.size, t.weapon, tostring(t.anim))
	end
	local function cast(res)
		EEex_LuaObject = p
		EEex_Action_ExecuteResponseStringOnAIBaseInstantly(string.format('ApplySpellRES("%s",EEex_LuaObject)', res), p)
	end
	if s == nil then
		s = { stage = "before", at = now }
		B24T.slayer = s
		B24T.SetStatus("Slayer change and back")
	elseif s.stage == "before" and now - s.at > 30 then
		s.before = state()
		out("before: " .. describe(s.before))
		cast("SPIN823")
		s.stage, s.at = "form", now
	elseif s.stage == "form" and now - s.at > 60 then
		s.form = state()
		out("as the Slayer: " .. describe(s.form))
		conditionCheck("Slayer change takes effect", { changed = s.form.anim ~= s.before.anim or s.form.weapon ~= s.before.weapon,
			ac = s.form.ac <= 22, large = s.form.size >= B24.SIZE.LARGE,
			level = s.form.level == s.before.level, alive = not B24.GState_Has(p, B24.GState.DEAD) })
		-- SPIN822 only starts the protagonist's dialogue that reverts the form (the test silences
		-- dialogues); the scripts end it with SPIN718A (End Slayer Change).
		cast("SPIN718A")
		s.stage, s.at = "back", now
	elseif s.stage == "back" and now - s.at > 75 then
		local after = state()
		out("changed back: " .. describe(after))
		conditionCheck("changing back restores the character", { class = after.class == s.before.class, level = after.level == s.before.level,
			prof = after.prof == s.before.prof, ac = after.ac == s.before.ac, maxhp = after.maxhp == s.before.maxhp,
			str = after.str == s.before.str, anim = after.anim == s.before.anim })
		s.stage = "done"
		B24T.phase = "report"
		B24T.reportAt = now
	end
end
