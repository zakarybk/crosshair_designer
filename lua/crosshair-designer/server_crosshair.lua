if SERVER then
	util.AddNetworkString("CrosshairDesigner_SetServerCrosshair")
	util.AddNetworkString("CrosshairDesigner_GetServerCrosshair")
	util.AddNetworkString("CrosshairDesigner_ExistsServerCrosshair")
end

local canEditCheck = function(ply) return ply:IsSuperAdmin() end
local serverCrosshair = false
local crosshairFile = "server_crosshair.txt" -- uses json

CrosshairDesigner.SetCanEditServerCrosshairCheck = function(func) canEditCheck = func end
CrosshairDesigner.CanEditServerCrosshair = function(ply) return canEditCheck(ply) end

if CLIENT then

	local useServerCross = CreateClientConVar(
		"crosshairdesigner_allowservercrosshair",
		"1",
		true,
		"When set, if the server has a custom crosshair then you will use their one instead."
	)
	cvars.AddChangeCallback("crosshairdesigner_allowservercrosshair",
		function(name, old, new)
    	if tobool(new) == true then
    		CrosshairDesigner.RequestServerCrosshair()
    	else
    		CrosshairDesigner.HideServerCrosshair()
    	end
	end)

	CrosshairDesigner.SetServerCrosshair = function(cross)
		net.Start("CrosshairDesigner_SetServerCrosshair")
			net.WriteString(cross)
		net.SendToServer()
	end

	CrosshairDesigner.RequestServerCrosshair = function()
		net.Start("CrosshairDesigner_ExistsServerCrosshair")
		net.SendToServer()
	end

	net.Receive("CrosshairDesigner_GetServerCrosshair", function(len)
		if useServerCross:GetBool() then
			CrosshairDesigner.ShowServerCrosshair(net.ReadString())
		end
	end)

	-- Todo - only run when the client allows server crosshairs
	if useServerCross:GetBool() then
		timer.Create("RequestCrosshair", 1, 0, function()
			if IsValid(LocalPlayer()) then
				CrosshairDesigner.RequestServerCrosshair()
				timer.Remove("RequestCrosshair")
			end
		end)
	end

end

if not CLIENT then return end

CrosshairDesigner.ServerCrosshair = function()
	return serverCrosshair
end

CrosshairDesigner.ExistsServerCrosshair = function()
	return serverCrosshair != false
end

CrosshairDesigner.ToSafeCrosshair = function(cross)
	local parts = string.Explode(" ", cross)
	local safe = ""
	local setting = nil

	for i, val in pairs(parts) do
		setting = CrosshairDesigner.Setting(i)
		if setting then
			safe = safe + tostring(CrosshairDesigner.SafeValue(setting.id, val)) + " "
		end
	end

	return safe
end

CrosshairDesigner.CrosshairToJSON = function(cross)
	local safe = CrosshairDesigner.ToSafeCrosshair(cross)
	local tbl = {}
	local setting = nil
	local parts = string.Explode(" ", safe)

	for i, val in pairs(parts) do
		setting = CrosshairDesigner.Setting(i)
		if setting then
			tbl[setting.id] = val
			table.insert(tbl)
		end
	end

	return util.TableToJSON(tbl)
end

CrosshairDesigner.CrosshairFromJSON = function(jsonCross)
	local tbl = util.JSONToTable(jsonCross)
	local cross = ""
	local toAppend = ""
	local settings = CrosshairDesigner.Settings()

	for i, setting in pairs(settings) do
		if tbl[setting.id] != nil then
			toAppend = tostring(CrosshairDesigner.SafeValue(setting.id, tbl[setting.id]))
		else
			toAppend = setting.default
		end
		cross = cross + toAppend + " "
	end

	return cross
end

net.Receive("CrosshairDesigner_SetServerCrosshair", function(len, ply)
	if CrosshairDesigner.CanEditServerCrosshair(ply) then
		local cross = net.ReadString()
		local safe = CrosshairDesigner.ToSafeCrosshair(cross)
		local json = CrosshairDesigner.CrosshairToJSON(safe)

		file.Write(crosshairFile, json)
		serverCrosshair = safe

		CrosshairDesigner.SendCrosshair(nil, true)
	end
end)

net.Receive("CrosshairDesigner_ExistsServerCrosshair", function(len, ply)
	net.Start("CrosshairDesigner_ExistsServerCrosshair")
		net.WriteBool(CrosshairDesigner.ExistsServerCrosshair())
	net.Send(ply)
end)

net.Receive("CrosshairDesigner_GetServerCrosshair", function(len, ply)
	if CrosshairDesigner.ExistsServerCrosshair() then
		net.Start("CrosshairDesigner_GetServerCrosshair")
			net.WriteString(serverCrosshair)
		net.Send(ply)
	end
end)

CrosshairDesigner.SendCrosshair = function(ply, broadcast)
	if CrosshairDesigner.ExistsServerCrosshair() then
		net.Start("CrosshairDesigner_GetServerCrosshair")
			net.WriteString(CrosshairDesigner.ServerCrosshair())
		if broadcast then
			net.Broadcast()
		else
			net.Send(ply)
		end
	end
end