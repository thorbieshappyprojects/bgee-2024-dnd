-- BG 2024 Rules Mod: entry point. The engine loads every M_*.lua from override at startup.

if not EEex_Active then
	print("[BG2024] EEex is not active; the core rules need EEex. Start the game with InfinityLoader.exe.")
	return
end

-- The UI can be reloaded; listeners must only be registered once.
if B24_Loaded then return end
B24_Loaded = true

for _, file in ipairs({ "B24STATE", "B24CORE", "B24SAVE", "B24PROF", "B24ADV", "B24CONC", "B24REST", "B24WPN", "B24ROUND", "B24COND", "B24DYING", "B24TURN", "B24MULTI", "B24UI", "B24OPT" }) do
	Infinity_DoFile(file)
end

-- The turn-based combat switch on the game screen (B24TURN.menu). Also runs after an F5 UI reload,
-- which drops menus that were not in UI.MENU.
EEex_Menu_AddAfterMainFileLoadedListener(function()
	EEex_Menu_LoadFile("B24TURN")
end)

-- Character creation (component 3) adds feats and species traits once both parts are loaded; see M_B24CG.lua.
if B24CG_Loaded then
	Infinity_DoFile("B24FEAT")
	Infinity_DoFile("B24SPEC")
end

-- Class components that loaded before the core rules.
for _, load in ipairs(B24_PendingModules or {}) do EEex_Utility_TryIgnore(load) end
B24_PendingModules = nil

print(string.format("[BG2024] runtime loaded: %s", B24 and B24.Concentration and B24SREST and "ok" or "INCOMPLETE"))
