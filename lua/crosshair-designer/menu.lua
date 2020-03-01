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

		hook.Run("CrosshairDesigner_MenuOpened", CrosshairDesigner.Menu)

		return
	end

	CrosshairDesigner.Menu = vgui.Create( "DFrame" )
	CrosshairDesigner.Menu:SetSize(frameW, frameH)
	CrosshairDesigner.Menu:SetPos(frameX, frameY)
	CrosshairDesigner.Menu:MakePopup(false)
	CrosshairDesigner.Menu:SetTitle( "Crosshair Designer V3" )
	CrosshairDesigner.Menu.btnClose.DoClick = function(button) 
		CrosshairDesigner.Menu:SetVisible(false)
		hook.Run("CrosshairDesigner_MenuClosed", CrosshairDesigner.Menu)
	end

	CrosshairDesigner.Sheet = vgui.Create("DPropertySheet", CrosshairDesigner.Menu)
    CrosshairDesigner.Sheet:Dock(FILL)

   	CrosshairDesigner.Sheet.Settings = vgui.Create("DPanel", CrosshairDesigner.Sheet)
    CrosshairDesigner.Sheet.Settings.Paint = function(self, w, h) 
    	draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0))
    end
    CrosshairDesigner.Sheet:AddSheet("Settings", CrosshairDesigner.Sheet.Settings)

	CrosshairDesigner.Sheet.Saving = vgui.Create("DPanel", CrosshairDesigner.Sheet)
    CrosshairDesigner.Sheet.Saving.Paint = function(self, w, h) 
    	draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0)) 
    end
    CrosshairDesigner.Sheet:AddSheet("Saving", CrosshairDesigner.Sheet.Saving)


	local convarDatas = CrosshairDesigner.GetConvarDatas()

	CrosshairDesigner.ScrollPanel = vgui.Create("DScrollPanel", CrosshairDesigner.Sheet.Settings)
	CrosshairDesigner.ScrollPanel:Dock(FILL)

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

	CrosshairDesigner.Sliders = {}
	
	-- Create sliders
	for i, data in pairs(convarDatas) do
		if not data.isBool and not data.isColour then
			local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
            label:SetTextColor(Color(255, 255, 255, 255))
            label:SetText(data.title)
            label:SetDark(1)
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
			slider.var = data.var

			table.insert(CrosshairDesigner.Sliders, slider)
	    end
	end

	-- Colour picker for normal
	local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetText("Normal crosshair colour")
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
    CrosshairDesigner.colourPicker = colourPicker

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
    label:SetText("On target crosshair colour")
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
    CrosshairDesigner.targetColourPicker = targetColourPicker

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

	-- Saving menu now

	for i=1, 10 do
		local dPanel = vgui.Create("DPanel", CrosshairDesigner.Sheet.Saving)
		dPanel:Dock(TOP)
		dPanel:DockMargin(0, 5, 0, 0)

		local whichtextsave = GetConVar("Hc_crosssave_" .. i)
		local textEntry = vgui.Create("DTextEntry", dPanel)
		textEntry:Dock(FILL)
		textEntry:DockMargin(0, 0, 0, 0)
		textEntry:SetText(whichtextsave:GetString())
		textEntry.OnChange = function( self )
			RunConsoleCommand("Hc_crosssave_" .. i, (self:GetValue()))
		end

		local loadButton = vgui.Create("DButton", dPanel)
        loadButton:SetText("Load")
        loadButton:Dock(RIGHT)
        loadButton:DockMargin(0, 0, 0, 0)
        loadButton.DoClick = function()
        	CrosshairDesigner.Load(i)
		end
		
		local saveButton = vgui.Create("DButton", dPanel)
        saveButton:SetText("Save")
        saveButton:Dock(RIGHT)
        saveButton:DockMargin(0, 0, 0, 0)
        saveButton.DoClick = function()
        	if file.Exists("crosshair_designer/save_" .. i .. ".txt", "DATA") then
        		CrosshairDesigner.OpenSavePrompt(i)
        	else
        		CrosshairDesigner.Save(i)
        	end
		end
	
	end

	local toClipboard = vgui.Create("DButton", CrosshairDesigner.Sheet.Saving)
    toClipboard:SetText("Copy current crosshair to clipboard")
    toClipboard:Dock(TOP)
	toClipboard:DockMargin(0, 5, 0, 0)
    toClipboard.DoClick = function()
    	SetClipboardText(CrosshairDesigner.CurrentToString())
	end

	local toClipboard = vgui.Create("DButton", CrosshairDesigner.Sheet.Saving)
    toClipboard:SetText("Load crosshair from string (control+v to paste)")
    toClipboard:Dock(TOP)
	toClipboard:DockMargin(0, 5, 0, 0)
    toClipboard.DoClick = function()
    	Derma_StringRequest(
			"Crosshair Designer", 
			"Paste the crosshair settings string (control+v)",
			"",
			function(text) CrosshairDesigner.Load(0, text) end,
			function(text) end
		)
	end

	-- Always at bottom
	hook.Run("CrosshairDesigner_MenuOpened", CrosshairDesigner.Menu)

