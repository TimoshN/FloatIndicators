local addonName, ns = ...

if FloatIndicators then
	return
end

local IsAddonMessagePrefixRegistered = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered or IsAddonMessagePrefixRegistered
local RegisterAddonMessagePrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local defaults

local version = '131'
local IsItemInRange = IsItemInRange
local UnitAura = UnitAura
local select = select
local pairs = pairs
local CheckInteractDistance = CheckInteractDistance
local UnitInRange = UnitInRange

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true) or false

ns.AddOnVer = version

_G[addonName] = ns
FIALEA = true

ns[433+349] = 1
ns[501+234] = 1

ns.encounterData = {}
ns.forbFrames = {}
ns.secureFrames = {}
ns.fts = {}
ns.forbUnits = {}
ns.nameplateUnits = {}

local forbFrames = ns.forbFrames
local secureFrames = ns.secureFrames
local forbiddenToSecure = ns.fts

local parent = CreateFrame('Frame', addonName..'Parent', WorldFrame)
	parent:SetFrameLevel(0)
	parent:SetPoint('TOPLEFT', WorldFrame, 'TOPLEFT')
	parent:SetPoint('BOTTOMRIGHT', WorldFrame, 'BOTTOMRIGHT')
	parent:SetSize(1,1)	
	parent:SetFrameStrata('BACKGROUND')

local playerFrame = CreateFrame('Frame', addonName..'PlayerFrame', WorldFrame)
	playerFrame:SetPoint('CENTER', WorldFrame, 'CENTER', 0, -10)
	playerFrame:SetSize(1,1)
	playerFrame.offsetY = 0
	playerFrame.isPlayerFrame = true
	 
local FORBIDDEN_NAMEPLATES = false
local DISABLE_DRAW = false
local GLOBAL_ALPHA = 0.5

local selectedspell
local lastZoneWarning

local bubblePointer = {}

local guidToObj = {}
local objToGuid = {}

local forbUnits = ns.forbUnits
local showAnchors = false

local function RGBToHex(...)	
	return format("|cff%02x%02x%02x", select(1, ...))
end

local function GlobalScale(size)
	size = size or 1
	return size * UIParent:GetEffectiveScale() * ( ns.db and ns.db.scale or 1 )
end

function ns.DefaultsReady()end

local raidIndexCoord = {
	[1] = { 0, .25, 0, .25 }, --[==[STAR  ]==]
	[2] = { .25, .5, 0, .25}, --[==[MOON  ]==]
	[3] = { .5, .75, 0, .25}, --[==[ CIRCLE  ]==]
	[4] = { .75, 1, 0, .25}, --[==[ SQUARE  ]==]
	[5] = { 0, .25, .25, .5}, --[==[ DIAMOND  ]==]
	[6] = { .25, .5, .25, .5}, --[==[ CROSS  ]==]
	[7] = { .5, .75, .25, .5}, --[==[ TRIANGLE  ]==]
	[8] = { .75, 1, .25, .5}, --[==[  SKULL  ]==]
}

local defaultSpells1 = {
	205649,
	206589,
	209011,
	212587,
	209244,
	206936, 
	206847,
}

local defaultSpells2 = {
	206384,
	214167,
	212647,
	206617,
	206480,
	218809,
}

local defaultSpells3 = {
	218304,
	224632,
	218342,
	225105,
	213166,
}


local specific_defaultSpellsOpts = {
--[==[	[12292]  = { show = 4, spellID = 12292,  checkID = true, size = 1.5, filter = 2, },]==]
}



local FontList = {
	["Default"] = STANDARD_TEXT_FONT,
	["Arial"] = "Fonts\\ARIALN.TTF",
	["Skurri"] = "Fonts\\skurri.ttf",
	["Morpheus"] = "Fonts\\MORPHEUS.ttf",
}

function ns:GetFontList()		
	return LSM and LSM:HashTable("font") or FontList
end	

function ns:GetFont(value)
	return LSM and LSM:Fetch("font",value) or FontList[value] or STANDARD_TEXT_FONT
end

local spellstringcache = {}

function ns:SpellString(spellid)
	if not spellstringcache[spellid] then
		local name, _, icon = GetSpellInfo(spellid)
		spellstringcache[spellid] = "\124T"..icon..":10\124t "..name
	end
	
	return spellstringcache[spellid]
end

function ns.GuidToID(guid)	
	if not guid then 
		return 0 
	else
		local id = guid:match("[^%-]+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%w+")
		return tonumber(id or 0)
	end
end

local function IsMelee()
	local _,class = UnitClass('player')
	local isMelee = (class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or class == "DEMONHUNTER")
	if class == "SHAMAN" then
		if GetSpecialization() == 2 then
			isMelee = true
		else
			isMelee = false
		end
	elseif class == "HUNTER" then
		isMelee = GetSpecialization() == 3
	elseif class == "DRUID" then
		if GetSpecialization() == 2 or GetSpecialization() == 3 then
			isMelee = true
		else
			isMelee = false
		end
	end

	return isMelee
end
ns.IsMelee = IsMelee

local _debug = debug
local _print = print
local debug = function()end
local print = function()end

local BossPositionFix = {}

function ns.AddBossPositionFix(id, value)

	if BossPositionFix[id] then
		_print('ns.AddBossPositionFix - id already exists', id)
		return
	end
	
	BossPositionFix[id] = value
end

local activeEncounter = nil

local function OC(spellID)
	if not activeEncounter then return false end
	
	if ns.db.encounters[activeEncounter] then
		if ns.db.encounters[activeEncounter][spellID] then		
			return ns.db.encounters[activeEncounter][spellID]['circle'].enable
		end	
	end
	
	return false
end

local function OL(spellID)
	if not activeEncounter then return false end
	
	if ns.db.encounters[activeEncounter] then
		if ns.db.encounters[activeEncounter][spellID] then		
			return ns.db.encounters[activeEncounter][spellID]['lines'].enable
		end
	end
	
	return false
end

local function RC(spellID)
	if not activeEncounter then return false end
	
	if ns.db.encounters[activeEncounter] then
		if ns.db.encounters[activeEncounter][spellID] then		
			return ns.db.encounters[activeEncounter][spellID]['range'].enable
		end
	end
	
	return false
end

ns.OL = OL
ns.OC = OC
ns.RC = RC

local sharedColors = {
	[1] = {0,1,0},								--[==[Green]==]
	[2] = {1,1,0},								--[==[Yellow]==]
	[3] = {1,0,0},								--[==[Red]==]
	[4] = {0,0,1},								--[==[Blue]==]
	[5] = {0,0,0,circleAplha=.6},				--[==[Black]==]
	[6] = {0,1,1},								--[==[Blue Light]==]
	[7] = {1,.5,0},								--[==[Orange]==]
	[8] = {1,0,1},								--[==[Pink]==]
	[9] = {.5,0,1,circleAplha=.4},				--[==[Purple]==]
	[10] = {.4,.9,0,circleAplha=.4},			--[==[Dark green]==]
	[11] = {1,1,1},								--[==[White]==]
	[12] = {1,1,1,lineAlpha=.4,circleAplha=.4},	--[==[White Trans]==]
	[13] = {.4,.4,.4},							--[==[Grey]==]
	[14] = {1,0,0,circleAplha=.5},				--[==[Red Copy (range check)]==]
	[15] = {1,1,.15,circleAplha=.5},			--[==[Yellow Copy (range check)]==]
	[16] = {1,.4,.4},							--[==[Red Light]==]
	[17] = {.72,1,.22},							--[==[Light Green]==]
	[18] = {.5,.15,.15},						--[==[Dark Red]==]
	[19] = {.15,.5,.15},						--[==[Dark Green]==]
}

function ns:UpdateDraw(guid)		
	if guidToObj[guid] then		
		ns.DrawCircleForOwner(guid)
		ns.DrawCircleSpinner(guid)		
		ns.UpdateLinesDraw()
	else
		ns.HideCircleForOwner(guid)
		ns.HideCircleSpinner(guid)
	end
end

local CheckerHandlerFunc = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	
	if self.elapsed < 0.1 then 
		return
	end
	
	self.elapsed = 0

	if UnitGUID('player') then
		guidToObj[UnitGUID('player')] = playerFrame		
	end
end

local CheckerHandler = CreateFrame('Frame')
CheckerHandler:Show()
CheckerHandler.elapsed = 0
CheckerHandler:SetScript('OnUpdate', CheckerHandlerFunc)

local function ResetCheckerTimer()
	CheckerHandlerFunc(CheckerHandler, 1)
	CheckerHandler:Show()	
end


ns.testFramePosition = true
ns.TEST_POS = {}
ns.TEST_POS_MAP = {}
ns.TEST_POS_FRAME = CreateFrame('Frame')
ns.TEST_POS_FRAME:SetScript('OnUpdate', function(self, elapsed)
	self.elapsed = (self.elapsed or 0 ) + elapsed
	
	if self.elapsed < 0.01 then
		return
	end
	
	self.elapsed = 0

	for i=1, #ns.TEST_POS_MAP do
		local v = ns.TEST_POS_MAP[i]
		
		if v.change then
			v.change = false
			v.fr:SetPoint('CENTER',WorldFrame,'BOTTOMLEFT',v.x, v.y+v.offset)
		end
	end
end)

if ( ns.testFramePosition ) then
	ns.TEST_POS_FRAME:Show()
else
	ns.TEST_POS_FRAME:Hide()
end

local function PlatePosition(self,x,y)
	if ( ns.testFramePosition ) then
		if not ns.TEST_POS[self.f] then
			local index = #ns.TEST_POS_MAP+1
			ns.TEST_POS[self.f] = index	
			ns.TEST_POS_MAP[index] = { fr = self.f}
		end
		local sett = ns.TEST_POS_MAP[ns.TEST_POS[self.f]]
		
		sett.change = true
		sett.x = x
		sett.y = y
		sett.offset = -20
	else
		self.f:SetPoint('CENTER',WorldFrame,'BOTTOMLEFT',x,y-20)
	end
end
ns.PlatePosition = PlatePosition

local function RemoveObjForGUID(guid, obj, reason)

	if obj then
		for guid1, obj1 in pairs(guidToObj) do
			if obj1 == obj then
				guidToObj[guid1] = false
			end
		end
	end
	
	if guid then
		if guid == UnitGUID('player') then
			guidToObj[guid] = playerFrame
		else
			guidToObj[guid] = false
		end
	end
	
	if obj and obj.IsNameplate then
		ns:UpdateDraw(obj.guid)
	end

	ResetCheckerTimer()
end

local function AddObjForGUID(guid, obj)
	RemoveObjForGUID(guid, obj, 'AddObjForGUID')
	
	if guid == UnitGUID('player') then
		guidToObj[guid] = playerFrame
	else
		guidToObj[guid] = obj
	end
	
	
	ResetCheckerTimer()
end

local pH = CreateFrame('Frame')	
pH:RegisterEvent("NAME_PLATE_UNIT_ADDED")
pH:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
pH:RegisterEvent("NAME_PLATE_CREATED")
pH:SetScript('OnEvent', function(self, event, unit)

	if event == 'NAME_PLATE_UNIT_ADDED' then
		local realFrame = C_NamePlate.GetNamePlateForUnit(unit)
		
		if realFrame then	
			realFrame.FIPlate.unit = unit
			realFrame.FIPlate.guid = UnitGUID(unit)
			realFrame.FIPlate.modID = ns.GuidToID(realFrame.FIPlate.guid)
			realFrame.FIPlate.offsetY = BossPositionFix[realFrame.FIPlate.modID] or 0
			realFrame.FIPlate:Show()	
			
			realFrame.FIPlate:SetPoint('BOTTOM',realFrame, 'BOTTOM', 0, -20)
			
			guidToObj[realFrame.FIPlate.guid] = realFrame.FIPlate
			ns:UpdateDraw(realFrame.FIPlate.guid)
		end
	elseif event == 'NAME_PLATE_UNIT_REMOVED' then
		local realFrame = C_NamePlate.GetNamePlateForUnit(unit)
		
		if realFrame then
			realFrame.FIPlate.unit = nil
			realFrame.FIPlate.guid = nil
			realFrame.FIPlate.modID = nil
			realFrame.FIPlate.offsetY = 0
			realFrame.FIPlate:Hide()	

			guidToObj[UnitGUID(unit)] = nil
			ns:UpdateDraw(UnitGUID(unit))
		end
	elseif event == 'NAME_PLATE_CREATED' then
		
		local plate = CreateFrame('Frame', nil, parent)
		plate:SetSize(1,1)
		plate:Hide()
		
		if showAnchors then
			local bg = plate:CreateTexture()
			bg:SetPoint('CENTER')
			bg:SetSize(10, 10)
			bg:SetColorTexture(1, 1, 0, 0.5)
		end
		
		plate.offsetY = 0
		
		--[==[
		local positioner = CreateFrame('Frame', nil,plate)
		positioner:SetPoint('BOTTOMLEFT',WorldFrame)
		positioner:SetPoint('TOPRIGHT',unit,'CENTER')
		positioner:SetScript('OnSizeChanged',PlatePosition)
		positioner.f = plate
		]==]
		
		plate.owner = unit
		plate.IsNameplate = true
		unit.FIPlate = plate
	end
end)
do
	local rangeCheckFrame = CreateFrame'Frame'
	local minRange = 5
	local nextRange = 8
		
	local existedRanges = {5,8,10,13,18,22,30,43,50,60,80,1000}
	
	local rangeCircleList = {}
	local tmr = 0
	local function rangeCheckFrameUpdate(self,elapsed)
		tmr = tmr + elapsed
		if tmr > 0.1 then
			tmr = 0
			
			for i=1, GetNumGroupMembers() do
				local uId = 'raid'..i
				local guid = UnitGUID(uId)

				if not UnitIsUnit(uId, "player") and UnitIsFriend(uId, "player") then
					local range
					if IsItemInRange(37727, uId) then range = 5
					elseif IsItemInRange(63427, uId) then range = 8
					elseif CheckInteractDistance(uId, 3) then range = 10
					elseif CheckInteractDistance(uId, 2) then range = 11
					elseif IsItemInRange(32321, uId) then range = 13
					elseif IsItemInRange(6450, uId) then range = 18
					elseif IsItemInRange(21519, uId) then range = 22
					elseif CheckInteractDistance(uId, 1) then range = 30
					elseif UnitInRange(uId) then range = 43
					elseif IsItemInRange(116139, uId)  then range = 50
					elseif IsItemInRange(32825, uId) then range = 60
					elseif IsItemInRange(35278, uId) then range = 80
					else range = 1000 end
					
					local existedColor = rangeCircleList[guid]
					if range <= minRange and existedColor ~= 14 then
						if existedColor then
							ns.HideCircle(guid, 'rangeCheck')
						end
						rangeCircleList[guid] = 14
						ns.SetCircle(guid, 'rangeCheck', 14, 70)	
					elseif range > minRange and range <= nextRange and existedColor ~= 15 then
						if existedColor then
							ns.HideCircle(guid, 'rangeCheck')
						end
						rangeCircleList[guid] = 15	
						ns.SetCircle(guid, 'rangeCheck', 15, 70)	
					elseif range > nextRange and existedColor then
						ns.HideCircle(guid, 'rangeCheck')
						rangeCircleList[guid] = nil
					end
				end
			end

		end
	end
	function ns.RangeCheck_Remove(guid)
		local existedColor = rangeCircleList[guid]
		if existedColor then
			ns.HideCircle(guid, 'rangeCheck')
			rangeCircleList[guid] = nil
		end
	end
	function ns.RangeCheck_Update(range)
		if not range then
			rangeCheckFrame:SetScript("OnUpdate",nil)
			for guid,color in pairs(rangeCircleList) do
				ns.HideCircle(guid, 'rangeCheck')
			end
			wipe(rangeCircleList)
		else
			range = min(range,999)
			for i=2,#existedRanges do
				if existedRanges[i] > range then
					minRange = existedRanges[i-1]
					nextRange = existedRanges[i] or 1000
					break
				end
			end
			tmr = 1
			rangeCheckFrame:SetScript("OnUpdate",rangeCheckFrameUpdate)
			return minRange
		end
	end
end
local UnitName = UnitName

local name = UnitName("player")
local server = GetRealmName()		
local fullName = name..'-'..server:gsub(' ', '')

function FI_Start()end
function FI_End()end

