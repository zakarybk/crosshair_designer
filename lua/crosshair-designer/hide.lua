--[[
	Handles when the crosshair should be hidden or visible as a result of 
	external factors (not related to crosshair settings but other addons)

	The crosshair settings can control whether the external factors should
	be a factor when deciding to hide the crosshair.



	--- API quick doc

	This is made to be used by other addons if they wish through

	CrosshairDesigner.AddSwepCheck( -- see load.lua for examples
		name,
		shouldUse(ply, wep),  -- always passes through valid values
		shouldDraw(ply, wep), -- always passes through valid values
		enabled (optional, default=true)
	)

	shouldUse will be called whenever the player swaps SWEPs or changes
	crosshair settings if the player and active SWEP are valid



	Since only ever one of the SWEP checks will be used (first to return shouldUse=true),
	you can modify the priority so that yours can be checked before the rest with

	CrosshairDesigner.MakeSwepCheckTopPriority(
		name
	)



	These can all be setup when CrosshairDesigner_FullyLoaded is called for example

	hook.Add("CrosshairDesigner_FullyLoaded", "MyCustomHook", function(crossTbl)
		crossTbl.AddSwepCheck(...)
		crossTbl.AddSwepCheck(...)
		crossTbl.AddSwepCheck(...)

		crossTbl.MakeSwepCheckTopPriority(...)
	end)
	---

]]--

local UpdateVisibility = function() end
local UpdateSWEPCheck = function() end
local DefaultSWEPShouldDraw = function() return true end
local SWEPShouldDraw = DefaultSWEPShouldDraw

local activeWeapon = nil
local ply
local wep
local shouldDraw = true

local SWEPChecks = {} -- SWEPChecks[n].ShouldUse() SWEPChecks[n].ShouldUse.ShouldDraw()

-- GM:PlayerSwitchWeapon "This hook is predicted. This means that in singleplayer, 
-- it will not be called in the Client realm."
-- https://wiki.facepunch.com/gmod/GM:PlayerSwitchWeapon
hook.Add("Think", "CrosshairDesigner_WeaponSwitchMonitor", function()

	ply = LocalPlayer()

	if IsValid(ply) then
		wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			if activeWeapon ~= wep then
				activeWeapon = wep
				UpdateSWEPCheck(ply, wep)
			end
		end

		UpdateVisibility(ply, wep)
	end

end)

-- Update weapon on weapon change + update vis for every tick
UpdateVisibility = function(ply, wep)

	shouldDraw = true

	if not CrosshairDesigner.GetBool("ShowCross") then
		shouldDraw = false

	elseif not shouldDraw or not ply:Alive() then
		shouldDraw = false

	elseif not SWEPShouldDraw(ply, wep) then
		shouldDraw = false

	elseif ply:InVehicle() and CrosshairDesigner.GetBool("HideInVeh") then
		shouldDraw = false
	end

end

UpdateSWEPCheck = function(ply, wep)
	for i, check in pairs(SWEPChecks) do
		if check.enabled and check.ShouldUse(ply, wep) then
			SWEPShouldDraw = check.ShouldDraw
			return
		end
	end
	SWEPShouldDraw = DefaultSWEPShouldDraw
end

CrosshairDesigner.AddSwepCheck = function(name, shouldUseFunc, shouldDrawFunc, enabled)
	table.insert(SWEPChecks, {
		name=name,
		ShouldUse=shouldUseFunc,
		ShouldDraw=shouldDrawFunc,
		enabled=enabled ~= nil and enabled or true
	})
end

local IndexOfSwepCheck = function(name)
	local index = 0

	for i, check in pairs(SWEPChecks) do
		if check.name == name then
			index = i
			break
		end
	end

	return index
end

CrosshairDesigner.SetSwepCheckEnabled = function(name, newVal)
	local index = IndexOfSwepCheck(name)

	if index and tobool(newVal) ~= nil then
		SWEPChecks[index].enabled = newVal
	end
end

CrosshairDesigner.MakeSwepCheckTopPriority = function(name) -- untested
	local index = IndexOfSwepCheck(name)

	if index then
		local copy = table.Copy(SWEPChecks[index])
		table.remove(SWEPChecks, index)
		table.insert(SWEPChecks, 1, copy)
	end
end

hook.Add("CrosshairDesigner_ShouldHideCross", "CrosshairDesigner_SWEPCheck", function()
	if not shouldDraw then
		return true
	end
end)

hook.Add("CrosshairDesigner_ValueChanged", "UpdateSWEPCheck", function()
	ply = LocalPlayer()

	if IsValid(ply) then
		wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			UpdateSWEPCheck(ply, wep)
		end
	end
end)