local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad
local font_size = 16

local frame_name = 'nameplate'

-- Import API functions
local math_floor = math.floor
local table_insert, ipairs = table.insert, ipairs
local UnitExists = UnitExists
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsUnit = UnitIsUnit
local UnitIsTapDenied = UnitIsTapDenied
local UnitThreatSituation = UnitThreatSituation
local UnitPlayerControlled = UnitPlayerControlled
local UnitClassification = UnitClassification
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local IsInRaid, IsInGroup = IsInRaid, IsInGroup

local Auras_ShouldDisplayDebuff = NameplateBuffContainerMixin.ShouldShowBuff -- Blizzard_NamePlates/Blizzard_NamePlates.lua

-- ------------------------------------------------------------------------
-- > NAMEPLATES SPECIFIC
-- ------------------------------------------------------------------------

local NamePlate_CVars = {
	['nine'] = {
		nameplateGlobalScale = 1,
		NamePlateHorizontalScale = 1,
		NamePlateVerticalScale = 1,
		nameplateLargerScale = 1.2,
		nameplateMaxScale = 1,
		nameplateMinScale = 0.8,
		nameplateSelectedScale = 1.0,
		nameplateSelfScale = 1.0,
		nameplateMinAlpha = 0.6,
		nameplateMinAlphaDistance = 10,
		nameplateMaxAlpha = 1,
		nameplateMaxAlphaDistance = 40,
		nameplateMaxDistance = 60,
		nameplateOtherBottomInset = 0.04,
		nameplateOtherTopInset = 0.04,
		nameplateOverlapH = 0.7,
		nameplateOverlapV = 0.8
	},
	['default'] = {
		nameplateGlobalScale = 1,
		NamePlateHorizontalScale = 1,
		NamePlateVerticalScale = 1,
		nameplateLargerScale = 1.2,
		nameplateMaxScale = 1,
		nameplateMinScale = 0.8,
		nameplateSelectedScale = 1.0,
		nameplateSelfScale = 1.0,
		nameplateMinAlpha = 0.6,
		nameplateMinAlphaDistance = 10,
		nameplateMaxAlpha = 1,
		nameplateMaxAlphaDistance = 40,
		nameplateMaxDistance = 60,
		nameplateOtherBottomInset = 0.1,
		nameplateOtherTopInset = 0.08,
		nameplateOverlapH = 0.8,
		nameplateOverlapV = 1.1
	}
}

local function HealthBorder_Update(self, event, unit)
	-- health border target glow / shadows / hide
	local health = self.Health
	if (UnitIsUnit('target', self.unit)) then
		health.Border:SetBackdropBorderColor(1, 1, 1, 1)
	elseif (health.dropShadows) then
		health.Border:SetBackdropBorderColor(unpack(config.frame.shadows))
	else
		health.Border:SetBackdropBorderColor(1, 1, 1, 0)
	end
end

local function NamePlate_Callback(self, event, unit)
	if (not self or event ~= 'NAME_PLATE_UNIT_ADDED') then
		return
	end

	HealthBorder_Update(self)

	--elite icon
	local class = UnitClassification(self.unit)
	if (class == 'elite' or class == 'worldboss') then
		self.EliteIcon:SetAtlas('nameplates-icon-elite-gold')
		self.EliteIcon:Show()
	elseif (class == 'rareelite' or  class == 'rare') then
		self.EliteIcon:SetAtlas('nameplates-icon-elite-silver')
		self.EliteIcon:Show()
	else
		self.EliteIcon:Hide()
	end
end

-- -----------------------------------
-- > GROUP ROLE TRACKER
-- -----------------------------------

local roles = CreateFrame('Frame')
roles.Group = {}

-- Classification of Party into Roles
local function GroupRoles_Update(self, event)
	local group = { ['TANK'] = {}, ['HEALER'] = {}, ['DAMAGER'] = {}, ['NONE'] = {} }
	local isInRaid = IsInRaid()
	local isInGroup = isInRaid or IsInGroup()

	if (not isInGroup) then
		return
	end

	local numPlayers = (isInRaid and GetNumGroupMembers()) or GetNumSubgroupMembers()
	local unit = (isInRaid and 'raid') or 'party'

	for i = 1, numPlayers do
		if (UnitExists(unit .. i) and not UnitIsUnit(unit, 'player')) then
			local role = UnitGroupRolesAssigned(unit .. i)
			table_insert(group[role], unit .. i)
		end
	end
	self.Group = group
end

