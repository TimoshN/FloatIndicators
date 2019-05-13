local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

local IsAddonMessagePrefixRegistered = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered or IsAddonMessagePrefixRegistered
local RegisterAddonMessagePrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage

ns.AddBossPositionFix(117269, 120)
--ns.AddBossPositionFix(119107, 80)

RegisterAddonMessagePrefix("KJ_ARM_SOAK")
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
	234310 - дебафф от армагеддона
	240916 - дебафф от армагеддона танков
	238505 - дебафф прострела
	
	238502 - прострел
	
	236710 - Взрывное темное отражение -- ДД
	237590 - Обреченное темное отражение -- Хилерский
	236378 - Танковский
	
	
	243536 - дебафф после адда Мифик
]==]


local function DamageAddSpawnCounter(emit)
	local _, _, _, _, duration, expires = ns.GetAuraByName('player', (GetSpellInfo(236710)), 'HARMFUL')
	
	if expires then	
		return ceil(expires-GetTime())
	end
	
	return 0
end

local function HealAddSpawnCounter(emit)
	local _, _, _, _, duration, expires = ns.GetAuraByName('player', (GetSpellInfo(237590)), 'HARMFUL')
	
	if expires then	
		return ceil(expires-GetTime())
	end
	
	return 0
end
	
	
		
local function IsMythic()
    local _, _, diff = GetInstanceInfo()    
    return diff == 16
end

local function GetPlayerRole(unit)
    local role = UnitGroupRolesAssigned(unit)
    if role ~= "DAMAGER" then
        --HEALER, TANK, NONE
        return 10
    else
        local _,class = UnitClass(unit)
        local isMelee = (class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or class == "DEMONHUNTER")
        if class == "SHAMAN" then
            if (UnitPowerMax(unit,0) or 500001) < 500000 then
                isMelee = true
            else
                isMelee = false
            end
        elseif class == "HUNTER" then
            isMelee = false
        elseif class == "DRUID" then
            if UnitPowerType(unit) == 3 then
                isMelee = true
            else
                isMelee = false
            end
        end
        if isMelee then
            return 1
        else
            return 2
        end
    end
end

local reflectionName = GetSpellInfo( 236710 )

local function SortMarkTable(name1, name2)
	local role1 = GetPlayerRole(name1)
	local role2 = GetPlayerRole(name2)
	
	role1 = role1 or 10
	role2 = role2 or 10
	
	return role1 < role2
end

local armageddonCount = 1 
local intermission = false
local stage = 1
local armageddonTimers = { -- +8 seconds per timer
	{11, 54.0, 38}, -- Stage 1
	{18.4, 32, 45, 33, 36, 36, 47, 32, 45}, -- Stage 2
}
local totalArmageddons = 1
local timerOffset = 8
local nextCast = 0

