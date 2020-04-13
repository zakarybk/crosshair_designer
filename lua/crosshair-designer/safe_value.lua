local settings = {} -- index{ setting }
local idToSetting = {} -- id: settings index

CrosshairDesigner.SettingIDIndex = function(id)
	return idToSetting[id]
end

CrosshairDesigner.Setting = function(index)
	return settings[index]
end

CrosshairDesigner.Settings = function()
	return table.Copy(settings)
end

CrosshairDesigner.SettingAtID = function(id)
	local index = CrosshairDesigner.SettingIDIndex(id)
	return(
		index != nil and
		CrosshairDesigner.Setting(index) or
		nil
	)
end

CrosshairDesigner.AddSafeCheck = function(setting)
	table.insert(settings, setting)
	idToSetting[setting.id] = #settings
end

local safeOrDefault = function(typeFunc, val, default)
	local changed = false

	if typeFunc(val) == nil then
		val = typeFunc(default)
		changed = true
	else
		val = typeFunc(val)
	end

	val, changed
end

CrosshairDesigner.SafeValue = function(id, val)
	local setting = CrosshairDesigner.SettingAtID(id)
	local changed = false
	
	assert(setting != nil, "Tried to make a safe value for a non-existant setting!" ..
		" ( " + id + ") ")


	if setting.isBool then
		local val, changed = safeOrDefault(tobool, val, setting.default)
	else
		local val, changed = safeOrDefault(tonumber, val, setting.default)

		if setting.min ~= nil then
			local clamped = math.max(val, setting.min)
			changed = val != clamped or changed
			val = clamped
		end

		if setting.max ~= nil then
			local clamped = math.min(val, setting.max)
			changed = val != clamped or changed
			val = clamped
		end

		val = math.floor(val)
	end

	return val, changed
end

CrosshairDesigner.IsSafeValue = function(id, val)
	local val, changed = CrosshairDesigner.SafeValue(id, val)
	return not changed
end