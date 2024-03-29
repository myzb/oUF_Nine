local A, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF
local auras = ns.auras

local filters = config.filters
local spells = config.spells

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
		nameplateOverlapH = 0.6,
		nameplateOverlapV = 0.6
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

local function FocusOverlay_Update(self, event)
	local health = self.Health
	if (not health.stripes) then
		return
	end
	if (UnitIsUnit('focus', self.unit)) then
		health.stripes:Show()
	else
		health.stripes:Hide()
	end
end

local function TargetIndicator_Update(self, event, unit)
	local health = self.Health
	if not (health.IndicatorLeft) then
		return
	end
	if (UnitIsUnit('target', self.unit)) then
		health.IndicatorLeft:Show()
		health.IndicatorRight:Show()
	else
		health.IndicatorLeft:Hide()
		health.IndicatorRight:Hide()
	end
end

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

local function EliteIcon_Update(self, event, unit)
	local class = UnitClassification(self.unit)
	if (class == 'elite' or class == 'worldboss') then
		self.EliteIcon:SetTexture(m.icons.star)
		self.EliteIcon:SetTexCoord(0.75, 1, 0, 1)
		self.EliteIcon:SetVertexColor(1, 0.8, 0)
		self.EliteIcon:Show()
	elseif (class == 'rareelite' or class == 'rare') then
		self.EliteIcon:SetTexture(m.icons.star)
		self.EliteIcon:SetTexCoord (0.75, 1, 0, 1)
		self.EliteIcon:SetVertexColor(0, 0.57, 0.97)
		self.EliteIcon:SetDesaturated(true)
		self.EliteIcon:Show()
	else
		self.EliteIcon:Hide()
	end
end

local function NamePlate_Callback(self, event, unit)
	if (not self or event ~= 'NAME_PLATE_UNIT_ADDED') then
		return
	end

	FocusOverlay_Update(self)
	HealthBorder_Update(self)
	TargetIndicator_Update(self)
	EliteIcon_Update(self)
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
-- > NAMEPLATE CUSTOM COLOR
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
local function ThreadColor(group_member, unit)
	local group = roles.Group['TANK']
	local status, num = UnitThreatSituation(group_member, unit), nil
	if (status == 2) then
		num = 2 -- low/lossing thread
	elseif (status == 3) then
		num = 3 -- have thread
	elseif (UnitGroupRolesAssigned('player') == 'TANK' and GroupThreatSituation(group, unit)) then
		num = 4 -- off-tank has thread
	end

	return num and oUF.colors.threat[num]
end

-- Color Override for Special Units
local function UnitColor(unit)
	local guid = UnitGUID(unit)
	local _, _, _, _, _, npcId = strsplit('-', guid or '')
	return filters.color.unit[npcId]
end

local function Health_ExecuteIndicator(element, unit)
	local execPerc = common:GetExecutePerc()
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if (execPerc and (cur/max * 100) < execPerc) then
		element.Execute:SetPoint('CENTER', element, 'LEFT', element:GetWidth() * execPerc/100, 0)
		element.Execute:Show()
	else
		element.Execute:Hide()
	end
end

local function Health_PostUpdateColor(element, unit)
	Health_ExecuteIndicator(element, unit)

	-- do not colorize players and tapped units
	if (UnitPlayerControlled(unit) or UnitIsTapDenied(unit)) then
		return
	end

	local rgb, r, g, b

	rgb = UnitColor(unit) or ThreadColor('player', unit)

	if (rgb) then
		r, g, b = rgb[1], rgb[2], rgb[3]
	end

	if (b) then
		element:SetStatusBarColor(r, g, b)
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
	castbar:SetSize(width - 1 - height, height)

	local background = castbar:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(0, 0, 0, 0.9)

	-- spell name
	castbar.Text = common:CreateFontstring(castbar, font, font_size - 2, nil, 'CENTER')
	castbar.Text:SetShadowColor(0, 0, 0, 1)
	castbar.Text:SetShadowOffset(1, -1)
	castbar.Text:SetPoint('CENTER')
	castbar.Text:SetSize(width - 4, font_size - 1)

	-- castbar spark
	castbar.Spark = castbar:CreateTexture(nil, 'OVERLAY')
	castbar.Spark:SetSize(20, 2.2 *height)
	castbar.Spark:SetBlendMode('ADD')
	castbar.Spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)

	-- spell icon
	castbar.Icon = castbar:CreateTexture(nil, 'ARTWORK')
	castbar.Icon:SetTexCoord(0.2, 0.8, 0.2, 0.8)
	castbar.Icon:SetSize(height, height)
	castbar.Icon:SetPoint('RIGHT', castbar, 'LEFT', -1, 0)

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
	widgetxp.Rank = common:CreateFontstring(widgetxp, font_num, font_size - 1, nil, 'LEFT')
	widgetxp.Rank:SetShadowColor(0, 0, 0, 1)
	widgetxp.Rank:SetShadowOffset(1, -1)
	widgetxp.Rank:SetPoint('RIGHT', widgetxp, 'LEFT', -5, 0)

	-- progress text
	widgetxp.ProgressText = common:CreateFontstring(widgetxp, font_num, font_size - 1, nil, 'CENTER')
	widgetxp.ProgressText:SetShadowColor(0, 0, 0, 1)
	widgetxp.ProgressText:SetShadowOffset(1, -1)
	widgetxp.ProgressText:SetPoint('CENTER')

	return widgetxp
