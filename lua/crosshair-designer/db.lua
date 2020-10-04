CrosshairDesigner.Directory = "crosshair_designer"
CrosshairDesigner.FutureDirectory = "crosshair_designer/remastered" -- old crosshair has good file restriction so may not need new dir
-- but it would make it more clear for users

-- Outdated - the way I handled crosshair naming back in 2016 
-- so that it's forwards and backwards compatible
local saveNameConvars = {}
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_1", "Save 1", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_2", "Save 2", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_3", "Save 3", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_4", "Save 4", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_5", "Save 5", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_6", "Save 6", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_7", "Save 7", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_8", "Save 8", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_9", "Save 9", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_10", "Save 10", true, false))

local convars = {}
local indexed = {}

--[[
	Needs to be forwards and backwards compatible since servers run different versions
]]--

CrosshairDesigner.CurrentToString = function()
	local data = ""

	for i, convarData in pairs(indexed) do
		data = data .. tostring(CrosshairDesigner.GetInt(convarData.data.var)) .. " "
	end

	return data
end

CrosshairDesigner.Save = function(crossID)
	local saveFile = "crosshair_designer/save_" .. crossID .. ".txt" -- temporary - if replacing watchout for duplicates

	file.Write(saveFile, CrosshairDesigner.CurrentToString())
end

CrosshairDesigner.Load = function(crossID, dataStr)
	local strings = false
	local saveFile = "crosshair_designer/save_" .. crossID .. ".txt"

	if dataStr then
		strings = string.Explode(" ", dataStr)

	elseif file.Exists(saveFile, "DATA") then
		strings = string.Explode(" ", file.Read(saveFile, "DATA"))
	end

	if strings then
		local i = 1
		local count = #indexed

		timer.Create( "CrosshairDesigner_StaggeredSettings", 0.02, 0, function()

			local id = CrosshairDesigner.ConvarDataAtIndex(i)
			local val = "0"

			if id then
				-- If a setting was found in the save, use it
				if strings[i] != nil then
					val = strings[i]
				else
				-- Otherwise use the default value
					val = id.data.default
				end
			end

			CrosshairDesigner.SetValue(id.data.var, val)

			-- Keep running until the game decides it wants to update our values
			if tostring(CrosshairDesigner.GetValue(id.data.var)) == tostring(val) then
				i = i + 1

				if i == count then
					hook.Run("CrosshairDesigner_CrosshairLoaded")
					timer.Remove("CrosshairDesigner_StaggeredSettings")
				end
			end
		end)
	else
		-- Hacky - remove?
		file.Write(saveFile, "0 1 1 1 0 0 50 250 50 255 2 7 2 0 8 0 1 250 46 46 255 0 50 1 1 1 1 1") -- default config (thanks Necro)
		CrosshairDesigner.Load(crossID)
	end
end

CrosshairDesigner.SetUpConvars = function(convars)
	for i, convarData in pairs(convars) do
		CrosshairDesigner.AddConvar(convarData.id, convarData)
		CrosshairDesigner.AddConvarCallback(convarData)
	end
end

CrosshairDesigner.AddConvar = function(id, convarData)
	convars[id] = {}	-- Index ignores duplicates
	convars[id].index = math.floor(table.Count(convars) / 2) + 1
	convars[id].data = convarData
	convars[id].var = CreateClientConVar(
		convarData.var,
		convarData.default,
		true,
		false,
		convarData.help or nil,
		convarData.min or nil,
		convarData.max or nil
	)
	convars[convarData.var] = convars[id]
	indexed[convars[id].index] = convars[id]
end

