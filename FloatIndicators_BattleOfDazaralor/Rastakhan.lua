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

core.bossOrder = core.bossOrder + 1

ns.AddEncounter(2272,{
	Enable = true,
	Name = "Растахан",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
        [286779] = {
            ['circle'] = { enable = true, color = 12, desc = 286779, },
        },
        [284686] = {
            ['circle'] = { enable = true, color = 3, desc = 284686, },
        },
        [288449] = {
            ['circle'] = { enable = true, color = 8, desc = 288449, },
        },
        [285397] = {
            ['circle'] = { enable = true, color = 1, desc = 285397, },
        },
        [284662] = {
            ['circle'] = { enable = true, color = 2, desc = 284662, },
        },
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
           
            if spellID == 286779 and OC(286779) then
                if ( dstGUID == UnitGUID('player') ) then
                    if eventType == 'SPELL_AURA_APPLIED' then
                        ns.SetCircle(srcGUID, 286779, 12, 90, nil, nil, 'Кикни каст')
                    elseif eventType == 'SPELL_AURA_REMOVED' then
                        ns.HideCircle(srcGUID, 286779)
                    end
                end
            elseif spellID == 284686 and eventType == 'SPELL_CAST_START' and OC(284686) then
                local bossUnit = nil
			
                for i=1, 5 do
                    if not bossUnit then
                        local id = ns.GuidToID(UnitGUID("boss"..i))
        
                        if id == 146322 then
                            bossUnit = "boss"..i
                        end
                    end
                end
			
                if ( bossUnit ) then
                    C_Timer.After(0.2, function() 

                        local guid = UnitGUID(bossUnit..'target')

                        if ( guid ) then
                            ns.AddSpinner(guid, 284686, 3, {GetTime(), 4.8},90,nil,nil,'Делить')
                            C_Timer.After(4.8, function() 
                                ns.RemoveSpinner(guid, 284686)
                            end)
                        end
                    end)
                end
            elseif spellID == 288449 and OC(288449) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 288449, 8, {GetTime(), 8}, 60,nil,nil,'Портал')
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 288449)
                end 
            elseif spellID == 285397 and OC(285397) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.SetCircle(dstGUID, 285397, 1, 60, nil, nil, 'Вуду')
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.HideCircle(dstGUID, 285397)
                end 
            elseif ( spellID == 290450 or spellID == 284662 ) and OC(284662) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 290450, 2, {GetTime(), 6}, 60,nil,nil,'Луч')
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 290450)
                end 
            end
        end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})