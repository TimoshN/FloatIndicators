local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug

core.version = '17'
core.raidName = 'Анторус (Т21)'
core.raidID = 946
core.bossOrder = 0
--[==[
-- Antorus, the Burning Throne
  [1984] = 2063, -- Aggramar
  [1985] = 2064, -- Portal Keeper Hasabel
  [1983] = 2069, -- Varimathras
  [1997] = 2070, -- War Council
  [1986] = 2073, -- The Coven of Shivarra
  [1987] = 2074, -- Hounds of Sargeras
  [2025] = 2075, -- Eonar, the Lifebinder
  [1992] = 2076, -- Garothi Worldbreaker
  [2009] = 2082, -- Imonar the Soulhunter
  [2004] = 2088, -- Kin'garoth
  [2031] = 2092, -- Argus the Unmaker
]==]


-- ns.AddToDeafaultSpell(list, size)

local list = {
	-- Азабель
	[246316] = true,
	[244607] = true,
	[245050] = true,

	--Вариматрас
	[243961] = true,

	-- Ковен
	[245586] = true,
}

--ns.AddToDeafaultSpell(list, 1)
