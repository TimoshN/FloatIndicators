local addon, ns = ...

local version_ns = {}
local addonChannel = "FIVCH"
local remindMeagain_Guild = true
local remindMeagain_Raid = true

local IsAddonMessagePrefixRegistered = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered or IsAddonMessagePrefixRegistered
local RegisterAddonMessagePrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage

local name
local string_match = string.match
local format = format
local SendAddonMessage = SendAddonMessage
local tonumber = tonumber
local sendmessagethottle = 20
local versioncheck1 = 0
local versioncheck2 = 0
local showwarning = true

if not IsAddonMessagePrefixRegistered(addonChannel) then
	RegisterAddonMessagePrefix(addonChannel)
end

function version_ns:AddonMessage(msg, channel)

	if channel == "GUILD" and IsInGuild() then
		SendAddonMessage(addonChannel, msg, "GUILD")
	else
		local chatType = "PRINT"
		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
			chatType = "INSTANCE_CHAT"
		elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
			chatType = "RAID"
		elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
			chatType = "PARTY"
		end
			
		if chatType == "PRINT" then
			
		else
			SendAddonMessage(addonChannel, msg, chatType)
		end
	end
end

local function constructVersion(ver)
	local d1, d2, d3 = strsplit(".", ver)
	
	d1 = d1 or "0"
	d2 = d2 or "0"
	d3 = d3 or "0"
	
	if #d2 == 1 then
	   d2 = "00"..d2
	end
	if #d2 == 2 then
	   d2 = "0"..d2
	end
	if #d3 == 1 then
	   d3 = "00"..d3
	end
	if #d3 == 2 then
	   d3 = "0"..d3
	end
	
	return tonumber(d1..d2..d3)
end

ns.constructVersion = constructVersion

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

function events:CHAT_MSG_ADDON(event, prefix, message, channel, sender)
	if prefix ~= addonChannel then return end
	if sender == name then return end
	
	if channel == 'GUILD' then
		if not remindMeagain_Guild then 
			return 
		end
	else
		if not remindMeagain_Raid then
			return
		end
	end
	
	local version, source = strsplit(":", message)
	
	if version and source then
		local cntrV = constructVersion(version)
		local cntrmV = constructVersion(version_ns.myVersionT)
	
		if cntrV > cntrmV then
			
			if channel == 'GUILD' then			
				remindMeagain_Guild = false
			else
				remindMeagain_Raid = false
			end
			
			C_Timer.After(10, function() 
				print("|cFFFFFF00"..addon..": Доступна новая версия "..version..".|r ") 
				
				
				if showwarning then
					showwarning = false
					
					AleaUI_GUI.ShowPopUp(addon,"Доступна новая версия "..version..".",{ name = "Хорошо", OnClick = function() end},{ name = "Потом", OnClick = function() end})
				end				
			end)
		end
	end
end

function events:SendAddonIndo()
	if GetTime() < versioncheck1 then return end
	versioncheck1 = GetTime() + sendmessagethottle
	version_ns:AddonMessage(format("%s:%s", version_ns.myVersionT, version_ns.VersionSource))
end

function events:SendAddonIndo2()
	if GetTime() < versioncheck2 then return end
	versioncheck2 = GetTime() + sendmessagethottle
	version_ns:AddonMessage(format("%s:%s", version_ns.myVersionT, version_ns.VersionSource) , "GUILD")
end

events.GROUP_ROSTER_UPDATE = events.SendAddonIndo
events.PLAYER_ENTERING_WORLD = events.SendAddonIndo2
events.PLAYER_ENTERING_BATTLEGROUND = events.SendAddonIndo
events.GROUP_JOINED = events.SendAddonIndo
events.RAID_INSTANCE_WELCOME = events.SendAddonIndo
events.ZONE_CHANGED_NEW_AREA = events.SendAddonIndo

events.GUILD_MOTD = events.SendAddonIndo2
events.GUILD_NEWS_UPDATE = events.SendAddonIndo2
events.GUILD_ROSTER_UPDATE = events.SendAddonIndo2

events:RegisterEvent("PLAYER_LOGIN")

function events:PLAYER_LOGIN()
	local version = ns.AddOnVer or GetAddOnMetadata(addon, "Version") or "0"
	local version_c = version:gsub("%.", "")
	
	name = UnitName("player").."-"..GetRealmName():gsub(' ', '')
	
	version_ns.myVersionT = version
	version_ns.myVersion = tonumber(version_c) or 0
	version_ns.VersionSource = 'main'

	events:RegisterEvent("CHAT_MSG_ADDON")
	events:RegisterEvent("GROUP_ROSTER_UPDATE")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
	events:RegisterEvent("GROUP_JOINED")
	events:RegisterEvent("RAID_INSTANCE_WELCOME")
	events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	events:RegisterEvent("GUILD_MOTD")
	events:RegisterEvent("GUILD_NEWS_UPDATE")
	events:RegisterEvent("GUILD_ROSTER_UPDATE")
	
	events:SendAddonIndo()
	events:SendAddonIndo2()
end