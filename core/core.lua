local _, ns = ...

local core, config, m, oUF = {}, ns.config, ns.m, ns.oUF
ns.core = core

-- Import API functions
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local GetCVar = GetCVar
local string_match = string.match

-- ------------------------------------------------------------------------
-- > CORE FUNCTIONS
-- ------------------------------------------------------------------------

-- Virtual Pixel Scaling Factor
function core:GetPixelScale(self)
	local scale = string_match(GetCVar('gxWindowedResolution'), '%d+x(%d+)')
	local parent = (self and self:GetParent()) or UIParent
	local uiScale = parent:GetEffectiveScale()
	return 768/scale/uiScale
end

-- Fontstring Builder
function core:CreateFontstring(self, font, size, outline, justify)
	local fs = self:CreateFontString(nil, 'ARTWORK')
	fs:SetFont(font, size, outline)
	fs:SetJustifyH(justify or 'LEFT')
	return fs
end


-- -----------------------------------
-- > BORDER / BACKDROP UTILITIES
-- -----------------------------------

-- Set the Backdrop
function core:SetBackdrop(self, inset_l, inset_r, inset_t, inset_b, color)
	self.backdropInfo = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		tile = false,
		tileSize = 0,
		insets = {
			left = -inset_l,
			right = -inset_r,
			top = -inset_t,
			bottom = -inset_b
		}
	}
	self:ApplyBackdrop()
	self:SetBackdropColor(unpack(color or { 0, 0, 0, 1 }))
end

-- Create Standard Frame Border
function core:CreateBorder(self, point, e_size, f_level, texture)
	local parent = (self:IsObjectType('Texture') and self:GetParent()) or self
	local border = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
	border:SetPoint('TOPLEFT', self, 'TOPLEFT', -point, point)
	border:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', point, -point)
	border.backdropInfo = { edgeFile = texture, edgeSize = e_size }
	border:ApplyBackdrop()
	border:SetFrameLevel(f_level)
	return border
end

-- Create Frame Shadow Border
function core:CreateDropShadow(self, point, e_size, f_level, color)
	local shadow = CreateFrame('Frame', nil, self, 'BackdropTemplate')
	shadow:SetPoint('TOPLEFT', self, 'TOPLEFT', -point, point)
	shadow:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', point, -point)
	shadow.backdropInfo = {
		bgFile = nil,
		edgeFile = m.textures.glow_texture,
		tile = false,
		tileSize = 32,
		edgeSize = e_size,
		insets = {
			left = -e_size,
			right = -e_size,
			top = -e_size,
			bottom = -e_size
		}
	}
	shadow:ApplyBackdrop()
	shadow:SetBackdropColor(0, 0, 0, 0)
	shadow:SetBackdropBorderColor(unpack(color or { 0, 0, 0, 1 }))
	shadow:SetFrameLevel(f_level)
	return shadow
end

-- -----------------------------------
-- > MOUSE EVENTS
-- -----------------------------------

local function Mouseover_OnEnter(self)
	-- mouseover highlight show
	self.Health.Highlight:Show()
	if (self.Power) then
		self.Power.Highlight:Show()
	end
	UnitFrame_OnEnter(self)
end

local function Mouseover_OnLeave(self)
	-- mouseover highlight hide
	self.Health.Highlight:Hide()
	if (self.Power) then
		self.Power.Highlight:Hide()
	end
	UnitFrame_OnLeave(self)
end

local function Mousebutton_OnDown(self, button)
	if (button == 'RightButton') then
		MouselookStart()
	end
end

function core:RegisterMouse(self, rightClickthrough)
	self:SetScript('OnEnter', Mouseover_OnEnter)
	self:SetScript('OnLeave', Mouseover_OnLeave)
	if (not rightClickthrough) then
		self:RegisterForClicks('AnyDown')
	else
		self:RegisterForClicks('LeftButtonDown')
		self:SetScript('OnMouseDown', Mousebutton_OnDown)
	end
end

-- -----------------------------------
-- > HEAL PREDICTION
-- -----------------------------------

