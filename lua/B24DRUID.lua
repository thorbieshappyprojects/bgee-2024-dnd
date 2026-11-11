-- BG 2024 Rules Mod: the 2024 Druid with the Circle of the Land (SRD subclass). Druid spells use
-- the Spells component.
--
--   1  Spellcasting, Primal Order (Magician: one more cantrip, Wisdom to Arcana and Nature;
--      Warden: martial weapons, medium armor), cantrips (2; 3 at 4, 4 at 10)
--   2  Wild Shape (2024 beast forms, see below), Wild Companion
--   3  Subclass: Land (land type; Land's Aid)
--   4, 8, 12, 16  Ability Score Improvement; 19 Epic Boon (an Epic Boon feat or another feat)
--   5  Wild Resurgence
--   6  Land: Natural Recovery (the slot part; its free circle spell waits for the circle spells)
--   7  Elemental Fury (Potent Spellcasting: Wisdom modifier to cantrip damage; or Primal Strike:
--      +1d8 elemental damage once per round with weapons); 15 Improved Elemental Fury (2d8)
--   10 Land: Nature's Ward (immune to poison, resistance to the land's element)
--   14 Land: Nature's Sanctuary, 18 Beast Spells (spellcasting in beast form),
--      20 Archdruid (Evergreen Wild Shape, Nature Magician)
--
-- Locals: B24LAUSE (Land's Aid uses), B24PRIM (Primal Order), B24EFURY (Elemental Fury),
-- B24LAND (land type).

B24DR = {}

function B24DR.Level(sprite)
	return B24LV.ClassLevel(sprite, "DRUID")
end

B24LV.AddSubclasses("DRUID", 3, {
	{ key = "LAND", name = "Circle of the Land",
	  desc = "Druids of the Land draw on the magic of the place they protect.\n\nLevel 3: choose a land type; Land's Aid (heal an ally, damage enemies around it).\nLevel 6: Natural Recovery (once per long rest, a short rest brings back spent spell slots worth half your Druid level).\nLevel 10: Nature's Ward (immune to poison, resistance to your land's element).\nLevel 14: Nature's Sanctuary (a Wild Shape use: +2 AC and your Nature's Ward resistance for you and the allies near you, for a minute).\nCircle spells follow with the spell updates.",
	  features = { [3] = "Land type, Land's Aid", [6] = "Natural Recovery", [10] = "Nature's Ward", [14] = "Nature's Sanctuary" } },
})

local function isLand(sprite)
	return B24LV.Subclass(sprite, "DRUID") == "LAND"
end

B24LV.AddOption({ key = "PRIMAL_ORDER", localName = "B24PRIM", class = "DRUID", level = 1, title = "Primal Order",
	list = {
		{ key = "MAGICIAN", name = "Magician", desc = "One extra cantrip, and your Wisdom modifier (at least +1) adds to Arcana and Nature." },
		{ key = "WARDEN", name = "Warden", desc = "Trained for battle: proficiency with martial weapons and training with medium armor." },
	} })

B24LV.AddOption({ key = "ELEMENTAL_FURY", localName = "B24EFURY", class = "DRUID", level = 7, title = "Elemental Fury",
	list = {
		{ key = "POTENT_SPELLCASTING", name = "Potent Spellcasting", desc = "Your druid cantrips add your Wisdom modifier to their damage." },
		{ key = "PRIMAL_STRIKE", name = "Primal Strike", desc = "Once per round, a weapon hit or a beast form's attack in Wild Shape deals 1d8 extra cold, fire or lightning damage (2d8 from level 15)." },
	} })

-- Land types: the element of Nature's Ward.
B24DR.LANDS = {
	{ key = "ARID", name = "Arid Land", desc = "Deserts and wastes. Nature's Ward: resistance to fire.", resist = 30 },
	{ key = "POLAR", name = "Polar Land", desc = "Frozen lands. Nature's Ward: resistance to cold.", resist = 28 },
	{ key = "TEMPERATE", name = "Temperate Land", desc = "Forests and grasslands. Nature's Ward: resistance to lightning.", resist = 29 },
	{ key = "TROPICAL", name = "Tropical Land", desc = "Jungles and swamps. Nature's Ward: resistance to poison.", resist = 173 },
}
B24LV.AddOption({ key = "LAND_TYPE", localName = "B24LAND", class = "DRUID", level = 3, title = "Land Type", subclass = "LAND",
	list = B24DR.LANDS })

local function wis(sprite) return B24.AbilityModOf(sprite, "WIS") end

B24LV.AddResource("LANDS_AID", { spell = "B24LAID", localName = "B24LAUSE", shortRest = "one",
	max = function(sprite)
		local level = B24DR.Level(sprite)
		if level < 3 or not isLand(sprite) then return 0 end
		return level >= 17 and 4 or level >= 6 and 3 or 2
	end })

B24DR.ASI_LEVELS = { 4, 8, 12, 16, 19 }

B24LV.AddChoiceListener(function(sprite)
	local level = B24DR.Level(sprite)
	if level <= 0 then return nil end
	local asi = 0
	for _, l in ipairs(B24DR.ASI_LEVELS) do
		if level >= l then asi = asi + 1 end
	end
	local cantrips = 2 + (level >= 4 and 1 or 0) + (level >= 10 and 1 or 0)
		+ (B24LV.Option(sprite, "PRIMAL_ORDER") == "MAGICIAN" and 1 or 0)
	return { ASI = asi, CANTRIP = cantrips }
end)

B24DR.FEATURES = {
	[1] = "Spellcasting, Primal Order, cantrips (2)",
	[2] = "Wild Shape (beast forms; 2 uses), Wild Companion",
	[5] = "Wild Resurgence",
	[3] = "Subclass",
	[4] = "Ability Score Improvement, cantrips (3), Wild Shape forms up to Challenge Rating 1/2",
	[7] = "Elemental Fury",
	[8] = "Ability Score Improvement, Wild Shape forms up to Challenge Rating 1",
	[10] = "cantrips (4)",
	[12] = "Ability Score Improvement",
	[15] = "Improved Elemental Fury",
	[16] = "Ability Score Improvement",
	[18] = "Beast Spells (spellcasting in beast form)",
	[19] = "Epic Boon (an Epic Boon feat or another feat)",
	[20] = "Archdruid (Evergreen Wild Shape, Nature Magician)",
}

B24LV.AddFeatureTextListener(function(sprite)
	local level = B24DR.Level(sprite)
	local lines = {}
	for l = B24LV.AppliedClassLevel(sprite, "DRUID") + 1, level do
		if B24DR.FEATURES[l] then table.insert(lines, string.format("Druid %d: %s", l, B24DR.FEATURES[l])) end
	end
	return lines
end)

-- Nature's Ward (10, Land).
B24LV.AddApplyListener(function(sprite)
	if B24DR.Level(sprite) < 10 or not isLand(sprite) then return end
	B24LV.Permanent(sprite, { ["effectID"] = 101, ["dwFlags"] = 25 }) -- immune to poison
	local landKey = B24LV.Option(sprite, "LAND_TYPE")
	for _, land in ipairs(B24DR.LANDS) do
		if land.key == landKey then
			B24LV.Permanent(sprite, { ["effectID"] = land.resist, ["effectAmount"] = 50 })
		end
	end
end)

------------------
-- Primal Order --
------------------

B24.AddWeaponProficiencyListener(function(sprite)
	return B24DR.Level(sprite) > 0 and B24LV.Option(sprite, "PRIMAL_ORDER") == "WARDEN"
end)

B24.AddSkillBonusListener(function(sprite, key)
	if (key == "ARCANA" or key == "NATURE") and B24DR.Level(sprite) > 0
		and B24LV.Option(sprite, "PRIMAL_ORDER") == "MAGICIAN" then
		return math.max(1, wis(sprite))
	end
	return 0
end)

----------------
-- Land's Aid --
----------------

-- op402 entry point of B24LAID.SPL (cast on a creature): enemies around the target make a
-- Constitution save or take 2d6 necrotic damage (half on a success); the target, if it is a
-- party member, or else the druid regains 2d6 hit points. 3d6 at 10, 4d6 at 14.
function B24LAID(op402, target)
	EEex_Utility_TryIgnore(function()
		local druid = B24.GetSprite(op402.m_sourceId)
		if druid == nil then return end
		B24LV.Use(druid, "LANDS_AID")
		local level = B24DR.Level(druid)
		local dice = level >= 14 and 4 or level >= 10 and 3 or 2
		local dc = 8 + B24.ProfOf(druid) + wis(druid)
		local victims = EEex_Sprite_GetAllOfTypeStringInRange(target, "[ENEMY]", B24.Feet(10), true) or {}
		if not B24.InParty(target) then table.insert(victims, target) end
		for _, enemy in ipairs(victims) do
			local damage = 0
			for i = 1, dice do damage = damage + B24.Roll(6) end
			if B24.RollSave(enemy, "CON", dc, nil, " (Land's Aid)") then damage = math.floor(damage / 2) end
			B24.ApplyEffect(enemy, { ["effectID"] = 12, ["effectAmount"] = damage, ["dwFlags"] = 0x400000, ["sourceID"] = druid.m_id })
		end
		local healed = 0
		for i = 1, dice do healed = healed + B24.Roll(6) end
		B24.Heal(B24.InParty(target) and target or druid, healed)
		B24.Log(string.format("%s: Land's Aid, %d hit points", B24.Name(druid), healed))
	end)
end

--------------------
-- Elemental Fury --
--------------------

table.insert(B24WPN.DamageListeners, function(context)
	local druid = context.attacker
	local level = B24DR.Level(druid)
	if level < 7 or B24LV.Option(druid, "ELEMENTAL_FURY") ~= "PRIMAL_STRIKE" then return end
	local aux = B24.Aux(druid)
	local now = B24.GameTick()
	if aux.B24_PrimalStrike and now - aux.B24_PrimalStrike < 90 then return end
	aux.B24_PrimalStrike = now
	local extra = B24.Roll(8) + (level >= 15 and B24.Roll(8) or 0)
	context.effect.m_effectAmount = context.effect.m_effectAmount + extra
	B24.Log(string.format("%s: Primal Strike %d", B24.Name(druid), extra))
end)

B24LV.WhenSpells(function()
	table.insert(B24SP.DamageListeners, function(effect, caster, target, res)
		if not B24SP.IsCantrip(res) or B24DR.Level(caster) < 7 then return end
		if B24LV.Option(caster, "ELEMENTAL_FURY") ~= "POTENT_SPELLCASTING" then return end
		effect.m_effectAmount = effect.m_effectAmount + math.max(0, wis(caster))
	end)
end)

-- BG's 2e druid passives (SPCL924-927: poison immunity, elemental resistances) are removed from
-- the class table at install time; existing druids lose their effects too.
B24LV.AddApplyListener(function(sprite)
	if B24DR.Level(sprite) <= 0 then return end
	for _, res in ipairs({ "SPCL924", "SPCL925", "SPCL926", "SPCL927" }) do B24.RemoveEffectsBySource(sprite, res) end
	-- BG's shapeshifting (wolf, black and brown bear) makes way for the 2024 Wild Shape.
	for _, res in ipairs({ "SPCL611", "SPCL612", "SPCL613" }) do B24.ApplyEffect(sprite, { ["effectID"] = 172, ["res"] = res }) end
end)

----------------
-- Wild Shape --
----------------

-- Wild Shape uses (2 at Druid level 2, 3 at 6, 4 at 17; one returns on a short rest), spent on the
-- beast forms below and on the other 2024 features that use them. Local B24WSUSE.
B24LV.AddResource("WILD_SHAPE", { localName = "B24WSUSE", shortRest = "one", powers = {},
	max = function(sprite)
		local level = B24DR.Level(sprite)
		return level >= 17 and 4 or level >= 6 and 3 or level >= 2 and 2 or 0
	end })

local function addPower(power) table.insert(B24LV.RESOURCES.WILD_SHAPE.powers, power) end

-- Beast forms (B24WSHAP.2DA; b24_fighter.tpa builds an innate, claws and a look for each). A form
-- is its claws item B24WI<id>, held through a timed op111 (source B24WSFRM) for half the Druid
-- level in hours. The claws carry the look (op135), the attacks per round and resistances; while
-- they are held, the stat listener below gives the beast's Strength, Dexterity, Constitution, AC
-- and attack bonus. The druid keeps hit points, Intelligence, Wisdom and Charisma. Tiers: 1 CR 1/4
-- (Druid 2), 2 CR 1/2 (4), 3 CR 1 (8; Moon 3), 4 CR 2 (Moon 6). Every form of the druid's tier and
-- below can be taken (BG has no screen to learn forms); BG has no flying, so no flying forms.
B24DR.FORM_SOURCE = "B24WSFRM"
B24DR.NATURAL_FORM = "B24WSEND"
B24DR.FORMS = {} -- by claws item resref

local function formName(key)
	return (key:lower():gsub("_", " "):gsub("(%a)(%a*)", function(a, b) return a:upper() .. b end))
end

for key, row in pairs(B24.LoadTable("B24WSHAP")) do
	local form = { key = key, name = formName(key), res = row.RES, item = "B24WI" .. row.RES:sub(6),
		tier = tonumber(row.TIER), ac = tonumber(row.AC), str = tonumber(row.STR), dex = tonumber(row.DEX),
		con = tonumber(row.CON), atk = tonumber(row.ATK), apr = tonumber(row.APR), prone = tonumber(row.PRONE),
		trait = row.TRAIT }
	local n, size = (row.POISON or ""):match("^(%d+)d(%d+)$")
	if n then form.poison = { tonumber(n), tonumber(size) } end
	B24DR.FORMS[form.item] = form
	-- The form's innate (op402) calls the function of its name.
	_G[row.RES] = function(op402, sprite) EEex_Utility_TryIgnore(B24DR.Assume, sprite, form) end
end

-- Turn-based combat (B24TURN.lua): opening the list of forms costs nothing; taking a form or leaving
-- it is a bonus action.
if B24TB then
	B24TB.FREE_INNATES.B24WSHAP = true
	B24TB.BONUS_INNATES[B24DR.NATURAL_FORM] = true
	for _, form in pairs(B24DR.FORMS) do B24TB.BONUS_INNATES[form.res] = true end
end

local function isMoon(sprite, level) return B24LV.Is(sprite, "DRUID", "MOON", level or 3) end

-- The highest form tier the druid can take (0: no Wild Shape yet).
function B24DR.FormTier(sprite)
	local level = B24DR.Level(sprite)
	if isMoon(sprite) then return level >= 6 and 4 or 3 end
	return level >= 8 and 3 or level >= 4 and 2 or level >= 2 and 1 or 0
end

-- The form the creature is in, or nil: told by the claws it holds (op111 selects them; the other
-- slots are a fallback after a weapon switch).
local function formOfItem(item)
	return item ~= nil and B24DR.FORMS[item.cResRef:get():upper()] or nil
end

function B24DR.Form(sprite)
	local equipment = sprite.m_equipment
	local form = formOfItem(equipment.m_items:get(equipment.m_selectedWeapon))
	if form then return form end
	for slot = 0, 38 do
		form = formOfItem(equipment.m_items:get(slot))
		if form then return form end
	end
	return nil
end

-- Wild Shape (innate, with a use left): opens the list of the forms up to the druid's tier
-- (op214 over B24WSL<tier>.2DA). The use is spent when a form is picked, so the innate comes back
-- at once (a closed list costs nothing).
addPower({ res = "B24WSHAP", when = function(s) return B24DR.FormTier(s) > 0 end })

function B24WSHAP(op402, sprite)
	EEex_Utility_TryIgnore(function()
		B24LV.RefreshPowers(sprite, "WILD_SHAPE")
		B24.ApplyEffect(sprite, { ["effectID"] = 214, ["dwFlags"] = 0, ["res"] = "B24WSL" .. B24DR.FormTier(sprite) })
	end)
end

function B24DR.Assume(sprite, form)
	if form.tier > B24DR.FormTier(sprite) or not B24LV.Spend(sprite, "WILD_SHAPE", 1) then return end
	B24DR.EndForm(sprite, true)
	local level = B24DR.Level(sprite)
	local seconds = math.max(1, math.floor(level / 2)) * 3600
	local function timed(args)
		args.durationType, args.duration, args.m_sourceRes = 0, seconds, B24DR.FORM_SOURCE
		B24.ApplyEffect(sprite, args)
	end
	-- The engine drops the op111 effect once the claws are made, so the form keeps its own end
	-- time (local B24WSTIM, game ticks).
	timed({ ["effectID"] = 111, ["res"] = form.item })
	sprite:setLocalInt("B24WSTIM", B24.GameTick() + seconds * 15)
	-- No spellcasting until Beast Spells (18).
	if level < 18 then
		timed({ ["effectID"] = 145, ["dwFlags"] = 0 })
		timed({ ["effectID"] = 145, ["dwFlags"] = 1 })
	end
	B24LV.Grant(sprite, B24DR.NATURAL_FORM, true)
	B24.Aux(sprite).B24_FormShown = true
	B24.Log(string.format("%s: Wild Shape, %s", B24.Name(sprite), form.name))
	-- Circle Forms (Moon 3): three times the Druid level.
	B24LV.TempHP(sprite, (isMoon(sprite) and 3 or 1) * level, seconds)
end

function B24DR.EndForm(sprite, quiet)
	local form = B24DR.Form(sprite)
	if form == nil then return end
	sprite:setLocalInt("B24WSTIM", 0)
	B24.RemoveEffectsBySource(sprite, B24DR.FORM_SOURCE)
	-- The claws go with op112.
	B24.ApplyEffect(sprite, { ["effectID"] = 112, ["res"] = form.item })
	B24LV.Grant(sprite, B24DR.NATURAL_FORM, false)
	B24.Aux(sprite).B24_FormShown = false
	if not quiet then B24.Log(string.format("%s returns to natural form", B24.Name(sprite))) end
end

function B24WSEND(op402, sprite)
	EEex_Utility_TryIgnore(B24DR.EndForm, sprite)
end

-- The beast's scores, AC and attack bonus. Runs before the core's stat pass (B24.OnListsResolved,
-- which then skips the armor Dex caps), so advantage, Barkskin and Circle Forms still apply on top.
local function formStats(sprite)
	local form = B24DR.Form(sprite)
	B24.Aux(sprite).B24_Form = form
	if form == nil then return end
	local stats = sprite:getActiveStats()
	stats.m_nSTR, stats.m_nDEX, stats.m_nCON = form.str, form.dex, form.con
	-- Equipment merges into the form; bonuses of spells on the druid (Shield of Faith: op0, to-hit:
	-- op54/op278) stay.
	local bonus, toHit = 0, 0
	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)
		if effect.m_dWFlags ~= 0 then return end
		if effect.m_effectId == 0 then bonus = bonus + effect.m_effectAmount end
		if effect.m_effectId == 54 or effect.m_effectId == 278 then toHit = toHit + effect.m_effectAmount end
	end)
	-- Circle Forms (Moon 3): AC at least 13 + Wisdom modifier.
	local ac = isMoon(sprite) and math.max(form.ac, 13 + wis(sprite)) or form.ac
	stats.m_nArmorClass = 20 - ac - bonus
	-- The beast's attack bonus; the engine adds the Strength modifier itself.
	stats.m_nTHAC0 = 20 - (form.atk - B24.AbilityMod(form.str)) - toHit
