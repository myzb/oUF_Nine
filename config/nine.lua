local _, ns = ...

local config, m, oUF = {}, ns.m, ns.oUF
ns.config = config

-- ------------------------------------------------------------------------
-- > CONFIGURATION
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > GENERAL SETTINGS
-- -----------------------------------

config.fontsize = 14 -- global base fontsize

config.frame = {
	alpha = 1.0,

	range = {
		insideAlpha = 1,
		outsideAlpha = 0.25
	},
	colors = {
		-- fg/bg combinations used by custom colored health frames
		base = {
			fg = { 25/255, 25/255, 25/255, 0.8 },    -- dark gray
			bg = { 239/255, 154/255, 154/255, 0.8 }  -- light red
		},
		away = {
			fg = { 102/255, 102/255, 102/255, 1.0 }, -- med gray
			bg = { 239/255, 154/255, 154/255, 0.8 }  -- light red
		},
		dead = {
			fg = { 25/255, 25/255, 25/255, 0.8 }, -- dark gray
			bg = { 0, 0, 0, 0.9 }                 -- black
		},
		-- background used by other frames
		bg = { 0, 0, 0, 0.7 }
	},
	shadows = { 0, 0, 0, 0.7 }
}

-- -----------------------------------
-- > MISCELLANEOUS
-- -----------------------------------

config.misc = {
	talkinghead = {
		hide = true
	},

	gametooltip = {
		move = true,
		pos = { a1 = 'BOTTOMRIGHT', af = 'UIParent', a2 = 'BOTTOMRIGHT', x = -10, y = 200 }
	},

	raidframes = {
		hide = true
	}
}

-- -----------------------------------
-- > FRAME LAYOUTS
-- -----------------------------------

local layout = {
	main = {
		width = 180,
		height = 51,
		shadows = true,
		health = {
			colorCustom = true,
			colorClass = true,
			colorReaction = true
		},
		spacer = {
			height = 4
		},
		power = {
			height = 6,
			colorClass = false,
			frequentUpdates = true
		}
	},

	secondary = {
		width = 90,
		height = 51,
		shadows = true,
		health = {
			colorCustom = true,
			colorClass = true,
			colorReaction = true
		},
		spacer = {
			height = 4
		},
		power = {
			height = 6,
			colorClass = false,
			frequentUpdates = true
		}
	},

	group = {
		width = -1,  -- dynamic
		height = -1, -- dynamic
		texture = m.textures.flat,
		shadows = false,
		health = {
			colorCustom = true,
			colorClass = true,
			colorReaction = false,
			colorOnBuff = true
		},
		spacer = {
			height = 0,
		},
		power = {
			height = 4,
			colorClass = false,
			displayAltPower = true
		}
	},

	raid = {
		width = -1,  -- dynamic
		height = -1, -- dynamic
		texture = m.textures.flat,
		shadows = false,
		health = {
			colorCustom = true,
			colorClass = true,
			colorReaction = false,
			colorOnBuff = true
		}
	}
}

-- -----------------------------------
-- > UNITS
-- -----------------------------------

