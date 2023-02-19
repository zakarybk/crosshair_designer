CrosshairDesigner = CrosshairDesigner or {}
CrosshairDesigner.VERSION = 3.36
CrosshairDesigner.WSID = 590788321
CrosshairDesigner.FinishLoad = nil -- support auto reload
CrosshairDesigner.StartLoad = SysTime()
CrosshairDesigner.hasPrefix = function(str, prefix)
	return string.sub(str, 1, #prefix) == prefix
end
local hasPrefix = CrosshairDesigner.hasPrefix

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

	local function conVarOrZero(conVar)
		var = GetConVar(conVar)
		if var ~= nil then return var:GetInt() end
		return 0
	end

	local function HideWeaponCrosshairHUD(fn_name, fn_forceshow)
		fn_forceshow = fn_forceshow or function(wep) return false end
		return function(wep)
			-- sometimes a weapon will re-create the draw function (at least Modern Warefare weapons does)
			local original = wep[fn_name]
			if wep.CrosshairDesignerDetour == nil or wep.CrosshairDesignerDetour ~= wep[fn_name] then
				wep[fn_name] = function(...)
					if not CrosshairDesigner.GetBool('HideWeaponCrosshair') or fn_forceshow(wep) then
						return original(...)
					end
				end
				wep.CrosshairDesignerDetour = wep[fn_name]
				wep.CrosshairDesignerDetoured = true
			end
		end
	end

	--[[
		Setup the client convars and callbacks to verify values
	]]--
	CrosshairDesigner.SetUpConvars({ -- Must be in this order as it's the order the values are read from file
		{
			id="ShowHL2",
			var="toggle_crosshair_hide",
			default="0",
			help="Show the half life crosshair",
			title="Show HL2/default crosshair",
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
		--
		-- Do not show these two anymore in the menu -- replace with HideWeaponCrosshair
		--
		{
			id="HideFAS", -- unused
			var="crosshairdesigner_hidefas",
			default="1",
			help="Hide the FA:S crosshair",
			title="Hide FA:S crosshair",
			isBool=true,
			menuGroup="hide"
		},
		-- { -- hide one of these to keep the same number of args for numbered saves
		-- 	id="HideCW", -- unused
		-- 	var="crosshairdesigner_hidecw",
		-- 	default="1",
		-- 	help="Hide the CW 2.0 crosshair",
		-- 	title="Hide CW crosshair",
		-- 	isBool=true,
		-- 	menuGroup="hide"
		-- },
		--
		-- /end
		--
		{
			id="HideWeaponCrosshair", -- replacement
			var="crosshairdesigner_hideweaponcross",
			-- default always 1 due to being set in crosshairdesigner_hidefas
			default=math.min(math.max(conVarOrZero("crosshairdesigner_hidecw"), conVarOrZero("crosshairdesigner_hidefas")), 1),
			help="Hide weapon crosshair",
			title="Hide FA:S, CW, MW, PWB2 crosshairs",
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
		['fnIsValid'] = function(wep, cls)
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
		['fnIsValid'] = function(wep, cls)
			return wep.GetIronsights ~= nil and cls == "ls_sniper"
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
		['fnIsValid'] = function(wep, cls)
			return wep.GetIronsights ~= nil and cls ~= "ls_sniper"
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIronsights()
		end,
	})

	-- If DarkRP has lower case sights, maybe some other addon has
	-- something similar with iron, or the whole thing
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Get[i]ron[s]ights',
		['fnIsValid'] = function(wep, cls)
			return wep.Getironsights ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:Getironsights()
		end,
	})
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = '[g]et[i]ron[s]ights',
		['fnIsValid'] = function(wep, cls)
			return wep.getironsights ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:getironsights()
		end,
	})
	-- found variant in Crysis 2 weapons (1257784914)
	-- though getIronsights doesn't actually work for that addon
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = '[g]etIron[s]ights',
		['fnIsValid'] = function(wep, cls)
			return wep.getIronsights ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:getIronsights()
		end,
	})
	-- Varient found in Sanctum 2 Weapons 391683214
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetIronSight',
		['fnIsValid'] = function(wep, cls)
			return wep.GetIronSight ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIronSight()
		end,
		['forceOnWSID'] = {391683214}
	})
	-- Varient found in Titanfall Heavy Weapons 840091742
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Iron',
		['fnIsValid'] = function(wep, cls)
			return wep:GetNWInt("Iron", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWInt("Iron", nil) == 1
		end,
		['forceOnWSID'] = {840091742}
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Modern Warfare 2459720887',
		['fnIsValid'] = function(wep, cls)
			return wep.GetIsAiming ~= nil and hasPrefix(cls, "mg_")
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetIsAiming()
		end,
		['forceOnBaseClasses'] = { -- Triggers a bunch of others otherwise
			'mg_base'
		},
		['onSwitch'] = function(wep)
			local fn_name = 'DrawCrosshairSticks'
			if wep.CrosshairDesignerDetour == nil or wep.CrosshairDesignerDetour ~= wep[fn_name] then
				fn_hide = HideWeaponCrosshairHUD(fn_name)

				-- Modern Warefare reloads a bunch of stuff when an attachment
				-- is added, so we need to re-apply the patch each time, including
				-- the trigger for the patch (SWEP:Attach)
				local applyAttachPatch = function(reapply_fn)
					local originalAttach = wep.Attach
					wep.Attach = function(...)
						local val = originalAttach(...)
						fn_hide(wep)
						reapply_fn(reapply_fn)
						return val
					end
				end
				applyAttachPatch(applyAttachPatch)
				fn_hide(wep)

				wep.CrosshairDesignerDetoured = true
			end
		end
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'ArcCW',
		['fnIsValid'] = function(wep, cls)
			return wep.Sighted ~= nil and ArcCW ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Sighted or wep:GetState() == ArcCW.STATE_SIGHTS
		end,
		['forceOnBaseClasses'] = {
			'arccw_base'
		}
		-- detour manually handles in hide.lua
	})

	-- DayOfDefeat weapons
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetNetworkedBool Iron[s]ights',
		['fnIsValid'] = function(wep, cls)
			return wep.Weapon ~= nil and
				wep.Weapon:GetNetworkedBool("Ironsights", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Weapon:GetNetworkedBool("Ironsights", false)
		end
	})

	-- Alternative IronSights GetNWBool vs GetNetworkedBool
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'GetNetworkedBool IronSights',
		['fnIsValid'] = function(wep, cls)
			return wep.Weapon ~= nil and
				wep.Weapon:GetNWBool("IronSights", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.Weapon:GetNWBool("IronSights", false)
		end
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'FA:S',
		['fnIsValid'] = function(wep, cls)
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
					if CrosshairDesigner.GetBool('HideWeaponCrosshair') then
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

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'CW 2.0',
		['fnIsValid'] = function(wep, cls)
			return wep.dt ~= nil and wep.dt.State ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.dt.State == CW_AIMING
		end,
		['forceOnBaseClasses'] = {
			'cw_base',
		}
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'M9K Legacy',
		['fnIsValid'] = function(wep, cls)
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

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'M9K Remastered scoped',
		['fnIsValid'] = function(wep, cls)
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

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'M9K Remastered un scoped',
		['fnIsValid'] = function(wep, cls)
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

	-- Crysis 2 weapons (1257784914)
	-- Hackery as getIronSights doesn't work as expected
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'base_autorif',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "tsp_")
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetDTBool(1)
		end,
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'ARC9 Weapon Base 2910505837',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "arc9_")
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetInSights() and
			not wep:GetSight().CrosshairInSights -- akimbo support
		end,
		['forceOnBaseClasses'] = { -- Triggers GetIron[S|s]igns in addition otherwise
			'arc9_base',
			'arc9_base_nade',
			'arc9_go_base'
		}
	})

	-- GetIronSights checks are added, but never trigger
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'PWB 2 1470662323',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_pwb2") and wep:GetNWBool("Iron", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWBool("Iron", false)
		end,
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD'),
		['forceOnWSID'] = {916201112, 921842698, 922433152, 913618147, 917779957, 
		914808995, 918900571, 923515273, 1498694632, 1492190276, 1470662323, 
		1469422668, 1468151297}, 
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Unreal Tournament SWEPs 189453748',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_ut99")
		end,
		['fnShouldHide'] = function(wep)
			return false
		end,
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD'),
		['forceOnBaseClasses'] = {'weapon_ut99_base'},
		['forceOnWSID'] = {189453748}
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'DOOM 2016/Eternal Weapons 2296325632',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_dredux")
		end,
		['fnShouldHide'] = function(wep)
			return false -- no ADS in addon
		end,
		['onSwitch'] = HideWeaponCrosshairHUD('DrawCrosshairElementRotated'),
		['forceOnBaseClasses'] = {'weapon_dredux_base2', 'weapon_dredux_base3'},
		['forceOnWSID'] = {2296325632}
	})

	-- GetIronSights checks are added, but never trigger
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Dr>Breens Private Reserve Weaponry 2506186936',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "azbr_pr") and wep.GetIsZoomedIn ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.GetIsZoomedIn and wep:GetIsZoomedIn()
		end,
		['forceOnWSID'] = {2506186936}
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Classic CS:S weapons for GMod 13 124725938',
		['fnIsValid'] = function(wep, cls)
			return wep.Base ~= nil and wep.Base == "weapon_cs_base"
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWBool("IronSights", false) -- duplciates others
		end,
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD'),
		['forceOnBaseClasses'] = {'weapon_cs_base'},
		['forceOnWSID'] = {124725938}
	})

	-- Hide their hud only when not scoped / otherwise swap in our crosshair
	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Team Fortress 2 Weapon Pack 949733637',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "tf_weapon")
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWInt("CrosshairAlpha", 255) == 0
		end,
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD', function(wep) 
			return (wep:GetNWInt("ScopeLaserAlpha", 0) == 255 or wep:GetNWInt("ScopeAlpha", 0) == 255) -- Allow HUD for scoped weapons
		end),
		['forceOnWSID'] = {949733637}
	})

	-- CrosshairDesigner.AddSWEPCrosshairCheck({
	-- 	['id'] = 'Counter-Strike: Global Offensive Sniper Rifle Pack 1244760503, 2180833718, 1257243225',
	-- 	['fnIsValid'] = function(wep, cls)
	-- 		return hasPrefix(cls, "weapon_csgo")
	-- 	end,
	-- 	['fnShouldHide'] = function(wep)
	-- 		return wep:GetNWInt("ScopeAlpha", 0) == 255
	-- 	end,
	-- 	['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD', function(wep)
	-- 		return (wep:GetNWInt("ScopeAlpha", 0) == 255) -- Allow HUD for scoped weapons
	-- 	end)
	-- })

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'CS:GO Weapons 2180833718',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_csgo")
		end,
		['fnShouldHide'] = function(wep)
			return (
				(wep.GetZoomLevel and wep:GetZoomLevel() ~= 1)
				or
				(wep.GetIronsights and wep:GetIronsights()) -- specific to weapon_csgo_rif_sg553
			)
		end,
		['forceOnWSID'] = {2180833718},
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Counter-Strike: Global Offensive Operation Breakout Weapon Pack 1257243225',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_csgo_breakout")
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWInt("ScopeAlpha", 0) == 255 or wep:GetNWInt("ScopeAlpha", 0) == 1
		end,
		['forceOnWSID'] = {1257243225},
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD', function(wep)
			return wep:GetNWInt("ScopeAlpha", 0) == 255
		end)
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Counter-Strike: Global Offensive Assault Rifle Pack 1239501421',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_csgo")
		end,
		['fnShouldHide'] = function(wep)
			return tonumber(wep:GetNWInt("ScopeAlpha", 0)) == 1
		end,
		['forceOnWSID'] = {1239501421},
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD', function(wep)
			return tonumber(wep:GetNWInt("ScopeAlpha", 0)) == 1
		end)
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Counter-Strike: Global Offensive Sniper Rifle Pack 1244760503',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_csgo")
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWInt("ScopeAlpha", 0) == 255
		end,
		['forceOnWSID'] = {1244760503},
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'DOOM 3 SWEPs 210267782',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_doom3")
		end,
		['fnShouldHide'] = function(wep)
			return wep.GetIronSights and wep:GetIronSights()
		end,
		['forceOnWSID'] = {210267782},
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD'),
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'DOOM 3 SWEPs 1218893879',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_l4d")
		end,
		['fnShouldHide'] = function(wep)
			return wep.GetIronSights and wep:GetIronSights() -- actually no ADS in this pack
		end,
		['forceOnWSID'] = {1218893879},
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD'),
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Quake 4 SWEPs 1341861055',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_quake4")
		end,
		['fnShouldHide'] = function(wep)
			return false --wep:GetNWInt("Ironsights", 0) == 1 -- needs crosshair always visible
		end,
		['forceOnWSID'] = {1341861055},
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD'),
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'ACT3: Arctic\'s Customizable Thirdperson (Weapons) 3.0 1631362949',
		['fnIsValid'] = function(wep, cls)
			return wep.ACT3Weapon ~= nil and wep.State != nil and ACT3_STATE_INSIGHTS != nil
		end,
		['fnShouldHide'] = function(wep)
			return wep.State == ACT3_STATE_INSIGHTS
		end,
		['forceOnWSID'] = {1631362949},
		-- detour manually handles in hide.lua
	})

	CrosshairDesigner.AddSWEPCrosshairCheck({
		['id'] = 'Call of Duty 4: Modern Warfare 1510230490',
		['fnIsValid'] = function(wep, cls)
			return hasPrefix(cls, "weapon_cod4") and wep:GetNWBool("Crosshair", nil) ~= nil
		end,
		['fnShouldHide'] = function(wep)
			return wep:GetNWBool("Crosshair", true) == false
		end,
		['onSwitch'] = HideWeaponCrosshairHUD('DrawHUD', function(wep)
			return wep:GetNWBool("Scope", false) == true
		end),
		['forceOnWSID'] = {1606353301, 1506867125, 1601712255, 1598900546,
		1537777119, 1510224023},
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
