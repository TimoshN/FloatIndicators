local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddBossPositionFix(106643, 50)
ns.AddEncounter(1872,{
	Enable = true,
	Name = 'Элисанда',
	order = 9, raidID = 786, raidN = 'Цитадель Ночи (T19)',version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[209244] = {
			['lines'] = { enable = true, color = 7 },
			['circle'] = { enable = true, color = 7 },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local timestamp, eventType, hideCaster,
					srcGUID, srcName, srcFlags, srcFlags2,
					dstGUID, dstName, dstFlags, dstFlags2,
					spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...
				
					
			if eventType == "SPELL_AURA_APPLIED" then					
				if spellID == 209244 then --[==[Пророческий луч]==]
					if OL(209244) then
						ns.AddLine(srcGUID, dstGUID, spellName, 7)	
					end
					
					if OC(209244) and UnitName(dstName) then
						ns.SetCircle(dstGUID, 209244, 7, 80)	
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 209244 then --[==[Пророческий луч]==]
					ns.HideCircle(dstGUID, 209244)
					ns.RemoveLine(srcGUID, dstGUID, spellName)
				end
			end
		end
	end,
})