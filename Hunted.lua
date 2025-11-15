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
--  ESP CONFIGURATION SETTINGS 
--================================================================--
local ESP = {
    OrangeShard = { Enabled = false, Color = Color3.fromRGB(255, 140, 0) },
    RedShard    = { Enabled = false, Color = Color3.fromRGB(255, 50, 50) },
    Shard       = { Enabled = false, Color = Color3.fromRGB(150, 0, 255) },
    Monkey      = { Enabled = false, Color = Color3.fromRGB(255, 0, 0) }
}

local ESP_MAX_DISTANCE = 2000
local Tracked = {}

--================================================================--
-- ESP SYSTEM (PERFECT MONKEY DISTANCE + HIGHLIGHTS)
--================================================================--
local function isTarget(obj)
    if not obj or not obj.Name then return false end
    local name = obj.Name

    for targetName, config in pairs(ESP) do
        if config.Enabled then
            if targetName == "Monkey" then
                if obj:IsA("Model") and (string.match(name, "%f[%a]Monkey%f[%A]") or name == "Monkey") then
                    return true, targetName
                end
            else
                if obj:IsA("BasePart") and string.find(string.lower(name), string.lower(targetName)) then
                    return true, targetName
                end
            end
        end
    end
    return false
end

local function addESP(part, targetName)
    if not part or not part:IsA("BasePart") or Tracked[part] or part:FindFirstChild("ESP_HL") then return end
    local config = ESP[targetName]
    if not config then return end

    Tracked[part] = true

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Parent = part
    hl.Adornee = part
    hl.FillColor = config.Color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.3
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local bg = Instance.new("BillboardGui")
    bg.Name = "ESP_BG"
    bg.Parent = part
    bg.Adornee = part
    bg.Size = UDim2.new(0, 220, 0, 70)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.AlwaysOnTop = true
    bg.MaxDistance = ESP_MAX_DISTANCE

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = bg
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.RichText = true
    label.Text = string.format("<font color='rgb(%d,%d,%d)'><b>%s</b></font>", 
        config.Color.R * 255, config.Color.G * 255, config.Color.B * 255, targetName)
end

local function removeESP(part)
    if not part then return end
    Tracked[part] = nil
    if part:FindFirstChild("ESP_HL") then part.ESP_HL:Destroy() end
    if part:FindFirstChild("ESP_BG") then part.ESP_BG:Destroy() end
end

local function clearAllESP()
    for part, _ in pairs(Tracked) do
        removeESP(part)
    end
    Tracked = {}
end

local function scanESP()
    clearAllESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local ok, name = isTarget(obj)
        if ok then
            local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if root and root:IsA("BasePart") then
                addESP(root, name)
            end
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.05)
    local ok, name = isTarget(obj)
    if ok then
        local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
        if root and root:IsA("BasePart") then
            addESP(root, name)
        end
    end
end)

Workspace.DescendantRemoving:Connect(removeESP)

RunService.Heartbeat:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local pos = LP.Character.HumanoidRootPart.Position

    for part, _ in pairs(Tracked) do
        if part and part.Parent then
            local dist = (part.Position - pos).Magnitude
            if dist > ESP_MAX_DISTANCE then
                removeESP(part)
            else
                local bg = part:FindFirstChild("ESP_BG")
                if bg then
                    local label = bg:FindFirstChild("Label")
                    if label then
                        local targetName = nil
                        local parentModel = part.Parent
                        if parentModel and parentModel:IsA("Model") then
                            local modelName = parentModel.Name
                            if ESP.Monkey.Enabled and (string.match(modelName, "%f[%a]Monkey%f[%A]") or modelName == "Monkey") then
                                targetName = "Monkey"
                            end
                        end
                        if not targetName then
                            for name, config in pairs(ESP) do
                                if config.Enabled and string.find(string.lower(part.Name), string.lower(name)) then
                                    targetName = name
                                    break
                                end
                            end
                        end
                        if targetName then
                            local config = ESP[targetName]
                            local display = (targetName == "Monkey") and "Monkey" or targetName
                            label.Text = string.format(
                                "<font color='rgb(%d,%d,%d)'><b>%s</b></font>\n<font color='rgb(200,200,200)'>[%dm]</font>",
                                config.Color.R * 255, config.Color.G * 255, config.Color.B * 255,
                                display, math.floor(dist)
                            )
                        end
                    end
                end
            end
        else
            removeESP(part)
        end
    end
