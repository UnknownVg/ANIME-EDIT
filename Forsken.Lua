--================================================================--
--                             VGXMOD HUB - DEAD BY DAYLIGHT
--          Generator ESP • Killer ESP • Survivor ESP • Loot ESP • Auto Repair • Unli Sprint
--================================================================--

print("------------------------------------------------------------------")
print("Load ................................ Armor V3")
print("Load ................................ Vgxmod Hub")
print("------------------------------------------------------------------")

--================================================================--
-- LOAD LIBRARY (Vgxmod UI)
--================================================================--
local repo = "https://raw.githubusercontent.com/Devilx89/CUSTOM-1/refs/heads/main/"
local success, err = pcall(function()
    Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    ThemeManager = loadstring(game:HttpGet(repo .. "Add-ons/ThemeManager.lua"))()
    SaveManager = loadstring(game:HttpGet(repo .. "Add-ons/SaveManager.lua"))()
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

--================================================================--
-- ESP CONFIGURATION
--================================================================--
local ESP = {
    Generator = { Enabled = false, Color = Color3.fromRGB(255, 140, 0) },
    Killer    = { Enabled = false, Color = Color3.fromRGB(255, 50, 50) },
    Survivor  = { Enabled = false, Color = Color3.fromRGB(240, 240, 240) },
    Loot      = { Enabled = false, Color = Color3.fromRGB(0, 255, 0) }
}

local MAX_DISTANCE = 99999

--================================================================--
-- SURVIVOR FEATURES FLAGS
--================================================================--
local AutoRepairEnabled = false
local UnliSprintEnabled = false

--================================================================--
-- TRACKED OBJECTS
--================================================================--
local Tracked = {
    Generators = {},
    Killers    = {},
    Survivors  = {},
    Loot       = {}
}

--================================================================--
-- HELPER FUNCTIONS
--================================================================--
local function isTopLevelGenerator(obj)
    if not obj or not obj:IsA("Model") or not obj.Name:find("Generator") then return false end
    local parent = obj.Parent
    while parent do
        if parent:IsA("Model") and parent.Name:find("Generator") then return false end
        parent = parent.Parent
    end
    return true
end

local function isLoot(obj)
    if not obj or not obj.Name then return false end
    return obj.Name == "Medkit" or obj.Name == "BloxyCola"
end

local function createHighlight(model, color, fillTrans)
    local hl = model:FindFirstChild("VGX_ESP_HL") or Instance.new("Highlight")
    hl.Name = "VGX_ESP_HL"
    hl.Adornee = model
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = fillTrans or 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
end

local function createBillboard(part, text)
    local bg = part:FindFirstChild("VGX_ESP_BILLBOARD") or Instance.new("BillboardGui")
    bg.Name = "VGX_ESP_BILLBOARD"
    bg.Adornee = part
    bg.Size = UDim2.new(0, 240, 0, 50)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.AlwaysOnTop = true
    bg.MaxDistance = MAX_DISTANCE
    bg.LightInfluence = 0
    bg.Parent = part

    local label = bg:FindFirstChild("Label") or Instance.new("TextLabel", bg)
    label.Name = "Label"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    label.TextSize = 10
    label.RichText = true
    label.Text = text
    return bg
end

local function clearESP(model)
    if model then
        if model:FindFirstChild("VGX_ESP_HL") then model.VGX_ESP_HL:Destroy() end
        for _, child in ipairs(model:GetChildren()) do
            if child.Name == "VGX_ESP_BILLBOARD" then child:Destroy() end
        end
    end
end

--================================================================--
-- AUTO REPAIR SYSTEM - FIXED & WORKING
--================================================================--
local AutoRepairEnabled = false
local repairConnections = {}

local function doRepair(g)
    local rem = g:FindFirstChild("Remotes")
    local prog = g:FindFirstChild("Progress")
    if not rem or not prog then return end
    local rf = rem:FindFirstChild("RF")
    local re = rem:FindFirstChild("RE")

    local conn = task.spawn(function()
        while AutoRepairEnabled and prog.Value < 100 and g.Parent do
            local playerOnGen = g:FindFirstChild("Player")
            if playerOnGen and playerOnGen.Value == game.Players.LocalPlayer then
                task.wait(1)
                continue
            end
            if rf then pcall(rf.InvokeServer, rf) end
            if re then pcall(re.FireServer, re) end
            task.wait(3.6)
        end
    end)
    repairConnections[g] = conn
end

local function startAutoRepair()
    if not AutoRepairEnabled then return end
    task.spawn(function()
        local map = workspace:FindFirstChild("Map")
        if not map then return end
        local ingame = map:FindFirstChild("Ingame")
        if not ingame then return end
        local gens = ingame:FindFirstChild("Map")
        if not gens then return end

        for _, v in pairs(gens:GetChildren()) do
            if v:FindFirstChild("Remotes") and v:FindFirstChild("Progress") then
                doRepair(v)
            end
        end
    end)
end

-- AUTO RESTART ON DEATH
LP.CharacterAdded:Connect(function()
    task.wait(5)
    if AutoRepairEnabled then
        for _, c in pairs(repairConnections) do
            if typeof(c) == "thread" then task.cancel(c) end
        end
        repairConnections = {}
        startAutoRepair()
    end
end)

-- AUTO RESTART ON NEW MAP
workspace.DescendantAdded:Connect(function(obj)
    if AutoRepairEnabled and obj.Name == "Map" and obj:FindFirstChild("Ingame") then
        task.wait(6)
        for _, c in pairs(repairConnections) do
            if typeof(c) == "thread" then task.cancel(c) end
        end
        repairConnections = {}
        startAutoRepair()
    end
end)
--================================================================--
-- UNLIMITED SPRINT SYSTEM
--================================================================--
local staminaModule = nil
local sprintConnection = nil

local function applyUnliSprint()
    if not UnliSprintEnabled then return end

    local success, module = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Character"):WaitForChild("Game"):WaitForChild("Sprinting"))
    end)

    if not success or not module then
        task.wait(2)
        if UnliSprintEnabled then applyUnliSprint() end
        return
    end

    staminaModule = module

    pcall(function() staminaModule.StaminaLossDisabled = true end)
    pcall(function() staminaModule.CanSprint = true end)

    if sprintConnection then task.cancel(sprintConnection) end

    sprintConnection = task.spawn(function()
        while UnliSprintEnabled and task.wait(0.15) do
            if not staminaModule or not LP.Character then break end

            pcall(function()
                if staminaModule.Stamina ~= nil and staminaModule.MaxStamina then
                    staminaModule.Stamina = staminaModule.MaxStamina
                end

                local event = staminaModule:FindFirstChild("StaminaChanged")
                if event and (event:IsA("BindableEvent") or event:IsA("RemoteEvent")) then
                    event:Fire()
                end
            end)
        end
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(2)
    if UnliSprintEnabled then applyUnliSprint() end
end)

