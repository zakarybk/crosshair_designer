CrosshairDesigner = CrosshairDesigner or {}

print("Loading crosshair designer (590788321)")

if SERVER then
	AddCSLuaFile("detours.lua")
	AddCSLuaFile("db.lua")
	AddCSLuaFile("hide.lua")
	AddCSLuaFile("calculate.lua")
	AddCSLuaFile("draw.lua")
	AddCSLuaFile("menu.lua")
	AddCSLuaFile("disable.lua")

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
	include("calculate.lua")
	include("draw.lua")
	include("menu.lua")
	include("disable.lua")

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
			help="Draw four crosshair lines",
			title="Show crosshair lines",
			isBool=true
		},
		{
			id="LineStyle",
			var="cross_arrow",
			default="0",
			help="Change the lines on the crosshair to be pointed:\n0 = Rectangle\n1 = Inwards\n2 = Outwards",
			title="Line Style",
			min=0,
			max=2,
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
			min=2,
			max=100,
		},
		{
			id="Thickness",
			var="cross_thickness",
			default="3",
			help="Change the thickness of the lines in the crosshair",
			title="Thickness of lines",
			min=1,
			max=100,
		},
		{
			id="Stretch",
			var="cross_stretch",
			default="0",
			help="The amount to stretch the crosshair by (disabled when using fill draw)",
			title="Stretch of lines",
			min=-180,
			max=180,
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
			help="Change the colour of the crosshair when aiming at a target",
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

		-- Outline
		{
			id="Outline",
			var="crosshair_designer_outline",
			default="0",
			help="Outlines the crosshair",
			title="Outline thickness",
			min=0,
			max=100
		},
		{
			id="OutlineRed",
			var="crosshair_designer_outline_r",
			default="0",
			help="Change the amount of red in the outline of the crosshair",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="OutlineGreen",
			var="crosshair_designer_outline_g",
			default="0",
			help="Change the amount of green in the outline of the crosshair",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="OutlineBlue",
			var="crosshair_designer_outline_b",
			default="0",
			help="Change the amount of blue in the outline of the crosshair",
			min=0,
			max=255,
			isColour=true,
		},
		{
			id="OutlineAlpha",
			var="crosshair_designer_outline_a",
			default="255",
			help="Change the transparency of the outline of the crosshair",
			min=0,
			max=255,
			isColour=true,
		},

		-- Rotation
		{
			id="Rotation",
			var="crosshairdesigner_rotation",
			default="0",
			help="How much to rotate the crosshair by",
			title="Rotation",
			min=0,
			max=360,
		},

		-- Draw with polys instead of lines
		{
			id="FillDraw",
			var="crosshairdesigner_filldraw",
			default="0",
			help="Draw a single shape instead of multiple lines",
			title="Fill draw",
			isBool=true
		},
		{
			id="Segments",
			var="crosshairdesigner_segments",
			default="4",
			help="Change the number of segemnts which make up the crosshair",
			title="Segments",
			min=1,
			max=100,
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
				if wep.dt ~= nil and wep.dt.Status ~= nil then
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

	-- M9K is not listed as a setting since it doesn't draw its own crosshair
	-- We only need to hide our crosshair when aiming down sights
	-- M9k Remastered + Legacy
	CrosshairDesigner.AddSwepCheck("M9K",
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 4) == "m9k_" then
				if wep.GetIronsights ~= nil and
					wep.IronSightsPos ~= nil and
					wep.RunSightsPos ~= nil
					then return true -- M9k Legacy
				else
					return true -- M9k Remastered
				end
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				-- Legacy
				(not MMM_M9k_IsBaseInstalled and
				CrosshairDesigner.GetBool("HideOnADS") and
				wep:GetIronsights() and -- returns true when running....
				wep.IronSightsPos ~= wep.RunSightsPos) or -- so also check pos
				-- Remastered
				(MMM_M9k_IsBaseInstalled and
				CrosshairDesigner.GetBool("HideOnADS") and
				(wep.IronSightState ~= nil and wep.IronSightState or wep:GetNWInt("ScopeState") > 0))
			)
		end
	)

	-- CW
	CrosshairDesigner.AddSwepCheck("CW",
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 3) == "cw_" then
				if wep.dt ~= nil and wep.dt.State ~= nil then
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

	-- Scifi
	CrosshairDesigner.AddSwepCheck("Scifi",
		function(ply, wep) -- ShouldUse
			if string.Left(wep:GetClass(), 4) == "sfw_" then
				return wep.GetIronSights ~= nil
			end
		end,
		function(ply, wep) -- ShouldDraw
			return not (
				CrosshairDesigner.GetBool("HideOnADS") and
				wep:GetIronSights()
			)
		end
	)

	-- Disable Target Cross for Prop Hunt and Guess Who to stop cheating
	local gm = engine.ActiveGamemode()
	if gm == "prop_hunt" then
		CrosshairDesigner.DisableFeature("ColOnTarget", false, "Giving away positions in Prop Hunt!")
	elseif gm == "guesswho" then
		CrosshairDesigner.DisableFeature("ColOnTarget", false, "Giving away position in Guess Who!")
	end

	-- Directory where everything is saved
	if not file.IsDir( "crosshair_designer", "DATA" ) then
		file.CreateDir( "crosshair_designer", "DATA" )
	end
end

print("Finished loading crosshair designer (590788321)")
hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)