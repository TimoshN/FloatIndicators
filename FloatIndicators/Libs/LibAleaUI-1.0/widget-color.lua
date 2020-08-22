if AleaUI_GUI then return end
local ns = _G['AleaGUI_PrototypeLib']

ns.colorFrames = {}

local _
local current

local customColorPicker = _G['AleaUIGUI-ColorPickerFrame'] or CreateFrame('Frame', 'AleaUIGUI-ColorPickerFrame', UIParent, BackdropTemplateMixin and 'BackdropTemplate')
customColorPicker:SetFrameStrata('FULLSCREEN_DIALOG')
customColorPicker:SetSize(300, 200)
customColorPicker:SetPoint("CENTER")
customColorPicker:SetBackdrop({
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
customColorPicker:SetBackdropColor(0, 0, 0, 0.7)
customColorPicker:SetBackdropBorderColor(1, 1, 1, 1)
customColorPicker:Hide()

ns.customColorPicker = customColorPicker

local dimension = 96
local withalpha = true
local alphawidth = 18
local colorselect = CreateFrame("ColorSelect", customColorPicker:GetName()..'ColorSelect', customColorPicker)
colorselect:SetPoint("TOPLEFT", customColorPicker, "TOPLEFT", 10, -10)
colorselect:SetFrameLevel(customColorPicker:GetFrameLevel() + 10)
colorselect:SetWidth((dimension or 128)+37)
colorselect:SetHeight(dimension or 128)

local colorwheel = colorselect:CreateTexture()
colorwheel:SetWidth(dimension or 128)
colorwheel:SetHeight(dimension or 128)
colorwheel:SetPoint("TOPLEFT", colorselect, "TOPLEFT", 5, 0)
colorselect:SetColorWheelTexture(colorwheel)

local colorwheelthumbtexture = colorselect:CreateTexture()
colorwheelthumbtexture:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
colorwheelthumbtexture:SetWidth(10)
colorwheelthumbtexture:SetHeight(10)
colorwheelthumbtexture:SetTexCoord(0,0.15625, 0, 0.625)
colorselect:SetColorWheelThumbTexture(colorwheelthumbtexture)

local colorvalue = colorselect:CreateTexture()
colorvalue:SetWidth(alphawidth or 32)
colorvalue:SetHeight(dimension or 128)
colorvalue:SetPoint("LEFT", colorwheel, "RIGHT", 10, -3)
colorselect:SetColorValueTexture(colorvalue)
local colorvaluethumbtexture = colorselect:CreateTexture()
colorvaluethumbtexture:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
colorvaluethumbtexture:SetWidth( alphawidth/32 * 48)
colorvaluethumbtexture:SetHeight( alphawidth/32 * 14)
colorvaluethumbtexture:SetTexCoord(0.25, 1, 0.875, 0)
colorselect:SetColorValueThumbTexture(colorvaluethumbtexture)

local cancelbutton = CreateFrame('Button', nil, customColorPicker, "UIPanelButtonTemplate")
cancelbutton:SetPoint("BOTTOMRIGHT", customColorPicker, "BOTTOMRIGHT", -3, 6)
cancelbutton:SetSize(80, 22)
cancelbutton:SetText(CANCEL)
cancelbutton:SetScript('OnClick', function()
	current = nil
	customColorPicker:Hide()
end)

local okeybutton = CreateFrame('Button', nil, customColorPicker, "UIPanelButtonTemplate")
okeybutton:SetPoint("RIGHT", cancelbutton, "LEFT", -2, 0)
okeybutton:SetSize(80, 22)
okeybutton:SetText(ACCEPT)	
okeybutton:SetScript('OnClick', function()
	--[[
	print("T",'Red', select(1, colorselect:GetColorRGB()))
	print("T",'Green', select(2, colorselect:GetColorRGB()))
	print("T",'Blue', select(3, colorselect:GetColorRGB()))
	print("T",'Alpha', floor(customColorPicker.alphaScroll:GetValue())/100)
	]]
	
	local newR, newG, newB, newA = 
		select(1, colorselect:GetColorRGB()), select(2, colorselect:GetColorRGB()), select(3, colorselect:GetColorRGB()), 
		( customColorPicker.alphaScroll:IsShown() and floor(customColorPicker.alphaScroll:GetValue())/100 or 1 )
	
	
	current._OnClick(_, newR, newG, newB,newA)
	current:SetBackdropColor(newR, newG, newB,newA or 1) --���� ����
	
	ns:GetRealParent(current):RefreshData()
	
	
	current = nil
	customColorPicker:Hide()
end)

local editBoxR255 = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxR255:SetFontObject('ChatFontNormal')
editBoxR255:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxR255:SetAutoFocus(false)
editBoxR255:SetNumeric(true)
editBoxR255:SetWidth(40)
editBoxR255:SetHeight(20)
editBoxR255:SetPoint('TOPRIGHT', customColorPicker, 'TOPRIGHT', -10, -20)
editBoxR255:SetScript("OnEnterPressed", function(self)
	local r = tonumber(self:GetText())/255
	local _, g, b = colorselect:GetColorRGB()
	colorselect:SetColorRGB(r,g,b)
	self:ClearFocus()
end)

local editBoxG255 = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxG255:SetFontObject('ChatFontNormal')
editBoxG255:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxG255:SetAutoFocus(false)
editBoxG255:SetNumeric(true)
editBoxG255:SetWidth(40)
editBoxG255:SetHeight(20)
editBoxG255:SetPoint('TOP', editBoxR255, 'BOTTOM', 0, -3)
editBoxG255:SetScript("OnEnterPressed", function(self)
	local g = tonumber(self:GetText())/255
	local r, _, b = colorselect:GetColorRGB()
	colorselect:SetColorRGB(r,g,b)
	self:ClearFocus()
end)

local editBoxB255 = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxB255:SetFontObject('ChatFontNormal')
editBoxB255:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxB255:SetAutoFocus(false)
editBoxB255:SetNumeric(true)
editBoxB255:SetWidth(40)
editBoxB255:SetHeight(20)
editBoxB255:SetPoint('TOP', editBoxG255, 'BOTTOM', 0, -3)
editBoxB255:SetScript("OnEnterPressed", function(self)
	local b = tonumber(self:GetText())/255
	local r, g, _ = colorselect:GetColorRGB()
	colorselect:SetColorRGB(r,g,b)
	self:ClearFocus()
end)


customColorPicker.editBoxR255 = editBoxR255
customColorPicker.editBoxG255 = editBoxG255
customColorPicker.editBoxB255 = editBoxB255

local customColorPickerColor0255 = customColorPicker:CreateFontString()
customColorPickerColor0255:SetFontObject('ChatFontSmall') --(STANDARD_TEXT_FONT, 10)
customColorPickerColor0255:SetText('0-255')
customColorPickerColor0255:SetPoint('BOTTOM', editBoxR255, 'TOP', 0, 1)

local editBoxR1 = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxR1:SetFontObject('ChatFontNormal')
editBoxR1:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxR1:SetAutoFocus(false)
editBoxR1:SetWidth(40)
editBoxR1:SetHeight(20)
editBoxR1:SetPoint('TOPRIGHT', customColorPicker, 'TOPRIGHT', -60, -20)
editBoxR1:SetScript("OnEnterPressed", function(self)
	local r = tonumber(self:GetText())
	local _, g, b = colorselect:GetColorRGB()
	colorselect:SetColorRGB(r,g,b)
	self:ClearFocus()
end)

local customColorPickerColor01 = customColorPicker:CreateFontString()
customColorPickerColor01:SetFontObject('ChatFontSmall') --(STANDARD_TEXT_FONT, 10)
customColorPickerColor01:SetText('0-1')
customColorPickerColor01:SetPoint('BOTTOM', editBoxR1, 'TOP', 0, 1)

local editBoxG1 = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxG1:SetFontObject('ChatFontNormal')
editBoxG1:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxG1:SetAutoFocus(false)
editBoxG1:SetWidth(40)
editBoxG1:SetHeight(20)
editBoxG1:SetPoint('TOP', editBoxR1, 'BOTTOM', 0, -3)
editBoxG1:SetScript("OnEnterPressed", function(self)
	local g = tonumber(self:GetText())
	local r, _, b = colorselect:GetColorRGB()
	colorselect:SetColorRGB(r,g,b)
	self:ClearFocus()
end)

local editBoxB1 = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxB1:SetFontObject('ChatFontNormal')
editBoxB1:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxB1:SetAutoFocus(false)
editBoxB1:SetWidth(40)
editBoxB1:SetHeight(20)
editBoxB1:SetPoint('TOP', editBoxG1, 'BOTTOM', 0, -3)
editBoxB1:SetScript("OnEnterPressed", function(self)
	local b = tonumber(self:GetText())
	local r, g, _ = colorselect:GetColorRGB()
	colorselect:SetColorRGB(r,g,b)
	self:ClearFocus()
end)

customColorPicker.editBoxR1 = editBoxR1
customColorPicker.editBoxG1 = editBoxG1
customColorPicker.editBoxB1 = editBoxB1

local customColorPickerRed = customColorPicker:CreateFontString()
customColorPickerRed:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 12)
customColorPickerRed:SetText('R:')
customColorPickerRed:SetPoint('RIGHT', editBoxR1, 'LEFT', -6, 0)

local customColorPickerGreen = customColorPicker:CreateFontString()
customColorPickerGreen:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 12)
customColorPickerGreen:SetText('G:')
customColorPickerGreen:SetPoint('RIGHT', editBoxG1, 'LEFT', -6, 0)

