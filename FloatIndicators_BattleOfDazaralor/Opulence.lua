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

ns.AddEncounter(2271,{
	Enable = true,
	Name = core.Lang.BOSS4,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
        [284470] = {
            ['circle'] = { enable = true, color = 6, desc = 284470, },
        },
        [287072] = {
            ['circle'] = { enable = true, color = 8, desc = 287072, },
        },
        [283507] = {
            ['circle'] = { enable = true, color = 3, desc = 283507, },
        },
        [285014] = {
            ['circle'] = { enable = true, color = 1, desc = 285014, },
        },
		[289383] = {
			['circle'] = { enable = true, color = 11, desc = 289383, },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
            
            if spellID == 284470 and OC(284470) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 284470, 6, {GetTime(), 30},80,nil,nil, core.Lang.DISPEL)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 284470)
                end
            elseif spellID == 287072 and OC(287072) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 287072, 8, {GetTime(), 12},60,nil,nil, core.Lang.POOL)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 287072)
                end
            elseif ( spellID == 283507 or spellID == 287648 ) and OC(283507) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 283507, 3, {GetTime(), 8},90,nil,nil, core.Lang.SPHERE)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 283507)
                end
            elseif spellID == 285014 and OC(285014) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 285014, 1, {GetTime(), 10},60,nil,nil, core.Lang.SHARE)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 285014)
                end
			elseif spellID == 289383 and OC(289383) then
				if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 289383, 11, {GetTime(), 6},60,nil,nil, core.Lang.SWAP)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 289383)
                end				
            end
        end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})