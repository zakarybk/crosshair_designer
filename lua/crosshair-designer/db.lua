CrosshairDesigner.Save = function(crossID, crossData)

end

CrosshairDesigner.Load = function(crossID)

end

local convars = {}

CrosshairDesigner.SetUpConvars = function(convars)
	for i, convarData in pairs(convars) do
		CrosshairDesigner.AddConvar(convarData)
		CrosshairDesigner.AddConvarCallback(convarData)
	end
end

CrosshairDesigner.AddConvar = function (convarData)
	convars[convarData.id] = {}
	convars[convarData.id].data = convarData
	convars[convarData.id].var = CreateClientConVar(
		convarData.id, 
		convarData.default,
		true, 
		false,
		convarData.help or nil,
		convarData.min or nil,
		convarData.max or nil
	)
end

-- Verify convars edited by user
CrosshairDesigner.AddConvarCallback = function(convarData)
	cvars.AddChangeCallback(
		convarData.id,
		function(convarName, oldVal, newVal)
			
			newVal = CrosshairDesigner.ClampConvar(convarData, oldVal, newVal)

			hook.Run("CrosshairDesigner_ValueChanged", 
				convarData.id, 
				tostring(oldVal), 
				tostring(newVal)
			)
		end,
		"CrosshairDesigner." .. convarData.id
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
			CrosshairDesigner.SetValue(convarData.id, newVal)
		end
		
	elseif tonumber(convarData.default) != nil then -- number

		if tonumber(newVal) == nil then
			if tonumber(oldVal) == nil then
				newVal = convarData.default
			else
				newVal = oldVal
			end
			CrosshairDesigner.SetValue(convarData.id, newVal)
		else
			local clamped = tonumber(newVal)

			if convarData.min != nil then
				clamped = math.max(clamped, convarData.min)
			end

			if convarData.max != nil then
				clamped = math.min(clamped, convarData.max)
			end

			if clamped != tonumber(newVal) then
				CrosshairDesigner.SetValue(convarData.id, clamped)
				newVal = clamped
			end
		end
	end

	return newVal
end

CrosshairDesigner.GetValue = function(id)
	return (convars[id] != nil and convars[id].var:GetString()) or "0"
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