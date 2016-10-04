local ADDON, ns = ...
local cfg = ns.Config

local scanner = CreateFrame("GameTooltip", ADDON.."Scanner", nil, "GameTooltipTemplate")
local questtipLine = setmetatable({}, { __index = function(k, i)
	local line = _G[ADDON.."ScannerTextLeft" .. i]
	if line then rawset(k, i, line) end
	return line
end })

function ns.GetUnitQuestInfo(namePlateUnitToken)
	if not namePlateUnitToken or UnitIsPlayer(namePlateUnitToken) then
		return false
	end

	local is_quest
	local num_left = 0

	scanner:SetOwner(UIParent, "ANCHOR_NONE")
	scanner:SetUnit(namePlateUnitToken)

	for i = 3, scanner:NumLines() do
		local str = questtipLine[i]
		if (not str) then break; end
		local r,g,b = str:GetTextColor()
		if (r > .99) and (g > .82) and (g < .83) and (b < .01) then -- quest title (yellow)
			is_quest = true
		else
			local done, total = str:GetText():match('(%d+)/(%d+)')  -- kill objective
			if (done and total) then
				local left = total - done
				if (left == 0) then
					is_quest = false
				elseif (left > num_left) then
					num_left = left
				end
			end
		end
	end
	return is_quest, num_left
end

function ns.IsPlayerEffectivelyTank()
	local assignedRole = UnitGroupRolesAssigned("player");
	if ( assignedRole == "NONE" ) then
		local spec = GetSpecialization();
		return spec and GetSpecializationRole(spec) == "TANK";
	end

	return assignedRole == "TANK";
end