end

concommand.Add("crosshairs", function()
	if CrosshairDesigner.IsMenuOpen() then
		CrosshairDesigner.Menu:SetVisible(false)
		hook.Run("CrosshairDesigner_MenuClosed", CrosshairDesigner.Menu)
	else
		CrosshairDesigner.OpenMenu()
	end
end)
concommand.Add("+crosshairs", function()
	CrosshairDesigner.OpenMenu()
end)
concommand.Add("-crosshairs", function()
	CrosshairDesigner.Menu:SetVisible(false)
	hook.Run("CrosshairDesigner_MenuClosed", CrosshairDesigner.Menu)
end)

hook.Add("CrosshairDesigner_CrosshairLoaded", "UpdateMenu", function()
	if CrosshairDesigner.Menu == nil or not IsValid(CrosshairDesigner.Menu) then
		return
	end

	for i, slider in pairs(CrosshairDesigner.Sliders) do
		local val = CrosshairDesigner.GetInt(slider.var)
		slider:SetValue(val)
	end

	CrosshairDesigner.colourPicker:SetColor(Color(
    	CrosshairDesigner.GetInt("Red"),
    	CrosshairDesigner.GetInt("Green"), 
    	CrosshairDesigner.GetInt("Blue"), 
    	CrosshairDesigner.GetInt("Alpha") 
    ))

	CrosshairDesigner.targetColourPicker:SetColor(Color(
    	CrosshairDesigner.GetInt("TargetRed"), 
    	CrosshairDesigner.GetInt("TargetGreen"),
    	CrosshairDesigner.GetInt("TargetBlue"),
    	CrosshairDesigner.GetInt("TargetAlpha")
    ))
end)

CrosshairDesigner.OpenSavePrompt = function(crossID)

	local Frame = vgui.Create("DFrame")
	Frame:SetPos(ScrW() / 2 - 150, ScrH() / 2 - 75)
	Frame:SetSize(300, 130)
	Frame:SetTitle("Confirm")
	Frame:SetVisible(true)
	Frame:SetBackgroundBlur(true)
	Frame:SetDraggable(false)
	Frame:ShowCloseButton(true)
	Frame:MakePopup()
	function Frame:Paint( w, h )
		draw.RoundedBox(0, 0, 0, w, h, Color( 255, 93, 0 ))
		draw.RoundedBox(0, 1, 1, w-2, h-2, Color( 36, 36, 36 ))
	end

	local DLabel = vgui.Create("DLabel", Frame)
	DLabel:SetPos(20, 30 )
	DLabel:SetText("Are you sure you want to override")
	DLabel:SizeToContents() 

	local DLabel = vgui.Create("DLabel", Frame)
	DLabel:SetPos(20 , 50)
	DLabel:SetText(GetConVar("Hc_crosssave_" .. crossID):GetString() .. "?")
	DLabel:SizeToContents() 

	local yesButton = vgui.Create("DButton", Frame)
	yesButton:SetText("Yes")
	yesButton:SetSize(40, 20)
	yesButton:SetPos(70, 90)
	yesButton.DoClick = function()
		CrosshairDesigner.Save(crossID)
		Frame:Close()
	end

	local noButton = vgui.Create("DButton", Frame)
	noButton:SetText("No")
	noButton:SetSize(40, 20)
	noButton:SetPos(190, 90)
	noButton.DoClick = function()
		Frame:Close()
	end

end


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