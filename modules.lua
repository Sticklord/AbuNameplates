local _, ns = ...
local cfg = ns.Config
local BUTTON_WIDTH, BUTTON_HEIGHT = 25, 25
local BUTTON_GAP = 3
local IconTexture = cfg.IconTextures
local FONT, FONTSIZE = cfg.Fonts.Normal, 12

local lists = cfg.AuraList
local BlackListMine = {}
local WhiteListAll = {}

----------- [[	Update 			  	]]  --------------------
local function UpdatePlayerData(e)
	local level = UnitLevel("player");
	if level then
		ns.PlayerLevel = level;
	end
	local GUID = UnitGUID("player")
	if GUID then
		ns.PlayerGUID = GUID
	end
	local spec = GetSpecialization()
	ns.PlayerIsTankSpec = spec and (GetSpecializationRole(spec) == "TANK") or false;
end

ns.RegisterEvent("PLAYER_LOGIN", UpdatePlayerData)
ns.RegisterEvent("PLAYER_TALENT_UPDATE", UpdatePlayerData)
ns.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", UpdatePlayerData)

local function UpdateAuras(e)
	local _, class = UnitClass("player")

	wipe(BlackListMine)
	for id, v in pairs(lists.BLACKLIST[class]) do
		BlackListMine[id] = true
	end

	for id, v in pairs(lists.ALL) do
		WhiteListAll[id] = true
	end
end
ns.RegisterEvent("PLAYER_ENTERING_WORLD", UpdateAuras)

----------- [[	Auras on nameplate sometimes ]]  --------------------
--[===============[
	TODO
		Bind auras to guid instead of Auras or transfer them some way, if possible
		Add filter 
--]===============]

local AuraDurationCache = {}
local AuraLists = {}
local ShowEvents = {
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_APPLIED_DOSE"] = true,
	["SPELL_AURA_REMOVED_DOSE"] = true,
}
local HideEvents = {
	["SPELL_AURA_BROKEN"] = true,
	["SPELL_AURA_BROKEN_SPELL"] = true,
	["SPELL_AURA_REMOVED"] = true,
}

local SecondsToTimeAbbrev, 		GetSpellTexture,	GetTime,    UnitGUID,  	 UnitIsFriend
	= _G.SecondsToTimeAbbrev, _G.GetSpellTexture, _G.GetTime, _G.UnitGUID, _G.UnitIsFriend
	

local function UpdateButtonPositions(self)
	local prev = nil;
	for i = 1, #self.Buttons do 
		local b = self.Buttons[i]
		if b:IsShown() then
			b:ClearAllPoints()
			if prev then
				b:SetPoint("TOPLEFT", prev, "TOPRIGHT", BUTTON_GAP, 0)
			else
				b:SetPoint("BOTTOMLEFT")
			end
			prev = b
		end
	end
	if prev then 
		self:Show()
	else
		self:Hide()
	end
end

local function Button_OnShow(self)
	self:GetParent():UpdateButtonPositions()
end

local function Button_OnHide(self)
	local Auras = self:GetParent()

	if Auras.SpellIDs[self.spellID] == self then
		Auras.SpellIDs[self.spellID] = nil
	end

	self.spellID = nil
	Auras:UpdateButtonPositions()
end

local function Button_OnUpdate(self, e)
	self.elapsed = self.elapsed - e
	if self.elapsed <= 0 then
		local timeLeft = self.expiration - GetTime()

		if timeLeft < 0 then -- Should have ran out
			self.Duration:SetText('')
			self:SetScript("OnUpdate", nil)
		else
			self.Duration:SetFormattedText(SecondsToTimeAbbrev(timeLeft))
		end
		self.elapsed = .49
	end
end

