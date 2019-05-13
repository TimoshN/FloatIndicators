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

-- 274230 имун босса на переходке
-- 272407 сфера мк

ns.AddEncounter(2135,{
	Enable = true,
	Name = "Митракс Развоплотитель",
	order = core.bossOrder, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED" },
	Settings = {
		[272536] = {
			['circle'] = { enable = true, color = 8, desc = 272536, },
		},
		[272407] = {
			['circle'] = { enable = true, color = 3, desc = 272407, },
			['range'] = { enable = true },
		},
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if ( spellID ==  272536) then
					if ( OC(272536) ) then
						local size = 12
						local text = nil

						if ( dstGUID == UnitGUID('player') ) then
							size = 12	
							text = 'БЕГИ!'
						end

						ns.AddSpinner(dstGUID, 272536, 8, { GetTime(), 12 }, 60, nil, nil, text, size)
					end
				elseif ( spellID == 272407 ) then
					if ( OC(272407) ) then
						ns.SetCircle(dstGUID, 272407, 3, 60, nil, nil, 'ВЫБИТЬ')
					end
				elseif ( spellID == 274230 ) then 
					encounterData.stage = encounterData.stage + 1
					
					print('[FL] TRANSITION',encounterData.stage,'STARTED. Disable range check there')

					if ( RC(272407) ) then 
						C_Timer.After(3, function()
							ns.RangeCheck_Update() 
						end)
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 
				if ( spellID ==  272536) then
					if OC(272536) then 	
						ns.RemoveSpinner(dstGUID, 272536)
					end
				elseif ( spellID == 272407 ) then
					if OC(272407) then 	
						ns.HideCircle(dstGUID, 272407)
					end
				elseif ( spellID == 274230 ) then 
					encounterData.stage = encounterData.stage + 1
					
					print('[FL] STAGE',encounterData.stage,'STARTED. Enable range check there')
					if ( RC(272407) ) then 
						C_Timer.After(10, function()
							ns.RangeCheck_Update(5)
						end)
					end
				end
			end
		end
	end,
	OnUpdateHandler = nil,
	OnEngage = function(self)
		encounterData.stage = 1
		
		print('[FL] STAGE',encounterData.stage,'STARTED. Enable range check there')
		if ( RC(272407) ) then 
			ns.RangeCheck_Update(5)
		end
	end,
})