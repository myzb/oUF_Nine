local _, ns = ...

local core, m, oUF = ns.core, ns.m, ns.oUF

-- Import API functions
local floor, mod = floor, mod
local ipairs = ipairs
local table_insert = table.insert

-- ------------------------------------------------------------------------
-- > CORE FUNCTIONS
-- ------------------------------------------------------------------------

-- -----------------------------------
-- > UTILITY FUNCTIONS
-- -----------------------------------

-- Convert color to HEX
function core:ToHex(r, g, b)
	if (r) then
		if (type(r) == 'table') then
			if (r.r) then
				r, g, b = r.r, r.g, r.b
			else
				r, g, b = unpack(r)
			end
		end
		return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
	end
end

-- Shortens Numbers
function core:ShortNumber(v)
	if (v > 1E10) then
		return (floor(v/1E9))..'|cffbbbbbbb|r'
	elseif (v > 1E9) then
		return (floor((v/1E9)*10)/10)..'|cffbbbbbbb|r'
	elseif (v > 1E7) then
		return (floor(v/1E6))..'|cffbbbbbbm|r'
	elseif (v > 1E6) then
		return (floor((v/1E6)*10)/10)..'|cffbbbbbbm|r'
	elseif (v > 1E4) then
		return (floor(v/1E3))..'|cffbbbbbbk|r'
	elseif (v > 1E3) then
		return (floor((v/1E3)*10)/10)..'|cffbbbbbbk|r'
	else
		return v
	end
end

function core:NumberToPerc(v1, v2)
	return floor(v1 / v2 * 100 + 0.5)
end

function core:FormatTime(s)
	local day, hour, minute = 86400, 3600, 60

	if (s >= day) then
		return format('%dd', floor(s/day + 0.5))
	elseif (s >= hour) then
		return format('%dh', floor(s/hour + 0.5))
	elseif (s >= minute) then
		return format('%dm', floor(s/minute + 0.5))
	end
	return format('%d', mod(s, minute))
end

function core:table_merge(...)
	local res = {}
	for _,tbl in ipairs({...}) do
		for _,val in ipairs(tbl) do
			table_insert(res, val)
		end
	end
	return res
end
