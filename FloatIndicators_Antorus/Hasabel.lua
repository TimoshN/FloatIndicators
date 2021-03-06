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

ns.AddEncounter(2064,{
	Enable = true,
	Name = 'Хранительница порталов Азабель',
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		--[==[
		[244926] = {
			['circle'] = { enable = true, color = 1, desc = 244926, },
		},
		]==]
		[245050] = {
			['circle'] = { enable = true, color = 9, desc = 245050, },
		},
		--[==[
		[245118] = {
			['circle'] = { enable = true, color = 3, desc = 245118, },
		},
		[244849] = {
			['circle'] = { enable = true, color = 3, desc = 244849, },
		},
		]==]
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...

			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 244926 then
					--[==[
					if OC(244926) then
						ns.SetCircle(dstGUID, 244926, 1, 90)
					end
					]==]
				elseif spellID == 245050 then
					if OC(245050) then
						ns.SetCircle(dstGUID, 245050, 9, 90)
					end
				elseif spellID == 245118 then
					--[==[
					if OC(245118) then
						ns.AddSpinner(dstGUID, 245118, 3, { GetTime(), 30 }, 90 )
					end
					]==]
				elseif spellID == 244849 then
					--[==[
					if OC(244849) then
						ns.AddSpinner(dstGUID, 244849, 3, { GetTime(), 20 }, 90 )
					end
					]==]
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 244926 then
					--[==[
					if OC(244926) then
						ns.HideCircle(dstGUID, 244926)
					end
					]==]
				elseif spellID == 245050 then
					if OC(245050) then
						ns.HideCircle(dstGUID, 245050)
					end
				elseif spellID == 245118 then
					--[==[
					if OC(245118) then
						ns.RemoveSpinner(dstGUID, 245118)
					end
					]==]
				elseif spellID == 244849 then
					--[==[
					if OC(244849) then
						ns.RemoveSpinner(dstGUID, 244849)
					end
					]==]
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})
