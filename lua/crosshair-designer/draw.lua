local cachedCross = {}

-- Fix crosshair thickness (adds two at once) - though will be troublesome with backwards compatibility

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
local dynamic = 0
local hc_shootingvalue = 0
local hc_dynamiccorsshair = function()
	
	local ply = LocalPlayer()
	
	if not cachedCross["Dynamic"] or timer.Exists("HC_SmoothDynamics") then
		timer.Destroy ("HC_SmoothDynamics")
	end
		
	if cachedCross["Dynamic"] then
		timer.Create( "HC_SmoothDynamics", 0.03, 0, function()
			local hc_dynamicamount = cachedCross["DynamicSize"]
			local speedzzz = ply:GetVelocity():Length()
			
			if ply:Health() > 0 and ply:GetActiveWeapon():IsValid() then
				if ply:GetActiveWeapon():Clip1() > 0 then
					if speedzzz / string.len( speedzzz )  < hc_dynamicamount and speedzzz / string.len( speedzzz ) > 3 then
						dynamic = speedzzz / string.len( speedzzz ) 
			
					elseif speedzzz / string.len( speedzzz ) < 3 and ply:KeyDown( IN_ATTACK ) and hc_shootingvalue < hc_dynamicamount / 3 then
						hc_shootingvalue = hc_shootingvalue + 0.5
						dynamic = hc_shootingvalue
			
					elseif speedzzz / string.len( speedzzz ) < 3 and !ply:KeyDown( IN_ATTACK ) and hc_shootingvalue > 0 then
						hc_shootingvalue = hc_shootingvalue - 0.5
						dynamic = hc_shootingvalue
			
					elseif speedzzz / string.len( speedzzz ) < 4 and !ply:KeyDown( IN_ATTACK ) and hc_shootingvalue < 1 then  ---- IN_ATTACK1 instead
						dynamic = speedzzz / string.len( speedzzz )
					end
				else
					dynamic = 0
				end
			end
		end)
	end
end

