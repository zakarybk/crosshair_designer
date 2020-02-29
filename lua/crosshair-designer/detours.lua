--[[
	Detours for client convars so that we don't change the users real settings
]]--

local detours = {}		-- "convar" = original
local returnValues = {} -- "convar" = value

CrosshairDesigner.AddConvarDetour = function(convar, value)
	returnValues[convar] = value
end

CrosshairDesigner.RemoveConvarDetour = function(convar, value)
	returnValues[convar] = nil
end

--[[
	Detours
]]--

detours.GetConVarNumber = GetConVarNumber

GetConVarNumber = function(name)
	if returnValues[name] != nil then
		return returnValues[name]
	end
	return detours.GetConVarNumber(name)
end