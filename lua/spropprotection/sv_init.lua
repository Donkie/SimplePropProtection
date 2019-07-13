------------------------------------
--	Simple Prop Protection
--	By Spacetech, Maintained by Donkie
-- 	https://github.com/Donkie/SimplePropProtection
------------------------------------

SPropProtection.Props = {}

function SPropProtection.SetupSettings()
	if not sql.TableExists("spropprotection") then
		sql.Query("CREATE TABLE IF NOT EXISTS spropprotection(toggle INTEGER NOT NULL, admin INTEGER NOT NULL, use INTEGER NOT NULL, edmg INTEGER NOT NULL, pgr INTEGER NOT NULL, awp INTEGER NOT NULL, dpd INTEGER NOT NULL, dae INTEGER NOT NULL, delay INTEGER NOT NULL);")
		sql.Query("CREATE TABLE IF NOT EXISTS spropprotectionfriends(steamid TEXT NOT NULL PRIMARY KEY, bsteamid TEXT);")
		sql.Query("INSERT INTO spropprotection(toggle, admin, use, edmg, pgr, awp, dpd, dae, delay) VALUES(1, 1, 1, 1, 1, 1, 1, 0, 120)")
	end
	return sql.QueryRow("SELECT * FROM spropprotection LIMIT 1")
end

SPropProtection.Config = SPropProtection.SetupSettings()

function SPropProtection.EscapeNotify(str) return str end -- Backwards compatibility

function SPropProtection.NotifyAll(str)
	for _,v in pairs(player.GetAll()) do
		SPropProtection.Notify(v, str)
	end
	MsgN(str)
end
SPropProtection.NofityAll = SPropProtection.NotifyAll -- Backwards compatibility

util.AddNetworkString("spp_notify")
function SPropProtection.Notify(ply, str)
	net.Start("spp_notify")
		net.WriteString(str)
	net.Send(ply)

	ply:PrintMessage(HUD_PRINTCONSOLE, str)
end
SPropProtection.Nofity = SPropProtection.Notify -- Backwards compatibility

function SPropProtection.AdminReloadPlayer(ply)
	if not IsValid(ply) then
		return
	end
	for k,v in pairs(SPropProtection.Config) do
		local stuff = k
		if stuff == "toggle" then
			stuff = "check"
		end
		ply:ConCommand("spp_" .. stuff .. " " .. v .. "\n")
	end
end

function SPropProtection.AdminReload(ply)
	if ply then
		SPropProtection.AdminReloadPlayer(ply)
	else
		for k,v in pairs(player.GetAll()) do
			SPropProtection.AdminReloadPlayer(v)
		end
	end
end

function SPropProtection.LoadFriends(ply)
	local PData = ply:GetPData("SPPFriends", "")
	if PData != "" then
		for k,v in pairs(string.Explode(";", PData)) do
			local String = string.Trim(v)
			if String != "" then
				table.insert(SPropProtection[ply:SteamID()], String)
			end
		end
	end

	SPropProtection.NotifyFriendChange(ply)
end

function SPropProtection.UnOwnProp(ent)
	if not IsValid(ent) then return false end

	SPropProtection.Props[ent:EntIndex()] = nil
	ent:SetNWString("Owner", nil)
	ent:SetNWEntity("OwnerObj", nil)

	return true
end

function SPropProtection.PlayerMakePropOwner(ply, ent)
	if ent:IsPlayer() then
		return false
	end

	local ret = hook.Run("CPPIAssignOwnership", ply, ent, ply:UniqueID())
	if ret == false then return end

	SPropProtection.Props[ent:EntIndex()] = {
		Ent = ent,
		Owner = ply,
		SteamID = ply:SteamID()
	}
	ent:SetNWString("Owner", ply:Nick())
	ent:SetNWEntity("OwnerObj", ply)

	return true
end

