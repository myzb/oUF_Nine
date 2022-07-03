local addonName, ns = ...

local config = ns.config
local misc, events = CreateFrame('Frame'), {}

-- ------------------------------------------------------------------------
-- > OTHER MISCELLANEOUS ADJUSTMENTS
-- ------------------------------------------------------------------------

-- Hide Blizzard's Compact Raid Frames
if (config.misc.raidframes and config.misc.raidframes.hide) then
	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameContainer:Hide()
end

-- Hide Blizzard's Talking Head Frame
if (config.misc.talkinghead and config.misc.talkinghead.hide) then
	function events:TALKINGHEAD_REQUESTED(...)
		TalkingHeadFrame:Hide()
	end
end

-- Mover for the Default Game Tooltip
if (config.misc.gametooltip and config.misc.gametooltip.move) then
	local function GameTooltip_Move (self)
		local pos = config.misc.gametooltip.pos

		self:ClearAllPoints(true)
		self:SetPoint(pos.a1, pos.af, pos.a2, pos.x, pos.y)
	end
	hooksecurefunc('GameTooltip_SetDefaultAnchor', GameTooltip_Move)
end

-- Register oUF_Nine Raid Frame with OmniCD
function events:ADDON_LOADED(name)
	if name == addonName or name == 'OmniCD' then
		local func = OmniCD and OmniCD.AddUnitFrameData
		if func then
			func(addonName, addonName..'Raid1UnitButton', 'unit', 1)
		end
	end
end

-- Setup Event Handle
do
	for k, _ in pairs(events) do
		misc:RegisterEvent(k)
	end
	misc:SetScript('OnEvent', function(element, event, ...)
		events[event](element, ...)
	end)
end
