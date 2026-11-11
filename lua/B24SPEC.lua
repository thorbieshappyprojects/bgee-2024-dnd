-- BG 2024 Rules Mod: species (component 3).
--
-- The ten 2024 species. Each uses one of the engine's races as its body (animations, engine
-- racial behavior); the species itself and its lineage are stored in creature locals by
-- character creation:
--   B24SPC    species id (B24SPEC.SPECIES index)     B24LIN    lineage id (index into its lineages)
--   B24SPSET  version of the species setup that has been applied
--   B24RELUS  1 once Relentless Endurance has been used since the last long rest
-- Creatures without B24SPC (companions, older saves) get the species of their engine race;
-- half-elves count as elves and half-orcs as orcs.
--
-- Spells granted by species or lineages (cantrips, level 3/5 spells) follow with the spell phases.
--
-- Loaded after B24CORE and B24SAVE (see M_B24CG.lua).

B24SPEC = {}

B24SPEC.SETUP_VERSION = 3
B24SPEC.SOURCE_RES = "B24SPEC"
B24SPEC.RELENTLESS_RES = "B24RELEN"
B24SPEC.ADRENALINE_RES = "B24ADREN"
B24SPEC.GIANT_INTERVAL = 90 -- one round (15 ticks per second)

-- Engine races (RACE.IDS) used as bodies.
local R_HUMAN, R_ELF, R_DWARF, R_HALFLING, R_GNOME, R_HALF_ORC = 1, 2, 4, 5, 6, 7

-- Damage types: op12 damage type, resistance opcode, breath weapon spell.
B24SPEC.DAMAGE = {
	ACID      = { name = "acid",      op12 = 0x10000,  resist = 27,  breath = "B24BRACI" },
	COLD      = { name = "cold",      op12 = 0x20000,  resist = 28,  breath = "B24BRCOL" },
	LIGHTNING = { name = "lightning", op12 = 0x40000,  resist = 29,  breath = "B24BRELE" },
	FIRE      = { name = "fire",      op12 = 0x80000,  resist = 30,  breath = "B24BRFIR" },
	POISON    = { name = "poison",    op12 = 0x200000, resist = 173, breath = "B24BRPOI" },
	-- Radiant and necrotic have no BG damage type; they map to magic damage.
	MAGIC     = { name = "magic",     op12 = 0x400000, resist = 31 },
}

