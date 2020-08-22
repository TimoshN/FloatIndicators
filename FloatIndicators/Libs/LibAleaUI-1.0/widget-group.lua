if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.groupFrames = {}

local function Update(self, panel, opts, parent, datapath)
	
	self.free = false
	self:SetParent(panel)
	
	self:Show()	

	self:SetName(opts.name)	

	self:UpdateSize(panel, opts, parent, datapath)	
	
	panel.childs[self] = true
end

local function UpdateSize(self, panel, opts, parent, datapath)
	if parent then
		local step = ns.GetNumInGroups(self) - 2
		
		if step == 1 then
			self:SetWidth( parent:GetWidth()- 18 )
			self.main:SetWidth(parent:GetWidth() - 18 )
		else
			self:SetWidth( parent:GetWidth()- 10 )
			self.main:SetWidth(parent:GetWidth() - 10 )
		end
	else	
		self:SetWidth( panel:GetWidth() - 25)
		self.main:SetWidth(panel:GetWidth() - 25)
	end
	
	self:UpdateState(panel, opts.args, nil, datapath)
end

local function Remove(self)
	self.free = true
	
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

local function SetElementPosition(self)

end

local function UpdateState(self, panel, args, arg1, datapath)
	
	ns:FreeAllElements(self, 'group')
	ns:FreeAllChilds(self, 'group')
	
	local panel_width = self:GetWidth()+10
	local elements_row = floor(panel_width/180)
	local s = {}
	
	for name, data1 in pairs(args) do
		s[#s+1] = { name = name, order = data1.order }
	end
	
	ns:SortTree(s)
	
	local frames = 0
	local index = 0
	local totalheight = 23
	local currentheight = 0
	
	for i=1, #s do
		local opts = args[s[i].name]
		local prototype = opts.type
		local width = opts.width
		local height = opts.height
		local fromNewLine = opts.newLine
		
		if prototype ~= "group" then
			index = index + 1
			if not self.elements[index] then
				self.elements[index] = ns:GetPrototype(prototype)
				self.elements[index]:Update(panel, opts, self, datapath)
			end
			if self.elements[index].UpdateSize then
				self.elements[index]:UpdateSize(panel, opts, self, datapath)
			end
			self.elements[index]:ClearAllPoints()
			
			
			if frames == 0 then
				frames = frames + 1
				self.elements[index]:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -totalheight)
				
				if width == "full" then
			--		self.elements[index]:SetPoint("RIGHT", self.bg, "RIGHT", -3, 0)
					frames = elements_row
				end
				
				if currentheight < self.elements[index]:GetHeight() then
					currentheight = self.elements[index]:GetHeight()
				end	
				
				if height == "full" then				
					self.elements[index]:SetPoint("BOTTOM", self, "BOTTOM")					
				end
			else
				if width == "full" then
				
					totalheight = totalheight + currentheight
					currentheight = 0
					
					self.elements[index]:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -totalheight)
				--	self.elements[index]:SetPoint("RIGHT", self.bg, "RIGHT", -3, 0)
					if currentheight < self.elements[index]:GetHeight() then
						currentheight = self.elements[index]:GetHeight()
					end
					frames = elements_row
				elseif frames >= elements_row or fromNewLine then
				
					totalheight = totalheight + currentheight
					currentheight = 0
					
					frames = 1
					self.elements[index]:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -totalheight)
					if currentheight < self.elements[index]:GetHeight() then
						currentheight = self.elements[index]:GetHeight()
					end
				else
					frames = frames + 1
					self.elements[index]:SetPoint("TOPLEFT", self.elements[index-1], "TOPRIGHT")
					if currentheight < self.elements[index]:GetHeight() then
						currentheight = self.elements[index]:GetHeight()
					end
				end
				
				if height == "full" then
					
					self.elements[index]:SetPoint("BOTTOM", self, "BOTTOM")
					
				end
			end
		elseif prototype == "group" and opts.embend == true then
			index = index + 1		
			if not self.elements[index] then
				self.elements[index] = ns:GetPrototype(prototype)
				self.elements[index]:Update(panel, opts, self, datapath)
			end
			if self.elements[index].UpdateSize then
				self.elements[index]:UpdateSize(panel, opts, self, datapath)
			end
			self.elements[index]:ClearAllPoints()
		
			if frames == 0 then
				frames = elements_row
				self.elements[index]:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -totalheight)			
				if currentheight < self.elements[index]:GetHeight() then
					currentheight = self.elements[index]:GetHeight()
				end
			else
				totalheight = totalheight + currentheight
				currentheight = 0
					
				self.elements[index]:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -totalheight)
				if currentheight < self.elements[index]:GetHeight() then
					currentheight = self.elements[index]:GetHeight()
				end
				frames = elements_row
			end
			
		end
	end
	totalheight = totalheight + currentheight
	
	self:SetHeight(totalheight+10)
end

function ns:CreateGroup()
	
	for i=1, #ns.groupFrames do
		if ns.groupFrames[i].free then
			return ns.groupFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-GroupFrame'..#ns.groupFrames+1, UIParent)
	f:SetSize(200, 200)
	f.free = true
	f.elements = {}
	f.childs = {}
	
	f.main = CreateFrame("Frame", nil, f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -15)
	f.main:SetSize(200, 185)
	
	local bg = CreateFrame("Frame", nil, f) --f:CreateTexture(nil)
--	bg:EnableMouse(false)
--	bg:SetBackdrop({
--		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
--		edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=], 
--		edgeSize = 1,
--		insets = {top = 0, left = 0, bottom = 0, right = 0},
--		})
--	bg:SetBackdropColor(0, 0, 0, 0.4) --���� ����
--	bg:SetBackdropBorderColor(unpack(ns.button_border_color_ondown)) --���� �����
	
	bg:SetPoint("TOPLEFT", f.main, "TOPLEFT", 0, -5)
	bg:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
	bg:SetPoint("RIGHT", f.main, "RIGHT", 0, 0)
		
	local bg_border = CreateFrame("Frame", nil, f, BackdropTemplateMixin and 'BackdropTemplate')
	bg_border:SetFrameLevel(f:GetFrameLevel()+1)
	bg_border:SetPoint("TOPLEFT", f, "TOPLEFT", -0,-16)
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
	text:SetPoint("BOTTOMLEFT", f.main, "TOPLEFT", 3 , -2)
--	text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	text:SetText("TEST")
	text:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	
	f.main.text = text
	
--	bg:SetTexture(0.5, 1, 0.5, 0.5)	
	f.bg = bg
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.GetDim = GetDim
	f.SetElementPosition = SetElementPosition
	f.UpdateSize = UpdateSize
	
	ns.groupFrames[#ns.groupFrames+1] = f
	
	return f
end
	
ns.prototypes["group"] = "CreateGroup"