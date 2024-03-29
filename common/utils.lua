local _, ns = ...

local util, m, oUF = {}, ns.m, ns.oUF
ns.util = util

-- Import API functions
local floor = floor
local table_insert = table.insert

-- ------------------------------------------------------------------------
-- > UTILITY FUNCTIONS
-- ------------------------------------------------------------------------

-- Convert color to HEX
function util:ToHex(r, g, b)
	if (not r) then
		return
	end
	if (type(r) == 'table') then
		if (r.r) then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end
	return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

-- Shortens Numbers
function util:ShortNumber(v)
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

function util:NumberToPerc(num, den)
	return floor(num / den * 100 + 0.5)
end

function util:TableConcat(...)
	local res = {}
	for _,tbl in ipairs({...}) do
		for _,val in ipairs(tbl) do
			table_insert(res, val)
		end
	end
	return res
end

function util:TableMerge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			self:TableMerge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
end