B24SPEC.SPECIES = {
	{ key = "AASIMAR", name = "Aasimar", body = R_HUMAN,
	  desc = "AASIMAR: Aasimar carry a spark of the Upper Planes in their souls. Celestial light shines in their eyes, and their touch can heal.\n\nSpecies traits:\n– Celestial Resistance: resistance to necrotic and radiant damage (in BG: magic damage).\n– Darkvision (infravision).\n– Healing Hands: once per long rest, touch a creature and restore hit points equal to a number of d4 equal to your Proficiency Bonus.\n– Light Bearer: the Light cantrip (arrives with the spell updates).\n\nBody: human." },
	{ key = "DRAGONBORN", name = "Dragonborn", body = R_HALF_ORC,
	  lineageTitle = "Draconic Ancestry",
	  lineages = {
		{ key = "BLACK", name = "Black dragon (acid)", damage = "ACID" },
		{ key = "BLUE", name = "Blue dragon (lightning)", damage = "LIGHTNING" },
		{ key = "BRASS", name = "Brass dragon (fire)", damage = "FIRE" },
		{ key = "BRONZE", name = "Bronze dragon (lightning)", damage = "LIGHTNING" },
		{ key = "COPPER", name = "Copper dragon (acid)", damage = "ACID" },
		{ key = "GOLD", name = "Gold dragon (fire)", damage = "FIRE" },
		{ key = "GREEN", name = "Green dragon (poison)", damage = "POISON" },
		{ key = "RED", name = "Red dragon (fire)", damage = "FIRE" },
		{ key = "SILVER", name = "Silver dragon (cold)", damage = "COLD" },
		{ key = "WHITE", name = "White dragon (cold)", damage = "COLD" },
	  },
	  desc = "DRAGONBORN: The ancestors of the dragonborn hatched from the eggs of dragons. They are proud and draconic in form, and they breathe the element of their dragon ancestors.\n\nSpecies traits:\n– Draconic Ancestry: choose a dragon; it decides your breath weapon and resistance.\n– Breath Weapon: an innate cone of your ancestry's damage, 1d10 (2d10 at level 5, 3d10 at 11, 4d10 at 17), Dexterity save (DC 8 + Constitution modifier + Proficiency Bonus) for half. Usable twice per long rest.\n– Damage Resistance: resistance to your ancestry's damage type.\n– Darkvision (infravision).\n\nBody: half-orc." },
	{ key = "DWARF", name = "Dwarf", body = R_DWARF,
	  desc = "DWARF: Dwarves are a stout and hardy people, shaped by mountain halls and the stone they work. They are slow to trust and slower to forget, and as tough as the rock they live in.\n\nSpecies traits:\n– Darkvision (infravision).\n– Dwarven Resilience: resistance to poison damage and advantage on saving throws against poison.\n– Dwarven Toughness: +1 hit point per level." },
	{ key = "ELF", name = "Elf", body = R_ELF,
	  desc = "ELF: Elves are a magical people of otherworldly grace, living for centuries in harmony with the world around them. They rarely sleep, and their keen eyes miss little.\n\nSpecies traits:\n– Darkvision (infravision).\n– Fey Ancestry: advantage on saving throws against being charmed.\n– Keen Senses: proficiency in Perception.\n– Trance: magic can't put you to sleep.\n– Elven Lineage (drow, high elf, wood elf): arrives with the spell updates." },
	{ key = "GNOME", name = "Gnome", body = R_GNOME,
	  desc = "GNOME: Gnomes are small, curious and inventive, with an endless love for tinkering, illusions and riddles. Their quick minds are hard to fool.\n\nSpecies traits:\n– Darkvision (infravision).\n– Gnomish Cunning: advantage on Intelligence, Wisdom and Charisma saving throws.\n– Gnomish Lineage (forest, rock): arrives with the spell updates." },
	{ key = "GOLIATH", name = "Goliath", body = R_HALF_ORC, skin = 43, -- broad half-orc build, slate-grey skin (position in the skin list)
	  lineageTitle = "Giant Ancestry",
	  lineages = {
		{ key = "CLOUD", name = "Cloud's Jaunt", spell = "B24GLCLD",
		  desc = "Teleport a short distance to a spot you can see (as Dimension Door)." },
		{ key = "FIRE", name = "Fire's Burn", spell = "B24GLFIR",
		  desc = "Your next weapon hit this round deals an extra 1d10 fire damage." },
		{ key = "FROST", name = "Frost's Chill", spell = "B24GLFRO",
		  desc = "Your next weapon hit this round deals an extra 1d6 cold damage and slows the target for a round." },
		{ key = "HILL", name = "Hill's Tumble", spell = "B24GLHIL",
		  desc = "Your next weapon hit this round knocks the target prone for a round." },
		{ key = "STONE", name = "Stone's Endurance", spell = "B24GLSTO",
		  desc = "The next damage you take this round is reduced by 1d12 + your Constitution modifier." },
		{ key = "STORM", name = "Storm's Thunder", spell = "B24GLSTM",
		  desc = "The next creature that damages you this round takes 1d8 thunder damage (in BG: lightning)." },
	  },
	  desc = "GOLIATH: Goliaths are towering folk descended from giants. Each carries a gift of their giant ancestors, and their strength is legendary.\n\nSpecies traits:\n– Giant Ancestry: choose a gift of the giants, an innate ability usable twice per long rest.\n– Powerful Build: you can carry more (in BG: no effect yet).\n– Large Form (level 5): arrives with the level-up updates.\n\nBody: half-orc (the broad build); in BG the Goliath keeps the half-orc's infravision." },
	{ key = "HALFLING", name = "Halfling", body = R_HALFLING,
	  desc = "HALFLING: Halflings are a small, cheerful people who value home and good company, yet often find themselves on great adventures. Their luck is legendary.\n\nSpecies traits:\n– Brave: advantage on saving throws against being frightened.\n– Luck: when you roll a 1 on a saving throw, you reroll it.\n– Naturally Stealthy: a bonus to Move Silently and Hide in Shadows.\n\nIn BG, halflings keep the engine's infravision." },
	{ key = "HUMAN", name = "Human", body = R_HUMAN,
	  desc = "HUMAN: Humans are the most widespread people of Faerûn, found in every land and every walk of life. Ambitious and adaptable, they make up for their short lives with drive and variety.\n\nSpecies traits:\n– Resourceful: you gain Heroic Inspiration after every long rest.\n– Skillful: proficiency in one extra skill.\n– Versatile: an extra origin feat, chosen together with your background." },
	{ key = "ORC", name = "Orc", body = R_HALF_ORC,
	  desc = "ORC: Orcs are a people of endurance and fierce determination, gifted by their god with the strength to push on when others fall.\n\nSpecies traits:\n– Darkvision (infravision).\n– Adrenaline Rush: an innate ability you can use twice per long rest; you move faster for a round and gain temporary hit points equal to your Proficiency Bonus.\n– Relentless Endurance: once per long rest, when you drop to 0 hit points without being killed outright, you drop to 1 hit point instead.\n\nBody: half-orc." },
	{ key = "TIEFLING", name = "Tiefling", body = R_HUMAN,
	  lineageTitle = "Fiendish Legacy",
	  lineages = {
		{ key = "ABYSSAL", name = "Abyssal", damage = "POISON",
		  desc = "Resistance to poison damage. Spells: Poison Spray, later Ray of Sickness and Hold Person." },
		{ key = "CHTHONIC", name = "Chthonic", damage = "MAGIC",
		  desc = "Resistance to necrotic damage (in BG: magic damage). Spells: Chill Touch, later False Life and Ray of Enfeeblement." },
		{ key = "INFERNAL", name = "Infernal", damage = "FIRE",
		  desc = "Resistance to fire damage. Spells: Fire Bolt, later Hellish Rebuke and Darkness." },
	  },
	  desc = "TIEFLING: Tieflings are touched by the power of the Lower Planes. Horns, a tail and eyes like embers mark their fiendish heritage.\n\nSpecies traits:\n– Darkvision (infravision).\n– Fiendish Legacy: choose a legacy; it gives a damage resistance now, and spells with the spell updates.\n– Otherworldly Presence: the Thaumaturgy cantrip (arrives with the spell updates).\n\nBody: human." },
}
B24SPEC.Index = {}
for i, species in ipairs(B24SPEC.SPECIES) do B24SPEC.Index[species.key] = i end

