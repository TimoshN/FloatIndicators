local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddBossPositionFix(116939, 140)

local IsAddonMessagePrefixRegistered = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered or IsAddonMessagePrefixRegistered
local RegisterAddonMessagePrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage

RegisterAddonMessagePrefix("SB_TAINT_FA")

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
	239739 - бомба
	236604 - темные клинки
]==]


--[==[
cooldowns = {
    class = {
        ["MAGE"] = {
            45438, --Ice Block
        },
        ["PALADIN"] = {
            642, --Divine Shield
        },
        ["HUNTER"] = {
            186265, --Aspect of the Turtle
        },
        ["ROGUE"] = {
            31224, -- Cloak of Shadows
        },
    },
    specc = {
        [577] = { --Havoc
            196555, --Netherwalk
        },
        [258] = { -- Shadow Priest
            47585, --Dispersion
        },
    }
}
]==]

local immunities = {
	[45438] = 60*4,
	[642] = 60*5,
	[186265] = 60*3,
	[31224] = 60+30-9,
	[196555] = 60*2,
	
}

local classImmunities = {
	['MAGE'] = true,
	['PALADIN'] = true,
	['HUNTER'] = true,
	['ROGUE'] = true,
	['DEMONHUNTER'] = true,
}

local DarkMark = GetSpellInfo(239739)

local function SortMarkTable(name1, name2)
	local _, _, _, _, duration1 = ns.GetAuraByName(name1, DarkMark, 'HARMFUL')
	local _, _, _, _, duration2 = ns.GetAuraByName(name2, DarkMark, 'HARMFUL')
	
	duration1 = duration1 or 0
	duration2 = duration2 or 0
	
	return duration1 < duration2
end

local function GetGroup(name)
	return encounterData.mappingGroup[name] or '??'
end

