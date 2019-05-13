local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddEncounter(1866, { 
	Enable = true, 
	Name = "Гул'дан", 
	order = 10, raidID = 786, raidN = 'Цитадель Ночи (T19)',version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" }, 
	Settings = { 
		[209011] = { 	--[==[Узы Скверны]==] 
			['circle'] = { enable = true, color = 3 }, 
		}, 
		[209454] = { 
			['circle'] = { enable = true, color = 9 }, 
			['range']  = { enable = true }, 
		}, 
		[206847] = { 
			['circle'] = { enable = true, color = 8 }, }, 
		[206983] = { 
			['lines'] = { enable = true, color = 1 }, 
		}, 
		[221603] = { 
			['circle'] = { enable = true, color = 2 }, 
		}, 
		['tankCircle'] = { 
			['circle'] = { name = '', customName = 'Текущий танк', enable = true, desc = 227554 }, 
		}, 
	}, 
	OnUpdateHandler = function(self, elapsed) 
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed  
		if encounterData.tmr > 0.15 then 
			encounterData.tmr = 0 
				
			if OC('tankCircle') then 
				local findEm = nil 
				
				for i=1,30 do 
					local isTanking = UnitDetailedThreatSituation("raid"..i, "boss1") 
					
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
			else 
				ns.HideCircleByTag('bossTarget') 
			end
		end
	end, 
	Handler = function(self, event, ...) 
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			if eventType == 'SPELL_CAST_START' then 
				if ( spellID == 209270 or spellID == 211152 ) and RC(209454) and not ns.IsMelee() then 
					ns.RangeCheck_Update(8) 
					C_Timer.After(5, function() ns.RangeCheck_Update() end) 
				end 
			elseif eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 209011 or spellID == 206384) then --[==[Узы Скверны]==] 
					if OC(209011) then 
						ns.SetCircle(dstGUID, 209011, 3, 120) 
					end 
				elseif (spellID == 209454 or spellID == 209489 or spellID == 221728 ) then	--[==[Око Гул'дана]==] 
					if OC(209454) and UnitName(dstName) then 
						ns.SetCircle(dstGUID, 209454, 9, 120) 
					end 
				elseif ( spellID == 206847 ) then 	--[==[Паразитарная рана]==] 
					if OC(206847) then 
						ns.AddSpinner(dstGUID, 206847, 8, { GetTime(), 10 }, 90 ) 
					end 
				elseif ( spellID == 206983 ) then --[==[Темный взор]==] 
					if OL(206983) then 
						ns.AddLine(srcGUID, dstGUID, spellName, 1) 
					end 
				elseif ( spellID == 221606 ) then --[==[Тот что перед срем]==] 
					if OC(221603) then 
						ns.AddSpinner(dstGUID, spellName, 2, { GetTime(), 3 } ) 
					end 
				elseif ( spellID == 221603 ) then --[==[Тот что срет]==] 
					if OC(221603) then 
						ns.AddSpinner(dstGUID, spellName, 2, { GetTime(), 3 } ) 
					end 
				end 
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if (spellID == 209011 or spellID == 206384) then --[==[Узы Скверны]==] 
					ns.HideCircle(dstGUID, 209011) 
				elseif (spellID == 209454 or spellID == 209489 or spellID == 221728) then --[==[Око Гул'дана]==] 
					ns.HideCircle(dstGUID, 209454) 
				elseif ( spellID == 206847 ) then 	--[==[Паразитарная рана]==] 
					ns.RemoveSpinner(dstGUID, 206847) 
				elseif ( spellID == 206983 ) then --[==[Темный взор]==] 
					ns.RemoveLine(srcGUID, dstGUID, spellName) 
				elseif ( spellID == 221606 ) then --[==[Тот что перед срем]==] 
					ns.RemoveSpinner(dstGUID, spellName) 
				elseif ( spellID == 221603 ) then --[==[Тот что срет]==] 
					ns.RemoveSpinner(dstGUID, spellName) 
				end 
			end 
		end 
	end,
})