end
for i, listener in ipairs(B24.StatListeners) do
	if listener == B24.OnListsResolved then table.insert(B24.StatListeners, i, formStats) break end
end

-- The form ends when its time runs out, or when the druid is incapacitated or drops to 0 hit
-- points; Natural Form comes and goes with the form. Wild Shape stays first on the innate bar.
B24LV.AddTickListener(function(sprite)
	if B24DR.Level(sprite) < 2 then return end
	-- Wild Shape (and Natural Form) first on the innate bar.
	EEex_Utility_TryIgnore(B24.InnatesFirst, sprite, { "B24WSHAP", B24DR.NATURAL_FORM })
	local form = B24DR.Form(sprite)
	local ends = sprite:getLocalInt("B24WSTIM")
	if form and (sprite.m_baseStats.m_hitPoints <= 0 or B24.IsUnconscious(sprite) or B24.IsParalyzed(sprite)
		or (ends > 0 and B24.GameTick() >= ends)) then
		B24DR.EndForm(sprite)
		form = nil
	end
	local aux = B24.Aux(sprite)
	if (form ~= nil) ~= (aux.B24_FormShown == true) then
		B24LV.Grant(sprite, B24DR.NATURAL_FORM, form ~= nil)
		aux.B24_FormShown = form ~= nil
	end
end)

