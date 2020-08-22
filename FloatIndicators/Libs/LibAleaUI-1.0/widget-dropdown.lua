if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.toggleDropdowns = {}

local function Update(self, panel, opts)
	assert(opts.values, "No Values is set on "..opts.name)
	
	self.main._values = nil
	
	if type(opts.values) == "function" then
		self.main._values = opts.values
		self.main.values = self.main._values()		
	elseif type(opts.values) == "table" then
		self.main.values = opts.values
	else
		assert(false, "Values should be only function of table")
	end

	self.main.showSpellTooltip = opts.showSpellTooltip
	self.main.docked = opts.docked
	self.free = false
	self:SetParent(panel)
	self:SetDescription(opts.desc)
	self:Show()	
	self:SetName(opts.name)
	self:SetDisabledState(opts.disabled)
	self:UpdateState(opts.set, opts.get)
	
	if panel.childs then
		panel.childs[self] = true
	else
	
	end
end

local function UpdateSize(self, panel, opts, parent)
	if opts.width == 'full' then
		if parent then
			self:SetWidth( parent:GetWidth() - 15)
			self.main:SetWidth( parent:GetWidth() - 15)
		else
			self:SetWidth( panel:GetWidth() - 25)
			self.main:SetWidth( panel:GetWidth() - 25)
		end
	else
		self:SetWidth(180)
		self.main:SetWidth(170)
	end
end

local function Remove(self)
	self.free = true
	self:Hide()
	self:ClearAllPoints()
end

local function SetName(self, name)
	self.main._rname = name
	self.main.text:SetText(name)
end

local function SetDescription(self, text)
	self.main.desc = text
end

local function UpdateState(self, func, get)
	
	self.main._OnClick = func
	self.main._OnShow = get
	
	self.main.value:SetText(self.main.values[self.main._OnShow()] or "")
end

local function SetDisabledState(self, state)

	if state == true then		
		self.main.text:SetTextColor(0.5, 0.5, 0.5)
		self.main.value:SetTextColor(0.5, 0.5, 0.5)
		self.main.arrow:Disable()		
	else
		self.main.text:SetTextColor(1, 0.8, 0)
		self.main.value:SetTextColor(1, 1, 1)
		self.main.arrow:Enable()	
	end
end

local function CreateCoreDropDown(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(170, 25)
	
	local left = f:CreateTexture(nil, "BORDER")
	left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
	left:SetTexCoord(0, 0.1953125, 0, 1)
	left:SetPoint("TOPLEFT", -20, 17)
	left:SetSize(25, 64)
	
	local right = f:CreateTexture(nil, "BORDER")
	right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
	right:SetTexCoord(0.8046875, 1, 0, 1)
	right:SetPoint("TOPRIGHT", 10, 17)
	right:SetSize(25, 64)
	
	local middle = f:CreateTexture(nil, "BORDER")
	middle:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
	middle:SetTexCoord(0.1953125, 0.8046875, 0, 1)
	middle:SetPoint("LEFT", left, "RIGHT", 0, 0)
	middle:SetPoint("RIGHT", right, "LEFT", 0, 0)
	middle:SetSize(165, 64)

	f.arrow = CreateFrame('Button', nil, f) --"UICheckButtonTemplate"
	f.arrow:SetPoint("RIGHT", right, "RIGHT", -15, 1)
	f.arrow:SetFrameLevel(f:GetFrameLevel() + 1)
	f.arrow:SetSize(25, 25)
	
	f.arrow.text = f.arrow:CreateFontString(nil, "OVERLAY")
	f.arrow.text:SetFont("Fonts\\ARIALN.TTF", 1, "OUTLINE")
	f.arrow.text:SetPoint("CENTER")
	f.arrow.text:SetText(ns.statearrow[2])
	f.arrow.text:Hide()
	f.arrow.text:SetWordWrap(false)
	
	f.arrow.text:SetJustifyH("CENTER")
	f.arrow.text:SetJustifyV("CENTER")
	
	f.arrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	f.arrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	f.arrow:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	f.arrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	
	f.arrow:SetScript("OnEnter", function(self)	
		ns.Tooltip(self, f._rname, f.desc, "show")
	end)
	f.arrow:SetScript("OnLeave", function(self)
		ns.Tooltip(self, f._rname, f.desc, "hide")
	end)

	f.arrow:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
		if self:GetParent()._values then
			self:GetParent().values = self:GetParent()._values()
		end
		ns.DD.Show(self:GetParent(),self:GetParent()._OnShow())
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 3 , -2)
	text:SetPoint("BOTTOMRIGHT", f.arrow, "TOPRIGHT", 0 , -2)
	text:SetTextColor(1, 0.8, 0)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	
	local value = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	value:SetPoint("LEFT", f, "LEFT", 3 , 0)
	value:SetPoint("RIGHT", f.arrow, "LEFT", 0 , 0)
	value:SetTextColor(1, 1, 1)
	value:SetJustifyH("RIGHT")
	value:SetWordWrap(false)
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", value, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", value, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)	
		ns.Tooltip(self, self:GetParent()._rname,  self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)
	
	f.text = text
	f.value = value
	
	return f
end

function ns:CreateDropDown()
	
	for i=1, #ns.toggleDropdowns do
		if ns.toggleDropdowns[i].free then
			return ns.toggleDropdowns[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-DropDownButton'..#ns.toggleDropdowns+1, UIParent)
	f:SetSize(180, 45)
	f.free = true
	
	f.main = CreateCoreDropDown(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -10)
	f.main:SetPoint("RIGHT", f, "RIGHT", 0, 0)
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	f.SetDisabledState = SetDisabledState
	f.UpdateSize = UpdateSize
	
	ns.toggleDropdowns[#ns.toggleDropdowns+1] = f
	
	return f
end
	
ns.prototypes["dropdown"] = "CreateDropDown"