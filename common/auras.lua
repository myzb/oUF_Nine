local _, ns = ...

local auras, m, oUF = {}, ns.m, ns.oUF
ns.auras = auras

local font_num = m.fonts.arial

-- Import API functions
local GetSpecializationRole = GetSpecializationRole
local GetSpecialization = GetSpecialization
local UnitIsFriend = UnitIsFriend

local PLAYER_CLASS = select(2, UnitClass('player'))

-- ------------------------------------------------------------------------
-- > AURAS RELATED FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > DISPELLABLE DEBUFFS
-- -----------------------------------

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
-- > BLIZZARD'S AURA FILTERING LOGIC
-- -----------------------------------

function auras:PlayerShowBuffs(unit, data, expanded)
	local timeLeft = data.expirationTime - GetTime()
	local hideUnlessExpanded = (data.duration == 0) or (data.expirationTime == 0)
			or ((timeLeft) > BUFF_DURATION_WARNING_TIME)
	return not hideUnlessExpanded or expanded
end

function auras:NameplateShowDebuffs(unit, data, showAll)
	return NameplateBuffContainerMixin.ShouldShowBuff(self, data, showAll)
end

function auras:TargetShowBuffs(unit, data)
	return not data.isNameplateOnly
end

function auras:TargetShowDebuffs(unit, data)
	return TargetFrameMixin.ShouldShowDebuffs(self, unit, data.sourceUnit,
			data.nameplateShowAll, data.isFromPlayerOrPlayerPet)
end

function auras:RaidShowBuffs(unit, data)
	return AuraUtil.ProcessAura(data, true) == AuraUtil.AuraUpdateChangedType.Buff
end

function auras:RaidShowDebuffs(unit, data)
	return AuraUtil.ProcessAura(data, true) == AuraUtil.AuraUpdateChangedType.Debuff
end

-- -----------------------------------
-- > STATUSBAR AURA COLOR
-- -----------------------------------

local function StatusAura_Reset(element, unit)
	local auracolor = element.AuraColor

	if (auracolor.auraInstanceID) then
		local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auracolor.auraInstanceID)
		if (not data) then
			auracolor.auraInstanceID = nil
			element.AuraColor.rgba = nil
		end
	end
end

--- Colorize Registered StatusBar Based on Aura Event
local function StatusAura_Colorize(element, unit)
	local rgba = element.AuraColor.rgba
	local statusbar = element.AuraColor.StatusBar

	if (rgba and not statusbar:IsIgnoringColor()) then
		statusbar:DisableColorUpdate()
		statusbar:SetStatusBarColor(unpack(rgba))
	elseif (not rgba and statusbar:IsIgnoringColor()) then
		statusbar:EnableColorUpdate()
		statusbar:ForceUpdate()
	end
end

local function StatusAura_Check(element, unit, data)
	local auracolor = element.AuraColor

	local color = auracolor:GetColor(unit, data)

	-- bar color override
	if (color) then
		auracolor.rgba = color
		auracolor.auraInstanceID = data.auraInstanceID
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
	if (self.FilterAura) then
		hooksecurefunc(self, 'FilterAura', StatusAura_Check)
	else
		self.FilterAura = StatusAura_Check
	end
	if (self.PostUpdate) then
		hooksecurefunc(self, 'PostUpdate', StatusAura_Colorize)
	else
		self.PostUpdate = StatusAura_Colorize
	end

	return auracolor
end

-- -----------------------------------
-- > ENHANCED AURA FRAME HELPERS
-- -----------------------------------

-- Button Creation Helper from oUF_Auras
local function UpdateTooltip(self)
	if(GameTooltip:IsForbidden()) then return end

	if(self.isHarmful) then
		GameTooltip:SetUnitDebuffByAuraInstanceID(self:GetParent().__owner.__owner.unit, self.auraInstanceID)
	else
		GameTooltip:SetUnitBuffByAuraInstanceID(self:GetParent().__owner.__owner.unit, self.auraInstanceID)
	end
end

local function onEnter(self)
	if(GameTooltip:IsForbidden() or not self:IsVisible()) then return end

	-- Avoid parenting GameTooltip to frames with anchoring restrictions,
	-- otherwise it'll inherit said restrictions which will cause issues with
	-- its further positioning, clamping, etc
	GameTooltip:SetOwner(self, self:GetParent().__owner.__restricted and 'ANCHOR_CURSOR' or self:GetParent().__owner.tooltipAnchor)
	self:UpdateTooltip()
end

local function onLeave()
	if(GameTooltip:IsForbidden()) then return end

	GameTooltip:Hide()
end