local function HealthPredict_PostUpdate(self, unit, ...)
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
	local absorb = select(3, ...)

	-- update our custom heal absorb overlay
	if (self.absorbBar and self.absorbBar.overlay) then
		local overlay = self.absorbBar.overlay
		if (absorb > 0 and health < maxHealth) then
			local frame = self.__owner.Health
			local width = frame:GetWidth() / maxHealth * absorb -- absorb value to texture width
			overlay:SetWidth(width)
			overlay:SetTexCoord(0, width / overlay.tileSize, 0, frame:GetHeight() / overlay.tileSize)
			overlay:Show()
		else
			overlay:Hide()
		end
	end
end

function core:CreateHealthPredict(self, width, texture)

	-- clips heal predict frames to avoid overflow on create
	local clipping = CreateFrame('Frame', nil, self)
	clipping:SetClipsChildren(true)
	clipping:SetAllPoints()
	clipping:EnableMouse(false)
	self.ClipFrame = clipping

	-- my heals
	local myBar = CreateFrame('StatusBar', nil, clipping)
	myBar:SetPoint('TOPLEFT', self:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	myBar:SetPoint('BOTTOMLEFT', self:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	myBar:SetWidth(width)
	myBar:SetStatusBarTexture(texture or m.textures.status_texture)
	myBar:SetStatusBarColor(125/255, 255/255, 50/255, 0.5)

	-- other heals
	local otherBar = CreateFrame('StatusBar', nil, clipping)
	otherBar:SetPoint('TOPLEFT', myBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	otherBar:SetPoint('BOTTOMLEFT', myBar:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	otherBar:SetWidth(width)
	otherBar:SetStatusBarTexture(texture or m.textures.status_texture)
	otherBar:SetStatusBarColor(100/255, 235/255, 200/255, 0.5)

	-- absorbs (shields)
	local absorbBar = CreateFrame('StatusBar', nil, clipping)
	absorbBar:SetPoint('TOPLEFT', otherBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	absorbBar:SetPoint('BOTTOMLEFT', otherBar:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	absorbBar:SetWidth(width)
	absorbBar:SetStatusBarTexture(texture or m.textures.status_texture)
	absorbBar:SetStatusBarColor(1, 1, 1, 1)

	absorbBar.overlay = absorbBar:CreateTexture(nil, 'OVERLAY')
	absorbBar.overlay:SetTexture(m.textures.absorb_overlay, true, true)
	absorbBar.overlay:SetAlpha(0.5)
	absorbBar.overlay:SetPoint('TOPLEFT', otherBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	absorbBar.overlay:SetPoint('BOTTOMLEFT', otherBar:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	absorbBar.overlay.width = width
	absorbBar.overlay.tileSize = 30

	-- heal absorbs (i.e necrotic strike)
	local healAbsorbBar = CreateFrame('StatusBar', nil, clipping)
	healAbsorbBar:SetPoint('TOPRIGHT', self:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	healAbsorbBar:SetPoint('BOTTOMRIGHT', self:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	healAbsorbBar:SetWidth(width)
	healAbsorbBar:SetReverseFill(true)
	healAbsorbBar:SetStatusBarTexture(texture or m.textures.status_texture)
	healAbsorbBar:SetStatusBarColor(5/255, 5/255, 5/255, 0.5)

	local overAbsorb = absorbBar:CreateTexture(nil, 'OVERLAY')
	overAbsorb:SetPoint('TOP')
	overAbsorb:SetPoint('BOTTOM')
	overAbsorb:SetPoint('LEFT', self, 'RIGHT', -4, 0)
	overAbsorb:SetWidth(10)

	local overHealAbsorb = healAbsorbBar:CreateTexture(nil, 'OVERLAY')
	overHealAbsorb:SetPoint('TOP')
	overHealAbsorb:SetPoint('BOTTOM')
	overHealAbsorb:SetPoint('RIGHT', self, 'LEFT', 4, 0)
	overHealAbsorb:SetWidth(10)

	local healthPredict = {
		myBar = myBar,
		otherBar = otherBar,
		absorbBar = absorbBar,
		healAbsorbBar = healAbsorbBar,
		overAbsorb = overAbsorb,
		overHealAbsorb = overHealAbsorb,
		maxOverflow = 1.00,
		PostUpdate = HealthPredict_PostUpdate
	}
	return healthPredict
end

-- -----------------------------------
-- > SHARED STYLE FUNCTION
-- -----------------------------------

-- Health color override for inverted color mode
local function Health_UpdateColor(self, event, unit)
	if (not unit or self.unit ~= unit) then return end
	local element = self.Health
	local color = config.frame.colors

	if (UnitIsConnected(unit)) then
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

function core:CreateLayout(self, layout)
	local l = layout

	-- pixel scale
	self.pixelScale = core:GetPixelScale(self)

	-- hp bar
	local health = CreateFrame('StatusBar', nil, self)
	health:SetPoint('TOPLEFT', self, 'TOPLEFT', 0 ,0)
	health:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0 ,0)
	health:SetStatusBarTexture(l.texture or m.textures.status_texture)
	health:SetAlpha(config.frame.alpha)
	health:GetStatusBarTexture():SetHorizTile(false)

	-- hp background (under our own control, not to be confused with oUFs bg)
	health.Background = health:CreateTexture(nil, 'BACKGROUND')
	health.Background:SetAllPoints(health)
	health.Background:SetTexture(l.texture or m.textures.status_texture)
	health.Background:SetVertexColor(unpack(config.frame.colors.bg))

	-- hp highlight
	health.Highlight = health:CreateTexture(nil, 'OVERLAY')
	health.Highlight:SetAllPoints()
	health.Highlight:SetTexture(m.textures.white_square)
	health.Highlight:SetVertexColor(1, 1, 1, 0.05)
	health.Highlight:SetBlendMode('ADD')
	health.Highlight:Hide()

	-- hp color and Shadows
	if (l.health.colorCustom) then
		health.UpdateColor = Health_UpdateColor
		self:RegisterEvent('UNIT_CONNECTION', Health_UpdateColor)
	else
		health.colorClass = l.health.colorClass
		health.colorReaction = l.health.colorReaction
		health.colorHealth = true
		health.colorTapping = true
		health.colorDisconnected = true
	end

	if (l.shadows) then
		health.Shadow = core:CreateDropShadow(health, 5, 5, 0, config.frame.shadows)
	end

	-- power bar
	if (l.power) then
		local power = CreateFrame('StatusBar', nil, self)
		power:SetPoint('TOP', self, 'BOTTOM', 0, l.power.height)
		power:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 0, 0)
		power:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 0)
		power:SetAlpha(config.frame.alpha)
		power:SetStatusBarTexture(l.texture or m.textures.status_texture)
		power:GetStatusBarTexture():SetHorizTile(false)
		power.frequentUpdates = l.power.frequentUpdates

		-- background (under our own control, not to be confused with oUFs bg)
		power.Background = power:CreateTexture(nil, 'BACKGROUND')
		power.Background:SetAllPoints(power)
		power.Background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		power.Background:SetVertexColor(unpack(config.frame.colors.bg))

		-- highlight
		power.Highlight = power:CreateTexture(nil, 'OVERLAY')
		power.Highlight:SetAllPoints()
		power.Highlight:SetTexture(m.textures.white_square)
		power.Highlight:SetVertexColor(1, 1, 1, 0.05)
		power.Highlight:SetBlendMode('ADD')
		power.Highlight:Hide()

		-- color and shadows
		power.colorClass = l.power.colorClass
		power.colorPower = not l.power.colorClass
		power.colorTapping = true
		power.colorDisconnected = true
		power.displayAltPower = l.power.displayAltPower

		if (l.shadows) then
			power.Shadow = core:CreateDropShadow(power, 5, 5, 0, config.frame.shadows)
		end
		self.Power = power
	end

	-- hp bottom anchor to fill the remaining frame
	local vsep = (l.spacer and l.spacer.height) or 0
	health:SetPoint('BOTTOM', self.Power or self, self.Power and 'TOP' or 'BOTTOM', 0, vsep)
	self.Health = health

	-- hp prediction
	self.HealthPrediction = core:CreateHealthPredict(self.Health, self:GetWidth(), l.texture)
end
