local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

--[==[
	116689 -- Атриган
	116691 -- Белак
]==]

ns.AddBossPositionFix(116689, 110)
ns.AddBossPositionFix(116691, 110)

--[==[
	
	ns.RangeCheck_Update(distance) -- nil for off 
	
	ns.SetCircle(dstGUID, spellName, color, size)		
	ns.HideCircle(dstGUID, tag)
	ns.HideCircleByTag(tag) 
	
	ns.AddSpinner(dstGUID, 206847, 8, { GetTime(), 10 }, 90 ) 
	ns.RemoveSpinner(dstGUID, 206847) 
	
	ns.AddLine(srcGUID, dstGUID, tag, color) 
	ns.RemoveLine(srcGUID, dstGUID, tag) 
	ns.RemoveLineByTag(tag)
]==]

--[==[
local sharedColors = { 
	[1] = {0,1,0},								--Green
	[2] = {1,1,0},								--Yellow
	[3] = {1,0,0},								--Red
	[4] = {0,0,1},								--Blue
	[5] = {0,0,0,circleAplha=.6},				--Black
	[6] = {0,1,1},								--Blue Light
	[7] = {1,.5,0},								--Orange
	[8] = {1,0,1},								--Pink
	[9] = {.5,0,1,circleAplha=.4},				--Purple
	[10] = {.4,.9,0,circleAplha=.4},			--Dark green
	[11] = {1,1,1},								--White
	[12] = {1,1,1,lineAlpha=.4,circleAplha=.4},	--White Trans
	[13] = {.4,.4,.4},							--Grey
	[14] = {1,0,0,circleAplha=.5},				--Red Copy (range check)
	[15] = {1,1,.15,circleAplha=.5},			--Yellow Copy (range check)
	[16] = {1,.4,.4},							--Red Light
	[17] = {.72,1,.22},							--Light Green
	[18] = {.5,.15,.15},						--Dark Red
	[19] = {.15,.5,.15},						--Dark Green
}
]==]


--[==[
	233983 - дебафф на диспелл, кружок 10 ярдов 12 секунд

	241524 - каст моба 8 ярдов
	
	??? Torment soul ?? фоллоу моба ?? полосочку к кому идет
	
	233431 -- удар босса перед собой
]==]

local function GetMobID(unit)
	local _, _, _, _, _, mobId = strsplit("-", (UnitGUID(unit)))
	
	if mobId then
		return tonumber(mobId) or 0
	end
	
	return 0
end

ns.AddEncounter(2048,{
	Enable = true,
	Name = 'Демоническая инвизиция',
	order = 2, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[233983] = {
			['circle'] = { enable = true, color = 9, desc = 233983, },			
		},
	--	[241524] = {
	--		['circle'] = { enable = true, color = 3, desc = 241524, },	
	--	},
		[233431] = {
			['circle'] = { enable = true, color = 2, desc = 233431, },	
			['lines']  = { enable = true, color = 2, desc = 233431, },	
		},
		['tankCircle'] = { 
			['circle'] = { enable = true, name = 'Атриган', customName = 'Текущий танк', desc = 233426 }, 
		}, 
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 233983) then
					if OC(233983) then 
						ns.AddSpinner(dstGUID, 233983, 9, { GetTime(), 12 }, 120 ) 
					end 
				elseif (spellID == 241524) then
				--	if OC(241524) then 				
				--		ns.SetCircle(srcGUID, 241524, 3, 120)		
				--	end
				elseif spellID == 233431 then
					if OC(233431) then 				
						ns.SetCircle(dstGUID, 'CalcifiedQuills', 2, 120)		
					end
					if OL(233431) then 				
						ns.AddLine(srcGUID, dstGUID, 'CalcifiedQuills' , 2)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 233983) then
					ns.RemoveSpinner(dstGUID, 233983) 
				elseif (spellID == 241524) then
				--	if OC(241524) then 				
				--		ns.HideCircle(srcGUID, 241524)		
				--	end
				elseif spellID == 233431 then
					ns.HideCircleByTag('CalcifiedQuills') 
					ns.RemoveLineByTag('CalcifiedQuills')
				end
			end
		end
	end,
	OnUpdateHandler = function(self, elapsed) 
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed  
		if encounterData.tmr > 0.15 then 
			encounterData.tmr = 0 
			
			local bossUnit = nil
			
			for i=1, 2 do
				if not bossUnit then					
					local id = ns.GuidToID(UnitGUID("boss"..i))
					
					if id == 116689 then
						bossUnit = "boss"..i
					end
				end
			end
	
			bossUnit = bossUnit or 'boss2'
			
			if OC('tankCircle') and bossUnit then 
				local findEm = nil 
				
				for i=1,30 do 
					local isTanking = UnitDetailedThreatSituation("raid"..i, bossUnit) 
					
					if isTanking then 
						findEm = "raid"..i 
						break 
					end 
				end 
				
			--	print('Tank1:', findEm)
				
				if findEm == encounterData.prevF then 
				--	print('Tank2: return')
					return 
				elseif findEm then 
					if encounterData.prev then 
						ns.HideCircle(encounterData.prev, 'bossTarget') 
					end 
					local guid = UnitGUID(findEm)  
				
					if guid ~= UnitGUID('player') then 
						ns.SetCircle(guid, 'bossTarget', 5, 150) 
					end  
				--	print('Tank3:',findEm)
					encounterData.prev = guid 
					encounterData.prevF = findEm 
				elseif encounterData.prev then 
				--	print('Tank4:', encounterData.prev)
					ns.HideCircle(encounterData.prev, 'bossTarget') 
				end 
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget') 
			end
		end
	end,
})