local customColorPickerBlue = customColorPicker:CreateFontString()
customColorPickerBlue:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 12)
customColorPickerBlue:SetText('B:')
customColorPickerBlue:SetPoint('RIGHT', editBoxB1, 'LEFT', -6, 0)

local editBoxHex = CreateFrame("EditBox", nil, customColorPicker, "InputBoxTemplate")
editBoxHex:SetFontObject('ChatFontNormal')
editBoxHex:SetFrameLevel(customColorPicker:GetFrameLevel() + 1)
editBoxHex:SetAutoFocus(false)
editBoxHex:SetWidth(60)
editBoxHex:SetHeight(20)
editBoxHex:SetPoint('TOPLEFT', editBoxB1, 'BOTTOMLEFT', 0, -3)
editBoxHex:SetScript("OnEnterPressed", function(self)
	
	local hex = self:GetText()	
	hex = hex:gsub("#","")
	
--	print('T2', hex:len())
	local a, r, g, b
	
	if hex:len() == 8 then
		a = tonumber("0x"..hex:sub(1,2))
		r = tonumber("0x"..hex:sub(3,4))
		g = tonumber("0x"..hex:sub(5,6))
		b = tonumber("0x"..hex:sub(7,8))

	else
		r = tonumber("0x"..hex:sub(1,2))
		g = tonumber("0x"..hex:sub(3,4))
		b = tonumber("0x"..hex:sub(5,6))
	end
	
	if r and g and b then
		colorselect:SetColorRGB(r/255,g/255,b/255)
	end
	
	if a then
		customColorPicker.alphaScroll:SetValue(floor(a/255*100))
	end
	
	editBoxR1:SetText(tonumber(format('%.2f',r)))
	editBoxG1:SetText(tonumber(format('%.2f',g)))
	editBoxB1:SetText(tonumber(format('%.2f',b)))
	
	editBoxR255:SetText(tonumber(format('%.0f',r*255)))
	editBoxG255:SetText(tonumber(format('%.0f',g*255)))
	editBoxB255:SetText(tonumber(format('%.0f',b*255)))
	
--	print('T', a, r, g, b)

	self:ClearFocus()
end)

