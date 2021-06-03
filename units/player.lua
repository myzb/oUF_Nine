local A, ns = ...

local core, config, m, oUF = ns.core, ns.config, ns.m, ns.oUF
local auras, filters = ns.auras, ns.filters

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'player'
local PLAYER_CLASS = select(2, UnitClass('player'))

-- ------------------------------------------------------------------------
-- > PLAYER UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > DYNAMIC TOTEM BAR ANCHORING
-- -----------------------------------

local function TotemBar_PositionUpdate(self)
	local anchor = self

	-- update anchor based on what is currently being displayed
	if (self.AdditionalPower and self.AdditionalPower.isShown) then
		anchor = self.AdditionalPower
	elseif (self.ClassPower and self.ClassPower.isShown) then
		anchor = self.ClassPower[1]
	elseif (self.Runes and self.Runes.isShown) then
		anchor = self.Runes[1]
	elseif (self.Stagger and self.Stagger.isShown) then
		anchor = self.Stagger
	end

	-- update anchor
	if (self.Totems.anchor ~= anchor) then
		self.Totems[1]:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -8)
		self.Totems.anchor = anchor
	end
end

-- -----------------------------------
-- > EXTRA RESOURCE BARS
-- -----------------------------------

-- Class Power Bars (Combo Points...)
local function ClassPower_PostUpdate(element, cur, max, maxChanged)
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

	element.isShown = element[1]:IsShown()
	TotemBar_PositionUpdate(element.__owner)
end

local function ClassPower_Create(self, width, height, texture)
	local numBars, maxWidth, gap = 11, width, 6
	local barWidth = (maxWidth / numBars) - (((numBars-1) * gap) / numBars)
	local classpower = {}

	for index = 1, numBars do
		local bar = CreateFrame('StatusBar', nil, self)
		bar:SetSize(barWidth, height)
		bar:SetStatusBarTexture(texture or m.textures.status_texture)

		local background = bar:CreateTexture(nil, 'BACKGROUND')
		background:SetAllPoints()
		background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		background:SetVertexColor(unpack(config.frame.colors.bg))

		core:CreateDropShadow(bar, 5, 5, 0, config.frame.shadows)

		if (index > 1) then
			bar:SetPoint('LEFT', classpower[index - 1], 'RIGHT', 6, 0)
		end
		classpower[index] = bar
	end

	-- Class Power Callbacks
	classpower.PostUpdate = ClassPower_PostUpdate

	return classpower
end

-- Death Knight Runebar
local function RuneBar_PostUpdate(element)
	element.isShown = element[1]:IsShown()
	TotemBar_PositionUpdate(element.__owner)
end

local function RuneBar_Create(self, width, height, texture)
	local numRunes, maxWidth, gap = 6, width, 6
	local runeWidth = (maxWidth / numRunes) - (((numRunes-1) * gap) / numRunes)

	local runes = {}
	for index = 1, numRunes do
		local rune = CreateFrame('StatusBar', nil, self)
		rune:SetSize(runeWidth, height)
		rune:SetStatusBarTexture(texture or m.textures.status_texture)

		local background = rune:CreateTexture(nil, 'BACKGROUND')
		background:SetAllPoints()
		background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		background:SetVertexColor(unpack(config.frame.colors.bg))

		core:CreateDropShadow(rune, 5, 5, 0, config.frame.shadows)

		if (index > 1) then
			rune:SetPoint('LEFT', runes[index - 1], 'RIGHT', gap, 0)
		end

		runes[index] = rune
	end

	runes.sortOrder = 'asc'
	runes.colorSpec = true -- color runes by spec
	runes.PostUpdate = RuneBar_PostUpdate

	return runes
end

