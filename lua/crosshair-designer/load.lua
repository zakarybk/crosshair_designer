CrosshairDesigner = CrosshairDesigner or {}

if SERVER then
	AddCSLuaFile("fonts.lua")
	AddCSLuaFile("db.lua")
	AddCSLuaFile("draw.lua")
	AddCSLuaFile("menu.lua")
else
	include("fonts.lua")
	include("db.lua")
	include("draw.lua")
	include("menu.lua")

	/*
	local convars = {}
	convars.ShowHL2 = CreateClientConVar("toggle_crosshair_hide", 0, true, false, "Show the Half Life crosshair", 0, 1)
	convars.HideCross = CreateClientConVar("toggle_crosshair", 1, true, false)
	convars.HideOnADS = CreateClientConVar("cross_ads", 1, true, false)
	convars.UseLine = CreateClientConVar("cross_line", 1, true, false)
	convars.ColOnTarget = CreateClientConVar("hc_target_colour", 1, true, false)
	convars.Dynamic = CreateClientConVar("hc_dynamic_cross", 1, true, false)
	convars.HideInVeh = CreateClientConVar("hc_vehicle_cross", 1, true, false)
	convars.
	*/

	CrosshairDesigner.SetUpConvars({
		["ShowHL2"] = {
			id="toggle_crosshair_hide", 
			default="1", 
			help="Show the half life crosshair", 
			isBool=true
		},
		["HideCross"] = {
			id="toggle_crosshair", 
			default="0", 
			help="Hide the custom crosshair", 
			isBool=true
		},
		["HideOnADS"] = {
			id="cross_ads", 
			default="1", 
			help="Hide the custom crosshair when aiming down sights", 
			isBool=true
		},
		["UseLine"] = {
			id="cross_line", 
			default="1", 
			help="Use the line style for the crosshair", 
			isBool=true
		},
		["ColOnTarget"] = {
			id="hc_target_colour", 
			default="1", 
			help="Use the line style for the crosshair", 
			isBool=true
		},
		["Dynamic"] = {
			id="hc_dynamic_cross",
			default="0",
			help="Make the crosshair dynamic",
			isBool=true
		},

		["Red"] = {
			id="cross_hud_color_r",
			default="29",
			help="Change the amount of red in the crosshair",
			min=0,
			max=255,
		},
		["Green"] = {
			id="cross_hud_color_g",
			default="0",
			help="Change the amount of green in the crosshair",
			min=0,
			max=255,
		},
		["Blue"] = {
			id="cross_hud_color_b",
			default="255",
			help="Change the amount of blue in the crosshair",
			min=0,
			max=255,
		},
		["Alpha"] = {
			id="cross_hud_color_b",
			default="255",
			help="Change the transparency of the crosshair",
			min=0,
			max=255,
		},

		["TargetRed"] = {
			id="target_cross_hud_color_r",
			default="255",
			help="Change the amount of red in the crosshair when aiming at a target",
			min=0,
			max=255,
		},
		["TargetGreen"] = {
			id="target_cross_hud_color_g",
			default="0",
			help="Change the amount of green in the crosshair when aiming at a target",
			min=0,
			max=255,
		},
		["TargetBlue"] = {
			id="target_cross_hud_color_b",
			default="0",
			help="Change the amount of blue in the crosshair when aiming at a target",
			min=0,
			max=255,
		},
		["TargetAlpha"] = {
			id="target_cross_hud_color_a",
			default="255",
			help="Change the transparency of the crosshair when aiming at a target",
			min=0,
			max=255,
		},

		["Gap"] = {
			id="cross_gap",
			default="5",
			help="Change size of the gap in the middle of the crosshair",
			min=0,
			max=50,
		},
		["Length"] = {
			id="cross_length",
			default="13",
			help="Change the length of the lines in the crosshair",
			min=0,
			max=50,
		},
		["Thickness"] = {
			id="cross_thickness",
			default="1",
			help="Change the length of the lines in the crosshair",
			min=0,
			max=50,
		},
		["UseArrow"] = {
			id="cross_arrow",
			default="1",
			help="Change the lines on the crosshair to be pointed",
			isBool=true,
		},
		["Stretch"] = {
			id="cross_stretch",
			default="0",
			help="The amount to stretch the crosshair by",
			min=0,
			max=360,
		},

		["UseCircle"] = {
			id="cross_circle",
			default="0",
			help="Add a circle to the middle of the crosshair",
			isBool=true,
		},
		["CircleRadius"] = {
			id="cross_radius",
			default="0",
			help="The radius for the circle if enabled with cross_circle",
			min=0,
			max=50,
		},
		["CircleSegments"] = {
			id="cross_segments",
			default="0",
			help="The number of segments for the circle if enabled with cross_circle",
			min=0,
			max=50,
		},
		["DynamicSize"] = {
			id="hc_dynamic_amount",
			default="50",
			help="The amount the dynamic crosshair will move when enabled with hc_dynamic_cross",
			min=0,
			max=50,
		},
	})



	hook.Add("CrosshairDesigner_ValueChanged", "test", print)
end