task.spawn(function()
    local wasEnabled = false
    while task.wait(1) do
        if not UnliSprintEnabled and wasEnabled then
            if staminaModule then
                pcall(function() staminaModule.StaminaLossDisabled = false end)
            end
            if sprintConnection then
                task.cancel(sprintConnection)
                sprintConnection = nil
            end
            wasEnabled = false
        elseif UnliSprintEnabled and not wasEnabled then
            wasEnabled = true
        end
    end
end)
--================================================================--
-- MAIN ESP + FEATURES LOOP
--================================================================--
RunService.Heartbeat:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LP.Character.HumanoidRootPart.Position
    local playersFolder = Workspace:FindFirstChild("Players")

    if ESP.Generator.Enabled then
        for model, data in pairs(Tracked.Generators) do
            if model and model.Parent then
                local root = data.Root
                if root then
                    local dist = math.floor((root.Position - myPos).Magnitude)
                    createHighlight(model, ESP.Generator.Color)
                    createBillboard(root, string.format(
                        "<font color='rgb(255,140,0)'>Generator</font>\n[%dm]", dist
                    ))
                end
            else
                Tracked.Generators[model] = nil
            end
        end
    else
        for model in pairs(Tracked.Generators) do clearESP(model) end
    end

    if playersFolder and (ESP.Killer.Enabled or ESP.Survivor.Enabled) then
        for role, color in pairs({Killers = ESP.Killer.Color, Survivors = ESP.Survivor.Color}) do
            local enabled = (role == "Killers" and ESP.Killer.Enabled) or (role == "Survivors" and ESP.Survivor.Enabled)
            local folder = playersFolder:FindFirstChild(role)
            if folder and enabled then
                for _, model in ipairs(folder:GetChildren()) do
                    if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                        local dist = math.floor((model.HumanoidRootPart.Position - myPos).Magnitude)
                        createHighlight(model, color)
                        local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
                        if head then
                            createBillboard(head, string.format(
                                "<font color='rgb(%d,%d,%d)' size='16'>%s</font>\n<font color='rgb(180,180,180)'>[%dm]</font> <font color='rgb(255,150,0)'>[%s]</font>",
                                color.R*255, color.G*255, color.B*255, model.Name, dist, role
                            ))
                        end
                    end
                end
            else
                if folder then
                    for _, model in ipairs(folder:GetChildren()) do clearESP(model) end
                end
            end
        end
    else
        if playersFolder then
            for _, role in ipairs({"Killers", "Survivors"}) do
                local folder = playersFolder:FindFirstChild(role)
                if folder then
                    for _, model in ipairs(folder:GetChildren()) do clearESP(model) end
                end
            end
        end
    end

    -- Loot ESP
    if ESP.Loot.Enabled then
        for model, data in pairs(Tracked.Loot) do
            if model and model.Parent then
                local root = data.Root
                if root then
                    local dist = math.floor((root.Position - myPos).Magnitude)
                    createHighlight(model, ESP.Loot.Color, 0.5)
                    createBillboard(root, string.format(
                        "<font color='rgb(0,255,0)'>%s</font>\n[%dm]", model.Name, dist
                    ))
                end
            else
                Tracked.Loot[model] = nil
            end
        end
    else
        for model in pairs(Tracked.Loot) do clearESP(model) end
    end
