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
			help="Draw crosshair lines",
			title="Show crosshair lines",
			isBool=true
		},
		{
			id="LineStyle",
			var="cross_arrow",
			default="0",
			help="Change the lines on the crosshair to be pointed:\n0 = Rectangle\n1 = Inwards\n2 = Outwards",
			title="Line style",
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
		{
			id="HideInCameraView",
			var="crosshairdesigner_hideincameraview",
			default="0",
			help="Hides the crosshair when looking through a camera",
			title="Hide in camera view",
			isBool=true
		},
		{
			id="InvertCol",
			var="crosshairdesigner_invertcol",
			default="0",
			help="Inverts the colour of the crosshair",
			title="Invert crosshair colour",
			isBool=true
		},
		{
			id="InvertOutlineCol",
			var="crosshairdesigner_invertoutlinecol",
			default="0",
			help="Inverts the colour of the outline",
			title="Invert outline colour",
			isBool=true
		},
	})

	function isExpectedBaseOrClass(swep, expectedBase, expectedClassPrefix)
		if swep and swep.Base and swep.Base == expectedBase then
			return true
		elseif swep and swep.GetClass and
			string.Left(swep:GetClass(), #expectedClassPrefix) == expectedClassPrefix then
			return true
		else
			return false
		end
	end

	--[[
		Crosshair checks

		Checks the currently held weapon and tries to read
		information from the weapon to workout if our
		custom crosshair should be hidden. Such as if
		the player is using the aiming down sights.
	]]--

	-- The more odd they are, the further down the
	-- list they should be placed, so they don't
	-- interfer with anything.
	--
	-- If they're specific then add the param
	-- forceOnBaseClasses, and they will be
	-- used before anything else

	-- Also use forceOnBaseClasses to speedup lookup
	-- for known combinations

	-- TFA -- thank you TFA for being simple!
	-- + Scifi weapons
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.GetIronSights ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIronSights()
		end,
		['forceOnBaseClasses'] = {
			'tfa_gun_base'
		}
	})

	-- Modern Warfare 2459720887
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.GetIsAiming ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIsAiming()
		end
	})

	-- ArcCW
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.Sighted ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Sighted
		end,
		['forceOnBaseClasses'] = {
			'arccw_base'
		}
	})

	-- DayOfDefeat weapons
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.Weapon ~= nil and
				wep.Weapon:GetNetworkedBool("Ironsights", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Weapon:GetNetworkedBool("Ironsights", false)
		end
	})

	-- FA:S
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.dt ~= nil and wep.dt.Status ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.dt.Status == FAS_STAT_ADS
		end,
		['forceOnBaseClasses'] = {
			'fas2_base',
		}
	})

	-- CW 2.0
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.dt ~= nil and wep.dt.State ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.dt.State == CW_AIMING
		end,
		['forceOnBaseClasses'] = {
			'cw_base',
		}
	})

	-- M9K Legacy
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.GetIronSights ~= nil and
				wep.IronSightsPos ~= nil and
				wep.RunSightsPos ~= nil and
				not MMM_M9k_IsBaseInstalled
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIronSights() and
				wep.IronSightsPos ~= wep.RunSightsPos
		end,
		['forceOnBaseClasses'] = {
			'bobs_gun_base',
			'bobs_scoped_base',
			'bobs_shotty_base'
		}
	})

	-- M9K Remastered -- scoped
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep:GetNWInt("ScopeState", nil) ~= nil and
				MMM_M9k_IsBaseInstalled
		end,
		['fnShouldHide'] = function(wep)
			return wep.IronSightState or
				wep:GetNWInt("ScopeState") > 0
		end,
		['forceOnBaseClasses'] = {
			'bobs_scoped_base',
		}
	})

	-- M9K Remastered -- un scoped
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['fnIsValid'] = function(wep)
			return wep.IronSightState ~= nil and
				MMM_M9k_IsBaseInstalled
		end,
		['fnShouldHide'] = function(wep)
			return wep.IronSightState ~= nil and
				wep.IronSightState
		end,
		['forceOnBaseClasses'] = {
			'bobs_gun_base',
			'bobs_shotty_base'
		}
	})

	-- Disable Target Cross for Prop Hunt and Guess Who to stop cheating
	local gm = engine.ActiveGamemode()
	if gm == "prop_hunt" then
		CrosshairDesigner.DisableFeature("ColOnTarget", false, "Giving away positions in Prop Hunt!")
	elseif gm == "guesswho" then
		CrosshairDesigner.DisableFeature("ColOnTarget", false, "Giving away positions in Guess Who!")
	end

	-- Directory where everything is saved
	if not file.IsDir( "crosshair_designer", "DATA" ) then
		file.CreateDir( "crosshair_designer", "DATA" )
	end
end

print("Finished loading crosshair designer (590788321)")
hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)