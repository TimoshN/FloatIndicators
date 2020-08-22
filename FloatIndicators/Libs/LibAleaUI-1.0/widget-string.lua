if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.stringFrames = {}

local function Update(self, panel, opts)
	
	self.free = false
	self:SetParent(panel)
	self:Show()	
	
	self:SetDescription(opts.desc)
	self:SetName(opts.name)	
	self:UpdateState(opts.get, opts.name)
	
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

local function UpdateState(self, get, name)

	self.main._OnShow = get

	self.main.text:SetText(self.main._OnShow and self.main._OnShow() or name)

	local height = self.main.text:GetStringHeight()
	local height2 = self.main.text:GetHeight()

	if height < 25 then
		height = 25
	end

	self:SetHeight(height)
	self.main.text:SetHeight(0)

end

local function CreateCore(parent)

	local f = CreateFrame("Frame", nil, parent)
	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetWidth(160)
	f:SetHeight(20)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", f, "TOPLEFT", 3 , 0)
	text:SetPoint("RIGHT", f, "RIGHT", -3 , 0)
	text:SetWordWrap(true)
--	text:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	text:SetTextColor(1, 1, 1, 1)
	text:SetJustifyV("TOP")
	text:SetJustifyH("LEFT")
	--[[
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", text, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)	
	]]
	--	ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	--[[
	end)
	f.mouseover:SetScript("OnLeave", function(self)
	]]
	--	ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
--	end)
	
	
--	f.ok = okbttm
	f.text = text
	
	return f
end

function ns:CreateString()
	
	for i=1, #ns.stringFrames do
		if ns.stringFrames[i].free then
			return ns.stringFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-StringFrame'..#ns.stringFrames+1, UIParent)
	f:SetSize(180, 30)
	f.free = true
	
	f.main = CreateCore(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, 0)
	f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
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
	
	ns.stringFrames[#ns.stringFrames+1] = f
	
	return f
end
	
ns.prototypes["string"] = "CreateString"