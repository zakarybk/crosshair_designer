if SERVER then	
	AddCSLuaFile("crosshair-designer/load.lua")
	include("crosshair-designer/load.lua")
else
	include("crosshair-designer/load.lua")
end

CreateConVar(
	"CrosshairDesigner_AllowAuthorDebug",
	1,
	{FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_ARCHIVE}, 
	"Allow Zak (STEAM_0:1:50714411) special permissions to use debug commands in the Crosshair Designer addon (completely client side)"
)