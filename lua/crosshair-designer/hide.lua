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

function CrosshairDesigner.IsAddonSupported(wsid)
	-- Not 100% true due to checks being able to be applied for other packs
	-- if fnIsValid passes + not all supported addons and linked with wsid
	return wsidCrossChecks[wsid] ~= nil
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

	-- Find specific to addon using WSID
	if wep.BaseWeaponWSID and wsidCrossChecks[wep.BaseWeaponWSID] then
		cachedCrossChecks[baseClass] = {wsidCrossChecks[wep.BaseWeaponWSID][SHOULDHIDE]}
		return cachedCrossChecks[baseClass]
	elseif wep.WeaponWSID and wsidCrossChecks[wep.WeaponWSID] then
		cachedCrossChecks[wepClass] = {wsidCrossChecks[wep.WeaponWSID][SHOULDHIDE]}
		return cachedCrossChecks[wepClass]
	end

	-- Use cached
	if cachedCrossChecks[wepClass] then
		return cachedCrossChecks[wepClass]
	elseif cachedCrossChecks[baseClass] then
		return cachedCrossChecks[baseClass]
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
			CrosshairDesigner.AddConvarDetour("act3_hud_crosshair_enable", 0)
			CrosshairDesigner.AddConvarDetour("arccw_crosshair", 0)
		else
			CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
			CrosshairDesigner.RemoveConvarDetour("act3_hud_crosshair_enable")
			CrosshairDesigner.RemoveConvarDetour("arccw_crosshair", 0)
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
	WSID swep cache

	Reduce filesystem reads to greatly increase subsequent loading times 

	{
		addons: {wsid: lastUpdated},
		sweps: {class: [wsid,...]}  -- on load, filter wsid by mounted
	}
]]--

local wsidCacheFile = "crosshair_designer/swep_cache.json"

local function shouldCheckAddon(addon)
	return addon.mounted and string.find(addon.tags, "Weapon")
end

local function SWEPCache(filePath)
	local uncommitted = 0
	local cached = file.Exists(filePath, "DATA") and util.JSONToTable(file.Read(filePath, "DATA")) or {addons = {}, sweps = {}}

	local function mountedWSID()
		local mounts = {}
		for k, addon in pairs(engine.GetAddons()) do
			if shouldCheckAddon(addon) then
				mounts[tonumber(addon.wsid)] = addon.updated
			end
		end
		return mounts
	end

	local function isUnCommitted()
		return uncommitted >= 1
	end

	local function unCommittedCount()
		return uncommitted
	end

	local function commit()
		if isUnCommitted() then
			local mounts = mountedWSID()
			for wsid, updated in pairs(mounts) do
				cached['addons'][tonumber(wsid)] = updated
			end
			file.Write(filePath, util.TableToJSON(cached))
			uncommitted = 0
		end
	end

	local function filterSWEPsByMounted(sweps, mounts)
		local mountedSWEPs = {}

		for class, wsids in pairs(sweps) do
			for k, wsid in pairs(wsids) do
				if mounts[wsid] then
					mountedSWEPs[class] = wsid
					break  -- only ever return first match - a game should never have two sweps of the same class
				end
			end
		end

		return mountedSWEPs
	end

	local function mounted()
		local mounts = mountedWSID()
		return filterSWEPsByMounted(cached['sweps'], mounts)
	end

	local function needsUpdating(wsid, lastUpdated)
		return cached['addons'][tonumber(wsid)] ~= lastUpdated
	end

	local function update(wsid, sweps)
		local wsid = tonumber(wsid)
		-- Handle added
		for k, swep in pairs(sweps) do
			if cached['sweps'][swep] then
				if not table.HasValue(cached['sweps'][swep], wsid) then
					table.insert(cached['sweps'][swep], wsid)
					uncommitted = uncommitted + 1
				end
			else
				cached['sweps'][swep] = {wsid}
				uncommitted = uncommitted + 1
			end
		end

		-- Handle removed
		for swep, wsids in pairs(cached['sweps']) do
			if table.HasValue(wsids, wsid) and not table.HasValue(sweps, swep) then
				table.RemoveByValue(cached['sweps'][swep], wsid)
				if #cached['sweps'][swep] == 0 then
					cached['sweps'][swep] = nil
				end
				uncommitted = uncommitted + 1
			end
		end
	end

	return {
		update = update,
		needsUpdating = needsUpdating,
		commit = commit,
		mounted = mounted,
		mountedWSID = mountedWSID,
		isUnCommitted = isUnCommitted,
		unCommittedCount = unCommittedCount
	}
