------------------------------------
--	Simple Prop Protection
--	By Spacetech, Maintained by Donkie
-- 	https://github.com/Donkie/SimplePropProtection
------------------------------------

AddCSLuaFile("autorun/sh_spropprotection.lua")
AddCSLuaFile("spropprotection/cl_init.lua")
AddCSLuaFile("spropprotection/sh_cppi.lua")

SPropProtection = {}
SPropProtection.Version = 1.7

CPPI = {}
CPPI_NOTIMPLEMENTED = 26
CPPI_DEFER = 16

include("spropprotection/sh_cppi.lua")

if SERVER then
	include("spropprotection/sv_init.lua")
else
	include("spropprotection/cl_init.lua")
end

Msg("==========================================================\n")
Msg("Simple Prop Protection Version " .. SPropProtection.Version .. " by Spacetech has loaded\n")
Msg("==========================================================\n")