-- Engine race -> species for creatures without a stored species.
B24SPEC.FROM_RACE = {
	[R_HUMAN] = "HUMAN", [R_ELF] = "ELF", [3] = "ELF", [R_DWARF] = "DWARF",
	[R_HALFLING] = "HALFLING", [R_GNOME] = "GNOME", [R_HALF_ORC] = "ORC",
}

function B24SPEC.Species(sprite)
	local stored = B24SPEC.SPECIES[sprite:getLocalInt("B24SPC")]
	if stored then return stored.key end
	return B24SPEC.FROM_RACE[sprite.m_typeAI.m_Race]
end

-- Lineage entry of the creature's species, or nil (first lineage if none was chosen).
function B24SPEC.Lineage(sprite)
	local species = B24SPEC.SPECIES[B24SPEC.Index[B24SPEC.Species(sprite) or ""] or 0]
	if species == nil or species.lineages == nil then return nil end
	return species.lineages[sprite:getLocalInt("B24LIN")] or species.lineages[1]
end

local function permanent(sprite, args)
	args.durationType = 9
	args.m_sourceRes = B24SPEC.SOURCE_RES
	B24.ApplyEffect(sprite, args)
end

local function darkvision(sprite)
	permanent(sprite, { ["effectID"] = 63 })
end

local function resistance(sprite, damageKey)
	permanent(sprite, { ["effectID"] = B24SPEC.DAMAGE[damageKey].resist, ["effectAmount"] = 50 })
end

local function grantInnate(sprite, res, uses)
	for i = 1, uses or 1 do
		B24.ApplyEffect(sprite, { ["effectID"] = 171, ["res"] = res })
	end
end

