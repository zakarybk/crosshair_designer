--[[
	Detours for client convars so that we don't change the users real settings

	For example in TTT if we were to give them the option to disable the
	crosshair through the menu (ttt_disable_crosshair), they would wonder 
	why they couldn't see the TTT crosshair in other servers and become lost! 
	This aims to make that a non-issue as no permanent changes will be made.
]]--

CrosshairDesigner.Detours = CrosshairDesigner.Detours or {}

local detours = {}		-- "convar" = original
local returnValues = {} -- "convar" = value

CrosshairDesigner.AddConvarDetour = function(convar, value)
	returnValues[convar] = tostring(value)

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

detours.GetConVarNumber = CrosshairDesigner.Detours.GetConVarNumber or GetConVarNumber

GetConVarNumber = function(name, ...)
	if returnValues[name] != nil then
		return tonumber(returnValues[name])
	end
	return detours.GetConVarNumber(name, ...)
end

-- Hacky detour to hide TTT crosshair without making permanent changes to the convar
local convarCache = {}
local convarMeta = FindMetaTable("ConVar")
detours.CreateConVar = CrosshairDesigner.Detours.CreateConVar or CreateConVar

CreateConVar = function(name, ...)
	local convar = detours.CreateConVar(name, ...)

	if name == "ttt_disable_crosshair" then
		local wrapper = {}

		for name, func in pairs(convarMeta) do
			if name != "GetBool" then
				wrapper[name] = func
			end
		end
		wrapper.GetBool = function() return CrosshairDesigner.GetBool("HideTTT") end

		return wrapper
	end

	return convar
end

-- Always place at end
CrosshairDesigner.Detours = detours