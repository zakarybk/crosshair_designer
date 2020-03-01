local cachedCross = {} -- todo

	
local drawingcircle = function( x, y, radius, seg )
	
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is need for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
	
end
 
local Crosshair = function()

	-- Conditions for crosshair to be drawn
	local shouldDraw = hook.Run("HUDShouldDraw", "CrosshairDesiger_Crosshair")

	if not shouldDraw then
		return true
	end

	-- todo weapon check (ads)

	-- todo vehicle check

	-- no cross sweps

	-- target colour


	-- Cross Colour
	surface.SetDrawColor(
		cachedCross["Red"],
		cachedCross["Green"],
		cachedCross["Blue"],
		cachedCross["Alpha"]
	)

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
			
			surface.DrawLine( mx+i-stretch, my - length-stretch, mx, my - gap ) -- UP Right
			-- surface.DrawLine( x+i, y - length, x, y - gap )  -- cool
			surface.DrawLine( mx-i-stretch, my - length-stretch, mx, my - gap ) -- UP left
			
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
			
			surface.DrawLine( mx+i-stretch, my - length-stretch, mx+i, my - gap ) -- UP Right
			surface.DrawLine( mx-i-stretch, my - length-stretch, mx-i, my - gap ) -- UP left
			
			surface.DrawLine( mx+i+stretch, my + length+stretch, mx+i, my + gap )
			surface.DrawLine( mx-i+stretch, my + length+stretch, mx-i, my + gap )
		end

	end

	if cachedCross["UseCircle"] then
		draw.NoTexture()
		drawingcircle(
			mx, 
			my, 
			cachedCross["CircleRadius"], 
			cachedCross["CircleSegments"]
		)
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

	hook.Add("HUDPaint", "CustomCross", Crosshair)
end)