local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug

core.version = '18.04.2019 01:06'
core.raidName = 'Горнило Штормов (Т23.5)'
core.raidID = 1177
core.bossOrder = 0
--[==[
  -- uldir

  [2146] = 2128 - Fetid Devourer
  [2147] = 2122 - G'huun
  [2167] = 2141 - MOTHER
  [2194] = 2135 - Mythrax the Unraveler
  [2168] = 2144 - Taloc
  [2166] = 2134 - Vectis
  [2169] = 2136 - Zek'voz
  [2195] = 2145 - Zul TODO:Check it
]==]


local list = {
}

ns.AddToDeafaultSpell(list, 1)		