local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

core.bossOrder = core.bossOrder + 1

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

ns.AddEncounter(2075,{
	Enable = true,
	Name = 'Эонар',
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		--[==[
		[248332] = {
			['circle'] = { enable = true, color = 3, desc = 248332, },
		},
		]==]
		[250691] = {
			['circle'] = { enable = true, color = 9, desc = 250691, },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...

			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 248332 then
					--[==[
					if OC(248332) then
						ns.AddSpinner(dstGUID, 248332, 3, { GetTime(), 5 }, 90 )
					end
					]==]
				elseif spellID == 250691 then
					if OC(250691) then
						--ns.AddSpinner(dstGUID, 250691, 9, { GetTime(), 20 }, 90 )
						ns.SetCircle(dstGUID, 250691, 9, 90)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 248332 then
					--[==[
					if OC(248332) then
						ns.RemoveSpinner(dstGUID, 248332)
					end
					]==]
				elseif spellID == 250691 then
					if OC(250691) then
						--ns.RemoveSpinner(dstGUID, 250691)
						ns.HideCircle(dstGUID, 250691)
					end
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})
