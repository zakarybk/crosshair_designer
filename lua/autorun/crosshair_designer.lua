--AddCSLuaFile()

if (CLIENT) then

-- to find values lua_run_cl print( GetConVar( "hc_dynamic_amount" ):GetInt() )
--crosshairs
local CrossHide = CreateClientConVar( "toggle_crosshair_hide", 0, true, false ) --
local Cross = CreateClientConVar( "toggle_crosshair", 1, true, false ) --
local Cross_ADS = CreateClientConVar( "cross_ads", 1, true, false ) --
local Cross_Line = CreateClientConVar( "cross_line", 1, true, false ) --
local Target_Colour = CreateClientConVar( "hc_target_colour", 1, true, false )
local Hc_Dynamic_Cross = CreateClientConVar( "hc_dynamic_cross", 1, true, false )
local Hc_Vehicle_Cross = CreateClientConVar( "hc_vehicle_cross", 1, true, false )

--colour
local Red_Cross = CreateClientConVar("cross_hud_color_r", "29", true, false)
local Green_Cross = CreateClientConVar("cross_hud_color_g", "0", true, false)
local Blue_Cross = CreateClientConVar("cross_hud_color_b", "255", true, false)
local Alpha_Cross = CreateClientConVar("cross_hud_color_a", "255", true, false)

local Target_Red_Cross = CreateClientConVar("target_cross_hud_color_r", "255", true, false)
local Target_Green_Cross = CreateClientConVar("target_cross_hud_color_g", "0", true, false)
local Target_Blue_Cross = CreateClientConVar("target_cross_hud_color_b", "0", true, false)
local Target_Alpha_Cross = CreateClientConVar("target_cross_hud_color_a", "255", true, false)
		
--size
local Cross_Gap = CreateClientConVar("cross_gap", "5", true, false)
local Cross_Length = CreateClientConVar("cross_length", "13", true, false)
local Cross_Thickness = CreateClientConVar("cross_thickness", "1", true, false)
local Cross_Arrow = CreateClientConVar("cross_arrow", 0, true, false)
local Cross_Stretch = CreateClientConVar("cross_stretch", "0", true, false)

local Cross_Circle = CreateClientConVar("cross_circle", 1, true, false)
local Cross_Radius = CreateClientConVar("cross_radius", "0", true, false)
local Cross_Segments = CreateClientConVar("cross_segments", "0", true, false)

local Hc_Dynamic_Amount = CreateClientConVar("hc_dynamic_amount", "50", true, false)


--[[
	Saving settings
]]--
	local Hc_whichsaveslot = 0
	local Hc_whichtoload = 0

	local Hc_Save1 = CreateClientConVar("Hc_crosssave_1", "Save 1", true, false)
	local Hc_Save2 = CreateClientConVar("Hc_crosssave_2", "Save 2", true, false)
	local Hc_Save3 = CreateClientConVar("Hc_crosssave_3", "Save 3", true, false)
	local Hc_Save4 = CreateClientConVar("Hc_crosssave_4", "Save 4", true, false)
	local Hc_Save5 = CreateClientConVar("Hc_crosssave_5", "Save 5", true, false)
	local Hc_Save6 = CreateClientConVar("Hc_crosssave_6", "Save 6", true, false)
	local Hc_Save7 = CreateClientConVar("Hc_crosssave_7", "Save 7", true, false)
	local Hc_Save8 = CreateClientConVar("Hc_crosssave_8", "Save 8", true, false)
	local Hc_Save9 = CreateClientConVar("Hc_crosssave_9", "Save 9", true, false)
	local Hc_Save10 = CreateClientConVar("Hc_crosssave_10", "Save 10", true, false)
	
	local Hc_Save_Warning = CreateClientConVar("Hc_save_warning", 1, true, false)
	
--[[
	Notes, Hc stands for Hackcraft who put this together. Was going to put it in the convars, but too lazy xD
]]--

--other
local dynamic = 0
local hc_shootingvalue = 0
local hc_con_num = 24
 
