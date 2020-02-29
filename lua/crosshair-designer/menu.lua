local buttonSizeYOffset = 10 -- fontSize+buttonSizeOffset = buttonSize

local fontSize = 14 -- Later add option in settings, maybe also allow weight adjustment etc and type?
local fontTitleSize = 20
local screenW, screenH = ScrW(), ScrH()

local cols = {
	title = Color(35,35,35)
}

-- Return a frame size which takes into account the aspect ratio
local function CalculateMenuSize(screenWidth, screenHeight)
	local frameW = screenWidth * (0.2 * ((1920/1080) - (screenWidth/screenHeight) +1))
	local frameH = screenHeight

	return frameW, frameH
end

-- Return position for menu to be at top right
local function CalculateMenuPos(calcMenuSize, screenWidth, screenHeight)
	local frameW, frameH = calcMenuSize(screenWidth, screenHeight)

	local x = screenWidth - frameW
	local y = 0

	return x, y
end

CrosshairDesigner.CreateFonts(fontSize) -- Unused

-- Check for resolution changes
timer.Create("CrosshairDesigner.ResolutionChangeCheck", 1, 0, function()
	if ScrW() ~= screenW or ScrH() ~= screenH then
		if CrosshairDesigner.IsMenuOpen() then
			CrosshairDesigner.OpenMenu() -- Updates menu size if already open
		end
	end
end)

CrosshairDesigner.IsMenuOpen = function()
	return CrosshairDesigner.Menu ~= nil and 
			IsValid(CrosshairDesigner.Menu) and
			CrosshairDesigner.Menu:IsVisible()
end

CrosshairDesigner.MenuWidgets = {}
CrosshairDesigner.OpenMenu = function()

	-- Make the frame seem the same size regardless of aspect ratio
	screenW, screenH = ScrW(), ScrH()
	local frameW, frameH = CalculateMenuSize(screenW, screenH)
	local frameX, frameY = CalculateMenuPos(CalculateMenuSize, screenW, screenH)

	-- Only open one copy
	if IsValid(CrosshairDesigner.Menu) then
		CrosshairDesigner.Menu:SetVisible(true)

		-- Update size
		CrosshairDesigner.Menu:SetSize( frameW, frameH )
		CrosshairDesigner.Menu:SetPos( frameX, frameY )

		for i, widget in pairs(CrosshairDesigner.MenuWidgets) do
			widget.UpdateSize()
		end
		return
	end

	CrosshairDesigner.Menu = vgui.Create( "DFrame" )
	CrosshairDesigner.Menu:SetSize( frameW, frameH )
	CrosshairDesigner.Menu:SetPos( frameX, frameY )
	CrosshairDesigner.Menu:MakePopup()
	CrosshairDesigner.Menu:SetTitle( "Crosshair Designer" )
	CrosshairDesigner.Menu.btnClose.DoClick = function ( button ) CrosshairDesigner.Menu:Remove() end //CrosshairDesigner.ShowMenu(false) end

	-- Use scroll bar parent
	-- Add/remove ones which are only enabled with toggle?

	-- Move into custom vgui element
	local MB_topBar = vgui.Create( "DMenuBar", CrosshairDesigner.Menu )
	MB_topBar:DockMargin( -3, -6, -3, 0 )

	// https://wiki.garrysmod.com/page/Category:DMenuBar
	local M1 = MB_topBar:AddMenu( "File" )
	M1:AddOption( "Open", function() Msg( "Chose File:New\n" ) end ):SetIcon( "icon16/page_white_go.png" )
	M1:AddOption( "Save", function() 
	--Derma_Query("Enter save name", "Save", "Accept", function() print("saving...") end, "Cancel", function() print("cancel...") end)
	Derma_StringRequest("Enter save nma", "Save", "Save 1", function(text) print("Saving..") end, function(text) print("cancel..") end)
	end ):SetIcon( "icon16/folder_go.png" )
	local M2 = MB_topBar:AddMenu( "Settings" )
	M1:AddOption( "Reset", function() Msg( "Chose File:New\n" ) end ):SetIcon( "icon16/page_white_go.png" )

	local sheet = vgui.Create("DPropertySheet", CrosshairDesigner.Menu)
    sheet:Dock( FILL )

    local panel4 = vgui.Create( "DPanel", sheet )
    panel4.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color(0, 0, 0, 0 ) ) end
    sheet:AddSheet( "Crosshair Settings", panel4 )

    local panel6 = vgui.Create( "DPanel", sheet )
    panel6.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color(0, 0, 0, 0 ) ) end
    sheet:AddSheet( "Colour", panel6 )

    local panel5 = vgui.Create( "DPanel", sheet )
    panel5.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color(0, 0, 0, 0 ) ) end
    sheet:AddSheet( "Saving", panel5 )

    local sub = M1:AddSubMenu( "Sub Menu" )
	sub:SetDeleteSelf( false )
	for i = 0, 5 do
		sub:AddOption( "Option " .. i, function() MsgN( "Chose sub menu option " .. i ) end )
	end

	-- :D
	local convarDatas = CrosshairDesigner.GetConvarDatas()

	-- create the menus!

end

CrosshairDesigner.OpenMenu()

