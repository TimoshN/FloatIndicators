if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.tabgroupFrames = {}

local dim_frame_st = -30

local function UpdateWidth(self)
	return function(panel, width, height)
	
		self:SetWidth(width)
		self.main:SetWidth(width)
		
		self.bg:SetPoint("RIGHT", self:GetParent():GetParent():GetParent():GetParent(), "RIGHT", dim_frame_st-self:GetDim(), 0)
		
	--	self:UpdateTabSize()
	end
end

local function Update(self, panel, opts, parent, datapath)
	
	self.free = false
	self:SetParent(panel)
	
	if self.lastdatapath ~= datapath then
		self.selectedTab = nil
		self.selectedTabIndex = nil
	end
	self.lastdatapath = datapath

	self:Show()	
	
	self.args = opts.args
	
	self:SetName(opts.name)	
	self:UpdateState(panel, opts.args, nil, datapath)
	self:UpdateSize(panel, opts, nil, datapath)	
	
	panel.childs[self] = true
end

local function UpdateSize(self, panel, opts, parent, datapath)	
	if parent then
		self:SetWidth( parent:GetWidth()- 25)
		self.main:SetWidth(parent:GetWidth() - 25)
	else	
		self:SetWidth( panel:GetWidth() - 25)
		self.main:SetWidth(panel:GetWidth() - 25)
	end
	
	self:UpdateTabPanelSize(self, panel, args, nil, datapath)
end

local function Remove(self)
	self.free = true
	self.args = nil
	
	ns:FreeAllElements(self)
	ns:FreeAllChilds(self)
	
	self:Hide()
	self:ClearAllPoints()
end

local function SetName(self, name)
	self.main.text:SetText(name)
end

local function GetDim(self)
	local a4 = self:GetParent():GetParent():GetParent():GetParent().rightSide
	if self.main:GetLeft() and a4:GetLeft() then
		if self.main:GetLeft() - a4:GetLeft() > 50 then
			return 50
		end
		return self.main:GetLeft() - a4:GetLeft()
	end
	return 0
end

local function UpdateTabPanelSize(self, panel, largs, arg1, datapath)
	
	local args = self.args
	local panel_width = self:GetWidth()
	local elements_row = floor(panel_width/180)
	local s = {}
	
	for name, data1 in pairs(args) do
		if data1.type == 'group' then
			s[#s+1] = { name = name, realName = data1.name, order = data1.order }
		end
	end
	
	ns:SortTree(s)
	
	if self.selectedTab then
		for i=1, #s do
			if s[i].name == self.selectedTab then
				self.selectedTabIndex = i
				break
			end
		end
		
		if not self.selectedTabIndex then
			for i=1, #s do
				self.selectedTab = s[i].name
				break
			end
			self.selectedTabIndex = 1
		end
	else
		for i=1, #s do
			self.selectedTab = s[i].name
			break
		end
		self.selectedTabIndex = 1
	end
	
	local frames = 0
	local index = 0
	local totalheight = 20
	local currentheight = 0
	
	self:ResetTabs()
	
	self.tabList = s
	self.tabWidth = self:SetTabs()
	self:SetSelected(self.selectedTabIndex)
	
	if self.selectedTabIndex and s[self.selectedTabIndex] then
		local opts = args[s[self.selectedTabIndex].name]
		local prototype = opts.type
		local width = opts.width
		local height = opts.height
	
		if prototype == "group" then
			index = index + 1
			if not self.elements[index] then
				self.elements[index] = ns:GetPrototype(prototype)
				self.elements[index]:Update(panel, opts, self)
			end
			if self.elements[index].UpdateSize then
				self.elements[index]:UpdateSize(panel, opts, self)
			end
			self.elements[index]:ClearAllPoints()
			
			if frames == 0 then
				frames = elements_row
				self.elements[index]:SetPoint("TOPLEFT", self.main, "TOPLEFT", 2, -totalheight+10)			
				if currentheight < self.elements[index]:GetHeight() then
					currentheight = self.elements[index]:GetHeight()
				end
			else
				totalheight = totalheight + currentheight
				currentheight = 0
					
				self.elements[index]:SetPoint("TOPLEFT", self.main, "TOPLEFT", 2, -totalheight+10)
				if currentheight < self.elements[index]:GetHeight() then
					currentheight = self.elements[index]:GetHeight()
				end
				frames = elements_row
			end
			
		end
	end
	totalheight = totalheight + currentheight
	
	self.totalheight = totalheight
	self.main:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -10-self.tabWidth)	
	self:SetHeight(self.totalheight+10+self.tabWidth)
