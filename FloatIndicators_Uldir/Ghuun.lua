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

local stage = 1
local waveOfCorruptionCount = 1

local function EndRangeCheck()
	ns.RangeCheck_Update() 
	print('End range check')
end

local function StartRangeCheck()
	if IsEncounterInProgress() then
		print('Start range check')
		ns.RangeCheck_Update(5) 

		C_Timer.After(8, EndRangeCheck)
	end
end 


local function GetBoils(unit)
	local findSpell = GetSpellInfo(277007)
	local guid = UnitGUID(unit)

	for i=1, 40 do 
		local name,icon,count,debuffType, duration, endTime = UnitDebuff(unit, i) 

		if not name then 
			break
		end

		if name == findSpell then 
			ns.SetCircle(guid, 'boil', 3, 40, nil, nil, 'дебафф')
			return
		end
	end 

	--ns.SetCircle(guid, 'boil', 1, 40, nil, nil, 'чист')
end

core.bossOrder = core.bossOrder + 1

ns.AddEncounter(2122,{
	Enable = true,
	Name = "Г'уун",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED", "UNIT_SPELLCAST_SUCCEEDED", 'RAID_BOSS_EMOTE' },
	Settings = {
		[274262] = {
			['circle'] = { enable = true, color = 3, desc = 274262, },
		},
		[263372] = {
			['circle'] = { enable = true, color = 2, desc = 263372, },
		},
		[267813] = {
			['circle'] = { enable = true, color = 16, desc = 267813, },
		},
		[268074] = {
			['circle'] = { enable = true, color = 8, desc = 268074, },
			['lines']  = { enable = true, color = 8, desc = 268074, },
		},
		[263235] = {
			['circle'] = { enable = true, color = 1, desc = 263235, },
		},
		[263227] = {	
			['range']  = { enable = true, desc = 263227 }, 
		},
		[277057] = {
			['circle'] = { enable = true, color = 1, desc = 277057, },
		}
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if ( spellID == 274262 or spellID == 272506 ) then
					if ( OC(274262) ) then
						local size = nil
						local text = nil

						if ( dstGUID == UnitGUID('player') ) then
							size = 14	
							text = 'на тебе'
						end

						ns.AddSpinner(dstGUID, 274262, 3, { GetTime(), 4 }, 50, nil, nil, text, size)
					end
				elseif ( spellID == 263372 ) then
					if ( OC(263372) ) then
						ns.SetCircle(dstGUID, 263372, 2, 70, nil, nil, 'Сфера')
					end
				elseif ( spellID == 263436 ) then 
					if ( OC(263372) ) then
						ns.HideCircle(dstGUID, 263372) 
					end
				elseif ( spellID == 267813 ) then
					if ( OC(267813) ) then
						ns.AddSpinner(dstGUID, 267813, 16, { GetTime(), 20 }, 50)
					end
				elseif ( spellID == 268074 ) then
					if ( dstGUID == UnitGUID('player') ) then
						if ( OC(268074) ) then
							ns.SetCircle(srcGUID, 268074, 8, 60)
						end
						if ( OL(268074) ) then
							ns.AddLine(srcGUID, dstGUID, 268074, 8) 
						end
					end
				elseif ( spellID == 263235 ) then 
					if ( OC(263235) ) then
						ns.AddSpinner(dstGUID, 263235, 1, { GetTime(), 6 }, 120, nil, nil, 'Чистка', 14)
					end
				elseif ( spellID == 270443 and RC(263227) ) then 
					print('[FL] STAGE 2 STARTED. Enable range check there')

					stage = 2
					waveOfCorruptionCount = 1

					--self:Bar(270373, 15.5) -- Wave of Corruption

					local timer = 15.5
					
					C_Timer.After(timer-5, StartRangeCheck)

					--ns.RangeCheck_Update(5) 
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if ( spellID == 274262 or spellID == 272506 ) then
					if ( OC(274262) ) then
						ns.RemoveSpinner(dstGUID, 274262) 
					end
				elseif ( spellID == 263372 ) then
					if ( OC(263372) ) then
						ns.HideCircle(dstGUID, 263372) 
					end
				elseif ( spellID == 267813 ) then
					if ( OC(267813) ) then
						ns.RemoveSpinner(dstGUID, 267813) 
					end
				elseif ( spellID == 268074 ) then
					if ( dstGUID == UnitGUID('player') ) then
						if OC(268074) then 	
							ns.HideCircle(srcGUID, 268074)
						end
						if OL(268074) then
							ns.RemoveLine(srcGUID, dstGUID, 268074)
						end
					end
				elseif ( spellID == 263235 ) then 
					if ( OC(263235) ) then
						ns.RemoveSpinner(dstGUID, 263235) 
					end
				end
			elseif eventType == 'SPELL_CAST_SUCCESS' then 
				if spellID == 276839 and RC(263227) then 
					print('[FL] STAGE 3 STARTED. Enable range check there')
					
					stage = 3
					waveOfCorruptionCount = 1

					--self:Bar(270373, 50.5) -- Wave of Corruption
					local timer = 50.5

					C_Timer.After(timer-5, StartRangeCheck)
				elseif spellID == 270373  and RC(263227) then 
					waveOfCorruptionCount = waveOfCorruptionCount + 1
				
					local timer = stage == 3 and 25.5 or waveOfCorruptionCount % 2 == 0 and 15 or 31

					print('WAVE start timer', timer)

					C_Timer.After(timer-5, StartRangeCheck)
				end
			end
		elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then 
			local unitID, castGUID, spellID = ...

			if spellID == 277057 then 
				print('Ghuun cast mythic spell')
				
				
				for i=1, GetNumGroupMembers() do
					GetBoils('raid'..i)
				end

				C_Timer.After(8, function()
					ns.HideCircleByTag('boil')	
				end)	
			end
		elseif event == 'RAID_BOSS_EMOTE' then
			print(...)
		end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		stage = 1
	end,
})