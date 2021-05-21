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
			if string.StripExtension(_file) == fileOrFolderToFind then
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
				table.Add(
					addons,
					{
						-- Keep number index with key values inside
						{
							["ADDON"] = v,
							["REFERENCES"] = paths
						}
					}
				)
			end
		end
	end

	return addons
end

local function SWEPAddon(swep)
	-- folder or file.lua
	local fileOrFolderToFind = swep:GetClass()

	-- Find locations of everywhere the weapon could be
	-- Yes you cannot have two lua files with the same name,
	-- but if they're in different directories, then you can.
	-- Although this should not be a problem when looking up SWEPs

	workshopMatches = workshopAddonsContainingLuaFolder(fileOrFolderToFind)

	localMatches = pathsToFileOrFolder('addons', 'GAME', fileOrFolderToFind)

	return {
		"These are the found files relating to the SWEP you're holding (can be empty)",
		['Workshop Addons'] = workshopMatches,
		['Local Addons'] = localMatches
	}
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

concommand.Add("crosshairdesigner_debugdump", function()
	local ply = LocalPlayer()
	local swep = LocalPlayer():GetActiveWeapon()
	local swepAddons = SWEPAddon(swep)

	print("--------------------------------------------------------------------")
	print()
	print()

	print("Crosshair Designer Debug Dump:")
	print("Current Crosshair: " .. CrosshairDesigner.CurrentToString())
	print("Held SWEP: " .. swep:GetClass())
	print("SWEP Base: " .. (swep.Base or "No base class"))
	print("More details saved in the text file below!")
	PrintTable(swepAddons)

	local dataPath = guessDataPathBasedOnAddons()
	local savePath = CrosshairDesigner.Directory .. "\\debug\\debugdump.txt"
	file.Write(savePath, util.TableToJSON({
		['Current Crosshair'] = CrosshairDesigner.CurrentToString(),
		['Held SWEP'] = swep:GetClass(),
		['SWEP Base'] = (swep.Base or "No base class"),
		['SWEP Addons'] = swepAddons,
		['Is Hiding'] = {
			['CrosshairShouldHide'] = CrosshairDesigner.CrosshairShouldHide(ply, wep),
			['WeaponCrossCheck'] = any(CrosshairDesigner.WeaponCrossCheck(wep)),
			['Checks'] = CrosshairDesigner.IndexesOfCrossChecks(CrosshairDesigner.WeaponCrossCheck(wep))
		}
	}, true))

	if dataPath then
		savePath = dataPath .. savePath
	else
		savePath = "GarrysMod\\garrysmod\\data\\" .. savePath
	end

	print("Output written to " .. savePath)

	print()
	print()
	print("--------------------------------------------------------------------")
end)

concommand.Add("crosshairdesigner_debugswepdump", function()
	local addons = {}

	for k, v in pairs(engine.GetAddons()) do
		if v.mounted then
			local sweps, moreSweps = file.Find("lua/weapons/*", v.title)
			if moreSweps or sweps then
				sweps = sweps or {}
				moreSweps = moreSweps or {}
				if #sweps + #moreSweps > 0 then
					table.Add(sweps, moreSweps)
					table.Add(addons, {
						{
							['title'] = v.title,
							['wsid'] = v.wsid,
							['downloaded'] = v.downloaded,
							['mounted'] = v.mounted,
							['SWEPS'] = sweps
						}
					})
				end
			end
		end
	end

	print("--------------------------------------------------------------------")
	print()
	print()

	print("Crosshair Designer found these addons which contain SWEPS")
	PrintTable(addons)

	local dataPath = guessDataPathBasedOnAddons()
	local savePath = CrosshairDesigner.Directory .. "\\debug\\debugswepdump.txt"
	file.Write(savePath, util.TableToJSON(addons, true))

	if dataPath then
		savePath = dataPath .. savePath
	else
		savePath = "GarrysMod\\garrysmod\\data\\" .. savePath
	end

	print("Output written to " .. savePath)

	print()
	print()
	print("--------------------------------------------------------------------")
end)