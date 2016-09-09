local ADDON, ns = ...

local DriverFrame = CreateFrame('Frame', ADDON..'DriverFrame', UIParent)
local UnitFrameMixin = {}
local UnitBuffMixin = {}
_G[ADDON] = ns

local config = {
	Colors = {
		Frame 	= AbuGlobal.GlobalConfig.Colors.Frame,	
		Border   = AbuGlobal.GlobalConfig.Colors.Border,
		Interrupt = AbuGlobal.GlobalConfig.Colors.Interrupt,
	},

	IconTextures = {
		White = AbuGlobal.GlobalConfig.IconTextures.White,
		Normal = AbuGlobal.GlobalConfig.IconTextures.Normal,
		Shadow = AbuGlobal.GlobalConfig.IconTextures.Shadow,
	},

	-- Nameplates
	StatusbarTexture = AbuGlobal.GlobalConfig.Statusbar.Light,
	Font = AbuGlobal.GlobalConfig.Fonts.Normal,
	FontSize = 12,

	friendlyConfig = {
		useClassColors = true,
		displaySelectionHighlight = true,
		colorHealthBySelection = true,
		considerSelectionInCombatAsHostile = true,
		displayNameByPlayerNameRules = true,
		colorHealthByRaidIcon = true,
		displayName = true,
		filter = "NONE",

		castBarHeight = 8,
		healthBarHeight = 4*2,
	},

	enemyConfig = {
		useClassColors = true,
		displayAggroHighlight = true,
		displaySelectionHighlight = true,
		colorHealthBySelection = true,
		considerSelectionInCombatAsHostile = true,
		displayNameByPlayerNameRules = true,
		colorHealthByRaidIcon = true,
		displayName = true,
		tankBorderColor = true,

		castBarHeight = 8,
		healthBarHeight = 4*2,
		filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY",
	},

	playerConfig = {

		filter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY",
		useClassColors = true,
		hideCastbar = true,
		
	},
}
ns.config = config
ns.DriverFrame = DriverFrame
ns.UnitFrameMixin = UnitFrameMixin

local BorderTex = 'Interface\\AddOns\\AbuNameplates\\media\\Plate.blp'
local BorderTexGlow = 'Interface\\AddOns\\AbuNameplates\\media\\PlateGlow.blp'
local MarkTex = 'Interface\\AddOns\\AbuNameplates\\media\\Mark.blp'
local HighlightTex = 'Interface\\AddOns\\AbuNameplates\\media\\Highlight.blp'

local TexCoord 		= {24/256, 186/256, 35/128, 59/128}
local CbTexCoord 	= {24/256, 186/256, 59/128, 35/128}

local GlowTexCoord 	= {15/256, 195/256, 21/128, 73/128}
local CbGlowTexCoord= {15/256, 195/256, 73/128, 21/128}

local HiTexCoord 	= {5/128, 105/128, 20/32, 26/32}

local raidIconColor = {
	[1] = {r = 1.0,  g = 0.92, b = 0,     },
	[2] = {r = 0.98, g = 0.57, b = 0,     },
	[3] = {r = 0.83, g = 0.22, b = 0.9,   },
	[4] = {r = 0.04, g = 0.95, b = 0,     },
	[5] = {r = 0.7,  g = 0.82, b = 0.875, },
	[6] = {r = 0,    g = 0.71, b = 1,     },
	[7] = {r = 1.0,  g = 0.24, b = 0.168, },
	[8] = {r = 0.98, g = 0.98, b = 0.98,  },
}

local Backdrop = {
	bgFile = 'Interface\\Buttons\\WHITE8x8',
}

-------
--  DriverFrame
------

function DriverFrame:OnEvent(event, ...)
	if (event == 'ADDON_LOADED') then
		local addon_name = ...
		if (addon_name == ADDON) then
			self:OnLoad()
		end
	elseif (event == 'NAME_PLATE_CREATED') then
		local namePlateFrameBase = ...
		self:OnNamePlateCreated(namePlateFrameBase)
	elseif (event == 'NAME_PLATE_UNIT_ADDED') then
		local namePlateUnitToken = ...
		self:OnNamePlateAdded(namePlateUnitToken)
	elseif (event == 'NAME_PLATE_UNIT_REMOVED') then
		local namePlateUnitToken = ...
		self:OnNamePlateRemoved(namePlateUnitToken)
	elseif event == 'PLAYER_TARGET_CHANGED' then
		self:OnTargetChanged();
	elseif event == 'DISPLAY_SIZE_CHANGED' then -- resolution change
		self:UpdateNamePlateOptions();
	elseif event == "UNIT_AURA" then
		self:OnUnitAuraUpdate(...)
	elseif event == 'VARIABLES_LOADED' then
		self:DisableBlizzard()
		self:UpdateNamePlateOptions();
	elseif event == 'UPDATE_MOUSEOVER_UNIT' then
		self:UpdateMouseOver()
	elseif event == 'UNIT_FACTION' then
		self:OnUnitFactionChanged(...)
	end
