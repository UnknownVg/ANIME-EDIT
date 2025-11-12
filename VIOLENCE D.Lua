--================================================================--
--                    VGXMOD HUB - VIOLENCE DISTRICT 1.7
--                          
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
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--================================================================--
-- BLOCK REMOTE SYSTEM
--================================================================--
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local blocked = {}

local function blockRemote(remote)
    if not remote or blocked[remote] then return end
    blocked[remote] = true
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        if blocked[self] then return nil end
        return oldNamecall(self, ...)
    end
    setreadonly(mt, true)
end

local function unblockRemote(remote)
    blocked[remote] = nil
end

--================================================================--
-- CONFIGURATION
--================================================================--
local DESIRED_FOV = 95

-- ESP SETTINGS (PUMPKINS ADDED HERE)
local espSettings = {
    Survivors  = {Enabled=false, Color=Color3.fromRGB(255,255,255), Transparency=0.9},
    Killers    = {Enabled=false, Color=Color3.fromRGB(255,0,0), Transparency=0.5},
    Generators = {Enabled=false, Color=Color3.fromRGB(0,170,255), Transparency=0.6},
    Pallets    = {Enabled=false, Color=Color3.fromRGB(139,69,19), Transparency=0.6},
    ExitGates  = {Enabled=false, Color=Color3.fromRGB(0,255,0), Transparency=0.5},
    Windows    = {Enabled=false, Color=Color3.fromRGB(0,255,255), Transparency=0.6},
    Pumpkins   = {Enabled=false, Color=Color3.fromRGB(255,140,0), Transparency=0.5}
}

local playerHitboxes = {}
local hitboxEnabledAll = false
local headSize = 12
local hitboxTransparency = 0.9

--================================================================--
-- ITEM Display Names
--================================================================--
local displayNames = {
    ["Motion Tracker"] = "Motion Tracker",
    ["Gate"] = "Gate",
    ["Flashlight"] = "Flashlight",
    ["Bandage"] = "Bandage",
    ["Parrying Dagger"] = "Parrying Dagger",
    ["Adrenaline Shot"] = "Adrenaline Shot",
    ["Shadow Clone"] = "Shadow Clone",
}

--================================================================--
-- GET SURVIVOR ITEM
--================================================================--
local function getSurvivorItem(player)
    if not player or not player.Character then return nil end
    for _, obj in pairs(player.Character:GetDescendants()) do
        if (obj:IsA("Tool") or obj:IsA("Accessory") or obj:IsA("Model")) and displayNames[obj.Name] then
            return "("..displayNames[obj.Name]..")"
        end
    end
    return nil
end

--================================================================--
-- TRACK OBJECTS 
--================================================================--
local trackedObjects = {}

local function trackObject(obj)
    if not obj or not obj.Name then return end
    local n = obj.Name:lower()

    -- Find current Map.Pumpkins (even if recreated)
    local map = workspace:FindFirstChild("Map")
    local pumpkinsFolder = map and map:FindFirstChild("Pumpkins")
    
    -- Only track pumpkins that are DIRECT children of the current Pumpkins folder
    if pumpkinsFolder and obj.Parent == pumpkinsFolder and n:find("pumpkin") then
        trackedObjects[obj] = "Pumpkins"
        return
    end

    -- Track other objects normally
    if n:find("generator") then trackedObjects[obj] = "Generators"
    elseif n:find("pallet") then trackedObjects[obj] = "Pallets"
    elseif n:find("gate") then trackedObjects[obj] = "ExitGates"
    elseif n:find("window") then trackedObjects[obj] = "Windows"
    end
end

-- Initial scan
for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("Model") then trackObject(v) end
end

-- Live tracking (works on new round)
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then trackObject(obj) end
end)

-- Optional: clean up when object is removed
Workspace.DescendantRemoving:Connect(function(obj)
    trackedObjects[obj] = nil
end)
--================================================================--
-- GET PLAYER ROLE
--================================================================--
local function getRole(p)
    if p and p.Team and p.Team.Name then
        local n = p.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

--================================================================--
-- ESP FUNCTIONS
--================================================================--
local function ensureHighlight(model, color, transparency)
    if not model then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = model
        hl.FillColor = color
        hl.FillTransparency = transparency or 0.7
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
    else
        hl.FillColor = color
        hl.FillTransparency = transparency or 0.7
    end