-- Breath Weapon uses: the Proficiency Bonus at level 1 (2); later levels follow with level-ups.
local setup = {
	AASIMAR = function(sprite)
		darkvision(sprite)
		resistance(sprite, "MAGIC")
		grantInnate(sprite, "B24HEALH")
	end,
	DRAGONBORN = function(sprite)
		local damage = B24SPEC.Lineage(sprite).damage
		resistance(sprite, damage)
		grantInnate(sprite, B24SPEC.DAMAGE[damage].breath, 2)
	end,
	DWARF = function(sprite)
		resistance(sprite, "POISON")
	end,
	ELF = function(sprite)
		permanent(sprite, { ["effectID"] = 101, ["dwFlags"] = 39 }) -- Trance: immune to sleep
	end,
	GNOME = function(sprite) end,
	GOLIATH = function(sprite)
		grantInnate(sprite, B24SPEC.Lineage(sprite).spell, 2)
	end,
	HALFLING = function(sprite)
		permanent(sprite, { ["effectID"] = 59, ["effectAmount"] = 10 })  -- Naturally Stealthy
		permanent(sprite, { ["effectID"] = 275, ["effectAmount"] = 10 })
	end,
	HUMAN = function(sprite)
		B24.Inspiration_Grant(sprite) -- Resourceful
	end,
	ORC = function(sprite)
		grantInnate(sprite, B24SPEC.ADRENALINE_RES, 2)
		B24SPEC.Relentless_Ready(sprite)
	end,
	TIEFLING = function(sprite)
		darkvision(sprite)
		resistance(sprite, B24SPEC.Lineage(sprite).damage)
	end,
}

local function needsSpecies(sprite)
	local species = B24SPEC.Species(sprite)
	return species ~= nil and setup[species] ~= nil and sprite:getLocalInt("B24SPSET") < B24SPEC.SETUP_VERSION
end

function B24SPEC.ApplySpecies(sprite)
	sprite:setLocalInt("B24SPSET", B24SPEC.SETUP_VERSION)
	B24.RemoveEffectsBySource(sprite, B24SPEC.SOURCE_RES)
	setup[B24SPEC.Species(sprite)](sprite)
end

local originalNeedsSetup = B24_PartyNeedsSetup
local originalSetup = B24_SetupParty

function B24_PartyNeedsSetup()
	if originalNeedsSetup() then return true end
	for _, member in ipairs(B24.Party()) do
		if needsSpecies(member) then return true end
	end
	return false
end

function B24_SetupParty()
	originalSetup()
	for _, member in ipairs(B24.Party()) do
		if needsSpecies(member) then
			EEex_Utility_TryIgnore(B24SPEC.ApplySpecies, member)
		end
	end
end

-- The breath weapon's save DC uses Constitution.
B24.CASTING_ABILITY_PREFIXES["B24BR"] = "CON"

-------------------
-- Proficiencies --
-------------------

-- Human Skillful: one skill, chosen in character creation (local B24SKHUM, a B24.SKILLS index);
-- without a choice the first of this list the character isn't proficient in yet.
B24SPEC.SKILLFUL_DEFAULTS = { "PERCEPTION", "INSIGHT", "STEALTH", "ATHLETICS", "PERSUASION" }

B24.AddGrantedSkillListener(function(sprite, proficient)
	local species = B24SPEC.Species(sprite)
	if species == "ELF" then
		proficient.PERCEPTION = true -- Keen Senses
	elseif species == "HUMAN" then
		local chosen = B24.SKILLS[sprite:getLocalInt("B24SKHUM")]
		if chosen then
			proficient[chosen.key] = true
			return
		end
		for _, key in ipairs(B24SPEC.SKILLFUL_DEFAULTS) do
			if not proficient[key] then
				proficient[key] = true
				return
			end
		end
	end
end)

------------------------------
-- Saving throw advantages --
------------------------------

B24.AddSaveAdvantageListener(function(sprite, ability, conditions)
	local species = B24SPEC.Species(sprite)
	if species == "ELF" and conditions.CHARM then return true end              -- Fey Ancestry
	if species == "DWARF" and conditions.POISON then return true end           -- Dwarven Resilience
	if species == "HALFLING" and conditions.FEAR then return true end          -- Brave
	if species == "GNOME" and (ability == "INT" or ability == "WIS" or ability == "CHA") then
		return true                                                            -- Gnomish Cunning
	end
	return false
end)

-- Halfling Luck.
B24.AddSaveRerollOnOneListener(function(sprite)
	return B24SPEC.Species(sprite) == "HALFLING"
end)

-------------------------
-- Dwarven Toughness --
-------------------------

