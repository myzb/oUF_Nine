local A, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF

local font = m.fonts.frizq

local frame_name = 'focustarget'

-- ------------------------------------------------------------------------
-- > FOCUS TARGET UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > FOCUS TARGET STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	common:CreateLayout(self, layout)

	-- Mouse Events
	common:RegisterMouse(self)

	-- Text Strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.name = common:CreateFontstring(text, font, config.fontsize - 2, nil, 'CENTER')
	text.name:SetShadowColor(0, 0, 0, 1)
	text.name:SetShadowOffset(1, -1)
	text.name:SetPoint('CENTER', 0 , 0)
	text.name:SetSize(layout.width - 4, config.fontsize)
	if (layout.health.colorCustom) then
		self:Tag(text.name, '[n:unitcolor][n:abbrev_name]')
	else
		self:Tag(text.name, '[n:abbrev_name]')
	end
	self.Text = text
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))
	oUF:Spawn(frame_name)
end