local hc_con_order = {}
hc_con_order[1] = "toggle_crosshair_hide"
hc_con_order[2] = "toggle_crosshair"
hc_con_order[3] = "cross_ads"
hc_con_order[4] = "cross_line"
hc_con_order[5] = "cross_arrow"
hc_con_order[6] = "cross_circle"
hc_con_order[7] = "cross_hud_color_r"
hc_con_order[8] = "cross_hud_color_g"
hc_con_order[9] = "cross_hud_color_b"
hc_con_order[10] = "cross_hud_color_a"
hc_con_order[11] = "cross_gap"
hc_con_order[12] = "cross_length"
hc_con_order[13] = "cross_thickness"
hc_con_order[14] = "cross_stretch"
hc_con_order[15] = "cross_radius"
hc_con_order[16] = "cross_segments"
hc_con_order[17] = "hc_target_colour"
hc_con_order[18] = "target_cross_hud_color_r"
hc_con_order[19] = "target_cross_hud_color_g"
hc_con_order[20] = "target_cross_hud_color_b"
hc_con_order[21] = "target_cross_hud_color_a"
hc_con_order[22] = "hc_dynamic_cross"
hc_con_order[23] = "hc_dynamic_amount"
hc_con_order[24] = "hc_vehicle_cross"


--might use this part sometime if I can work out how to make a loop to write a long string using this
local hc_var_order = {}
hc_var_order[1] = CrossHide
hc_var_order[2] = Cross 
hc_var_order[3] = Cross_ADS 
hc_var_order[4] = Cross_Line 
hc_var_order[5] = Cross_Arrow 
hc_var_order[6] = Cross_Circle 
hc_var_order[7] = Red_Cross 
hc_var_order[8] = Green_Cross 
hc_var_order[9] = Blue_Cross 
hc_var_order[10] = Alpha_Cross 
hc_var_order[11] = Cross_Gap 
hc_var_order[12] = Cross_Length 
hc_var_order[13] = Cross_Thickness 
hc_var_order[14] = Cross_Stretch 
hc_var_order[15] = Cross_Radius 
hc_var_order[16] = Cross_Segments 
hc_var_order[17] = Target_Colour  
hc_var_order[18] = Target_Red_Cross 
hc_var_order[19] = Target_Green_Cross  
hc_var_order[20] = Target_Blue_Cross  
hc_var_order[21] = Target_Alpha_Cross 
hc_var_order[22] = Hc_Dynamic_Cross
hc_var_order[23] = Hc_Dynamic_Amount
hc_var_order[24] = Hc_Vehicle_Cross

--end

--if (CLIENT) then

--Excluded weapons for ADS -- Table is global so it can be edited by the client without having to edit the lua script.
Hc_ewfads = {
"weapon_357",
"weapon_ar2",
"weapon_bugbait",
"weapon_crossbow",
"weapon_crowbar",
"weapon_frag",
"weapon_physcannon",
"weapon_pistol",
"weapon_rpg",
"weapon_shotgun",
"weapon_slam",
"weapon_smg1",
"weapon_stunstick",
"weapon_fists",
"weapon_flechettegun",
"manhack_welder",
"weapon_medkit",
"weapon_physgun",
"gmod_tool",

--DarkRP support
"weapon_keypadchecker",
"arrest_stick",
"door_ram",
"keys",
"lockpick",
"med_kit",
"pocket",
"stunstick",
"unarrest_stick",
"weaponchecker",
"keypad_cracker",

--Common addons
"weapon_portalgun",
"climb_swep2",
"dogbite",
"weapon_cbox",
"swep_construction_kit",
"weapon_lightsaber",
"weapon_scarrefuel",
"weapon_scarkeys",
"weapon_scarrepair",
"weapon_hack_phone",
"laserpointer",
"remotecontroller",
"butterfly",
"cooljetpack",
"weapon_techhud_dualpistol",
"weapon_gphone",

--M9K
"m9k_dbarrel",
"m9k_damascus",
"m9k_fists",
"m9k_m61_frag",
"m9k_harpoon",
"m9k_ied_detonator",
"m9k_knife",
"m9k_machete",
"m9k_nerve_gas",
"m9k_nitro",
"m9k_proxy_mine",
"m9k_sticky_grenade",
"m9k_suicide_bomb",

--Doesn't work too well with FA:S because of how it toggles ADS rather than a button hold

}

