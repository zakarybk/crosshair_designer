local cachedCross = {}
local cacheHits = 0
local cacheMisses = 0
local newCacheDepth = CrosshairDesigner.CacheSize()
local cacheDepth = CrosshairDesigner.CacheSize()

local surface = {}
surface.SetDrawColor = _G.surface.SetDrawColor
surface.DrawPoly = _G.surface.DrawPoly
surface.DrawLine = _G.surface.DrawLine
surface.DrawRect = _G.surface.DrawRect

local math = table.Copy(math)

local util = {}
util.TraceLine = _G.util.TraceLine

local draw = {}
draw.NoTexture = _G.draw.NoTexture

local table = {}
table.RemoveByValue = _G.table.RemoveByValue
table.insert = _G.table.insert
table.Count = _G.table.Count

-- Pause cache stats on menu open
local menuOpenState = 0
hook.Add("CrosshairDesigner_MenuOpened", "StartCacheStats", function()
	menuOpenState = 1
end)
hook.Add("CrosshairDesigner_MenuClosed", "StopCacheStats", function()
	menuOpenState = 0
end)

CrosshairDesigner.CacheHitPercent = function()
	return (cacheHits / (cacheHits + cacheMisses)) * 100
end

-- Watch for cache size updates
hook.Add("CrosshairDesigner_CacheSizeUpdate", "CrosshairDesigner.draw", function(newVal)
	cacheHits = 0
	cacheMisses = 0
	newCacheDepth = newVal
end)

-- Centre circle generation
local generateCircle = function(x, y, radius, seg)
	local cir = {}

	table.insert(cir, {x=x, y=y, u=0.5, v=0.5})
	for i = 0, seg do
		local a = math.rad((i/seg) * -360)
		table.insert(cir, {
			x = x + math.sin( a ) * radius,
			y = y + math.cos( a ) * radius,
			u = math.sin( a ) / 2 + 0.5,
			v = math.cos( a ) / 2 + 0.5
		})
	end

	local a = math.rad(0)
	table.insert(cir, {
		x = x + math.sin( a ) * radius,
		y = y + math.cos( a ) * radius,
		u = math.sin( a ) / 2 + 0.5,
		v = math.cos( a ) / 2 + 0.5
	})

	return cir
end

local function generateCrossCircle(x, y, radius, segments, rotation)
	local circle = generateCircle(0, 0, radius, segments)

	if rotation ~= 0 then
		circle = CrosshairDesigner.RotatePoly(
			circle,
			rotation
		)
	end

	return CrosshairDesigner.TranslatePoly(
		circle,
		{x, y}
	)
end

local function updateStaticCircles()
	cachedCross.circleOutline = generateCrossCircle(
		(ScrW()/2) + cachedCross["CircleXOffset"],
		(ScrH()/2) + 1 - cachedCross["CircleYOffset"],
		cachedCross["CircleRadius"] + cachedCross["CircleOutlineThickness"],
		cachedCross["CircleSegments"],
		cachedCross["CircleRotation"]
	)
	cachedCross.circle = generateCrossCircle(
		(ScrW()/2) + cachedCross["CircleXOffset"],
		(ScrH()/2) + 1 - cachedCross["CircleYOffset"],
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"],
		cachedCross["CircleRotation"]
	)
end

--[[
	Smooth dynamic crosshair (copied from old version)
	todo - update
]]--
local IsValid = IsValid
local dynamic = 0
local hc_shootingvalue = 0
local ply
local hc_dynamiccorsshair = function()

	if not cachedCross["Dynamic"] or timer.Exists("HC_SmoothDynamics") then
		timer.Destroy ("HC_SmoothDynamics")
	end

	if cachedCross["Dynamic"] then
		timer.Create( "HC_SmoothDynamics", 0.03, 0, function()
			if not IsValid(ply) then return end

			local hc_dynamicamount = cachedCross["DynamicSize"]
			local speedzzz = ply:GetVelocity():Length()

			if ply:Health() > 0 and ply:GetActiveWeapon():IsValid() then
				if ply:GetActiveWeapon():Clip1() > 0 then
					local spedzLength = string.len(speedzzz)
					local inAttack = ply:KeyDown(IN_ATTACK)

					if speedzzz / spedzLength  < hc_dynamicamount and speedzzz / spedzLength > 3 then
						dynamic = speedzzz / spedzLength 

					elseif speedzzz / spedzLength < 3 and inAttack and hc_shootingvalue < hc_dynamicamount / 3 then
						hc_shootingvalue = hc_shootingvalue + 0.5
						dynamic = hc_shootingvalue

					elseif speedzzz / spedzLength < 3 and !inAttack and hc_shootingvalue > 0 then
						hc_shootingvalue = hc_shootingvalue - 0.5
						dynamic = hc_shootingvalue

					elseif speedzzz / spedzLength < 4 and !inAttack and hc_shootingvalue < 1 then  ---- IN_ATTACK1 instead
						dynamic = speedzzz / spedzLength
					end
				else
					dynamic = 0
				end
			end
		end)
	end
