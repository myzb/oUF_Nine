local A, ns = ...

local base, core, config, m, oUF = ns.base, ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'player'
local PLAYER_CLASS = select(2, UnitClass('player'))

-- ------------------------------------------------------------------------
-- > PLAYER UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > DYNAMIC RESOURCE BAR ANCHORING
-- -----------------------------------

local function TotemBar_PositionUpdate(self)
	local parent = self.__owner
	local anchor = parent

	-- update anchor based on what is currently being displayed
	if (parent.AdditionalPower.isShown) then
		anchor = parent.AdditionalPower
	end
	if (parent.ClassPower and parent.ClassPower.isShown) then
		anchor = parent.ClassPower[1]
	end
	-- update anchor
	if (parent.Totems.anchor ~= anchor) then
		parent.Totems[1]:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -8)
		parent.Totems.anchor = anchor
	end
end

local function AddPower_PositionUpdate(self)
	local parent = self.__owner
	local anchor = parent

	-- update anchor based on what is currently being displayed
	if (parent.ClassPower and parent.ClassPower.isShown) then
		anchor = parent.ClassPower[1]
	end

	-- updat anchor
	if (parent.AdditionalPower.anchor ~= anchor) then
		parent.AdditionalPower:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -10)
		parent.AdditionalPower.anchor = anchor
	end
end

-- -----------------------------------
-- > EXTRA RESOURCE BARS
-- -----------------------------------

-- Class Power Bars (Combo Points...)
local function ClassPower_PostUpdate(element, cur, max, maxChanged, powerType)
	if (maxChanged) then
		local maxWidth = element.__owner:GetWidth()
		local gap = 6
		local barWidth = (maxWidth / max) - (((max-1) * gap) / max)

		for index = 1, max do
			local bar = element[index]
			bar:SetWidth(barWidth)

			if (index > 1) then
				bar:ClearAllPoints()
				bar:SetPoint('LEFT', element[index - 1], 'RIGHT', gap, 0)
			end
		end
	end

	-- Colorize the last bar
	local lastBarColor = {
		COMBO_POINTS = { 255/255, 26/255, 48/255 },
		ARCANE_CHARGES = { 238/255, 48/255, 83/255 },
		CHI = { 0/255, 143/255, 247/255 },
		HOLY_POWER = { 255/255, 26/255, 48/255 },
		SOUL_SHARDS = { 255/255, 26/255, 48/255 }
	}

	if (max) then
		local lastBar = element[max]
		lastBar:SetStatusBarColor(unpack(lastBarColor[powerType]))
	end

	-- update other bars positions
	element.isShown = element.isEnabled
	AddPower_PositionUpdate(element)
	TotemBar_PositionUpdate(element)
end

local function ClassPower_Create(self, width, height, texture)
	local numBars, maxWidth, gap = 11, width, 6
	local barWidth = (maxWidth / numBars) - (((numBars-1) * gap) / numBars)
	local classpower = {}

	for index = 1, 11 do
		local bar = CreateFrame('StatusBar', nil, self)
		bar:SetSize(barWidth, height)
		bar:SetStatusBarTexture(texture or m.textures.status_texture)

		local background = bar:CreateTexture(nil, 'BACKGROUND')
		background:SetAllPoints()
		background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		background:SetVertexColor(unpack(config.frame.colors.bg))

		core:createDropShadow(bar, 5, 5, 0, config.frame.shadows)

		if (index > 1) then
			bar:SetPoint('LEFT', classpower[index - 1], 'RIGHT', 6, 0)
		end

		if (index > 5) then
			bar:SetFrameLevel(bar:GetFrameLevel() + 1)
		end

		classpower[index] = bar
	end

	-- Class Power Callbacks
	classpower.PostUpdate = ClassPower_PostUpdate

	return classpower
end

-- Death Knight Runebar
local function RuneBar_Create(self, width, height, texture)
	local numRunes, maxWidth, gap = 6, width, 6
	local runeWidth = (maxWidth / numRunes) - (((numRunes-1) * gap) / numRunes)

	local runes = {}
	for index = 1, 6 do
		local rune = CreateFrame('StatusBar', nil, self)
		rune:SetSize(runeWidth, height)
		rune:SetStatusBarTexture(texture or m.textures.status_texture)

		local background = rune:CreateTexture(nil, 'BACKGROUND')
		background:SetAllPoints()
		background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		background:SetVertexColor(unpack(config.frame.colors.bg))

		core:createDropShadow(rune, 5, 5, 0, config.frame.shadows)

		if (index > 1) then
			rune:SetPoint('LEFT', runes[index - 1], 'RIGHT', gap, 0)
		end

		runes[index] = rune
	end

	runes.sortOrder = 'asc'
	runes.colorSpec = true -- color runes by spec

	return runes
