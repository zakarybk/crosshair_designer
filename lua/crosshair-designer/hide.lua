--[[
	Handles when the crosshair should be hidden or visible as a result of
	external factors (not related to crosshair settings but other addons)

	The crosshair settings can control whether the external factors should
	be a factor when deciding to hide the crosshair.

	--- API quick doc

	This is made to be used by other addons if they wish through

	CrosshairDesigner.AddSWEPCrosshairCheck( -- see load.lua for examples
		['fnIsValid'] = function(swep) <your code> return end,
		['fnShouldHide'] = function(swep) <your code> return end,
		['forceOnBaseClasses'] = ['some_base_class', 'some_other']
	)

	fnIsValid will be called whenever the player swaps SWEPs or changes
	crosshair settings if the player and active SWEP are valid

	fnShouldHide is called every frame if your check is used, and will
	hide the crosshair if you return True

	Crosshair checks will stack for weapons that have no Base class match with any check
	using forceOnBaseClasses. This allows the system to 'guess' the right response, as
	only one fnShouldHide from all those which passed fnIsValid, needs to return True
	to hide the crosshair.

	These can all be setup when CrosshairDesigner_FullyLoaded is called for example

	hook.Add("CrosshairDesigner_FullyLoaded", "MyCustomHook", function(crossTbl)
		crossTbl.AddSWEPCrosshairCheck(...)
		crossTbl.AddSWEPCrosshairCheck(...)
		crossTbl.AddSWEPCrosshairCheck(...)
	end)
	---

]]--

local hasPrefix = CrosshairDesigner.hasPrefix

local UpdateVisibility = function() end
local UpdateSWEPCheck = function() end

local DefaultSWEPShouldHide = function() return false end
local SWEPShouldHide = DefaultSWEPShouldHide

local activeWeapon = nil
local activeWeaponBase = nil
local ply
local wep
local shouldHide = false

local SWEPChecks = {} -- SWEPChecks[n].ShouldUse() SWEPChecks[n].ShouldUse.ShouldDraw()
local cachedCross = {}

local LocalPlayer = LocalPlayer
local IsValid = IsValid
local GetViewEntity = GetViewEntity

local oddCrossChecks = {} -- When weapon packs do not conform to the norm
local normCrossChecks = {} -- For everything else which can be generic
local cachedCrossChecks = {}

local ISVALID = 1
local SHOULDHIDE = 2
local ID = 3
local ONSWITCH = 4

function CrosshairDesigner.AddSWEPCrosshairCheck(tbl)
	local fnIsValid = tbl['fnIsValid']
	local fnShouldHide = tbl['fnShouldHide']
	local fnOnSwitch = tbl['onSwitch']
	local id = tbl['id'] or 'None'
	table.insert(normCrossChecks, {fnIsValid, fnShouldHide, id, fnOnSwitch})

	if tbl['forceOnBaseClasses'] then
		for k, class in pairs(tbl['forceOnBaseClasses']) do
			oddCrossChecks[class] = oddCrossChecks[class] or {}
			table.insert(oddCrossChecks[class], {fnIsValid, fnShouldHide, id, fnOnSwitch})
		end
	end
end

function CrosshairDesigner.IndexesOfCrossChecks(checks)
	local function indexOfCheck(check)
		for i, tbl in pairs(normCrossChecks) do
			if tbl[SHOULDHIDE] == check then
				return i
			end
		end
		return "Unknown"
	end

	local indexes = {}

	for k, check in pairs(checks) do
		local index = indexOfCheck(check)
		local id = normCrossChecks[index] and normCrossChecks[index][ID] or 'dumby'
		table.insert(indexes, {index = index, id = id})
	end

	return indexes
end

local function weaponCrossCheck(wep)
	local wepClass = wep:GetClass()
	local baseClass = wep.Base

	-- Use cached
	if cachedCrossChecks[wepClass] then
		return cachedCrossChecks[wepClass]
	end

	-- Find weapon specific
	if oddCrossChecks[baseClass] then
		local fnShouldHides = {}

		for k, tbl in pairs(oddCrossChecks[baseClass]) do
			if tbl[ISVALID](wep, wepClass) then
				table.insert(fnShouldHides, tbl[SHOULDHIDE])
			end
		end

		if #fnShouldHides >=1 then
			cachedCrossChecks[wepClass] = fnShouldHides
			return fnShouldHides
		end

	end

	-- Find generic checks
	local fnShouldHides = {}

	for k, tbl in pairs(normCrossChecks) do
		if tbl[ISVALID](wep, wepClass) then
			table.insert(fnShouldHides, tbl[SHOULDHIDE])
		end
	end

	-- Return generic checks and save lookup
	if #fnShouldHides >= 1 then
		cachedCrossChecks[wepClass] = fnShouldHides
		return fnShouldHides
	else
		-- Return dumby if nothing found
		return {function() return false end}
	end

