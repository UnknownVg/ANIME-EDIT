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
-- GUI - LAYOUT
--================================================================--
local Window = Library:CreateWindow({
Title = "Vgxmod Hub",
Footer = "version: 1.7",
Icon = 94858886314945,
NotifySide = "Right",
ShowCustomCursor = true,
})

local InfoTab     = Window:AddTab("Info", "info")
local MainTab     = Window:AddTab("Main", "house")
local SettingsTab = Window:AddTab("Settings", "cog")

--================================================================--
-- INFO TAB
--================================================================--
local InfoLeft  = InfoTab:AddLeftGroupbox("Credits")
local InfoRight = InfoTab:AddRightGroupbox("Discord")

InfoLeft:AddLabel("Made By: Pkgx1")
InfoLeft:AddLabel("Discord: https://discord.gg/n9gtmefsjc")
InfoLeft:AddDivider()
InfoLeft:AddLabel("You Can Request Script")
InfoLeft:AddLabel("On Discord!")

InfoRight:AddLabel("Discord Link")
InfoRight:AddButton({
Text = "Copy",
Func = function()
setclipboard("https://discord.gg/n9gtmefsjc")
Library:Notify({Title = "Copied!", Description = "Paste it on your browser", Time = 4})
end
})

--================================================================--
-- GROUPBOXES (MAP 1)
--================================================================--
local AutoLeft      = MainTab:AddLeftGroupbox("AUTOMATION", "cpu")
local TpLeft        = MainTab:AddRightGroupbox("TELEPORT", "navigation")
local ReminderLeft  = MainTab:AddLeftGroupbox("MAP 1", "map-pin")
local ReminderRight = MainTab:AddRightGroupbox("MAP 2", "map")
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
    Text = "TP to Orb Piece",
    Func = function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Library:Notify({
                Title = "TP Failed",
                Description = "HumanoidRootPart missing!",
                Time = 3
            })
            return
        end

        ----------------------------------------------------------------
        -- MAP 1 DETECTION
        ----------------------------------------------------------------
        local map1Exists = workspace:FindFirstChild("Hotel")
        if map1Exists then
            local altar
            pcall(function()
                altar = workspace.Hotel.Maze.Rooms.Main.RingAltar.Parts:FindFirstChild("RingAltar")
            end)

            if altar and altar:IsA("BasePart") then
                hrp.CFrame = altar.CFrame + Vector3.new(0, 2, 0)

                Library:Notify({
                    Title = "TP Success",
                    Description = "Teleported to Map 1 Ring Altar!",
                    Time = 3
                })
                return
            end
        end

        ----------------------------------------------------------------
        -- MAP 2 POSITION (your exact CFrame)
        ----------------------------------------------------------------
        local map2CFrame = CFrame.new(
            -157.319611, 0.991705775, 401.749207,
             0, 0, 1,
             0, 1, 0,
            -1, 0, 0
        )

        hrp.CFrame = map2CFrame

        Library:Notify({
            Title = "TP Success",
            Description = "Teleported to Map 2 Orb Piece!",
            Time = 3
        })
    end,
})



--================================================================--
-- REMINDER
--================================================================--
ReminderLeft:AddLabel("To Avoid Crash Or Bug")
ReminderLeft:AddLabel("Before Turn On The Auto Shards")
ReminderLeft:AddLabel("Make Sure The Tutorial Is Already")
ReminderLeft:AddLabel("Finish Yapping or Simply Skipp.")

--================================================================--
-- REMINDER2
--================================================================--
ReminderRight:AddLabel("To Avoid Crash Or Bug")
ReminderRight:AddLabel("Before Turn On The Auto Shards")
ReminderRight:AddLabel("Make Sure You Open The Door First")
ReminderRight:AddLabel("And Finish The Animation.")
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
