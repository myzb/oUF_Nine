local _, ns = ...

local filters = {}
ns.filters = filters

-- ------------------------------------------------------------------------
-- > AURAS LIST
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > BLACKLISTS / WHITELISTS
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

filters.buffs = {
	whitelist = {},
	blacklist = {
		[206150] = true,  -- bfa: Challenger's Might  (m+ scaling)
		[297871] = true,  -- bfa: Anglers' Water Striders (mount equipment)
		[17619] = true,   -- bfa: Alchemist Stone (trinket)
		[186401] = true,  -- bfa: Sign of the Skirmisher (arena bonus honor)
		[186403] = true,  -- bfa: Sign of Battle (bg bonus honor)
		[225787] = true,  -- bfa: Sign of the Warrior (extra end of dungeon reward)
		[225788] = true,  -- bfa: Sign of the Emissary (bonus reputation)
		[328136] = true,  -- bfa: Impressive Influence (bonus reputation)
		[264408] = true,  -- bfa: Soldier of the Horde (warmode)
		[269083] = true,  -- bfa: Enlisted (warmode)
		[308212] = true,  -- bfa: WoW's 15th Anniversary
	}
}

filters.debuffs = {
	whitelist = {},
	blacklist = {
		[206151] = true,  -- bfa: Challenger's Burden (m+ scaling)
	}
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