end

local function UpdateState(self, panel, args, arg1, datapath)
	
	ns:FreeAllElements(self)
	ns:FreeAllChilds(self)
	
	self:UpdateTabPanelSize(panel, args, nil, datapath)
end

local function AddTab(self, name)
	local tab = nil
	
	for i=1, #self.tabs do
		if self.tabs[i].free then
			tab = self.tabs[i]
			break
		end
	end
	
	if not tab then
		tab = CreateFrame('Button', nil,  self.main)
		tab:SetSize(80, 20)
		tab:SetScript('OnClick', function(me)
			if tab.selected then return end
			self.selectedTab = me.arg
			ns:GetRealParent(self):RefreshData()
			PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB or "igCharacterInfoTab");
		end)
		tab.free = true
		tab.index = #self.tabs+1
		
		tab.texture = tab:CreateTexture()
		tab.texture:SetDrawLayer('ARTWORK', 0)
		tab.texture:SetPoint('TOPLEFT', tab, 'TOPLEFT', 3, -3)
		tab.texture:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', -3, 3)
		tab.texture:SetColorTexture(0, 0, 0, 0)
		
		tab.Left = tab:CreateTexture()
		tab.Left:SetDrawLayer('ARTWORK', 1)
		tab.Left:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-InActiveTab]])
		tab.Left:SetSize(20,24)
		tab.Left:SetTexCoord(0, 0.15625, 0, 1)
		tab.Left:SetPoint('TOPLEFT', tab, -5, 6)
		
		tab.Right = tab:CreateTexture()
		tab.Right:SetDrawLayer('ARTWORK', 1)
		tab.Right:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-InActiveTab]])
		tab.Right:SetSize(20,24)
		tab.Right:SetTexCoord(0.84375, 1, 0, 1)
		tab.Right:SetPoint('TOPRIGHT', tab, 5, 6)
		
		tab.Middle = tab:CreateTexture()
		tab.Middle:SetDrawLayer('ARTWORK', 1)
		tab.Middle:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-InActiveTab]])
		tab.Middle:SetSize(88,24)
		tab.Middle:SetTexCoord(0.15625, 0.84375, 0, 1)
		tab.Middle:SetPoint('LEFT', tab.Left, 'RIGHT', 0, 0)
		tab.Middle:SetPoint('RIGHT', tab.Right, 'LEFT', 0, 0)
				
		tab.LeftDisabled = tab:CreateTexture()
		tab.LeftDisabled:SetDrawLayer('ARTWORK', 1)
		tab.LeftDisabled:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-ActiveTab]])
		tab.LeftDisabled:SetSize(20,24)
		tab.LeftDisabled:SetTexCoord(0, 0.15625, 0, 1)
		tab.LeftDisabled:SetPoint('TOPLEFT', tab, -5, 3)
		
		tab.RightDisabled = tab:CreateTexture()
		tab.RightDisabled:SetDrawLayer('ARTWORK', 1)
		tab.RightDisabled:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-ActiveTab]])
		tab.RightDisabled:SetSize(20,24)
		tab.RightDisabled:SetTexCoord(0.84375, 1, 0, 1)
		tab.RightDisabled:SetPoint('TOPRIGHT', tab, 5, 3)
		
		tab.MiddleDisabled = tab:CreateTexture()
		tab.MiddleDisabled:SetDrawLayer('ARTWORK', 1)
		tab.MiddleDisabled:SetTexture([[Interface\OptionsFrame\UI-OptionsFrame-ActiveTab]])
		tab.MiddleDisabled:SetSize(88,24)
		tab.MiddleDisabled:SetTexCoord(0.15625, 0.84375, 0, 1)
		tab.MiddleDisabled:SetPoint('LEFT', tab.LeftDisabled, 'RIGHT', 0, 0)
		tab.MiddleDisabled:SetPoint('RIGHT', tab.RightDisabled, 'LEFT', 0, 0)

		tab.Highlight = tab:CreateTexture()
		tab.Highlight:SetDrawLayer('ARTWORK', 1)
		tab.Highlight:SetSize(88,24)
		tab.Highlight:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-Tab-Highlight]])
		tab.Highlight:SetPoint('LEFT', tab, 10, -2)
		tab.Highlight:SetPoint('RIGHT', tab, -10, -2)
		tab.Highlight:Hide()
		tab.Highlight:SetBlendMode('ADD')
		
		tab:SetScript('OnEnter', function()
			if tab.selected then return end
			tab.Highlight:Show()
		end)
		tab:SetScript('OnLeave', function()
			tab.Highlight:Hide()
		end)
		
		local text = tab:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
		text:SetPoint("CENTER", tab, 'CENTER', 0, 0)
	--	text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		text:SetText("TEST")
		text:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
		text:SetJustifyH("CENTER")
		text:SetWordWrap(false)
		text:Show()
	
		tab.text = text
		
		self.tabs[tab.index] = tab
	end

	tab.arg = name
	tab.text:SetText(name)
	tab.free = false
	tab:Show()

	return tab
