if AleaUI_GUI then return end

local IsAddonMessagePrefixRegistered = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered or IsAddonMessagePrefixRegistered
local RegisterAddonMessagePrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage

--[==[
	Change log
	v83
		еще пропажа с PlaySound
		
	v82
		обнова для PlaySound
	
	v81
		корректировка границ групп
		
	v80
		hidden = true, чтобы скрыть подгруппы в меню
		
	v79
		иконки + и - из файлов игры
		
	v78
		вкладки групп
		изменен код расстановки элементов, UpdateSize для всех элементов
		
	v77
		добавить в список выпадающее меня для скрытия
		
	v76
		добавлена отладка
		
	v75
		по умолчанию выбирать профиль №1
	
	v74
		fix error with profile gui
		
	v73
		ActveSpecGroup to specialization multi frofile
		
	v72
		:SetColorTexture for legion
	
	v71
		добавлен индикатор слайдера для multidropdown
		
	v70
		обновления для multidropdown
		
	v69
		улучшена работа multidropdown
		добавлены тултипы в multidropdown
		обвновление положения фреймов при изменении размеров
		исправлен текст выбора шрифтов
		добавлен звук при нажатии
		
	v68
		багфиксы multidropdown
	
	v67
		добавлен новый вид виджета - multidropdown
		используем общую функцию для скрытия выпадающих меню
	
	v66 
		выпадающее меню проверяет левый и правый край экрана
	
	v65
		исправлен баг при вводе значения у ползунка
	
	v64
		исправлен баг в окне выбора цвета с ползунком прозрачности
		
		
]==]

local libOwner = ...
local ns = _G['AleaGUI_PrototypeLib']

_G['AleaUI_GUI'] = ns

local options
local scan
local default = {}
local version = 83
local debugging = false

local cvarSettings = 'AleaGUI_enablePerSpecProfile'
local savedVariableDebug = 'AleaUIGUI_savedVariableDebug'
local enableSavedVariableLogging = false
local lastVarDir = nil

