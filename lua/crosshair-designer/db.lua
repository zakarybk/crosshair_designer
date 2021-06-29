CrosshairDesigner.Directory = "crosshair_designer"
CrosshairDesigner.FutureDirectory = "crosshair_designer/remastered" -- old crosshair has good file restriction so may not need new dir
-- but it would make it more clear for users
local defaultCrosshair = "0 1 1 1 0 0 12 0 255 255 7 11 1 0 2 14 1 255 0 0 221 0 50 1 1 1 1 1 0 1 182 182 182 186 0 1 4 0"
-- Outdated - the way I handled crosshair naming back in 2016
-- so that it's forwards and backwards compatible -- To-Do: Refactor this whole file and improve saving and allow for temporary crosshairs and undos
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
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_11", "Save 11", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_12", "Save 12", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_13", "Save 13", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_14", "Save 14", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_15", "Save 15", true, false))
table.insert(saveNameConvars, CreateClientConVar("Hc_crosssave_16", "Save 16", true, false))

local convars = {}
local indexed = {}

-- Temporary workaround for saving the cache value
local cacheID = "crosshairdesigner_cache"
CrosshairDesigner.CacheSetting = CreateClientConVar(cacheID, "5", true, false)
local cacheSize = CrosshairDesigner.CacheSetting:GetInt()
CrosshairDesigner.SetCacheSize = function(val) RunConsoleCommand(cacheID, tostring(math.Round(val))) end
CrosshairDesigner.CacheSize = function() return cacheSize end
CrosshairDesigner.CacheEnabled = function() return cacheSize >= 2 end
CrosshairDesigner.CacheMaxSize = 200
CrosshairDesigner.CacheMinSize = 2
-- excluding cache min size to allow value to be set below, but still 2 is the lowest val where the cache will work
local withinCacheRange = function(val) return val ~= nil and val >= 0 and val <= CrosshairDesigner.CacheMaxSize end
-- Secure console command values
cvars.RemoveChangeCallback(cacheID, "CrosshairDesigner." .. cacheID)
cvars.AddChangeCallback(cacheID, function(convarName, oldVal, newVal)
	newVal = tonumber(newVal)
	oldVal = tonumber(oldVal)

	if not withinCacheRange(newVal) then
		-- revert to old value if valid and new value not valid
		if withinCacheRange(oldVal) then
			RunConsoleCommand(cacheID, tostring(oldVal))
		else
			-- invalid value - fallback and turn off cache
			RunConsoleCommand(cacheID, tostring(0))
		end
	else
		-- valid value - allow update
		newVal = math.Round(newVal)
		cacheSize = newVal
		hook.Run("CrosshairDesigner_CacheSizeUpdate", newVal)
	end
end, "CrosshairDesigner." .. cacheID)

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

CrosshairDesigner.CurrentToTable = function()
	local data = {}

	for i, convarData in pairs(indexed) do
		data[convarData.data.id] = tostring(CrosshairDesigner.GetInt(convarData.data.var))
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
				if strings[i] != nil and strings[i] != "" then
					val = strings[i]
				else
				-- Otherwise use the default value
					val = id.data.default
				end
			end

			-- print(id.data.id, "\t", val)

			-- Hacky fix for older crosshairs
			if id.data.id == "Thickness" then
				val = math.max(1, val)
			end

			CrosshairDesigner.SetValue(id.data.var, val)

			-- Keep running until the game decides it wants to update our values
			if tostring(CrosshairDesigner.GetValue(id.data.var)) == tostring(val) then
				if i == count then
					hook.Run("CrosshairDesigner_CrosshairLoaded")
					timer.Remove("CrosshairDesigner_StaggeredSettings")
				end

				i = i + 1
			end
		end)
	else
		-- Hacky - remove?
		file.Write(saveFile, defaultCrosshair)
		CrosshairDesigner.Load(crossID)
	end
end

CrosshairDesigner.LoadDefaultCrosshair = function()
	CrosshairDesigner.Load(0, defaultCrosshair)
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


CrosshairDesigner.IsValidCrosshair = function(values)
	local isValid = true
	local inValid = {id = "none", expected="none", actual="none"}

	local keys = {"Segments", "Rotation", "Thickness", "Stretch", "Gap" ,"Length", "Outline", "LineStyle"}

	for k=1, #keys do
		local key = keys[k]
		local id = key
		local val = values[key]

		if val == nil or val == "" or val == "nil" then
			isValid = false
			inValid = {
				id = id,
				expected="Any value",
				actual=val
			}
			break
		end

		local data = CrosshairDesigner.GetConvarData(id)

		if data.min ~= nil then
			if tonumber(val) == nil or tonumber(val) < data.min then
				isValid = false
				inValid = {
					id = id,
					expected="between " + data.min + ":" + data.max,
					actual=val
				}
				break
			end
		end

		if data.max ~= nil then
			if tonumber(val) == nil or tonumber(val) > data.max then
				isValid = false
				inValid = {
					id = id,
					expected="between " + data.min + ":" + data.max,
					actual=val
				}
				break
			end
		end

		if data.isBool then
			if tobool(val) == nil then
				isValid = false
				inValid = {id = id, expected="true/false", actual=val}
				break
			end
		end
	end

	return isValid, inValid
end