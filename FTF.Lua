--================================================================--
--                             VGXMOD HUB (PERFECT SKILLCHECK ADDED)
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

--================================================================--
-- ESP CONFIG (EXACTLY LIKE YOU WANTED)
--================================================================--
local ESP = {
    Killer   = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.5 },
    Survivor = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8 },
    Computer = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0.4 }
}

local MAX_DISTANCE = 9999
local FONT_ID = "rbxassetid://12187362578"
local OBJECT_NAME = "ComputerTable"
local Tracked = {}

local Hitbox_Enabled = false
local Hitbox_Size = 8

--================================================================--
-- KILL AURA CONFIG
--================================================================--
local KillAura_Enabled = false
local KillAura_Range = 30
local HammerRemote = nil

--================================================================--
-- PERFECT SKILLCHECK CONFIG
--================================================================--
local PerfectSkillCheck_Enabled = false
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

--================================================================--
-- SHARED ESP HELPERS
--================================================================--
local function removeESP(obj)
    if not obj then return end
    if obj:FindFirstChild("ESP_HL") then obj.ESP_HL:Destroy() end
    if obj:FindFirstChild("ESP_BILLBOARD") then obj.ESP_BILLBOARD:Destroy() end
end

local function createHighlight(char, color, transparency)
    if not char then return end
    local hl = char:FindFirstChild("ESP_HL") or Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = char
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = transparency
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
end