end

local function UpdateTabSize(self)
	self:ResetTabs()
	self.tabWidth = self:SetTabs()
	self.main:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -10-self.tabWidth)	
	self:SetHeight(self.totalheight+10+self.tabWidth)
	self:SetSelected(self.selectedTabIndex)
end

local function ResetTabs(self)
	for i=1, #self.tabs do
		self.tabs[i].free = true
		self.tabs[i]:Hide()
	end
end

local function SetSelected(self, index)
	for i=1, #self.tabs do	
		local tab = self.tabs[i]
		if i==index then
			tab.MiddleDisabled:Show()
			tab.LeftDisabled:Show()
			tab.RightDisabled:Show()
			
			tab.Middle:Hide()
			tab.Left:Hide()
			tab.Right:Hide()
			
			tab.text:SetTextColor(1,1,1,1)
			
			tab.selected = true
			tab.Highlight:Hide()
		else
			tab.MiddleDisabled:Hide()
			tab.LeftDisabled:Hide()
			tab.RightDisabled:Hide()
			
			tab.Middle:Show()
			tab.Left:Show()
			tab.Right:Show()
			
			tab.text:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
			
			tab.selected = false
			tab.Highlight:Hide()
		end
	end
end

local StringWidth = CreateFrame('Frame', nil, UIParent):CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
	StringWidth:SetPoint("CENTER")
	StringWidth:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
	StringWidth:SetJustifyH("LEFT")
	StringWidth:SetWordWrap(false)
	StringWidth:Show()

