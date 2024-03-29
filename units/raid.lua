local A, ns = ...

local common, config, m, util, oUF = ns.common, ns.config, ns.m, ns.util, ns.oUF
local auras = ns.auras

local filters = config.filters
local spells = config.spells

local font = m.fonts.frizq
local font_num = m.fonts.myriad
local font_size = config.fontsize

local frame_name = 'raid'

-- Import API functions
local floor, ceil = floor, ceil
local UnitIsUnit = UnitIsUnit
local UnitThreatSituation = UnitThreatSituation
local GetThreatStatusColor = GetThreatStatusColor

-- ------------------------------------------------------------------------
-- > RAID UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- Raid Frames Target Highlight Border
local function UpdateTarget(self, event, unit)
	if (UnitIsUnit('target', self.unit)) then
		self.TargetBorder:Show()
	else
		self.TargetBorder:Hide()
	end
end

-- Create Target Border
local function TargetBorder_Create(self)
	local border = common:CreateBorder(self, 2, 2, self:GetFrameLevel() + 1, [[Interface\ChatFrame\ChatFrameBackground]])
	border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
	border:Hide()
	self:RegisterEvent('PLAYER_TARGET_CHANGED', UpdateTarget, true)
	self:RegisterEvent('GROUP_ROSTER_UPDATE', UpdateTarget, true)
	self.TargetBorder = border
end

-- Party / Raid Frames Threat Highlight
local function UpdateThreat(self, event, unit)
	if (unit and not UnitIsUnit(unit, self.unit)) then
		return
	end
	local status = UnitThreatSituation(self.unit)
	if (status and status > 1) then
		local r, g, b = GetThreatStatusColor(status)
		self.ThreatBorder:Show()
		self.ThreatBorder:SetBackdropBorderColor(r, g, b, 1)
	else
		self.ThreatBorder:Hide()
	end
end

-- Create Party / Raid Threat Status Border
local function ThreatBorder_Create(self)
	local border = common:CreateDropShadow(self, 6, 6, 0)
	border:Hide()
	self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', UpdateThreat)
	self:RegisterEvent('GROUP_ROSTER_UPDATE', UpdateThreat, true)
	self.ThreatBorder = border
end

local function RaidFrame_PostUpdate(self, event)
	if (event == 'OnShow') then
		UpdateTarget(self)
		UpdateThreat(self)
	end
end

-- -----------------------------------
-- > STATUSBAR AURA COLOR
-- -----------------------------------

local function BuffColor_GetColor(element, unit, data)
	return data.isPlayerAura and filters.color.aura[data.spellId]
end

-- -----------------------------------
-- > RAID AURAS
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

local function PostUpdateButton(element, button, unit, data, position)
	if (data.isBossAura) then
		button:SetSize(element.size + 8, element.size + 8)
	end
end

local function SetPosition(element, from, to)
	local ref = {
		['BOTTOMLEFT']  = 'BOTTOMRIGHT',
		['BOTTOMRIGHT'] = 'BOTTOMLEFT'
	}
	local anchor = element.initialAnchor or 'BOTTOMLEFT'

	if (from == 1 and element[1]) then
		element[1]:SetPoint(anchor, element, anchor)
		from = from + 1
	end

	for i = from, to do
		local button = element[i]
		if(not button) then break end

		button:ClearAllPoints()
		button:SetPoint(anchor, element[i - 1], ref[anchor])
	end
end

-- -----------------------------------
-- > RAID STYLE
-- -----------------------------------

-- Hide Power for Non-Healers
local function Power_PostUpdate(element, unit)
	local parent = element.__owner

	if (UnitGroupRolesAssigned(unit) ~= 'HEALER') then
		element:SetPoint('TOP', parent, 'BOTTOM')
		element:Hide()
	else
		element:SetPoint('TOP', parent, 'BOTTOM', 0, element.height)
		element:Show()
	end
end