local function PostCreateButton2(element, button)
	button.Count:SetFont(font_num, 12, 'OUTLINE,MONOCHROME')
	button.Count:SetPoint('BOTTOMRIGHT', 1, 0)
	button.Count:SetJustifyH('RIGHT')
	button.Count:GetParent():SetFrameLevel(button.Cooldown:GetFrameLevel() - 1)
	button.Cooldown:SetHideCountdownNumbers(element.hideCooldownNumber)
	button.Cooldown:SetReverse(true)
	button.Overlay:SetTexture(m.textures.border_button)
	button.Overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.Icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
end

local function CreateButton(element, index)
	local button = CreateFrame('Button', element:GetDebugName() .. 'Button' .. index, element)

	local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
	cd:SetAllPoints()
	cd:SetHideCountdownNumbers(element.hideCooldownNumber)
	cd:SetReverse(true)
	button.Cooldown = cd

	local icon = button:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()
	icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
	button.Icon = icon

	local countFrame = CreateFrame('Frame', nil, button)
	countFrame:SetAllPoints(button)
	countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

	local count = countFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	--count:SetPoint('BOTTOMRIGHT', countFrame, 'BOTTOMRIGHT', -1, 0)
	--count:GetParent():SetFrameLevel(button.Cooldown:GetFrameLevel() - 1)
	count:SetPoint('BOTTOMRIGHT', 1, 0)
	count:SetFont(font_num, 12, 'OUTLINE,MONOCHROME')
	count:SetJustifyH('RIGHT')
	button.Count = count

	local overlay = button:CreateTexture(nil, 'OVERLAY')
	overlay:SetTexture(m.textures.border_button)
	overlay:SetAllPoints()
	overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.Overlay = overlay

	local stealable = button:CreateTexture(nil, 'OVERLAY')
	stealable:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
	stealable:SetPoint('TOPLEFT', -3, 3)
	stealable:SetPoint('BOTTOMRIGHT', 3, -3)
	stealable:SetBlendMode('ADD')
	button.Stealable = stealable

	button.UpdateTooltip = UpdateTooltip
	button:SetScript('OnEnter', onEnter)
	button:SetScript('OnLeave', onLeave)

	return button
end

-- Aura Update Function from oUF_Auras
local function updateAura(element, unit, data, position)
	if(not data.name) then return end

	local button = element[position]
	if(not button) then
		--[[ Override: Auras:CreateButton(position)
		Used to create an aura button at a given position.

		* self     - the widget holding the aura buttons
		* position - the position at which the aura button is to be created (number)

		## Returns

		* button - the button used to represent the aura (Button)
		--]]
		button = CreateButton(element, position)

		table.insert(element, button)
		element.createdButtons = element.createdButtons + 1
	end

	-- for tooltips
	button.auraInstanceID = data.auraInstanceID
	button.isHarmful = data.isHarmful

	if(button.Cooldown and not element.disableCooldown) then
		if(data.duration > 0) then
			button.Cooldown:SetCooldown(data.expirationTime - data.duration, data.duration, data.timeMod)
			button.Cooldown:Show()
		else
			button.Cooldown:Hide()
		end
	end

	if(button.Overlay) then
		if((data.isHarmful and element.showDebuffType) or (not data.isHarmful and element.showBuffType) or element.showType) then
			local color = element.__owner.__owner.colors.debuff[data.dispelName] or element.__owner.__owner.colors.debuff.none

			button.Overlay:SetVertexColor(color[1], color[2], color[3])
			button.Overlay:Show()
		else
			button.Overlay:Hide()
		end
	end

	if(button.Stealable) then
		if(not data.isHarmful and data.isStealable and element.showStealableBuffs and not UnitIsUnit('player', unit)) then
			button.Stealable:Show()
		else
			button.Stealable:Hide()
		end
	end

	if(button.Icon) then button.Icon:SetTexture(data.icon) end
	if(button.Count) then button.Count:SetText(data.applications > 1 and data.applications or '') end

	local width = element.width or element.size or 16
	local height = element.height or element.size or 16
	button:SetSize(width, height)
	button:EnableMouse(not element.disableMouse)
	button:Show()
end

-- -----------------------------------
-- > ENHANCED AURA FRAME
-- -----------------------------------

local function Auras_PostCreateButton(element, button)
	button.Count:SetFont(font_num, 12, 'OUTLINE,MONOCHROME')
	button.Count:SetPoint('BOTTOMRIGHT', 1, 0)
	button.Count:SetJustifyH('RIGHT')
	button.Count:GetParent():SetFrameLevel(button.Cooldown:GetFrameLevel() - 1)
	button.Cooldown:SetHideCountdownNumbers(true)
	button.Cooldown:SetReverse(true)
	button.Overlay:SetTexture(m.textures.border_button)
	button.Overlay:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.Icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
end

