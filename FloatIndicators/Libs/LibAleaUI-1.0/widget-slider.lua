if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.sliderFrames = {}
local _
local hidenframe = CreateFrame('Frame')
hidenframe:Hide()

local function Update(self, panel, opts)
	
	self.free = false
	self:SetParent(panel)
	self:Show()	
	
	self:SetDescription(opts.desc)
	self:SetMinMaxStep(opts.min, opts.max, opts.step)
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
			self:SetWidth( panel:GetWidth() - 27)
			self.main:SetWidth( panel:GetWidth() - 27)
		end
	else
		self:SetWidth(180)
		self.main:SetWidth(170)
	end
end

local function Remove(self)
	self.free = true
	self.main:SetScript("OnValueChanged", nil)
	self:Hide()
	self:ClearAllPoints()
	self.main._lastval = nil
end

local function SetName(self, name)
	self.main._rname = name
	self.main.text:SetText(name)
end

local function SetMinMaxStep(self, min1, max1, step)
	local step = step or 1
	self.main:SetMinMaxValues(min1,max1)
	self.main.mintext:SetText(min1)
	self.main.maxtext:SetText(max1)
	
	self.main:SetValueStep(step)
	self.main:SetObeyStepOnDrag(true)
	
	if step ~= floor(step) then
		self.main.floatValue = true
		self.main.step = "%.1f"
	else
		self.main.floatValue = false
		self.main.step = "%d"
	end
end

local function SetDescription(self, text)
	self.main.desc = text
end

local function SecondsRound(num, numDecimals)
	numDecimals = numDecimals or 1
	
	return math_floor(num*(10*numDecimals)+.5)/(10*numDecimals)
end

local function Round(num) return math.floor(num+.5) end

local function OnValueChanged(self, value)
	local val = format(self.step, value)

--	print(val, value, self:GetWidth())
	
	
	if val ~= self._lastval then
		self._lastval = val
	--	print("T", self:HasScript("OnMouseDown"), self:HasScript("OnMouseUp"), self:HasScript("OnDragStop"), self:HasScript("OnDragStart"))
	--	self:SetScript("OnValueChanged", nil)
		self._OnValueChanged(_, tonumber(val))	
	--	self:SetValue(self._OnShow() or 0)
		self.editbox:SetText(format(self.step, self._OnShow() or 0))
	--	self:SetScript("OnValueChanged", OnValueChanged)
	end
end

local function UpdateState(self, set, get)
	
	self.main._lastval = nil
	self.main._OnValueChanged = set
	self.main._OnShow = get
	self.main:SetValue(self.main._OnShow() or 0)
	self.main.editbox:SetText(format(self.main.step, self.main._OnShow() or 0))
	self.main:SetScript("OnValueChanged", OnValueChanged)
	
--	self.main:SetThumbPosition(self.main._OnShow() or 0)
end

local function SetRelPoint(self, point)
--	if point > self:GetParent():GetWidth()*0.5 then point = self:GetParent():GetWidth()*0.5
--	elseif point < 200 then point = 200
--	end		
--	self:ClearAllPoints()
--	self:SetPoint("TOP", f, "TOP", 0, -10)
--	self:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
--	self:SetPoint("LEFT", f, "LEFT", point, 0)
	if point < 16 then point = 16
	elseif point >  self:GetParent():GetWidth()-16 then point = self:GetParent():GetWidth()-16 
	end
	
	local pos = ( self:GetParent().floatValue and SecondsRound(point, 1) or Round(point) )
	
	print('pos', pos, self:GetParent().floatValue)
	
	self:ClearAllPoints()
	self:SetPoint("CENTER", self:GetParent(), "LEFT", pos, 0)
end

local function MoveSeparator(self)
	SetRelPoint(self, GetCursorPosition()/self:GetEffectiveScale()-self:GetParent():GetLeft())
end

local function SetThumbPosition(self, value)
	local minValue, maxValue = self:GetMinMaxValues()
	local width = self:GetWidth()-16-16
	
	local totalvalue = abs(minValue) + abs(maxValue)
	
	local stepvalue = width/totalvalue
	
	local point = 0
	
	if value == 0 then
		point = 0
	elseif value > 0 then
		point = 16+stepvalue*value
	elseif value < 0 then
		point = -16-stepvalue*value
	end
	
	print('point', point, 'value', value, 'stepvalue', stepvalue, 'width', width, 'minValue', minValue, 'maxValue', maxValue)
	
	SetRelPoint(self.polzynok, point)
end

local function CreateCoreButton(parent)
	local f = CreateFrame('Slider', parent:GetName()..'Handler', parent, 'OptionsSliderTemplate')
	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:HookScript("OnMouseUp", function(self)
		ns:GetRealParent(self):RefreshData()
	--	print("OnMouseUp") 
	end)
--	f:HookScript("OnDragStop", function(self) print("OnDragStop") end)
	
	local thumb = f:GetThumbTexture()
--	thumb:SetSize(32, 32)
--	thumb:SetParent(hidenframe)
--[==[	
	local polzynok = CreateFrame('Frame', nil, f)
	polzynok:SetSize(8, 16)
	polzynok.texture = polzynok:CreateTexture()
	polzynok.texture:SetColorTexture(0, 1, 0, 1)
	polzynok.texture:SetAllPoints()
	polzynok:SetPoint('CENTER', f, 'CENTER', 0, 0)
	polzynok:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	polzynok:SetScript("OnMouseDown", function(self)
		self:SetScript("OnUpdate", MoveSeparator)
	end)
	
	f.polzynok = polzynok
	
	f.SetThumbPosition = SetThumbPosition
]==]	
	f.text = f:CreateFontString("$parentHeader", 'OVERLAY', "GameFontHighlight")
	f.text:SetPoint("BOTTOM", f, "TOP", 0 , -4)
