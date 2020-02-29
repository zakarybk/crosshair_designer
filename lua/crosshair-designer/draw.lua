local cachedCross = {} -- todo

	
local function drawingcircle( x, y, radius, seg )
	
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
 
local function Crosshair()

	-- Conditions for crosshair to be drawn
	if not CrosshairDesigner.GetBool("ShowCross") or 
		LocalPlayer():Health() <= 0 or
		not LocalPlayer():GetActiveWeapon():IsValid() then
		return
	end

	-- todo weapon check (ads)

	-- todo vehicle check

	-- no cross sweps

	-- target colour


	-- Cross Colour
	surface.SetDrawColor(
		CrosshairDesigner.GetInt("Red"),
		CrosshairDesigner.GetInt("Green"),
		CrosshairDesigner.GetInt("Blue"),
		CrosshairDesigner.GetInt("Alpha")
	)

	local mx = ScrW() / 2
	local my = ScrH() / 2

	local gap = CrosshairDesigner.GetInt("Gap")
	local length = CrosshairDesigner.GetInt("Length")
	local stretch = CrosshairDesigner.GetInt("Stretch")

	-- centre gap option? - link to thickness? -- conflict with draw poly
	surface.DrawLine( mx-stretch - length, my+stretch, mx - gap, my ) -- Left
	surface.DrawLine( mx+stretch + length, my-stretch, mx + gap, my ) -- Right
	surface.DrawLine( mx-stretch, my - length-stretch, mx, my - gap ) -- Up
	surface.DrawLine( mx+stretch, my + length+stretch, mx, my + gap ) -- Down

	if CrosshairDesigner.GetBool("UseArrow") then
		
		--Arrows -- replace with draw poly? -- remove call overlay effect with low alpha
		for i=1,CrosshairDesigner.GetInt("Thickness") do 
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
		for i=1,CrosshairDesigner.GetInt("Thickness") do 
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

	if CrosshairDesigner.GetBool("UseCircle") then
		draw.NoTexture()
		drawingcircle(
			mx, 
			my, 
			CrosshairDesigner.GetInt("CircleRadius"), 
			CrosshairDesigner.GetInt("CircleSegments")
		)
	end


end

hook.Add("HUDPaint","CustomCross",Crosshair)

hook.Add("CrosshairDesigner_ValueChanged", "UpdateCrosshair", print)