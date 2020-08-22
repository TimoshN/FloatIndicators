if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.multiSelect = {}
local _
local BuildDropDown, UpdateDropdownButtons, ResetDropdowns
local ResetNextDropdowns

local stringHeight = 14
local stringTextSize = 12
local minWidth = 80
local numButtonLines = 10
local lineWidth = 130

local dropdowns = {}

local chekcerForHide = CreateFrame("Frame")
chekcerForHide:Hide()
chekcerForHide:SetScript('OnUpdate', function(self, elapsed)
	self.elapsed = ( self.elapsed or 0 ) + elapsed
	
	if self.elapsed < 3 then return end
	
	local isMultiOpen = false
	
	for i=2, #dropdowns do
		if dropdowns[i]:IsVisible() then
			isMultiOpen = true
			if MouseIsOver(dropdowns[i]) then
				self.elapsed = 0 
				
		--		print('T', 'Mouse over', 'dropdown', i, 'delay')
				return
			end
		end
	end
	--[==[
	for i=1, #nextDropDownButtons do
		if nextDropDownButtons[i]:IsVisible() then
			if MouseIsOver(nextDropDownButtons[i]) then
				self.elapsed = 0 
				
		--		print('T', 'Mouse over', 'nextDropDownButtons', i, 'delay')
				return
			end
		end
	end
	
	for i=1, #selectButtons do
		if selectButtons[i]:IsVisible() then
			if MouseIsOver(selectButtons[i]) then
				self.elapsed = 0 
				
		--		print('T', 'Mouse over', 'nextDropDownButtons', i, 'delay')
				return
			end
		end
	end
	]==]
	
	if not isMultiOpen and dropdowns[1] and dropdowns[1]:IsVisible() then
		self.elapsed = 0
	--	print('T', 'Only open main dropdown', 'Delay')
		return
	end
	
	self:Hide()
	ResetDropdowns(true)
--	print('T', 'Hide dropdowns')
end)

local function StartCheckForHide()
	chekcerForHide.elapsed = 0
	chekcerForHide:Show()
end

local function EndCheckForHide()
	chekcerForHide.elapsed = 0
	chekcerForHide:Hide()
end
	
function ns:HideMultiDropdown()
	ResetDropdowns(true)
	EndCheckForHide()
end

function ResetDropdowns(clearParent)
	
	for i=1, #dropdowns do
		dropdowns[i]:Free()
		
		if clearParent then
			dropdowns[i].parent = nil
		end
	end
	
end

function ResetNextDropdowns(step)
	
	for i=step, #dropdowns do
		dropdowns[i]:Free()
	end
	
end

