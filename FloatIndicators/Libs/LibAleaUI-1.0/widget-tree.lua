if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.treeGroupFrames = {}
ns.treeGroupFramesElements = {}

local string_height = 16

local function PrintSubElements(self, datas, maintree)

	if datas.subelement then
		ns:SortTree(datas.subelement)
		for i, data in pairs(datas.subelement) do
			if data.show then
				self.id = self.id + 1
				ns:GetTreeGroupElement(self, maintree..";"..data.name):UpdatePoint(self, data.realname, self.id, data.hidden and 0 or ( data.subelement and #data.subelement or 0), data.toggle)
				PrintSubElements(self, data, maintree..";"..data.name)
			end
		end
	end
end
	
function ns:GetTreeGroupElement(parent, main)
	for i=1, #self.treeGroupFramesElements do		
		if self.treeGroupFramesElements[i].free then
			self.treeGroupFramesElements[i].main = main	
			return self.treeGroupFramesElements[i]
		end
	end
	
	local f = CreateFrame("Button", 'AleaUIGUI-TreeElement'..#ns.treeGroupFramesElements+1, parent.buttonParent)
	f:SetSize(200, string_height)	
	f:SetParent(parent.buttonParent)
	f:Show()
	
	f.main = main
	
	f:SetScript("OnClick", function(self)
		self:GetParent():GetParent():GetParent():GetParent().datapath = self.main	
		
	--	print("T", self.main)
		ns.openedmainFrames[self:GetParent():GetParent():GetParent():GetParent().addon]:Update(self:GetParent():GetParent():GetParent():GetParent().addon)
		
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
	end)

	f.exp = CreateFrame("Button", nil, f)
	f.exp:SetSize(16, 16)
	f.exp:SetParent(f)
	f.exp:SetPoint("RIGHT")
	f.exp:SetScript("OnClick", function(self, ...)
		local datas = nil
		--[[
		print("T1", self:GetParent().addon)
		print("T2", self:GetParent():GetParent().addon)
		print("T3", self:GetParent():GetParent():GetParent().addon)
		print("T4", self:GetParent():GetParent():GetParent():GetParent().addon)
		print("T5", self:GetParent():GetParent():GetParent():GetParent():GetParent().addon)
		]]
		
		for i=1, select("#", strsplit(";", self:GetParent().main)) do
			local arg = select(i, strsplit(";", self:GetParent().main))
			datas = datas or ns.RegisteredAddons[self:GetParent():GetParent():GetParent():GetParent():GetParent().addon]
			
			datas = datas.args[arg]
		end
	
		datas = datas or ns.RegisteredAddons[self:GetParent():GetParent():GetParent():GetParent():GetParent().addon].args[self:GetParent():GetParent():GetParent().main]
			
		if datas._expand == nil and datas.expand == true then
			datas._expand = false
		else
			datas._expand = not datas._expand
		end
			
		ns.openedmainFrames[self:GetParent():GetParent():GetParent():GetParent():GetParent().addon]:Update(self:GetParent():GetParent():GetParent():GetParent():GetParent().addon)
	end)
	
	local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetJustifyH("LEFT")
	text:SetText("TEST")
	text:SetPoint("LEFT", f, "LEFT", 3, 0)
	text:SetPoint("RIGHT", f.exp, "LEFT")
	text:SetWordWrap(false)
	
	f.mouseup = f:CreateTexture()
	f.mouseup:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	f.mouseup:SetBlendMode("ADD")
	f.mouseup:SetPoint("LEFT", parent.buttonParent, "LEFT", -50, 0)
	f.mouseup:SetTexCoord(0,1,0.35,0.65)
	f.mouseup:SetPoint("RIGHT", f, "RIGHT", 50, 0)
	f.mouseup:SetPoint("TOP", f, "TOP", 0, 0)
	f.mouseup:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
	f.mouseup:Hide()
	f.mouseup:SetVertexColor(1,1, 1, 0.5)
	f:SetScript("OnEnter", function(self, ...)
		if self.changetextcolor then
			self.text:SetTextColor(ns.fontOnMouse[1],ns.fontOnMouse[2],ns.fontOnMouse[3],ns.fontOnMouse[4])
		end

		self.mouseup:Show()
		
		if self.choosen then
		--	self.mouseup:SetVertexColor(1, 1, 0, 0.7)
			self.text:SetTextColor(ns.fontOnMouse[1],ns.fontOnMouse[2],ns.fontOnMouse[3],ns.fontOnMouse[4])
		else
		--	self.mouseup:SetVertexColor(0.5,0.8, 1, 0.7)
		end
	end)
	
	f:SetScript("OnMouseUp", function(self)	
		self.text:SetPoint("LEFT", f, "LEFT", 3, 0)
	end)
	f:SetScript("OnMouseDown", function(self)
		self.text:SetPoint("LEFT", f, "LEFT", 4, -1)
	end)
	
	f:SetScript("OnLeave", function(self, ...)
		if self.changetextcolor then
			self.text:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
		end
		
		if self.choosen then
			self.mouseup:Show()
		--	self.mouseup:SetVertexColor(1, 1, 0, 0.7)
			self.text:SetTextColor(ns.fontOnMouse[1],ns.fontOnMouse[2],ns.fontOnMouse[3],ns.fontOnMouse[4])
		else
			self.mouseup:Hide()
		end
	end)
		
	f.text = text
	f.Remove = function(self)
		self:Hide()
		self.main = nil
		self.free = true
	end
	f.UpdatePoint = function(self, parent, text, id, amountsub, shown)
		
		self.free = false
		self:Show()
			
		self:ClearAllPoints()
		self:SetParent(parent.buttonParent)
		
		parent.elements[#parent.elements+1] = self
		
		local step = 0
		
		local substep = select("#", strsplit(";", self.main))-1

		if substep then
			step = 10*substep
		end
		
		if amountsub > 0 then
			if shown then
			--	self.exp.text:SetText("-")
			--	self.exp.bg:SetTexture(0, 1, 0, 1)
				self.exp:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
				self.exp:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
			else
			--	self.exp.text:SetText("+")
			--	self.exp.bg:SetTexture(1, 0, 0, 1)
			
				self.exp:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
				self.exp:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
			end
			self.exp:Show()
		else
			self.exp:Hide()
		end
	
		if step == 0 then self.changetextcolor = true end
		
		self:SetPoint("TOPLEFT", parent.buttonParent, "TOPLEFT", step, (-5) + (-string_height*(id-1)))
		self:SetPoint("RIGHT", parent, "RIGHT")
		
		self.text:SetText(text)
		
		if substep == 0 then
			self.text:SetFontObject('GameFontNormal')
			self.text:SetTextColor(ns.fontNormal[1],ns.fontNormal[2],ns.fontNormal[3],ns.fontNormal[4])
		else
			self.text:SetFontObject('GameFontNormalSmall')
			self.text:SetTextColor(ns.fontOnMouse[1],ns.fontOnMouse[2],ns.fontOnMouse[3],ns.fontOnMouse[4])
			self.changetextcolor = nil
		end
		
		self.choosen = false
		self.mouseup:Hide()
	
		if self:GetParent():GetParent():GetParent():GetParent().datapath == self.main then	
			self.choosen = true
			self.mouseup:Show()
			self.text:SetTextColor(ns.fontOnMouse[1],ns.fontOnMouse[2],ns.fontOnMouse[3],ns.fontOnMouse[4])
		--	self.mouseup:SetVertexColor(1, 1, 0, 0.7)
		end
	end
	
	self.treeGroupFramesElements[#self.treeGroupFramesElements+1] = f
	return f
end
	
function ns:GetTreeGroupFramesFrame(parent)
	for i=1, #self.treeGroupFrames do		
		if self.treeGroupFrames[i].free then
			self.treeGroupFrames[i]:SetParent(parent)
			parent.tree = self.treeGroupFrames[i]
			return parent.tree
		end
	end
	
	local f = CreateFrame("ScrollFrame", 'AleaUIGUI-TreeGroupFrame'..#self.treeGroupFrames+1, parent.leftSide)
	f:SetFrameLevel(parent.leftSide:GetFrameLevel() + 1)
	f:SetSize(1, 1)
	f:SetPoint("TOPRIGHT", parent.leftSide, "TOPRIGHT", -20, 0)
	f:SetPoint("BOTTOMLEFT", parent.leftSide, "BOTTOMLEFT", 0, 0)
	
	f.elements = {}	
	f.free = true
	f.protoType = "treeGroupFrames"
	
	f.buttonParent = CreateFrame("Frame", nil, f)
	f.buttonParent:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	f.buttonParent:SetWidth(200)
	f.buttonParent:SetHeight(800)
	f.buttonParent:SetFrameLevel(f:GetFrameLevel() + 1)
	
	f:SetSize(1, 1)
	f:SetPoint("TOPRIGHT", parent.leftSide, "TOPRIGHT", -20, 0)
	f:SetPoint("BOTTOMLEFT", parent.leftSide, "BOTTOMLEFT", 0, 0)
	f:SetScrollChild(f.buttonParent)
	f:SetHorizontalScroll(0)
	f:SetVerticalScroll(0)
	f:EnableMouse(true)
	f:SetScript("OnMouseWheel", function(self, delta)
		self.scroll:SetValue(self.scroll:GetValue()-( 30 * delta))	
		self:SetVerticalScroll(self.scroll:GetValue())	
	end)
	
	local scrollbar = CreateFrame("Slider", nil, f, "UIPanelScrollBarTemplate")
	scrollbar:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, -16)
	scrollbar:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 4, 16)
	scrollbar:SetMinMaxValues(0, 1)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	scrollbar:SetScript("OnValueChanged", function(self, value)
		self:GetParent():SetVerticalScroll(value)
	end)
	
	f.scroll = scrollbar
	
	if ( f.buttonParent:GetHeight() - f:GetHeight() ) > 0 then
		f.scroll:SetMinMaxValues(0, ( f.buttonParent:GetHeight() - f:GetHeight() ))
	else
		f.scroll:SetMinMaxValues(0, 0)
	end
	
	f.DisableAllElevents = function(self)
		
		for i=1, #self.elements do
			self.elements[i]:Remove()
		end
		
		wipe(self.elements)
	end
	
	f.Remove = function(self)		
		self:Hide()
		self.free = true
		self:DisableAllElevents()
	end
	f.UpdateScrollElement = function(self, parent)

		self.buttonParent:SetHeight(self.realHeight or 0)
		
		if ( self.buttonParent:GetHeight() - parent:GetHeight() ) > 0 then
			self.scroll:SetMinMaxValues(0, ( self.buttonParent:GetHeight() - parent:GetHeight() )+50)
			self.scroll:Show()
		else
			self.scroll:SetMinMaxValues(0, 0)
			self.scroll:Hide()
		end
	end
	
	f.UpdateSubElements = function(self, data, s, shown)
	--	print("UpdateSubElements", data)
		
		for name, datas in pairs(data.args) do
	--		print("UpdateSubElements", name, datas, datas.type, datas.embend)
			if datas.type == "group" and datas.embend ~= true then
				if not s.subelement then s.subelement = {} end
				
				local show = false		

				if not datas.hidden then
					if ( datas.expand == true and datas._expand == nil ) or ( datas._expand == true ) then
						show = true
					end
				end
				
				s.subelement[#s.subelement+1] = { id = #s.subelement+1, name = name, order = datas.order, toggle = show, show = shown, realname = datas.name, hidden = datas.hidden}
	
				self:UpdateSubElements(datas, s.subelement[#s.subelement], show)
			end
		end
	end
	
	f.UpdateElements = function(self, data)
		assert(data.args, "No args set")
	--	print("UpdateElements", data)
		
		self.free = false
		self:Show()
			
		self.id = 0
		self:DisableAllElevents()
		
		local s = {}
		
		for name, datas in pairs(data.args) do
			
			-- main elements 
			
			if datas.type == "group" then
				local show = false
				
				if not datas.hidden then
					if ( datas.expand == true and datas._expand == nil ) or ( datas._expand == true ) then
						show = true
					end
				end
				
				s[#s+1] = { id = #s+1, name = name, order = datas.order, toggle = show, show = show, realname = datas.name, hidden = datas.hidden }
				
				self:UpdateSubElements(datas, s[#s], show)	
			end
		end
		
		ns:SortTree(s)
	
		for i,data in pairs(s) do
			
		--	print(i, data.show, data.name, data.order, data.subelement and #data.subelement or 0)
	
			self.id = self.id + 1
		
			if self:GetParent():GetParent().datapath == nil then
				self:GetParent():GetParent().datapath = data.name		
			end
			
			ns:GetTreeGroupElement(self, data.name):UpdatePoint(self,data.realname, self.id, data.hidden and 0 or ( data.subelement and #data.subelement or 0) , data.toggle)
					
			if data.show then
				PrintSubElements(self, data, data.name)
			end
		end
		
		self.realHeight = self.id*string_height
		
		
		self:UpdateScrollElement(self:GetParent())
	end
	
	
	self.treeGroupFrames[#self.treeGroupFrames+1] = f
	parent.tree = self.treeGroupFrames[#self.treeGroupFrames]
	
	return f
end