function roles:EnableUpdates()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('PLAYER_ROLES_ASSIGNED')
	self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	self:RegisterEvent('GROUP_ROSTER_UPDATE')
	self:SetScript('OnEvent', GroupRoles_Update)
end

-- -----------------------------------
-- > NAMEPLATE THREAT COLOR
-- -----------------------------------

local function GroupThreatSituation(group, unit)
	if (not group) then
		return
	end
	local status
	for _, u in ipairs(group) do
		status = UnitThreatSituation(u, unit)
		if status == 3 then
			return 3 -- secure tanking
		elseif status == 2 then
			return 2 -- insecure tanking
		end
	end
end

-- Threat Based Nameplate Coloring
local function Health_PostUpdateColor(element, unit)
	if (UnitPlayerControlled(unit) or UnitIsTapDenied(unit)) then
		return
	end

	local group = roles.Group['TANK']
	local status, num = UnitThreatSituation('player', unit), nil
	if (status == 2) then
		num = 2 -- insecure tanking
	elseif (status == 3) then
		num = 3 -- secure tanking
	elseif (GroupThreatSituation(group, unit)) then
		num = 4 -- off-tank tanking
	end

	if (num) then
		local t, r, g, b
		t = oUF.colors.threat[num]

		if (t) then
			r, g, b = t[1], t[2], t[3]
		end
		if (b) then
			element:SetStatusBarColor(r, g, b)
		end
	end
end

local function Health_UpdateColor(self, event, unit)
	if (not unit or self.unit ~= unit) then
		return
	end
	self.Health:ForceUpdate()
end

-- -----------------------------------
-- > NAMEPLATE CASTBAR
-- -----------------------------------

-- Update the Castbar Based on the Current Status
local function Castbar_Update(self, unit)
	if (self.notInterruptible) then
		self:SetStatusBarColor(unpack(oUF.colors.castbar['IMMUNE']))
	elseif (self.channeling) then
		self:SetStatusBarColor(unpack(oUF.colors.castbar['CHANNEL']))
	else
		self:SetStatusBarColor(unpack(oUF.colors.castbar['CAST']))
	end
	self.Icon:SetDesaturated(self.notInterruptible)
end

local function PostCast_Failed(self, unit)
	self:SetStatusBarColor(unpack(oUF.colors.castbar['FAILED']))
end

local function createCastbar(self, width, height, texture, iconSep, iconSize)
	local castbar = CreateFrame('StatusBar', nil, self)
	castbar:SetStatusBarTexture(texture or m.textures.status_texture)
	castbar:GetStatusBarTexture():SetHorizTile(false)
	castbar:SetSize(width, height)

	local background = castbar:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(0, 0, 0, 0.9)

	-- spell name
	castbar.Text = core:CreateFontstring(castbar, font, font_size - 1, nil, 'CENTER')
	castbar.Text:SetShadowColor(0, 0, 0, 1)
	castbar.Text:SetShadowOffset(1, -1)
	castbar.Text:SetPoint('TOP', castbar, 'BOTTOM', 0, -1)
	castbar.Text:SetSize(width - 4, font_size - 1)

	-- castbar spark
	castbar.Spark = castbar:CreateTexture(nil, 'OVERLAY')
	castbar.Spark:SetSize(20, 2.2 *height)
	castbar.Spark:SetBlendMode('ADD')
	castbar.Spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)

	-- spell icon
	castbar.Icon = castbar:CreateTexture(nil, 'ARTWORK')
	castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	castbar.Icon:SetSize(iconSize, iconSize)
	castbar.Icon:SetPoint('BOTTOMLEFT', castbar, 'BOTTOMRIGHT', iconSep + 2, 0)

	-- castbar interrupt / status display
	castbar.timeToHold = 0.5
	castbar.PostCastStart = Castbar_Update
	castbar.PostCastInterruptible = Castbar_Update
	castbar.PostCastFail = PostCast_Failed

	return castbar
end

-- -----------------------------------
-- > NAMEPLATE WIDGET XP BAR
-- -----------------------------------