local function createNewButton()
	
	local frame = CreateFrame("Frame")
	frame.typo = nil
	
	frame:SetSize(lineWidth, stringHeight)
	
	frame.highlight = frame:CreateTexture(nil, "ARTWORK")
	frame.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") --"Interface\\Buttons\\UI-Common-MouseHilight")
	frame.highlight:SetBlendMode("ADD")
	frame.highlight:Hide()

	frame.highlight:SetPoint("LEFT",   frame, "LEFT",   0, 0)
	frame.highlight:SetPoint("RIGHT",  frame, "RIGHT",  0, 0)
	frame.highlight:SetPoint("TOP",    frame, "TOP",    0, 0)
	frame.highlight:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)

	frame.arrow = frame:CreateTexture(nil, 'OVERLAY')
	frame.arrow:SetSize(16, 16)
	frame.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
	frame.arrow:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	
	frame.check = frame:CreateTexture(nil, 'OVERLAY')
	frame.check:SetSize(16, 16)
	frame.check:SetTexture("Interface\\Common\\UI-DropDownRadioChecks")
	frame.check:SetTexCoord(0, 0.5, 0.5, 1)
	frame.check:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	
	frame.text = frame:CreateFontString(nil, 'OVERLAY')
	frame.text:SetFont(STANDARD_TEXT_FONT, stringTextSize, 'NONE')
	frame.text:SetText('Next Button')
	frame.text:SetPoint('LEFT', frame.check, 'RIGHT', 0, 0)
	frame.text:SetPoint('RIGHT', frame.arrow, 'LEFT', 0, 0)
	frame.text:SetJustifyH('LEFT')
	frame.text:SetWordWrap(false)
	
	frame.SetButtonType = function(self, typo)
		if typo == 'arrow' then
			self.arrow:SetWidth(16)
			self.check:SetWidth(0.0001)
		elseif typo == 'check' then
			self.check:SetWidth(16)
			self.arrow:SetWidth(0.0001)
		else
			self.check:SetWidth(0.0001)
			self.arrow:SetWidth(0.0001)
		end	
		
		self.typo = typo
	end
	
	frame.SetStatus = function(self, checked)
		if checked then			
			self.check:SetTexCoord(0, 0.5, 0.5, 1)
		else
			self.check:SetTexCoord(0.5, 1.0, 0.5, 1)
		end
	end
	
	frame:SetScript("OnMouseUp", function(self)
		if self.typo ~= 'check' then return end
		
		if dropdowns[1] and dropdowns[1].parent then
		--	print('Click', 'Value', self.step, self.value, dropdowns[1].parent)
			
			dropdowns[1].parent._OnClick(_, self.value)
			ns:GetRealParent(dropdowns[1].parent):RefreshData()
		end
		
		ResetDropdowns(true)
		EndCheckForHide()
	end)
	
	frame:SetScript('OnEnter', function(self)
		ns.Tooltip(self:GetParent().tooltipParent, self.text:GetText(),  nil, "show")
		
		self.highlight:Show()
		
		if self.typo == 'arrow' then
			
			ResetNextDropdowns(self.step+2)
			
			local dropdown = BuildDropDown(self.values, self.step+1, self.key)
			local realparent = ns:GetRealParent(self)
			dropdown:Show()
			dropdown.parent = self
			dropdown:SetParent(realparent)
			dropdown:SetFrameLevel(realparent:GetFrameLevel()+10)
			dropdown:ClearAllPoints()
			dropdown:SetPoint('TOPLEFT', self, 'TOPRIGHT', 15, -5)
			
			UpdateDropdownButtons(dropdown)
			
			self.dropdown = dropdown
		elseif self.typo == 'check' then
			if self.dropdown then
				self.dropdown:Free()
				self.dropdown = nil
			end
		
		end
	end)
	
	frame:SetScript('OnLeave', function(self)
		ns.Tooltip(self:GetParent().tooltipParent, self.text:GetText(),  nil, "hide")

		self.highlight:Hide()
		
		if self.typo == 'arrow' then
		
			if self.dropdown then
			--	self.dropdown:Free()
			--	self.dropdown = nil
			
				chekcerForHide.elapsed = 0
			end
		elseif self.typo == 'check' then
			if self.dropdown then
			--	self.dropdown:Free()
			--	self.dropdown = nil
			
				chekcerForHide.elapsed = 0
			end
		
		
		end

	end)
	
	return frame
end

