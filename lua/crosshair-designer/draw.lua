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
local screenCentre = Vector(0, 0)
local defaultColour = Color(0,0,0,255)
local drawCol = defaultColour

local surface = {}
surface.SetDrawColor = _G.surface.SetDrawColor
surface.DrawPoly = _G.surface.DrawPoly
surface.DrawLine = _G.surface.DrawLine
surface.DrawRect = _G.surface.DrawRect

local math = {}
math.Round = _G.math.Round

local util = {}
util.TraceLine = _G.util.TraceLine

local draw = {}
draw.NoTexture = _G.draw.NoTexture

local Crosshair = function()

	-- Conditions for crosshair to be drawn
	shouldDraw = hook.Run("HUDShouldDraw", "CrosshairDesiger_Crosshair")
	drawCol = defaultColour
	alreadyTraced = false

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
			drawCol = cachedCross["TargetColour"]
		else
			drawCol = cachedCross["Colour"]
		end
	else
		drawCol = cachedCross["Colour"]
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
		mx, my = pos.x - 1, pos.y
		-- smooth out jitter caused by tracing from eyes
		screenCentre.x = math.Round(mx)
		screenCentre.y = math.Round(my)
	else
		-- Align with HL2 crosshair
		mx = (ScrW() / 2) - 1
		my = ScrH() / 2
		--
		screenCentre.x = mx
		screenCentre.y = my
	end

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

			-- Ignore texture set by other addons
			draw.NoTexture()

			-- Draw outline
			surface.SetDrawColor(cachedCross["OutlineColour"])
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
			local lines = cachedCross["Lines"]
			local outlines = cachedCross["Outlines"]
			local offset = cachedCross["LineStyle"] > 0 and 1 or 0 -- pointInwards and 1 or pointOutwards and 1 or 0

			-- Apply dynamic offset
			if cachedCross["Dynamic"] then
				lines = CrosshairDesigner.AdjustLinesByDynamicGap(lines, dynamic)
				outlines = CrosshairDesigner.AdjustOutlinesByDynamicGap(outlines, dynamic)
			end

			-- Translate to middle of screen
			lines = CrosshairDesigner.TranslateLines(lines, screenCentre)
			outlines = CrosshairDesigner.TranslateLines(outlines, screenCentre)

			-- Draw outline
			surface.SetDrawColor(drawCol)
			for k=1, #lines do
				surface.DrawLine(unpack(lines[k]))
			end

			surface.DrawLine(unpack({0, 0, 10, 10}))

			-- Draw crosshair inner
			surface.SetDrawColor(cachedCross["OutlineColour"])
			for k=1, #outlines do
				surface.DrawLine(unpack(outlines[k]))
			end
		end

	end


	if cachedCross["UseCircle"] then
		surface.SetDrawColor(drawCol)
		if cachedCross["CircleRadius"] == 1 then
			-- Pixel perfect under the HL2 crosshair
			draw.NoTexture()
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

local LINE_STYLE = {
	RECTANLE = 0,
	INWARDS = 1,
	OUTWARDS = 2
}

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

	cachedCross.circle = generateCircle(
		ScrW()/2-1,
		ScrH()/2+1,
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"]
	)

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

hook.Add("CrosshairDesigner_DetectedResolutionChange", "CenterCircle", function()
	cachedCross.circle = generateCircle(
		ScrW()/2-1,
		ScrH()/2+1,
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"]
	)
end)