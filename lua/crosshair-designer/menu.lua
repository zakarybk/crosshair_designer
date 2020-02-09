local buttonSizeYOffset = 10 -- fontSize+buttonSizeOffset = buttonSize

local fontSize = 14 -- Later add option in settings, maybe also allow weight adjustment etc and type?
local fontTitleSize = 20

local cols = {
	title = Color(35,35,35)
}

-- Return a frame size which takes into account the aspect ratio
local function CalculateMenuSize(screenWidth, screenHeight)
	local frameW = screenWidth * (0.2 * ((1920/1080) - (screenWidth/screenHeight) +1))
	local frameH = screenHeight

	return frameW, frameH
end

local function CalculateMenuPos(calcMenuSize, screenWidth, screenHeight)
	local frameW, frameH = calcMenuSize(screenWidth, screenHeight)

	local x = ScrW() - frameW
	local y = 0

	return x, y
end

-- Make the frame seem the same size regardless of aspect ratio
local screenW, screenH = ScrW(), ScrH()
local frameW, frameH = CalculateMenuSize(screenW, screenH)
local frameX, frameY = CalculateMenuPos(CalculateMenuSize, screenW, screenH)

CrosshairDesigner.CreateFonts(fontSize)

local function GetPanelX(panel) local x, y = panel:GetPos() return x end
local function GetPanelY(panel) local x, y = panel:GetPos() return y end

local frame = vgui.Create( "DFrame" )
frame:SetSize( frameW, frameH )
frame:SetPos( frameX, frameY )
frame:MakePopup()
frame:SetTitle( "Crosshair Designer" )
//frame:SetVisible(false)
frame.dpanels = {}
frame.btnClose.DoClick = function ( button ) frame:Remove() end //CrosshairDesigner.ShowMenu(false) end

-- Move into custom vgui element
local MB_topBar = vgui.Create( "DMenuBar", frame )
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

frame.PosInFrameBounds = function(self, posX, posY) 
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	
	return x <= posX and posX <= x + w and
		y <= posY and posY <= y + h
end
frame.AddDPanel = function(self, panel, droppedPosX, droppedPosY)
	insertAt = frame:WhichIndexToPlacePanel(droppedPosX, droppedPosY)

	if not table.HasValue(self.dpanels, panel) then
		table.insert(self.dpanels, insertAt, panel)
	else
		if not onBackground then
			table.RemoveByValue(self.dpanels, panel)
			table.insert(self.dpanels, insertAt, panel)
		end
	end
	panel:SetSize(frame:GetWide(), panel:GetTall())
	self:UpdateDFramePositions()
end
frame.RemoveDPanel = function(self, panel)
	if table.HasValue(self.dpanels, panel) then
		table.RemoveByValue(self.dpanels, panel)
		PrintTable(self.dpanels)
		self:UpdateDFramePositions()
	end
end
frame.PanelAtPosition = function(self, panels, posX, posY)
	local panelAtPos = nil
	local posAbove = true

	for i, panel in pairs(panels) do
		if panel:PosInFrameBounds(posX, posY) then
			panelAtPos = panel
			local x, y = panel:GetPos()
			posAbove = posY < (y + panel:GetTall() /2)
			break
		end
	end

	return panelAtPos, posAbove