end

DriverFrame:SetScript('OnEvent', DriverFrame.OnEvent)
DriverFrame:RegisterEvent'ADDON_LOADED'
DriverFrame:RegisterEvent'VARIABLES_LOADED'

function DriverFrame:DisableBlizzard()
	NamePlateDriverFrame:UnregisterAllEvents()
	NamePlateDriverFrame:Hide()
end

function DriverFrame:OnLoad()
	self:RegisterEvent'NAME_PLATE_CREATED'
	self:RegisterEvent'NAME_PLATE_UNIT_ADDED'
	self:RegisterEvent'NAME_PLATE_UNIT_REMOVED'

	self:RegisterEvent'PLAYER_TARGET_CHANGED'
	self:RegisterEvent'RAID_TARGET_UPDATE'

	self:RegisterEvent'CVAR_UPDATE'
	self:RegisterEvent'DISPLAY_SIZE_CHANGED' -- Resolution change

	self:RegisterEvent'UPDATE_MOUSEOVER_UNIT'
	self:RegisterEvent'UNIT_FACTION'

	--self:SetBaseNamePlateSize(110, 45)
end

function DriverFrame:UpdateNamePlateOptions()
	local baseNamePlateWidth = 110;
	local baseNamePlateHeight = 45;
	local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"));
	local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"));
	C_NamePlate.SetNamePlateOtherSize(baseNamePlateWidth * horizontalScale, baseNamePlateHeight);
	C_NamePlate.SetNamePlateSelfSize(baseNamePlateWidth, baseNamePlateHeight);


	for i, frame in ipairs(C_NamePlate.GetNamePlates()) do
		frame:ApplyFrameOptions(frame.namePlateUnitToken);
		CompactUnitFrame_UpdateAll(frame.UnitFrame);
	end
end

function DriverFrame:OnNamePlateCreated(nameplate)
	local f = CreateFrame('Button', nameplate:GetName()..'UnitFrame', nameplate)
	f:SetAllPoints(nameplate)
	f:Show()
	Mixin(f, UnitFrameMixin)
	f:Create(nameplate)
	f:EnableMouse(false)

	nameplate.UnitFrame = f
end

function DriverFrame:OnNamePlateAdded(namePlateUnitToken)
	local nameplate = C_NamePlate.GetNamePlateForUnit(namePlateUnitToken)
	nameplate.UnitFrame:ApplyFrameOptions(namePlateUnitToken)
	nameplate.UnitFrame:OnAdded(namePlateUnitToken)
	nameplate.UnitFrame:UpdateAllElements()
end

function DriverFrame:OnNamePlateRemoved(namePlateUnitToken)
	local nameplate = C_NamePlate.GetNamePlateForUnit(namePlateUnitToken)
	nameplate.UnitFrame:OnAdded(nil)
end

function DriverFrame:OnTargetChanged()
	--self:OnUnitAuraUpdate'target'
end

function DriverFrame:OnRaidTargetUpdate()
	for _, frame in pairs(C_NamePlate.GetNamePlates()) do
		frame.UnitFrame:UpdateRaidTarget()
		CompactUnitFrame_UpdateHealthColor(frame.UnitFrame)
	end
end

function DriverFrame:OnUnitFactionChanged(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit);
	if (nameplate) then
		CompactUnitFrame_UpdateName(nameplate.UnitFrame);
		CompactUnitFrame_UpdateHealthColor(nameplate.UnitFrame);
	end
end

local mouseoverframe -- if theres a better way im all ears
function DriverFrame:OnUpdate(elapsed) 
	local nameplate = C_NamePlate.GetNamePlateForUnit('mouseover')
	if not nameplate or nameplate ~= mouseoverframe then
		mouseoverframe.UnitFrame.hoverHighlight:Hide()
		mouseoverframe = nil
		self:SetScript('OnUpdate', nil)
	end
