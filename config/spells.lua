local _, ns = ...

local spells, config = {}, ns.config
config.spells = spells

-- ------------------------------------------------------------------------
-- > SPELL LISTS
-- ------------------------------------------------------------------------

spells.personal = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	[110909] = true,	-- Alter Time
	[235313] = true,	-- Blazing Barrier (Fire)
	[11426] = true,		-- Ice Barrier (Frost)
	[45438] = true,		-- Ice Block
	[32612] = true,		-- Invisibility
	[55342] = true,		-- Mirror Images
	-- Monk
	-- Paladin
	-- Priest
	[19236] = true,		-- Desperate Prayer
	[47585] = true,		-- Dispersion (Shadow)
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
	[324867] = true,	-- Fleshcraft (Necrolord)
	--[194384] = true	-- DEBUG: Atonement
}

spells.external = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	-- Monk
	-- Paladin
	-- Priest
	[33206] = true,		-- Pain Suppression (Discipline)
	[47788] = true,		-- Guardian Spirit (Holy)
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
}

spells.selfcast = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	[190319] = true,	-- Combustion (Fire)
	[12472] = true,		-- Icy Veins (Frost)
	[116014] = true,	-- Rune of Power
	[337299] = true,	-- Tempest Barrier (Conduit)
	-- Monk
	-- Paladin
	-- Priest
	[17] = true,		-- Power Word: Shield
	[15286] = true,		-- Vampiric Embrace (Shadow)
	[193223] = true,	-- Surrender to Madness (Shadow talent)
	[47536] = true,		-- Rapture (Discipline)
	[200183] = true,	-- Apotheosis (Holy talent)
	[337661] = true,	-- Translucent Image (Conduit)
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
	[310143] = true,	-- Soulshape (Nightfae)
}

spells.utility = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	-- Monk
	-- Paladin
	-- Priest
	[65081] = true,		-- Body and Soul (Discipline/Shadow talent)
	[121557] = true,	-- Angelic Feather (Discipline/Holy talent)
	[109964] = true,	-- Spirit Shell (Discipline talent)
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
}

spells.powerup = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	-- Monk
	-- Paladin
	-- Priest
	[10060] = true,		-- Power Infusion
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
}

spells.crowdcontrol = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	-- Monk
	-- Paladin
	-- Priest
	[8122] = true,		-- Psychic Scream
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
}
