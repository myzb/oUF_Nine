local _, ns = ...

local config = ns.config

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
