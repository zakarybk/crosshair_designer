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

local function rotateAroundPoint(point, radians, origin)
	local cosRadians = math.cos(radians)
	local sinRadians = math.sin(radians)

    local x, y = point.x, point.y
    local ox, oy = origin.x, origin.y

    local qx = ox + cosRadians * (x - ox) + sinRadians * (y - oy)
    local qy = oy + -sinRadians * (x - ox) + cosRadians * (y - oy)

    return qx, qy
end

local function drawRotated(px, py, ox, oy, screenCentre, rotation)
	local lineStartX, lineStartY = rotateAroundPoint(Vector(px, py),rotation,screenCentre)
	local lineEndX, lineEndY = rotateAroundPoint(Vector(ox, oy), rotation, screenCentre)

	--surface.DrawLine(o.x, o.y, p.x, p.y)
	surface.DrawLine(lineStartX, lineStartY, lineEndX, lineEndY)
end

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

	-- Thanks Simple ThirdPerson - https://github.com/Metastruct/simplethirdperson/blob/master/lua/autorun/thirdperson.lua#L933
	if cachedCross["TraceDraw"] then
		if not alreadyTraced then
			trace.start = ply:GetShootPos()
			trace.endpos = trace.start + ply:GetAimVector() * 9000
			trace.filter = ply
			traceResult = util.TraceLine(trace)
		end

		local pos = traceResult.HitPos:ToScreen()
		mx, my = pos.x, pos.y
	else
		mx = (ScrW() / 2) - 1
		my = ScrH() / 2
	end

	surface.SetDrawColor(0,0,0,255)

	local rotation = math.rad(0) -- -45
	local screenCentre = Vector(mx, my)

	surface.SetDrawColor(drawCol)

	if cachedCross["UseLine"] then

		local gap = cachedCross["Gap"] + dynamic
		local length = cachedCross["Length"] - 1
		local stretch = cachedCross["Stretch"]

		local gapLeft = math.floor((gap/2)) + 1
		local gapRight = math.ceil(gap/2)
		local topOffset = math.floor(cachedCross["Thickness"]/2) + 1
		local bottomOffset = math.ceil(cachedCross["Thickness"]/2)

		local boolNum = {["false"] = 0, ["true"] = 1, ["nil"] = 0}
		local fillOutline = boolNum[tostring(cachedCross["Outline"])]

		surface.SetDrawColor( 255, 255, 0, 255 )
		draw.NoTexture()

		-- left
		-- surface.DrawPoly({
		-- 	{x = mx-stretch-length-gapLeft, y = my+stretch+bottomOffset}, -- bottom
		-- 	{x = mx-stretch-length-gapLeft, y = my+stretch-topOffset}, -- top
		-- 	{x = mx-gapLeft, y = my-topOffset}, -- top
		-- 	{x = mx-gapLeft, y = my+bottomOffset} -- bottom
		-- })

		-- left
		local x1, y1 = rotateAroundPoint(Vector(mx-stretch-length-gapLeft-fillOutline, my+stretch+bottomOffset), rotation, screenCentre) -- bottom
		local x2, y2 = rotateAroundPoint(Vector(mx-stretch-length-gapLeft-fillOutline, my+stretch-topOffset+1-fillOutline), rotation, screenCentre) -- top
		local x3, y3 = rotateAroundPoint(Vector(mx-gapLeft+fillOutline+1, my-topOffset+1-fillOutline), rotation, screenCentre) -- top
		local x4, y4 = rotateAroundPoint(Vector(mx-gapLeft+fillOutline+1, my+bottomOffset), rotation, screenCentre) -- bottom
		surface.DrawPoly({
			{x = x1, y = y1},
			{x = x2, y = y2},
			{x = x3, y = y3},
			{x = x4, y = y4}
		})

		-- bottom
		x1, y1 = rotateAroundPoint(Vector(mx-topOffset+stretch+1-fillOutline, my+gapLeft+length+1+fillOutline), rotation, screenCentre) -- bottom
		x2, y2 = rotateAroundPoint(Vector(mx-topOffset+1-fillOutline, my+gapLeft-fillOutline), rotation, screenCentre) -- top
		x3, y3 = rotateAroundPoint(Vector(mx+bottomOffset, my+gapLeft-fillOutline), rotation, screenCentre) -- top
		x4, y4 = rotateAroundPoint(Vector(mx+bottomOffset+stretch, my+gapLeft+stretch+length+1+fillOutline), rotation, screenCentre) -- bottom
		surface.DrawPoly({
			{x = x1, y = y1},
			{x = x2, y = y2},
			{x = x3, y = y3},
			{x = x4, y = y4}
		})

		surface.SetDrawColor( 255, 255, 0, 0 )

		-- Draw the inital lines
		-- drawRotated(mx-stretch-length-gapLeft, my+stretch, mx-gapLeft, my, screenCentre, rotation) -- left
		-- drawRotated(mx+stretch, my+length+stretch+gapLeft, mx, my+gapLeft, screenCentre, rotation) -- bottom

		-- drawRotated(mx+stretch+length+gapRight, my-stretch, mx+gapRight, my, screenCentre, rotation) -- right
		-- drawRotated(mx-stretch, my-length-stretch-gapRight, mx, my-gapRight, screenCentre, rotation) -- top

		if cachedCross["UseArrow"] then

			--Arrows
			for i=2,cachedCross["Thickness"] do

				local offset = math.floor(i/2)

				if i % 2 == 0 then
					-- Draw clockwise on other side of the line
					drawRotated(mx-stretch-length-gapLeft, my+stretch-offset, mx-gapLeft, my, screenCentre, rotation) -- left
					drawRotated(mx+stretch-offset, my+length+stretch+gapLeft, mx, my+gapLeft, screenCentre, rotation) -- bottom

					drawRotated(mx+stretch+length+gapRight, my-stretch+offset, mx+gapRight, my, screenCentre, rotation) -- right
					drawRotated(mx-stretch+offset, my-length-stretch-gapRight, mx, my-gapRight, screenCentre, rotation) -- top

				else
					-- Draw anti-clockwise on other side of the line
					drawRotated(mx-stretch-length-gapLeft, my+stretch+offset, mx-gapLeft, my, screenCentre, rotation) -- left
					drawRotated(mx+stretch+offset, my+length+stretch+gapLeft, mx, my+gapLeft, screenCentre, rotation) -- bottom

					drawRotated(mx+stretch+length+gapRight, my-stretch-offset, mx+gapRight, my, screenCentre, rotation) -- right
					drawRotated(mx-stretch-offset, my-length-stretch-gapRight, mx, my-gapRight, screenCentre, rotation) -- top

				end

			end

			-- Outline for arrow crosshair
			if cachedCross["Outline"] then

				surface.SetDrawColor(
					cachedCross["OutlineRed"],
					cachedCross["OutlineGreen"],
					cachedCross["OutlineBlue"],
					cachedCross["OutlineAlpha"]
				)

				local topOffset = math.floor(cachedCross["Thickness"]/2) + 1
				local bottomOffset = math.ceil(cachedCross["Thickness"]/2)

				-- Outline left
				drawRotated(mx-stretch-length-gapLeft, my+stretch-topOffset, mx-gapLeft, my, screenCentre, rotation) -- top
				drawRotated(mx-stretch-length-gapLeft, my+stretch+bottomOffset, mx-gapLeft, my, screenCentre, rotation) -- bottom
				drawRotated(mx-stretch-length-gapLeft-1, my+stretch+bottomOffset, mx-stretch-length-gapLeft-1, my-topOffset+stretch, screenCentre, rotation) -- left

				-- Outline bottom
				drawRotated(mx-topOffset+stretch, my+gapLeft+stretch+length+1, mx+bottomOffset+stretch, my+gapLeft+stretch+length+1, screenCentre, rotation) -- bottom
				drawRotated(mx+stretch-topOffset, my+length+stretch+gapLeft, mx, my+gapLeft, screenCentre, rotation) -- left
				drawRotated(mx+stretch+bottomOffset, my+length+stretch+gapLeft, mx, my+gapLeft, screenCentre, rotation) -- right

				-- Outline right
				drawRotated(mx+stretch+length+gapRight, my-stretch-bottomOffset, mx+gapRight, my, screenCentre, rotation) -- top
				drawRotated(mx+stretch+length+gapRight, my-stretch+topOffset, mx+gapRight, my, screenCentre, rotation) -- bottom
				drawRotated(mx+stretch+length+gapRight+1, my-stretch-bottomOffset, mx+gapRight+length+stretch+1, my+topOffset-stretch, screenCentre, rotation) -- right

				-- Outline top
				drawRotated(mx-stretch-bottomOffset, my-length-stretch-gapRight-1, mx+topOffset-stretch, my-gapRight-length-stretch-1, screenCentre, rotation) -- top
				drawRotated(mx-stretch-bottomOffset, my-length-stretch-gapRight, mx, my-gapRight, screenCentre, rotation) -- left
				drawRotated(mx-stretch+topOffset, my-length-stretch-gapRight, mx, my-gapRight, screenCentre, rotation) -- right

			end

		else

			--Thickness
			for i=2,cachedCross["Thickness"] do

				local offset = math.floor(i/2)

				if i % 2 == 0 then
					-- Draw clockwise on other side of the line
					drawRotated(mx-stretch-length-gapLeft, my+stretch-offset, mx-gapLeft, my-offset, screenCentre, rotation) -- left
					drawRotated(mx+stretch-offset, my+length+stretch+gapLeft, mx-offset, my+gapLeft, screenCentre, rotation) -- bottom

					drawRotated(mx+stretch+length+gapRight, my-stretch+offset, mx+gapRight, my+offset, screenCentre, rotation) -- right
					drawRotated(mx-stretch+offset, my-length-stretch-gapRight, mx+offset, my-gapRight, screenCentre, rotation) -- top

				else
					-- Draw anti-clockwise on other side of the line
					drawRotated(mx-stretch-length-gapLeft, my+stretch+offset, mx-gapLeft, my+offset, screenCentre, rotation) -- left
					drawRotated(mx+stretch+offset, my+length+stretch+gapLeft, mx+offset, my+gapLeft, screenCentre, rotation) -- bottom

					drawRotated(mx+stretch+length+gapRight, my-stretch-offset, mx+gapRight, my-offset, screenCentre, rotation) -- right
					drawRotated(mx-stretch-offset, my-length-stretch-gapRight, mx-offset, my-gapRight, screenCentre, rotation) -- top

				end
			end

			-- Outline for rectangle crosshair
			if cachedCross["Outline"] then

				surface.SetDrawColor(
					cachedCross["OutlineRed"],
					cachedCross["OutlineGreen"],
					cachedCross["OutlineBlue"],
					cachedCross["OutlineAlpha"]
				)

				local topOffset = math.floor(cachedCross["Thickness"]/2) + 1
				local bottomOffset = math.ceil(cachedCross["Thickness"]/2)

				-- Outline left
				drawRotated(mx-stretch-length-gapLeft, my+stretch-topOffset, mx-gapLeft, my-topOffset, screenCentre, rotation) -- top
				drawRotated(mx-stretch-length-gapLeft, my+stretch+bottomOffset, mx-gapLeft, my+bottomOffset, screenCentre, rotation) -- bottom
				drawRotated(mx-stretch-length-gapLeft-1, my+stretch+bottomOffset, mx-stretch-length-gapLeft-1, my-topOffset+stretch, screenCentre, rotation) -- left
				drawRotated(mx-gapLeft+1, my+bottomOffset, mx-gapLeft+1, my-topOffset, screenCentre, rotation) -- right

				-- Outline bottom
				drawRotated(mx-topOffset, my+gapLeft-1, mx+bottomOffset, my+gapLeft-1, screenCentre, rotation) -- top
				drawRotated(mx-topOffset+stretch, my+gapLeft+stretch+length+1, mx+bottomOffset+stretch, my+gapLeft+stretch+length+1, screenCentre, rotation) -- bottom
				drawRotated(mx+stretch-topOffset, my+length+stretch+gapLeft, mx-topOffset, my+gapLeft, screenCentre, rotation) -- left
				drawRotated(mx+stretch+bottomOffset, my+length+stretch+gapLeft, mx+bottomOffset, my+gapLeft, screenCentre, rotation) -- right

				-- -- Outline right
				-- drawRotated(mx+stretch+length+gapRight, my-stretch-bottomOffset, mx+gapRight, my-bottomOffset, screenCentre, rotation) -- top
				-- drawRotated(mx+stretch+length+gapRight, my-stretch+topOffset, mx+gapRight, my+topOffset, screenCentre, rotation) -- bottom
				-- drawRotated(mx+gapRight-1, my-bottomOffset, mx+gapRight-1, my+topOffset, screenCentre, rotation) -- left
				-- drawRotated(mx+stretch+length+gapRight+1, my-stretch-bottomOffset, mx+gapRight+length+stretch+1, my+topOffset-stretch, screenCentre, rotation) -- right

				-- -- Outline top
				-- drawRotated(mx-stretch-bottomOffset, my-length-stretch-gapRight-1, mx+topOffset-stretch, my-gapRight-length-stretch-1, screenCentre, rotation) -- top
				-- drawRotated(mx-bottomOffset, my-gapRight+1, mx+topOffset, my-gapRight+1, screenCentre, rotation) -- bottom
				-- drawRotated(mx-stretch-bottomOffset, my-length-stretch-gapRight, mx-bottomOffset, my-gapRight, screenCentre, rotation) -- left
				-- drawRotated(mx-stretch+topOffset, my-length-stretch-gapRight, mx+topOffset, my-gapRight, screenCentre, rotation) -- right

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