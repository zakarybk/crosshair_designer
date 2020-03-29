CrosshairDesigner = CrosshairDesigner or {}

print("Loading crosshair designer (590788321)")

if SERVER then
	AddCSLuaFile("detours.lua")
	AddCSLuaFile("db.lua")
	AddCSLuaFile("hide.lua")
	AddCSLuaFile("draw.lua")
	AddCSLuaFile("menu.lua")

	--[[
		Chat command to open menu - OnPlayerChat wasn't working in TTT
	]]--
	hook.Add("PlayerSay", "PlayerSayExample", function(ply, text, team)
		text = string.Trim(string.lower(text))

		if text == "!cross" or text == "!crosshair" or text == "!crosshairs" then
			ply:ConCommand("crosshairs")
			return text
		end
	end)

else
	include("detours.lua")
	include("db.lua")
	include("hide.lua")
	include("draw.lua")
	include("menu.lua")

	--[[
		Setup the client convars and callbacks to verify values
	]]--
	CrosshairDesigner.SetUpConvars({ -- Must be in this order as it's the order the values are read from file
		{
			id="ShowHL2",
			var="toggle_crosshair_hide", 
			default="0", 
			help="Show the half life crosshair",
			title="Show HL2/TFA crosshair",
			isBool=true
		},
		{
			id="ShowCross",
			var="toggle_crosshair", 
			default="1", 
			help="Hide the custom crosshair",
			title="Show custom crosshair",
			isBool=true
		},
		{
			id="HideOnADS",
			var="cross_ads", 
			default="1", 
			help="Hide the custom crosshair when aiming down sights",
			title="Hide when aiming down sights",
			isBool=true
		},
		{
			id="UseLine",
			var="cross_line", 
			default="1",
			help="Use the line style for the crosshair",
			title="Show crosshair lines",
			isBool=true
		},
		{
			id="UseArrow",
			var="cross_arrow",
			default="0",
			help="Change the lines on the crosshair to be pointed",
			title="Make lines into arrows",
			isBool=true,
		},
		{
			id="UseCircle",
			var="cross_circle",
			default="0",
			help="Add a circle to the middle of the crosshair",
			title="Add circle crosshair",
			isBool=true,
		},


		{
			id="Red",
			var="cross_hud_color_r",
			default="50",
			help="Change the amount of red in the crosshair",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="Green",
			var="cross_hud_color_g",
			default="250",
			help="Change the amount of green in the crosshair",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="Blue",
			var="cross_hud_color_b",
			default="50",
			help="Change the amount of blue in the crosshair",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="Alpha",
			var="cross_hud_color_a",
			default="255",
			help="Change the transparency of the crosshair",
			min=0,
			max=255,
			isColour=true,
		},


		{
			id="Gap",
			var="cross_gap",
			default="8",
			help="Change size of the gap in the middle of the crosshair",
			title="Gap in middle",
			min=0,
			max=100,
		},
		{
			id="Length",
			var="cross_length",
			default="7",
			help="Change the length of the lines in the crosshair",
			title="Length of lines",
			min=0,
			max=100,
		},
		{
			id="Thickness",
			var="cross_thickness",
			default="3",
			help="Change the length of the lines in the crosshair",
			title="Thickness of lines",
			min=0,
			max=100,
		},
		{
			id="Stretch",
			var="cross_stretch",
			default="0",
			help="The amount to stretch the crosshair by",
			title="Stretch of lines",
			min=0,
			max=360,
		},
		{
			id="CircleRadius",
			var="cross_radius",
			default="0",
			help="The radius for the circle if enabled with cross_circle",
			title="Circle radius",
			min=0,
			max=100,
		},
		{
			id="CircleSegments",
			var="cross_segments",
			default="0",
			help="The number of segments for the circle if enabled with cross_circle",
			title="Circle segments",
			min=0,
			max=100,
		},


		{
			id="ColOnTarget",
			var="hc_target_colour", 
			default="1", 
			help="Use the line style for the crosshair",
			title="Change colour on target",
			isBool=true,
		},
		{
			id="TargetRed",
			var="target_cross_hud_color_r",
			default="250",
			help="Change the amount of red in the crosshair when aiming at a target",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="TargetGreen",
			var="target_cross_hud_color_g",
			default="46",
			help="Change the amount of green in the crosshair when aiming at a target",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="TargetBlue",
			var="target_cross_hud_color_b",
			default="46",
			help="Change the amount of blue in the crosshair when aiming at a target",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="TargetAlpha",
			var="target_cross_hud_color_a",
			default="255",
			help="Change the transparency of the crosshair when aiming at a target",
			min=0,
			max=255,
			isColour=true,
		},


		{
			id="Dynamic",
			var="hc_dynamic_cross",
			default="0",
			help="Make the crosshair dynamic",
			title="Make dynamic",
			isBool=true
		},
		{
			id="DynamicSize",
			var="hc_dynamic_amount",
			default="50",
			help="The amount the dynamic crosshair will move when enabled with hc_dynamic_cross",
			title="Dynamic effect size",
			min=0,
			max=100,
		},
		{
			id="HideInVeh",
			var="hc_vehicle_cross",
			default="1",
			help="Hide the crosshair when in a vehicle",
			title="Hide in vehicle",
			isBool=true
		},

		-- NEW
		{
			id="HideInSpectate",
			var="crosshairdesigner_hideinspectate",
			default="1",
			help="Hide the crosshair when spectating",
			title="Hide when spectating",
			isBool=true
		},
		{
			id="HideTTT",
			var="crosshairdesigner_hidettt",
			default="1",
			help="Hide the TTT crosshair",
			title="Hide TTT crosshair",
			isBool=true
		},
		{
			id="HideFAS",
			var="crosshairdesigner_hidefas",
			default="1",
			help="Hide the FA:S crosshair",
			title="Hide FA:S crosshair",
			isBool=true
		},
		{
			id="HideCW",
			var="crosshairdesigner_hidecw",
			default="1",
			help="Hide the CW 2.0 crosshair",
			title="Hide CW crosshair",
			isBool=true
		},
		{
			id="TraceDraw",
			var="crosshairdesigner_tracedraw",
			default="0",
			help="Draw based on player angles",
			title="Centre to player angles",
			isBool=true
		},
	})

	--[[
		SWEP should draw custom crosshair checks

		ply and wep will always be valid

		Only one of these can be valid at once so the most
		any one of these will be called is once per frame
	]]--
	CrosshairDesigner.AddSwepCheck("FA:S", 
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 5) == "fas2_" then
				if wep.dt != nil and wep.dt.Status ~= nil then
					return true
				end
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				CrosshairDesigner.GetBool("HideOnADS") and 
				wep.dt.Status == FAS_STAT_ADS
			)
		end
	)

	-- TFA
	CrosshairDesigner.AddSwepCheck("TFA", 
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 4) == "tfa_" then
				if wep.GetIronSights ~= nil then
					return true
				end
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				CrosshairDesigner.GetBool("HideOnADS") and 
				wep:GetIronSights()
			)
		end
	)

	-- M9k
	CrosshairDesigner.AddSwepCheck("M9K", 
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 4) == "m9k_" then
				if wep.GetIronsights ~= nil and
					wep.IronSightsPos ~= nil and
					wep.RunSightsPos ~= nil 
					then return true
				end
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				CrosshairDesigner.GetBool("HideOnADS") and 
				wep:GetIronsights() and -- returns true when running....
				wep.IronSightsPos ~= wep.RunSightsPos -- so also check pos
			)
		end
	)

	-- CW
	CrosshairDesigner.AddSwepCheck("CW", 
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 3) == "cw_" then
				if wep.dt ~= nil and wep.dt.State != nil then
					return true
				end
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				CrosshairDesigner.GetBool("HideOnADS") and 
				wep.dt.State == CW_AIMING
			)
		end
	)
	
	-- Ghost Death Match Sweps
	CrosshairDesigner.AddSwepCheck("Ghost_DM", 
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 13) == "weapon_ghost_" then
				if wep.DrawHUD != nil then
					return true
				end
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				CrosshairDesigner.GetBool("HideOnADS") and 
				wep:GetIronSights()
			)
		end
	)

	-- Directory where everything is saved
	if not file.IsDir( "crosshair_designer", "DATA" ) then
		file.CreateDir( "crosshair_designer", "DATA" )
	end
end

print("Finished loading crosshair designer (590788321)")
hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)
