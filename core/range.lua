local _, ns = ...

local common, config, m, oUF = ns.common, ns.config, ns.m, ns.oUF

local PLAYER_CLASS = select(2, UnitClass('player'))
local UnitCanAttack, IsSpellInRange, GetSpecialization = UnitCanAttack, IsSpellInRange, GetSpecialization

-- ------------------------------------------------------------------------
-- > RANGE CHECK
-- ------------------------------------------------------------------------

local spellRange = {
	PRIEST = {
		harm = { 'Shadow Word: Pain' }, -- 40 yards
		help = { 'Flash Heal' } -- 40 yards
	},
	DRUID = {
		harm = { 'Moonfire' }, -- 40 yards
		help = { 'Regrowth' } -- 40 yards
	},
	PALADIN = {
		harm = { 'Judgement' }, -- 40 yards
		help = { 'Flash of Light' } -- 40 yards
	},
	SHAMAN = {
		harm = { 'Lightning Bolt' },-- 40 yards
		help = { 'Healing Surge' } -- 40 yards
	},
	WARLOCK = {
		harm = { 'Shadow Bolt' }, -- 40 yards
		help = { '' }
	},
	MAGE = {
		harm = { 'Counterspell' }, -- 40 yards
		help = { 'Remove Curse' } -- 40 yards
	},
	HUNTER = {
		harm = { 'Arcane Shot' }, -- 40 yards
		help = { '' }
	},
	DEATHKNIGHT = {
		harm = { 'Death Grip' }, -- 30 yards
		help = { '' },
	},
	ROGUE = {
		-- Assassination, Outlaw, Subtlety
		harm = { 'Poisoned Knife', 'Pistol Shot', 'Shuriken Toss' }, -- 30, 20, 30 yards
		help = { '' },
	},
	WARRIOR = {
		harm = { 'Charge' }, -- 25 yards
		help = { 'Intervene' }, -- 25 yards
	},
	MONK = {
		harm = { 'Crackling Jade Lightning' }, -- 40 yards
		help = { 'Vivify' } -- 40 yards
	},
	DEMONHUNTER = {
		harm = { 'Throw Glaive' }, -- 30 yards
		help = { '' },
	}
}

function common:UnitInRange(unit)
	local spells = spellRange[PLAYER_CLASS]
	local spec, spell = GetSpecialization()

	if (UnitCanAttack('player', unit)) then
		spell = spells.harm[spec] or spells.harm[1]
	else
		spell = spells.help[spec] or spells.help[1]
	end
	return IsSpellInRange(spell, unit)
end
