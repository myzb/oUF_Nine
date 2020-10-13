local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'boss'

-- Import API functions
local Auras_ShouldDisplayDebuff = NameplateBuffContainerMixin.ShouldShowBuff -- Blizzard_NamePlates/Blizzard_NamePlates.lua

-- ------------------------------------------------------------------------
-- > BOSS UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > BOSS AURA SPECIFIC FUNCTIONS
-- -----------------------------------

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, ...)
	local name = select(1, ...)
	local duration = select(5, ...)
	local caster = select(7, ...)
	local showSelf = select(9, ...)
	local spellId = select(10, ...)
	local showAll = select(14, ...)

	-- hide blacklisted debuffs
	if (filters.debuffs['blacklist'][spellId]) then
		return false
	end
	-- blizzard's nameplate filtering function
	return button.isPlayer and Auras_ShouldDisplayDebuff(nil, name, caster, showSelf, showAll, duration)
end

-- -----------------------------------
-- > BOSS STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	core:CreateLayout(self, layout)

	-- mouse events
	core:RegisterMouse(self)

	-- text strings
	local health = CreateFrame('Frame', nil, self.Health)
	health:SetAllPoints()
	health.unitname = core:CreateFontstring(health, font, config.fontsize -1, nil, 'CENTER')
	health.unitname:SetShadowColor(0, 0, 0, 1)
	health.unitname:SetShadowOffset(1, -1)
	health.unitname:SetPoint('TOPLEFT', 2, -2)
	health.unitname:SetSize(layout.width - 10, config.fontsize + 1)
	if (layout.health.colorCustom) then
		self:Tag(health.unitname, '[n:unitcolor][n:name]')
	else
		self:Tag(health.unitname, '[n:name]')
	end

	health.hpperc = core:CreateFontstring(health, font_num, config.fontsize + 6, nil, 'CENTER')
	health.hpperc:SetPoint('CENTER', 0, -2)
	health.hpperc:SetSize(layout.width - 10, config.fontsize + 1)
	if (layout.health.colorCustom) then
		self:Tag(health.hpperc, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(health.hpperc, '[n:perhp_status]')
	end

	local power = CreateFrame('Frame', nil, self.Power)
	power:SetAllPoints()
	power.value = core:CreateFontstring(power, font_num, config.fontsize + 1, nil, 'CENTER')
	power.value:SetShadowColor(0, 0, 0, 1)
	power.value:SetShadowOffset(1, -1)
	power.value:SetPoint('CENTER')
	power.value:SetSize(layout.width - 10, config.fontsize + 1)
	self:Tag(power.value, '[n:powervalue]')

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local width, height, pos = uframe.castbar.width, uframe.castbar.height, uframe.castbar.pos
		local castbar = core:CreateCastbar(self, width, height)
		castbar:SetPoint(pos.a1, self, pos.a2, pos.x, pos.y)
		self.Castbar = castbar
	end

	-- raid icons
	local raidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', self, 'TOP', 40, 5)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- debuffs
	if (uframe.debuffs and uframe.debuffs.show) then
		local cols = uframe.debuffs.cols or 4
		local size = uframe.debuffs.size or math.floor(self:GetWidth() / (2 * (cols + 0.25)))
		local rows = uframe.debuffs.rows or math.floor(2 * self:GetHeight() / (3 * size))

		local debuffs = auras:CreateAuras(self, 15, cols, rows, size, 1)
		debuffs:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', 0, 0)
		debuffs.initialAnchor = 'BOTTOMRIGHT'
		debuffs['growth-x'] = 'LEFT'
		debuffs['growth-y'] = 'UP'
		debuffs.showDebuffType = true
		debuffs.filter = 'HARMFUL|INCLUDE_NAME_PLATE_ONLY'
		debuffs.CustomFilter = Debuffs_CustomFilter
		self.Debuffs = debuffs
	end

	self.Range = config.frame.range
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))

	local f = config.units[frame_name]
	for index = 1, MAX_BOSS_FRAMES or 5 do
		local boss = oUF:Spawn(frame_name .. index, 'oUF_NineBoss' .. index)
		--local boss = oUF:Spawn('target', 'oUF_NineBoss' .. index) -- Debug

		if (index == 1) then
			boss:SetPoint(f.pos.a1, f.pos.af, f.pos.a2, f.pos.x, f.pos.y)
		else
			boss:SetPoint('TOP', _G['oUF_NineBoss' .. index - 1], 'BOTTOM', 0, -f.sep)
		end
	end
end
