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

local function IsMythic()
    local _, _, diff = GetInstanceInfo()    
    return diff == 16
end

local function GetNumVectorStacks(unit)
	local num = 0
	local findSpell = GetSpellInfo(265129)
	local endTime1 = GetTime()+50
	local dur = IsMythic() and 14 or 10

	local guid = UnitGUID(unit)

	for i=1, 40 do 
		local name,icon,count,debuffType, duration, endTime = UnitDebuff(unit, i) 

		if not name then 
			break
		end

		if name == findSpell then 
			num = num + 1

			if endTime1 > endTime then
				endTime1 = endTime
			end
		end
	end 

	if num > 0 then 

		local size = 14
		local text = nil

		if ( guid == UnitGUID('player') ) then
			size = 14	
			text = 'на тебе'
		end

		--print(unit, 'Timeleft', endTime1-GetTime() )

		ns.AddSpinner(guid, 267160, 1, { endTime1-dur, dur }, 60, nil, nil, 'x'..num, 12)
	else 
		ns.RemoveSpinner(guid, 267160)
	end 
end

ns.AddEncounter(2134,{
	Enable = true,
	Name = "Вектис",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[267160] = {
			['circle'] = { enable = true, color = 1, desc = 267160, },
		},
		[265212] = {
			['circle'] = { enable = true, color = 8, desc = 265212, },
		},
		[265127] = {
			['circle'] = { enable = true, color = 2, desc = 265127, },
		},
	},
	OnEngage = function(self)
		encounterData.stacks = {}
	end,
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 267160 or spellID == 265129 then
					if OC(267160) then 						
						GetNumVectorStacks(dstName) 
					end
				elseif spellID == 265212 then
					if OC(spellID) then 	
						
						local size = nil
						local text = nil

						if ( dstGUID == UnitGUID('player') ) then
							size = 20	
							text = 'на тебе'
						end


						ns.AddSpinner(dstGUID, spellID, 8, { GetTime(), 10 }, 90, nil, nil, text, size)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 267160 or spellID == 265129 then
					if OC(267160) then 	
						GetNumVectorStacks(dstName) 
					end
				elseif spellID == 265212 then
					if OC(spellID) then 	
						ns.RemoveSpinner(dstGUID, spellID)
					end
				end
			elseif eventType == 'SPELL_AURA_APPLIED_DOSE' or eventType == 'SPELL_AURA_REMOVED_DOSE' then
				if spellID == 265127 and IsMythic() and OC(265127) then		
					--[==[			
					if amount > 5 and amount < 12 then
						ns.SetCircle(dstGUID, spellID, 2, 40, nil, nil, 'aoe', 10)
					elseif amount > 11 then
						ns.SetCircle(dstGUID, spellID, 7, 40, nil, nil, 'add', 10)
					else
						ns.HideCircle(dstGUID, spellID)
					end
					]==]

					encounterData.stacks[dstGUID] = amount
				end
			elseif eventType == 'SPELL_CAST_START' then 
				if spellID == 267242 and IsMythic() and OC(265127) then 
				--	print('Start cast')

					for dstGUID,amount in pairs(encounterData.stacks) do 
						if amount > 5 and amount < 12 then
							ns.SetCircle(dstGUID, 265127, 2, 40, nil, nil, 'aoe', 10)
						elseif amount > 11 then
							ns.SetCircle(dstGUID, 265127, 7, 40, nil, nil, 'add', 10)
						else
							ns.HideCircle(dstGUID, 265127)
						end
					end

					C_Timer.After(4, function() 
						for dstGUID,amount in pairs(encounterData.stacks) do 
							ns.HideCircle(dstGUID, 265127)
						end
					end)
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})