local function createStyle(self, unit, ...)
	local num = self:GetAttribute('oUF_NineRaidProfile')
	local uframe = config.units[frame_name][num]
	local layout = uframe.layout

	common:CreateLayout(self, layout)

	-- mouse events
	local clickthrough = uframe.misc and uframe.misc.rightClickthrough
	common:RegisterMouse(self, clickthrough)

	-- power show/hide for non-healers
	if (self.Power and uframe.misc and uframe.misc.hidePower == 'NON_HEALER') then
		self.Power.height = layout.power.height
		self.Power.PostUpdate = Power_PostUpdate
	end

	-- text strings (on top of health)
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.unit = common:CreateFontstring(text, font, font_size - 2, nil, 'LEFT')
	text.unit:SetPoint('TOPRIGHT', -2, 0)
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetSize(self:GetWidth() - 15, font_size + 1)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:name]')
	end

	text.status = common:CreateFontstring(text, font_num, font_size + 2, nil, 'CENTER')
	text.status:SetPoint('LEFT')
	text.status:SetPoint('RIGHT')
	text.status:SetSize(self:GetWidth(), font_size + 13)
	local statustag
	if (uframe.misc and uframe.misc.hideHPPerc) then
		statustag = '[n:status]'
	else
		statustag = '[n:perhp_status]'
	end
	if (layout.health.colorCustom) then
		self:Tag(text.status, '[n:reactioncolor]'..statustag)
	else
		self:Tag(text.status, statustag)
	end
	self.Text = text

	-- icons frame (ready check, raid icons, role, ...)
	local icons = CreateFrame('Frame', nil, self.Health)
	icons:SetAllPoints()

	-- phase indicator
	local phaseIcon = icons:CreateTexture(nil, 'OVERLAY')
	phaseIcon:SetSize(28, 28)
	phaseIcon:SetPoint('CENTER', icons)
	self.PhaseIndicator = phaseIcon

	-- resurrect indicator
	local ressIcon = icons:CreateTexture(nil, 'OVERLAY')
	ressIcon:SetSize(28, 28)
	ressIcon:SetPoint('CENTER', icons)
	self.ResurrectIndicator = ressIcon

	-- summon indicator
	local summonIcon = icons:CreateTexture(nil, 'OVERLAY')
	summonIcon:SetSize(28, 28)
	summonIcon:SetPoint('CENTER', icons)
	self.SummonIndicator = summonIcon

	-- ready check
	local readyCheck = icons:CreateTexture(nil, 'OVERLAY')
	readyCheck:SetPoint('CENTER', icons)
	readyCheck:SetSize(28, 28)
	readyCheck.finishedTimer = 10
	readyCheck.fadeTimer = 2
	self.ReadyCheckIndicator = readyCheck

	-- raid indicator
	local raidIcon = icons:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', icons, 'TOP', 0, -4)
	raidIcon:SetSize(18,18)
	self.RaidTargetIndicator = raidIcon

	-- role icon
	local roleIcon = icons:CreateTexture(nil, 'OVERLAY')
	roleIcon:SetPoint('CENTER', self, 'TOPLEFT', 7, -7)
	roleIcon:SetSize(12, 12)
	self.GroupRoleIndicator = roleIcon

	-- raid auras
	if (uframe.auras) then
		-- calc dimensions, prevent them from overflowing the frame
		local cols = uframe.auras.cols or 3
		local size = uframe.auras.size or floor(self:GetWidth() / (2 * (cols + 0.25)))
		local rows = uframe.auras.rows or floor(2 * self:GetHeight() / (3 * size))

		local buffs = auras:CreateRaidAuras(icons, size, cols + 0.5, rows, 0, size - 4)
		buffs:SetPoint('BOTTOMRIGHT', self.Health, 'BOTTOMRIGHT', -2, 2)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true

		buffs.FilterAura = Buffs_FilterAura
		buffs.SetPosition = SetPosition
		buffs.SortAuras = AuraUtil.DefaultAuraCompare

		if (layout.health.colorOnBuff) then
			self.BuffColor = auras:CreateAuraColor(buffs, self.Health)
			self.BuffColor.GetColor = BuffColor_GetColor
		end

		self.Buffs = buffs

		local debuffs = auras:CreateRaidAuras(icons, size, cols + 0.5, rows, 0, size + 8, true)
		debuffs:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 2, 2)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.dispel:SetPoint('TOPRIGHT', self.Health)
		debuffs.special:SetPoint('CENTER', self.Health)
		debuffs.special.isDebuff = true

		debuffs.FilterAura = Debuffs_FilterAura
		debuffs.SortAuras = auras.DebuffComparator
		debuffs.SetPosition = SetPosition
		debuffs.PostUpdateButton = PostUpdateButton

		self.Debuffs = debuffs
	end

	self.Range = config.frame.range

	-- target / threat warning borders
	ThreatBorder_Create(self)
	TargetBorder_Create(self)

	self.PostUpdate = RaidFrame_PostUpdate
