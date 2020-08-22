if AleaUI_GUI then return end
local addon = ...

local ns = CreateFrame("Frame", "AleaGUI_PrototypeLib")

local table_insert, table_remove = table.insert, table.remove
local table_wipe = table.wipe
local table_sort = table.sort
local format = format

local versionStr, internalVersion, dateofpatch, uiVersion = GetBuildInfo(); internalVersion = tonumber(internalVersion)

ns.wowbuild = internalVersion
ns.uibuild	= tonumber(uiVersion)

ns.isClassic = ns.uibuild < 20000

ns.mainFrames = {}
ns.openedmainFrames = {}
ns.RegisteredAddons = {}
ns.prototypes = {}
ns.OnButtonPanelSizeChanged = {}

ns.fontOnMouse = { 1, 1, 1, 1 }
ns.fontNormal = { 1, 0.8, 0, 1 }
ns.statearrow = { " ▲", " ▼","◄", "►" }

ns.main_bg_color = {18/255 , 18/255 , 18/255 , 0.6}
ns.main_border_color = {0, 0, 0 , 1}
ns.main_bg_left_right_side_color = {18/255 , 18/255 , 18/255 , 0.1}

ns.alt_border_color = { 23/256, 131/256, 209/256 , 0.6 }
ns.alt_bg_color = { 0 , 0 , 0 , 0.9 }
ns.button_border_color_onup = {0 , 0.85 , 1 , 0.8}
ns.button_border_color_ondown = {153/255, 153/255, 153/255 , 0.5 }
ns.button_bg_color = { 5/255 , 5/255 , 5/255 , 0.9 }


local numFrames = 0

function ns:GetNumFrames()
	numFrames = numFrames + 1
	return numFrames
end

do
	local gametooltip = _G['AleaGUIGameToolTip'] or CreateFrame("GameTooltip", "AleaGUIGameToolTip", nil, "GameTooltipTemplate"); -- Tooltip name cannot be nil	
	gametooltip:Show()
	gametooltip:Hide()
	gametooltip:SetScale(0.7)
	
	
	local spellIcon = gametooltip:CreateTexture(nil, "ARTWORK")
	spellIcon:SetPoint("TOPRIGHT", gametooltip, "TOPLEFT", -3, -2)
	spellIcon:SetSize(60, 60)
	spellIcon:Hide()
	
	function ns.Tooltip(self, name, desc, state, hyper, texture)
		gametooltip:Hide()
		if state == "show" then
			gametooltip:SetOwner(self, "ANCHOR_TOPRIGHT")			
			gametooltip:ClearLines()
			
			gametooltip:SetText(name or "", 1, .82, 0, true)
			
			spellIcon:Hide()
			
			if hyper then
				gametooltip:SetHyperlink(hyper)
				
				gametooltip:AddLine('   ', 1,1,1, true)
				gametooltip:AddLine(hyper, 1,1,1, true)
				
				local spellName, spellRank, spellID = gametooltip:GetSpell() 
				
				if spellID then
					local fake, real = GetSpellTexture(spellID)
					spellIcon:SetTexture(texture or real or fake)
					spellIcon:Show()
				end
				
			elseif desc then
				if string.find(desc, '\n') then
					gametooltip:AddLine(desc, 1,1,1, false)
				else
					gametooltip:AddLine(desc, 1,1,1, true)
				end
			end

			gametooltip:Show()
		else
			gametooltip:Hide()
			gametooltip:ClearLines()
		end
		
		return gametooltip
	end

end

local dims = 25
local sorting_menu = function(x,y) 		
	if x.order > 0 and y.order > 0 then		
		return x.order < y.order 			
	elseif x.order > 0 and y.order < 0 then
		return true
	elseif x.order < 0 and y.order > 0 then
		return false
	elseif x.order < 0 and y.order < 0 then					
		if x.order > y.order then
			return true
		elseif x.order < y.order then
			return false
		end
	end
	
	return false
end
--[[
local sorting_menu2 = function(x,y) 		
	if x > 0 and y > 0 then		
		return x < y 			
	elseif x > 0 and y < 0 then
		return true
	elseif x < 0 and y > 0 then
		return false
	elseif x < 0 and y < 0 then					
		if x > y then
			return true
		elseif x < y then
			return false
		end
	end
	
	return false
end

ALEAUI_GUI_SORT = sorting_menu2
]]
function ns:SortTree(t)
	table_sort(t, sorting_menu)