end
CrosshairDesigner.WeaponCrossCheck = weaponCrossCheck

local UpdateSWEPCheck = function(ply, wep) -- local
	local checks = weaponCrossCheck(wep)
	SWEPShouldHide = function(wep)
		for k, fn in pairs(checks) do
			if fn(wep) then return true end
		end
		return false
	end
end

-- Update weapon on weapon change + update vis for every tick
local CrosshairShouldHide = function(ply, wep) -- local
	return (
		not cachedCross["ShowCross"]
		or not ply:Alive()
		or (cachedCross["HideInVeh"] and ply:InVehicle())
		or (cachedCross["HideInSpectate"] and ply:Team() == TEAM_SPECTATOR)
		or (cachedCross["HideInCameraView"] and GetViewEntity() ~= ply)
	)
end
CrosshairDesigner.CrosshairShouldHide = CrosshairShouldHide

local function RunAnyOnSwitchListeners(wep)
	local checks = weaponCrossCheck(wep)
	local checkIndexes = CrosshairDesigner.IndexesOfCrossChecks(checks)

	for i, tbl in pairs(checkIndexes) do
		local index = tbl.index
		local id = tbl.id

		if index ~= 'Unknown' and id ~= 'dumby' then
			if normCrossChecks[index][ONSWITCH] then
				normCrossChecks[index][ONSWITCH](wep)
			end
		end
	end
end

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
				activeWeaponBase = wep.Base
				UpdateSWEPCheck(ply, wep)
				RunAnyOnSwitchListeners(wep)
			end
			shouldHide = cachedCross["HideOnADS"] and (SWEPShouldHide(wep) or CrosshairShouldHide(ply, wep))
		else
			shouldHide = cachedCross["HideOnADS"] and CrosshairShouldHide(ply, wep)
		end

	end

end


hook.Add("HUDShouldDraw", "CrosshairDesigner_ShouldHideCross", function(name)
	-- Hide default crosshair when disabled in the menu
	-- Hide default crosshair when held weapon is TFA and HideWeaponCrosshair enabled
	-- Hide our crosshair when shouldHide is true
	if name == "CHudCrosshair" and
	(
		(not cachedCross["ShowHL2"])
		or
		(cachedCross["HideWeaponCrosshair"] and activeWeaponBase and hasPrefix(activeWeaponBase, "tfa_"))
	) 
	or 
	(
		shouldHide and name == "CrosshairDesiger_Crosshair"
	) then
		return false
	end
end)

local function thirdpersonAddonCrosshairPatch(showDefault)
	-- patch for https://steamcommunity.com/sharedfiles/filedetails/?id=207948202
	-- not everyone realises this addon also disables the default crosshair with
	-- its own option
	if showDefault then
		var = GetConVar("simple_thirdperson_hide_crosshair")
		if var ~= nil and var:GetBool() then
			RunConsoleCommand("simple_thirdperson_hide_crosshair", 0)
		end
	end
end

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

	if id == "HideWeaponCrosshair" then
		if val then
			CrosshairDesigner.AddConvarDetour("cw_crosshair", 0)
		else
			CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
		end
	end
	-- TTT crosshair is being handled directly in detour.lua
	-- TFA hides with HUDShouldDraw CHudCrosshair

	-- Re-enable default crosshair if disabled elsewhere
	if data.id == "ShowHL2" then
		thirdpersonAddonCrosshairPatch(true)
	end
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
	if cachedCross["HideWeaponCrosshair"] then
		CrosshairDesigner.AddConvarDetour("cw_crosshair", 0)
	else
		CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
	end

	hook.Add("Think", "CrosshairDesigner_WeaponSwitchMonitor", WeaponSwitchMonitor)
end)

