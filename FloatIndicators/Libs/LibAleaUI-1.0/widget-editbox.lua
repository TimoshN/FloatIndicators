if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.editboxFrames = {}
local _
local function Update(self, panel, opts)
	
	self.free = false
	self:SetParent(panel)
	self:Show()
	
	self:SetDescription(opts.desc)
	self:SetName(opts.name)	
	self:UpdateState(opts.set, opts.get)
	
	if panel.childs then
		panel.childs[self] = true
	else
	
	end
end

local function 	UpdateSize(self, panel, opts, parent)
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
		self.main:SetWidth(160)
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

local function UpdateState(self, set, get)
	
	self.main._OnClick = set
	self.main._OnShow = get

	self.main:SetText(self.main._OnShow() or "")
end

local function CreateCore(parent)

	local f = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	f:SetFontObject('ChatFontNormal')
	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetAutoFocus(false)
	f:SetWidth(160)
	f:SetHeight(20)
	
	f:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self.ok:Hide()
		self:SetText(self._OnShow() or "")
		ns:GetRealParent(self):RefreshData()	
	end)
	
	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
	text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 3 , 2)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	
	local okbttm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	okbttm:SetFrameLevel(f:GetFrameLevel()+1)
	okbttm:SetSize(40,20)
	okbttm:SetPoint("RIGHT", f, "RIGHT", 0, 0)
	okbttm:Hide()

	okbttm:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
		self:Hide()
		self:GetParent():ClearFocus()
		self:GetParent()._OnClick(_, self:GetParent():GetText())	
		ns:GetRealParent(self):RefreshData()	
	end)
	
	okbttm.text = okbttm:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
	okbttm.text:SetPoint("CENTER", okbttm, "CENTER", 0 , 0)
	okbttm.text:SetTextColor(1, 0.8, 0)
	okbttm.text:SetText("OK")
	okbttm.text:SetJustifyH("CENTER")
	okbttm.text:SetWordWrap(false)
	
	f:SetScript("OnTextChanged", function(self, userInput)	
		if userInput then
			self.ok:Show()
		end
	end)
	
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", text, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)	
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)
	
	
	f.ok = okbttm
	f.text = text
	
	return f
end