Hc_nocross_sweps = {

"weapon_lightsaber",
"keys",

}


--[[
	Smooth dynamic crosshair
]]--

	local function hc_dynamiccorsshair()
	
	local ply = LocalPlayer()
	
		if not Hc_Dynamic_Cross:GetBool() then
		timer.Destroy ( "HC_SmoothDynamics" )	-- saving the script breaks the timer, this doesn't fix it :'(
		end
		
		if Hc_Dynamic_Cross:GetBool() then
		timer.Create( "HC_SmoothDynamics", 0.03, 0, function()
		
	--local ply = LocalPlayer()
	local hc_dynamicamount = Hc_Dynamic_Amount:GetInt()
	local speedzzz = ply:GetVelocity():Length()
	
	if ply:Health() > 0 and ply:GetActiveWeapon():IsValid() then
	if ply:GetActiveWeapon():Clip1() > 0 then
	if speedzzz / string.len( speedzzz )  < hc_dynamicamount and speedzzz / string.len( speedzzz ) > 3 then
	dynamic = speedzzz / string.len( speedzzz ) 
	
	elseif speedzzz / string.len( speedzzz ) < 3 and ply:KeyDown( IN_ATTACK ) and hc_shootingvalue < hc_dynamicamount / 3 then
	hc_shootingvalue = hc_shootingvalue + 0.5
	dynamic = hc_shootingvalue
	
	elseif speedzzz / string.len( speedzzz ) < 3 and !ply:KeyDown( IN_ATTACK ) and hc_shootingvalue > 0 then
	hc_shootingvalue = hc_shootingvalue - 0.5
	dynamic = hc_shootingvalue
	
	elseif speedzzz / string.len( speedzzz ) < 4 and !ply:KeyDown( IN_ATTACK ) and hc_shootingvalue < 1 then  ---- IN_ATTACK1 instead
	dynamic = speedzzz / string.len( speedzzz )
					end
					else
					dynamic = 0
				end
			end
		end)
		end
	end
	
cvars.AddChangeCallback( "hc_dynamic_cross", function( convar_name, value_old, value_new )
	hc_dynamiccorsshair()
end )


--[[
	Circle
]]--
	
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

--[[
	Crosshair
]]--
local function Crosshair()
	
	if Cross:GetBool() and LocalPlayer():Health() > 0 and LocalPlayer():GetActiveWeapon():IsValid() then
	
	--um... might change this part sometime...
	
	if LocalPlayer():KeyDown( IN_ATTACK2 ) and !table.HasValue( Hc_ewfads, LocalPlayer():GetActiveWeapon():GetClass() ) and Cross_ADS:GetBool()  then
	surface.SetDrawColor( 0, 0, 0, 0 )
	--else
	
	elseif Hc_Vehicle_Cross:GetBool() and LocalPlayer():InVehicle() then
	surface.SetDrawColor( 0, 0, 0, 0 )
	
	elseif table.HasValue( Hc_nocross_sweps, LocalPlayer():GetActiveWeapon():GetClass() ) then
	surface.SetDrawColor( 0, 0, 0, 0 )
	else
	
		if Target_Colour:GetBool() then 
		
		local Target = LocalPlayer():GetEyeTrace().Entity
	
			if Target:IsNPC()  then -- The only way I could get it to work...
				surface.SetDrawColor( Target_Red_Cross:GetInt(), Target_Green_Cross:GetInt(), Target_Blue_Cross:GetInt(), Target_Alpha_Cross:GetInt() )
			
			elseif Target:IsPlayer()  then
				surface.SetDrawColor( Target_Red_Cross:GetInt(), Target_Green_Cross:GetInt(), Target_Blue_Cross:GetInt(), Target_Alpha_Cross:GetInt() )
			
			else 
				surface.SetDrawColor( Red_Cross:GetInt(), Green_Cross:GetInt(), Blue_Cross:GetInt(), Alpha_Cross:GetInt() )
			end
			
		else
	
		surface.SetDrawColor( Red_Cross:GetInt(), Green_Cross:GetInt(), Blue_Cross:GetInt(), Alpha_Cross:GetInt() )
	
		end

	if Cross_Line:GetBool() then
	--middle
	local x = ScrW() / 2
	local y = ScrH() / 2
 
	--vars	
	local gap = Cross_Gap:GetInt() + dynamic
	local length = gap + Cross_Length:GetInt()
	local stretch = Cross_Stretch:GetInt()
 
	--draw the crosshair

	
	surface.DrawLine( x-stretch - length, y+stretch, x - gap, y ) -- Left
	surface.DrawLine( x+stretch + length, y-stretch, x + gap, y ) -- Right
	surface.DrawLine( x-stretch, y - length-stretch, x, y - gap ) -- Up
	surface.DrawLine( x+stretch, y + length+stretch, x, y + gap ) -- Down
	
	if Cross_Arrow:GetBool() then
	
	--Arrows
	for i=1,Cross_Thickness:GetInt() do 
	surface.DrawLine( x-stretch - length, y+i+stretch, x - gap, y )
	surface.DrawLine( x-stretch - length, y-i+stretch, x - gap, y ) 
	
	surface.DrawLine( x+stretch + length, y+i-stretch, x + gap, y )
	surface.DrawLine( x+stretch + length, y-i-stretch, x + gap, y )
	
	surface.DrawLine( x+i-stretch, y - length-stretch, x, y - gap ) -- UP Right
	-- surface.DrawLine( x+i, y - length, x, y - gap )  -- cool
	surface.DrawLine( x-i-stretch, y - length-stretch, x, y - gap ) -- UP left
	
	surface.DrawLine( x+i+stretch, y + length+stretch, x, y + gap )
	surface.DrawLine( x-i+stretch, y + length+stretch, x, y + gap )
	end 
	
	else
	
	--Thickness
	for i=1,Cross_Thickness:GetInt() do 
	surface.DrawLine( x-stretch - length, y+i+stretch, x - gap, y+i )
	--surface.DrawLine( x - length, y+i, x - gap, y+i )
	surface.DrawLine( x-stretch - length, y-i+stretch, x - gap, y-i ) 
	
	surface.DrawLine( x+stretch + length, y+i-stretch, x + gap, y+i )
	surface.DrawLine( x+stretch + length, y-i-stretch, x + gap, y-i )
	
	surface.DrawLine( x+i-stretch, y - length-stretch, x+i, y - gap ) -- UP Right
	-- surface.DrawLine( x+i, y - length, x, y - gap )  -- cool
	surface.DrawLine( x-i-stretch, y - length-stretch, x-i, y - gap ) -- UP left
	
	surface.DrawLine( x+i+stretch, y + length+stretch, x+i, y + gap )
	surface.DrawLine( x-i+stretch, y + length+stretch, x-i, y + gap )
				 
			end
		end
	end

	
	if Cross_Circle:GetBool() then
	
	--surface.SetDrawColor( 0, 0, 0, 200 )
	draw.NoTexture()
	drawingcircle( ScrW() / 2, ScrH() / 2, Cross_Radius:GetInt(), Cross_Segments:GetInt() ) -- Radius, segments
	
				--end
			end
		end
	end
end
hook.Add("HUDPaint","CustomCross",Crosshair)

		
--[[
	Hide HL2 crosshair
]]--

local hide = {
	CHudCrosshair = true,
}

hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if not CrossHide:GetBool() then
	if ( hide[ name ] ) then return false end
	end

	-- Don't return anything here, it may break other addons that rely on this hook.
end )


