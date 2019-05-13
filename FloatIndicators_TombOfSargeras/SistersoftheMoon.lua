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


--[==[
	231729 - лужи
	237561 - Сумеречная глефа
	237561
]==]

ns.AddEncounter(2050,{
	Enable = true,
	Name = 'Сестры Луны',
	order = 4, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[236305] = {
			['circle'] = { enable = true, color = 1, desc = 236305, },			
		},
		[237561] = {
			['lines']  = { enable = true, color = 3, desc = 237561, },
			['circle'] = { enable = true, color = 3, desc = 237561, },				
		},
		[236712] = {
			['circle'] = { enable = true, color = 6, desc = 236712, },				
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 236305) then
					if OC(236305) then 				
						ns.SetCircle(dstGUID, 236305, 4, 120)		
					end				
				elseif spellID == 237561 then
					if OL(237561) then
						ns.AddLine(srcGUID, dstGUID, spellName, 3)	
					end
					if OC(237561) then
						ns.SetCircle(dstGUID, 237561, 3, 90)	
					end
				elseif spellID == 236712 then
					if OC(236712) then 
						ns.AddSpinner(dstGUID, 236712, 6, { GetTime(), 6 }, 120 ) 
					end 
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 236305) then
					if OC(236305) then 				
						ns.HideCircle(dstGUID, 236305)		
					end
				elseif spellID == 237561 then
					ns.RemoveLine(srcGUID, dstGUID, spellName)
					ns.HideCircle(dstGUID, 237561)	
				elseif spellID == 236712 then
					ns.RemoveSpinner(dstGUID, 236712) 
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})