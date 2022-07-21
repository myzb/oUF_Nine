local _, ns = ...

local auras, m, oUF = {}, ns.m, ns.oUF
ns.auras = auras

local font_num = m.fonts.arial

-- Import API functions
local band, bor = bit.band, bit.bor
local math_floor = math.floor
local table_sort = table.sort
local table_insert = table.insert
local GetSpecializationRole = GetSpecializationRole
local GetSpecialization = GetSpecialization
local UnitIsFriend = UnitIsFriend
local Auras_IsPrioDebuff = CompactUnitFrame_Util_IsPriorityDebuff    -- FrameXML/CompactUnitFrame.lua
local Auras_IsBossAura = CompactUnitFrame_Util_IsBossAura            -- FrameXML/CompactUnitFrame.lua
auras.NameplateShowAura = NameplateBuffContainerMixin.ShouldShowBuff -- AddOns/Blizzard_NamePlates/Blizzard_NamePlates.lua

local PLAYER_CLASS = select(2, UnitClass('player'))

-- ------------------------------------------------------------------------
-- > AURAS RELATED FUNCTIONS
-- ------------------------------------------------------------------------

 auras.dispellableDebuff = {
	['Curse'] = {
		MAGE   = 'ALL',
		SHAMAN = 'ALL',
		DRUID  = 'ALL'
	},
	['Disease'] = {
		PALADIN = 'ALL',
		PRIEST  = 'ALL',
		SHAMAN  = 'ALL',
		MONK    = 'ALL',
	},
	['Poison'] = {
		PALADIN = 'ALL',
		DRUID   = 'ALL',
		MONK    = 'ALL'
	},
	['Magic'] = {
		PALADIN = 'HEALER',
		PRIEST  = 'ALL',
		SHAMAN  = 'HEALER',
		DRUID   = 'HEALER',
		MONK    = 'HEALER'
	}
 }

function auras:CanDispel(type, unit)
	if (not type or (unit and not UnitIsFriend('player', unit))) then
		return
	end

	local spec = GetSpecialization()
	local role = GetSpecializationRole(spec)
	local dispelBy = auras.dispellableDebuff[type] and auras.dispellableDebuff[type][PLAYER_CLASS]

	return (dispelBy == 'ALL') or (dispelBy == role)
end

function auras:CasterIsPlayer(caster)
	return caster == 'player' or caster == 'pet' or caster == 'vehicle'
end

-- -----------------------------------
-- > BUFF/DEBUFF PRIORITY
-- -----------------------------------

-- Auras Priorities
auras.PRIO_SHOW = 100
auras.AURA_BOSS = 3
auras.AURA_PRIO = 2
auras.AURA_MISC = 1
auras.PRIO_HIDE = false

-- Buff Priority Calculation
function auras:GetBuffPrio(unit, ...)
	return auras.AURA_MISC
end

-- Debuff Priority Calculation
function auras:GetDebuffPrio(unit, dispellable, ...)
	local _, _, _, _, _, _, _, _, _, spellId, _, isBossAura = ...

	if (isBossAura) then
		return auras.AURA_BOSS
	elseif (Auras_IsPrioDebuff(spellId)) then
		return auras.AURA_PRIO
	else
		return auras.AURA_MISC
	end
end

-- -----------------------------------
-- > AURA FUNCTIONS
-- -----------------------------------

local function Auras_PostCreateIcon(self, button)
	button.count:SetFont(font_num, 12, 'OUTLINE,MONOCHROME')
	button.count:SetPoint('BOTTOMRIGHT', 1, 0)
	button.count:SetJustifyH('RIGHT')
	button.count:GetParent():SetFrameLevel(button.cd:GetFrameLevel() - 1)
	button.cd:SetHideCountdownNumbers(true)
	button.cd:SetReverse(true)
	button.overlay:SetTexture(m.textures.border_button)
	button.overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
end

function auras:CreateAuras(self, size, num, cols, rows, sep)
	local tsize = size + sep
	local auras = CreateFrame('Frame', nil, self)
	auras:SetSize(tsize * cols, tsize * rows) -- container size
	auras.num = num
	auras.size = size
	auras.spacing = sep
	auras.disableCooldown = false
	auras.PostCreateIcon = Auras_PostCreateIcon

	return auras
end

-- -----------------------------------
-- > STATUSBAR AURA COLOR
-- -----------------------------------

local function StatusAura_Reset(element)
	element.AuraColor.rgba = nil
end

--- Colorize Registered StatusBar Based on Aura Event
local function StatusAura_Colorize(element, unit)
	local auracolor = element.AuraColor.rgba
	local statusbar = element.AuraColor.StatusBar

	if (auracolor and not statusbar:IsIgnoringColor()) then
		statusbar:DisableColorUpdate()
		statusbar:SetStatusBarColor(unpack(auracolor))
	elseif (not auracolor and statusbar:IsIgnoringColor()) then
		statusbar:EnableColorUpdate()
		statusbar:ForceUpdate()
	end
