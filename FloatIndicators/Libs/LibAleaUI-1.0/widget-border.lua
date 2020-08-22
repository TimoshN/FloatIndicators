if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.toggleBorders = {}

local function Update(self, panel, opts)
	assert(opts.values, "No Values is set on "..opts.name)
	
	if type(opts.values) == "function" then
		self.main.values = opts.values()		
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
end

local function UpdateSize(self, panel, opts)
	if opts.width == 'full' then
		self:SetWidth(panel:GetWidth() - 25)
		self.main:SetWidth(panel:GetWidth() - 25)
	else
		self:SetWidth(180)
		self.main:SetWidth(125)
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

local function UpdateState(self, func, get)
	
	self.main._OnClick = func
	self.main._OnShow = get

	self.main.value:SetText(self.main._OnShow() or "")
	
	
	local texture = LibStub("LibSharedMedia-3.0"):Fetch('border', ( self.main._OnShow() or "") ) or ""
	
	self.main.borderex:SetBackdrop({ edgeFile = texture,
	bgFile=[[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }})
			
end

local function CreateCoreDropDown(parent)

	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(125, 25)
	f.border = true
	
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
	f.arrow.text:SetText(ns.statearrow[2])
	f.arrow.text:Hide()
	f.arrow.text:SetJustifyH("CENTER")
	f.arrow.text:SetJustifyV("CENTER")
	f.arrow.text:SetWordWrap(false)
	
	f.arrow:SetScript("OnEnter", function(self)	
		ns.Tooltip(self, f._rname, f.desc, "show")
	end)
	f.arrow:SetScript("OnLeave", function(self)
		ns.Tooltip(self, f._rname, f.desc, "hide")
	end)	
	
	f.arrow:SetScript("OnClick", function(self)
		ns.DD.Show(self:GetParent(), self:GetParent()._OnShow())
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlightSmall")
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
	
	local borderex = CreateFrame("Frame", nil, f, BackdropTemplateMixin and 'BackdropTemplate')
	borderex:SetSize(42, 42)
	borderex:SetPoint("RIGHT", f, "LEFT", 0, 5)
	borderex:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8x8]],
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
		edgeSize = 16,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5,
		}
	})
	borderex:SetBackdropColor(0, 0, 0, 1)
	borderex:SetBackdropBorderColor(1, 1, 1, 1)

	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", value, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", value, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)
		ns.Tooltip(self, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
		ns.Tooltip(self, self:GetParent().desc, "hide")
	end)
	
	f.text = text
	f.value = value
	f.borderex = borderex
	
	return f
end

function ns:CreateDropDownBorder()
	
	for i=1, #ns.toggleBorders do
		if ns.toggleBorders[i].free then
			return ns.toggleBorders[i]
		end
	end
	
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(180, 45)
	f.free = true
	
	f.main = CreateCoreDropDown(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 50, -15)
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	f.UpdateSize = UpdateSize
	
	ns.toggleBorders[#ns.toggleBorders+1] = f
	
	return f
end
	
ns.prototypes["border"] = "CreateDropDownBorder"