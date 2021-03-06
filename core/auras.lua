local _, ns = ...

local auras, m, filters, oUF = {}, ns.m, ns.filters, ns.oUF
ns.auras = auras

local font_num = m.fonts.arial

-- Import API functions
local lps = LibStub('LibPlayerSpells-1.0')
local band, bor = bit.band, bit.bor
local math_floor = math.floor
local table_sort = table.sort
local table_insert = table.insert
local GetSpecializationRole = GetSpecializationRole
local GetSpecialization = GetSpecialization
local UnitIsFriend = UnitIsFriend
local Auras_IsPrioDebuff = CompactUnitFrame_Util_IsPriorityDebuff  -- FrameXML/CompactUnitFrame.lua
local Auras_IsBossAura = CompactUnitFrame_Util_IsBossAura          -- FrameXML/CompactUnitFrame.lua

local PLAYER_CLASS = select(2, UnitClass('player'))

-- ------------------------------------------------------------------------
-- > AURAS RELATED FUNCTIONS
-- ------------------------------------------------------------------------

function auras:CanDispel(type, unit)
	if (not type or (unit and not UnitIsFriend('player', unit))) then
		return
	end

	local debuff = {
		['Curse'] = {
			MAGE = 'ALL',
			SHAMAN = 'ALL',
			DRUID = 'ALL'
		},
		['Disease'] = {
			PALADIN = 'ALL',
			PRIEST = 'ALL',
			SHAMAN = 'ALL',
			MONK = 'ALL',
		},
		['Poison'] = {
			PALADIN = 'ALL',
			DRUID = 'ALL',
			MONK = 'ALL'
		},
		['Magic'] = {
			PALADIN = 'HEALER',
			PRIEST = 'ALL',
			SHAMAN = 'HEALER',
			DRUID = 'HEALER',
			MONK = 'HEALER'
		}
	}
	local spec = GetSpecialization()
	local role = GetSpecializationRole(spec)
	local dispelBy = debuff[type] and debuff[type][PLAYER_CLASS]

	return (dispelBy == 'ALL') or (dispelBy == role)
end

-- -----------------------------------
-- > BUFF/DEBUFF PRIORITY
-- -----------------------------------

-- LibPlayerSpell Constants
local SC = lps.constants

local COOLDOWN_SURVIVAL = bor(SC.COOLDOWN, SC.SURVIVAL)
local COOLDOWN_BURST = bor(SC.COOLDOWN, SC.BURST)
local COOLDOWN_PERSONAL_AURA = bor(SC.COOLDOWN, SC.PERSONAL, SC.AURA)

-- Auras Priorities
auras.BUFF_WHITELIST = 7
auras.BUFF_DEFENSIVE = 6
auras.BUFF_OFFENSIVE = 5
auras.BUFF_PERSONAL = 4
auras.BUFF_OWN_HELPFUL = 3
auras.BUFF_CLASS = 2
auras.BUFF_MISC = 1

auras.DEBUFF_BOSS = 11
auras.DEBUFF_PRIO = 10
auras.DEBUFF_WHITELIST = 9
auras.DEBUFF_STUN = 8
auras.DEBUFF_INCAPACITATE = 7
auras.DEBUFF_DISORIENT = 6
auras.DEBUFF_ROOT = 5
auras.DEBUFF_INTERRUPT = 4
auras.DEBUFF_PLAYER = 3
auras.DEBUFF_DISPEL = 2
auras.DEBUFF_MISC = 1

auras.cache = { help = {}, harm = {} }

-- Buff Priority Calculation
function auras:GetBuffPrio(unit, ...)
	local spellId = select(10, ...)
	local group = (UnitIsFriend('player', unit)) and 'help' or 'harm'

	if (auras.cache[group][spellId]) then
		return unpack(auras.cache[group][spellId])
	end

	local prio, warn = auras.BUFF_MISC, false
	local flags = lps:GetSpellInfo(spellId)

	if (not flags) then
		-- aura not know by the lib, cache and return
		auras.cache[group][spellId] = { prio, warn }
		return prio, warn
	end

	local duration = select(5, ...)
	local caster = select(7, ...)
	local casterIsUs = (caster == 'player' or caster == 'vehicle')

	if (band(flags, COOLDOWN_SURVIVAL) == COOLDOWN_SURVIVAL) then
		prio = auras.BUFF_DEFENSIVE
		if (not casterIsUs and (duration > 6)) then
			-- big survival cds are usually > 6 sec
			warn = true
		end
	elseif (band(flags, COOLDOWN_BURST) == COOLDOWN_BURST) then
		prio = auras.BUFF_OFFENSIVE
	elseif (band(flags, COOLDOWN_PERSONAL_AURA) == COOLDOWN_PERSONAL_AURA) then
		prio = auras.BUFF_PERSONAL
	elseif (band(flags, SC.HELPFUL) ~= 0 and casterIsUs) then
		prio = auras.BUFF_OWN_HELPFUL
	else
		prio = auras.BUFF_CLASS
	end

	-- cache result
	auras.cache[group][spellId] = { prio, warn }
	return prio, warn