function ns:CreateEditBox()
	
	for i=1, #ns.editboxFrames do
		if ns.editboxFrames[i].free then
			return ns.editboxFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-EditBox'..#ns.editboxFrames+1, UIParent)
	f:SetSize(180, 40)
	f.free = true
	
	f.main = CreateCore(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 13, -15)
	f.main:SetPoint("RIGHT", f, "RIGHT", -8, 0)
	
	--[[
	local bg = f:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0.5, 1, 0.5, 1)
	]]
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	f.UpdateSize = UpdateSize
	
	ns.editboxFrames[#ns.editboxFrames+1] = f
	
	return f
end
	
ns.prototypes["editbox"] = "CreateEditBox"


do
	ns.editboxFramesExtends = {}

	local function Update(self, panel, opts)
		
		self.free = false
		self:SetParent(panel)
		self:Show()	
		
		self:SetDescription(opts.desc)
		self:SetName(opts.name)	
		self:UpdateState(opts.set, opts.get)		
	end
	
	local function 	UpdateSize(self, panel, opts, parent)
		if opts.width == 'full' then			
			self.main.editbox:SetWidth(300)
		else
			self.main.editbox:SetWidth(180)
		end
		
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
			self.main:SetWidth(160)
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

	local function UpdateState(self, set, get)
		
		self.main._OnClick = set
		self.main._OnShow = get

		self.main.editbox:SetText(self.main._OnShow() or "")
	end

	local function CreateCore(parent)
		
		local pf = CreateFrame("Frame", nil, parent)
	
		local bg_border = CreateFrame("Frame", nil, pf, BackdropTemplateMixin and 'BackdropTemplate')
		bg_border:SetFrameLevel(pf:GetFrameLevel()+1)
		bg_border:SetPoint("TOPLEFT", pf, "TOPLEFT", -3, 3)
		bg_border:SetPoint("BOTTOMRIGHT", pf, "BOTTOMRIGHT", 3, -3)
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
		bg_border:SetBackdropColor(0, 0, 0, 0.5)
		bg_border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
	
		pf.Scroll = CreateFrame("ScrollFrame", "AleaUIEditBoxMultiLineScrollFrame"..#ns.editboxFramesExtends+1, pf, "UIPanelScrollFrameTemplate")
		pf.Scroll:SetFrameLevel(pf:GetFrameLevel() + 1)
		
		local focusFrame = CreateFrame('Frame', 'focusFrame', pf)
		focusFrame:SetAllPoints()
		focusFrame:SetFrameLevel(pf:GetFrameLevel() + 5)
		focusFrame:EnableMouse(true)
		focusFrame:SetScript('OnMouseDown', function(self)
			self:Hide()
			pf.editbox:SetFocus()
		end)
		
		local f = CreateFrame("EditBox", nil, pf)
		f:SetFontObject('ChatFontNormal')
		f:SetFrameLevel(parent:GetFrameLevel() + 1)
		f:SetAutoFocus(false)
		f:SetWidth(260)
		f:SetHeight(80)
		f:SetText('\n\n\n\n')
		f:SetMultiLine(true)
		--[[
		local bg = f:CreateTexture()
		bg:SetAllPoints()
		bg:SetTexture(0.5, 0, 0.5, 1)
		]]
		pf.Scroll:SetScrollChild(f)
		pf.Scroll:SetPoint("TOPRIGHT", pf, "TOPRIGHT", -23, -2)
		pf.Scroll:SetPoint("TOPLEFT", pf, "TOPLEFT", 0, -2)
		pf.Scroll:SetPoint("BOTTOM", pf, "BOTTOM", 0, 2)

		--[[
		local bg = pf.Scroll:CreateTexture()
		bg:SetAllPoints()
		bg:SetTexture(0, 0, 0.5, 1)
		]]
		f:SetPoint('TOPLEFT', pf.Scroll, "TOPLEFT", 11, -5)
		f:SetPoint('RIGHT', pf, "RIGHT", 0, 0)
		f:SetPoint("BOTTOM", pf, "BOTTOM", 0, 2)
		
		pf.Scroll:SetSize(160, 80)
		pf.Scroll:SetHorizontalScroll(-5)
		pf.Scroll:SetVerticalScroll(0)
		pf.Scroll:EnableMouse(false)
		pf.Scroll:EnableMouseWheel(false)
		
		f:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
			self.ok:Hide()
			focusFrame:Show()
			self:SetText(self.pf._OnShow() or "")
			ns:GetRealParent(self.pf):RefreshData()	
		end)
		
		local text = pf:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
		text:SetPoint("BOTTOMLEFT", pf, "TOPLEFT", 3 , 4)
		text:SetJustifyH("LEFT")
		text:SetWordWrap(false)
		
		local okbttm = CreateFrame("Button", nil, pf, "UIPanelButtonTemplate")
		okbttm:SetFrameLevel(pf:GetFrameLevel()+1)
		okbttm:SetSize(40,20)
		okbttm:SetPoint("TOPRIGHT", pf, "BOTTOMRIGHT", 0, -2)
		okbttm:Hide()

		okbttm:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
			
			self:Hide()
			focusFrame:Show()
			self:GetParent():ClearFocus()
			self:GetParent()._OnClick(_, self:GetParent():GetText())	
			ns:GetRealParent(self):RefreshData()	
		end)
		
		okbttm.text = okbttm:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
		okbttm.text:SetPoint("CENTER", okbttm, "CENTER", 0 , 0)
		okbttm.text:SetTextColor(1, 0.8, 0)
		okbttm.text:SetText("OK")
		okbttm.text:SetJustifyH("CENTER")
		okbttm.text:SetWordWrap(false)
		
		f:SetScript("OnTextChanged", function(self, userInput)	
			if userInput then
				self.ok:Show()
			end
		end)
		
		
		f.mouseover = CreateFrame("Frame", nil, pf)
		f.mouseover:SetFrameLevel(pf:GetFrameLevel()-1)
		f.mouseover:SetSize(1,1)
		f.mouseover:SetPoint("TOPLEFT", text, "TOPLEFT", -3, 3)
		f.mouseover:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 3, -3)
		f.mouseover:SetScript("OnEnter", function(self)	
			ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
		end)
		f.mouseover:SetScript("OnLeave", function(self)
			ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
		end)
		
		
		pf.editbox = f
		pf.ok = okbttm
		pf.text = text
		f.pf = pf
		f.ok = okbttm
		f.text = text
		
		return pf
	end

	function ns:CreateEditBoxExtends()
		
		for i=1, #ns.editboxFramesExtends do
			if ns.editboxFramesExtends[i].free then
				return ns.editboxFramesExtends[i]
			end
		end
		
		local f = CreateFrame("Frame", 'AleaUIGUI-EditBoxExtends'..#ns.editboxFramesExtends+1, UIParent)
		f:SetSize(180, 100)
		f.free = true
		
		f.main = CreateCore(f)
		f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -15)
		f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 20)
		
		--[[
		local bg = f:CreateTexture()
		bg:SetAllPoints()
		bg:SetTexture(0.5, 1, 0.5, 1)
		]]
		
		f.Update = Update
		f.Remove = Remove
		f.SetName = SetName
		f.UpdateState = UpdateState
		f.SetDescription = SetDescription
		f.UpdateSize = UpdateSize
		
		ns.editboxFramesExtends[#ns.editboxFramesExtends+1] = f
		
		return f
	end
		
	ns.prototypes["multieditbox"] = "CreateEditBoxExtends"

end