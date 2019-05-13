local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC


ns.AddEncounter(1871,{
	Enable = true,
	Name = 'Алуриэль',
	order = 4, raidID = 786, raidN = 'Цитадель Ночи (T19)', version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[212587] = {
			['circle'] = { enable = true, color = 6, desc = 212587, },
		},
		[213166] = {
			['circle'] = { enable = true, color = 3, desc = 213166, },			
		},
		[213275] = {
			['range'] = { enable = true },			
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local timestamp, eventType, hideCaster,
					srcGUID, srcName, srcFlags, srcFlags2,
					dstGUID, dstName, dstFlags, dstFlags2,
					spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType, blocked,absorbed,critical,glancing,crushing, multistrike = ...
			
			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 212587 then --[==[Знак льда]==]
					
					if dstGUID == UnitGUID('player') then 

					elseif OC(212587) then
						ns.SetCircle(dstGUID, spellName, 6, 100)	
					end
				elseif spellID == 213166 then  --[==[Пылающее клеймо]==]
					encounterData.SearingBrand = encounterData.SearingBrand or {}
					
					if OC(213166) then
						ns.SetCircle(dstGUID, spellName, 3, 90)	
					end					
					encounterData.SearingBrand[dstGUID] = true						
				end
			elseif eventType == "SPELL_AURA_REMOVED" then			
				if spellID == 212587 then --[==[Знак льда]==]
					ns.HideCircle(dstGUID, spellName)
				elseif spellID == 213166 then --[==[Пылающее клеймо]==]
					encounterData.SearingBrand = encounterData.SearingBrand or {}
				
					ns.HideCircle(dstGUID, spellName)

					encounterData.SearingBrand[dstGUID] = nil
				end
			elseif eventType == 'SPELL_CAST_START' then
				if spellID == 213275 and RC(213275) then		
					for guid in pairs(encounterData.SearingBrand) do
						if guid == UnitGUID('player') then
							ns.RangeCheck_Update(8)
							break
						end
					end
				end
			elseif eventType == "SPELL_CAST_SUCCESS" then
				if spellID == 213275 then --[==[Детонация: пылающее клеймо]==]
					encounterData.SearingBrand = encounterData.SearingBrand or {}
					ns.RangeCheck_Update()
					
					for guid in pairs(encounterData.SearingBrand) do
						ns.HideCircle(guid, (GetSpellInfo(213166)))			
					end
					wipe(encounterData.SearingBrand)
				end					
			end
		end
	end,
})