end

-- Debuff Priority Calculation
function auras:GetDebuffPrio(unit, dispellable, ...)
	local spellId = select(10, ...)
	local group = (UnitIsFriend('player', unit)) and 'help' or 'harm'

	if (auras.cache[group][spellId]) then
		return unpack(auras.cache[group][spellId])
	end

	local casterIsHuman = select(13, ...)
	local flags, _, _, special = lps:GetSpellInfo(spellId)
	local prio, warn = auras.DEBUFF_MISC, false

	if (Auras_IsBossAura(...)) then
		prio = auras.DEBUFF_BOSS
		if (dispellable) then
			warn = true
		end
	elseif (Auras_IsPrioDebuff(...)) then
		prio = auras.DEBUFF_PRIO
	elseif (flags and special and band(special, SC.CROWD_CTRL)) then
		if (band(flags, SC.STUN) ~= 0) then
			prio = auras.DEBUFF_STUN
		elseif (band(flags, SC.INCAPACITATE) ~= 0) then
			prio = auras.DEBUFF_INCAPACITATE
		elseif (band(flags, SC.DISORIENT) ~= 0) then
			prio = auras.DEBUFF_DISORIENT
		elseif (band(flags, SC.ROOT) ~= 0) then
			prio = auras.DEBUFF_ROOT
		end
		warn = true
	elseif (flags and band(flags, SC.INTERRUPT) ~= 0) then
		prio = auras.DEBUFF_INTERRUPT
		warn = true
	elseif (dispellable) then
		prio = auras.DEBUFF_DISPEL
		if (not casterIsHuman) then
			warn = true
		end
	end

	-- cache result
	auras.cache[group][spellId] = { prio, warn }
	return prio, warn
end

-- Aura Cache Wiper
local function Auras_WipeCache(self, event, unit)
	if (unit == 'player') then
		auras.cache['help'] = {}
		auras.cache['harm'] = {}
	end
end

do
	local cache = CreateFrame('Frame')
	cache:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	cache:SetScript('OnEvent', Auras_WipeCache)
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

function auras:CreateAuras(self, num, cols, rows, size, spacing)
	local auras = CreateFrame('Frame', nil, self)
	auras:SetSize((cols * (size + spacing or 0)), rows * (size + spacing or 0)) -- container size
	auras.num = num or (cols * rows)
	auras.size = size
	auras.spacing = spacing or 0
	auras.disableCooldown = false
	auras.PostCreateIcon = Auras_PostCreateIcon

	return auras
end

-- -----------------------------------
-- > STATUSBAR AURA COLOR
-- -----------------------------------

local function StatusAura_Reset(element)
	element.auraColor = false
end

--- Colorize Registered StatusBar Based on Aura Event
local function StatusAura_Colorize(element, unit)
	local bar = element.StatusBar
	if (element.auraColor and not bar:IsIgnoringColor()) then
		bar:DisableColorUpdate()
		bar:SetStatusBarColor(unpack(element.auraColor))
	elseif (not element.auraColor and bar:IsIgnoringColor()) then
		bar:EnableColorUpdate()
		bar:ForceUpdate()
	end
end

local function StatusAura_Check(element, unit, button, isDispellable, ...)
	local spellId = select(10, ...)
	local auraColor = filters.auracolor[PLAYER_CLASS][spellId]

	-- hp bar color override
	if (auraColor and button.isPlayer) then
		element.auraColor = auraColor
	end
end

function auras:EnableColorToggle(self, statusbar)
	self.StatusBar = statusbar

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

function auras:CreateRaidAuras(self, size, num, cols, rows, othersize)
	local auras = CreateFrame('Frame', nil, self)
	auras:SetSize(size * cols, size * rows)
	auras.size = size
	auras.num = num
	auras.showStealableBuffs = true

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
