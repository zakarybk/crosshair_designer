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
	if ScrW() != screenW or ScrH() != screenH then
		if CrosshairDesigner.IsMenuOpen() then
			CrosshairDesigner.OpenMenu() -- Updates menu size if already open
		end
	end
end)

CrosshairDesigner.IsMenuOpen = function()
	return CrosshairDesigner.Menu != nil and 
			IsValid(CrosshairDesigner.Menu) and
			CrosshairDesigner.Menu:IsVisible()
end

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
		return
	end

	CrosshairDesigner.Menu = vgui.Create( "DFrame" )
	CrosshairDesigner.Menu:SetSize( frameW, frameH )
	CrosshairDesigner.Menu:SetPos( frameX, frameY )
	CrosshairDesigner.Menu:MakePopup()
	CrosshairDesigner.Menu:SetTitle( "Crosshair Designer" )
	CrosshairDesigner.Menu.btnClose.DoClick = function ( button ) CrosshairDesigner.Menu:Remove() end //CrosshairDesigner.ShowMenu(false) end

	-- Move into custom vgui element
	local MB_topBar = vgui.Create( "DMenuBar", CrosshairDesigner.Menu )
	MB_topBar:DockMargin( -3, -6, -3, 0 )

	// https://wiki.garrysmod.com/page/Category:DMenuBar
	local M1 = MB_topBar:AddMenu( "File" )
	M1:AddOption( "New", function() Msg( "Chose File:New\n" ) end ):SetIcon( "icon16/page_white_go.png" )
	M1:AddOption( "Open", function() Msg( "Chose File:Open\n" ) end ):SetIcon( "icon16/folder_go.png" )
	local M2 = MB_topBar:AddMenu( "Edit" )
	local M2 = MB_topBar:AddMenu( "Settings" )
	M2:AddOption( "Save workspace", function() Msg( "Chose File:New\n" ) end ):SetIcon( "icon16/page_white_go.png" )
	M2:AddOption( "Load workspace", function() Msg( "Chose File:Open\n" ) end ):SetIcon( "icon16/folder_go.png" )
	local M3 = MB_topBar:AddMenu( "Window" )
	M3:AddOption( "Settings", function() Msg( "Chose File:Open\n" ) end ):SetIcon( "icon16/folder_go.png" )
	M3:AddOption( "Layers", function() Msg( "Chose File:Open\n" ) end ):SetIcon( "icon16/folder_go.png" )
	local M4 = MB_topBar:AddMenu( "Help" )

end

--CrosshairDesigner.OpenMenu()