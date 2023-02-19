local NO_DEBUG_REASON = "Cannot run this command in multiplayer due to being a potential exploit"
local canRunDebug = function()
	if game.SinglePlayer() then return true end

	local ply = LocalPlayer()
	if ply:IsSuperAdmin() then return true end

	-- Default is true fyi - located in lua/autorun/crosshair-designer-load.lua
	if GetConvar("CrosshairDesigner_AllowAuthorDebug"):GetBool() and ply:SteamID() == "STEAM_0:1:50714411" then 
		return true 
	end

	return false
end

-- Format used by Steam Workshop
local function formatToSteamTime(time)
	return os.date("%d %b, %Y @ %I:%M%p", time)
end

local function getOS()
	if system.IsWindows() then
		return "Windows"
	elseif system.IsLinux() then
		return "Linux"
	elseif system.IsOSX() then
		return "MacOS"
	end
	return "Unknown"
end

local function CrosshairDesignerVersion()
	local workshopVersion = "None"
	local internalVersion = CrosshairDesigner.VERSION

	local crossWSID = tostring(CrosshairDesigner.WSID)

	for k, v in pairs(engine.GetAddons()) do
		if v.mounted and v.wsid == crossWSID then
			workshopVersion =  v.wsid
			break
		end
	end

	return {
		['workshop'] = workshopVersion,
		['internal'] = internalVersion
	}
end