-- Additional Power (Mana, ...)
local function AddPower_PostUpdate(element, cur, max)
	-- Show bar if not full for supported classes only
	if (AlternatePowerBar_ShouldDisplayPower(element) and cur ~= max) then
		element:Show()
	else
		element:Hide()
	end

	element.isShown = element:IsShown()
	TotemBar_PositionUpdate(element.__owner)
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
	local value = core:CreateFontstring(addpower, font_num, config.fontsize - 1, nil, 'RIGHT')
	value:SetShadowColor(0, 0, 0, 1)
	value:SetShadowOffset(1, -1)
	value:SetPoint('RIGHT', -4, 0)
	self:Tag(value, '[n:addpower]')

	core:CreateDropShadow(addpower, 5, 5, 0, config.frame.shadows)

	-- Add Power Callbacks
	addpower.PostUpdate = AddPower_PostUpdate

	return addpower
end

-- Monk StaggerBar
local function StaggerBar_PostUpdate(element, cur, max)
	-- Hide bar if full
	if (cur == 0 or UnitPowerType('player') == 0) then
		element:Hide()
	else
		element:Show()
	end
	element.isShown = element:IsShown()
	TotemBar_PositionUpdate(element.__owner)
end

local function StaggerBar_Create(self, width, height, texture)
	local stagger = CreateFrame('StatusBar', nil, self)
	stagger:SetAlpha(config.frame.alpha)
	stagger:SetStatusBarTexture(texture or m.textures.status_texture)
	stagger:GetStatusBarTexture():SetHorizTile(false)
	stagger:SetSize(width, height)

	local background = stagger:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	background:SetVertexColor(0, 0, 0, 0.9)

	-- Value
	local value = core:CreateFontstring(stagger, font_num, config.fontsize - 1, nil, 'RIGHT')
	value:SetShadowColor(0, 0, 0, 1)
	value:SetShadowOffset(1, -1)
	value:SetPoint('RIGHT', -4, 0)
	self:Tag(value, '[n:stagger]')

	core:CreateDropShadow(stagger, 5, 5, 0, config.frame.shadows)

	-- Add Power Callbacks
	stagger.PostUpdate = StaggerBar_PostUpdate

	return stagger
end

-- TotemBar (Shadowfiend, Gargoyle, ...)
local function TotemBar_Create(self, width)
	local numTotems, gap = 5, 1
	local totemWidth = (width / numTotems) - (((numTotems - 1) * gap) / numTotems)
	local totems = {}

	for index = 1, numTotems do
		-- Position and size of the totem indicator
		local totem = CreateFrame('Button', nil, self)
		totem:SetSize(totemWidth, totemWidth)

		local icon = totem:CreateTexture(nil, 'BORDER')
		icon:SetAllPoints()
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

		local cooldown = CreateFrame('Cooldown', nil, totem, 'CooldownFrameTemplate')
		cooldown:SetHideCountdownNumbers(true)
		cooldown:SetReverse(true)
		cooldown:SetAllPoints()

		core:CreateDropShadow(totem, 5, 5, 0, config.frame.shadows)

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
-- > INFO BARS - XP, REP ...
-- -----------------------------------

-- Color the Experience Bar
local function Experience_PostUpdate(element, unit, cur, max, rested, level, isHonor)
	local rep = element.__owner.Reputation
	if (isHonor) then
		-- Showing Honor
		element:SetStatusBarColor(255/255, 75/255, 75/255)
		element.Rested:SetStatusBarColor(255/255, 205/255, 90/255, 0)
	else
		-- Showing Experience
		element:SetStatusBarColor(150/255, 40/255, 200/255)
		element.Rested:SetStatusBarColor(197/255, 202/255, 233/255, 1)
	end
	rep:ForceUpdate()
end

local function Reputation_PostUpdate(element, unit)
	local xp = element.__owner.Experience
	local cfg = config.elements.infobars
	if (xp and xp:IsShown()) then
		element:SetPoint('BOTTOM', xp, 'TOP', 0, cfg.sep)
	else
		element:SetPoint(cfg.pos.v.a1, cfg.pos.v.af, cfg.pos.v.a2, cfg.pos.v.x, cfg.pos.v.y)
	end
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

