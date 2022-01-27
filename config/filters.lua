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
	DEMONHUNTER = {},
	DEATHKNIGHT = {},
	DRUID = {},
	HUNTER = {},
	MAGE = {},
	MONK = {},
	PALADIN = {
		[287268] = teal  -- Glimmer of Light
	},
	PRIEST = {
		[194384] = teal  -- Atonement
	},
	ROGUE = {},
	SHAMAN = {},
	WARLOCK = {},
	WARRIOR = {},
}
