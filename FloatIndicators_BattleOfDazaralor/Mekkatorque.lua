local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC


ns.AddBossPositionFix(144796, 120)

--[==[
	
	ns.RangeCheck_Update(distance) -- nil for off 
	
	ns.SetCircle(owner, tag, color, size, offset, alpha, text, textSize)	
	ns.HideCircle(owner, tag)
	ns.HideCircleByTag(tag) 
	
	ns.AddSpinner(owner,tag,color,timer,size,offset,alpha,text,textSize)
	ns.RemoveSpinner(owner,tag) 
	
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

local function FindTarget()
	local unitGUID = UnitGUID('boss1target')
	local srcGUID = UnitGUID('boss1')
	
	if not encounterData.target then
		if ( unitGUID ) then
			encounterData.target = true
			
			--ns.AddLine(srcGUID, unitGUID, 282153, 8) 
			ns.SetCircle(unitGUID, 282153, 8, 60, nil, nil, core.Lang.GUN)
			
			C_Timer.After(1.5, function()
			--	ns.RemoveLine(srcGUID, unitGUID, 282153) 
				ns.HideCircle(unitGUID, 282153)
			end)
		end
	end
end

local colorOrder = { 2, 7, 8 }

ns.AddEncounter(2276,{
	Enable = true,
	Name = core.Lang.BOSS7,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
        [284168] = {
            ['circle'] = { enable = true, color = 9, desc = 284168, },
        },
        [286646] = {
            ['circle'] = { enable = true, color = 3, desc = 286646, },
        },
        [287167] = {
            ['circle'] = { enable = true, color = 12, desc = 287167, },
        },
		[282153] = {
			['circle'] = { enable = true, color = 8, desc = 282153, },
			--['lines'] = { enable = true, color = 8, desc = 282153, }, 
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
            
            if spellID == 284168 and OC(284168) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.SetCircle(dstGUID, 284168, 6, 60, nil, nil, core.Lang.MINI)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.HideCircle(dstGUID, 284168)
                end
            elseif spellID == 286646 and OC(286646) then
                if eventType == 'SPELL_AURA_APPLIED' then
					local runText = ''
					
					C_Timer.After(0.5, function()
						--[==[
						if ( not encounterData.playerMark or encounterData.playerMark == 3 ) then
							encounterData.playerMark = 0
						end
						
						encounterData.playerMark = encounterData.playerMark + 1
						]==]
						--[==[
							1 yellow
							2 orange
							3 pink
						]==]
						
						if IsEncounterInProgress() then
							local mark = GetRaidTargetIndex(dstName)
							
							if ( mark and mark > 0 ) then
								runText = '|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_'..mark..':40|t'
							end
							
							ns.AddSpinner(dstGUID,286646, colorOrder[mark] or 3,{GetTime(), 14.5 }, 90, nil,nil, runText)
						end
					end)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 286646)
                end
            elseif spellID == 287167 and OC(287167) then 
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.SetCircle(dstGUID, 287167, 12, 60, nil, nil, core.Lang.DISPEL)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.HideCircle(dstGUID, 287167)
                end
			elseif spellID == 282153 then
				if eventType == 'SPELL_CAST_START' and OC(282153) then
					
					encounterData.target = nil
					encounterData.castStarted = true
					
				
					C_Timer.After(0.3, FindTarget)				
					C_Timer.After(0.5, FindTarget)				
					C_Timer.After(1.0, FindTarget)						
				end
            end
		elseif event == 'UNIT_TARGET' then
			local unit = ...
			
			if ( unit and unit:sub(1,4) == 'boss' ) and UnitGUID(unit..'target') and not UnitDetailedThreatSituation(unit..'target', unit) then
				
				if ( encounterData.castStarted ) then
					encounterData.castStarted = nil
					
					--print(unit,  UnitName(unit..'target'))
				end
			end
        end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})