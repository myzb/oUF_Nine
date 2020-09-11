local _, ns = ...

local core, oUF = ns.core, ns.oUF

-- ------------------------------------------------------------------------
-- > Custom Tags
-- ------------------------------------------------------------------------

local tags = oUF.Tags.Methods or oUF.Tags
local events = oUF.TagEvents or oUF.Tags.Events

local floor = floor

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
tags['n:hpvalue'] = function(unit)
	local min = UnitHealth(unit)
	if (min == 0 or not UnitIsConnected(unit) or UnitIsGhost(unit) or UnitIsDead(unit)) then
		return ''
	end
	return core:shortNumber(min)
end
events['n:hpvalue'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION UNIT_NAME_UPDATE'

-- Health Percent
tags['n:perhp'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if (min and max) then
		return floor((min / max) * 100 + 0.5)..'%'
	else
		return ''
	end
end
events['n:perhp'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE'

-- Health Percent with Status
tags['n:perhp_status'] = function(unit)
	if (UnitIsDead(unit)) then
		return 'Dead'
	elseif (UnitIsGhost(unit)) then
		return 'Ghost'
	elseif (not UnitIsConnected(unit)) then
		return 'Offline'
	else
		-- Get perhp
		local m = UnitHealthMax(unit)
		if (m == 0) then
			return 0
		else
			return math.floor(UnitHealth(unit) / m * 100 + 0.5)..'%'
		end
	end
end
events['n:perhp_status'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED'

-- Player Status
tags['n:status'] = function(unit)
	if (UnitIsDead(unit)) then
		return 'Dead'
	elseif (UnitIsGhost(unit)) then
		return 'Ghost'
	elseif (not UnitIsConnected(unit)) then
		return 'Offline'
	else
		return ''
	end
end
events['n:status'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED'

-- Power value
tags['n:powervalue'] = function(unit)
	-- Hide it if DC, Ghost or Dead!
	local min, max = UnitPower(unit, UnitPowerType(unit)), UnitPowerMax(unit, UnitPowerType(unit))
	if (min == 0 or not UnitIsConnected(unit) or UnitIsGhost(unit) or UnitIsDead(unit)) then
		return ''
	end

	local _, ptype = UnitPowerType(unit)
	if (ptype == 'MANA') then
		return core:shortNumber(min)
	elseif (ptype == 'RAGE' or ptype == 'RUNIC_POWER' or ptype == 'LUNAR_POWER') then
		return floor(min / 10)  -- don't round up!
	elseif (ptype == 'INSANITY') then
		return floor(min / 100) -- don't round up!
	else
		return core:shortNumber(min)
	end
end
events['n:powervalue'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE UNIT_CONNECTION PLAYER_DEAD PLAYER_ALIVE'

-- Additional Power Percent
tags['n:addpower'] = function(unit)
	local min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)

	if (UnitPowerType(unit) ~= 0 and min ~= max) then -- If Power Type is not Mana(it's Energy or Rage) and Mana is not at Maximum
		return core:shortNumber(min)
	end
end
events['n:addpower'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE'

-- Unit color
tags['n:unitcolor'] = function(unit)
	local _, class = UnitClass(unit)
	local isPlayer, isPet = UnitIsPlayer(unit), UnitPlayerControlled(unit)
	local color = ''

	if (isPlayer) then
		if (class) then
			color = core:toHex(oUF.colors.class[class])
		else
			local id = unit:match('arena(%d)$')
			if (id) then
				local specID = GetArenaOpponentSpec(tonumber(id))
				if (specID and specID > 0) then
					_, _, _, _, _, class = GetSpecializationInfoByID(specID)
					color = core:toHex(oUF.colors.class[class])
				end
			end
		end
	else
		color = '|cffbbbbbb'
	end
	return color
end

-- Status color
tags['n:reactioncolor'] = function(unit)
	local isPlayerControlled = UnitPlayerControlled(unit)
	local reaction = UnitReaction(unit, 'player')

	if (isPlayerControlled) then
		return ''
	end
	local color = ''
	if (UnitIsTapDenied(unit)) then
		color = core:toHex(oUF.colors.tapped)
	elseif (reaction and reaction > 4) then
		-- only friendlies
		color = core:toHex(oUF.colors.reaction[reaction])
	end
	return color
end
