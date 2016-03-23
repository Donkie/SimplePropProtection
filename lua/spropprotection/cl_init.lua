------------------------------------
--	Simple Prop Protection
--	By Spacetech, Maintained by Donkie
-- 	https://github.com/Donkie/SimplePropProtection
------------------------------------

SPropProtection.AdminCPanel = nil
SPropProtection.ClientCPanel = nil

CreateClientConVar("spp_check", 1, false, true)
CreateClientConVar("spp_admin", 1, false, true)
CreateClientConVar("spp_use", 1, false, true)
CreateClientConVar("spp_edmg", 1, false, true)
CreateClientConVar("spp_pgr", 1, false, true)
CreateClientConVar("spp_awp", 1, false, true)
CreateClientConVar("spp_dpd", 1, false, true)
CreateClientConVar("spp_dae", 0, false, true)
CreateClientConVar("spp_delay", 120, false, true)

function SPropProtection.HUDPaint()
	if not IsValid(LocalPlayer()) then
		return
	end
	local tr = util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
	if tr.HitNonWorld then
		if IsValid(tr.Entity) and not tr.Entity:IsPlayer() and not LocalPlayer():InVehicle() then
			local PropOwner = "Owner: "
			local OwnerObj = tr.Entity:GetNWEntity("OwnerObj", false)
			if IsValid(OwnerObj) and OwnerObj:IsPlayer() then
				PropOwner = PropOwner .. OwnerObj:Name()
			else
				OwnerObj = tr.Entity:GetNWString("Owner", "N/A")
				if type(OwnerObj) == "string" then
					PropOwner = PropOwner .. OwnerObj
				elseif IsValid(OwnerObj) and OwnerObj:IsPlayer() then
					PropOwner = PropOwner .. OwnerObj:Name()
				else
					PropOwner = PropOwner .. "N/A"
				end
			end
			surface.SetFont("Default")
			local w, h = surface.GetTextSize(PropOwner)
			w = w + 25
			draw.RoundedBox(4, ScrW() - (w + 8), (ScrH() / 2 - 200) - (8), w + 8, h + 8, Color(0, 0, 0, 150))
			draw.SimpleText(PropOwner, "Default", ScrW() - (w / 2) - 7, ScrH() / 2 - 200, Color(255, 255, 255, 255), 1, 1)
		end
	end
end
hook.Add("HUDPaint", "SPropProtection.HUDPaint", SPropProtection.HUDPaint)

function SPropProtection.AdminPanel(Panel)
	Panel:ClearControls()

	if not LocalPlayer():IsAdmin() then
		Panel:AddControl("Label", {Text = "You are not an admin"})
		return
	end

	if not SPropProtection.AdminCPanel then
		SPropProtection.AdminCPanel = Panel
	end

	Panel:AddControl("Label", {Text = "SPP - Admin Panel - Spacetech"})

	Panel:AddControl("CheckBox", {Label = "Prop Protection", Command = "spp_check"})
	Panel:AddControl("CheckBox", {Label = "Admins Can Do Everything", Command = "spp_admin"})
	Panel:AddControl("CheckBox", {Label = "+Use Protection", Command = "spp_use"})
	Panel:AddControl("CheckBox", {Label = "Entity Damage Protection", Command = "spp_edmg"})
	Panel:AddControl("CheckBox", {Label = "Physgun Reload Protection", Command = "spp_pgr"})
	Panel:AddControl("CheckBox", {Label = "Admins Can Touch World Prop", Command = "spp_awp"})
	Panel:AddControl("CheckBox", {Label = "Disconnect Prop Deletion", Command = "spp_dpd"})
	Panel:AddControl("CheckBox", {Label = "Delete Admin Entities", Command = "spp_dae"})
	Panel:AddControl("Slider", {Label = "Deletion Delay (Seconds)", Command = "spp_delay", Type = "Integer", Min = "10", Max = "500"})
	Panel:AddControl("Button", {Text = "Apply Settings", Command = "spp_apply"})

	Panel:AddControl("Label", {Text = "Cleanup Panel"})

	for k, ply in pairs(player.GetAll()) do
		if IsValid(ply) then
			Panel:AddControl("Button", {Text = ply:Nick(), Command = "spp_cleanupprops " .. ply:EntIndex()})
		end
	end

	Panel:AddControl("Label", {Text = "Other Cleanup Options"})
	Panel:AddControl("Button", {Text = "Cleanup Disconnected Players Props", Command = "spp_cdp"})
end

function SPropProtection.ClientPanel(Panel)
	Panel:ClearControls()

	if not SPropProtection.ClientCPanel then
		SPropProtection.ClientCPanel = Panel
	end

	Panel:AddControl("Label", {Text = "SPP - Client Panel - Spacetech"})

	Panel:AddControl("Button", {Text = "Cleanup Props", Command = "spp_cleanupprops"})
	Panel:AddControl("Label", {Text = "Friends Panel"})

	local Players = player.GetAll()
	if table.Count(Players) == 1 then
		Panel:AddControl("Label", {Text = "No Other Players Are Online"})
	else
		for k, ply in pairs(Players) do
			if IsValid(ply) and ply != LocalPlayer() then
				local FriendCommand = "spp_friend_" .. ply:GetNWString("SPPSteamID")
				if not LocalPlayer():GetInfo(FriendCommand) then
					CreateClientConVar(FriendCommand, 0, false, true)
				end
				Panel:AddControl("CheckBox", {Label = ply:Nick(), Command = FriendCommand})
			end
		end
		Panel:AddControl("Button", {Text = "Apply Settings", Command = "spp_applyfriends"})
	end
	Panel:AddControl("Button", {Text = "Clear Friends", Command = "spp_clearfriends"})
end

function SPropProtection.SpawnMenuOpen()
	if IsValid(SPropProtection.AdminCPanel) then
		SPropProtection.AdminPanel(SPropProtection.AdminCPanel)
	end
	
	if IsValid(SPropProtection.ClientCPanel) then
		SPropProtection.ClientPanel(SPropProtection.ClientCPanel)
	end
end
hook.Add("SpawnMenuOpen", "SPropProtection.SpawnMenuOpen", SPropProtection.SpawnMenuOpen)

function SPropProtection.PopulateToolMenu()
	spawnmenu.AddToolMenuOption("Utilities", "Simple Prop Protection", "Admin", "Admin", "", "", SPropProtection.AdminPanel)
	spawnmenu.AddToolMenuOption("Utilities", "Simple Prop Protection", "Client", "Client", "", "", SPropProtection.ClientPanel)
end
hook.Add("PopulateToolMenu", "SPropProtection.PopulateToolMenu", SPropProtection.PopulateToolMenu)

net.Receive("spp_notify", function()
	local msg = net.ReadString()

	GAMEMODE:AddNotify(msg, NOTIFY_GENERIC, 5)
	surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
end)
