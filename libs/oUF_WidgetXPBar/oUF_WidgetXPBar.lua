local _, ns = ...
local oUF = ns.oUF or oUF

assert(oUF, 'oUF WidgetXPBar was unable to locate oUF install')

local UnitPlayerControlled = UnitPlayerControlled
local UnitIsOwnerOrControllerOfUnit = UnitIsOwnerOrControllerOfUnit
local C_UIWidgetManager_GetStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo
local string_match = string.match

local WIDGET_INFO_RANK_MAX = 30

local widgetMap = {
	[149805] = 1940, -- Farseer Ori
	[149804] = 1613, -- Hunter Akana
	[149803] = 1966, -- Bladesman Inowari
	[149904] = 1621, -- Neri Sharpfin
	[149902] = 1622, -- Poen Gillbrack
	[149906] = 1920, -- Vim Brineheart

	[154304] = 1940, -- Farseer Ori
	[150202] = 1613, -- Hunter Akana
	[154297] = 1966, -- Bladesman Inowari
	[151300] = 1621, -- Neri Sharpfin
	[151310] = 1622, -- Poen Gillbrack
	[151309] = 1920, -- Vim Brineheart

	[163541] = 2342, -- Voidtouched Egg
	[163592] = 2342, -- Yu'gaz
	[163593] = 2342, -- Bitey McStabface
	[163595] = 2342, -- Reginald
	[163596] = 2342, -- Picco
	[163648] = 2342, -- Bitey McStabface
	[163651] = 2342, -- Yu'gaz
}

local function GetWidgetInfoBase(widgetID)
	local widget = widgetID and C_UIWidgetManager_GetStatusBarWidgetVisualizationInfo(widgetID)
	if not widget then return end

	local cur = widget.barValue - widget.barMin
	local toNext = widget.barMax - widget.barMin
	local total = widget.barValue

	local rank, maxRank
	if widget.overrideBarText then
		rank = tonumber(string_match(widget.overrideBarText, "%d+"))
		maxRank = rank == WIDGET_INFO_RANK_MAX
	end

	return cur, toNext, total, rank, maxRank
end

local function Hide(element)
	if element.Rank then element.Rank:Hide() end
	if element.ProgressText then element.ProgressText:Hide() end
	element:Hide()
end

local function Update(self)
	local npShown = self:IsShown()
	local element = npShown and self.WidgetXPBar
	if not element then return end

	local unit = self.unit
	if unit and UnitPlayerControlled(unit) and not UnitIsOwnerOrControllerOfUnit('player', unit) then Hide(element) return end

	if element.PreUpdate then
		element:PreUpdate()
	end

	local unitGUID = UnitGUID(unit)
	local npcID = tonumber(unitGUID and select(6, strsplit('-', unitGUID)))
	local widgetID = widgetMap[npcID]

	local cur, toNext, total, rank, maxRank = GetWidgetInfoBase(widgetID)
	if not cur then Hide(element) return end

	element:SetMinMaxValues(0, maxRank and 1 or toNext)
	element:SetValue(maxRank and 1 or cur)
	element:Show()

	if rank and element.Rank then
		element.Rank:SetText(rank)
		element.Rank:Show()
	end

	if element.ProgressText then
		element.ProgressText:SetFormattedText(maxRank and "" or "%d / %d", cur, toNext)
		element.ProgressText:Show()
	end

	if element.PostUpdate then
		element:PostUpdate(cur, toNext, total, rank, maxRank)
	end
end

local function Path(self, ...)
	return (self.WidgetXPBar.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.WidgetXPBar
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UPDATE_UI_WIDGET", Path, true)
		self:RegisterEvent("QUEST_LOG_UPDATE", Path, true)
		return true
	end
end

local function Disable(self)
	local element = self.WidgetXPBar
	if element then
		Hide(element)

		self:UnregisterEvent("UPDATE_UI_WIDGET", Path)
		self:UnregisterEvent("QUEST_LOG_UPDATE", Path)
	end
end

oUF:AddElement("WidgetXPBar", Path, Enable, Disable)
