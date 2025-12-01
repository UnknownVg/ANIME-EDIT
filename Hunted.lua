--================================================================--
--                            VGXMOD HUB
--================================================================--

print("------------------------------------------------------------------")
print("Load ................................ Armor V3")
print("Load ................................ Vgxmod Hub")
print("------------------------------------------------------------------")

--================================================================--
-- LOAD LIBRARY (Vgxmod UI)
--================================================================--
local repo = "https://raw.githubusercontent.com/UnknownVg/CUSTOM-LIB/refs/heads/main/"
local success, err = pcall(function()
Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
ThemeManager = loadstring(game:HttpGet(repo .. "Add-ons/ThemeManager.lua"))()
SaveManager  = loadstring(game:HttpGet(repo .. "Add-ons/SaveManager.lua"))()
end)

if not success then
warn("Failed to load Vgxmod Hub libraries: " .. tostring(err))
return
end

local Options = Library.Options
local Toggles = Library.Toggles

--================================================================--
-- CORE SERVICES
--================================================================--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

--================================================================--
-- SHARD AUTO COLLECT SETTINGS
--================================================================--
local Collect = {
OrangeShard = { Enabled = false },
RedShard    = { Enabled = false },
Shard       = { Enabled = false }
}

local COLLECT_MAX_DISTANCE = 99999
local Cooldowns = {}

--================================================================--
-- AUTO COLLECT SHARDS SYSTEM
--================================================================--
local function isCollectTarget(obj)
if not obj or not obj.Name then return false end
local name = string.lower(obj.Name)
for targetName, config in pairs(Collect) do
if config.Enabled and string.find(name, string.lower(targetName)) then
return true
end
end
return false
end

local function instantCollect(part)
local char = LP.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return end

local root = char.HumanoidRootPart  
local dist = (part.Position - root.Position).Magnitude  
if dist > COLLECT_MAX_DISTANCE then return end  

local now = tick()  
if Cooldowns[part] and now - Cooldowns[part] < 0.1 then return end  
Cooldowns[part] = now  

firetouchinterest(root, part, 0)  
firetouchinterest(root, part, 1)

end

RunService.Heartbeat:Connect(function()
if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end

for _, obj in ipairs(Workspace:GetDescendants()) do  
    if obj:IsA("BasePart") and isCollectTarget(obj) and obj.Parent then  
        instantCollect(obj)  
    end  
end

end)

Workspace.DescendantAdded:Connect(function(obj)
if obj:IsA("BasePart") and isCollectTarget(obj) then
task.spawn(function()
instantCollect(obj)
end)
end
end)






--================================================================--
-- TP ORB
--================================================================--


local function teleportToOrb()
	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		Library:Notify({Title = "Error", Description = "No HumanoidRootPart", Time = 3})
		return
	end

	local placeId = game.PlaceId

	if placeId == 102181577519757 then
		local altar = workspace:FindFirstChild("Hotel", true)
		if altar then altar = altar.Maze.Rooms.Main.RingAltar.Parts:FindFirstChild("RingAltar") end
		if altar then
			hrp.CFrame = altar.CFrame + Vector3.new(0, 3, 0)
			Library:Notify({Title = "TP Success", Description = "Map 1 - Ring Altar", Time = 3})
			return
		end

	elseif placeId == 125591428878906 then
		hrp.CFrame = CFrame.new(-157.319611, 0.991705775, 401.749207, 0, 0, 1, 0, 1, 0, -1, 0, 0)
		Library:Notify({Title = "TP Success", Description = "Map 2 - Classic Orb", Time = 3})
		return
	end

	local statue = workspace:FindFirstChild("RingPiece", true)
	if statue then statue = statue:FindFirstChild("Statue") end

	if statue and statue:IsA("BasePart") then
		for i = 1, 2 do
			hrp.CFrame = statue.CFrame + Vector3.new(0, 10, 0)
			task.wait(0.08)
		end
		Library:Notify({Title = "TP Success", Description = "Map 3 - RingPiece Statue", Time = 3})
		return
	end

	task.spawn(function()
		local ring = workspace:WaitForChild("RingPiece", 10)
		if ring then
			local s = ring:WaitForChild("Statue", 5)
			if s then
				hrp.CFrame = s.CFrame + Vector3.new(0, 10, 0)
				Library:Notify({Title = "TP Success", Description = "Map 3 - RingPiece Statue", Time = 3})
			end
		end
	end)
end


