local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddBossPositionFix(115767, 50)

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
	230139 - выстрел
	230920 - дебафф от мурлоков
]==]

local immunes = { 1022, 196555, 642, 45438 }

local getNumberOfShotsForDifficulty = function()
    local _, _, diff = GetInstanceInfo()
    return diff == 15 and 3 or 4 -- Heroic: 3, Mythic: 4
end

local function HaveImmunity(unit)
	for i=1, #immunes do
	
		if UnitBuff(unit, (GetSpellInfo(unit))) then -- ignore me
			return truen
		end
	end
end

local myPos = 8
local buff = GetSpellInfo(239362)
local debuff = GetSpellInfo(230139)

local function Selection()
	local _, _, _, instanceId = UnitPosition("player")
	
	myPos = nil
	for i=1,30 do
		local unit = ("raid%d"):format(i)
		local _, _, _, tarInstanceId = UnitPosition(unit)
		
		if tarInstanceId == instanceId and UnitIsConnected(unit)
		and not GetPartyAssignment("MAINTANK", unit) 
		and UnitGroupRolesAssigned(unit) ~= "TANK" 
		and not ns.GetAuraByName(unit, buff, 'HARMFUL')
		and not ns.GetAuraByName(unit, debuff, 'HARMFUL')
		and not UnitIsDead(unit) then
			local pos = (#encounterData.soaker+1)%getNumberOfShotsForDifficulty() + 1
			encounterData.soaker[#encounterData.soaker+1] = {name = UnitName(unit), pos = pos, unit = unit}
			
			if UnitIsUnit(unit, "player") then
			   myPos = pos
			end
		end
	end
	
	for i=1,30 do
		local unit = ("raid%d"):format(i)
		if UnitGroupRolesAssigned(unit) == "TANK" 
		and not UnitDetailedThreatSituation(unit, 'boss1') then    
			local groups = {}        
			for a=1, #encounterData.soaker do
				local pos = encounterData.soaker[a].pos            
				groups[pos] = ( groups[pos] or 0 ) + 1
			end
			
			local lowergroup = -1
			local loweramount = 99
			
			for k,v in pairs(groups) do        
				if loweramount > v then
					loweramount = v
					lowergroup = k
				end
			end
			
			if lowergroup ~= -1 and UnitIsUnit(unit, "player") then
				myPos = lowergroup
			end
			
			encounterData.soaker[#encounterData.soaker+1] = {name = UnitName(unit), pos = lowergroup, unit = unit }
		end
	end

	return myPos
end

ns.AddEncounter(2037,{
	Enable = true,
	Name = "Госпожа Сашж'ин",
	order = 5, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[230139] = {
			['lines']  = { enable = true, color = 1, desc = 230139, },
			['circle'] = { enable = true, color = 1, desc = 230139, },			
			['MarkGroup'] = { enable = false, name = 'MarkGroup', customName = 'Цвет рейда'}, 
		},
		[230920] = {
			['circle'] = { enable = true, color = 2, desc = 230920, },
		},
		[232913] = {
			['circle'] = { enable = true, color = 7, desc = 232913, },
		},
	--	['MarkGroup'] = { 
	--		['circle'] = { enable = false, name = 'MarkGroup', customName = 'Цвет рейда'}, 
	--	}, 
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 230139) then
				
					encounterData.shors = encounterData.shors or {}
					encounterData.shors[#encounterData.shors+1] = dstName
					
					if #encounterData.shors == getNumberOfShotsForDifficulty() then
						encounterData.selectmark = Selection()
					end
					
					if #encounterData.shors == 1 then
						encounterData.soaker = encounterData.soaker or {}
						wipe(encounterData.soaker)
						
						myPos = nil
						encounterData.selectmark = nil
						
						C_Timer.After(0.7, function()
							local bossGUID = srcGUID

							
							for i=1, #encounterData.soaker do
								local pos = encounterData.soaker[i].pos
								local unit = encounterData.soaker[i].unit
								
								local color = nil
								if pos == 1 then
									-- Звезда
									color = 2
								elseif pos == 2 then
									-- Печенька
									color = 7
								elseif pos == 3 then
									-- Ромб
									color = 8
								elseif pos == 4 then
									-- Трусы
									color = 1
								end
								
								if color and ns.CheckOpts(230139, 'MarkGroup') then
									ns.SetCircle(UnitGUID(unit), 'MarkGroup', color, 40, nil, 0.5)	
								end
							end
							
							for i=1, #encounterData.shors do
								local unit = encounterData.shors[i] 
								local guid = UnitGUID(unit)
								local mark = GetRaidTargetIndex(unit)
								
								local color = 1
								local alpha = ( mark == encounterData.selectmark ) and 0.8 or nil
								local size = ( mark == encounterData.selectmark ) and 20 or nil
								
								if mark == 1 then
									-- Звезда
									color = 2
								elseif mark == 2 then
									-- Печенька
									color = 7
								elseif mark == 3 then
									-- Ромб
									color = 8
								elseif mark == 4 then
									-- Трусы
									color = 1
								end
				
								if OC(230139) then 				
									ns.SetCircle(guid, 230139, color, 90, nil, alpha)						
								end
								if OL(230139) then
									ns.AddLine(bossGUID, guid, 230139, color, nil, nil, nil, size, alpha)	
								end					
							end
						end)
					end
					--[==[
					if OC(230139) then 				
						ns.SetCircle(dstGUID, 230139, 1, 90)						
					end
					if OL(230139) then
						ns.AddLine(srcGUID, dstGUID, 230139, 1)	
					end
					]==]
				elseif spellID == 230920 then
					if OC(230920) then 				
						ns.SetCircle(dstGUID, 230920, 2, 90)						
					end
				elseif spellID == 232913 then
					if OC(232913) then 				
						ns.SetCircle(dstGUID, 232913, 7, 90)						
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 230139) then		

					tDeleteItem(encounterData.shors, dstName)
					
					ns.HideCircle(dstGUID, 230139)
					ns.RemoveLine(srcGUID, dstGUID, 230139)
					
					if #encounterData.shors == 0 then					
						for i=1, #encounterData.soaker do
							local unit = encounterData.soaker[i].unit							
							ns.HideCircle(UnitGUID(unit), 'MarkGroup')
						end
					end
				elseif spellID == 230920 then		
					ns.HideCircle(dstGUID, 230920)
				elseif spellID == 232913 then
					ns.HideCircle(dstGUID, 232913)
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})