-- Create Button
local function CreateAuraButton(self)
	local b = CreateFrame('Button', nil, self)
	b:Hide()
	b:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)

	b.Icon = b:CreateTexture(nil, "BACKGROUND")
	b.Icon:SetTexCoord(.05, .95, .05, .95)
	b.Icon:SetPoint("TOPRIGHT", -1, -1)
	b.Icon:SetPoint("BOTTOMLEFT", 1, 1)

	b.Border = b:CreateTexture(nil, 'BORDER')
	b.Border:SetPoint('TOPRIGHT', b, 1, 1)
	b.Border:SetPoint('BOTTOMLEFT', b, -1, -1)
	b.Border:SetTexture(IconTexture['Normal'])
	b.Border:SetVertexColor(unpack(cfg.Colors['Border']))

	b.Shadow = b:CreateTexture(nil, 'BACKGROUND')
	b.Shadow:SetTexture(IconTexture['Shadow'])
	b.Shadow:SetPoint('TOPRIGHT', b.Border, 3, 3)
	b.Shadow:SetPoint('BOTTOMLEFT', b.Border, -3, -3)
	b.Shadow:SetVertexColor(0, 0, 0, 1)

	b.Duration = b:CreateFontString(nil, 'OVERLAY')
	b.Duration:SetFont(FONT, FONTSIZE, "THINOUTLINE")
	b.Duration:SetJustifyH("CENTER")
	b.Duration:SetPoint('TOP', 1, 3)
	b.Duration:SetTextColor(.85, .89, .25)

	b.Count = b:CreateFontString(nil, 'OVERLAY')
	b.Count:SetPoint('BOTTOMRIGHT', 1, 1)
	b.Count:SetFont(FONT, FONTSIZE, "THINOUTLINE")
	b.Count:SetTextColor(.85, .89, .25)
	b.Count:SetPoint("BOTTOM", b, "BOTTOM", 1, -3)

	b:SetScript("OnHide", Button_OnHide)
	b:SetScript("OnShow", Button_OnShow)
	table.insert(self.Buttons, b)
	return b
end

local function GetAuraButton(Auras, spellID, phony)
	if Auras.SpellIDs[spellID] then
		if (phony and not Auras.SpellIDs[spellID].phony) then return; end -- lets not overwrite
		return Auras.SpellIDs[spellID]
	end
	local numButtons = #Auras.Buttons

	for i = 1, numButtons do
		local b = Auras.Buttons[i]
		if (not b:IsShown()) then
			return b
		end
	end

	if numButtons >= Auras.MaxButtons then return; end
	local b = CreateAuraButton(Auras)
	Auras.SpellIDs[spellID] = b
	return b;
end

local function UpdateAuraButton(plate, spellID, texture, count, duration, expiration, phony)
	local button = GetAuraButton(plate.Auras, spellID, phony)
	if button then
		plate.Auras.SpellIDs[spellID] = button;
		button.Icon:SetTexture(texture)

		if count and count > 1 then
			button.Count:SetText(count)
			button.Count:Show()
		else
			button.Count:Hide()
		end

		if duration < .5 then
			button:SetScript("OnUpdate", nil)
			button.Duration:Hide()
		else
			button:SetScript("OnUpdate", Button_OnUpdate)
			button.Duration:Show()
		end

		button.duration = duration;
		button.expiration = expiration;
		button.spellID = spellID;
		button.elapsed = 0;
		button.phony = phony

		button:Show()
		plate.Auras:Show()
	end
end

local function HideAura(dstGUID, spellID, srcGUID)
	local plate = ns.GetNameplateByGuid(dstGUID);
	if (not plate) or (not plate.Auras) then return; end

	if plate.Auras.SpellIDs[spellID] then
		plate.Auras.SpellIDs[spellID]:Hide();
	end
end

local isPlayer = { player = true, pet = true, vehicle = true }

local function UpdateAuraByUnit(unit, dstGUID, plate) -- Good way
	dstGUID = dstGUID or UnitGUID(unit or "")
	local plate = plate or ns.GetNameplateByGuid(dstGUID)
	if (not plate) or (not plate.Auras) then return; end
	local filter = UnitIsFriend(unit, 'player') and "HELPFUL" or "HARMFUL"
	for i = 1, 40 do
		local name, _, texture, count, dispelType, duration, expire, caster, _, _, spellID = UnitAura(unit, i, filter)

		if not spellID then break; end
		if (isPlayer[caster] and not BlackListMine[spellID]) or (WhiteListAll[spellID]) then
			if AuraDurationCache[spellID] then
				if AuraDurationCache[spellID] < duration then -- Only store it if its longer
					AuraDurationCache[spellID] = duration
				end
			else
				AuraDurationCache[spellID] = duration
			end
			UpdateAuraButton(plate, spellID, texture, count, duration, expire, false)
		end
	end