if cleanup then
	local Clean = cleanup.Add
	function cleanup.Add(ply, Type, ent)
		if ent then
			if ply:IsPlayer() and IsValid(ent) then
				SPropProtection.PlayerMakePropOwner(ply, ent)
			end
		end
		Clean(ply, Type, ent)
	end
end

local plymeta = FindMetaTable("Player")
if plymeta.AddCount then
	local Backup = plymeta.AddCount
	function plymeta:AddCount(Type, ent)
		SPropProtection.PlayerMakePropOwner(self, ent)
		Backup(self, Type, ent)
	end
end

function SPropProtection.CheckConstraints(ply, ent)
	for k,v in pairs(constraint.GetAllConstrainedEntities(ent) or {}) do
		if IsValid(v) then
			if not SPropProtection.PlayerCanTouch(ply, v) then
				return false
			end
		end
	end
	return true
end

function SPropProtection.IsFriend(ply, ent)
	local plys = player.GetAll()

	if #plys == 1 then
		return true
	end
	for k,v in pairs(plys) do
		if v != ply then
			if SPropProtection.Props[ent:EntIndex()].SteamID == v:SteamID() then
				if SPropProtection[v:SteamID()] and table.HasValue(SPropProtection[v:SteamID()], ply:SteamID()) then
					return true
				else
					return false
				end
			end
		end
	end
end

function SPropProtection.PlayerCanTouch(ply, ent)
	if tonumber(SPropProtection.Config["toggle"]) == 0 or ent:GetClass() == "worldspawn" then
		return true
	end

	if not ent:GetNWString("Owner") or ent:GetNWString("Owner") == "" and not ent:IsPlayer() then
		SPropProtection.PlayerMakePropOwner(ply, ent)
		SPropProtection.Notify(ply, "You now own this prop")
		return true
	end

	if ent:GetNWString("Owner") == "World" then
		if ply:IsAdmin() and tonumber(SPropProtection.Config["awp"]) == 1 and tonumber(SPropProtection.Config["admin"]) == 1 then
			return true
		end
	elseif ply:IsAdmin() and tonumber(SPropProtection.Config["admin"]) == 1 then
		return true
	end

	if SPropProtection.Props[ent:EntIndex()] then
		if SPropProtection.Props[ent:EntIndex()].SteamID == ply:SteamID() or SPropProtection.IsFriend(ply, ent) then
			return true
		end
	end
	return false
end

function SPropProtection.DRemove(SteamID, PlayerName)
	for k,v in pairs(SPropProtection.Props) do
		if IsValid(v.Ent) and v.SteamID == SteamID then
			v.Ent:Remove()
			SPropProtection.Props[k] = nil
		end
	end
	SPropProtection.NotifyAll(tostring(PlayerName) .. "'s props have been cleaned up")
end

function SPropProtection.PlayerInitialSpawn(ply)
	ply:SetNWString("SPPSteamID", string.gsub(ply:SteamID(), ":", "_"))
	SPropProtection[ply:SteamID()] = {}
	SPropProtection.LoadFriends(ply)
	SPropProtection.AdminReload(ply)
	local TimerName = "SPropProtection.DRemove: " .. ply:SteamID()
	if timer.Exists(TimerName) then
		timer.Remove(TimerName)
	end
end
hook.Add("PlayerInitialSpawn", "SPropProtection.PlayerInitialSpawn", SPropProtection.PlayerInitialSpawn)

function SPropProtection.Disconnect(ply)
	if tonumber(SPropProtection.Config["dpd"]) == 1 then
		if ply:IsAdmin() and tonumber(SPropProtection.Config["dae"]) == 0 then
			return
		end

		local sid = ply:SteamID()
		local nick = ply:Nick()
		timer.Create("SPropProtection.DRemove: " .. sid, tonumber(SPropProtection.Config["delay"]), 1,
			function()
				SPropProtection.DRemove(sid, nick)
			end)
	end
end
hook.Add("PlayerDisconnected", "SPropProtection.Disconnect", SPropProtection.Disconnect)

