CrosshairDesigner = CrosshairDesigner or {}
CrosshairDesigner.VERSION = 3.33
CrosshairDesigner.WSID = 590788321

print("Loading crosshair designer (590788321)")

if SERVER then
	AddCSLuaFile("detours.lua")
	AddCSLuaFile("db.lua")
	AddCSLuaFile("hide.lua")
	AddCSLuaFile("calculate.lua")
	AddCSLuaFile("draw.lua")
	AddCSLuaFile("menu.lua")
	AddCSLuaFile("disable.lua")
	AddCSLuaFile("debug.lua")

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
	include("debug.lua")

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
			isBool=true,
			menuGroup="cross"
		},
		{
			id="ShowCross",
			var="toggle_crosshair",
			default="1",
			help="Hide the custom crosshair",
			title="Show custom crosshair",
			isBool=true,
			menuGroup="cross"
		},
		{
			id="HideOnADS",
			var="cross_ads",
			default="1",
			help="Hide the custom crosshair when aiming down sights",
			title="Hide when aiming down sights",
			isBool=true,
			menuGroup="hide"
		},
		{
			id="UseLine",
			var="cross_line",
			default="1",
			help="Draw crosshair lines",
			title="Show crosshair lines",
			isBool=true,
			menuGroup="cross"
		},
		{
			id="LineStyle",
			var="cross_arrow",
			default="0",
			help="Change the lines on the crosshair to be pointed:\n0 = Rectangle\n1 = Inwards\n2 = Outwards",
			title="Line style",
			min=0,
			max=2,
			menuGroup="cross"
		},
		{
			id="UseCircle",
			var="cross_circle",
			default="0",
			help="Add a circle to the middle of the crosshair",
			title="Add circle crosshair",
			isBool=true,
			menuGroup="cross" -- Only in this group because it makes sense in the menu
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
			menuGroup="cross"
		},
		{
			id="Length",
			var="cross_length",
			default="7",
			help="Change the length of the lines in the crosshair",
			title="Length of lines",
			min=2,
			max=100,
			menuGroup="cross"
		},
		{
			id="Thickness",
			var="cross_thickness",
			default="3",
			help="Change the thickness of the lines in the crosshair",
			title="Thickness of lines",
			min=1,
			max=100,
			menuGroup="cross"
		},
		{
			id="Stretch",
			var="cross_stretch",
			default="0",
			help="The amount to stretch the crosshair by (disabled when using fill draw)",
			title="Stretch of lines",
			min=-180,
			max=180,
			menuGroup="cross"
		},
		{
			id="CircleRadius",
			var="cross_radius",
			default="0",
			help="The radius for the circle if enabled with cross_circle",
			title="Circle radius",
			min=0,
			max=100,
			menuGroup="circle"
		},
		{
			id="CircleSegments",
			var="cross_segments",
			default="0",
			help="The number of segments for the circle if enabled with cross_circle",
			title="Circle segments",
			min=0,
			max=100,
			menuGroup="circle"
		},


		{
			id="ColOnTarget",
			var="hc_target_colour",
			default="1",
			help="Change the colour of the crosshair when aiming at a target",
			title="Change colour on target",
			isBool=true,
			menuGroup="cross-circle"
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
			isBool=true,
			menuGroup="cross"
		},
		{
			id="DynamicSize",
			var="hc_dynamic_amount",
			default="50",
			help="The amount the dynamic crosshair will move when enabled with hc_dynamic_cross",
			title="Dynamic effect size",
			min=0,
			max=100,
			menuGroup="cross"
		},
		{
			id="HideInVeh",
			var="hc_vehicle_cross",
			default="1",
			help="Hide the crosshair when in a vehicle",
			title="Hide in vehicle",
			isBool=true,
			menuGroup="hide"
		},

		-- NEW
		{
			id="HideInSpectate",
			var="crosshairdesigner_hideinspectate",
			default="1",
			help="Hide the crosshair when spectating",
			title="Hide when spectating",
			isBool=true,
			menuGroup="hide"
		},
		{
			id="HideTTT",
			var="crosshairdesigner_hidettt",
			default="1",
			help="Hide the TTT crosshair",
			title="Hide TTT crosshair",
			isBool=true,
			menuGroup="hide"
		},
		{
			id="HideFAS",
			var="crosshairdesigner_hidefas",
			default="1",
			help="Hide the FA:S crosshair",
			title="Hide FA:S crosshair",
			isBool=true,
			menuGroup="hide"
		},
		{
			id="HideCW",
			var="crosshairdesigner_hidecw",
			default="1",
			help="Hide the CW 2.0 crosshair",
			title="Hide CW crosshair",
			isBool=true,
			menuGroup="hide"
		},
		{
			id="TraceDraw",
			var="crosshairdesigner_tracedraw",
			default="0",
			help="Draw based on player angles",
			title="Centre to player angles",
			isBool=true,
			menuGroup="cross-circle"
		},

		-- Outline
		{
			id="Outline",
			var="crosshair_designer_outline",
			default="0",
			help="Outlines the crosshair",
			title="Outline thickness",
			min=0,
			max=100,
			menuGroup="cross"
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
			menuGroup="cross"
		},

		-- Draw with polys instead of lines
		{
			id="FillDraw",
			var="crosshairdesigner_filldraw",
			default="0",
			help="Draw a single shape instead of multiple lines",
			title="Fill draw",
			isBool=true,
			menuGroup="cross"
		},
		{
			id="Segments",
			var="crosshairdesigner_segments",
			default="4",
			help="Change the number of segemnts which make up the crosshair",
			title="Segments",
			min=1,
			max=100,
			menuGroup="cross"
		},
		{
			id="HideInCameraView",
			var="crosshairdesigner_hideincameraview",
			default="0",
			help="Hides the crosshair when looking through a camera",
			title="Hide in camera view",
			isBool=true,
			menuGroup="hide"
		},
		{
			id="InvertCol",
			var="crosshairdesigner_invertcol",
			default="0",
			help="Inverts the colour of the crosshair",
			title="Invert crosshair colour",
			isBool=true,
			menuGroup="cross-circle"
		},
		{
			id="InvertOutlineCol",
			var="crosshairdesigner_invertoutlinecol",
			default="0",
			help="Inverts the colour of the outline",
			title="Invert outline colour",
			isBool=true,
			menuGroup="cross-circle"
		},
		{
			id="HighContrastInvertedCol",
			var="crosshairdesigner_highconstrastinvertedcol",
			default="0",
			help="Forces the inverted colour to be either black or white",
			title="High contrast inverted colour",
			isBool=true,
			menuGroup="cross-circle"
		},
		{
			id="CrossXOffset",
			var="crosshairdesigner_crossxoffset",
			default="0",
			help="Offset the crosshair on the horizontal axis",
			title="Cross X Offset",
			min=-25,
			max=25,
			menuGroup="cross"
		},
		{
			id="CrossYOffset",
			var="crosshairdesigner_crossyoffset",
			default="0",
			help="Offset the crosshair on the vertical axis",
			title="Cross Y Offset",
			min=-25,
			max=25,
			menuGroup="cross"
		},
		{
			id="CircleXOffset",
			var="crosshairdesigner_circlexoffset",
			default="0",
			help="Offset the circle on the horizontal axis",
			title="Circle X Offset",
			min=-25,
			max=25,
			menuGroup="circle"
		},
		{
			id="CircleYOffset",
			var="crosshairdesigner_circleyoffset",
			default="0",
			help="Offset the circle on the vertical axis",
			title="Circle Y Offset",
			min=-25,
			max=25,
			menuGroup="circle"
		},
		{
			id="CircleRotation",
			var="crosshairdesigner_circlerotation",
			default="0",
			help="How much to rotate the circle by",
			title="Circle Rotation",
			min=0,
			max=360,
			menuGroup="circle"
		},
		{
			id="CircleOutlineThickness",
			var="crosshairdesigner_circleoutline",
			default="0",
			help="Outlines the circle crosshair",
			title="Circle Outline Thickness",
			min=0,
			max=100,
			menuGroup="circle"
		},
	})

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
		['id'] = 'GetIronSights',
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

	-- DarkRP special case for ls_sniper
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'ls_sniper',
		['fnIsValid'] = function(wep)
			return wep.GetIronsights ~= nil and wep:GetClass() == "ls_sniper"
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIronsights() and wep:GetScopeLevel() > 1
		end,
		['forceOnBaseClasses'] = {
			'weapon_cs_base2'
		}
	})

	-- DarkRP uses lower case sights
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetIron[s]ights',
		['fnIsValid'] = function(wep)
			return wep.GetIronsights ~= nil and wep:GetClass() ~= "ls_sniper"
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIronsights()
		end,
		['forceOnBaseClasses'] = {
			'weapon_cs_base2'
		}
	})

	-- If DarkRP has lower case sights, maybe some other addon has
	-- something similar with iron, or the whole thing
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Get[i]ron[s]ights',
		['fnIsValid'] = function(wep)
			return wep.Getironsights ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:Getironsights()
		end,
	})
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = '[g]et[i]ron[s]ights',
		['fnIsValid'] = function(wep)
			return wep.getironsights ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:getironsights()
		end,
	})

	-- Modern Warfare 2459720887
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetIsAiming',
		['fnIsValid'] = function(wep)
			return wep.GetIsAiming ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIsAiming()
		end
	})

	-- ArcCW
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'ArcCW',
		['fnIsValid'] = function(wep)
			return wep.Sighted ~= nil and ArcCW ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Sighted or wep:GetState() == ArcCW.STATE_SIGHTS
		end,
		['forceOnBaseClasses'] = {
			'arccw_base'
		}
	})

	-- DayOfDefeat weapons
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetNetworkedBool Iron[s]ights',
		['fnIsValid'] = function(wep)
			return wep.Weapon ~= nil and
				wep.Weapon:GetNetworkedBool("Ironsights", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Weapon:GetNetworkedBool("Ironsights", false)
		end
	})

	-- Potentially another with IronSights
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetNetworkedBool IronSights',
		['fnIsValid'] = function(wep)
			return wep.Weapon ~= nil and
				wep.Weapon:GetNetworkedBool("IronSights", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Weapon:GetNetworkedBool("IronSights", false)
		end
	})

	-- FA:S
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'FA:S',
		['fnIsValid'] = function(wep)
			return wep.dt ~= nil and wep.dt.Status ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.dt.Status == FAS_STAT_ADS
		end,
		['forceOnBaseClasses'] = {
			'fas2_base',
		},
		['onSwitch'] = function(wep)
			-- Hide FA:S 2 crosshair by setting alpha to 0
			if not wep.CrosshairDesignerDetoured then
				local original = wep.DrawHUD

				wep.CrosshairDesignerDetoured = true
				wep.DrawHUD = function(...)
					if CrosshairDesigner.GetBool('HideFAS') then
						wep.CrossAlpha = 0
						-- Temp set firemode to safe to force cross alpha to 0
						-- Also temp hide grenade crosshair
						local originalVehicle = wep.Vehicle
						wep.Vehicle = true

						-- Call original draw hud
						local drawHUDResult = original(...)

						-- Revert back overrides
						wep.Vehicle = originalVehicle

						return drawHUDResult
					else
						return original(...)
					end
				end
			end
		end
	})

	-- CW 2.0
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'CW 2.0',
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
		['id'] = 'M9K Legacy',
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
		['id'] = 'M9K Remastered scoped',
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
		['id'] = 'M9K Remastered un scoped',
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
	if not file.IsDir( "crosshair_designer/debug", "DATA" ) then
		file.CreateDir( "crosshair_designer/debug", "DATA" )
	end
end

print("Finished loading crosshair designer (590788321)")
hook.Run("CrosshairDesigner_FullyLoaded", CrosshairDesigner)