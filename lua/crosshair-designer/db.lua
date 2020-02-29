CrosshairDesigner.Save = function(crossID, crossData)

end

CrosshairDesigner.Load = function(crossID)

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
	print(id, convars[id].index)
	convars[convarData.var] = convars[id]
end

-- Verify convars edited by user
CrosshairDesigner.AddConvarCallback = function(convarData)
	cvars.AddChangeCallback(
		convarData.var,
		function(convarName, oldVal, newVal)
			
			newVal = CrosshairDesigner.ClampConvar(convarData, oldVal, newVal)

			hook.Run("CrosshairDesigner_ValueChanged", 
				convarData.var, 
				tostring(oldVal), 
				tostring(newVal)
			)
		end,
		"CrosshairDesigner." .. convarData.var
	)
end

CrosshairDesigner.ClampConvar = function(convarData, oldVal, newVal)
	if convarData.isBool then -- bool

		if tobool(newVal) == nil then
			if tobool(oldVal) == nil then
				newVal = convarData.default
			else
				newVal = oldVal
			end
			CrosshairDesigner.SetValue(convarData.var, newVal)
		end
		
	elseif tonumber(convarData.default) != nil then -- number

		if tonumber(newVal) == nil then
			if tonumber(oldVal) == nil then
				newVal = convarData.default
			else
				newVal = oldVal
			end
			CrosshairDesigner.SetValue(convarData.var, newVal)
		else
			local clamped = tonumber(newVal)

			if convarData.min != nil then
				clamped = math.max(clamped, convarData.min)
			end

			if convarData.max != nil then
				clamped = math.min(clamped, convarData.max)
			end

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
	RunConsoleCommand(convars[id].data.id, val)
end

CrosshairDesigner.GetLimitMin = function(id)
	return (convars[id] != nil and convars[id].data.min) or 0
end

CrosshairDesigner.GetLimitMax = function(id)
	return (convars[id] != nil and convars[id].data.max) or 0
end

CrosshairDesigner.GetConvars = function() return convars end