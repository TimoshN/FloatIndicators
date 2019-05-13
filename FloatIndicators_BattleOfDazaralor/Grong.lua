local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

local dungeonID
local coreSpellId, energyAOESpellId, slamSpellId, addSpawnId, addCastId, tankComboId

if UnitFactionGroup("player") == "Alliance" then
    dungeonID = 2284
    coreSpellId, energyAOESpellId, slamSpellId, addSpawnId, addCastId, tankComboId = 286434, 282399, 282543, 282526, 282533, 286450
else--Horde
    dungeonID = 2263
    coreSpellId, energyAOESpellId, slamSpellId, addSpawnId, addCastId, tankComboId = 285659, 281936, 282179, 282247, 282243, 282082
end

--[==[
	
	ns.RangeCheck_Update(distance) -- nil for off 
	
	ns.SetCircle(dstGUID, spellName, color, size)		
	ns.HideCircle(dstGUID, tag)
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

ns.AddEncounter(dungeonID,{
	Enable = true,
	Name = "Грог",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[289292] = {
            ['circle'] = { enable = true, color = 3, desc = 289292, },
        },
		[285659] = {
			['circle'] = { enable = true, color = 6, desc = 285659, },
		}
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if spellID == 289307 and OC(289292) then
					
				if eventType == 'SPELL_AURA_APPLIED' then
					local runText = dstName
					
					if ( dstGUID == UnitGUID('player') ) then
						runText = runText..'\nБеги!'
					end
						
					ns.AddSpinner(dstGUID,289292,3,{GetTime(), 5},90,nil,nil,runText)
				elseif eventType == 'SPELL_AURA_REMOVED' then
					ns.RemoveSpinner(dstGUID,289292) 
				end
			elseif spellID == 285659 and OC(285659) then
				if eventType == 'SPELL_AURA_APPLIED' then
					local _, _, _, _, duration = ns.GetAuraByName(dstName, spellName, 'HARMFUL')

					ns.AddSpinner(dstGUID, 285659,6,{GetTime(), duration},60,nil,nil,'Сфера')
				elseif eventType == 'SPELL_AURA_REMOVED' then
					ns.RemoveSpinner(dstGUID, 285659) 
				end
			end
			
			--[==[
            if eventType == 'SPELL_CAST_SUCCESS' and spellID == 289292 and OC(289292) then

                C_Timer.After(0.2, function() 
                    local guid = UnitGUID('boss1target')

                    print('Throw target', guid, UnitName('boss1target') )
                    

                    if ( guid ) then

                        local runText = ''

                        if ( guid == UnitGUID('player') ) then
                            runText = 'Беги!'
                        end

                        ns.AddSpinner(guid,289292,3,{GetTime(), 4.8},60,nil,nil,runText)

                        C_Timer.After(4.8, function() 
                            ns.RemoveSpinner(guid,289292) 
                        end)
                    end
                end)
            end
			]==]
        end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})