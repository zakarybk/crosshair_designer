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
local shouldDraw = false

local SWEPChecks = {} -- SWEPChecks[n].ShouldUse() SWEPChecks[n].ShouldUse.ShouldDraw()
local cachedCross = {}

local LocalPlayer = LocalPlayer
local IsValid = IsValid
local GetViewEntity = GetViewEntity

-- GM:PlayerSwitchWeapon "This hook is predicted. This means that in singleplayer,
-- it will not be called in the Client realm."
-- https://wiki.facepunch.com/gmod/GM:PlayerSwitchWeapon
local function WeaponSwitchMonitor()

	local ply = LocalPlayer()

	if IsValid(ply) then
		local wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			if activeWeapon ~= wep then
				activeWeapon = wep
				UpdateSWEPCheck(ply, wep)
			end
			shouldDraw = SWEPShouldDraw(ply, wep) and CrosshairShouldDraw(ply, wep)
		else
			shouldDraw = CrosshairShouldDraw(ply, wep)
		end

	end

end

-- Update weapon on weapon change + update vis for every tick
CrosshairShouldDraw = function(ply, wep) -- local
	if (not cachedCross["ShowCross"]) or
		(not ply:Alive()) or
		(cachedCross["HideInVeh"] and ply:InVehicle()) or
		(cachedCross["HideInSpectate"] and ply:Team() == TEAM_SPECTATOR) or
		(cachedCross["HideInCameraView"] and GetViewEntity() ~= ply)
		then
		return false
	end
	return true
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
		-- Hide our crosshair
	if (not shouldDraw and name == "CrosshairDesiger_Crosshair") or
		--Hide HL2 (+TFA) crosshair
		(name == "CHudCrosshair" and not cachedCross["ShowHL2"]) then
		return false
	end
end)

hook.Add("CrosshairDesigner_ValueChanged", "UpdateSWEPCheck", function(convar, val)
	local data = CrosshairDesigner.GetConvarData(convar)
	if not data then return end
	cachedCross[data.id] = val

	ply = LocalPlayer()

	if IsValid(ply) then
		wep = ply:GetActiveWeapon()

		if IsValid(wep) then
			UpdateSWEPCheck(ply, wep)
		end
	end

	local id = CrosshairDesigner.GetConvarID(convar)

	if id == "HideFAS" then
		if val then
			CrosshairDesigner.AddConvarDetour("fas2_nohud", 1)
		else
			CrosshairDesigner.RemoveConvarDetour("fas2_nohud")
		end
	elseif id == "HideCW" then
		if val then
			CrosshairDesigner.AddConvarDetour("cw_crosshair", 0)
		else
			CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
		end
	end
	-- TTT crosshair is being handled directly in detour.lua
	-- TFA hides with HUDShouldDraw CHudCrosshair
end)

hook.Add("CrosshairDesigner_FullyLoaded", "CrosshairDesigner_SetupDetours", function()
	-- Cache values locally
	for i, data in pairs(CrosshairDesigner.GetConvarDatas()) do
		if data.isBool then
			cachedCross[data.id] = CrosshairDesigner.GetBool(data.id)
		else
			cachedCross[data.id] = CrosshairDesigner.GetInt(data.id)
		end
	end

	-- Load detours if set to active
	if cachedCross["HideFAS"] then
		CrosshairDesigner.AddConvarDetour("fas2_nohud", 1)
	else
		CrosshairDesigner.RemoveConvarDetour("fas2_nohud")
	end
	if cachedCross["HideCW"] then
		CrosshairDesigner.AddConvarDetour("cw_crosshair", 0)
	else
		CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
	end

	hook.Add("Think", "CrosshairDesigner_WeaponSwitchMonitor", WeaponSwitchMonitor)
end)