-- Riders of the beasts' attacks: poison damage, knocking the target prone (once a round for
-- beasts with several attacks, e.g. the Brown Bear's claw).
table.insert(B24WPN.DamageListeners, function(context)
	local attacker, target = context.attacker, context.target
	local form = B24DR.Form(attacker)
	if form == nil then return end
	if form.poison then
		B24X.Damage(target, attacker, B24LV.Dice(form.poison[1], form.poison[2]), B24X.POISON)
	end
	if form.prone > 0 and B24.Size(target) <= form.prone and (form.apr == 1 or B24LV.OncePerRound(attacker, "FORM_PRONE")) then
		B24.KnockProne(target, attacker)
	end
end)

-- Pack Tactics: advantage against a target an ally of the beast stands next to.
table.insert(B24.AdvantageAgainstListeners, function(attacker, target)
	local form = B24DR.Form(attacker)
	if form == nil or form.trait ~= "PACK" then return false end
	for _, ally in ipairs(EEex_Sprite_GetAllOfTypeStringInRange(target, "[GOODCUTOFF]", B24.ADJACENT, true) or {}) do
		if ally.m_id ~= attacker.m_id and ally.m_baseStats.m_hitPoints > 0 then return true end
	end
	return false
end)

-- Bloodied Fury: advantage while at half hit points or less.
table.insert(B24.AttackAdvantageListeners, function(sprite)
	local form = B24DR.Form(sprite)
	return form ~= nil and form.trait == "BLOODIED"
		and sprite.m_baseStats.m_hitPoints * 2 <= sprite:getActiveStats().m_nMaxHitPoints
end)

