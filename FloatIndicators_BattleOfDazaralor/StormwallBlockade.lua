local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

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

local function IsMythic()
    local _, _, diff = GetInstanceInfo()    
    return diff == 16
end

core.bossOrder = core.bossOrder + 1

ns.AddEncounter(2280,{
	Enable = true,
	Name = core.Lang.BOSS8,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[285426] = {
			['circle'] = { enable = true, color = 8,  desc = 285426, },
		},
		[285000] = {
			['circle'] = { enable = true, color = 17,  desc = 285000, },
		},
		[284361] = {
			['circle'] = { enable = true, color = 2,  desc = 284361, },
		},
		[288205] = {
			['circle'] = { enable = true, color = 3,  desc = 288205, },
		},
		[284405] = {
			['circle'] = { enable = true, color = 1,  desc = 284405, },
			['lines'] =  { enable = true, color = 1, desc = 284405, },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
            
           if ( spellID == 285426 or spellID == 285350 ) and OC(285426) then
                if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = core.Lang.CLEANING
                    if ( dstGUID == UnitGUID('player') ) then 
                        runAway = core.Lang.CLEANING..'\n'..core.Lang.ON_YOU
                    end
					
                    ns.AddSpinner(dstGUID,285426, 8,{GetTime(), 10 }, 60, nil, nil, runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 285426)
                end
			elseif spellID == 285000 and OC(285000) then
                if eventType == 'SPELL_AURA_APPLIED' or eventType == 'SPELL_AURA_APPLIED_DOSE' then
                    ns.AddSpinner(dstGUID,285000, 17,{GetTime(), 18 }, 60, nil, nil, core.Lang.SEAWEED)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 285000)
                end
			elseif spellID == 284361 and OC(284361) then
                if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = core.Lang.POOL
                    if ( dstGUID == UnitGUID('player') ) then 
                        runAway = core.Lang.POOL..'\n'..core.Lang.ON_YOU
                    end
					
                    ns.AddSpinner(dstGUID,284361, 2,{GetTime(), 2.5 }, 60, nil, nil, runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 284361)
                end
			elseif spellID == 288205 and OC(288205) then
				if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = core.Lang.SPHERE
                    if ( dstGUID == UnitGUID('player') ) then 
                        runAway = core.Lang.SPHERE..'\n'..core.Lang.ON_YOU
                    end
					
                    ns.AddSpinner(dstGUID,288205, 3,{GetTime(), 4 }, 60, nil, nil, runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 288205)
                end
			elseif spellID == 284405 or spellID == 286495 then
				if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = core.Lang.MC
                    if ( dstGUID == UnitGUID('player') ) then 
                        runAway = core.Lang.MC..'\n'..core.Lang.ON_YOU
                    end
					
					if ( OC(284405) ) then
						ns.SetCircle(dstGUID, 284405, 1, 60, nil, nil, runAway)
					end
					
					if ( OL(284405) ) then
						ns.AddLine(srcGUID, dstGUID, 284405, 1)
                    end
                elseif eventType == 'SPELL_AURA_REMOVED' then
				
                    ns.HideCircle(dstGUID, 284405)
					ns.RemoveLine(srcGUID, dstGUID, 284405) 
                end			
            end
        end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})