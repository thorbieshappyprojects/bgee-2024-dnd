-- BG 2024 Rules Mod: class component entry point. Its scripts need the core rules (M_B24.lua),
-- which may load before or after this file.

if not EEex_Active then return end

if B24FI_Loaded then return end
B24FI_Loaded = true

local function load()
	Infinity_DoFile("B24LEVEL")
	Infinity_DoFile("B24FIGHT")
	Infinity_DoFile("B24BARB")
	Infinity_DoFile("B24ROGUE")
	Infinity_DoFile("B24MONK")
	Infinity_DoFile("B24PALA")
	Infinity_DoFile("B24RANGR")
	Infinity_DoFile("B24BARD")
	Infinity_DoFile("B24CLER")
	Infinity_DoFile("B24DRUID")
	Infinity_DoFile("B24SORC")
	Infinity_DoFile("B24WIZ")
	Infinity_DoFile("B24GFEAT")
	-- Subclasses beyond the SRD.
	for _, file in ipairs({ "B24XCOM", "B24XFIG", "B24XBAR", "B24XBRD", "B24XCLR", "B24XDRU", "B24XMNK", "B24XPAL", "B24XRNG", "B24XROG", "B24XSOR", "B24XWIZ" }) do
		Infinity_DoFile(file)
	end
	-- Companions joining the party (after all subclasses are known).
	Infinity_DoFile("B24NPC")
	-- The Spells component hooks into the class features once both are loaded.
	if B24SP and B24SP.AttachClasses then B24SP.AttachClasses() end
end

if B24 and B24.Concentration and B24WPN then
	load()
else
	B24_PendingModules = B24_PendingModules or {}
	table.insert(B24_PendingModules, load)
end

-- Also runs after an F5 UI reload, which drops menus that were not in UI.MENU.
EEex_Menu_AddAfterMainFileLoadedListener(function()
	EEex_Menu_LoadFile("B24LEVEL")
end)
