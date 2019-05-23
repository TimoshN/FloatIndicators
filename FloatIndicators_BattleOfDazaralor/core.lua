local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug

if ( GetLocale() == 'ruRU' ) then
	core.Lang = {
		RAID_NAME = 'Дазаралор',
		BOSS1 = "Чемпион света",
		BOSS2 = "Гронг",
		BOSS3 = "Мастера Огня и Нефрита",
		BOSS4 = "Роскошь",
		BOSS5 = "Конклав избранных",
		BOSS6 = "Растахан",
		BOSS7 = "Главный механик Меггакрут",
		BOSS8 = "Штормовая блокада",
		BOSS9 = "Леди Джайна Праудмур",
	}

	core.Lang.DISPEL = 'Диспел'
	core.Lang.PURGE = 'Пурж'
	core.Lang.SPHERE = 'Сфера'
	core.Lang.RUN = 'Беги'
	core.Lang.POOL = 'Лужа'
	core.Lang.SHARE = 'Делить'
	core.Lang.SWAP = 'Свап'
	core.Lang.TIGER = 'Тигр'
	core.Lang.MOVE_OUT  = 'Отойди'
	core.Lang.RUN_AWAY = 'Выбеги'
	core.Lang.MINI = 'Мини'
	core.Lang.GUN = 'Пушка'
	core.Lang.CLEANING = 'Чистка'
	core.Lang.ON_YOU = 'На тебе'
	core.Lang.SEAWEED = 'Водоросли'
	core.Lang.MC = 'МК'
	core.Lang.AVALANCE = 'Лавина'
	core.Lang.TO_BARREL = 'К бочке'
	core.Lang.BLAST = 'Залп'
	core.Lang.HEARTH = 'Сердце'
	core.Lang.EXPLOSION = 'Взрыв'
	core.Lang.SHARE = 'Делить'
	core.Lang.KICK = 'Сбить'
	core.Lang.PORTAL = 'Портал'
	core.Lang.VUHDU = 'Тотем'
	core.Lang.RAY = 'Луч'
else 
	core.Lang = {
		RAID_NAME = 'Dazaralor',
		BOSS1 = "Champions of the Light",
		BOSS2 = "Grong",
		BOSS3 = "Jademasters",
		BOSS4 = "Opulence",
		BOSS5 = "Conclave of the Chosen",
		BOSS6 = "Rastakhan",
		BOSS7 = "Mekkatorque",
		BOSS8 = "Stormwall Blockade",
		BOSS9 = "Lady Jaina Proudmoore",
	}

	core.Lang.DISPEL = 'Dispel'
	core.Lang.PURGE = 'Purge'
	core.Lang.SPHERE = 'Sphere'
	core.Lang.RUN = 'Run'
	core.Lang.POOL = 'Pool'
	core.Lang.SHARE = 'Share'
	core.Lang.SWAP = 'Swap'
	core.Lang.TIGER = 'Tiger'
	core.Lang.MOVE_OUT  = 'Move out'
	core.Lang.RUN_AWAY = 'Run away'
	core.Lang.MINI = 'Mini'
	core.Lang.GUN = 'Gun'
	core.Lang.CLEANING = 'Cleaning'
	core.Lang.ON_YOU = 'On YOU'
	core.Lang.SEAWEED = 'Seaweed'
	core.Lang.MC = 'MC'
	core.Lang.AVALANCE = 'Avalance'
	core.Lang.TO_BARREL = 'To barrel'
	core.Lang.BLAST = 'Blast'
	core.Lang.HEARTH = 'Hearth'
	core.Lang.EXPLOSION = 'Explosion'
	core.Lang.SHARE = 'Share' 
	core.Lang.KICK = 'Kick'
	core.Lang.PORTAL = 'Portal'
	core.Lang.VUHDU = 'Totem'
	core.Lang.RAY = 'Ray'
end

core.version = '24.05.2019 00:15'
core.raidName = core.Lang.RAID_NAME..' (T23)'
core.raidID = 1176
core.bossOrder = 0
--[==[

	Champion of the Light: 2265
		--2344 Alliance, 2333 Horde
		
	Grong (Alliance: 2284, Horde: 2263)
		--2263 2340 Alliance, 2284 2325 Horde
		
	Jadefire Masters(Alliance: 2285, Horde: 2266)
		--2266 2341 horde, 2285 2323 Alliance
	
	
	Opulence: 2271 2342
	Conclave: 2268 2330
	Mekkatorque: 2276 2334
	Rastakhan: 2272 2335
	Stormwall Blockade: 2280 2337
	Jaina: 2281 2343
	

]==]

local list = {
	
}

ns.AddToDeafaultSpell(list, 1)		