local cachedCross = {} -- todo

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
 
local Crosshair = function()

	-- Conditions for crosshair to be drawn
	local shouldDraw = hook.Run("HUDShouldDraw", "CrosshairDesiger_Crosshair")
	local ply = LocalPlayer()

	if not shouldDraw or not IsValid(ply) then
		return true
	end

	-- Cross Colour
	surface.SetDrawColor(
		cachedCross["Red"],
		cachedCross["Green"],
		cachedCross["Blue"],
		cachedCross["Alpha"]
	)

	-- Change col on target
	if cachedCross["ColOnTarget"] then
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and (target:IsPlayer() or target:IsNPC()) then
			surface.SetDrawColor(
				cachedCross["TargetRed"],
				cachedCross["TargetGreen"],
				cachedCross["TargetBlue"],
				cachedCross["TargetAlpha"]
			)
		end
	end 

	if cachedCross["UseLine"] then

		local mx = ScrW() / 2
		local my = ScrH() / 2

		local gap = cachedCross["Gap"]
		local length = cachedCross["Length"]
		local stretch = cachedCross["Stretch"]

		-- centre gap option? - link to thickness? -- conflict with draw poly
		surface.DrawLine( mx-stretch - length, my+stretch, mx - gap, my ) -- Left
		surface.DrawLine( mx+stretch + length, my-stretch, mx + gap, my ) -- Right
		surface.DrawLine( mx-stretch, my - length-stretch, mx, my - gap ) -- Up
		surface.DrawLine( mx+stretch, my + length+stretch, mx, my + gap ) -- Down

		if cachedCross["UseArrow"] then
			
			--Arrows -- replace with draw poly? -- remove call overlay effect with low alpha
			for i=1,cachedCross["Thickness"] do 
				surface.DrawLine( mx-stretch - length, my+i+stretch, mx - gap, my )
				surface.DrawLine( mx-stretch - length, my-i+stretch, mx - gap, my ) 
				
				surface.DrawLine( mx+stretch + length, my+i-stretch, mx + gap, my )
				surface.DrawLine( mx+stretch + length, my-i-stretch, mx + gap, my )
				
				surface.DrawLine( mx+i-stretch, my - length-stretch, mx, my - gap )
				surface.DrawLine( mx-i-stretch, my - length-stretch, mx, my - gap )
				
				surface.DrawLine( mx+i+stretch, my + length+stretch, mx, my + gap )
				surface.DrawLine( mx-i+stretch, my + length+stretch, mx, my + gap )
			end 

		else

			--Thickness
			for i=1,cachedCross["Thickness"] do 
				surface.DrawLine( mx-stretch - length, my+i+stretch, mx - gap, my+i )
				surface.DrawLine( mx-stretch - length, my-i+stretch, mx - gap, my-i ) 
				
				surface.DrawLine( mx+stretch + length, my+i-stretch, mx + gap, my+i )
				surface.DrawLine( mx+stretch + length, my-i-stretch, mx + gap, my-i )
				
				surface.DrawLine( mx+i-stretch, my - length-stretch, mx+i, my - gap )
				surface.DrawLine( mx-i-stretch, my - length-stretch, mx-i, my - gap )
				
				surface.DrawLine( mx+i+stretch, my + length+stretch, mx+i, my + gap )
				surface.DrawLine( mx-i+stretch, my + length+stretch, mx-i, my + gap )
			end

		end

	end

	if cachedCross["UseCircle"] then
		draw.NoTexture()
		surface.DrawPoly(cachedCross.circle)
	end


end

--[[
	Hide HL2 (+TFA) crosshair
]]--

hook.Add("HUDShouldDraw", "HideHUD", function(name)
	if name == "CHudCrosshair" and 
		not CrosshairDesigner.GetBool("ShowHL2") 
		then
		return false 
	end
end)

-- Update cached values
hook.Add("CrosshairDesigner_ValueChanged", "UpdateCrosshair", function(convar, val)
	local data = CrosshairDesigner.GetConvarData(convar)

	if data.isBool then
		cachedCross[data.id] = tobool(val)
	else
		cachedCross[data.id] = tonumber(val)
	end

	if data.id == "CircleRadius" or data.id == "CircleSegments" then
		cachedCross.circle = generateCircle(
			ScrW()/2, 
			ScrH()/2, 
			cachedCross["CircleRadius"], 
			cachedCross["CircleSegments"]
		)
	end
end)

-- Load cached values
hook.Add("CrosshairDesigner_FullyLoaded", "CrosshairDesigner_SetupDrawing", function(tbl)
	for i, data in pairs(CrosshairDesigner.GetConvarDatas()) do
		if data.isBool then
			cachedCross[data.id] = CrosshairDesigner.GetBool(data.id)
		else
			cachedCross[data.id] = CrosshairDesigner.GetInt(data.id)
		end
	end

	cachedCross.circle = generateCircle(
		ScrW()/2, 
		ScrH()/2, 
		cachedCross["CircleRadius"], 
		cachedCross["CircleSegments"]
	)

	hook.Add("HUDPaint", "CustomCross", Crosshair)
end)

hook.Add("CrosshairDesigner_DetectedResolutionChange", "CenterCircle", function()
	cachedCross.circle = generateCircle(
		ScrW()/2, 
		ScrH()/2, 
		cachedCross["CircleRadius"], 
		cachedCross["CircleSegments"]
	)
end)