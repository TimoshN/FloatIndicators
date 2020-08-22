if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.DDSounds = {}
ns.soundFrames = {}

local DD = ns.DDSounds

local NUM_BUTTONS = 10
local BUTTON_HEIGHT = 20
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
local statearrow = ns.statearrow
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
			button.path = list_data[key]
			
			if button.key == self.checkedkey then			
				button.select:Show()
			else
				button.select:Hide()
			end

			button.text:SetText(key)
			button.desc = desc
			button:Show()
			
			dropdownFrame:SetHeight(BUTTON_HEIGHT*line)
		end
	end
end


dropdownFrame = CreateFrame("Frame",  "AleaUIGUISoundDropDownFrame"..ns:GetNumFrames())
dropdownFrame:SetSize(300, 200)
dropdownFrame.bg = dropdownFrame:CreateTexture()
dropdownFrame.bg:SetAllPoints()
dropdownFrame.bg:SetColorTexture(0, 0,0, 0.8)
dropdownFrame:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
dropdownFrame.Update = function(self)end

dropdownFrame.border1 = CreateFrame("Frame", nil, dropdownFrame, BackdropTemplateMixin and 'BackdropTemplate')
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

dropdownFrame.scrollFrame = CreateFrame("ScrollFrame", "AleaUIGUISoundScrillingFrame"..ns:GetNumFrames() , dropdownFrame, "FauxScrollFrameTemplate")

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

dropdownFrame.scrollFrame.ScrollBar:GetThumbTexture():SetDrawLayer("OVERLAY", 1)
dropdownFrame.scrollFrame.ScrollBar:SetFrameLevel(dropdownFrame.scrollFrame:GetFrameLevel()+2)
dropdownFrame.scrollFrame.ScrollBar.bg = dropdownFrame.scrollFrame.ScrollBar:CreateTexture(nil, "OVERLAY")
dropdownFrame.scrollFrame.ScrollBar.bg:SetAllPoints()
dropdownFrame.scrollFrame.ScrollBar.bg:SetColorTexture(0, 0, 0, 0)

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
			button:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 0, 0) --    -BUTTON_WIDTH*0.3+3, 0)
			button:SetPoint("TOPRIGHT", dropdownFrame, "TOPRIGHT", 0, 0) --   -BUTTON_WIDTH*0.3+3, 0)
		else
			button:SetPoint("TOPRIGHT", buttons[i - 1], "BOTTOMRIGHT")
			button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT")
		end
		button:SetNormalFontObject("GameFontNormal")
		
		button:EnableMouse(true)
		
		button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
		
		button.select = button:CreateTexture(nil, "BACKGROUND",1)
		button.select:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button.select:SetSize(BUTTON_WIDTH*0.2, BUTTON_WIDTH*0.2)
		button.select:SetPoint("LEFT", button, "LEFT", 0, 0)
		button.select:Hide()
		
		--[[
		button.mouseup = button:CreateTexture(nil, "OVERLAY",1)
		button.mouseup:SetTexture(1, 1, 0, 0.3)
		button.mouseup:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -2)
		button.mouseup:SetPoint("BOTTOMLEFT", button.select, "BOTTOMLEFT", 0, 2)
		button.mouseup:Hide()
		]]
		
		button.mouseup = button:CreateTexture()
		button.mouseup:SetDrawLayer("OVERLAY", 1)
		button.mouseup:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") --"Interface\\Buttons\\UI-Common-MouseHilight")
		button.mouseup:SetBlendMode("ADD")
		button.mouseup:Hide()

		button.mouseup:SetPoint("LEFT",   button.select, "LEFT",   0, 0)
		button.mouseup:SetPoint("RIGHT",  button, "RIGHT",  0, 0)
		button.mouseup:SetPoint("TOP",    button, "TOP",    0, 0)
		button.mouseup:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
		
		button.text = button:CreateFontString(nil, "OVERLAY",1)
		button.text:SetFontObject('GameFontHighlightSmall')
		button.text:SetWidth(250)
		button.text:SetHeight(12)
		button.text:SetJustifyH("LEFT")
		button.text:SetPoint("LEFT", button.select, "RIGHT",3, 0)
		button.text:SetPoint("RIGHT", button, "RIGHT", 0, 0)
		button.text:SetWordWrap(false)
		
		button.play = CreateFrame("Button", nil, button)
		button.play:SetSize(BUTTON_WIDTH*0.15, BUTTON_WIDTH*0.15)
		button.play:SetPoint("RIGHT", button.text, "RIGHT",-15, 0)
	
		button.play.tx = button.play:CreateTexture(nil, "OVERLAY",1)
		button.play.tx:SetTexture("Interface\\Common\\VoiceChat-Speaker")
		button.play.tx:SetAllPoints()
	
		button.play.txon = button.play:CreateTexture(nil, "OVERLAY",1)
		button.play.txon:SetTexture("Interface\\Common\\VoiceChat-On")
		button.play.txon:SetAllPoints()
		button.play.txon:Hide()
		
		button.play:SetScript("OnClick", function(self, ...)
			PlaySoundFile(self:GetParent().path, "Master")
		end)
		
		
		button.play:SetScript("OnEnter", function(self, ...)
			self.txon:Show()			
		end)
		button.play:SetScript("OnLeave", function(self, ...)
			self.txon:Hide()
		end)
		
		button:SetScript("OnClick", function(self, ...)
			dropdownFrame.parent._OnClick(_, self.key)
			ns:GetRealParent(dropdownFrame.parent):RefreshData()
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
	local realparent = ns:GetRealParent(f)
	dropdownFrame:SetParent(realparent)
	
	if f:GetLeft() < 170 then
		dropdownFrame:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 2, -8)
	else
		dropdownFrame:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -2, -8)
	end
	
	dropdownFrame:SetWidth( f:GetWidth() > 170 and f:GetWidth() or 170)
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
--	ns.DDFonts.HideFonts()
--	ns.DD.Hide()
	
	ns:FreeDropDowns(DD)
	
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
		DD.ShowFonts(self:GetParent(), self:GetParent()._OnShow())
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 3 , 0)
	text:SetPoint("BOTTOMRIGHT", f.arrow, "TOPRIGHT", 0 , 0)
	text:SetTextColor(1, 0.8, 0)
	text:SetJustifyH("LEFT")
	
	local value = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	value:SetPoint("LEFT", f, "LEFT", 3 , 0)
	value:SetPoint("RIGHT", f.arrow, "LEFT", 0 , 0)
	value:SetTextColor(1, 1, 1)
	value:SetJustifyH("RIGHT")
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", value, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", value, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)		
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)
	
	f.text = text
	f.value = value
	
	return f
end

function ns:CreateSoundDD()
	
	for i=1, #ns.soundFrames do
		if ns.soundFrames[i].free then
			return ns.soundFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-SoundFrame'..#ns.soundFrames+1, UIParent)
	f:SetSize(180, 45)
	f.free = true
	
	f.main = CreateCoreDropDown(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -15)
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	f.UpdateSize = UpdateSize
	
	ns.soundFrames[#ns.soundFrames+1] = f
	
	return f
end
	
ns.prototypes["sound"] = "CreateSoundDD"