end

function DriverFrame:UpdateMouseOver()
	local nameplate = C_NamePlate.GetNamePlateForUnit('mouseover')

	if mouseoverframe == nameplate then
		return
	elseif mouseoverframe then
		mouseoverframe.UnitFrame.hoverHighlight:Hide()
		self:SetScript('OnUpdate', nil)
	end

	if nameplate then
		nameplate.UnitFrame.hoverHighlight:Show()
		mouseoverframe = nameplate
		self:SetScript('OnUpdate', self.OnUpdate) --onupdate until mouse leaves frame
	end
end

------------------------
--	Nameplate
------------------------

function UnitFrameMixin:Create(unitframe)
	-- Healthbar
	local h = CreateFrame('Statusbar', '$parentHealthBar', unitframe)
	self.healthBar = h
	h:SetFrameLevel(90)
    h:SetStatusBarTexture(config.StatusbarTexture, 'BACKGROUND', 1)
	h:SetBackdrop(Backdrop)
	h:SetBackdropColor(0, 0, 0, .8)

	-- 	Healthbar textures --blizzard capital letters policy
	self.myHealPrediction = h:CreateTexture(nil, 'BORDER', nil, 5)
	self.myHealPrediction:SetVertexColor(0.0, 0.659, 0.608)
	self.myHealPrediction:SetTexture[[Interface/TargetingFrame/UI-TargetingFrame-BarFill]]

	self.otherHealPrediction = h:CreateTexture(nil, 'ARTWORK', nil, 5)
	self.otherHealPrediction:SetVertexColor(0.0, 0.659, 0.608)
	self.otherHealPrediction:SetTexture[[Interface/TargetingFrame/UI-TargetingFrame-BarFill]]

	self.totalAbsorb = h:CreateTexture(nil, 'ARTWORK', nil, 5)
	self.totalAbsorb:SetTexture[[Interface\RaidFrame\Shield-Fill]]
	--
	self.totalAbsorbOverlay = h:CreateTexture(nil, 'BORDER', nil, 6)
	self.totalAbsorbOverlay:SetTexture([[Interface\RaidFrame\Shield-Overlay]], true, true);	--Tile both vertically and horizontally
	self.totalAbsorbOverlay:SetAllPoints(self.totalAbsorb);
	self.totalAbsorbOverlay.tileSize = 20;
	--
	self.myHealAbsorb = h:CreateTexture(nil, 'ARTWORK', nil, 1)
	self.myHealAbsorb:SetTexture([[Interface\RaidFrame\Absorb-Fill]], true, true)

	self.myHealAbsorbLeftShadow = h:CreateTexture(nil, 'ARTWORK', nil, 1)
	self.myHealAbsorbLeftShadow:SetTexture[[Interface\RaidFrame\Absorb-Edge]]

	self.myHealAbsorbRightShadow = h:CreateTexture(nil, 'ARTWORK', nil, 1)
	self.myHealAbsorbRightShadow:SetTexture[[Interface\RaidFrame\Absorb-Edge]]
	self.myHealAbsorbRightShadow:SetTexCoord(1, 0, 0, 1)
	--
	h.border = h:CreateTexture(nil, 'ARTWORK', nil, 2)
	h.border:SetTexture(BorderTex)
	h.border:SetTexCoord(unpack(TexCoord))
	h.border:SetPoint('TOPLEFT', h, -4, 6)
	h.border:SetPoint('BOTTOMRIGHT', h, 4, -6)
	h.border:SetVertexColor(unpack(config.Colors.Frame))
	--
	self.overAbsorbGlow = h:CreateTexture(nil, 'ARTWORK', nil, 3)
	self.overAbsorbGlow:SetTexture[[Interface\RaidFrame\Shield-Overshield]]
	self.overAbsorbGlow:SetBlendMode'ADD'
	self.overAbsorbGlow:SetPoint('BOTTOMLEFT', h, 'BOTTOMRIGHT', -4, -1)
	self.overAbsorbGlow:SetPoint('TOPLEFT', h, 'TOPRIGHT', -4, 1)
	self.overAbsorbGlow:SetWidth(8);

	self.overHealAbsorbGlow = h:CreateTexture(nil, 'ARTWORK', nil, 3)
	self.overHealAbsorbGlow:SetTexture[[Interface\RaidFrame\Absorb-Overabsorb]]
	self.overHealAbsorbGlow:SetBlendMode'ADD'
	self.overHealAbsorbGlow:SetPoint('BOTTOMRIGHT', h, 'BOTTOMLEFT', 2, -1)
	self.overHealAbsorbGlow:SetPoint('TOPRIGHT', h, 'TOPLEFT', 2, 1)
	self.overHealAbsorbGlow:SetWidth(8);

	-- Castbar
	local c = CreateFrame('StatusBar', '$parentCastBar', nameplate)
	do
		self.castBar = c
		c:SetFrameLevel(100)
		c:Hide()
		c:SetStatusBarTexture(config.StatusbarTexture, 'BACKGROUND', 1)
		c:SetBackdrop(Backdrop)
		c:SetBackdropColor(0, 0, 0, .5)

		--		Castbar textures
		c.border = c:CreateTexture(nil, 'ARTWORK', nil, 0)
		c.border:SetTexCoord(unpack(CbTexCoord))
		c.border:SetTexture(BorderTex)
		c.border:SetPoint('TOPLEFT', c, -4, 6)
		c.border:SetPoint('BOTTOMRIGHT', c, 4, -6)
		c.border:SetVertexColor(unpack(config.Colors.Frame))

		c.BorderShield = c:CreateTexture(nil, 'ARTWORK', nil, 1)
		c.BorderShield:SetTexture(MarkTex)
		c.BorderShield:SetTexCoord(unpack(CbTexCoord))
		c.BorderShield:SetAllPoints(c.border)
		c.BorderShield:SetBlendMode'ADD'
		c.BorderShield:SetVertexColor(1, .9, 0, 0.7)
		--CastingBarFrame_AddWidgetForFade(frame.castBar, c.BorderShield)

		c.Text = c:CreateFontString(nil, 'OVERLAY', nil, 1)
		c.Text:SetPoint('CENTER', c, 0, 0)
		c.Text:SetPoint('LEFT', c, 0, 0)
		c.Text:SetPoint('RIGHT', c, 0, 0)
		c.Text:SetFont(config.Font, config.FontSize, 'THINOUTLINE')
		c.Text:SetShadowColor(0, 0, 0, 0)

		c.Icon = c:CreateTexture(nil, 'OVERLAY', nil, 1)
		c.Icon:SetTexCoord(.1, .9, .1, .9)
		c.Icon:SetPoint('BOTTOMRIGHT', c, 'BOTTOMLEFT', -7, 0)
		c.Icon:SetPoint('TOPRIGHT', h, 'TOPLEFT', -7, 0)
		--CastingBarFrame_AddWidgetForFade(c, c.Icon)

		c.IconBorder = c:CreateTexture(nil, 'OVERLAY', nil, 2)
		c.IconBorder:SetTexture(config.IconTextures.White)
		c.IconBorder:SetPoint('TOPRIGHT', c.Icon, 2, 2)
		c.IconBorder:SetPoint('BOTTOMLEFT', c.Icon, -2, -2)
		--CastingBarFrame_AddWidgetForFade(c, c.IconBorder)

		c.Spark = c:CreateTexture(nil, 'OVERLAY', nil, 2)
		c.Spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
		c.Spark:SetBlendMode'ADD'
		c.Spark:SetSize(16,16)
		c.Spark:SetPoint('CENTER', c, 0, 0)

		c.Flash = c:CreateTexture(nil, 'OVERLAY', nil, 2)
		c.Flash:SetTexture(config.StatusbarTexture)
		c.Flash:SetBlendMode'ADD'

		c:SetScript('OnEvent', CastingBarFrame_OnEvent)
		c:SetScript('OnUpdate',CastingBarFrame_OnUpdate)
		c:SetScript('OnShow', CastingBarFrame_OnShow)
		CastingBarFrame_OnLoad(c, nil, false, true);
		--CastingBarFrame_SetNonInterruptibleCastColor(c, 0.7, 0.7, 0.7)
	end

	-- Misc
	self.classificationIndicator = h:CreateTexture(nil, 'OVERLAY', nil)
	self.classificationIndicator:SetSize(14,13)
	self.classificationIndicator:SetPoint('RIGHT', h, 'LEFT', 0, 0)

	self.raidTargetIcon = h:CreateTexture(nil, 'OVERLAY', nil)
	self.raidTargetIcon:SetSize(12,12)
	self.raidTargetIcon:SetPoint('RIGHT', h, 'LEFT', -15, 0)
	self.raidTargetIcon:SetTexture[[Interface\TargetingFrame\UI-RaidTargetingIcons]]

	self.name = h:CreateFontString(nil, 'ARTWORK', 5)
	self.name:SetPoint('BOTTOM', h, 'TOP', 0, 4)
	self.name:SetWordWrap(false)
	self.name:SetJustifyH'CENTER'
	self.name:SetFont(config.Font, config.FontSize, 'THINOUTLINE')

	self.aggroHighlight = h:CreateTexture(nil, 'BORDER', nil, 4)
	self.aggroHighlight:SetTexture(BorderTexGlow)
	self.aggroHighlight:SetTexCoord(unpack(GlowTexCoord))
	self.aggroHighlight:SetPoint('TOPLEFT', h.border, -7, 15)
	self.aggroHighlight:SetPoint('BOTTOMRIGHT', h.border, 7, -15)
	self.aggroHighlight:SetAlpha(.7)
	self.aggroHighlight:Hide()

	self.hoverHighlight = h:CreateTexture(nil, 'ARTWORK', nil, 1)
	self.hoverHighlight:SetTexture(HighlightTex)
	self.hoverHighlight:SetAllPoints(h)
	self.hoverHighlight:SetVertexColor(1, 1, 1)
	self.hoverHighlight:SetBlendMode('ADD')
	self.hoverHighlight:SetTexCoord(unpack(HiTexCoord))
	self.hoverHighlight:Hide()

	self.selectionHighlight = h:CreateTexture(nil, 'ARTWORK', nil, 4)
	self.selectionHighlight:SetTexture(MarkTex)
	self.selectionHighlight:SetTexCoord(unpack(TexCoord))
	self.selectionHighlight:SetAllPoints(h.border)
	self.selectionHighlight:SetBlendMode('ADD')
	self.selectionHighlight:SetVertexColor(.8, .8, 1, .7)
	self.selectionHighlight:Hide()

	self.BuffFrame = CreateFrame('StatusBar', '$parentBuffFrame', self, 'HorizontalLayoutFrame')
	Mixin(self.BuffFrame, NameplateBuffContainerMixin)
	self.BuffFrame:SetPoint('LEFT', self.healthBar, -1, 0)
	self.BuffFrame.spacing = 4
	self.BuffFrame.fixedHeight = 14
	self.BuffFrame:SetScript('OnEvent', self.BuffFrame.OnEvent)
	self.BuffFrame:SetScript('OnUpdate', self.BuffFrame.OnUpdate)
	self.BuffFrame:OnLoad()

	-- Quest
	self.questIcon = f:CreateTexture(nil, nil, nil, 0)
	self.questIcon:SetSize(28, 22)
	self.questIcon:SetTexture('Interface/QuestFrame/AutoQuest-Parts')
	self.questIcon:SetTexCoord(0.30273438, 0.41992188, 0.015625, 0.953125)
	self.questIcon:SetPoint('LEFT', h, 'RIGHT', 4, 0)

	self.questText = plate:CreateFontString(nil, nil, "SystemFont_Outline_Small")
	self.questText:SetPoint('CENTER', icon, 1, 1)
	self.questText:SetShadowOffset(1, -1)
	self.questText:SetTextColor(1,.82,0)