--	f.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	f.text:SetText(text)
	f.text:SetTextColor(1, 0.8, 0)
	f.text:SetHeight(18)
	f.text:SetWidth(170)
	f.text:SetWordWrap(false)
	
	f:SetMinMaxValues(1, 200)	
	f:SetValueStep(0.1)	
	f:SetWidth(170)
	f:SetHitRectInsets(0, 0, 0, 0) 
	
	f.mintext = _G[f:GetName().."Low"]
	f.maxtext = _G[f:GetName().."High"]
	
	f.mintext:ClearAllPoints()
	f.maxtext:ClearAllPoints()
	
	f.mintext:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -2)
	f.maxtext:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -2)
	
	f.editbox = CreateFrame("EditBox", nil, f,BackdropTemplateMixin and 'BackdropTemplate')
--	f.editbox:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
	f.editbox:SetFontObject('ChatFontNormal')
	f.editbox.myslider = f
	f.editbox:SetFrameLevel(parent:GetFrameLevel() + 1)
	f.editbox:SetAutoFocus(false)
	f.editbox:SetWidth(40)
	f.editbox:SetHeight(16)
	f.editbox:SetJustifyH("Center")
	f.editbox:SetJustifyV("Center")

	f.editbox:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8x8]] , --[=[Interface\ChatFrame\ChatFrameBackground]=]
		edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=], --[=[Interface\ChatFrame\ChatFrameBackground]=]
		edgeSize = 1,
		insets = {top = 0, left = 0, bottom = 0, right = 0},
		})
	f.editbox:SetBackdropColor(0 , 0 , 0 , 1) --цвет фона
	f.editbox:SetBackdropBorderColor(0.2 , 0.2 , 0.2 , 1) --цвет краев
			
	 f.editbox:SetScript("OnEnterPressed", function(self)
		local val = tonumber(format("%.1f", self:GetText()))	
		if val then
			self.myslider:SetValue(val)
		else
			self.myslider:SetValue(0)
		end		
		self:ClearFocus()
	end)
	f.editbox:SetPoint("TOP", f, "BOTTOM", 0,-3)
	f.editbox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	
	f._plus = CreateFrame("Button", nil, f)
	f._plus:SetSize(14, 14)
	f._plus:SetPoint("LEFT", f.editbox, "RIGHT", 3, 0)
	f._plus:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
	f._plus:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
				
	--[==[
	f._plus:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8x8]],
		edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		edgeSize = 1,
		insets = {top = 0, left = 0, bottom = 0, right = 0},
		})
	f._plus:SetBackdropColor(0 , 0 , 0 , 1) --цвет фона
	f._plus:SetBackdropBorderColor(0.2 , 0.2 , 0.2 , 1) --цвет краев
	
	f._plus.text = f._plus:CreateFontString(nil, "OVERLAY")
	f._plus.text:SetPoint("CENTER")
	f._plus.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	f._plus.text:SetText("+")
	--]==]
	f._plus:SetScript("OnClick", function(self)
		
		local minVal, maxVal = self:GetParent():GetMinMaxValues()
		
		local newVal = tonumber(( self:GetParent()._OnShow() or 0 ) + self:GetParent():GetValueStep())
		
		if newVal > maxVal then
			newVal = maxVal
		end
		
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
		
		self:GetParent()._OnValueChanged(_, newVal)		
		ns:GetRealParent(self):RefreshData()
	end)
	--f._plus.text:SetWordWrap(false)
	
	f._minus = CreateFrame("Button", nil, f)
	f._minus:SetSize(14, 14)
	f._minus:SetPoint("RIGHT", f.editbox, "LEFT", -3, 0)
	f._minus:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
	f._minus:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
	
	
	--[==[
	f._minus:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8x8]],
		edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		edgeSize = 1,
		insets = {top = 0, left = 0, bottom = 0, right = 0},
		})
	f._minus:SetBackdropColor(0 , 0 , 0 , 1) --цвет фона
	f._minus:SetBackdropBorderColor(0.2 , 0.2 , 0.2 , 1) --цвет краев
	f._minus.text = f._minus:CreateFontString(nil, "OVERLAY")
	f._minus.text:SetPoint("CENTER")
	f._minus.text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	f._minus.text:SetText("-")
	]==]
	f._minus:SetScript("OnClick", function(self)
	
		local minVal, maxVal = self:GetParent():GetMinMaxValues()
		
		local newVal = tonumber(( self:GetParent()._OnShow() or 0 ) - self:GetParent():GetValueStep())
		
		if newVal < minVal then
			newVal = minVal
		end
		
		PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or "igMainMenuOptionCheckBoxOff")
		
		self:GetParent()._OnValueChanged(_, newVal)		
		ns:GetRealParent(self):RefreshData()
	end)
--	f._minus.text:SetWordWrap(false)
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", f.text, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", f.text, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)
	--	self:GetParent():SetBackdropBorderColor(unpack(ns.button_border_color_onup)) --цвет краев		
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
	--	self:GetParent():SetBackdropBorderColor(unpack(ns.button_border_color_ondown)) --цвет краев	
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)

	return f
end

function ns:CreateSlider()
	
	for i=1, #ns.sliderFrames do
		if ns.sliderFrames[i].free then
			return ns.sliderFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-SliderFrame'..#ns.sliderFrames+1, UIParent)
	f:SetSize(180, 55)
	f.free = true
	
	f.main = CreateCoreButton(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -15)
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
	f.SetMinMaxStep = SetMinMaxStep
	f.UpdateSize = UpdateSize
	
	ns.sliderFrames[#ns.sliderFrames+1] = f
	
	return f
end
	
ns.prototypes["slider"] = "CreateSlider"