local Crosshair = function()

	-- Conditions for crosshair to be drawn
	local shouldDraw = hook.Run("HUDShouldDraw", "CrosshairDesiger_Crosshair")
	local ply = LocalPlayer()

	if not shouldDraw or not IsValid(ply) then
		return
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

		local gap = cachedCross["Gap"] + dynamic
		local length = cachedCross["Length"]
		local stretch = cachedCross["Stretch"]

		if cachedCross["UseArrow"] then
			
			--Arrows -- replace with draw poly? -- remove call overlay effect with low alpha
			for i=1,cachedCross["Thickness"] do

				local gapLeft = (gap/2)
				local gapRight = math.floor(gap/2)

				local iLeft = (i/2)
				local iRight = math.floor(i/2)
				/*
				if i%2==1 then
					surface.DrawLine(mx-stretch-length, my+iLeft+stretch, mx+gapLeft, my) -- left.top
					surface.DrawLine(mx+stretch+length, my-iRight-stretch, mx+gapRight+1, my) -- right.top

					surface.DrawLine(mx+iRight-stretch, my-length-stretch, mx, my-gapRight) -- top.right
					surface.DrawLine(mx+iRight+stretch, my+length+stretch, mx, my + gapRight) -- bottom.right

				else
					surface.DrawLine(mx-stretch-length, my-iLeft+stretch, mx-gapLeft, my) -- left.bottom
					surface.DrawLine(mx-iLeft+stretch, my+length+stretch, mx, my + gapLeft) -- bottom.left

					if cachedCross["Thickness"] % 2 == 0 then
						surface.DrawLine(mx+iRight-stretch, my - length-stretch, mx, my - gapRight) -- top.right
					else
						surface.DrawLine(mx-iLeft-stretch, my - length-stretch, mx, my - gapLeft) -- top.left
					end

					surface.DrawLine(mx+stretch+length, my+iRight-stretch, mx + gapRight, my) -- right.bottom
				end
				*/
				if i%2==1 then
					surface.DrawLine(mx-stretch-length, my+iRight+stretch, mx-gapRight, my)-- left.bottom
					surface.DrawLine(mx+stretch+length+gapLeft, my+iLeft-stretch, mx+gapLeft, my) -- right.top

					surface.DrawLine(mx+iRight-stretch, my-length-stretch, mx, my-gapRight) -- top.right
					surface.DrawLine(mx+iRight+stretch, my+length+stretch, mx, my+gapRight) -- bottom.right
				else
					surface.DrawLine(mx-stretch-length, my-iLeft+stretch, mx-gapRight, my)-- left.top
					surface.DrawLine(mx-iLeft+stretch, my+length+stretch, mx, my+gapLeft) -- bottom.left
					
					if cachedCross["Thickness"] % 2 == 0 and cachedCross["Thickness"] < 4 then
						surface.DrawLine(mx+iRight-stretch, my-length-stretch, mx, my-gapRight) -- top.right
						surface.DrawLine(mx+stretch+length, my+iLeft-stretch, mx+gapLeft, my) -- right.top
					else
						surface.DrawLine(mx-iLeft-stretch, my-length-stretch, mx, my-gapRight) -- top.left
						surface.DrawLine(mx+stretch+length, my-iRight-stretch, mx + gapRight, my) -- right.bottom
					end
				end
				
			end 

		else

			--Thickness
			for i=1,cachedCross["Thickness"] do

				local gapLeft = (gap/2)
				local gapRight = math.floor(gap/2)

				local iLeft = (i/2)
				local iRight = math.floor(i/2)

				if i%2==1 then
					surface.DrawLine(mx-stretch-length-gapRight, my+iRight+stretch, mx-gapRight, my+iRight)-- left.bottom
					surface.DrawLine(mx+stretch+length+gapLeft, my+iLeft-stretch, mx+gapLeft, my+iLeft) -- right.top

					surface.DrawLine(mx+iRight-stretch, my-length-stretch-gapRight, mx+iRight, my-gapRight) -- top.right
					surface.DrawLine(mx+iRight+stretch, my+length+stretch+gapRight, mx+iRight, my + gapRight) -- bottom.right
				else
					surface.DrawLine(mx-stretch-length-gapRight, my-iLeft+stretch, mx-gapRight, my-iLeft)-- left.top
					surface.DrawLine(mx-iRight+stretch, my+length+stretch+gapRight, mx-iRight, my + gapRight) -- bottom.left
					
					if cachedCross["Thickness"] % 2 == 0 and cachedCross["Thickness"] < 4  then
						surface.DrawLine(mx+iRight-stretch, my-length-stretch-gapRight, mx+iRight, my-gapRight) -- top.right
						surface.DrawLine(mx+stretch+length+gapLeft, my+iLeft-stretch, mx+gapLeft, my+iLeft) -- right.top
					else
						surface.DrawLine(mx-iLeft-stretch, my-length-stretch-gapRight, mx-iLeft, my-gapRight) -- top.left
						surface.DrawLine(mx+stretch+length+gapLeft, my-iRight-stretch, mx + gapRight, my-iRight) -- right.bottom
					end
				end
			end
		end

	end

	-- Middle of screen
	--surface.SetDrawColor(255,0,0,255)
	--surface.DrawLine(ScrW() / 2, ScrH() / 2, (ScrW() / 2)+1, (ScrH() / 2)+1)

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

	if data.id == "Dynamic" then
		if not CrosshairDesigner.GetBool(data.id) then
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

-- Start up
local function Hc_startup()

	if not file.IsDir( "crosshair_designer", "DATA" ) then
		file.CreateDir( "crosshair_designer", "DATA" )
	end

	timer.Create("Hc_load_dynamic_startup", 1, 0, function()  
		if LocalPlayer():IsValid() then
			timer.Destroy( "Hc_load_dynamic_startup" )
			hc_dynamiccorsshair()
		end
	end)

end
hook.Add("Initialize", "Hc_startup", Hc_startup)
Hc_startup()