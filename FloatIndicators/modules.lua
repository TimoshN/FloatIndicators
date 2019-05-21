local addon, ns = ...

local nameplateAPI = {}
local applyHook = false

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local UnitIsFriend = UnitIsFriend

local numAttepts = 0

do
	local eventFrame = CreateFrame('Frame')
	eventFrame:RegisterEvent('ADDON_LOADED')
	eventFrame:SetScript('OnEvent', function(self, event, ...)
		if ( event == 'ADDON_LOADED' ) then
			local addonName = ...
			
			if addon == addonName then
				nameplateAPI.DisableBlizzardNameplates()
			end
		end
	end)
end

function nameplateAPI.DisableBlizzardNameplates()
	if ( applyHook ) then
		return
	end
	
	applyHook = true

	NamePlateDriverFrame:UnregisterEvent('FORBIDDEN_NAME_PLATE_UNIT_ADDED')
	NamePlateDriverFrame:UnregisterEvent('FORBIDDEN_NAME_PLATE_CREATED')
	NamePlateDriverFrame:UnregisterEvent('FORBIDDEN_NAME_PLATE_UNIT_REMOVED')
	
	NamePlateDriverFrame.OnUnitAuraUpdate = function(self, unit)
		if self:IsForbidden() then return end	
		NamePlateDriverMixin.OnUnitAuraUpdate(self, unit)
	end

	NamePlateDriverFrame.OnUnitFactionChanged = function(self, unit)
		if self:IsForbidden() then return end		
		NamePlateDriverMixin.OnUnitFactionChanged(self, unit)
	end

	function NamePlateDriverFrame:OnRaidTargetUpdate()
		if self:IsForbidden() then return end			
		NamePlateDriverMixin:OnRaidTargetUpdate()
	end

	NamePlateDriverMixin:SetupClassNameplateBars()
	
	
	local old_NamePlateDriverFrame_SetupClassNameplateBars = NamePlateDriverFrame.SetupClassNameplateBars
	
	function NamePlateDriverFrame:SetupClassNameplateBars()
	
		local showMechanicOnTarget;
		if self.classNamePlateMechanicFrame and self.classNamePlateMechanicFrame.overrideTargetMode ~= nil then
			showMechanicOnTarget = self.classNamePlateMechanicFrame.overrideTargetMode;
		else
			showMechanicOnTarget = GetCVarBool("nameplateResourceOnTarget");
		end

		local anchorMechanicToPowerBar = false;
		if self.classNamePlatePowerBar then
			local namePlatePlayer = C_NamePlate.GetNamePlateForUnit("player", issecure());
			if namePlatePlayer then
				self.classNamePlatePowerBar:SetParent(namePlatePlayer);
				self.classNamePlatePowerBar:SetPoint("TOPLEFT", namePlatePlayer.UnitFrame.healthBar, "BOTTOMLEFT", 0, 0);
				self.classNamePlatePowerBar:SetPoint("TOPRIGHT", namePlatePlayer.UnitFrame.healthBar, "BOTTOMRIGHT", 0, 0);
				self.classNamePlatePowerBar:Show();

				anchorMechanicToPowerBar = true;
			else
				self.classNamePlatePowerBar:Hide();
			end
		end

		if self.classNamePlateMechanicFrame then
			if showMechanicOnTarget then
				local namePlateTarget = C_NamePlate.GetNamePlateForUnit("target", issecure());
				if namePlateTarget then
					self.classNamePlateMechanicFrame:SetParent(namePlateTarget);
					self.classNamePlateMechanicFrame:ClearAllPoints();
					PixelUtil.SetPoint(self.classNamePlateMechanicFrame, "BOTTOM", namePlateTarget.UnitFrame.name, "TOP", 0, 4);
					self.classNamePlateMechanicFrame:Show();
				else
					self.classNamePlateMechanicFrame:Hide();
				end
			elseif anchorMechanicToPowerBar then
				local namePlatePlayer = C_NamePlate.GetNamePlateForUnit("player", issecure());
				self.classNamePlateMechanicFrame:SetParent(namePlatePlayer);
				self.classNamePlateMechanicFrame:ClearAllPoints();
				self.classNamePlateMechanicFrame:SetPoint("TOP", self.classNamePlatePowerBar, "BOTTOM", 0, self.classNamePlateMechanicFrame.paddingOverride or -4);
				self.classNamePlateMechanicFrame:Show();
			else
				local namePlatePlayer = C_NamePlate.GetNamePlateForUnit("player", issecure());
				if namePlatePlayer then
					self.classNamePlateMechanicFrame:SetParent(namePlatePlayer);
					self.classNamePlateMechanicFrame:ClearAllPoints();
					self.classNamePlateMechanicFrame:SetPoint("TOP", namePlatePlayer.UnitFrame.healthBar, "BOTTOM", 0, self.classNamePlateMechanicFrame.paddingOverride or -4);
					self.classNamePlateMechanicFrame:Show();
				else
					self.classNamePlateMechanicFrame:Hide();
				end
			end
		end
		--[==[
		local targetMode = GetCVarBool("nameplateResourceOnTarget");
		if (self.nameplateBar and self.nameplateBar.overrideTargetMode ~= nil) then
			targetMode = self.nameplateBar.overrideTargetMode;
		end
		self:SetupClassNameplateBar(targetMode, self.nameplateBar);
		self:SetupClassNameplateBar(false, self.nameplateManaBar);
		]==]
		
		--old_NamePlateDriverFrame_SetupClassNameplateBars(NamePlateDriverMixin)
	end
