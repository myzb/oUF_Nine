local _, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF

local font = m.fonts.frizq
local font_num = m.fonts.myriad

-- ------------------------------------------------------------------------
-- > CASTBARS
-- ------------------------------------------------------------------------

-- Castbar Custom Cast TimeText
local function CastTime_CustomText(self, duration)
	if (duration > 120) then return end
	self.Time:SetText(('%.1f'):format(self.channeling and duration or self.max - duration))
end

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

-- Castbar generator
function core:CreateCastbar(self, width, height, texture, latency)
	local castbar = CreateFrame('StatusBar', nil, self)
	castbar:SetStatusBarTexture(texture or m.textures.status_texture)
	castbar:GetStatusBarTexture():SetHorizTile(false)
	castbar:SetHeight(height)
	castbar:SetWidth(width - height) -- subtract for square icon (width = height)

	castbar.Background = castbar:CreateTexture(nil, 'BACKGROUND')
	castbar.Background:SetAllPoints()
	castbar.Background:SetTexture(m.textures.bg_texture)
	castbar.Background:SetVertexColor(1/7, 1/7, 1/7, 0.9)

	castbar.Text = core:CreateFontstring(castbar, font, config.fontsize -2, nil, 'LEFT')
	castbar.Text:SetTextColor(1, 1, 1)
	castbar.Text:SetShadowColor(0, 0, 0, 1)
	castbar.Text:SetShadowOffset(1, -1)
	castbar.Text:SetHeight(config.fontsize +1)
	castbar.Text:SetPoint('TOP')
	castbar.Text:SetPoint('BOTTOM')
	castbar.Text:SetWidth(width - 45)
	castbar.Text:SetPoint('LEFT', castbar, 2, 0)

	castbar.Time = core:CreateFontstring(castbar, font_num, config.fontsize -1, nil, 'RIGHT')
	castbar.Time:SetTextColor(1, 1, 1)
	castbar.Time:SetShadowColor(0, 0, 0, 1)
	castbar.Time:SetShadowOffset(1, -1)
	castbar.Time:SetHeight(config.fontsize +2)
	castbar.Time:SetPoint('RIGHT', castbar, -3, 0)
	castbar.CustomTimeText = CastTime_CustomText

	-- Icon is square of castbar height
	castbar.Icon = castbar:CreateTexture(nil, 'ARTWORK')
	castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	castbar.Icon:SetSize(height, height) -- square icon (width = height)
	castbar.Icon:SetPoint('RIGHT', castbar, 'LEFT', 0, 0)

	-- Spark
	castbar.Spark = castbar:CreateTexture(nil, 'OVERLAY')
	castbar.Spark:SetSize(20, 2.2*height)
	castbar.Spark:SetBlendMode('ADD')
	castbar.Spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)

	-- Interrupt / status display
	castbar.timeToHold = 0.12
	castbar.PostCastStart = Castbar_Update
	castbar.PostCastInterruptible = Castbar_Update
	castbar.PostCastFail = PostCast_Failed

	-- Add safezone
	if(latency and latency.show) then
		castbar.SafeZone = castbar:CreateTexture(nil, 'BACKGROUND')
		castbar.SafeZone:SetTexture(m.textures.status_texture)
		castbar.SafeZone:SetVertexColor(unpack(latency.color))
	end
	return castbar
end