local customColorPickerHex = customColorPicker:CreateFontString()
customColorPickerHex:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 12)
customColorPickerHex:SetText('Hex:')
customColorPickerHex:SetPoint('RIGHT', editBoxHex, 'LEFT', -6, 0)

colorselect:SetScript("OnColorSelect", function(self)

	local r, g, b = self:GetColorRGB()

	editBoxR1:SetText(tonumber(format('%.2f',r)))
	editBoxG1:SetText(tonumber(format('%.2f',g)))
	editBoxB1:SetText(tonumber(format('%.2f',b)))
	
	editBoxR255:SetText(tonumber(format('%.0f',r*255)))
	editBoxG255:SetText(tonumber(format('%.0f',g*255)))
	editBoxB255:SetText(tonumber(format('%.0f',b*255)))
	
	editBoxHex:SetText(format("ff%02x%02x%02x", r*255, g*255, b*255))
end)

local alphaScroll = CreateFrame('Slider', customColorPicker:GetName()..'AlphaScroll', customColorPicker, 'OptionsSliderTemplate')
alphaScroll:SetFrameLevel(customColorPicker:GetFrameLevel()+2)
alphaScroll:SetOrientation('HORIZONTAL')
alphaScroll:SetMinMaxValues(0, 100)
alphaScroll:SetValue(0)
alphaScroll:SetValueStep(1)
alphaScroll:SetSize(120, 16)
alphaScroll:SetPoint("TOPLEFT", colorselect, "BOTTOMLEFT", 18, -28)
--alphaScroll:SetPoint("BOTTOMRIGHT", colorselect, "BOTTOMRIGHT", 18, 0)
alphaScroll:SetScript("OnValueChanged", function(self, value)			
	alphaScroll.editbox:SetText(format('%d', floor(value)))
end)