function SPropProtection.PhysGravGunPickup(ply, ent)
	if not IsValid(ent) then
		return
	end
	if not SPropProtection.KVcanuse[ent:EntIndex()] then SPropProtection.KVcanuse[ent:EntIndex()] = -1 end
	if SPropProtection.KVcantouch[ent:EntIndex()] == 0 then
		return false
	end
	if SPropProtection.KVcantouch[ent:EntIndex()] == 2 or (SPropProtection.KVcantouch[ent:EntIndex()] == 1 and ply:IsAdmin()) then
		return
	end
	if ent:IsPlayer() and ply:IsAdmin() and tonumber(SPropProtection.Config["admin"]) == 1 then
		return
	end
	if not SPropProtection.PlayerCanTouch(ply, ent) then
		return false
	end
end
hook.Add("GravGunPunt", "SPropProtection.GravGunPunt", SPropProtection.PhysGravGunPickup)
hook.Add("GravGunPickupAllowed", "SPropProtection.GravGunPickupAllowed", SPropProtection.PhysGravGunPickup)
hook.Add("PhysgunPickup", "SPropProtection.PhysgunPickup", SPropProtection.PhysGravGunPickup)

function SPropProtection.CanTool(ply, tr, mode)
	if tr.HitWorld then
		return
	end
	local ent = tr.Entity
	if not IsValid(ent) or ent:IsPlayer() then
		return false
	end

	if not SPropProtection.KVcanuse[ent:EntIndex()] then SPropProtection.KVcanuse[ent:EntIndex()] = -1 end

	if not SPropProtection.PlayerCanTouch(ply, ent) or SPropProtection.KVcantool[ent:EntIndex()] == 0 or (SPropProtection.KVcantool[ent:EntIndex()] == 1 and not ply:IsAdmin()) then
		return false
	elseif mode == "remover" then
		if ply:KeyDown(IN_ATTACK2) or ply:KeyDownLast(IN_ATTACK2) then
			if not SPropProtection.CheckConstraints(ply, ent) then
				return false
			end
		end
	end
end
hook.Add("CanTool", "SPropProtection.CanTool", SPropProtection.CanTool)

function SPropProtection.EntityTakeDamageFireCheck(ent)
	if not IsValid(ent) then
		return
	end
	if ent:IsOnFire() then
		ent:Extinguish()
	end
end

