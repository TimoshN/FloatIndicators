local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

core.bossOrder = core.bossOrder + 1

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
	-- Аргус
	Космический луч -
	Аватара -
	Изнуряющая чума круги с цифрой + надпись Эскорт. Зеленый / Красный с эскортом
	Цепи круги + кто рвет
	кружки на бафф
	Круг на танка который танчит + стаки
]==]

local vulnerabilityIcons = {
	[255419] = { mark = 1, color = 2, text = 'Свет' }, -- Holy Vulnerability (Yellow Star)
	[255429] = { mark = 2, color = 7, text = 'Огонь' }, -- Fire Vulnerability (Orange Circle)
	[255430] = { mark = 3, color = 9, text = 'Тьма' }, -- Shadow Vulnerability (Purple Diamond)
	[255422] = { mark = 4, color = 1, text = 'Природа' }, -- Nature Vulnerability (Green Triangle)
	[255433] = { mark = 5, color = 8, text = 'Аркан' }, -- Arcane Vulnerability (Blue Moon)
	[255425] = { mark = 6, color = 4, text = 'Лёд' }, -- Frost Vulnerability (Blue Square)
	[255418] = { mark = 7, color = 3, text = 'Физика' }, -- Physical Vulnerability (Red Cross)
}


local spell={}
local function SpellName(spellid)
    spell[spellid] = spell[spellid] or GetSpellInfo(spellid)
    return spell[spellid]
end


-- 248499
-- 258838
local function GetStackFromScythe(unit)
	local name, rank, icon, count

	name, icon, count = ns.GetAuraByName(unit, (GetSpellInfo(248499)), 'HARMFUL')

	if ( name and count ) then
		return count
	end

	name, icon, count = ns.GetAuraByName(unit, (GetSpellInfo(258838)), 'HARMFUL')

	if ( name and count ) then
		return count
	end

	return 0
end

local function UpdateCircleBreakText()
	local now = GetTime()
    
    local maxunit, maxscore
    for unit, score in pairs(encounterData.list) do
        local _,_,stacks = ns.GetAuraByName(unit, SpellName(257911), 'HARMFUL') -- Unleashed rage
        if stacks then score = score + encounterData.unleashed*stacks end
        _,_,stacks = ns.GetAuraByName(unit, SpellName(257930), 'HARMFUL') -- Crushing fear
        if stacks then score = score + encounterData.crushing*stacks end
        
        -- finds player with maximum score
        if not maxscore then
            maxscore = score
            maxunit = unit
        elseif score > maxscore then
            maxscore = score
            maxunit = unit
        elseif score == maxscore and (UnitInRaid(unit) or 0) < (UnitInRaid(maxunit) or 0) then
            -- make sure to always return the first unit (by index) in case of equal score
            maxscore = score
            maxunit = unit
        end
    end
    
    for unit, score in pairs(encounterData.list) do
		local guid = UnitGUID(unit)

        if now - encounterData.phStartTime < 150 then 
			if ( encounterData.activeSentence[guid] ) then
				encounterData.activeSentence[guid].Text:SetText("|cFFFF0000BREAK|r")
			end
        elseif now - encounterData.phStartTime > 270 or ns.GetAuraByName(unit, SpellName(258000), 'HARMFUL') then 
			if ( encounterData.activeSentence[guid] ) then
				encounterData.activeSentence[guid].Text:SetText("NO BREAK" )
			end
        elseif unit == maxunit then
            if ns.GetAuraByName(unit, SpellName(257931), 'HARMFUL') then
				if ( encounterData.activeSentence[guid] ) then
					encounterData.activeSentence[guid].Text:SetText("|cFFFF0000BREAK + ESCORT|r")
				end
            else 
				if ( encounterData.activeSentence[guid] ) then
					encounterData.activeSentence[guid].Text:SetText("|cFFFF0000BREAK|r")
				end
            end
        else
			if ( encounterData.activeSentence[guid] ) then
				encounterData.activeSentence[guid].Text:SetText("NO BREAK")
			end
        end
    end
end


