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
	return 1.3
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
		if not ply then
			return SPropProtection.UnOwnProp(self)
		end

		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end
		return SPropProtection.PlayerMakePropOwner(ply, self)
	end

	function entmeta:CPPISetOwnerUID(uid)
		if not uid then
			return SPropProtection.UnOwnProp(self)
		end

		local ply = player.GetByUniqueID(tostring(uid))
		if not IsValid(ply) then
			return false
		end

		return SPropProtection.PlayerMakePropOwner(ply, self)
	end

	function entmeta:CPPICanTool(ply, toolmode)
		if not IsValid(ply) or not toolmode then
			return false
		end

		local entidx = self:EntIndex()

		if not SPropProtection.KVcanuse[entidx] then SPropProtection.KVcanuse[entidx] = -1 end

		if not SPropProtection.PlayerCanTouch(ply, self) or SPropProtection.KVcantool[entidx] == 0 or (SPropProtection.KVcantool[entidx] == 1 and not ply:IsAdmin()) then
			return false
		elseif toolmode == "remover" then
			if ply:KeyDown(IN_ATTACK2) or ply:KeyDownLast(IN_ATTACK2) then
				if not SPropProtection.CheckConstraints(ply, self) then
					return false
				end
			end
		end

		return true
	end

	function entmeta:CPPICanPhysgun(ply)
		if not IsValid(ply) then
			return false
		end
		if SPropProtection.PhysGravGunPickup(ply, self) == false then
			return false
		end
		return true
	end
	entmeta.CPPICanPickup = entmeta.CPPICanPhysgun
	entmeta.CPPICanPunt = entmeta.CPPICanPhysgun

	function entmeta:CPPICanUse(ply)
		if not IsValid(ply) then
			return false
		end
		if SPropProtection.PlayerUse(ply, self) == false then
			return false
		end
		return true
	end

	function entmeta:CPPICanDamage(ply)
		if not IsValid(ply) then
			return false
		end

		if tonumber(SPropProtection.Config["edmg"]) == 0 then
			return true
		end

		return SPropProtection.PlayerCanTouch(ply, self)
	end

	function entmeta:CPPIDrive(ply)
		if not IsValid(ply) then
			return false
		end

		if SPropProtection.CanDrive(ply, self) == false then
			return false
		end

		return true
	end

	function entmeta:CPPICanProperty(ply, prop)
		if not IsValid(ply) then
			return false
		end

		if SPropProtection.CanProperty(ply, prop, self) == false then
			return false
		end

		return true
	end

	function entmeta:CPPICanEditVariable(ply, key, val, edit)
		if not IsValid(ply) then
			return false
		end

		if SPropProtection.CanEditVariable(self, ply, key, val, edit) == false then
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
