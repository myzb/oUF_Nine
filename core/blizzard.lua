local addonName, ns = ...

local config = ns.config
local extras, events = CreateFrame('Frame'), {}

-- ------------------------------------------------------------------------
-- > BLIZZARD UI ADJUSTMENTS
-- ------------------------------------------------------------------------

-- Hide Blizzard's Compact Raid Frames
if (config.blizzard.raidframes and config.blizzard.raidframes.hide) then
	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameContainer:Hide()
end

-- Hide Blizzard's Talking Head Frame
if (config.blizzard.talkinghead and config.blizzard.talkinghead.hide) then
	local TalkingFrame = CreateFrame('Frame')
	TalkingFrame:RegisterEvent('TALKINGHEAD_REQUESTED');

	local function TalkingHead_Hide(self, event, ...)
		if (event == 'TALKINGHEAD_REQUESTED') then
			TalkingHeadFrame:Hide()
		end
	end
	TalkingFrame:SetScript('OnEvent', TalkingHead_Hide)
end

-- Mover for the Default Game Tooltip
if (config.blizzard.gametooltip and config.blizzard.gametooltip.move) then
	local function GameTooltip_Move (self)
		local pos = config.blizzard.gametooltip.pos

		self:ClearAllPoints(true)
		self:SetPoint(pos.a1, pos.af, pos.a2, pos.x, pos.y)
	end
	hooksecurefunc('GameTooltip_SetDefaultAnchor', GameTooltip_Move)
end

-- OmniCD registration
function events:ADDON_LOADED(name)
	if name == addonName or name == 'OmniCD' then
		local func = OmniCD and OmniCD.AddUnitFrameData
		if func then
			func(addonName, addonName..'Raid1UnitButton', 'unit', 1)
		end
	end
end

-- event registration
do
	for k, _ in pairs(events) do
		extras:RegisterEvent(k)
	end
	extras:SetScript('OnEvent', function(element, event, ...)
		events[event](element, ...)
	end)
end