-- Verify convars edited by user
CrosshairDesigner.AddConvarCallback = function(convarData)
	cvars.RemoveChangeCallback(convarData.var, "CrosshairDesigner." .. convarData.var)

	cvars.AddChangeCallback(
		convarData.var,
		function(convarName, oldVal, newVal)

			-- Override value
			local forceVal, reason = hook.Run("CrosshairDesigner_OverrideValue", convarName)

			if forceVal ~= nil then
				local name = CrosshairDesigner.GetConvarData(convarName).title
				if reason ~= nil then
					Derma_Message(
						"'" .. name .. "' has been disabled for:\n" .. reason, 
						"Crosshair Designer disabled setting", 
						"OK"
					)
				else
					Derma_Message(
						"'" .. name .. "' has been disabled",
						"Crosshair Designer disabled setting", 
						"OK"
					)
				end
				return -- Stop execution
			end

			-- Update value

			local adjusted = CrosshairDesigner.ClampConvar(convarData, oldVal, newVal)
			local val

			if convarData.isBool then
				val = tobool(adjusted)
				oldVal = tobool(oldVal)
			else
				val = tonumber(adjusted)
				oldVal = tonumber(oldVal)
			end

			if val ~= oldVal then
				hook.Run("CrosshairDesigner_ValueChanged",
					convarData.var,
					val
				)
			end
		end,
		"CrosshairDesigner." .. convarData.var
	)
end

CrosshairDesigner.ClampConvar = function(convarData, oldVal, newVal)
	if convarData.isBool then -- bool

		if tobool(newVal) == nil or tonumber(newVal) == nil then
			if tobool(oldVal) == nil then
				newVal = convarData.default
			else
				newVal = oldVal
			end
			CrosshairDesigner.SetValue(convarData.var, math.floor(tonumber(newVal)))
		end

	elseif tonumber(convarData.default) ~= nil then -- number

		if tonumber(newVal) == nil then
			if tonumber(oldVal) == nil then
				newVal = convarData.default
			else
				newVal = math.floor(oldVal)
			end
			CrosshairDesigner.SetValue(convarData.var, math.floor(newVal))
		else
			local clamped = tonumber(newVal)

			if convarData.min ~= nil then
				clamped = math.max(clamped, convarData.min)
			end

			if convarData.max ~= nil then
				clamped = math.min(clamped, convarData.max)
			end

			clamped = math.floor(clamped)

			if clamped ~= tonumber(newVal) then
				CrosshairDesigner.SetValue(convarData.var, clamped)
				newVal = clamped
			end
		end
	end

	return newVal
end

CrosshairDesigner.GetValue = function(id)
	return (convars[id] ~= nil and convars[id].var:GetString()) or "0"
end

CrosshairDesigner.GetInt = function(id)
	return (convars[id] ~= nil and convars[id].var:GetInt()) or 0
end

CrosshairDesigner.GetBool = function(id)
	if convars[id] ~= nil then
		local forceVal, reason = hook.Run("CrosshairDesigner_OverrideValue", convars[id].data.var)
		if forceVal ~= nil then
			return forceVal
		else
			return convars[id].var:GetBool()
		end
	else
		return false
	end
end

CrosshairDesigner.SetValue = function(id, val)
	RunConsoleCommand(convars[id].data.var, tostring(val))
end

CrosshairDesigner.GetLimitMin = function(id)
	return (convars[id] ~= nil and convars[id].data.min) or 0
end

CrosshairDesigner.GetLimitMax = function(id)
	return (convars[id] ~= nil and convars[id].data.max) or 0
end

CrosshairDesigner.GetConvarDatas = function()
	local data = {}

	for i, convarData in pairs(indexed) do
		data[convarData.index] = convarData.data
	end

	return data
end

CrosshairDesigner.ConvarDataAtIndex = function(index)
	local found = false

	if indexed[index] ~= nil then
		found = indexed[index]
	end

	return found
end

CrosshairDesigner.GetConvarData = function(id)
	return (convars[id] ~= nil and convars[id].data) or false
end

-- The friendly readable one
CrosshairDesigner.GetConvarID = function(convar)
	return convars[convar] ~= nil and convars[convar].data.id or ""
end