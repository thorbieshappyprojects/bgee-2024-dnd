-- BG 2024 Rules Mod: the mod's settings in the game's options (EEex's options menu, a "BG 2024
-- Rules" tab). Each option reads and writes a B24.Config value, so the rules see a change at once;
-- the values are kept in Baldur.lua (section "BG 2024 Rules") and come back at the next start.

if EEex_Options_Register == nil or EEex_Options_AddTab == nil then return end

B24OPT = {}

-- Inner accessor of an EEex_Options_ClampedAccessor: the option's value is the B24.Config value.
-- Switches are 1/0 in the options (false in B24.Config is off, anything else on); numbers can be
-- shown in other units (toOption/fromOption).
local ConfigAccessor = {}
ConfigAccessor.__index = ConfigAccessor
setmetatable(ConfigAccessor, EEex_Options_Accessor)

function ConfigAccessor.new(o)
	setmetatable(o, ConfigAccessor)
	o:_init()
	return o
end

function ConfigAccessor:get()
	local value = B24.Config[self.key]
	if self.switch then return value == false and 0 or 1 end
	return self.toOption and self.toOption(value) or value
end

function ConfigAccessor:set(option, value)
	if self.switch then
		B24.Config[self.key] = value ~= 0
	else
		B24.Config[self.key] = self.fromOption and self.fromOption(value) or value
	end
	return value
end

local STRING_PREFIX = "B24OPT_"
local texts = {}

-- Option texts: the options menu looks its labels up in uiStrings.
local function addTexts()
	if uiStrings == nil then return end
	for key, text in pairs(texts) do uiStrings[key] = text end
end

local entries = {}

-- def: key (B24.Config), label, description, switch or min/max (with maxCharacters), and
-- toOption/fromOption for a number shown in other units.
local function option(def)
	local id = "B24_" .. def.key
	local current = B24.Config[def.key]
	local default
	if def.switch then
		default = current == false and 0 or 1
		if def.defaultOff and current == nil then default = 0 end
	else
		default = def.toOption and def.toOption(current) or current
	end
	-- An unset switch that is off by default: false in B24.Config, so the rules read it as off.
	if def.switch and current == nil then B24.Config[def.key] = default == 1 end
	local inner = ConfigAccessor.new({ key = def.key, switch = def.switch, toOption = def.toOption, fromOption = def.fromOption })
	EEex_Options_Register(id, EEex_Options_Option.new({
		["default"] = default,
		["type"] = def.switch and EEex_Options_ToggleType.new() or EEex_Options_EditType.new(),
		["accessor"] = EEex_Options_ClampedAccessor.new({ ["accessor"] = inner,
			["min"] = def.switch and 0 or def.min, ["max"] = def.switch and 1 or def.max }),
		["storage"] = EEex_Options_NumberLuaStorage.new({ ["section"] = "BG 2024 Rules", ["key"] = def.key }),
		["onChange"] = def.onChange,
	}))
	local label, description = STRING_PREFIX .. def.key, STRING_PREFIX .. def.key .. "_Description"
	texts[label], texts[description] = def.label, def.description
	table.insert(entries, EEex_Options_DisplayEntry.new({
		["optionID"] = id,
		["label"] = label,
		["description"] = description,
		["widget"] = def.switch and EEex_Options_ToggleWidget.new()
			or EEex_Options_EditWidget.new({ ["maxCharacters"] = def.maxCharacters or 2, ["number"] = true }),
	}))
end

local function feet(units) return math.floor((units - 16) / B24.FOOT + 0.5) end

option({ key = "turnBased", switch = true, label = "Turn-Based Combat",
	description = "Offers turn-based combat: the switch on the game screen while enemies are in sight. Off: real-time combat only, the switch is gone.",
	onChange = function(self) if self:get() == 0 and B24TB then EEex_Utility_TryIgnore(function() B24TB.Stop("turn-based combat switched off in the options", true) end) end end })
option({ key = "alwaysTurnBased", switch = true, defaultOff = true, label = "Always Start Turn-Based",
	description = "Every fight starts turn-based: when enemies come into sight, the mode switches to turn-based by itself. The switch on the game screen still goes back to real time for the rest of that fight." })
option({ key = "reactionPrompts", switch = true, label = "Ask for Reactions",
	description = "Turn-based combat: asks before a party member uses its reaction (Opportunity Attack, Shield, Uncanny Dodge). Off: the reaction is always used." })
option({ key = "roundPause", switch = true, label = "Pause Every Round",
	description = "Real-time combat: the game pauses when a fight starts and at the start of every 6-second round, so each character can be given its action." })
option({ key = "moveLimit", switch = true, label = "Movement Limit",
	description = "Real-time combat: a character can move only for a part of each round (about 30 feet), as in a 2024 turn." })
option({ key = "moveSecondsPerRound", min = 1, max = 6, maxCharacters = 1, label = "Movement Seconds per Round",
	description = "Real-time combat with the movement limit: seconds of walking a character has each round (3 is about 30 feet)." })
option({ key = "rangedInMelee2024", switch = true, label = "2024 Ranged Attacks in Melee",
	description = "Ranged attacks have disadvantage while an enemy is within 5 feet (Sharpshooter and Crossbow Expert ignore it). Off: the game's own penalty for shooting at an adjacent target." })
option({ key = "shortRestsPerLongRest", min = 0, max = 9, maxCharacters = 1, label = "Short Rests per Long Rest",
	description = "How many short rests the party can take between two long rests." })
option({ key = "shortRestEnemyRange", min = 0, max = 200, maxCharacters = 3, label = "Short Rest: Enemy Distance (feet)",
	description = "A short rest is refused while an enemy is within this many feet of the resting character.",
	toOption = feet, fromOption = B24.Feet })
option({ key = "exhaustionSpeedPercent", min = 0, max = 50, label = "Exhaustion: Speed Lost per Level (%)",
	description = "Movement speed lost per exhaustion level, in percent (2024: 5 of 30 feet, about 17)." })
option({ key = "verboseLog", switch = true, label = "Detailed Messages",
	description = "Prints saving throws, concentration checks and rest results to the message log." })

addTexts()
EEex_Menu_AddMainFileLoadedListener(addTexts)
texts.B24OPT_Tab = "BG 2024 Rules"
addTexts()
EEex_Options_AddTab("B24OPT_Tab", function() return { entries } end)
