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
			CrosshairDesigner.OpenMenu(true) -- Updates menu size if already open
			hook.Run("CrosshairDesigner_DetectedResolutionChange")
		end
	end
end)

CrosshairDesigner.IsMenuOpen = function()
	return CrosshairDesigner.Menu ~= nil and 
			IsValid(CrosshairDesigner.Menu) and
			CrosshairDesigner.Menu:IsVisible()
end

CrosshairDesigner.OpenMenu = function(resolutionChanged)

	-- Make the frame seem the same size regardless of aspect ratio
	screenW, screenH = ScrW(), ScrH()
	local frameW, frameH = CalculateMenuSize(screenW, screenH)
	local frameX, frameY = CalculateMenuPos(CalculateMenuSize, screenW, screenH)

	-- Only open one copy
	if IsValid(CrosshairDesigner.Menu) then
		CrosshairDesigner.Menu:SetVisible(true)

		-- Update size
		if resolutionChanged then
			CrosshairDesigner.Menu:SetSize( frameW, frameH )
			CrosshairDesigner.Menu:SetPos( frameX, frameY )
		end

		return
	end

	CrosshairDesigner.Menu = vgui.Create( "DFrame" )
	CrosshairDesigner.Menu:SetSize( frameW, frameH )
	CrosshairDesigner.Menu:SetPos( frameX, frameY )
	CrosshairDesigner.Menu:MakePopup()
	CrosshairDesigner.Menu:SetTitle( "Crosshair Designer V3" )
	CrosshairDesigner.Menu.btnClose.DoClick = function(button) 
		CrosshairDesigner.Menu:SetVisible(false) 
	end

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
	M1:AddOption( "Reset", function() Msg( "Chose File:New\n" ) end ):SetIcon( "icon16/page_white_go.png" )

	local sub -- more DermaMenu

	local function createSubMenus()
		if IsValid(sub) then sub:Remove() end
	    sub = M1:AddSubMenu( "Open" )
		sub:SetDeleteSelf( false )
		for i = 1, 10 do
			sub:AddOption( i .. ": SaveGG2 " .. tostring(CurTime()), function() MsgN( "Chose sub menu option " .. i ) end )
		end
	end
	createSubMenus()
	createSubMenus()

	-- :D
	local convarDatas = CrosshairDesigner.GetConvarDatas()

	CrosshairDesigner.ScrollPanel = vgui.Create("DScrollPanel", CrosshairDesigner.Menu)
	CrosshairDesigner.ScrollPanel:Dock( FILL )

	-- Create toggles
	for i, data in pairs(convarDatas) do
		if data.isBool then
			local checkBox = vgui.Create("DCheckBoxLabel", CrosshairDesigner.ScrollPanel)
	        checkBox:SetText(data.title)
	        checkBox:SetConVar(data.var)
	        checkBox:Dock( TOP )
			checkBox:DockMargin( 0, 5, 0, 0 )
	    end
	end
	
	-- Create sliders
	for i, data in pairs(convarDatas) do
		if not data.isBool and not data.isColour then
			local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
            label:SetTextColor(Color(255, 255, 255, 255))
            label:SetText(data.title)
            label:SetDark( 1 )
            label:Dock(TOP)
			label:DockMargin(0, 5, 0, 0)

		    local slider = vgui.Create("Slider", CrosshairDesigner.ScrollPanel)
            slider:SetMin(data.min)
            slider:SetMax(data.max)
            slider:SetDecimals(0)
            slider:SetConVar(data.var)
			slider:SetValue(CrosshairDesigner.GetInt(data.var))
			slider:Dock(TOP)
			slider:DockMargin(0, 0, 0, 0)
	    end
	end

	-- Colour picker for normal
	local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetText("Normal crosshair colour picker")
    label:SetDark( 1 )
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)

	local colourPicker = vgui.Create("DColorMixer", CrosshairDesigner.ScrollPanel)
    colourPicker:SetPalette(true)
    colourPicker:SetAlphaBar(true)
    colourPicker:SetWangs(true)
    colourPicker:Dock(TOP)
	colourPicker:DockMargin(0, 5, 0, 0)
    colourPicker:SetColor(Color(
    	CrosshairDesigner.GetInt("Red"), 
    	CrosshairDesigner.GetInt("Green"), 
    	CrosshairDesigner.GetInt("Blue"), 
    	CrosshairDesigner.GetInt("Alpha") 
    ))

    local confirm = vgui.Create("DButton", CrosshairDesigner.ScrollPanel)
    confirm:SetText("Normal colour")
    confirm:Dock(TOP)
	confirm:DockMargin(0, 5, 0, 0)
    confirm.DoClick = function()
	    local colour = colourPicker:GetColor()
	    CrosshairDesigner.SetValue("Red", colour.r)
	    CrosshairDesigner.SetValue("Green", colour.g)
	    CrosshairDesigner.SetValue("Blue", colour.b)
	    CrosshairDesigner.SetValue("Alpha", colour.a)
	end

	-- Colour picker for target
	local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetText("On target crosshair colour picker")
    label:SetDark(1)
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)

	local targetColourPicker = vgui.Create("DColorMixer", CrosshairDesigner.ScrollPanel)
    targetColourPicker:SetPalette(true)
    targetColourPicker:SetAlphaBar(true)
    targetColourPicker:SetWangs(true)
    targetColourPicker:Dock(TOP)
	targetColourPicker:DockMargin(0, 5, 0, 0)
    targetColourPicker:SetColor(Color(
    	CrosshairDesigner.GetInt("TargetRed"), 
    	CrosshairDesigner.GetInt("TargetGreen"),
    	CrosshairDesigner.GetInt("TargetBlue"), 
    	CrosshairDesigner.GetInt("TargetAlpha") 
    ))

    local targetConfirm = vgui.Create("DButton", CrosshairDesigner.ScrollPanel)
    targetConfirm:SetText("Target colour")
    targetConfirm:Dock(TOP)
	targetConfirm:DockMargin(0, 5, 0, 0)
    targetConfirm.DoClick = function()
	    local colour = targetColourPicker:GetColor()
	    CrosshairDesigner.SetValue("TargetRed", colour.r)
	    CrosshairDesigner.SetValue("TargetGreen", colour.g)
	    CrosshairDesigner.SetValue("TargetBlue", colour.b)
	    CrosshairDesigner.SetValue("TargetAlpha", colour.a)
	end

end

concommand.Add("crosshairs", function()
	if CrosshairDesigner.IsMenuOpen() then
		CrosshairDesigner.Menu:SetVisible(false)
	else
		CrosshairDesigner.OpenMenu()
	end
end)
concommand.Add("+crosshairs", function()
	CrosshairDesigner.OpenMenu()
end)
concommand.Add("-crosshairs", function()
	CrosshairDesigner.Menu:SetVisible(false)
end)


--[[
	Chat command
]]--
hook.Add("OnPlayerChat", "CrosshairDesigner_OpenMenu", function(ply, text, teamChat, isDead)
	if ply == LocalPlayer() and not teamChat then
		text = string.Trim(string.lower(text))

		if text == "!cross" or text == "!crosshair" or text == "!crosshairs" then
			CrosshairDesigner.OpenMenu()
		end
	end
end)