end

local function clearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        model.VD_HL:Destroy()
    end
end

local function ensureLabel(model, text)
    if not model then return end
    local lbl = model:FindFirstChild("VD_Label")
    if not lbl then
        lbl = Instance.new("BillboardGui")
        lbl.Name = "VD_Label"
        lbl.Size = UDim2.new(0, 200, 0, 22)
        lbl.StudsOffset = Vector3.new(0, 4.5, 0)
        lbl.AlwaysOnTop = true
        lbl.MaxDistance = 500
        lbl.Parent = model

        local tl = Instance.new("TextLabel")
        tl.Name = "TextLabel"
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.TextScaled = false
        tl.TextSize = 10
        tl.RichText = true
        tl.TextStrokeTransparency = 0.2
        tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        tl.TextColor3 = Color3.fromRGB(255, 255, 255)
        tl.Text = text
        tl.FontFace = Font.new("rbxassetid://11702779517")
        tl.Parent = lbl
    else
        local tl = lbl:FindFirstChild("TextLabel")
        if tl then tl.Text = text end
    end
end

local function clearLabel(model)
    if model and model:FindFirstChild("VD_Label") then
        model.VD_Label:Destroy()
    end
end

--================================================================--
-- GENERATOR PROGRESS
--================================================================--
local function getGeneratorProgress(gen)
    if not gen then return 0 end
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in ipairs(gen:GetDescendants()) do
            if (child:IsA("NumberValue") or child:IsA("IntValue")) and (child.Name:lower():find("progress") or child.Name:lower():find("repair")) then
                progress = child.Value
                break
            end
        end
    end
    return math.clamp((progress > 1 and progress / 100 or progress), 0, 1)
end

local function getProgressColor(percent)
    return Color3.fromRGB(255 * (1 - percent), 255 * percent, 0)
end

--================================================================--
-- FOV
--================================================================--
local function applyFOV()
    if Camera and Camera.FieldOfView ~= DESIRED_FOV then
        Camera.FieldOfView = DESIRED_FOV
    end
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.wait(0.1)
    Camera = Workspace.CurrentCamera
end)
RunService.RenderStepped:Connect(applyFOV)

--================================================================--
-- HITBOX
--================================================================--
local function applyHitbox(player)
    if not hitboxEnabledAll or getRole(player) ~= "Survivor" or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    playerHitboxes[player] = hrp
    hrp.Size = Vector3.new(headSize, headSize, headSize)
    hrp.Transparency = hitboxTransparency
    hrp.BrickColor = BrickColor.new("Really black")
    hrp.Material = Enum.Material.Neon
    hrp.CanCollide = false
end

local function removeHitbox(player)
    local hrp = playerHitboxes[player]
    if hrp and hrp.Parent then
        hrp.Size = Vector3.new(2,2,1)
        hrp.Transparency = 0
        hrp.BrickColor = BrickColor.new("Medium stone grey")
        hrp.Material = Enum.Material.Plastic
        hrp.CanCollide = true
    end
    playerHitboxes[player] = nil
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function() task.wait(0.5); if hitboxEnabledAll and getRole(p) == "Survivor" then applyHitbox(p) end end)
        if hitboxEnabledAll and getRole(p) == "Survivor" then applyHitbox(p) end
    end
end

Players.PlayerRemoving:Connect(removeHitbox)
RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            if hitboxEnabledAll and getRole(p) == "Survivor" then applyHitbox(p) else removeHitbox(p) end
        end
    end
end)