end

local trace = {}
local traceResult = nil
local target
local alreadyTraced = false
local LocalPlayer = LocalPlayer
local surface = surface
local ScrH = ScrH
local ScrW = ScrW
local IsValid = IsValid
local unpack = unpack
local math_Round = math.Round
local mx, my
local shouldDraw = true
local crossCentre = Vector(0, 0)
local crossCircleCentre = Vector(0, 0)
local defaultColour = Color(0,0,0,255)
local drawCol = defaultColour
local outlineCol = defaultColour

-- Cache prototype
-- TODO: Look at removing code duplication though it seems tricky due to
-- all the minor differences

local cache2 = {}
cache2Ordered = {}
local key
local function cacheAdjustPolysByDynamicGap(polys, isOutline, dynamic, rotation)
	if cacheDepth < 2 then
		return CrosshairDesigner.AdjustPolysByDynamicGap(polys, dynamic, rotation)
	end
	-- Do not need to hash polys or rotation
	key = tostring(isOutline) .. '-' .. tostring(dynamic)
	if cache2[key] then
		-- move the cache hit to the front
		table.RemoveByValue(cache2Ordered, key)
		table.insert(cache2Ordered, 1, key)
		-- remove a miss from the end
		if #cache2Ordered > cacheDepth then
			miss_key = cache2Ordered[#cache2Ordered]
			table.RemoveByValue(cache2Ordered, miss_key)
			cache2[miss_key] = nil
		end
		cacheHits = cacheHits + 1 - menuOpenState
		return cache2[key]
	else
		-- calc new result for cache
		result = CrosshairDesigner.AdjustPolysByDynamicGap(polys, dynamic, rotation)
		cache2[key] = result
		table.insert(cache2Ordered, 1, key)
		-- remove a miss from the end
		if #cache2Ordered > cacheDepth then
			miss_key = cache2Ordered[#cache2Ordered]
			table.RemoveByValue(cache2Ordered, miss_key)
			cache2[miss_key] = nil
		end
		cacheMisses = cacheMisses + 1 - menuOpenState
		return result
	end
end

local cache3 = {}
cache3Ordered = {}
local function cacheTranslatePolys(polys, isOutline, screenCentre, dynamic)
	if cacheDepth < 2 then
		return CrosshairDesigner.TranslatePolys(polys, screenCentre)
	end
	key = tostring(isOutline) .. '-' .. tostring(screenCentre) .. '-' .. tostring(dynamic)
	if cache3[key] then
		-- move the cache hit to the front
		table.RemoveByValue(cache3Ordered, key)
		table.insert(cache3Ordered, 1, key)
		-- remove a miss from the end
		if #cache3Ordered > cacheDepth then
			miss_key = cache3Ordered[#cache3Ordered]
			table.RemoveByValue(cache3Ordered, miss_key)
			cache3[miss_key] = nil
		end
		cacheHits = cacheHits + 1 - menuOpenState
		return cache3[key]
	else
		-- calc new result for cache
		result = CrosshairDesigner.TranslatePolys(polys, screenCentre)
		cache3[key] = result
		table.insert(cache3Ordered, 1, key)
		-- remove a miss from the end
		if #cache3Ordered > cacheDepth then
			miss_key = cache3Ordered[#cache3Ordered]
			table.RemoveByValue(cache3Ordered, miss_key)
			cache3[miss_key] = nil
		end
		cacheMisses = cacheMisses + 1 - menuOpenState
		return result
	end
end

local cache4 = {}
cache4Ordered = {}
local function cacheAdjustLinesByDynamicGap(lines, dynamic)
	if cacheDepth < 2 then
		return CrosshairDesigner.AdjustLinesByDynamicGap(lines, dynamic)
	end
	key = tostring(dynamic)
	if cache4[key] then
		-- move the cache hit to the front
		table.RemoveByValue(cache4Ordered, key)
		table.insert(cache4Ordered, 1, key)
		-- remove a miss from the end
		if #cache4Ordered > cacheDepth then
			miss_key = cache4Ordered[#cache4Ordered]
			table.RemoveByValue(cache4Ordered, miss_key)
			cache4[miss_key] = nil
		end
		cacheHits = cacheHits + 1 - menuOpenState
		return cache4[key]
	else
		-- calc new result for cache
		result = CrosshairDesigner.AdjustLinesByDynamicGap(lines, dynamic)
		cache4[key] = CrosshairDesigner.AdjustLinesByDynamicGap(lines, dynamic)
		table.insert(cache4Ordered, 1, key)
		-- remove a miss from the end
		if #cache4Ordered > cacheDepth then
			miss_key = cache4Ordered[#cache4Ordered]
			table.RemoveByValue(cache4Ordered, miss_key)
			cache4[miss_key] = nil
		end
		cacheMisses = cacheMisses + 1 - menuOpenState
		return result
	end
end

local cache5 = {}
cache5Ordered = {}
local function cacheAdjustOutlinesByDynamicGap(outlines, dynamic)
	if cacheDepth < 2 then
		return CrosshairDesigner.AdjustOutlinesByDynamicGap(outlines, dynamic)
	end
	key = tostring(dynamic)
	if cache5[key] then
		-- move the cache hit to the front
		table.RemoveByValue(cache5Ordered, key)
		table.insert(cache5Ordered, 1, key)
		-- remove a miss from the end
		if #cache5Ordered > (cacheDepth / 2) then
			miss_key = cache5Ordered[#cache5Ordered]
			table.RemoveByValue(cache5Ordered, miss_key)
			cache5[miss_key] = nil
		end
		cacheHits = cacheHits + 1 - menuOpenState
		return cache5[key]
	else
		-- calc new result for cache
		result = CrosshairDesigner.AdjustOutlinesByDynamicGap(outlines, dynamic)
		cache5[key] = result
		table.insert(cache5Ordered, 1, key)
		-- remove a miss from the end
		if #cache5Ordered > (cacheDepth / 2) then
			miss_key = cache5Ordered[#cache5Ordered]
			table.RemoveByValue(cache5Ordered, miss_key)
			cache5[miss_key] = nil
		end
		cacheMisses = cacheMisses + 1 - menuOpenState
		return result
	end
end

local cache6 = {}
cache6Ordered = {}
local function cacheTranslateLines(lines, isOutline, screenCentre, dynamic)
	if cacheDepth < 2 then
		return CrosshairDesigner.TranslateLines(lines, screenCentre)
	end
	key =  tostring(isOutline) .. '-' .. tostring(screenCentre) .. '-' .. tostring(dynamic)
	if cache6[key] then
		-- move the cache hit to the front
		table.RemoveByValue(cache6Ordered, key)
		table.insert(cache6Ordered, 0, key)
		-- remove a miss from the end
		if #cache6Ordered > (cacheDepth / 2) then
			miss_key = cache6Ordered[#cache5Ordered]
			table.RemoveByValue(cache6Ordered, miss_key)
			cache6[miss_key] = nil
		end
		cacheHits = cacheHits + 1 - menuOpenState
		return cache6[key]
	else
		-- calc new result for cache
		result = CrosshairDesigner.TranslateLines(lines, screenCentre)
		cache6[key] = result
		table.insert(cache6Ordered, 0, key)
		-- remove a miss from the end
		if #cache6Ordered > (cacheDepth / 2) then
			miss_key = cache6Ordered[#cache5Ordered]
			table.RemoveByValue(cache6Ordered, miss_key)
			cache6[miss_key] = nil
		end
		cacheMisses = cacheMisses + 1 - menuOpenState
		return result
	end
end

local previousDrawCol = Color(0,0,0,255)
local nextDrawCol = Color(0,0,0,255)
local Lerp = Lerp

local function LerpColor(t, from, to)
	return Color(
		Lerp(t, from.r, to.r),
		Lerp(t, from.g, to.g),
		Lerp(t, from.b, to.b),
		Lerp(t, from.a, to.a)
	)
end

local cumulativeDrawFrameTime = 0

local function calcInvertedColours(previousCol)
	local updateRate = 0.2
	cumulativeDrawFrameTime = cumulativeDrawFrameTime + RealFrameTime()

	if cumulativeDrawFrameTime > updateRate then
		previousDrawCol = previousCol
		render.CapturePixels()
		local a, b, c = render.ReadPixel(mx, my)
		local r, g, b = 255 - a, 255 - b, 255 - c

		if cachedCross['HighContrastInvertedCol'] then
			local constrast = r * 0.299 + g * 0.587 + b * 0.114
			if constrast > 186 then
				nextDrawCol = Color(255, 255, 255, 255)
			else
				nextDrawCol = Color(0, 0, 0, 255)
			end
		else
			nextDrawCol = Color(r, g, b, 255)
		end
		cumulativeDrawFrameTime = 0
	end

	return LerpColor(cumulativeDrawFrameTime / (updateRate / 2), previousDrawCol, nextDrawCol)
end

local Crosshair = function()

	-- Conditions for crosshair to be drawn
	shouldDraw = hook.Run("HUDShouldDraw", "CrosshairDesiger_Crosshair")
	-- drawCol = defaultColour
	alreadyTraced = false

	if not shouldDraw or not IsValid(ply) then
		return
	end

	-- Thanks Simple ThirdPerson - https://github.com/Metastruct/simplethirdperson/blob/master/lua/autorun/thirdperson.lua#L933
	if cachedCross["TraceDraw"] then
		if not alreadyTraced then
			trace.start = ply:GetShootPos()
			trace.endpos = trace.start + ply:GetAimVector() * 9000
			trace.filter = ply
			traceResult = util.TraceLine(trace)
		end

		local pos = traceResult.HitPos:ToScreen()
		-- smooth out jitter caused by tracing from eyes
		mx, my =  math.Round(pos.x - 1), math.Round(pos.y)
	else
		-- Align with HL2 crosshair
		mx = (ScrW() / 2) - 1
		my = ScrH() / 2
	end

	crossCentre.x = mx + cachedCross["CrossXOffset"]
	crossCentre.y = my - cachedCross["CrossYOffset"]
	crossCircleCentre.x = mx + cachedCross["CircleXOffset"]
	crossCircleCentre.y = my - cachedCross["CircleYOffset"] + 1

	-- Ignore texture set by other addons
	draw.NoTexture()

	-- Change col on target
	if cachedCross["ColOnTarget"] then
		trace.start = ply:GetShootPos()
		trace.endpos = trace.start + ply:GetAimVector() * 9000
		trace.filter = ply
		traceResult = util.TraceLine(trace)
		alreadyTraced = true

		target = traceResult.Entity
		if IsValid(target) and (target:IsPlayer() or target:IsNPC()) then
			drawCol = cachedCross["TargetColour"]
		else
			if cachedCross["InvertCol"] then
				drawCol = calcInvertedColours(drawCol)
				if cachedCross["InvertOutlineCol"] then
					outlineCol = drawCol
				else
					outlineCol = cachedCross["OutlineColour"]
				end
			elseif cachedCross["InvertOutlineCol"] then
				outlineCol = calcInvertedColours(outlineCol)
				drawCol = cachedCross["Colour"]
			else
				drawCol = cachedCross["Colour"]
				outlineCol = cachedCross["OutlineColour"]
			end
		end
	else
		if cachedCross["InvertCol"] then
			drawCol = calcInvertedColours(drawCol)
			if cachedCross["InvertOutlineCol"] then
				outlineCol = drawCol
			else
				outlineCol = cachedCross["OutlineColour"]
			end
		elseif cachedCross["InvertOutlineCol"] then
			outlineCol = calcInvertedColours(outlineCol)
			drawCol = cachedCross["Colour"]
		else
			drawCol = cachedCross["Colour"]
			outlineCol = cachedCross["OutlineColour"]
		end
	end

	dynamicGap = math.Round(dynamic)

	if cachedCross["UseLine"] then

		if cachedCross["FillDraw"] then
			--
			-- Draw poly renderer
			--
			local polys = cachedCross["LinePolys"] or {}
			local outlinePolys = cachedCross["OutlinePolys"] or {}

			-- Apply dynamic offset
			if cachedCross["Dynamic"] then
				polys = cacheAdjustPolysByDynamicGap(polys, false, dynamicGap, cachedCross["Rotation"])
				outlinePolys = cacheAdjustPolysByDynamicGap(outlinePolys, true, dynamicGap, cachedCross["Rotation"])
			end

			-- Translate to middle of screen
			polys = cacheTranslatePolys(polys, false, crossCentre, dynamicGap)
			outlinePolys = cacheTranslatePolys(outlinePolys, true, crossCentre, dynamicGap)

			-- Draw outline
			surface.SetDrawColor(outlineCol)
			for k=1, #outlinePolys do
				surface.DrawPoly(outlinePolys[k])
			end

			-- Draw crosshair inner
			surface.SetDrawColor(drawCol)
			for k=1, #polys do
				surface.DrawPoly(polys[k])
			end
		else
			--
			-- Draw line renderer
			--
			local lines = cachedCross["Lines"] or {}
			local outlines = cachedCross["Outlines"] or {}
			local offset = cachedCross["LineStyle"] > 0 and 1 or 0 -- pointInwards and 1 or pointOutwards and 1 or 0

			-- Apply dynamic offset
			if cachedCross["Dynamic"] then
				lines = cacheAdjustLinesByDynamicGap(lines, dynamicGap)
				outlines = cacheAdjustOutlinesByDynamicGap(outlines, dynamicGap)
			end

			-- Translate to middle of screen
			lines = cacheTranslateLines(lines, false, crossCentre, dynamicGap)
			outlines = cacheTranslateLines(outlines, true, crossCentre, dynamicGap)

			-- Draw lines
			surface.SetDrawColor(drawCol)
			for k=1, #lines do
				surface.DrawLine(unpack(lines[k]))
			end

			-- Draw crosshair outline
			surface.SetDrawColor(outlineCol)
			for k=1, #outlines do
				surface.DrawLine(unpack(outlines[k]))
			end
		end

	end


	if cachedCross["UseCircle"] then
		surface.SetDrawColor(drawCol)
		if cachedCross["CircleRadius"] == 1 then
			-- Pixel perfect under the HL2 crosshair
			surface.DrawRect(crossCircleCentre.x, crossCircleCentre.y, 1, 1)
		else
			-- If the circle pos is based off of tracing,
			-- then it needs updating every frame
			if cachedCross["TraceDraw"] then
				cachedCross.circleOutline = generateCrossCircle(
					crossCircleCentre.x,
					crossCircleCentre.y,
					cachedCross["CircleRadius"] + cachedCross["CircleOutlineThickness"],
					cachedCross["CircleSegments"],
					cachedCross["CircleRotation"]
				)
				cachedCross.circle = generateCrossCircle(
					crossCircleCentre.x,
					crossCircleCentre.y,
					cachedCross["CircleRadius"],
					cachedCross["CircleSegments"],
					cachedCross["CircleRotation"]
				)
			end
			-- Draw outline
			if cachedCross["CircleOutlineThickness"] > 0 then
				surface.SetDrawColor(outlineCol)
				surface.DrawPoly(cachedCross.circleOutline)
			end
			-- Draw inner
			surface.SetDrawColor(drawCol)
			surface.DrawPoly(cachedCross.circle)
		end
	end

	-- Update cache size after drawing instead of in hook.Add.
	-- Otherwise GMod updates the value in the middle of drawing
	-- and we get script errors with null indexes
	if newCacheDepth ~= cacheDepth then
		cacheDepth = newCacheDepth
	end

end

CrosshairDesigner.FormatBytes = function(bytes, precision)
	precision = precision or 2
	-- local units = {'B', 'KiB', 'MiB', 'GiB', 'TiB'}

	-- local bytes = math.max(bytes, 0)
	-- local pow = math.floor((bytes and math.log(bytes) or 0) / math.log(1024))
	-- pow =  math.min(pow, #units)

	-- return math.Round(bytes, precision) .. ' ' .. units[pow]
	if (bytes > math.pow(1024,3)) then
		return math.Round(bytes / math.pow(1024,3), precision) .."GB"
    elseif (bytes > math.pow(1024,2)) then
    	return math.Round(bytes / math.pow(1024,2), precision) .."MB"
    elseif (bytes > 1024) then
    	return math.Round(bytes / 1024, precision) .."KB"
    else
    	return tostring(bytes).."B"
    end
end

CrosshairDesigner.CalcMemoryUsage = function()
	local INT_MEM = 4
	local CHAR_MEM = 1

	local ints = 0
	local chars = 0

	local intsPerLine = 5
	local charsPerLine = 1
	local intsPerPoly = 9
	local charsPerPoly = 9

	local info = CrosshairDesigner.CalcInfo()

	-- keys (chars) representing one cache entry
	local keyLenPerPoly = string.len("true") + (string.len("100")*2) + string.len("960.000000 540.000000 0.000000")
	local keyLenPerLine = (string.len("true")*3) + string.len("100") + string.len("960.000000 540.000000 0.000000")
	local keyLength = cachedCross["FillDraw"] and keyLenPerPoly or keyLenPerLine
	-- multiplier represents the extra data stored due to everything using seaparte cache counts
	local multiplier = cachedCross["FillDraw"] and 2 or 3

	ints = (info.lines * intsPerLine * multiplier) + (info.polys * intsPerPoly * multiplier)
	chars = (info.lines * charsPerLine * multiplier) + (info.polys * charsPerPoly * multiplier) + keyLength

	usedBytes = (ints * INT_MEM) + (chars * CHAR_MEM)
	return usedBytes
end

CrosshairDesigner.CalcInfo = function()
	-- If menu is opened before crosshair finished loading
	if CrosshairDesigner.FinishLoad == nil then
		return {
			lines=0,
			polys=0
		} 
	end

	info = {}

	if cachedCross["FillDraw"] then
		info.lines = 0
		info.polys = cachedCross["Segments"] * math.max(cachedCross["Outline"]+1, 1)
	else
		info.lines = (cachedCross["Segments"] * math.max(cachedCross["Thickness"], 1)) +
						(cachedCross["Segments"] * cachedCross["Outline"] * 4)
		info.polys = 0
	end

	if cachedCross["UseCircle"] then
		info.polys = info.polys + 1
		if cachedCross["CircleOutlineThickness"] > 0 then
			info.polys = info.polys + 1
		end
	end

	return info
end

local LINE_STYLE = {
	RECTANLE = 0,
	INWARDS = 1,
	OUTWARDS = 2
}

local function updateCalculated()
	-- clear cache
	cache2 = {}
	cache2Ordered = {}
	cache3 = {}
	cache3Ordered = {}
	cache4 = {}
	cache4Ordered = {}
	cache5 = {}
	cache5Ordered = {}
	cache6 = {}
	cache6Ordered = {}
	cacheHits = 0
	cacheMisses = 0
	-- Only update if all values are valid
	local isValid, inValid = CrosshairDesigner.IsValidCrosshair({
			["Segments"] = cachedCross["Segments"],
			["Rotation"] = cachedCross["Rotation"],
			["Thickness"] = cachedCross["Thickness"],
			["Stretch"] = cachedCross["Stretch"],
			["Gap"] = cachedCross["Gap"],
			["Length"] = cachedCross["Length"],
			["Outline"] = cachedCross["Outline"],
			["LineStyle"] = cachedCross["LineStyle"]
	})

	if not isValid then
		PrintTable(inValid)
		return
	end

	-- Poly based
	if cachedCross["FillDraw"] then
		local polys, outlinePolys = CrosshairDesigner.CalculateLinePolys({
			lineCount = cachedCross["Segments"],
			rotation = cachedCross["Rotation"],
			thickness = cachedCross["Thickness"],
			stretch = cachedCross["Stretch"],
			gap = cachedCross["Gap"],
			length = cachedCross["Length"],
			addOutline = cachedCross["Outline"] > 0,
			outlineWidth = cachedCross["Outline"],
			pointInwards = cachedCross["LineStyle"] == LINE_STYLE.INWARDS,
			pointOutwards = cachedCross["LineStyle"] == LINE_STYLE.OUTWARDS,
		})
		cachedCross["LinePolys"] = polys
		cachedCross["OutlinePolys"] = outlinePolys

	else
	-- Line based
		local lines, lineOutlines = CrosshairDesigner.CalculateLines({
			lineCount = cachedCross["Segments"],
			rotation = cachedCross["Rotation"],
			thickness = cachedCross["Thickness"],
			stretch = cachedCross["Stretch"],
			gap = cachedCross["Gap"],
			length = cachedCross["Length"],
			addOutline = cachedCross["Outline"] > 0,
			outlineWidth = cachedCross["Outline"],
			pointInwards = cachedCross["LineStyle"] == LINE_STYLE.INWARDS,
			pointOutwards = cachedCross["LineStyle"] == LINE_STYLE.OUTWARDS,
		})
		cachedCross["Lines"] = lines
		cachedCross["Outlines"] = lineOutlines
	end
end

local function updateColours()
	cachedCross["Colour"] = Color(
		cachedCross["Red"],
		cachedCross["Green"],
		cachedCross["Blue"],
		cachedCross["Alpha"]
	)

	cachedCross["TargetColour"] = Color(
		cachedCross["TargetRed"],
		cachedCross["TargetGreen"],
		cachedCross["TargetBlue"],
		cachedCross["TargetAlpha"]
	)

	cachedCross["OutlineColour"] = Color(
		cachedCross["OutlineRed"],
		cachedCross["OutlineGreen"],
		cachedCross["OutlineBlue"],
		cachedCross["OutlineAlpha"]
	)
end

-- Update cached values
hook.Add("CrosshairDesigner_ValueChanged", "UpdateCrosshair", function(convar, val)
	local data = CrosshairDesigner.GetConvarData(convar)
	if not data then return end
	cachedCross[data.id] = val

	if data.menuGroup == "circle" then
		updateStaticCircles()
	end

	if data.id == "Dynamic" then
		if not val then
			if timer.Exists("HC_SmoothDynamics") then
				timer.Destroy("HC_SmoothDynamics")
				dynamic = 0
			end
		else
			hc_dynamiccorsshair()
		end
	end

	ply = LocalPlayer()
	updateColours()
	updateCalculated()
end)

-- Load cached values
hook.Add("CrosshairDesigner_FullyLoaded", "CrosshairDesigner_SetupDrawing", function(tbl)
	for i, data in pairs(CrosshairDesigner.GetConvarDatas()) do
		-- Do not update if the value has already been set
		if cachedCross[data.id] == nil then
			if data.isBool then
				cachedCross[data.id] = CrosshairDesigner.GetBool(data.id)
			else
				cachedCross[data.id] = CrosshairDesigner.GetInt(data.id)
			end
		end
	end

	updateStaticCircles()
	updateColours()
	updateCalculated()

	timer.Create("CrosshairDesigner_WaitForValidPly", 0.2, 0, function()
		ply = LocalPlayer()
		if IsValid(ply) then
			timer.Remove("CrosshairDesigner_WaitForValidPly")
		end
	end)

	hook.Add("HUDPaint", "CrosshairDesigner_DrawCrosshair", Crosshair)
	hc_dynamiccorsshair()
end)

hook.Add("OnScreenSizeChanged", "CrosshairDesignerCenterCircle", function()
	updateStaticCircles()
end)

concommand.Add("crosshair_designer_cache_size", function()
	size = table.Count(cache2) + table.Count(cache3) + table.Count(cache4) + table.Count(cache5) + table.Count(cache6)
	print(size)
end)

concommand.Add("crosshairdesigner_cache_hit_ratio", function()
	local accuracy = math.Round(CrosshairDesigner.CacheHitPercent(), 2)
	print(accuracy)
	print(CrosshairDesigner.FormatBytes(CrosshairDesigner.CalcMemoryUsage()))
end)