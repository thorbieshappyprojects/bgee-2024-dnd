-- BG 2024 Rules Mod: Spells component entry point. Its script needs the core rules (M_B24.lua),
-- which may load before or after this file; it hooks into the class component by itself
-- whichever loads first (B24SP.AttachClasses).

if not EEex_Active then return end

if B24SP_Loaded then return end
B24SP_Loaded = true

local function load()
	Infinity_DoFile("B24SPELL")
end

if B24 and B24.Concentration and B24WPN then
	load()
else
	B24_PendingModules = B24_PendingModules or {}
	table.insert(B24_PendingModules, load)
end
