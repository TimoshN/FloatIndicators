﻿if AleaUI_GUI then return end
local C = _G['AleaGUI_PrototypeLib']

C.DDFonts = {}
C.fontFrames = {}

local DD = C.DDFonts

local NUM_BUTTONS = 4
local BUTTON_HEIGHT = 60
local BUTTON_WIDTH = 96
local LIST_NUM_VALUES = 0

DD.list = {}
DD.list_data = {}

local list = DD.list
local list_data = DD.list_data

local wipe = table.wipe

local buttons = {}
local _
local table_sort = table.sort
local statearrow = C.statearrow
local dropdownFrame
local update 

function DD.buildList(t)

	DD.list_data = t
	list_data = DD.list_data
	
	local i = 0
	wipe(list)
	
	for k in pairs(list_data) do
		i = i + 1
		list[i] = k
	end
	
	table_sort(list, function(x, y)
		return tostring(list_data[x]) < tostring(list_data[y])
	end)
	
	LIST_NUM_VALUES = i
end


function update(self, checkedkey)
	local numItems = #list
	local offset = 0

	if checkedkey then
		self.checkedkey = checkedkey
	end
	
	if numItems <= NUM_BUTTONS then
		self:Hide()
	else
		self:Show()
		FauxScrollFrame_Update(self, numItems, NUM_BUTTONS, BUTTON_HEIGHT)
		offset = FauxScrollFrame_GetOffset(self)
	end

	for line = 1, NUM_BUTTONS do
		local lineplusoffset = line + offset
		local button = buttons[line]
		if lineplusoffset > numItems then
			button:Hide()
			button.select:Hide()
		else
			local name, desc = nil, nil
			local key = list[lineplusoffset]
		
			if type(list_data[key]) == "table" then
				name = list_data[key].name or UNKNOWN
				desc = list_data[key].desc
			else
				name = list_data[key] or UNKNOWN
			end
			
			button.key = key
			
			button.test:SetFont(name, 12, "OUTLINE")
			
			if button.key == self.checkedkey then			
				button.select:Show()
			else
				button.select:Hide()
			end

			button.text:SetText(key)
			button.desc = desc
			button:Show()
		end
	end
end


dropdownFrame = CreateFrame("Frame",  "AleaUIGUIFontDropDownFrame"..C:GetNumFrames())
dropdownFrame:SetSize(300, 200)
dropdownFrame.bg = dropdownFrame:CreateTexture()
dropdownFrame.bg:SetAllPoints()
if C.IsLegion then
	dropdownFrame.bg:SetColorTexture(0, 0,0, 0.8)
else
	dropdownFrame.bg:SetTexture(0, 0,0, 0.8)
end
dropdownFrame:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
dropdownFrame.Update = function(self)end

dropdownFrame.border1 = CreateFrame("Frame", nil, dropdownFrame,BackdropTemplateMixin and 'BackdropTemplate')
dropdownFrame.border1:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", -10, 10)
dropdownFrame.border1:SetPoint("BOTTOMRIGHT", dropdownFrame, "BOTTOMRIGHT", 10, -10)
dropdownFrame.border1:SetBackdrop({
	bgFile = [[Interface\Buttons\WHITE8x8]],
	edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
	edgeSize = 22,
	insets = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	}
})
dropdownFrame.border1:SetBackdropColor(0, 0, 0, 1)
dropdownFrame.border1:SetBackdropBorderColor(1, 1, 1, 1)

dropdownFrame.scrollFrame = CreateFrame("ScrollFrame", "AleaUIGUIFontScrollingFrame"..C:GetNumFrames() , dropdownFrame, "FauxScrollFrameTemplate")

dropdownFrame.scrollFrame:SetWidth(BUTTON_WIDTH)
dropdownFrame.scrollFrame:SetFrameLevel(dropdownFrame:GetFrameLevel()+1)
dropdownFrame.scrollFrame:SetPoint("TOPRIGHT",dropdownFrame, "TOPRIGHT", -20, 0)
dropdownFrame.scrollFrame:SetPoint("TOPLEFT",dropdownFrame, "TOPLEFT", -20, 0)
dropdownFrame.scrollFrame:EnableMouse(true)
dropdownFrame.scrollFrame:SetMovable(true)
dropdownFrame.scrollFrame:SetVerticalScroll(0)
dropdownFrame.scrollFrame:RegisterForDrag("LeftButton")
dropdownFrame.scrollFrame:Show()
dropdownFrame.scrollFrame.scroll = 0
dropdownFrame.scrollFrame:SetClampedToScreen(true)
dropdownFrame.scrollFrame:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
dropdownFrame.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, BUTTON_HEIGHT, update)
end)