--================================================================--
-- ESP LOOP (PUMPKINS ADDED HERE)
--================================================================--
RunService.Heartbeat:Connect(function()
    local LPPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position
    if not LPPos then return end

    for obj, typeName in pairs(trackedObjects) do
        if obj and obj.Parent and espSettings[typeName].Enabled then
            local set = espSettings[typeName]
            local hl = obj:FindFirstChild("VD_HL") or Instance.new("Highlight")
            hl.Name = "VD_HL"; hl.Adornee = obj; hl.FillTransparency = 1; hl.OutlineColor = set.Color; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = obj

            if typeName == "Generators" then
                local progress = getGeneratorProgress(obj)
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = math.floor((root.Position - LPPos).Magnitude)
                    local percent = math.floor(progress * 100); if percent == 0 and progress > 0 then percent = 1 end
                    local c = getProgressColor(progress)
                    ensureLabel(obj, string.format("<font color='rgb(255,255,255)'>Gen</font> <font color='rgb(200,200,200)'>(%d)</font> <font color='rgb(%d,%d,0)'>[%d%%]</font>", dist, math.floor(c.R*255), math.floor(c.G*255), percent))
                end
            elseif typeName == "Pumpkins" then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = math.floor((root.Position - LPPos).Magnitude)
                    ensureLabel(obj, string.format("<font color='rgb(255,200,0)'>Pumpkin</font> <font color='rgb(200,200,200)'>(%d)</font>", dist))
                end
            else
                clearLabel(obj)
            end
        else
            clearHighlight(obj); clearLabel(obj)
        end
    end

    -- Player ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = getRole(p)
            local set = (role == "Killer") and espSettings.Killers or espSettings.Survivors
            if set.Enabled then
                local dist = math.floor((p.Character.HumanoidRootPart.Position - LPPos).Magnitude)
                local label = "<font color='rgb("..math.floor(set.Color.R*255)..","..math.floor(set.Color.G*255)..","..math.floor(set.Color.B*255)..")'>"..p.DisplayName.."</font>"
                if role == "Killer" then
                    label = label.." <font color='rgb(0,255,0)'>["..dist.."]</font>"
                else
                    local item = getSurvivorItem(p)
                    if item then label = label.." <font color='rgb(255,255,0)'>"..item.."</font>" end
                end
                ensureHighlight(p.Character, set.Color)
                ensureLabel(p.Character, label)
            else
                clearHighlight(p.Character); clearLabel(p.Character)
            end
        end
    end
end)

--================================================================--
-- LOW GRAPHICS
--================================================================--
local lowGraphicsEnabled = false
local originalMaterials = {}
local originalTransparencies = {}