end)

--================================================================--
--  AUTO CONFIGURATION SETTINGS 
--================================================================--
local Collect = {
    OrangeShard = { Enabled = false },
    RedShard    = { Enabled = false },
    Shard       = { Enabled = false }
}

local COLLECT_MAX_DISTANCE = 99999
local Cooldowns = {}

--================================================================--
-- AUTO COLLECT SHARD SYSTEM 
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
local MainTab     = Window:AddTab("Map 1", "house")
local Main2Tab     = Window:AddTab("Map 2", "house")
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
-- GROUP BOX 
--================================================================--
local AutoLeft = MainTab:AddLeftGroupbox("AUTOMATION", "cpu")
local EspRight = MainTab:AddRightGroupbox("VISUAL", "eye")
local TpLeft   = MainTab:AddLeftGroupbox("TELEPORT", "portal-enter")

--================================================================--
-- AUTOMATION
--================================================================--
AutoLeft:AddToggle("AutoCollect", {
    Text = "Auto Collect Shards",
    Default = false,
    Callback = function(state)
        Collect.OrangeShard.Enabled = state
        Collect.RedShard.Enabled = state
        Collect.Shard.Enabled = state
        
        if state then
            Library:Notify({Title = "Auto Collect", Description = "ON", Time = 2})
        else
            Library:Notify({Title = "Auto Collect", Description = "OFF", Time = 2})
        end
    end,
})

--================================================================--
-- ESP
--================================================================--
EspRight:AddToggle("ShardESP", {
    Text = "Shard ESP",
    Default = false,
    Callback = function(state)
        ESP.OrangeShard.Enabled = state
        ESP.RedShard.Enabled = state
        ESP.Shard.Enabled = state
        
        if state then
            scanESP()
            Library:Notify({Title = "Shard ESP", Description = "ON", Time = 2})
        else
            for part, _ in pairs(Tracked) do
                local parent = part.Parent
                if parent and parent:IsA("Model") then
                    if not ESP.Monkey.Enabled then
                        removeESP(part)
                    end
                else
                    removeESP(part)
                end
            end
            Library:Notify({Title = "Shard ESP", Description = "OFF", Time = 2})
        end
    end,
})

EspRight:AddToggle("MonkeyESP", {
    Text = "Monkey ESP",
    Default = false,
    Callback = function(state)
        ESP.Monkey.Enabled = state
        
        if state then
            scanESP()
            Library:Notify({Title = "Monkey ESP", Description = "ON", Time = 2})
        else
            for part, _ in pairs(Tracked) do
                local parent = part.Parent
                if parent and parent:IsA("Model") then
                    removeESP(part)
                end
            end
            Library:Notify({Title = "Monkey ESP", Description = "OFF", Time = 2})
        end
    end,
})

--================================================================--
-- TELEPORT 
--================================================================--
TpLeft:AddButton({
    Text = "TP to Ring Altar",
    Func = function()
        local success, result = pcall(function()
            return workspace.Hotel.Maze.Rooms.Main.RingAltar.Parts.RingAltar
        end)
        
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if success and result and result:IsA("BasePart") then
                char.HumanoidRootPart.CFrame = result.CFrame + Vector3.new(0, 5, 0)
                Library:Notify({Title = "TP Success", Description = "Teleported to Ring Altar!", Time = 2})
            else
                Library:Notify({Title = "TP Failed", Description = "Ring Altar not found!", Time = 3})
            end
        else
            Library:Notify({Title = "TP Failed", Description = "Character not loaded!", Time = 3})
        end
    end,
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