local function createBillboard(char, text)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local gui = head:FindFirstChild("ESP_BILLBOARD") or Instance.new("BillboardGui")
    gui.Name = "ESP_BILLBOARD"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 220, 0, 60)
    gui.StudsOffset = Vector3.new(0, 3.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = MAX_DISTANCE
    gui.LightInfluence = 0
    gui.Parent = head
    local label = gui:FindFirstChild("Label") or Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.FontFace = Font.new(FONT_ID, Enum.FontWeight.Bold)
    label.TextSize = 10
    label.RichText = true
    label.Parent = gui
end

--================================================================--
-- PLAYER ESP (KILLER/SURVIVOR)
--================================================================--
local function isKiller(plr)
    if not plr then return false end
    local folder = Workspace:FindFirstChild(plr.Name)
    return folder and folder:FindFirstChild("BeastPowers") ~= nil
end

RunService.Heartbeat:Connect(function()
    if not (ESP.Killer.Enabled or ESP.Survivor.Enabled) then 
        for _, plr in Players:GetPlayers() do
            if plr.Character then removeESP(plr.Character) end
        end
        return 
    end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LP.Character.HumanoidRootPart.Position
    for _, plr in Players:GetPlayers() do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local dist = math.floor((hrp.Position - myPos).Magnitude)
            local isKillerPlayer = isKiller(plr)
            local espType = isKillerPlayer and "Killer" or "Survivor"
            local espConfig = ESP[espType]
            if espConfig.Enabled then
                local roleText = isKillerPlayer and "[KILLER]" or "[SURVIVOR]"
                local text = string.format(
                    "<font size='16'>%s</font>\n<font color='rgb(200,200,200)'>[%dm]</font> <font color='rgb(%d,%d,%d)'>%s</font>",
                    plr.DisplayName, dist, 
                    espConfig.Color.R * 255, espConfig.Color.G * 255, espConfig.Color.B * 255, 
                    roleText
                )
                createHighlight(plr.Character, espConfig.Color, espConfig.Transparency)
                createBillboard(plr.Character, text)
            else
                removeESP(plr.Character)
            end
        end
    end
end)

--================================================================--
-- COMPUTER ESP
--================================================================--
local function isTarget(obj)
    return obj and obj:IsA("Model") and obj.Name:lower():find(OBJECT_NAME:lower())
end

local function createComputerESP(model, dist)
    if not model then return end
    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not root then return end
    local hl = model:FindFirstChild("ESP_HL") or Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = model
    hl.FillColor = ESP.Computer.Color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = ESP.Computer.Transparency
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
    local bb = root:FindFirstChild("ESP_BILLBOARD") or Instance.new("BillboardGui")
    bb.Name = "ESP_BILLBOARD"
    bb.Adornee = root
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 1500
    bb.Parent = root
    local lbl = bb:FindFirstChild("Label") or Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.format(
        "<b><font color='rgb(0,255,255)'>Computer Table</font></b>\n<font color='rgb(0,255,255)'>[%dm]</font>",
        math.floor(dist)
    )
    lbl.TextColor3 = ESP.Computer.Color
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.FontFace = Font.new("rbxassetid://12187362578", Enum.FontWeight.Bold)
    lbl.TextSize = 10
    lbl.RichText = true
    lbl.Parent = bb
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if isTarget(obj) then Tracked[obj] = true end
end

Workspace.DescendantAdded:Connect(function(obj)
    if isTarget(obj) then task.wait(); Tracked[obj] = true end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if Tracked[obj] then 
        removeESP(obj)
        Tracked[obj] = nil 
    end
end)

RunService.Heartbeat:Connect(function()
    if not ESP.Computer.Enabled then
        for model in pairs(Tracked) do
            removeESP(model)
        end
        return
    end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LP.Character.HumanoidRootPart.Position
    for model in pairs(Tracked) do
        if model and model.Parent then
            local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist <= 1500 then
                    createComputerESP(model, dist)
                else
                    removeESP(model)
                end
            end
        else
            Tracked[model] = nil
        end
    end
end)

--================================================================--
-- HITBOX ENLARGER (FIXED)
--================================================================--
local OriginalProps = {}

local function resetHitbox(plr)
    if not plr or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local props = OriginalProps[plr]
    if props then
        hrp.Size = props.size
        hrp.Transparency = props.transparency
        hrp.Color = props.color
        hrp.Material = props.material
        hrp.CanCollide = props.canCollide
        OriginalProps[plr] = nil
    end
end

local function saveOriginal(plr)
    if not plr or not plr.Character then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp and not OriginalProps[plr] then
        OriginalProps[plr] = {
            size = hrp.Size,
            transparency = hrp.Transparency,
            color = hrp.Color,
            material = hrp.Material,
            canCollide = hrp.CanCollide
        }
    end
end

RunService.RenderStepped:Connect(function()
    for _, plr in Players:GetPlayers() do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not isKiller(plr) then
                if Hitbox_Enabled then
                    saveOriginal(plr)
                    local hrp = plr.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(Hitbox_Size, Hitbox_Size, Hitbox_Size)
                    hrp.Transparency = 0.9
                    hrp.Color = Color3.fromRGB(0, 0, 0)
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                else
                    resetHitbox(plr)
                end
            end
        else
            OriginalProps[plr] = nil
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    OriginalProps[plr] = nil
end)

--================================================================--
-- KILL AURA SYSTEM
--================================================================--
local function getHammerRemote()
    if not LP.Character then return end
    local hammer = LP.Character:FindFirstChild("Hammer")
    if not hammer then return end
    return hammer:FindFirstChild("HammerEvent")
end

local function getClosest()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local closest, bestDist = nil, KillAura_Range
    for _, plr in Players:GetPlayers() do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 and not plr.Character:FindFirstChildWhichIsA("ForceField") then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest, bestDist
end

task.spawn(function()
    while true do
        if not KillAura_Enabled then task.wait(0.5) continue end
        if not LP.Character or not LP.Character:FindFirstChild("Hammer") then
            HammerRemote = nil
            task.wait(0.5)
            continue
        end
        if not HammerRemote then
            HammerRemote = getHammerRemote()
            task.wait(0.2)
            continue
        end
        local target, distance = getClosest()
        if target and distance <= KillAura_Range then
            HammerRemote:FireServer("HammerClick", true)
            local torso = target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("UpperTorso")
            if torso then
                HammerRemote:FireServer("HammerHit", torso)
            end
        end
        task.wait(0.15)
    end
end)

LP.CharacterAdded:Connect(function()
    HammerRemote = nil
end)

--================================================================--
-- PERFECT SKILLCHECK SYSTEM (FLEE THE FACILITY)
--================================================================--
task.spawn(function()
    while true do
        if PerfectSkillCheck_Enabled then
            local args = {
                [1] = "SetPlayerMinigameResult",
                [2] = true
            }
            RemoteEvent:FireServer(unpack(args))
        end
        task.wait(0.01)
    end
end)

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
local BeastLeft = MainTab:AddLeftGroupbox("BEAST FEATURE", "skull")
local SurvivorRight = MainTab:AddRightGroupbox("SURVIVOR FEATURE", "cpu")

local VisualTab = Window:AddTab("Visual", "eye")
local ESPLeft = VisualTab:AddLeftGroupbox("ESP FEATURE", "eye")

--================================================================--
-- TOGGLES WITH NOTIFY (UPDATED)
--================================================================--
ESPLeft:AddToggle("KillerESP", {
    Text = "Killer ESP",
    Default = false,
    Callback = function(state)
        ESP.Killer.Enabled = state
        Library:Notify({
            Title = "Killer ESP",
            Description = state and "Enabled" or "Disabled",
            Time = 2
        })
    end,
})

ESPLeft:AddToggle("SurvivorESP", {
    Text = "Survivor ESP", 
    Default = false,
    Callback = function(state)
        ESP.Survivor.Enabled = state
        Library:Notify({
            Title = "Survivor ESP",
            Description = state and "Enabled" or "Disabled",
            Time = 2
        })
    end,
})

ESPLeft:AddToggle("ComputerESP", {
    Text = "Computer ESP",
    Default = false,
    Callback = function(state)
        ESP.Computer.Enabled = state
        Library:Notify({
            Title = "Computer ESP",
            Description = state and "Enabled" or "Disabled",
            Time = 2
        })
    end,
})

--================================================================--
-- PERFECT SKILLCHECK TOGGLE (NEW!)
--================================================================--
SurvivorRight:AddToggle("PerfectSkillCheck", {
    Text = "Perfect Skill Check",
    Default = false,
    Callback = function(state)
        PerfectSkillCheck_Enabled = state
        Library:Notify({
            Title = "Perfect Skill Check",
            Description = state and "ALWAYS PERFECT!" or "Disabled",
            Time = 2
        })
    end,
})

--================================================================--
-- KILL AURA TOGGLE & SLIDER
--================================================================--
BeastLeft:AddToggle("KillAuraToggle", {
    Text = "Hammer Kill Aura",
    Default = false,
    Callback = function(state)
        KillAura_Enabled = state
        Library:Notify({
            Title = "Kill Aura",
            Description = state and "Enabled" or "Disabled",
            Time = 2
        })
    end,
})

BeastLeft:AddSlider("KillAuraRange", {
    Text = "Kill Aura Range",
    Default = 30,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        KillAura_Range = value
        Library:Notify({
            Title = "Kill Aura Range",
            Description = "Set to " .. value .. " studs",
            Time = 2
        })
    end,
})

--================================================================--
-- HITBOX TOGGLE & SLIDER
--================================================================--
BeastLeft:AddToggle("HitboxToggle", {
Text = "Hitbox Enlarger",
Default = false,
Callback = function(state)
Hitbox_Enabled = state
Library:Notify({
Title = "Hitbox Enlarger",
Description = state and "Enabled" or "Disabled",
Time = 2
})
end,
})

BeastLeft:AddSlider("HitboxSize", {
Text = "Hitbox Size",
Default = 8,
Min = 5,
Max = 12,
Rounding = 0,
Callback = function(value)
Hitbox_Size = value
Library:Notify({
Title = "Hitbox Size",
Description = "Level " .. tostring(value),
Time = 2
})
end,
})

--================================================================--
-- SETTINGS TAB
--================================================================--
local SettingsTab = Window:AddTab("Settings", "cog")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("Vgxmod")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()
