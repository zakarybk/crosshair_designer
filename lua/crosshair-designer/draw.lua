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
			surface.SetDrawColor(
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
		surface.SetDrawColor(
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

	if cachedCross["UseLine"] then

		local gap = cachedCross["Gap"] + dynamic
		local length = cachedCross["Length"]
		local stretch = cachedCross["Stretch"]

		local gapLeft = math.floor((gap/2)) + 1
		local gapRight = math.ceil(gap/2)

		-- Draw the inital lines
		surface.DrawLine(mx-stretch-length-gapLeft, my+stretch, mx-gapLeft, my) -- left
		surface.DrawLine(mx+stretch, my+length+stretch+gapLeft, mx, my+gapLeft) -- bottom

		surface.DrawLine(mx+stretch+length+gapRight, my-stretch, mx+gapRight, my) -- right
		surface.DrawLine(mx-stretch, my-length-stretch-gapRight, mx, my-gapRight) -- top

		if cachedCross["UseArrow"] then

			--Arrows
			for i=2,cachedCross["Thickness"] do

				local offset = math.floor(i/2)

				if i % 2 == 0 then
					-- Draw clockwise on other side of the line
					surface.DrawLine(mx-stretch-length-gapLeft, my+stretch-offset, mx-gapLeft, my) -- left
					surface.DrawLine(mx+stretch-offset, my+length+stretch+gapLeft, mx, my+gapLeft) -- bottom

					surface.DrawLine(mx+stretch+length+gapRight, my-stretch+offset, mx+gapRight, my) -- right
					surface.DrawLine(mx-stretch+offset, my-length-stretch-gapRight, mx, my-gapRight) -- top

				else
					-- Draw anti-clockwise on other side of the line
					surface.DrawLine(mx-stretch-length-gapLeft, my+stretch+offset, mx-gapLeft, my) -- left
					surface.DrawLine(mx+stretch+offset, my+length+stretch+gapLeft, mx, my+gapLeft) -- bottom

					surface.DrawLine(mx+stretch+length+gapRight, my-stretch-offset, mx+gapRight, my) -- right
					surface.DrawLine(mx-stretch-offset, my-length-stretch-gapRight, mx, my-gapRight) -- top

				end

			end

		else

			--Thickness
			for i=2,cachedCross["Thickness"] do

				local offset = math.floor(i/2)

				if i % 2 == 0 then
					-- Draw clockwise on other side of the line
					surface.DrawLine(mx-stretch-length-gapLeft, my+stretch-offset, mx-gapLeft, my-offset) -- left
					surface.DrawLine(mx+stretch-offset, my+length+stretch+gapLeft, mx-offset, my+gapLeft) -- bottom

					surface.DrawLine(mx+stretch+length+gapRight, my-stretch+offset, mx+gapRight, my+offset) -- right
					surface.DrawLine(mx-stretch+offset, my-length-stretch-gapRight, mx+offset, my-gapRight) -- top

				else
					-- Draw anti-clockwise on other side of the line
					surface.DrawLine(mx-stretch-length-gapLeft, my+stretch+offset, mx-gapLeft, my+offset) -- left
					surface.DrawLine(mx+stretch+offset, my+length+stretch+gapLeft, mx+offset, my+gapLeft) -- bottom

					surface.DrawLine(mx+stretch+length+gapRight, my-stretch-offset, mx+gapRight, my-offset) -- right
					surface.DrawLine(mx-stretch-offset, my-length-stretch-gapRight, mx-offset, my-gapRight) -- top

				end
			end
		end

	end

	-- Middle of screen
	--surface.SetDrawColor(255,0,0,255)
	--surface.DrawLine(ScrW() / 2, ScrH() / 2, (ScrW() / 2)+1, (ScrH() / 2)+1)

	if cachedCross["UseCircle"] then
		if cachedCross["CircleRadius"] == 1 then
			surface.DrawLine(ScrW() / 2, ScrH() / 2, (ScrW() / 2)+1, (ScrH() / 2)+1)
		else
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
			ScrW()/2,
			ScrH()/2,
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
		ScrW()/2,
		ScrH()/2,
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"]
	)


	ply = LocalPlayer()

	hook.Add("HUDPaint", "CrosshairDesigner_DrawCrosshair", Crosshair)
	hc_dynamiccorsshair()
end)

hook.Add("CrosshairDesigner_DetectedResolutionChange", "CenterCircle", function()
	cachedCross.circle = generateCircle(
		ScrW()/2,
		ScrH()/2,
		cachedCross["CircleRadius"],
		cachedCross["CircleSegments"]
	)
end)