--[[
	Crosshair load the saves
]]--

local function crossloadingsaves()

local crosshairloading = "crosshair_designer/save_" .. Hc_whichtoload .. ".txt"
if file.Exists( crosshairloading, "DATA" ) then
	local brokencrossstring = string.Explode( " ", file.Read( crosshairloading, "DATA" ) )
	--local crosshairdata = file.Read( crosshairloading, "DATA" )

local hc_timer_i = 1
local hc_printerror = 1

	timer.Create( "hc_load_cross", 0.1, hc_con_num, function()

--Stops console errors from outdated saves!
		if brokencrossstring[hc_timer_i] == nil or brokencrossstring[hc_timer_i] == '' then
		
			hc_timer_i = hc_timer_i + 1 
			if Hc_Save_Warning:GetBool() then
				if hc_printerror == 1 then -- stops chat spam
				hc_printerror = 0
				chat.AddText( "'" .. GetConVar( "Hc_crosssave_" .. Hc_whichtoload ):GetString() .. "' needs to be resaved" )
				surface.PlaySound( "common/warning.wav" )
				end
			end

		else
		
		RunConsoleCommand( hc_con_order[hc_timer_i], ( brokencrossstring[hc_timer_i] ) )
		hc_timer_i = hc_timer_i + 1  
			
		end
	end) 
	
