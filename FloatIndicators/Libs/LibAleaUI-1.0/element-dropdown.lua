if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.DD = {}

local DD = ns.DD

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
	
	--	print("T", x,y, tostring(list_data[x]), tostring(list_data[y]))
	--	return tostring(list_data[x]) < tostring(list_data[y])
		if type(x) == type(y) then
			return x < y
		else
			return false
		end
	end)
	
	LIST_NUM_VALUES = i
end


function DD.update(self, checkedkey)
	local numItems = #list
	local offset = 0
	
	if checkedkey then
		self.checkedkey = checkedkey
	end
	
	if numItems < NUM_BUTTONS then
	--	FauxScrollFrame_Update(self, NUM_BUTTONS, NUM_BUTTONS, BUTTON_HEIGHT)
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
			button:Hide()
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
			button.border = self.border and name or nil
			button.statusbar = self.statusbar and name or nil
			button.showSpellTooltip = self.showSpellTooltip
			
			button._name = name
			
			if button.key == self.checkedkey then			
				button.select:Show()
			else
				button.select:Hide()
			end
			
			if button.border or button.statusbar then
				button.text:SetText(key)
			else
				button.text:SetText(name)
			end
			
			if button.statusbar then
				button.statusbar_tx:SetTexture(button.statusbar)
				button.statusbar_tx:SetVertexColor(0.7, 0.7, 0.7, 1)
				button.statusbar_tx:Show()
			else
				button.statusbar_tx:Hide()
			end
			
			button.desc = desc
			button:Show()
			
			DD.dropdown:SetHeight(BUTTON_HEIGHT*line)
		end
	end
end


DD.dropdown = CreateFrame("Frame")
DD.dropdown:SetSize(300, 200)
DD.dropdown.bg = DD.dropdown:CreateTexture()
DD.dropdown.bg:SetAllPoints()
DD.dropdown.bg:SetColorTexture(0, 0,0, 0.8)
DD.dropdown:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
DD.dropdown.Update = function(self)end
DD.dropdown:SetClampedToScreen(true)
DD.dropdown.border1 = CreateFrame("Frame", nil, DD.dropdown, BackdropTemplateMixin and 'BackdropTemplate')
DD.dropdown.border1:SetPoint("TOPLEFT", DD.dropdown, "TOPLEFT", -10, 10)
DD.dropdown.border1:SetPoint("BOTTOMRIGHT", DD.dropdown, "BOTTOMRIGHT", 10, -10)
DD.dropdown.border1:SetBackdrop({
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
DD.dropdown.border1:SetBackdropColor(0, 0, 0, 0.8)
DD.dropdown.border1:SetBackdropBorderColor(1, 1, 1, 1)
	
DD.dropdown.border = CreateFrame("Frame", nil, DD.dropdown, BackdropTemplateMixin and 'BackdropTemplate')
DD.dropdown.border:SetPoint("TOPLEFT", DD.dropdown, "TOPLEFT", -10, 10)
DD.dropdown.border:SetPoint("BOTTOMRIGHT", DD.dropdown, "BOTTOMRIGHT", 10, -10)
DD.dropdown.updateBorder = function(self, texture)
	self.border:SetBackdrop({
		edgeFile = texture, 
		edgeSize = 20,
	})
	self.border1:SetBackdropBorderColor(1, 1, 1, 0) --цвет краев
	self.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1) --цвет краев
end

DD.dropdown.HideBorder = function(self)
	self.border1:SetBackdropBorderColor(1, 1, 1, 1) --цвет краев
	self.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0) --цвет краев
end

