local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'arena'

-- Import API functions
local Auras_ShouldDisplayDebuff = NameplateBuffContainerMixin.ShouldShowBuff -- Blizzard_NamePlates/Blizzard_NamePlates.lua

-- ------------------------------------------------------------------------
-- > ARENA UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

local function Arena_GetOpponentInfo(id)
	local specID = GetArenaOpponentSpec(id)
	if(specID and specID > 0) then
		return GetSpecializationInfoByID(specID)
	end
end

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
	local border = core:CreateBorder(self, 2, 2, self:GetFrameLevel() + 1, [[Interface\ChatFrame\ChatFrameBackground]])
	border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
	border:Hide()
	self:RegisterEvent('PLAYER_TARGET_CHANGED', UpdateTarget, true)
	self:RegisterEvent('GROUP_ROSTER_UPDATE', UpdateTarget, true)
	self.TargetBorder = border
end

-- -----------------------------------
-- > PVP TRINKET
-- -----------------------------------

local function Trinket_Update(self, event, unit)
	if (self.unit ~= unit) then
		return
	end
	local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
	if (spellID) then
		if (spellID ~= self.Trinket.spellID) then
			local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID)
			self.Trinket.spellID = spellID
			self.Trinket.icon:SetTexture(spellTextureNoOverride)
		end
		if (startTime ~= 0 and duration ~= 0 and self.Trinket.icon:GetTexture()) then
			self.Trinket.cd:SetCooldown(startTime/1000.0, duration/1000.0)
		else
			self.Trinket.cd:Clear()
		end
	end
end

local function Trinket_UpdateIcon(self, event, unit, spellID)
	if (self.unit ~= unit) then
		return
	end
	if (spellID ~= self.Trinket.spellID) then
		local spellTexture, spellTextureNoOverride = GetSpellTexture(spellID)
		self.Trinket.spellID = spellID
		self.Trinket.icon:SetTexture(spellTextureNoOverride)
	end
end

local function Trinket_Clear(self)
	self.Trinket.spellID = nil
	self.Trinket.icon:SetTexture(nil)
	self.Trinket.cd:Clear()
end

local function Trinket_Create(self)
	local trinket = CreateFrame('Button', self:GetDebugName() .. 'Button', self)
	trinket:SetSize(48, 48)
	trinket:SetPoint('LEFT', self, 'RIGHT', 10, 0)

	trinket.cd = CreateFrame('Cooldown', '$parentCooldown', trinket, 'CooldownFrameTemplate')
	trinket.cd:SetHideCountdownNumbers(false)
	trinket.cd:SetAllPoints()

	trinket.icon = trinket:CreateTexture(nil, 'BORDER')
	trinket.icon:SetAllPoints()
 	self.Trinket = trinket

	self:RegisterEvent('ARENA_COOLDOWNS_UPDATE', Trinket_Update)
	self:RegisterEvent('ARENA_CROWD_CONTROL_SPELL_UPDATE', Trinket_UpdateIcon)
	self:RegisterEvent('ARENA_OPPONENT_UPDATE', Trinket_UpdateIcon)
end

-- -----------------------------------
-- > ARENA ENEMY ROLE
-- -----------------------------------

local function ArenaRole_Update(self, event, ...)
	local unit = ...
	if (unit and self.unit ~= unit) then
		return
	end
	local id = tonumber(self.id)
	local _, _, _, _, role = Arena_GetOpponentInfo(id)
	if(role == 'TANK' or role == 'HEALER' or role == 'DAMAGER') then
		self.ArenaRole:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		self.ArenaRole:Show()
	else
		self.ArenaRole:Hide()
	end
end

local function ArenaRole_Create(self)
	local arenaRole = self.Health:CreateTexture(nil, 'OVERLAY')
	arenaRole:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
	arenaRole:SetPoint('CENTER', self, 'TOPLEFT', 7, -7)
	arenaRole:SetSize(12, 12)
	self.ArenaRole = arenaRole
end

-- -----------------------------------
-- > ARENA AURAS
-- -----------------------------------

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, ...)
	local name = select(1, ...)
	local duration = select(5, ...)
	local caster = select(7, ...)
	local showSelf = select(9, ...)
	local spellId = select(10, ...)
	local showAll = select(14, ...)

	-- auras white-/blacklist
	if (filters[frame_name]['whitelist'][spellId]) then
		return true
	end
	if (filters[frame_name]['blacklist'][spellId]) then
		return false
	end

	-- blizzard's nameplate filtering function
	return button.isPlayer and Auras_ShouldDisplayDebuff(nil, name, caster, showSelf, showAll, duration)
end

-- -----------------------------------
-- > ARENA STYLE
-- -----------------------------------

local function ArenaPrep_UpdateHealthColor(element, specID)
	local color = config.frame.colors
	element:SetStatusBarColor(unpack(color.base.fg))
	element.Background:SetVertexColor(unpack(color.base.bg))
end

local function Arenaprep_UpdatePowerColor(element, specID)
	local color = config.frame.colors
	element:SetStatusBarColor(unpack(color.away.fg))
