-- BG 2024 Rules Mod: character creation entry point (component 3). Loaded by the engine before UI.MENU.

if not EEex_Active then return end

if B24CG_Loaded then return end
B24CG_Loaded = true

Infinity_DoFile("B24CHGEN")

-- B24FEAT and B24SPEC need the core rules; whichever of M_B24 and M_B24CG loads second loads them.
if B24_Loaded then
	Infinity_DoFile("B24FEAT")
	Infinity_DoFile("B24SPEC")
end

-- Also runs after an F5 UI reload, which drops menus that were not in UI.MENU.
EEex_Menu_AddAfterMainFileLoadedListener(function()
	EEex_Menu_LoadFile("B24CHGEN")
end)
