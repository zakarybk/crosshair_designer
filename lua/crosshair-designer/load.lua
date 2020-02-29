CrosshairDesigner = CrosshairDesigner or {}

if SERVER then
	AddCSLuaFile("detours.lua")
	AddCSLuaFile("fonts.lua")
	AddCSLuaFile("db.lua")
	AddCSLuaFile("hide.lua")
	AddCSLuaFile("draw.lua")
	AddCSLuaFile("menu.lua")
else
	include("detours.lua")
	include("fonts.lua")
	include("db.lua")
	include("hide.lua")
	include("draw.lua")
	include("menu.lua")

	--[[
		Setup the client convars and callbacks to verify values
	]]--
	CrosshairDesigner.SetUpConvars({ -- Needs to be in order since it's the read order from file
		{
			id="ShowHL2",
			var="toggle_crosshair_hide", 
			default="1", 
			help="Show the half life crosshair", 
			isBool=true
		},
		{
			id="ShowCross",
			var="toggle_crosshair", 
			default="0", 
			help="Hide the custom crosshair", 
			isBool=true
		},
		{
			id="HideOnADS",
			var="cross_ads", 
			default="1", 
			help="Hide the custom crosshair when aiming down sights", 
			isBool=true
		},
		{
			id="UseLine",
			var="cross_line", 
			default="1", 
			help="Use the line style for the crosshair", 
			isBool=true
		},
		{
			id="UseArrow",
			var="cross_arrow",
			default="1",
			help="Change the lines on the crosshair to be pointed",
			isBool=true,
		},
		{
			id="UseCircle",
			var="cross_circle",
			default="0",
			help="Add a circle to the middle of the crosshair",
			isBool=true,
		},


		{
			id="Red",
			var="cross_hud_color_r",
			default="29",
			help="Change the amount of red in the crosshair",
			min=0,
			max=255,
		},
		{
			id="Green",
			var="cross_hud_color_g",
			default="0",
			help="Change the amount of green in the crosshair",
			min=0,
			max=255,
		},
		{
			id="Blue",
			var="cross_hud_color_b",
			default="255",
			help="Change the amount of blue in the crosshair",
			min=0,
			max=255,
		},
		{
			id="Alpha",
			var="cross_hud_color_a",
			default="255",
			help="Change the transparency of the crosshair",
			min=0,
			max=255,
		},


		{
			id="Gap",
			var="cross_gap",
			default="5",
			help="Change size of the gap in the middle of the crosshair",
			min=0,
			max=50,
		},
		{
			id="Length",
			var="cross_length",
			default="13",
			help="Change the length of the lines in the crosshair",
			min=0,
			max=50,
		},
		{
			id="Thickness",
			var="cross_thickness",
			default="1",
			help="Change the length of the lines in the crosshair",
			min=0,
			max=50,
		},
		{
			id="Stretch",
			var="cross_stretch",
			default="0",
			help="The amount to stretch the crosshair by",
			min=0,
			max=360,
		},
		{
			id="CircleRadius",
			var="cross_radius",
			default="0",
			help="The radius for the circle if enabled with cross_circle",
			min=0,
			max=50,
		},
		{
			id="CircleSegments",
			var="cross_segments",
			default="0",
			help="The number of segments for the circle if enabled with cross_circle",
			min=0,
			max=50,
		},


		{
			id="ColOnTarget",
			var="hc_target_colour", 
			default="1", 
			help="Use the line style for the crosshair", 
			isBool=true
		},
		{
			id="TargetRed",
			var="target_cross_hud_color_r",
			default="255",
			help="Change the amount of red in the crosshair when aiming at a target",
			min=0,
			max=255,
		},
		{
			id="TargetGreen",
			var="target_cross_hud_color_g",
			default="0",
			help="Change the amount of green in the crosshair when aiming at a target",
			min=0,
			max=255,
		},
		{
			id="TargetBlue",
			var="target_cross_hud_color_b",
			default="0",
			help="Change the amount of blue in the crosshair when aiming at a target",
			min=0,
			max=255,
		},
		{
			id="TargetAlpha",
			var="target_cross_hud_color_a",
			default="255",
			help="Change the transparency of the crosshair when aiming at a target",
			min=0,
			max=255,
		},


		{
			id="Dynamic",
			var="hc_dynamic_cross",
			default="0",
			help="Make the crosshair dynamic",
			isBool=true
		},
		{
			id="DynamicSize",
			var="hc_dynamic_amount",
			default="50",
			help="The amount the dynamic crosshair will move when enabled with hc_dynamic_cross",
			min=0,
			max=50,
		},
		{
			id="HideInVeh",
			var="hc_vehicle_cross",
			default="1",
			help="Hide the crosshair when in a vehicle",
			isBool=true
		},
	})

	--[[
		SWEP should draw custom crosshair checks

		ply and wep will always be valid

		Only one of these can be valid at once so the most
		any one of these will be called is once per frame
	]]--
	CrosshairDesigner.AddSwepCheck(
		"FA:S", 
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 4) == "fas2" then
				return true
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (CrosshairDesigner.GetBool("HideOnADS") and wep.dt.Status == FAS_STAT_ADS)
		end,
		function(ply, wep) -- OnSet
			if CrosshairDesigner.GetBool("HideOnADS") then
				CrosshairDesigner.AddConvarDetour("fas2_nohud", 1)
			end
		end,
		function(ply, wep) -- OnRemove
			CrosshairDesigner.RemoveConvarDetour("fas2_nohud")
		end
	)

	-- TFA

	-- M9k

	-- FA:S
end

hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)