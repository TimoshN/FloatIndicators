if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.executeFrames = {}

local function Update(self, panel, opts)
	self.free = false
	self:SetParent(panel)
	self:Show()	
	
	self:SetDescription(opts.desc)
	self:SetName(opts.name)	
	self:UpdateState(opts.func or opts.set, opts.get)
	
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

local function UpdateState(self, func, get)
	
	self.main._OnClick = func
	self.main._OnShow = get
	
end

local function CreateCoreButton(parent)
	local f = CreateFrame('Button', nil, parent, "UIPanelButtonTemplate")
	f:SetSize(160, 22)
	f:SetFrameLevel(parent:GetFrameLevel() + 2)

	f:SetScript("OnEnter", function(self)	
		ns.Tooltip(self, self._rname, self.desc, "show")
	end)
	f:SetScript("OnLeave", function(self)
		ns.Tooltip(self, self._rname, self.desc, "hide")
	end)
	
	f:SetScript("OnMouseUp", function(self)
		self.text:SetPoint("LEFT", self, "LEFT", 3 , 0)
		self.text:SetPoint("RIGHT", self, "RIGHT", -3 , 0)
	end)
	
	f:SetScript("OnMouseDown", function(self)
		self.text:SetPoint("LEFT", self, "LEFT", 2 , -1)
		self.text:SetPoint("RIGHT", self, "RIGHT", -4 ,-1)
	end)
	
	f:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION or "igMainMenuOption");
		
		self._OnClick()
		ns:GetRealParent(self):RefreshData()
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
	text:SetPoint("LEFT", f, "LEFT", 3 , 0)
	text:SetPoint("RIGHT", f, "RIGHT", -3 , 0)
	text:SetTextColor(1, 0.8, 0)
	text:SetJustifyH("CENTER")
	text:SetWordWrap(false)
	
	f.text = text
	
	return f
end

function ns:CreateExecuteButton()
	
	for i=1, #ns.executeFrames do
		if ns.executeFrames[i].free then
			return ns.executeFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-ExecuteButton'..#ns.executeFrames+1, UIParent)
	f:SetSize(180, 35)
	f.free = true
	
	f.main = CreateCoreButton(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -10)
	f.main:SetPoint("RIGHT", f, "RIGHT", 0, 0)
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
	
	ns.executeFrames[#ns.executeFrames+1] = f
	
	return f
end
	
ns.prototypes["execute"] = "CreateExecuteButton"