end

local function StatusAura_Check(element, unit, button, dispellable, ...)
	local debuffType = select(4, ...)
	local spellId = select(10, ...)
	local auracolor = element.AuraColor

	local color = auracolor:GetColor(unit, spellId, button.isPlayer, dispellable, debuffType)

	-- bar color override
	if (color) then
		auracolor.rgba = color
	end
end

function auras:CreateAuraColor(self, statusbar)
	local auracolor = {}
	auracolor.StatusBar = statusbar
	auracolor.Auras = self
	auracolor.GetColor = function() end
	self.AuraColor = auracolor

	-- statusbar hooks
	statusbar.ignoreColor = false
	statusbar.IsIgnoringColor = function(element)
		return element.ignoreColor
	end
	statusbar.EnableColorUpdate = function(element)
		element.ignoreColor = false
		element.UpdateColor = element.UpdateColor_Store or element.UpdateColor
	end
	statusbar.DisableColorUpdate = function(element)
		element.ignoreColor = true
		element.UpdateColor_Store = element.UpdateColor
		element.UpdateColor = function() end
	end

	-- aura module hooks
	if (self.PreUpdate) then
		hooksecurefunc(self, 'PreUpdate', StatusAura_Reset)
	else
		self.PreUpdate = StatusAura_Reset
	end
	if (self.CustomFilter) then
		hooksecurefunc(self, 'CustomFilter', StatusAura_Check)
	else
		self.CustomFilter = StatusAura_Check
	end
	if (self.PostUpdate) then
		hooksecurefunc(self, 'PostUpdate', StatusAura_Colorize)
	else
		self.PostUpdate = StatusAura_Colorize
	end

	return auracolor
end

-- -----------------------------------
-- > RAID AURA FUNCTIONS
-- -----------------------------------

local function RaidAuras_SortByPrio(container)
	local sort_func = function(a, b)
		if (a:IsShown() and b:IsShown()) then
			return a.prio > b.prio
		elseif (a:IsShown()) then
			return true
		end
	end
	table_sort(container, sort_func)
end

local function RaidAuras_UpdateSpecial(element, groups, idx)
	local group = groups[idx]
	local special = element.special
	local size = special.size or element.size or 16
	local sizex = size + (element['spacing-x'] or element.spacing or 0)
	local sizey = size + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthx = (element['growth-x'] == 'LEFT' and -1) or 1
	local growthy = (element['growth-y'] == 'DOWN' and -1) or 1
	local cols = math_floor(element:GetWidth() / sizex + 0.5)
	local num = special.num or #group

	-- display 'num' special buttons in their own frame
	for i = 1, num do
		local button = group[i]

		-- bail out if the to range is out of scope
		if (not button) then
			break
		end

		local col = (i - 1) % cols
		local row = math_floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, special, anchor, col * sizex * growthx, row * sizey * growthy)
		button.cd:SetHideCountdownNumbers(size <= element.size)
		button:SetSize(size, size)
		button:Show()
	end
	-- insert the rest in the normal groups so they can get displayed by the default mechanism
	for i = num + 1, #group do
		local button = group[i]

		-- bail out if the to range is out of scope
		if (not button) then
			break
		end
		if (not groups[button.prio]) then
			groups[button.prio] = {}
			if type(button.prio) == 'number' then
				table_insert(groups.used, button.prio)
			end
		end
		table_insert(groups[button.prio], button)
	end
	table_sort(groups.used, function(a, b) return a > b end)
end

local function RaidAuras_PreSetPosition(element, groups)
	if (groups['S']) then
		RaidAuras_SortByPrio(groups['S'])
		RaidAuras_UpdateSpecial(element, groups, 'S')
	end
end

local function RaidAuras_PostCreateIcon(self, button)
	button.overlay:SetTexture(m.textures.border_button)
	button.overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
end

-- Hide Cooldown Numbers by Default
local function RaidAuras_PostUpdateIcon(element, unit, button, index, position, prio)
	button.cd:SetHideCountdownNumbers(true)
end

function auras:CreateRaidAuras(self, size, num, cols, rows, sep, ...)
	local tsize = size + sep
	local auras = CreateFrame('Frame', nil, self)
	auras:SetSize(tsize * cols, tsize * rows)
	auras.size = size
	auras.num = num
	auras.spacing = sep
	auras.showStealableBuffs = true

	local othersize = ...
	if (othersize) then
		auras.special = CreateFrame('Frame', nil, auras)
		auras.special:SetSize(othersize, othersize)
		auras.special.size = othersize
		auras.special.num = 1
		auras.numMax = num + 1
	end

	auras.PostCreateIcon = RaidAuras_PostCreateIcon
	auras.PostUpdateIcon = RaidAuras_PostUpdateIcon
	auras.PreSetPosition = RaidAuras_PreSetPosition

	return auras
end
