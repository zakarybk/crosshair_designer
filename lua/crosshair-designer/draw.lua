local cachedCross = {}

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
local setColour = false
local alreadyTraced = false
local LocalPlayer = LocalPlayer
local surface = surface
local math = math
local ScrH = ScrH
local ScrW = ScrW
local mx, my
local shouldDraw

local Crosshair = function()

	-- Conditions for crosshair to be drawn
	shouldDraw = hook.Run("HUDShouldDraw", "CrosshairDesiger_Crosshair")
	ply = LocalPlayer()
	local drawCol = Color(0,0,0,255)
	setColour, alreadyTraced = false, false

	if not shouldDraw or not IsValid(ply) then
		return
	end

	-- Change col on target
	if cachedCross["ColOnTarget"] then
		trace.start = ply:GetShootPos()
		trace.endpos = trace.start + ply:GetAimVector() * 9000
		trace.filter = ply
		traceResult = util.TraceLine(trace)
		alreadyTraced = true

		target = traceResult.Entity
		if IsValid(target) and (target:IsPlayer() or target:IsNPC()) then
			drawCol = Color(
				cachedCross["TargetRed"],
				cachedCross["TargetGreen"],
				cachedCross["TargetBlue"],
				cachedCross["TargetAlpha"]
			)
			setColour = true
		end
	end

	if not setColour then
		-- Cross Colour
		drawCol = Color(
			cachedCross["Red"],
			cachedCross["Green"],
			cachedCross["Blue"],
			cachedCross["Alpha"]
		)
	end

	local outlineColor = Color(
		cachedCross["OutlineRed"],
		cachedCross["OutlineGreen"],
		cachedCross["OutlineBlue"],
		cachedCross["OutlineAlpha"]
	)

	local boolNum = {["false"] = 0, ["true"] = 1, ["nil"] = 0, [""] = 0}
	local outline = boolNum[tostring(cachedCross["Outline"])]
	outline = outline or 0

	-- Thanks Simple ThirdPerson - https://github.com/Metastruct/simplethirdperson/blob/master/lua/autorun/thirdperson.lua#L933
	if cachedCross["TraceDraw"] then
		if not alreadyTraced then
			trace.start = ply:GetShootPos()
			trace.endpos = trace.start + ply:GetAimVector() * 9000
			trace.filter = ply
			traceResult = util.TraceLine(trace)
		end

		local pos = traceResult.HitPos:ToScreen()
		mx, my = pos.x - 1, pos.y
	else
		-- Align with HL2 crosshair
		mx = (ScrW() / 2) - 1
		my = ScrH() / 2
	end

	local screenCentre = Vector(mx, my)

	if cachedCross["UseLine"] then

		if cachedCross["FillDraw"] then
			--
			-- Draw poly renderer
			--
			local polys = cachedCross["LinePolys"]
			local outlinePolys = cachedCross["OutlinePolys"]

			-- Apply dynamic offset
			if cachedCross["Dynamic"] then
				polys = CrosshairDesigner.AdjustPolysByDynamicGap(polys, dynamic, cachedCross["Rotation"])
				outlinePolys = CrosshairDesigner.AdjustPolysByDynamicGap(outlinePolys, dynamic, cachedCross["Rotation"])
			end

			-- Translate to middle of screen
			polys = CrosshairDesigner.TranslatePolys(polys, screenCentre)
			outlinePolys = CrosshairDesigner.TranslatePolys(outlinePolys, screenCentre)

			-- Draw outline
			surface.SetDrawColor(outlineColor)
			for k, poly in pairs(outlinePolys) do
				surface.DrawPoly(poly)
			end

			-- Draw crosshair inner
			surface.SetDrawColor(drawCol)
			for k, poly in pairs(polys) do
				surface.DrawPoly(poly)
			end
		else
			--
			-- Draw line renderer
			--
			local lines = cachedCross["Lines"]
			local outlines = cachedCross["Outlines"]
			local offset = cachedCross["LineStyle"] > 0 and 1 or 0 -- pointInwards and 1 or pointOutwards and 1 or 0

			-- Apply dynamic offset
			if cachedCross["Dynamic"] then
				lines = CrosshairDesigner.AdjustLinesByDynamicGap(lines, dynamic, cachedCross["Thickness"])
				outlines = CrosshairDesigner.AdjustOutlinesByDynamicGap(lines, outlines, dynamic, (4-offset) * cachedCross["Outline"], cachedCross["Thickness"])
			end

			-- Translate to middle of screen
			lines = CrosshairDesigner.TranslateLines(lines, screenCentre)
			outlines = CrosshairDesigner.TranslateLines(outlines, screenCentre)

			-- Draw outline
			surface.SetDrawColor(drawCol)
			for k, line in pairs(lines) do
				surface.DrawLine(unpack(line))
			end

			-- Draw crosshair inner
			surface.SetDrawColor(outlineColor)
			for k, line in pairs(outlines) do
				surface.DrawLine(unpack(line))
			end
		end

	end


	if cachedCross["UseCircle"] then
		surface.SetDrawColor(drawCol)
		if cachedCross["CircleRadius"] == 1 then
			-- Pixel perfect under the HL2 crosshair
			surface.DrawRect(mx, my, 1, 1)
		else
			-- If the circle pos is based off of tracing,
			-- then it needs updating every frame
			if cachedCross["TraceDraw"] then
				generateCircle(
					ScrW()/2-1,
					ScrH()/2+1,
					cachedCross["CircleRadius"],
					cachedCross["CircleSegments"]
				)
			end
			draw.NoTexture()
			surface.DrawPoly(cachedCross.circle)
		end
	end

end

local LINE_STYLE_RECTANLE = 0
local LINE_STYLE_INWARDS = 1
local LINE_STYLE_OUTWARDS = 2

local function updateCalculated()
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
			pointInwards = cachedCross["LineStyle"] == LINE_STYLE_INWARDS,
			pointOutwards = cachedCross["LineStyle"] == LINE_STYLE_OUTWARDS,
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
			pointInwards = cachedCross["LineStyle"] == LINE_STYLE_INWARDS,
			pointOutwards = cachedCross["LineStyle"] == LINE_STYLE_OUTWARDS,
		})
		cachedCross["Lines"] = lines
		cachedCross["Outlines"] = lineOutlines
	end
end

-- Update cached values
hook.Add("CrosshairDesigner_ValueChanged", "UpdateCrosshair", function(convar, val)
	local data = CrosshairDesigner.GetConvarData(convar)
	cachedCross[data.id] = val

	if data.id == "CircleRadius" or data.id == "CircleSegments" then
		cachedCross.circle = generateCircle(
			ScrW()/2-1,
			ScrH()/2+1,
			cachedCross["CircleRadius"],
			cachedCross["CircleSegments"]
		)
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

	cachedCross.circle = generateCircle(
		ScrW()/2-1,
		ScrH()/2+1,
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"]
	)

	ply = LocalPlayer()

	updateCalculated()

	hook.Add("HUDPaint", "CrosshairDesigner_DrawCrosshair", Crosshair)
	hc_dynamiccorsshair()
end)

hook.Add("CrosshairDesigner_DetectedResolutionChange", "CenterCircle", function()
	cachedCross.circle = generateCircle(
		ScrW()/2-1,
		ScrH()/2+1,
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"]
	)
end)