end

-- Additional Power (Mana, ...)
local function AddPower_PostUpdate(self, cur, max)
	-- Hide bar if full
	if (cur == max or UnitPowerType('player') == 0) then
		self:Hide()
	else
		self:Show()
	end

	self.isShown = self:IsShown()
	TotemBar_PositionUpdate(self)
end

local function AddPower_Create(self, width, height, texture)
	local addpower = CreateFrame('StatusBar', nil, self)
	addpower:SetAlpha(config.frame.alpha)
	addpower:SetStatusBarTexture(texture or m.textures.status_texture)
	addpower:GetStatusBarTexture():SetHorizTile(false)
	addpower:SetSize(width, height)
	addpower.colorPower = true
	addpower.frequentUpdates = true

	local background = addpower:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	background:SetVertexColor(0, 0, 0, 0.9)

	-- Value
	local value = core:createFontstring(addpower, font_num, config.fontsize - 1, nil, 'RIGHT')
	value:SetShadowColor(0, 0, 0, 1)
	value:SetShadowOffset(1, -1)
	value:SetPoint('RIGHT', -4, 0)
	self:Tag(value, '[n:addpower]')

	core:createDropShadow(addpower, 5, 5, 0, config.frame.shadows)

	-- Add Power Callbacks
	addpower.PostUpdate = AddPower_PostUpdate

	return addpower
end

-- TotemBar (Shadowfiend, Gargoyle, ...)
local function TotemBar_Create(self, width)
	local numTotems, gap = 5, 1
	local totemWidth = (width / numTotems) - (((numTotems - 1) * gap) / numTotems)
	local totems = {}

	for index = 1, 5 do
		-- Position and size of the totem indicator
		local totem = CreateFrame('Button', nil, self)
		totem:SetSize(totemWidth, totemWidth)

		local icon = totem:CreateTexture(nil, 'BORDER')
		icon:SetAllPoints()
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

		local cooldown = CreateFrame('Cooldown', nil, totem, 'CooldownFrameTemplate')
		cooldown.text = cooldown:GetRegions()
		cooldown.text:SetFont(font, config.fontsize - 2, 'OUTLINE')
		cooldown:SetReverse(true)
		cooldown:SetAllPoints()

		local overlay = totem:CreateTexture(nil, 'OVERLAY')
		overlay:SetTexture(m.textures.border_dark)
		overlay:SetAllPoints()
		overlay:SetTexCoord(0, 1, 0, 1)
		overlay:SetVertexColor(0.8, 0.8, 0.8)
		overlay:Show()

		totem.overlay = overlay
		totem.Icon = icon
		totem.Cooldown = cooldown

		if (index > 1) then
			totem:SetPoint('LEFT', totems[index - 1], 'RIGHT', gap, 0)
		end

		totems[index] = totem
	end

	return totems
end

-- -----------------------------------
-- > XP, REP, AP BARS
-- -----------------------------------

-- Color the Experience Bar
local function Experience_PostUpdate(self, unit, cur, max, rested, level, isHonor)
	local rep = self.__owner.Reputation
	if (isHonor) then
		-- Showing Honor
		self:SetStatusBarColor(255/255, 75/255, 75/255)
		self.Rested:SetStatusBarColor(255/255, 205/255, 90/255, 0)
	else
		-- Showing Experience
		self:SetStatusBarColor(150/255, 40/255, 200/255)
		self.Rested:SetStatusBarColor(197/255, 202/255, 233/255, 1)
	end
	rep:ForceUpdate()
end

local function Reputation_PostUpdate(self, unit)
	local xp, ap = self.__owner.Experience, self.__owner.ArtifactPower
	local cfg = config.elements.infobars
	if (xp and xp:IsShown()) then
		self:SetPoint('BOTTOM', xp, 'TOP', 0, cfg.sep)
	else
		self:SetPoint(cfg.pos.v.a1, cfg.pos.v.af, cfg.pos.v.a2, cfg.pos.v.x, cfg.pos.v.y)
	end
	ap:ForceUpdate()
end

local function ReputationBar_Create(self, width, height, texture)
	local reputation = CreateFrame('StatusBar', nil, self)
	reputation:SetStatusBarTexture(texture or m.textures.status_texture)
	reputation:SetSize(width, height)

	local background = reputation:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(unpack(config.frame.colors.bg))

	reputation:EnableMouse(true)
	reputation.colorStanding = true
	reputation.PostUpdate = Reputation_PostUpdate

	return reputation
end

