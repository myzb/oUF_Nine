local A, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF
local auras = ns.auras

local filters = config.filters
local spells = config.spells

local font = m.fonts.frizq
local font_num = m.fonts.myriad

local frame_name = 'focus'

-- Import API Functions
local Auras_ShouldDisplayDebuff = CompactUnitFrame_Util_ShouldDisplayDebuff -- FrameXML/CompactUnitFrame.lua
local Auras_ShouldDisplayBuff = CompactUnitFrame_UtilShouldDisplayBuff      -- FrameXML/CompactUnitFrame.lua
local Aura_IsPriorityDebuff = CompactUnitFrame_Util_IsPriorityDebuff        -- FrameXML/CompactUnitFrame.lua

-- ------------------------------------------------------------------------
-- > FOCUS UNIT SPECIFIC FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > FOCUS AURA SPECIFIC FUNCTIONS
-- -----------------------------------

-- Filter Buffs
local function Buffs_ShouldUpdate(element, unit, auraInfo)
	if (not auraInfo.isHelpful) then
		return false
	end

	local canApplyAura = auraInfo.canApplyAura
	local caster = auraInfo.sourceUnit
	local spellId = auraInfo.spellId

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[spellId]) then
		return true
	end
	if (filters[frame_name].blacklist[spellId]) then
		return false
	end

	-- adaptation of blizzard's raid frame filtering logic
	if (Auras_ShouldDisplayBuff(caster, spellId, canApplyAura)) then
		return true
	elseif (spells.external[spellId]) then
		return true
	elseif (spells.personal[spellId]) then
		return true
	else
		return false
	end
end

local function Buffs_CustomFilter(element, unit, button, dispellable, ...)
	local _, _, _, _, _, _, caster, _, _, spellId, canApplyAura = ...

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[spellId]) then
		return auras.AURA_MISC
	end
	if (filters[frame_name].blacklist[spellId]) then
		return auras.PRIO_HIDE
	end

	-- adaptation of blizzard's raid frame filtering logic
	if (Auras_ShouldDisplayBuff(caster, spellId, canApplyAura)) then
		button.prio = auras.AURA_MISC
	elseif (spells.external[spellId]) then
		button.prio = auras.PRIO_HIDE
	elseif (spells.personal[spellId]) then
		button.prio = auras.PRIO_HIDE
	else
		button.prio = auras.PRIO_HIDE
	end

	-- special auras will go in a separate group 'S'
	if (element.showSpecial) then
		if (spells.external[spellId]) then
			return 'S'
		elseif (spells.personal[spellId]) then
			return 'S'
		end
	end

	return button.prio
end

-- Filter Debuffs
local function Debuffs_ShouldUpdate(element, unit, auraInfo)
	if (not auraInfo.isHarmful) then
		return false
	end

	local caster = auraInfo.sourceUnit
	local spellId = auraInfo.spellId
	local isBossAura = auraInfo.isBossAura

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[spellId]) then
		return true
	end
	if (filters[frame_name].blacklist[spellId]) then
		return false
	end

	-- blizzards raid frame filtering logic
	if (isBossAura) then
		return true
	elseif (Aura_IsPriorityDebuff(spellId)) then
		return true
	elseif (Auras_ShouldDisplayDebuff(caster, spellId)) then
		return true
	else
		return false
	end
end

local function Debuffs_CustomFilter(element, unit, button, dispellable, ...)
	local _, _, _, _, _, _, caster, _, _, spellId, _, isBossAura, casterIsPlayer = ...

	-- auras white-/blacklist
	if (filters[frame_name].whitelist[spellId]) then
		return auras.AURA_MISC
	end
	if (filters[frame_name].blacklist[spellId]) then
		return auras.PRIO_HIDE
	end

	-- blizzards raid frame filtering logic
	if (isBossAura) then
		button.prio = auras.AURA_BOSS
	elseif (Aura_IsPriorityDebuff(spellId)) then
		button.prio = auras.AURA_PRIO
	elseif (Auras_ShouldDisplayDebuff(caster, spellId)) then
		button.prio = auras.AURA_MISC
	else
		button.prio = auras.PRIO_HIDE
	end

	-- some special auras will go in a separate group 'S'
	if (element.showSpecial) then
		if (dispellable and not casterIsPlayer) then
			return 'S'
		elseif (spells.crowdcontrol[spellId]) then
			return 'S'
		end
	end

	return button.prio
end

-- -----------------------------------
-- > FOCUS STYLE
-- -----------------------------------

