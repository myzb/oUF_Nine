local A, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF
local auras = ns.auras

local filters = config.filters
local spells = config.spells

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'focus'

-- ------------------------------------------------------------------------
-- > FOCUS UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > FOCUS AURA SPECIFIC FUNCTIONS
-- -----------------------------------

-- Filter Buffs
local function Buffs_FilterAura(element, unit, data)

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[data.spellId]) then
		return true
	end
	if (filters[frame_name].blacklist[data.spellId]) then
		return false
	end

	-- filter special auras
	if (element.special) then
		if (spells.external[data.spellId]) then
			element.special.active[data.auraInstanceID] = data
			return true
		elseif (spells.personal[data.spellId]) then
			element.special.active[data.auraInstanceID] = data
			return true
		end
	end

	return auras:RaidShowBuffs(unit, data)
end

-- Filter Debuffs
local function Debuffs_FilterAura(element, unit, data)

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[data.spellId]) then
		return true
	end
	if (filters[frame_name].blacklist[data.spellId]) then
		return false
	end

	-- filter dispellable auras
	if (element.dispel) then
		if (data.canDispel) then
			element.dispel.active[data.auraInstanceID] = data
		end
	end

	-- filter special auras
	if (element.special) then
		if (not data.isFromPlayerOrPlayerPet and data.canDispel) then
			element.special.active[data.auraInstanceID] = data
			return true
		elseif (spells.crowdcontrol[data.spellId]) then
			element.special.active[data.auraInstanceID] = data
			return true
		end
	end

	return auras:RaidShowDebuffs(unit, data)
end

-- -----------------------------------
-- > FOCUS STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	common:CreateLayout(self, layout)

	-- mouse events
	common:RegisterMouse(self)

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.unit = common:CreateFontstring(text, font, config.fontsize -2, nil, 'LEFT')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetPoint('TOPLEFT', 1, -2)
	text.unit:SetSize(0.8 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:name]')
	end

	text.status = common:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
	text.status:SetPoint('CENTER', 0, 0)
	if (layout.health.colorCustom) then
		self:Tag(text.status, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(text.status, '[n:perhp_status]')
	end
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local cfg = uframe.castbar
		local castbar = common:CreateCastbar(self, cfg.width, cfg.height)
		castbar:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		self.Castbar = castbar
	end

	-- icons frame (raid icons, leader, role, resting, ...)
	local icons = CreateFrame('Frame', nil, self.Health)
	icons:SetAllPoints()

	-- raid icons
	local raidIcon = icons:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', icons, 'TOP', 0, 5)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- quest icon
	local QuestIcon = common:CreateFontstring(self, font, 26, 'THINOUTLINE', 'CENTER')
	QuestIcon:SetPoint('LEFT', self.Health, 'RIGHT', 0, -2)
	QuestIcon:SetText('!')
	QuestIcon:SetTextColor(238/255, 217/255, 43/255)
	self.QuestIndicator = QuestIcon

	-- auras
	if (uframe.auras.show) then
		local cols = uframe.auras.cols or 4
		local size = uframe.auras.size or math.floor(self:GetWidth() / (2 * (cols + 0.25)))
		local rows = uframe.auras.rows or floor(2 * self:GetHeight() / (3 * size))

		local buffs = auras:CreateRaidAuras(icons, size, cols + 0.5, rows, 0, size - 4)
		buffs:SetPoint('BOTTOMRIGHT', self.Health, 'BOTTOMRIGHT', -2, 2)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true
		buffs.special:SetPoint('TOPRIGHT', self.Health)

		buffs.FilterAura = Buffs_FilterAura
		buffs.SortAuras = AuraUtil.DefaultAuraCompare

		self.Buffs = buffs

		local debuffs = auras:CreateRaidAuras(icons, size, cols, rows, 0, size + 8, true)
		debuffs:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 2, 2)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.dispel:SetPoint('TOPRIGHT', self.Health)
		debuffs.special:SetPoint('CENTER', self.Health)
		debuffs.special.isDebuff = true

		debuffs.FilterAura = Debuffs_FilterAura
		debuffs.SortAuras = auras.DebuffComparator

		self.Debuffs = debuffs
	end
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))
	oUF:Spawn(frame_name)
end