ns.AddEncounter(2051,{
	Enable = true,
	Name = "Кил'джеден",
	order = 9, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED", 'CHAT_MSG_RAID_BOSS_EMOTE', 'CHAT_MSG_RAID_BOSS_WHISPER', 'CHAT_MSG_ADDON', 'INSTANCE_ENCOUNTER_ENGAGE_UNIT' },
	Settings = {
	--	[234310] = {
	--		['circle'] = { enable = true, color = 2, desc = 234310, },
	--	},
		[238502] = {
			['circle'] = { enable = true, color = 7, desc = 238502, },
			['range']  = { enable = true }, 
			['lines']  = { enable = true, color = 7, desc = 238502, },
		},
		[236710] = {
			['circle'] = { enable = true, color = 3, desc = 236710, },
			['lines']  = { enable = true, color = 3, desc = 236710, },
		},
		[237590] = {
			['circle'] = { enable = true, color = 1, desc = 237590, },
		},
		[236378] = {
			['circle'] = { enable = true, color = 8, desc = 236378, },
		},
		['tankCircle'] = { 
			['circle'] = { enable = true, name = "Кил'джеден", customName = 'Текущий танк', desc = 239932 }, 
		}, 
		[238429] = {
			['circle'] = { enable = true, color = 16, desc = 238429, },	
		},
		[243536] = {
			['circle'] = { enable = true, color = 3, desc = 243536, },	
		},
		[240910] = {
			['circle'] = { enable = true, color = 7, desc = 240910, },	
		},
		[241564] = {
			['circle'] = { enable = true, color = 8, desc = 241564, },			
		},
	--	[239253] = {
	--		['circle'] = { enable = true, color = 8, desc = 239253, },	
	--	},
	},
	OnEngage = function(self)		
		armageddonCount = 1 
		totalArmageddons = 1
        intermission = false
        stage = 1
		
		nextCast = GetTime()+armageddonTimers[stage][armageddonCount] + timerOffset
	end,
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 236710 then
					if OC(236710) then 				

						encounterData.marks = encounterData.marks or {}
						
						encounterData.marks[#encounterData.marks+1] = dstName
						
						if #encounterData.marks == 1 then
							
							C_Timer.After(0.5, function()
								
								table.sort(encounterData.marks, SortMarkTable)
								
								for i=1, #encounterData.marks do
									local unit = encounterData.marks[i]
									local guid = UnitGUID(unit)
									local _, _, _, _, duration, expires = ns.GetAuraByName(unit, reflectionName, 'HARMFUL')
									
									--
									-- 
									-- луна рдд
									
									local markOrder = ( i == 1 and 3 or i == 2 and 4 or i == 3 and 5 )
									local mark = '|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_'..markOrder..':0|t'
									
									ns.AddSpinner(guid, 236710, 3, { GetTime(), ( expires and (expires - GetTime()) or 7.5 ) }, 90, nil, nil, mark, 30 ) 
									
									if guid == UnitGUID('player') then
										ns.EmitMessage('{rt'..markOrder..'} ДД адд - %ds {rt'..markOrder..'}', 7.5, 1, DamageAddSpawnCounter, 0)
									end
								end
							end)
						end
					end
				elseif spellID == 237590 then
					if OC(237590) then 					
						ns.AddSpinner(dstGUID, 237590, 1, { GetTime(), 8 }, 90 ) 
					end
					
					if dstGUID == UnitGUID('player') then
						ns.EmitMessage('{rt4} Хил адд - %ds {rt4}', 8, 1, HealAddSpawnCounter, 0)
					end
				elseif spellID == 239253 then
					if OC(239253) then 				
						ns.SetCircle(dstGUID, 239253, 8, 90)		
					end
				elseif spellID == 236378 then
					if OC(236378) then 				
						ns.AddSpinner(dstGUID, 236378, 8, { GetTime(), 7 }, 90, -20 ) 
					end
				elseif spellID == 243536 and IsMythic() then
					if OC(243536) then
						ns.SetCircle(dstGUID, 243536, 3, 90)	
					end
				end
				
				if encounterData.haveActiveFocused then
					if eventType == 'SPELL_AURA_APPLIED' and spellID == 244834 then
						encounterData.haveActiveFocused = false
						
						if RC(238502) then 
							ns.RangeCheck_Update()
						end
						if OC(238502) then 			
							ns.HideCircle(guid, 238502)	
						end
						if OL(238502) then					
							ns.RemoveLine(UnitGUID('boss1'), guid, 238502)
						end
					end
				end
			elseif eventType == 'UNIT_DIED' and dstGUID and dstGUID:sub(1, 6) == 'Player' and dstName and UnitInRaid(dstName) then
				ns.HideCircle(dstGUID, 243536)	
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 236710 then
					tDeleteItem(encounterData.marks, dstName)
					
					ns.RemoveSpinner(dstGUID, 236710) 
					
					if not UnitIsDeadOrGhost(dstName) and OC(243536) and IsMythic() then
						ns.SetCircle(dstGUID, 243536, 3, 90)	
					end
				elseif spellID == 237590 then
					ns.RemoveSpinner(dstGUID, 237590) 
				elseif spellID == 236378 then
					ns.RemoveSpinner(dstGUID, 236378) 
				elseif spellID == 243536 then
					ns.HideCircle(dstGUID, 243536)
				end
			elseif eventType == 'SPELL_CAST_SUCCESS' and spellID == 241564 then
				if OC(241564) then 
					C_Timer.After(1.25, function()
						ns.RemoveSpinner(srcGUID, 241564)
					end)
				end
				-- 23:51:26 SPELL_CAST_SUCCESS 241564 Жалобное отражение Элиика
				-- print(eventType, spellID, srcGUID, srcName, GetTime()-encounterData.addSpawnTime )
			end
			
			-- WA Support
			
			if eventType == "SPELL_AURA_APPLIED" and spellID == 244834 then
			--	print('[FI] KJ Phase 2 Start')
				armageddonCount = 1
				totalArmageddons = 4
				nextCast = GetTime()+6.5 + timerOffset
				intermission = true
			elseif eventType == 'SPELL_AURA_REMOVED' and spellID == 244834 then
			--	print('[FI] KJ Phase 2 End')
				stage = 2
				armageddonCount = 1
				
				nextCast = GetTime()+armageddonTimers[2][armageddonCount] + timerOffset
				intermission = false
			elseif eventType == 'SPELL_CAST_START' and spellID == 240910 then
			--	print('[FI] Cast Armageddon', totalArmageddons)
				
				if encounterData.listAddon then
				
					local list = encounterData.listAddon[totalArmageddons]
					
					if list then
						for i=1, #list do
						
							print('   ', totalArmageddons, list[i], UnitGUID(list[i]), UnitName(list[i]))
							
							local guid = UnitGUID(list[i])
							if guid and OC(240910) then
								ns.SetCircle(guid, 'ARM_SOAK', 7,  90, nil, 0.8)	
							end
						end
					
						C_Timer.After(8, function()						
							ns.HideCircleByTag('ARM_SOAK')	
						end)
					end
				end
				
				armageddonCount = armageddonCount + 1
				totalArmageddons = totalArmageddons + 1
				
				if intermission then
					if armageddonCount == 2 then
						nextCast = GetTime()+58.9 + timerOffset
					end
				else
					if not armageddonTimers[stage][armageddonCount] then
						print('[FI] Error on ', armageddonCount)
					else
						nextCast = GetTime()+armageddonTimers[stage][armageddonCount] + timerOffset
					end
				end
			end
		elseif event == 'INSTANCE_ENCOUNTER_ENGAGE_UNIT' then
			encounterData.addSpawns = encounterData.addSpawns or {}
			
			for i=1, 5 do
				local unit = 'boss'..i
				local guid = UnitGUID(unit)
				if guid and not encounterData.addSpawns[guid] and ns.GuidToID(guid) == 119107 then
					encounterData.addSpawns[guid] = true
					encounterData.addSpawnTime = GetTime()
					
					if OC(241564) then 
						ns.AddSpinner(guid, 241564, 8, { GetTime(), 15.5 }, 120, -40 ) 
						print('Summon add')		
					end		
				end
			end
		elseif event == 'CHAT_MSG_RAID_BOSS_EMOTE' then
			local msg, npc, _, _, target = ...
			-- 18:33:27 For 238502 CHAT_MSG_RAID_BOSS_EMOTE %s выбирает Айсфриз целью для [сосредоточенного пламени ужаса]! Айсфриз Player-1625-06C5CB16
			if msg:find("238502") then -- Focused Dreadflame Target
				local guid = UnitGUID(target)
				
				if not guid then
					print("Error to find guid for ", target)
					return
				end
				
				if OC(238502) then 				
					ns.SetCircle(guid, 238502, 7, 120)		
				end
				if ( RC(238502) ) then 
					ns.RangeCheck_Update(5)
				end
				if ( OL(238502) ) then
					ns.AddLine(UnitGUID('boss1'), guid, 238502, 7)	
				end
				
				encounterData.haveActiveFocused = true
				
				C_Timer.After(5, function()
					if encounterData.haveActiveFocused then
						encounterData.haveActiveFocused = false
						
						if RC(238502) then 
							ns.RangeCheck_Update()
						end
						if OC(238502) then 			
							ns.HideCircle(guid, 238502)	
						end
						if OL(238502) then					
							ns.RemoveLine(UnitGUID('boss1'), guid, 238502)
						end
					end
				end)
				
			--	print('For 238502', event, msg, target, guid)
			end
		elseif event == 'CHAT_MSG_RAID_BOSS_WHISPER' then
			local msg, npc, _, _, target = ...
			-- 18:34:24 For 238429 CHAT_MSG_RAID_BOSS_WHISPER %s выбирает вас целью для [взрывного пламени ужаса]! Тимош
			if OC(238429) then
				if msg:find("spell:238429") then
					ns.SendMessage('238429-gain', ns.ADDON_SYNC_CHANNEL1)
				end
				if msg:find("spell:238430") then
					ns.SendMessage('238429-gain', ns.ADDON_SYNC_CHANNEL1)
				end
				
			--	print('For 238429', event, msg, target)
			end
		elseif event == ns.ADDON_SYNC_CHANNEL1 then
			local msg, author = ...
			local nameSender = strsplit('-', author)
			
			local guid = nil
			for i=1, GetNumGroupMembers() do
				local unit = 'raid'..i
				
				if ( UnitName(unit) == nameSender ) then
					guid = UnitGUID(unit)						
					break
				end
			end
			
			if guid then
				if OC(238429) then 				
					ns.AddSpinner(guid, 238429, 16, { GetTime(), 5 }, 120 ) 
				end
	
				C_Timer.After(5, function()
					if OC(238429) then 	
						ns.RemoveSpinner(guid, 238429)
					end
				end)
			end
		elseif event == 'CHAT_MSG_ADDON' then
			local prefix, message = ...
			
			if prefix == 'KJ_ARM_SOAK' then			
				if message == 'STARTING' then
					encounterData.list = {}
			--		print('[FI] Start')
				elseif message == 'FINISHED' then
					encounterData.listAddon = {}
				--	print('[FI] Finish')
					for i=1, #encounterData.list do
						local msg = encounterData.list[i]
						encounterData.listAddon[i] = {}
						
				--		print('[FI] Msg', i, msg)
						for a=1, GetNumGroupMembers() do
							local unit = 'raid'..a
							local name = UnitName(unit)
							
							if msg:find(name) then
								encounterData.listAddon[i][#encounterData.listAddon[i]+1] = name
				--				print('   Add to list', i, name)
							end
						end
					end	
				else
			--		print('[FI] ', message)
					encounterData.list[#encounterData.list+1] = message       
				end
			end
		elseif event == 'UNIT_AURA' then
			local unit = ...
			local guid = UnitGUID(unit)
			
			if ns.GetAuraByName(unit, (GetSpellInfo(238505)), 'HARMFUL') and encounterData.targetSpell ~= guid then
				encounterData.targetSpell = guid
				
				if OC(238502) then 				
					ns.SetCircle(guid, 238502, 7, 120)		
				end
				if ( RC(238502) ) then 
					ns.RangeCheck_Update(5) 
				--	C_Timer.After(5, function() ns.RangeCheck_Update() end) 
				end
				if ( OL(238502) ) then
					ns.AddLine(UnitGUID('boss1'), guid, 238502, 7)	
				end
					
					
			--	print('Find target on spell', UnitName(unit))
			elseif encounterData.targetSpell == guid and not ns.GetAuraByName(unit, (GetSpellInfo(238505)), 'HARMFUL') then
				encounterData.targetSpell = nil
				
				ns.RangeCheck_Update()
				ns.HideCircle(guid, 238502)		
				ns.RemoveLine(UnitGUID('boss1'), guid, 238502)
					
			--	print('Remove target on spell', UnitName(unit))
			end
		end
	end,
	OnUpdateHandler = function(self, elapsed) 
	
		encounterData.markThrottle = ( encounterData.markThrottle or 0 ) + elapsed
		
		if encounterData.markThrottle > 0.15 then
			encounterData.markThrottle = 0
			
			local haveDebuff = ns.GetAuraByName('player', (GetSpellInfo(236710)), 'HARMFUL')
			
			encounterData.lastNumLines = encounterData.lastNumLines or 0
			
			if encounterData.lastNumLines > 0 then
				encounterData.lastNumLines = 0
				
				ns.RemoveLineByTag('line1')
				ns.RemoveLineByTag('line2')
				
			--	print('Remove lines' , 'line1', 'line2')
			end
			
			local line = 0
			
			if OL(236710) and haveDebuff then
				for i=1, 30 do
					local unit = 'raid'..i
					
					if not UnitIsUnit(unit, 'player') and ns.GetAuraByName(unit, (GetSpellInfo(236710)), 'HARMFUL') then	
						line = line + 1
						
						if IsItemInRange(21519, unit) then -- в 22х ярдах							
							ns.AddLine( UnitGUID('player'), UnitGUID(unit), 'line'..line, 3)	
						--	print('AddLine', 'line'..line)
						else
							ns.AddLine( UnitGUID('player'), UnitGUID(unit), 'line'..line, 1)	
						--	print('AddLine', 'line'..line)
						end
					end
				end
			end
			
			encounterData.lastNumLines = line
		end
		
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
					end 
					local guid = UnitGUID(findEm)  
				
					if guid ~= UnitGUID('player') then 
						ns.SetCircle(guid, 'bossTarget', 5, 150) 
					end  
				--	print('Tank3:',findEm)
					encounterData.prev = guid 
					encounterData.prevF = findEm 
				elseif encounterData.prev then 
				--	print('Tank4:', encounterData.prev)
					ns.HideCircle(encounterData.prev, 'bossTarget') 
				end 
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget') 
			end
		end
	end
})