-- Wild Companion (2): a Wild Shape use summons a spirit animal (in BG: a wolf) for an hour.
B24DR.COMPANION = "B24BST03"
addPower({ res = "B24WCOMP", when = function(s) return B24DR.Level(s) >= 2 end })

function B24WCOMP(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Spend(sprite, "WILD_SHAPE", 1) then return end
		B24.Summon(sprite, B24DR.COMPANION, 3600)
		B24.Log(string.format("%s: Wild Companion", B24.Name(sprite)))
	end)
end

-- Wild Resurgence (5): with no Wild Shape uses left, once per round the lowest ready spell slot
-- buys one back (B24WRES1); once per long rest, a Wild Shape use buys back a spent 1st-level slot
-- (B24WRES2). Local B24WRUSE.
local function noUses(sprite) return B24LV.Remaining(sprite, "WILD_SHAPE") == 0 end

function B24DR.RefreshResurgence(sprite)
	local level = B24DR.Level(sprite)
	local slot = B24SP and B24SP.ReadySlotLevel and B24SP.ReadySlotLevel(sprite, false, 1)
	B24LV.Grant(sprite, "B24WRES1", level >= 5 and noUses(sprite) and slot ~= nil)
end

addPower({ res = "B24WRES2", when = function(s)
	return B24DR.Level(s) >= 5 and s:getLocalInt("B24WRUSE") == 0 and B24SP ~= nil and B24SP.UnreadyEntries ~= nil
		and #B24SP.UnreadyEntries(s, false, 1) > 0
end })