local function applyLowGraphics()
    if lowGraphicsEnabled then return end
    lowGraphicsEnabled = true

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            originalMaterials[obj] = obj.Material
            obj.Material = Enum.Material.Plastic
        elseif (obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceGui")) and obj.Name ~= "face" then
            originalTransparencies[obj] = obj.Transparency
            obj.Transparency = 1
        end
    end

    Workspace.DescendantAdded:Connect(function(obj)
        if not lowGraphicsEnabled then return end
        if obj:IsA("BasePart") then
            originalMaterials[obj] = obj.Material
            obj.Material = Enum.Material.Plastic
        elseif (obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceGui")) and obj.Name ~= "face" then
            originalTransparencies[obj] = obj.Transparency
            obj.Transparency = 1
        end
    end)
end

local function restoreGraphics()
    lowGraphicsEnabled = false
    for obj, mat in pairs(originalMaterials) do
        if obj.Parent then
            obj.Material = mat
        end
    end
    for obj, trans in pairs(originalTransparencies) do
        if obj.Parent then
            obj.Transparency = trans
        end
    end
    originalMaterials = {}
    originalTransparencies = {}
end

--================================================================--
-- REAL BOOST SYSTEM - NO RESET, PERMANENT!
--================================================================--
local BOOST_LEVELS = {1.1, 1.2, 1.3, 1.4, 1.5}
local boostConnections = {}

local function applyBoost(attr, level)
    if not LP.Character then return end
    local mult = BOOST_LEVELS[level] or 1.0
    LP.Character:SetAttribute(attr, mult)
end

local function startBoost(attr, level, name)
    if boostConnections[attr] then return end
    
    boostConnections[attr] = RunService.Heartbeat:Connect(function()
        if LP.Character then
            applyBoost(attr, level)
        end
    end)
    
    local mult = BOOST_LEVELS[level] or 1.0
    local percent = math.round((mult - 1) * 100)
    Library:Notify({Title = name, Description = "ON - " .. mult .. "x (" .. percent .. "%) - Survivor", Time = 3})
end

local function stopBoost(attr, name)
    if boostConnections[attr] then
        boostConnections[attr]:Disconnect()
        boostConnections[attr] = nil
        Library:Notify({Title = name, Description = "OFF", Time = 2})
    end
end

--================================================================--
-- GUI
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "version: 1.7",
    Icon = 94858886314945,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- TABS
local InfoTab   = Window:AddTab("Info", "info")
local MainTab   = Window:AddTab("Main", "house")
local EspTab    = Window:AddTab("ESP", "eye")
local MiscTab   = Window:AddTab("Misc", "settings")
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
-- MAIN TAB - KILLER (LEFT) | SURVIVOR (RIGHT)
--================================================================--
local KillerLeft = MainTab:AddLeftGroupbox("KILLER FEATURE", "skull")
local PlayerLeft = MainTab:AddRightGroupbox("SURVIVOR FEATURE", "user")

-- KILLER FEATURES
KillerLeft:AddToggle("HitboxAll", {
    Text = "Hitbox Expander",
    Default = false,
    Callback = function(state)
        hitboxEnabledAll = state
        Library:Notify({Title = "Hitbox Expander", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

KillerLeft:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = 12,
    Min = 4,
    Max = 50,
    Suffix = " studs",
    Callback = function(v) headSize = v end
})

KillerLeft:AddSlider("HitboxTransparency", {
    Text = "Transparency",
    Default = 0.9,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v) hitboxTransparency = v end
})

KillerLeft:AddToggle("KillerThirdPerson", {
    Text = "Third Person (Killer Only)",
    Default = false,
    Callback = function(enabled)
        if enabled and getRole(LP) ~= "Killer" then
            Library:Notify({Title = "Error", Description = "Killer only!", Time = 2})
            Toggles.KillerThirdPerson:Set(false)
            return
        end
        if enabled then
            task.spawn(function()
                while Toggles.KillerThirdPerson.Value do
                    LP.CameraMode = Enum.CameraMode.Classic
                    LP.CameraMaxZoomDistance = 30
                    LP.CameraMinZoomDistance = 0.5
                    if Camera then Camera.FieldOfView = DESIRED_FOV end
                    task.wait()
                end
            end)
        else
            LP.CameraMode = Enum.CameraMode.LockFirstPerson
        end
    end
})

KillerLeft:AddToggle("BlockFlashlightRemote", {
    Text = "Anti-Blind",
    Default = false,
    Callback = function(enabled)
        local itemsRemote = remotes and remotes:FindFirstChild("Items")
        local gotBlinded = itemsRemote and itemsRemote:FindFirstChild("Flashlight") and itemsRemote.Flashlight:FindFirstChild("GotBlinded")
        if gotBlinded then
            if enabled then blockRemote(gotBlinded) else unblockRemote(gotBlinded) end
        end
    end
})


PlayerLeft:AddToggle("PerfectSkillCheck", {
    Text = "Perfect SkillCheck Gen",
    Default = false,
    Callback = function(enabled)
        if enabled then
            local genSkill = ReplicatedStorage.Remotes.Generator.SkillCheckEvent
            local genResult = ReplicatedStorage.Remotes.Generator.SkillCheckResultEvent
            local healSkill = ReplicatedStorage.Remotes.Healing.SkillCheckEvent
            local healResult = ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent

            genSkill.OnClientEvent:Connect(function(generator, point)
                task.spawn(function()
                    task.wait(0.05)
                    genResult:FireServer("success", 1, generator, point)
                    Library:Notify({Title = "PERFECT!", Description = "Generator Skill Check", Time = 1})
                end)
            end)

            healSkill.OnClientEvent:Connect(function(target, point)
                task.spawn(function()
                    task.wait(0.05)
                    healResult:FireServer("success", 1, target, point)
                    Library:Notify({Title = "PERFECT!", Description = "Healing Skill Check", Time = 1})
                end)
            end)

            Library:Notify({Title = "Perfect Skill Check", Description = "ON", Time = 3})
        end
    end
})
--[[
PlayerLeft:AddToggle("BlockGeneratorRemotes", {
    Text = "Anti-Fail Generator",
    Default = false,
    Callback = function(enabled)
        local gen = remotes and remotes:FindFirstChild("Generator")
        local fail = gen and gen:FindFirstChild("SkillCheckFailEvent")
        local result = gen and gen:FindFirstChild("SkillCheckResultEvent")
        if fail and result then
            if enabled then blockRemote(fail); blockRemote(result) else unblockRemote(fail); unblockRemote(result) end
        end
    end
})
]]
PlayerLeft:AddToggle("BlockHealingRemotes", {
    Text = "Perfect SkillCheck Healing",
    Default = false,
    Callback = function(enabled)
        local heal = remotes and remotes:FindFirstChild("Healing")
        local fail = heal and heal:FindFirstChild("SkillCheckFailEvent")
        local result = heal and heal:FindFirstChild("SkillCheckResultEvent")
        if fail and result then
            if enabled then blockRemote(fail); blockRemote(result) else unblockRemote(fail); unblockRemote(result) end
        end
    end
})


PlayerLeft:AddToggle("SpeedBoostToggle", {
    Text = "Speed Boost",
    Default = false,
    Callback = function(enabled)
        if enabled then startBoost("speedboost", Options.SpeedLevel.Value, "Speed Boost")
        else stopBoost("speedboost", "Speed Boost") end
    end
})

PlayerLeft:AddSlider("SpeedLevel", {
    Text = "Boost Level",
    Default = 1,
    Min = 1,
    Max = 5,
    Callback = function(level)
        if Toggles.SpeedBoostToggle.Value then
            stopBoost("speedboost", "Speed Boost")
            startBoost("speedboost", level, "Speed Boost")
        end
    end
})

PlayerLeft:AddToggle("RepairBoostToggle", {
    Text = "Repair Boost",
    Default = false,
    Callback = function(enabled)
        if enabled then startBoost("repairboost", Options.RepairLevel.Value, "Repair Boost")
        else stopBoost("repairboost", "Repair Boost") end
    end
})

PlayerLeft:AddSlider("RepairLevel", {
    Text = "Boost Level",
    Default = 1,
    Min = 1,
    Max = 5,
    Callback = function(level)
        if Toggles.RepairBoostToggle.Value then
            stopBoost("repairboost", "Repair Boost")
            startBoost("repairboost", level, "Repair Boost")
        end
    end
})

--================================================================--
-- ESP TAB (PUMPKINS TOGGLE ADDED HERE)
--================================================================--
local ESPRight = EspTab:AddLeftGroupbox("ESP FEATURE", "eye")

ESPRight:AddLabel("Halloween Event")
ESPRight:AddToggle("PumpkinsESP", {  -- PUMPKINS TOGGLE
    Text = "Pumpkins ESP",
    Default = false,
    Callback = function(v) espSettings.Pumpkins.Enabled = v end
})
ESPRight:AddDivider()
ESPRight:AddToggle("KillersESP",       { Text = "Killers ESP",       Default = false, Callback = function(v) espSettings.Killers.Enabled = v end })
ESPRight:AddToggle("SurvivorsESP",     { Text = "Survivors ESP",     Default = false, Callback = function(v) espSettings.Survivors.Enabled = v end })
ESPRight:AddToggle("GeneratorsESP",    { Text = "Generators ESP",    Default = false, Callback = function(v) espSettings.Generators.Enabled = v end })
ESPRight:AddToggle("PalletsESP",       { Text = "Pallets ESP",       Default = false, Callback = function(v) espSettings.Pallets.Enabled = v end })
ESPRight:AddToggle("ExitGatesESP",     { Text = "Exit Gates ESP",    Default = false, Callback = function(v) espSettings.ExitGates.Enabled = v end })

--================================================================--
-- MISC TAB
--================================================================--
local MiscRight = MiscTab:AddLeftGroupbox("MISC FEATURE", "settings")

MiscRight:AddSlider("FOVSlider", {
    Text = "Fov",
    Default = 95,
    Min = 70,
    Max = 150,
    Suffix = " degrees",
    Callback = function(value) DESIRED_FOV = value end
})

MiscRight:AddButton({
    Text = "Enable Day Mode",
    Func = function()
        local Lighting = game:GetService("Lighting")
        local function applyDaySettings()
            Lighting.TimeOfDay = "14:00:00"
            Lighting.ClockTime = 14
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        end
        applyDaySettings()
        for _, prop in ipairs({"TimeOfDay","ClockTime","Brightness","Ambient","OutdoorAmbient","FogEnd","FogStart","FogColor"}) do
            Lighting:GetPropertyChangedSignal(prop):Connect(applyDaySettings)
        end
        task.spawn(function() while task.wait(5) do applyDaySettings() end end)
    end
})

MiscRight:AddToggle("LowGraphics", {
    Text = "Low Graphics (FPS Boost)",
    Default = false,
    Callback = function(enabled)
        if enabled then applyLowGraphics() else restoreGraphics() end
    end
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
