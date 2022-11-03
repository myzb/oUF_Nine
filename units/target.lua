local A, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF
local auras = ns.auras

local filters = config.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'target'

-- Import API Functions
local UnitIsUnit = UnitIsUnit

-- ------------------------------------------------------------------------
-- > TARGET UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- AltPower PreUpdate
local function AltPower_PreUpdate(self)
	-- player altpower is already showing next to player frame
	if (UnitIsUnit('target', 'player')) then
		self:Hide()
	end
	-- dynamically adjust castbar's position
	local castbar = self.__owner.Castbar
	if (castbar) then
		local pos = config.units[frame_name].castbar.pos
		castbar:SetPoint(pos.a1, (self:IsShown() and self) or pos.af, pos.a2, pos.x, pos.y)
	end
end

-- -----------------------------------
-- > TARGET AURA SPECIFIC FUNCTIONS
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

	return auras:TargetShowBuffs(unit, data)
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

	return auras:TargetShowDebuffs(unit, data)
end

-- -----------------------------------
-- > TARGET STYLE
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
	text:SetAllPoints(self)
	text.unit = common:CreateFontstring(text, font, config.fontsize -2, nil, 'LEFT')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetPoint('TOPLEFT', self.Health, 'TOPLEFT', 1, -2)
	text.unit:SetSize(0.8 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:name]')
	end

	text.health = common:CreateFontstring(text, font_num, config.fontsize +1, nil, 'RIGHT')
	text.health:SetShadowColor(0, 0, 0, 1)
	text.health:SetShadowOffset(1, -1)
	text.health:SetPoint('RIGHT', self.Health, 'RIGHT', -4, 0)
	self:Tag(text.health, '[n:curhp]')

	text.status = common:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
	text.status:SetPoint('CENTER', self.Health, 'CENTER', 0, 0)
	if (layout.health.colorCustom) then
		self:Tag(text.status, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(text.status, '[n:perhp_status]')
	end

	text.power = common:CreateFontstring(text, font_num, config.fontsize +1, nil, 'RIGHT')
	text.power:SetShadowColor(0, 0, 0, 1)
	text.power:SetShadowOffset(1, -1)
	text.power:SetPoint('RIGHT', self.Power, 'RIGHT', -4, 0)
	self:Tag(text.power, '[n:curpp]')
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local cfg = uframe.castbar
		local castbar = common:CreateCastbar(self, cfg.width, cfg.height)
		castbar:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		self.Castbar = castbar
	end

	-- alternative power (quest or boss special power)
	if (uframe.altpower and uframe.altpower.show) then
		local cfg = uframe.altpower
		local altpower = common:CreateAltPower(self, cfg.width, cfg.height, layout.texture)
		altpower:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		altpower.PreUpdate = AltPower_PreUpdate
		self.AlternativePower = altpower
	end

	-- icons frame (raid icons, leader, role, resting, ...)
	local icons = CreateFrame('Frame', nil, self.Health)
	icons:SetFrameLevel(self.Health:GetFrameLevel() +2)
	icons:SetAllPoints()

	-- raid icons
	local raidIcon = icons:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', icons, 'TOP', 0, 5)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- leader icon
	local leaderIcon = icons:CreateTexture(nil, 'OVERLAY')
	leaderIcon:SetPoint('CENTER', icons, 'TOPRIGHT', -8, -2)
	leaderIcon:SetSize(14, 14)
	self.LeaderIndicator = leaderIcon

	-- threat indicator
	local threat = icons:CreateTexture(nil, 'OVERLAY')
	threat:SetSize(16, 16)
	threat:SetPoint('CENTER', self.Power, 'BOTTOMLEFT')
	threat.feedbackUnit = 'player'
	self.ThreatIndicator = threat

	-- quest icon
	local QuestIcon = common:CreateFontstring(self, font, 26, 'THINOUTLINE', 'CENTER')
	QuestIcon:SetPoint('LEFT', self.Health, 'RIGHT', 0, -2)
	QuestIcon:SetText('!')
	QuestIcon:SetTextColor(238/255, 217/255, 43/255)
	self.QuestIndicator = QuestIcon

	-- Auras
	if (uframe.auras.show) then
		local cols = uframe.auras.cols or 4
		local rows = uframe.auras.rows or 4
		local size = uframe.auras.size or floor(self:GetWidth() / (2 * (cols + 0.25)))

		local buffs = auras:CreateAuras(self, size, cols, rows, 0)
		buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 4)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true
		buffs.FilterAura = Buffs_FilterAura
		self.Buffs = buffs

		local debuffs = auras:CreateAuras(self, size, cols, rows, 0)
		debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 4)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.showDebuffType = true
		debuffs.FilterAura = Debuffs_FilterAura
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
