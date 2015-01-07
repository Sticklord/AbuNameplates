local name, ns = ...
local Gcfg = AbuGlobal.GlobalConfig

ns.Config = {
	-- Nameplates
	StatusbarTexture = Gcfg.Statusbar.Light,
	Font = Gcfg.Fonts.Normal,
	Colors = Gcfg.Colors,
	IconTextures = Gcfg.IconTextures,

	FontSize = 12,
	MinimumAlpha = 0.6,-- Minimum alpha on a nameplate
	RaidIconSize = 20, -- Size on raid icons

	-- Auras
	AuraSize = 25,
	AuraGap = 3,
	AuraTexture = Gcfg.IconTextures,

	-- Nameplates by default show every debuff that you apply.
	-- The blacklist hides debuffs that you cast, and the ALL list shows
	-- the debuff no matter who applied it.

	-- HIDE THESE DEBUFFS BY YOU
	BLACKLIST = {
		[159238] = true, --"Shattered Bleed"
		['DRUID'] = { },
		['HUNTER'] = { },
		['MAGE'] = {
			[116] = true, -- frostbolt debuff
			[132210] = true, -- pyromaniac
		},
		['DEATHKNIGHT'] = { },
		['WARRIOR'] = {
			[113746] = true, -- weakened armour
			[1160] = true,   -- demoralizing shout
			[115767] = true, -- deep wounds; td
			[469] = true,    -- commanding shout
			[6673] = true,   -- battle shout
			[115804] = true, -- mortal WOUNDS
			[81326] = true,  -- Physical invul
		},
		['PALADIN'] = { },
		['WARLOCK'] = {
			[30213] = true, -- Legion Strike
		},
		['SHAMAN'] = {
			[63685] = true,  -- frost shock root
			[51490] = true,  -- thunderstorm slow
			[61882] = true,  -- earthquake
			
			[3600] = true,   -- earthbind totem passive
			[64695] = true,   -- earthgrap totem root
			[116947] = true,   -- earthgrap totem slow
		},
		['PRIEST'] = { },
		['ROGUE'] = {
			[113952] = true, --Paralytic Poison"
			[93068] = true, --Master Poisoner
			[3409] = true,  --Crippling Poison
			},
		['MONK'] = { },
	},
	-- SHOW THESE FROM ALL
	ALL = {
		[23333] = true,  -- Horde Flag
		[34976] = true,  -- Netherstorm Flag
		[23335] = true,  -- Alliance Flag
	},
}