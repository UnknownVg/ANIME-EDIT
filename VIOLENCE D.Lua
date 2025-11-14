--================================================================--
--                    VGXMOD HUB - VIOLENCE DISTRICT 1.7
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
    local map = workspace:FindFirstChild("Map")
    local pumpkinsFolder = map and map:FindFirstChild("Pumpkins")
    
    if pumpkinsFolder and obj.Parent == pumpkinsFolder and n:find("pumpkin") then
        trackedObjects[obj] = "Pumpkins"
        return
    end

    if n:find("generator") then trackedObjects[obj] = "Generators"
    elseif n:find("pallet") then trackedObjects[obj] = "Pallets"
    elseif n:find("gate") then trackedObjects[obj] = "ExitGates"
    elseif n:find("window") then trackedObjects[obj] = "Windows"
    end
end

for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("Model") then trackObject(v) end
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then trackObject(obj) end
end)

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
    if model and model:FindFirstChild("VD_HL") then model.VD_HL:Destroy() end
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
    if model and model:FindFirstChild("VD_Label") then model.VD_Label:Destroy() end
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
local function updateFOV()
    Camera = Workspace.CurrentCamera
    if Camera then Camera.FieldOfView = DESIRED_FOV end
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.wait(0.1)
    updateFOV()
end)

task.spawn(updateFOV)

--================================================================--
-- HITBOX SYSTEM (2 TOGGLES - UNCHANGED)
--================================================================--
local survivorHitboxes = {}
local killerHitboxes = {}
local survivorHitboxEnabled = false
local killerHitboxEnabled = false
local survivorHitboxSize = 13
local killerHitboxSize = 13
local hitboxTransparency = 0.9

local function applySurvivorHitbox(player)
    if not survivorHitboxEnabled or getRole(player) ~= "Survivor" or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or survivorHitboxes[player] then return end
    survivorHitboxes[player] = hrp
    hrp.Size = Vector3.new(survivorHitboxSize, survivorHitboxSize, survivorHitboxSize)
    hrp.Transparency = hitboxTransparency
    hrp.BrickColor = BrickColor.new("Really black")
    hrp.Material = Enum.Material.Neon
    hrp.CanCollide = false
end

local function removeSurvivorHitbox(player)
    local hrp = survivorHitboxes[player]
    if hrp and hrp.Parent then
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 0
        hrp.BrickColor = BrickColor.new("Medium stone grey")
        hrp.Material = Enum.Material.Plastic
        hrp.CanCollide = true
    end
    survivorHitboxes[player] = nil
end

local function applyKillerHitbox(player)
    if not killerHitboxEnabled or getRole(player) ~= "Killer" or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or killerHitboxes[player] then return end
    killerHitboxes[player] = hrp
    hrp.Size = Vector3.new(killerHitboxSize, killerHitboxSize, killerHitboxSize)
    hrp.Transparency = hitboxTransparency
    hrp.BrickColor = BrickColor.new("Bright red")
    hrp.Material = Enum.Material.Neon
    hrp.CanCollide = false
end

local function removeKillerHitbox(player)
    local hrp = killerHitboxes[player]
    if hrp and hrp.Parent then
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 0
        hrp.BrickColor = BrickColor.new("Medium stone grey")
        hrp.Material = Enum.Material.Plastic
        hrp.CanCollide = true
    end
    killerHitboxes[player] = nil
end

for _, p in Players:GetPlayers() do
    if p ~= LP then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if getRole(p) == "Survivor" and survivorHitboxEnabled then
                applySurvivorHitbox(p)
            elseif getRole(p) == "Killer" and killerHitboxEnabled then
                applyKillerHitbox(p)
            end
        end)
        if p.Character then
            if getRole(p) == "Survivor" and survivorHitboxEnabled then
                applySurvivorHitbox(p)
            elseif getRole(p) == "Killer" and killerHitboxEnabled then
                applyKillerHitbox(p)
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(p)
    removeSurvivorHitbox(p)
    removeKillerHitbox(p)
end)

