local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddEncounter(1865,{
	Enable = true,
	Name = 'Аномалия',
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	order = 2, raidID = 786, raidN = 'Цитадель Ночи (T19)', version = core.version,
	Settings = {
		[206617] = {
			['circle'] = { enable = true, color = 6 },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local timestamp, eventType, hideCaster,
					srcGUID, srcName, srcFlags, srcFlags2,
					dstGUID, dstName, dstFlags, dstFlags2,
					spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...
					
			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 206617 then --[==[Часовая бомба]==]					
					if OC(206617) then
						ns.SetCircle(dstGUID, spellName, 6, 100)	
					end				
				end
			elseif eventType == "SPELL_AURA_REMOVED" then			
				if spellID == 206617 then --[==[Часовая бомба]==]
					ns.HideCircle(dstGUID, spellName)
				end
			end
		end		
	end,
})