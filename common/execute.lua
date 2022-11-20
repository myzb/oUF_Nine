local _, ns = ...

local common, oUF = ns.common, ns.oUF

-- ------------------------------------------------------------------------
-- > EXECUTE PERCENTAGES BY CLASS AND SPEC
-- ------------------------------------------------------------------------

local PLAYER_CLASS = select(2, UnitClass('player'))

local execute = {
	DEATHKNIGHT = { 0, 0, 0 },
	DEMONHUNTER = { 0, 0, 0 },
	DRUID = { 0, 0, 0, 0 },
	HUNTER = { 0, 0, 0 },
	MAGE = { 0, 30, 0 },
	MONK = { 0, 0, 0 },
	PALADIN = { 0, 0, 0 },
	PRIEST = { 0, 0, 0 },
	ROGUE  = { 0, 0, 0 },
	SHAMAN = { 0, 0, 0 },
	WARLOCK = { 0, 0, 0 },
	WARRIOR = { 0, 0, 20 },
}

function common:GetExecutePerc()
	local spec = GetSpecialization()
	return execute[PLAYER_CLASS][spec]
end
