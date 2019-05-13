local addon, core = ...
local ns = FloatIndicators or FloatIndicatorsDebug
local ed = ns.encounterData

local OL = ns.OL
local OC = ns.OC
local RC = ns.RC

ns.AddBossPositionFix(115844, 90)
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
	231363 - от танка
	232249 - от дд
	
	233272 - метеор, полоска + кружок
	230345 - дебафф на взрыв, кружок 10 ярдов 16 секунд
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

local ddDebuff = GetSpellInfo(232249)
local tankDebuff = GetSpellInfo(231363)

 
local function IsDamage_Debuff(unit)
	local show = false
	local index = 1
	
	if ns.GetAuraByName(unit, ddDebuff, 'HARMFUL') then
		while true do
			local name, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, index)
			
			if not name then
				break
			end
			
			index = index + 1
			
			if spellID == 232249 then
				show = true
				break
			end
		end
	end
	
	return show
end

local function IsTank_Debuff(unit)
	local show = false
	local index = 1
	
	if ns.GetAuraByName(unit, tankDebuff, 'HARMFUL') then
		while true do
			local name, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, index)
			
			if not name then
				break
			end
			
			index = index + 1
			
			if spellID == 231363 then
				show = true
				break
			end
		end
	end
	
	return show
end

ns.AddEncounter(2032,{
	Enable = true,
	Name = 'Горот',
	order = 1, raidID = core.raidID, raidN = core.raidName, version = core.version,
	Events = { "COMBAT_LOG_EVENT_UNFILTERED", 'UNIT_AURA' },
	Settings = {
		[233272] = {
			['circle'] = { enable = true, color = 2, desc = 233272, },
			['lines'] = { enable = true, color = 2, desc = 233272, },
		},
		[232249] = {
			['circle'] = { enable = true, color = 3, desc = 232249, },			
		},
		--[==[
		[231363] = {
			['circle'] = { enable = true, color = 3, desc = 231363, },	
		}
		]==]
	},
	Handler = function(self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
			local _, eventType, _, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType= ...  
			
			if eventType == "SPELL_AURA_APPLIED" then 
				if (spellID == 233272) then
					if OL(233272) then
						ns.AddLine(srcGUID, dstGUID, spellName, 2) 
					end
					if OC(233272) then
						ns.SetCircle(dstGUID, 233272, 2, 80)	
					end
				end
			elseif eventType == "SPELL_AURA_REMOVED" then 	
				if (spellID == 233272) then
					ns.RemoveLine(srcGUID, dstGUID, spellName) 
					ns.HideCircle(dstGUID, 233272) 
				end
			end
		elseif event == 'UNIT_AURA' then
			local unit = ...
			local guid = UnitGUID(unit)
			
			if OC(233272) then
				if IsDamage_Debuff(unit) and ed[guid] ~= 'have' then
					ed[guid] = 'have'
					
					
					if OC(233272) then
						ns.AddSpinner(guid, 233272, 1, { GetTime(), 5 }, 120 ) 
						
						
						C_Timer.After(5, function()
							ns.RemoveSpinner(guid, 233272)
						end)
					end
					
					
				--	print('Find target on spell', UnitName(unit))
				elseif ed[guid] == 'have' and not IsDamage_Debuff(unit) then
					ed[guid] = 'dont'
					
				--	print('Remove target on spell', UnitName(unit))
				end
			end
		end
	end,
	OnUpdateHandler = nil,
})