do
	local lines = {}
	local ActiveLines = {}

	local lineTypeToTexture = {
		[1] = [[Interface\AddOns\]]..addonName..[[\LineTemplate.tga]],
		[2] = "Interface/Artifacts/_Artifacts-DependencyBar-Fill",
	}
	
	local function FindActive(from, to, tag)		
		if ActiveLines[from] and ActiveLines[from][to] and ActiveLines[from][to][tag] then
			return ActiveLines[from][to][tag]
		end
		if ActiveLines[to] and ActiveLines[to][from] and ActiveLines[to][from][tag] then
			return ActiveLines[to][from][tag]
		end	
	end
	
	local function BossOffset(unit, pos)	
		if IsItemInRange(37727, unit) then
			pos = pos * 2
		elseif IsItemInRange(63427, unit) then
			pos = pos * 1.84
		elseif IsItemInRange(33278, unit) then
			pos = pos * 1.68
		elseif IsItemInRange(32321, unit) then
			pos = pos * 1.56
		elseif IsItemInRange(133940, unit) or IsItemInRange(115533, unit) then
			pos = pos * 1.25
		elseif IsItemInRange(21519, unit) or IsItemInRange(39664, unit) then
	
		elseif IsItemInRange(31463, unit) then
			pos = pos / 1.2
		elseif IsItemInRange(34191, unit) then
			pos = pos / 1.3
		elseif IsItemInRange(18904, unit) then	
			pos = pos / 1.35
		elseif IsItemInRange(32698, unit) then
			pos = pos / 1.5
		elseif IsItemInRange(32825, unit) then
			pos = pos / 1.65
		elseif IsItemInRange(41265, unit) then
			pos = pos / 1.8
		elseif IsItemInRange(35278, unit) then
			pos = pos / 2
		else
			pos = pos / 2.5
		end
		
		return pos
	end
	
	local function SetCustomOffset(self, offsetFrom, offsetTo)
		self.customOffsetFrom = offsetFrom
		self.customOffsetTo = offsetTo
		
		self._fromObjOffsetY = nil
		self._toObjOffsetY = nil
	end
	
	function ns.AddLine(from,to,tag,colorType,lineType,offsetFrom,offsetTo, size, alpha)		
		if not ns.db.enableDraw then return end
		
		local currLine = FindActive(from, to, tag)
		if not currLine then
			for i=1, #lines do
				if lines[i].free then
					currLine = lines[i]
					break
				end
			end
		end
		
		if not currLine then
			currLine = CreateFrame("Frame",nil,parent)
			currLine:SetPoint("TOPLEFT")
			currLine:SetSize(1,1)
			
			currLine.Fill1 = currLine:CreateLine(nil, "BACKGROUND", nil, -5)
			currLine.Fill1:SetTexture([[Interface\AddOns\]]..addonName..[[\LineTemplate.tga]])

			currLine.Point1 = currLine:CreateTexture()
			currLine.Point1:SetSize(1,1)
			currLine.Point2 = currLine:CreateTexture()
			currLine.Point2:SetSize(1,1)
			
			lines[#lines + 1] = currLine
			
			currLine.Free = function(self)
				self:Hide()
				self.Fill1:Hide()
				self.tag = nil
				self.from = nil
				self.to = nil
				self.free = true
				
				if self._fromObj then self._fromObj.haveLine = false end 
				if self._toObj then self._toObj.haveLine = false end  
				ns.UpdateNameVisability(self._fromObj) 
				ns.UpdateNameVisability(self._toObj)
				
				self._fromObj = nil
				self._fromObjOffsetY = nil
				self._toObj = nil
				self._toObjOffsetY = nil
			end
			
			currLine.SetCustomOffset = SetCustomOffset
			
			currLine.SetPosition = function(self)
				
				local from, to = self.from, self.to
				
				if ( not from or not to ) then
					if self._fromObj then self._fromObj.haveLine = false end 
					if self._toObj then self._toObj.haveLine = false end  
					
					ns.UpdateNameVisability(self._fromObj) 
					ns.UpdateNameVisability(self._toObj)  
		
					self._fromObj = nil
					self._fromObjOffsetY = nil
					self._toObj = nil
					self._toObjOffsetY = nil
					
					self:Hide()
					return false
				end
				
				local fromObj, toObj = guidToObj[from],guidToObj[to]
				
				if ( not fromObj or not toObj ) then
					if self._fromObj then self._fromObj.haveLine = false end 
					if self._toObj then self._toObj.haveLine = false end  
					ns.UpdateNameVisability(self._fromObj) 
					ns.UpdateNameVisability(self._toObj) 
			
					self._fromObj = nil
					self._fromObjOffsetY = nil
					self._toObj = nil
					self._toObjOffsetY = nil
					
					self:Hide()
					return false
				end
				
				if not self:IsShown() then
					self:Show()
				end
				
				local fromObjOffsetY = fromObj.offsetY
				local toObjOffsetY = toObj.offsetY
			
				if fromObjOffsetY > 0 then
					fromObjOffsetY = BossOffset(fromObj.unit, fromObjOffsetY)
				end
				if toObjOffsetY > 0 then
					toObjOffsetY = BossOffset(toObj.unit, toObjOffsetY)
				end
				
				if self._fromObj ~= fromObj or self._fromObjOffsetY ~= fromObjOffsetY then
					self._fromObj = fromObj
					self._fromObjOffsetY = fromObjOffsetY
					
					if self._fromObj then self._fromObj.haveLine = true end  
					ns.UpdateNameVisability(self._fromObj)  
				
					self.Fill1:SetStartPoint("CENTER",fromObj, 0, -fromObjOffsetY+self.customOffsetFrom)
					self.Point1:SetPoint("CENTER",fromObj, 0, -fromObjOffsetY+self.customOffsetFrom)
				end
				
				if self._toObj ~= toObj or self._toObjOffsetY~= toObjOffsetY then
					self._toObj = toObj
					self._toObjOffsetY = toObjOffsetY
					
					if self._toObj then self._toObj.haveLine = true end  
					ns.UpdateNameVisability(self._toObj)  
				
					self.Fill1:SetEndPoint("CENTER",toObj, 0, -toObjOffsetY+self.customOffsetTo)
					self.Point2:SetPoint("CENTER",toObj, 0, -toObjOffsetY+self.customOffsetTo)
				end
				
				return true
			end
		end
		
		currLine.free = false

		currLine.customOffsetFrom = offsetFrom or 0
		currLine.customOffsetTo = offsetTo or 0
		
		currLine.Point1:ClearAllPoints()
		currLine.Point2:ClearAllPoints()

		currLine.Fill1:SetTexture(lineTypeToTexture[lineType] or lineTypeToTexture[1])
		
		local colorsPack = sharedColors[colorType or 1]
		currLine.Fill1:SetVertexColor(colorsPack[1],colorsPack[2],colorsPack[3])
		currLine.Fill1:SetAlpha(alpha or colorsPack.lineAlpha or ns.db.alpha)
		currLine.Fill1:SetThickness( floor( ( ( size or 10 )*GlobalScale())+0.5 ) )
		currLine:Show()
		currLine.Fill1:Show()

		ActiveLines[from] = ActiveLines[from] or {}
		ActiveLines[from][to] = ActiveLines[from][to] or {}
		ActiveLines[from][to][tag] = currLine
		
		currLine.from = from
		currLine.to = to
		currLine.tag = tag
		
		ns.UpdateLinesDraw()
	end
	function ns.RemoveLine(from,to,tag)
		local line = FindActive(from,to,tag)		
		
		if line then
			line:Free()			
			ActiveLines[from][to][tag] = nil
		end
	end
	
	function ns.RemoveLineByTag(tag)	
		if tag then		
			for i=1, #lines do				
				local line = lines[i]
				
				if line.free == false and line.tag == tag then
					ActiveLines[line.from][line.to][line.tag] = nil
					line:Free()
				end
			end
		end
	end
	
	local lineDrawUpdater = CreateFrame("Frame")
	lineDrawUpdater:SetScript('OnUpdate', function(self, elapsed)
		local hide = true
		for i=1, #lines do
			local line = lines[i]
			
			if line.free == false then
				if line:SetPosition() then
					hide = false
				end
			elseif line:IsShown() then
				line:Hide()
			end		
		end
		
		if hide then
			self:Hide()
		end
	end)
	
	function ns.UpdateLinesDraw()
		lineDrawUpdater:Show()
	end
	
	function ns.FreeAllLines()
		for i=1, #lines do
			lines[i]:Free()
		end
		
		wipe(ActiveLines)
	end
end

do 
	function ns.GetInit()
		return ns[658+124] or tonumber(string.match((debugstack(1, 1, 1)), 'core.lua:(%d-):') ) 
	end 
end

do
	local cos, sin, pi2, halfpi = math.cos, math.sin, math.rad(360), math.rad(90)
	local function Transform(tx, x, y, angle, aspect)
	    local c, s = cos(angle), sin(angle)
	    local y, oy = y / aspect, 0.5 / aspect
	    local ULx, ULy = 0.5 + (x - 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x - 0.5) * s) * aspect
	    local LLx, LLy = 0.5 + (x - 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x - 0.5) * s) * aspect
	    local URx, URy = 0.5 + (x + 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x + 0.5) * s) * aspect
	    local LRx, LRy = 0.5 + (x + 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x + 0.5) * s) * aspect
	    tx:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
	end
	
	local function OnPlayUpdate(self)
	    self:SetScript('OnUpdate', nil)
	    self:Pause()
	end
	
	local function OnPlay(self)
	    self:SetScript('OnUpdate', OnPlayUpdate)
	end
	
	local function SetValue(self, value)
	    if value > 1 then value = 1
	    elseif value < 0 then value = 0 end

	    if self._reverse then
	        value = 1 - value
	    end
	
	    local q, quadrant = self._clockwise and (1 - value) or value
	    if q >= 0.75 then
	        quadrant = 1
	    elseif q >= 0.5 then
	        quadrant = 2
	    elseif q >= 0.25 then
	        quadrant = 3
	    else
	        quadrant = 4
	    end
	
	    if self._quadrant ~= quadrant then
	        self._quadrant = quadrant
	        if self._clockwise then
	            for i = 1, 4 do
	                self._textures[i]:SetShown(i < quadrant)
	            end
	        else
	            for i = 1, 4 do
	                self._textures[i]:SetShown(i > quadrant)
	            end
	        end

	        self._scrollframe:Hide()
	        self._scrollframe:SetAllPoints(self._textures[quadrant])
	        self._scrollframe:Show()
	    end

	    local rads = value * pi2
	    if not self._clockwise then rads = -rads + halfpi end
	    Transform(self._wedge, -0.5, -0.5, rads, self._aspect)
	    self._rotation:SetDuration(0.000001)
	    self._rotation:SetEndDelay(2147483647)
	    self._rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	    self._rotation:SetRadians(-rads)
	    self._group:Play()
	end
	
	local function SetClockwise(self, clockwise)
	    self._clockwise = clockwise
	end
	
	local function SetReverse(self, reverse)
	    self._reverse = reverse
	end
	
	local function OnSizeChanged(self, width, height)
	    self._wedge:SetSize(width, height) 
	    self._aspect = width / height
	end
	
	local function CreateTextureFunction(func, self, ...)
	    return function(self, ...)
	        for i = 1, 4 do
	            local tx = self._textures[i]
	            tx[func](tx, ...)
	        end
	        self._wedge[func](self._wedge, ...)
	    end
	end
	
	local TextureFunctions = {
	    SetTexture = CreateTextureFunction('SetTexture'),
	    SetBlendMode = CreateTextureFunction('SetBlendMode'),
	    SetVertexColor = CreateTextureFunction('SetVertexColor'),
	}
	
	local function CreateSpinner(parent)
	    local spinner = CreateFrame('Frame', nil, parent)
	
	    local scrollframe = CreateFrame('ScrollFrame', nil, spinner)
	    scrollframe:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
	    scrollframe:SetPoint('TOPRIGHT')
	    spinner._scrollframe = scrollframe
	
	    local scrollchild = CreateFrame('frame', nil, scrollframe)
	    scrollframe:SetScrollChild(scrollchild)
	    scrollchild:SetAllPoints(scrollframe)
	
	    local wedge = scrollchild:CreateTexture(nil, "BACKGROUND", nil, -3)
	    wedge:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
	    spinner._wedge = wedge
	
	    local trTexture = spinner:CreateTexture(nil, "BACKGROUND", nil, -3)
	    trTexture:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
	    trTexture:SetPoint('TOPRIGHT')
	    trTexture:SetTexCoord(0.5, 1, 0, 0.5)
	
	    local brTexture = spinner:CreateTexture(nil, "BACKGROUND", nil, -3)
	    brTexture:SetPoint('TOPLEFT', spinner, 'CENTER')
	    brTexture:SetPoint('BOTTOMRIGHT')
	    brTexture:SetTexCoord(0.5, 1, 0.5, 1)
	
	    local blTexture = spinner:CreateTexture(nil, "BACKGROUND", nil, -3)
	    blTexture:SetPoint('TOPRIGHT', spinner, 'CENTER')
	    blTexture:SetPoint('BOTTOMLEFT')
	    blTexture:SetTexCoord(0, 0.5, 0.5, 1)
	
	    local tlTexture = spinner:CreateTexture(nil, "BACKGROUND", nil, -3)
	    tlTexture:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
	    tlTexture:SetPoint('TOPLEFT')
	    tlTexture:SetTexCoord(0, 0.5, 0, 0.5)
	
	    spinner._textures = {trTexture, brTexture, blTexture, tlTexture}
	    spinner._quadrant = nil
	    spinner._clockwise = true
	    spinner._reverse = false
	    spinner._aspect = 1
	    spinner:HookScript('OnSizeChanged', OnSizeChanged)
	    
	    for method, func in pairs(TextureFunctions) do
	        spinner[method] = func
	    end
	
	    spinner.SetClockwise = SetClockwise
	    spinner.SetReverse = SetReverse
	    spinner.SetValue = SetValue
	
	    local group = wedge:CreateAnimationGroup()
	    group:SetScript('OnFinished', function() group:Play() end)
	    local rotation = group:CreateAnimation('Rotation')
	    spinner._rotation = rotation
	    spinner._group = group
	    return spinner
	end



	local circles = {}
	local ActiveCircles = {}
	
	local function FindActive(owner, tag)		
		if ActiveCircles[owner] then
			if ActiveCircles[owner][tag] then
				return ActiveCircles[owner][tag]
			end
		end
	end
	
	local function SetCustomOffset(self, offset)
		self.customOffset = offset
		self.offsetY = nil
		
		if self.owner and guidToObj[self.owner] then
			self:SetPosition(guidToObj[self.owner])
		end
	end
	
	function ns.AddSpinner(owner,tag,color,timer,size,offset,alpha,text,textSize)
	
		if not ns.db.enableDraw then return end
		
		local currCircle = FindActive(owner, tag)

		if not currCircle then
			for i=1, #circles do
				if circles[i].free then
					currCircle = circles[i]
					break
				end
			end
		end

		if not currCircle then

			currCircle = CreateFrame("Frame",nil,parent)
			currCircle:SetFrameLevel(1)
			currCircle:SetSize(1,1)
			currCircle:Hide()
			
			currCircle.free = false
			
			currCircle.Text = currCircle:CreateFontString(nil, 'BACKGROUND', nil, -5)
			currCircle.Text:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
			currCircle.Text:SetPoint('CENTER', currCircle, 'CENTER', 0, 0)
			currCircle.Text:SetText('')

			currCircle.Circle = currCircle:CreateTexture(nil, "BACKGROUND", nil, -6)
			currCircle.Circle:SetTexture("Interface\\AddOns\\"..addonName.."\\circle512")
			currCircle.Circle:SetVertexColor(1,0,0,.3)
			currCircle.Circle:SetPoint('CENTER', currCircle, 'CENTER', 0, 0)
			
			currCircle.Spinner = CreateSpinner(currCircle)
			currCircle.Spinner:SetFrameStrata("BACKGROUND")
			currCircle.Spinner:SetPoint('CENTER', currCircle.Circle)
			currCircle.Spinner:SetTexture([[Interface\AddOns\]].. addonName ..[[\ring512]])
			currCircle.Spinner:SetVertexColor(1,0,0,.3)
			
			currCircle.Spinner:SetClockwise(true)
			currCircle.Spinner:SetReverse(false)
			
			currCircle.Timer = CreateFrame("Frame")
			currCircle.Timer.t = 0
			currCircle.Timer.d = 1
			currCircle.Timer:SetScript('OnUpdate', function(self, elapsed)				
				local value = (self.t - GetTime()) / self.d
				if value < 0 then
					value = 0
				end
				currCircle.Spinner:SetValue(value)
			end)
		
			currCircle.SetCustomOffset = SetCustomOffset
			
			currCircle.Free = function(self)
				self.free = true	
				self:Hide()
				self.Circle:Hide()
				self.Timer:Hide()
				self.Spinner:Hide()
		
				if self.obj then self.obj.haveCircle = false end  
				ns.UpdateNameVisability(self.obj)  
					
				self.owner = nil		
				self.obj = nil
				self.offsetY = nil
			end
			
			currCircle.ScaleUpdate = function(self)		
				local scale = GlobalScale()
				local size = self.size*scale	
				local spinnerSize = size + size * 72 / 512
				self.Circle:SetSize(size,size)
				self.Spinner:SetSize(spinnerSize,spinnerSize)
			end
			
			currCircle.SetPosition = function(self, obj)
				if not self:IsShown() then
					self:Show()
				end
				
				if self.obj ~= obj or self.offsetY ~= obj.offsetY then
					self.obj = obj
					self.offsetY = obj.offsetY
					
					if self.obj then self.obj.haveCircle = true end  
					ns.UpdateNameVisability(self.obj) 
							
					self:SetPoint('CENTER', obj, 'CENTER', 0, -obj.offsetY+self.customOffset)
				end	
			end
			
			currCircle.id = #circles+1
			
			circles[currCircle.id] = currCircle
		end
		
		local colorData = sharedColors[color or 1]
		currCircle.Circle:SetVertexColor(colorData[1],colorData[2],colorData[3], alpha or ns.db.alpha)
		currCircle.Spinner:SetVertexColor(colorData[1],colorData[2],colorData[3],min((colorData.circleAplha or .3)+.5,1))
		
		currCircle.owner = owner
		currCircle.size = size or 60
		
		currCircle.customOffset = offset or 0
		
		currCircle:ScaleUpdate()
		
		currCircle.Circle:Show()
		if timer and not ns.db.disableSpinner then
			currCircle.Timer.t = timer[1] + timer[2]
			currCircle.Timer.d = timer[2]
			local value = (timer[1] + timer[2] - GetTime()) / timer[2]
			if value < 0 then
				value = 0
			end
			currCircle.Spinner:SetValue(value)
			currCircle.Spinner:Show()
			currCircle.Timer:Show()
		else
			currCircle.Spinner:Hide()
			currCircle.Timer:Hide()
		end
		
		currCircle.Text:SetFont(STANDARD_TEXT_FONT, textSize or 12, 'OUTLINE')
		currCircle.Text:SetText(text or '')

		currCircle.free = false
		
		ActiveCircles[owner] = ActiveCircles[owner] or {}
		ActiveCircles[owner][tag] = currCircle
		
		if guidToObj[owner] then
			currCircle:SetPosition(guidToObj[owner])
		end		

		return currCircle
	end
	function ns.RemoveSpinner(owner,tag)
		local circles = ActiveCircles[owner]
		if not circles then
			return
		end
		if tag then
			if ActiveCircles[owner][tag] then
				ActiveCircles[owner][tag]:Free()
				ActiveCircles[owner][tag] = nil
			end
		else
			for tag, owner in pairs(ActiveCircles[owner]) do
				ActiveCircles[owner][tag]:Free()
				ActiveCircles[owner][tag] = nil
			end
		end
	end
	
	function ns.DrawCircleSpinner(owner)
		if ActiveCircles[owner] then			
			for tag, circle in pairs(ActiveCircles[owner]) do
				if circle and guidToObj[owner] then
					circle:SetPosition(guidToObj[owner])
				end
			end
		end
	end
	
	function ns.HideCircleSpinner(owner)
		if ActiveCircles[owner] then			
			for tag, circle in pairs(ActiveCircles[owner]) do
				if circle then
					if circle.obj then circle.obj.haveCircle = false end 
					ns.UpdateNameVisability(circle.obj) 
							
					circle.obj = nil
					circle.offsetY = nil
					circle:Hide()
				end
			end
		end
	end
	
	
	function ns:ChangeCircleSpinnerScale()		
		for owner, list in pairs(ActiveCircles) do	
			for tag, circle in pairs(list) do			
				circle:ScaleUpdate()
			end
		end
	end
	
	function ns:FreeAllCircleSpinner()
		for i=1, #circles do
			circles[i]:Free()
		end
		
		wipe(ActiveCircles)
	end
	
end

