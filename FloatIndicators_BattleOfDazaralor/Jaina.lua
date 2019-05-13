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

local function IsMythic()
    local _, _, diff = GetInstanceInfo()    
    return diff == 16
end

core.bossOrder = core.bossOrder + 1

ns.AddEncounter(2281,{
	Enable = true,
	Name = "Леди Джайна Праудмур",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
        [288412] = {
            ['circle'] =  { enable = true, color = 6, desc = 288412, },
        },
        [285254] = {
            ['circle'] =  { enable = true, color = 3, desc = 285254, },
        },
        [288212] = {
            ['circle'] =  { enable = true, color = 8, desc = 288212, },
        },
        [288038] = {
            ['lines'] =  { enable = true, color = 3, desc = 288038, },
        },
		['tankCircle'] = {
			['circle'] = { enable = true, name = "Джайна", customName = 'Текущий танк', desc = 289940 },
		},
		[289220] = {
			['circle'] =  { enable = true, color = 6, desc = 289220, },
			['range']  =  { enable = true }, 
		},
		[289387] = { -- Замерзание
			['circle'] =  { enable = false, color = 1, desc = 289387, },
		},
		[288374] = { -- Бортовой залб, грип 288374
			['circle'] =  { enable = false, color = 3, desc = 288374, },
		},
		[288219] = { -- Дебафф на бочке
			['circle'] =  { enable = false, color = 2, desc = 288219, },
		},
		[288221] = {
			['circle'] =  { enable = false, color = 3, desc = 288221, },
		}
 	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
            
            if spellID == 288412 and OC(288412) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddSpinner(dstGUID, 288412, 4, {GetTime(), 8}, 40,nil,nil,'Диспел 2')
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 288412)
                end 
            elseif spellID == 285254 and OC(285254) then
                if eventType == 'SPELL_AURA_APPLIED' then

                    local runAway = 'Лавина'
                    if ( dstGUID == UnitGUID('player') ) then 
						runAway = runAway..'\n|cFFFF0000На тебе|r'
                    end

                    ns.AddSpinner(dstGUID, 285254, 3, {GetTime(), 8}, 60,nil,nil, runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 285254)
                end
            elseif spellID == 288212 and OC(288212) then
				if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = 'К снаряду'
                    if ( dstGUID == UnitGUID('player') ) then 
						runAway = runAway..'\n|cFFFF0000На тебе|r'
                    end
					
                    ns.AddSpinner(dstGUID, 288212, 8, {GetTime(), 6}, 60,nil,nil,runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 288212)
				end
			elseif spellID == 288374 and OC(288374) then 
				if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = 'Залп'
                    if ( dstGUID == UnitGUID('player') ) then 
						runAway = runAway..'\n|cFFFF0000На тебе|r'
                    end
                    ns.AddSpinner(dstGUID, 288374, 3, {GetTime(), 8}, 70,nil,nil,runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 288374)
				end
			elseif spellID == 289220 and OC(289220) then
				if eventType == 'SPELL_CAST_START' then
					C_Timer.After(0.1, function()
						if IsEncounterInProgress() then
							ns.SetCircle(UnitGUID('boss2target'), 'heart', 3, 90, nil, nil, '|cFFFF0000>Сердце<\n'..UnitName('boss2target') )	
						end
					end)
					C_Timer.After(2, function()
						ns.HideCircleByTag('heart') 
					end)
				end 

				if eventType == 'SPELL_AURA_APPLIED' then
					ns.HideCircleByTag('heart') 

					local runAway = 'Сердце'
                    if ( dstGUID == UnitGUID('player') ) then 
						runAway = runAway..'\n|cFFFF0000На тебе|r'
					else
						runAway = runAway..'\n'..dstName
					end
					
                    ns.AddSpinner(dstGUID, 289220, 6, {GetTime(), 12}, 60,nil,nil,runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 289220)
				end 
			elseif spellID == 289387 and OC(289387) then
				if eventType == 'SPELL_AURA_APPLIED' then
					local runAway = '!!!'
					local offset = 0

                    if ( dstGUID == UnitGUID('player') ) then 
						runAway = '|cFFFF0000!!!|r'
						offset = 35
					end
					
                    ns.AddSpinner(dstGUID, 289387, 1, {GetTime(), 6},50,offset,0.1,runAway)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveSpinner(dstGUID, 289387)
                end 
            elseif spellID == 288038 and OL(288038) then
                if eventType == 'SPELL_AURA_APPLIED' then
                    ns.AddLine(srcGUID, dstGUID, 288038, 3)
                elseif eventType == 'SPELL_AURA_REMOVED' then
                    ns.RemoveLine(srcGUID, dstGUID, 288038) 
				end
			elseif spellID == 288219 and OC(288219) then 
				if eventType == 'SPELL_AURA_APPLIED' then
				--	print('T', 'Бочка дебафф', eventType)
					ns.SetCircle(dstGUID, 288219, 3, 50, nil, nil, '-99%')	

				elseif eventType == 'SPELL_AURA_REMOVED' then
				--	print('T', 'Бочка дебафф', eventType)
                    ns.SetCircle(dstGUID, 288219, 1, 50, nil, nil, '=)')	
				end
			elseif spellID == 288221 and OC(288221) then 
				if ( eventType == 'SPELL_CAST_START' ) then 
				--	print('T', 'Каст бочки', eventType)

					local duration =  IsMythic() and 8 or 15

					ns.HideCircle(srcGUID, 288219)
					ns.AddSpinner(srcGUID, 288221, 3, {GetTime(), duration}, 50,nil,nil,'Взрыв')
					C_Timer.After(duration, function()
						ns.RemoveSpinner(srcGUID, 288221)
					end)
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
						ns.SetCircle(guid, 'bossTarget', 5, 90, nil, 0.2)	
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
	OnEngage = function(self)
		
	end,
})