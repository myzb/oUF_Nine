local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'focus'

-- Import API Functions
local Auras_ShouldDisplayDebuff = CompactUnitFrame_Util_ShouldDisplayDebuff -- FrameXML/CompactUnitFrame.lua
local Auras_ShouldDisplayBuff = CompactUnitFrame_UtilShouldDisplayBuff      -- FrameXML/CompactUnitFrame.lua

-- ------------------------------------------------------------------------
-- > FOCUS UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > FOCUS AURA SPECIFIC FUNCTIONS
-- -----------------------------------

local function RaidAuras_PreUpdate(element, unit)
	element.hasWarn = false
end

-- Filter Buffs
local function Buffs_CustomFilter(element, unit, button, isDispellable, ...)
	local spellId = select(10, ...)

	-- buffs white-/blacklist
	if (filters[frame_name]['whitelist'][spellId]) then
		return auras.BUFF_WHITELIST
	end
	if (filters[frame_name]['blacklist'][spellId]) then
		return false
	end

	-- get buff priority and warn level
	local prio, warn = auras:GetBuffPrio(unit, ...)

	-- blizzard raid-frames filtering function
	if (not (Auras_ShouldDisplayBuff(...) or warn)) then
		return false
	end
	if (warn and element.hasWarn) then
		return false
	end
	if (warn) then
		element.hasWarn = true
	end
	button.prio = prio

	return (warn and 'S') or prio
end

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, isDispellable, ...)
	local spellId = select(10, ...)

	-- auras white-/blacklist
	if (filters.raid['whitelist'][spellId]) then
		return auras.DEBUFF_WHITELIST
	end
	if (filters.raid['blacklist'][spellId]) then
		return false
	end

	-- blizzard raid-frames filtering function
	if (not Auras_ShouldDisplayDebuff(...)) then
		return false
	end

	-- get debuff priority and warn level
	local prio, warn = auras:GetDebuffPrio(unit, isDispellable, ...)
	button.prio = prio

	return (element.showSpecial and warn and 'S') or prio
end

-- -----------------------------------
-- > FOCUS STYLE
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
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.unit = core:CreateFontstring(text, font, config.fontsize -2, nil, 'LEFT')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetPoint('TOPLEFT', 1, -2)
	text.unit:SetSize(0.8 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:name]')
	end

	text.status = core:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
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
		local castbar = core:CreateCastbar(self, cfg.width, cfg.height)
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
	local QuestIcon = core:CreateFontstring(self, font, 26, 'THINOUTLINE', 'CENTER')
	QuestIcon:SetPoint('LEFT', self.Health, 'RIGHT', 0, -2)
	QuestIcon:SetText('!')
	QuestIcon:SetTextColor(238/255, 217/255, 43/255)
	self.QuestIndicator = QuestIcon

	-- auras
	if (uframe.auras.show) then
		local cols = (uframe.auras.cols) or 4
		local size = (uframe.auras.size) or math.floor(self:GetWidth() / (2 * (cols + 0.25)))

		local raidBuffs = auras:CreateRaidAuras(icons, size, cols, cols + 0.5, 1, size - 6)
		raidBuffs:SetPoint('BOTTOMRIGHT', self.Health, 'BOTTOMRIGHT', -2, 2)
		raidBuffs.initialAnchor = 'BOTTOMRIGHT'
		raidBuffs['growth-x'] = 'LEFT'
		raidBuffs['growth-y'] = 'UP'
		raidBuffs.showStealableBuffs = true
		raidBuffs.special:SetPoint('TOPRIGHT', self.Health, 'TOPRIGHT', -2, -2)
		raidBuffs.PreUpdate = RaidAuras_PreUpdate
		raidBuffs.CustomFilter = Buffs_CustomFilter

		self.RaidBuffs = raidBuffs

		local raidDebuffs = auras:CreateRaidAuras(icons, size, cols, cols + 0.5, 1, size + 8)
		raidDebuffs:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 2, 2)
		raidDebuffs.initialAnchor = 'BOTTOMLEFT'
		raidDebuffs['growth-x'] = 'RIGHT'
		raidDebuffs['growth-y'] = 'UP'
		raidDebuffs.showDebuffType = true
		raidDebuffs.special:SetPoint('CENTER', self.Health, 'CENTER', 0, 0)
		raidDebuffs.showSpecial = uframe.auras.warn
		raidDebuffs.dispelIcon = CreateFrame('Button', nil, raidDebuffs)
		raidDebuffs.dispelIcon:SetPoint('TOPRIGHT', self.Health)
		raidDebuffs.dispelIcon:SetSize(14, 14)
		raidDebuffs.CustomFilter = Debuffs_CustomFilter

		self.RaidDebuffs = raidDebuffs
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
