--[=====================================[

	Based off rNamePlates2 by zork	

--]=====================================]

local _, ns = ...
setmetatable(ns, { __index = ABUADDONS })

local cfg = ns.Config
local StatusbarTex = cfg.Statusbar.Light
local FONT, FONTSIZE = cfg.Fonts.Normal, 12
local WIDTH, HEIGHT, CBHEIGHT, GAP = 105, 8,8,7
local TOTALHEIGHT = (HEIGHT + CBHEIGHT + GAP);
local MINALPHA = 0.6;
local RAIDSIZE = 20;

local BorderTex = "Interface\\AddOns\\AbuEssentials\\Textures\\NamePlate\\Plate.blp"
local BorderTexGlow = "Interface\\AddOns\\AbuEssentials\\Textures\\NamePlate\\PlateGlow.blp"
local MarkTex = "Interface\\AddOns\\AbuEssentials\\Textures\\NamePlate\\Mark2.blp"
local TexCoord 		= {24/256, 186/256, 35/128, 59/128}
local GlowTexCoord 	= {15/256, 195/256, 21/128, 73/128}
local CbTexCoord 	= {24/256, 186/256, 59/128, 35/128}
local CbGlowTexCoord= {15/256, 195/256, 73/128, 21/128}

local HighlightTex = "Interface\\AddOns\\AbuEssentials\\Textures\\NamePlate\\Highlight.blp"
local HiTexCoord 	= {5/128, 105/128, 20/32, 26/32}

local SHORTUPDATE = .1;
local LONGUPDATE = 1;

local FactionColors = {
	["FriendNPC"] 	= {r = FACTION_BAR_COLORS[6].r, g = FACTION_BAR_COLORS[6].g, b = FACTION_BAR_COLORS[6].b},
	["FriendPlayer"]= {r = .35, g = 0.35, b = 1},
	["HostileNPC"] 	= {r = FACTION_BAR_COLORS[2].r, g = FACTION_BAR_COLORS[2].g, b = FACTION_BAR_COLORS[2].b},
	["NeutralNPC"] 	= {r = FACTION_BAR_COLORS[4].r, g = FACTION_BAR_COLORS[4].g, b = FACTION_BAR_COLORS[4].b},
}

local ThreatColors = {
   [1] = {1, 1, 0.2},
   [2] = {1, .7, .3},
   [3] = {1, 0.1, 0.1},
}
----------------------------------------------------------

local UPDATETIME = .2
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local floor = floor

local Backdrop = {
	bgFile = 'Interface\\Buttons\\WHITE8x8',
}

--  [[  Totem Icons  ]]  --
local OverrideIcons = {
	["Stormlash Totem"]			= "Interface\\ICONS\\ability_shaman_tranquilmindtotem",
	["Healing Tide Totem"] 		= "Interface\\ICONS\\ability_shaman_healingtide",
	["Earth Elemental Totem"] 	= "Interface\\ICONS\\spell_nature_earthelemental_totem",
	["Searing Totem"] 			= "Interface\\ICONS\\spell_fire_searingtotem",
	["Fire Elemental Totem"] 	= "Interface\\ICONS\\spell_fire_elemental_totem",
	["Healing Stream Totem"] 	= "Interface\\ICONS\\inv_spear_04",
	["Tremor Totem"] 			= "Interface\\ICONS\\spell_nature_tremortotem",
	["Capacitor Totem"] 		= "Interface\\ICONS\\spell_nature_brilliance",
	["Earthbind Totem"] 		= "Interface\\ICONS\\spell_nature_strengthofearthtotem02",
	["Magma Totem"] 			= "Interface\\ICONS\\spell_fire_selfdestruct",
	-- Specializations
	["Mana Tide Totem"] 		= "Interface\\ICONS\\spell_frost_summonwaterelemental",
	["Spirit Link Totem"] 		= "Interface\\ICONS\\spell_shaman_spiritlink",
	-- Talents
	["Windwalk Totem"] 			= "Interface\\ICONS\\ability_shaman_windwalktotem",
	["Stone Bulwark Totem"] 	= "Interface\\ICONS\\ability_shaman_stonebulwark",
	["Earthgrab Totem"] 		= "Interface\\ICONS\\spell_nature_stranglevines",
}

local NamePlates = { };

local Hider = CreateFrame("Frame")
Hider:Hide()
local function HideIt(frame)
	frame:SetParent(Hider)
	frame:Hide()
end