end

-- -----------------------------------
-- > RAID PETS STYLE
-- -----------------------------------

local function createSubStyle(self, unit)
	local num = self:GetAttribute('oUF_NineRaidProfile')
	local uframe = config.units[frame_name][num] -- inherited from 'num' profile style
	local layout = uframe.layout

	common:CreateLayout(self, layout)

	-- mouse events
	local clickthrough = uframe.misc and uframe.misc.rightClickthrough
	common:RegisterMouse(self, clickthrough)

	-- disable power
	self.Power:Hide()
	self.Power:ClearAllPoints()
	self.Health:SetAllPoints()

	-- text strings (on top of health)
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.unit = common:CreateFontstring(text, font, font_size - 2, nil, 'LEFT')
	text.unit:SetPoint('LEFT', 6, 0)
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetSize(self:GetWidth() - 12, font_size + 1)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:name]')
	end
	self.Text = text

	-- icons frame (ready check, raid icons, role, ...)
	local icons = CreateFrame('Frame', nil, self.Health)
	icons:SetAllPoints()

	local raidIcon = icons:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', icons, 'TOP', 0, -4)
	raidIcon:SetSize(18, 18)
	self.RaidTargetIndicator = raidIcon

	-- raid buffs (only used for health color toggle)
	if (uframe.auras and layout.health.colorOnBuff) then
		local buffs = CreateFrame('Frame', nil, self)
		buffs.num = 3

		local buffColor = auras:CreateAuraColor(buffs, self.Health)
		buffColor.GetColor = BuffColor_GetColor

		self.BuffColor = buffColor
		self.RaidBuffs = buffs
	end

	self.Range = config.frame.range

	-- target / threat warning borders
	ThreatBorder_Create(self)
	TargetBorder_Create(self)

	self.PostUpdate = RaidFrame_PostUpdate
end

-- -----------------------------------
-- > HELPERS TO CONFIG HEADERS
-- -----------------------------------

local function gen_visibility(role, from, to)
	if (not to) then
		return 'hide'
	end

	local spec
	for i = 1, GetNumSpecializations() do
		local isRole = role:match(GetSpecializationRole(i))
		if (isRole and not spec) then
			spec = i
		elseif (isRole) then
			spec = spec..'/'..i
		end
	end
	-- build hide conditions
	local s = spec and '[nospec:'..spec..']' or '[]'
	local a = (from > 0) and '[@raid'..from..',noexists]' or ''
	local b = (to < 41) and '[@raid'..(to+1)..',exists]' or ''

	return ('%s %s %s hide; show'):format(s, a, b)
end

local function element_width(grid)
	return floor((grid.width - ((grid.cols - 1)*grid.sep)) / grid.cols)
end

local function element_height(grid)
	return floor((grid.height - ((grid.rows - 1)*grid.sep)) / grid.rows)
end

