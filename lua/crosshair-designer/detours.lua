--[[
	Detours for client convars so that we don't change the users real settings
]]--

local detours = {}		-- "convar" = original
local returnValues = {} -- "convar" = value

CrosshairDesigner.AddConvarDetour = function(convar, value)
	returnValues[convar] = value

	cvars.RemoveChangeCallback(convar, "CrosshairDesigner_DetourWarning")

	cvars.AddChangeCallback(convar, function(name, oldVal, newVal)
    	print("Thing convar is currently being detoured by CrosshairDesigner")
    	print("Set this value to false in the menu to remove the detour.")
    	print("If this script has been reloaded then you may need to rejoin the game.")
	end,
	"CrosshairDesigner_DetourWarning")
end

CrosshairDesigner.RemoveConvarDetour = function(convar, value)
	returnValues[convar] = nil

	cvars.RemoveChangeCallback(convar, "CrosshairDesigner_DetourWarning")
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