local function SetTabs(self, args)

	local t = {}
	
	local width1 = 0
	
	local width = self:GetWidth()-10
	local numElements = 0
	local row = 1
	local rowWidth = 0
	for i=1, #self.tabList do	
		numElements = numElements + 1
		StringWidth:Show()
		StringWidth:SetWidth(0)
		StringWidth:SetText(self.tabList[i].realName)
	
		local stringWidth = StringWidth:GetStringWidth()		
		local stringCompleteWidth = math.max(30, math.min(stringWidth, 180))+25
	
		if ( rowWidth + stringCompleteWidth ) > width then
			row = row + 1
			numElements = 1
			rowWidth = 0
		end
		
		StringWidth:Hide()
		
		rowWidth = rowWidth + stringCompleteWidth
		t[row] = t[row] or {}
		t[row][numElements] = self:AddTab(self.tabList[i].name)
		t[row][numElements].text:SetText(self.tabList[i].realName)
		t[row][numElements].text:SetWidth(stringCompleteWidth-15)
		t[row][numElements]:SetWidth(stringCompleteWidth)
	end	
	
	
	local numRows = #t
	
	for row in pairs(t) do
		width1 = width1 + 20
		
		-- Calculate total row width
		local totalRowWidth = 0
		for index, tab in pairs(t[row]) do		
			totalRowWidth = totalRowWidth + tab:GetWidth()
		end
		
		-- Calculate left width 
		local widthLeft = width - totalRowWidth
		
		-- Spread width with elements
		local widthLeftPerElement = widthLeft > 0 and widthLeft/#t[row] or 0
		
		local rowWidth = 0
		for index, tab in pairs(t[row]) do
			tab:SetPoint('BOTTOMLEFT', self.main, 'TOPLEFT', rowWidth, 20*(numRows-row))
			local rowTabWidth = tab:GetWidth()+widthLeftPerElement
			rowWidth = rowWidth + rowTabWidth
			tab:SetWidth(rowTabWidth)
		end
	end
	
	return width1
end

function ns:CreateTabGroup()
	
	for i=1, #ns.tabgroupFrames do
		if ns.tabgroupFrames[i].free then
			return ns.tabgroupFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-TabGroupFrame'..#ns.tabgroupFrames+1, UIParent)
	f:SetSize(200, 200)
	f.free = true
	f.elements = {}
	f.childs = {}
	f.tabs = {}
	
	f.main = CreateFrame("Frame", nil, f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5)
	f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 5)
	f.main:SetSize(200, 185)
	--[==[
	f.texture = f:CreateTexture()
	f.texture:SetAllPoints()
	f.texture:SetColorTexture(0.6, 0.6, 0, 1)
	
	f.main.texture = f.main:CreateTexture()
	f.main.texture:SetAllPoints()
	f.main.texture:SetColorTexture(0, 0.6, 0, 1)
		]==]
	local bg = CreateFrame("Frame", nil, f)
	bg:SetPoint("TOPLEFT", f.main, "TOPLEFT", 0, -5)
	bg:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
	bg:SetPoint("RIGHT", f.main, "RIGHT", 5, 0)
	
	local bg_border = CreateFrame("Frame", nil, f, BackdropTemplateMixin and 'BackdropTemplate')
	bg_border:SetFrameLevel(f:GetFrameLevel()+1)
	bg_border:SetPoint("TOPLEFT", f.main, "TOPLEFT", -5, 2)
	bg_border:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 3)
	bg_border:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8x8]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		edgeSize = 16,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5,
		}
	})
	bg_border:SetBackdropColor(0, 0, 0, 0.3)
	bg_border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	
	local text = bg:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
	text:SetPoint("BOTTOMLEFT", f.main, "TOPLEFT", 3 , -1)
--	text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	text:SetText("TEST")
	text:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	text:Hide()
	
	f.main.text = text
	
--	bg:SetTexture(0.5, 1, 0.5, 0.5)	
	f.bg = bg
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.UpdateWidth = UpdateWidth
	f.GetDim = GetDim
	f.AddTab = AddTab
	f.ResetTabs = ResetTabs
	f.SetTabs = SetTabs
	f.SetSelected = SetSelected
	f.UpdateTabSize = UpdateTabSize
	f.UpdateSize = UpdateSize
	f.UpdateTabPanelSize = UpdateTabPanelSize
	
	ns.tabgroupFrames[#ns.tabgroupFrames+1] = f
	
	return f
end
	
ns.prototypes["tabgroup"] = "CreateTabGroup"