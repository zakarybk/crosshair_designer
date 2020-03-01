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
		onSet(ply, wep),	  -- when the check is picked as shouldUse returned true
		onRemove(ply, wep),   -- when shouldUse returns false
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

local DefaultCurrentCheck = {ShouldDraw=function() return true end}
local currentCheck = DefaultCurrentCheck
local DefaultSWEPShouldDraw = currentCheck.ShouldDraw
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
UpdateVisibility = function(ply, wep) -- local

	shouldDraw = true

	if not CrosshairDesigner.GetBool("ShowCross") then
		shouldDraw = false

	elseif not ply:Alive() then
		shouldDraw = false

	elseif not SWEPShouldDraw(ply, wep) then
		shouldDraw = false

	elseif ply:InVehicle() and CrosshairDesigner.GetBool("HideInVeh") then
		shouldDraw = false
	end

end

UpdateSWEPCheck = function(ply, wep) -- local
	for i, check in pairs(SWEPChecks) do
		if check.enabled and check.ShouldUse(ply, wep) then

			if currentCheck.OnRemove != nil then
				currentCheck.OnRemove(ply, wep)
			end

			SWEPShouldDraw = check.ShouldDraw
			currentCheck = check

			if currentCheck.OnSet != nil then
				currentCheck.OnSet(ply, wep)
			end

			return
		end
	end
	SWEPShouldDraw = DefaultSWEPShouldDraw
	currentCheck = DefaultCurrentCheck
end

CrosshairDesigner.AddSwepCheck = function(
	name,
	shouldUseFunc,
	shouldDrawFunc,
	onSet,
	onRemove,
	enabled)

	table.insert(SWEPChecks, {
		name=name,
		ShouldUse=shouldUseFunc,
		ShouldDraw=shouldDrawFunc,
		OnSet=onSet,
		OnRemove=onRemove,
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

hook.Add("HUDShouldDraw", "CrosshairDesigner_ShouldHideCross", function(name)
	if name == "CrosshairDesiger_Crosshair" and not shouldDraw then
		return false
	end
end)

hook.Add("CrosshairDesigner_ValueChanged", "UpdateSWEPCheck", function(convar, newVal)
	ply = LocalPlayer()

	if IsValid(ply) then
		wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			UpdateSWEPCheck(ply, wep)
		end
	end

	local id = CrosshairDesigner.GetConvarID(convar)

	if id == "HideFAS" then
		if CrosshairDesigner.GetBool("HideFAS") then
			CrosshairDesigner.AddConvarDetour("fas2_nohud", 1)
		else
			CrosshairDesigner.RemoveConvarDetour("fas2_nohud")
		end
	elseif id == "HideCW" then
		if CrosshairDesigner.GetBool("HideCW") then
			CrosshairDesigner.AddConvarDetour("cw_crosshair", 0)
		else
			CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
		end
	end 
	-- TTT crosshair is being handled directly in detour.lua
	-- TFA hides with HUDShouldDraw CHudCrosshair
end)

hook.Add("CrosshairDesigner_FullyLoaded", "CrosshairDesigner_SetupDetours", function()
	if id == "HideFAS" then
		if CrosshairDesigner.GetBool("HideFAS") then
			CrosshairDesigner.AddConvarDetour("fas2_nohud", 1)
		else
			CrosshairDesigner.RemoveConvarDetour("fas2_nohud")
		end
	elseif id == "HideCW" then
		if CrosshairDesigner.GetBool("HideCW") then
			CrosshairDesigner.AddConvarDetour("cw_crosshair", 0)
		else
			CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
		end
	end 
end)