-- -----------------------------------
-- > PLAYER AURA SPECIFIC FUNCTIONS
-- -----------------------------------

-- Filter Buffs
local function Buffs_CustomFilter(element, unit, button, ...)
	local spellId = select(10, ...)

	-- auras white-/blacklist
	if (filters[frame_name]['whitelist'][spellId]) then
		return true
	end
	if (filters[frame_name]['blacklist'][spellId]) then
		return false
	end

	-- get buff priority and warn level
	local prio = auras:GetBuffPrio(unit, ...)

	return (prio >= auras.BUFF_OWN_HELPFUL)
end

-- Filter Debuffs
local function Debuffs_CustomFilter(element, unit, button, ...)
	local spellId = select(10, ...)

	-- auras white-/blacklist
	if (filters[frame_name]['whitelist'][spellId]) then
		return true
	end
	if (filters[frame_name]['blacklist'][spellId]) then
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
	core:CreateLayout(self, layout)

	-- mouse events
	core:RegisterMouse(self)

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints(self)
	text.unit = core:CreateFontstring(text, font, config.fontsize -2, nil, 'LEFT')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetPoint('TOPLEFT', self.Health, 'TOPLEFT', 1, -2)
	text.unit:SetSize(0.8 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:difficultycolor][level]|r [raidcolor][n:name]')
	else
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:name]')
	end

	text.health = core:CreateFontstring(text, font_num, config.fontsize +1, nil, 'RIGHT')
	text.health:SetShadowColor(0, 0, 0, 1)
	text.health:SetShadowOffset(1, -1)
	text.health:SetPoint('RIGHT', self.Health, 'RIGHT', -4, 0)
	self:Tag(text.health, '[n:curhp]')

	text.status = core:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
	text.status:SetPoint('CENTER', self.Health, 'CENTER', 0, 0)
	if (layout.health.colorCustom) then
		self:Tag(text.status, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(text.status, '[n:perhp_status]')
	end

	text.group = core:CreateFontstring(text, font, config.fontsize -4, nil, 'LEFT')
	text.group:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 1, 2)
	text.group:SetAlpha(0)
	self:HookScript('OnEnter', function(s) s.Text.group:SetAlpha(1) end)
	self:HookScript('OnLeave', function(s) s.Text.group:SetAlpha(0) end)
	self:Tag(text.group, '[Group $>n:raidgroup]')

	text.power = core:CreateFontstring(text, font_num, config.fontsize +1, nil, 'RIGHT')
	text.power:SetShadowColor(0, 0, 0, 1)
	text.power:SetShadowOffset(1, -1)
	text.power:SetPoint('RIGHT', self.Power, 'RIGHT', -4, 0)
	self:Tag(text.power, '[n:curpp]')
	self.Text = text

	-- class resources
	if (uframe.classpower.show) then
		local width, height = layout.width, layout.power.height

		--  combo points, chi, soul shards, etc ...
		local classpower = ClassPower_Create(self, width, height, layout.texture)
		classpower[1]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
		self.ClassPower = classpower

		-- stagger, runes, additional power bar (mana)
		if (PLAYER_CLASS == 'DEATHKNIGHT') then
			local runes = RuneBar_Create(self, width, height, layout.texture)
			runes[1]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
			self.Runes = runes
		elseif (PLAYER_CLASS == 'MONK') then
			local stagger = StaggerBar_Create(self, width, 3, layout.texture)
			stagger:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
			self.Stagger = stagger
		else
			local addpower = AddPower_Create(self, width, 3, layout.texture)
			addpower:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
			self.AdditionalPower = addpower
		end
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
		combat.PostUpdate = function(element, inCombat)
			element.__owner.RestingIndicator:SetAlpha((inCombat and 0) or 1)
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

	-- oUF experience, reputation
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
