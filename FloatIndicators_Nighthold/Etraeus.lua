local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC


local etraySyncSort = true

local function Etray_CheckData(list)
	local dist = {
		{1,2,3,4},
		{1,3,2,4},
		{1,4,2,3},
	}
	for i=1,#dist do
		local dT = dist[i]
		for j=0,2,2 do
			local name1, name2 = list[ dT[1+j] ], list[ dT[2+j] ]
			dT[1+j], dT[2+j] = name1, name2
		
			local d = 999999

			if encounterData.SortMapperUnit then
				if encounterData.SortMapperUnit[name1] and encounterData.SortMapperUnit[name1][name2] then
					d = encounterData.SortMapperUnit[name1][name2]
				elseif encounterData.SortMapperUnit[name2] and encounterData.SortMapperUnit[name2][name1] then
					d = encounterData.SortMapperUnit[name2][name1]
				end
			end
			
			dT[j == 0 and 5 or 6] = d
		end
		dT[7] = dT[5] + dT[6]
	end
	sort(dist,function(a,b) return a[7]<b[7] end)
	
	
	for i=1, 3 do
	--[==[	print(GetTime(), 'N', i, dist[i][1], dist[i][2], '=', dist[i][5], dist[i][3], dist[i][4], '=', dist[i][6]) ]==]
	end
	
	wipe(list)
	for i=1, 4 do
		list[i] = dist[1][i]
	end
end

ns.AddEncounter(1863,{
	Enable = true,
	Name = 'Этрей',
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	order = 8, raidID = 786, raidN = 'Цитадель Ночи (T19)',version = core.version,
	Settings = {
		['etrayConstell'] = {
			['circle'] = { name = 'Созвездия', enable = true, desc = 205408 },
			['lines'] = { name = 'Созвездия', enable = true, desc = 205408 },
		},
	},
	Handler = function(self, event, ...)
		--[==[
		 Red 205445
		 Yellow 205429
		 Green 216345
		 Blue 216344
		]==]
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local timestamp, eventType, hideCaster,
					srcGUID, srcName, srcFlags, srcFlags2,
					dstGUID, dstName, dstFlags, dstFlags2,
					spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType, blocked,absorbed,critical,glancing,crushing, multistrike = ...
			
			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 205445 or spellID == 205429 or spellID == 216345 or spellID == 216344 then
					local colorType, colorID
				
					if spellID == 216344 then
						colorType = 'Blue'
						colorID = 6
					elseif spellID == 216345 then
						colorType = 'Green'
						colorID = 1
					elseif spellID == 205429 then
						colorType = 'Yellow'
						colorID = 2
					elseif spellID == 205445 then
						colorType = 'Red'
						colorID = 3
					end

					encounterData[colorType] = encounterData[colorType] or {}
					encounterData.Mapper = encounterData.Mapper or {}
					
					if dstGUID == UnitGUID('player') then 
					
						C_Timer.After(0.2, function()
							local message = ''
							
							for i=1, GetNumGroupMembers() do
								local unit = 'raid'..i
							
								if ns.GetAuraByName(unit, spellName, 'HARMFUL') and not UnitIsUnit('player', unit) then									
									message = message..UnitName(unit)..' '..ns:GetDistance(unit)..' '
								end
							end
							
							if message ~= '' then
								ns.SendMessage(message, ns.ADDON_SYNC_CHANNEL1)
							end
						end)				
					end
					
					encounterData[colorType][#encounterData[colorType]+1] = dstName
					
					if #encounterData[colorType] == 1 then
						C_Timer.After(0.6, function()	
							local numEntry = #encounterData[colorType]
							
							if numEntry == 4 then
							
								if etraySyncSort then
									Etray_CheckData(encounterData[colorType])
								else
									table.sort(encounterData[colorType])
								end
							
								local groupIndex = 0
								
								for i=0, #encounterData[colorType], 2 do								
									local from = encounterData[colorType][i+1]
									local to = encounterData[colorType][i+2]
									
									if not from or not to then
										break
									end
									
									groupIndex = groupIndex + 1
								
									encounterData.Mapper[from] = colorType..'Group'..groupIndex
									encounterData.Mapper[to] = colorType..'Group'..groupIndex
									
									if OL('etrayConstell') then 
										ns.AddLine(UnitGUID(from), UnitGUID(to), colorType..'Group'..groupIndex, colorID)
									end
								end
							else
								print('FI Error on set lines cuz of numEntry=', numEntry,'for color=',colorType)
							end
							
							if encounterData[colorType] then
								wipe(encounterData[colorType])
							end
						end)
					end
					
					if OC('etrayConstell') then 
						ns.SetCircle(dstGUID, spellName, colorID, 90)	
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 205445 or spellID == 205429 or spellID == 216345 or spellID == 216344 then					
					ns.HideCircle(dstGUID, spellName)
					ns.RemoveLineByTag(encounterData.Mapper[dstName])
					
					encounterData.Mapper[dstName] = nil
				end
			end
		elseif event == ns.ADDON_SYNC_CHANNEL1 then
			local msg, author = ...
			
			local unit1 = strsplit('-', author)
			
			local info = { strsplit(' ', msg) }
			
			local color
		
			if ns.GetAuraByName(unit1, (GetSpellInfo(216344)), 'HARMFUL') then color = 'Blue'
			elseif ns.GetAuraByName(unit1, (GetSpellInfo(216345)), 'HARMFUL') then color = 'Green'
			elseif ns.GetAuraByName(unit1, (GetSpellInfo(205429)), 'HARMFUL') then color = 'Yellow'
			elseif ns.GetAuraByName(unit1, (GetSpellInfo(205445)), 'HARMFUL') then color = 'Red'
			end

			encounterData.SortMapperUnit = encounterData.SortMapperUnit or {}
		
		--[==[ print(GetTime(), 'FI Source=',unit1,'Color=',color,'list=', msg)]==]
			
			for i=0, (#info-2), 2 do				
				local target = info[i+1]					
				local range = tonumber(info[i+2])
				
				if target and range then
					if encounterData.SortMapperUnit[unit1] and encounterData.SortMapperUnit[unit1][target] then
						if encounterData.SortMapperUnit[unit1][target] > range then
							encounterData.SortMapperUnit[unit1][target] = range	
						end
					elseif encounterData.SortMapperUnit[target] and encounterData.SortMapperUnit[target][unit1] then
						if encounterData.SortMapperUnit[target][unit1] > range then
							encounterData.SortMapperUnit[target][unit1] = range
						end
					else
						encounterData.SortMapperUnit[unit1] = encounterData.SortMapperUnit[unit1] or {}					
						encounterData.SortMapperUnit[unit1][target] = range	
					end
				end
			end
			
			if not encounterData.clearMapper then
				encounterData.clearMapper = true
				
				C_Timer.After(2, function()
					encounterData.clearMapper = false
					if encounterData.SortMapperUnit then
						wipe(encounterData.SortMapperUnit)
					end
				end)
			end
		end
	end,
})