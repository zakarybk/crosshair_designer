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
		['forceOnBaseClasses'] = {'some_base_class', 'some_other'},
		['forceOnWSID'] = {123456, 666666}
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
local holdingTFA = false
local ply
local wep
local shouldHide = false

local SWEPChecks = {} -- SWEPChecks[n].ShouldUse() SWEPChecks[n].ShouldUse.ShouldDraw()
local cachedCross = {}

local LocalPlayer = LocalPlayer
local IsValid = IsValid
local GetViewEntity = GetViewEntity

local oddCrossChecks = {} -- When weapon packs do not conform to the norm
local wsidCrossChecks = {} -- Target specific weapon packs
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

	if tbl['forceOnWSID'] then
		for k, wsid in pairs(tbl['forceOnWSID']) do
			wsidCrossChecks[wsid] = {fnIsValid, fnShouldHide, id, fnOnSwitch}
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
	elseif cachedCrossChecks[baseClass] then
		return cachedCrossChecks[baseClass]
	end

	-- Find specific to addon using WSID
	if wep.BaseWeaponWSID and wsidCrossChecks[wep.BaseWeaponWSID] then
		cachedCrossChecks[baseClass] = {wsidCrossChecks[wep.BaseWeaponWSID][SHOULDHIDE]}
		return cachedCrossChecks[baseClass]
	elseif wep.WeaponWSID and wsidCrossChecks[wep.WeaponWSID] then
		cachedCrossChecks[wepClass] = {wsidCrossChecks[wep.WeaponWSID][SHOULDHIDE]}
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
			return cachedCrossChecks[wepClass]
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

CrosshairDesigner.RunSWEPCheckById = function(id, wep)
	for k, v in pairs(normCrossChecks) do
		if v[ID] == id then
			return v[SHOULDHIDE](wep) and true or false
		end
	end
	return false
end

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
				holdingTFA = wep.Base and hasPrefix(wep.Base, "tfa_")
				wep.WeaponWSID = CrosshairDesigner.WeaponWSID(wep:GetClass())
				wep.BaseWeaponWSID = CrosshairDesigner.WeaponWSID(wep.Base)
				UpdateSWEPCheck(ply, wep)
				RunAnyOnSwitchListeners(wep)
				-- Run hook for any external addons / for our menu
				hook.Run("CrosshairDesinger_PlayerSwitchedWeapon", ply, wep)
			end
			shouldHide = (cachedCross["HideOnADS"] and SWEPShouldHide(wep)) or CrosshairShouldHide(ply, wep)
		else
			shouldHide = CrosshairShouldHide(ply, wep)
		end

	end

end


hook.Add("HUDShouldDraw", "CrosshairDesigner_ShouldHideCross", function(name)
	-- Hide default crosshair when disabled in the menu
	-- Hide default crosshair when held weapon is TFA and HideWeaponCrosshair enabled
	-- Hide our crosshair when shouldHide is true
	-- TFA crosshair hides on CHudCrosshair - same as default HL2 crosshair
	if name == "CHudCrosshair" and
	(
		(not cachedCross["ShowHL2"] and not holdingTFA)
		or
		(cachedCross["HideWeaponCrosshair"] and holdingTFA)
	) 
	or 
	(
		shouldHide and name == "CrosshairDesiger_Crosshair"
	) 
	or not GetConVar("cl_drawhud"):GetBool() -- hide for screenshots
	then
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
	if data.id == "ShowHL2" and tobool(val) then
		thirdpersonAddonCrosshairPatch(true)
		-- If crosshair is still hidden, then let the user know
		timer.Simple(1, function()
			if CrosshairDesigner.AnythingBlockingDefaultCrosshair() then
				chat.AddText(Color(46, 248, 48), "[CrosshairDesigner]", Color(240,240,240), " Another addon is hiding the default crosshair! Run crosshairdesigner_debugHUDShouldDraw in console for more information (will freeze game)")
			end
		end)
	end
end)


--[[
	WSID finder
]]--


local function optimisedOrder(addons)
	-- Optimised order for finding file for weapon
	local firstSet = {}
	local secondSet = {}

	for k, v in ipairs(addons) do
		if v.mounted then
			if string.find(v.tags, "Weapon") then
				table.insert(firstSet, k)
			else
				table.insert(secondSet, k)
			end
		end
	end

	return table.Add(firstSet, secondSet)
end


local initialCoroutine = false
local periodicCoroutine = false
local initialcoroutineFinished = false
local swepToWSID = {}
local processedAddons = {}

local function IncludeSwepsFromAddon(title, wsid)
	local files, folders = file.Find('lua/weapons/*', title)

	for i, file in pairs(files or {}) do
		swepToWSID[string.StripExtension(file)] = tonumber(wsid)
	end
	for i, folder in pairs(folders or {}) do
		swepToWSID[folder] = tonumber(wsid)
	end

	processedAddons[wsid] = true
end

local function InitalSwepScan()
	local addons = engine.GetAddons()
	local order = optimisedOrder(addons)

	for k, _ in pairs(order) do
		selected = addons[k]

		coroutine.yield()
		IncludeSwepsFromAddon(selected.title, selected.wsid)
	end

	initialcoroutineFinished = true
end

local function PeriodicSwepScan()
	while true do
		for k, addon in pairs(engine.GetAddons()) do
			if k%50 == 0 then coroutine.yield() end -- 50 at a time
			if addon.mounted and processedAddons[addon.wsid] == nil then
				IncludeSwepsFromAddon(addon.title, addon.wsid)
			end
		end
	end
end

local function WeaponWSID(swepClass)
	if swepToWSID[swepClass] ~= nil then return swepToWSID[swepClass] end
end
CrosshairDesigner.WeaponWSID = WeaponWSID

hook.Add("Think", "CrosshairDesigner_SWEPScan", function()
	if initialcoroutineFinished then
		CrosshairDesigner.FinishLoad = SysTime()
		time = math.Round(CrosshairDesigner.FinishLoad - CrosshairDesigner.StartLoad, 2)
		print("Finished loading crosshair designer (590788321) in " .. time .. " seconds")
		hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)
		hook.Remove("Think", "CrosshairDesigner_SWEPScan")
		return
	end

	if not initialCoroutine then
		initialCoroutine = coroutine.create(InitalSwepScan)
		periodicCoroutine = coroutine.create(PeriodicSwepScan)
		timer.Create("CrosshairDesigner_PeriodicSWEPScan", 1, 0, function()
			coroutine.resume(periodicCoroutine)
		end)
	end

	coroutine.resume(initialCoroutine)
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

