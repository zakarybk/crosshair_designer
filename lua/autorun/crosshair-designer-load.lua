if SERVER then
	AddCSLuaFile("load.lua")
	include("load.lua")
else
	include("load.lua")
end