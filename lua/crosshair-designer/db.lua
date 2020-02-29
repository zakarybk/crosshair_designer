CrosshairDesigner.Directory = "crosshair_designer"
CrosshairDesigner.FutureDirectory = "crosshair_designer/remastered" -- old crosshair has good file restriction so may not need new dir
-- but it would make it more clear for users

--[[
	Needs to be forwards and backwards compatible since servers run different versions
]]--

CrosshairDesigner.Save = function(crossID, crossData)
	local crosshairsaves = "crosshair_designer/save_" .. Hc_whichsaveslot .. ".txt"
end

CrosshairDesigner.Load = function(crossID) -- Needs testing
	local crosshairloading = "crosshair_designer/save_" .. crossID .. ".txt" -- temporary

	if file.Exists( crosshairloading, "DATA" ) then
		local brokencrossstring = string.Explode( " ", file.Read( crosshairloading, "DATA" ) )

		local hc_timer_i = 1
		local hc_printerror = 1

		timer.Create( "CrosshairDesigner_ApplySettings", 0.1, hc_con_num, function()

			local id = CrosshairDesigner.ConvarAtIndex(hc_timer_i)

			if id then
				CrosshairDesigner.SetValue(id, ( brokencrossstring[hc_timer_i] ))
			end

			hc_timer_i = hc_timer_i + 1  
		end)

	else
		-- Hacky - remove?
		file.Write( crosshairloading, "0 1 1 1 0 1 29 0 255 255 5 13 1 0 8 0 1 255 0 0 255 1 50 1" ) -- default config
		CrosshairDesigner.Load(crossID)
	end
end

local convars = {}

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
end

-- Verify convars edited by user
CrosshairDesigner.AddConvarCallback = function(convarData)
	cvars.AddChangeCallback(
		convarData.var,
		function(convarName, oldVal, newVal)
			
			local adjusted = CrosshairDesigner.ClampConvar(convarData, oldVal, newVal)

			if adjusted != tonumber(newVal) then
				hook.Run("CrosshairDesigner_ValueChanged", 
					convarData.var,
					tostring(adjusted)
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
		
	elseif tonumber(convarData.default) != nil then -- number

		if tonumber(newVal) == nil then
			if tonumber(oldVal) == nil then
				newVal = convarData.default
			else
				newVal = math.floor(oldVal)
			end
			CrosshairDesigner.SetValue(convarData.var, math.floor(newVal))
		else
			local clamped = tonumber(newVal)

			if convarData.min != nil then
				clamped = math.max(clamped, convarData.min)
			end

			if convarData.max != nil then
				clamped = math.min(clamped, convarData.max)
			end

			clamped = math.floor(clamped)

			if clamped != tonumber(newVal) then
				CrosshairDesigner.SetValue(convarData.var, clamped)
				newVal = clamped
			end
		end
	end

	return newVal
end

CrosshairDesigner.GetValue = function(id)
	return (convars[id] != nil and convars[id].var:GetString()) or "0"
end

CrosshairDesigner.GetInt = function(id)
	return (convars[id] != nil and convars[id].var:GetInt()) or 0
end

CrosshairDesigner.GetBool = function(id)
	return (convars[id] != nil and convars[id].var:GetBool()) or false
end

CrosshairDesigner.SetValue = function(id, val)
	RunConsoleCommand(convars[id].data.var, tostring(val))
end

CrosshairDesigner.GetLimitMin = function(id)
	return (convars[id] != nil and convars[id].data.min) or 0
end

CrosshairDesigner.GetLimitMax = function(id)
	return (convars[id] != nil and convars[id].data.max) or 0
end

CrosshairDesigner.GetConvarDatas = function()
	local data = {}

	for id, convarData in pairs(convars) do
		data[convarData.index] = convarData.data
	end

	return data
end

CrosshairDesigner.ConvarAtIndex = function(index) -- inefficient (duplicates in tbl)
	local found = false

	for id, convarData in pairs(convars) do
		if convarData.index == index then
			found = id
			break
		end
	end

	return found
end