RunService.Heartbeat:Connect(function()
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            local role = getRole(p)
            if role == "Survivor" then
                if survivorHitboxEnabled then applySurvivorHitbox(p) else removeSurvivorHitbox(p) end
            elseif role == "Killer" then
                if killerHitboxEnabled then applyKillerHitbox(p) else removeKillerHitbox(p) end
            end
        end
    end
end)

local function updateHitboxSizes()
    for player, hrp in pairs(survivorHitboxes) do
        if hrp and hrp.Parent then
            hrp.Size = Vector3.new(survivorHitboxSize, survivorHitboxSize, survivorHitboxSize)
        end
    end
    for player, hrp in pairs(killerHitboxes) do
        if hrp and hrp.Parent then
            hrp.Size = Vector3.new(killerHitboxSize, killerHitboxSize, killerHitboxSize)
        end
    end
end

local function updateHitboxTransparency()
    for _, tbl in pairs({survivorHitboxes, killerHitboxes}) do
        for _, hrp in pairs(tbl) do
            if hrp and hrp.Parent then hrp.Transparency = hitboxTransparency end
        end
    end
end

--================================================================--
-- ESP LOOP
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
        if obj.Parent then obj.Material = mat end
    end
    for obj, trans in pairs(originalTransparencies) do
        if obj.Parent then obj.Transparency = trans end
    end
    originalMaterials = {}
    originalTransparencies = {}
end

--================================================================--
-- REAL BOOST SYSTEM
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
        if LP.Character then applyBoost(attr, level) end
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
-- CROSSHAIR
--================================================================--
local crosshairEnabled = false
local lineCount = 4
local radius = 7
local lineLength = 15
local lineColor = Color3.fromRGB(128, 0, 255)
local thickness = 2
local rotationSpeed = 0.05

local lines = {}
for i = 1, lineCount do
    local line = Drawing.new("Line")
    line.Color = lineColor
    line.Thickness = thickness
    line.Visible = crosshairEnabled
    table.insert(lines, line)
end

local dot = Drawing.new("Circle")
dot.Radius = 2
dot.Filled = true
dot.Color = lineColor
dot.Visible = crosshairEnabled

local angle = 0
RunService.RenderStepped:Connect(function()
    if not crosshairEnabled then
        for _, line in ipairs(lines) do line.Visible = false end
        dot.Visible = false
        return
    end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for i, line in ipairs(lines) do
        local a = angle + (math.pi * 2 / lineCount) * (i - 1)
        local from = Vector2.new(center.X + math.cos(a) * radius, center.Y + math.sin(a) * radius)
        local to = Vector2.new(center.X + math.cos(a) * (radius + lineLength), center.Y + math.sin(a) * (radius + lineLength))
        line.From = from
        line.To = to
        line.Color = lineColor
        line.Visible = true
    end

    dot.Position = center
    dot.Color = lineColor
    dot.Visible = true
    angle = angle + rotationSpeed
end)

--================================================================--
-- AUTO SAFE KILLER
--================================================================--
local autoSafeEnabled = false
local autoSafeDistance = 50
local safeConnection
local lastTpTime = 0

