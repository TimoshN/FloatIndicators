local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local encounterData = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

--[==[
	
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

ns.AddEncounter(2268,{
	Enable = true,
	Name = core.Lang.BOSS5,
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
        [286811] = {
            ['circle'] = { enable = true, color = 3, desc = 286811, },
        },
        [285878] = {
            ['circle'] = { enable = true, color = 6, desc = 285878, },
        },
		--[==[
        [284663] = {
            ['circle'] = { enable = true, color = 6, desc = 284663, },
        },
		]==]
        [282079] = {
            ['circle'] = { enable = true, color = 2, desc = 282079, },
        },
        [282209] = {
            ['lines'] = { enable = true, color = 3, desc = 282209, },
        },
        [282135] = {
            ['circle'] = { enable = true, color = 8, desc = 282135, },
        },
        [282098] = {
            ['circle'] = { enable = true, color = 12, desc = 282098, },
        },
		[282834] = {
			['circle'] = { enable = true, color = 7, desc = 282834, },
		},
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Kimbala", customName = ns.Lang.CURRENT_TANK, desc = 282592 },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
            
            if spellID == 286811 and OC(286811) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 286811, 3, {GetTime(), 6},40,nil,nil, core.Lang.SPHERE)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 286811)
                end
            elseif spellID == 285878 and OC(285878) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 285878, 6, {GetTime(), 30},40,nil,nil,core.Lang.DISPEL)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 285878)
                end      
            elseif spellID == 284663 and OC(284663) then
				--[==[
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 284663, 6, {GetTime(), 10},40,nil,nil,'Диспел')
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 284663)
                end 
				]==]				
            elseif spellID == 282079 and OC(282079) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.SetCircle(srcGUID, 282079, 3, 90, nil, nil, '-99%')
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.HideCircle(dstGUID, 282079)
                end 
            elseif spellID == 282209 and OL(282209) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    if ( dstGUID == UnitGUID('player') ) then 
                        ns.AddLine(srcGUID, dstGUID, 282209, 3) 
                    end
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveLine(srcGUID, dstGUID, 282209) 
                end
            elseif spellID == 282135 and OC(282135) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    local runAway = core.Lang.MOVE_OUT
                    if ( dstGUID == UnitGUID('player') ) then 
                        runAway = core.Lang.RUN_AWAY
                    end

                    ns.AddSpinner(dstGUID, 282135, 8, {GetTime(), 5},40,nil,nil,runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 282135)
                end
            elseif spellID == 282098 and OC(282098) and not UnitInRaid(dstName) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.SetCircle(dstGUID, 282098, 12, 40, nil, nil, core.Lang.PURGE)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.HideCircle(dstGUID, 282098)
                end 
			elseif spellID == 282834 and OC(282834) then
				if eventType == 'SPELL_AURA_APPLIED' then
					ns.AddSpinner(dstGUID, 282834, 7, {GetTime(), 3}, 70,nil,nil, core.Lang.TIGER)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                     ns.RemoveSpinner(dstGUID, 282834)
                end 
            end
        end
	end,
	--144963
	OnUpdateHandler = function(self, elapsed)
		encounterData.tmr = ( encounterData.tmr or 0 ) + elapsed
		if encounterData.tmr > 0.15 then
			encounterData.tmr = 0

			local bossUnit = nil
			
			for i=1, 5 do
				if not bossUnit then
					local id = ns.GuidToID(UnitGUID("boss"..i))
	
					if id == 144963 then
						bossUnit = "boss"..i
					end
				end
			end
			
			if OC('tankCircle') then
				local findEm = nil
	
				if bossUnit then
					for i=1,30 do
						local isTanking = UnitDetailedThreatSituation("raid"..i, bossUnit)

						if isTanking then
							findEm = "raid"..i
							break
						end
					end
				end
			--	print('Tank1:', findEm)

				if findEm == encounterData.prevF then
				--	print('Tank2: return')
					return
				elseif findEm then
					if encounterData.prev then
						ns.HideCircle(encounterData.prev, 'bossTarget')
						encounterData.frame = nil
					end
					local guid = UnitGUID(findEm)

					if guid ~= UnitGUID('player') then	
						encounterData.frame = ns.SetCircle(guid, 'bossTarget', 5, 100)
					end
				--	print('Tank3:',findEm)
					encounterData.prev = guid
					encounterData.prevF = findEm
				elseif encounterData.prev then
				--	print('Tank4:', encounterData.prev)
					ns.HideCircle(encounterData.prev, 'bossTarget')
					encounterData.frame = nil
				end
			elseif encounterData.prev then
				encounterData.prev = nil
				ns.HideCircleByTag('bossTarget')
			end
		end
	end,
	OnEngage = function(self)
		
	end,
})