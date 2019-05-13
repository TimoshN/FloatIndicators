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

--[==[
	-- Ковен
	Студеная кровь цвет синий
	Пламенный удар -
	Прострел полоска зеленая с кружками 250757
	Рендж на молнии
]==]

ns.AddEncounter(2073,{
	Enable = true,
	Name = 'Ковен шиварр',
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		--[==[
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Ковен", customName = 'Текущий танк', desc = 244899 },
		},
		]==]
		[245586] = {
			['circle'] = { enable = true, color = 6, desc = 245586, },
		},
		[253520] = {
			['circle'] = { enable = true, color = 3, desc = 253520, },
		},
		[250757] = {
			['circle'] = { enable = true, color = 1, desc = 250757, },
			['lines'] = { enable = true, color = 1, desc = 250757, },
		}
		--self:Log("SPELL_CAST_SUCCESS", "CosmicGlare", 250912)
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...

			if eventType == "SPELL_AURA_APPLIED" then
				if spellID == 245586 then
					if OC(245586) then
						ns.AddSpinner(dstGUID, 245586, 6, { GetTime(), 10 }, 120 )
					end
				elseif spellID == 253520 then
					ns.AddSpinner(dstGUID, 253520, 3, { GetTime(), 10 }, 120 )
				elseif spellID == 250757 then

					encounterData.cosmic = encounterData.cosmic or {}
					encounterData.cosmic[#encounterData.cosmic+1] = dstName

					if #encounterData.cosmic == 1 then
						C_Timer.After(0.5, function()

							local p1 = UnitGUID(encounterData.cosmic[1])
							local p2 = UnitGUID(encounterData.cosmic[2])

							if OC(250757) then
								ns.SetCircle(p1, 'COSMIC', 1, 60)
								ns.SetCircle(p2, 'COSMIC', 1, 60)
							end

							if OL(250757) then
								ns.AddLine(p1, p2, 'COSMIC', 1) 
							end
						end)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then
				if spellID == 245586 then
					if OC(245586) then
						ns.RemoveSpinner(dstGUID, 245586)
					end
				elseif spellID == 253520 then
					ns.RemoveSpinner(dstGUID, 253520)
				elseif spellID == 250757 then

					tDeleteItem(encounterData.cosmic, dstName)

					ns.RemoveLineByTag('COSMIC')
					ns.HideCircleByTag('COSMIC')
				end
			end
		end
	end,
	OnUpdateHandler = function(self, elapsed)
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed
		if encounterData.tmr > 0.15 then
			encounterData.tmr = 0

			local bossUnit = nil

			for i=1, 2 do
				if not bossUnit then
					local id = ns.GuidToID(UnitGUID("boss"..i))

					if id == 122468 then
						bossUnit = "boss"..i
					end
				end
			end

			bossUnit = bossUnit or 'boss2'

			
			--[==[
			if OC('tankCircle') then
				local findEm = nil

				for i=1,30 do
					local isTanking = UnitDetailedThreatSituation("raid"..i, bossUnit)

					if isTanking then
						findEm = "raid"..i
						break
					end
				end

				if findEm == encounterData.prevF then
					return
				elseif findEm then
					if encounterData.prev then
						ns.HideCircle(encounterData.prev, 'bossTarget')
					end
					local guid = UnitGUID(findEm)

					if guid ~= UnitGUID('player') then
						ns.SetCircle(guid, 'bossTarget', 5, 150)
					end
					encounterData.prev = guid
					encounterData.prevF = findEm
				elseif encounterData.prev then
					ns.HideCircle(encounterData.prev, 'bossTarget')
				end
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget')
			end
			]==]
		end
	end,
})
