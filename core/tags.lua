local _, ns = ...

local core, util, oUF = ns.core, ns.util, ns.oUF
local tags, events = oUF.Tags.Methods, oUF.Tags.Events

-- Import API Functions
local floor = floor

-- ------------------------------------------------------------------------
-- > CUSTOM TAGS
-- ------------------------------------------------------------------------

-- Name (creature family for player owned units if possible)
tags['n:name'] = function(unit, rolf)
	return (UnitPlayerControlled(unit) and UnitCreatureFamily(unit)) or tags['name'](unit, rolf)
end
events['n:name'] = 'UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_ENTERING_VEHICLE UNIT_EXITING_VEHICLE'

-- Name Abbreviated
local function abbreviateName(text)
	return string.sub(text, 1, 1) .. '.'
end

local abbrevCache = setmetatable({}, {
	__index = function(tbl, val)
		val = string.gsub(val, '([^%s]+) ', abbreviateName)
		rawset(tbl, val, val)
		return val
	end})

tags['n:abbrev_name'] = function(unit, rolf)
	local name = tags['n:name'](unit, rolf)
	return (string.len(name) > 10) and abbrevCache[name] or name
end
events['n:abbrev_name'] = 'UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_ENTERING_VEHICLE UNIT_EXITING_VEHICLE'

-- Unit Difficulty Color
tags['n:difficultycolor'] = function(unit)
	local c = UnitClassification(unit)
	if (c == 'rare' or c == 'rareelite') then
		return '|cff008ff7'
	elseif (c == 'elite' or c == 'worldboss') then
		return '|cffffe453'
	end
end

-- Health Value
tags['n:curhp'] = function(unit)
	local min = UnitHealth(unit)
	if (min == 0 or not UnitIsConnected(unit) or UnitIsGhost(unit) or UnitIsDead(unit)) then
		return
	end
	return util:ShortNumber(min)
end
events['n:curhp'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION UNIT_NAME_UPDATE'

-- Player Status
tags['n:status'] = function(unit)
	if (UnitIsDead(unit)) then
		return 'Dead'
	elseif (UnitIsGhost(unit)) then
		return 'Ghost'
	elseif (not UnitIsConnected(unit)) then
		return 'Offline'
	end
end
events['n:status'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED'

-- Health Percent with Status
tags['n:perhp_status'] = function(unit)
	return tags['n:status'](unit) or tags['perhp'](unit)..'%'
end
events['n:perhp_status'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED'

-- Power Value
tags['n:curpp'] = function(unit)
	-- Hide it if DC, Ghost or Dead!
	local min = UnitPower(unit, UnitPowerType(unit))
	if (min == 0 or not UnitIsConnected(unit) or UnitIsGhost(unit) or UnitIsDead(unit)) then
		return
	end

	local _, ptype = UnitPowerType(unit)
	if (ptype == 'MANA') then
		return util:ShortNumber(min)
	elseif (ptype == 'RAGE' or ptype == 'RUNIC_POWER' or ptype == 'LUNAR_POWER') then
		return floor(min / 10)  -- don't round up!
	elseif (ptype == 'INSANITY') then
		return floor(min / 100) -- don't round up!
	else
		return util:ShortNumber(min)
	end
end
events['n:curpp'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE UNIT_CONNECTION PLAYER_DEAD PLAYER_ALIVE'

-- Additional Power
tags['n:addpower'] = function(unit)
	local cur = UnitPower(unit, ADDITIONAL_POWER_BAR_INDEX)
	local max = UnitPowerMax(unit, ADDITIONAL_POWER_BAR_INDEX)

	-- same as AlternatePowerBar_ShouldDisplayPower()
	local shouldDisplay
	if (not UnitHasVehicleUI('player') and max ~= 0) then
		local _, class = UnitClass(unit)
		if (ALT_MANA_BAR_PAIR_DISPLAY_INFO[class]) then
			local powerType = UnitPowerType(unit)
			shouldDisplay = ALT_MANA_BAR_PAIR_DISPLAY_INFO[class][powerType]
		end
	end

	-- Show bar if not full for supported classes only
	if (shouldDisplay and cur ~= max) then
		return util:ShortNumber(cur)
	end
end
events['n:addpower'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE'

-- Stagger Value
tags['n:stagger'] = function(unit)
	return util:ShortNumber(UnitStagger(unit))
end

events['n:stagger'] = 'UNIT_AURA UNIT_DISPLAYPOWER PLAYER_TALENT_UPDATE'

-- Unit Color
tags['n:unitcolor'] = function(unit)
	if (UnitIsPlayer(unit)) then
		return tags['raidcolor'](unit)
	else
		return '|cffbbbbbb'
	end
end

-- Reaction Color
tags['n:reactioncolor'] = function(unit)
	if (UnitPlayerControlled(unit)) then
		return
	end
	local reaction = UnitReaction(unit, 'player')
	if (UnitIsTapDenied(unit)) then
		return util:ToHex(oUF.colors.tapped)
	elseif (reaction and reaction > 4) then
		-- only friendlies
		return util:ToHex(oUF.colors.reaction[reaction])
	end
end

-- Raid Group Number
tags['n:raidgroup'] = function(unit)
	return IsInRaid() and tags['group'](unit)
end
events['n:raidgroup'] = 'GROUP_ROSTER_UPDATE'