B24.AddStatListener(function(sprite)
	if B24SPEC.Species(sprite) == "DWARF" then
		local stats = sprite:getActiveStats()
		stats.m_nMaxHitPoints = stats.m_nMaxHitPoints + B24.Level(sprite)
	end
end)

----------------------------
-- Relentless Endurance --
----------------------------

-- op208 keeps the orc at 1 hit point; the damage hook below notices when it caught a hit and
-- removes it until the next long rest.
function B24SPEC.Relentless_Ready(sprite)
	sprite:setLocalInt("B24RELUS", 0)
	B24.RemoveEffectsBySource(sprite, B24SPEC.RELENTLESS_RES)
	B24.ApplyEffect(sprite, {
		["effectID"] = 208, ["effectAmount"] = 1, ["durationType"] = 9, ["m_sourceRes"] = B24SPEC.RELENTLESS_RES,
	})
end

------------------------------
-- Goliath Giant Ancestry --
------------------------------

-- The innates (op402) arm a one-round effect in the creature's aux data; the damage hooks below
-- spend it: weapon riders on the next hit (Fire, Frost, Hill), damage reduction on the next damage
-- taken (Stone), retaliation against the next attacker (Storm).

local function arm(sprite, kind)
	B24.Aux(sprite).B24_Giant = { kind = kind, expires = B24.GameTick() + B24SPEC.GIANT_INTERVAL }
	B24.Log(string.format("%s: %s", B24.Name(sprite), B24SPEC.SPECIES[B24SPEC.Index.GOLIATH].lineages[({
		FIRE = 2, FROST = 3, HILL = 4, STONE = 5, STORM = 6 })[kind]].name))
end

local function armed(sprite, kind)
	local giant = B24.Aux(sprite).B24_Giant
	if giant == nil or giant.kind ~= kind then return false end
	if B24.GameTick() > giant.expires then
		B24.Aux(sprite).B24_Giant = nil
		return false
	end
	return true
end

local function disarm(sprite)
	B24.Aux(sprite).B24_Giant = nil
end

function B24GLFIR(op402, sprite) EEex_Utility_TryIgnore(arm, sprite, "FIRE") end
function B24GLFRO(op402, sprite) EEex_Utility_TryIgnore(arm, sprite, "FROST") end
function B24GLHIL(op402, sprite) EEex_Utility_TryIgnore(arm, sprite, "HILL") end
function B24GLSTO(op402, sprite) EEex_Utility_TryIgnore(arm, sprite, "STONE") end
function B24GLSTM(op402, sprite) EEex_Utility_TryIgnore(arm, sprite, "STORM") end

local function isAttacking(sprite)
	local id = sprite.m_curAction.m_actionID
	return id == 3 or id == 94 or id == 98 or id == 105 or id == 134
end

local function damage(target, source, numDice, diceSize, damageKey)
	B24.ApplyEffect(target, { ["effectID"] = 12, ["numDice"] = numDice, ["diceSize"] = diceSize,
		["dwFlags"] = B24SPEC.DAMAGE[damageKey].op12, ["sourceID"] = source.m_id })
end

local function rollDice(n, size)
	local total = 0
	for i = 1, n do total = total + B24.Roll(size) end
	return total
end

local function onWeaponHit(effect, source, target)
	if effect.m_numDice <= 0 or not isAttacking(source) then return end
	if armed(source, "FIRE") then
		disarm(source)
		damage(target, source, 1, 10, "FIRE")
	elseif armed(source, "FROST") then
		disarm(source)
		damage(target, source, 1, 6, "COLD")
		B24.ApplyEffect(target, { ["effectID"] = 176, ["effectAmount"] = 67, ["dwFlags"] = 5,
			["durationType"] = 0, ["duration"] = 6, ["sourceID"] = source.m_id })
	elseif armed(source, "HILL") then
		disarm(source)
		B24.KnockProne(target, source)
		B24.Log(string.format("%s is knocked prone", B24.Name(target)))
	end
end

local function onDamageTaken(effect, target)
	if not armed(target, "STONE") then return end
	disarm(target)
	local total = effect.m_effectAmount + rollDice(effect.m_numDice, effect.m_diceSize)
	local reduction = B24.Roll(12) + B24.AbilityModOf(target, "CON")
	effect.m_numDice = 0
	effect.m_effectAmount = math.max(0, total - reduction)
	B24.Log(string.format("%s: Stone's Endurance reduces the damage by %d", B24.Name(target), reduction))
