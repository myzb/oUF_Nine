local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF

local font = m.fonts.frizq

local frame_name = 'pet'

-- ------------------------------------------------------------------------
-- > PET UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > PET STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	core:CreateLayout(self, layout)

	-- mouse events
	core:RegisterMouse(self)

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.name = core:CreateFontstring(text, font, config.fontsize -2, nil, 'CENTER')
	text.name:SetShadowColor(0, 0, 0, 1)
	text.name:SetShadowOffset(1, -1)
	text.name:SetPoint('CENTER', 0 ,0)
	text.name:SetSize(layout.width - 4, config.fontsize)
	if (layout.health.colorCustom) then
		self:Tag(text.name, '[n:unitcolor][n:name]')
	else
		self:Tag(text.name, '[n:name]')
	end
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local cfg = uframe.castbar
		local castbar = core:CreateCastbar(self, cfg.width, cfg.height)
		castbar:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		self.Castbar = castbar
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
