local addon, ns = ...

local nameplateAPI = {}
local applyHook = false

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local UnitIsFriend = UnitIsFriend

local numAttepts = 0

nameplateAPI.startUp = CreateFrame('Frame')
nameplateAPI.startUp:RegisterEvent('PLAYER_LOGIN')
nameplateAPI.startUp:SetScript('OnEvent', function(self, event, ...)

	if ElvUI then 
		ElvUI[1]:IgnoreCVar('nameplateMinScale', true) 
		ElvUI[1]:IgnoreCVar('nameplateMaxScale', true) 
		ElvUI[1]:IgnoreCVar('nameplateGlobalScale', true) 
		ElvUI[1]:IgnoreCVar('nameplateOtherTopInset', true) 
		ElvUI[1]:IgnoreCVar('nameplateOtherBottomInset', true) 
		ElvUI[1]:IgnoreCVar('nameplateLargeBottomInset', true) 
		ElvUI[1]:IgnoreCVar('nameplateLargeTopInset', true)  
		ElvUI[1]:IgnoreCVar('nameplateShowAll', true)  
		
		
		local mod = ElvUI[1]:GetModule('NamePlates')
    
		local oldConfigureElement_Name = mod.ConfigureElement_Name
		
		function mod:ConfigureElement_Name(frame)
			oldConfigureElement_Name(self, frame)
			
			local name = frame.Name
			
			if(self.db.units[frame.UnitType].healthbar.enable or frame.isTarget) then
				
			else
				name:ClearAllPoints()
				name:SetPoint("TOP", frame, "CENTER", 0, 15)          
			end
			
		end          
		
		local oldRegisterEvents = mod.RegisterEvents
		
		function mod:RegisterEvents(frame, unit)
			oldRegisterEvents(self, frame, unit)
			frame:RegisterEvent("RAID_TARGET_UPDATE")
		end
		
	end

	if AleaUI then 
		AleaUI:IgnoreCVar('nameplateMinScale', true) 
		AleaUI:IgnoreCVar('nameplateMaxScale', true)
		AleaUI:IgnoreCVar('nameplateGlobalScale', true) 
		AleaUI:IgnoreCVar('nameplateOtherTopInset', true) 
		AleaUI:IgnoreCVar('nameplateOtherBottomInset', true) 
		AleaUI:IgnoreCVar('nameplateLargeBottomInset', true) 
		AleaUI:IgnoreCVar('nameplateLargeTopInset', true) 
		AleaUI:IgnoreCVar('nameplateShowAll', true)  
	end

	ns:LockCVar('nameplateMinScale', '1') 
	ns:LockCVar('nameplateMaxScale', '1') 
	ns:LockCVar('nameplateGlobalScale', '1')  
	
	ns:LockCVar("nameplateOtherTopInset", "0.01")	
	ns:LockCVar("nameplateLargeTopInset", "0.01")

	ns:LockCVar("nameplateOtherBottomInset", '-1')  
	ns:LockCVar("nameplateLargeBottomInset", '.08')
	
	SetCVar("nameplateShowOnlyNames", 0) 
	
	--ns:LockCVar("nameplateShowOnlyNames", 1)
	ns:LockCVar("nameplateShowDebuffsOnFriendly", 0)
	
	ns:LockCVar("nameplateLargerScale", 1)
	ns:LockCVar("nameplateMinAlpha", 1)
	
	ns:LockCVar('nameplateShowAll', 1) 
	
	ns:LockCVar('UnitNameFriendlyPlayerName', 1) 
	C_NamePlate.SetNamePlateFriendlyClickThrough(true)
	
	
	--SetCVar("nameplateShowFriends", GetCVarBool("nameplateShowFriends") and 0 or 1) 
	
	
	local ignoreSizeChange = false

	local function SetSize()
		ignoreSizeChange = true
		C_NamePlate.SetNamePlateFriendlySize(1, 1);    
		SetCVar('nameplateMaxDistance', ns.db.distance)
		--print('FI Update nameplate size')
		ignoreSizeChange = false        
	end
	
	local outcombatUpdate = CreateFrame('Frame')
	outcombatUpdate:SetScript('OnEvent', function(self, event)
		SetSize()
		self:UnregisterEvent(event)
	end)
	
	local function UpdateBasePlateSize()
		if ignoreSizeChange then return end
		if InCombatLockdown() then
			outcombatUpdate:RegisterEvent('PLAYER_REGEN_ENABLED')
		else
			SetSize()
		end
	end
	
	SetSize()

	hooksecurefunc(C_NamePlate, 'SetNamePlateFriendlySize', UpdateBasePlateSize)
	C_NamePlate.SetNamePlateFriendlySize(1, 1); 
	
	if ElvUI then 
		hooksecurefunc(ElvUI[1]:GetModule('NamePlates'), 'ConfigureAll', UpdateBasePlateSize)
	end
	
	--[==[
		print(' ') 
		print('===== FI Apply CVars =========') 
		print('  nameplateMinScale:', GetCVar('nameplateMinScale')) 
		print('  nameplateMaxScale:', GetCVar('nameplateMaxScale')) 
		print('  nameplateGlobalScale:', GetCVar('nameplateGlobalScale')) 
		print('  nameplateOtherTopInset:', GetCVar('nameplateOtherTopInset')) 
		print('  nameplateOtherBottomInset:', GetCVar('nameplateOtherBottomInset')) 
		print('  nameplateLargeBottomInset:', GetCVar('nameplateLargeBottomInset')) 
		print('  nameplateLargeTopInset:', GetCVar('nameplateLargeTopInset')) 
		print(' ') 
	]==]
end)

do

	local outofcombat = CreateFrame('Frame')
	outofcombat:SetScript('OnEvent', function(self, event)
		ns.NamePlateVisUpdate()
		self:UnregisterEvent(event)
	end)
	
	
	local function Handler(self)
		local _, instanceType, difficultyID = GetInstanceInfo()
		
		if instanceType ~= self.instanceType then
			self.instanceType = instanceType
			
			if (IsInInstance() and difficultyID ~= 0) then		
				local curZone = GetRealZoneText()
				if curZone ~= self.zone then
					self.zone = curZone

					if InCombatLockdown() then
						outofcombat:RegisterEvent('PLAYER_REGEN_ENABLED')
					else
						SetCVar("nameplateShowFriends", ns.db.inDungeon and '1' or '0') 
					end
				--	print('Join instance. Prev=', self.prevStatus)
				--	print('Enable friendly nameplates. Prev=', self.prevStatus)
				end
			else
			--	print('Leave instance. Prev=', self.prevStatus)
				self.zone = nil
				if InCombatLockdown() then
					outofcombat:RegisterEvent('PLAYER_REGEN_ENABLED')
				else
					SetCVar("nameplateShowFriends", ns.db.inWorld and '1' or '0')
				end
			end
		end
	end
	
	local eventFrame = CreateFrame('Frame')
	eventFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	eventFrame:SetScript('OnEvent', Handler)
	
	hooksecurefunc(ns, 'DefaultsReady', function(...)
		Handler(eventFrame)
	end)
		
	function ns.NamePlateVisUpdate()
		local _, instanceType, difficultyID = GetInstanceInfo()
		
		if (IsInInstance() and difficultyID ~= 0) then		
			-- Instance
			if not InCombatLockdown() then
				SetCVar("nameplateShowFriends", ns.db.inDungeon and '1' or '0') 
			end
		else
			-- World
			if not InCombatLockdown() then
				SetCVar("nameplateShowFriends", ns.db.inWorld and '1' or '0')
			end
		end
	end
end