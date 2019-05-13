local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug

core.version = '69'
core.raidName = 'Гробница Саргераса (Т20)'
core.raidID = 875

--[==[
	-- Tomb of Sargeras
  [1862] = 2032, -- Goroth
  [1867] = 2048, -- Demonic Inquisition
  [1856] = 2036, -- Harjatan
  [1861] = 2037, -- Mistress Sasszine
  [1903] = 2050, -- Sisters of the Moon
  [1896] = 2054, -- Desolate Host
  [1897] = 2052, -- Maiden of Vigilance
  [1873] = 2038, -- Fallen Avatar
  [1898] = 2051, -- Kiljaeden
]==]


-- ns.AddToDeafaultSpell(list, size)		

local list = {
	-- KJ
	[234310] = true,
	[240916] = true,
	[238505] = true,
	[236710] = true,
	[237590] = true,
	
	-- Inquiz
	[233983] = true,

	-- Goroth
	[233272] = true,
	
	-- Harj
	[231729] = true,
	[234016] = true,
	
	-- Misst
	[230920] = true,
	[232913] = true,
	
	-- Sisters
	[236712] = true,
	[236305] = true,

	-- Maiden
	[235213] = true, 
	[235240] = true,
	[240209] = true,
	
	-- Soul
	[238018] = true,
	[236515] = true, 
--	[235924] = true,

	-- Avatar
	[240728] = true,
	[239739] = true,
}

ns.AddToDeafaultSpell(list, 1)	