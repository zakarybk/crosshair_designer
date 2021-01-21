local ORIGIN = Vector(0, 0)
local DEFAULT_DIRECTION = Vector(1, 1)

local math = {}
math.sin = _G.math.sin
math.cos = _G.math.cos
math.rad = _G.math.rad
math.ceil = _G.math.ceil
math.floor = _G.math.floor
math.sin = _G.math.sin

local table = {}
table.insert = _G.table.insert

local Vector = Vector

function CrosshairDesigner.PointsToPoly(positions)
	local output = {}

	for k=1, #positions do
		table.insert(output, Vector(positions[k].x, positions[k].y))
	end
	return output
end

function CrosshairDesigner.TranslatePoly(poly, newPos)
	local translated = {}

	for k=1, #poly do
		translated[k] = {x = poly[k].x + newPos[1], y = poly[k].y + newPos[2]}
	end

	translated.dir = newPos.dir or DEFAULT_DIRECTION

	return translated
end

function CrosshairDesigner.TranslatePolys(polys, newPos)
	local translated = {}

	for k=1, #polys do
		translated[k] = CrosshairDesigner.TranslatePoly(polys[k], newPos)
	end

	return translated
end

function CrosshairDesigner.TranslateLine(line, newPos)
	return line[1] + newPos[1], line[2] + newPos[2],
		line[3] + newPos[1], line[4] + newPos[2],
		newPos.dir or DEFAULT_DIRECTION
end

function CrosshairDesigner.TranslateLines(lines, newPos)
	local translated = {}

	for k=1, #lines do
		translated[k] = {CrosshairDesigner.TranslateLine(lines[k], newPos)}
	end

	return translated
end

function CrosshairDesigner.RotateAroundPoint(point, radians, origin)
	local cosRadians = math.cos(radians)
	local sinRadians = math.sin(radians)

    local x, y = point.x, point.y
    local ox, oy = origin.x, origin.y

    local qx = ox + cosRadians * (x - ox) + sinRadians * (y - oy)
    local qy = oy + -sinRadians * (x - ox) + cosRadians * (y - oy)

    return Vector(qx, qy)
end

function CrosshairDesigner.RotatePoly(poly, rotation)
	local radians = math.rad(rotation)
	local output = {}

	-- Loop through each point which makes up a poly
	for k=1, #poly do
		output[k] = CrosshairDesigner.RotateAroundPoint(poly[k], radians, ORIGIN)
	end

	output.dir = Vector(math.sin(radians), math.cos(radians))

	return output
end

function CrosshairDesigner.RotateLine(line, rotation)
	local radians = math.rad(rotation)

	local rotatedStart = CrosshairDesigner.RotateAroundPoint(Vector(line[1], line[2]), radians, ORIGIN)
	local rotatedEnd = CrosshairDesigner.RotateAroundPoint(Vector(line[3], line[4]), radians, ORIGIN)

	return rotatedStart.x, rotatedStart.y,
		rotatedEnd.x, rotatedEnd.y,
		Vector(math.sin(radians), math.cos(radians))
end

function CrosshairDesigner.AdjustLinesByDynamicGap(lines, gap, lineThickness)
	local translatedLines = {}
	local dynamicAmt = gap

	local line, direction, dyanmicGap

	for k=1, #lines do
		line = lines[k]
		direction = line[5]
		dyanmicGap = direction * dynamicAmt

		translatedLines[k] = {
			line[1] + dyanmicGap.x,
			line[2] + dyanmicGap.y,
			line[3] + dyanmicGap.x,
			line[4] + dyanmicGap.y
		}

	end

	return translatedLines
end

function CrosshairDesigner.AdjustOutlinesByDynamicGap(outlines, gap)
	local translated = {}
	local dynamicAmt = gap

	local line, direction, dyanmicGap

	for k=1, #outlines do
		line = outlines[k]
		direction = line[5]
		dyanmicGap = direction * dynamicAmt

		translated[k] = {
			line[1] + dyanmicGap.x,
			line[2] + dyanmicGap.y,
			line[3] + dyanmicGap.x,
			line[4] + dyanmicGap.y
		}
	end

	return translated
end

function CrosshairDesigner.AdjustPolysByDynamicGap(polys, gap)
	local translatedPolys = {}
	local dynamicAmt = gap

	local poly, direction, dyanmicGap

	for k=1, #polys do
		poly = polys[k]
		direction = poly.dir
		dyanmicGap = direction * dynamicAmt

		translatedPolys[k] = CrosshairDesigner.TranslatePoly(poly, dyanmicGap)
	end

	return translatedPolys
end