end

function UnitFrameMixin:ApplyFrameOptions(namePlateUnitToken)
	if UnitIsUnit('player', namePlateUnitToken) then
		self.optionTable = config.playerConfig
		self.healthBar:SetPoint('LEFT', self, 'LEFT', 12, 5);
		self.healthBar:SetPoint('RIGHT', self, 'RIGHT', -12, 5);
	else

		if UnitIsFriend('player', namePlateUnitToken) then
			self.optionTable = config.friendlyConfig
		else
			self.optionTable = config.enemyConfig
		end

		self.castBar:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 12, 6);
		self.castBar:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -12, 6);
		self.castBar:SetHeight(self.optionTable.castBarHeight);
		self.castBar.Icon:SetWidth(self.optionTable.castBarHeight + self.optionTable.healthBarHeight + 6)
	
		self.healthBar:SetPoint('BOTTOMLEFT', self.castBar, 'TOPLEFT', 0, 6);
		self.healthBar:SetPoint('BOTTOMRIGHT', self.castBar, 'TOPRIGHT', 0, 6);
		self.healthBar:SetHeight(self.optionTable.healthBarHeight);
	end
end

function UnitFrameMixin:OnAdded(namePlateUnitToken)
	self.unit = namePlateUnitToken
	self.displayedUnit = namePlateUnitToken
	self.inVehicle = false;
	
	if namePlateUnitToken then 
		self:RegisterEvents()
	else
		self:UnregisterEvents()
	end

	if self.castBar then
		if namePlateUnitToken and (not self.optionTable.hideCastbar) then
			CastingBarFrame_SetUnit(self.castBar, namePlateUnitToken, false, true);
		else
			CastingBarFrame_SetUnit(self.castBar, nil, nil, nil);
		end
	end
