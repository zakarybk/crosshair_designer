local buttonSizeYOffset = 10 -- fontSize+buttonSizeOffset = buttonSize

local fontSize = 14 -- Later add option in settings, maybe also allow weight adjustment etc and type?
local fontTitleSize = 20
local screenW, screenH = ScrW(), ScrH()

local cols = {
	title = Color(35,35,35)
}

-- Return a frame size which takes into account the aspect ratio
local function CalculateMenuSize(screenWidth, screenHeight)
	local baseW, baseH = 1920, 1080

	-- Stops the menu from becoming wider if only the screen width increases
	local aspect = math.min(screenWidth/screenHeight, baseW/baseH)
	local diff = math.min((baseW/baseH) / (screenWidth/screenHeight), 1)
	local frameW = math.Round(screenWidth * (0.2 * ((1920/1080)-aspect +1)) * diff)

	local frameH = screenHeight

	return frameW, frameH
end

-- Return position for menu to be at top right
local function CalculateMenuPos(calcMenuSize, screenWidth, screenHeight)
	local frameW, frameH = calcMenuSize(screenWidth, screenHeight)

	local x = screenWidth - frameW + 1
	local y = 0

	return x, y
end

-- Returns the factor to scale everything by to better support higher resolutions
local function CalculateScaleFactor(calcMenuSize, screenWidth, screenHeight)
	local baseW, baseH = calcMenuSize(1920, 1080)
	local frameW, frameH = calcMenuSize(screenWidth, screenHeight)

	return math.max(frameW/baseW, 1)
end

-- Check for resolution changes
hook.Add("OnScreenSizeChanged", "CrosshairDesignerMenuResize", function()
	if IsValid(CrosshairDesigner.Menu) then
		CrosshairDesigner.OpenMenu(true) -- Updates menu size if already open
	end
end)

CrosshairDesigner.IsMenuOpen = function()
	return CrosshairDesigner.Menu ~= nil and
			IsValid(CrosshairDesigner.Menu) and
			CrosshairDesigner.Menu:IsVisible()
end

hook.Add("CrosshairDesigner_ValueChanged", "UpdateStats", function(convar, val)
	if IsValid(CrosshairDesigner.Menu) then
		CrosshairDesigner.Sheet.Advanced.Mem.Recalculate()
		CrosshairDesigner.Sheet.Advanced.Info.Recalculate()
	end
end)

local function sortedConvarData(tbl, typeCheck, groupOrder)
	local sorted = {}

	-- group
	for i, group in ipairs(groupOrder) do
		for ii, row in ipairs(tbl) do
			if typeCheck(row) and row.menuGroup and row.menuGroup == group then
				table.insert(sorted, row)
			end
		end
	end

	-- add remainder
	for ii, row in ipairs(tbl) do
		if typeCheck(row) and not table.HasValue(sorted, row) then
			table.insert(sorted, row)
		end
	end

	return sorted
end

local function createSpacer()
	local spacer = vgui.Create("DPanel")
	spacer:Dock(TOP)
	spacer:DockMargin(0, 5, 0, 0)
	spacer:SetHeight(1)

	function spacer:Paint( w, h )
	    draw.RoundedBox( 8, 0, 0, w, h, Color( 90, 90, 90 ) )
	end

	return spacer
end