end

function ns.CallBackUpateAuras(unit, guid, plate) -- When a plate gets a guid
	--print('callbacked yo', unit)
	--if not ns.GetNameplateByGuid(guid) then
	--	print("BUT NOT FUCKING PLATE")
	--end
	UpdateAuraByUnit(unit, guid, plate)
end

local function UpdateAurasByGuid(dstGUID, spellID, expire, count, srcGUID, duration, texture) -- Shit way
	local _, instance = IsInInstance() 
	local buUnit = instance == "arena" and "arena" or "boss"

	if dstGUID == UnitGUID("mouseover") then
		return UpdateAuraByUnit("mouseover", dstGUID);
	else
		for i = 1, 5 do
			if dstGUID == UnitGUID(buUnit..i) then
				return UpdateAuraByUnit(buUnit..i, dstGUID);
			end
		end
	end
	-- No match, lets try some more
	local plate = ns.GetNameplateByGuid(dstGUID)
	if not plate then return; end
	-- We have the plate at least
	UpdateAuraButton(plate, spellID, texture, count, duration, expire, true)
end

local function Auras_OnEvent(event, unit)
	if (event == "PLAYER_TARGET_CHANGED") then
		unit = 'target'
	elseif (event == "UPDATE_MOUSEOVER_UNIT") then
		unit = 'mouseover'
	end
	if unit and unit ~= "player" then
		UpdateAuraByUnit(unit)
	end
end

local function Auras_CLEU(event, _, subEvent, _, srcGUID, _, _, _, dstGUID, _, _, _, spellID, _, _, _, count)
	if srcGUID and dstGUID and spellID then
		if (srcGUID == ns.PlayerGUID and not BlackListMine[spellID]) or (WhiteListAll[spellID]) then
			if ShowEvents[subEvent] then
				local duration = AuraDurationCache[spellID] or 0
				local texture = GetSpellTexture(spellID or 0)
				count = tonumber(count or 1) and count or 1
				UpdateAurasByGuid(dstGUID, spellID, GetTime() + (duration or 0), count, srcGUID, duration, texture or "")
			elseif HideEvents[subEvent] then
				HideAura(dstGUID, spellID, srcGUID)
			end
		end
	end
end

function ns.CreateAuraFrame(self)
	local plate = self.plate
	plate.Auras = CreateFrame("Frame", plate)
	plate.Auras:SetHeight(32)
	plate.Auras:Show()
	plate.Auras:SetSize(plate:GetWidth()+20, plate:GetHeight())
	plate.Auras:SetPoint("BOTTOMLEFT", plate, "TOPLEFT", -10, 20)

	plate.Auras.UpdateButtonPositions = UpdateButtonPositions

	plate.Auras.Buttons = { };
	plate.Auras.SpellIDs = { };
	plate.Auras.numVisible = 0;
	plate.Auras.MaxButtons = (plate:GetWidth()+25) / (BUTTON_WIDTH + BUTTON_GAP)

	plate.Auras:SetScript("OnHide", function(self)
		for i = 1, #self.Buttons do
			self.Buttons[i]:Hide()
		end
	end)
	self:HookScript("OnHide", function(self)
		self.plate.Auras:Hide()
	end)
	self:HookScript("OnShow", function(self)
		self.plate.Auras:Show()
	end)
end

ns.RegisterEvent("UNIT_AURA", Auras_OnEvent)
ns.RegisterEvent("PLAYER_TARGET_CHANGED", Auras_OnEvent)
ns.RegisterEvent("UPDATE_MOUSEOVER_UNIT", Auras_OnEvent)
ns.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", Auras_CLEU)