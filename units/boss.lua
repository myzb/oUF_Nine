local A, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'boss'

-- Import API functions
local UnitIsConnected, UnitCanAssist, UnitCanAttack = UnitIsConnected, UnitCanAssist, UnitCanAttack
local UnitIsDead, UnitIsGhost = UnitIsDead, UnitIsGhost

-- ------------------------------------------------------------------------
-- > BOSS UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

local function RangeCheck_PostUpdate(element, parent, inRange, checkedRange, connected)
	if (not connected or checkedRange) then
		return
	end
	-- also treat non-interactive units as in rage
	if (common:UnitInRange(parent.unit) ~= 0) then
		parent:SetAlpha(element.insideAlpha)
	else
		parent:SetAlpha(element.outsideAlpha)
	end
end

local function Health_UpdateColor(self, event, unit)
	if (not unit or self.unit ~= unit) then return end
	local element = self.Health
	local color = config.frame.colors

	if (UnitIsConnected(unit) and (UnitCanAssist('player', unit) or UnitCanAttack('player', unit))) then
		element:SetStatusBarColor(unpack(color.base.fg))
	else
		element:SetStatusBarColor(unpack(color.away.fg))
	end

	if (UnitIsDead(unit) or UnitIsGhost(unit)) then
		element.Background:SetVertexColor(unpack(color.dead.bg))
	else
		element.Background:SetVertexColor(unpack(color.base.bg))
	end
end

-- -----------------------------------
-- > BOSS AURA SPECIFIC FUNCTIONS
-- -----------------------------------

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, ...)
	local name = select(1, ...)
	local caster = select(7, ...)
	local showSelf = select(9, ...)
	local spellId = select(10, ...)
	local showAll = select(14, ...)

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[spellId]) then
		return true
	end
	if (filters[frame_name].blacklist[spellId]) then
		return false
	end

	-- blizzard's nameplate filtering function
	return button.isPlayer and auras:ShowNameplateAura(name, caster, showSelf, showAll)
end

-- -----------------------------------
-- > BOSS STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	common:CreateLayout(self, layout)

	-- mouse events
	common:RegisterMouse(self)

	if (layout.health.colorCustom) then
		self.Health.UpdateColor = Health_UpdateColor
	end

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints(self)
	text.unit = common:CreateFontstring(text, font, config.fontsize -1, nil, 'CENTER')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetPoint('TOPLEFT', self.Health, 'TOPLEFT', 2, -2)
	text.unit:SetSize(layout.width - 10, config.fontsize + 1)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:name]')
	end

	text.status = common:CreateFontstring(text, font_num, config.fontsize + 6, nil, 'CENTER')
	text.status:SetPoint('CENTER', self.Health, 'CENTER', 0, -2)
	text.status:SetSize(layout.width - 10, config.fontsize + 1)
	if (layout.health.colorCustom) then
		self:Tag(text.status, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(text.status, '[n:perhp_status]')
	end

	text.power = common:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
	text.power:SetShadowColor(0, 0, 0, 1)
	text.power:SetShadowOffset(1, -1)
	text.power:SetPoint('CENTER', self.Power, 'CENTER', 0, 0)
	text.power:SetSize(layout.width - 10, config.fontsize + 1)
	self:Tag(text.power, '[n:curpp]')
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local width, height, pos = uframe.castbar.width, uframe.castbar.height, uframe.castbar.pos
		local castbar = common:CreateCastbar(self, width, height)
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
	self.Range.PostUpdate = RangeCheck_PostUpdate
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