function CrosshairDesigner.CalculateLinePolys(config)
	-- Parameter check
	if config.lineCount == nil then Error("No lineCount supplied to CalculateLinePolys!") end
	if config.thickness == nil then Error("No thickness supplied to CalculateLinePolys!") end
	if config.gap == nil then Error("No gap supplied to CalculateLinePolys!") end
	if config.length == nil then Error("No length supplied to CalculateLinePolys!") end

	-- Parameter mapping
	local lineCount = config.lineCount
	local rotation = config.rotation != nil and config.rotation or 0
	local thickness = config.thickness
	local stretch = config.stretch != nil and config.stretch or 0
	local gap = config.gap
	local length = config.length
	local addOutline = config.addOutline != nil and config.addOutline or false
	local outlineWidth = config.outlineWidth or 1
	local pointInwards = config.pointInwards != nil and config.pointInwards or false
	local pointOutwards = config.pointOutwards != nil and config.pointOutwards or false

	local polys = {}
	local outlinePolys = {}

	-- Based on clockwise with start at the top, so right then left
	local leftThickness = math.floor(thickness/2)
	local rightThickness = math.ceil(thickness/2)

	-- top left, top right, bottom right, bottom left
	local topLeft, topRight, bottomRight, bottomLeft
	if pointInwards then
		topLeft = Vector(0, 0)
		topRight = Vector(0, 0)
		bottomRight = Vector(rightThickness-stretch, length)
		bottomLeft = Vector(-leftThickness-stretch, length)
	elseif pointOutwards then
		topLeft = Vector(-leftThickness, 0)
		topRight = Vector(rightThickness, 0)
		bottomRight = Vector(0-stretch, length)
		bottomLeft = Vector(0-stretch, length)
	else
		topLeft = Vector(-leftThickness, 0)
		topRight = Vector(rightThickness, 0)
		bottomRight = Vector(rightThickness-stretch, length)
		bottomLeft = Vector(-leftThickness-stretch, length)
	end

	-- For each line, calculate line and outline if requested
	for i=1, lineCount do

		local rot = (((360 / lineCount) * i) - rotation) % 360
		local middleOffset = Vector(0, 0)
		local poly = {}

		-- 45 is the rotation offset needed to separate top and left from bottom and right
		-- This split was chosen because the HL2 crosshair uses the top right pixel
		-- The rotation goes anti-clockwise, hence using -cachedCross["Rotation"])

		if rot >= 0+45 and rot <= (180+45)%360 then
			local gapOffset = math.ceil(gap/2)

			if (rot >=0+45 and rot <= 90+45) then
				-- Right side (with 0 rotation)
				middleOffset = Vector(-1, gapOffset) -- x = y, y = x
			else
				-- Top side (with 0 rotation)
				middleOffset = Vector(-1, -1 + gapOffset)
			end
		else
			local gapOffset = math.floor((gap/2)) + 1

			if (rot > 180+45 and rot <= 270+45) then
				-- Left side (with 0 rotation)
				middleOffset = Vector(0, -1 + gapOffset)
			else
				-- Bottom side (with 0 rotation)
				middleOffset = Vector(0, gapOffset)
			end
		end

		if addOutline then
			poly = CrosshairDesigner.RotatePoly(
				CrosshairDesigner.TranslatePoly( -- Apply middle gap offset
					CrosshairDesigner.PointsToPoly({
						topLeft+Vector(-outlineWidth, -outlineWidth),
						topRight+Vector(outlineWidth, -outlineWidth),
						bottomRight+Vector(outlineWidth, outlineWidth),
						bottomLeft+Vector(-outlineWidth, outlineWidth)
					}),
					middleOffset
				),
				rot
			)
			table.insert(outlinePolys, poly)
		end

		-- Normal line
		poly = CrosshairDesigner.RotatePoly(
			CrosshairDesigner.TranslatePoly( -- Apply middle gap offset
				CrosshairDesigner.PointsToPoly({topLeft, topRight, bottomRight, bottomLeft}),
				middleOffset
			),
			rot
		)
		table.insert(polys, poly)

	end

	return polys, outlinePolys
end

