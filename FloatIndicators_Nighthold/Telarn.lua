local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddEncounter(1886,{
	Enable = true,
	Name = 'Ботаник',
	order = 7, raidID = 786, raidN = 'Цитадель Ночи (T19)',version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[218304] = {
			['circle'] = { enable = true, color = 3 },
		},
		[218809] = {
			['circle'] = { enable = true, color = 9 },
		},
		[218342] = {
			['lines'] = { enable = true, color = 7 },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local timestamp, eventType, hideCaster,
					srcGUID, srcName, srcFlags, srcFlags2,
					dstGUID, dstName, dstFlags, dstFlags2,
					spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...
				
					
			if eventType == "SPELL_AURA_APPLIED" then					
				if spellID == 218304 then --[==[Паразитические путы]==]
					if OC(218304) then
						ns.SetCircle(dstGUID, spellName, 3, 120)	
					end
				elseif spellID == 218809 then --[==[Зов ночи]==]
					if dstGUID == UnitGUID('player') then
						
					else
						if OC(218809) then
							ns.AddSpinner(dstGUID, spellName, 9, { GetTime(), 45 } )
						end
					end
				elseif spellID == 218342 then --[==[Паразитическое сосредоточение]==]
					if OL(218342) then
						ns.AddLine(srcGUID, dstGUID, spellName, 7)	
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 218304 then --[==[Паразитические путы]==]
					ns.HideCircle(dstGUID, spellName)
				elseif spellID == 218809 then --[==[Зов ночи]==]
					ns.RemoveSpinner(dstGUID, spellName)
				elseif spellID == 218342 then --[==[Паразитическое сосредоточение]==]
					ns.RemoveLine(srcGUID, dstGUID, spellName)
				end
			end
		end
	end,
})