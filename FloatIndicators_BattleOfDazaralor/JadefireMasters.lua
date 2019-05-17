local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

local dungeonID, creatureID, creatureID2, encID
if UnitFactionGroup("player") == "Alliance" then
	dungeonID, creatureID, creatureID2, encID = 2323, 144691, 144692, 2285--Ma'ra Grimfang and Anathos Firecaller
else--Horde
	dungeonID, creatureID, creatureID2, encID = 2341, 144693, 144690, 2266--Manceroy Flamefist and the Mestrah <the Illuminated>
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

ns.AddEncounter(encID,{
	Enable = true,
	Name = core.Lang.BOSS3,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
        [286988] = {
            ['circle'] = { enable = true, color = 6, desc = 286988, },
        },
        [285632] = {
            ['lines'] = { enable = true, color = 9, desc = 285632, },
        },
        [287747] = {
            ['circle'] = { enable = true, color = 17, desc = 287747, },
        }
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
           
            if spellID == 286988 and OC(286988) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID,286988,6,{GetTime(), 10},60,nil,nil,core.Lang.DISPEL)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID,286988) 
                end
            elseif spellID == 285632 and OL(285632) then
                if eventType == 'SPELL_AURA_APPLIED' then

                    if ( dstGUID == UnitGUID('player') ) then
                        ns.AddLine(srcGUID, dstGUID, 285632, 9)
                    end 
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    if ( dstGUID == UnitGUID('player') ) then
                        ns.RemoveLine(srcGUID, dstGUID, tag) 
                    end
                end
            elseif spellID == 287747 and OC(287747) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.SetCircle(dstGUID, 287747, 17, 60)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.HideCircle(dstGUID, 287747)
                end
            end
        end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})