else
file.Write( crosshairloading, "0 1 1 1 0 1 29 0 255 255 5 13 1 0 8 0 1 255 0 0 255 1 50 1" ) -- default config
crossloadingsaves()

end

-- Took way longer that it should have xD

end


--[[
	Save Prompt
]]--
local function crosshairs_save_prompt()

local Frame = vgui.Create( "DFrame" )
Frame:SetPos( ScrW() / 2 - 150, ScrH() / 2 - 75 )
Frame:SetSize( 300, 130 )
Frame:SetTitle( "Confirm" )
Frame:SetVisible( true )
Frame:SetBackgroundBlur( true )
Frame:SetDraggable( false )
Frame:ShowCloseButton( true )
Frame:MakePopup()

function Frame:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 93, 0 ) )
	draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 36, 36, 36 ) )
end

local DLabel = vgui.Create( "DLabel", Frame )
DLabel:SetPos( 20, 30 )
DLabel:SetText( "Are you sure you want to override" )
DLabel:SizeToContents() 

local DLabel = vgui.Create( "DLabel", Frame )
DLabel:SetPos( 20 , 50 )
DLabel:SetText( GetConVar( "Hc_crosssave_" .. Hc_whichsaveslot ):GetString() .. "?" )
DLabel:SizeToContents() 

local ConfirmColor = vgui.Create( "DButton", Frame )
ConfirmColor:SetText( "Yes" )
ConfirmColor:SetSize( 40, 20 )
ConfirmColor:SetPos( 70, 90 )
ConfirmColor.DoClick = function()

	local CrossHideX = CrossHide:GetBool()
      
	Frame:Close()
	--( Hc_whichsaveslot:GetInt() )
	--probs better ways of doing this....
	local crosshairsaves = "crosshair_designer/save_" .. Hc_whichsaveslot .. ".txt"
	file.Write( crosshairsaves, math.Round(CrossHide:GetInt()) .. " " .. math.Round(Cross:GetInt()) .. " " .. math.Round(Cross_ADS:GetInt()) .. " " .. 
	math.Round(Cross_Line:GetInt()) .. " " .. math.Round(Cross_Arrow:GetInt()) .. " " .. math.Round(Cross_Circle:GetInt()) .. " " .. math.Round(Red_Cross:GetInt()) .. " " ..  
	math.Round(Green_Cross:GetInt()) .. " " .. math.Round(Blue_Cross:GetInt()) .. " " .. math.Round(Alpha_Cross:GetInt()) .. " " .. math.Round(Cross_Gap:GetInt()) .. " " .. 
	math.Round(Cross_Length:GetInt()) .. " " .. math.Round(Cross_Thickness:GetInt()) .. " " .. math.Round(Cross_Stretch:GetInt()) .. " " .. math.Round(Cross_Radius:GetInt()) .. " " .. 
	math.Round(Cross_Segments:GetInt()) .. " " .. math.Round(Target_Colour:GetInt()) .. " " .. math.Round(Target_Red_Cross:GetInt()) .. " " .. math.Round(Target_Green_Cross:GetInt()) .. " " ..
	math.Round(Target_Blue_Cross:GetInt()) .. " " .. math.Round(Target_Alpha_Cross:GetInt()) .. " " .. math.Round(Hc_Dynamic_Cross:GetInt()) .. " " .. 
	math.Round(Hc_Dynamic_Amount:GetInt()) .. " " .. math.Round(Hc_Vehicle_Cross:GetInt()) )
	