alphaScroll.mintext = _G[alphaScroll:GetName().."Low"]
alphaScroll.maxtext = _G[alphaScroll:GetName().."High"]
alphaScroll.mintext:SetText('0%')
alphaScroll.maxtext:SetText('100%')

customColorPicker.alphaScroll = alphaScroll

local alphaScrollText = alphaScroll:CreateFontString()
alphaScrollText:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 12)
alphaScrollText:SetText('Alpha')
alphaScrollText:SetPoint('BOTTOM', alphaScroll, 'TOP')

alphaScroll.editbox = CreateFrame("EditBox", nil, alphaScroll, BackdropTemplateMixin and 'BackdropTemplate')
alphaScroll.editbox:SetFontObject('ChatFontNormal')
alphaScroll.editbox:SetFrameLevel(alphaScroll:GetFrameLevel() + 1)
alphaScroll.editbox:SetAutoFocus(false)
alphaScroll.editbox:SetWidth(40)
alphaScroll.editbox:SetHeight(16)
alphaScroll.editbox:SetJustifyH("Center")
alphaScroll.editbox:SetJustifyV("Center")

alphaScroll.editbox:SetBackdrop({
	bgFile = [[Interface\Buttons\WHITE8x8]],
	edgeFile = [[Interface\Buttons\WHITE8x8]],
	edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
	})
alphaScroll.editbox:SetBackdropColor(0,0,0,1)
alphaScroll.editbox:SetBackdropBorderColor(0.2,0.2,0.2,1)
		
alphaScroll.editbox:SetScript("OnEnterPressed", function(self)
	local val = tonumber(self:GetText())
	if val then
		alphaScroll:SetValue(floor(val))
		alphaScroll.editbox:SetText(floor(val))
	else
		alphaScroll:SetValue(0)
		alphaScroll.editbox:SetText(0)
	end
	
	self:ClearFocus()
end)
alphaScroll.editbox:SetPoint("TOP", alphaScroll, "BOTTOM", 0,-3)
alphaScroll.editbox:SetScript("OnEscapePressed", function(self)
	self:ClearFocus()
end)

