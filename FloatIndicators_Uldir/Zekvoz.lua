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

local function GetStackFromVoidLash(unit)
	local name, rank, icon, count

	name, icon, count = ns.GetAuraByName(unit, (GetSpellInfo(265268)), 'HARMFUL')

	if ( name and count ) then
		return count
	end

	return 0
end

local function IsMythic()
    local _, _, diff = GetInstanceInfo()    
    return diff == 16
end


local function EndRangeCheck()
	ns.RangeCheck_Update() 
	--print('End range check')
end

local function StartRangeCheck()
	if IsEncounterInProgress() then
	--	print('Start range check')
		ns.RangeCheck_Update(5) 

		C_Timer.After(8, EndRangeCheck)
	end
end 

local eyeThorttle = -1
local countVoids = 0

ns.AddEncounter(2136,{
	Enable = true,
	Name = "Зек'воз, глашатай Н'Зота",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[265360] = {
			['circle'] = { enable = true, color = 6, desc = 265360, },
		},
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Zek'voz", customName = 'Текущий танк', desc = 265268 },
		},
		--[==[
		[158702] = {
			['circle'] = { enable = true, color = 6, desc = 271296, }, 
			['lines']  = { enable = true, color = 6, desc = 271296, },
		},]==]
		[264382] = {
			['circle'] = { enable = true, color = 3, desc = 264382, }, 
			['range'] = { enable = true },
		},
		[265662] = {
			['circle'] = { enable = true, color = 17, desc = 265662, }, 
		}
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 265268 then
					if encounterData.prev == dstGUID and encounterData.frame then
						local count = GetStackFromVoidLash(dstName)

						encounterData.frame.Text:SetText(count)
					end
				elseif spellID == 265360 then
					if OC(spellID) then 	
						
						local size = 20
						local text = ''

						if ( dstGUID == UnitGUID('player') ) then
							size = 14	
							text = '\nна тебе'
						end

						countVoids = countVoids + 1

						if ( countVoids == 4 ) then 
							countVoids = 1
						end

						ns.AddSpinner(dstGUID, spellID, 6, { GetTime(), 12 }, 90, nil, nil, countVoids..text, size)
					end
				elseif spellID == 265662 then 
					if OC(spellID) then 
						ns.AddSpinner(dstGUID, spellID, 17, { GetTime(), 30 }, 90, nil, nil, 'мк', 14)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 265268 then
					if encounterData.prev == dstGUID and encounterData.frame then
						local count = GetStackFromVoidLash(dstName)

						encounterData.frame.Text:SetText(count)
					end
				elseif spellID == 265360 then
					if OC(spellID) then 	
						ns.RemoveSpinner(dstGUID, spellID)
					end
				elseif spellID == 265662 then 
					if OC(spellID) then 
						ns.RemoveSpinner(dstGUID, spellID)
					end
				end
			elseif eventType == 'SPELL_AURA_APPLIED_DOSE' or eventType == 'SPELL_AURA_REMOVED_DOSE' then
				if spellID == 265268  then
					if encounterData.prev == dstGUID and encounterData.frame then
						local count = GetStackFromVoidLash(dstName)

						encounterData.frame.Text:SetText(count)
					end
				end
			elseif eventType == 'SPELL_CAST_SUCCESS' then
				if spellID == 264382 and OC(spellID) then
					ns.RemoveSpinner(dstGUID, 'eye')
				end
			elseif eventType == 'SPELL_CAST_START' then

				if spellID == 264382 and RC(264382) and IsMythic() then 
				--	print('YEY cast', eyeThorttle - GetTime(), ( eyeThorttle - GetTime() ) < 0 )

					if ( eyeThorttle - GetTime() ) < 0 then 
						eyeThorttle = GetTime() + 10
						
						-- IsMythic() and 52.5 or 32.8

						local timer = IsMythic() and 52.5 or 32.8

						C_Timer.After(timer, StartRangeCheck)

					--	print('Start yey timer', timer)
					end
				end 

				if spellID == 264382 and OC(spellID) then

					C_Timer.After(0.3, function()
						local guid = UnitGUID('boss2target')
						
						if ( guid ) then
							ns.AddSpinner(guid, 'eye', 3, { GetTime(), 1.7 }, 90, nil, nil, ( UnitGUID('player') == guid and 'на тебе' or nil ), 24)
						end
					end)
				end
			end	
		end
	end,
	OnEngage = function(self)
		countVoids = 0

		-- IsMythic() and 52.5 or 32.8
		if RC(264382) and IsMythic() then 
			local timer = IsMythic() and 52.5 or 32.8

			C_Timer.After(timer-5, StartRangeCheck)

		--	print('Start yey timer', timer)
		end
	end,
	OnUpdateHandler = function(self, elapsed)
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed
		if encounterData.tmr > 0.15 then
			encounterData.tmr = 0

			local bossUnit = 'boss1'
			--[==[
			for i=1, 2 do
				if not bossUnit then
					local id = ns.GuidToID("boss"..i)

					if id == 116689 then
						bossUnit = "boss"..i
					end
				end
			end
			]==]
			if OC('tankCircle') then
				local findEm = nil

				for i=1,30 do
					local isTanking = UnitDetailedThreatSituation("raid"..i, bossUnit)

					if isTanking then
						findEm = "raid"..i
						break
					end
				end

			--	print('Tank1:', findEm)

				if findEm == encounterData.prevF then
				--	print('Tank2: return')
					return
				elseif findEm then
					if encounterData.prev then
						ns.HideCircle(encounterData.prev, 'bossTarget')
						encounterData.frame = nil
					end
					local guid = UnitGUID(findEm)

					if guid ~= UnitGUID('player') then
						local numDebuffs = GetStackFromVoidLash(findEm)

						encounterData.frame = ns.SetCircle(guid, 'bossTarget', 5, 150)
						encounterData.frame.Text:SetText(numDebuffs)
					end
				--	print('Tank3:',findEm)
					encounterData.prev = guid
					encounterData.prevF = findEm
				elseif encounterData.prev then
				--	print('Tank4:', encounterData.prev)
					ns.HideCircle(encounterData.prev, 'bossTarget')
					encounterData.frame = nil
				end
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget')
			end
		end
	end,
})