CrosshairDesigner.OpenMenu = function(resolutionChanged)

	-- Make the frame seem the same size regardless of aspect ratio
	screenW, screenH = ScrW(), ScrH()
	local frameW, frameH = CalculateMenuSize(screenW, screenH)
	local frameX, frameY = CalculateMenuPos(CalculateMenuSize, screenW, screenH)
	--local scaleFactor = CalculateScaleFactor(CalculateMenuSize, screenW, screenH) -- To later use to change font size?

	-- Only open one copy
	if IsValid(CrosshairDesigner.Menu) then

		-- Update size or open menu
		if resolutionChanged then
			CrosshairDesigner.Menu:SetSize(frameW, frameH)
			CrosshairDesigner.Menu:SetPos(frameX, frameY)
		else
			CrosshairDesigner.Menu:SetVisible(true)
		end

		-- update the cache stat
		local stat = tostring(math.Round(CrosshairDesigner.CacheHitPercent(), 2)) or "0"
		CrosshairDesigner.Sheet.Advanced.Stat:SetText("Current cache hit percent: " .. stat .. "%")

		CrosshairDesigner.Sheet.Advanced.Mem.Recalculate()
		CrosshairDesigner.Sheet.Advanced.Info.Recalculate()

		hook.Run("CrosshairDesigner_MenuOpened", CrosshairDesigner.Menu)

		return
	end

	CrosshairDesigner.Menu = vgui.Create( "DFrame" )
	CrosshairDesigner.Menu:SetSize(frameW, frameH)
	CrosshairDesigner.Menu:SetPos(frameX, frameY)
	CrosshairDesigner.Menu:MakePopup(false)
	CrosshairDesigner.Menu:SetTitle( "Crosshair Designer " .. CrosshairDesigner.VERSION )
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

    CrosshairDesigner.Sheet.Advanced = vgui.Create("DPanel", CrosshairDesigner.Sheet)
    CrosshairDesigner.Sheet.Advanced.Paint = function(self, w, h)
    	draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 0))
    end
    CrosshairDesigner.Sheet:AddSheet("Advanced", CrosshairDesigner.Sheet.Advanced)


	local convarDatas = CrosshairDesigner.GetConvarDatas()

	CrosshairDesigner.ScrollPanel = vgui.Create("DScrollPanel", CrosshairDesigner.Sheet.Settings)
	CrosshairDesigner.ScrollPanel:Dock(FILL)

	-- Create toggles
	local prevGroup = 'cross'
	local toggles = sortedConvarData(
		convarDatas,
		function(data) return data.isBool end,
		{'cross', 'hide', 'cross-circle', 'cirlce'}
	)
	local excludeItems = {['HideFAS']=true, ['HideCW']=true} -- temporarily hide these whilst I decide how best to remove them
	for i, data in pairs(toggles) do
		if excludeItems[data.id] ~= true then

			if prevGroup ~= data.menuGroup then
				CrosshairDesigner.ScrollPanel:AddItem(createSpacer())
				prevGroup = data.menuGroup
			end

			local checkBox = vgui.Create("DCheckBoxLabel", CrosshairDesigner.ScrollPanel)
			checkBox:SetText(data.title)
			checkBox:SetFont("DermaDefaultBold")
			checkBox:SetConVar(data.var)
			checkBox:Dock( TOP )
			checkBox:DockMargin( 0, 5, 0, 0 )
			checkBox:SetTooltip(data.help)
		end
	end

	CrosshairDesigner.ScrollPanel:AddItem(createSpacer())

	CrosshairDesigner.Sliders = {}

	-- Create sliders
	local prevGroup = 'cross'
	local slides = sortedConvarData(
		convarDatas,
		function(data) return not data.isBool and not data.isColour end,
		{'cross', 'hide', 'cross-circle', 'cirlce'}
	)
	for i, data in pairs(slides) do
		if prevGroup ~= data.menuGroup then
			CrosshairDesigner.ScrollPanel:AddItem(createSpacer())
			prevGroup = data.menuGroup
		end

		local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
	    label:SetTextColor(Color(255, 255, 255, 255))
	    label:SetText(data.title)
	    label:SetFont("DermaDefaultBold")
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

	CrosshairDesigner.ScrollPanel:AddItem(createSpacer())

	-- Colour picker for normal
	local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetFont("DermaDefaultBold")
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
    label:SetFont("DermaDefaultBold")
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

	-- Colour picker for outline
	local label = vgui.Create("DLabel", CrosshairDesigner.ScrollPanel)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetFont("DermaDefaultBold")
    label:SetText("Outline colour (requires outline enabled)")
    label:SetDark(1)
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)

	local outlineColourPicker = vgui.Create("DColorMixer", CrosshairDesigner.ScrollPanel)
    outlineColourPicker:SetPalette(true)
    outlineColourPicker:SetAlphaBar(true)
    outlineColourPicker:SetWangs(true)
    outlineColourPicker:Dock(TOP)
	outlineColourPicker:DockMargin(0, 5, 0, 0)
    outlineColourPicker:SetColor(Color(
    	CrosshairDesigner.GetInt("OutlineRed"),
    	CrosshairDesigner.GetInt("OutlineGreen"),
    	CrosshairDesigner.GetInt("OutlineBlue"),
    	CrosshairDesigner.GetInt("OutlineAlpha")
    ))
    CrosshairDesigner.outlineColourPicker = outlineColourPicker

    local outlineConfirm = vgui.Create("DButton", CrosshairDesigner.ScrollPanel)
    outlineConfirm:SetText("Outline colour")
    outlineConfirm:Dock(TOP)
	outlineConfirm:DockMargin(0, 5, 0, 0)
    outlineConfirm.DoClick = function()
	    local colour = outlineColourPicker:GetColor()
	    CrosshairDesigner.SetValue("OutlineRed", colour.r)
	    CrosshairDesigner.SetValue("OutlineGreen", colour.g)
	    CrosshairDesigner.SetValue("OutlineBlue", colour.b)
	    CrosshairDesigner.SetValue("OutlineAlpha", colour.a)
	end

	-- Saving menu now

	for i=1, 16 do
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

	local resetCrosshair = vgui.Create("DButton", CrosshairDesigner.Sheet.Saving)
    resetCrosshair:SetText("Reset crosshair to default")
    resetCrosshair:Dock(BOTTOM)
	resetCrosshair:DockMargin(0, 5, 0, 0)
    resetCrosshair.DoClick = function()
    	prompt = {
    		title="Crosshair Designer - Reset Crosshair",
			text="Are you sure? Any unsaved changes will be lost!",
			btn1text="Yes",
			btn2text="Cancel",
			btn1func=function(text) CrosshairDesigner.LoadDefaultCrosshair() end,
			btn2func=function(text) end
		}
    	Derma_Query(
			prompt.text,
			prompt.title,
			prompt.btn1text,
			prompt.btn1func,
			prompt.btn2text,
			prompt.btn2func
		)
	end

	-- Advanced TAB
	local label = vgui.Create("DLabel", CrosshairDesigner.Sheet.Advanced)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetAutoStretchVertical(true)
    label:SetWrap(true)
    label:SetText("Cache the calculations used to generate the crosshair at each position on the screen. The bigger the cache, the more memory used but the less you need to re-calculate and the higher the cache hit percent. - Can be left at 1 for static crosshairs (dynamic off + centre to player angles off)")
    label:SetDark(1)
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)

	local label = vgui.Create("DLabel", CrosshairDesigner.Sheet.Advanced)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetAutoStretchVertical(true)
    label:SetWrap(true)
	label:SetText("Placeholder")
    label:SetDark(1)
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)
	label.Recalculate = function()
		local stat = tostring(math.Round(CrosshairDesigner.CacheHitPercent(), 2)) or "0"
		label:SetText("Current cache hit percent: " .. stat .. "%")
	end
	CrosshairDesigner.Sheet.Advanced.Stat = label
	CrosshairDesigner.Sheet.Advanced.Stat.Recalculate()

	local cacheTickbox = vgui.Create("DCheckBoxLabel", CrosshairDesigner.Sheet.Advanced)
    cacheTickbox:SetText("Enable cache")
    cacheTickbox:SetValue(CrosshairDesigner.CacheEnabled())
    cacheTickbox:Dock( TOP )
	cacheTickbox:DockMargin( 0, 5, 0, 0 )
	cacheTickbox:SetTooltip("Enable for more performance")
	hook.Add("CrosshairDesigner_CacheSizeUpdate", "MenuUpdate", function(newVal)
		CrosshairDesigner.Sheet.Advanced.cacheSlider:SetVisible(newVal >= 2)
		if newVal >= 2 then
			CrosshairDesigner.Sheet.Advanced.cacheSlider:SetValue(newVal)
		end
		CrosshairDesigner.Sheet.Advanced.Mem.Recalculate()
		CrosshairDesigner.Sheet.Advanced.Stat.Recalculate()
	end)
	cacheTickbox.OnChange = function(self, newVal)
		if newVal then
			CrosshairDesigner.SetCacheSize(5)
		else
			CrosshairDesigner.SetCacheSize(0)
		end
	end

	local cacheSlider = vgui.Create("DNumSlider", CrosshairDesigner.Sheet.Advanced)
    cacheSlider:SetMin(CrosshairDesigner.CacheMinSize)
    cacheSlider:SetMax(CrosshairDesigner.CacheMaxSize)
    cacheSlider:SetDecimals(0)
	cacheSlider:SetValue(CrosshairDesigner.CacheSize())
	cacheSlider:Dock(TOP)
	cacheSlider:DockMargin(0, 0, 0, 0)
	cacheSlider:SetVisible(CrosshairDesigner.CacheEnabled())
	cacheSlider.OnValueChanged = function(self, val)
		CrosshairDesigner.SetCacheSize(val)
		CrosshairDesigner.Sheet.Advanced.Stat.Recalculate()
	end
	CrosshairDesigner.Sheet.Advanced.cacheSlider = cacheSlider

	local label = vgui.Create("DLabel", CrosshairDesigner.Sheet.Advanced)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetAutoStretchVertical(true)
    label:SetWrap(true)
	label:SetText("Current estimated memory usage: Unknown")
    label:SetDark(1)
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)
	label.Recalculate = function()
		local crossMem = CrosshairDesigner.CalcMemoryUsage()
		local cacheSize = math.max(CrosshairDesigner.CacheSize(), 1)
		local mem = crossMem * cacheSize
		label:SetText("Current estimated memory usage: " .. CrosshairDesigner.FormatBytes(mem))
	end
	label.Recalculate()
	CrosshairDesigner.Sheet.Advanced.Mem = label

	local label = vgui.Create("DLabel", CrosshairDesigner.Sheet.Advanced)
    label:SetTextColor(Color(255, 255, 255, 255))
    label:SetAutoStretchVertical(true)
    label:SetWrap(true)
	label:SetText("Placeholder")
    label:SetDark(1)
    label:Dock(TOP)
	label:DockMargin(0, 5, 0, 0)

	label.Recalculate = function()
		local info = CrosshairDesigner.CalcInfo()
		local txt = "Crosshair stats:\n"
		txt = txt .. "Lines: " .. info.lines .. "\n"
		txt = txt .. "Polys: " .. info.polys .. "\n"
		label:SetText(txt)
	end
	CrosshairDesigner.Sheet.Advanced.Info = label
	CrosshairDesigner.Sheet.Advanced.Info.Recalculate()


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

    CrosshairDesigner.outlineColourPicker:SetColor(Color(
    	CrosshairDesigner.GetInt("OutlineRed"),
    	CrosshairDesigner.GetInt("OutlineGreen"),
    	CrosshairDesigner.GetInt("OutlineBlue"),
    	CrosshairDesigner.GetInt("OutlineAlpha")
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

list.Set("DesktopWindows", "CrosshairDesigner", {
	title = "Crosshair",
	icon = "crosshair_designer/ui/logo.png",
	init = function(icon, window)
		CrosshairDesigner.OpenMenu()
	end
})