end

function nameplateAPI.EnableBlizzardNameplates()
	if ( applyHook ) then
		return
	end
	
	applyHook = true

	NamePlateDriverFrame:RegisterEvent('FORBIDDEN_NAME_PLATE_CREATED')
	NamePlateDriverFrame:RegisterEvent('FORBIDDEN_NAME_PLATE_UNIT_ADDED')
	NamePlateDriverFrame:RegisterEvent('FORBIDDEN_NAME_PLATE_UNIT_REMOVED') 
end

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
--[==[	hooksecurefunc(C_NamePlate, 'SetNamePlateEnemySize', UpdateBasePlateSize) ]==]
--[==[	hooksecurefunc(C_NamePlate, 'SetNamePlateSelfSize', UpdateBasePlateSize) ]==]
	
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
	
	if ( WeakAurasSaved ) then
		for k,v in pairs(WeakAurasSaved.displays) do
			if k and k:find('ElvUIHookPlate') then
				print('Find bad WAs', k)
			end
		end
	end
end)
--[==[
do
	local nphandler = CreateFrame('Frame')
	nphandler:RegisterEvent('PLAYER_TARGET_CHANGED')
	nphandler:SetScript('OnEvent', function(self, event, unit)
		if UnitExists('target') then
			local realFrame = C_NamePlate.GetNamePlateForUnit('target')
			for _, frame in pairs(C_NamePlate.GetNamePlates()) do
				if frame ~= realFrame then
					if frame.UnitFrame then
						frame.UnitFrame:SetAlpha(0.6)
					end
				end
			end

			if ( realFrame ) then
				if realFrame.UnitFrame then
					realFrame.UnitFrame:SetAlpha(1)
				end
			end
		else
			for _, frame in pairs(C_NamePlate.GetNamePlates()) do
				if frame.UnitFrame then
					frame.UnitFrame:SetAlpha(0.6)
				end
			end
		end
	end)

end

do
	local nphandler = CreateFrame('Frame')
	nphandler:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	nphandler:SetScript('OnEvent', function(self, event, unit)
		if UnitIsFriend("player", unit) and not UnitIsUnit('player', unit) then
			local namePlateFrameBase = C_NamePlate.GetNamePlateForUnit(unit);
			
			if namePlateFrameBase then
				if namePlateFrameBase.UnitFrame then

					namePlateFrameBase.UnitFrame:SetIgnoreParentAlpha(true)
					namePlateFrameBase.UnitFrame:SetAlpha(1)
					
					namePlateFrameBase.UnitFrame.healthBar:Hide()
			
					if namePlateFrameBase.UnitFrame.healthBar then
						namePlateFrameBase.UnitFrame.healthBar:SetAlpha(0)
					end
					if namePlateFrameBase.UnitFrame.castBar then
						namePlateFrameBase.UnitFrame.castBar:SetAlpha(0)
					end
					if namePlateFrameBase.UnitFrame.selectionHighlight then
						namePlateFrameBase.UnitFrame.selectionHighlight:SetAlpha(0)
					end
				end
			end
		else
			local namePlateFrameBase = C_NamePlate.GetNamePlateForUnit(unit);
			
			if namePlateFrameBase then				
				if namePlateFrameBase.UnitFrame then
					namePlateFrameBase.UnitFrame:SetIgnoreParentAlpha(true)
					namePlateFrameBase.UnitFrame:SetAlpha( UnitIsUnit("target", unit) and 1 or 0.6 )
					
					namePlateFrameBase.UnitFrame.healthBar:Show()
					if namePlateFrameBase.UnitFrame.healthBar then
						namePlateFrameBase.UnitFrame.healthBar:SetAlpha(1)

						namePlateFrameBase.UnitFrame.healthBar:SetSize(120, 4)
					end
					if namePlateFrameBase.UnitFrame.castBar then
						namePlateFrameBase.UnitFrame.castBar:SetAlpha(1)
					end
					if namePlateFrameBase.UnitFrame.selectionHighlight then
						namePlateFrameBase.UnitFrame.selectionHighlight:SetAlpha(.25)
					end
				end
			end
		end
	end)
end
]==]

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