end

local sizes = {}

function ns:RegisterMainFrame(addonName, guiTable, curwidth,curheight, minwidth, minheight)
	assert(addonName, 'Usage ns:RegisterMainFrame("addonName") - addonName is nil')
--	assert(not self.RegisteredAddons[addonName], addonName..' already registered.')
	
	
	ns.RegisteredAddons[addonName] = guiTable
	
	sizes[addonName] = sizes[addonName] or {}
	sizes[addonName].minwidth = minwidth or 500
	sizes[addonName].minheight = minheight or 400
	sizes[addonName].curwidth = curwidth or 650
	sizes[addonName].curheight = curheight	or 400
end

function ns:SelectGroup(addonName, ...)
	assert(addonName, 'Usage ns:SelectGroup("addonName", groups) - addonName is nil')
	assert(self.RegisteredAddons[addonName], addonName..'not registered.')
	
	if not self.openedmainFrames[addonName] then
		return
	end
	
	local curpath = ""
	local prev = ns.RegisteredAddons[addonName]
	
	for i=1, select("#", ...) do
		local group = select(i, ...)
		
		if not group then
			break;
		end
		
		if prev.args[group] then
			prev = prev.args[group]
			
			if curpath == "" then
				curpath = group
			else
				curpath = curpath..";"..group
			end
		else
			print("Error in",group,"in path",curpath)
			break;
		end
	end
	
	self.openedmainFrames[addonName].datapath = curpath
	self.openedmainFrames[addonName]:Update(addonName)

end

function ns:Open(addonName)
	assert(addonName, 'Usage ns:Open("addonName") - addonName is nil')
	assert(self.RegisteredAddons[addonName], addonName..'not registered.')
	
	if not self.openedmainFrames[addonName] then
		self.openedmainFrames[addonName] = self:GetMainFrame()
		self.openedmainFrames[addonName]:ClearAllPoints()
		self.openedmainFrames[addonName]:SetPoint("CENTER")
		self.openedmainFrames[addonName]:Update(addonName)	
	else
		self.openedmainFrames[addonName]:Update(addonName)
	end
end

function ns:Close(addonName)
	assert(addonName, 'Usage ns:Close("addonName") - addonName is nil')
	assert(self.RegisteredAddons[addonName], addonName..' not registered.')
	
	if self.openedmainFrames[addonName] then
		
		local width, height = self.openedmainFrames[addonName]:GetSize()
		
		sizes[addonName].curwidth = width
		sizes[addonName].curheight = height
	
		self.openedmainFrames[addonName]:Deactivate("openedmainFrames", addonName)
	end	
end

function ns:IsOpened(addonName)
	return self.openedmainFrames[addonName]
end

function ns:Deactivate(from, addonName)
	ns[from][self.addon or addonName] = nil
	self.tree:Remove()
	self:Remove()
end


function ns:Remove()
	self:Hide()
	self.free = true
	self.datapath = nil
	self.addon = nil
end

