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
	return (UnitPlayerControlled(unit) and UnitCreatureFamily(unit)) or UnitName(rolf or unit)
end
events['n:name'] = 'UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_ENTERING_VEHICLE UNIT_EXITING_VEHICLE'

-- Name abbreviated
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
	local name = (UnitPlayerControlled(unit) and UnitCreatureFamily(unit)) or UnitName(rolf or unit)
	return string.len(name) > 10 and abbrevCache[name] or name
end
events['n:abbrev_name'] = 'UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_ENTERING_VEHICLE UNIT_EXITING_VEHICLE'

-- Unit difficulty color
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
	local min, max = UnitPower(unit, UnitPowerType(unit)), UnitPowerMax(unit, UnitPowerType(unit))
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
	local min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)

	-- hide if the units main power type is already mana (0) or power is full
	if (UnitPowerType(unit) ~= 0 and min ~= max) then
		return util:ShortNumber(min)
	end
end
events['n:addpower'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE'

-- Stagger Value
tags['n:stagger'] = function(unit)
	local min, max = UnitStagger(unit), UnitHealthMax(unit)
	return util:ShortNumber(min)
end

events['n:stagger'] = 'UNIT_AURA UNIT_DISPLAYPOWER PLAYER_TALENT_UPDATE'

-- Unit Color
tags['n:unitcolor'] = function(unit)
	local _, class = UnitClass(unit)
	local isPlayer, isPet = UnitIsPlayer(unit), UnitPlayerControlled(unit)
	local color = ''

	if (isPlayer) then
		if (class) then
			color = util:ToHex(oUF.colors.class[class])
		else
			local id = unit:match('arena(%d)$')
			if (id) then
				local specID = GetArenaOpponentSpec(tonumber(id))
				if (specID and specID > 0) then
					_, _, _, _, _, class = GetSpecializationInfoByID(specID)
					color = util:ToHex(oUF.colors.class[class])
				end
			end
		end
	else
		color = '|cffbbbbbb'
	end
	return color
end

-- Reaction Color
tags['n:reactioncolor'] = function(unit)
	local isPlayerControlled = UnitPlayerControlled(unit)
	local reaction = UnitReaction(unit, 'player')

	if (isPlayerControlled) then
		return ''
	end
	local color = ''
	if (UnitIsTapDenied(unit)) then
		color = util:ToHex(oUF.colors.tapped)
	elseif (reaction and reaction > 4) then
		-- only friendlies
		color = util:ToHex(oUF.colors.reaction[reaction])
	end
	return color
end
