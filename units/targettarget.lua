local A, ns = ...

local base, core, config, m, oUF = ns.base, ns.core, ns.config, ns.m, ns.oUF

local font = m.fonts.frizq

local frame_name = 'targettarget'

-- ------------------------------------------------------------------------
-- > TARGET OF TARGET UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > TARGET OF TARGET STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	base:CreateLayout(self, layout)

	-- mouse events
	base:RegisterMouse(self)

	-- text strings
	local health = CreateFrame('Frame', nil, self.Health)
	health:SetAllPoints()
	health.unitname = core:CreateFontstring(health, font, config.fontsize -2, nil, 'CENTER')
	health.unitname:SetShadowColor(0, 0, 0, 1)
	health.unitname:SetShadowOffset(1, -1)
	health.unitname:SetPoint('CENTER', 0 ,0)
	health.unitname:SetSize(layout.width - 4, config.fontsize)
	if (layout.health.colorCustom) then
		self:Tag(health.unitname, '[n:unitcolor][n:abbrev_name]')
	else
		self:Tag(health.unitname, '[n:abbrev_name]')
	end
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))
	oUF:Spawn(frame_name)
end