local function ExperienceBar_Create(self, width, height, texture)
	local experience = CreateFrame('StatusBar', nil, self)
	experience:SetStatusBarTexture(texture or m.textures.status_texture)
	experience:SetSize(width, height)

	experience.Rested = CreateFrame('StatusBar', nil, experience)
	experience.Rested:SetStatusBarTexture(texture or m.textures.status_texture)
	experience.Rested:SetAllPoints()

	local background = experience.Rested:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(unpack(config.frame.colors.bg))

	experience:EnableMouse(true)
	experience.PostUpdate = Experience_PostUpdate

	return experience
end

local function ArtifactBar_PostUpdate(self)
	local xp, rep = self.__owner.Experience, self.__owner.Reputation
	local cfg = config.elements.infobars
	if (rep and rep:IsShown()) then
		self:SetPoint('BOTTOM', rep, 'TOP', 0, cfg.sep)
	elseif (xp and xp:IsShown()) then
		self:SetPoint('BOTTOM', xp, 'TOP', 0, cfg.sep)
	else
		self:SetPoint(cfg.pos.v.a1, cfg.pos.v.af, cfg.pos.v.a2, cfg.pos.v.x, cfg.pos.v.y)
	end
end

local function ArtifactPowerBar_Create(self, width, height, texture)
	local artifactpower = CreateFrame('StatusBar', nil, self)
	artifactpower:SetStatusBarTexture(texture or m.textures.status_texture)
	artifactpower:SetStatusBarColor(217/255, 205/255, 145/255)
	artifactpower:SetSize(width, height)

	local background = artifactpower:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(m.textures.bg_texture)
	background:SetVertexColor(unpack(config.frame.colors.bg))

	artifactpower:EnableMouse(true)
	artifactpower.PostUpdate = ArtifactBar_PostUpdate

	return artifactpower
end

-- -----------------------------------
-- > PLAYER AURA SPECIFIC FUNCTIONS
-- -----------------------------------

-- Filter Buffs
local function Buffs_CustomFilter(element, unit, button, ...)
	local spellId = select(10, ...)

	-- hide blacklisted buffs
	if (filters.buffs['blacklist'][spellId]) then
		return false
	end
	-- get buff priority and warn level
	button.prio = auras:GetBuffPrio(...)

	return (button.prio >= auras.BUFF_OWN_HELPFUL)
end

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, ...)
	local spellId = select(10, ...)

	-- hide blacklisted debuffs
	if (filters.debuffs['blacklist'][spellId]) then
		return false
	end
	return true
end

