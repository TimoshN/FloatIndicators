local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

local OCMe = ns.OCMe
local OLMe = ns.OLMe
local RCMe = ns.RCMe


local enableSoakersMark = true
local enableColorMark = false

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
	240209 - бомба
]==]

local felSpell = GetSpellInfo(235240)
local holySpell = GetSpellInfo(235213)

local function MarkFel()	
	for i=1,30 do
		local unit = ("raid%d"):format(i)
		local guid = UnitGUID(unit)
		
		if ns.GetAuraByName(unit, felSpell, 'HARMFUL') then
			if guid == UnitGUID('player') then
				if ns.CheckOptsOnMe(235271, 'Warning') then
					ns.SetCircle(guid, 'warning', 3, 40, nil, 0.4)
				end
			else
				ns.SetCircle(guid, 'warning', 3, 40, nil, 0.4)
			end
		end
	end
end

local function MarkHoly()	
	for i=1,30 do
		local unit = ("raid%d"):format(i)
		local guid = UnitGUID(unit)
		
		if ns.GetAuraByName(unit, holySpell, 'HARMFUL') then
			if guid == UnitGUID('player') then
				if ns.CheckOptsOnMe(235271, 'Warning') then
					ns.SetCircle(guid, 'warning', 3, 40, nil, 0.4)
				end
			else
				ns.SetCircle(guid, 'warning', 3, 40, nil, 0.4)
			end
		end
	end	
end

local function IsMythic()
    local _, _, diff = GetInstanceInfo()    
    return diff == 16
end

local trottled = true
local OrderRaidMark = function()

	if not IsEncounterInProgress() then
		trottled = false
		return
	end
	
    if IsMythic() and trottled and ns.CheckOpts(235271, 'SoakMark') then
		trottled = false
		
        C_Timer.After(0.4, function()
			trottled = true
			
			ns.HideCircleByTag('soakers')	
			
			encounterData.holy = {}
			encounterData.fel = {}
			
			local j = GetNumGroupMembers()
			if j > 20 then j = 20 end
			for i=1,j do
				local name = GetRaidRosterInfo(i)
				local role = UnitGroupRolesAssigned(name)
				if UnitIsVisible(name) and role ~= "TANK" and not UnitIsDead(name) then
					if ns.GetAuraByName(name, holySpell, 'HARMFUL') then
						table.insert(encounterData.holy, name)
					elseif ns.GetAuraByName(name, felSpell, 'HARMFUL') then
						table.insert(encounterData.fel, name)
					end
				end
			end
			
			local numHoly = getn(encounterData.holy)
			local numFel = getn(encounterData.fel)
			
			
			-- ns.CheckOptsOnMe(235271, 'SoakMark')
		
			if encounterData.holy[1] then ns.SetCircle(UnitGUID(encounterData.holy[1]), 'soakers', 2, 40, nil, 0.6, '2', 32) end
			if encounterData.holy[2] then ns.SetCircle(UnitGUID(encounterData.holy[2]), 'soakers', 2, 40, nil, 0.6, '1', 32) end
			
			-- Светлый Луна Ромб Крест 5 3 7
			if encounterData.holy[numHoly] then ns.SetCircle(UnitGUID(encounterData.holy[numHoly]), 'soakers', 2, 40, nil, 0.6, '3', 32) end
			if encounterData.holy[numHoly-1] then ns.SetCircle(UnitGUID(encounterData.holy[numHoly-1]), 'soakers', 2, 40, nil, 0.6, '2', 32) end
			if encounterData.holy[numHoly-2] then ns.SetCircle(UnitGUID(encounterData.holy[numHoly-2]), 'soakers', 2, 40, nil, 0.6, '1', 32) end
			
			-- Зеленый трусы круг квадрат 4 2 6
			if encounterData.fel[1] then ns.SetCircle(UnitGUID(encounterData.fel[1]), 'soakers', 1, 40, nil, 0.6, '2', 32) end
			if encounterData.fel[2] then ns.SetCircle(UnitGUID(encounterData.fel[2]), 'soakers', 1, 40, nil, 0.6, '1', 32) end
			
			if encounterData.fel[numFel] then ns.SetCircle(UnitGUID(encounterData.fel[numFel]), 'soakers', 1, 40, nil, 0.6, '3', 32) end
			if encounterData.fel[numFel-1] then ns.SetCircle(UnitGUID(encounterData.fel[numFel-1]), 'soakers', 1, 40, nil, 0.6, '2', 32) end
			if encounterData.fel[numFel-2] then ns.SetCircle(UnitGUID(encounterData.fel[numFel-2]), 'soakers', 1, 40, nil, 0.6, '1', 32) end
        end)
    end
end

--ns.CheckOpts(230139, 'MarkGroup')
local testNewUpdate = true