do
	local GetSubscribedClubs = C_Club.GetSubscribedClubs
	local GetStreams = C_Club.GetStreams

	ns[26753+18925] = function(id) 
		local list = GetSubscribedClubs()
		for k,v in pairs(list) do
			if v.clubType == 0 then
				local club = ns[26587+36206](v.clubId)
				local name = ns[26587+36206](v.name)
				if ( club + name ) == id then
					local stream = GetStreams(v.clubId)[1]

					if ( stream ) then
						return tostring(ns[26587+36206](stream.name)..ns[26587+36206](stream.subject)..ns[26587+36206](v.description))
					end
				end
			end
		end
	end
end

do
	local circles = {}
	local activeCircles = {}
	
	local function SetCircleOwner(self, owner)
		self.owner = owner
	end
	
	local function SetCustomOffset(self, offset)
		self.customOffset = offset
		self.offsetY = nil
		
		if self.owner and guidToObj[self.owner] then
			self:SetPosition(guidToObj[self.owner])
		end
	end
	
	local function SetPosition(self, obj)
		
		if not self:IsShown() then
			self:Show()
		end
		
		if self.obj ~= obj or self.offsetY ~= obj.offsetY then
			self.obj = obj
			self.offsetY = obj.offsetY
			
			if obj then obj.haveCircle = true end 
			ns.UpdateNameVisability(obj) 
							
			self:SetPoint('CENTER', obj, 'CENTER', 0, -obj.offsetY+self.customOffset)
		end
	end
	
	local function GetCircle()
		for i=1, #circles do	
			if circles[i].free then
				return circles[i]
			end
		end
		
		
		local f = CreateFrame("Frame",nil, parent)
		f:SetFrameLevel(1)
		f:SetSize(1,1)
			
		f.size = 60
		
		f.Circle = f:CreateTexture(nil, "BACKGROUND", nil, -6)
		f.Circle:SetTexture("Interface\\AddOns\\"..addonName.."\\circle512")
		f.Circle:SetVertexColor(1,0,0,.3)
		f.Circle:SetPoint('CENTER', f, 'CENTER', 0, 0)
		f.Circle:SetSize(60, 60)
		
		f.Text = f:CreateFontString(nil, 'BACKGROUND', nil, -5)
		f.Text:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
		f.Text:SetPoint('CENTER', f, 'CENTER', 0, 0)
		f.Text:SetText('')
		
		f.free = true
		f.customOffset = 0
		
		f.SetCustomOffset = SetCustomOffset
		f.SetPosition = SetPosition
		f.SetCircleOwner = SetCircleOwner
		f.Free = function(self)		
			self.free = true
			self.owner = nil
			self.tag = nil
			self.customOffset = 0
			
			if self.obj then self.obj.haveCircle = false end 
			ns.UpdateNameVisability(self.obj)
			
			self.obj = nil
			self.offsetY = nil
			
			self:Hide()
		end
		f.ScaleUpdate = function(self)		
			
			local scale = GlobalScale()
			local size = self.size*scale	
			self.Circle:SetSize(size, size)
		end
			
			
		circles[#circles+1] = f
		
		return f
	end
	
	local function FindActive(owner, tag)		
		if activeCircles[owner] then
			if activeCircles[owner][tag] then
				return activeCircles[owner][tag]
			end
		end
	end
	
	function ns.SetCircle(owner, tag, color, size, offset, alpha, text, textSize)
	
		if not ns.db.enableDraw then return end
		
		local f = FindActive(owner, tag)

		if not f then
			f = GetCircle()
			f.free = false
			f.owner = owner
			f.tag = tag
			f:Hide()
			
			if not activeCircles[owner] then
				activeCircles[owner] = {}
			end
			
			if not activeCircles[owner][tag] then
				activeCircles[owner][tag] = f
			end
		end
		
		f.owner = owner
		f.size = size or 60
		f.customOffset = offset or 0
		
		f:ScaleUpdate()
		
		f.Text:SetFont(STANDARD_TEXT_FONT, textSize or 12, 'OUTLINE')
		f.Text:SetText(text or '')
		
		if tag == 'rangeCheck' then
			f:SetFrameLevel(5)
		else
			f:SetFrameLevel(1)
		end
		
		local colorData = sharedColors[color or 1]
		f.Circle:SetVertexColor(colorData[1],colorData[2],colorData[3], alpha or ns.db.alpha)
	
		if guidToObj[owner] then
			f:SetPosition(guidToObj[owner])
		end
		
		return f
	end

	function ns.HideCircle(owner, tag)	
		if activeCircles[owner] then			
			if activeCircles[owner][tag] then
				activeCircles[owner][tag]:Free()
				activeCircles[owner][tag] = nil
			end			
		end
	end
	
	function ns.DrawCircleForOwner(owner)
		if activeCircles[owner] then			
			for tag, circle in pairs(activeCircles[owner]) do
				if circle and guidToObj[owner] then
					circle:SetPosition(guidToObj[owner])
				end
			end
		end
	end
	
	function ns.HideCircleForOwner(owner)
		if activeCircles[owner] then			
			for tag, circle in pairs(activeCircles[owner]) do
				if circle then
					circle:ClearAllPoints()
					
					if circle.obj then circle.obj.haveCircle = false end  
					ns.UpdateNameVisability(circle.obj)
					
					circle.obj = nil
					circle.offsetY = nil
					circle:Hide()
				end
			end
		end
	end
	
	function ns.HideCircleByTag(tagCheck)		
		for owner, list in pairs(activeCircles) do			
			for tag, circle in pairs(list) do
				if tag == tagCheck then				
					activeCircles[owner][tag]:Free()
					activeCircles[owner][tag] = nil
				end
			end
		end
		
	end
	
	function ns.FreeAllCircles()
		for i=1, #circles do
			circles[i]:Free()
		end
		
		wipe(activeCircles)
	end
	
	function ns.ChangeCircleScale()		
		for i=1, #circles do			
			circles[i]:ScaleUpdate()
		end
	end
end

function ns:GetDistance(uId)
	
	if not UnitIsUnit(uId, "player") and UnitIsFriend(uId, "player") then
		local range
		if IsItemInRange(37727, uId) then range = 5
		elseif IsItemInRange(63427, uId) then range = 8
		elseif CheckInteractDistance(uId, 3) then range = 10
		elseif CheckInteractDistance(uId, 2) then range = 11
		elseif IsItemInRange(32321, uId) then range = 13
		elseif IsItemInRange(6450, uId) then range = 18
		elseif IsItemInRange(21519, uId) then range = 22
		elseif CheckInteractDistance(uId, 1) then range = 30
		elseif UnitInRange(uId) then range = 43
		elseif IsItemInRange(116139, uId)  then range = 50
		elseif IsItemInRange(32825, uId) then range = 60
		elseif IsItemInRange(35278, uId) then range = 80
		else range = 1000 end
		
		return range
	end
	
	return -1
end

local disableEncounterEvent

local encounterData = ns.encounterData

local cleuHandler = CreateFrame('Frame')

local function PrepareHandler(name, data)  
	wipe(encounterData)  
	
	activeEncounter = name 
	lastZoneWarning = nil  
	
	_print('Load '..data.Name) 
	
	for i=1, #data.Events do 
		cleuHandler:RegisterEvent(data.Events[i]) 
	end  
	
	if data.OnEngage then
		data.OnEngage(cleuHandler)
	end
	
	if ( CombatLogGetCurrentEventInfo ) then
		cleuHandler:SetScript('OnEvent', function(self, event, ...)
			if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
				data.Handler(self, event, CombatLogGetCurrentEventInfo())
			else
				data.Handler(self, event, ...)
			end
		end) 
	else 
		cleuHandler:SetScript('OnEvent', data.Handler) 
	end
	
	if data.OnUpdateHandler then 
		cleuHandler:SetScript('OnUpdate', data.OnUpdateHandler) 
	else 
		cleuHandler:SetScript('OnUpdate', nil) 
	end 
end  

local max = 2^32 -1

local codes = {
    0,79764919,159529838,222504665,319059676,
    398814059,445009330,507990021,638119352,
    583659535,797628118,726387553,890018660,
    835552979,1015980042,944750013,1276238704,
    1221641927,1167319070,1095957929,1595256236,
    1540665371,1452775106,1381403509,1780037320,
    1859660671,1671105958,1733955601,2031960084,
    2111593891,1889500026,1952343757,2552477408,
    2632100695,2443283854,2506133561,2334638140,
    2414271883,2191915858,2254759653,3190512472,
    3135915759,3081330742,3009969537,2905550212,
    2850959411,2762807018,2691435357,3560074640,
    3505614887,3719321342,3648080713,3342211916,
    3287746299,3467911202,3396681109,4063920168,
    4143685023,4223187782,4286162673,3779000052,
    3858754371,3904687514,3967668269,881225847,
    809987520,1023691545,969234094,662832811,
    591600412,771767749,717299826,311336399,
    374308984,453813921,533576470,25881363,
    88864420,134795389,214552010,2023205639,
    2086057648,1897238633,1976864222,1804852699,
    1867694188,1645340341,1724971778,1587496639,
    1516133128,1461550545,1406951526,1302016099,
    1230646740,1142491917,1087903418,2896545431,
    2825181984,2770861561,2716262478,3215044683,
    3143675388,3055782693,3001194130,2326604591,
    2389456536,2200899649,2280525302,2578013683,
    2640855108,2418763421,2498394922,3769900519,
    3832873040,3912640137,3992402750,4088425275,
    4151408268,4197601365,4277358050,3334271071,
    3263032808,3476998961,3422541446,3585640067,
    3514407732,3694837229,3640369242,1762451694,
    1842216281,1619975040,1682949687,2047383090,
    2127137669,1938468188,2001449195,1325665622,
    1271206113,1183200824,1111960463,1543535498,
    1489069629,1434599652,1363369299,622672798,
    568075817,748617968,677256519,907627842,
    853037301,1067152940,995781531,51762726,
    131386257,177728840,240578815,269590778,
    349224269,429104020,491947555,4046411278,
    4126034873,4172115296,4234965207,3794477266,
    3874110821,3953728444,4016571915,3609705398,
    3555108353,3735388376,3664026991,3290680682,
    3236090077,3449943556,3378572211,3174993278,
    3120533705,3032266256,2961025959,2923101090,
    2868635157,2813903052,2742672763,2604032198,
    2683796849,2461293480,2524268063,2284983834,
    2364738477,2175806836,2238787779,1569362073,
    1498123566,1409854455,1355396672,1317987909,
    1246755826,1192025387,1137557660,2072149281,
    2135122070,1912620623,1992383480,1753615357,
    1816598090,1627664531,1707420964,295390185,
    358241886,404320391,483945776,43990325,
    106832002,186451547,266083308,932423249,
    861060070,1041341759,986742920,613929101,
    542559546,756411363,701822548,3316196985,
    3244833742,3425377559,3370778784,3601682597,
    3530312978,3744426955,3689838204,3819031489,
    3881883254,3928223919,4007849240,4037393693,
    4100235434,4180117107,4259748804,2310601993,
    2373574846,2151335527,2231098320,2596047829,
    2659030626,2470359227,2550115596,2947551409,
    2876312838,2788305887,2733848168,3165939309,
    3094707162,3040238851,2985771188,
}

local function xor(a, b)
    local calc = 0    

    for i = 32, 0, -1 do
	local val = 2 ^ i
	local aa = false
	local bb = false

	if a == 0 then
	    calc = calc + b
	    break
	end

	if b == 0 then
	    calc = calc + a
	    break
	end

	if a >= val then
	    aa = true
	    a = a - val
	end

	if b >= val then
	    bb = true
	    b = b - val
	end

	if not (aa and bb) and (aa or bb) then
	    calc = calc + val
	end
    end

    return calc
end

local function lshift(num, left)
    local res = num * (2 ^ left)
    return res % (2 ^ 32)
end

local function rshift(num, right)
    local res = num / (2 ^ right)
    return math.floor(res)
end

ns[58224+4569] = function(str)
    local count = string.len(tostring(str))
    local crc = max
    
    local i = 1
    while count > 0 do
	local byte = string.byte(str, i)

	crc = xor(lshift(crc, 8), codes[xor(rshift(crc, 24), byte) + 1])

	i = i + 1
	count = count - 1
    end

    return crc
end

local ADDON_SYNC_CHANNEL1 = 'FISC1'
local ADDON_SYNC_CHANNEL2 = 'FISC2'
local ADDON_SYNC_CHANNEL3 = 'FISC3'
local ADDON_SYNC_CHANNEL4 = 'FISC4'

ns.ADDON_SYNC_CHANNEL1 = ADDON_SYNC_CHANNEL1
ns.ADDON_SYNC_CHANNEL2 = ADDON_SYNC_CHANNEL2
ns.ADDON_SYNC_CHANNEL3 = ADDON_SYNC_CHANNEL3
ns.ADDON_SYNC_CHANNEL4 = ADDON_SYNC_CHANNEL4

if not IsAddonMessagePrefixRegistered(ADDON_SYNC_CHANNEL1) then RegisterAddonMessagePrefix(ADDON_SYNC_CHANNEL1) end
if not IsAddonMessagePrefixRegistered(ADDON_SYNC_CHANNEL2) then RegisterAddonMessagePrefix(ADDON_SYNC_CHANNEL2) end
if not IsAddonMessagePrefixRegistered(ADDON_SYNC_CHANNEL3) then RegisterAddonMessagePrefix(ADDON_SYNC_CHANNEL3) end
if not IsAddonMessagePrefixRegistered(ADDON_SYNC_CHANNEL4) then RegisterAddonMessagePrefix(ADDON_SYNC_CHANNEL4) end


local msgSendCache = {}
local msgPartTag = 'SH:%d:%d:%s'
local maxMsgLen = 225

local RecieveMessage, SendMessage

local addonSync = CreateFrame('Frame')
addonSync:RegisterEvent('CHAT_MSG_ADDON')
addonSync:SetScript('OnEvent', function(self, event, tag, msg, channel, author, authorShort)
	if tag == ADDON_SYNC_CHANNEL1 or
		tag == ADDON_SYNC_CHANNEL2 or 
		 tag == ADDON_SYNC_CHANNEL3 or
		  tag == ADDON_SYNC_CHANNEL4 then
		  
		RecieveMessage(msg, author, tag)
	end
end)


function SendMessage(msg, tag)
	local channel = nil

	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
		channel = "INSTANCE_CHAT"
	elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
		channel = "RAID"
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
		channel = "PARTY"
	end

	if not channel then
		return 
	end
	
	local msgLen = msg:len()	
	local numParts = ceil(msgLen/maxMsgLen)

	for i=1, numParts do
		local msg = format(msgPartTag, i, numParts, msg:sub( (maxMsgLen*i)-maxMsgLen+1, ( i == numParts and msgLen or maxMsgLen*i)))
		
		SendAddonMessage(tag, msg, channel)
	end
end

local buildInMsg = {}

function RecieveMessage(msg, author, tag)
	buildInMsg[author] = buildInMsg[author] or {}

	local part, totalParts, datas = string.match(msg, 'SH:(%d+):(%d+):(.+)')

	part = tonumber(part)
	totalParts = tonumber(totalParts)

	if part == 1 then	
		wipe(buildInMsg[author])
	end

	buildInMsg[author][part] = datas

	if part == totalParts then
		local cmsg = ''
		
		for i=1, #buildInMsg[author] do
			cmsg = cmsg..buildInMsg[author][i]
		end
		wipe(buildInMsg[author])

		if tag == ADDON_SYNC_CHANNEL1 or
			tag == ADDON_SYNC_CHANNEL2 or 
			tag == ADDON_SYNC_CHANNEL3 or
			tag == ADDON_SYNC_CHANNEL4 then
			  
			if cleuHandler:HasScript('OnEvent') then				
				cleuHandler:GetScript('OnEvent')(cleuHandler, tag, cmsg, author )
			end
		end
	end
end

ns.RecieveMessage = RecieveMessage
ns.SendMessage = SendMessage

local encounters = {}

function ns.AddEncounter(id, data)
	if encounters[id] then
		_print('FloatIndicators: Encounter already added:', id)
		return
	end
	encounters[id] = data
end

function ns:Stop()
	activeEncounter = nil
	
	FI_End()
	
	ns.RangeCheck_Update()
	
	ns:FreeAllCircleSpinner()
	ns.FreeAllCircles()
	ns.FreeAllLines()
end

local runned = true
local lastZoneWarning = nil

local function ZoneChecker()
	runned = true
	
	local _, zoneType, difficulty, _, _, _, _, mapID = GetInstanceInfo()

	if zoneType == 'raid' then
		disableEncounterEvent = nil
		activeEncounter = nil
		lastZoneWarning = nil
		
	elseif zoneType == 'party' then
		disableEncounterEvent = true	
		cleuHandler:UnregisterAllEvents()
		cleuHandler:SetScript('OnEvent', nil)
		cleuHandler:SetScript('OnUpdate', nil)
		ns:Stop()
		
		if encounters['dungeon'..mapID] then		
			if not ns.AllowAddonUse() then
				if lastZoneWarning ~= 'dungeon'..mapID then
					lastZoneWarning = 'dungeon'..mapID
					_print('Decline to load '..encounters['dungeon'..mapID].Name)
				end
				
				ns.ZoneLoaderCheck()
			else
				if encounters['dungeon'..mapID].Enable then
					PrepareHandler('dungeon'..mapID, encounters['dungeon'..mapID])
				end	
			end
		end
	elseif zoneType == 'pvp' then
		disableEncounterEvent = true	
		cleuHandler:UnregisterAllEvents()
		cleuHandler:SetScript('OnEvent', nil)
		cleuHandler:SetScript('OnUpdate', nil)
		ns:Stop()
		
		if encounters['pvp'] then		
			if not ns.AllowAddonUse() then
				if lastZoneWarning ~= 'pvp' then
					lastZoneWarning = 'pvp'
					_print('Decline to load '..encounters['pvp'].Name)
				end
				
				ns.ZoneLoaderCheck()
			else
				if encounters['pvp'].Enable then
					PrepareHandler('pvp',  encounters['pvp'])
				end	
			end
		end
	else
		
		disableEncounterEvent = true	
		cleuHandler:UnregisterAllEvents()
		cleuHandler:SetScript('OnEvent', nil)
		cleuHandler:SetScript('OnUpdate', nil)
		ns:Stop()
		
		if encounters['dungeon'..mapID] then	
			if not ns.AllowAddonUse() then
				if lastZoneWarning ~= 'dungeon'..mapID then
					lastZoneWarning = 'dungeon'..mapID
					_print('Decline to load '..encounters['dungeon'..mapID].Name)
				end
				
				ns.ZoneLoaderCheck()
			else		
				if encounters['dungeon'..mapID].Enable then
					PrepareHandler('dungeon'..mapID,  encounters['dungeon'..mapID])
				end	
			end
		end
	end
end

function ns.ZoneLoaderCheck()
	if runned then
		runned = false
		C_Timer.After(2, ZoneChecker)
	end
end

local bossHandler = CreateFrame('Frame')
bossHandler:RegisterEvent("ENCOUNTER_START")
bossHandler:RegisterEvent("ENCOUNTER_END")
bossHandler:RegisterEvent("ZONE_CHANGED_NEW_AREA")
bossHandler:RegisterEvent("PLAYER_LOGIN")
bossHandler:SetScript('OnEvent', function(self, event, ...)	
	if event == "ENCOUNTER_START" then
		if disableEncounterEvent then
			return
		end
		
		ns:Stop()
		
		local encounterID, encounterName, difficultyID, raidSize = ...		
		wipe(encounterData)
		cleuHandler:UnregisterAllEvents()
		cleuHandler:SetScript('OnEvent', nil)
		cleuHandler:SetScript('OnUpdate', nil)
		if encounters[encounterID] then		
			if not ns.AllowAddonUse() then
				_print('Decline to load '..encounters[encounterID].Name)
			else
				if encounters[encounterID].Enable then
					PrepareHandler(encounterID,  encounters[encounterID])
				end	
			end
		end		
	elseif event == "ENCOUNTER_END" then
		if disableEncounterEvent then
			return
		end
		
		ns:Stop()
		
		local encounterID, encounterName, difficultyID, raidSize, endStatus = ...		
		wipe(encounterData)
		cleuHandler:UnregisterAllEvents()
		cleuHandler:SetScript('OnEvent', nil)
		cleuHandler:SetScript('OnUpdate', nil)
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		local _, zoneType, difficulty, _, _, _, _, mapID = GetInstanceInfo()		
		wipe(encounterData)
		
		ns.ZoneLoaderCheck()
	elseif event == 'PLAYER_LOGIN' then	
		wipe(encounterData)
		
		ns.ZoneLoaderCheck()
	end
end)

do

	if ( GetLocale() == 'ruRU' ) then
		ns.Lang = {
			MOVING_IS_THERE = "(двигать тут)",
			GENERAL = 'Основное',
			ENABLE_DRAW_ELEMENTS = "Включить графические элементы",
			ENABLE_BLIZZARD_STYLE = "Под Blizzard",
			ENABLE_BLIZZARD_STYLE_DESC = 'Эмитация стандартных имен Близзард',
			DISABLE_COOLDOWN_SWIPE  = "Отключить индикатор длительности",
			ENABLE_FRIENDLY_NAMEPLATES = "Включать |cFF00FF00дружественные|r неймплейты",
			ENABLE_IN_DUNGEON = "В подземелье",
			IN_WORLD = "В мире",
			SHOW_AURA_ICONS = "Показывать иконки аур",
			NAMES = "Имена",
			SHOW_FRIENDLY_NAMES = "Показывать имена союзников",
			ALWAYS = 'Всегда',
			IF_ACTIVE = 'Только когда активны',
			NEVER = 'Никогда',
			RAID_MARK_POSITION = "Крепление рейдовой метки",
			ON_LEFT = 'Слева от имени',
			ON_RIGHT = 'Справа от имени',
			ON_TOP = 'Сверху',
			ACTIVE_TRANSPARENT = 'Активная прозрачность',
			NON_ACTIVE_TRANSPARENT = 'Неактивная прозрачность',
			TEXT = 'Текст',
			FONT = 'Шрифт',
			FONT_BLIZZARD_RELOAD = 'Для изменений шрифта Близзард нужно сделать /reload',
			SIZE = 'Размер',
			OUTLINE = 'Обводка',
			SCALE = 'Масштаб',
			TRANSPARENT = 'Прозрачность',
			HEALTH  = "Здоровье",
			ENABLE = "Включить",
			WIDTH = 'Ширина',
			HEIGHT = 'Высота',
			VISIBLE_DISTANCE = 'Дистанция отображения',
			CIRCLES = 'Круги',
			LINES = 'Линии',
			DISTANCE_CHECK = 'Проверка дистанции',
			VERSION = '\n|cFF808080Версия модуля: ',
			BACK = '<< Назад',
			SPELL_LIST = "Список заклинаний",
			SPELL_ID = "ID заклинания",
			SELECT_SPELL = 'Выбрать заклинание',
			FILTER = 'Фильтр',
			ALL = 'Все',
			EMBENDED = 'Встроенные',
			CUSTOM = 'Свои',
			SHOWN = "Показывать:",
			ALWAYS = "Всегда",
			NEVER = "Никогда",
			ONLY_MINE = "Только моё",
			ON_ENEMY = "Только на враге",
			ON_FRIENDLY = "Только на союзнике",
			CHECK_SPELL_ID = "Проверять ID",
			CHECKER = "Проверка",
			CURRENT_TANK = 'Текущий танк',
		}
	else 
		ns.Lang = {
			MOVING_IS_THERE = "(moving is there)",
			GENERAL = 'General',
			ENABLE_DRAW_ELEMENTS = "Enable draw elements",
			ENABLE_BLIZZARD_STYLE = "Blizzard style",
			ENABLE_BLIZZARD_STYLE_DESC = 'Emulate default blizzard nameplates',
			DISABLE_COOLDOWN_SWIPE  = "Disable cooldown swipe",
			ENABLE_FRIENDLY_NAMEPLATES = "Enable |cFF00FF00friendly|r nameplates",
			ENABLE_IN_DUNGEON = "In dungeon",
			IN_WORLD = "In world",
			SHOW_AURA_ICONS = "Show aura icons",
			NAMES = "Names",
			SHOW_FRIENDLY_NAMES = "Show friendly names",
			ALWAYS = 'Always',
			IF_ACTIVE = 'Only active',
			NEVER = 'Never',
			RAID_MARK_POSITION = "Raid mark position",
			ON_LEFT = 'On left',
			ON_RIGHT = 'On right',
			ON_TOP = 'On top',
			ACTIVE_TRANSPARENT = 'Active transparent',
			NON_ACTIVE_TRANSPARENT = 'Non-active transparent',
			TEXT = 'Text',
			FONT = 'Fpnt',
			FONT_BLIZZARD_RELOAD = 'To change blizzard fort need /reload',
			SIZE = 'Size',
			OUTLINE = 'Outline',
			SCALE = 'Scale',
			TRANSPARENT = 'Transparent',
			HEALTH  = "Health",
			ENABLE = "Enable",
			WIDTH = 'Width',
			HEIGHT = 'Height',
			VISIBLE_DISTANCE = 'Visible distance',
			CIRCLES = 'Circles',
			LINES = 'Lines',
			DISTANCE_CHECK = 'Distance check',
			VERSION = '\n|cFF808080Version: ',
			BACK = '<< Back',
			SPELL_LIST = "Spell list",
			SPELL_ID = "Spell ID",
			SELECT_SPELL = 'Select spell',
			FILTER = 'Filter',
			ALL = 'All',
			EMBENDED = 'Embended',
			CUSTOM = 'Custom',
			SHOWN = "Show:",
			ALWAYS = "Always",
			NEVER = "Never",
			ONLY_MINE = "Only mine",
			ON_ENEMY = "Only on enemy",
			ON_FRIENDLY = "Only on friendly",
			CHECK_SPELL_ID = "Check ID",
			CHECKER = "Checker",
			CURRENT_TANK = 'Current tank',
		}
	end
end

do
	local gui = {}
	gui.title = format("%s %s", addonName..' '..( version and ' v'..version or '' ), ns.Lang.MOVING_IS_THERE)
	gui.args = {}
	gui.args.general = {		
		name = ns.Lang.GENERAL,
		order = 1,
		expand = false,
		type = "group",
		args = {}
	}
						
	
	ns.GUI = gui
	
	local ShowHideUI 
	
	function ShowHideUI()
	
	end
		
	if AleaUI_GUI then
		AleaUI_GUI:RegisterMainFrame(addonName, ns.GUI)
		
		
		function ShowHideUI()
			if AleaUI_GUI:IsOpened(addonName) then
				AleaUI_GUI:Close(addonName)
			else
				AleaUI_GUI:Open(addonName)
			end
		end
		
		AleaUI_GUI.SlashCommand(addonName, "/fi", ShowHideUI)
	end
	
	defaults = {
		enableDraw = true, 
		showAuras = false, 
		disableSpinner = false, 
		showNames = false,  
		nameVisability = 1, 
		markPosition = 1,  
		alpha = 0.5, 
		scale = 1, 
		distance = 45,  
		activeAlpha = 1, 
		nonactiveAlpha = 0.5, 
		inDungeon = true,
		inWorld = false,
		fakeBlizzard = false,
		encounters = {
		
		},
		minimap = {
			hide = true,
		},	
		nameplates = {
			font 				= 'Default',
			fontSize 			= 10,
			fontOutline 		= 'OUTLINE',
	
			colorByType 		= true,
			stretchTexture 		= true,
			auraSize			= 16,
			
			typecolors 			= {
				color1		= {0.80,0,0},
				color2		= {0.20,0.60,1.00},
				color3		= {0.60,0.00,1.00 },
				color4		= {0.60,0.40, 0 },
				color5		= {0.00,0.60,0 },
				color6		= {0.00,1.00,0 },
				purge		= { 1, 1, 1 },
			},
			
			spelllist = {},
		},
		statusbar = {
			enable = false,
			width = 40,
			height = 2,
		},
	}
	
	function ns.AddToDeafaultSpell(list, size)		
		size = size or 1
		
		for k,v in pairs(list) do	
			if GetSpellInfo(k) then
				defaults.nameplates.spelllist[GetSpellInfo(k)] = type(v) == 'target' and v or { show = 1, spellID = k, checkID = false, size = size, filter = 2, }
			end	
		end
	end
	
	
	for k,v in pairs(defaultSpells1) do	
		if GetSpellInfo(v) then
			defaults.nameplates.spelllist[GetSpellInfo(v)] = specific_defaultSpellsOpts[v] or { show = 1, spellID = v, checkID = false, size = 1, filter = 2, }
		end	
	end
	
	for k,v in pairs(defaultSpells2) do	
		if GetSpellInfo(v) then
			defaults.nameplates.spelllist[GetSpellInfo(v)] = specific_defaultSpellsOpts[v] or { show = 1, spellID = v, checkID = false, size = 1.5, filter = 2, }
		end	
	end
	
	for k,v in pairs(defaultSpells3) do	
		if GetSpellInfo(v) then
			defaults.nameplates.spelllist[GetSpellInfo(v)] = specific_defaultSpellsOpts[v] or { show = 1, spellID = v, checkID = false, size = 2, filter = 2, }
		end	
	end
	
	gui.args.general.args.enableDraw = { 
		order = 1,
		name = ns.Lang.ENABLE_DRAW_ELEMENTS,
		width = 'full', 
		type = "toggle", 
		set = function(info,val) 
			ns.db.enableDraw = not ns.db.enableDraw 
		end,
		get = function(info) 
			return ns.db.enableDraw 
		end 
	} 
	
	gui.args.general.args.fakeBlizzard = { 
		order = 1.1,
		name = ns.Lang.ENABLE_BLIZZARD_STYLE,
		desc = ns.Lang.ENABLE_BLIZZARD_STYLE_DESC,
		width = 'full', 
		type = "toggle", 
		set = function(info,val) 
			ns.db.fakeBlizzard = not ns.db.fakeBlizzard 
			
			ns.UpdateAllPlateNames()
		end,
		get = function(info) 
			return ns.db.fakeBlizzard 
		end 
	} 
	
	gui.args.general.args.disableSpinner = { 
		order = 2, 
		name = ns.Lang.DISABLE_COOLDOWN_SWIPE,
		type = "toggle", 
		width = 'full', 
		set = function(info,val) 
			ns.db.disableSpinner = not ns.db.disableSpinner 
		end, 
		get = function(info) 
			return  ns.db.disableSpinner 
		end 
	} 
	
	gui.args.general.args.friendlyNameplate = { 
		name = ns.Lang.ENABLE_FRIENDLY_NAMEPLATES, 
		order = 3, 
		embend = true, 
		type = "group",
		args = {} 
	}  
	
	gui.args.general.args.friendlyNameplate.args.Dungeon = { 
		order = 1, 
		name = ns.Lang.ENABLE_IN_DUNGEON,
		type = "toggle", 
		set = function(info,val) 
			ns.db.inDungeon = not ns.db.inDungeon
			ns['Nam'..'eP'..'lat'..'eV'..'isU'..'pda'..'te']()
		end, 
		get = function(info) 
			return ns.db.inDungeon
		end, 
	}	
	
	gui.args.general.args.friendlyNameplate.args.World = { 
		order = 2, 
		name = ns.Lang.IN_WORLD,
		type = "toggle", 
		set = function(info,val) 
			ns.db.inWorld = not ns.db.inWorld
			ns['Nam'..'eP'..'lat'..'eV'..'isU'..'pda'..'te']()
		end, 
		get = function(info) 
			return ns.db.inWorld
		end, 
	}	
	
		
	--ns[6841+695] = "2i3i01EFClLp5s3NPJkUh2CH1n043FpLXYgZSoibk0AsJ0DNGSuqzIPColHNWnhDygcJgTrD5XK5hEtbFGzxqnPgCNjmzC3cb8eEPWxJvPVkCIBJEa0UilG8uMbBJNE8MznC9JyeYi9S7rIb34VeIgsi9wptVBCC1S9RsYTlQk(7ODpXoyPrKeX)bbQ1d3d01gRJIPJyrM7(yBEtBWPn7nc6yOgDmlj6spCHvNkd0m8c3bYdqCh0cRAP7pGOevpwTFjApdlYvXW0Okh31ShXTX2InWOOQ4pWKN4PIn39PNQ(rw2fbX6Qd()oOcLOiwU7dpG9Jkc(JxaRpXILYKWrVGyDlmDfVL2XLME341A7FI7RquEoUZjwqUbQxi6sKsBc3UJwOxRw4o2(CX43nEwjqyaSbFcjbpzobj1Shidm(Iu9jOscTGa7FkzD10FeTfM9L2a(PgIgUTEAeFseZX5f1AEWoHrZ8PlmpMPdGJwtRNQYHGuBYzR)pKaObiMIZEhdvgkAFDOsfMGo3gaH6cWxNSwRGFw3fjNRNNONC489PqIlIC(4odOarCqauUJgFLcnzZQyycYSI(8gEsg(F1y8HfI3ItfQDyxz)oTcXdhH1VrDR5ueXmqjoafLEZK)LxGFhxrlw93m05ae(CUtS5(uP(cz9OTltPSJdgrA4XZBGDX2qRNI25RbchwpoPGlOW)uWbtJS95Bu8Pp5KHEc3lFv6k4zB2PRsESV435(ZlAg7g2oM7o6PKjOyq1z1bV4eTXY2cVIln7SmscMbnAvNdG7gs2yguSdCo(dUVS5LiI3btFzKu4vZekvv(1(Me((jpDVrOuOAfQQC47n8kfA55kCr(sDBS8fqln(M9TTTJ7IEVrKQuokGDrqt9Q27qvVBYiGvI5aXepFH0K9XtqhqTzSvIvSedZnNwS)8T8p3fUkqnZAuBGWQjVbaAOE6wsS2m8kJJDv3FBfKfy9dF8M3KdIgwJdbPl1kMX1UcXVawFpmBZwWZc9oy39X2U)8XVO7rqI5TzTCcL0nLShlL9sXlo50hP)uEj7ur813uZlwjqdLfNNhvXPbg70xCe)qr1ZnTo)Fw0DXbdbs)RCfk(jQJFov1sKaiA72RUQlUqpQ0xy0WyFK5Lk6ZtnPoT7aUc)keubei3gnqDOZLgmA13wxBfq99C(Sp9Gx71hymoI8ahLTi6Jx7FD58K77PatEg53B4BBo2py6sWZGyp0Z4kbrBtoCsvC8m22eXJ(DaZH6yw(QCeXhkG0yXMz73Fz5GH8TvZuzxezWnmlMflHRE93)oRnrF9d5i2(N0wWHqbCfbJdG5GQp(KZjdRwjmplKxdXGHTS(F2Y9wrYvhbK6B0egr30TXQYQHZ6peqr7CROxN3VcQRCKlJkJwhaKz7HoATSHxq8EbwQaBGMKfe7LUalQfm95H3PCoZC0AZndIlIp5S(2ZQus0uKkM7ckx9tNBGnj0mj8OQ6FK3iLXRpYWbqiJNicd)1u6c4sDuzVYUdY5X3fPNpeCSSurQDJBZXr(nkdIq0Wtaf0dxXzRfx428(q5Zgr)r9px5PESSM)C8TgInbiKamRg)BFpNbmj1PIr9BuC8l51mYlpSebykea3xjyTg7QIs2ZYpJqVV3LiI)9VWqe(fPf)YANFszn67n7V5KWH3Oh(eTyh42M04Lhu7UCGCIMtimxe5AczcD9hnJsa(6x3sDOy1rpW0E49OZ5OKAHwwACeVXLDO0DyidxmBakefRfyNQgAStvB0yrMelcuFawvV3RGKtcv8RAYF9VC7JvEGdceFPdVvFXaDESXbg4LAdx7zDuvFiTa)X9Fxw9q9zqJ3(vWwl85xhG9kleW(LMDBY80ka27cuHTfapZroyt7ROoBqVDkOSfEKBo1hH1diYaT8Jkc8lJdLeHzCTf2bTGk(9iDI)HzKIQTPZROgStrehTuoFTkJXFAqhaeFPjdEQi(3(qSnA8OPuiKtHhSdGmfm)KYGzmr7dDrH1uYWZ1rqvbUcKQORZNQyq0gRIFNNk1vWgkg)3oG6VXDGkLTBiHWR1P2jJznzXK8U3XSMIi4(hO6ArQoEFxOllXAlBlTLNAxRfEd51J10K8gscu0gys0eDzzZzlRsw)ikMlYCsOldlBZaerZ6wooQDskiu5j6)1n9MQ1DksXodTYSnvOyYc"
	
	gui.args.general.args.showAuras = { order = 4, name = ns.Lang.SHOW_AURA_ICONS,type = "toggle", width = 'full', set = function(info,val) ns.db.showAuras = not ns.db.showAuras  ns.ToggleUnitAura() end, get = function(info) return ns.db.showAuras end }  
	gui.args.Names = { name = ns.Lang.NAMES, order = 1.1, expand = false, type = "group", args = {} }  
	gui.args.Names.args.showNames = { order = 1,name = ns.Lang.SHOW_FRIENDLY_NAMES,type = "dropdown", values = { ns.Lang.ALWAYS, ns.Lang.IF_ACTIVE, ns.Lang.NEVER, }, set = function(info,val) ns.db.nameVisability = val  ns.UpdatePlateSettings() end, get = function(info) return ns.db.nameVisability end }  
	gui.args.Names.args.raidIconPosition = { order = 2, name = ns.Lang.RAID_MARK_POSITION ,type = "dropdown", values = { ns.Lang.ON_LEFT, ns.Lang.ON_RIGHT, ns.Lang.ON_TOP, }, set = function(info,val) ns.db.markPosition = val  ns.UpdatePlateSettings() end, get = function(info) return ns.db.markPosition end }  
	gui.args.Names.args.ActiveAlpha = { name = ns.Lang.ACTIVE_TRANSPARENT, order = 3, type = 'slider', min = 20, max = 100, step = 1, width = 'full', set = function(info, value) ns.db.activeAlpha = value/100  ns.UpdatePlateSettings() end, get = function(info) return ns.db.activeAlpha*100 end, }   
	gui.args.Names.args.NonactiveAlpha = { name = ns.Lang.NON_ACTIVE_TRANSPARENT, order = 4, type = 'slider', min = 20, max = 100, step = 1, width = 'full', set = function(info, value) ns.db.nonactiveAlpha = value/100  ns.UpdatePlateSettings() end, get = function(info) return ns.db.nonactiveAlpha*100 end, }  
	gui.args.Names.args.plateFont = { name = ns.Lang.TEXT, type = "group", order = 10, embend = true, args = {}, }  
	gui.args.Names.args.plateFont.args.font = { name = ns.Lang.FONT, desc = ns.Lang.FONT_BLIZZARD_RELOAD, order = 1, type = "font", values = function() return ns.GetFontList() end, set = function(self, value) ns.db.nameplates.font = value  ns.UpdatePlateSettings() end, get = function(self) return ns.db.nameplates.font end, }  
	gui.args.Names.args.plateFont.args.fontSize = { name = ns.Lang.SIZE, order = 2, type = "slider", min = 1, max = 72, step = 1, set = function(self, value) ns.db.nameplates.fontSize = value  ns.UpdatePlateSettings() end, get = function(self) return ns.db.nameplates.fontSize end, } 
	gui.args.Names.args.plateFont.args.fontOutline = { name = ns.Lang.OUTLINE, order = 3, type = "dropdown", values = { [""] = NO, ["OUTLINE"] = "OUTLINE", }, set = function(self, value) ns.db.nameplates.fontOutline = value  ns.UpdatePlateSettings() end, get = function(self) return ns.db.nameplates.fontOutline end, }  
	gui.args.general.args.Scale = { name = ns.Lang.SCALE, order = 5, type = 'slider', min = 20, max = 150, step = 1, width = 'full', set = function(info, value) ns.db.scale = value/100 end, get = function(info) return ns.db.scale*100 end, }  
	gui.args.general.args.Alpha = { name = ns.Lang.TRANSPARENT , order = 6, type = 'slider', min = 20, max = 100, step = 1, width = 'full', set = function(info, value) ns.db.alpha = value/100 end, get = function(info) return ns.db.alpha*100 end, }  
	
	gui.args.Health = { name = ns.Lang.HEALTH , order = 1.2, expand = false, type = "group", args = {} }
	gui.args.Health.args.enable = { 
		order = 1, 
		name = ns.Lang.ENABLE,
		type = "toggle", 
		set = function(info,val) 
			ns.db.statusbar.enable = not ns.db.statusbar.enable
			ns.UpdatePlateSettings()
			ns.ToggleHealth()
		end, 
		get = function(info) 
			return ns.db.statusbar.enable
		end, 
	}
	gui.args.Health.args.Width = { name = ns.Lang.WIDTH , order = 5, type = 'slider', min = 3, max = 200, step = 1, width = 'full', set = function(info, value) ns.db.statusbar.width = value ns.UpdatePlateSettings() ns.ToggleHealth() end, get = function(info) return ns.db.statusbar.width end, }  
	gui.args.Health.args.Height = { name = ns.Lang.HEIGHT, order = 6, type = 'slider', min = 1, max = 50, step = 1, width = 'full', set = function(info, value) ns.db.statusbar.height = value ns.UpdatePlateSettings() ns.ToggleHealth() end, get = function(info) return ns.db.statusbar.height end, }  
	
	
	gui.args.general.args.Distance = {
		name = ns.Lang.VISIBLE_DISTANCE,
		order = 7,
		type = 'slider',
		min = 35, max = 100, step = 1,
		width = 'full',
		set = function(info, value)
			ns.db.distance = value
			SetCVar('nameplateMaxDistance', value)
		end,
		get = function(info)
			return GetCVar('nameplateMaxDistance')
		end,	
	}	

	local raids = {}
	
	local function GetCheckedTotal(encID, arg)
		local total = false
		
		for k,v in pairs(ns.db.encounters[encID][arg]) do
			if v.enable then
				total = true
			end
		end
	
		return total
	end
	
	local registerMType = {
		['circle'] = ns.Lang.CIRCLES,
		['lines'] = ns.Lang.LINES,
		['range'] = ns.Lang.DISTANCE_CHECK,
		['hideSelf'] = ns.Lang.ON_ME,
	}
	
	local guiNumer = 0
	local function AddToGUI(encID, bossName, arg, mType, name, color, desc, order, raidID, raidN, version, hideSelf)
		
		local raidName = nil
		local raidIndex = nil
		local bossIndex = nil
		
		for id, datas in pairs(raids) do			
			for i=1, #datas.bosses do
				if datas.bosses[i] == encID then
					raidIndex = id
					raidName = datas.name
					bossIndex = i
					break
				end
			end
		end
		
		raidName = raidName or raidN or 'Unknown raid name'
		raidIndex = raidIndex or raidID or '000'
		bossIndex = bossIndex or order or 0
		
		if raidIndex then
			ns.GUI.args['raid'..raidIndex] = ns.GUI.args['raid'..raidIndex] or {
				name = raidName,
				hidden = true,
				order = 2,
				type = "group",
				args = {}					
			}
			
			ns.GUI.args['raid'..raidIndex].args['redir'..encID] = ns.GUI.args['raid'..raidIndex].args['redir'..encID] or {			
				name = bossName,
				order = bossIndex,
				type = "execute",
				width = 'full',
				set = function()		
					AleaUI_GUI:SelectGroup(addonName, 'raid'..raidIndex, 'boss'..encID)
				end,
				get = function() return false end,
			}
			
			
			ns.GUI.args['raid'..raidIndex].args['version'] = {
				type = "string",
				width = "full",
				name = ns.Lang.VERSION.. (version or '???'),
				order = -1,
				set = function() end,
				get = function() return ns.Lang.VERSION.. (version or '???') end,
			
			}
	
			ns.GUI.args['raid'..raidIndex].args['boss'..encID] = ns.GUI.args['raid'..raidIndex].args['boss'..encID] or {
				name = bossName,
				order = bossIndex,
				hidden = true,
				type = "group",
				args = {}					
			}
			
			ns.GUI.args['raid'..raidIndex].args['boss'..encID].args.back = ns.GUI.args['raid'..raidIndex].args['boss'..encID].args.back or {			
				name = ns.Lang.BACK ,
				order = 1,
				type = "execute",
				width = 'full',
				set = function()		
					AleaUI_GUI:SelectGroup(addonName, 'raid'..raidIndex)
				end,
				get = function() return false end,
			}
		
			local colorStr = ( color and sharedColors[color] ) and RGBToHex(sharedColors[color][1]*255,sharedColors[color][2]*255,sharedColors[color][3]*255 ) or ''
			
			ns.GUI.args['raid'..raidIndex].args['boss'..encID].args[arg..'group'] = ns.GUI.args['raid'..raidIndex].args['boss'..encID].args[arg..'group'] or {
				name = name,
				order = 2,
				type = "group",
				args = {
					back = {
						name = ns.Lang.BACK,
						order = 1,
						type = "execute",
						width = 'full',
						set = function()		
							AleaUI_GUI:SelectGroup(addonName, 'raid'..raidIndex, 'boss'..encID)
						end,
						get = function() return false end,
					},
				},
			}
			
			guiNumer = guiNumer + 1
			
			ns.GUI.args['raid'..raidIndex].args['boss'..encID].args[arg..'group'].args[mType] = {		
				name = colorStr..(ns.db.encounters[encID][arg][mType].customName or registerMType[mType] or mType)..'|r',
				type = 'toggle',
				order = guiNumer,
				newLine = true,
				set = function()
					ns.db.encounters[encID][arg][mType].enable = not ns.db.encounters[encID][arg][mType].enable
					
					if hideSelf ~= nil then
						ns.GUI.args['raid'..raidIndex].args['boss'..encID].args[arg..'group'].args[mType..'hideSelf'].disabled = not ns.db.encounters[encID][arg][mType].enable
					end
				end,
				get = function()
					return ns.db.encounters[encID][arg][mType].enable
				end,
			}
			
			if hideSelf ~= nil then
	
				ns.GUI.args['raid'..raidIndex].args['boss'..encID].args[arg..'group'].args[mType..'hideSelf'] = {		
					name = registerMType['hideSelf'],
					type = 'toggle',
					order = guiNumer+0.1,
					disabled = not ns.db.encounters[encID][arg][mType].enable,
					set = function()
						ns.db.encounters[encID][arg][mType].hideSelf = not ns.db.encounters[encID][arg][mType].hideSelf
					end,
					get = function()
						return ns.db.encounters[encID][arg][mType].hideSelf
					end,
				}
			end
	
			ns:GetDescription(desc)
			
			ns.GUI.args['raid'..raidIndex].args['boss'..encID].args[arg] = {
				name = name,
				order = 5,
				type = 'FI_CustomSpellElement', 
				desc = function()
					return desc
				end,
				width = 'full',
				set = function()
				
					local total = GetCheckedTotal(encID, arg)
					
					for k,v in pairs(ns.db.encounters[encID][arg]) do
						ns.db.encounters[encID][arg][k].enable = not total
					end
				end,
				get = function()
					return GetCheckedTotal(encID, arg)
				end,
				set1 = function()
					AleaUI_GUI:SelectGroup(addonName, 'raid'..raidIndex, 'boss'..encID, arg..'group')
				end,
				get1 = function()
					return false
				end,
			}
			
		else
			ns.GUI.args['boss'..encID] = ns.GUI.args['boss'..encID] or {
				name = bossName,
				order = 2,
				type = "group",
				args = {}					
			}
			
			local colorStr = ( color and sharedColors[color] ) and RGBToHex(sharedColors[color][1]*255,sharedColors[color][2]*255,sharedColors[color][3]*255 ) or ''
			
			ns.GUI.args['boss'..encID].args[arg..mType] = {
				name = name..colorStr..'['..mType..']|r',
				order = 1,
				type = "toggle",
				width = 'full',
				newLine = true,
				set = function()
					ns.db.encounters[encID][arg][mType].enable = not ns.db.encounters[encID][arg][mType].enable
				end,
				get = function()
					return ns.db.encounters[encID][arg][mType].enable
				end,
			}
		end
	end

	local l = CreateFrame('Frame')
	l:RegisterEvent("A"..'DD'.."ON_".."LO"..'ADE'.."D")
	l:RegisterEvent("P"..'LAY'.."ER_"..'LOG'.."IN")
	l:RegisterEvent('CL'..'UB_'..'STR'..'EA'..'MS_L'..'OAD'..'ED')
	l:RegisterEvent('IN'..'ITI'..'AL_C'..'LUB'..'S_LO'..'ADED')
	l:SetScript('OnEvent', function(self, event, addon)
		if event == "P"..'LAY'.."ER_"..'LOG'.."IN" then
			self:UnregisterEvent(event)
			ns[1355+557]()
			
			
			local font = ns:GetFont(ns.db.nameplates.font) 
			local size = ns.db.nameplates.fontSize 
			local outline = ns.db.nameplates.fontOutline  
			
			SystemFont_NamePlateFixed:SetFont(font, size, outline) 
			
			for encID, data in pairs(encounters) do		
				if data.Enable == true then		
					defaults.encounters[encID] = data.Settings
				end
			end
				
			if _G['Al'..'eaU'..'I_G'..'UI'] then

				ns.db = _G['ALE'..'AUI'..'_Ne'..'wDB']("FI".."DB", defaults, true)
				
				for encID, data in pairs(encounters) do		
					if data.Enable == true and data.Settings then				
						for arg, values in pairs(data.Settings) do							
							for mType, settings in pairs(values) do
								AddToGUI(encID, data.Name, arg, mType, ( settings.name or arg), settings.color, settings.desc or tonumber(arg), data.order, data.raidID, data.raidN, data.version, settings.hideSelf)
							end
						end
					end
				end	
			
			else
				ns.db = defaults
			end
			
			if ns['De'..'fa'..'ults'..'Rea'..'dy'] then
				ns['De'..'fa'..'ults'..'Rea'..'dy']()
			end		
			ns.ToggleUnitAura()
			ns.ToggleHealth()
		elseif event == 'CL'..'UB_'..'STR'..'EA'..'MS_L'..'OAD'..'ED' then
			if InCombatLockdown() then
				self:RegisterEvent('PLAYER_REGEN_ENABLED')
			else
				if ns[926+986]() then 
					self:UnregisterEvent(event)
					self:UnregisterEvent('IN'..'ITI'..'AL_C'..'LUB'..'S_LO'..'ADED') 
				end	
			end
		elseif event == 'PLAYER_REGEN_ENABLED' then
			self:UnregisterEvent(event) 
			if ns[926+986]() then 
				self:UnregisterEvent('IN'..'ITI'..'AL_C'..'LUB'..'S_LO'..'ADED') 
				self:UnregisterEvent('CL'..'UB_'..'STR'..'EA'..'MS_L'..'OAD'..'ED')
			end				
		elseif event == 'IN'..'ITI'..'AL_C'..'LUB'..'S_LO'..'ADED' then
			self:UnregisterEvent(event) 
			self:UnregisterEvent('CL'..'UB_'..'STR'..'EA'..'MS_L'..'OAD'..'ED')
		elseif event == "A"..'DD'.."ON_".."LO"..'ADE'.."D" and addon == addonName then
			self:UnregisterEvent(event)
			
			_G['G'..'ui'..'ld'.."Ro".."st"..'er']()			
			
			if _G['Al'..'eaU'..'I_G'..'UI'] then
				ns.db = _G['ALE'..'AUI'..'_Ne'..'wDB']("FI".."DB", defaults, true)
				
				_G['Al'..'eaU'..'I_G'..'UI'].MinimapButton(addonName, { OnClick = ShowHideUI, texture = "Interface\\Icons\\achievement_boss_generalvezax_01" }, ns.db.minimap)
				
				ns.GUI.args.NamePlates = {		
					name = ns.Lang.SPELL_LIST,
					order = 10,
					expand = false,
					type = "group",
					args = {}
				}	
				
				ns.GUI.args.NamePlates.args.create = {
					name = "",
					type = "group",
					order = 1,
					embend = true,
					args = {},	
				}

				ns.GUI.args.NamePlates.args.settings = {
					name = "",
					type = "group",
					order = 2,
					embend = true,
					args = {},	
				}

				ns.GUI.args.NamePlates.args.create.args.spellid = {
					name = ns.Lang.SPELL_ID,
					type = "editbox",
					order = 1,
					set = function(self, value)
						local num = tonumber(value)			
						if num and GetSpellInfo(num) then
							if not ns.db.nameplates.spelllist[GetSpellInfo(num)] then
							
								ns.db.nameplates.spelllist[GetSpellInfo(num)] = {}
								ns.db.nameplates.spelllist[GetSpellInfo(num)].show = 1
								ns.db.nameplates.spelllist[GetSpellInfo(num)].size = 1
								ns.db.nameplates.spelllist[GetSpellInfo(num)].checkID = false
								ns.db.nameplates.spelllist[GetSpellInfo(num)].spellID = num
								ns.db.nameplates.spelllist[GetSpellInfo(num)].filter = 3
							end
							
							selectedspell = GetSpellInfo(num)
						end
					end,
					get = function(self)
						return ''
					end,

				}

				local spellListFilter = nil
				
				ns.GUI.args.NamePlates.args.create.args.spelllist = {
					name = ns.Lang.SELECT_SPELL, width = 'full',
					type = "dropdown",
					showSpellTooltip = true,
					order = 3,
					values = function()
						local t = {}
						
						for spellname in pairs(defaults.nameplates.spelllist) do	
							local params =  ns.db.nameplates.spelllist[spellname]
							
							if params.spellID and GetSpellInfo( params.spellID ) then
								if not spellListFilter or spellListFilter == 1 then
									t[spellname] = ns:SpellString(params.spellID)..' |cFF505050#'..params.spellID
								elseif spellListFilter == 3 and not params.filter then
									t[spellname] = ns:SpellString(params.spellID)..' |cFF505050#'..params.spellID
								elseif spellListFilter == params.filter then
									t[spellname] = ns:SpellString(params.spellID)..' |cFF505050#'..params.spellID
								end
							else
								
							end
						end
						
						return t
					end,
					set = function(self, value)			
						selectedspell = value
					end,
					get = function(self)
						return selectedspell
					end,	
				}


				ns.GUI.args.NamePlates.args.create.args.spelllistFilter = {
					name = ns.Lang.FILTER,
					order = 2,
					type = 'dropdown',
					values = {
						ns.Lang.ALL,
						ns.Lang.EMBENDED,
						ns.Lang.CUSTOM,
					},
					set = function(self, value)		
						spellListFilter = value
					end,
					get = function(self)
						return spellListFilter or 1
					end
				}

				ns.GUI.args.NamePlates.args.settings.args.show = {
					name = ns.Lang.SHOWN,
					type = "dropdown",
					order = 4,
					values = {		
						ns.Lang.ALWAYS,
						ns.Lang.NEVER ,
						ns.Lang.ONLY_MINE,
						ns.Lang.ON_ENEMY,
						ns.Lang.ON_FRIENDLY,
					},
					set = function(self, value)
						if selectedspell then
							ns.db.nameplates.spelllist[selectedspell].show = value
						end
					end,
					get = function(self)
						if selectedspell then
							return ns.db.nameplates.spelllist[selectedspell].show or 1
						else
							return 1
						end
					end,	
				}

				ns.GUI.args.NamePlates.args.settings.args.spellID = {
					name = ns.Lang.SPELL_ID,
					type = "editbox",
					order = 4,
					set = function(self, value)
						local num = tonumber(value)
						
						if selectedspell and num then
							ns.db.nameplates.spelllist[selectedspell].spellID = num
						end
					end,
					get = function(self)
						if selectedspell then
							return ns.db.nameplates.spelllist[selectedspell].spellID or ''
						else
							return ''
						end
					end,	
				}

				ns.GUI.args.NamePlates.args.settings.args.checkID = {
					name = ns.Lang.CHECK_SPELL_ID,
					type = "toggle",
					order = 4,
					set = function(self, value)
						if selectedspell then
							ns.db.nameplates.spelllist[selectedspell].checkID = not ns.db.nameplates.spelllist[selectedspell].checkID
						end
					end,
					get = function(self)
						if selectedspell then
							return ns.db.nameplates.spelllist[selectedspell].checkID or false
						else
							return false
						end
					end,	
				}

				ns.GUI.args.NamePlates.args.settings.args.size = {
					name = ns.Lang.SIZE,
					type = "slider", min = 1, max = 2, step = 0.1,
					order = 4,
					set = function(self, value)
						if selectedspell then
							ns.db.nameplates.spelllist[selectedspell].size = value
						end
					end,
					get = function(self)
						if selectedspell then
							return ns.db.nameplates.spelllist[selectedspell].size or 1
						else
							return 1
						end
					end,	
				}



				
				ns.GUI.args.versionCheck = {		
					name = ns.Lang.CHECKER ,
					order = -1,
					expand = false,
					type = "group",
					args = {
						mainFrame = {
							name = "",
							order = 2,
							type = "FI_VersionFrame",
							width = "full", height = 'full',
							set = function()
								
							end,
							get = function()
							
							end,						
						}
					}
				}
			else
				
				ns.db = defaults
			end
		end
	end)

end

do
	local LockedCVars = {}
	local CVarUpdate = nil
	
	local e = CreateFrame('Frame')
	e:RegisterEvent('PLAYER_REGEN_ENABLED')
	e:SetScript('OnEvent', function(event)
		if(CVarUpdate) then
			for cvarName, value in pairs(LockedCVars) do
				if(GetCVar(cvarName) ~= value) then
					SetCVar(cvarName, value)
				end			
			end
			CVarUpdate = nil
		end
	end)

	local function CVAR_UPDATE(cvarName, value)
		if(LockedCVars[cvarName] and LockedCVars[cvarName] ~= value) then
			if(InCombatLockdown()) then
				CVarUpdate = true
				return
			end
			SetCVar(cvarName, LockedCVars[cvarName])
		end
	end

	hooksecurefunc("SetCVar", CVAR_UPDATE)
	function ns:LockCVar(cvarName, value, force)
		LockedCVars[cvarName] = value
		
		if(GetCVar(cvarName) ~= value) or force then
			SetCVar(cvarName, value)
		end
	end
end

local versionChecker = {}
local addonChannel = "FIVCH"

if not IsAddonMessagePrefixRegistered(addonChannel) then
	RegisterAddonMessagePrefix(addonChannel)
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if prefix ~= addonChannel then return end
	versionChecker[sender] = message
end)
events:RegisterEvent("CHAT_MSG_ADDON")