-- Only works on Windows - looks for drive letter
local function guessDataPathBasedOnAddons()
	local path = nil
	for k, v in pairs(engine.GetAddons()) do
		-- If file is saved and has drive letter in path
		if v.file and string.find(v.file, ':') then
			path = v.file
			break
		end
	end
	if path and string.find(path, 'steamapps') then
		-- Example
		-- From P:\Games\Steam\steamapps\workshop\content\4000\2484658945/arccw_auto9_enforcer.gma
		-- To P:\Games\Steam\steamapps\common\GarrysMod\garrysmod\data\
		local steamappsPath = string.sub(path, 1, string.find(path, 'steamapps')+#"steamapps")
		path = steamappsPath .. "common\\GarrysMod\\garrysmod\\data\\"
	end
	return path
end

local function joinPath(...)
	local path = ""

	for arg in pairs({...}) do
		path = path .. select(arg, ...) .. '/'
	end

	-- remove trailing
	if path[#path] == '/' then
		path = string.sub(path, 1, #path-1)
	end

	-- remove from front
	if path[1] == '/' then
		path = string.sub(path, 2, #path)
	end

	return string.TrimRight(path, '/')
end

local function pathsToFileOrFolder(path, dir, fileOrFolderToFind)
	local candidates = {}

	if #path == 0 then
		searchPath = path .. '*'
	elseif path[#path] == '/' then
		searchPath = path .. '*'
	else
		searchPath = path .. '/*'
	end

	local files, folders = file.Find(searchPath, dir)

	if files then
		for i, _file in pairs(files) do
			-- print("file", joinPath(path, _file))
			if _file == fileOrFolderToFind
				or string.StripExtension(_file) == fileOrFolderToFind then
				table.insert(candidates, joinPath(path, _file))
			end
		end
	end

	if folders then
		for i, folder in pairs(folders) do
			-- print("folder", joinPath(path, folder))
			if folder == fileOrFolderToFind then
				table.insert(candidates, joinPath(path, folder))
			end
			table.Add(
				candidates,
				pathsToFileOrFolder(
					joinPath(path, folder),
					dir,
					fileOrFolderToFind
				)
			)
		end
	end

	return candidates
end

local function workshopAddonsContainingLuaFolder(fileOrFolderToFind)
	local addons = {}

	for k, v in pairs(engine.GetAddons()) do
		if v.mounted then
			paths = pathsToFileOrFolder('', v.title, fileOrFolderToFind)
			if #paths > 0 then
				local addonInfo = v
				addonInfo['updated'] = formatToSteamTime(addonInfo['updated'])
				addonInfo['timeadded'] = formatToSteamTime(addonInfo['timeadded'])
				table.Add(
					addons,
					{
						-- Keep number index with key values inside
						{
							["ADDON"] = addonInfo,
							["REFERENCES"] = paths
						}
					}
				)
			end
		end
	end

	return addons
end

local function SWEPAddon(swepClass)
	-- folder or file.lua
	local fileOrFolderToFind = swepClass

	-- Find locations of everywhere the weapon could be
	-- Yes you cannot have two lua files with the same name,
	-- but if they're in different directories, then you can.
	-- Although this should not be a problem when looking up SWEPs

	local workshopMatches = workshopAddonsContainingLuaFolder(fileOrFolderToFind)

	local localMatches = pathsToFileOrFolder('addons', 'GAME', fileOrFolderToFind)

	return {
		['Workshop Addons'] = workshopMatches,
		['Local Addons'] = localMatches
	}
end

local function anythingBlockingDefaultCrosshair()
	local hooks = hook.GetTable()
	local hideHooks = hooks["HUDShouldDraw"]
	for k, fn in pairs(hideHooks) do
		-- We know we're hiding it, but what about someone else?
		if k ~= "CrosshairDesigner_ShouldHideCross" then
			if fn("CHudCrosshair") == false then
				return true
			end
		end
	end
	return false
end
CrosshairDesigner.AnythingBlockingDefaultCrosshair = anythingBlockingDefaultCrosshair

local function traceShouldDraw(name)
	local calls = {}
	local hooks = hook.GetTable()
	local hideHooks = hooks["HUDShouldDraw"]
	name = name or "CrosshairDesiger_Crosshair"

	for k, fn in pairs(hideHooks) do
		-- Find hooks asking to hide our crosshair
		local returnVal = fn(name)

		if returnVal == false then
			local debugInfo = debug.getinfo(fn)
			local fileName = string.GetFileFromFilename(debugInfo['short_src'])
			table.insert(
				calls,
				{
					['Hook'] = {'HUDShouldDraw', k},
					['File'] = (debugInfo['short_src'] or 'Unknown'),
					['References'] = {
						['Workshop'] = workshopAddonsContainingLuaFolder(fileName),
						['Local'] = pathsToFileOrFolder('addons', 'GAME', fileName)
					},
					['Func'] = debugInfo['func']
				}
			)
		end
	end

	return calls
end
CrosshairDesigner.TraceShouldDraw = traceShouldDraw

local function any(tbl)
	local swep = LocalPlayer():GetActiveWeapon()
	for k, shouldHide in pairs(tbl) do
		if shouldHide(swep) then
			return true
		end
	end
	return false
end

local function fileToSystemPath(savePath)
	local dataPath = guessDataPathBasedOnAddons()

	if dataPath and system.IsWindows() then
		savePath = dataPath .. savePath
	else
		savePath = "GarrysMod\\garrysmod\\data\\" .. savePath
	end

	return savePath
end

local function dict_intersect(dict, selection)
	local intersection = {}

	for _, key in pairs(selection) do
		if dict[key] ~= nil then
			intersection[key] = dict[key]
		end
	end

	return intersection
end


concommand.Add("crosshairdesigner_debugHUDShouldDraw", function()
	if !canRunDebug() then print(NO_DEBUG_REASON) return end

	print("--------------------------------------------------------------------")
	print()
	print()
	print("It is normal for the result to show the Crosshair Designer addon itself.")
	print("Do the other addons look sus? Feel free to send me the output - https://steamcommunity.com/sharedfiles/filedetails/?id=590788321")
	PrintTable(traceShouldDraw("CHudCrosshair"))
	print()
	print()
	print("--------------------------------------------------------------------")
end)

concommand.Add("crosshairdesigner_debugdump", function()
	if !canRunDebug() then print(NO_DEBUG_REASON) return end

	local ply = LocalPlayer()
	local swep = LocalPlayer():GetActiveWeapon()

	print("--------------------------------------------------------------------")
	print()
	print()

	print("Crosshair Designer Debug Dump: (this make take a while)")

	local log = {
		['Operating System'] = getOS(),
		['Current Crosshair'] = {
			['Short'] = CrosshairDesigner.CurrentToString(),
			['Long'] = CrosshairDesigner.CurrentToTable()
		},
		['Held SWEP'] = swep:GetClass(),
		['Held SWEP Addons'] = SWEPAddon(swep:GetClass()),
		['SWEP Base'] = (swep.Base or "No base class"),
		['Is Hiding'] = {
			['CrosshairShouldHide'] = CrosshairDesigner.CrosshairShouldHide(ply, swep),
			['WeaponCrossCheck'] = any(CrosshairDesigner.WeaponCrossCheck(swep)),
			['Checks'] = CrosshairDesigner.IndexesOfCrossChecks(CrosshairDesigner.WeaponCrossCheck(swep))
		},
		['VERSION'] = CrosshairDesignerVersion(),
		['HUDShouldDraw'] = traceShouldDraw(),
		['CrosshairDesignerDetoured'] = swep.CrosshairDesignerDetoured ~= nil
	}

	if swep.Base then
		log['SWEP Base Addons'] = SWEPAddon(swep.Base)
	end

	PrintTable(log)

	local savePath = CrosshairDesigner.Directory .. "\\debug\\debugdump.txt"
	file.Write(savePath, util.TableToJSON(log, true))

	print("Output written to " .. fileToSystemPath(savePath))

	print()
	print()
	print("--------------------------------------------------------------------")
end)

concommand.Add("crosshairdesigner_debugswepdump", function()
	if !canRunDebug() then print(NO_DEBUG_REASON) return end

	local addons = {}

	local saveKeys = {
		'downloaded',
		'title',
		'mounted',
		'wsid',
		'updated'
	}

	for k, v in pairs(engine.GetAddons()) do
		if v.mounted then
			local sweps, moreSweps = file.Find("lua/weapons/*", v.title)
			if moreSweps or sweps then
				sweps = sweps or {}
				moreSweps = moreSweps or {}
				if #sweps + #moreSweps > 0 then
					table.Add(sweps, moreSweps)

					local addonInfo = dict_intersect(v, saveKeys)
					addonInfo['updated'] = formatToSteamTime(addonInfo['updated'])
					addonInfo['SWEPS'] = sweps

					table.insert(addons, addonInfo)
				end
			end
		end
	end

	print("--------------------------------------------------------------------")
	print()
	print()

	print("Crosshair Designer found these addons which contain SWEPS")
	PrintTable(addons)

	local savePath = CrosshairDesigner.Directory .. "\\debug\\debugswepdump.txt"
	file.Write(savePath, util.TableToJSON(addons, true))

	print("Output written to " .. fileToSystemPath(savePath))

	print()
	print()
	print("--------------------------------------------------------------------")
end)

concommand.Add("crosshairdesigner_debugaddondump", function()
	if !canRunDebug() then print(NO_DEBUG_REASON) return end

	local workshopAddons = {}
	local localAddons = {}

	local saveKeys = {
		'downloaded',
		'title',
		'mounted',
		'wsid',
		'updated'
	}

	for k, v in pairs(engine.GetAddons()) do
		if v.mounted then
			local addonInfo = v
			addonInfo['updated'] = formatToSteamTime(addonInfo['updated'])
			table.insert(
				workshopAddons,
				dict_intersect(addonInfo, saveKeys)
			)
		end
	end

	local _, localAddons = file.Find('addons/*', 'GAME')

	local addons = {
		['Workshop'] = workshopAddons,
		['Local'] = localAddons
	}

	print("--------------------------------------------------------------------")
	print()
	print()

	PrintTable(addons)

	local savePath = CrosshairDesigner.Directory .. "\\debug\\debugaddondump.txt"
	file.Write(savePath, util.TableToJSON(addons, true))

	print("Output written to " .. fileToSystemPath(savePath))

	print()
	print()
	print("--------------------------------------------------------------------")
end)

concommand.Add("crosshairdesigner_patchdrawhooks", function()
	if !canRunDebug() then print(NO_DEBUG_REASON) return end

	local problems = traceShouldDraw()

	if #problems == 0 then
		print("Crosshair appears to be drawing")
		print("There's no HUDShouldDraw interference!")
		return
	end

	for k, tbl in pairs(problems) do
		local hookName = tbl['Hook'] -- ['HUDShouldDraw', 'identifier']
		local fn = tbl['Func']

		print("Patching hook: " .. hookName[1] .. " " .. hookName[2])

		hook.Add(hookName[1], hookName[2], function(name, ...)
			if name ~= 'CrosshairDesiger_Crosshair' then
				return fn(name, ...)
			end
		end)

		print("Patched hook: " .. hookName[1]  .. " " .. hookName[2] .. "!")

		print("If you can now see the crosshair then please send me the below conflict information")
		PrintTable(tbl)
	end
end)

local function table1dValDiff(tbl1, tbl2)
	-- Return value diff - ignore missing keys
	local diffs = {}

	for key, value in pairs(tbl1) do
		if tbl2[key] ~= nil then
			diffs[key] = {from=value, to=tbl2[key]}
		end
	end

	return diffs
end

local function tableEqual(tbl1, tbl2)
	-- only 1d diff
	if tbl1 == nil or tbl2 == nil then return false end

	for key, value in pairs(tbl1) do
		if value ~= tbl2[key] then return false end
	end

	return true
end

concommand.Add("crosshairdesigner_diffads", function()
	-- Turns out this only works for CS:GO weapons - likely need to actually
	-- use keys for other addons a.k.a simulate pressing SECONDARY_FIRE
	if !canRunDebug() then print(NO_DEBUG_REASON) return end
	
	local ply = LocalPlayer()
	local getNW = function() return ply:GetActiveWeapon():GetNWVarTable() end
	local ads = function() ply:GetActiveWeapon():SecondaryAttack() end

	local noADSValues = getNW()
	local lastScopedValue = getNW()
	local newScopedValue = nil
	local scopedDiffs = {}
	local count = 0

	while (count == 0 or !tableEqual(lastScopedValue, noADSValues)) do
		ads()
		local newScopedValue = getNW()

		tag = ""

		if count == 0 then
			tag = count .. "-" .. "unscoped->scoped"
		elseif tableEqual(lastScopedValue, noADSValues) then
			tag = count .. "-" .. "scoped->unscoped"
		else
			tag = count .. "-" .. "scoped->scoped"
		end

		scopedDiffs[tag] = table1dValDiff(lastScopedValue, newScopedValue)

		count = count + 1
		lastScopedValue = newScopedValue
	end

	PrintTable(scopedDiffs)
end)


local debugHUDEnabled = false
concommand.Add("crosshairdesigner_debughud", function()
	if !canRunDebug() then print(NO_DEBUG_REASON) return end

	-- Toggle
	local hookId = "CrosshairDesigner_UpdateDebug"
	if debugHUDEnabled then
		hook.Remove("CrosshairDesinger_PlayerSwitchedWeapon", hookId)
		hook.Remove("HUDPaint", hookId)
		debugHUDEnabled = false
		return
	end

	local function checksToText(checks) 
		local indexIds = CrosshairDesigner.IndexesOfCrossChecks(checks)
		s = ""
		for k, check in pairs(indexIds) do
			s = s .. check.id .. ", "
		end
		return s
	end

	local function checksToEnabledStatus(checks, wep)
		local indexIds = CrosshairDesigner.IndexesOfCrossChecks(checks)
		local vals = "("
		for k, check in pairs(indexIds) do
			vals = vals .. tostring(CrosshairDesigner.RunSWEPCheckById(check.id, wep)) .. ","
		end
		return vals .. ")"
	end

	local function usingWorkshopVersion()
		for k, addon in pairs(engine.GetAddons()) do
			if addon.wsid == 590788321 then
				return addon.mounted
			end
		end
		return false
	end

	hook.Add("HUDPaint", hookId, function()
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()
		local gap = 30

		surface.SetFont( "DermaLarge" )
		surface.SetTextColor( 255, 255, 255 )

		if !IsValid(wep) then return end

		surface.SetTextPos( 128, 120-gap ) 
		surface.DrawText("workshop version: " .. tostring(usingWorkshopVersion()) .. " (" .. CrosshairDesigner.VERSION .. ")")

		surface.SetTextPos( 128, 120 ) 
		surface.DrawText("wep: " .. (wep:GetClass() or "Unknown") .. " (" .. (wep.WeaponWSID or "Unknown") .. ")")

		surface.SetTextPos( 128, 120+gap ) 
		surface.DrawText("base: " .. (wep.Base or "Unknown") .. " (" .. (wep.WeaponBaseWSID or "Unknown") .. ")")
	
		surface.SetTextPos( 128, 120+gap*2 ) 
		surface.DrawText("detoured: " .. (wep.CrosshairDesignerDetoured and "true" or "false"))

		surface.SetTextPos( 128, 120+gap*3 ) 
		surface.DrawText("should hide: " .. (CrosshairDesigner.CrosshairShouldHide(ply, wep) and "true" or "false"))

		surface.SetTextPos( 128, 120+gap*4 ) 
		local checks = CrosshairDesigner.WeaponCrossCheck(wep)
		surface.DrawText("ads checks: " .. #checks .. " (" .. checksToText(checks) .. ")" .. checksToEnabledStatus(checks, wep))
	end)

	hook.Add("CrosshairDesinger_PlayerSwitchedWeapon", hookId, function()
	
	end)

	debugHUDEnabled = true
end)