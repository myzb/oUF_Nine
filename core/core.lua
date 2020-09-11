local _, ns = ...

local core, config, m, oUF = CreateFrame('Frame'), ns.config, ns.m, ns.oUF
ns.core = core

-- ------------------------------------------------------------------------
-- > CORE FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > GENERAL FUNCTIONS
-- -----------------------------------

-- Set the Backdrop
function core:setBackdrop(self, inset_l, inset_r, inset_t, inset_b, color)
	self:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		tile = false,
		tileSize = 0,
		insets = {
			left = -inset_l,
			right = -inset_r,
			top = -inset_t,
			bottom = -inset_b
		}
	})
	self:SetBackdropColor(unpack(color or { 0, 0, 0, 1 }))
end

-- Fontstring Function
function core:createFontstring(self, font, size, outline, justify)
	local fs = self:CreateFontString(nil, 'ARTWORK')
	fs:SetFont(font, size, outline)
	fs:SetJustifyH(justify or 'LEFT')
	return fs
end

-- Create Standard Border
function core:createBorder(self, point, e_size, f_level, texture)
	local parent = (self:GetObjectType() == 'Frame') and self or self:GetParent()
	local border = CreateFrame('Frame', nil, parent)
	border:SetPoint('TOPLEFT', self, 'TOPLEFT', -point, point)
	border:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', point, -point)
	border:SetBackdrop({ edgeFile = texture, edgeSize = e_size })
	border:SetFrameLevel(f_level)
	return border
end

-- Create Frame Shadow Border
function core:createDropShadow(self, point, edge, f_level, color)
	local shadow = CreateFrame('Frame', nil, self)
	shadow:SetFrameLevel(f_level)
	shadow:SetPoint('TOPLEFT', self, 'TOPLEFT', -point, point)
	shadow:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', point, -point)
	shadow:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = m.textures.glow_texture,
		tile = false,
		tileSize = 32,
		edgeSize = edge,
		insets = {
			left = -edge,
			right = -edge,
			top = -edge,
			bottom = -edge
		}
	})
	shadow:SetBackdropColor(0, 0, 0, 0)
	shadow:SetBackdropBorderColor(unpack(color or { 0, 0, 0, 1 }))
	return shadow
end

-- Create Frame Glow Border
function core:createGlowBorder(self, point, edge, f_level, color)
	local glow = CreateFrame('Frame', nil, self)
	glow:SetFrameLevel(f_level)
	glow:SetPoint('TOPLEFT', self, 'TOPLEFT', -point, point)
	glow:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', point, -point)
	glow:SetBackdrop({
		bgFile = m.textures.white_square,
		edgeFile = m.textures.glow_texture,
		tile = false,
		tileSize = 32,
		edgeSize = edge,
		insets = {
			left = -edge,
			right = -edge,
			top = -edge,
			bottom = -edge
		}
	})
	glow:SetBackdropColor(0, 0, 0, 0)
	glow:SetBackdropBorderColor(unpack(color or { 1, 1, 1, 1 }))
	return glow
end

-- -----------------------------------
-- > TARGET/THREAT HIGHLIGHT
-- -----------------------------------

-- Raid Frames Target Highlight Border
local function ChangedTarget(self, event, unit)
	if (UnitIsUnit('target', self.unit)) then
		self.TargetBorder:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
		self.TargetBorder:Show()
	else
		self.TargetBorder:Hide()
	end
end

-- Create Target Border
function core:CreateTargetBorder(self, f_level)
	local border = core:createBorder(self, 2, 2, f_level, [[Interface\ChatFrame\ChatFrameBackground]])
	self:RegisterEvent('PLAYER_TARGET_CHANGED', ChangedTarget, true)
	self:RegisterEvent('GROUP_ROSTER_UPDATE', ChangedTarget)
	self.TargetBorder = border

	-- trigger update
	ChangedTarget(self)
end

-- Party / Raid Frames Threat Highlight
local function UpdateThreat(self, event, unit)
	if (self.unit ~= unit) then
		return
	end

	local status = UnitThreatSituation(unit)
	unit = unit or self.unit

	if (status and status > 1) then
		local r, g, b = GetThreatStatusColor(status)
		self.ThreatBorder:Show()
		self.ThreatBorder:SetBackdropBorderColor(r, g, b, 1)
	else
		self.ThreatBorder:SetBackdropBorderColor(0, 0, 0, 0)
		self.ThreatBorder:Hide()
	end
end

-- Create Party / Raid Threat Status Border
function core:CreateThreatBorder(self, f_level)
	local border = core:createGlowBorder(self, 6, 6, f_level)
	self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', UpdateThreat)
	self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', UpdateThreat)
	self.ThreatBorder = border

	-- trigger update
	UpdateThreat(self, nil, self.unit)
end