function B24WRES1(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not noUses(sprite) or not B24LV.OncePerRound(sprite, "WILD_RESURGENCE") then return end
		local slot = B24SP.SpendSlot(sprite, false, 1)
		if slot == nil then return end
		sprite:setLocalInt("B24WSUSE", math.max(0, sprite:getLocalInt("B24WSUSE") - 1))
		B24LV.Rebuild(sprite, "WILD_SHAPE")
		B24DR.RefreshResurgence(sprite)
		B24.Log(string.format("%s: Wild Resurgence (a level %d slot for a Wild Shape use)", B24.Name(sprite), slot))
	end)
end

function B24WRES2(op402, sprite)
	EEex_Utility_TryIgnore(function()
		local entries = B24SP.UnreadyEntries(sprite, false, 1)
		if #entries == 0 or sprite:getLocalInt("B24WRUSE") == 1 or not B24LV.Spend(sprite, "WILD_SHAPE", 1) then return end
		B24SP.Restore(entries[1])
		sprite:setLocalInt("B24WRUSE", 1)
		B24LV.RefreshPowers(sprite, "WILD_SHAPE")
		B24.Log(string.format("%s: Wild Resurgence (a 1st-level slot for a Wild Shape use)", B24.Name(sprite)))
	end)
end

B24LV.AddTickListener(function(sprite)
	if B24DR.Level(sprite) >= 5 then B24DR.RefreshResurgence(sprite) end
end)