local function Create_WidgetXPBar(self, width, height, texture)
	local widgetxp = CreateFrame('StatusBar', self:GetDebugName() .. 'WidgetXPBar', self)
	widgetxp:SetStatusBarTexture(texture or m.textures.status_texture)
	widgetxp:SetSize(width, height)
	widgetxp:SetStatusBarColor(255/255, 202/255, 40/255, 1)

	-- background (under our own control, not to be confused with oUFs bg)
	local background = widgetxp:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(0, 0, 0, 0.9)

	-- rank text
	widgetxp.Rank = core:CreateFontstring(widgetxp, font_num, font_size - 1, nil, 'LEFT')
	widgetxp.Rank:SetShadowColor(0, 0, 0, 1)
	widgetxp.Rank:SetShadowOffset(1, -1)
	widgetxp.Rank:SetPoint('RIGHT', widgetxp, 'LEFT', -5, 0)

	-- progress text
	widgetxp.ProgressText = core:CreateFontstring(widgetxp, font_num, font_size - 1, nil, 'CENTER')
	widgetxp.ProgressText:SetShadowColor(0, 0, 0, 1)
	widgetxp.ProgressText:SetShadowOffset(1, -1)
	widgetxp.ProgressText:SetPoint('CENTER')

	return widgetxp
end

-- -----------------------------------
-- > NAMEPLATE AURAS
-- -----------------------------------

local function Auras_PostCreateIcon(element, button)
	button.icon:SetTexCoord(0.15, 0.85, 0.15, 0.85)

	button.count:SetPoint('BOTTOMRIGHT', 1, 0)
	button.count:SetJustifyH('RIGHT')

	if (element.showDebuffType) then
		button.overlay:SetTexture(m.textures.border_button)
		button.overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	end
end

-- Filter Buffs
local function Buffs_CustomFilter(element, unit, button, isDispellable, ...)
	local isStealable = select(8, ...)
	local duration = select(5, ...)
	local spellId = select(10, ...)
	local casterIsPlayer = select(13, ...)

	-- auras white-/blacklist
	if (filters[frame_name]['whitelist'][spellId]) then
		return auras.BUFF_WHITELIST
	end
	if (filters[frame_name]['blacklist'][spellId]) then
		return false
	end

	-- only show stealable / purgeable buffs
	if (isStealable and ((duration > 0 and duration < 30) or not casterIsPlayer)) then
		return 1
	end
end

local function Debuffs_PreUpdate(element, unit)
	local filter
	local showAll

	local reaction = UnitReaction('player', unit)
	if (reaction and reaction <= 4) then
		-- reaction 4 is neutral and less than 4 becomes increasingly more hostile
		filter = 'HARMFUL|INCLUDE_NAME_PLATE_ONLY'
	else
		local showDebuffsOnFriendly = GetCVarBool('nameplateShowDebuffsOnFriendly')
		if (showDebuffsOnFriendly) then
			-- dispellable debuffs
			filter = 'HARMFUL|RAID'
			showAll = true
		else
			filter = 'NONE'
		end
	end

	element.filter = filter
	element.showAll = showAll
end

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, isDispellable, ...)
	local name = select(1, ...)
	local duration = select(5, ...)
	local caster = select(7, ...)
	local showSelf = select(9, ...)
	local spellId = select(10, ...)
	local showAll = select(14, ...)

	-- auras white-/blacklist
	if (filters[frame_name]['whitelist'][spellId]) then
		return auras.DEBUFF_WHITELIST
	end
	if (filters[frame_name]['blacklist'][spellId]) then
		return false
	end

	-- blizzard's nameplate filtering function
	if (not Auras_ShouldDisplayDebuff(nil, name, caster, showSelf, showAll, duration)) then
		return false
	end

	-- get debuff priority and warn level
	local prio, warn = auras:GetDebuffPrio(isDispellable, ...)
	button.prio = prio

	return (element.showSpecial and warn and 'S') or prio
end