--================================================================--
-- TP EXIT
--================================================================--
local function teleportToExit()
	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		Library:Notify({Title = "Error", Description = "No HumanoidRootPart", Time = 3})
		return
	end

	local placeId = game.PlaceId
	local portal = workspace.Portals:FindFirstChild("ExitPortal")

	if portal and portal:IsA("BasePart") then
		hrp.CFrame = portal.CFrame + Vector3.new(0, -3, 0)
		local mapName = placeId == 102181577519757 and "Map 1" or placeId == 125591428878906 and "Map 2" or "Map 3"
		Library:Notify({Title = "TP Success", Description = mapName .. " - Exit Portal", Time = 3})
		return
	end

	task.spawn(function()
		local portals = workspace:WaitForChild("Portals", 10)
		if portals then
			local p = portals:WaitForChild("ExitPortal", 5)
			if p then
				hrp.CFrame = p.CFrame + Vector3.new(0, -3, 0)
				local mapName = placeId == 102181577519757 and "Map 1" or placeId == 125591428878906 and "Map 2" or "Map 3"
				Library:Notify({Title = "TP Success", Description = mapName .. " - Exit Portal", Time = 3})
			end
		end
	end)
end






--================================================================--
-- GUI - LAYOUT
--================================================================--
local Window = Library:CreateWindow({
Title = "Vgxmod Hub",
Footer = "version: 1.7",
Icon = 94858886314945,
NotifySide = "Right",
ShowCustomCursor = true,
})




--================================================================--
-- INFO TAB
--================================================================--
local InfoTab = Window:AddTab("Info", "info")
local InfoLeft = InfoTab:AddLeftGroupbox("Credits")
local InfoRight = InfoTab:AddRightGroupbox("Discord")

InfoLeft:AddLabel("Made By: Pkgx1")
InfoLeft:AddLabel("Discord: https://discord.gg/n9gtmefsjc")
InfoLeft:AddDivider()
InfoLeft:AddLabel("You Can Request Script")
InfoLeft:AddLabel("On Discord!")
InfoLeft:AddDivider()

InfoLeft:AddLabel("Discord Link")
InfoLeft:AddButton({
    Text = "Copy",
    Func = function()
        setclipboard("https://discord.gg/n9gtmefsjc")
        Library:Notify({Title = "Copied!", Description = "Paste it on your browser", Time = 4})
    end,
})


InfoRight:AddLabel("MOBILE USER")
InfoRight:AddLabel("To Close The Menu")
InfoRight:AddLabel("Simply Click the Icon")
InfoRight:AddLabel()
InfoRight:AddLabel("PC USER")
InfoRight:AddLabel("To Close the Menu")
InfoRight:AddLabel("Just Press The CTRL")
InfoRight:AddLabel()



--================================================================--
-- TAB
--================================================================--
local MainTab     = Window:AddTab("Main", "house")
local SettingsTab = Window:AddTab("Settings", "cog")

local AutoLeft = MainTab:AddLeftGroupbox("AUTOMATION", "cpu")
local TpLeft = MainTab:AddRightGroupbox("TELEPORT", "navigation")
local ReminderLeft = MainTab:AddLeftGroupbox("Reminder", "pin")

--================================================================--
-- REMINDER
--================================================================--
ReminderLeft:AddLabel("TO AVOID CRASH OR BUG")
ReminderLeft:AddLabel("FINISH THE INTRO FIRST")
ReminderLeft:AddLabel("BEFORE AUTO COLLECT SHARD")
ReminderLeft:AddLabel("DO THIS TO ALL MAP HAVE FUN")

--================================================================--
-- AUTOMATION (MAP 1)
--================================================================--
AutoLeft:AddToggle("AutoCollect", {
Text = "Auto Collect Shards",
Default = false,
Callback = function(state)
Collect.OrangeShard.Enabled = state
Collect.RedShard.Enabled = state
Collect.Shard.Enabled = state

Library:Notify({  
        Title = "Auto Collect",  
        Description = state and "ON" or "OFF",  
        Time = 2  
    })  
end,

})
--================================================================--
-- TELEPORT SYSTEM (AUTO DETECT MAP)
--================================================================--

TpLeft:AddButton({
	Text = "TP (Orb Piece)",
	Func = teleportToOrb
})


TpLeft:AddButton({
	Text = "TP (Exit Portal)",
	Func = teleportToExit
})


--================================================================--
-- SETTINGS TAB
--================================================================--
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Vgxmod")
SaveManager:SetFolder("Vgxmod")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()