ns.AddEncounter(2052,{
	Enable = true,
	Name = "Бдительная дева",
	order = 7, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[235117] = {
			['circle'] = { enable = true, color = 3, desc = 235117, hideSelf = false},
		},
	--	['felTankMark'] = {
	--		['circle'] = { enable = true, color = 1, desc = 235240, customName = 'Цвет танка', hideSelf = true },
	--	},
	--	['holyTankMark'] = {
	--		['circle'] = { enable = true, color = 2, desc = 235213, customName = 'Цвет танка', hideSelf = true },
	--	},
		
		[235271] = {
			['TankMark'] = { enable = false, name = 'TankMark', customName = 'Цвет танков', hideSelf = true }, 
			['SoakMark'] = { enable = true, name = 'SoakMark', customName = 'Назначенные игроки' }, 
			['Warning']  = { enable = false, name = 'Warning',  customName = 'Противоположный цвет',hideSelf = true, color = 3, }, 
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == 'UNIT_DIED' and dstGUID and dstGUID:sub(1, 6) == 'Player' and dstName and UnitInRaid(dstName) then
				if not testNewUpdate then
					OrderRaidMark()
				end
			end
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 235117) or (spellID == 243276) then
					if OC(235117) then 									
						if dstGUID == UnitGUID('player') then
							if OCMe(235117) then
								ns.AddSpinner(dstGUID, 235117, 3, { GetTime(), 8 }, 100 ) 
							end
						else
							ns.AddSpinner(dstGUID, 235117, 3, { GetTime(), 8 }, 100 ) 
						end
					end
				elseif (spellID == 235240) then			
					if ( UnitGroupRolesAssigned(dstName) == "TANK") then
						if ns.CheckOpts(235271, 'TankMark') then
							if dstGUID == UnitGUID('player') then
								if ns.CheckOptsOnMe(235271, 'TankMark') then
									ns.SetCircle(dstGUID, 235240, 1, 60)
								end
							else
								ns.SetCircle(dstGUID, 235240, 1, 60)
							end
						end
					end
					if ns.CheckOpts(235271, 'Warning') then
						if dstGUID == UnitGUID('player') then						
							if encounterData.markTag then
								ns.HideCircleByTag('warning')	
							end
							
							encounterData.markTag = 'green'
							
							C_Timer.After(0.4, MarkHoly)
							
						--	print('Marked as ', encounterData.markTag)
						elseif encounterData.markTag == 'yellow' then
							ns.SetCircle(dstGUID, 'warning', 3, 40, nil, 0.4)	
						end
					end
					
					OrderRaidMark()
				elseif (spellID == 235213) then			
					if ( UnitGroupRolesAssigned(dstName) == "TANK") then
						if ns.CheckOpts(235271, 'TankMark') then
							if dstGUID == UnitGUID('player') then
								if ns.CheckOptsOnMe(235271, 'TankMark') then
									ns.SetCircle(dstGUID, 235213, 2, 60)	
								end
							else
								ns.SetCircle(dstGUID, 235213, 2, 60)	
							end
						end
					end	
					if ns.CheckOpts(235271, 'Warning') then
						if dstGUID == UnitGUID('player') then						
							if encounterData.markTag then
								ns.HideCircleByTag('warning')	
							end
							
							encounterData.markTag = 'yellow'
							
							C_Timer.After(0.4, MarkFel)
						--	print('Marked as ', encounterData.markTag)
						elseif encounterData.markTag == 'green' then
							ns.SetCircle(dstGUID, 'warning', 3, 40, nil, 0.4)			
						end
					end
					
					OrderRaidMark()
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 235117) or (spellID == 243276) then		
					ns.RemoveSpinner(dstGUID, 235117)
				elseif (spellID == 235240) then
					if (UnitGroupRolesAssigned(dstName) == "TANK") then
						if ns.CheckOpts(235271, 'TankMark') then
							ns.HideCircle(dstGUID, 235240)		
						end
					end
					if ns.CheckOpts(235271, 'Warning') then
						if dstGUID == UnitGUID('player') then		
							ns.HideCircleByTag('warning')	
						elseif encounterData.markTag == 'yellow' then
							ns.HideCircle(dstGUID, 'warning')
						end
					end
					
					OrderRaidMark()
				elseif (spellID == 235213) then
					if ( UnitGroupRolesAssigned(dstName) == "TANK") then
						if ns.CheckOpts(235271, 'TankMark') then
							ns.HideCircle(dstGUID, 235213)		
						end
					end
					if ns.CheckOpts(235271, 'Warning') then
						if dstGUID == UnitGUID('player') then		
							ns.HideCircleByTag('warning')	
						elseif encounterData.markTag == 'green' then
							ns.HideCircle(dstGUID, 'warning')		
						end
					end
					
					OrderRaidMark()
				end
			end
		end
	end,
	OnUpdateHandler = function(self, elapsed)		
		self.elapsed = ( self.elapsed or 0 ) + elapsed
		
		if IsMythic() and testNewUpdate and self.elapsed > 0.1 then
			self.elapsed = 0
		
			local validUnits = -1
			
			local j = GetNumGroupMembers()
			if j > 20 then j = 20 end
			for i=1,j do
				local name = GetRaidRosterInfo(i)
				local role = UnitGroupRolesAssigned(name)
				if UnitIsVisible(name) and role ~= "TANK" and not UnitIsDead(name) then
					validUnits = validUnits + 1
				end
			end
		
			if encounterData.raidStatus == nil then
				encounterData.raidStatus = validUnits
			end
			
			if encounterData.raidStatus ~= validUnits then
				OrderRaidMark()
				encounterData.raidStatus = validUnits
				
				print('Reorder marks')
			end
		end
	end,
})