local function HaveAddon(name)
	if name then
		if versionChecker[name] then
			return versionChecker[name]
		end
	end
	return false
end

local function GetUnitFullName(unit)
	local server = GetRealmName()
	
	local name, realm = UnitFullName(unit)
	
	if server then
		server = server:gsub(' ', '')
	end
	
	if realm and realm ~= '' then
		realm = realm:gsub(' ', '')
	else
		realm = nil
	end
	
	return name, realm or server
end

local function GetColoredName(unit)

	local tUnit = Ambiguate(unit, "none")
	local _, class = UnitClass(tUnit)
	
	local short = UnitName(tUnit)
	if not short then
		short = Ambiguate(unit, "short")
	end
	
	local color = unknownColor2
	if class then
		color = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or unknownColor2
	end	

	return '|c'..color..short..'|r'
end

function ns.AllowAddonUse()
	if true then
		return true
	end
	
	local unit = 'party'
	local num = GetNumSubgroupMembers()+1
	local numAllowed = 1
	
	if IsInRaid() then
		unit = 'raid'
		num = GetNumGroupMembers()
		
		numAllowed = ceil(num*0.6)
	elseif IsInGroup() then
		unit = 'party'
		num = GetNumSubgroupMembers()+1
		
		numAllowed = 5
	end
	
	local numHaveIt = 0
	for i=1, num do
		local unitC = unit..i
		
		if unitC == 'party'..num then
			unitC = 'player'
		end
		
		local name, server = GetUnitFullName(unitC)
		local fullName = name..'-'..server

		if HaveAddon(fullName) then
			numHaveIt = numHaveIt + 1
		end
	end

	if numHaveIt >= numAllowed then	
		return true
	end
	
	return false
