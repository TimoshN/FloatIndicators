local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

local dungeonID
if UnitFactionGroup("player") == "Alliance" then
	dungeonID = 2344
else--Horde
	dungeonID = 2333
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

local function ShowAuraCirce()

	local guid = UnitGUID('boss1')

	if ( encounterData.haveAura ) then
		ns.SetCircle(guid, 284436, 3, 60)
	elseif ( encounterData.showCircle ) then
		ns.SetCircle(guid, 284436, 2, 60)
	else
		ns.HideCircle(guid, 284436)
	end
end

ns.AddEncounter(2265,{
	Enable = true,
	Name = core.Lang.BOSS1,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED", 'UNIT_AURA', 'UNIT_POWER_UPDATE' },
	Settings = {
		[284436] = {
			['circle'] = { enable = true, color = 2, desc = 284436, },
		},
		[283617] = {
			['circle'] = { enable = true, color = 1, desc = 283617, },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if spellID == 284436 and OC(spellID) then
				if eventType == 'SPELL_AURA_APPLIED' then
					encounterData.haveAura = true
					
					ShowAuraCirce()
				elseif eventType == 'SPELL_AURA_REMOVED' then
					encounterData.haveAura = false
					
					ShowAuraCirce()
				end
			elseif OC(283617) then
				if spellID == 283617 then
					if eventType == 'SPELL_AURA_APPLIED' then
						ns.AddSpinner(dstGUID, 283617, 1, { GetTime(), 15 }, 60,nil,nil, core.Lang.DISPEL)

					elseif eventType == 'SPELL_AURA_REMOVED' then
						ns.RemoveSpinner(dstGUID, 283617) 
					end
				elseif ( spellID == 283619 ) then
					if eventType == 'SPELL_AURA_APPLIED' then
						ns.AddSpinner(dstGUID, 283619, 6, { GetTime(), 7 }, 60,nil,nil, core.Lang.PURGE)

					elseif eventType == 'SPELL_AURA_REMOVED' then
						ns.RemoveSpinner(dstGUID, 283619) 
					end
				end
			end
		elseif event == 'UNIT_POWER_UPDATE' then
			local unit = ...
			
			if not encounterData.haveAura and ( unit == 'boss1' ) and OC(284436) then				
				if UnitPower('boss1') > 90 then
				
					if ( not encounterData.showCircle ) then
						encounterData.showCircle = true
						
						ShowAuraCirce()
					end
				else 
					if ( encounterData.showCircle ) then
						encounterData.showCircle = false

						ShowAuraCirce()
					end
				end
			end
		end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		
	end,
})