end

function UnitFrameMixin:RegisterEvents()
	self:RegisterEvent'UNIT_NAME_UPDATE'
	self:RegisterEvent'PLAYER_ENTERING_WORLD'
	self:RegisterEvent'PLAYER_TARGET_CHANGED'
	self:RegisterEvent'UNIT_PET'
	self:RegisterEvent'UNIT_ENTERED_VEHICLE'
	self:RegisterEvent'UNIT_EXITED_VEHICLE'

	if ( UnitIsUnit('player', self.unit) ) then
		self:RegisterUnitEvent('UNIT_DISPLAYPOWER', 'player');
		self:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player');
		self:RegisterUnitEvent('UNIT_MAXPOWER', 'player');
	end
	self:UpdateUnitEvents();
	self:SetScript('OnEvent', self.OnEvent);
end

function UnitFrameMixin:UpdateUnitEvents()
	local unit = self.unit;
	local displayedUnit;
	if ( unit ~= self.displayedUnit ) then
		displayedUnit = self.displayedUnit;
	end
	self:RegisterUnitEvent('UNIT_MAXHEALTH', unit, displayedUnit);
	self:RegisterUnitEvent('UNIT_HEALTH', unit, displayedUnit);
	self:RegisterUnitEvent('UNIT_HEALTH_FREQUENT', unit, displayedUnit);

	self:RegisterUnitEvent('UNIT_AURA', unit, displayedUnit);
	self:RegisterUnitEvent('UNIT_THREAT_SITUATION_UPDATE', unit, displayedUnit);
	self:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', unit, displayedUnit);
	self:RegisterUnitEvent('UNIT_HEAL_PREDICTION', unit, displayedUnit);