local function createDropdownPanel(index)

	if dropdowns[index] then
		return dropdowns[index]
	end

	
	local frame = CreateFrame("Frame")
	frame:SetSize(100, 100)
	frame.DropDownIndex = index
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame.buttons = {}
	frame.values = {}
	frame.tempFrom = 1
	frame:SetScript("OnMouseWheel", function(self, delta)
		
		self.tempFrom = self.tempFrom - delta
	
		if self.tempFrom < 1 then
			self.tempFrom = 1
		end
		
		local minFrom = #self.values - 9
		
		if minFrom < 1 then
			minFrom = 1
		end
		
		if self.tempFrom > minFrom then
			self.tempFrom = minFrom
		end
	
		UpdateDropdownButtons(self)
	end)
	
	for i=1, numButtonLines do
		frame.buttons[i] = createNewButton()
		frame.buttons[i]:SetParent(frame)
		frame.buttons[i]:SetPoint('TOP', frame, 'TOP', 0,  -1*( i - 1 ) * (stringHeight + 2))
		frame.buttons[i]:Hide()
	end
	
	frame.tooltipParent = CreateFrame('Frame', nil, frame)
	frame.tooltipParent:SetSize(1, 10)
	frame.tooltipParent:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 0)
	frame.tooltipParent:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', 0, 0)
	
	frame.slider = frame:CreateFontString(nil, 'OVERLAY')
	frame.slider:SetFont(STANDARD_TEXT_FONT, stringTextSize, 'NONE')
	frame.slider:SetText('Next Button')
	frame.slider:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 0, -6)
	frame.slider:SetJustifyH('LEFT')
	frame.slider:SetWordWrap(false)
	frame.slider:Hide()
	
	frame.sliderIndicator = frame:CreateTexture(nil, 'OVERLAY')
	frame.sliderIndicator.parent = frame
	frame.sliderIndicator:SetSize(2, 100)
	if ns.IsLegion then
		frame.sliderIndicator:SetColorTexture(0.5,0.5,0.5,1)
	else
		frame.sliderIndicator:SetTexture(0.5,0.5,0.5,1)
	end
	
	frame.sliderIndicator:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1)
	frame.sliderIndicator.SetPosition = function(self, from, to, maxV)		
		if maxV <= numButtonLines then
			self:Hide()		
		else
			self:Show()
			local total = numButtonLines*(stringHeight+2)
			self:SetHeight(numButtonLines/maxV*total)
			self:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", 0, 1-(from-1)/maxV*total)
		end
	end
	
	frame.border1 = CreateFrame("Frame", nil, frame,BackdropTemplateMixin and 'BackdropTemplate')
	frame.border1:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, 10)
	frame.border1:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, -10)
	frame.border1:SetBackdrop({
		bgFile   = [[Interface\Buttons\WHITE8x8]],
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
		edgeSize = 22,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5,
		}
	})
	frame.border1:SetBackdropColor(0, 0, 0, 1)
	frame.border1:SetBackdropBorderColor(1, 1, 1, 1)
	
	frame.sliderIndicator:SetParent(frame.border1)
	
	frame.Free = function(self)
		self:Hide()
		self:ClearAllPoints()
		self.key = nil
		for i=1, numButtonLines do
			self.buttons[i]:Hide()
		end
	end
	
	frame:SetScript('OnEnter', function(self)
		chekcerForHide.elapsed = 0
	
	end)
	frame:SetScript('OnLeave', function(self)
		chekcerForHide.elapsed = 0
	end)
	
	dropdowns[index] = frame
	
	return frame
end