function ns:Update(addonName)

	local o = ns.RegisteredAddons[addonName]
	
	self.addon = addonName
	self.free = false
	self:Show()
	
	self:SetMinResize(sizes[addonName].minwidth, sizes[addonName].minheight)	
	self:SetSize(sizes[addonName].curwidth, sizes[addonName].curheight)

	
	if o.title then
		if type(o.title) == "string" then
			self.header.text:SetText(o.title)
		elseif type(o.title) == "function" then
			self.header.text:SetText(o.title(addonName))
		end
	end
	
	self.tree:UpdateElements(o)

	ns:GetRightGroupFramesFrame(self, o)

	if ( self.rightSide.__border ) then 
		self.rightSide.__border:SetBackdrop({
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
		self.rightSide.__border:SetBackdropColor(0, 0, 0, 0.5)
		self.rightSide.__border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

		self.rightSide.__border = false
	end

end

function ns:RefreshData()
	if not ns:IsOpened(self.addon) then return end
	
	self.tree:UpdateElements(ns.RegisteredAddons[self.addon])
	
	ns:GetRightGroupFramesFrame(self, ns.RegisteredAddons[self.addon])
end

local function MoveSeparator(self)
	self.bg:SetColorTexture(0.4, 0.4, 0.4, 1)
	self:SetRelPoint(GetCursorPosition()/self:GetEffectiveScale()-self:GetParent():GetLeft())
end

local function UpdateRightSide(self)

	local elements_row = floor(self:GetWidth())
	local elements_num = floor(self:GetHeight())

	if ( self.buttonParent:GetHeight() - self:GetHeight() ) > 1 then
		self.slider.scroll:Show()
		self.slider.scroll:SetMinMaxValues(0, ( self.buttonParent:GetHeight() - self:GetHeight() ))
	else
		self.slider.scroll:SetMinMaxValues(0, 0)
		self.slider.scroll:Hide()
	end
	
	if self.last_elements_row and self.last_elements_num then
		if elements_row == self.last_elements_row and elements_num == self.last_elements_num then 
			return 
		end		
	end
	
	self.buttonParent:SetWidth(self:GetWidth())
	
	self.last_elements_num = elements_num
	self.last_elements_row = elements_row
	
--	ns:GetRightGroupFramesFrame(self:GetParent(), ns.RegisteredAddons[self:GetParent().addon])
	
--	ns:GetRealParent(self):RefreshData()	
	self:GetParent():SetElementPosition()
end

local function UpdateLeftSide(self)
	if self:GetParent().tree then
		self:GetParent().tree:UpdateScrollElement(self:GetParent())
	end
end

local function OnButtonParentSizeChanged(self, ...)	
	for i=1, #ns.OnButtonPanelSizeChanged do		
		ns.OnButtonPanelSizeChanged[i](self, ...)
	end
end

function ns:GetRealParent(f)
	local ff = f
	
	if f and f.docked then
		return f
	end
	
	assert(ff, "Frame Is nil")
	while ( true ) do
		ff = ff:GetParent()
		if ff.RefreshData then
			return ff
		end
	end
end

function ns.GetNumInGroups(f)
	local ff = f
	local num = 0
	
	while ( true ) do
		ff = ff:GetParent()
		
		if ff.RefreshData then
			return num
		else
			num = num + 1
		end
	end
end

local function AddBorders(f, bg, color)
	
	local color = color or { 0, 0, 0, 1}
	
	--[[
	local bg1 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	bg1:SetPoint("TOPRIGHT", bg, "TOPLEFT", 0, 1)
	bg1:SetPoint("BOTTOMRIGHT", bg, "BOTTOMLEFT", 0, -1)
	bg1:SetSize(1,1)
	bg1:SetTexture(color[1],color[2],color[3],color[4])
	
	local bg2 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	bg2:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", -1, 0)
	bg2:SetPoint("TOPRIGHT", bg, "BOTTOMRIGHT", 1, 0)
	bg2:SetSize(1,1)
	bg2:SetTexture(color[1],color[2],color[3],color[4])
	
	local bg3 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	bg3:SetPoint("BOTTOMLEFT", bg, "TOPLEFT", -1, 0)
	bg3:SetPoint("BOTTOMRIGHT", bg, "TOPRIGHT", 1, 0)
	bg3:SetSize(1,1)
	bg3:SetTexture(color[1],color[2],color[3],color[4])
	
	local bg4 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	bg4:SetPoint("TOPLEFT", bg, "TOPRIGHT", 0, 1)
	bg4:SetPoint("BOTTOMLEFT", bg, "BOTTOMRIGHT", 0, -1)
	bg4:SetSize(1,1)
	bg4:SetTexture(color[1],color[2],color[3],color[4])
	]]
	
	
	-- [[Interface\DialogFrame\UI-DialogBox-Border]]
	
end


local function SetElementPosition(self)
	local datapath = self.datapath	
	local panel = self.rightSide
	local panel_width = panel:GetWidth()-dims
	local elements_row = floor(panel_width/180)
	
	local frames = 0
	local index = 0
	local totalheight = 0
	local currentheight = 0

	panel.buttonParent:SetWidth(panel:GetWidth())
	
	for i=1, #self.ListElements do
		local opts = self.datas.args[self.ListElements[i].name]
		local prototype = opts.type
		local width = opts.width
		local height = opts.height
		local fromNewLine = opts.newLine
	
		if prototype ~= "group" then
			index = index + 1
			
			if not panel.elements[index] then
				panel.elements[index] = ns:GetPrototype(prototype)
				panel.elements[index]:Update(panel.buttonParent, opts, nil, datapath)
			end
			if panel.elements[index].UpdateSize then
				panel.elements[index]:UpdateSize(panel.buttonParent, opts, nil, datapath)
			end
			panel.elements[index]:ClearAllPoints()
			
			if frames == 0 then
				frames = frames + 1
				panel.elements[index]:SetPoint("TOPLEFT", panel.buttonParent, "TOPLEFT", 2, 0)
				
				if width == "full" then
				--	panel.elements[index]:SetPoint("RIGHT", panel.buttonParent, "RIGHT", -20, 0)
					frames = elements_row
				end
				
				if currentheight < panel.elements[index]:GetHeight() then
					currentheight = panel.elements[index]:GetHeight()
				end
			else
			
				if width == "full" then
				
					totalheight = totalheight + currentheight
					currentheight = 0
					
					panel.elements[index]:SetPoint("TOPLEFT", panel.buttonParent, "TOPLEFT", 2, -totalheight)
				--	panel.elements[index]:SetPoint("RIGHT", panel.buttonParent, "RIGHT", -20, 0)
					if currentheight < panel.elements[index]:GetHeight() then
						currentheight = panel.elements[index]:GetHeight()
					end
					frames = elements_row
					
				elseif frames >= elements_row or fromNewLine then
					
					totalheight = totalheight + currentheight
					currentheight = 0
					
					frames = 1
					panel.elements[index]:SetPoint("TOPLEFT", panel.buttonParent, "TOPLEFT", 2, -totalheight)
				
					if currentheight < panel.elements[index]:GetHeight() then
						currentheight = panel.elements[index]:GetHeight()
					end
				else
					frames = frames + 1
					panel.elements[index]:SetPoint("TOPLEFT", panel.elements[index-1], "TOPRIGHT", 2, 0)
					if currentheight < panel.elements[index]:GetHeight() then
						currentheight = panel.elements[index]:GetHeight()
					end
				end
			end
			
			if height == "full" then
				totalheight = totalheight + panel:GetHeight() - totalheight
				currentheight = 0
				
				panel.elements[index]:SetPoint("BOTTOM", panel.buttonParent, "BOTTOM", 0, 0)				
			end
			
		elseif prototype == "group" and opts.embend == true then
			index = index + 1		
			if not panel.elements[index] then
				panel.elements[index] = ns:GetPrototype(prototype)
				panel.elements[index]:Update(panel.buttonParent, opts, nil, datapath)
			end
			if panel.elements[index].UpdateSize then
				panel.elements[index]:UpdateSize(panel.buttonParent, opts, nil, datapath)
			end
			panel.elements[index]:ClearAllPoints()
			
			if frames == 0 then
				frames = elements_row
				panel.elements[index]:SetPoint("TOPLEFT", panel.buttonParent, "TOPLEFT", 0, 0)
				if currentheight < panel.elements[index]:GetHeight() then
					currentheight = panel.elements[index]:GetHeight()
				end					
			else
				totalheight = totalheight + currentheight
				currentheight = 0
				
				panel.elements[index]:SetPoint("TOPLEFT", panel.buttonParent, "TOPLEFT", 0, -totalheight)
				if currentheight < panel.elements[index]:GetHeight() then
					currentheight = panel.elements[index]:GetHeight()
				end
				frames = elements_row
			end
		end
	end
	totalheight = totalheight + currentheight
	
	panel.buttonParent:SetHeight(totalheight) --totalheight

	if ( panel.buttonParent:GetHeight() - panel:GetHeight() ) > 1 then
		panel.slider.scroll:Show()
		panel.slider.scroll:SetMinMaxValues(0, ( panel.buttonParent:GetHeight() - panel:GetHeight() ))
	else
		panel.slider.scroll:Hide()
		panel.slider.scroll:SetMinMaxValues(0, 0)
	end
	
	return totalheight
end

function ns:GetMainFrame()
	for i=1, #self.mainFrames do		
		if self.mainFrames[i].free then
			return self.mainFrames[i]
		end
	end
		
	local f = CreateFrame("Frame", "AleaUIGUI-MainFrame"..#self.mainFrames+1, UIParent)
	f:SetSize(650, 400)
	f:SetPoint("CENTER")
	f:SetClampedToScreen(true)	
	f.protoType = "mainFrames"
	f:SetFrameLevel(10*#self.mainFrames+1)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f.free = true
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetMinResize(500, 400)
	f:SetMaxResize(1000, 1000)
	f:SetResizable(true)
	f:SetToplevel(true)
	f:SetDontSavePosition(true)
	
	f:SetScript("OnHide", function(self)
		if self.addon then ns:Close(self.addon) end
	end)
	
	f.ListElements = {}
	f.datas = {}
	f.SetElementPosition = SetElementPosition
	
	tinsert(UISpecialFrames, "AleaUIGUI-MainFrame"..#self.mainFrames+1)
	
	local bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	bg:SetPoint("TOPLEFT", f, "TOPLEFT", -10, 10)
	bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 10, -30)
	
	bg:SetColorTexture(ns.main_bg_color[1],ns.main_bg_color[2],ns.main_bg_color[3],ns.main_bg_color[4])

	local f_border = CreateFrame("Frame", nil, f,BackdropTemplateMixin and 'BackdropTemplate')
	f_border:SetPoint("TOPLEFT", f, "TOPLEFT", -15, 15)
	f_border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 15, -35)
	f_border:SetBackdrop({
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
		edgeSize = 26,
	})
	f_border:SetBackdropBorderColor(1, 1, 1, 1)

	
--	AddBorders(f, bg)
	
	local header = CreateFrame("Frame", nil, f)
	header:SetFrameLevel(f_border:GetFrameLevel()+3)
	header:SetSize(20,20)
	header:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, -3)
	header:SetPoint("BOTTOMRIGHT", f,"TOPRIGHT", 0, -3)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function(self)
		self:GetParent():StartMoving() end)
	header:SetScript("OnDragStop", function(self)
		self:GetParent():StopMovingOrSizing() 
	end)
	
	local header_text = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	header_text:SetPoint("TOP")
--	header_text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	header_text:SetJustifyH("CENTER")
	header_text:SetText("Moving")
	--[[
	local header_bg = f_border:CreateTexture(nil, "BACKGROUND", nil, 0)
	header_bg:SetPoint("TOPLEFT", header_text, "TOPLEFT", -3, 3)
	header_bg:SetPoint("BOTTOMRIGHT", header_text, "BOTTOMRIGHT", 3, -3)
	header_bg:SetTexture(0, 0, 0, 1)
	]]
	local header_border = CreateFrame("Frame", nil, f,BackdropTemplateMixin and 'BackdropTemplate')
	header_border:SetFrameLevel(header:GetFrameLevel()-1)
	header_border:SetPoint("TOPLEFT", header_text, "TOPLEFT", -10, 10)
	header_border:SetPoint("BOTTOMRIGHT", header_text, "BOTTOMRIGHT", 10, -10)
	header_border:SetBackdrop({
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
	header_border:SetBackdropColor(0, 0, 0, 1)
	header_border:SetBackdropBorderColor(1, 1, 1, 1)
	
	local sizing = CreateFrame("Frame", nil, f)
	sizing:SetSize(18, 18)
	sizing.isMouseDown = false
	sizing:RegisterForDrag("LeftButton")
	sizing:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -1, 1)
	sizing:SetScript("OnDragStart", function(self)
		self:GetParent():StartSizing() 
	end)
	sizing:SetScript("OnDragStop", function(self)
		self:GetParent():StopMovingOrSizing()
		
		local addonName = self:GetParent().addon
		
		local width, height = ns.openedmainFrames[addonName]:GetSize()
		
		sizes[addonName].curwidth = width
		sizes[addonName].curheight = height
		
		
		self.isMouseDown = false
		self.bg:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") --0.4, 0.4, 0.4, 1)
		
		self:GetParent():RefreshData()	
	end)
	sizing:SetScript("OnEnter", function(self)
		self.bg:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight") --0.4, 0.4, 0.4, 0.8)
	end)
	sizing:SetScript("OnLeave", function(self)
		if not self.isMouseDown then
			self.bg:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") --0.4, 0.4, 0.4, 0.4)
		end
	end)
	sizing:SetScript("OnMouseUp", function(self)
		self.isMouseDown = false
		self.bg:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") --0.4, 0.4, 0.4, 1)
	end)
	sizing:SetScript("OnMouseDown", function(self)
		self.isMouseDown = true
		self.bg:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down") --0.4, 0.4, 0.4, 0.8)
	end)
	
	local sizing_bg = sizing:CreateTexture(nil, "BACKGROUND", nil, 1)
	sizing_bg:SetAllPoints()
	sizing_bg:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") --0.4, 0.4, 0.4, 0.4)	
	sizing.bg = sizing_bg
	
	f.Deactivate = self.Deactivate
	f.Update = self.Update
	f.RefreshData = self.RefreshData
	f.Remove = self.Remove
	
	f.ResetSeparator = function(self)		
		self.separator:SetRelPoint(200)
	end
	
	f.header = header
	f.header.text = header_text
	
	local separator = CreateFrame("Frame", nil, f)
	separator:SetFrameLevel(f:GetFrameLevel()+5)
	separator:SetMovable(true)
	separator:SetSize(3, 10)
	separator:EnableMouse(true)
	separator:RegisterForDrag("LeftButton")
	separator:SetScript("OnDragStart", function(self)
	--	self:SetScript("OnUpdate", MoveSeparator)
	end)
	separator:SetScript("OnDragStop", function(self)
		self.bg:SetColorTexture(0.4, 0.4, 0.4, 0)
		self:SetScript("OnUpdate", nil)	
		self:GetParent():RefreshData()	
	end)
	separator:SetScript("OnEnter", function(self)
		self.bg:SetColorTexture(0.4, 0.4, 0.4, 0.8)
	end)
	separator:SetScript("OnLeave", function(self)
		self.bg:SetColorTexture(0.4, 0.4, 0.4, 0)
	end)
	separator:SetScript("OnMouseUp", function(self)
		self.bg:SetColorTexture(0.4, 0.4, 0.4, 1)
		self:SetScript("OnUpdate", nil)
	end)
	separator:SetScript("OnMouseDown", function(self)
		self.bg:SetColorTexture(0.4, 0.4, 0.4, 0.8)
		self:SetScript("OnUpdate", MoveSeparator)
	end)
	
	separator.SetRelPoint = function(self, point)
		if point > self:GetParent():GetWidth()*0.5 then point = self:GetParent():GetWidth()*0.5
		elseif point < 200 then point = 200
		end		
		self:ClearAllPoints()
		self:SetPoint("TOP", f, "TOP", 0, -10)
		self:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
		self:SetPoint("LEFT", f, "LEFT", point, 0)
	end
	separator:SetRelPoint(200)
	
	separator.bg  = separator:CreateTexture(nil, "BACKGROUND", nil, 0)
	separator.bg:SetAllPoints()
	separator.bg:SetColorTexture(0.4, 0.4, 0.4, 0)
	local leftSide = CreateFrame("Frame", nil, f)
	leftSide:SetFrameLevel(f:GetFrameLevel()+1)
	leftSide:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
	leftSide:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	leftSide:SetPoint("RIGHT", separator, "LEFT", -5, 0)
	leftSide:SetScript("OnSizeChanged", UpdateLeftSide)	
	
--	local leftSide_bg = leftSide:CreateTexture(nil, "BACKGROUND", nil, 1)
--	leftSide_bg:SetAllPoints()
--	leftSide_bg:SetTexture(ns.main_bg_left_right_side_color[1], ns.main_bg_left_right_side_color[2], ns.main_bg_left_right_side_color[3], ns.main_bg_left_right_side_color[4])	
	
--	AddBorders(leftSide, leftSide_bg)
	
	local leftSide_border = CreateFrame("Frame", nil, leftSide,BackdropTemplateMixin and 'BackdropTemplate')
	leftSide_border:SetFrameLevel(leftSide:GetFrameLevel()-1)
	leftSide_border:SetPoint("TOPLEFT", leftSide, "TOPLEFT", -5, 5)
	leftSide_border:SetPoint("BOTTOMRIGHT", leftSide, "BOTTOMRIGHT", 5, -5)
	leftSide_border:SetBackdrop({
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
	leftSide_border:SetBackdropColor(0, 0, 0, 0.5)
	leftSide_border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	
	local rightSide = CreateFrame("Frame", nil, f)
	rightSide:SetFrameLevel(f:GetFrameLevel()+1)
	rightSide:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
	rightSide:SetPoint("LEFT", separator, "RIGHT", 5, 0)
	rightSide.elements = {}
	rightSide:SetScript("OnSizeChanged", UpdateRightSide)	

	rightSide.slider = CreateFrame("ScrollFrame",nil, rightSide)
	rightSide.slider:SetFrameLevel(rightSide:GetFrameLevel() + 1)
	rightSide.slider:EnableMouse(true)
	
	rightSide.buttonParent = CreateFrame("Frame", nil, rightSide)
	rightSide.buttonParent:SetPoint("TOPLEFT", rightSide, "TOPLEFT", 0, 0)
	rightSide.buttonParent:SetWidth(1)
	rightSide.buttonParent:SetHeight(1)
	rightSide.buttonParent:SetFrameLevel(rightSide.slider:GetFrameLevel() + 1)
	rightSide.buttonParent:SetScript("OnSizeChanged", OnButtonParentSizeChanged)
	rightSide.buttonParent.childs = {}
		
	rightSide.slider:SetSize(1, 1)
	rightSide.slider:SetPoint("TOPRIGHT", rightSide, "TOPRIGHT", -20, 0)
	rightSide.slider:SetPoint("BOTTOMLEFT", rightSide, "BOTTOMLEFT", 0, 0)
	rightSide.slider:SetScrollChild(rightSide.buttonParent)
	rightSide.slider:SetHorizontalScroll(0)
	rightSide.slider:SetVerticalScroll(0)
	rightSide.slider:EnableMouse(true)
	rightSide.slider:SetScript("OnMouseWheel", function(self, delta)
		self.scroll:SetValue(self.scroll:GetValue()-( 30 * delta))	
		self:SetVerticalScroll(self.scroll:GetValue())	
	end)
	
	local scrollbar = CreateFrame("Slider", nil, rightSide.slider, "UIPanelScrollBarTemplate")
	scrollbar:SetPoint("TOPLEFT", rightSide.slider, "TOPRIGHT", 4, -16)
	scrollbar:SetPoint("BOTTOMLEFT", rightSide.slider, "BOTTOMRIGHT", 4, 16)
	scrollbar:SetMinMaxValues(0, 1)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	scrollbar:SetScript("OnValueChanged", function(self, value)
		self:GetParent():SetVerticalScroll(value)
	end)
	
	rightSide.slider.scroll = scrollbar
	
	local rightSide_bg = rightSide:CreateTexture(nil, "BACKGROUND", nil, 1)
	rightSide_bg:SetAllPoints()
	
	rightSide_bg:SetColorTexture(ns.main_bg_left_right_side_color[1], ns.main_bg_left_right_side_color[2], ns.main_bg_left_right_side_color[3], ns.main_bg_left_right_side_color[4])	


	local rightSide_border = CreateFrame("Frame", nil, rightSide, BackdropTemplateMixin and 'BackdropTemplate')
	rightSide_border:SetFrameLevel(rightSide:GetFrameLevel()-1)
	rightSide_border:SetPoint("TOPLEFT", rightSide, "TOPLEFT", -5, 5)
	rightSide_border:SetPoint("BOTTOMRIGHT", rightSide, "BOTTOMRIGHT", 5, -5)
	
	rightSide.__border = rightSide_border

	f.leftSide = leftSide
	f.rightSide = rightSide
	
	f.__close = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
	f.__close.f = f
	f.__close:SetSize(80,20)
	f.__close:SetFrameLevel(header:GetFrameLevel()+3)
	f.__close:EnableMouse(true)
	f.__close:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -20, 10)
	f.__close:SetScript("OnClick", function(self)
		ns:Close(f.addon)
	end)
	
--	AddBorders(f.__close, f.__close, { 0.3, 0.3, 0.3, 1 } )
	
	local close_text = f.__close:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
--	close_text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	close_text:SetJustifyH("CENTER")
	close_text:SetText(CLOSE)
	close_text:SetPoint("LEFT", f.__close, "LEFT", 3 , 0)
	close_text:SetPoint("RIGHT", f.__close, "RIGHT", -3 , 0)
	close_text:SetTextColor(1, 0.8, 0)
	--[[	
	local close_bg = f.__close:CreateTexture(nil, "BACKGROUND", nil, 0)
	close_bg:SetPoint("TOPLEFT", f.__close, "TOPLEFT", 0, 0)
	close_bg:SetPoint("BOTTOMRIGHT", f.__close, "BOTTOMRIGHT", 0, 0)
	close_bg:SetTexture(0, 0, 0, 1)
	]]
	
	f.__close:SetScript("OnMouseUp", function(self)
		close_text:SetPoint("LEFT", self, "LEFT", 3 , 0)
		close_text:SetPoint("RIGHT", self, "RIGHT", -3 , 0)
	end)
	
	f.__close:SetScript("OnMouseDown", function(self)
		close_text:SetPoint("LEFT", self, "LEFT", 2 , -1)
		close_text:SetPoint("RIGHT", self, "RIGHT", -4 ,-1)
	end)
	
	f.tree = ns:GetTreeGroupFramesFrame(f)
	
	--[[
	f.__close:SetScript("OnEnter", function(self)
		close_bg:SetTexture(0.2, 0.2, 0.2, 1)
	end)
	f.__close:SetScript("OnLeave", function(self)
		close_bg:SetTexture(0, 0, 0, 1)
	end)
	]]
	self.mainFrames[#self.mainFrames+1] = f
	
	return f
end

local freeDropDownList = {}
function ns:FreeDropDowns(me)
	if me ~= ns.DD then ns.DD.Hide() end
	if me ~= ns.DDFonts then ns.DDFonts.HideFonts() end
	if me ~= ns.DDSounds then ns.DDSounds.HideFonts() end
	if me ~= ns.customColorPicker then ns.customColorPicker:Hide() end
	if me ~= 'multiDropDown' then ns:HideMultiDropdown(me) end
	
	for k,v in pairs(freeDropDownList) do
		if k ~= me then v(me) end		
	end
end

function ns:AddToFreeDropDown(frame, func)
	freeDropDownList[frame] = func
end

function ns:FreeAllElements(panel, source)
	for i=1, #panel.elements do
		panel.elements[i]:Remove()
	end

	panel.elements ={}
end
function ns:FreeAllChilds(panel)

end

function ns:GetRightGroupFramesFrame(self, o)
	
	local datapath = self.datapath	
	local panel = self.rightSide
--	local panel_width = panel:GetWidth()-dims
--	local elements_row = floor(panel_width/180)
	local datas = nil
	local updatescroll = false
	
	if datapath ~= self._lastdatapath then
		self._lastdatapath = datapath
		updatescroll = true
	end
	
	ns:FreeDropDowns(me)
	
	--self.last_elements_row = elements_row
	
	for i=1, select("#", strsplit(";", datapath)) do
		local arg = select(i, strsplit(";", datapath))
		datas = datas or o

		if datas.args[arg] then
			datas = datas.args[arg]
		end
	end

	ns:FreeAllElements(panel)
	ns:FreeAllChilds(panel)
	
	wipe(ns.OnButtonPanelSizeChanged)
	
	local s = {}
	
	for name, data1 in pairs(datas.args) do
		s[#s+1] = { name = name, order = data1.order }	
	end
	
	ns:SortTree(s)
	
	self.ListElements = s
	
	if updatescroll then
		panel.slider.scroll:SetValue(0)
	end
	
	self.datas = datas
	self:SetElementPosition()
end


function ns:GetPrototype(prototype)
	assert(prototype, "Invalid prototype - "..tostring(prototype))
	assert(ns.prototypes[prototype], "Invalid prototype - "..tostring(prototype))
	
	return ns[ns.prototypes[prototype]](ns)
end