end

local function Arena_PostUpdate(self, event)
	if (event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS') then
		-- hide irrelevant frames during arena preparation
		if (self.HealthPrediction) then
			self.HealthPrediction.myBar:Hide()
			self.HealthPrediction.otherBar:Hide()
			self.HealthPrediction.healAbsorbBar:Hide()
			self.HealthPrediction.overAbsorb:Hide()
			self.HealthPrediction.overHealAbsorb:Hide()
		end
		if (self.Text.status) then
			self.Text.status:SetText("")
		end
		ArenaRole_Update(self, event)
		Trinket_Clear(self)
	elseif (event == 'ARENA_OPPONENT_UPDATE') then
		ArenaRole_Update(self, event)
	elseif (event == 'OnShow') then
		UpdateTarget(self)
		C_PvP.RequestCrowdControlSpell(self.unit)
	end
end

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	core:CreateLayout(self, layout)

	-- mouse events
	core:RegisterMouse(self)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "focus")

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.unit = core:CreateFontstring(text, font, config.fontsize - 2, nil, 'LEFT')
	text.unit:SetPoint('TOPRIGHT', -2, 0)
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetSize(self:GetWidth() - 15, config.fontsize + 1)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[raidcolor][name]')
	else
		self:Tag(text.unit, '[name]')
	end

	text.status = core:CreateFontstring(text, font_num, config.fontsize + 2, nil, 'CENTER')
	text.status:SetPoint('LEFT')
	text.status:SetPoint('RIGHT')
	text.status:SetSize(self:GetWidth(), config.fontsize + 13)
	if (uframe.misc and uframe.misc.hideHPPerc) then
		self:Tag(text.status, '[n:status]')
	else
		self:Tag(text.status, '[n:perhp_status]')
	end

	text.spec = core:CreateFontstring(text, font, config.fontsize - 2, nil, 'RIGHT')
	text.spec:SetPoint('BOTTOMRIGHT', -1, 1)
	text.spec:SetShadowColor(0, 0, 0, 1)
	text.spec:SetShadowOffset(1, -1)
	text.spec:SetSize(self:GetWidth() - 15, config.fontsize + 1)
	if (layout.health.colorCustom) then
		self:Tag(text.spec, '[raidcolor][arenaspec]')
	else
		self:Tag(text.spec, '[raidcolor]')
	end

	text.power = core:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
	text.power:SetShadowColor(0, 0, 0, 1)
	text.power:SetShadowOffset(1, -1)
	text.power:SetPoint('CENTER', self.Power, 'CENTER', 0, 0)
	text.power:SetSize(layout.width - 10, config.fontsize + 1)
	self:Tag(text.power, '[n:curpp]')
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local width, height, pos = uframe.castbar.width, uframe.castbar.height, uframe.castbar.pos
		local castbar = core:CreateCastbar(self, width, height)
		castbar:SetPoint(pos.a1, self, pos.a2, pos.x, pos.y)
		self.Castbar = castbar
	end

	-- debuffs
	if (uframe.debuffs and uframe.debuffs.show) then
		local cols = uframe.debuffs.cols or 4
		local size = uframe.debuffs.size or math.floor(self:GetWidth() / (2 * (cols + 0.25)))
		local rows = uframe.debuffs.rows or math.floor(2 * self:GetHeight() / (3 * size))

		local debuffs = auras:CreateAuras(self, 15, cols, rows, size, 1)
		debuffs:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', 0, 0)
		debuffs.initialAnchor = 'BOTTOMRIGHT'
		debuffs['growth-x'] = 'LEFT'
		debuffs['growth-y'] = 'UP'
		debuffs.showDebuffType = true
		debuffs.filter = 'HARMFUL|INCLUDE_NAME_PLATE_ONLY'
		debuffs.CustomFilter = Debuffs_CustomFilter
		self.Debuffs = debuffs
	end

	-- arena role icon and pvp trinket
	ArenaRole_Create(self)
	Trinket_Create(self)

	-- target borders
	TargetBorder_Create(self)

	-- hp/power colors during arena preparation
	if (layout.health.colorCustom) then
		self.Health.UpdateColorArenaPreparation = ArenaPrep_UpdateHealthColor
	end
	self.Power.UpdateColorArenaPreparation = Arenaprep_UpdatePowerColor

	-- handle own non-oUF extras
	self.PostUpdate = Arena_PostUpdate
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A.. frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A.. frame_name:gsub('^%l', string.upper))

	local f = config.units[frame_name]
	for index = 1, MAX_ARENA_ENEMIES or 5 do
		local arena = oUF:Spawn(frame_name .. index, 'oUF_NineArena' .. index)
		--local arena = oUF:Spawn('player', 'oUF_NineArena' .. index) -- Debug

		if (index == 1) then
			arena:SetPoint(f.pos.a1, f.pos.af, f.pos.a2, f.pos.x, f.pos.y)
		else
			arena:SetPoint('TOP', _G['oUF_NineArena' .. index - 1], 'BOTTOM', 0, -f.sep)
		end
	end
end