end

---------------------
-- Damage hooks --
---------------------

local hitPointsBefore = {}
local originalDamageStart = EEex_Sprite_Hook_OnDamageEffectStartingCalculations
local originalDamageDone = EEex_Sprite_Hook_OnDamageEffectDone

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	if B24SPEC.Species(targetSprite) == "ORC" then
		hitPointsBefore[targetSprite.m_id] = targetSprite.m_baseStats.m_hitPoints
	end
	EEex_Utility_TryIgnore(onDamageTaken, effect, targetSprite)
	if B24.IsSprite(sourceSprite) and sourceSprite.m_id ~= targetSprite.m_id then
		EEex_Utility_TryIgnore(onWeaponHit, effect, sourceSprite, targetSprite)
	end
	return originalDamageStart(effect, sourceSprite, targetSprite)
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)
	originalDamageDone(effect, sourceSprite, targetSprite)
	local before = hitPointsBefore[targetSprite.m_id]
	hitPointsBefore[targetSprite.m_id] = nil
	if before and before > 1 and targetSprite.m_baseStats.m_hitPoints == 1
		and targetSprite:getLocalInt("B24RELUS") == 0 and B24.HasEffectSource(targetSprite, 208, B24SPEC.RELENTLESS_RES) then
		targetSprite:setLocalInt("B24RELUS", 1)
		B24.RemoveEffectsBySource(targetSprite, B24SPEC.RELENTLESS_RES)
		B24.Log(string.format("%s: Relentless Endurance, drops to 1 hit point instead of 0", B24.Name(targetSprite)))
	end
	-- Storm's Thunder: the attacker takes thunder damage once.
	if B24.IsSprite(sourceSprite) and sourceSprite.m_id ~= targetSprite.m_id and armed(targetSprite, "STORM") then
		disarm(targetSprite)
		EEex_Utility_TryIgnore(damage, sourceSprite, targetSprite, 1, 8, "LIGHTNING")
	end
end

-----------------
-- Long rest --
-----------------

B24.AddLongRestListener(function(sprite)
	local species = B24SPEC.Species(sprite)
	if species == "HUMAN" then
		B24.Inspiration_Grant(sprite) -- Resourceful
	elseif species == "ORC" and sprite:getLocalInt("B24RELUS") == 1 then
		B24SPEC.Relentless_Ready(sprite)
	end
end)

-------------------------------
-- Innate ability scripts --
-------------------------------

-- op402 entry point of B24ADREN.SPL: faster movement for a round and temporary hit points equal to
-- the Proficiency Bonus (op18 mode 0 raises maximum and current hit points, for one minute).
function B24ADREN(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local pb = B24.ProfOf(sprite)
		B24.ApplyEffect(sprite, { ["effectID"] = 176, ["effectAmount"] = 150, ["dwFlags"] = 5, ["durationType"] = 0,
			["duration"] = 6, ["m_sourceRes"] = B24SPEC.ADRENALINE_RES })
		B24.ApplyEffect(sprite, { ["effectID"] = 18, ["effectAmount"] = pb, ["dwFlags"] = 0, ["durationType"] = 0,
			["duration"] = 60, ["m_sourceRes"] = B24SPEC.ADRENALINE_RES })
		B24.Log(string.format("%s: Adrenaline Rush, %d temporary hit points", B24.Name(sprite), pb))
	end)
end

-- op402 entry point of B24HEALH.SPL (Aasimar Healing Hands): the touched creature regains a number
-- of d4 equal to the caster's Proficiency Bonus.
function B24HEALH(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local caster = B24.GetSprite(op402.m_sourceId) or sprite
		local pb = B24.ProfOf(caster)
		local healed = rollDice(pb, 4)
		B24.Heal(sprite, healed)
		B24.Log(string.format("%s: Healing Hands restores %d hit points to %s", B24.Name(caster), healed, B24.Name(sprite)))
	end)
end

-- Relentless Endurance catches a drop to 0 before the dying rules (B24DYING.lua).
B24.AddDownSaver(function(sprite)
	return sprite:getLocalInt("B24RELUS") == 0 and B24.HasEffectSource(sprite, 208, B24SPEC.RELENTLESS_RES)
end)