-- -----------------------------------
-- > NAMEPLATES STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	-- size and position
	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.x, uframe.pos.y)
	self:SetScale(core:GetPixelScale(self))

	-- hp bar
	local health = CreateFrame('StatusBar', nil, self)
	health:SetPoint('TOPLEFT', self)
	health:SetPoint('TOPRIGHT', self)
	health:SetPoint('BOTTOM', self, 'BOTTOM', 0, layout.spacer.height)
	health:SetStatusBarTexture(layout.texture or m.textures.status_texture)
	health:GetStatusBarTexture():SetHorizTile(false)

	-- background (under our own control, not to be confused with oUFs bg)
	local background = health:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints(health)
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(0, 0, 0, 0.9)

	-- hp bar colors
	if (layout.health.colorThreat) then
		health.PostUpdateColor = Health_PostUpdateColor
		self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', Health_UpdateColor)
	end
	health.colorClass = layout.health.colorClass
	health.colorReaction = layout.health.colorReaction
	health.colorHealth = true
	health.colorDisconnected = true
	health.colorTapping = true

	-- health border white glow (targeting) / shadows
	health.Border = core:CreateDropShadow(health, 4, 4, 0, {1, 1, 1, 1}) -- white glow
	health.dropShadows = layout.shadows
	self:RegisterEvent('PLAYER_TARGET_CHANGED', HealthBorder_Update, true)

	self.Health = health

	-- hp prediction
	self.HealthPrediction = core:CreateHealthPredict(self.Health, layout.width)

	-- elite icon
	local eliteIcon = self:CreateTexture(nil, 'OVERLAY')
	eliteIcon:SetPoint('RIGHT', self.Health, 'LEFT', -1, 0)
	eliteIcon:SetSize(18, 18)
	self.EliteIcon = eliteIcon

	-- raid icons
	local raidIcon = self:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('RIGHT', self.Health, 'LEFT', -20, 0)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints(self.Health)
	text.unit = core:CreateFontstring(text, font, font_size, nil, 'CENTER')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetSize(2 * layout.width, font_size)
	text.unit:SetPoint('BOTTOM', text, 'TOP', 0, 2)
	self:Tag(text.unit, '[n:name]')

	if (uframe.misc and not uframe.misc.hideHPPerc) then
		text.status = core:CreateFontstring(text, font, font_size, nil, 'CENTER')
		text.status:SetShadowColor(0, 0, 0, 1)
		text.status:SetShadowOffset(1, -1)
		text.status:SetAllPoints()
		self:Tag(text.status, '[perhp]')
	end
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local iconSize = self.Health:GetHeight() + uframe.castbar.height + uframe.sep
		local castbar = createCastbar(self.Health, layout.width, uframe.castbar.height, layout.texture, uframe.sep, iconSize)
		castbar:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -uframe.sep)
		self.Castbar = castbar
	end

	-- buffs
	if (uframe.buffs and uframe.buffs.show) then
		local cfg = uframe.buffs
		local cols = cfg.cols or 4
		local size = cfg.size or math_floor(self:GetWidth() / (2 * (cols + 0.25)))

		local raidBuffs = auras:CreateRaidAuras(self, size, cols, cols + 0.5, 2)
		raidBuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 20)
		raidBuffs.initialAnchor = 'BOTTOMRIGHT'
		raidBuffs['growth-x'] = 'LEFT'
		raidBuffs['growth-y'] = 'UP'
		raidBuffs.showStealableBuffs = true
		raidBuffs.disableMouse = true
		raidBuffs.PostCreateIcon = Auras_PostCreateIcon
		raidBuffs.CustomFilter = Buffs_CustomFilter

		self.RaidBuffs = raidBuffs
	end

	-- debuffs
	if (uframe.debuffs and uframe.debuffs.show) then
		local cfg = uframe.debuffs
		local cols = cfg.cols or 4
		local size = cfg.size or math_floor(self:GetWidth() / (2 * (cols + 0.25)))
		local raidDebuffs = auras:CreateRaidAuras(self, size, cols, cols + 0.5, 2, size + 8)
		raidDebuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 20)
		raidDebuffs.initialAnchor = 'BOTTOMLEFT'
		raidDebuffs['growth-x'] = 'RIGHT'
		raidDebuffs['growth-y'] = 'UP'
		raidDebuffs.disableMouse = true

		raidDebuffs.PostCreateIcon = Auras_PostCreateIcon
		raidDebuffs.PreUpdate = Debuffs_PreUpdate
		raidDebuffs.CustomFilter = Debuffs_CustomFilter

		raidDebuffs.special:SetPoint('BOTTOM', self, 'TOP', 0, 20)
		raidDebuffs.showSpecial = uframe.debuffs and uframe.debuffs.warn

		self.RaidDebuffs = raidDebuffs
	end

	-- widget xp bar (nazjatar followers, ...)
	do
		local w = math_floor(0.7 * layout.width)
		local h = math_floor(0.5 * self.Health:GetHeight())
		local widgetxp = Create_WidgetXPBar(self, w, h, layout.texture)
		widgetxp:SetPoint('TOP', self.Health, 'BOTTOM', 0, -14)
		self.WidgetXPBar = widgetxp
	end
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))
	oUF:SpawnNamePlates(A.. frame_name:gsub('^%l', string.upper), NamePlate_Callback, NamePlate_CVars['nine'])
	roles:EnableUpdates()
end
