local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

--[==[
	2269

	ns.RangeCheck_Update(distance) -- nil for off 
	
	ns.SetCircle(owner, tag, color, size, offset, alpha, text, textSize)	
	ns.HideCircle(owner, tag)
	ns.HideCircleByTag(tag) 
	
	ns.AddSpinner(owner,tag,color,timer,size,offset,alpha,text,textSize)
	ns.RemoveSpinner(owner,tag) 
	
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

ns.AddEncounter(2269,{
	Enable = true,
	Name = "Неусыпный совет",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" }, --"RAID_BOSS_EMOTE",  
	Settings = {
		[282386] = { -- Афотический взрыв МК
			['circle'] = { enable = false, color = 8, desc = 282386, },
			['tankCircle'] = { enable = true, name = "Cabal", customName = 'Текущий танк', desc = 282386 },
		},
		[282432] = { -- Тяжелые сомнения
			['circle'] = { enable = true, color = 3, desc = 282432, },
		},
		[282561] = { -- Глашатай тьмы
			['circle'] = { enable = true, color = 6, desc = 282561, },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if ( eventType == 'SPELL_AURA_APPLIED' or eventType == 'SPELL_AURA_REFRESH' or eventType == 'SPELL_AURA_APPLIED_DOSE') then 
				if spellID == 282386 then
					if OC(spellID) then 
						
						local text = 'МК'

						if ( dstGUID == UnitGUID('player') ) then
							text = '|cFFFF0000МК|r'
						end 

						ns.AddSpinner(dstGUID, spellID, 8, { GetTime(), 30 }, 60, nil, nil, text )
					end
				end
			end 

			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 282432 then
					if OC(spellID) then 		
						local text = 'Взрыв'

						if ( dstGUID == UnitGUID('player') ) then
							text = '|cFFFF0000Выбеги|r'
						end 
						
						local _, _, _, _, duration = ns.GetAuraByName(dstName, spellName, 'HARMFUL')

						ns.AddSpinner(dstGUID, spellID, 3, { GetTime(), duration }, 70, nil, nil, text  )
					end
				elseif spellID == 282561 then
					if OC(spellID) then 	
						
						local text = 'Бафф'

						if ( dstGUID == UnitGUID('player') ) then
							text = '|cFFFF0000Бафф|r'
						end 
						
						ns.AddSpinner(dstGUID, spellID, 6, { GetTime(), 10 }, 80, nil, nil, text  )
					end
				end	
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 282386 then
					if OC(spellID) then 	
						ns.RemoveSpinner(dstGUID, spellID)
					end
				elseif spellID == 282432 then
					if OC(spellID) then 
						ns.RemoveSpinner(dstGUID, spellID)
					end
				elseif spellID == 282561 then
					if OC(spellID) then 
						ns.RemoveSpinner(dstGUID, spellID)
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

					if id == 144755 then
						bossUnit = "boss"..i
					end
				end
			end
			]==]
			if ns.CheckOpts(282386, 'tankCircle') then
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
						ns.SetCircle(guid, 'bossTarget', 7, 90, nil, nil, 'Глашатай')	
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