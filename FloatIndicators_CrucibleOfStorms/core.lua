local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug

if ( GetLocale() == 'ruRU' ) then
  core.Lang = {
    RAID_NAME = 'Горнило Штормов',
		BOSS1 = "Неусыпный совет",
		BOSS2 = "Глашатай Бездны Уу'нат",
  }

  core.Lang.MC = 'МК'
  core.Lang.EXPLOSION = 'Взрыв'
  core.Lang.BUFF = 'Бафф'
  core.Lang.RUN_AWAY = 'Выбеги'
  core.Lang.HERALD = 'Глашатай'
  core.Lang.TRIDENT = 'Трезубец'
  core.Lang.STONE ='Камень'
  core.Lang.CROWN = 'Корона'
  core.Lang.HEAL = 'Хил'
else 
  core.Lang = {
    RAID_NAME = 'Crucible of Storms',
		BOSS1 = "Cabal",
		BOSS2 = "Uunat",
  }

  core.Lang.MC = 'MC'
  core.Lang.EXPLOSION = 'Explosion'
  core.Lang.BUFF = 'Buff'
  core.Lang.RUN_AWAY = 'Run away'
  core.Lang.HERALD = 'Herald'

  core.Lang.TRIDENT = 'Trident'
  core.Lang.STONE ='Stone'
  core.Lang.CROWN = 'Crown'
  core.Lang.HEAL = 'Heal'
end 

core.version = '18.04.2019 01:06'
core.raidName = core.Lang.RAID_NAME..' (Т23.5)'
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