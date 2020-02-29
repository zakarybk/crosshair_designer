local cachedCross = {} -- todo
 
local function Crosshair()

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

	surface.DrawLine( mx-stretch - length, my+stretch, mx - gap, my ) -- Left
	surface.DrawLine( mx+stretch + length, my-stretch, mx + gap, my ) -- Right
	surface.DrawLine( mx-stretch, my - length-stretch, mx, my - gap ) -- Up
	surface.DrawLine( mx+stretch, my + length+stretch, mx, my + gap ) -- Down
/*
	--Thickness
	for i=1,CrosshairDesigner.GetInt("Thickness") do 
		surface.DrawLine( mx-stretch - length, my+i+stretch, mx - gap, my+i )
		--surface.DrawLine( x - length, y+i, x - gap, y+i )
		surface.DrawLine( mx-stretch - length, my-i+stretch, mx - gap, my-i ) 
		
		surface.DrawLine( mx+stretch + length, my+i-stretch, mx + gap, my+i )
		surface.DrawLine( mx+stretch + length, my-i-stretch, mx + gap, my-i )
		
		surface.DrawLine( mx+i-stretch, my - length-stretch, mx+i, my - gap ) -- UP Right
		-- surface.DrawLine( x+i, y - length, x, y - gap )  -- cool
		surface.DrawLine( mx-i-stretch, my - length-stretch, mx-i, my - gap ) -- UP left
		
		surface.DrawLine( mx+i+stretch, my + length+stretch, mx+i, my + gap )
		surface.DrawLine( mx-i+stretch, my + length+stretch, mx-i, my + gap )
	end
*/
end

hook.Add("HUDPaint","CustomCross",Crosshair)