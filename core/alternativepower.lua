local _, ns = ...

local core, util, config, m, oUF = ns.core, ns.util, ns.config, ns.m, ns.oUF

local font_num = m.fonts.asap

-- ------------------------------------------------------------------------
-- > ALTERNATIVE POWER BAR RELATED FUNCTIONS
-- ------------------------------------------------------------------------

-- AltPower PostUpdate
local function AltPowerPostUpdate(self, unit, cur, min, max)
	if (not self.__barInfo) then
		-- barInfo is nil when no alt power info
		return
	end

	local _, r, g, b = GetUnitPowerBarTextureInfo(self.__owner.unit, 3)

	if ((r == 1 and g == 1 and b == 1) or not b) then
		r, g, b = 1, 0, 0
	end
	self:SetStatusBarColor(r, g, b)

	-- hide/fade the bar if empty
	self:SetAlpha((cur == 0) and 0.2 or 1.0)

	if (cur < max) then
		if (self.isMouseOver) then
			self.Text:SetFormattedText('%s / %s - %d%%', util:ShortNumber(cur), util:ShortNumber(max), util:NumberToPerc(cur, max))
		elseif (cur > 0) then
			self.Text:SetFormattedText('%s', util:ShortNumber(cur))
		else
			self.Text:SetText(nil)
		end
	else
		if (self.isMouseOver) then
			self.Text:SetFormattedText('%s', util:ShortNumber(cur))
		else
			self.Text:SetText(nil)
		end
	end
end

local function AltPowerOnEnter(self)
	if (not self:IsVisible()) then
		return
	end

	self.isMouseOver = true
	self:ForceUpdate()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	self:UpdateTooltip()
end

local function AltPowerOnLeave(self)
	self.isMouseOver = nil
	self:ForceUpdate()
	GameTooltip:Hide()
end

-- AltPower (quest or boss special power)
function core:CreateAltPower(self, width, height, texture)
	local altpower = CreateFrame('StatusBar', nil, self)
	altpower:SetStatusBarTexture(texture or m.textures.status_texture)
	altpower:SetSize(width, height)

	altpower.Text = core:CreateFontstring(altpower, font_num, config.fontsize - 1, nil, 'CENTER')
	altpower.Text:SetShadowColor(0, 0, 0, 1)
	altpower.Text:SetShadowOffset(1, -1)
	altpower.Text:SetAllPoints()

	local background = altpower:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetColorTexture(unpack(config.frame.colors.bg))

	altpower:SetScript('OnEnter', AltPowerOnEnter)
	altpower:SetScript('OnLeave', AltPowerOnLeave)
	altpower.PostUpdate = AltPowerPostUpdate

	return altpower
end