local function Auras_PostProcessData(element, unit, data)
	data.canDispel = auras:CanDispel(data.dispelName, unit)
	return data
end

function auras:CreateAuras(self, size, cols, rows, sep)
	local auras = CreateFrame('Frame', nil, self)
	auras:SetSize((size + sep) * cols, (size + sep) * rows) -- container size
	auras.num = math.floor(cols) * math.floor(rows)
	auras.size = size
	auras.spacing = sep
	auras.showType = true

	auras.PostProcessAuraData = Auras_PostProcessData
	auras.PostCreateButton = Auras_PostCreateButton

	return auras
end

local function Auras_PreUpdate(element, unit, fullupdate)
	if (not fullupdate) then return end

	local special = element.special
	if (special) then
		local comparator
		if (special.isDebuff) then
			comparator = AuraUtil.UnitFrameDebuffComparator
		else
			comparator = AuraUtil.DefaultAuraCompare
		end
		special.active = TableUtil.CreatePriorityTable(comparator, TableUtil.Constants.AssociativePriorityTable)
	end

	local dispel = element.dispel
	if (dispel) then
		dispel.active = TableUtil.CreatePriorityTable(AuraUtil.UnitFrameDebuffComparator, TableUtil.Constants.AssociativePriorityTable)
	end
end

local function Auras_PostUpdate(element, unit)

	local dispel = element.dispel
	if (dispel) then
		-- draw debuff icon for top prio dispellable debuff on unit
		local data = dispel.active:GetTop()
		if (data) then
			dispel.Icon:SetTexture([[Interface\RaidFrame\Raid-Icon-Debuff]]..data.dispelName)
			dispel.Icon:Show()
		else
			dispel.Icon:Hide()
		end
	end

	local special = element.special
	if (special) then
		-- draw x (currently only '1' supported) special auras in our
		-- separate special frame
		local data = special.active:GetTop()
		local count = 0
		if (data) then
			count = 1
			updateAura(special, unit, data, 1)
			special[1]:SetPoint('CENTER')

			-- restore the aura to active, since it may not be the
			-- top prio one during the next update
			element.active[data.auraInstanceID] = true
		end
		-- hide the rest
		for i = count + 1, #special do
			special[i]:Hide()
		end
	end
end

local function PostUpdateInfo(element, unit, updated)
	if not updated then return end

	local dispel = element.dispel
	if (dispel) then
		-- top prio dispellable debuff on unit
		local data = dispel.active:GetTop()
		if (data) then
			if (element.active[data.auraInstanceID]) then
				-- added/updated
				dispel.active[data.auraInstanceID] = element.all[data.auraInstanceID]
			else
				-- removed
				dispel.active[data.auraInstanceID] = nil
			end
		end
	end

	local special = element.special
	if (special) then
		-- top prio special aura
		local data = special.active:GetTop()
		if (data) then
			if (element.active[data.auraInstanceID]) then
				-- added/updated
				special.active[data.auraInstanceID] = element.all[data.auraInstanceID]
			else
				-- removed
				special.active[data.auraInstanceID] = nil
			end
		end
		-- top prio special aura after add/update/remove
		-- we will be updating it ourselves so remove it from active so
		-- we don't also have oUF draw it.
		data = special.active:GetTop()
		if (data) then
			element.active[data.auraInstanceID] = nil
		end
	end
end

local function CreateDispel(parent)
	local dispel = CreateFrame('Button', nil, parent)
	dispel.Icon = dispel:CreateTexture(nil, 'BORDER')
	dispel.Icon:SetAllPoints()
	dispel.__owner = parent
	dispel.num = 1
	dispel.createdButtons = 0

	return dispel
end

local function CreateSpecial(parent, hideCooldown)
	local special = CreateFrame('Frame', nil, parent)
	special.num = 1
	special.__owner = parent
	special.createdButtons = 0
	special.hideCooldownNumber = hideCooldown

	return special
end

function auras:CreateRaidAuras(self, size, cols, rows, sep, ...)
	local auras = auras:CreateAuras(self, size, cols, rows, sep)

	local specialSize, dispelIcon = ...
	if (specialSize and specialSize > 0) then
		auras.special = CreateSpecial(auras, specialSize < size)
		auras.special:SetSize(specialSize, specialSize)
		auras.special.size = specialSize
		auras.special.showDebuffType = true
	end
	if (dispelIcon) then
		auras.dispel = CreateDispel(auras)
		auras.dispel:SetSize(14, 14)
	end

	if (specialSize or dispelIcon) then
		auras.PreUpdate = Auras_PreUpdate
		auras.PostUpdateInfo = PostUpdateInfo
		auras.PostUpdate = Auras_PostUpdate
	end

	return auras
end
