--[[
# Element: RaidAuras

Handles creation and updating of raid aura icons.

## Widget

Buffs   - A Frame to hold `Button`s representing buffs.
Debuffs - A Frame to hold `Button`s representing debuffs.

## Notes

At least one of the above widgets must be present for the element to work.

## Options

.disableMouse       - Disables mouse events (boolean)
.disableCooldown    - Disables the cooldown spiral (boolean)
.size               - Aura icon size. Defaults to 16 (number)
.onlyShowPlayer     - Shows only auras created by player/vehicle (boolean)
.showStealableBuffs - Displays the stealable texture on buffs that can be stolen (boolean)
.spacing            - Spacing between each icon. Defaults to 0 (number)
.['spacing-x']      - Horizontal spacing between each icon. Takes priority over `spacing` (number)
.['spacing-y']      - Vertical spacing between each icon. Takes priority over `spacing` (number)
.['growth-x']       - Horizontal growth direction. Defaults to 'RIGHT' (string)
.['growth-y']       - Vertical growth direction. Defaults to 'UP' (string)
.initialAnchor      - Anchor point for the icons. Defaults to 'BOTTOMLEFT' (string)
.filter             - Custom filter list for auras to display. Defaults to 'HELPFUL' for buffs and 'HARMFUL' for
                      debuffs (string)

.num                - Number of auras to display. Defaults to 32 (number)
.numMax             - Number of auras to process. Defaults to .num (number)

## Attributes

button.caster   - the unit who cast the aura (string)
button.filter   - the filter list used to determine the visibility of the aura (string)
button.isDebuff - indicates if the button holds a debuff (boolean)
button.isPlayer - indicates if the aura caster is the player or their vehicle (boolean)

## Examples

    -- Position and size
    local debuffs = CreateFrame('Frame', nil, self)
    debuffs:SetPoint('RIGHT', self, 'LEFT')
    debuffs:SetSize(16 * 2, 16 * 16)

    -- optional dispelIcon showing if an aura can be dispelled (debuffs only)
    debuffs.dispelIcon = CreateFrame('Button', nil, debuffs)
    debuffs.dispelIcon:SetPoint('TOPRIGHT', self)
    debuffs.dispelIcon:SetSize(14, 14)

    -- Register with oUF
    self.RaidBuffs = debuffs
--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF RaidAuras was unable to locate oUF install')

local ipairs = ipairs
local math_floor =  math.floor
local table_sort = table.sort
local table_insert = table.insert
local Auras_IsPriorityDebuff = CompactUnitFrame_Util_IsPriorityDebuff   -- FrameXML/CompactUnitFrame.lua
local AuraUtil_ForEachAura = AuraUtil.ForEachAura

local PLAYER_CLASS = select(2, UnitClass('player'))

local function canDispel(type, unit)
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

local function UpdateTooltip(self)
	if(GameTooltip:IsForbidden()) then return end

	GameTooltip:SetUnitAura(self:GetParent().__owner.unit, self:GetID(), self.filter)
end

local function onEnter(self)
	if(GameTooltip:IsForbidden() or not self:IsVisible()) then return end

	-- Avoid parenting GameTooltip to frames with anchoring restrictions,
	-- otherwise it'll inherit said restrictions which will cause issues with
	-- its further positioning, clamping, etc
	GameTooltip:SetOwner(self, self:GetParent().__restricted and 'ANCHOR_CURSOR' or self:GetParent().tooltipAnchor)
	self:UpdateTooltip()
end

local function onLeave()
	if(GameTooltip:IsForbidden()) then return end

	GameTooltip:Hide()
end

local function createDispelIcon(element, dispelIcon)
	local icon = dispelIcon:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()
	return icon
end

local function createAuraIcon(element, index)
	local button = CreateFrame('Button', element:GetDebugName() .. 'Button' .. index, element)
	button:RegisterForClicks('RightButtonUp')

	local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
	cd:SetAllPoints()
	cd:SetReverse(true)
	cd:SetHideCountdownNumbers(true)

	local icon = button:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()

	local countFrame = CreateFrame('Frame', nil, button)
	countFrame:SetAllPoints(button)

	local count = countFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	count:SetPoint('BOTTOMRIGHT', countFrame, 'BOTTOMRIGHT', -1, 0)

	local overlay = button:CreateTexture(nil, 'OVERLAY')
	overlay:SetTexture([[Interface\Buttons\UI-Debuff-Overlays]])
	overlay:SetAllPoints()
	overlay:SetTexCoord(.296875, .5703125, 0, .515625)
	button.overlay = overlay

	local stealable = button:CreateTexture(nil, 'OVERLAY')
	stealable:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
	stealable:SetPoint('TOPLEFT', -3, 3)
	stealable:SetPoint('BOTTOMRIGHT', 3, -3)
	stealable:SetBlendMode('ADD')
	button.stealable = stealable

	button.UpdateTooltip = UpdateTooltip
	button:SetScript('OnEnter', onEnter)
	button:SetScript('OnLeave', onLeave)

	button.icon = icon
	button.count = count
	button.cd = cd

	--[[ Callback: Auras:PostCreateIcon(button)
	Called after a new aura button has been created.

	* self   - the widget holding the aura buttons
	* button - the newly created aura button (Button)
	--]]
	if (element.PostCreateIcon) then element:PostCreateIcon(button) end

	return button
end

local function customFilter(element, unit, button, dispellable, ...)
	local  _, _, _, _, _, _, _, _, _, spellId, _, isBossAura = ...

	if (element.onlyShowPlayer) then
		return button.isPlayer and 1
	end

	-- filter and sort boss first, then prio debuff, then other auras
	if (isBossAura) then
		return 1
	end
	if (Auras_IsPriorityDebuff(spellId)) then
		return 2
	end
	-- other auras
	return 3
end

local function SetGroupPosition(element, group, num, cur, max, offx, offy)
	local sizex = (element.size or 16) + (element['spacing-x'] or element.spacing or 0)
	local sizey = (element.size or 16) + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthx = (element['growth-x'] == 'LEFT' and -1) or 1
	local growthy = (element['growth-y'] == 'DOWN' and -1) or 1
	local cols = math_floor(element:GetWidth() / sizex + 0.5)

	for i = 1, #group do
		local button = group[i]

		-- Bail out if the to range is out of scope.
		if (not button or (cur >= max)) then break end

		local col = cur % cols
		local row = math_floor(cur / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
		button:Show()
		cur = cur + 1
	end
	return cur
end

local function ShouldUpdate(element, unit, isFullUpdate, updatedAuras)
	if (isFullUpdate ~= false or not updatedAuras) then
		return true
	end
	if (element.filter == 'NONE' or not element.ShouldUpdate) then
		return true
	end
	
	for _, auraInfo in ipairs(updatedAuras) do
		if (not auraInfo.shouldNeverShow) then
			--[[ Callback: Auras:ShouldUpdate(unit, auraInfo)
			Called to check whether an aura is to be updated

			* self     - the widget holding the aura buttons
			* unit     - the unit on which the aura is cast (string)
			* auraInfo - the informations about the current aura (table)

			## Returns

			* boolean - indicates whether this aura should be updated
			--]]
			if (element:ShouldUpdate(unit, auraInfo)) then
				return true
			end
		end
	end
	return false
end

local function filterIcons(element, unit, filter, numAuras, isDebuff)
	local index = 1
	local usedAuras = 0
	local groups = { used = {} }
	local dispelType

	AuraUtil_ForEachAura(unit, filter, numAuras, function(...)
		local _, texture, count, debuffType, duration, expiration, caster, isStealable = ...
		local position = index
		local button = element[position]
		if (not button) then
			--[[ Override: Auras:CreateIcon(position)
			Used to create the aura button at a given position.

			* self     - the widget holding the aura buttons
			* position - the position at which the aura button is to be created (number)

			## Returns

			* button - the button used to represent the aura (Button)
			--]]
			button = (element.CreateIcon or createAuraIcon) (element, position)

			table_insert(element, button)
			element.createdIcons = element.createdIcons + 1
		end

		button.caster = caster
		button.filter = filter
		button.isDebuff = isDebuff
		button.isPlayer = caster == 'player' or caster == 'vehicle'
		button:Hide()
		button:ClearAllPoints()

		local isDispellable = isDebuff and canDispel(debuffType, unit)
		if (isDispellable and not dispelType) then
			dispelType = debuffType
		end

		--[[ Override: Auras:CustomFilter(unit, button, ...)
		Defines a custom filter that controls if the aura button should be shown.

		* self          - the widget holding the aura buttons
		* unit          - the unit on which the aura is cast (string)
		* button        - the button displaying the aura (Button)
		* isDispellable - whether the aura is dispellable by the player (boolean)
		* ...           - the return values from [UnitAura](http://wowprogramming.com/docs/api/UnitAura.html)

		## Returns

		* prio  - in which group to place the button, use nil for none (number)
		--]]
		local prio = (element.CustomFilter or customFilter) (element, unit, button, isDispellable, ...)
		if (not prio) then
			index = index + 1
			return usedAuras >= numAuras
		end

		-- We might want to consider delaying the creation of an actual cooldown
		-- object to this point, but I think that will just make things needlessly
		-- complicated.
		if (button.cd and not element.disableCooldown) then
			if (duration and duration > 0) then
				button.cd:SetCooldown(expiration - duration, duration)
				button.cd:Show()
			else
				button.cd:Hide()
			end
		end

		if (button.overlay) then
			if ((isDebuff and element.showDebuffType) or (not isDebuff and element.showBuffType) or element.showType) then
				local color = element.__owner.colors.debuff[debuffType] or element.__owner.colors.debuff.none

				button.overlay:SetVertexColor(color[1], color[2], color[3])
				button.overlay:Show()
			else
				button.overlay:Hide()
			end
		end

		if (button.stealable) then
			if (not isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit('player', unit)) then
				button.stealable:Show()
			else
				button.stealable:Hide()
			end
		end

		if (button.icon) then button.icon:SetTexture(texture) end
		if (button.count) then button.count:SetText(count > 1 and count) end

		local size = element.size or 16
		button:SetSize(size, size)
		button:EnableMouse(not element.disableMouse)
		button:SetID(index)

		-- We place the updated button into it's appropriated group here
		if (not groups[prio]) then
			groups[prio] = {}
			if type(prio) == 'number' then
				table_insert(groups.used, prio)
			end
		end
		table_insert(groups[prio], button)

		--[[ Callback: Auras:PostUpdateIcon(unit, button, index, position)
		Called after the aura button has been updated.

		* self        - the widget holding the aura buttons
		* unit        - the unit on which the aura is cast (string)
		* button      - the updated aura button (Button)
		* index       - the index of the aura (number)
		* position    - the actual position of the aura button (number)
		* prio        - the priority given to this aura (number)
		* duration    - the aura duration in seconds (number?)
		* expiration  - the point in time when the aura will expire. Comparable to GetTime() (number)
		* debuffType  - the debuff type of the aura (string?)['Curse', 'Disease', 'Magic', 'Poison']
		* isStealable - whether the aura can be stolen or purged (boolean)
		--]]
		if (element.PostUpdateIcon) then
			element:PostUpdateIcon(unit, button, index, position, prio, duration, expiration, debuffType, isStealable)
		end

		index = index + 1
		usedAuras = usedAuras + 1

		-- true to stops iterating over auras
		return usedAuras >= numAuras
	end)

	-- hide out of scope icons
	for i=index or 1, #element do
		element[i]:Hide()
		element[i]:ClearAllPoints()
	end

	table_sort(groups.used, function(a, b) return a > b end)
	return groups, dispelType
end

local function UpdateAuras(self, event, unit, ...)
	if (self.unit ~= unit) then return end

	local buffs = self.RaidBuffs
	if (buffs and ShouldUpdate(buffs, unit, ...)) then
		if (buffs.PreUpdate) then buffs:PreUpdate(unit) end

		local numBuffs = buffs.numMax
		local groups = filterIcons(buffs, unit, buffs.filter or 'HELPFUL', numBuffs)

		if (buffs.PreSetPosition) then buffs:PreSetPosition(groups) end

		local offx, offy = 0, 0, 0
		local cur, max = 0, buffs.num or numBuffs
		for _, i in ipairs(groups.used) do
			if (cur >= max) then break end
			cur, offx, offy = (buffs.SetGroupPosition or SetGroupPosition) (buffs, groups[i], i, cur, max, offx, offy)
		end

		if (buffs.PostUpdate) then buffs:PostUpdate(unit, groups) end
	end

	local debuffs = self.RaidDebuffs
	if (debuffs and ShouldUpdate(debuffs, unit, ...)) then
		if (debuffs.PreUpdate) then debuffs:PreUpdate(unit) end

		local numDebuffs = debuffs.numMax
		local groups, dispelType = filterIcons(debuffs, unit, debuffs.filter or 'HARMFUL', numDebuffs, true)

		if (debuffs.PreSetPosition) then debuffs:PreSetPosition(groups) end

		local offx, offy = 0, 0, 0
		local cur, max = 0, debuffs.num or numDebuffs
		for _, i in ipairs(groups.used) do
			if (cur >= max) then break end
			cur, offx, offy = (debuffs.SetGroupPosition or SetGroupPosition) (debuffs, groups[i], i, cur, max, offx, offy)
		end

		if (debuffs.PostUpdate) then debuffs:PostUpdate(unit, groups) end

		if (debuffs.dispelIcon) then
			if (dispelType) then
				debuffs.dispelIcon:Show()
				debuffs.dispelIcon.icon:SetTexture([[Interface\RaidFrame\Raid-Icon-Debuff]]..dispelType)
			else
				debuffs.dispelIcon:Hide()
			end
		end
	end
end

local function Update(self, event, unit, ...)
	if (self.unit ~= unit) then return end

	UpdateAuras(self, event, unit, ...)
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit, true)
end

local function Enable(self)
	if (self.RaidBuffs or self.RaidDebuffs) then
		self:RegisterEvent('UNIT_AURA', UpdateAuras)

		local buffs = self.RaidBuffs
		if (buffs) then
			buffs.__owner = self
			-- check if there's any anchoring restrictions
			buffs.__restricted = not pcall(self.GetCenter, self)
			buffs.ForceUpdate = ForceUpdate

			buffs.createdIcons = buffs.createdIcons or 0
			buffs.anchoredIcons = 0
			buffs.tooltipAnchor = buffs.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			buffs.num = buffs.num or 32
			buffs.numMax = buffs.numMax or buffs.num

			buffs:Show()
		end

		local debuffs = self.RaidDebuffs
		if (debuffs) then
			debuffs.__owner = self
			-- check if there's any anchoring restrictions
			debuffs.__restricted = not pcall(self.GetCenter, self)
			debuffs.ForceUpdate = ForceUpdate

			debuffs.createdIcons = debuffs.createdIcons or 0
			debuffs.anchoredIcons = 0
			debuffs.tooltipAnchor = debuffs.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			debuffs.num = debuffs.num or 32
			debuffs.numMax = debuffs.numMax or debuffs.num

			if (debuffs.dispelIcon) then
				local dispelIcon = debuffs.dispelIcon
				dispelIcon.icon = createDispelIcon(debuffs, dispelIcon)
			end

			debuffs:Show()
		end

		return true
	end
end

local function Disable(self)
	if (self.RaidBuffs or self.RaidDebuffs) then
		self:UnregisterEvent('UNIT_AURA', UpdateAuras)

		if (self.RaidBuffs) then self.RaidBuffs:Hide() end
		if (self.RaidDebuffs) then self.RaidDebuffs:Hide() end
	end
end

oUF:AddElement('RaidAuras', Update, Enable, Disable)
