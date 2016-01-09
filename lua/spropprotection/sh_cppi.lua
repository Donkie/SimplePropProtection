------------------------------------
--	Simple Prop Protection
--	By Spacetech, Maintained by Donkie
-- 	https://github.com/Donkie/SimplePropProtection
------------------------------------

function CPPI:GetName()
	return "Simple Prop Protection"
end

function CPPI:GetVersion()
	return SPropProtection.Version
end

function CPPI:GetInterfaceVersion()
	return 1.1
end

function CPPI:GetNameFromUID(uid)
	return CPPI_NOTIMPLEMENTED
end

local plymeta = FindMetaTable("Player")
if not plymeta then
	error("Couldn't find Player metatable")
	return
end

function plymeta:CPPIGetFriends()
	if SERVER then
		local Table = {}
		for k, v in pairs(player.GetAll()) do
			if table.HasValue(SPropProtection[self:SteamID()], v:SteamID()) then
				table.insert(Table, v)
			end
		end
		return Table
	else
		return CPPI_NOTIMPLEMENTED
	end
end

local entmeta = FindMetaTable("Entity")
if not entmeta then
	print("Couldn't find Entity metatable")
	return
end

function entmeta:CPPIGetOwner()
	if self.SPPOwnerless then
		return true, CPPI_NOTIMPLEMENTED
	end

	local ply = self:GetNWEntity("OwnerObj", false)

	if SERVER then
		if SPropProtection.Props[self:EntIndex()] then
			ply = SPropProtection.Props[self:EntIndex()].Owner
		end
	end

	if not IsValid(ply) then
		return nil, CPPI_NOTIMPLEMENTED
	end

	local UID = CPPI_NOTIMPLEMENTED

	if SERVER then
		UID = ply:UniqueID()
	end

	return ply, UID
end

if SERVER then
	function entmeta:CPPISetOwner(ply)
		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end
		return SPropProtection.PlayerMakePropOwner(ply, self)
	end

	function entmeta:CPPISetOwnerless(Bool)
		self.SPPOwnerless = Bool
		if Bool then
			self:SetNWString("Owner", "Ownerless")
			self:SetNWEntity("OwnerObj", GetWorldEntity())
		else
			self:SetNWString("Owner", "N/A")
		end
	end

	function entmeta:CPPISetOwnerUID(uid)
		if not uid then
			return false
		end

		local ply = player.GetByUniqueID(tostring(uid))
		if not ply then
			return false
		end

		return SPropProtection.PlayerMakePropOwner(ply, self)
	end

	function entmeta:CPPICanTool(ply, toolmode)
		if not IsValid(ply) or not ply:IsPlayer() or not toolmode then
			return false
		end
		return SPropProtection.PlayerCanTouch(ply, self)
	end

	function entmeta:CPPICanPhysgun(ply)
		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end
		if SPropProtection.PhysGravGunPickup(ply, self) == false then
			return false
		end
		return true
	end

	function entmeta:CPPICanPickup(ply)
		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end
		if SPropProtection.PhysGravGunPickup(ply, self) == false then
			return false
		end
		return true
	end

	function entmeta:CPPICanPunt(ply)
		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end
		if SPropProtection.PhysGravGunPickup(ply, self) == false then
			return false
		end
		return true
	end
end

local function CPPIInitGM()
	function GAMEMODE:CPPIAssignOwnership(ply, ent)
	end
	function GAMEMODE:CPPIFriendsChanged(ply, ent)
	end
end
hook.Add("Initialize", "CPPIInitGM", CPPIInitGM)