end

function UnitFrameMixin:UnregisterEvents()
	self:SetScript('OnEvent', nil)
end


function UnitFrameMixin:UpdateAllElements()
	self:UpdateInVehicle()

	if UnitExists(self.displayedUnit) then
		CompactUnitFrame_UpdateSelectionHighlight(self)
		CompactUnitFrame_UpdateMaxHealth(self) 
		CompactUnitFrame_UpdateHealth(self)
		CompactUnitFrame_UpdateHealPrediction(self)
		CompactUnitFrame_UpdateClassificationIndicator(self)
		self:UpdateRaidTarget()
		CompactUnitFrame_UpdateHealthColor(self)
		CompactUnitFrame_UpdateName(self);
		self:UpdateThreat()
		self:OnUnitAuraUpdate()
	end
end

function UnitFrameMixin:OnEvent(event, ...)
	local arg1, arg2, arg3, arg4 = ...
	if ( event == 'PLAYER_TARGET_CHANGED' ) then
		CompactUnitFrame_UpdateSelectionHighlight(self);
		CompactUnitFrame_UpdateName(self);
		--CompactUnitFrame_UpdateHealthBorder(self);
	elseif ( event == 'PLAYER_REGEN_ENABLED' or event == 'PLAYER_REGEN_DISABLED' ) then
		--CompactUnitFrame_UpdateAuras(self);	--We filter differently based on whether the player is in Combat, so we need to update when that changes.
	elseif ( arg1 == self.unit or arg1 == self.displayedUnit ) then
		if ( event == 'UNIT_MAXHEALTH' ) then
			CompactUnitFrame_UpdateMaxHealth(self)
			CompactUnitFrame_UpdateHealth(self)
			CompactUnitFrame_UpdateHealPrediction(self)
		elseif ( event == 'UNIT_HEALTH' or event == 'UNIT_HEALTH_FREQUENT' ) then
			CompactUnitFrame_UpdateHealth(self)
			CompactUnitFrame_UpdateHealPrediction(self)
		elseif ( event == 'UNIT_NAME_UPDATE' ) then
			CompactUnitFrame_UpdateName(self)
			CompactUnitFrame_UpdateHealthColor(self)
		elseif ( event == 'UNIT_AURA' ) then
			self:OnUnitAuraUpdate()
		elseif ( event == 'UNIT_THREAT_SITUATION_UPDATE' ) then
			self:UpdateThreat()
			--CompactUnitFrame_UpdateHealthBorder(self)
		elseif ( event == 'UNIT_THREAT_LIST_UPDATE' ) then
			if ( self.optionTable.considerSelectionInCombatAsHostile ) then
				CompactUnitFrame_UpdateHealthColor(self)
				CompactUnitFrame_UpdateName(self)
			end
			self:UpdateThreat()
			--CompactUnitFrame_UpdateHealthBorder(self);
		elseif ( event == 'UNIT_HEAL_PREDICTION' or event == 'UNIT_ABSORB_AMOUNT_CHANGED' or event == 'UNIT_HEAL_ABSORB_AMOUNT_CHANGED' ) then
			CompactUnitFrame_UpdateHealPrediction(self)
		elseif ( event == 'UNIT_ENTERED_VEHICLE' or event == 'UNIT_EXITED_VEHICLE' or event == 'UNIT_PET' ) then
			self:UpdateAllElements()
		end

	elseif ( event == 'UNIT_DISPLAYPOWER' ) then
	elseif ( event == 'UNIT_POWER_FREQUENT' ) then
	elseif ( event == 'UNIT_MAXPOWER' ) then
	end
