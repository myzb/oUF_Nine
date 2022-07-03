local _, ns = ...

local filters, config = {}, ns.config
config.filters = filters

-- ------------------------------------------------------------------------
-- > FILTERS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > UNIT BLACKLISTS / WHITELISTS
-- -----------------------------------

filters.player = {
	blacklist = {},
	whitelist = {}
}

filters.target = {
	blacklist = {},
	whitelist = {}
}

filters.focus = {
	blacklist = {},
	whitelist = {}
}

filters.boss = {
	blacklist = {},
	whitelist = {}
}

filters.nameplate = {
	blacklist = {},
	whitelist = {
		-- Mage
		[12654] = true,		-- Ignite
		[2120] = true,		-- Flamestrike
	}
}

filters.raid = {
	blacklist = {},
	whitelist = {}
}

filters.arena = {
	blacklist = {},
	whitelist = {}
}


-- -----------------------------------
-- > CUSTOM FRAME COLORING
-- -----------------------------------

local teal = { 0/255, 121/255 , 107/255, 0.85 }
local purple = { 179/255, 136/255, 255/255, 0.85 }

filters.color = {}

-- Units
filters.color.unit = {
}

-- Auras
filters.color.aura = {
	-- Death Knight
	-- Demon Hunter
	-- Druid
	-- Hunter
	-- Mage
	-- Monk
	-- Paladin
	[287268] = teal,	-- Glimmer of Light (Holy)
	-- Priest
	[194384] = teal,	-- Atonement (Discipline)
	-- Rogue
	-- Shaman
	-- Warrior
	-- Warlock
	-- Other
}