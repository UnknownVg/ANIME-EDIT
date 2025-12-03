--================================================================--
--                             VGXMOD HUB
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
local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local LP            = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--================================================================--
-- ESP SYSTEM 
--================================================================--
local ESPEnabled = false

local OBJECT_NAME   = "Ore"
local ESP_COLOR     = Color3.fromRGB(0, 255, 255)
local MAX_DISTANCE  = 1500
local TARGET_FOLDER = Workspace.Items

local Tracked = {}

local function isTarget(obj)
    if not obj or not obj.Name then return false end
    return obj.Name:lower():find(OBJECT_NAME:lower())
end

local function getRoot(obj)
    if obj:IsA("BasePart") then
        return obj
    end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function track(obj)
    if isTarget(obj) then
        local root = getRoot(obj)
        if root then
            Tracked[obj] = true
        end
    end
end

local function untrack(obj)
    Tracked[obj] = nil
    local root = getRoot(obj)
    if not root then return end
    local hl = root:FindFirstChild("OBJ_ESP_HL")
    if hl then hl:Destroy() end
    local bb = root:FindFirstChild("OBJ_ESP_BILLBOARD")
    if bb then bb:Destroy() end
end

for _, obj in ipairs(TARGET_FOLDER:GetDescendants()) do
    track(obj)
end

TARGET_FOLDER.DescendantAdded:Connect(function(obj)
    task.wait()
    track(obj)
end)

TARGET_FOLDER.DescendantRemoving:Connect(untrack)

RunService.Heartbeat:Connect(function()
    if not ESPEnabled then return end
    if not LP.Character then return end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position

    for obj in pairs(Tracked) do
        if obj and obj.Parent then
            local root = getRoot(obj)
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist <= MAX_DISTANCE then
                    local cleanName = obj.Name
                        :gsub("[^A-Za-z%s]", " ")
                        :gsub("%s+", " ")
                        :gsub("^%s*(.-)%s*$", "%1")
                    cleanName = cleanName:match("^(%S+)") or cleanName
                    cleanName = cleanName:sub(1,1):upper() .. cleanName:sub(2):lower()

                    local hl = root:FindFirstChild("OBJ_ESP_HL") or Instance.new("Highlight", root)
                    hl.Name = "OBJ_ESP_HL"
                    hl.Adornee = root
                    hl.FillColor = ESP_COLOR
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.new(1,1,1)
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

                    local bb = root:FindFirstChild("OBJ_ESP_BILLBOARD") or Instance.new("BillboardGui", root)
                    bb.Name = "OBJ_ESP_BILLBOARD"
                    bb.Adornee = root
                    bb.Size = UDim2.new(0, 240, 0, 50)
                    bb.StudsOffset = Vector3.new(0, 4, 0)
                    bb.AlwaysOnTop = true

                    local label = bb:FindFirstChild("Label") or Instance.new("TextLabel", bb)
                    label.Name = "Label"
                    label.Size = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.Text = string.format(
                        "<font color='rgb(%d,%d,%d)'>%s</font>\n[%dm]",
                        ESP_COLOR.R*255, ESP_COLOR.G*255, ESP_COLOR.B*255,
                        cleanName, math.floor(dist)
                    )
                    label.TextColor3 = Color3.new(1,1,1)
                    label.TextStrokeTransparency = 0
                    label.TextStrokeColor3 = Color3.new(0,0,0)
                    label.FontFace = Font.new("rbxassetid://12187362578")
                    label.TextSize = 10
                    label.RichText = true
                else
                    untrack(obj)
                end
            end
        else
            untrack(obj)
        end
    end
end)

--================================================================--
-- AUTO LOOT
--================================================================--
local AutoLootEnabled = false
local visitedItems = {}
local TELEPORT_DELAY = 0.2
local lastTeleportTime = 0

RunService.Heartbeat:Connect(function(deltaTime)
    if not AutoLootEnabled then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end

    lastTeleportTime = lastTeleportTime + deltaTime
    if lastTeleportTime < TELEPORT_DELAY then return end
    lastTeleportTime = 0

    local targetFolder = Workspace:FindFirstChild("Items")
    if targetFolder then
        for _, item in ipairs(targetFolder:GetChildren()) do
            if not visitedItems[item] then
                local root = getRoot(item)
                if root then
                    LP.Character.HumanoidRootPart.CFrame = root.CFrame + Vector3.new(0,3,0)
                    visitedItems[item] = true
                    break
                end
            end
        end
    end
end)

--================================================================--
-- AUTO SELL
--================================================================--
local AutoSellEnabled = false
local SellRemote = ReplicatedStorage:WaitForChild("Ml"):WaitForChild("SellInventory")

task.spawn(function()
    while true do
        if AutoSellEnabled and SellRemote then
            SellRemote:FireServer()
        end
        task.wait(1)
    end
end)

--================================================================--
-- GUI: CREATE WINDOW
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "Mines",
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
-- MAIN TAB
--================================================================--
local MainTab = Window:AddTab("Main", "house")
local AutoLeft = MainTab:AddLeftGroupbox("AUTOMATION", "cpu")
local ESPRight = MainTab:AddRightGroupbox("ESP", "eye")

--================================================================--
-- AUTOMATION 
--================================================================--
AutoLeft:AddToggle("AutoLootTP", {
    Text = "Auto Loot",
    Default = false,
    Callback = function(state)
        AutoLootEnabled = state
        if not AutoLootEnabled then
            visitedItems = {}
        end
    end
})

AutoLeft:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(state)
        AutoSellEnabled = state
    end
})

--================================================================--
-- ESP
--================================================================--
ESPRight:AddToggle("OreESP", {
    Text = "Ore ESP",
    Default = false,
    Callback = function(state)
        ESPEnabled = state
    end
})

--================================================================--
-- SETTINGS TAB
--================================================================--
local SettingsTab = Window:AddTab("Settings", "cog")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Vgxmod")
SaveManager:SetFolder("Vgxmod")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()