function CrosshairDesigner.CalculateLines(config)
	-- Parameter check
	if config.lineCount == nil then Error("No lineCount supplied to CalculateLines!") end
	if config.thickness == nil then Error("No thickness supplied to CalculateLines!") end
	if config.gap == nil then Error("No gap supplied to CalculateLines!") end
	if config.length == nil then Error("No length supplied to CalculateLines!") end

	-- Parameter mapping
	local lineCount = config.lineCount
	local rotation = config.rotation != nil and config.rotation or 0
	local thickness = config.thickness
	local stretch = config.stretch != nil and config.stretch or 0
	local gap = config.gap
	local length = config.length
	local addOutline = config.addOutline != nil and config.addOutline or false
	local outlineWidth = config.outlineWidth != nil and config.outlineWidth or 1
	local pointInwards = config.pointInwards != nil and config.pointInwards or false
	local pointOutwards = config.pointOutwards != nil and config.pointOutwards or false

	local lines = {}
	local outlineLines = {}

	-- Based on clockwise with start at the top, so right then left
	local leftThickness = math.floor(thickness/2)
	local rightThickness = math.ceil(thickness/2)

	local lineStart = Vector(0, 0)
	local lineEnd = Vector(0, length)

	-- For each line, calculate line and outline if requested
	for i=1, lineCount do

		local rot = (((360 / lineCount) * i) - rotation) % 360
		local middleOffset = Vector(0, 0)
		local line = {}

		-- 45 is the rotation offset needed to separate top and left from bottom and right
		-- This split was chosen because the HL2 crosshair uses the top right pixel
		-- The rotation goes anti-clockwise, hence using -cachedCross["Rotation"])

		-- Differs from DrawPoly version
		if rot >= 0+45 and rot <= (180+45)%360 then
			local gapOffset = math.ceil(gap/2)

			if (rot >=0+45 and rot <= 90+45) then
				-- Right side (with 0 rotation)
				middleOffset = Vector(0, gapOffset) -- x = y, y = x
			else
				-- Top side (with 0 rotation)
				middleOffset = Vector(0, gapOffset)
			end
		else
			local gapOffset = math.floor((gap/2)) + 1

			if (rot > 180+45 and rot <= 270+45) then
				-- Left side (with 0 rotation)
				middleOffset = Vector(0, gapOffset)
			else
				-- Bottom side (with 0 rotation)
				middleOffset = Vector(0, gapOffset)
			end
		end

		if addOutline then
			-- based on | being the line
			-- right
			for w=1, outlineWidth do
				line = {CrosshairDesigner.RotateLine(
					{CrosshairDesigner.TranslateLine({
							not pointInwards and lineStart.x-leftThickness - w  or lineStart.x,
							lineStart.y,
							not pointOutwards and lineEnd.x-leftThickness-stretch - w or lineEnd.x,
							lineEnd.y-stretch
						},
						middleOffset
					)},
					rot
				)}
				table.insert(outlineLines, line)

				-- left
				line = {CrosshairDesigner.RotateLine(
					{CrosshairDesigner.TranslateLine({
							not pointInwards and lineStart.x+rightThickness + w -1 or lineStart.x,
							lineStart.y,
							not pointOutwards and lineEnd.x+rightThickness-stretch + w -1 or lineEnd.x,
							lineEnd.y-stretch
						},
						middleOffset
					)},
					rot
				)}
				table.insert(outlineLines, line)

				-- inner
				if not pointInwards then
					line = {CrosshairDesigner.RotateLine(
						{CrosshairDesigner.TranslateLine({
								lineStart.x-leftThickness-outlineWidth,
								lineStart.y-1 + w,
								lineStart.x+rightThickness+outlineWidth,
								lineStart.y-1 +w
							},
							middleOffset
						)},
						rot
					)}
					table.insert(outlineLines, line)
				end

				-- outer
				if not pointOutwards then
					line = {CrosshairDesigner.RotateLine(
						{CrosshairDesigner.TranslateLine({
								lineEnd.x-leftThickness-stretch-outlineWidth,
								lineEnd.y-stretch + w -1,
								lineEnd.x+rightThickness-stretch+outlineWidth,
								lineEnd.y-stretch + w -1
							},
							middleOffset
						)},
						rot
					)}
					table.insert(outlineLines, line)
				end
			end
		end

		-- Middle lines
		line = {CrosshairDesigner.RotateLine(
			{CrosshairDesigner.TranslateLine(
				{lineStart.x, lineStart.y, lineEnd.x - stretch, lineEnd.y - stretch},
				middleOffset
			)},
			rot
		)}

		table.insert(lines, line)

		-- Thickness lines
		for t=2, thickness do
			local offset = math.floor(t/2)
			if t % 2 == 0 then
				-- Draw clockwise on other side of the line
				line = {CrosshairDesigner.RotateLine(
					{CrosshairDesigner.TranslateLine({
							not pointInwards and lineStart.x - offset or lineStart.x,
							lineStart.y,
							not pointOutwards and lineEnd.x - offset - stretch or lineEnd.x,
							lineEnd.y - stretch
						},
						middleOffset
					)},
					rot
				)}
				table.insert(lines, line)
			else
				-- Draw anti-clockwise on other side of the line
				line = {CrosshairDesigner.RotateLine(
					{CrosshairDesigner.TranslateLine({
							not pointInwards and lineStart.x + offset or lineStart.x,
							lineStart.y,
							not pointOutwards and lineEnd.x + offset - stretch or lineEnd.x,
							lineEnd.y - stretch
						},
						middleOffset
					)},
					rot
				)}
				table.insert(lines, line)
			end
		end
	end

	return lines, outlineLines
end