-- Natural Recovery (Land 6): once per long rest, after a short rest, spent slots worth up to half
-- the Druid level (rounded up) come back, none above 5th, the highest first. Local B24NRUSE. (Its
-- free circle spell waits for the circle spells.)
B24.AddShortRestListener(function(sprite)
	local level = B24DR.Level(sprite)
	if level < 6 or not isLand(sprite) or sprite:getLocalInt("B24NRUSE") == 1 or B24SP == nil or B24SP.UnreadyEntries == nil then return end
	local budget, restored = math.ceil(level / 2), {}
	for spellLevel = math.min(5, budget), 1, -1 do
		for _, entry in ipairs(B24SP.UnreadyEntries(sprite, false, spellLevel)) do
			if budget >= spellLevel then
				B24SP.Restore(entry)
				budget = budget - spellLevel
				table.insert(restored, spellLevel)
			end
		end
	end
	if #restored > 0 then
		sprite:setLocalInt("B24NRUSE", 1)
		B24.Log(string.format("%s: Natural Recovery (spell slots of level %s)", B24.Name(sprite), table.concat(restored, ", ")))
	end
end)

-- Nature's Sanctuary (Land 14): a Wild Shape use; for a minute you and the allies near you get +2
-- AC (half cover from the trees) and your land's Nature's Ward resistance.
addPower({ res = "B24NSANC", when = function(s) return B24DR.Level(s) >= 14 and isLand(s) end })