end

-- -----------------------------------
-- > NAMEPLATE AURAS
-- -----------------------------------

local function Auras_PostCreateButton(element, button)
	button.Count:SetFont(font_num, 12, 'OUTLINE,MONOCHROME')
	button.Count:SetPoint('BOTTOMRIGHT', 1, 0)
	button.Count:SetJustifyH('RIGHT')
	button.Count:GetParent():SetFrameLevel(button.Cooldown:GetFrameLevel() - 1)
	button.Cooldown:SetHideCountdownNumbers(true)
	button.Cooldown:SetReverse(true)
	button.Icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)

	if (element.showType) then
		button.Overlay:SetTexture(m.textures.border_button)
		button.Overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	end
end

-- Filter Buffs
local function Buffs_FilterAura(element, unit, data)

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[data.spellId]) then
		return true
	end
	if (filters[frame_name].blacklist[data.spellId]) then
		return false
	end

	-- show stealable (purgeable) and short non-player buffs
	if (data.isStealable) then
		return true
	elseif ((data.duration > 0 and data.duration < 30) and not data.isFromPlayerOrPlayerPet) then
		return true
	end

	return false
end

local function Debuffs_Filter(element, unit)
	local reaction = UnitReaction('player', unit)
	local isHostile = reaction and reaction <= 4

	if (isHostile) then
		-- reaction 4 is neutral and less than 4 becomes increasingly more hostile
		element.showAll = false
		return 'HARMFUL|INCLUDE_NAME_PLATE_ONLY'
	else
		if (GetCVarBool('nameplateShowDebuffsOnFriendly')) then
			-- dispellable debuffs
			element.showAll = true
			return 'HARMFUL|RAID'
		else
			element.showAll = false
			return 'NONE'
		end
	end
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

	-- filter special auras
	if (element.special) then
		if (spells.crowdcontrol[data.spellId]) then
			element.special.active[data.auraInstanceID] = data
			return true
		end
	end

	return auras:NameplateShowDebuffs(unit, data, element.showAll)
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
	self:SetScale(common:GetPixelScale(self))

	-- hp bar
	local health = CreateFrame('StatusBar', nil, self)
	health:SetAllPoints()
	health:SetStatusBarTexture(layout.texture or m.textures.status_texture)
	health:GetStatusBarTexture():SetHorizTile(false)

	-- hp bar focus overlay stripes
	if (layout.health.focusHighlight) then
		health.stripes = health:CreateTexture(nil, 'OVERLAY')
		health.stripes:SetTexture(m.textures.stripes_texture, 'REPEAT')
		health.stripes:SetTexCoord(0, 0.5, 0.5, 1)
		health.stripes:SetBlendMode("ADD")
		health.stripes:SetHorizTile(true)
		health.stripes:SetAlpha(0.3)
		health.stripes:SetAllPoints(health:GetStatusBarTexture())
		self:RegisterEvent('PLAYER_FOCUS_CHANGED', FocusOverlay_Update, true)
	end

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
	health.Border = common:CreateDropShadow(health, 4, 4, 0, {1, 1, 1, 1}) -- white glow
	health.dropShadows = layout.shadows
	self:RegisterEvent('PLAYER_TARGET_CHANGED', HealthBorder_Update, true)

	if (uframe.targetIndicator and uframe.targetIndicator.show) then
		local w, h = uframe.targetIndicator.width, uframe.targetIndicator.height
		local ofs = uframe.targetIndicator.offset
		health.IndicatorLeft = health:CreateTexture(nil, 'OVERLAY')
		health.IndicatorLeft:SetTexture(m.icons.arrow_comp_right, 'REPEAT')
		health.IndicatorLeft:SetPoint('RIGHT', health, 'LEFT', -1 * ofs, 0)
		health.IndicatorLeft:SetSize(w, h)
		health.IndicatorRight = health:CreateTexture(nil, 'OVERLAY')
		health.IndicatorRight:SetTexture(m.icons.arrow_comp_left, 'REPEAT')
		health.IndicatorRight:SetPoint('LEFT', health, 'RIGHT', ofs, 0)
		health.IndicatorRight:SetSize(w, h)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', TargetIndicator_Update, true)
	end

	-- hp prediction
	self.HealthPrediction = common:CreateHealthPredict(health, layout.width)

	self.Health = health

	-- execute range
	if (layout.health.executeRange) then
		health.Execute = common:CreateSeparator(health, 0, 10, true)
		health.Execute:Hide()
	end

	-- elite icon
	local eliteIcon = self:CreateTexture(nil, 'OVERLAY')
	eliteIcon:SetPoint('LEFT', self.Health, 'RIGHT', 2, 0)
	eliteIcon:SetSize(16, 16)
	self.EliteIcon = eliteIcon

	-- raid icons
	local raidIcon = self:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('RIGHT', self.Health, 'LEFT', -20, 0)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local iconSize = self.Health:GetHeight() + uframe.castbar.height + uframe.sep
		local castbar = createCastbar(self.Health, layout.width, uframe.castbar.height, layout.texture, uframe.sep, iconSize)
		castbar:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', uframe.castbar.height+1, -uframe.sep)
		self.Castbar = castbar
	end

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints(self.Health)
	text.unit = common:CreateFontstring(text, font, font_size, nil, 'CENTER')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetSize(2 * layout.width, font_size)
	text.unit:SetPoint('BOTTOM', text, 'TOP', 0, 2)
	self:Tag(text.unit, '[n:name]')

	if (uframe.misc and uframe.misc.hpText) then
		text.status = common:CreateFontstring(text, font_num, font_size - 2, 'OUTLINE', 'CENTER')
		text.status:SetShadowColor(0, 0, 0, 1)
		text.status:SetShadowOffset(1, -1)
		text.status:SetPoint('RIGHT', text, 'BOTTOMRIGHT', -2, 0)
		self:Tag(text.status, '[n:curhp]')
	end
	self.Text = text

	-- buffs
	if (uframe.buffs and uframe.buffs.show) then
		local cfg = uframe.buffs
		local cols = cfg.cols or 4
		local rows = cfg.rows or 2
		local size = cfg.size or math_floor(self:GetWidth() / (2 * (cols + 0.25)))

		local buffs = auras:CreateAuras(self, size, cols + 0.5, rows, 0)
		buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 20)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true
		buffs.disableMouse = true

		buffs.PostCreateButton = Auras_PostCreateButton
		buffs.FilterAura = Buffs_FilterAura

		self.Buffs = buffs
	end

	-- debuffs
	if (uframe.debuffs and uframe.debuffs.show) then
		local cfg = uframe.debuffs
		local cols = cfg.cols or 4
		local rows = cfg.rows or 2
		local size = cfg.size or math_floor(self:GetWidth() / (2 * (cols + 0.25)))
		local specialSize = uframe.debuffs.warn and (size + 8) or 0

		local debuffs = auras:CreateRaidAuras(self, size, cols + 0.5, rows, 0, specialSize)
		debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 20)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.disableMouse = true

		if (uframe.debuffs.warn) then
			debuffs.special:SetPoint('BOTTOM', self, 'TOP', 0, 20)
			debuffs.special.isDebuff = true
		end

		debuffs.Filter = Debuffs_Filter
		debuffs.PostCreateButton = Auras_PostCreateButton
		debuffs.FilterAura = Debuffs_FilterAura
		debuffs.SortAuras = auras.DebuffComparator

		self.Debuffs = debuffs
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
