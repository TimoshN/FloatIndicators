local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

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

core.bossOrder = core.bossOrder + 1

ns.AddEncounter(2145,{
	Enable = true,
	Name = "Зул Перерожденный",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[273437] = { -- + 273365
			['circle'] = { enable = true, color = 3, desc = 273437, },
		},
		[274271] = {
			['circle'] = { enable = true, color = 8, desc = 274271, },
		},
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Zul", customName = 'Текущий танк', desc = 273316 },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if ( spellID == 273437 or spellID == 273365) then
					if ( OC(273437) ) then
						local size = nil
						local text = nil

						if ( dstGUID == UnitGUID('player') ) then
							size = 20	
							text = 'на тебе'
						end

						ns.AddSpinner(dstGUID, 273437, 3, { GetTime(), 10 }, 90, nil, nil, text, size)
					end
				elseif ( spellID == 274271 ) then
					if ( OC(274271) ) then
						ns.AddSpinner(dstGUID, 274271, 8, { GetTime(), 60 }, 90, nil, nil, 'Диспел')
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 273437 or spellID == 273365 then
					if OC(273437) then 	
						ns.RemoveSpinner(dstGUID, 273437)
					end
				elseif spellID == 274271 then
					if OC(274271) then 	
						ns.RemoveSpinner(dstGUID, 274271)
					end
				end
			end
		end
	end,
	OnUpdateHandler = function(self, elapsed)
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed
		if encounterData.tmr > 0.15 then
			encounterData.tmr = 0

			local bossUnit = nil
			
			for i=1, 5 do
				if not bossUnit then
					local id = ns.GuidToID(UnitGUID("boss"..i))
	
					if id == 139051 then
						bossUnit = "boss"..i
					end
				end
			end
			
			if OC('tankCircle') then
				local findEm = nil
	
				if bossUnit then
					for i=1,30 do
						local isTanking = UnitDetailedThreatSituation("raid"..i, bossUnit)

						if isTanking then
							findEm = "raid"..i
							break
						end
					end
				end
			--	print('Tank1:', findEm)

				if findEm == encounterData.prevF then
				--	print('Tank2: return')
					return
				elseif findEm then
					if encounterData.prev then
						ns.HideCircle(encounterData.prev, 'bossTarget')
						encounterData.frame = nil
					end
					local guid = UnitGUID(findEm)

					if guid ~= UnitGUID('player') then	
						encounterData.frame = ns.SetCircle(guid, 'bossTarget', 5, 150)
					end
				--	print('Tank3:',findEm)
					encounterData.prev = guid
					encounterData.prevF = findEm
				elseif encounterData.prev then
				--	print('Tank4:', encounterData.prev)
					ns.HideCircle(encounterData.prev, 'bossTarget')
					encounterData.frame = nil
				end
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget')
			end
		end
	end,
})