alphaScroll._plus = CreateFrame("Button", nil, alphaScroll, BackdropTemplateMixin and 'BackdropTemplate')
alphaScroll._plus:SetSize(14, 14)
alphaScroll._plus:SetPoint("LEFT", alphaScroll.editbox, "RIGHT", 3, 0)
alphaScroll._plus:SetBackdrop({
	bgFile = [[Interface\Buttons\WHITE8x8]],
	edgeFile = [[Interface\Buttons\WHITE8x8]],
	edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
	})
alphaScroll._plus:SetBackdropColor(0,0,0,1)
alphaScroll._plus:SetBackdropBorderColor(0.2,0.2,0.2,1)
alphaScroll._plus.text = alphaScroll._plus:CreateFontString(nil, "OVERLAY")
alphaScroll._plus.text:SetPoint("CENTER")
alphaScroll._plus.text:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
alphaScroll._plus.text:SetText("+")
alphaScroll._plus:SetScript("OnClick", function(self)
	alphaScroll:SetValue( ( alphaScroll:GetValue() or 0 ) + alphaScroll:GetValueStep() )
end)
alphaScroll._plus.text:SetWordWrap(false)

alphaScroll._minus = CreateFrame("Button", nil, alphaScroll, BackdropTemplateMixin and 'BackdropTemplate')
alphaScroll._minus:SetSize(14, 14)
alphaScroll._minus:SetPoint("RIGHT", alphaScroll.editbox, "LEFT", -3, 0)
alphaScroll._minus:SetBackdrop({
	bgFile = [[Interface\Buttons\WHITE8x8]] ,
	edgeFile = [[Interface\Buttons\WHITE8x8]],
	edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
})
alphaScroll._minus:SetBackdropColor(0,0,0,1)
alphaScroll._minus:SetBackdropBorderColor(0.2,0.2,0.2,1)
alphaScroll._minus.text = alphaScroll._minus:CreateFontString(nil, "OVERLAY")
alphaScroll._minus.text:SetPoint("CENTER")
alphaScroll._minus.text:SetFontObject('ChatFontNormal') --:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
alphaScroll._minus.text:SetText("-")
alphaScroll._minus:SetScript("OnClick", function(self)	
	alphaScroll:SetValue( ( alphaScroll:GetValue() or 0 ) - alphaScroll:GetValueStep() )
end)
alphaScroll._minus.text:SetWordWrap(false)
	
local function ShowColorPicker(r,g,b,a,showalpha, f)
	
	
	if current == f then
		current = nil
		customColorPicker:Hide()
	else	
		r = r or 1
		g = g or 1
		b = b or 1
		
		
		editBoxR1:SetText(tonumber(format('%.2f',r)))
		editBoxG1:SetText(tonumber(format('%.2f',g)))
		editBoxB1:SetText(tonumber(format('%.2f',b)))
		
		editBoxR255:SetText(tonumber(format('%.0f',r*255)))
		editBoxG255:SetText(tonumber(format('%.0f',g*255)))
		editBoxB255:SetText(tonumber(format('%.0f',b*255)))
		
		editBoxHex:SetText(format("%02x%02x%02x%02x", a and a*255 or 255, r*255, g*255, b*255))
	
		local realparent = ns:GetRealParent(f)
		customColorPicker:SetParent(realparent)
		customColorPicker:SetFrameLevel(realparent:GetFrameLevel()+10)
		
	
	
		current = f
		
		customColorPicker:SetPoint("TOPLEFT", f, 'BOTTOMLEFT', 0, 0)
		customColorPicker:Show()
		
		local height = 150
	
		if showalpha then
			alphaScroll:Show()
			alphaScroll:SetValue(floor(a*100))		
			alphaScroll.editbox:SetText(floor(a*100))
			
			
			height = height + 50
		else
			alphaScroll:Hide()
		end
		
		customColorPicker:SetSize(300, height)
		C_Timer.After(0.5, function()
			colorselect:SetColorRGB(r,g,b)
		end)
	end
