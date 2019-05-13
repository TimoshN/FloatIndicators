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

core.bossOrder = core.bossOrder + 1

ns.AddEncounter(2128,{
	Enable = true,
	Name = "Словонный пожиратель",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" }, --"RAID_BOSS_EMOTE",  
	Settings = {
		[262313] = {
			['circle'] = { enable = true, color = 2, desc = 262313, },
		},
		[262314] = {
			['circle'] = { enable = true, color = 3, desc = 262314, },
		},
	},
	OnEngage = function(self)
		encounterData.startBoss = GetTime()

	end,
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 262313 then
					if OC(spellID) then 		
						ns.AddSpinner(dstGUID, spellID, 2, { GetTime(), 18 }, 40 )
					end
				elseif spellID == 262314 then
					if OC(spellID) then 		
						ns.AddSpinner(dstGUID, spellID, 3, { GetTime(), 6 }, 70 )
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 262313 then
					if OC(spellID) then 	
						ns.RemoveSpinner(dstGUID, spellID)
					end
				elseif spellID == 262314 then
					if OC(spellID) then 
						ns.RemoveSpinner(dstGUID, spellID)
					end
				end
			--[==[
			elseif eventType == 'SPELL_DAMAGE' then

				if encounterData.ignoreBig and not encounterData.ignoreBig[srcGUID] and spellID ~= 280705 and UnitInRaid(srcName) then
					local id = ns.GuidToID(dstGUID)

					if id == 139866 then 
						encounterData.ignoreBig[srcGUID] = GetTime()
						print('Big damaged after ', srcName, GetTime()-ns.encounterData.bigSessionStart,'by',spellName, spellID )
					end
				end

				if encounterData.ignoreSmall and not encounterData.ignoreSmall[srcGUID] and spellID ~= 280705 and UnitInRaid(srcName) then
					local id = ns.GuidToID(dstGUID)

					if id == 133492 then 
						encounterData.ignoreSmall[srcGUID] = GetTime()
						print('Small damaged after ', srcName, GetTime()-ns.encounterData.smallSessionStart,'by',spellName, spellID )
					end
				end
			]==]
			end
		elseif event == 'RAID_BOSS_EMOTE' then
			local msg = ...
			if msg then       
				if msg:find('мутировавшая биомасса') then
					encounterData.bigSessionStart = GetTime()+20
					encounterData.ignoreBig = {}

					print('Summon big:', encounterData.bigSessionStart - encounterData.startBoss )
				elseif msg:find('частицы порчи') then
					encounterData.smallSessionStart = GetTime()+10
					encounterData.ignoreSmall = {}

					print('Summon small:', encounterData.smallSessionStart - encounterData.startBoss )
				end       
			end	
		end
	end,
	OnUpdateHandler = nil,
})