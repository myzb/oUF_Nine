local _, ns = ...

local filters = {}
ns.filters = filters

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
	whitelist = {}
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
-- > CLASS AURA COLORING
-- -----------------------------------

local teal = { 0/255, 121/255 , 107/255, 0.85 }

filters.auracolor = {
	-- Demon Hunter
	-- Death Knight
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
