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

local raidIdToString = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0:0|t",
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0:0|t",
}
	
ns.AddEncounter(2069,{
	Enable = true,
	Name = "Вариматрас",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[244042] = {
			['circle'] = { enable = true, color = 1, desc = 244042, },
			['lines']  = { enable = true, color = 1, desc = 244042, },
		},
		[244094] = {
			['circle'] = { enable = true, color = 3, desc = 244094, },
		},
		--[==[
		[248732] = {
			['circle'] = { enable = true, color = 9, desc = 248732, },
		},
		]==]
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...

			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 244042 then
					if OC(244042) then
						ns.AddSpinner(dstGUID, 244042, 1, { GetTime(), 5 }, 120 )
					end
					if OL(244042) then
						ns.AddLine(srcGUID, dstGUID, 244042, 1)
					end
				elseif spellID == 244094 then
					encounterData.playerList = encounterData.playerList or {}

					if #encounterData.playerList >= 2 then return end
					
					encounterData.playerList[#encounterData.playerList+1] = dstName
					
					local count = #encounterData.playerList
					local icon = count + 2
					
					local f = ns.AddSpinner(dstGUID, 244094, 3, { GetTime(), 6 }, 120 )
					
					local size = 40
					local text = raidIdToString[icon] or ''
					
					if ( dstGUID == UnitGUID('player') ) then
						size = 20	
						text = 'на тебе\n'..text
					end
					
					f.Text:SetFont(STANDARD_TEXT_FONT, size)
					f.Text:SetText(text)
				elseif spellID == 248732 then
					--[==[ns.AddSpinner(dstGUID, 248732, 9, { GetTime(), 3.5 }, 120 )]==]
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 244042 then
					if OC(244042) then
						ns.RemoveSpinner(dstGUID, 244042)
					end
					if OL(244042) then
						ns.RemoveLine(srcGUID, dstGUID, 244042)
					end
				elseif spellID == 244094 then
					ns.RemoveSpinner(dstGUID, 244094)
					
					tDeleteItem(encounterData.playerList, dstName)					
				elseif spellID == 248732 then
					--[==[ns.RemoveSpinner(dstGUID, 248732)]==]
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})