local old_print = print
local print = function(...)
	if not debugging then
		return 
	end
	
	if savedVariableDebug and lastVarDir then
	
		_G[lastVarDir][savedVariableDebug] = _G[lastVarDir][savedVariableDebug] or {}
		
		local msg = ''
		local numVars = select('#', ...)
		for i=1, numVars do
			local curVar = select(i, ...)
			
			if i < numVars then
				msg = msg..tostring(curVar)..', '
			else
				msg = msg..tostring(curVar)..'.'
			end
		end
		
		if msg ~= '' then
			_G[lastVarDir][savedVariableDebug][#_G[lastVarDir][savedVariableDebug]+1] = msg
		end
	end
	
	old_print('AleaUI-',libOwner,":",...)
end

local function addDefaultOptions(t1, t2)
	for i, v in pairs(t2) do
		if t1[i] == nil or ( ( type(t1[i]) == "table" or type(v) == "table" ) and type(t1[i]) ~= type(v) ) then
			t1[i] = v
		elseif type(v) == "table" and type(t1[i]) == "table" then
			 addDefaultOptions(t1[i], v)
		end
	end
end

ns.addDefaultOptions = addDefaultOptions


do
	local temp = {}
	for k,v in pairs(ns.prototypes) do
		for i=1, 10 do
			temp[i] = ns[v](ns)
			temp[i].free = false
		end
		for i=1, 10 do
			temp[i].free = true
		end
	end
	
	temp = nil
end

do
	-- localization
	
	local gameLocale = GetLocale()
	if gameLocale == "enGB" then
		gameLocale = "enUS"
	end

	local showmissing = true
	local locales = {}
	local setmetatable = setmetatable	
	local missings = {}
	
	local function BuildTranslateInstance(addon)
	
		local app = {}
		
		app._addon = addon
		app._app = {}
		app._mtt = setmetatable({}, {
			__newindex = function (table, key, value)
				app._app[key] = value
				return app._app[key]
			end,
			__index = function(table, key)
				if not app._app[key] then
					if showmissing then
						
						missings[app._addon] = missings[app._addon] or {}					
						missings[app._addon][key] = true
						
						print("Missing locale for",app._addon,key)
					end
					return key
				end	
				return app._app[key] == true and key or app._app[key]
			end})
				
		return app._mtt
	end
	
	ns.GetTranslate = function(addon, locale, default)
	
		local gameLocale = GAME_LOCALE or gameLocale

		if gameLocale ~= locale and not default then 
			return 
		end
		
		if not locales[addon] then
			locales[addon] = BuildTranslateInstance(addon)
		end
		
		return locales[addon]
	end
	
	ns.GetLocale = function(addon)
		return locales[addon]
	end
	
	
	ns.ExtractLovelArgs = function(addon, db)
	
		for k,v in pairs(missings[addon]) do
			
			db[addon] = db[addon] or {}
			db[addon][k] = v
		end
	end
end

do
	-- slashcommamd
	
	local slashtag = "SLASH_"
	local upper = string.upper
	local db = {}
	
	local function Slash(addon, command, func)
		
		local addon = upper(addon)
		local commnadLine = command:gsub('/', '')
		local slashName = addon..commnadLine
		
		if not db[slashName] then
			db[slashName] = 0 		
			SlashCmdList[slashName] = func
		end
		
		db[slashName] = db[slashName] + 1
		
		_G[slashtag..slashName..db[slashName]] = command	
	end
	
	ns.SlashCommand = Slash
end

do
	-- minimap
	local onClick, onMouseUp, onMouseDown, onDragStart, onDragStop, updatePosition


	local minimapShapes = {
		["ROUND"] = {true, true, true, true},
		["SQUARE"] = {false, false, false, false},
		["CORNER-TOPLEFT"] = {false, false, false, true},
		["CORNER-TOPRIGHT"] = {false, false, true, false},
		["CORNER-BOTTOMLEFT"] = {false, true, false, false},
		["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
		["SIDE-LEFT"] = {false, true, false, true},
		["SIDE-RIGHT"] = {true, false, true, false},
		["SIDE-TOP"] = {false, false, true, true},
		["SIDE-BOTTOM"] = {true, true, false, false},
		["TRICORNER-TOPLEFT"] = {false, true, true, true},
		["TRICORNER-TOPRIGHT"] = {true, false, true, true},
		["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
		["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
	}

	local function GetRadius()	
		return GetMiniMapButtonsRad and GetMiniMapButtonsRad() or 80
	end
	
	function updatePosition(button)
		local angle = math.rad(button.settings and button.settings.minimapPos or button.minimapPos or 225)
		local x, y, q = math.cos(angle), math.sin(angle), 1
		if x < 0 then q = q + 1 end
		if y > 0 then q = q + 2 end
		local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
		local quadTable = minimapShapes[minimapShape]
		if quadTable[q] then
			x, y = x*GetRadius(), y*GetRadius()
		else
			local diagRadius = math.sqrt(2*(GetRadius())^2)-10
			x = math.max(-GetRadius(), math.min(x*diagRadius, GetRadius()))
			y = math.max(-GetRadius(), math.min(y*diagRadius, GetRadius()))
		end
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end

	local function onUpdate(self)
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		if self.settings then
			self.settings.minimapPos = math.deg(math.atan2(py - my, px - mx)) % 360
		else
			self.minimapPos = math.deg(math.atan2(py - my, px - mx)) % 360
		end	
		updatePosition(self)
	end

	function onDragStart(self)
		self:LockHighlight()
		self.isMouseDown = true
		self.icon:UpdateCoord()
		self:SetScript("OnUpdate", onUpdate)
		self.isMoving = true
		GameTooltip:Hide()
	end

	function onDragStop(self)
		self:SetScript("OnUpdate", nil)
		self.isMouseDown = false
		self.icon:UpdateCoord()
		self:UnlockHighlight()
		self.isMoving = nil
	end

	local defaultCoords = {0, 1, 0, 1}
	local function updateCoord(self)
		local coords = defaultCoords
		local deltaX, deltaY = 0, 0
		if not self:GetParent().isMouseDown then
			deltaX = (coords[2] - coords[1]) * 0.05
			deltaY = (coords[4] - coords[3]) * 0.05
		end
		self:SetTexCoord(coords[1] + deltaX, coords[2] - deltaX, coords[3] + deltaY, coords[4] - deltaY)
	end

	function onClick(self, button)
		if self.OnClick then	
			self.OnClick()
		end
	end

	function onMouseDown(self) self.isMouseDown = true; self.icon:UpdateCoord() end
	function onMouseUp(self) self.isMouseDown = false; self.icon:UpdateCoord() end

	------------- нопка у миникраты-----------------------------
	
	local minimapsbuttons = {}
	
	local function MinimapButtonCreate(texture, addon)
		local button = CreateFrame("Button", 'LibDBIcon10_'..addon, Minimap)
		button:SetSize(31, 31)
		button.minimapButtonFadeOut = true
		button:SetFrameLevel(8)
		button:SetFrameStrata("MEDIUM")
		button:RegisterForClicks("anyUp")
		button:RegisterForDrag("LeftButton")
		button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
		button.isMouseDown = false

		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53, 53)
		overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
		overlay:SetPoint("TOPLEFT")

		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(20, 20)
		background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
		background:SetPoint("TOPLEFT", 7, -5)

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(17, 17)
		icon:SetTexture(texture or "Interface\\Icons\\spell_priest_shadoworbs")
		icon:SetPoint("TOPLEFT", 7, -6)	
		icon.UpdateCoord = updateCoord
		icon:UpdateCoord()

		button.icon = icon

		button.Update = function(self, settings)
			if settings then
				self.settings = settings
			end
			
			if self.settings and self.settings.hide == false then
				self:Hide()
			else
				self:Show()
			end
			
			updatePosition(self)
		end

		button:SetScript("OnMouseDown", onMouseDown)
		button:SetScript("OnMouseUp", 	onMouseUp)
		button:SetScript("OnClick",		onClick)
		button:SetScript("OnDragStart", onDragStart)
		button:SetScript("OnDragStop", 	onDragStop)

		button:SetScript("OnEnter", function(self)
			if self.OnEnter then
				self.OnEnter(self)
			end
		end)
		button:SetScript("OnLeave", function(self)
			if self.OnLeave then
				self.OnLeave(self)
			end
		end)
		
		return button
	end
	
	ns.MinimapButton = function(addon, data, settings)
	
		if not minimapsbuttons[addon] then
			minimapsbuttons[addon] = MinimapButtonCreate(data.texture, addon)
			minimapsbuttons[addon].settings = settings			
			minimapsbuttons[addon].OnClick = data and data.OnClick or false
			minimapsbuttons[addon].OnEnter = data and data.OnEnter or false
			minimapsbuttons[addon].OnLeave = data and data.OnLeave or false
		end
		minimapsbuttons[addon]:Update()		
	end
	
	ns.GetMinimapButton = function(addon)	
		return minimapsbuttons[addon]
	end
end

local MAX_NUM_SPECS = 2
local separator = " - "
local DEFAULT_NAME = "Default"
local lastactivespec = -1
local profileOwner
local db_variables = {}

local PROFILE_RESET = "PROFILE_RESET"
local PROFILE_CHANGED = "PROFILE_CHANGED"

local pairs, type, UnitFullName 
	= pairs, type, UnitFullName

local function GetOwner()
	local name = UnitName("player")
	local realm = GetRealmName()

	assert(realm, "T:"..GetRealmName())
	return name..separator..realm
end

local methods = {}
local function Fire(self, event)	
--	print("Fire switch profile by", event)
	
	if methods[self._db] and methods[self._db][event] then		
		for i=1, #methods[self._db][event] do
			methods[self._db][event][i]()
		end
	end
end

function scan(workcopy, default)
  
   for key, value in pairs(workcopy) do
      if type(value or "") == "table" and type(default[key] or "") == "table"then
         workcopy[key] = scan(value, default[key])
         
      elseif value == default[key] then
		 workcopy[key] = nil      
      end      
   end   
	if next( workcopy ) == nil then
		return nil
	end	
	return workcopy
end

local function deepcopy(t)
	if type(t) ~= 'table' then return t end
	
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			v = deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end

function ALEAUI_OnProfileEvent(db,event,func)

	if event ~= PROFILE_CHANGED and event ~= PROFILE_RESET then
		error('Allowed events "PROFILE_CHANGED" and "PROFILE_RESET"')
		return
	end
	
	methods[db] = methods[db] or {}
	methods[db][event] = methods[db][event] or {}
	methods[db][event][#methods[db][event]+1] = func
end
 
 local function merge(t1, t2)
	for i, v in pairs(t2) do
	
		if type(v) == "table" and type(t1[i]) == "table" then
			merge(t1[i], v)
		else
			t1[i] = v
		end
	end
end


local function GetInstance(db, defaults, profileKey)
	profileKey = profileKey or DEFAULT_NAME
	
	if not db_variables[db] then
		print('GetInstance - Not DB:', db,' Create it')
		
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LOGOUT")
		f:SetScript("OnEvent", function(self)
			print('PLAYER_LOGOUT')
			self:Save()	
		end)
		
		f._db = db
		f._defaults = defaults
		f._profileKey = profileKey
		f.Fire = Fire
		
		f.Save = function(self)	
			print('GetInstance - Save:', db, self._profileKey)
			scan(self.workingcopy, self._defaults)		
			_G[self._db].profiles[self._profileKey] = deepcopy(self.workingcopy)	
		end
		f.Reset = function(self)
			print('GetInstance - Reset:', db, self._profileKey)
			self.workingcopy = {}
			_G[db].profiles[self._profileKey] = {}
		end
		f.Refresh = function(self)
			print('GetInstance - Refresh:', db, self._profileKey)
			self.workingcopy = deepcopy(self._defaults)
			merge(self.workingcopy, _G[db].profiles[self._profileKey])
		end
		db_variables[db] = f	
	end
	
	print('GetInstance - return:', db, profileKey)
	
	db_variables[db]._profileKey = profileKey
	
	return db_variables[db]
end


do
	local GetActiveSpecGroup = GetActiveSpecGroup
	local GetNumSpecializations = GetNumSpecializations
	local GetSpecialization = GetSpecialization
	
	local function Legion_CreateProfileList(variable, profileOwner, usedefault)
	
	
		if not _G[variable].profileKeys[profileOwner] then
			_G[variable].profileKeys[profileOwner] = {}

			if usedefault then
				for i=1, ns.isClassic and 1 or GetNumSpecializations() do
					_G[variable].profileKeys[profileOwner][i] = DEFAULT_NAME
				end
			else
				for i=1, ns.isClassic and 1 or GetNumSpecializations() do
					_G[variable].profileKeys[profileOwner][i] = profileOwner		
				end
			end
		else	
			if usedefault then
				for i=1, ns.isClassic and 1 or GetNumSpecializations() do
					if not _G[variable].profileKeys[profileOwner][i] then
						_G[variable].profileKeys[profileOwner][i] = DEFAULT_NAME
					end
				end
			else
				for i=1, ns.isClassic and 1 or GetNumSpecializations() do
					if not _G[variable].profileKeys[profileOwner][i] then
						_G[variable].profileKeys[profileOwner][i] = profileOwner		
					end
				end
			end			
		end
	end

	function ALEAUI_NewDB(variable, default, usedefault)

		if not _G[variable] then _G[variable] = {}	end
		if not _G[variable].profiles then _G[variable].profiles = {} end
		if not _G[variable].profileKeys then _G[variable].profileKeys = {} end
		if _G[variable][cvarSettings] == nil then
			_G[variable][cvarSettings] = false
		end	
		
		lastVarDir = lastVarDir or variable
		
		profileOwner = profileOwner or GetOwner()

		Legion_CreateProfileList(variable, profileOwner, usedefault)
		

		if not _G[variable].profiles[DEFAULT_NAME] then
			_G[variable].profiles[DEFAULT_NAME] = {}
		end
		if not _G[variable].profiles[profileOwner] then
			_G[variable].profiles[profileOwner] = {}
		end
		
		if _G[variable].profileKeys[profileOwner] and type(_G[variable].profileKeys[profileOwner]) ~= "table" then
			local oldprofile = _G[variable].profileKeys[profileOwner]
			
			_G[variable].profileKeys[profileOwner] = {}
			
			for i=1, ns.isClassic and 1 or GetNumSpecializations() do
				_G[variable].profileKeys[profileOwner][i] = oldprofile		
			end	
		end
		
		local activespec
		local instance
		
		activespec = ns.isClassic and 1 or ( GetSpecialization() and GetSpecialization() > 0 ) and GetSpecialization() or 1
		
		if not _G[variable].profileKeys[profileOwner][_G[variable][cvarSettings] and activespec or 1] then		
			_G[variable].profileKeys[profileOwner][_G[variable][cvarSettings] and activespec or 1] = DEFAULT_NAME
		end
		
		if not _G[variable].profiles[_G[variable].profileKeys[profileOwner][_G[variable][cvarSettings] and activespec or 1]] then
			_G[variable].profileKeys[profileOwner][_G[variable][cvarSettings] and activespec or 1] = DEFAULT_NAME
		end
		
		instance = GetInstance(variable, default, _G[variable].profileKeys[profileOwner][_G[variable][cvarSettings] and activespec or 1])
		instance:Refresh()			
		
		lastactivespec = activespec
		
		print('ALEAUI_NewDB - lastactivespec:', activespec, cvarSettings, _G[variable][cvarSettings] )
		 
		return instance.workingcopy
	end
end

local h = CreateFrame("Frame")
if ( not ns.isClassic ) then
	h:RegisterEvent("PLAYER_TALENT_UPDATE")
end
h:SetScript("OnEvent", function(self, event)
	self[event](self, event)
end)

function h:ACTIVE_TALENT_GROUP_CHANGED(event)
	local activespec = GetActiveSpecGroup() or 1

	if activespec ~= lastactivespec then
		for db, instance in pairs(db_variables) do
		
			if _G[db][cvarSettings] then
				local prev = _G[db].profileKeys[profileOwner][lastactivespec]
				local new = _G[db].profileKeys[profileOwner][activespec]
				if prev ~= new then
					
					instance:Save()		
					instance:Fire(PROFILE_CHANGED)
					
					print('ACTIVE_TALENT_GROUP_CHANGED - prev ~= new', PROFILE_CHANGED )
				end
			elseif lastactivespec == -1 then
				instance:Save()		
				instance:Fire(PROFILE_CHANGED)
				
				print('ACTIVE_TALENT_GROUP_CHANGED - lastactivespec is -1', PROFILE_CHANGED )
			end
		end
		
		lastactivespec = activespec
	end
end

function h:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	unit = unit or 'player'
	if unit ~= 'player' then return end
	local activespec = ( GetSpecialization() and GetSpecialization() > 0 ) and GetSpecialization() or 1


	if activespec ~= lastactivespec then
		for db, instance in pairs(db_variables) do
		
			if _G[db][cvarSettings] then
				local prev = _G[db].profileKeys[profileOwner][lastactivespec]
				local new = _G[db].profileKeys[profileOwner][activespec]
				if prev ~= new then					
					instance:Save()		
					instance:Fire(PROFILE_CHANGED)
					
					print('PLAYER_SPECIALIZATION_CHANGED - prev ~= new', PROFILE_CHANGED )
				end
			elseif lastactivespec == -1 then
				instance:Save()		
				instance:Fire(PROFILE_CHANGED)
				
				print('PLAYER_SPECIALIZATION_CHANGED - lastactivespec is -1', PROFILE_CHANGED )
			end
		end
		
		lastactivespec = activespec
	end
end

local function RunSpecSwap()
	local activespec = GetSpecialization() or 1

	if activespec ~= lastactivespec then
		for db, instance in pairs(db_variables) do

			if _G[db][cvarSettings] then
				local prev = _G[db].profileKeys[profileOwner][lastactivespec]
				local new = _G[db].profileKeys[profileOwner][activespec]
				if prev ~= new then

					instance:Save()		
					instance:Fire(PROFILE_CHANGED)

					print('PLAYER_TALENT_UPDATE - prev ~= new', PROFILE_CHANGED )
				end
			elseif lastactivespec == -1 then
				instance:Save()		
				instance:Fire(PROFILE_CHANGED)

				print('PLAYER_TALENT_UPDATE - lastactivespec is -1', PROFILE_CHANGED )
			end
		end

		lastactivespec = activespec
	end
end

function h:PLAYER_TALENT_UPDATE(event)
	RunSpecSwap()
end

local function GetProfileInterator(db, spec)
	return function()
		local t = {}
		
		local activeProfile = _G[db].profileKeys[profileOwner][spec]
		for profileKey in pairs(_G[db].profiles) do			
		--	if activeProfile ~= profileKey then
			t[profileKey] = profileKey
		--	end
		end
		
		return t
	end
end

local function GetDeleteInterator(db)
	return function()
		local t = {}
	
		local profile1 = _G[db].profileKeys[profileOwner][1]
		local profile2 = _G[db][cvarSettings] and _G[db].profileKeys[profileOwner][2] or profile1
		local profile3 = _G[db][cvarSettings] and _G[db].profileKeys[profileOwner][3] or profile1
		local profile4 = _G[db][cvarSettings] and _G[db].profileKeys[profileOwner][4] or profile1
		
		for profileKey in pairs(_G[db].profiles) do			
			if profile1 ~= profileKey and profile2 ~= profileKey and profile3 ~= profileKey and profile4 ~= profileKey then
				t[profileKey] = profileKey
			end
		end
		
		return t
	end
end

local function ChangeProfile(db, spec, value)
	local instance = db_variables[db]
	
--	print("T", _G[db].profileKeys[profileOwner][spec], value)

	print('ChangeProfile - init', db, spec, value, ( _G[db].profileKeys[profileOwner][spec] ~= value ))
	
	if _G[db].profileKeys[profileOwner][spec] ~= value then
		_G[db].profileKeys[profileOwner][spec] = value
		
		print('ChangeProfile - Check for spec', db, spec, value, ( _G[db].profileKeys[profileOwner][spec] ~= value ), _G[db][cvarSettings], ( _G[db][cvarSettings] and lastactivespec or 1 ))
		
		if ( _G[db][cvarSettings] and lastactivespec or 1 ) == spec then
			instance:Save()
			instance:Fire(PROFILE_CHANGED)
		end
	end	
end

function ALEAUI_GetProfileOptions(db, singleSpec)
	
	local gameLocale = GAME_LOCALE or GetLocale()

	local L = {
		choose = "Existing Profiles",
		choose_desc = "You can either create a new profile by entering a name in the editbox, or choose one of the already existing profiles.",
		choose_sub = "Select one of your currently available profiles.",
		copy = "Copy From",
		copy_desc = "Copy the settings from one existing profile into the currently active profile.",
		current = "Current Profile:",
		default = "Default",
		delete = "Delete a Profile",
		delete_confirm = "Are you sure you want to delete the selected profile?",
		delete_desc = "Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file.",
		delete_sub = "Deletes a profile from the database.",
		intro = "You can change the active database profile, so you can have different settings for every character.",
		new = "New",
		new_sub = "Create a new empty profile.",
		profiles = "Profiles",
		profiles_sub = "Manage Profiles",
		reset = "Reset Profile",
		reset_desc = "Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over.",
		reset_sub = "Reset the current profile to the default",
	}

	local LOCALE = GetLocale()
	if LOCALE == "deDE" then
		L["choose"] = "Vorhandene Profile"
		L["choose_desc"] = "Du kannst ein neues Profil erstellen, indem du einen neuen Namen in der Eingabebox 'Neu' eingibst, oder wähle eines der vorhandenen Profile aus."
		L["choose_sub"] = "Wählt ein bereits vorhandenes Profil aus."
		L["copy"] = "Kopieren von..."
		L["copy_desc"] = "Kopiere die Einstellungen von einem vorhandenen Profil in das aktive Profil."
		-- L["current"] = "Current Profile:"
		L["default"] = "Standard"
		L["delete"] = "Profil löschen"
		L["delete_confirm"] = "Willst du das ausgewählte Profil wirklich löschen?"
		L["delete_desc"] = "Lösche vorhandene oder unbenutzte Profile aus der Datenbank um Platz zu sparen und um die SavedVariables Datei 'sauber' zu halten."
		L["delete_sub"] = "Löscht ein Profil aus der Datenbank."
		L["intro"] = "Hier kannst du das aktive Datenbankprofile ändern, damit du verschiedene Einstellungen für jeden Charakter erstellen kannst, wodurch eine sehr flexible Konfiguration möglich wird."
		L["new"] = "Neu"
		L["new_sub"] = "Ein neues Profil erstellen."
		L["profiles"] = "Profile"
		L["profiles_sub"] = "Profile verwalten"
		L["reset"] = "Profil zurücksetzen"
		L["reset_desc"] = "Setzt das momentane Profil auf Standardwerte zurück, für den Fall das mit der Konfiguration etwas schief lief oder weil du einfach neu starten willst."
		L["reset_sub"] = "Das aktuelle Profil auf Standard zurücksetzen."
	elseif LOCALE == "frFR" then
		L["choose"] = "Profils existants"
		L["choose_desc"] = "Vous pouvez créer un nouveau profil en entrant un nouveau nom dans la boîte de saisie, ou en choississant un des profils déjà existants."
		L["choose_sub"] = "Permet de choisir un des profils déjà disponibles."
		L["copy"] = "Copier à partir de"
		L["copy_desc"] = "Copie les paramètres d'un profil déjà existant dans le profil actuellement actif."
		-- L["current"] = "Current Profile:"
		L["default"] = "Défaut"
		L["delete"] = "Supprimer un profil"
		L["delete_confirm"] = "Etes-vous sûr de vouloir supprimer le profil sélectionné ?"
		L["delete_desc"] = "Supprime les profils existants inutilisés de la base de données afin de gagner de la place et de nettoyer le fichier SavedVariables."
		L["delete_sub"] = "Supprime un profil de la base de données."
		L["intro"] = "Vous pouvez changer le profil actuel afin d'avoir des paramètres différents pour chaque personnage, permettant ainsi d'avoir une configuration très flexible."
		L["new"] = "Nouveau"
		L["new_sub"] = "Créée un nouveau profil vierge."
		L["profiles"] = "Profils"
		L["profiles_sub"] = "Gestion des profils"
		L["reset"] = "Réinitialiser le profil"
		L["reset_desc"] = "Réinitialise le profil actuel au cas où votre configuration est corrompue ou si vous voulez tout simplement faire table rase."
		L["reset_sub"] = "Réinitialise le profil actuel avec les paramètres par défaut."
	elseif LOCALE == "koKR" then
		L["choose"] = "프로필 선택"
		L["choose_desc"] = "새로운 이름을 입력하거나, 이미 있는 프로필중 하나를 선택하여 새로운 프로필을 만들 수 있습니다."
		L["choose_sub"] = "당신이 현재 이용할수 있는 프로필을 선택합니다."
		L["copy"] = "복사"
		L["copy_desc"] = "현재 사용중인 프로필에, 선택한 프로필의 설정을 복사합니다."
		-- L["current"] = "Current Profile:"
		L["default"] = "기본값"
		L["delete"] = "프로필 삭제"
		L["delete_confirm"] = "정말로 선택한 프로필의 삭제를 원하십니까?"
		L["delete_desc"] = "데이터베이스에 사용중이거나 저장된 프로파일 삭제로 SavedVariables 파일의 정리와 공간 절약이 됩니다."
		L["delete_sub"] = "데이터베이스의 프로필을 삭제합니다."
		L["intro"] = "모든 캐릭터의 다양한 설정과 사용중인 데이터베이스 프로필, 어느것이던지 매우 다루기 쉽게 바꿀수 있습니다."
		L["new"] = "새로운 프로필"
		L["new_sub"] = "새로운 프로필을 만듭니다."
		L["profiles"] = "프로필"
		L["profiles_sub"] = "프로필 설정"
		L["reset"] = "프로필 초기화"
		L["reset_desc"] = "단순히 다시 새롭게 구성을 원하는 경우, 현재 프로필을 기본값으로 초기화 합니다."
		L["reset_sub"] = "현재의 프로필을 기본값으로 초기화 합니다"
	elseif LOCALE == "esES" or LOCALE == "esMX" then
		L["choose"] = "Perfiles existentes"
		L["choose_desc"] = "Puedes crear un nuevo perfil introduciendo un nombre en el recuadro o puedes seleccionar un perfil de los ya existentes."
		L["choose_sub"] = "Selecciona uno de los perfiles disponibles."
		L["copy"] = "Copiar de"
		L["copy_desc"] = "Copia los ajustes de un perfil existente al perfil actual."
		-- L["current"] = "Current Profile:"
		L["default"] = "Por defecto"
		L["delete"] = "Borrar un Perfil"
		L["delete_confirm"] = "¿Estas seguro que quieres borrar el perfil seleccionado?"
		L["delete_desc"] = "Borra los perfiles existentes y sin uso de la base de datos para ganar espacio y limpiar el archivo SavedVariables."
		L["delete_sub"] = "Borra un perfil de la base de datos."
		L["intro"] = "Puedes cambiar el perfil activo de tal manera que cada personaje tenga diferentes configuraciones."
		L["new"] = "Nuevo"
		L["new_sub"] = "Crear un nuevo perfil vacio."
		L["profiles"] = "Perfiles"
		L["profiles_sub"] = "Manejar Perfiles"
		L["reset"] = "Reiniciar Perfil"
		L["reset_desc"] = "Reinicia el perfil actual a los valores por defectos, en caso de que se haya estropeado la configuración o quieras volver a empezar de nuevo."
		L["reset_sub"] = "Reinicar el perfil actual al de por defecto"
	elseif LOCALE == "zhTW" then
		L["choose"] = "現有的設定檔"
		L["choose_desc"] = "你可以通過在文本框內輸入一個名字創立一個新的設定檔，也可以選擇一個已經存在的設定檔。"
		L["choose_sub"] = "從當前可用的設定檔裏面選擇一個。"
		L["copy"] = "複製自"
		L["copy_desc"] = "從當前某個已保存的設定檔複製到當前正使用的設定檔。"
		-- L["current"] = "Current Profile:"
		L["default"] = "預設"
		L["delete"] = "刪除一個設定檔"
		L["delete_confirm"] = "你確定要刪除所選擇的設定檔嗎？"
		L["delete_desc"] = "從資料庫裏刪除不再使用的設定檔，以節省空間，並且清理SavedVariables檔。"
		L["delete_sub"] = "從資料庫裏刪除一個設定檔。"
		L["intro"] = "你可以選擇一個活動的資料設定檔，這樣你的每個角色就可以擁有不同的設定值，可以給你的插件設定帶來極大的靈活性。"
		L["new"] = "新建"
		L["new_sub"] = "新建一個空的設定檔。"
		L["profiles"] = "設定檔"
		L["profiles_sub"] = "管理設定檔"
		L["reset"] = "重置設定檔"
		L["reset_desc"] = "將當前的設定檔恢復到它的預設值，用於你的設定檔損壞，或者你只是想重來的情況。"
		L["reset_sub"] = "將當前的設定檔恢復為預設值"
	elseif LOCALE == "zhCN" then
		L["choose"] = "现有的配置文件"
		L["choose_desc"] = "你可以通过在文本框内输入一个名字创立一个新的配置文件，也可以选择一个已经存在的配置文件。"
		L["choose_sub"] = "从当前可用的配置文件里面选择一个。"
		L["copy"] = "复制自"
		L["copy_desc"] = "从当前某个已保存的配置文件复制到当前正使用的配置文件。"
		-- L["current"] = "Current Profile:"
		L["default"] = "默认"
		L["delete"] = "删除一个配置文件"
		L["delete_confirm"] = "你确定要删除所选择的配置文件么？"
		L["delete_desc"] = "从数据库里删除不再使用的配置文件，以节省空间，并且清理SavedVariables文件。"
		L["delete_sub"] = "从数据库里删除一个配置文件。"
		L["intro"] = "你可以选择一个活动的数据配置文件，这样你的每个角色就可以拥有不同的设置值，可以给你的插件配置带来极大的灵活性。"
		L["new"] = "新建"
		L["new_sub"] = "新建一个空的配置文件。"
		L["profiles"] = "配置文件"
		L["profiles_sub"] = "管理配置文件"
		L["reset"] = "重置配置文件"
		L["reset_desc"] = "将当前的配置文件恢复到它的默认值，用于你的配置文件损坏，或者你只是想重来的情况。"
		L["reset_sub"] = "将当前的配置文件恢复为默认值"
	elseif LOCALE == "ruRU" then
		L["choose"] = "Существующие профили"
		L["choose_desc"] = "Вы можете создать новый профиль, введя название в поле ввода, или выбрать один из уже существующих профилей."
		L["choose_sub"] = "Выбор одиного из уже доступных профилей"
		L["copy"] = "Скопировать из"
		L["copy_desc"] = "Скопировать настройки из выбранного профиля в активный."
		-- L["current"] = "Current Profile:"
		L["default"] = "По умолчанию"
		L["delete"] = "Удалить профиль"
		L["delete_confirm"] = "Вы уверены, что вы хотите удалить выбранный профиль?"
		L["delete_desc"] = "Удалить существующий и неиспользуемый профиль из БД для сохранения места, и очистить SavedVariables файл."
		L["delete_sub"] = "Удаление профиля из БД"
		L["intro"] = "Изменяя активный профиль, вы можете задать различные настройки модификаций для каждого персонажа."
		L["new"] = "Новый"
		L["new_sub"] = "Создать новый чистый профиль"
		L["profiles"] = "Профили"
		L["profiles_sub"] = "Управление профилями"
		L["reset"] = "Сброс профиля"
		L["reset_desc"] = "Если ваша конфигурации испорчена или если вы хотите настроить всё заново - сбросьте текущий профиль на стандартные значения."
		L["reset_sub"] = "Сброс текущего профиля на стандартный"
	elseif LOCALE == "itIT" then
		L["choose"] = "Profili esistenti"
		L["choose_desc"] = "Puoi creare un nuovo profilo digitando il nome della casella di testo, oppure scegliendone uno tra i profili gia' esistenti."
		L["choose_sub"] = "Seleziona uno dei profili disponibili."
		L["copy"] = "Copia Da"
		L["copy_desc"] = "Copia le impostazioni da un profilo esistente, nel profilo attivo in questo momento."
		L["current"] = "Profilo Attivo:"
		L["default"] = "Standard"
		L["delete"] = "Cancella un profilo"
		L["delete_confirm"] = "Sei sicuro di voler cancellare il profilo selezionato?"
		L["delete_desc"] = "Cancella i profili non utilizzati dal database per risparmiare spazio e mantenere puliti i file di configurazione SavedVariables."
		L["delete_sub"] = "Cancella un profilo dal Database."
		L["intro"] = "Puoi cambiare il profilo attivo, in modo da usare impostazioni diverse per ogni personaggio."
		L["new"] = "Nuovo"
		L["new_sub"] = "Crea un nuovo profilo vuoto."
		L["profiles"] = "Profili"
		L["profiles_sub"] = "Gestisci Profili"
		L["reset"] = "Reimposta Profilo"
		L["reset_desc"] = "Riporta il tuo profilo attivo alle sue impostazioni di default, nel caso in cui la tua configurazione si sia corrotta, o semplicemente tu voglia re-inizializzarla."
		L["reset_sub"] = "Reimposta il profilo ai suoi valori di default."
	end
	
	local L_DUALSPEC_DESC, L_ENABLED, L_ENABLED_DESC, L_DUAL_PROFILE, L_DUAL_PROFILE_DESC

	do
		L_DUALSPEC_DESC = "When enabled, this feature allow you to select a different "..
				"profile for each talent spec. The dual profile will be swapped with the "..
				"current profile each time you switch from a talent spec to the other."
		L_ENABLED = 'Enable dual profile'
		L_ENABLED_DESC = 'Check this box to automatically swap profiles on talent switch.'
		L_DUAL_PROFILE = 'Dual profile'
		L_DUAL_PROFILE_DESC = 'Select the profile to swap with on talent switch.'

		local locale = GetLocale()
		if locale == "frFR" then
			L_DUALSPEC_DESC = "Lorsqu'elle est activée, cette fonctionnalité vous permet de choisir un profil différent pour chaque spécialisation de talents.  Le second profil sera échangé avec le profil courant chaque fois que vous passerez d'une spécialisation à l'autre."
			L_DUAL_PROFILE = "Second profil"
			L_DUAL_PROFILE_DESC = "Sélectionnez le profil à échanger avec le profil courant lors du changement de spécialisation."
			L_ENABLED = "Activez le second profil"
			L_ENABLED_DESC = "Cochez cette case pour échanger automatiquement les profils lors d'un changement de spécialisation."
		elseif locale == "deDE" then
			L_DUALSPEC_DESC = "Wenn aktiv, wechselt dieses Feature bei jedem Wechsel der dualen Talentspezialisierung das Profil. Das duale Profil wird beim Wechsel automatisch mit dem derzeit aktiven Profil getauscht."
			L_DUAL_PROFILE = "Duales Profil"
			L_DUAL_PROFILE_DESC = "Wähle das Profil, das beim Wechsel der Talente aktiviert wird."
			L_ENABLED = "Aktiviere Duale Profile"
			L_ENABLED_DESC = "Aktiviere diese Option, um beim Talentwechsel automatisch zwischen den Profilen zu wechseln."
		elseif locale == "koKR" then
			L_DUALSPEC_DESC = "이중 특성에 의하여 다른 프로필을 선택할 수 있게 합니다. 이중 프로필은 현재 프로필과 번갈아서 특성이 변경될 때 같이 적용됩니다."
			L_DUAL_PROFILE = "이중 프로필"
			L_DUAL_PROFILE_DESC = "특성이 바뀔 때 프로필을 선택합니다."
			L_ENABLED = "이중 프로필 사용"
			L_ENABLED_DESC = "특성이 변경 될때 자동으로 프로필을 변경하도록 선택합니다."
		elseif locale == "ruRU" then
			L_DUALSPEC_DESC = "Двойной профиль позволяет вам выбрать различные профили для каждой раскладки талантов. Профили будут переключаться каждый раз, когда вы переключаете раскладку талантов."
			L_DUAL_PROFILE = "Второй профиль"
			L_DUAL_PROFILE_DESC = "Выберите профиль, который необходимо активировать при переключениии талантов."
			L_ENABLED = "Включить двойной профиль"
			L_ENABLED_DESC = "Включите эту опцию для автоматического переключения между профилями при переключении раскладки талантов."
		elseif locale == "zhCN" then
			L_DUALSPEC_DESC = "启时，你可以为你的双天赋设定另一组配置文件，你的双重配置文件将在你转换天赋时自动与目前使用配置文件交换。"
			L_DUAL_PROFILE = "双重配置文件"
			L_DUAL_PROFILE_DESC = "选择转换天赋时所要使用的配置文件"
			L_ENABLED = "开启双重配置文件"
			L_ENABLED_DESC = "勾选以便转换天赋时自动交换配置文件。"
		elseif locale == "zhTW" then
			L_DUALSPEC_DESC = "啟用時，你可以為你的雙天賦設定另一組設定檔。你的雙設定檔將在你轉換天賦時自動與目前使用設定檔交換。"
			L_DUAL_PROFILE = "雙設定檔"
			L_DUAL_PROFILE_DESC = "選擇轉換天賦後所要使用的設定檔"
			L_ENABLED = "啟用雙設定檔"
			L_ENABLED_DESC = "勾選以在轉換天賦時自動交換設定檔"
		elseif locale == "esES" then
			L_DUALSPEC_DESC = "Si está activa, esta característica te permite seleccionar un perfil distinto para cada configuración de talentos. El perfil secundario será intercambiado por el activo cada vez que cambies de una configuración de talentos a otra."
			L_DUAL_PROFILE = "Perfil secundario"
			L_DUAL_PROFILE_DESC = "Elige el perfil secundario que se usará cuando cambies de talentos."
			L_ENABLED = "Activar perfil secundario"
			L_ENABLED_DESC = "Activa esta casilla para alternar automáticamente entre prefiles cuando cambies de talentos."
		end
	end


	local f = {		
		name = L['profiles'],
		order = 999999999999,
		expand = true,
		type = "group",
		args = {}
	}
	
	f.args.description1 = {
		type = "string",
		width = "full",
		name = L["intro"],
		order = 1,
		set = function() end,
		get = function() return L["intro"] end,
	
	}
	
	f.args.descreset = {
		order = 1.1,
		type = "string",
		width = "full",
		name = L["reset_desc"],
		set = function() end,
		get = function() return L["reset_desc"] end,
	}
	
	f.args.resetProfile = {					
		name = L["reset"],
		desc = L["reset_sub"],
		order = 1.2,
		type = "execute",
		set = function(self, value)
			AleaUI_GUI.ShowPopUp(
			   db, 
			   "Do you want to reset profile?", 
			   { name = "Yes", OnClick = function()
					local instance = db_variables[db]			
					local profileKey = instance._profileKey
					instance:Reset()
					instance:Fire(PROFILE_RESET)
					collectgarbage("collect"); 
				end},
			   { name = "No", OnClick = function() end}
			)
		end,
		get = function(self) 
			return false
		end,
	
	}

	
	f.args.current = {
		order = 1.3,
		type = "string",
		name = L["current"] .. " " .. NORMAL_FONT_COLOR_CODE .. "Default" .. FONT_COLOR_CODE_CLOSE,
		set = function() end,
		get = function()
			local instance = db_variables[db]			
			local profileKey = instance._profileKey
			
			return L["current"] .. " " .. NORMAL_FONT_COLOR_CODE .. profileKey .. FONT_COLOR_CODE_CLOSE end,
	}
	
	f.args.choosedesc = {
		order = 1.4, width = "full",
		type = "string",
		name = "\n" .. L["choose_desc"],
		set = function() end,
		get = function() return "\n" .. L["choose_desc"] end
	}
	
	f.args.createNew = {					
		name = L["new"],
		desc = L["new_sub"],
		order = 1.5,
		type = "editbox",
		set = function(self, value)
			if not _G[db].profiles[value] then
				_G[db].profiles[value] = {}
			end
		end,
		get = function(self) 
			return ''
		end,
	
	}
	
	f.args.defSpecchoose = {			
		name = L["choose"],
		desc = L["choose_sub"],
		order = 1.6,
		type = "dropdown", 
		values = GetProfileInterator(db, 1),
		set = function(self, value)
			ChangeProfile(db, 1, value)	
		end,
		get = function(self) 
			return _G[db].profileKeys[profileOwner][1]
		end,
	
	}
	
	f.args.copydesc = {
		order = 1.7, width = "full",
		type = "string",
		name = L_DUALSPEC_DESC,
		set = function() end,
		get = function() return L_DUALSPEC_DESC end
	}
	
	f.args.enableMultiSpecProfile = {
		name = L_ENABLED,
		desc = L_ENABLED_DESC,
		
		order = 1.8,
		type = "toggle",
		newLine = true,
		func = function(self) 
		
			_G[db][cvarSettings] = not _G[db][cvarSettings] 
			f.args.defSpecchoose.disabled = _G[db][cvarSettings];
			
			for i=1, GetNumSpecializations() do				
				f.args['spec'..i..'choose'].disabled = not _G[db][cvarSettings];
			end
			
			lastactivespec = -1
			
			RunSpecSwap()
		end,
		get = function(self) return _G[db][cvarSettings] end,
	}
	
	if ( not ns.isClassic ) then 
		if GetNumSpecializations() == 0 then
			local handler = CreateFrame('Frame')
			handler:RegisterEvent("PLAYER_TALENT_UPDATE")
			handler:RegisterEvent("PLAYER_LOGIN")
			handler:SetScript('OnEvent', function(self, event)
				unit = unit or 'player'
				if unit ~= 'player' then return end
				
				if GetNumSpecializations() == 0 then return end
				for i=1, GetNumSpecializations() do
					f.args['spec'..i..'choose'] = {
						name = (select(2, GetSpecializationInfo(i))),
						desc = L_DUAL_PROFILE_DESC,
						disabled = not _G[db][cvarSettings],
						order = 1.9+(0.01*i),
						type = "dropdown",
						values = GetProfileInterator(db, i),
						set = function(self, value)
							if _G[db][cvarSettings] then
								ChangeProfile(db, i, value)	
							end
						end,
						get = function(self) 
							return _G[db].profileKeys[profileOwner][i]
						end,
					}
				end

				f.args.defSpecchoose.disabled = _G[db][cvarSettings];

				handler:UnregisterAllEvents()
			end)
		else
			for i=1, GetNumSpecializations() do
				f.args['spec'..i..'choose'] = {
					name = (select(2, GetSpecializationInfo(i))),
					desc = L_DUAL_PROFILE_DESC,
					disabled = not _G[db][cvarSettings],
					order = 1.9+(0.01*i),
					type = "dropdown",
					values = GetProfileInterator(db, i),
					set = function(self, value)
						if _G[db][cvarSettings] then
							ChangeProfile(db, i, value)	
						end
					end,
					get = function(self) 
						return _G[db].profileKeys[profileOwner][i]
					end,
				}
			end
		
			f.args.defSpecchoose.disabled = _G[db][cvarSettings];
		end
	end
	
	f.args.copydesc = {
		order = 2, width = "full",
		type = "string",
		name = "\n"..L["copy_desc"],
		set = function() end,
		get = function() return "\n"..L["copy_desc"] end
	}
	
	f.args.copyProfile = {					
		name = L["copy"],
		desc = L["copy_desc"],
		order = 2.1,
		type = "dropdown",
		values = GetDeleteInterator(db),
		set = function(self, value)	
			AleaUI_GUI.ShowPopUp(
			   db, 
			   "Do you want to copy this profile to current one?", 
			   { name = "Yes", OnClick = function()
			   
					local instance = db_variables[db]			
					local profileKey = instance._profileKey
					
					_G[db].profiles[profileKey] = {}
					_G[db].profiles[profileKey] = deepcopy(_G[db].profiles[value])
	
					instance.workingcopy = {}
					
					instance:Refresh()
					
					instance:Fire(PROFILE_CHANGED)
					
					collectgarbage("collect"); 
				end},
			   { name = "No", OnClick = function() end}
			)
		end,
		get = function(self) 
			return ""
		end,
	
	}
	
	f.args.deletedesc = {
		order = 2.2, width = "full",
		type = "string",
		name = L["delete_desc"],
		set = function() end,
		get = function() return L["delete_desc"] end
	}
	
	f.args.delete = {					
		name = L["delete"],
		desc = L["delete_desc"],
		order = 2.3,
		type = "dropdown",
		values = GetDeleteInterator(db),
		set = function(self, value)	
			AleaUI_GUI.ShowPopUp(
			   db, 
			   "Do you want to delete profile?", 
			   { name = "Yes", OnClick = function()
					_G[db].profiles[value] = nil
					collectgarbage("collect"); 
				end},
			   { name = "No", OnClick = function() end}
			)
		end,
		get = function(self) 
			return ""
		end,
	
	}
	
	db_variables[db]._profileMethode = f
	
	return f
end





do
	local yOffset = -150
	local width = 290
	local height = 90
	
	local frames = {}
	
	local messageType = {
	
		[1] = "Error",
		[2] = "Attention",
	
	}
	
	local function UpdatePosition()
		local num = 0
		for i=1, #frames do		
			if not frames[i].free then
				num = num + 1
				frames[i]:SetPoint("TOP", UIParent, "TOP", 0, yOffset+((-height-2)*(num-1)))
			end
		end	
	end
	
	local function GetFrame()
		for i=1, #frames do		
			if frames[i].free then
				return frames[i]
			end
		end
		
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(width, height)
		f:SetPoint("TOP", UIParent, "TOP", 0, -50)
		f:SetFrameStrata("TOOLTIP")
		
		f.bg = CreateFrame("Frame", nil, f)
		f.bg:SetPoint("TOPLEFT", f, "TOPLEFT", -10, 10)
		f.bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 10, -10)
		f.bg:SetBackdrop({
			bgFile = [[Interface\Buttons\WHITE8x8]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			edgeSize = 22,
			insets = {
				left = 5,
				right = 5,
				top = 5,
				bottom = 5,
			}
		})
		f.bg:SetBackdropColor(0, 0, 0, 0.7)
		f.bg:SetBackdropBorderColor(1, 1, 1, 1)

		f.free = true
		
		f.text = f.bg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.text:SetJustifyV("TOP")
		f.text:SetWordWrap(true)
		f.text:SetJustifyH("CENTER")
		f.text:SetText("")
		f.text:SetPoint("TOP", f, "TOP", 0, -5)
		f.text:SetSize(width, height*0.6)
		f.text:SetTextColor(1, 1, 1)
		
		f.leftbutton = CreateFrame("Button", nil, f.bg, "UIPanelButtonTemplate")
		f.leftbutton:SetSize(80,20)
		f.leftbutton:SetFrameLevel(f.bg:GetFrameLevel()+3)
		f.leftbutton:EnableMouse(true)
		f.leftbutton:SetPoint("BOTTOM", f, "BOTTOM", -50, 10)
		f.leftbutton:SetScript("OnClick", function(self) 		
			if self._OnClick then
				self._OnClick()
			end
			self:GetParent():GetParent().free = true
			self:GetParent():GetParent():Hide()
			UpdatePosition()
		end)

		f.leftbutton.text = f.leftbutton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--	f.leftbutton.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		f.leftbutton.text:SetJustifyH("CENTER")
		f.leftbutton.text:SetText(NO)
		f.leftbutton.text:SetPoint("LEFT", f.leftbutton, "LEFT", 3 , 0)
		f.leftbutton.text:SetPoint("RIGHT", f.leftbutton, "RIGHT", -3 , 0)

		f.leftbutton:SetScript("OnMouseUp", function(self)
			self.text:SetPoint("LEFT", self, "LEFT", 3 , 0)
			self.text:SetPoint("RIGHT", self, "RIGHT", -3 , 0)
		end)

		f.leftbutton:SetScript("OnMouseDown", function(self)
			self.text:SetPoint("LEFT", self, "LEFT", 2 , -1)
			self.text:SetPoint("RIGHT", self, "RIGHT", -4 ,-1)
		end)

		f.rightbutton = CreateFrame("Button", nil, f.bg, "UIPanelButtonTemplate")
		f.rightbutton:SetSize(80,20)
		f.rightbutton:SetFrameLevel(f.bg:GetFrameLevel()+3)
		f.rightbutton:EnableMouse(true)
		f.rightbutton:SetPoint("BOTTOM", f, "BOTTOM", 50, 10)
		f.rightbutton:SetScript("OnClick", function(self) 
			if self._OnClick then
				self._OnClick()
			end
			self:GetParent():GetParent().free = true
			self:GetParent():GetParent():Hide()
			UpdatePosition()
		end)

		f.rightbutton.text = f.rightbutton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--		f.rightbutton.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		f.rightbutton.text:SetJustifyH("CENTER")
		f.rightbutton.text:SetText(NO)
		f.rightbutton.text:SetPoint("LEFT", f.rightbutton, "LEFT", 3 , 0)
		f.rightbutton.text:SetPoint("RIGHT", f.rightbutton, "RIGHT", -3 , 0)

		f.rightbutton:SetScript("OnMouseUp", function(self)
			self.text:SetPoint("LEFT", self, "LEFT", 3 , 0)
			self.text:SetPoint("RIGHT", self, "RIGHT", -3 , 0)
		end)

		f.rightbutton:SetScript("OnMouseDown", function(self)
			self.text:SetPoint("LEFT", self, "LEFT", 2 , -1)
			self.text:SetPoint("RIGHT", self, "RIGHT", -4 ,-1)
		end)

		
		frames[#frames+1] = f
		
		return frames[#frames]
	end
	
	ns.ShowPopUp = function(addon, message, leftbutton, rightbutton)
		
		local f = GetFrame()
		f.free = false
		f.text:SetText(addon..": "..message)
		
		
		if leftbutton then
			f.leftbutton:Show()		
			f.leftbutton.text:SetText(leftbutton.name)			
			f.leftbutton._OnClick = leftbutton.OnClick
		else
			f.leftbutton:Hide()
		end
		
		if rightbutton then
			f.rightbutton:Show()
			f.rightbutton.text:SetText(rightbutton.name)
			f.rightbutton._OnClick = rightbutton.OnClick
		else
			f.rightbutton:Hide()
		end
		
		f:Show()
		UpdatePosition()
	end
end

do
	local addon = 'ALEAGUIINFO'
	local command = '/aleaguiinfo'
	local elemets = { 'mainFrames', 'treeGroupFrames', 'treeGroupFramesElements', 'toggleBorders', 'executeFrames', 'toggleFrames', 'colorFrames', 'toggleDropdowns', 'editboxFrames', 'fontFrames', 'groupFrames','sliderFrames', 'soundFrames', 'toggleStatusBars', 'stringFrames' }
	local prots = ns.prototypes
	
	local func = function()
		old_print('--------------------------')
		old_print('----- AleaUI 1.0 -------')
		old_print('---- aleaaddons.ru ----')
		old_print('LibOwner:', libOwner)
		old_print('--------------------------')
		old_print('Usade in:')
		local i=1
		for addon in pairs(ns.RegisteredAddons) do
			old_print('  #'..i..". "..addon)
			i = i + 1
		end
		old_print('Amount elements:')
		for i, elem in pairs(elemets) do
			old_print('  #'..i..". "..elem..": "..#ns[elem])
		end
		old_print('Registered Prototypes:')
		i=1
		for prototopes, methode in pairs(prots) do
			old_print('  #'..i..". "..prototopes..": "..methode)
			i = i + 1
		end
	end
	
	ns.SlashCommand(addon, command, func)
end