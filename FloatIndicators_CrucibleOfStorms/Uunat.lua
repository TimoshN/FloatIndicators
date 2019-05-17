local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

--[==[
	2273

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

ns.AddEncounter(2273,{
	Enable = true,
	Name = core.Lang.BOSS2,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[285652] = { -- Нескончаемая мука
			['circle'] = { enable = true, color = 3, desc = 285652, },
		},
		['tankCircle'] = { -- Касание погибели
			['circle'] = { enable = true, name = "УУнат", customName = ns.Lang.CURRENT_TANK, desc = 284851 },
		},
		['marks'] = {
			['circle'] = { enable = true, color = 3, desc = 293653, },
			['lines']  = { enable = true, color = 3, desc = 293653, },
		},
		--[==[
		293662 - резонанс окена, 293661 - резонанс бури, 293663 - резонанс бездны, которые по 15, дебаффы; 
		
		284768 - трезубец, 284684 - войдстоун, 284569 - корона, бафы
		]==]
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if ( spellID == 285652 ) then
					if ( OC(285652) ) then
						ns.SetCircle(dstGUID, 285652, 3, 70, nil, nil, '-'..core.Lang.HEAL)
					end
				elseif spellID == 293662 or spellID == 293661 or spellID == 293663 then
					if ( OC('marks') ) then
						local color = 1
						
						if spellID == 293662 then
							color = 12
						elseif spellID == 293661 then 
							color = 4
						elseif spellID == 293663 then 
							color = 8
						end

						ns.SetCircle(dstGUID, 'marks', color, 50, nil, 0.4)
					end
				elseif spellID == 284768 or spellID == 284684 or spellID == 284569 then
					if ( OC('marks') ) then
						local color = 1
						local text = ''

						if spellID == 284768 then
							color = 12
							text = core.Lang.TRIDENT
						elseif spellID == 284684 then 
							color = 8
							text = core.Lang.STONE
						elseif spellID == 284569 then 
							color = 4
							text = core.Lang.CROWN
						end

						ns.SetCircle(dstGUID, 'marks', color, 90, nil, nil, text)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if ( spellID == 285652 ) then
					if ( OC(285652) ) then
						ns.HideCircle(dstGUID, 285652) 
					end
				elseif spellID == 293662 or spellID == 293661 or spellID == 293663 then
					if ( OC('marks') ) then
						ns.HideCircle(dstGUID, 'marks') 
					end
				elseif spellID == 284768 or spellID == 284684 or spellID == 284569 then
					if ( OC('marks') ) then
						ns.HideCircle(dstGUID, 'marks') 
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

					if id == 145371 then
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
						ns.SetCircle(guid, 'bossTarget', 6, 90, nil, 0.4)	
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