end


--[[
	WSID finder
]]--
local periodicCoroutine = false
local swepToWSID = {}

local function IncludeSwepsFromAddon(title, wsid)
	local sweps = {}
	local files, folders = file.Find('lua/weapons/*', title)

	for i, file in pairs(files or {}) do
		table.insert(sweps, string.StripExtension(file))
	end
	for i, folder in pairs(folders or {}) do
		table.insert(sweps, folder)
	end

	return sweps
end

local function PeriodicSwepScan()
	local swepCache = SWEPCache(wsidCacheFile)
	global_SWEPCACHE = swepCache
	local sweps = {}

	swepToWSID = swepCache.mounted()

	local function check(addon)
		if shouldCheckAddon(addon) and swepCache.needsUpdating(addon.wsid, addon.updated) then
			sweps = IncludeSwepsFromAddon(addon.title, addon.wsid)
			swepCache.update(addon.wsid, sweps)
		end
	end

	-- Initial load -- will be slowest if first time
	for k, addon in pairs(engine.GetAddons()) do
		for i=1, 5 do coroutine.yield() end
		check(addon)
	end

	if swepCache.isUnCommitted() then
		local changes = swepCache.unCommittedCount()
		swepToWSID = swepCache.mounted()
		swepCache.commit()
		CrosshairDesigner.Print("Updated swep wsid cache with " .. tostring(changes) .. " changes")
	else
		CrosshairDesigner.Print("Used purely cached swep wsid matching")
	end

	coroutine.yield()

	CrosshairDesigner.FinishLoad = SysTime()
	local time = math.Round(CrosshairDesigner.FinishLoad - CrosshairDesigner.StartLoad, 2)
	CrosshairDesigner.Print("Finished loading in " .. time .. " seconds")
	hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)

	-- Periodic load for sweps mounted during game
	while true do
		for k, addon in pairs(engine.GetAddons()) do
			for i=1, 5 do coroutine.yield() end
			check(addon)
		end
		if swepCache.isUnCommitted() then
			swepToWSID = swepCache.mounted()
			swepCache.commit()
		end
	end
end

local function WeaponWSID(swepClass)
	if swepToWSID[swepClass] ~= nil then return swepToWSID[swepClass] end
end
CrosshairDesigner.WeaponWSID = WeaponWSID

local periodicCoroutine = coroutine.create(PeriodicSwepScan)
hook.Add("Think", "CrosshairDesigner_SWEPScan", function()
	local success, err = coroutine.resume(periodicCoroutine)

	if not success then
		CrosshairDesigner.Print("Errored", err)
		hook.Remove("Think", "CrosshairDesigner_SWEPScan")
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
		CrosshairDesigner.AddConvarDetour("act3_hud_crosshair_enable", 0)
		CrosshairDesigner.AddConvarDetour("arccw_crosshair", 0)
	else
		CrosshairDesigner.RemoveConvarDetour("cw_crosshair")
		CrosshairDesigner.RemoveConvarDetour("act3_hud_crosshair_enable")
		CrosshairDesigner.RemoveConvarDetour("arccw_crosshair", 0)
	end

	hook.Add("Think", "CrosshairDesigner_WeaponSwitchMonitor", WeaponSwitchMonitor)
end)