end)

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    if obj:IsA("Model") then
        if ESP.Generator.Enabled and isTopLevelGenerator(obj) then
            local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if root then Tracked.Generators[obj] = {Root = root} end
        elseif ESP.Loot.Enabled and isLoot(obj) then
            local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if root then Tracked.Loot[obj] = {Root = root} end
        end
    end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    Tracked.Generators[obj] = nil
    Tracked.Loot[obj] = nil
end)

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") then
        if isTopLevelGenerator(obj) then
            local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if root then Tracked.Generators[obj] = {Root = root} end
        elseif isLoot(obj) then
            local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if root then Tracked.Loot[obj] = {Root = root} end
        end
    end
end




--================================================================--
-- GUI: CREATE WINDOW
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "version: 1.6",
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

InfoRight:AddLabel("Discord Link")
InfoRight:AddButton({
    Text = "Copy",
    Func = function()
        setclipboard("https://discord.gg/n9gtmefsjc")
        Library:Notify({Title = "Copied!", Description = "Paste it on your browser", Time = 4})
    end,
})

--================================================================--
-- MAIN TAB
--================================================================--
local MainTab = Window:AddTab("Main", "house")
local SurvivorLeft = MainTab:AddLeftGroupbox("SURVIVOR FEATURE", "user")
local KillerLeft = MainTab:AddRightGroupbox("KILLER FEATURE", "skull")

