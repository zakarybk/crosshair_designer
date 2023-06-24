local disabled = {}

-- Only supports on/off features
CrosshairDesigner.DisableFeature = function(id, forceVal, reason)
	local data = CrosshairDesigner.GetConvarData(id)
	if data then
		if data.isBool then
			disabled[data.var] = {
				forceVal = forceVal,
				reason = reason and reason or "none"
			}
			hook.Run("CrosshairDesigner_ValueChanged", data.var, forceVal)
		else
			ErrorNoHalt(
				"CrosshairDesigner: ",
				"Tried to disable a non-boolean value feature: " + data.var
			)
		end
	else
		CrosshairDesigner.Print("Disable feature failed. Feature: " .. id .. " not found!")
	end
end

CrosshairDesigner.EnableFeature = function(convar)
	local data = CrosshairDesigner.GetConvarData(id)
	if data then
		disabled[data.var] = nil
	end
end

hook.Add("CrosshairDesigner_OverrideValue", "CrosshairDesigner_DisableFeature", function(convar)
	if disabled[convar] ~= nil then
		return disabled[convar].forceVal, disabled[convar].reason
	end
end)