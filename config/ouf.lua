local _, ns = ...

local oUF = ns.oUF

-- ------------------------------------------------------------------------
-- > OUF OVERRIDES
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > COLORS
-- -----------------------------------

-- partially modify oUF power colors
oUF.colors.power.MANA = { 1/255, 121/255, 228/255 }
oUF.colors.power[0] = oUF.colors.power.MANA
oUF.colors.power.RAGE = { 255/255, 26/255, 48/255 }
oUF.colors.power[1] = oUF.colors.power.RAGE
oUF.colors.power.FOCUS = { 255/255, 192/255, 0/255 }
oUF.colors.power[2] = oUF.colors.power.FOCUS
oUF.colors.power.ENERGY = { 255/255, 238/255, 88/255 }
oUF.colors.power[3] = oUF.colors.power.ENERGY
--oUF.colors.power[4] = oUF.colors.power.COMBO_POINTS
oUF.colors.power.RUNES = { 0/255, 200/255, 255/255 }
oUF.colors.power[5] = oUF.colors.power.RUNES
oUF.colors.power.RUNIC_POWER = { 134/255, 239/255, 254/255 }
oUF.colors.power[6] = oUF.colors.power.RUNIC_POWER
--oUF.colors.power[7] = oUF.colors.power.SOUL_SHARDS
oUF.colors.power.LUNAR_POWER = { 134/255, 143/255, 254/255 }
oUF.colors.power[8] = oUF.colors.power.LUNAR_POWER
--oUF.colors.power[9] = oUF.colors.power.HOLY_POWER
oUF.colors.power.MAELSTROM = { 0/255, 200/255, 255/255 }
oUF.colors.power[11] = oUF.colors.power.MAELSTROM
--oUF.colors.power[12] = oUF.colors.power.CHI
oUF.colors.power.INSANITY = { 137/255, 76/255, 219/255 }
oUF.colors.power[13] = oUF.colors.power.INSANITY
--oUF.colors.power[16] = oUF.colors.power.ARCANE_CHARGES
oUF.colors.power.FURY = { 255/255, 50/255, 50/255 }
oUF.colors.power[17] = oUF.colors.power.FURY
--oUF.colors.power[18] = oUF.colors.power.PAIN

oUF.colors.runes = {
	[1] = { 225/255, 75/255, 75/255 },   -- Blood
	[2] = { 50/255, 160/255, 250/255 },  -- Frost
	[3] = { 100/255, 225/255, 125/255 }, -- Unholy
}

oUF.colors.reaction = {
	[1] = { 182/255, 34/255, 32/255 }, -- Hated / Enemy
	[2] = { 182/255, 34/255, 32/255 },
	[3] = { 182/255, 92/255, 32/255 },
	[4] = { 220/225, 180/255, 52/255 },
	[5] = { 132/255, 181/255, 26/255 },
	[6] = { 132/255, 181/255, 26/255 },
	[7] = { 132/255, 181/255, 26/255 },
	[8] = { 132/255, 181/255, 26/255 },
	[9] = { 0/255, 110/255, 255/255 }, -- Paragon (Reputation)
}

-- partially modify/extend oUF threat colors
oUF.colors.threat[2] = { 255/255, 153/255, 153/255 } -- insecurely tanking (light-red)
oUF.colors.threat[3] = { 0/255, 255/255, 255/255 }   -- securely tanking (cyan)
oUF.colors.threat[4] = { 179/255, 136/255, 255/255 } -- off-tank tanking (purple)

oUF.colors.castbar = {
	['CAST'] = { 209/255, 157/255, 21/255 },   -- orange/brown
	['CHANNEL'] = { 0/255, 191/255, 0/255 },   -- green
	['FAILED'] = { 233/255, 0/255, 0/255 },    -- orange/red
	['IMMUNE'] = { 178/255, 178/255, 178/255 } -- gray
}