function B24NSANC(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if not B24LV.Spend(sprite, "WILD_SHAPE", 1) then return end
		local landKey = B24LV.Option(sprite, "LAND_TYPE")
		local resist
		for _, land in ipairs(B24DR.LANDS) do
			if land.key == landKey then resist = land.resist end
		end
		local allies = EEex_Sprite_GetAllOfTypeStringInRange(sprite, "[PC]", B24.Feet(15), true) or {}
		local selfIncluded = false
		for _, ally in ipairs(allies) do selfIncluded = selfIncluded or ally.m_id == sprite.m_id end
		if not selfIncluded then table.insert(allies, sprite) end
		for _, ally in ipairs(allies) do
			-- (An AC effect with a source resource is not applied by the engine.)
			B24.ApplyEffect(ally, { ["effectID"] = 0, ["effectAmount"] = 2, ["dwFlags"] = 0, ["durationType"] = 0, ["duration"] = 60 })
			if resist then
				B24.ApplyEffect(ally, { ["effectID"] = resist, ["effectAmount"] = 50, ["durationType"] = 0, ["duration"] = 60 })
			end
		end
		B24.Log(string.format("%s: Nature's Sanctuary", B24.Name(sprite)))
	end)
end

-- Archdruid (20): a fight that starts with no Wild Shape uses left brings one back (Evergreen
-- Wild Shape); once per long rest, Wild Shape uses turn into a spent spell slot, two slot levels
-- per use (Nature Magician, B24NMAGI). Local B24NMUSE.
B24.AddCombatStartListener(function(sprite)
	if B24DR.Level(sprite) < 20 or not noUses(sprite) then return end
	sprite:setLocalInt("B24WSUSE", math.max(0, sprite:getLocalInt("B24WSUSE") - 1))
	B24LV.Rebuild(sprite, "WILD_SHAPE")
	B24.Log(string.format("%s: Evergreen Wild Shape", B24.Name(sprite)))
end)

addPower({ res = "B24NMAGI", when = function(s) return B24DR.Level(s) >= 20 and s:getLocalInt("B24NMUSE") == 0 end })

function B24NMAGI(op402, sprite)
	EEex_Utility_TryIgnore(function()
		if sprite:getLocalInt("B24NMUSE") == 1 or B24SP == nil then return end
		local uses = B24LV.Remaining(sprite, "WILD_SHAPE")
		for spellLevel = math.min(7, uses * 2), 1, -1 do
			local entries = B24SP.UnreadyEntries(sprite, false, spellLevel)
			if #entries > 0 then
				local cost = math.ceil(spellLevel / 2)
				if B24LV.Spend(sprite, "WILD_SHAPE", cost) then
					B24SP.Restore(entries[1])
					sprite:setLocalInt("B24NMUSE", 1)
					B24LV.RefreshPowers(sprite, "WILD_SHAPE")
					B24.Log(string.format("%s: Nature Magician (a level %d slot for %d Wild Shape uses)", B24.Name(sprite), spellLevel, cost))
				end
				return
			end
		end
	end)
end

B24.AddLongRestListener(function(sprite)
	sprite:setLocalInt("B24WRUSE", 0)
	sprite:setLocalInt("B24NRUSE", 0)
	sprite:setLocalInt("B24NMUSE", 0)
end)