end

function UnitFrameMixin:UpdateInVehicle()
	if ( UnitHasVehicleUI(self.unit) ) then
		if ( not self.inVehicle ) then
			self.inVehicle = true
			local prefix, id, suffix = string.match(self.unit, '([^%d]+)([%d]*)(.*)')
			self.displayedUnit = prefix..'pet'..id..suffix
			self:UpdateUnitEvents()
		end
	else
		if ( self.inVehicle ) then
			self.inVehicle = false
			self.displayedUnit = self.unit
			self:UpdateUnitEvents()
		end
	end
end

function UnitFrameMixin:UpdateRaidTarget()
	local icon = self.raidTargetIcon;
	local index = GetRaidTargetIndex(self.unit)
	if ( index ) then
		SetRaidTargetIconTexture(icon, index);
		icon:Show();
		if self.optionTable.colorHealthByRaidIcon then
			self.optionTable.healthBarColorOverride = raidIconColor[index]
		end
	else
		self.optionTable.healthBarColorOverride = nil
		icon:Hide();
	end
end

local function IsPlayerEffectivelyTank()
	local assignedRole = UnitGroupRolesAssigned("player");
	if ( assignedRole == "NONE" ) then
		local spec = GetSpecialization();
		return spec and GetSpecializationRole(spec) == "TANK";
	end

	return assignedRole == "TANK";
end

function UnitFrameMixin:UpdateThreat()
	local tex = self.aggroHighlight
	if not self.optionTable.tankBorderColor then
		tex:Hide() 
		return
	end

	local isTanking, status = UnitDetailedThreatSituation('player', self.displayedUnit)
	if status ~= nil then
		if IsPlayerEffectivelyTank() then
			status = math.abs(status - 3)
		end
		if status > 0 then
			tex:SetVertexColor(GetThreatStatusColor(status))
			if not tex:IsShown() then 
				tex:Show()
			end
			return
		end
	end
	tex:Hide() 
end

local questtip = CreateFrame("GameTooltip", "AbuQuestCheckTip", nil, "GameTooltipTemplate")
local questtipLine = setmetatable({}, { __index = function(k, i)
	local line = _G["AbuQuestCheckTipTextLeft" .. i]
	if line then rawset(k, i, line) end
	return line
end })

function UnitFrameMixin:UpdateQuestVisuals()

end

function UnitFrameMixin:OnUnitAuraUpdate()
--	print(self:GetName(), self.optionTable.filter)
	self.BuffFrame:UpdateBuffs(self.displayedUnit, self.optionTable.filter)
end