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

ns.AddEncounter(2144,{
	Enable = true,
	Name = "Талок",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[271222] = { -- Выброс плазмы
			['circle'] = { enable = true, color = 3, desc = 271222, },
		},
		[271296] = {  -- Кровавый отбойник
			['circle'] = { enable = true, color = 6, desc = 271296, }, 
			['lines']  = { enable = true, color = 6, desc = 271296, },
		},
		[275270] = {  -- Фиксейт от моба
			['circle'] = {enable = true, color = 3, desc = 275270, },
			['lines']  = {enable = true, color = 3, desc = 275270, },
		},
		[275189] = { -- Уплотнение артерий
			['circle'] = {enable = true, color = 4, desc = 275189, },
		},
		[275205] = { -- Увеличенное сердце
			['circle'] = {enable = true, color = 2, desc = 275205, },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if spellID == 271222 or spellID == 271224 or spellID == 271225 or spellID == 278888 or spellID == 278889 then
					if OC(271222) then 		
						ns.AddSpinner(dstGUID, 271222, 3, { GetTime(), 4 }, 90 )
					end
				elseif spellID == 275270 then
					if OC(275270) then 	

						--owner, tag, color, size, offset, alpha, text, textSize

						local size = nil
						local text = nil

						if ( dstGUID == UnitGUID('player') ) then
							size = 20	
							text = 'на тебе'
						end

						ns.SetCircle(dstGUID, 275270, 3, 60, nil, nil, text, size)
					end
					if OL(275270) then
						ns.AddLine(srcGUID, dstGUID, 275270, 3) 
					end
				elseif spellID == 275189 then
					if OC(spellID) then 	
						--owner,tag,color,timer,size,offset, alpha, text, textSize
						ns.AddSpinner(dstGUID, spellID, 4, { GetTime(), 6 }, 120, nil, nil, 'Взрыв')
					end
				elseif spellID == 275205 then
					if OC(spellID) then 	
						--owner,tag,color,timer,size,offset, alpha, text, textSize
						ns.AddSpinner(dstGUID, spellID, 2, { GetTime(), 6 }, 120, nil, nil, 'Делить')
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if spellID == 271222 or spellID == 271224 or spellID == 271225 or spellID == 278888 or spellID == 278889 then
					if OC(271222) then 		
						ns.RemoveSpinner(dstGUID, 271222)
					end
				elseif spellID == 275270 then
					if OC(275270) then 	
						ns.HideCircle(dstGUID, 275270)
					end
					if OL(275270) then
						ns.RemoveLine(srcGUID, dstGUID, 275270)
					end
				elseif spellID == 275189 then
					if OC(spellID) then 	
						ns.RemoveSpinner(dstGUID, spellID)
					end
				elseif spellID == 275205 then
					if OC(spellID) then 
						ns.RemoveSpinner(dstGUID, spellID)
					end
				end
			elseif eventType == "SPELL_CAST_START" then
				if spellID == 271296 then
					if OC(271296) then 	
						ns.AddSpinner(dstGUID, 271296, 6, { GetTime(), 4.5 }, 120 )
					end
					if OL(271296) then
						ns.AddLine(srcGUID, dstGUID, 271296, 6) 
					end
					C_Timer.After(4.5, function()
						ns.RemoveSpinner(dstGUID, 271296)
						ns.RemoveLineByTag(271296)
					end)
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})