local spacing = -5
DD.scrollFrame = CreateFrame("ScrollFrame", "AleaUIGUINormalScrollingFrame"..ns:GetNumFrames(), DD.dropdown, "FauxScrollFrameTemplate")
DD.scrollFrame:SetWidth(BUTTON_WIDTH)
DD.scrollFrame:SetFrameLevel(DD.dropdown:GetFrameLevel()+1)
DD.scrollFrame:SetPoint("TOPRIGHT",DD.dropdown, "TOPRIGHT", -spacing, 0)
DD.scrollFrame:SetPoint("TOPLEFT",DD.dropdown, "TOPLEFT", -spacing, 0)
DD.scrollFrame:EnableMouse(true)
DD.scrollFrame:SetMovable(true)
DD.scrollFrame:SetVerticalScroll(0)
DD.scrollFrame:RegisterForDrag("LeftButton")
DD.scrollFrame:Show()
DD.scrollFrame.scroll = 0
DD.scrollFrame:SetClampedToScreen(true)
DD.scrollFrame:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
DD.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
	self.scroll = offset
	FauxScrollFrame_OnVerticalScroll(self, offset, BUTTON_HEIGHT, DD.update)
end)


DD.scrollFrame.ScrollBar:GetThumbTexture():SetDrawLayer("OVERLAY", 1)
DD.scrollFrame.ScrollBar:SetFrameLevel(DD.scrollFrame:GetFrameLevel()+2)
DD.scrollFrame.ScrollBar.bg = DD.scrollFrame.ScrollBar:CreateTexture(nil, "OVERLAY")
DD.scrollFrame.ScrollBar.bg:SetAllPoints()
DD.scrollFrame.ScrollBar.bg:SetColorTexture(0, 0, 0, 0.6)
DD.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
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
		local button = CreateFrame("Button", nil, DD.dropdown)
		button:SetFrameLevel(DD.scrollFrame:GetFrameLevel()+1)
		if i == 1 then
			button:SetPoint("TOPLEFT", DD.dropdown, "TOPLEFT", 0, 0) --    -BUTTON_WIDTH*0.3+3, 0)
			button:SetPoint("TOPRIGHT", DD.dropdown, "TOPRIGHT", 0, 0) --   -BUTTON_WIDTH*0.3+3, 0)
		else
			button:SetPoint("TOPRIGHT", buttons[i - 1], "BOTTOMRIGHT")
			button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT")
		end
		button:SetNormalFontObject("GameFontNormal")
		
		button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
		
		button.select = button:CreateTexture(nil, "BACKGROUND",1)
		button.select:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button.select:SetSize(BUTTON_WIDTH*0.2, BUTTON_WIDTH*0.2)
		button.select:SetPoint("LEFT", button, "LEFT", 0, 0)
		button.select:Hide()
		
		button.statusbar_tx = button:CreateTexture(nil, "ARTWORK", -1)
		button.statusbar_tx:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button.statusbar_tx:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -2)
		button.statusbar_tx:SetPoint("BOTTOMLEFT", button.select, "BOTTOMLEFT", 0, 2)
		button.statusbar_tx:Hide()
		--[==[
		button.mouseup = button:CreateTexture(nil, "OVERLAY",1)
		button.mouseup:SetTexture(1, 1, 0, 0.3)
		button.mouseup:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -2)
		button.mouseup:SetPoint("BOTTOMLEFT", button.select, "BOTTOMLEFT", 0, 2)
		button.mouseup:Hide()
		]==]
		
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
	--	button.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
		button.text:SetFontObject('GameFontHighlightSmall')
		button.text:SetWordWrap(false)
	-- , "GameFontHighlight"
	
		button.text:SetWidth(250)
		button.text:SetHeight(10)
		button.text:SetJustifyH("LEFT")
		button.text:SetPoint("LEFT",button.select,"RIGHT", 0,0)
		button.text:SetPoint("RIGHT",button,"RIGHT",-3,0)
		
		button:SetScript("OnClick", function(self, ...)
		--	print('T1', DD.dropdown.parent)
			
			DD.dropdown.parent._OnClick(_, self.key)
			
		--	print('T1', DD.dropdown.parent)
			
			if DD.dropdown.parent then
				ns:GetRealParent(DD.dropdown.parent):RefreshData()	
			end
		end)
		
		button:SetScript("OnEnter", function(self, ...)
			self.mouseup:Show()		
	
			if self.showSpellTooltip and self.key and tonumber(self.key) and GetSpellInfo(self.key) then
				ns.Tooltip(DD.dropdown.parent, self._name, self.desc, "show", "spell:"..self.key, string.match(self._name,"|T(.-):"))
			elseif self.showSpellTooltip then
				local mtch = string.match(self._name, "#(%d+)")
				
				if mtch and tonumber(mtch) and GetSpellInfo(tonumber(mtch)) then
					ns.Tooltip(DD.dropdown.parent, self._name, self.desc, "show", "spell:"..tonumber(mtch), string.match(self._name,"|T(.-):"))
				end
			elseif not self.border and not self.statusbar then
				ns.Tooltip(DD.dropdown.parent, self._name, self.desc, "show")
			end

			if self.border then
				DD.dropdown:updateBorder(self.border)
			else
				DD.dropdown:HideBorder()
			end
		end)
		button:SetScript("OnLeave", function(self, ...)
			self.mouseup:Hide()
			
			ns.Tooltip(DD.dropdown, self._name, self.desc, "hide")
			
			if self.border then
				DD.dropdown:updateBorder(self.border)
			else
				DD.dropdown:HideBorder()
			end
		end)
		
		buttons[i] = button
	end
