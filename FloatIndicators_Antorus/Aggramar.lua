local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

core.bossOrder = core.bossOrder + 1

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
	-- Агграмар
	обжигающее -
	+ дебафф от огненной  волны маленький 244736
	+ хищное пламя 254452
]==]

ns.AddEncounter(2063,{
	Enable = true,
	Name = 'Агграмар',
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		--[==[
		[245994] = {
			['circle'] = { enable = true, color = 3, desc = 245994, },			
		},
		]==]
		[244736] = {
			['circle'] = { enable = true, color = 7, desc = 244736, },	
		}, 
		[254452] = {
			['circle'] = { enable = true, color = 3, desc = 254452, },	
		}
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 245994 then
					if OC(245994) then 		
						--[==[ns.AddSpinner(dstGUID, 245994, 3, { GetTime(), 8 }, 90 )]==]
					end
				elseif spellID == 244736 then
					if OC(244736) then 		
						ns.AddSpinner(dstGUID, 244736, 7, { GetTime(), 12 }, 40 )
					end
				elseif spellID == 254452 then
					if OC(254452) then 		
						ns.AddSpinner(dstGUID, 254452, 3, { GetTime(), 8 }, 70 )
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 245994 then
					if OC(245994) then 		
						--[==[ns.RemoveSpinner(dstGUID, 245994)]==]
					end
				elseif spellID == 244736 then
					if OC(244736) then 		
						ns.RemoveSpinner(dstGUID, 244736)
					end
				elseif spellID == 254452 then
					if OC(254452) then 		
						ns.RemoveSpinner(dstGUID, 254452)
					end
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})