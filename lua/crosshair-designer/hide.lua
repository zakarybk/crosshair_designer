--[[
	Handles when the crosshair should be hidden or visible as a result of 
	external factors (not related to crosshair settings but other addons)

	The crosshair settings can control whether the external factors should
	be a factor when deciding to hide the crosshair.
]]--

local UpdateVisability = function() end
local UpdateSWEPCheck = function() end
local SWEPShouldDraw = function() end

local activeWeapon = nil
local ply
local wep
local shouldDraw = true

hook.Add("Think", "CrosshairDesigner_WeaponSwitchMonitor", function()

	ply = LocalPlayer()

	if IsValid(ply) then
		wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			if activeWeapon != wep then
				activeWeapon = wep
				UpdateSWEPCheck(ply, wep)
			end
		end

		UpdateVisability(ply, wep)
	end

end)

-- Update weapon on weapon change + update vis for every tick?
local UpdateVisability = function(ply, wep)

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

local UpdateSWEPCheck = function(ply, wep)
	-- Check.ShouldUse Check.ShouldDraw
	-- If FA:S use FA:S check etc
	SWEPShouldDraw = function() return true end
end

hook.Add("CrosshairDesigner_ShouldHideCross", "CrosshairDesigner_SWEPCheck", function()
	if not shouldDraw then
		return true
	end
end)