end

local ConfirmColor = vgui.Create( "DButton", Frame )
ConfirmColor:SetText( "No" )
ConfirmColor:SetSize( 40, 20 )
ConfirmColor:SetPos( 190, 90 )
ConfirmColor.DoClick = function()
      
	Frame:Close()
end


end

--end


--[[
	Derma Menu
]]--

    local midW, midH = ScrW() / 2, ScrH() / 2
	local function OpenCrosshairDerma()
		local CrosshairDerma = vgui.Create( "DFrame" )
		CrosshairDerma:SetSize( 230, 650 )
		CrosshairDerma:SetPos( ScrW() * 0.01, ScrH() * 0.05 )
		CrosshairDerma:SetTitle( "Hackcraft's crosshair designer V2.2" )
		CrosshairDerma:MakePopup()
		
		 local sheet = vgui.Create( "DPropertySheet", CrosshairDerma )
         sheet:Dock( FILL )
		
		 local panel4 = vgui.Create( "DPanel", sheet )
                panel4.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color(0, 0, 0, 0 ) ) end
                sheet:AddSheet( "Crosshair Settings", panel4 )

				
				local lazy_y = 5
               
                --Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Choose crosshairs to toggle" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
               
                --Hide crosshair
                local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "HL2 crosshair" )
                CheckBoxThing:SetConVar( "toggle_crosshair_hide" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 0 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
               
                --cross 1
                local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Custom crosshair" )
                CheckBoxThing:SetConVar( "toggle_crosshair" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				
				--cross ADS
                local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Hide crosshair when ADS" )
                CheckBoxThing:SetConVar( "cross_ads" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				
				--Line crosshair
                local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Line crosshair " )
                CheckBoxThing:SetConVar( "cross_line" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				--Crosshair Arrow
				local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Arrow crosshair" )
                CheckBoxThing:SetConVar( "cross_arrow" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				--Crosshair Circle
				local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Circle crosshair" )
                CheckBoxThing:SetConVar( "cross_circle" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				--Crosshair colour change on target
				local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Change colour on target" )
                CheckBoxThing:SetConVar( "hc_target_colour" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				
				--Dynamic crosshair
				local CheckBoxThing7 = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing7:SetPos( 5,lazy_y )
                CheckBoxThing7:SetText( "Dynamic crosshair" )
                CheckBoxThing7:SetConVar( "hc_dynamic_cross" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing7:SizeToContents() -- Make its size to the contents. Duh?
				--CheckBoxThing7.DoClick() = function()
				--RunConsoleCommand( "hc_toggle_dynamic" )
				--end
				
				local lazy_y = lazy_y + 20
				
				--Crosshair in vehicle
				local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel4 )
                CheckBoxThing:SetPos( 5,lazy_y )
                CheckBoxThing:SetText( "Hide crosshair in vehicle" )
                CheckBoxThing:SetConVar( "hc_vehicle_cross" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				local lazy_y = lazy_y + 20
				
				--[[
					Other half
				]]--
				
                --Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Crosshair gap" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
				         
                --cross gap
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Gap" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 50 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "cross_gap" )
				ESlider:SetValue( Cross_Gap:GetInt() )
				
				local lazy_y = lazy_y + 20
               
                --Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Crosshair length" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
               
                --cross length
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Length" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 50 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "cross_length" )
				ESlider:SetValue( Cross_Length:GetInt() )
				
				local lazy_y = lazy_y + 20
				
				--Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Custom crosshair thickness" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
               
                --cross thickness
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Thickness" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 50 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "cross_thickness" )
				ESlider:SetValue( Cross_Thickness:GetInt() )
				
				local lazy_y = lazy_y + 20
				
				--Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Crosshair stretch" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
               
                --cross stretch
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Stretch" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 360 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "cross_stretch" )
				ESlider:SetValue( Cross_Stretch:GetInt() )
				
				local lazy_y = lazy_y + 20
				
				--Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Circle crosshair radius" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
               
                --cross circle radius
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Radius" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 50 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "cross_radius" )
				ESlider:SetValue( Cross_Radius:GetInt() )
				
				local lazy_y = lazy_y + 20
				
				--Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Circle crosshair segments" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
               
                --cross circle segments
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Segments" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 50 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "cross_segments" )
				ESlider:SetValue( Cross_Segments:GetInt() )
				
               local lazy_y = lazy_y + 20
			   
			   	--Text
                local DLabel = vgui.Create( "DLabel", panel4 )
                DLabel:SetPos( 5, lazy_y ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Dynamic size" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				local lazy_y = lazy_y + 20
			   
			    --cross dynamic size
                local ESlider = vgui.Create( "Slider", panel4 )
                ESlider:SetText( "Dynamic size" )
                ESlider:SetPos( 0, lazy_y )
                ESlider:SetSize( 230, 20 )
                ESlider:SetMin( 0 )
                ESlider:SetMax( 50 )
                ESlider:SetDecimals( 0 )
                ESlider:SetConVar( "hc_dynamic_amount" )
				ESlider:SetValue( Hc_Dynamic_Amount:GetInt() )
				
               local lazy_y = lazy_y + 20
			   
			   
			   --[[
					Colour settings (yes I don't know which order numbers go in...)
			   ]]--
			   
			   	local panel6 = vgui.Create( "DPanel", sheet )
                panel6.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color(0, 0, 0, 0 ) ) end
                sheet:AddSheet( "Colour", panel6 )
				
				local ChosenColor = nil
				
				--Text
                local DLabel = vgui.Create( "DLabel", panel6 )
                DLabel:SetPos( 5, 0 ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Crosshair colour picker" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
 
                local ColorPicker = vgui.Create( "DColorMixer", panel6 )
                ColorPicker:SetSize( 193, 200 )
                ColorPicker:SetPos( 5, 20 )
                --ColorPicker:SetPos( 10, 10 )
                ColorPicker:SetPalette( true )
                ColorPicker:SetAlphaBar( true )
                ColorPicker:SetWangs( true )
                ColorPicker:SetColor( Color( Red_Cross:GetInt(), Green_Cross:GetInt(), Blue_Cross:GetInt(), Alpha_Cross:GetInt() ) )
				
				 
                local ConfirmColor = vgui.Create( "DButton", panel6 )
                ConfirmColor:SetText( "Crosshair colour" )
                ConfirmColor:SetSize( 96.5, 30 )
                ConfirmColor:SetPos( 54, 230 )
                --ConfirmColor:SetSize( 90, 30 )
                --ConfirmColor:SetPos( 60, 220 )
                ConfirmColor.DoClick = function()
                local ChosenColor = ColorPicker:GetColor()
                RunConsoleCommand("cross_hud_color_r", (ChosenColor.r) )
                RunConsoleCommand("cross_hud_color_g", (ChosenColor.g) )
                RunConsoleCommand("cross_hud_color_b", (ChosenColor.b) )
                RunConsoleCommand("cross_hud_color_a", (ChosenColor.a) )
               
        end
				
				local ColorPicker = vgui.Create( "DColorMixer", panel6 )
                ColorPicker:SetSize( 193, 200 )
                ColorPicker:SetPos( 5, 270 )
                --ColorPicker:SetPos( 10, 10 )
                ColorPicker:SetPalette( true )
                ColorPicker:SetAlphaBar( true )
                ColorPicker:SetWangs( true )
                ColorPicker:SetColor( Color( Target_Red_Cross:GetInt(), Target_Green_Cross:GetInt(), Target_Blue_Cross:GetInt(), Target_Alpha_Cross:GetInt() ) )
				
		
		        local ConfirmColor = vgui.Create( "DButton", panel6 )
                ConfirmColor:SetText( "On target colour" )
                ConfirmColor:SetSize( 96.5, 30 )
                ConfirmColor:SetPos( 54, 480 )
                --ConfirmColor:SetSize( 90, 30 )
                --ConfirmColor:SetPos( 60, 220 )
                ConfirmColor.DoClick = function()
                local ChosenColor = ColorPicker:GetColor()
                RunConsoleCommand("target_cross_hud_color_r", (ChosenColor.r) )
                RunConsoleCommand("target_cross_hud_color_g", (ChosenColor.g) )
                RunConsoleCommand("target_cross_hud_color_b", (ChosenColor.b) )
                RunConsoleCommand("target_cross_hud_color_a", (ChosenColor.a) )
               
        end
               
				
				--[[
					Magic saving derma part :D
				]]--
			
				local panel5 = vgui.Create( "DPanel", sheet )
                panel5.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color(0, 0, 0, 0 ) ) end
                sheet:AddSheet( "Saving", panel5 )
				
				--Outdated save warning
				local CheckBoxThing = vgui.Create( "DCheckBoxLabel", panel5 )
                CheckBoxThing:SetPos( 0, 5 )
                CheckBoxThing:SetText( "Outdated save warning" )
                CheckBoxThing:SetConVar( "Hc_save_warning" ) -- ConCommand must be a 1 or 0 value
                --CheckBoxThing:SetValue( 1 )
                CheckBoxThing:SizeToContents() -- Make its size to the contents. Duh?
				
				-- too lazy to work out how to use dscrollpanel
				
				for i=1, 10 do
				local whichtextsave = GetConVar( "Hc_crosssave_" .. i )
				local supereasy_y = i * 10 * 2.5 + 5
				local TextEntry = vgui.Create( "DTextEntry", panel5 )	-- create the form as a child of frame
				TextEntry:SetPos( 0, supereasy_y )
				TextEntry:SetSize( 100, 20 )
				TextEntry:SetText( whichtextsave:GetString() )
				TextEntry.OnChange = function( self )
				RunConsoleCommand( "Hc_crosssave_" .. i, ( self:GetValue() ) )
				end
				
				local ConfirmColor = vgui.Create( "DButton", panel5 )
                ConfirmColor:SetText( "Save" )
                ConfirmColor:SetSize( 40, 20 )
                ConfirmColor:SetPos( 110, supereasy_y )
                ConfirmColor.DoClick = function()
				Hc_whichsaveslot = i
				--RunConsoleCommand( "crosshairs_save_prompt" )
				crosshairs_save_prompt()
			end
			
				local ConfirmColor = vgui.Create( "DButton", panel5 )
                ConfirmColor:SetText( "Load" )
                ConfirmColor:SetSize( 40, 20 )
                ConfirmColor:SetPos( 160, supereasy_y )
                ConfirmColor.DoClick = function()
				Hc_whichtoload = i
                crossloadingsaves()
			end
			end	
			
				--[[
					Server saving crosshairs :D
				]]--
				
				--Text
                local DLabel = vgui.Create( "DLabel", panel5 )
                DLabel:SetPos( 5, 280 ) -- Set the position of the label
                DLabel:SetTextColor( Color( 255, 255, 255, 255  ) )
                DLabel:SetText( "Submitted crosshairs" ) -- Set the text of the label
                DLabel:SizeToContents() -- Size the label to fit the text in it
                DLabel:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
				
				
		

end
concommand.Add( "crosshairs", OpenCrosshairDerma )

--[[
	Startup
]]--

	local function Hc_startup()
	
		if not file.IsDir( "crosshair_designer", "DATA" ) then
		file.CreateDir( "crosshair_designer", "DATA" )
		end
		
	timer.Create( "Hc_load_dynamic_startup", 1, 0, function()  
	if LocalPlayer():IsValid() then
	timer.Destroy( "Hc_load_dynamic_startup" )
	hc_dynamiccorsshair()
	end
	end )
		
	end
	hook.Add( "Initialize", "Hc_startup", Hc_startup )
	
end
	
--[[
	Chat command
]]--
			
		hook.Add( "PlayerSay", "CrosshairMenu", function( ply, text, public )
		text = string.lower( text ) -- Make the chat message entirely lowercase
		if ( text == "!cross" or text == "!crosshair" ) then
		ply:ConCommand( "crosshairs" )
		return text
	end
	end )