end

local function Update(self, panel, opts)
	
	self.free = false
	self:SetParent(panel)
	self:Show()	
	
	self:SetDescription(opts.desc)
	self:SetName(opts.name)
	
	self:UpdateColor(opts)
	self:UpdateState(opts.set, opts.get)
	
	if panel.childs then
		panel.childs[self] = true
	else
	
	end
end

local function UpdateSize(self, panel, opts)
	if opts.width == 'full' then
		self:SetWidth(panel:GetWidth() - 25)
	else
		self:SetWidth(180)
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

local function UpdateColor(self, opts)

	self.main.hasAlpha = opts.hasAlpha
	
	local r,g,b,a = opts.get()
	
	r = r or 1
	g = g or 1
	b = b or 1
	
	self.main.texture:SetColorTexture(r,g,b, self.main.hasAlpha and ( a or 1 ) or 1)
end

local function CreateCoreButton(parent)
	local f = CreateFrame('Button', nil, parent, BackdropTemplateMixin and 'BackdropTemplate') --"UICheckButtonTemplate"

	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetSize(21, 21)

	local colorSwatch = f:CreateTexture(nil, "OVERLAY")
	colorSwatch:SetWidth(16)
	colorSwatch:SetHeight(16)
	colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
	colorSwatch:SetPoint("CENTER")

	local texture = f:CreateTexture(nil, "BACKGROUND", 0)
	texture:SetWidth(13)
	texture:SetHeight(13)
	texture:SetColorTexture(1, 1, 1)
	texture:SetPoint("CENTER", colorSwatch)
	texture:Show()
	
	local checkers = f:CreateTexture(nil, "BACKGROUND", -1)
	checkers:SetWidth(11)
	checkers:SetHeight(11)
	checkers:SetTexture("Tileset\\Generic\\Checkers")
	checkers:SetTexCoord(.25, 0, 0.5, .25)
--	checkers:SetDesaturated(true)
	checkers:SetVertexColor(1, 1, 1, 0.75)
	checkers:SetPoint("CENTER", colorSwatch)
	checkers:Show()
	
	f:SetBackdrop({
		bgFile = "",
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Background]], 
		edgeSize = 2,
		insets = {top = 0, left = 0, bottom = 0, right = 0},
	})
	f:SetBackdropBorderColor(unpack(ns.button_border_color_ondown))
	
	f:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(unpack(ns.button_border_color_onup))
		ns.Tooltip(self, self._rname, self.desc, "show")
	end)
	f:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(unpack(ns.button_border_color_ondown))
		ns.Tooltip(self, self._rname, self.desc, "hide")
	end)
	
	
	f:SetScript("OnClick", function(self)
		local r,g,b,a = self._OnShow()	
		if self.hasAlpha then
			ShowColorPicker(r,g,b,(a or 1), self.hasAlpha, self)
		else
			ShowColorPicker(r,g,b,1, self.hasAlpha, self)
		end
	end)

	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontHighlight")
	text:SetPoint("LEFT", f, "RIGHT", 3 , 0)
--	text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	text:SetTextColor(1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", text, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)
--		self:GetParent():SetBackdropBorderColor(unpack(ns.button_border_color_onup)) --���� �����		
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
--		self:GetParent():SetBackdropBorderColor(unpack(ns.button_border_color_ondown)) --���� �����
	
		ns.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)
	
	f.text = text
	f.texture = colorSwatch
	
	return f
end

function ns:CreateColorFrame()
	
	for i=1, #ns.colorFrames do
		if ns.colorFrames[i].free then
			return ns.colorFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", 'AleaUIGUI-ColorButton'..#ns.colorFrames+1, UIParent)
	f:SetSize(180, 45)
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
	f.UpdateColor = UpdateColor
	f.UpdateSize = UpdateSize
	
	ns.colorFrames[#ns.colorFrames+1] = f
	
	return f
end
	
ns.prototypes["color"] = "CreateColorFrame"