-- -----------------------------------
-- > PLAYER STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	-- root frame
	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	base:CreateLayout(self, layout)

	-- mouse events
	base:RegisterMouse(self)

	-- text strings
	local health = CreateFrame('Frame', nil, self.Health)
	health:SetAllPoints()
	health.level = core:createFontstring(health, font, config.fontsize -2, nil, 'LEFT')
	health.level:SetShadowColor(0, 0, 0, 1)
	health.level:SetShadowOffset(1, -1)
	health.level:SetPoint('TOPLEFT', 1, -2)
	self:Tag(health.level, '[n:difficultycolor][level]')

	health.unitname = core:createFontstring(health, font, config.fontsize -2, nil, 'LEFT')
	health.unitname:SetShadowColor(0, 0, 0, 1)
	health.unitname:SetShadowOffset(1, -1)
	health.unitname:SetPoint('LEFT', health.level, 'RIGHT', 1, 0)
	health.unitname:SetSize(0.46 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(health.unitname, '[raidcolor][n:name]')
	else
		self:Tag(health.unitname, '[n:name]')
	end

	health.hpvalue = core:createFontstring(health, font_num, config.fontsize +1, nil, 'RIGHT')
	health.hpvalue:SetShadowColor(0, 0, 0, 1)
	health.hpvalue:SetShadowOffset(1, -1)
	health.hpvalue:SetPoint('RIGHT', -4, 0)
	self:Tag(health.hpvalue, '[n:hpvalue]')
	health.hpperc = core:createFontstring(health, font_num, config.fontsize +1, nil, 'CENTER')
	health.hpperc:SetPoint('CENTER', 0, 0)
	if (layout.health.colorCustom) then
		self:Tag(health.hpperc, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(health.hpperc, '[n:perhp_status]')
	end

	local power = CreateFrame('Frame', nil, self.Power)
	power:SetAllPoints()
	power.value = core:createFontstring(power, font_num, config.fontsize +1, nil, 'RIGHT')
	power.value:SetShadowColor(0, 0, 0, 1)
	power.value:SetShadowOffset(1, -1)
	power.value:SetPoint('RIGHT', -4, 0)
	self:Tag(power.value, '[n:powervalue]')

	-- class power (combo points, etc...)
	if (uframe.classpower.show) then
		local classpower = ClassPower_Create(self, layout.width, layout.power.height, layout.texture)
		classpower[1]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
		self.ClassPower = classpower
	end

	-- death knight runes
	if (uframe.classpower.show and PLAYER_CLASS == 'DEATHKNIGHT') then
		local runes = RuneBar_Create(self, layout.width, layout.power.height, layout.texture)
		runes[1]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
		self.Runes = runes
	end

	-- additional power bar (mana bar)
	do
		local addpower = AddPower_Create(self, layout.width, 3, layout.texture)
		addpower:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
		self.AdditionalPower = addpower
	end

	-- totembar (shadowfiend, gargoyle, ...)
	if (uframe.totems.show) then
		local totems = TotemBar_Create(self, math.floor(2/3 * layout.width))
		totems[1]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
		self.Totems = totems
	end

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local cfg = uframe.castbar
		local castbar = core:CreateCastbar(self, cfg.width, cfg.height, nil, cfg.latency)
		local xoffset = cfg.pos.x + floor(cfg.height/2 + 0.5)
		castbar:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, xoffset, cfg.pos.y)
		self.Castbar = castbar
	end

	-- alternative power (quest or boss special power)
	if (uframe.altpower and uframe.altpower.show) then
		local cfg = uframe.altpower
		local altpower = core:CreateAltPower(self, cfg.width, cfg.height, layout.texture)
		altpower:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		self.AlternativePower = altpower
	end

	-- icons frame (raid icons, leader, role, resting, ...)
	local icons = CreateFrame('Frame', nil, self.Health)
	icons:SetFrameLevel(self.Health:GetFrameLevel() +2)
	icons:SetAllPoints()

	-- raid icons
	local raidIcon = icons:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', icons, 'TOP', 0, 5)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- leader icon
	local leaderIcon = icons:CreateTexture(nil, 'OVERLAY')
	leaderIcon:SetPoint('CENTER', icons, 'TOPRIGHT', -8, -2)
	leaderIcon:SetSize(14, 14)
	self.LeaderIndicator = leaderIcon

	-- combined status indicator (resting / combat)
	do
		local resting = self.Power:CreateTexture(nil, 'OVERLAY')
		resting:SetPoint('CENTER', self.Power, 'BOTTOMLEFT', 0 , 0)
		resting:SetSize(22, 22)
		self.RestingIndicator = resting

		local combat = self.Power:CreateTexture(nil, 'OVERLAY')
		combat:SetSize(22, 22)
		combat:SetPoint('CENTER', self.Power, 'BOTTOMLEFT', 0 ,0)
		combat.PostUpdate = function(self, inCombat)
			self.__owner.RestingIndicator:SetAlpha((inCombat and 0) or 1)
		end
		self.CombatIndicator = combat
	end

	-- auras
	if (uframe.auras and uframe.auras.show) then
		local cols = (uframe.auras.cols) or 4
		local size = (uframe.auras.size) or floor(self:GetWidth() / (2 * (cols + 0.25)))
		local buffs = auras:CreateAuras(self, 15, cols, 4, size, 1)
		buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 4)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true
		buffs.CustomFilter = Buffs_CustomFilter
		self.Buffs = buffs

		local debuffs = auras:CreateAuras(self, 15, cols, 4, size, 1)
		debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 4)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.showDebuffType = true
		debuffs.CustomFilter = Debuffs_CustomFilter
		self.Debuffs = debuffs
	end

	-- oUF experience, reputation, artifact power
	if (config.elements.infobars.show) then
		local cfg = config.elements.infobars
		local vpt, hpt = cfg.pos.v, cfg.pos.h
		local experience = ExperienceBar_Create(self, cfg.width, cfg.height, cfg.texture)
		experience:SetPoint(hpt.a1, hpt.af, hpt.a2, hpt.x, hpt.y)
		experience:SetPoint(vpt.a1, vpt.af, vpt.a2, vpt.x, vpt.y)
		self.Experience = experience

		local reputation = ReputationBar_Create(self, cfg.width, cfg.height, cfg.texture)
		reputation:SetPoint(hpt.a1, hpt.af, hpt.a2, hpt.x, hpt.y)
		self.Reputation = reputation

		local artifactpower = ArtifactPowerBar_Create(self, cfg.width, cfg.height, cfg.texture)
		artifactpower:SetPoint(hpt.a1, hpt.af, hpt.a2, hpt.x, hpt.y)
		self.ArtifactPower = artifactpower
	end
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------

if (config.units[frame_name].show) then
	oUF:RegisterStyle(A..frame_name:gsub('^%l', string.upper), createStyle)
	oUF:SetActiveStyle(A..frame_name:gsub('^%l', string.upper))
	oUF:Spawn(frame_name)
end
