local name, ns = ...
local Gcfg = AbuGlobal.GlobalConfig

ns.Config.Colors.Frame 	= Gcfg.Colors.Frame
ns.Config.Colors.Border   = Gcfg.Colors.Border
ns.Config.Colors.Interrupt = Gcfg.Colors.Interrupt

ns.Config.IconTextures.White = Gcfg.IconTextures.White
ns.Config.IconTextures.Normal = Gcfg.IconTextures.Normal
ns.Config.IconTextures.Shadow = Gcfg.IconTextures.Shadow

-- Nameplates
ns.Config.StatusbarTexture = Gcfg.Statusbar.Light

ns.Config.Font = Gcfg.Fonts.Normal
ns.Config.FontSize = 12

ns.Config.MinimumAlpha = 0.6  -- Minimum alpha on a nameplate
ns.Config.RaidIconSize = 20   -- Size on raid icon

-- Auras
ns.Config.AuraSize = 25
ns.Config.AuraGap = 3

-- Nameplates by default show every debuff that you apply.
-- The blacklist hides debuffs that you cast, and the WHITELIST list shows
-- the debuff no matter who applied it.

-- SHOW THESE FROM ALL
ns.Config.WHITELIST = {
	[23333] = true,  -- Horde Flag
	[34976] = true,  -- Netherstorm Flag
	[23335] = true,  -- Alliance Flag
}

-- HIDE THESE DEBUFFS BY YOU
-- 		ALL CLASSES
ns.Config.BLACKLIST[159238] = true --"Shattered Bleed"

-- 		PER CLASS
ns.Config.BLACKLIST['DRUID'] = { 

}

ns.Config.BLACKLIST['HUNTER'] = { 

}

ns.Config.BLACKLIST['MAGE'] = {
	[116] = true, -- frostbolt debuff
	[132210] = true, -- pyromaniac
}

ns.Config.BLACKLIST['DEATHKNIGHT'] = { 

}

ns.Config.BLACKLIST['WARRIOR'] = {
	[113746] = true, -- weakened armour
	[1160] = true,   -- demoralizing shout
	[115767] = true, -- deep wounds
	[469] = true,    -- commanding shout
	[6673] = true,   -- battle shout
	[115804] = true, -- mortal WOUNDS
	[81326] = true,  -- Physical invulnbiloiuity
}

ns.Config.BLACKLIST['PALADIN'] = { 

}

ns.Config.BLACKLIST['WARLOCK'] = {
	[30213] = true, -- Legion Strike
}

ns.Config.BLACKLIST['SHAMAN'] = {
	[63685] = true,  -- frost shock root
	[51490] = true,  -- thunderstorm slow
	[61882] = true,  -- earthquake
	
	[3600] = true,   -- earthbind totem passive
	[64695] = true,   -- earthgrap totem root
	[116947] = true,   -- earthgrap totem slow
}
ns.Config.BLACKLIST['PRIEST'] = { 

}

ns.Config.BLACKLIST['ROGUE'] = {
	[113952] = true, --Paralytic Poison"
	[93068] = true, --Master Poisoner
	[3409] = true,  --Crippling Poison
}

ns.Config.BLACKLIST['MONK'] = { 

}