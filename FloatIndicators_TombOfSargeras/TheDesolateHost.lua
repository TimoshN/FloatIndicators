local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

--[==[
118460 -- Engine of Souls
118462 -- Soul Queen Dejahna
119072 -- The Desolate Host
]==]

ns.AddBossPositionFix(118460, 100)

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
	236515 -- дебафф снятия щита
	235924 -- переход в другой мир
	
	236011 -- каст от души с пометкой
	
	+122.2, event=SPELL_AURA_APPLIED, spellID=238018, spell=Стон страдания, source=Неизвестно, sourceID=118924, target=Лантейя, targetID=0
]==]

ns.AddEncounter(2054,{
	Enable = true,
	Name = 'Сонм страданий',
	order = 6, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[236515] = {
			['circle'] = { enable = true, color = 6, desc = 236515, },			
		},
		[235924] = {
			['circle'] = { enable = true, color = 9, desc = 235924, },	
		},
		[238018] = {
			['circle'] = { enable = true, color = 8, desc = 238018, },	
			['lines']  = { enable = true, color = 8, desc = 238018, },	
		}
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 236515) then
					if OC(236515) then 				
						ns.SetCircle(dstGUID, 236515, 6, 120)		
					end				
				elseif spellID == 235924 then
					if OC(235924) then 				
						ns.AddSpinner(dstGUID, 235924, 9, { GetTime(), 6 }, 120 ) 
					end	
				elseif spellID == 238018 then
					if OC(238018) then 		
						ns.SetCircle(dstGUID, 238018, 8, 90)	
					end				
					if OL(238018) then
					
						local bossUnit = nil
			
						for i=1, 5 do
							if not bossUnit and UnitGUID("boss"..i) then					
								local id = ns.GuidToID(UnitGUID("boss"..i))
								
								if id == 118460 then
									bossUnit = "boss"..i
								end
							end
						end
						
						if bossUnit then
							ns.AddLine(UnitGUID(bossUnit), dstGUID, spellName, 8)
						end
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 236515) then
					if OC(236515) then 				
						ns.HideCircle(dstGUID, 236515)		
					end
				elseif spellID == 235924 then
					if OC(235924) then 					
						ns.RemoveSpinner(dstGUID, 235924) 
					end
				elseif spellID == 238018 then
					if OC(238018) then 				
						ns.HideCircle(dstGUID, 238018)		
					end
					if OL(238018) then
						local bossUnit = nil
			
						for i=1, 5 do
							if not bossUnit and UnitGUID("boss"..i) then					
								local id = ns.GuidToID(UnitGUID("boss"..i))
								
								if id == 118460 then
									bossUnit = "boss"..i
								end
							end
						end
						
						if bossUnit then
							ns.RemoveLine(UnitGUID(bossUnit), dstGUID, spellName)
						end
					end
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})