local function createStyle(self)
	local uframe = config.units[frame_name]
	local layout = uframe.layout

	self:SetSize(layout.width, layout.height)
	self:SetPoint(uframe.pos.a1, uframe.pos.af, uframe.pos.a2, uframe.pos.x, uframe.pos.y)
	common:CreateLayout(self, layout)

	-- mouse events
	common:RegisterMouse(self)

	-- text strings
	local text = CreateFrame('Frame', nil, self.Health)
	text:SetAllPoints()
	text.unit = common:CreateFontstring(text, font, config.fontsize -2, nil, 'LEFT')
	text.unit:SetShadowColor(0, 0, 0, 1)
	text.unit:SetShadowOffset(1, -1)
	text.unit:SetPoint('TOPLEFT', 1, -2)
	text.unit:SetSize(0.8 * layout.width, config.fontsize + 2)
	if (layout.health.colorCustom) then
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:unitcolor][n:name]')
	else
		self:Tag(text.unit, '[n:difficultycolor][level]|r [n:name]')
	end

	text.status = common:CreateFontstring(text, font_num, config.fontsize +1, nil, 'CENTER')
	text.status:SetPoint('CENTER', 0, 0)
	if (layout.health.colorCustom) then
		self:Tag(text.status, '[n:reactioncolor][n:perhp_status]')
	else
		self:Tag(text.status, '[n:perhp_status]')
	end
	self.Text = text

	-- castbar
	if (uframe.castbar and uframe.castbar.show) then
		local cfg = uframe.castbar
		local castbar = common:CreateCastbar(self, cfg.width, cfg.height)
		castbar:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
		self.Castbar = castbar
	end

	-- icons frame (raid icons, leader, role, resting, ...)
	local icons = CreateFrame('Frame', nil, self.Health)
	icons:SetAllPoints()

	-- raid icons
	local raidIcon = icons:CreateTexture(nil, 'OVERLAY')
	raidIcon:SetPoint('CENTER', icons, 'TOP', 0, 5)
	raidIcon:SetSize(20, 20)
	self.RaidTargetIndicator = raidIcon

	-- quest icon
	local QuestIcon = common:CreateFontstring(self, font, 26, 'THINOUTLINE', 'CENTER')
	QuestIcon:SetPoint('LEFT', self.Health, 'RIGHT', 0, -2)
	QuestIcon:SetText('!')
	QuestIcon:SetTextColor(238/255, 217/255, 43/255)
	self.QuestIndicator = QuestIcon

	-- auras
	if (uframe.auras.show) then
		local cols = uframe.auras.cols or 4
		local size = uframe.auras.size or math.floor(self:GetWidth() / (2 * (cols + 0.25)))
		local rows = uframe.auras.rows or floor(2 * self:GetHeight() / (3 * size))

		local buffs = auras:CreateRaidAuras(icons, size, cols * rows, cols + 0.5, rows, 0, size - 6)
		buffs:SetPoint('BOTTOMRIGHT', self.Health, 'BOTTOMRIGHT', -2, 2)
		buffs.initialAnchor = 'BOTTOMRIGHT'
		buffs['growth-x'] = 'LEFT'
		buffs['growth-y'] = 'UP'
		buffs.showStealableBuffs = true
		buffs.special:SetPoint('TOPRIGHT', self.Health, 'TOPRIGHT', -2, -2)
		buffs.showSpecial = true
		buffs.CustomFilter = Buffs_CustomFilter
		buffs.ShouldUpdate = Buffs_ShouldUpdate

		self.RaidBuffs = buffs

		local debuffs = auras:CreateRaidAuras(icons, size, cols * rows, cols + 0.5, rows, 0, size + 8)
		debuffs:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMLEFT', 2, 2)
		debuffs.initialAnchor = 'BOTTOMLEFT'
		debuffs['growth-x'] = 'RIGHT'
		debuffs['growth-y'] = 'UP'
		debuffs.showDebuffType = true
		debuffs.special:SetPoint('CENTER', self.Health, 'CENTER', 0, 0)
		debuffs.showSpecial = uframe.auras.warn
		debuffs.dispelIcon = CreateFrame('Button', nil, debuffs)
		debuffs.dispelIcon:SetPoint('TOPRIGHT', self.Health)
		debuffs.dispelIcon:SetSize(14, 14)
		debuffs.CustomFilter = Debuffs_CustomFilter
		debuffs.ShouldUpdate = Debuffs_ShouldUpdate

		self.RaidDebuffs = debuffs
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