-----------------------------------------------------------------------------------
-- General Helper functions
-----------------------------------------------------------------------------------

local function GetFixedColor(r, g, b)
	return floor(r *100 + .5)/100, floor(g *100 + .5)/100, floor(b *100 + .5)/100
end

local function GetHexColorString(r, g, b)
	r, g, b = GetFixedColor(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

local function GetFaction(r,g,b)
	if (r < .01) then
		if (b < .01) and (g > .99) then 
			return "Friend", "NPC";
		elseif (b > .99) and (g < .01) then 
			return "Friend", "Player"; 
		end
	elseif (r > .99) then
		if (b < .01) and (g > .99) then 
			return "Neutral", "NPC";
		elseif (b < .01) and (g < .01) then
			return "Hostile", "NPC"; 
		end
	elseif (r > .5 and r < .55) and (g > .5 and g < .55) and (g > .5 and g < .55) then
		return "Tapped", "NPC"
	end
	return "Hostile", "Player"
end

local function CanHaveThreat(r, g, b)
	local r, f = GetFaction(r,g,b)
	return f == "NPC" and r ~= "Friend"
end

local function IsInCombat(plate)
	local r,g,b = plate._Name:GetTextColor()
	return (r > .5) and (g < .5);
end

local function GetThreatStatus(_Threat) -- 0 - 3, none - high
	if (not _Threat:IsShown()) then
		return 0; -- none
	end
	local r,g,b = _Threat:GetVertexColor()
	if r > 0 then
		if g > 0 then
			if b > 0 then
				return 1; -- low
			end
			return 2; -- medium
		end
		return 3; -- high
	end
	return 0; -- none
end

local function PlateIsTarget(self)
	if not (UnitExists("target")) then return false; end
	if (self:GetAlpha() > .95) then
		return true;
	end
	return false;
end

-----------------------------------------------------------------------------------
-- Nameplate functions
-----------------------------------------------------------------------------------

local function UpdateHealthColor(plate)
	if plate.Health.doNotOverride then return; end
	local r, g, b = GetFixedColor(plate._Health:GetStatusBarColor())

	for class, _ in pairs(RAID_CLASS_COLORS) do
		if RAID_CLASS_COLORS[class].r == r and 
			RAID_CLASS_COLORS[class].g == g and 
			RAID_CLASS_COLORS[class].b == b
		then
			return;
		end
	end
	local re, f = GetFaction(r,g,b)
	local color = FactionColors[re..f]
	if color then
		plate.Health:SetStatusBarColor(color.r, color.g, color.b);
	else
		plate.Health:SetStatusBarColor(r, g, b)
	end
end

local function UpdateName(plate)
	plate.unitName = plate._Name:GetText() or "Unknown"
	-- Totemicon instead of name
	local icon = OverrideIcons[plate.unitName]
	if icon then
		if (not plate.TotemIcon) then
			plate.TotemIcon = CreateFrame("Frame", nil, plate)
			plate.TotemIcon:EnableMouse(false)
			plate.TotemIcon:SetSize(30, 30)
			plate.TotemIcon:SetPoint("BOTTOM", plate, "TOP", 0, 5)
			plate.TotemIcon.Border = plate.TotemIcon:CreateTexture(nil, "BACKGROUND", nil, 1)
			plate.TotemIcon.Border:SetTexture(cfg.IconTextures.White)
			plate.TotemIcon.Border:SetPoint("TOPRIGHT", plate.TotemIcon, 2, 2)
			plate.TotemIcon.Border:SetPoint("BOTTOMLEFT", plate.TotemIcon, -2, -2)
		end

		plate.TotemIcon:SetBackdrop({
			bgFile = icon,
			insets = { top = -2, left = -2, bottom = -2, right = -2 },
		})
		plate.Name:Hide()
		plate.TotemIcon.Border:SetVertexColor(GetFixedColor(plate._Health:GetStatusBarColor()))
		plate.TotemIcon:Show()
		return;
	elseif plate.TotemIcon then
		plate.TotemIcon:SetBackdrop(nil)
		plate.TotemIcon:Hide()
		plate.Name:Show()
	end

	local level = plate._Level:GetText() or "-1"
	local levelColor = GetHexColorString(plate._Level:GetTextColor())
	if plate._Boss:IsShown() then
		level = "??"
		levelColor = "|cffAF5050"
	elseif plate._Dragon:IsShown() then
		level = level.."+"
	elseif ns.PlayerLevel and tostring(ns.PlayerLevel) == level then
		level = ""
	end
	--plate.Name:SetTextColor(GetFixedColor(plate._Health:GetStatusBarColor()))
	--plate.Name:SetTextColor(GetFixedColor(plate._Name:GetTextColor()))
	plate.Name:SetText(levelColor..level.."|r "..plate.unitName)
end

local function UpdateThreat(plate)
	if not plate.canHaveThreat then return; end
	local t = plate.Threat

	local status = GetThreatStatus(plate._Threat);
	if ns.PlayerIsTankSpec then
		status = abs(status - 3) -- Math yeah
	end

	if plate.lastthreat == status then return; end
	plate.lastthreat = status;
	--[[	threat	glow 		tank 	glow 	bar
			3	full	red 	0 		none 	green 
			2	losin	orange	1 		yello	orange
			1	low 	yellow	2 		orang	default (red)
			0	noen 	none 	3 		red		default 			]]
	if plate._Threat:IsVisible() then
		if status > 0 then -- incase ur a tank
			t:SetVertexColor(unpack(ThreatColors[status]))
			if not t:IsShown() then t:Show() end
		else
			if t:IsShown() then t:Hide() end
		end
		if ns.PlayerIsTankSpec and status < 2 then
			if status == 0 then
				plate.Health:SetStatusBarColor(0, 1, 0)
			elseif status == 1 then
				plate.Health:SetStatusBarColor(unpack(ThreatColors[1]))
			end
			plate.Health.doNotOverride = true
		else
			plate.Health.doNotOverride = nil
		end
	else
		if t:IsShown() then t:Hide() end
		plate.Health.doNotOverride = nil
	end
end

local PlateGuidMap = { };
local NameGuidMap = { };

local function SetGuid(plate, unit)
	if (not unit) then -- no unit, educated guess
		if NameGuidMap[plate.unitName] then
			plate.guid = NameGuidMap[plate.unitName]
			PlateGuidMap[plate.guid] = plate
		end
		return;
	end

	local GUID = UnitGUID(unit)
	if not GUID then return; end

	if plate.guid ~= GUID then
		PlateGuidMap[GUID] = plate
		plate.guid = GUID
	end

	ns.CallBackUpateAuras(unit, GUID, plate) -- update auras 

	if UnitIsPlayer(unit) then
		NameGuidMap[plate.unitName] = plate.guid
	end
end

local function ClearGuid(plate, unit)
	if PlateGuidMap[plate.guid] == plate then
		PlateGuidMap[plate.guid] = nil;
	end
	plate.guid = nil
end

function ns.GetNameplateByGuid(GUID)
	if not GUID then return false; end
	return PlateGuidMap[GUID]
end
-----------------------------------------------------------------------------------
-- Nameplate OnScripts
-----------------------------------------------------------------------------------

local function Healthbar_OnValueChanged(plate)
	plate.Health:SetMinMaxValues(plate._Health:GetMinMaxValues())
	plate.Health:SetValue(plate._Health:GetValue()) 
end

local function Nameplate_OnShow(self)
	local plate = self.plate
	plate.isSmall = plate._Frame:GetScale() < .8
	local scale = plate.isSmall and .6 or 1
	plate:SetSize(WIDTH*scale, TOTALHEIGHT*scale)

	plate.Health:ClearAllPoints()
	plate.Health:SetPoint("TOP", plate)
	plate.Health:SetPoint("LEFT", plate)
	plate.Health:SetPoint("RIGHT", plate)
	plate.Health:SetHeight(HEIGHT*scale)

	plate:UpdateName()
	plate:SetGuid() -- Try at least

	self.elapsed = SHORTUPDATE;
	self.elapsedLong = LONGUPDATE;
	plate.lastthreat = 5;
	plate:Show()
end

local function Nameplate_OnHide(self)
	local plate = self.plate
	plate:Hide()
	plate:SetFrameLevel(0)
	plate:ClearGuid()
	plate.highlighted = nil;
	plate.target = nil;
	plate.Health.doNotOverride = nil;
	plate.Glow:Hide()
	plate.Highlight:Hide()
end

local function NameplateCastbar_OnValueChanged(Castbar, curTime)
	if Castbar.Shield:IsShown() then
		Castbar.Border:SetAlpha(1)
		Castbar.Border:Show()
		Castbar.Shield:SetVertexColor(1, .9, 0)
	end
	Castbar.Border:SetVertexColor(r, g, b, 1)
end

local function NameplateCastbar_OnShow(Castbar)
	local plate = Castbar:GetParent()
	local scale = plate.isSmall and .6 or 1

	Castbar:ClearAllPoints()
	Castbar:SetPoint("BOTTOM", plate)
	Castbar:SetPoint("LEFT", plate)
	Castbar:SetPoint("RIGHT", plate)
	Castbar:SetHeight(CBHEIGHT*scale)

	local r,g,b = unpack(cfg.Colors.Frame)
	Castbar.Border:SetVertexColor(r, g, b, 1)
	
	if Castbar.Shield:IsShown() then
		Castbar.IconBorder:SetTexture(cfg.IconTextures.White)
		Castbar.IconBorder:SetVertexColor(unpack(cfg.Colors.Interrupt))
	else
		Castbar.IconBorder:SetTexture(cfg.IconTextures.Normal)
		Castbar.IconBorder:SetVertexColor(unpack(cfg.Colors.Border))
	end
end

--  [[  OnUpdate Function  ]]  --
local function Nameplate_OnUpdate(self, elapsed)
	self.elapsed = elapsed + self.elapsed;
	self.elapsedLong = elapsed + self.elapsedLong;
	local plate = self.plate

	-- Update Alpha
	plate.alpha = self:GetAlpha()
	if PlateIsTarget(self) or (plate.Castbar and plate.Castbar:IsShown()) then
		plate.alpha = 1
	elseif UnitExists("target") then
		plate.alpha = MINALPHA
	else
		plate.alpha = 1
	end
	if plate.alpha ~= plate.lastAlpha then
		local change = plate.alpha - plate.lastAlpha
		local time = .5 * change
		if 0 < change then
			ns.UIFrameFadeIn(plate, time, plate.lastAlpha, plate.alpha)
		else
			ns.UIFrameFadeOut(plate, -time, plate.lastAlpha, plate.alpha)
		end
		plate.lastAlpha = plate.alpha
	end

	-- Mouseover / target
	if plate._Highlight:IsShown() then
		if not plate.highlighted then
			plate.highlighted = true;
			plate.Highlight:Show();
			plate:SetGuid('mouseover'); -- It's moused over, lets grab it while its hot
		end
	elseif plate.highlighted then
		plate.highlighted = nil;
		plate.Highlight:Hide();
	end

	if PlateIsTarget(self) then
		if not plate.target then
			plate.target = true;
			plate:SetGuid('target');
			plate:SetFrameLevel(5);
			plate.Glow:Show()
		end
	elseif plate.target then
		plate.target = nil;
		plate:SetFrameLevel(0);
		plate.Glow:Hide()
	end

	-- Short Updates
	if self.elapsed > SHORTUPDATE then
		self.elapsed = 0;

		-- Threat
		plate:UpdateThreat()
	-- Long Updates
	elseif self.elapsedLong > LONGUPDATE then
		self.elapsedLong = 0;
		plate.canHaveThreat = CanHaveThreat(plate._Health:GetStatusBarColor())

		plate:UpdateHealthColor()
		plate:UpdateName()
		Healthbar_OnValueChanged(plate)
	end
end

-----------------------------------------------------------------------------------
-- Nameplate Init
-----------------------------------------------------------------------------------

local function InitNameplate(self)
	-- Main frame
	local Frame, Nameframe = self:GetChildren()
	local Health, Castbar = Frame:GetChildren()
	local Name = Nameframe:GetRegions()
	local Threat, Border, Highlight, Level, Boss, Raid, Dragon = Frame:GetRegions()
	local cTexture, cBorder, cShield, cIcon, cName, cNameshadow = Castbar:GetRegions()
	local IconLayer, IconSublevel = cIcon:GetDrawLayer()

	-- Setup the plate
	local plate = self.plate
	plate:SetSize(WIDTH, TOTALHEIGHT)
	plate:SetFrameLevel(0)
	plate:SetFrameStrata("BACKGROUND")

	--local HIV = self:CreateTexture('BACKGROUND')
	--HIV:SetTexture(.8, .5, 0, .4)
	--HIV:SetAllPoints(plate)

	--local AIDS = plate:CreateTexture('BACKGROUND')
	--AIDS:SetTexture(.8, .5, .8, .4)
	--AIDS:SetAllPoints(plate)

	-- Stuff we will use, _ means used but not shown.
	plate._Frame = Frame
	plate._Health = Health
	plate._Highlight = Highlight
	plate._Threat = Threat
	plate.Castbar = Castbar
	plate.Castbar.Texture = cTexture
	plate.Castbar.Border = cBorder
	plate.Castbar.Name = cName
	plate.Castbar.Icon = cIcon
	plate.Castbar.Shield = cShield
	plate.Raid = Raid
	plate._Boss = Boss
	plate._Dragon = Dragon
	plate._Level = Level
	plate._Name = Name

	-- functions
	plate.UpdateName = UpdateName
	plate.UpdateHealthColor = UpdateHealthColor
	plate.ShowTotemIcon = ShowTotemIcon
	plate.UpdateThreat = UpdateThreat
	plate.SetGuid = SetGuid
	plate.ClearGuid = ClearGuid

	-- Hiding:
	HideIt(Level)
	HideIt(Nameframe)
	HideIt(Health)
	--Health:SetStatusBarTexture(nil)
	Border:SetTexture(nil)
	--cNameshadow:SetTexture(nil)
	Boss:SetTexture(nil)
	Dragon:SetTexture(nil)
	Threat:SetTexture(nil)

	-- Healthbar
	plate.Health = CreateFrame("Statusbar", nil, plate)
    plate.Health:SetStatusBarTexture(StatusbarTex, "BACKGROUND", 1)
    plate._Health:HookScript("OnValueChanged", function() Healthbar_OnValueChanged(plate) end)

	plate.Health:SetBackdrop(Backdrop)
	plate.Health:SetBackdropColor(0, 0, 0, .5)
	-- 		Border
	plate.Border = plate.Health:CreateTexture(nil, "BACKGROUND", nil, 3)
	plate.Border:SetTexture(BorderTex)
	plate.Border:SetTexCoord(unpack(TexCoord))
	plate.Border:SetPoint('TOPLEFT', plate.Health, -4, 6)
	plate.Border:SetPoint('BOTTOMRIGHT', plate.Health, 4, -6)
	plate.Border:SetVertexColor(unpack(cfg.Colors.Frame))

	-- Highlight
	plate.Highlight = plate.Health:CreateTexture(nil, "BACKGROUND", nil, 2)
	plate.Highlight:SetTexture(HighlightTex)
	plate.Highlight:SetAllPoints(plate.Health)
	plate.Highlight:SetVertexColor(1, 1, 1)
	plate.Highlight:SetBlendMode("ADD")
	plate.Highlight:SetTexCoord(unpack(HiTexCoord))
	plate.Highlight:Hide()

	-- Threat
	plate.Threat = plate.Health:CreateTexture(nil, "BACKGROUND", 4)
	plate.Threat:SetTexture(BorderTexGlow)
	plate.Threat:SetTexCoord(unpack(GlowTexCoord))
	plate.Threat:SetPoint('TOPLEFT', plate.Border, -7, 15)
	plate.Threat:SetPoint('BOTTOMRIGHT', plate.Border, 7, -15)
	plate.Threat:SetVertexColor(unpack(ThreatColors[2]))
	plate.Threat:SetAlpha(.7)
	plate.Threat:Hide()

	-- Target Marker
	plate.Glow = plate.Health:CreateTexture(nil, "BORDER")
	plate.Glow:SetTexture(MarkTex)
	plate.Glow:SetTexCoord(unpack(TexCoord))
	plate.Glow:SetAllPoints(plate.Border)
	plate.Glow:SetBlendMode("ADD")
	plate.Glow:SetVertexColor(.8, .8, 1, .5)
	plate.Glow:Hide()

	-- Castbar
	plate.Castbar:SetParent(plate)
	plate.Castbar:SetStatusBarTexture(StatusbarTex)
	plate.Castbar:SetFrameLevel(plate.Castbar:GetFrameLevel())
	plate.Castbar:SetBackdrop(Backdrop)
	plate.Castbar:SetBackdropColor(0, 0, 0, .5)
	plate.Castbar:ClearAllPoints() -- We set points in onshow
	plate.Castbar.Texture:SetDrawLayer("BACKGROUND", 1)
	--		Border
	plate.Castbar.Border:SetTexCoord(unpack(CbTexCoord))
    plate.Castbar.Border:SetDrawLayer('BACKGROUND', 2)
	plate.Castbar.Border:SetTexture(BorderTex)
	plate.Castbar.Border:ClearAllPoints()
	plate.Castbar.Border:SetPoint('TOPLEFT', plate.Castbar, -4, 6)
	plate.Castbar.Border:SetPoint('BOTTOMRIGHT', plate.Castbar, 4, -6)
	plate.Castbar.Border:SetVertexColor(unpack(cfg.Colors.Frame))
	plate.Castbar.Border:Show()
	--		Shield
	plate.Castbar.Shield:SetParent(plate.Castbar)
	plate.Castbar.Shield:SetTexture(MarkTex)
	plate.Castbar.Shield:SetTexCoord(unpack(CbTexCoord))
	plate.Castbar.Shield:SetAllPoints(plate.Castbar.Border)
	plate.Castbar.Shield:SetBlendMode("ADD")
	plate.Castbar.Shield:SetVertexColor(1, .9, 0)
	-- 		Name
	plate.Castbar.Name:ClearAllPoints()
	plate.Castbar.Name:SetPoint("BOTTOM", plate.Castbar, 0, -5)
	plate.Castbar.Name:SetPoint("LEFT", plate.Castbar, 5, 0)
	plate.Castbar.Name:SetPoint("RIGHT", plate.Castbar, -5, 0)
	plate.Castbar.Name:SetFont(FONT, FONTSIZE, "THINOUTLINE")
	plate.Castbar.Name:SetShadowColor(0, 0, 0, 0)
	--		Icon
	plate.Castbar.Icon:SetTexCoord(.1, .9, .1, .9)
	plate.Castbar.Icon:SetSize(25, 25)
	plate.Castbar.Icon:SetParent(plate.Castbar)
	plate.Castbar.Icon:ClearAllPoints()
	plate.Castbar.Icon:SetPoint("TOPRIGHT", plate, "TOPLEFT", -GAP, 0)
	plate.Castbar.IconBorder = plate.Castbar:CreateTexture(nil, IconLayer, nil, IconSublevel+1)
	plate.Castbar.IconBorder:SetTexture(cfg.IconTextures.White)
	plate.Castbar.IconBorder:SetPoint("TOPRIGHT", plate.Castbar.Icon, 2, 2)
	plate.Castbar.IconBorder:SetPoint("BOTTOMLEFT", plate.Castbar.Icon, -2, -2)

	-- Name
	plate.Name = plate.Health:CreateFontString(nil, "BORDER", 5)
	plate.Name:SetPoint("BOTTOM", plate, "TOP", 0, 4)
	plate.Name:SetPoint("LEFT", plate, -5, 0)
	plate.Name:SetPoint("RIGHT", plate, 5, 0)
	plate.Name:SetFont(FONT, FONTSIZE, "THINOUTLINE")

	-- RaidIcon
	plate.Raid:SetParent(plate)
	plate.Raid:ClearAllPoints()
	plate.Raid:SetSize(RAIDSIZE, RAIDSIZE)
	plate.Raid:SetPoint("BOTTOM", plate.Name, "TOP", 0, 0)

	ns.CreateAuraFrame(self)

	plate.lastAlpha = 0; -- Need this here, frame outside screen calls onshow again. For fading

	self:HookScript("OnShow", Nameplate_OnShow)
	self:HookScript("OnHide", Nameplate_OnHide)
	if self:IsShown() then
		Nameplate_OnShow(self)
	else
		plate:Hide()
	end

	plate.Castbar:HookScript('OnShow', NameplateCastbar_OnShow)
	plate.Castbar:HookScript("OnValueChanged", NameplateCastbar_OnValueChanged)
	self:HookScript("OnUpdate", Nameplate_OnUpdate)
end


local numNamePlates
WorldFrame:HookScript("OnUpdate", function(self, elap)
	local numChildren = self:GetNumChildren()
	if numChildren == numNamePlates then return; end

	for _, obj in pairs({self:GetChildren()}) do
		if (not obj.plate) then
			local name = obj:GetName()
			if name and name:find("NamePlate") then
				
				local plate = CreateFrame("Frame", nil, WorldFrame)
				NamePlates[obj] = plate

				local mover = CreateFrame("Frame", nil, plate)
				mover:SetPoint('BOTTOMLEFT', WorldFrame)
				mover:SetPoint('TOPRIGHT', obj, 'CENTER')
				mover:SetScript("OnSizeChanged", function(self, width, height)
					plate:Hide()
					plate:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", width, height)
					plate:Show()
				end)

				obj.plate = plate
				InitNameplate(obj)
			end
		end
	end
end)

SetCVar("bloatnameplates", 1)
SetCVar("bloatthreat", 1)