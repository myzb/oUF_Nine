local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'target'

-- Import API Functions
local UnitIsUnit = UnitIsUnit
local Auras_ShouldDisplayDebuff = TargetFrame_ShouldShowDebuffs -- FrameXML/TargetFrame.lua

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
local function Buffs_CustomFilter(element, unit, button, ...)
	local spellId = select(10, ...)

	-- hide blacklisted buffs
	if (filters.buffs['blacklist'][spellId]) then
		return false
	end
	-- get buff priority and warn level
	button.prio = auras:GetBuffPrio(...)
	-- show all buffs
	return true
end

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, ...)
	local name = select(1, ...)
	local caster = select(7, ...)
	local spellId = select(10, ...)
	local casterIsPlayer = select(13, ...)
	local nameplateShowAll = select(14, ...)

	-- hide blacklisted debuffs
	if (filters.debuffs['blacklist'][spellId]) then
		return false
	end
	-- blizzard target-/focus frame filtering function
	return Auras_ShouldDisplayDebuff(unit, caster, nameplateShowAll, casterIsPlayer)
end

-- -----------------------------------
-- > TARGET STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	core:CreateLayout(self, layout)

	-- mouse events
	core:RegisterMouse(self)

	-- text strings
	local health = CreateFrame('Frame', nil, self.Health)
	health:SetAllPoints()
	health.level = core:CreateFontstring(health, font, config.fontsize -2, nil, 'LEFT')
	health.level:SetShadowColor(0, 0, 0, 1)
	health.level:SetShadowOffset(1, -1)
	health.level:SetPoint('TOPLEFT', 1, -2)
	self:Tag(health.level, '[n:difficultycolor][level]')

	health.unitname = core:CreateFontstring(health, font, config.fontsize -2, nil, 'LEFT')
	health.unitname:SetShadowColor(0, 0, 0, 1)
	health.unitname:SetShadowOffset(1, -1)
	health.unitname:SetPoint('LEFT', health.level, 'RIGHT', 1, 0)
	health.unitname:SetSize(0.8 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(health.unitname, '[n:unitcolor][n:name]')
	else
		self:Tag(health.unitname, '[n:name]')
	end

	health.hpvalue = core:CreateFontstring(health, font_num, config.fontsize +1, nil, 'RIGHT')
	health.hpvalue:SetShadowColor(0, 0, 0, 1)
	health.hpvalue:SetShadowOffset(1, -1)
	health.hpvalue:SetPoint('RIGHT', -4, 0)
	self:Tag(health.hpvalue, '[n:hpvalue]')
	health.hpperc = core:CreateFontstring(health, font_num, config.fontsize +1, nil, 'CENTER')
	health.hpperc:SetPoint('CENTER', 0, 0)
	if (layout.health.colorCustom) then
		self:Tag(health.hpperc, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(health.hpperc, '[n:perhp_status]')
	end

	local power = CreateFrame('Frame', nil, self.Power)
	power:SetAllPoints()
	power.value = core:CreateFontstring(power, font_num, config.fontsize +1, nil, 'RIGHT')
	power.value:SetShadowColor(0, 0, 0, 1)
	power.value:SetShadowOffset(1, -1)
	power.value:SetPoint('RIGHT', -4, 0)
	self:Tag(power.value, '[n:powervalue]')

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local cfg = uframe.castbar
		local castbar = core:CreateCastbar(self, cfg.width, cfg.height)
		castbar:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		self.Castbar = castbar
	end

	-- alternative power (quest or boss special power)
	if (uframe.altpower and uframe.altpower.show) then
		local cfg = uframe.altpower
		local altpower = core:CreateAltPower(self, cfg.width, cfg.height, layout.texture)
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
	local QuestIcon = core:CreateFontstring(self, font, 26, 'THINOUTLINE', 'CENTER')
	QuestIcon:SetPoint('LEFT', self.Health, 'RIGHT', 0, -2)
	QuestIcon:SetText('!')
	QuestIcon:SetTextColor(238/255, 217/255, 43/255)
	self.QuestIndicator = QuestIcon

	-- Auras
	if (uframe.auras.show) then
		local cols = (uframe.auras.cols) or 4
		local size = (uframe.auras.size) or floor(self:GetWidth() / (2 * (cols + 0.25)))
		local buffs = auras:CreateAuras(self, 15, cols, 4, size, 1)
		buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 4)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true
		buffs.CustomFilter = Buffs_CustomFilter
		self.Buffs = buffs

		local debuffs = auras:CreateAuras(self, 15, cols, 4, size, 1)
		debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 4)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.showDebuffType = true
		debuffs.CustomFilter = Debuffs_CustomFilter
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