config.units = {
	player = {
		show = true,
		pos = { a1 = 'TOPRIGHT', af = 'UIParent', a2 = 'CENTER', x = -272, y = -205 },
		layout = layout['main'],
		auras = {
			show = true,
			cols = 4,
			rows = 4
		},
		castbar = {
			show = true,
			pos = { a1 = 'BOTTOM', af = 'UIParent', a2 = 'CENTER', x = 0, y = -177 },
			width = 196,
			height = 17,
			latency = {
				show = false,
				color = { 1, 0, 0, 0.5 }
			}
		},
		altpower = { -- boss encounter resources i.e sanity (n'zoth)
			show = true,
			pos = { a1 = 'TOP', af = 'UIParent', a2 = 'CENTER', x = 0, y = -177 },
			width = 196,
			height = 9
		},
		classpower = { -- i.e combo points, holy power, mana
			show = true,
			text = false
		},
		totems = { -- totems and guardians i.e shadowfiend, gargoyle
			show = false
		},
		infobars = { -- xp, rep, etc.: dynamically stacked on-top of each other
			show = false,
			height = 10,
			width = 465,
			sep = 1,
			pos = {
				h = { a1 = 'LEFT', af = 'UIParent', a2 = 'LEFT', x = 6, y = 0 },
				v = { a1 = 'BOTTOM', af = 'UIParent', a2 = 'BOTTOM', x = 0, y = 6 }
			}
		}
	},

	target = {
		show = true,
		pos = { a1 = 'TOPLEFT', af = 'UIParent', a2 = 'CENTER', x = 272, y = -205 },
		layout = layout['main'],
		auras = {
			show = true,
			cols = 4,
			rows = 4,
		},
		castbar = {
			show = true,
			pos = { a1 = 'TOPRIGHT', af = 'oUF_NineTarget', a2 = 'BOTTOMRIGHT', x = 0, y = -6 },
			width = 180,
			height = 17
		},
		altpower = {
			show = true,
			pos = { a1 = 'TOPRIGHT', af = 'oUF_NineTarget', a2 = 'BOTTOMRIGHT', x = 0, y = -6 },
			width = 180,
			height = 9
		}
	},

	targettarget = {
		show = true,
		pos = { a1 = 'TOPLEFT', af = 'oUF_NineTarget', a2 = 'TOPRIGHT', x = 10, y = 0 },
		layout = layout['secondary'],
	},

	focus = {
		show = true,
		pos = { a1 = 'TOPRIGHT', af = 'oUF_NinePlayer', a2 = 'BOTTOMRIGHT', x = 0, y = -50 },
		layout = layout['main'],
		auras = {
			show = true,
			warn = true,
			size = 18,
			cols = 3,
			rows = 1
		},
		castbar = {
			show = true,
			pos = { a1 = 'TOPRIGHT', af = 'oUF_NineFocus', a2 = 'BOTTOMRIGHT', x = 0, y = -6 },
			width = 180,
			height = 17
		}
	},

	focustarget = {
		show = true,
		pos = { a1 = 'TOPRIGHT', af = 'oUF_NineFocus', a2 = 'BOTTOMRIGHT', x = 0, y = -32 },
		layout = {
			width = 180,
			height = 21,
			shadows = true,
			health = {
				colorCustom = true,
				colorClass = true,
				colorReaction = true
			},
		}
	},

	pet = {
		show = true,
		pos = { a1 = 'TOPRIGHT', af = 'oUF_NinePlayer', a2 = 'TOPLEFT', x = -10, y = 0 },
		layout = layout['secondary'],
		castbar = {
			show = true,
			pos = { a1 = 'TOPRIGHT', af = 'oUF_NinePet', a2 = 'BOTTOMRIGHT', x = 0, y = -8 },
			width = 90,
			height = 15
		}
	},

	boss = {
		show = true,
		pos = { a1 = 'RIGHT', af = 'UIParent', a2 = 'CENTER', x = 825, y = 300 },
		sep = 40, -- separation between boss frames
		layout = {
			width = 150,
			height = 60,
			shadows = true,
			health = {
				colorCustom = true,
				colorReaction = true
			},
			spacer = {
				height = 1
			},
			power = {
				height = 10,
				colorClass = false,
				frequentUpdates = true
			},
		},
		debuffs = {
			show = true,
			cols = 2,
			rows = 2,
			size = 30
		},
		castbar = {
			show = true,
			pos = { a1 = 'TOPRIGHT', a2 = 'BOTTOMRIGHT', x = 0, y = -10 },
			width = 150,
			height = 17
		}
	},

	raid = {
		show = true,
		{ -- Raid 1-5man (Party)
			visibility = { role = 'TANK,DAMAGER,HEALER', from = 0, to = 5 },
			pos = { a1 = 'TOPRIGHT', af = 'UIParent', a2 = 'CENTER', x = -462, y = 260 },
			grid = { cols = 1, rows = 5, sep = 2, width = 140, height = 350 },
			sort = 'GROUP',
			grow = 'DOWNLEFT',
			layout = layout['group'],
			auras = { warn = true, rows = 1 },
			misc = { hideHPPerc = false },
			pets = { show = true, anchor = 'BOTTOMLEFT', num = 4 }
		},
		{ -- Raid 6-10man healer
			visibility = { role = 'HEALER', from = 6, to = 10 },
			pos = { a1 = 'TOP', af = 'UIParent', a2 = 'CENTER', x = 0, y = -260 },
			grid = { cols = 5, rows = 2, sep = 2, width = 540, height = 100 },
			sort = 'GROUP',
			grow = 'LEFTDOWN',
			layout = layout['raid'],
			auras = { rows = 1 },
			misc = { hideHPPerc = true }
		},
		{ -- Raid 11-25man healer
			visibility = { role = 'HEALER', from = 11, to = 25 },
			pos = { a1 = 'TOP', af = 'UIParent', a2 = 'CENTER', x = 0, y = -260 },
			grid = { cols = 5, rows = 5, sep = 2, width = 540, height = 250 },
			sort = 'GROUP',
			grow = 'LEFTDOWN',
			layout = layout['raid'],
			auras = { rows = 1 },
			misc = { hideHPPerc = true, rightClickthrough = true }
		},
		{ -- Raid 26-40man healer
			visibility = { role = 'HEALER', from = 26, to = 40 },
			pos = { a1 = 'TOP', af = 'UIParent', a2 = 'CENTER', x = 0, y = -260 },
			grid = { cols = 8, rows = 5, sep = 2, width = 540, height = 250 },
			sort = 'GROUP',
			grow = 'LEFTDOWN',
			layout = layout['raid'],
			auras = { cols = 2, rows = 1 },
			misc = { hideHPPerc = true, rightClickthrough = true }
		},
		{ -- Raid 6-20man tank/dps
			visibility = { role = 'TANK,DAMAGER', from = 6, to = 20 },
			pos = { a1 = 'TOPLEFT', af = 'UIParent', a2 = 'CENTER', x = -1025, y = 450 },
			grid = { cols = 2, rows = 10, sep = 2, width = 200, height = 500 },
			sort = 'GROUP',
			grow = 'DOWNLEFT',
			layout = layout['raid'],
			auras = { rows = 1 },
			misc = { hideHPPerc = true }
		},
		{ -- Raid 21-40man tank/dps
			visibility = { role = 'TANK,DAMAGER', from = 21, to = 40 },
			pos = { a1 = 'TOPLEFT', af = 'UIParent', a2 = 'CENTER', x = -1025, y = 500 },
			grid = { cols = 3, rows = 15, sep = 2, width = 300, height = 750 },
			sort = 'GROUP',
			grow = 'DOWNLEFT',
			layout = layout['raid'],
			auras = { cols = 2, rows = 1 },
			misc = { hideHPPerc = true }
		},
		--[[
		{ -- Debug
			visibility = { role = 'HEALER,TANK,DAMAGER', from = 0, to = 40 },
			pos = { a1 = 'TOP', af = 'UIParent', a2 = 'CENTER', x = 0, y = -260 },
			grid = { cols = 5, rows = 5, sep = 2, width = 540, height = 250 },
			sort = 'GROUP',
			grow = 'LEFTDOWN',
			layout = layout['raid'],
			auras = { cols = 2, rows = 1 },
			misc = { hideHPPerc = false }
		},
		--]]
	},

	nameplate = {
		show = true,
		sep = 4,
		pos = { a1 = 'CENTER', x = 0, y = 0 },
		layout = {
			width = 160, -- of hit-box
			height = 10, -- of hit-box
			shadows = true,
			health = {
				colorClass = true,
				colorThreat = true,
				colorReaction = true,
				executeRange = true,
				focusHighlight = true
			}
		},
		buffs = {
			show = true,
			size = 24,
			cols = 2
		},
		debuffs = {
			show = true,
			warn = false,
			size = 24,
			cols = 4
		},
		castbar = {
			show = true,
			width = 160,
			height = 15
		},
		targetIndicator = {
			show = false,
			offset = 15,
			width = 16,
			height = 32
		},
		misc = {
			hideHPPerc = true,
		},
	},

	arena = {
		show = false,
		pos = { a1 = 'TOPLEFT', af = 'UIParent', a2 = 'CENTER', x = 462, y = 260 },
		sep = 40, -- separation between arena frames
		layout = {
			width = 150,
			height = 60,
			shadows = true,
			health = {
				colorCustom = true,
				colorReaction = true
			},
			spacer = {
				height = 1
			},
			power = {
				height = 10,
				colorClass = false,
				frequentUpdates = true
			},
		},
		debuffs = {
			show = true,
			cols = 2,
			rows = 2,
			size = 30
		},
		castbar = {
			show = true,
			pos = { a1 = 'TOPRIGHT', a2 = 'BOTTOMRIGHT', x = 0, y = -10 },
			width = 150,
			height = 17
		}
	}
}