ns.AddEncounter(2038,{
	Enable = true,
	Name = "Аватар Падшего",
	order = 8, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED", 'RAID_BOSS_WHISPER', 'CHAT_MSG_ADDON' },
	Settings = {
		[239739] = {
			['circle'] = { enable = true, color = 1, desc = 239739, },
		},
		[236604] = {
			['circle'] = { enable = true, color = 8, desc = 236604, },
			['lines'] = { enable = true, color = 8, desc = 236604, },
		},
		[240746] = {
			['circle'] = { enable = true, color = 6, desc = 240746, },
			['SOAKGROUP'] = { enable = true, name = 'SOAKGROUP', color = 6, customName = 'Связь перекрывателей'}, 
			['SOAKWARNING'] = { enable = false, name = 'SOAKWARNING', color = 9, customName = 'Полоса пилона'}, 
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  

			if eventType == 'SPELL_CAST_SUCCESS' then
				if (spellID == 235219) then
					encounterData.immunitiesCooldowns = encounterData.immunitiesCooldowns or {}
					encounterData.immunitiesCooldowns[srcGUID] = nil
					
			--		print("Reset iceblock", srcName)
				end
			end
			
			if eventType == "SPELL_AURA_APPLIED" then 
			
				if immunities[spellID] then
					encounterData.immunitiesCooldowns = encounterData.immunitiesCooldowns or {}
					
					encounterData.immunitiesCooldowns[dstGUID] = GetTime()+immunities[spellID]
					
			--		print('Run immune', GetSpellInfo(spellID), srcName, dstGUID)
				end
				
				if (spellID == 239739) then
					if OC(239739) then 			
						
						encounterData.immunitiesCooldowns = encounterData.immunitiesCooldowns or {}
						encounterData.marks = encounterData.marks or {}
						encounterData.marks[#encounterData.marks+1] = dstName
						
						if #encounterData.marks == 1 then
							
							C_Timer.After(0.5, function()
								
								table.sort(encounterData.marks, SortMarkTable)
								
								
								for i=1, #encounterData.marks do
									local unit = encounterData.marks[i]
									local guid = UnitGUID(unit)
									local _, _, _, _, duration, expires = ns.GetAuraByName(unit, DarkMark, 'HARMFUL')
									local _, class = UnitClass(unit)
									
									if encounterData.immunitiesCooldowns[guid] and encounterData.immunitiesCooldowns[guid] < GetTime() then
										encounterData.immunitiesCooldowns[guid] = nil
									end
									
									local imm = classImmunities[class] and ( not encounterData.immunitiesCooldowns[guid] ) or false
									
									ns.AddSpinner(guid, 239739, imm and 1 or 3, { GetTime(), ( expires and (expires - GetTime()) or 6 ) }, nil, nil, nil, i..( imm and '|cFF00FF00+|r' or '|cFFFF0000-|r'), 30 ) 
								
								end
							end)
						end
					end
				elseif (spellID == 240746) then
					--	ns.CheckOpts(240746, 'SOAKGROUP')
					--	ns.CheckOpts(240746, 'SOAKWARNING')
						
					if ns.CheckOpts(240746, 'SOAKWARNING') then
						ns.AddLine(UnitGUID('boss1'), dstGUID, 'SOAKWARNING', 9) 
					end
					
					if encounterData.mapping[dstName] then
					
						local group = GetGroup(dstName)
						
						ns.RemoveLineByTag('SOAKLINK-'..group)
						ns.HideCircleByTag('SOAKLINK-'..group)
						
						ns.RemoveLineByTag('SOAKLINK')
						ns.HideCircleByTag('SOAKLINK')
						
						local p1 = dstGUID
						local p2 = UnitGUID(encounterData.mapping[dstName])
						
						if p1 == UnitGUID('player') or p2 == UnitGUID('player') then
							if OC(240746) then 
								ns.SetCircle(p1, 'SOAKLINK-'..group, 6, 60)
								ns.SetCircle(p2, 'SOAKLINK-'..group, 6, 40)
							end
							
							if ns.CheckOpts(240746, 'SOAKGROUP') then
								ns.AddLine(p1, p2, 'SOAKLINK-'..group, 6) 
							end
						end
						
					--	print('Лучик показать', dstName, ' Next:', encounterData.mapping[dstName], ' Группа:', group)
					else
						local group = GetGroup(dstName)
						
						if group then
							ns.RemoveLineByTag('SOAKLINK-'..group)
							ns.HideCircleByTag('SOAKLINK-'..group)
						end
						
						ns.RemoveLineByTag('SOAKLINK')
						ns.HideCircleByTag('SOAKLINK')
						
						if OC(240746) then 			
							ns.SetCircle(dstGUID, 'SOAKLINK', 6, 60)
						end
						
					--	print('Лучик показать. Ошибка', dstName, ' Next:', encounterData.mapping[dstName], ' Группа:', group)
					end
				end
			elseif eventType == 'SPELL_AURA_APPLIED_DOSE' then
				if (spellID == 240728) then
				
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 239739) then		
				
					tDeleteItem(encounterData.marks, dstName)
					
					ns.RemoveSpinner(dstGUID, 239739)
				elseif (spellID == 240746) then
					
					ns.RemoveLine(UnitGUID('boss1'), dstGUID, 'SOAKWARNING') 
					
					local group = GetGroup(dstName)
					
					if group then
						ns.RemoveLineByTag('SOAKLINK-'..group)
						ns.HideCircleByTag('SOAKLINK-'..group)
					end
					
					ns.RemoveLineByTag('SOAKLINK')
					ns.HideCircleByTag('SOAKLINK')
					
				--	print('Лучик скрыть', dstName, ' Next:', encounterData.mapping[dstName], ' Группа:', group)
				end
			end
		elseif event == 'CHAT_MSG_ADDON' then
			local prefix, message = ...
			
			if prefix == 'SB_TAINT_FA' then			
				if message == 'STARTING' then
					encounterData.groups = {}
					encounterData.mapping = {}
					encounterData.mappingGroup = {}
					
				elseif message == 'FINISHED' then
					encounterData.mapping = {}

					encounterData.mapping[ encounterData.groups['1'][1] ] = encounterData.groups['1'][2]
					encounterData.mapping[ encounterData.groups['1'][2] ] = encounterData.groups['1'][3]
					encounterData.mapping[ encounterData.groups['1'][3] ] = encounterData.groups['1'][4]
					encounterData.mapping[ encounterData.groups['1'][4] ] = encounterData.groups['1'][5]
					encounterData.mapping[ encounterData.groups['1'][5] ] = encounterData.groups['1'][6]
					encounterData.mapping[ encounterData.groups['1'][6] ] = encounterData.groups['1'][1]
					
					encounterData.mapping[ encounterData.groups['2'][1] ] = encounterData.groups['2'][2]
					encounterData.mapping[ encounterData.groups['2'][2] ] = encounterData.groups['2'][3]
					encounterData.mapping[ encounterData.groups['2'][3] ] = encounterData.groups['2'][4]
					encounterData.mapping[ encounterData.groups['2'][4] ] = encounterData.groups['2'][5]
					encounterData.mapping[ encounterData.groups['2'][5] ] = encounterData.groups['2'][6]
					encounterData.mapping[ encounterData.groups['2'][6] ] = encounterData.groups['2'][1]
	
				else
					local guid, index = strsplit('^', message)
					local name = select(6, GetPlayerInfoByGUID(guid))
					
					encounterData.groups[index] = encounterData.groups[index] or {}
					
					encounterData.mappingGroup = encounterData.mappingGroup or {}
					
					encounterData.mappingGroup[name] = index
					encounterData.mappingGroup[guid] = index
						
					encounterData.groups[index][#encounterData.groups[index]+1] = name					
				end
			end
		elseif event == 'RAID_BOSS_WHISPER' then
			local msg = ...
			
			if msg and ( msg:find("236604", nil, true) or msg:find("spell:236604") ) then -- Shadowy Blades
				ns.SendMessage('236604-gain', ns.ADDON_SYNC_CHANNEL1)
			end
		elseif event == ns.ADDON_SYNC_CHANNEL1 then
			local msg, author = ...
			local nameSender = strsplit('-', author)
			
			if msg == '236604-gain' then
				local guid = nil
				for i=1, GetNumGroupMembers() do
					local unit = 'raid'..i
					
					if ( UnitName(unit) == nameSender ) then
						guid = UnitGUID(unit)						
						break
					end
				end
				
				local bossUnit = nil
				
			--	print('Find owner', author, nameSender, guid)
				
				for i=1, 2 do
			--		print('BossIDs', i, ns.GuidToID("boss"..i))
					
					if not bossUnit then					
						local id = ns.GuidToID(UnitGUID("boss"..i))
						
						if id == 116939 then
							bossUnit = "boss"..i
						end
					end
				end
				
				if guid then
					if OC(236604) then 				
						ns.AddSpinner(guid, 236604, 8, { GetTime(), 4.5 }, 120 ) 
					end
					
				--	print('T', 'AddLine', OL(236604), bossUnit, UnitGUID(bossUnit), UnitName(bossUnit),  guid)
					if OL(236604) and bossUnit then
						ns.AddLine(UnitGUID(bossUnit), guid, '236604-gain', 8)
					end
					C_Timer.After(5, function()
						if OC(236604) then 	
							ns.RemoveSpinner(guid, 236604)
						end
						if OL(236604) and bossUnit  then
							ns.RemoveLine(UnitGUID(bossUnit), guid, '236604-gain')
						end
					end)
				end
			end			
		end
	end,
	OnUpdateHandler = nil,
})