end

local function UpdateDD(f,key)
	DD.buildList(f.values)
	DD.scrollFrame.checkedkey = key
	DD.scrollFrame.border = (f and f.border )
	DD.scrollFrame.statusbar = (f and f.statusbar )
	DD.scrollFrame.showSpellTooltip = f.showSpellTooltip
	DD.scrollFrame:SetVerticalScroll(0)
	DD.scrollFrame.scroll = 0
	DD.update(DD.scrollFrame, key)
	
	if #list <= NUM_BUTTONS then
		DD.scrollFrame:Hide()
	else
		DD.scrollFrame:Show()
	end
	
	if DD.dropdown.parent then
		DD.dropdown.parent.arrow.text:SetText(statearrow[2])
	end
	local realparent = ns:GetRealParent(f)
	DD.dropdown:SetParent(realparent)
	
	DD.dropdown:ClearAllPoints()
	
	if f:GetLeft() < 170 then
		DD.dropdown:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 2, -8)
	else
		DD.dropdown:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -2, -8)
	end
	
	DD.dropdown:SetWidth( f:GetWidth() > 170 and f:GetWidth() or 170)
	
	DD.dropdown:SetFrameLevel(realparent:GetFrameLevel()+10)
	DD.dropdown:Update()
	DD.dropdown:Show()
	DD.dropdown.parent = f
	DD.dropdown:HideBorder()
	DD.dropdown.parent.arrow.text:SetText(statearrow[1])
end

function DD.Hide()
	
	if DD.dropdown:IsShown() then
		DD.dropdown:Hide()
		if DD.dropdown.parent then
			DD.dropdown.parent.arrow.text:SetText(statearrow[2])
		end
		DD.dropdown.parent = nil
		DD.scrollFrame.checkedkey = nil
		DD.scrollFrame.border = nil
		DD.scrollFrame.statusbar = nil
	end
end

function DD.Show(f,key)
	
	ns:FreeDropDowns(DD)
	
--	ns.DDFonts.HideFonts()
--	ns.DDSounds.HideFonts()

	if DD.dropdown.parent and DD.dropdown.parent ~= f then
		UpdateDD(f,key)
	elseif DD.dropdown.parent then
		DD.dropdown:Hide()
		if DD.dropdown.parent then
			DD.dropdown.parent.arrow.text:SetText(statearrow[2])
		end
		DD.dropdown.parent = nil
		DD.scrollFrame.checkedkey = nil
		DD.scrollFrame.border = nil
		DD.scrollFrame.statusbar = nil
	else
		UpdateDD(f,key)
	end
end