function SPropProtection.EntityTakeDamage(ent, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if tonumber(SPropProtection.Config["edmg"]) == 0 then
		return
	end
	if not IsValid(ent) or ent:IsPlayer() or not attacker:IsPlayer() then
		return
	end
	if not SPropProtection.PlayerCanTouch(attacker, ent) then
		dmginfo:SetDamage(0)
		timer.Simple(0.1,
			function()
				if IsValid(ent) then SPropProtection.EntityTakeDamageFireCheck(ent) end
			end)
	end
end
hook.Add("EntityTakeDamage", "SPropProtection.EntityTakeDamage", SPropProtection.EntityTakeDamage)

function SPropProtection.PlayerUse(ply, ent)
	if not SPropProtection.KVcanuse[ent:EntIndex()] then SPropProtection.KVcanuse[ent:EntIndex()] = -1 end
	if SPropProtection.KVcanuse[ent:EntIndex()] == 0 or (SPropProtection.KVcantouch[ent:EntIndex()] == 1 and not ply:IsAdmin()) then
		return false
	end
	if SPropProtection.KVcanuse[ent:EntIndex()] == 2 then
		return
	end
	if IsValid(ent) and tonumber(SPropProtection.Config["use"]) == 1 then
		if not SPropProtection.PlayerCanTouch(ply, ent) and ent:GetNWString("Owner") != "World" then
			return false
		end
	end
end
hook.Add("PlayerUse", "SPropProtection.PlayerUse", SPropProtection.PlayerUse)

function SPropProtection.OnPhysgunReload(weapon, ply)
	if tonumber(SPropProtection.Config["pgr"]) == 0 then
		return
	end
	local tr = util.TraceLine(util.GetPlayerTrace(ply))
	if not tr.HitNonWorld or not IsValid(tr.Entity) or tr.Entity:IsPlayer() then
		return
	end
	if not SPropProtection.PlayerCanTouch(ply, tr.Entity) then
		return false
	end
end
hook.Add("OnPhysgunReload", "SPropProtection.OnPhysgunReload", SPropProtection.OnPhysgunReload)

function SPropProtection.EntityRemoved(ent)
	SPropProtection.Props[ent:EntIndex()] = nil
end
hook.Add("EntityRemoved", "SPropProtection.EntityRemoved", SPropProtection.EntityRemoved)

function SPropProtection.PlayerSpawnedSENT(ply, ent)
	SPropProtection.PlayerMakePropOwner(ply, ent)
end
hook.Add("PlayerSpawnedSENT", "SPropProtection.PlayerSpawnedSENT", SPropProtection.PlayerSpawnedSENT)

function SPropProtection.PlayerSpawnedVehicle(ply, ent)
	SPropProtection.PlayerMakePropOwner(ply, ent)
end
hook.Add("PlayerSpawnedVehicle", "SPropProtection.PlayerSpawnedVehicle", SPropProtection.PlayerSpawnedVehicle)

--Thanks to TP Hunter NL for these two hooks
--Causes ragdolls and weapons dropped by NPCs to be owned by the NPC's owner.
function SPropProtection.NPCCreatedRagdoll(npc,doll)
	if SPropProtection.Props[npc:EntIndex()] and not SPropProtection.Props[doll:EntIndex()] and IsValid(SPropProtection.Props[npc:EntIndex()].Owner) then
		SPropProtection.PlayerMakePropOwner(SPropProtection.Props[npc:EntIndex()].Owner,doll)
	end
end
hook.Add("CreateEntityRagdoll","SPropProtection.NPCCreatedRagdoll",SPropProtection.NPCCreatedRagdoll)

function SPropProtection.NPCDeath(npc,attacker,weapon)
	if not IsValid(npc:GetActiveWeapon()) then return end
	if SPropProtection.Props[npc:EntIndex()] and not SPropProtection.Props[npc:GetActiveWeapon():EntIndex()] and IsValid(SPropProtection.Props[npc:EntIndex()].Owner) then
		SPropProtection.PlayerMakePropOwner(SPropProtection.Props[npc:EntIndex()].Owner,npc:GetActiveWeapon())
	end
end
hook.Add("OnNPCKilled","SPropProtection.NPCDeath",SPropProtection.NPCDeath)

function SPropProtection.CDP(ply, cmd, args)
	if IsValid(ply) and not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You are not an admin!" )
		return
	end
	for k,v in pairs(SPropProtection.Props) do
		local Found = false
		for k2,v2 in pairs(player.GetAll()) do
			if v.SteamID == v2:SteamID() then
				Found = true
			end
		end
		if not Found then
			local Ent = v.Ent
			if IsValid(Ent) then
				Ent:Remove()
			end
			SPropProtection.Props[k] = nil
		end
	end
	SPropProtection.NotifyAll("Disconnected players props have been cleaned up")
end
concommand.Add("spp_cdp", SPropProtection.CDP)

function SPropProtection.CleanupPlayerProps(ply)
	for k,v in pairs(SPropProtection.Props) do
		if v.SteamID == ply:SteamID() then
			local Ent = v.Ent
			if IsValid(Ent) then
				Ent:Remove()
			end
			SPropProtection.Props[k] = nil
		end
	end
end

function SPropProtection.CleanupProps(ply, cmd, args)
	local EntIndex = args[1]
	if not EntIndex or EntIndex == "" then
		if not IsValid(ply) then
			MsgN("usage: spp_cleanupprops <entity_id>")
			return
		end
		SPropProtection.CleanupPlayerProps(ply)
		SPropProtection.Notify(ply, "Your props have been cleaned up")
	elseif not IsValid(ply) or ply:IsAdmin() then
		for k,v in pairs(player.GetAll()) do
			if tonumber(EntIndex) == v:EntIndex() then
				SPropProtection.CleanupPlayerProps(v)
				SPropProtection.NotifyAll(v:Nick() .. "'s props have been cleaned up")
			end
		end
	else
		ply:PrintMessage( HUD_PRINTCONSOLE, "You are not an admin!" )
	end
end
concommand.Add("spp_cleanupprops", SPropProtection.CleanupProps)

function SPropProtection.NotifyFriendChange(ply)
	local Table = {}
	for k,v in pairs(SPropProtection[ply:SteamID()]) do
		for k2,v2 in pairs(player.GetAll()) do
			if v == v2:SteamID() then
				table.insert(Table, v2)
				break
			end
		end
	end
	hook.Run("CPPIFriendsChanged", ply, Table)
end

function SPropProtection.ApplyFriends(ply, cmd, args)
	if not IsValid(ply) then
		MsgN("This command can only be run in-game!")
		return
	end

	local plys = player.GetAll()
	if #plys > 1 then
		local ChangedFriends = false
		for k,v in pairs(plys) do
			local PlayersSteamID = v:SteamID()
			local PData = ply:GetPData("SPPFriends", "")
			if tonumber(ply:GetInfo("spp_friend_" .. v:GetNWString("SPPSteamID"))) == 1 then
				if not table.HasValue(SPropProtection[ply:SteamID()], PlayersSteamID) then
					ChangedFriends = true
					table.insert(SPropProtection[ply:SteamID()], PlayersSteamID)
					if PData == "" then
						ply:SetPData("SPPFriends", PlayersSteamID .. ";")
					else
						ply:SetPData("SPPFriends", PData .. PlayersSteamID .. ";")
					end
				end
			else
				if table.HasValue(SPropProtection[ply:SteamID()], PlayersSteamID) then
					for k2,v2 in pairs(SPropProtection[ply:SteamID()]) do
						if v2 == PlayersSteamID then
							ChangedFriends = true
							table.remove(SPropProtection[ply:SteamID()], k2)
							ply:SetPData("SPPFriends", string.gsub(PData, PlayersSteamID .. ";", ""))
						end
					end
				end
			end
		end
		if ChangedFriends then
			SPropProtection.NotifyFriendChange(ply)
		end
	end
	SPropProtection.Notify(ply, "Your friends have been updated")
end
concommand.Add("spp_applyfriends", SPropProtection.ApplyFriends)

function SPropProtection.ClearFriends(ply, cmd, args)
	if not IsValid(ply) then
		MsgN("This command can only be run in-game!")
		return
	end

	local PData = ply:GetPData("SPPFriends", "")
	if PData != "" then
		for k,v in pairs(string.Explode(";", PData)) do
			local String = string.Trim(v)
			if String != "" then
				ply:ConCommand("spp_friend_" .. string.gsub(String, ":", "_") .. " 0\n")
			end
		end
		ply:SetPData("SPPFriends", "")
	end
	if SPropProtection[ply:SteamID()] then
		for k,v in pairs(SPropProtection[ply:SteamID()]) do
			ply:ConCommand("spp_friend_" .. string.gsub(v, ":", "_") .. " 0\n")
		end
	end
	SPropProtection[ply:SteamID()] = {}
	SPropProtection.Notify(ply, "Your friends have been cleared")
end
concommand.Add("spp_clearfriends", SPropProtection.ClearFriends)

function SPropProtection.ApplySettings(ply, cmd, args)
	if not IsValid(ply) then
		MsgN("This command can only be run in-game!")
		return
	end
	if not ply:IsAdmin() then
		return
	end

	local toggle = tonumber(ply:GetInfo("spp_check") or 1)
	local admin = tonumber(ply:GetInfo("spp_admin") or 1)
	local use = tonumber(ply:GetInfo("spp_use") or 1)
	local edmg = tonumber(ply:GetInfo("spp_edmg") or 1)
	local pgr = tonumber(ply:GetInfo("spp_pgr") or 1)
	local awp = tonumber(ply:GetInfo("spp_awp") or 1)
	local dpd = tonumber(ply:GetInfo("spp_dpd") or 1)
	local dae = tonumber(ply:GetInfo("spp_dae") or 1)
	local delay = math.Clamp(tonumber(ply:GetInfo("spp_delay") or 120), 1, 500)

	sql.Query("UPDATE spropprotection SET toggle = " .. toggle .. ", admin = " .. admin .. ", use = " .. use .. ", edmg = " .. edmg .. ", pgr = " .. pgr .. ", awp = " .. awp .. ", dpd = " .. dpd .. ", dae = " .. dae .. ", delay = " .. delay)

	SPropProtection.Config = sql.QueryRow("SELECT * FROM spropprotection LIMIT 1")

	timer.Simple(2, SPropProtection.AdminReload)

	SPropProtection.Notify(ply, "Admin settings have been updated")
end
concommand.Add("spp_apply", SPropProtection.ApplySettings)

function SPropProtection.WorldOwner()
	local WorldEnts = 0
	for k,v in pairs(ents.FindByClass("*")) do
		if not v:IsPlayer() and not v:GetNWString("Owner", false) then
			v:SetNWString("Owner", "World")
			WorldEnts = WorldEnts + 1
		end
	end
	MsgN("=================================================")
	MsgN("Simple Prop Protection: " .. tostring(WorldEnts) .. " props belong to world")
	MsgN("=================================================")
end
timer.Simple(2, SPropProtection.WorldOwner)

/*
Gmod 13 support
*/
function SPropProtection.CanEditVariable( ent, ply, key, val, editor )
	if not SPropProtection.PlayerCanTouch(ply, ent) then return false end
end
hook.Add("CanEditVariable", "SPropProtection.CanEditVariable", SPropProtection.CanEditVariable)

function SPropProtection.AllowPlayerPickup( ply, ent )
	if not SPropProtection.PlayerCanTouch(ply, ent) then return false end
end
hook.Add("AllowPlayerPickup", "SPropProtection.AllowPlayerPickup", SPropProtection.AllowPlayerPickup)

function SPropProtection.CanDrive( ply, ent )
	if not SPropProtection.PlayerCanTouch(ply, ent) then return false end
	if ent:GetNWString("Owner") == "World" then return false end
end
hook.Add("CanDrive", "SPropProtection.CanDrive", SPropProtection.CanDrive)

function SPropProtection.CanProperty( ply, property, ent )
	if not SPropProtection.PlayerCanTouch(ply, ent) then return false end
	if ent:GetNWString("Owner") == "World" then return false end
end
hook.Add("CanProperty", "SPropProtection.CanProperty", SPropProtection.CanProperty)



-- Modification allowing mappers to add keyvalues to entites that will override settings of spp
-- so setting spp_canuse to 2 in some entity would make it possible for everyone to use it.
--
-- Author: Sebi

SPropProtection.KVcantouch = {}
SPropProtection.KVcanuse = {}
SPropProtection.KVcantool = {}

function SPropProtection.CheckKeyvalue( ent, key, val )
	if not IsValid(ent) then return end
	if val == nil then return end

	if key == "spp_cantouch" then
		SPropProtection.KVcantouch[ ent:EntIndex() ] = tonumber(val)
	elseif key == "spp_canuse" then
		SPropProtection.KVcanuse[ ent:EntIndex() ] = tonumber(val)
	elseif key == "spp_cantool" then
		SPropProtection.KVcantool[ ent:EntIndex() ] = tonumber(val)
	end
end

hook.Add( "EntityKeyValue", "SPropProtection.CheckKeyvalue", SPropProtection.CheckKeyvalue )