dropdownFrame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
	local reduce = self.scroll-( BUTTON_HEIGHT * delta)

	if reduce < 0 then
		reduce = 0
	elseif reduce > self:GetVerticalScrollRange() then
		reduce = self:GetVerticalScrollRange()
	end
	self.scroll = reduce
	self:SetVerticalScroll(self.scroll)
end)


for i = 1, NUM_BUTTONS do
	
	if not buttons[i] then
		local button = CreateFrame("Button", nil, dropdownFrame)
		button:SetFrameLevel(dropdownFrame.scrollFrame:GetFrameLevel()+1)
		if i == 1 then
			button:SetPoint("TOPLEFT", dropdownFrame, -BUTTON_WIDTH*0.3+3, 0)
			button:SetPoint("TOPRIGHT", dropdownFrame, -BUTTON_WIDTH*0.3+3, 0)
		else
			button:SetPoint("TOPRIGHT", buttons[i - 1], "BOTTOMRIGHT")
			button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT")
		end
		button:SetNormalFontObject("GameFontNormal")
		
		button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
		
		button.select = button:CreateTexture(nil, "OVERLAY",1)
		button.select:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button.select:SetSize(BUTTON_WIDTH*0.2, BUTTON_WIDTH*0.2)
		button.select:SetPoint("LEFT", button, "LEFT", BUTTON_WIDTH*0.3, 0)
		button.select:Hide()
		--[==[
		button.mouseup = button:CreateTexture(nil, "OVERLAY",1)
		button.mouseup:SetTexture(1, 1, 0, 0.3)
		button.mouseup:SetPoint("LEFT", button.select, "LEFT", 0, 0)
		button.mouseup:SetPoint("TOP", button, "TOP", 0, -2)
		button.mouseup:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 2)
		button.mouseup:Hide()
		]==]
		
		button.mouseup = button:CreateTexture()
		button.mouseup:SetDrawLayer("OVERLAY", 1)
		button.mouseup:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") --"Interface\\Buttons\\UI-Common-MouseHilight")
		button.mouseup:SetBlendMode("ADD")
		button.mouseup:Hide()

		button.mouseup:SetPoint("LEFT",   button, "LEFT",   30, 0)
		button.mouseup:SetPoint("RIGHT",  button, "RIGHT",  0, 0)
		button.mouseup:SetPoint("TOP",    button, "TOP",    0, 0)
		button.mouseup:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
	
		button.test = button:CreateFontString(nil, "OVERLAY",1)
		button.test:SetFontObject('ChatFontNormal')
		button.test:SetWidth(250)
		button.test:SetJustifyH("CENTER")
		button.test:SetText("ABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n1234567890")
		button.test:SetPoint("TOP", button, "TOP",5, -2)
		button.test:SetWordWrap(true)
		
		button.text = button:CreateFontString(nil, "OVERLAY",1)
		button.text:SetFontObject('ChatFontNormal')
		button.text:SetWidth(250)
		button.text:SetHeight(12)
		button.text:SetJustifyH("LEFT")
		button.text:SetPoint("BOTTOM", button, "BOTTOM",5, 2)
		button.text:SetWordWrap(false)

		button:SetScript("OnClick", function(self, ...)
			dropdownFrame.parent._OnClick(_, self.key)
			C:GetRealParent(dropdownFrame.parent):RefreshData()
		end)
		
		button:SetScript("OnEnter", function(self, ...)
			self.mouseup:Show()		
		end)
		button:SetScript("OnLeave", function(self, ...)
			self.mouseup:Hide()
		end)
		
		buttons[i] = button
	end
end

