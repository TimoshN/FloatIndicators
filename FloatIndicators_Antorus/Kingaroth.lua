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

-- 249680
-- 246687

-- 245770

ns.AddEncounter(2088,{
	Enable = true,
	Name = "Кин'гарот",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Кин'гарот", customName = 'Текущий танк', desc = 257978 },
		},
		[246687] = {
			['circle'] = { enable = true, color = 3, desc = 246687, },
		}
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...
			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 246687 or spellID == 249680 or spellID == 245770 then
					if OC(246687) then

						local name, icon, count, debuffType, duration, expirationTime = ns.GetAuraByName(dstName, spellName, 'HARMFUL')

						ns.AddSpinner(dstGUID, 246687, 3, { expirationTime-duration-3, duration+3 }, 120 )
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 246687 or spellID == 249680 or spellID == 245770 then
					if OC(246687) then
						ns.RemoveSpinner(dstGUID, 246687)
					end
				end
			end
		end
	end,
	OnUpdateHandler = function(self, elapsed)
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed
		if encounterData.tmr > 0.15 then
			encounterData.tmr = 0

			local bossUnit = 'boss1'
			--[==[
			for i=1, 2 do
				if not bossUnit then
					local id = ns.GuidToID("boss"..i)

					if id == 116689 then
						bossUnit = "boss"..i
					end
				end
			end
			]==]
			if OC('tankCircle') then
				local findEm = nil

				for i=1,30 do
					local isTanking = UnitDetailedThreatSituation("raid"..i, bossUnit)

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
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget')
			end
		end
	end,
})
