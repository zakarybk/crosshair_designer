CrosshairDesigner = CrosshairDesigner or {}

if SERVER then
	AddCSLuaFile("fonts.lua")
	AddCSLuaFile("db.lua")
	AddCSLuaFile("draw.lua")
	AddCSLuaFile("menu.lua")
else
	include("fonts.lua")
	include("db.lua")
	include("draw.lua")
	include("menu.lua")
end