local function UpdateDD(f,key)
	DD.buildList(f.values)
	dropdownFrame.scrollFrame.checkedkey = key
	dropdownFrame.scrollFrame.border = (f and f.border )
	dropdownFrame.scrollFrame.statusbar = (f and f.statusbar )
	
	update(dropdownFrame.scrollFrame, key)
	
	if #list <= NUM_BUTTONS then
		dropdownFrame.scrollFrame:Hide()
	else
		dropdownFrame.scrollFrame:Show()
	end
	
	if dropdownFrame.parent then
		dropdownFrame.parent.arrow.text:SetText(statearrow[2])
	end
	local realparent = C:GetRealParent(f)
	dropdownFrame:SetParent(realparent)
	dropdownFrame:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -7)
	dropdownFrame:SetFrameLevel(realparent:GetFrameLevel()+10)
	dropdownFrame:Update()
	dropdownFrame:Show()
	dropdownFrame.parent = f
	dropdownFrame.parent.arrow.text:SetText(statearrow[1])
end

function DD.HideFonts()
	
	if dropdownFrame:IsShown() then
		dropdownFrame:Hide()
		if dropdownFrame.parent then
			dropdownFrame.parent.arrow.text:SetText(statearrow[2])
		end
		dropdownFrame.parent = nil
		dropdownFrame.scrollFrame.checkedkey = nil
		dropdownFrame.scrollFrame.border = nil
		dropdownFrame.scrollFrame.statusbar = nil
	end
end

function DD.ShowFonts(f,key)
--	C.DD.Hide()
--	C.DDSounds.HideFonts()
	
	C:FreeDropDowns(DD)
	
	if dropdownFrame.parent and dropdownFrame.parent ~= f then
		UpdateDD(f,key)
	elseif dropdownFrame.parent then
		dropdownFrame:Hide()
		if dropdownFrame.parent then
			dropdownFrame.parent.arrow.text:SetText(statearrow[2])
		end
		dropdownFrame.parent = nil
		dropdownFrame.scrollFrame.checkedkey = nil
		dropdownFrame.scrollFrame.border = nil
		dropdownFrame.scrollFrame.statusbar = nil
	else
		UpdateDD(f,key)
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
	
	self.free = false
	self:SetParent(panel)
	self:SetDescription(opts.desc)
	self:Show()	
	
	self:SetName(opts.name)
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

	self.main.value:SetText(self.main._OnShow() or "")
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
	right:SetPoint("TOPRIGHT", 15, 17)
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
	
	f.arrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	f.arrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	f.arrow:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	f.arrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	
	f.arrow.text = f.arrow:CreateFontString(nil, "OVERLAY")
	f.arrow.text:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
	f.arrow.text:SetPoint("CENTER")
	f.arrow.text:SetText(C.statearrow[2])
	f.arrow.text:Hide()
	f.arrow.text:SetJustifyH("CENTER")
	f.arrow.text:SetJustifyV("CENTER")
	f.arrow.text:SetWordWrap(false)
	
	
	f.arrow:SetScript("OnEnter", function(self)
		C.Tooltip(self, f._rname, f.desc, "show")
	end)
	f.arrow:SetScript("OnLeave", function(self)
		C.Tooltip(self, f._rname, f.desc, "hide")
	end)
	
	
	f.arrow:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
		if self:GetParent()._values then
			self:GetParent().values = self:GetParent()._values()
		end
		DD.ShowFonts(self:GetParent(), self:GetParent()._OnShow())
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
	text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 3 , 0)
	text:SetPoint("BOTTOMRIGHT", f.arrow, "TOPRIGHT", 0 , 0)
--	text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	text:SetTextColor(1, 0.8, 0)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	
	local value = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	value:SetPoint("LEFT", f, "LEFT", 3 , 0)
	value:SetPoint("RIGHT", f.arrow, "LEFT", 0 , 0)
--	value:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	value:SetTextColor(1, 1, 1)
	value:SetJustifyH("RIGHT")
	value:SetWordWrap(false)
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", value, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", value, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)	
		C.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
		C.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)
	
	f.text = text
	f.value = value
	
	return f
end

function C:CreateFontDD()
	
	for i=1, #C.fontFrames do
		if C.fontFrames[i].free then
			return C.fontFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-FontsFrame'..#C.fontFrames+1, UIParent)
	f:SetSize(180, 45)
	f.free = true
	
	f.main = CreateCoreDropDown(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -10)
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	f.UpdateSize = UpdateSize
	
	C.fontFrames[#C.fontFrames+1] = f
	
	return f
end
	
C.prototypes["font"] = "CreateFontDD"