local function findSafeObjectAwayFromKiller()
    local lpPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not lpPos then return nil end
    
    local safeObjects = {}
    for obj, typeName in pairs(trackedObjects) do
        if obj and obj.Parent and (typeName == "Generators" or typeName == "Pallets") then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if root then
                local distToPlayer = (root.Position - lpPos.Position).Magnitude
                safeObjects[#safeObjects + 1] = {obj = root, dist = distToPlayer}
            end
        end
    end
    
    local nearestKillerPos = lpPos.Position
    local nearestKillerDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and getRole(p) == "Killer" then
            local dist = (p.Character.HumanoidRootPart.Position - lpPos.Position).Magnitude
            if dist < nearestKillerDist then
                nearestKillerDist = dist
                nearestKillerPos = p.Character.HumanoidRootPart.Position
            end
        end
    end
    
    local validSafes = {}
    for _, safe in ipairs(safeObjects) do
        local distToKiller = (safe.obj.Position - nearestKillerPos).Magnitude
        if distToKiller > autoSafeDistance * 1.5 then
            validSafes[#validSafes + 1] = safe
        end
    end
    
    if #validSafes == 0 then return nil end
    
    local randomSafe = validSafes[math.random(1, #validSafes)]
    return randomSafe.obj
end

local function tpToSafe()
    local safeObj = findSafeObjectAwayFromKiller()
    if safeObj and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local tpCFrame = safeObj.CFrame + Vector3.new(math.random(-8,8), 3, math.random(-8,8))
        LP.Character.HumanoidRootPart.CFrame = tpCFrame
        Library:Notify({Title = "AUTO SAFE", Description = "Teleported to SAFE spot!", Time = 2})
    end
end

local function startAutoSafe()
    if safeConnection then return end
    safeConnection = RunService.Heartbeat:Connect(function()
        if not autoSafeEnabled or getRole(LP) ~= "Survivor" or not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local currentTime = tick()
        if currentTime - lastTpTime < 3 then return end
        
        local lpPos = LP.Character.HumanoidRootPart.Position
        local nearestKillerDist = math.huge
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and getRole(p) == "Killer" then
                local dist = (p.Character.HumanoidRootPart.Position - lpPos).Magnitude
                if dist < nearestKillerDist then nearestKillerDist = dist end
            end
        end
        
        if nearestKillerDist <= autoSafeDistance then
            tpToSafe()
            lastTpTime = currentTime
        end
    end)
end

local function stopAutoSafe()
    if safeConnection then
        safeConnection:Disconnect()
        safeConnection =  nil
    end
end

--================================================================--
-- GUI - LAYOUT ONLY (EXACTLY AS REQUESTED)
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "version: 1.7",
    Icon = 94858886314945,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- TABS
local InfoTab       = Window:AddTab("Info", "info")
local SurvivorTab   = Window:AddTab("Survivor", "user")
local KillerTab     = Window:AddTab("Killer", "sword")
local EspTab        = Window:AddTab("Visual", "eye")
local MiscTab       = Window:AddTab("Misc", "settings")
local SettingsTab   = Window:AddTab("Settings", "cog")

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
-- KILLER TAB
--================================================================--
local KillerLeft  = KillerTab:AddLeftGroupbox("HITBOX", "scan")
local KillerRight = KillerTab:AddRightGroupbox("KILLER", "skull")

KillerLeft:AddToggle("KillerHitbox", {
    Text = "Hitbox (Killer)",
    Default = false,
    Callback = function(state)
        killerHitboxEnabled = state
        Library:Notify({Title = "Killer Hitbox", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

KillerLeft:AddSlider("KillerHitboxSize", {
    Text = "Hitbox Size (Killer)",
    Default = 13,
    Min = 4,
    Max = 20,
    Suffix = " studs",
    Callback = function(v)
        killerHitboxSize = v
        updateHitboxSizes()
    end
})

KillerLeft:AddSlider("HitboxTransparency", {
    Text = "Transparency",
    Default = 0.9,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        hitboxTransparency = v
        updateHitboxTransparency()
    end
})

KillerRight:AddToggle("KillerThirdPerson", {
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

KillerRight:AddToggle("BlockFlashlightRemote", {
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

--================================================================--
-- SURVIVOR TAB
--================================================================--
local SurvivorLeft    = SurvivorTab:AddLeftGroupbox("HITBOX", "scan")
local AutomationLeft  = SurvivorTab:AddLeftGroupbox("AUTOMATION", "cpu")
local SurvivorRight   = SurvivorTab:AddRightGroupbox("SURVIVOR", "user")

-- HITBOX (LEFT - TOP)
SurvivorLeft:AddToggle("SurvivorHitbox", {
    Text = "Hitbox (Survivor)",
    Default = false,
    Callback = function(state)
        survivorHitboxEnabled = state
        Library:Notify({Title = "Survivor Hitbox", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

SurvivorLeft:AddSlider("SurvivorHitboxSize", {
    Text = "Hitbox Size (Survivor)",
    Default = 13,
    Min = 4,
    Max = 20,
    Suffix = " studs",
    Callback = function(v)
        survivorHitboxSize = v
        updateHitboxSizes()
    end
})

-- AUTOMATION (LEFT - BOTTOM)
AutomationLeft:AddToggle("AutoSafeKiller", {
    Text = "Auto Safe (Survivor)",
    Default = false,
    Callback = function(enabled)
        autoSafeEnabled = enabled
        if enabled then 
            startAutoSafe()
            Library:Notify({Title = "Auto Safe", Description = "ON - " .. autoSafeDistance .. " studs", Time = 3})
        else 
            stopAutoSafe()
            Library:Notify({Title = "Auto Safe", Description = "OFF", Time = 2})
        end
    end
})

AutomationLeft:AddSlider("AutoSafeDistance", {
    Text = "Trigger Distance",
    Default = 50,
    Min = 10,
    Max = 200,
    Suffix = " studs",
    Callback = function(value)
        autoSafeDistance = value
        if autoSafeEnabled then
            Library:Notify({Title = "Auto Safe", Description = "Distance: " .. value .. " studs", Time = 2})
        end
    end
})

-- SURVIVOR FEATURES (RIGHT)
SurvivorRight:AddToggle("PerfectSkillCheck", {
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

SurvivorRight:AddToggle("BlockHealingRemotes", {
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

SurvivorRight:AddButton({
    Text = "Instant Escape",
    Func = function()
        local playerName = LP.Name
        local playerFolder = workspace:FindFirstChild(playerName)
        if not playerFolder then
            Library:Notify({Title = "Error", Description = "You're spectator!", Time = 3})
            return
        end
        
        local skillGen = playerFolder:FindFirstChild("Skillcheck-gen")
        local skillPlayer = playerFolder:FindFirstChild("Skillcheck-player")
        if not skillGen or not skillPlayer then
            Library:Notify({Title = "Error", Description = "You're spectator!", Time = 3})
            return
        end
        
        local finishline = Workspace.Map:FindFirstChild("Fininshline")
        if not finishline then
            Library:Notify({Title = "Error", Description = "Fininshline not found!", Time = 3})
            return
        end
        
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            hrp.CFrame = finishline.CFrame + Vector3.new(0, 5, 0)
            Library:Notify({Title = "SUCCESS", Description = "Instant Escape!", Time = 3})
        end
    end
})

SurvivorRight:AddToggle("SpeedBoostToggle", {
    Text = "Speed Boost",
    Default = false,
    Callback = function(enabled)
        if enabled then startBoost("speedboost", Options.SpeedLevel.Value, "Speed Boost")
        else stopBoost("speedboost", "Speed Boost") end
    end
})

SurvivorRight:AddSlider("SpeedLevel", {
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

SurvivorRight:AddToggle("RepairBoostToggle", {
    Text = "Repair Boost",
    Default = false,
    Callback = function(enabled)
        if enabled then startBoost("repairboost", Options.RepairLevel.Value, "Repair Boost")
        else stopBoost("repairboost", "Repair Boost") end
    end
})

SurvivorRight:AddSlider("RepairLevel", {
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
-- VISUAL TAB
--================================================================--
local ESPRight = EspTab:AddLeftGroupbox("ESP", "eye")

ESPRight:AddLabel("Halloween Event")
ESPRight:AddToggle("PumpkinsESP", {  
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
local MiscRight = MiscTab:AddRightGroupbox("MISC", "sun")

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

local CrosshairRight = MiscTab:AddLeftGroupbox("CROSSHAIR", "crosshair")

CrosshairRight:AddToggle("CrosshairToggle", {
    Text = "Enable Crosshair",
    Default = false,
    Callback = function(state)
        crosshairEnabled = state
        for _, line in ipairs(lines) do line.Visible = state end
        dot.Visible = state
        Library:Notify({Title = "Crosshair", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

CrosshairRight:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColor", {
    Default = lineColor,
    Title = "Pick Crosshair Color",
    Callback = function(value)
        lineColor = value
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