local function gen_options(i, grid, sort, grow, width, height)
	local attr = {}
	attr.general = {
		'showSolo', false, 'showParty', true, 'showRaid', true, 'showPlayer', true
	}
	attr.grid = {
		['LEFTDOWN'] = {
			'columnAnchorPoint', 'TOP', 'point', 'LEFT',
			'unitsPerColumn', grid.cols,
			'maxColumns', grid.rows,
			'xOffset', grid.sep,
			'yOffset', -grid.sep,
			'columnSpacing', grid.sep
		},
		['DOWNLEFT'] = {
			'columnAnchorPoint', 'LEFT', 'point', 'TOP',
			'unitsPerColumn', grid.rows,
			'maxColumns', grid.cols,
			'xOffset', grid.sep,
			'yOffset', -grid.sep,
			'columnSpacing', grid.sep
		}
	}
	attr.order = {
		['ROLE'] = {
			'groupBy', 'ASSIGNEDROLE', 'groupingOrder', 'TANK,HEALER,DAMAGER'
		},
		['GROUP'] = {
			'groupBy', 'GROUP', 'groupingOrder', '1,2,3,4,5,6,7,8'
		}
	}
	attr.frame = {
		'oUF-initialConfigFunction', ([[
		local num, w, h, s = %d, %d, %d, %.64f
		self:SetWidth(w)
		self:SetHeight(h)
		self:SetScale(s)
		self:SetAttribute('oUF_NineRaidProfile', num)
		]]):format(i, width or element_width(grid), height or element_height(grid), common:GetPixelScale())
	}
	return util:TableConcat(attr.general, attr.grid[grow], attr.order[sort], attr.frame)
end

local function gen_pet_options(i, grid, sort, grow, num)
	local pet_grow = (grow == 'LEFTDOWN') and 'DOWNLEFT' or 'LEFTDOWN'
	local rows = (pet_grow == 'LEFTDOWN') and ceil(num / grid.cols) or grid.rows
	local cols = (pet_grow == 'LEFTDOWN') and grid.cols or ceil(num / grid.rows)
	local width, height = element_width(grid), (0.5 * element_height(grid)) - 1
	local pet_grid = { cols = cols, rows = rows, sep = grid.sep }

	return gen_options(i, pet_grid, sort, pet_grow, width, height)
end

-- -----------------------------------
-- > SPAWN HEADERS
-- -----------------------------------

local header = {}

local function header_onLogin()
	for i = 1, #header do
		local v = config.units[frame_name][i].visibility

		-- class specialization info
		header[i].visibility = v and gen_visibility(v.role, v.from, v.to)
		RegisterAttributeDriver(header[i], 'state-visibility', header[i].visibility)
		if (header[i].pets) then
			RegisterAttributeDriver(header[i].pets, 'state-visibility', header[i].visibility)
		end
	end
end

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper)..'Pets', createSubStyle)

	-- create the raid headers
	for i, cfg in ipairs(config.units[frame_name]) do
		local options = gen_options(i, cfg.grid, cfg.sort, cfg.grow)

		oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))
		header[i] = oUF:SpawnHeader('oUF_NineRaid'..i, nil, nil, unpack(options))
		header[i]:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)

		-- optional pet-frames
		if (cfg.pets and cfg.pets.show) then
			local xoff = (cfg.pets.anchor == 'TOPRIGHT') and cfg.grid.sep or 0
			local yoff = (cfg.pets.anchor == 'TOPRIGHT') and 0 or -cfg.grid.sep
			options = gen_pet_options(i, cfg.grid, cfg.sort, cfg.grow, cfg.pets.num)

			oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper)..'Pets')
			header[i].pets = oUF:SpawnHeader('oUF_NineRaidPets'..i, 'SecureGroupPetHeaderTemplate', nil, unpack(options))
			header[i].pets:SetPoint('TOPLEFT', 'oUF_NineRaid'..i, cfg.pets.anchor or 'TOPRIGHT', xoff, yoff)
		end
	end

	oUF:Factory(header_onLogin)
end