end
frame.WhichIndexToPlacePanel = function(self, posX, posY)
	local index = 1
	local foundIndex = false
	local _, height = self:GetPos()

	if posY == nil then
		foundIndex = true
		index = math.max(#self.dpanels+1, 1)
	end

	height = height + 24 + MB_topBar:GetTall()

	if self.dpanels[1] != nil then
		height = height + self.dpanels[1]:GetTall() / 2
	else
		foundIndex = true
	end

	while(not foundIndex and index <= #self.dpanels) do
		if height + self.dpanels[index]:GetTall()/2 > posY then
			foundIndex = true
		else
			height =  height + self.dpanels[index]:GetTall()
			index = index + 1
		end
	end

	return index
end

local originalThink = frame.Think
local carry = true
frame.Think = function(self)
	local dragging = self.Dragging
	originalThink(self)
	if dragging or self:HasFocus() then
		frame:UpdateDFramePositions()
	end
end
frame.UpdateDFramePositions = function(self)
	local x, y = self:GetPos()
	local totalHeight = 24 + MB_topBar:GetTall()
	for i, panel in pairs(self.dpanels) do
		panel:MakePopup(true)
		panel:SetPos(x, y+totalHeight)
		totalHeight = totalHeight + panel:GetTall()
	end
end

--[[
	Zoom (make crosshair bigger)
]]--


/*
local popup1 = vgui.Create("DFrame")
popup1:SetSize(400, 300)
popup1:Center()
popup1:MakePopup()
popup1:SetTitle("This is a normal window.")
popup1.dpanels = {}
popup1.AddDPanel = function(self, panel, droppedPosX, droppedPosY)
	insertAt = popup1:WhichIndexToPlacePanel(droppedPosX, droppedPosY)

	if not table.HasValue(self.dpanels, panel) then
		table.insert(self.dpanels, insertAt, panel)
	else
		if not onBackground then
			table.RemoveByValue(self.dpanels, panel)
			table.insert(self.dpanels, insertAt, panel)
		end
	end
	panel:SetSize(popup1:GetWide(), panel:GetTall())
	self:UpdateDFramePositions()
end
popup1.RemoveDPanel = function(self, panel)
	if table.HasValue(self.dpanels, panel) then
		table.RemoveByValue(self.dpanels, panel)
		PrintTable(self.dpanels)
		self:UpdateDFramePositions()
	end
end
popup1.PanelAtPosition = function(self, panels, posX, posY)
	local panelAtPos = nil
	local posAbove = true

	for i, panel in pairs(panels) do
		if panel:PosInFrameBounds(posX, posY) then
			panelAtPos = panel
			local x, y = panel:GetPos()
			posAbove = posY < (y + panel:GetTall() /2)
			break
		end
	end

	return panelAtPos, posAbove
end
popup1.WhichIndexToPlacePanel = function(self, posX, posY)
	local index = 1
	local foundIndex = false
	local _, height = self:GetPos()

	if posY == nil then
		foundIndex = true
		index = math.max(#self.dpanels+1, 1)
		print(index)
	end

	height = height + 24

	if self.dpanels[1] != nil then
		height = height + self.dpanels[1]:GetTall() / 2
	else
		foundIndex = true
	end

	while(not foundIndex and index <= #self.dpanels) do
		if height + self.dpanels[index]:GetTall()/2 > posY then
			foundIndex = true
		else
			height =  height + self.dpanels[index]:GetTall()
			index = index + 1
		end
	end

	return index
end

local popThink = popup1.Think
local carry = true
popup1.Think = function(self)
	local dragging = self.Dragging
	popThink(self)
	if dragging or self:HasFocus() then
		popup1:UpdateDFramePositions()
	end
end
popup1.UpdateDFramePositions = function(self)
	local x, y = self:GetPos()
	local totalHeight = 24
	for i, panel in pairs(self.dpanels) do
		panel:MakePopup(true)
		panel:SetPos(x, y+totalHeight)
		totalHeight = totalHeight + panel:GetTall()
	end
end
popup1.PosInFrameBounds = function(self, posX, posY) 
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	
	return x <= posX and posX <= x + w and
		y <= posY and posY <= y + h
end
*/
local PANEL = {}

function PANEL:Init()
	self:SetSize(300, 100)
	self:Center()
	self:MakePopup()
	self:SetTitle("Crosshair Editor panel")
	self:SetDraggable(true)
	self:MakePopup()
	self.btnMaxim:SetVisible( false )
	self.btnMinim:SetVisible( false )
	self:DockPadding( 0, 24, 0, 0 )

	self.EditorFrame = frame

	local x, y = frame:GetPos()
	self:SetPos(x, y+24)
	self:SetSize(self:GetWide(), self:GetTall()-24)
	self.WasDragging = false
end

function PANEL:Think()
	if self.WasDragging and not self.Dragging then
		if not self.EditorFrame:PosInFrameBounds(input.GetCursorPos()) then
			self.EditorFrame:RemoveDPanel(self)
		else
			self.EditorFrame:AddDPanel(self, input.GetCursorPos())
		end
	end
	self.WasDragging = self.Dragging
	self.BaseClass.Think(self)
end

function PANEL:PosInFrameBounds(posX, posY) 
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	
	return x <= posX and posX <= x + w and
		y <= posY and posY <= y + h
end

derma.DefineControl( "CrossEditorPanel", "An editor panel for the crosshair designer", PANEL, "DFrame" )

local test = vgui.Create("CrossEditorPanel")
test:SetTitle(test:GetTitle() .. " 1")
frame:AddDPanel(test)

local test = vgui.Create("CrossEditorPanel")
test:SetTitle(test:GetTitle() .. " 2")
frame:AddDPanel(test)

local test = vgui.Create("CrossEditorPanel")
test:SetTitle(test:GetTitle() .. " 3")
frame:AddDPanel(test)

local test = vgui.Create("CrossEditorPanel")
test:SetTitle(test:GetTitle() .. " 4")
frame:AddDPanel(test)

//hook.Add("")

--[[
	Zoom (make crosshair bigger)
]]--
/*
local P_zoom = vgui.Create( "DPanel", frame )
P_zoom:SetPos(3, frameH - fontSize - buttonSizeYOffset - 2)
P_zoom:SetSize(frameW-6, fontSize + buttonSizeYOffset)
*/
--[[
	Add/remove layers
]]--
/*
local P_layerOptions = vgui.Create( "DPanel", frame )
P_layerOptions:SetPos(3, GetPanelY(P_zoom) - fontSize - buttonSizeYOffset - 1)
P_layerOptions:SetSize(frameW-6, fontSize + buttonSizeYOffset)


local B_addLayer = vgui.Create( "DButton", P_layerOptions )
B_addLayer:SetFont( "CrosshairDesignerMenu" )
B_addLayer:SetText( "Add layer" )
B_addLayer:SetPos( 0,0 )
B_addLayer:SetSize(P_layerOptions:GetWide()/2, P_layerOptions:GetTall())
B_addLayer.DoClick = function()
	RunConsoleCommand( "say", "Hi" )
end

local B_removeLayer = vgui.Create( "DButton", P_layerOptions )
B_removeLayer:SetFont( "CrosshairDesignerMenu" )
B_removeLayer:SetText( "Remove layer" )
B_removeLayer:SetPos( P_layerOptions:GetWide()/2,0 )
B_removeLayer:SetSize(P_layerOptions:GetWide()/2, P_layerOptions:GetTall())
B_removeLayer.DoClick = function()
	RunConsoleCommand( "say", "Hi" )
end
*/

--[[
	List of layers
]]--
/*
local P_layers = vgui.Create( "DPanel", frame )
P_layers:SetPos(3, 26 + MB_topBar:GetTall() - 2)
P_layers:SetSize(frameW-6, frameH - ((fontSize + buttonSizeYOffset)*2) - 4 - 26 - MB_topBar:GetTall()) -- button gap+height

local L_layerTitle = vgui.Create( "DLabel", P_layers )
L_layerTitle:SetPos( fontTitleSize/3, fontTitleSize/3 )
L_layerTitle:SetFont( "CrosshairDesignerMenuTitle" )
L_layerTitle:SetText( "Layers" )
L_layerTitle:SetColor( cols.title )

local SC_layers = vgui.Create( "DScrollPanel", P_layers )
SC_layers:SetPos(0, L_layerTitle:GetTall()+(fontTitleSize/2))
SC_layers:SetSize(P_layers:GetWide(), P_layers:GetTall())

for i=0, 100 do
	local DButton = SC_layers:Add( "DButton" )
	DButton:SetText( "Button #" .. i )
	DButton:Dock( TOP )
	DButton:DockMargin( 0, 0, 0, 5 )
end
*/
//CrosshairDesigner.ShowMenu = function(showMenu) frame:SetVisible(showMenu) end

//CrosshairDesigner.ShowMenu(true)
//CrosshairDesigner.MenuVisible = function() return frame.

/*
	File Settings
	Layers


	Divider between layers and selected layer options?

	Each layer also has an eye to hide it
	Clicking on layer expands it?
		Shape:
			circle
			line
			triangle
			square
			etc..
		usePositionAsOffset []
		position [x, y]
		angle []
		Normal Color (popup)
		Target Color (popup)
	Hold clicking a layer lets you move it up/down

	Hotload setting?
		select entity -> assign crosshair
		default -> fallback crosshair

	Other settings:
		Use instead of (crosshairs):
			CW 2.0
			M9K
			FA:S
			TFA

	Must add a way to load old crosshairs (backwards stuff)






local frame1 = vgui.Create( "DPanel", frame )
frame1:Dock( TOP )

local frame2 = vgui.Create( "DPanel", frame )
frame2:Dock( FILL )

// Add layer will add one below the selected, then select the new layer
*/