ns.AddEncounter(2092,{
	Enable = true,
	Name = 'Аргус',
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[248396] = { -- Изнуряющая тьма
			['circle'] = { enable = true, color = 3, desc = 248396, },			
		},
		[250669] = { -- Взрывная душа
			['circle'] = { enable = true, color = 9, desc = 250669, },			
		},
		[251570] = { -- Бомба души
			['circle'] = { enable = true, color = 3, desc = 251570, },			
		},
		[258647] = { -- Sea {rt6} Haste/Versa
			['circle'] = { enable = true, color = 4, desc = 258647, },		
		},
		[258646] = { -- Sky {rt5} Crit/Mast
			['circle'] = { enable = true, color = 6, desc = 258646, },		
		},
		[257966] = { -- Цепи
			['circle'] = { enable = true, color = 3, desc = 257966, },		
		},
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Аргус", customName = 'Текущий танк', desc = 248499 },
		},
		--[==[
		[252707] = { -- Космический луч
			['circle'] = { enable = true, color = 3, desc = 252707, },			
		},
		]==]
		--[==[
		[255199] = { -- Аватара Агграмара
			['circle'] = { enable = true, color = 3, desc = 255199, hideSelf = true },			
		},
		]==]
	},
	Handler = function(self, event, ...)

		 -- phase transition detection
		 if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local timeStamp,subevent,hideCaster,sourceGUID,sourceName,sourceFlags,sourceRaidFlags,destGUID,destName,destFlags,destRaidFlags, spellID, spellName, spellSchool, extraspellID = ...

			if subevent == "SPELL_INTERRUPT" and (spellID == 256544 or extraspellID == 256544) then
				encounterData.phStartTime = GetTime()
			elseif subevent == "SPELL_AURA_APPLIED" and spellID == 257966 then  -- Sentence: 257966

				local _,_,classid = UnitClass(destName)
				local score = encounterData.ClassScore[classid] or 0 -- prioritise squishy classes when all else are equal
				local role = UnitGroupRolesAssigned(destName)
				if role == "HEALER" then -- Avoid healers break
					score = score + encounterData.healer
				end
				if ns.GetAuraByName(destName, SpellName(257931), 'HARMFUL') then -- Avoid players with Fear
					score = score + encounterData.fear
				end
				
				if ns.GetAuraByName(destName, SpellName(257869), 'HARMFUL') then -- Prioritise players with Rage
					score = score + encounterData.rage
				end
				encounterData.list[destName] = score
			elseif subevent == "SPELL_AURA_REMOVED" and spellID == 257966 then
				encounterData.list[destName] = nil
			end
		end
	

		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 248396 then
					if OC(248396) then 		
						local text = ''
						local color = 1
						
						if ns.GetAuraByName(dstName, SpellName(257931), 'HARMFUL') then
							text = 'ESCORT'
							color = 3
						end
						

						if encounterData.blackPoolsStart < GetTime() then
							print('[FI] Reset black pool counter')
							encounterData.blackPools = 0
						end
						if encounterData.blackPools == 0 then
							print('Start black pool timer')
							encounterData.blackPoolsStart = GetTime() + 10
						end

						encounterData.blackPools = encounterData.blackPools + 1


						ns.AddSpinner(dstGUID, 248396, color, { GetTime(), 8 }, 90 ).Text:SetText('#'..encounterData.blackPools..'\n'..text)
					end
				elseif spellID == 252707 then
					--[==[
					if OC(252707) then 		
						ns.SetCircle(dstGUID, 252707, 3, 90 ) 
					end
					]==]
				elseif spellID == 255199 then
					--[==[
					if OC(255199) then 		
						ns.AddSpinner(dstGUID, 255199, 2, { GetTime(), 60 }, 90 ) 
					end
					]==]
				elseif spellID == 248499 or spellID == 258838 then

					if encounterData.prev == dstGUID and encounterData.frame then
						local count = GetStackFromScythe(dstName)

						encounterData.frame.Text:SetText(count)
					end
				elseif vulnerabilityIcons[spellID] then
					ns.SetCircle(dstGUID, spellID, vulnerabilityIcons[spellID].color, 90, -100, nil, vulnerabilityIcons[spellID].text, 24)
				elseif spellID == 258646 then
					-- Молния 5сек
		
					if OC(258646) then 		
						ns.AddSpinner(dstGUID, 258646, 6, { GetTime(), 5 }, 90 ).Text:SetText('Crit/Mast')
					end
				elseif spellID == 258647 then
					-- вода 5сек
					
					if OC(258647) then 		
						ns.AddSpinner(dstGUID, 258647, 4, { GetTime(), 5 }, 90 ).Text:SetText('Haste/Versa')
					end
				elseif spellID == 251570 or spellID == 250669 then
					-- бомба 15сек
					
					if spellID == 250669 then
						if OC(250669) then 		
							local name, icon, count, debuffType, duration = ns.GetAuraByName(dstName, spellName, 'HARMFUL')
							
							ns.AddSpinner(dstGUID, 250669, 9, { GetTime(), duration }, 90 ) 
						end
					end
					
					if spellID == 251570 then
						if OC(251570) then 	
							local name, icon, count, debuffType, duration = ns.GetAuraByName(dstName, spellName, 'HARMFUL')
							
							ns.AddSpinner(dstGUID, 251570, 3, { GetTime(), duration }, 90 ) 
						end
					end
				elseif spellID == 257966 then
					if OC(257966) then 		
						encounterData.activeSentence[dstGUID] = ns.SetCircle(dstGUID, 257966, 3, 90 ) 
						UpdateCircleBreakText()
					end
				end
			elseif eventType == 'SPELL_AURA_APPLIED_DOSE' or eventType == 'SPELL_AURA_REMOVED_DOSE' then
				if spellID == 248499 or spellID == 258838 then
					if encounterData.prev == dstGUID and encounterData.frame then
						local count = GetStackFromScythe(dstName)

						encounterData.frame.Text:SetText(count)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 248396 then
					if OC(248396) then 		
						ns.RemoveSpinner(dstGUID, 248396)
					end
				elseif spellID == 250669 then
					if OC(250669) then 		
						ns.RemoveSpinner(dstGUID, 250669)
					end
				elseif spellID == 251570 then
					if OC(251570) then 		
						ns.RemoveSpinner(dstGUID, 251570)
					end
				elseif spellID == 252707 then
					--[==[
					if OC(252707) then 		
						ns.RemoveCircle(dstGUID, 252707)
					end
					]==]
				elseif spellID == 255199 then
					--[==[
					if OC(255199) then 		
						ns.RemoveSpinner(dstGUID, 255199)
					end
					]==]
				elseif spellID == 248499 or spellID == 258838 then
					if encounterData.prev == dstGUID and encounterData.frame then
						local count = GetStackFromScythe(dstName)

						encounterData.frame.Text:SetText(count)
					end
				elseif spellID == 258646 then
					if OC(258646) then 		
						ns.RemoveSpinner(dstGUID, 258646)
					end
				elseif spellID == 258647 then
					if OC(258647) then 		
						ns.RemoveSpinner(dstGUID, 258647)
					end
				elseif spellID == 257966 then
					if OC(257966) then 		
						ns.HideCircle(dstGUID, 257966)
						encounterData.activeSentence[dstGUID] = nil
						UpdateCircleBreakText()
					end
				elseif vulnerabilityIcons[spellID] then
					ns.HideCircle(dstGUID, spellID)
				end
			end
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
						local numDebuffs = GetStackFromScythe(findEm)

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
	OnEngage = function()
		encounterData.blackPools = 0
		encounterData.blackPoolsStart = 0

		encounterData.list = {}
		encounterData.activeSentence = {}

		encounterData.showAll = true -- true: show all affected names and break status; false: show "BREAK" or "DON'T BREAK" only when you are affected

		-- Do not edit below unless you know what you are doing
		encounterData.count = 0
		encounterData.last = 0
		encounterData.phStartTime = 0
		encounterData.list = {}

		-- Assigns a score for tankiness based on class, higher = squishy and preferred for breaking
		encounterData.ClassScore = {
			-1, -2, 20, -- warrior, pala, hunter
			-3, 3, -2, -- rogue, priest, dk
			3, 20, -3, -- shaman, mage, warlock
			-1, 0, -2 -- monk, druid, dh
		}

		-- Scores assigned to different conditions.
		-- Positive values means people with these debuffs/conditions are prioritised to break first.
		encounterData.healer = -10   -- Healers
		encounterData.fear = -10     -- Sargeras' fear
		encounterData.rage = 20      -- Sargeras' Rage
		encounterData.unleashed = 10 -- Unleashed Rage (per stack)
		encounterData.crushing = 10  -- Crushing Fear (per stack)

	end,
})