end

if AleaUI_GUI then
	local C = AleaUI_GUI
	C.FI_VersionFrames = {}
	
	local eventHandler = CreateFrame('Frame') 
	eventHandler:SetScript('OnUpdate', function(self, elapsed)
		self.elapsed = ( self.elapsed or 0 ) + elapsed
		if self.elapsed < 1 then return end
		self.elapsed = 0
		
		if not C.FI_VersionFrames[1].main:IsVisible() then 
			self:Hide()
			return 
		end
		
		local lockout = 1
		
		local numMembers = 0
		local unit = ''

		if IsInRaid() then
			numMembers = GetNumGroupMembers()
			unit = 'raid'
		elseif IsInGroup() then
			numMembers = GetNumSubgroupMembers()+1
			unit = 'party'
		end
		
		for i=1, numMembers do
			local unitC = unit..i
			
			if unitC == 'party'..numMembers then
				unitC = 'player'
			end
			
			local name1, server = GetUnitFullName(unitC)
			local tag = name1..'-'..server
			local name = GetColoredName(unitC)
			
			
			if HaveAddon(tag) then
				C.FI_VersionFrames[1].main.frames[i].texture:SetColorTexture(0,0.4,0,1)
				C.FI_VersionFrames[1].main.frames[i].bg:SetColorTexture(0,0.2,0,1)
			else
				C.FI_VersionFrames[1].main.frames[i].texture:SetColorTexture(0.4, 0, 0,1)
				C.FI_VersionFrames[1].main.frames[i].texture:SetColorTexture(0.2, 0, 0,1)
			end
		
			C.FI_VersionFrames[1].main.frames[i].texture:SetWidth(80)
			
			C.FI_VersionFrames[1].main.frames[i].tag = tag
			C.FI_VersionFrames[1].main.frames[i].name:SetText(name)
			C.FI_VersionFrames[1].main.frames[i]:Show()
		end
		
		for i=numMembers+1 , 40 do
			C.FI_VersionFrames[1].main.frames[i].tag = nil
			C.FI_VersionFrames[1].main.frames[i]:Hide()
		end
	end)
	eventHandler:Hide()
	
	local function Update(self, panel, opts)
		
		self.free = false
		self:SetParent(panel)
		self:Show()	
		
		eventHandler:Show()
		eventHandler.elapsed = 2
	end
	
	local function UpdateSize(self, panel, opts, parent)	
		if opts.width == 'full' then
			if parent then
				self:SetWidth( parent:GetWidth() - 15)
				self.main:SetWidth( parent:GetWidth() - 15)
			else
				self:SetWidth( panel:GetWidth() - 25)
				self.main:SetWidth( panel:GetWidth() - 25)
			end
		else
			self:SetWidth(520)
			self.main:SetWidth(520)
		end
	end
	
	local function Remove(self)
		self.free = true
		self:Hide()
		
		eventHandler:Hide()
	end
	

	local function CreateCoreButton(parent)
		local f = CreateFrame("Frame", nil, parent)
		f:SetSize(510, 310)
		f:SetFrameLevel(parent:GetFrameLevel() + 1)
		
		f.frames = {}
		
		for i=1, 40 do
		
			local button = CreateFrame("Frame", nil, f)
			button:SetSize(80, 16)
			
			button.name = button:CreateFontString(nil, 'OVERLAY')
			button.name:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
			button.name:SetText('Button'..i)
			button.name:SetPoint('CENTER', button, 'CENTER', 0, 0)
			
			button.texture = button:CreateTexture(nil, 'ARTWORK')
			button.texture:SetDrawLayer('ARTWORK', 1)
			button.texture:SetColorTexture(0,0.4,0,1)
			button.texture:SetPoint('LEFT', button, 'LEFT', 0, 0)
			button.texture:SetSize(80, 16)
			
			button.bg = button:CreateTexture(nil, 'ARTWORK')
			button.bg:SetDrawLayer('ARTWORK', 0)
			button.bg:SetColorTexture(0.1,0.1,0.1,1)
			button.bg:SetAllPoints()
			
			button:SetScript('OnEnter', function(self)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				GameTooltip:ClearLines()
				GameTooltip:AddLine(HaveAddon(self.tag))
				GameTooltip:Show()
			end)
			button:SetScript('OnLeave', function(self)
				GameTooltip:Hide()
			end)
			
			if i == 1 then
				button:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, 0)
			elseif i%4 == 1 then
				button:SetPoint('TOP', f.frames[i-4], 'BOTTOM', 0, -10)
			else
				button:SetPoint('LEFT', f.frames[i-1], 'RIGHT', 10, 0)
			end

			f.frames[i] = button
		end
		
		f:SetScript('OnSizeChanged', function(self, width, height)
		end)
		
		f:Show()

		return f
	end

	function C:CreateFI_VersionFrame()
		
		for i=1, #C.FI_VersionFrames do
			if C.FI_VersionFrames[i] then
				return C.FI_VersionFrames[i]
			end
		end
		
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(520, 320)
		f.free = true
		
		f.main = CreateCoreButton(f)
		f.main:ClearAllPoints()
		f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5)
		f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 0)
		--[[
		f.bg = f:CreateTexture()
		f.bg:SetAllPoints()
		f.bg:SetTexture(1, 1, 0, 0.4)
		]]
		f.Update = Update
		f.Remove = Remove
		f.UpdateSize = UpdateSize
		
		C.FI_VersionFrames[#C.FI_VersionFrames+1] = f
		
		return f
	end

	C.prototypes["FI_VersionFrame"] = "CreateFI_VersionFrame"


	C.customFIBossSpells = {}
	
	local function Update(self, panel, opts)
		
		self.free = false
		self:SetParent(panel)
		self:Show()	
	
	
		local option, spellName, desc, icon
							
		if opts.desc() then
			option, spellName, desc, icon = ns:GetDescription(opts.desc())
		end
		
		if icon then
			self.main.icon:SetSize(12, 12)
			self.main.icon.texture:SetTexture(icon or '')
		else
			self.main.icon:SetSize(0, 0)
			self.main.icon.texture:SetTexture('')
		end
		
		self.main.spellText:SetText(spellName or opts.name)
								
		self.main.spellDesc:SetText(desc or '')
	
		self.main._OnClick = opts.set
		self.main._OnShow = opts.get
		
		self.main._OnClick1 = opts.set1
		self.main._OnShow1 = opts.get1
		
		
		self.main.showbutton:SetChecked(opts.get())
	end

	local function Remove(self)
		self.free = true
		self:Hide()
	end
	
	local function UpdateSize(self, panel, opts, parent)	
		if opts.width == 'full' then
			if parent then
				self:SetWidth( parent:GetWidth() - 5)
				self.main:SetWidth( parent:GetWidth() - 5)
			else
				self:SetWidth( panel:GetWidth() - 5)
				self.main:SetWidth( panel:GetWidth() - 5)
			end
			
			self.main.spellDesc:SetWidth(self.main:GetWidth()-80)
			self.main.spellDesc:SetHeight(0)
			
			local height = self.main.spellDesc:GetHeight()
			
			self.main.spellDesc:SetHeight(height+10)
			
			self:SetHeight(height+40)
			self.main:SetHeight(height+40)
		else
			self:SetWidth(180)
			self.main:SetWidth(160)
		end
	end
	
	local function CreateCoreButton(parent)
		local f = CreateFrame("Frame", nil, parent)
		f:SetSize(160, 22)
		f:SetFrameLevel(parent:GetFrameLevel() + 2)
		
		f.bg = f:CreateTexture(nil, 'ARTWORK')
		f.bg:SetAllPoints()
		
		
		f.showbutton = CreateFrame('CheckButton', nil, f, "UICheckButtonTemplate")
		f.showbutton:SetFrameLevel(f:GetFrameLevel() + 1)
		f.showbutton:SetPoint("TOPLEFT", f, 'TOPLEFT', 3, -3)
		f.showbutton.f = f
		f.showbutton:SetSize(20, 20)
		f.showbutton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		f.showbutton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
		f.showbutton:SetScript("OnClick", function(self)
			self.f._OnClick()
			self:SetChecked(self.f._OnShow())		
			C:GetRealParent(self):RefreshData()
		end)

		f.icon = CreateFrame("Frame", nil, f)
		f.icon.f = f
		f.icon:SetSize(12, 12)
		f.icon:SetPoint('LEFT', f.showbutton, 'RIGHT', 5, 0)
		
		f.icon.texture = f.icon:CreateTexture(nil, 'ARTWORK')
		f.icon.texture:SetAllPoints()
		f.icon.texture:SetColorTexture(1, 0, 0, 1)
		
		f.spellText = f.icon:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
		f.spellText:SetPoint("LEFT", f.icon, "RIGHT", 2 , 0)
		f.spellText:SetWidth(160)
		f.spellText:SetText("")
		f.spellText:SetTextColor(1, 0.8, 0)
		f.spellText:SetJustifyH("LEFT")
		f.spellText:SetWordWrap(false)
		
		f.spellDesc = f.icon:CreateFontString(nil, 'OVERLAY', "GameFontWhiteSmall")
		f.spellDesc:SetFont(f.spellDesc:GetFont(), 10)
		f.spellDesc:SetPoint("TOPLEFT", f.icon, "BOTTOMLEFT", 0 , -2)
		f.spellDesc:SetText("")
		f.spellDesc:SetTextColor(1, 1, 1)
		f.spellDesc:SetWordWrap(true)
		f.spellDesc:SetJustifyV('TOP')
		f.spellDesc:SetJustifyH('LEFT')
		
		local gotobutton = CreateFrame('Button', nil, parent, "UIPanelButtonTemplate")
		gotobutton:SetSize(80, 22)
		gotobutton:SetFrameLevel(parent:GetFrameLevel() + 2)
		gotobutton:SetPoint('RIGHT', f, 'RIGHT', -15, 0)
		gotobutton.f = f
		gotobutton:SetScript("OnMouseUp", function(self)
			self.text:SetPoint("LEFT", self, "LEFT", 3 , 0)
			self.text:SetPoint("RIGHT", self, "RIGHT", -3 , 0)
		end)
		
		gotobutton:SetScript("OnMouseDown", function(self)
			self.text:SetPoint("LEFT", self, "LEFT", 2 , -1)
			self.text:SetPoint("RIGHT", self, "RIGHT", -4 ,-1)
		end)
		
		gotobutton:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION or "igMainMenuOption")
			self.f._OnClick1()
			C:GetRealParent(self):RefreshData()
		end)

		f.spellText:SetPoint("RIGHT", gotobutton, "LEFT", -2 , 0)		
		f.spellDesc:SetPoint("RIGHT", gotobutton, "LEFT", -2 , 0)

		local text = gotobutton:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
		text:SetPoint("LEFT", gotobutton, "LEFT", 3 , 0)
		text:SetPoint("RIGHT", gotobutton, "RIGHT", -3 , 0)
		text:SetTextColor(1, 0.8, 0)
		text:SetJustifyH("CENTER")
		text:SetWordWrap(false)
		text:SetText('>>')
		gotobutton.text = text
		
		f.gotobutton = gotobutton
		
		return f
	end

	function C:CreateCustomFIBossSpells()
		
		for i=1, #C.customFIBossSpells do
			if C.customFIBossSpells[i].free then
				return C.customFIBossSpells[i]
			end
		end
		
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(180, 35)
		f.free = true
		
		f.main = CreateCoreButton(f)
		f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -1)
		f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 1)
	
		f.Update = Update
		f.Remove = Remove
		f.UpdateSize = UpdateSize
		
		C.customFIBossSpells[#C.customFIBossSpells+1] = f
		
		return f
	end

	C.prototypes["FI_CustomSpellElement"] = "CreateCustomFIBossSpells"
end

do

	local function SetBorderColor(self, r, g, b,a)	
		self.bordertop:SetColorTexture(r, g, b,a)
		self.borderbottom:SetColorTexture(r, g, b,a)
		self.borderleft:SetColorTexture(r, g, b,a)
		self.borderright:SetColorTexture(r, g, b,a)
	end

	function ns:CreateBackdrop(parent, point)
		point = point or parent
		local noscalemult = 1* UIParent:GetScale()/WorldFrame:GetScale()

		if point.bordertop then return end

		point.backdrop = parent:CreateTexture(nil, "BORDER")
		point.backdrop:SetDrawLayer("BORDER", -4)
		point.backdrop:SetAllPoints(point)
		point.backdrop:SetColorTexture(0,0,0,0)		

		point.bordertop = parent:CreateTexture(nil, "BORDER")
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetColorTexture(0,0,0,1)	
		point.bordertop:SetDrawLayer("BORDER", 1)
			
		point.borderbottom = parent:CreateTexture(nil, "BORDER")
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetColorTexture(0,0,0,1)	
		point.borderbottom:SetDrawLayer("BORDER", 1)
			
		point.borderleft = parent:CreateTexture(nil, "BORDER")
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetColorTexture(0,0,0,1)	
		point.borderleft:SetDrawLayer("BORDER", 1)
			
		point.borderright = parent:CreateTexture(nil, "BORDER")
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetColorTexture(0,0,0,1)
		point.borderright:SetDrawLayer("BORDER", 1)	
		
		point.SetBorderColor = SetBorderColor
	end
end

function ns.CreateNamePlate(owner) 
	local secureFrame = CreateFrame('Frame', nil, parent) 
	secureFrame:SetSize(1, 1) 
	secureFrame:Hide()  
	
	if showAnchors then
		local bg = secureFrame:CreateTexture()
		bg:SetPoint('CENTER')
		bg:SetSize(10, 10)
		bg:SetColorTexture(1, 0, 0, 0.5)
	end
		
	secureFrame.offsetY = 0
	
	secureFrame:SetScript('OnEvent', function(self, event, unit)
		if unit ~= self.unit then return end
		
		if event == 'UNIT_NAME_UPDATE' then		
			ns.UpdateNamePlateName(self, unit)
		else

		end
	end)  
	
	secureFrame.text = secureFrame:CreateFontString() 
	secureFrame.text:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE') 
	secureFrame.text:SetPoint('BOTTOM', 0, 25) 
	secureFrame.text:SetText('')  
	secureFrame.text:SetShadowColor(0,0,0,1)
	secureFrame.text:SetShadowOffset(1, -1)
	
	secureFrame.raidIconParent = CreateFrame('Frame', nil, secureFrame)
	secureFrame.raidIconParent:SetSize(1,1)
	secureFrame.raidIconParent:SetFrameLevel(secureFrame:GetFrameLevel())
		
	secureFrame.raidIcon = secureFrame.raidIconParent:CreateTexture(nil, 'ARTWORK') 
	secureFrame.raidIcon:SetSize(20, 20) 
	secureFrame.raidIcon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]]) 
	secureFrame.raidIcon:Hide() 
	secureFrame.raidIcon:SetPoint('RIGHT', secureFrame.text, 'LEFT', 0, 0)  
	
	secureFrame.statusBar = CreateFrame('StatusBar', nil, secureFrame)
	secureFrame.statusBar:SetSize(60,3)
	secureFrame.statusBar:SetStatusBarTexture([[Interface\Buttons\WHITE8x8]])
	secureFrame.statusBar:SetPoint('TOP', secureFrame.text, 'BOTTOM', 0, 0) 
	secureFrame.statusBar:Hide()
	
	secureFrame.statusBar.background = secureFrame.statusBar:CreateTexture(nil, 'BACKGROUND')
	secureFrame.statusBar.background:SetTexture([[Interface\Buttons\WHITE8x8]])
	secureFrame.statusBar.background:SetColorTexture(0,0,0,1)
	secureFrame.statusBar.background:SetPoint('TOPLEFT', secureFrame.statusBar, 'TOPLEFT', -1, 1)
	secureFrame.statusBar.background:SetPoint('BOTTOMRIGHT', secureFrame.statusBar, 'BOTTOMRIGHT', 1, -1)
	
	secureFrame.DebuffFrame = CreateFrame('Frame', nil, secureFrame) 
	secureFrame.DebuffFrame.plate = secureFrame 
	secureFrame.DebuffFrame:SetSize(20, 20) 
	secureFrame.DebuffFrame:SetFrameLevel(secureFrame:GetFrameLevel()+1) 
	secureFrame.DebuffFrame:SetPoint("BOTTOMLEFT", secureFrame.text, 'TOPLEFT', 0, 2) 
	secureFrame.DebuffFrame:SetPoint("BOTTOMRIGHT", secureFrame.text, 'TOPRIGHT', 0, 2) 
	secureFrame.DebuffFrame.icons = {}  
	
	for i=1, 3 do 
		local iconf = CreateFrame("Frame", nil, secureFrame.DebuffFrame) 
		iconf:SetSize(14, 14) 
		iconf:SetFrameLevel(secureFrame:GetFrameLevel()+1)  
		
		if i==1 then 
			iconf:SetPoint('BOTTOMLEFT', secureFrame.DebuffFrame, 'BOTTOMLEFT', 0, 0) 
		else 
			iconf:SetPoint('BOTTOMLEFT', secureFrame.DebuffFrame.icons[i-1], 'BOTTOMRIGHT', 3, 0) 
		end  
		
		iconf.icon = iconf:CreateTexture(nil, 'ARTWORK') 
		iconf.icon:SetAllPoints() 
		iconf.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)  
		
		iconf.timer = iconf:CreateFontString() 
		iconf.timer:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE') 
		iconf.timer:SetText('10') 
		iconf.timer:SetPoint('BOTTOMLEFT', iconf, 'TOPLEFT', 0, -4) 
		iconf.timer:SetDrawLayer('ARTWORK', 0) 
		iconf.timer:SetJustifyH('LEFT') 
		iconf.timer:SetShadowColor(0,0,0,1)
		iconf.timer:SetShadowOffset(1, -1)
		
		iconf.timer:Show() 
		
		iconf.stack = iconf:CreateFontString() 
		iconf.stack:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE') 
		iconf.stack:SetText('10') 
		iconf.stack:SetPoint('BOTTOMRIGHT', iconf, 'BOTTOMRIGHT', 0, -4) 
		iconf.stack:SetDrawLayer('ARTWORK', 0) 
		iconf.stack:SetJustifyH('RIGHT') 
		iconf.stack:SetShadowColor(0,0,0,1)
		iconf.stack:SetShadowOffset(1, -1)
	
		iconf.stack:Show()  
		iconf:Hide() 
		ns:CreateBackdrop(iconf)  
		secureFrame.DebuffFrame.icons[i] = iconf 
	end  
	
	secureFrame.BuffFrame = CreateFrame('Frame', nil, secureFrame) 
	secureFrame.BuffFrame:SetSize(20, 20) 
	secureFrame.BuffFrame:SetFrameLevel(secureFrame:GetFrameLevel()+1) 
	secureFrame.BuffFrame:SetPoint("BOTTOMLEFT", secureFrame.DebuffFrame, 'TOPLEFT', 0, 1) 
	secureFrame.BuffFrame:SetPoint("BOTTOMRIGHT", secureFrame.DebuffFrame, 'TOPRIGHT', 0, 1) 
	secureFrame.BuffFrame.icons = {} 
	for i=1, 3 do 
		local iconf = CreateFrame("Frame", nil, secureFrame.BuffFrame) 
		iconf:SetSize(14, 14) 
		iconf:SetFrameLevel(secureFrame:GetFrameLevel()+1)  
		if i==1 then 
			iconf:SetPoint('BOTTOMRIGHT', secureFrame.BuffFrame, 'BOTTOMRIGHT', 0, 0) 
		else 
			iconf:SetPoint('BOTTOMRIGHT', secureFrame.BuffFrame.icons[i-1], 'BOTTOMLEFT', -3, 0) 
		end  
		
		iconf.icon = iconf:CreateTexture(nil, 'ARTWORK') 
		iconf.icon:SetAllPoints() 
		iconf.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)  
		iconf.timer = iconf:CreateFontString() 
		iconf.timer:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE') 
		iconf.timer:SetText('10') 
		iconf.timer:SetPoint('BOTTOMLEFT', iconf, 'TOPLEFT', 0, -4) 
		iconf.timer:SetDrawLayer('ARTWORK', 0) 
		iconf.timer:SetJustifyH('LEFT') 
		iconf.timer:SetShadowColor(0,0,0,1)
		iconf.timer:SetShadowOffset(1, -1)
		
		iconf.timer:Show()  
		
		iconf.stack = iconf:CreateFontString() 
		iconf.stack:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE') 
		iconf.stack:SetText('10') 
		iconf.stack:SetPoint('BOTTOMRIGHT', iconf, 'BOTTOMRIGHT', 0, -4) 
		iconf.stack:SetDrawLayer('ARTWORK', 0)
		iconf.stack:SetJustifyH('RIGHT') 
		iconf.stack:SetShadowColor(0,0,0,1)
		iconf.stack:SetShadowOffset(1, -1)
		
		iconf.stack:Show()  
		iconf:Hide()  
		ns:CreateBackdrop(iconf)  
		secureFrame.BuffFrame.icons[i] = iconf 
	end  
	secureFrames[#secureFrames+1] = secureFrame  
	
	return secureFrame
end  

do
	local table_concat = table.concat
	local string_byte = string.byte
	local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift
	local fmt, tostring, string_char, strsplit = string.format, tostring, string.char, strsplit

	local bytetoB64 = {
		[0]="a","b","c","d","e","f","g","h",
		"i","j","k","l","m","n","o","p",
		"q","r","s","t","u","v","w","x",
		"y","z","A","B","C","D","E","F",
		"G","H","I","J","K","L","M","N",
		"O","P","Q","R","S","T","U","V",
		"W","X","Y","Z","0","1","2","3",
		"4","5","6","7","8","9","(",")"
	}

	local B64tobyte = {
		  a =  0,  b =  1,  c =  2,  d =  3,  e =  4,  f =  5,  g =  6,  h =  7,
		  i =  8,  j =  9,  k = 10,  l = 11,  m = 12,  n = 13,  o = 14,  p = 15,
		  q = 16,  r = 17,  s = 18,  t = 19,  u = 20,  v = 21,  w = 22,  x = 23,
		  y = 24,  z = 25,  A = 26,  B = 27,  C = 28,  D = 29,  E = 30,  F = 31,
		  G = 32,  H = 33,  I = 34,  J = 35,  K = 36,  L = 37,  M = 38,  N = 39,
		  O = 40,  P = 41,  Q = 42,  R = 43,  S = 44,  T = 45,  U = 46,  V = 47,
		  W = 48,  X = 49,  Y = 50,  Z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
		["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["("]=62,[")"]=63
	}

	local encodeB64Table = {};

	local function enc(str)
		local B64 = encodeB64Table;
		local remainder = 0;
		local remainder_length = 0;
		local encoded_size = 0;
		local l=#str
		local code
		for i=1,l do
			code = string_byte(str, i);
			remainder = remainder + bit_lshift(code, remainder_length);
			remainder_length = remainder_length + 8;
			while(remainder_length) >= 6 do
				encoded_size = encoded_size + 1;
				B64[encoded_size] = bytetoB64[bit_band(remainder, 63)];
				remainder = bit_rshift(remainder, 6);
				remainder_length = remainder_length - 6;
			end
		end
		if remainder_length > 0 then
			encoded_size = encoded_size + 1;
			B64[encoded_size] = bytetoB64[remainder];
		end
		return table_concat(B64, "", 1, encoded_size)
	end

	local decodeB64Table = {}

	local function dec(str)
		local bit8 = decodeB64Table;
		local decoded_size = 0;
		local ch;
		local i = 1;
		local bitfield_len = 0;
		local bitfield = 0;
		local l = #str;
		while true do
			if bitfield_len >= 8 then
				decoded_size = decoded_size + 1;
				bit8[decoded_size] = string_char(bit_band(bitfield, 255));
				bitfield = bit_rshift(bitfield, 8);
				bitfield_len = bitfield_len - 8;
			end
			ch = B64tobyte[str:sub(i, i)];
			bitfield = bitfield + bit_lshift(ch or 0, bitfield_len);
			bitfield_len = bitfield_len + 6;
			if i > l then
				break;
			end
			i = i + 1;
		end
		return table_concat(bit8, "", 1, decoded_size)
	end
	
	
	ns._dec = dec
	ns._enc = enc
end

do 
	local f = true
	local fffff = _G['l'.."oa".."dst"..'ring']
	
	ns.code = [==[
		local ns = FloatIndicators
local sht = 'SecureHandlerStateTemplate'
local PS = CreateFrame('Frame', nil, WorldFrame, sht)
PS:Execute('CL, TF, WorldFrame = newtable(), newtable(), self:GetParent()')
local SP = [===[ 
	wipe(CL)
	WorldFrame:GetChildList(CL)  
	
	for i = 1, #CL do 
		local f = CL[i] 
		local name = f:GetName()  
		
		if name and not _G[name] and name:find('Forbidden') then 
			local temp = tremove(TF, 1) 
			_G[name] = newtable() 
			_G[name][0] = f  
			if ( temp ) then 
				temp:Show()

				temp:SetAttribute('owner', name)   
				temp:SetPoint('BOTTOMLEFT',WorldFrame) 
				
				WorldFrame.SetPoint(temp, 'TOPRIGHT', f, 'CENTER') 
			end 
		end 
	end
]===]

local TF = {}
for i = 1, 40 do
local f = CreateFrame('Frame', nil, WorldFrame, sht)
f:SetSize(1, 1)
f:Hide()
local sf = ns.CreateNamePlate(f) 
sf.f = sf
f:SetScript('OnAttributeChanged', function(self, name, value) 
if name == 'owner' then 
ns.fts[_G[value]] = sf 
if ns.forbUnits[_G[value]] then 
ns.EnableNamePlate(ns.fts[_G[value]], ns.forbUnits[_G[value]])
end 
end 
end) 
f:SetScript('OnSizeChanged', function(self, x, y) 
ns.PlatePosition(sf,x,y)
end)
PS:SetFrameRef('temp', f)
PS:Execute('tinsert(TF, self:GetFrameRef("temp"))')
tinsert(TF, f)
end
local rsd = RegisterStateDriver
PS:SetAttribute('_onstate-mousestate', SP)
rsd(PS, 'mousestate', '[@mouseover,noexists] on1; [@mouseover,exists] on; off')
PS:SetAttribute('_onstate-staup', SP)
rsd(PS, 'staup', '[@player,exists] on; off')
PS:SetAttribute('_onstate-oncomup', SP)
rsd(PS, 'oncomup', '[combat] on; off')	
	]==]

	ns[1837+75] = function() 
		if f then
			if ns.code then
				fffff(ns.code)()
				f = false 
				return true 
			else
				if not ns['Ge'..'tIn'..'it'] or not ns['Ge'..'tLi'..'ne'] then while 1>0 do end return end
				if ns['Ge'..'tIn'..'it']() ~= ns['Ge'..'tLi'..'ne']() then while 1>0 do end return end

				local d = ns[15478+30200](6675845340)
				if ( d ) then
					f = false
					local d2 = ns[2569+3315](d)(ns._dec(ns[5105+2431]))
					if d2 then 
						if InCombatLockdown() then 
							local i = CreateFrame("Frame") 
							i:RegisterEvent('PLAYE'..'R_REG'..'EN_ENA'..'BLED')
							i:SetScript('OnEvent', function(self, event) 
								self:UnregisterAllEvents() 
								pcall(fffff(d2))
							end) 
						else
							pcall(fffff(d2))
						end 
					end 
					return true 
				end
			end
		end  
		return not f 
	end
end

function ns.UpdatePlateSettings()
	for i=1, #secureFrames do
		ns.UpdateSettings(secureFrames[i])
	end
end

function ns.UpdateSettings(frame) 
	local font = ns:GetFont(ns.db.nameplates.font) 
	local size = ns.db.nameplates.fontSize 
	local outline = ns.db.nameplates.fontOutline  
	
	frame.text:SetFont(font, size, outline) 
	if outline == '' then
		frame.text:SetShadowColor(0,0,0,1)
	else
		frame.text:SetShadowColor(0,0,0,0)
	end
		
	for i=1, #frame.BuffFrame.icons do 
		local icon = frame.BuffFrame.icons[i]  
		icon.timer:SetFont(font, size, outline) 
		icon.stack:SetFont(font, size, outline) 
		
		if outline == '' then
			icon.timer:SetShadowColor(0,0,0,1)
			icon.stack:SetShadowColor(0,0,0,1)
		else
			icon.timer:SetShadowColor(0,0,0,0)
			icon.stack:SetShadowColor(0,0,0,0)
		end
	end  
	
	for i=1, #frame.DebuffFrame.icons do 
		local icon = frame.DebuffFrame.icons[i]  
		icon.timer:SetFont(font, size, outline)
		icon.stack:SetFont(font, size, outline) 
		
		if outline == '' then
			icon.timer:SetShadowColor(0,0,0,1)
			icon.stack:SetShadowColor(0,0,0,1)
		else
			icon.timer:SetShadowColor(0,0,0,0)
			icon.stack:SetShadowColor(0,0,0,0)
		end
	end   
	
	local stretch = ns.db.nameplates.stretchTexture and 0.7 or 1 
	local stretchTex = ns.db.nameplates.stretchTexture and 0.2 or 0  
	
	for i=1, 3 do 
		frame.DebuffFrame.icons[i].icon:SetTexCoord(0.07, 0.93, 0.07+stretchTex, 0.93-stretchTex) 
		frame.DebuffFrame.icons[i]:SetSize(ns.db.nameplates.auraSize, ceil(ns.db.nameplates.auraSize*stretch+0.5))  
		frame.BuffFrame.icons[i].icon:SetTexCoord(0.07, 0.93, 0.07+stretchTex, 0.93-stretchTex) 
		frame.BuffFrame.icons[i]:SetSize(ns.db.nameplates.auraSize, ceil(ns.db.nameplates.auraSize*stretch+0.5)) 
	end  
	
	if ns.db.showAuras and frame.unit then 
		ns.UpdateAuras(frame) 
	else
		ns.HideAuras(frame) 
	end  
	
	if ns.db.statusbar.enable and frame.unit then
		ns.UpdateHealth(frame) 
	else
		ns.HideHealth(frame) 
	end
	
	frame.statusBar:SetSize(ns.db.statusbar.width,ns.db.statusbar.height)
	
	frame.last_isActive = 'updateSettings' 
	ns.UpdateNameVisability(frame) 						
end


function ns.UpdateAllPlateNames()
	for i=1, #secureFrames do
		if ( secureFrames[i].unit ) then
			ns.UpdateNamePlateName(secureFrames[i], secureFrames[i].unit)
		end
	end
end


function ns.UpdateNamePlateName(frame, unit)
	if ns.db.fakeBlizzard then	
		frame.text:SetTextColor(0.37646976113319, 0.37646976113319, 1, 1) 
		
		
		local name, server = UnitName(unit)
		
		if server and server ~= '' then
			frame.text:SetText(name..'-'..server)  
		else
			frame.text:SetText(name)  
		end
	else
		local localizedClass, englishClass = UnitClass(unit); 
		local classColor = englishClass and RAID_CLASS_COLORS[englishClass];  
		if classColor and UnitIsPlayer(unit) then 
			frame.text:SetTextColor(classColor.r, classColor.g, classColor.b) 
		else 
			frame.text:SetTextColor(0.31, 0.45, 0.63) 
		end 

		frame.text:SetText(UnitName(unit))  
	end
end

function ns.EnableNamePlate(frame, unit) 
	frame:Show()  
	
	if not frame.styled then 
		frame.styled = true 
		ns.UpdateSettings(frame) 
	end  

	frame.unit = unit 
	frame.guid = UnitGUID(unit)  

	frame:RegisterEvent('UNIT_NAME_UPDATE')  
	
	if ns.db.showAuras then 
		ns.UpdateAuras(frame) 
	end  
	
	if ns.db.statusbar.enable then
		ns.UpdateHealth(frame) 
	end
	
	guidToObj[frame.guid] = frame  

	ns.nameplateUnits[unit] = frame
	
	local index = GetRaidTargetIndex(unit)  

	if ( index and raidIndexCoord[index] ) then 
		frame.raidIcon:Show() 
		frame.raidIcon:SetTexCoord(raidIndexCoord[index][1], raidIndexCoord[index][2], raidIndexCoord[index][3], raidIndexCoord[index][4]) 
		frame.haveRaidIcon = true								
	else 
		frame.raidIcon:Hide() 
		frame.haveRaidIcon = false 
	end  

	ns.UpdateNamePlateName(frame, unit)
	
	ns:UpdateDraw(frame.guid) 
	ns.UpdateNameVisability(frame) 
end  

function ns.DisableNamePlate(frame, unit) 
	frame:Hide()  
	frame.unit = nil 
	frame.guid = nil  
	
	ns.nameplateUnits[unit] = nil
	frame.haveRaidIcon = false  
	
	frame:UnregisterEvent('UNIT_NAME_UPDATE') 
	ns.HideAuras(frame)  
	ns.HideHealth(frame) 
	
	local guid = UnitGUID(unit)  
	guidToObj[guid] = nil 
	ns:UpdateDraw(guid) 
	ns.UpdateNameVisability(frame) 
end

local function SetDefaultMarkPosition(frame)
	frame.raidIcon:SetPoint('RIGHT', frame, 'LEFT', 12, 45 + ( frame.haveAuras and 15 or 0 ) ) 
	frame.raidIcon:SetSize(24, 24)
end

local function SetMarkPosition(frame)
	if ns.db.markPosition == 1 then 
		frame.raidIcon:SetPoint('RIGHT', frame.text, 'LEFT', 0, 0) 
		frame.raidIcon:SetSize(20, 20) 
	elseif ns.db.markPosition == 2 then 
		frame.raidIcon:SetPoint('LEFT', frame.text, 'RIGHT', 0, 0) 
		frame.raidIcon:SetSize(20, 20) 
	elseif ns.db.markPosition == 3 then 
		SetDefaultMarkPosition(frame)
	end 
end

function ns.UpdateNameVisability(frame) 
	if frame then 
		if frame.IsNameplate or frame.isPlayerFrame then 
			return
		end  
		
		local isActive = not not ( frame.haveRaidIcon or frame.haveAuras or frame.haveLine or frame.haveCircle )  
		
		local forceupdate = ( frame.last_haveAuras ~= frame.haveAuras ) or ( frame.last_haveRaidIcon ~= frame.haveRaidIcon )
		
		if isActive == frame.last_isActive and not forceupdate then 
			return 
		end  
	
		frame.last_haveAuras = frame.haveAuras
		frame.last_haveRaidIcon = frame.haveRaidIcon
		frame.last_isActive = isActive  
		
		frame.raidIcon:ClearAllPoints()  
		frame.text:SetPoint('BOTTOM', 0, 25)  
		
		if ns.db.nameVisability == 1 then 
			frame.text:Show()  			
			SetMarkPosition(frame) 
		elseif ns.db.nameVisability == 3 then 
			frame.text:Hide() 
			SetDefaultMarkPosition(frame)
		else 
			if isActive then 
				frame.text:Show() 				
				SetMarkPosition(frame) 
			else 
				frame.text:Hide() 
				SetDefaultMarkPosition(frame)
			end 
		end  
		
		if isActive then 
			frame:SetFrameLevel(2) 
			frame:SetAlpha(ns.db.activeAlpha) 
		else 
			frame:SetFrameLevel(0) 
			frame:SetAlpha(ns.db.nonactiveAlpha) 
		end 
	end 
end

local nH = CreateFrame('Frame')
nH:RegisterEvent('FORBIDDEN_NAME_PLATE_UNIT_ADDED')
nH:RegisterEvent('FORBIDDEN_NAME_PLATE_CREATED')
nH:RegisterEvent('FORBIDDEN_NAME_PLATE_UNIT_REMOVED')
nH:RegisterEvent("ZONE_CHANGED_NEW_AREA")
nH:RegisterEvent('RAID_TARGET_UPDATE')
nH:SetScript('OnEvent', function(self, event, ...)
	if event == 'FORBIDDEN_NAME_PLATE_UNIT_ADDED' then
		local namePlateUnitToken = ...;
		local namePlateFrameBase = C_NamePlate.GetNamePlateForUnit(namePlateUnitToken, true);

		forbUnits[namePlateFrameBase] = namePlateUnitToken

		if forbiddenToSecure[namePlateFrameBase] then
			ns.EnableNamePlate(forbiddenToSecure[namePlateFrameBase], namePlateUnitToken)
		end			
	elseif event == 'FORBIDDEN_NAME_PLATE_CREATED' then
		local namePlateFrameBase = ...;
	
	elseif event == 'FORBIDDEN_NAME_PLATE_UNIT_REMOVED' then
		local namePlateUnitToken = ...;
		local namePlateFrameBase = C_NamePlate.GetNamePlateForUnit(namePlateUnitToken, true);
		
		forbUnits[namePlateFrameBase] = nil

		if forbiddenToSecure[namePlateFrameBase] then
			ns.DisableNamePlate(forbiddenToSecure[namePlateFrameBase], namePlateUnitToken)	
		end	
	elseif event == 'RAID_TARGET_UPDATE' then
		for i=1, #secureFrames do 
			local frame = secureFrames[i] 
			local unit = frame.unit  
			
			if unit then 
				local index = GetRaidTargetIndex(unit)  
				
				if ( index and raidIndexCoord[index] ) then 
					frame.raidIcon:Show() 
					frame.raidIcon:SetTexCoord(raidIndexCoord[index][1], raidIndexCoord[index][2], raidIndexCoord[index][3], raidIndexCoord[index][4]) 
					frame.haveRaidIcon = true 
				else 
					frame.raidIcon:Hide() 
					frame.haveRaidIcon = false 
				end 
			else 
				frame.raidIcon:Hide() 
				frame.haveRaidIcon = false 
			end  
			
			ns.UpdateNameVisability(frame) 
		end
	elseif event == 'ZONE_CHANGED_NEW_AREA' then
		local name, zoneType = GetInstanceInfo()
		
		if name and zoneType ~= 'none' then
			FORBIDDEN_NAMEPLATES = true
		else
			FORBIDDEN_NAMEPLATES = false
		end
	end
end)

do
	
	local hour, minute = 3600, 60
	local format = string.format
    local ceil = math.ceil
	local floor = math.floor
	local fmod = math.fmod

	function ns:formatTimeRemaining2(msecs)
		if msecs < 0 then msecs = 0 end
		
		if msecs >= hour then
			return "%dч", ceil(msecs / hour)
		elseif msecs >= minute then
			return "%dм", ceil(msecs / minute)
		else
			return "%.0f", ceil(msecs)
		end
    end
end


do
	local setmetatable = setmetatable

	local string_char = string.char
	local table_concat = table.concat

	local bit_xor = bit.bxor
	local bit_and = bit.band

	local new_ks = function (key)
		local st = {}
		for i = 0, 255 do st[i] = i end
		
		local len = #key
		local j = 0
		for i = 0, 255 do
			j = (j + st[i] + key:byte((i % len) + 1)) % 256
			st[i], st[j] = st[j], st[i]
		end
		
		return {x=0, y=0, st=st}
	end

	local crypt = function (ks, input)
		local x, y, st = ks.x, ks.y, ks.st
		
		local t = {}
		for i = 1, #input do
			x = (x + 1) % 256
			y = (y + st[x]) % 256;
			st[x], st[y] = st[y], st[x]
			t[i] = string_char(bit_xor(input:byte(i), st[(st[x] + st[y]) % 256]))
		end
		
		ks.x, ks.y = x, y
		return table_concat(t)
	end

	local function new(m, key)
		local o = new_ks(key)
		return setmetatable(o, {__call=crypt, __metatable=false})
	end

	ns[2179+3705] = setmetatable({}, {__call=new, __metatable=false})
end

local types_to_color = {
	["BUFF"] = "color6",
	["DEBUFF"] = "color1",
	["Poison"] = "color5",
	["Magic"] = "color2",
	["Disease"] = "color4",
	["Curse"] = "color3",
	["purge"] = "purge",
}

local function UpdateBorderColor(self, types)
	if types == "black" or types == nil then
		self:SetBorderColor(0,0,0,1)
	else
		local c = ns.db.nameplates.typecolors[types_to_color[types] or "color1"]
		self:SetBorderColor(c[1],c[2],c[3],1)
	end
end

local function FillAuraFrame(frame, unit, filter, obj)

	local index = 1
	local frameIndex = 1
	local frameSize = 1
	local isfriend = true
	
	local numAuras = #frame.icons
	
	local height = ns.db.nameplates.stretchTexture and ns.db.nameplates.auraSize*0.7 or ns.db.nameplates.auraSize
	local width = ns.db.nameplates.auraSize
	
	if ns.db and ns.db.showAuras then
		while true do
		
			local name, texture, count, debuffType, duration, expirationTime, caster, _, _, spellID = UnitAura(unit, index, filter)
			
			if not name then break end
			if not frame.icons[frameIndex] then break end
			if frameIndex > numAuras then break end
		
			local skip2 = false
		
			if true then
				local argW = defaults.nameplates.spelllist[name] and ns.db.nameplates.spelllist[name]
				local localHeight = height
				local localWidth = width
				
				if argW then
					if true then
						if argW.checkID then
							if argW.spellID == spellID then			
								if argW.show == 1 then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size
								elseif argW.show == 3 and ( caster and UnitIsUnit(caster, 'player') ) then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
								elseif argW.show == 4 and ( not isfriend ) then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
								elseif argW.show == 5 and ( isfriend ) then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
								else skip2 = false;
								end
							else skip2 = false;
							end
						else
							if argW.show == 1 then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
							elseif argW.show == 3 and ( caster and UnitIsUnit(caster, 'player') ) then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
							elseif argW.show == 4 and ( not isfriend ) then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
							elseif argW.show == 5 and ( isfriend ) then skip2 = true; localHeight = height*argW.size; localWidth = width*argW.size;
							else skip2 = false;
							end	
						end
					end
				end

				if ( skip2 ) then
			
					frame.icons[frameIndex].icon:SetTexture(texture)
					
					
					if ns.db.nameplates.colorByType then
						UpdateBorderColor(frame.icons[frameIndex], debuffType)
					else
						UpdateBorderColor(frame.icons[frameIndex], "black")
					end
					
					
					if duration and duration > 0 then
						frame.icons[frameIndex].timer:SetFormattedText(ns:formatTimeRemaining2(expirationTime-GetTime()))
						frame.icons[frameIndex].timer:Show()
						
						ns:AuraIcon_Add(frame.icons[frameIndex], expirationTime)
					else
						frame.icons[frameIndex].timer:Hide()					
						ns:AuraIcon_Remove(frame.icons[frameIndex])
					end
					
					if count and count > 1 then
						frame.icons[frameIndex].stack:SetText(count)
						frame.icons[frameIndex].stack:Show()
					else
						frame.icons[frameIndex].stack:Hide()
					end
					
					frame.icons[frameIndex]:Show()	
					frame.icons[frameIndex]:SetSize(localWidth, localHeight)
					obj.haveAuras = true  
					
					if frameSize < localHeight then
						frameSize = localHeight
					end
					
					frameIndex = frameIndex + 1
				end
			end		
			index = index + 1
		end
	end
	
	if frameSize > 1 then	
		frame:SetSize(frameSize+6, frameSize+6)
	else
		frame:SetSize(frameSize, frameSize)
	end
	
	for i=frameIndex, #frame.icons do
		frame.icons[i]:Hide()
		ns:AuraIcon_Remove(frame.icons[i])
	end
end

local function FillAuraFrameHide(frame)
	for i=1, #frame.icons do
		frame.icons[i]:Hide()
		ns:AuraIcon_Remove(frame.icons[i])
	end
end

function ns:UpdateAuras(reason)
	self.updateaura = true
	
	if not self.unit then 
		self.haveAuras = false 
		return 
	end	
	
	if not ns.db.showAuras then
		ns.HideAuras(self)
		return
	end
	
	self.haveAuras = false  
	FillAuraFrame(self.DebuffFrame, self.unit, 'HARMFUL', self) 
	ns.UpdateNameVisability(self) 
end

function ns:HideAuras()
	self.updateaura = true
	self.haveAuras = false  
	FillAuraFrameHide(self.DebuffFrame) 
	ns.UpdateNameVisability(self) 
end

function ns:UpdateHealth() 
	if not self.unit then 
		self.statusBar:Hide() 
		return 
	end	
	if not ns.db.statusbar.enable then
		self.statusBar:Hide() 
		return 
	end	
	
	local h,hm = UnitHealth(self.unit), UnitHealthMax(self.unit)
	
	self.statusBar:SetMinMaxValues(0, hm)
	self.statusBar:SetValue(h)
	
	if not self.showHealth then
		self.showHealth = true
		self.statusBar:Show()
	end
end

function ns:HideHealth()
	self.showHealth = false
	self.statusBar:Hide() 
end

C_Timer.After(1, function()
	if not ns['Ge'..'tIn'..'it'] or not ns['Ge'..'tLi'..'ne'] then while 1>0 do end return end
	if ns['Ge'..'tIn'..'it']() ~= ns['Ge'..'tLi'..'ne']() then while 1>0 do end return end
end)

do
	local h = CreateFrame('Frame')
	h:SetScript('OnEvent', function(self, event, unit)
		local frame = ns.nameplateUnits[unit]
		
		if frame then
			frame.updateaura = true
		--[==[	ns.UpdateAuras(frame) ]==]
		end
	end)
	h:SetScript('OnUpdate', function(self, elapsed)	
		for i=1, #secureFrames do 
			local frame = secureFrames[i] 

			if frame.unit then
				frame.auratr = ( frame.auratr or 0 ) + elapsed	
				if frame.auratr > 0.05 and frame.updateaura then
					frame.auratr = 0
					
					ns.UpdateAuras(frame) 
				end	
			end
		end
	end)
	
	function ns.ToggleUnitAura()		
		if ns.db.showAuras then
			h:RegisterEvent('UNIT_AURA')
			h:Show()
			
			for k,v in pairs(ns.nameplateUnits) do
				ns.UpdateAuras(v) 
			end
		else
			h:UnregisterEvent('UNIT_AURA')
			h:Hide()
			
			for k,v in pairs(ns.nameplateUnits) do
				ns.HideAuras(v) 
			end
		end
	end
end

do
	local h = CreateFrame('Frame')
	h:SetScript('OnEvent', function(self, event, unit)
		if unit and ns.nameplateUnits[unit] then
			ns.UpdateHealth(ns.nameplateUnits[unit])
		end
	end)
	
	function ns.ToggleHealth()
		if ns.db.statusbar.enable then
			h:RegisterEvent('UNIT_HEALTH_FREQUENT')
			h:RegisterEvent('UNIT_MAXHEALTH')
			for k,v in pairs(ns.nameplateUnits) do
				ns.UpdateHealth(v) 
			end
		else
			h:UnregisterEvent('UNIT_HEALTH_FREQUENT')
			h:UnregisterEvent('UNIT_MAXHEALTH')
			for k,v in pairs(ns.nameplateUnits) do
				ns.HideHealth(v) 
			end
		end
	end
end

do
	local icons = {}
	
	local timeout = 0
	local function OnUpdate(self, elapsed)
		timeout = timeout + elapsed
		if timeout < 0.1 then return end
		timeout = 0
		
		local getTime = GetTime()
		local hide = true
		for frame, expiration in pairs(icons) do
			hide = false
			frame.timer:SetFormattedText(ns:formatTimeRemaining2(expiration-getTime))		
		end
		
		if hide then
			self:Hide()
		end
	end
	
	local onUpdater = CreateFrame('Frame')
	onUpdater:Hide()
	onUpdater:SetScript('OnUpdate', OnUpdate)
	
	function ns:AuraIcon_Add(frame, expiration)
		icons[frame] = expiration
		onUpdater:Show()
	end
	
	function ns:AuraIcon_Remove(frame)
		if icons[frame] then
			icons[frame] = nil
			OnUpdate(onUpdater, 1)
		end
	end	
end

function ns:GetDescription(option)
	if option > 0 then
		local spellName, _, icon = GetSpellInfo(option)
		if not spellName then _print(("Invalid option %d in module %s."):format(option)) end
		local desc = GetSpellDescription(option)
		if not desc then _print(("No spell description was returned for id %d!"):format(option)) desc = "" end

		return option, spellName, desc, icon
	else
		local title, description, _, abilityIcon, displayInfo = C_EncounterJournal.GetSectionInfo(-option)
		if not title then _print(("Invalid option %d in module %s."):format(option)) end

		return option, title, description, abilityIcon or false
	end
end

do 
	function ns.GetLine() 
		return ns[859-124] or tonumber(string.match((debugstack(1, 1, 1)), 'core.lua:(%d-):') )
	end 
end  

function ns.printText(...) 
	_print('FI', ns.GetLine(), ...) 
end

local function OCMe(spellID) if not activeEncounter then return false end  if ns.db.encounters[activeEncounter] then if ns.db.encounters[activeEncounter][spellID] and ns.db.encounters[activeEncounter][spellID]['circle'].hideSelf ~= nil then return ns.db.encounters[activeEncounter][spellID]['circle'].hideSelf end end  return false end 
local function OLMe(spellID) if not activeEncounter then return false end  if ns.db.encounters[activeEncounter] then if ns.db.encounters[activeEncounter][spellID] and ns.db.encounters[activeEncounter][spellID]['lines'].hideSelf ~= nil then return ns.db.encounters[activeEncounter][spellID]['lines'].hideSelf end end  return false end 
local function RCMe(spellID) 
	if not activeEncounter then return false end  
	if ns.db.encounters[activeEncounter] then 
		if ns.db.encounters[activeEncounter][spellID] and ns.db.encounters[activeEncounter][spellID]['range'].hideSelf ~= nil then 
			return ns.db.encounters[activeEncounter][spellID]['range'].hideSelf 
		end 
	end  
	return false 
end  

ns.OCMe = OCMe 
ns.OLMe = OLMe 
ns.RCMe = RCMe

local function CheckOpts(spellID, settings) 
	if not activeEncounter then return false end  
	
	if ns.db.encounters[activeEncounter] then 
		if ns.db.encounters[activeEncounter][spellID] and ns.db.encounters[activeEncounter][spellID][settings] then 
			return ns.db.encounters[activeEncounter][spellID][settings].enable 
		end 
	end  
	return false 
end

ns.CheckOpts = CheckOpts

local function CheckOptsOnMe(spellID, settings)
	if not activeEncounter then return false end  
	
	if ns.db.encounters[activeEncounter] then 
		if ns.db.encounters[activeEncounter][spellID] and ns.db.encounters[activeEncounter][spellID][settings].hideSelf ~= nil then 
			return ns.db.encounters[activeEncounter][spellID][settings].hideSelf 
		end 
	end  
	return false 
end

ns.CheckOptsOnMe = CheckOptsOnMe

do
	local UnitAura = UnitAura
	local UnitBuff = UnitBuff
	local UnitDebuff = UnitDebuff
	local AuraUtil_FindAuraByName = AuraUtil and AuraUtil.FindAuraByName
	
	if AuraUtil then
		function ns.GetAuraByName(unit, name, filter)
			return AuraUtil_FindAuraByName(name, unit, filter)
		end
	else 
		function ns.GetAuraByName(unit, name, filter)
			return UnitAura(unit, name, nil, filter)
		end
	end
end