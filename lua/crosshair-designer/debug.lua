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

	-- print(searchPath)

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

local function traceShouldDraw()
	local calls = {}
	local hooks = hook.GetTable()
	local hideHooks = hooks["HUDShouldDraw"]

	for k, fn in pairs(hideHooks) do
		-- Find hooks asking to hide our crosshair
		local returnVal = fn("CrosshairDesiger_Crosshair")

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

concommand.Add("crosshairdesigner_debugdump", function()
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
		['HUDShouldDraw'] = traceShouldDraw()
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