function UpdateDropdownButtons(dropdown)


	local numLines = 0
	
	for i=1, #dropdown.buttons do
		dropdown.buttons[i]:Hide()
	end
	
	dropdown.sliderIndicator:SetPosition(dropdown.tempFrom,dropdown.tempFrom + 9, #dropdown.values)
	
	dropdown.slider:SetText('('..dropdown.tempFrom..'-'..( dropdown.tempFrom + 9 )..') /'..#dropdown.values)
	
	for i=dropdown.tempFrom, #dropdown.values do
		numLines = numLines + 1

		if dropdown.buttons[numLines] then
			local data = dropdown.values[i]
			
			if data.values then	
				dropdown.buttons[numLines]:SetButtonType('arrow')
				dropdown.buttons[numLines].values = data.values
				dropdown.buttons[numLines].key = dropdown.key
			elseif data.value then
				dropdown.buttons[numLines]:SetButtonType('check')
				dropdown.buttons[numLines].value = data.value
				dropdown.buttons[numLines]:SetStatus( data.value == dropdown.key )
			end

			dropdown.buttons[numLines].step = dropdown.step
			dropdown.buttons[numLines]:Show()
			dropdown.buttons[numLines].text:SetText(data.name)
		end
	end
end

function BuildDropDown(list, step, key)
	local dropdown = createDropdownPanel(step)
	dropdown:SetWidth(lineWidth)
	dropdown:SetHeight(10)
	
	wipe(dropdown.values)
	dropdown.tempFrom = 1
	dropdown.key = key
	dropdown.step = step
	
	local height = 0
	
	local realIndex = 0

	for index, data in pairs(list) do	
		realIndex = realIndex + 1
		
		dropdown.values[realIndex] = data
	end
	
	if realIndex > numButtonLines then
		height = numButtonLines * ( stringHeight + 2 )
	else
		height = realIndex * ( stringHeight + 2 )
	end
	
	dropdown:SetHeight(height)
	
	UpdateDropdownButtons(dropdown)
	
	return dropdown
end

local function ShowDropdown(self, list, key)
	ResetDropdowns(false)
	
	ns:FreeDropDowns('multiDropDown')
	
	local dropdown = BuildDropDown(list, 1, key)
	
	local show = dropdown.parent ~= self

	if show then
	
		local realparent = ns:GetRealParent(self)
	
		dropdown:Show()
		dropdown.parent = self
		dropdown:SetParent(realparent)
		dropdown:SetFrameLevel(realparent:GetFrameLevel()+10)
		dropdown:ClearAllPoints()
		dropdown:SetPoint('TOP', self, 'BOTTOM', 0, -5)
		
		StartCheckForHide()
	else
		dropdown:Hide()
		dropdown.parent = nil
		
		EndCheckForHide()
	end
end

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
	
--	self.main.showSpellTooltip = opts.showSpellTooltip
	self.main.docked = opts.docked
	self.free = false
	self:SetParent(panel)
	self:SetDescription(opts.desc)
	self:Show()	
	self:SetName(opts.name)
	self:SetDisabledState(opts.disabled)
	self:UpdateState(opts.set, opts.get)
end

local function UpdateSize(self, panel, opts)
	if opts.width == 'full' then
		self:SetWidth(panel:GetWidth() - 25)
		self.main:SetWidth(panel:GetWidth() - 25)
	else
		self:SetWidth(180)
		self.main:SetWidth(170)
	end
end

local function Remove(self)
	self.free = true
	self:Hide()	
end

local function SetName(self, name)
	self.main._rname = name
	self.main.text:SetText(name)
end

local function SetDescription(self, text)
	self.main.desc = text
end

local function SearchForName(vars, list)	
	if not vars then return end
	if not list then return end
	
	for index, data in pairs(list) do		
		if data.name and data.value then
			vars[data.value] = data.name
		elseif data.value then
			vars[data.value] = data.value
		elseif data.values then
			SearchForName(vars, data.values)
		end
	end
end

local function UpdateState(self, func, get)
	
	self.main._OnClick = func
	self.main._OnShow = get
	
	local nameList = {}
	
	SearchForName(nameList, self.main.values)
	
	self.main.value:SetText(nameList[self.main._OnShow()] or "")
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

		ShowDropdown(self:GetParent(), self:GetParent().values, self:GetParent()._OnShow())
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 3 , 0)
	text:SetPoint("BOTTOMRIGHT", f.arrow, "TOPRIGHT", 0 , 0)
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

function ns:CreateMultiSelect()
	
	for i=1, #ns.multiSelect do
		if ns.multiSelect[i].free then
			return ns.multiSelect[i]
		end
	end
	
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(180, 45)
	f.free = true
	
	f.main = CreateCoreDropDown(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -10)
	f.main:SetPoint("RIGHT", f, "RIGHT", 0, 0)
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	f.SetDisabledState = SetDisabledState
	f.UpdateSize = UpdateSize
	
	ns.multiSelect[#ns.multiSelect+1] = f
	
	return f
end
	
ns.prototypes["multiselect"] = "CreateMultiSelect"