local VisualTab = Window:AddTab("Visual", "eye")
local ESPLeft = VisualTab:AddLeftGroupbox("ESP FEATURE", "eye")

local MiscTab = Window:AddTab("Misc", "settings")
local MiscLeft = MiscTab:AddLeftGroupbox("MISC FEATURE", "Settings")

--================================================================--
-- SURVIVOR FEATURES (Left Side)
--================================================================--
SurvivorLeft:AddToggle("AutoRepair", {
    Text = "Auto Repair Generator",
    Default = false,
    Callback = function(v)
        AutoRepairEnabled = v
        if v then
            startAutoRepair()  -- NOW IT CALLS THE CORRECT FUNCTION
            Library:Notify({Title = "Auto Repair", Description = "ON - 3.6s fixed", Time = 3})
        else
            for g, c in pairs(repairConnections) do
                if typeof(c) == "thread" then task.cancel(c) end
            end
            repairConnections = {}
            Library:Notify({Title = "Auto Repair", Description = "OFF", Time = 2})
        end
    end
})

SurvivorLeft:AddToggle("UnliSprint", {
    Text = "Unlimited Sprint",
    Default = false,
    Callback = function(v)
        UnliSprintEnabled = v
        if v then
            applyUnliSprint()
            Library:Notify({Title = "Unlimited Sprint", Description = "Enabled - Never tired!", Time = 3})
        else
            if staminaModule then
                staminaModule.StaminaLossDisabled = false
            end
            Library:Notify({Title = "Unlimited Sprint", Description = "Disabled", Time = 2})
        end
    end
})

--================================================================--
-- ESP TOGGLES
--================================================================--
ESPLeft:AddToggle("GeneratorESP", {
    Text = "Generator ESP",
    Default = false,
    Callback = function(v)
        ESP.Generator.Enabled = v
        Library:Notify({Title = "Generator ESP", Description = v and "Enabled" or "Disabled", Time = 2})
    end
})

ESPLeft:AddToggle("KillerESP", {
    Text = "Killer ESP",
    Default = false,
    Callback = function(v)
        ESP.Killer.Enabled = v
        Library:Notify({Title = "Killer ESP", Description = v and "Enabled" or "Disabled", Time = 2})
    end
})

ESPLeft:AddToggle("SurvivorESP", {
    Text = "Survivor ESP",
    Default = false,
    Callback = function(v)
        ESP.Survivor.Enabled = v
        Library:Notify({Title = "Survivor ESP", Description = v and "Enabled" or "Disabled", Time = 2})
    end
})

ESPLeft:AddToggle("LootESP", {
    Text = "Loot ESP",
    Default = false,
    Callback = function(v)
        ESP.Loot.Enabled = v
        Library:Notify({Title = "Loot ESP", Description = v and "Enabled" or "Disabled", Time = 2})
    end
})



MiscLeft:AddButton({
    Text = "Day Mode",
    Func = function()
        local Lighting = game:GetService("Lighting")
        local function ultraDay()
            Lighting.ClockTime = 12
            Lighting.TimeOfDay = "12:00:00"
            Lighting.Brightness = 5
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Lighting.FogColor = Color3.fromRGB(255, 255, 255)
            Lighting.GlobalShadows = false
            Lighting.ShadowSoftness = 0
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
            Lighting.ExposureCompensation = 0.5
        end
        ultraDay()
        local props = {
            "ClockTime", "TimeOfDay", "Brightness", "FogEnd", "FogStart",
            "GlobalShadows", "OutdoorAmbient", "Ambient", "ExposureCompensation"
        }
        for _, prop in ipairs(props) do
            Lighting:GetPropertyChangedSignal(prop):Connect(ultraDay)
        end
        task.spawn(function()
            while task.wait(0.5) do
                ultraDay()
            end
        end)
        Library:Notify({Title = "Day Mode", Description = "", Time = 4})
    end,
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
