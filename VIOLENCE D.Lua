local targetPlaceId = 93978595733734

if game.PlaceId ~= targetPlaceId then
    return
end
--================================================================--
--                    VGXMOD HUB
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
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

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

-- ESP SETTINGS (PUMPKINS REMOVED)
local espSettings = {
    Survivors  = {Enabled=false, Color=Color3.fromRGB(255,255,255), Transparency=0.9},
    Killers    = {Enabled=false, Color=Color3.fromRGB(255,0,0), Transparency=0.5},
    Generators = {Enabled=false, Color=Color3.fromRGB(0,170,255), Transparency=0.6},
    Pallets    = {Enabled=false, Color=Color3.fromRGB(139,69,19), Transparency=0.6},
    ExitGates  = {Enabled=false, Color=Color3.fromRGB(0,255,0), Transparency=0.5},
    Windows    = {Enabled=false, Color=Color3.fromRGB(0,255,255), Transparency=0.6}
}

local savedPositions = {}
local flipGui = nil

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
-- TRACK OBJECTS (PUMPKINS REMOVED)
--================================================================--
local trackedObjects = {}

local function trackObject(obj)
    if not obj or not obj.Name then return end
    local n = obj.Name:lower()

    if n:find("generator") then
        trackedObjects[obj] = "Generators"
    elseif n:find("pallet") then
        trackedObjects[obj] = "Pallets"
    elseif n:find("gate") then
        trackedObjects[obj] = "ExitGates"
    elseif n:find("window") then
        trackedObjects[obj] = "Windows"
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
-- HITBOX SYSTEM
--================================================================--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local survivorHitboxes = {}
local killerHitboxes = {}

local survivorHitboxEnabled = false
local killerHitboxEnabled = false

local survivorHitboxSize = 13
local killerHitboxSize = 13
local hitboxTransparency = 0.9

local lastRole = {}

local function applySurvivorHitbox(player)
    if not survivorHitboxEnabled or getRole(player) ~= "Survivor" then return end
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
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
    if not killerHitboxEnabled or getRole(player) ~= "Killer" then return end
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
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
            local role = getRole(p)
            lastRole[p] = role
            if role == "Survivor" and survivorHitboxEnabled then
                applySurvivorHitbox(p)
            elseif role == "Killer" and killerHitboxEnabled then
                applyKillerHitbox(p)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        local role = getRole(p)
        lastRole[p] = role
        if role == "Survivor" and survivorHitboxEnabled then
            applySurvivorHitbox(p)
        elseif role == "Killer" and killerHitboxEnabled then
            applyKillerHitbox(p)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    removeSurvivorHitbox(p)
    removeKillerHitbox(p)
    lastRole[p] = nil
end)

RunService.Heartbeat:Connect(function()
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            local role = getRole(p)

            if lastRole[p] ~= role then
                removeSurvivorHitbox(p)
                removeKillerHitbox(p)
            end

            if role == "Survivor" then
                if survivorHitboxEnabled then applySurvivorHitbox(p) else removeSurvivorHitbox(p) end
            elseif role == "Killer" then
                if killerHitboxEnabled then applyKillerHitbox(p) else removeKillerHitbox(p) end
            else
                removeSurvivorHitbox(p)
                removeKillerHitbox(p)
            end

            lastRole[p] = role
        end
    end
end)

local function updateHitboxSizes()
    for _, hrp in pairs(survivorHitboxes) do
        if hrp and hrp.Parent then
            hrp.Size = Vector3.new(survivorHitboxSize, survivorHitboxSize, survivorHitboxSize)
        end
    end
    for _, hrp in pairs(killerHitboxes) do
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
-- FULL BRIGHTNESS
--================================================================--
local FullBright = false

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart
}

local function ApplyFullBright()
    pcall(function()
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = math.huge
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.FogStart = math.huge
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or 
               effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect") or 
               effect:IsA("SunRaysEffect") then
                pcall(function() effect:Destroy() end)
            end
        end
    end)
end

local function RestoreLighting()
    pcall(function()
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.FogStart = OriginalLighting.FogStart
    end)
end

-- Monitor lighting changes to reapply fullbright only when needed
local lightingConnection
local childConnection
local function MonitorLighting()
    if lightingConnection then lightingConnection:Disconnect() end
    if childConnection then childConnection:Disconnect() end
    if FullBright then
        ApplyFullBright()
        lightingConnection = Lighting.Changed:Connect(function(property)
            if FullBright then
                task.wait()
                ApplyFullBright()
            end
        end)
        childConnection = Lighting.ChildAdded:Connect(function(child)
            if FullBright and (child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("BlurEffect") or 
               child:IsA("ColorCorrectionEffect") or child:IsA("DepthOfFieldEffect") or 
               child:IsA("SunRaysEffect")) then
                task.wait()
                ApplyFullBright()
            end
        end)
    else
        RestoreLighting()
        lightingConnection = nil
        childConnection = nil
    end
end
--================================================================--
-- SERVICES & PLAYER
--================================================================--


local savedPositions = {}
local flipGui = nil


--================================================================--
-- SAFE DRAG SYSTEM (NO VIBRATE, NO ACCIDENTAL CLICK)
--================================================================--
local function MakeSafeDrag(Button, onClick)
    local dragging = false
    local moved = false
    local dragStart, startPos

    Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = Button.Position
        end
    end)

    Button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
        or input.UserInputType == Enum.UserInputType.Touch) then
            moved = true
            local delta = input.Position - dragStart

            Button.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    Button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false

            if moved == false then
                onClick()
            end
        end
    end)
end


--================================================================--
-- FLIP SYSTEM
--================================================================--
local function PerformFrontflip()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local animator = hum and hum:FindFirstChildOfClass("Animator")

    if not (hum and hrp) then return end

    if char:FindFirstChild("Animate") then
        char.Animate.Disabled = true
    end

    if animator then
        for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do tr:Stop() end
    end

    for _, s in ipairs({
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Running,
        Enum.HumanoidStateType.Seated,
        Enum.HumanoidStateType.Climbing
    }) do hum:SetStateEnabled(s, false) end

    hum:ChangeState(Enum.HumanoidStateType.Physics)

    local duration, steps = 0.45, 120
    local cf = hrp.CFrame
    local dir = cf.LookVector
    local up = Vector3.yAxis

    task.spawn(function()
        local t0 = tick()
        for i = 1, steps do
            local t = i / steps
            local y = 4 * (t - t*t) * 10
            local pos = cf.Position + dir*(35*t) + up*y
            local rot = CFrame.Angles(-math.rad(360*t), 0, 0)

            hrp.CFrame = CFrame.new(pos) * cf.Rotation * rot

            local waitTime = (duration/steps)*i - (tick() - t0)
            if waitTime > 0 then task.wait(waitTime) end
        end

        hrp.CFrame = CFrame.new(cf.Position + dir*35) * cf.Rotation

        for _, s in ipairs({
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.Climbing
        }) do hum:SetStateEnabled(s, true) end

        hum:ChangeState(Enum.HumanoidStateType.Running)
        char.Animate.Disabled = false
    end)
end


local function PerformBackflip()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local animator = hum and hum:FindFirstChildOfClass("Animator")

    if not (hum and hrp) then return end

    if char:FindFirstChild("Animate") then
        char.Animate.Disabled = true
    end

    if animator then
        for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do tr:Stop() end
    end

    for _, s in ipairs({
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Running,
        Enum.HumanoidStateType.Seated,
        Enum.HumanoidStateType.Climbing
    }) do hum:SetStateEnabled(s, false) end

    hum:ChangeState(Enum.HumanoidStateType.Physics)

    local duration, steps = 0.45, 120
    local cf = hrp.CFrame
    local dir = -cf.LookVector
    local up = Vector3.yAxis

    task.spawn(function()
        local t0 = tick()
        for i = 1, steps do
            local t = i / steps
            local y = 4 * (t - t*t) * 10
            local pos = cf.Position + dir*(35*t) + up*y
            local rot = CFrame.Angles(math.rad(360*t), 0, 0)

            hrp.CFrame = CFrame.new(pos) * cf.Rotation * rot

            local waitTime = (duration/steps)*i - (tick() - t0)
            if waitTime > 0 then task.wait(waitTime) end
        end

        hrp.CFrame = CFrame.new(cf.Position + dir*35) * cf.Rotation

        for _, s in ipairs({
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.Climbing
        }) do hum:SetStateEnabled(s, true) end

        hum:ChangeState(Enum.HumanoidStateType.Running)
        char.Animate.Disabled = false
    end)
end


--================================================================--
-- PC / MOBILE DETECTION
--================================================================--
local function isMobile()
    return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

local function isPC()
    return UIS.KeyboardEnabled
end


--================================================================--
-- PC KEYBINDS (Q = Frontflip, E = Backflip)
--================================================================--
local pcKeybindsEnabled = false

local function enablePCMode()
    if pcKeybindsEnabled then return end
    pcKeybindsEnabled = true

    Library:Notify({
        Title = "Flip Controls",
        Description = "Press Q = Frontflip\nPress E = Backflip",
        Time = 4
    })

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not pcKeybindsEnabled then return end

        if input.KeyCode == Enum.KeyCode.Q then
            PerformFrontflip()
        elseif input.KeyCode == Enum.KeyCode.E then
            PerformBackflip()
        end
    end)
end


--================================================================--
-- FLIP UI SYSTEM
--================================================================--
local function safeGetPlayerGui()
    return LP:WaitForChild("PlayerGui")
end


local function _internalCreateFlipUI()
    local guip = safeGetPlayerGui()
    if guip:FindFirstChild("FlipGui") then
        guip.FlipGui:Destroy()
    end

    local ui = Instance.new("ScreenGui")
    ui.Name = "FlipGui"
    ui.ResetOnSpawn = false
    ui.Parent = guip
    flipGui = ui

    local function createButton(id, text, pos, onClick)
        local btn = Instance.new("TextButton")
        btn.Name = id
        btn.Size = UDim2.new(0, 80, 0, 80)
        btn.Position = savedPositions[id] or pos
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.BackgroundColor3 = Color3.new(0, 0, 0)
        btn.BackgroundTransparency = 0.5
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 12
        btn.TextWrapped = true
        btn.AutoButtonColor = false
        btn.Parent = ui

        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local border = Instance.new("UIStroke", btn)
        border.Thickness = 2
        border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        border.Color = Color3.fromRGB(128, 0, 255)

        btn:GetPropertyChangedSignal("Position"):Connect(function()
            savedPositions[id] = btn.Position
        end)

        MakeSafeDrag(btn, onClick)
    end

    createButton("F-Flip", "F-Flip", UDim2.new(0.5, -60, 0.5, 0), PerformFrontflip)
    createButton("B-Flip", "B-Flip", UDim2.new(0.5, 60, 0.5, 0), PerformBackflip)
end


-- override UI creation with device check
local function createFlipUI()
    if isPC() then
        enablePCMode()
        return
    end

    _internalCreateFlipUI()
end


--================================================================--
-- TOGGLE HANDLER
--================================================================--
if Toggles and Toggles.FlipUIToggle then
    Toggles.FlipUIToggle:OnChanged(function(state)
        if state then
            createFlipUI()
        else
            pcKeybindsEnabled = false

            local gui = LP:FindFirstChild("PlayerGui")
            if gui and gui:FindFirstChild("FlipGui") then
                gui.FlipGui:Destroy()
            end
        end
    end)
end


--================================================================--
-- RESPAWN RESTORE
--================================================================--
LP.CharacterAdded:Connect(function()
    if Toggles and Toggles.FlipUIToggle and Toggles.FlipUIToggle.Value then
        task.wait(0.5)
        createFlipUI()
    end
end)


--==============================================================
-- EMOTE LIST
--==============================================================

local emotes = {
    ["24 Hour Cinderella"] = {
        anim = "rbxassetid://137195203725366",
        song = "rbxassetid://121099446613414"
    },

    ["Backflip"] = {
        anim = "rbxassetid://74705617908505"
    },

    ["Applause"] = {
        anim = "rbxassetid://96328361165090",
        song = "rbxassetid://115490787020749"
    },

    ["Arm Swing"] = {
        anim = "rbxassetid://80552139463944",
        song = "rbxassetid://74216458932348"
    },

    ["California Girls"] = {
        anim = "rbxassetid://123552803041504",
        song = "rbxassetid://87899327891544"
    },

    ["Floating Rest"] = {
        anim = "rbxassetid://114593021219597"
    },

    ["Ghouls"] = {
        anim = "rbxassetid://130415594909401",
        song = "rbxassetid://123004139176580"
    },

    ["Griddy"] = {
        anim = "rbxassetid://75586690784894"
    },

    ["Kyoufuu"] = {
        anim = "rbxassetid://137322894494527",
        song = "rbxassetid://129064643026442"
    },

    ["Rambunctious"] = {
        anim = "rbxassetid://81054496834622"
    },

    ["Rampage"] = {
        anim = "rbxassetid://79155929355612"
    },

    ["Schadenfreude"] = {
        anim = "rbxassetid://138303785534052",
        song = "rbxassetid://92070710839040"
    },

    ["Source"] = {
        anim = "rbxassetid://117228494282496"
    },

    ["Static"] = {
        anim = "rbxassetid://95096724457263",
        song = "rbxassetid://70950516511572"
    },

    ["Dap"] = {
        anim = "rbxassetid://93350677984372"
    },

    ["Thriller"] = {
        anim = "rbxassetid://99835792883875",
        song = "rbxassetid://139985043810748"
    },

    ["Wave"] = {
        anim = "rbxassetid://99670106766588"
    }
}

--==============================================================
-- SERVICES & STATE
--==============================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local char        -- current character instance
local hum         -- current humanoid
local soundFolder -- folder inside character for sounds

local currentAnimTrack
local currentSound

--================================================================--
-- EMOTE SYSTEM 
--================================================================--
local function stopCurrentEmote()
    -- safe stop
    if currentAnimTrack and currentAnimTrack.IsPlaying then
        pcall(function() currentAnimTrack:Stop() end)
    end
    currentAnimTrack = nil

    if currentSound then
        pcall(function() currentSound:Stop() end)
        if currentSound.Parent then
            pcall(function() currentSound:Destroy() end)
        end
        currentSound = nil
    end
end

local function playEmote(name)
    -- ensure humanoid and soundFolder exist
    if not hum or not hum.Parent then
        warn("Humanoid not ready; can't play emote.")
        return
    end

    stopCurrentEmote()

    local data = emotes[name]
    if not data then
        warn("Emote not found:", tostring(name))
        return
    end

    -- Play animation (safe pcall in case animation fails)
    local anim = Instance.new("Animation")
    anim.AnimationId = data.anim or ""
    local ok, track = pcall(function()
        return hum:LoadAnimation(anim)
    end)
    if ok and track then
        currentAnimTrack = track
        pcall(function() currentAnimTrack:Play() end)
    else
        warn("Failed to load/play animation:", tostring(name))
    end

    -- Play song (loop enabled) if available
    if data.song and soundFolder and soundFolder.Parent then
        local sound = Instance.new("Sound")
        sound.SoundId = data.song
        sound.Volume = 1
        sound.Looped = true
        sound.Parent = soundFolder
        local success, err = pcall(function() sound:Play() end)
        if success then
            currentSound = sound
        else
            warn("Failed to play sound for emote:", tostring(name), err)
            sound:Destroy()
        end
    end
end

--==============================================================
-- CHARACTER SETUP & RESPAWN HANDLING
--==============================================================
local function setupCharacter(newChar)
    if not newChar then return end

    -- clear previous references safely
    stopCurrentEmote()

    char = newChar
    hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")

    -- create/recreate sound folder
    if soundFolder and soundFolder.Parent then
        pcall(function() soundFolder:Destroy() end)
    end
    soundFolder = Instance.new("Folder")
    soundFolder.Name = "EmoteSounds"
    soundFolder.Parent = char
end

-- Connect CharacterAdded AFTER functions are defined
player.CharacterAdded:Connect(function(newChar)
    -- small delay to ensure character fully initializes
    -- (avoids race if CharacterAdded fires very early)
    task.wait(0.05)
    setupCharacter(newChar)
end)

-- initial setup (if character already exists)
if player.Character then
    setupCharacter(player.Character)
else
    player.CharacterAdded:Wait()
    setupCharacter(player.Character)
end



--================================================================--
-- GODMOD BETA SYSTEM 
--================================================================--
local hasTeleported = false

local function hasSkillcheck()
    local playerFolder = workspace:FindFirstChild(LP.Name)
    if not playerFolder then return false end
    local skillGen = playerFolder:FindFirstChild("Skillcheck-gen")
    local skillPlayer = playerFolder:FindFirstChild("Skillcheck-player")
    return skillGen and skillPlayer
end

local function fireSkillcheckTouch()
    if not hasSkillcheck() then return false end
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local finishline = workspace.Map:FindFirstChild("Fininshline")
    if not finishline then return false end
    local hrp = char.HumanoidRootPart
    for _, obj in ipairs(finishline:GetChildren()) do
        if obj:IsA("TouchTransmitter") or obj:IsA("TouchInterest") then
            firetouchinterest(hrp, finishline, 0)
            firetouchinterest(hrp, finishline, 1)
        end
    end
    return true
end

local function teleportToSurvivorSpawn()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local spawn = workspace.Map:FindFirstChild("SurvivorSpawn")
    if not spawn then return end
    char.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 17
    end
end


--================================================================--
-- BLOCK KILLER VIEW
--================================================================--

local followKiller = false

local function getRole(p)
    if p and p.Team and p.Team.Name then
        local n = p.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

local function getKiller()
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= LP and getRole(plr) == "Killer" then
            return plr
        end
    end
    return nil
end

local function fireSkillcheckTouchIfNeeded()
    local playerFolder = workspace:FindFirstChild(LP.Name)
    if not playerFolder then return false end

    local skillGen = playerFolder:FindFirstChild("Skillcheck-gen")
    local skillPlayer = playerFolder:FindFirstChild("Skillcheck-player")
    if not skillGen or not skillPlayer then return false end

    local finishline = workspace.Map:FindFirstChild("Fininshline")
    if not finishline then return true end

    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end

    for _, obj in ipairs(finishline:GetChildren()) do
        if obj:IsA("TouchTransmitter") or obj:IsA("TouchInterest") then
            firetouchinterest(hrp, finishline, 0)
            firetouchinterest(hrp, finishline, 1)
        end
    end
    return true
end

RunService.Heartbeat:Connect(function()
    if not followKiller then return end

    local killer = getKiller()
    if not killer or not killer.Character then return end

    local killerHRP = killer.Character:FindFirstChild("HumanoidRootPart")
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not killerHRP or not myHRP then return end

    fireSkillcheckTouchIfNeeded()

    local forwardOffset = 3
    local upwardOffset = 1
    local targetCFrame = killerHRP.CFrame + (killerHRP.CFrame.LookVector * forwardOffset) + Vector3.new(0, upwardOffset, 0)
    myHRP.CFrame = targetCFrame
end)

--================================================================--
-- RAPID ATTACK
--================================================================--
local BasicAttack = ReplicatedStorage.Remotes.Attacks.BasicAttack
local AfterAttack = ReplicatedStorage.Remotes.Attacks.AfterAttack

local rapidAttack = false
local attackDelay = 0.1
local savedPositions = {}
local rapidAttackGui

local function startRapidAttack()
rapidAttack = true
task.spawn(function()
while rapidAttack do
BasicAttack:FireServer()
firesignal(AfterAttack.OnClientEvent, "Nothing")
task.wait(attackDelay)
end
end)
end

local function stopRapidAttack()
rapidAttack = false
end

local function safeGetPlayerGui()
return LP:WaitForChild("PlayerGui")
end

local function MakeSafeDrag(frame, onClick)
local dragging = false
local dragInput, mousePos, framePos

frame.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
mousePos = input.Position
framePos = frame.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
dragging = false
if onClick then onClick() end
end
end)
end
end)

frame.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - mousePos
frame.Position = framePos + UDim2.new(0, delta.X, 0, delta.Y)
end
end)

end

local function createRapidAttackUI()
local guip = safeGetPlayerGui()
if guip:FindFirstChild("RapidAttackGui") then
guip.RapidAttackGui:Destroy()
end

rapidAttackGui = Instance.new("ScreenGui")
rapidAttackGui.Name = "RapidAttackGui"
rapidAttackGui.ResetOnSpawn = false
rapidAttackGui.Parent = guip

local function createButton(id, text, pos)
local btn = Instance.new("TextButton")
btn.Name = id
btn.Size = UDim2.new(0, 80, 0, 80)
btn.Position = savedPositions[id] or pos
btn.AnchorPoint = Vector2.new(0.5, 0.5)
btn.BackgroundColor3 = Color3.new(0, 0, 0)
btn.BackgroundTransparency = 0.5
btn.Text = text
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBlack
btn.TextSize = 12
btn.TextWrapped = true
btn.AutoButtonColor = false
btn.Parent = rapidAttackGui

Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)    
local border = Instance.new("UIStroke", btn)    
border.Thickness = 2    
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border    
border.Color = Color3.fromRGB(128, 0, 255)    

btn:GetPropertyChangedSignal("Position"):Connect(function()    
    savedPositions[id] = btn.Position    
end)    

MakeSafeDrag(btn, function()    
    rapidAttack = not rapidAttack    
    if rapidAttack then    
        btn.Text = "Rapid ON"    
        startRapidAttack()    
    else    
        btn.Text = "Rapid OFF"    
        stopRapidAttack()    
    end    
end)

end

createButton("RapidAttackBtn", "Rapid OFF", UDim2.new(0.5, 0, 0.8, 0))

end
--====================================================
-- SPEED KILLER SYSTEM 
--====================================================

-- anti blind
local function GetGotBlindedRemote()
    if not remotes then return nil end
    local itemsRemote = remotes:FindFirstChild("Items")
    if not itemsRemote then return nil end
    local flashlightRemote = itemsRemote:FindFirstChild("Flashlight")
    if not flashlightRemote then return nil end
    return flashlightRemote:FindFirstChild("GotBlinded")
end

local function EnableAntiBlind()
    local gotBlinded = GetGotBlindedRemote()
    if gotBlinded then
        blockRemote(gotBlinded)
    end
end

local function DisableAntiBlind()
    local gotBlinded = GetGotBlindedRemote()
    if gotBlinded then
        unblockRemote(gotBlinded)
    end
end



-- perfect skill check gen
local function PerfectGeneratorSkillCheck(generator, point)
    task.spawn(function()
        task.wait(0.05)
        ReplicatedStorage.Remotes.Generator.SkillCheckResultEvent:FireServer("success", 1, generator, point)
        Library:Notify({Title = "PERFECT!", Description = "Generator Skill Check", Time = 1})
    end)
end

local function PerfectHealingSkillCheck(target, point)
    task.spawn(function()
        task.wait(0.05)
        ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent:FireServer("success", 1, target, point)
        Library:Notify({Title = "PERFECT!", Description = "Healing Skill Check", Time = 1})
    end)
end

local function EnablePerfectSkillCheck()
    local genSkill = ReplicatedStorage.Remotes.Generator.SkillCheckEvent
    local healSkill = ReplicatedStorage.Remotes.Healing.SkillCheckEvent

    genSkill.OnClientEvent:Connect(PerfectGeneratorSkillCheck)
    healSkill.OnClientEvent:Connect(PerfectHealingSkillCheck)

    Library:Notify({Title = "Perfect Skill Check", Description = "ON", Time = 3})
end



--perfect skill check healing 
local function GetHealingRemotes()
    if not remotes then return nil, nil end
    local heal = remotes:FindFirstChild("Healing")
    if not heal then return nil, nil end
    return heal:FindFirstChild("SkillCheckFailEvent"), heal:FindFirstChild("SkillCheckResultEvent")
end

local function EnableBlockHealingRemotes()
    local fail, result = GetHealingRemotes()
    if fail and result then
        blockRemote(fail)
        blockRemote(result)
    end
end

local function DisableBlockHealingRemotes()
    local fail, result = GetHealingRemotes()
    if fail and result then
        unblockRemote(fail)
        unblockRemote(result)
    end
end


-- instant escape 
local function IsSpectator()
    local playerFolder = workspace:FindFirstChild(LP.Name)
    if not playerFolder then return true end
    local skillGen = playerFolder:FindFirstChild("Skillcheck-gen")
    local skillPlayer = playerFolder:FindFirstChild("Skillcheck-player")
    if not skillGen or not skillPlayer then return true end
    return false
end

local function GetHumanoidRootPart()
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart
    end
end

local function GetFinishLine()
    return workspace.Map:FindFirstChild("Fininshline")
end

local function TouchFinishLine(hrp, finishline)
    for _, obj in pairs(finishline:GetChildren()) do
        if obj:IsA("TouchTransmitter") or obj:IsA("TouchInterest") then
            firetouchinterest(hrp, finishline, 0)
            firetouchinterest(hrp, finishline, 1)
        end
    end
end

local function InstantEscape()
    local hrp = GetHumanoidRootPart()
    if not hrp then return end
    if IsSpectator() then
        Library:Notify({Title="Error", Description="You are Spectator!", Time=3})
        return
    end
    local finishline = GetFinishLine()
    if not finishline then return end
    TouchFinishLine(hrp, finishline)
end

--tp lobby
local function TeleportToLobby()
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0, 5, 0)
        Library:Notify({Title = "Teleported", Description = "You are in the Lobby!", Time = 3})
    end
end


-- tp in-game

local function TeleportToInGame()
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local spawn = workspace.Map:FindFirstChild("SurvivorSpawn")
        if spawn then
            char.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            Library:Notify({Title = "Teleported", Description = "You are In-Game!", Time = 3})
        else
            Library:Notify({Title = "Error", Description = "In-Game spawn not found!", Time = 3})
        end
    end
end


-- tp killer
local function TeleportToKiller()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    for _, player in pairs(game.Players:GetPlayers()) do
        if getRole(player) == "Killer" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
            Library:Notify({Title="Teleported", Description="To Killer", Time=3})
            return
        end
    end

    Library:Notify({Title="Error", Description="No killer found", Time=3})
end


--tp survivor 
local lastSurvivorIndex = 0

local function TeleportToSurvivor()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local survivors = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        if getRole(player) == "Survivor" and player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(survivors, player)
        end
    end

    if #survivors == 0 then
        Library:Notify({Title="Error", Description="No other survivor found", Time=3})
        return
    end

    lastSurvivorIndex = lastSurvivorIndex + 1
    if lastSurvivorIndex > #survivors then
        lastSurvivorIndex = 1
    end

    local target = survivors[lastSurvivorIndex]
    char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
    Library:Notify({Title="Teleported", Description="To Survivor", Time=3})
end

-- third person view killer
local CurrentCamera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

local zoomEnabled = false
local shiftLockEnabled = false
local BASE_FOV = 104
local connections = {}
local shiftLockConn

local function applyZoom()
	if zoomEnabled then
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		LocalPlayer.CameraMaxZoomDistance = 35
		LocalPlayer.CameraMinZoomDistance = 0.5
		Humanoid.CameraOffset = Vector3.new(0,0,0)
		CurrentCamera.FieldOfView = BASE_FOV
	else
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		LocalPlayer.CameraMaxZoomDistance = 0.5
		LocalPlayer.CameraMinZoomDistance = 0.5
		Humanoid.CameraOffset = Vector3.new(0,0,0)
		CurrentCamera.FieldOfView = 70
	end

	local CollectionService = game:GetService("CollectionService")
	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") and not CollectionService:HasTag(part, "alwaysInvisible") then
			part.LocalTransparencyModifier = (part.Name == "Head") and 1 or part.Transparency
		end
	end
end

local function setupBloodlustFrenzy()
	for _, c in pairs(connections) do c:Disconnect() end
	connections = {}

	if not zoomEnabled then return end

	table.insert(connections, script.Parent:GetAttributeChangedSignal("BloodLust"):Connect(function()
		local stage = script.Parent:GetAttribute("BloodLust") or 0
		TweenService:Create(CurrentCamera, TweenInfo.new(0.3), {FieldOfView = BASE_FOV + stage * 2}):Play()
	end))

	table.insert(connections, Character:GetAttributeChangedSignal("Frenzy"):Connect(function()
		TweenService:Create(CurrentCamera, TweenInfo.new(1.5), {
			FieldOfView = Character:GetAttribute("Frenzy") and 110 or BASE_FOV + (script.Parent:GetAttribute("BloodLust") or 0) * 2
		}):Play()
	end))
end

local function updateShiftLock()
	if shiftLockConn then shiftLockConn:Disconnect() end
	if not shiftLockEnabled or not Character:FindFirstChild("HumanoidRootPart") then return end

	shiftLockConn = RunService.RenderStepped:Connect(function()
		local root = Character.HumanoidRootPart
		local look = CurrentCamera.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z).Unit
		if flatLook.Magnitude > 0 then
			root.CFrame = CFrame.new(root.Position) * CFrame.fromAxisAngle(Vector3.new(0,1,0), math.atan2(-flatLook.X, -flatLook.Z))
		end
	end)
end

if Head:FindFirstChild("RedSurfaceLight") then
	Head.RedSurfaceLight:Destroy()
end

CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
	if CurrentCamera.CameraSubject and CurrentCamera.CameraSubject:IsA("VehicleSeat") then
		CurrentCamera.CameraSubject = Humanoid
	end
end)


LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid")
	Head = newChar:WaitForChild("Head")
	if Head:FindFirstChild("RedSurfaceLight") then Head.RedSurfaceLight:Destroy() end
	if zoomEnabled then applyZoom() setupBloodlustFrenzy() end
	if shiftLockEnabled then updateShiftLock() end
end)

-- auto tp lobby Carry
getgenv().TpOnCarry = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function setup()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local wasCarrying = false

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not getgenv().TpOnCarry then return end
        if not Character or not Character.Parent or not Character:FindFirstChild("HumanoidRootPart") then return end
        
        local carrying = Character:GetAttribute("IsCarrying") == true
        if carrying and not wasCarrying then
            Character.HumanoidRootPart.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0, 2, 0)
        end
        wasCarrying = carrying
    end)

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        if connection then connection:Disconnect() end
        Character = newChar
        wasCarrying = false
        setup()
    end)
end

setup()
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

-- TABS
local InfoTab       = Window:AddTab("Info", "info")
local SurvivorTab   = Window:AddTab("Survivor", "user")
local KillerTab     = Window:AddTab("Killer", "sword")
local EspTab        = Window:AddTab("Visual", "eye")
local TrollTab      = Window:AddTab("Troll", "flame")
local TeleportTab   = Window:AddTab("Teleport", "repeat")
local MiscTab       = Window:AddTab("Misc", "settings")
local SettingsTab   = Window:AddTab("Settings", "cog")

--================================================================--
-- GROUP BOXES
--================================================================--

-- SURVIVOR TAB
local SurvivorLeft    = SurvivorTab:AddLeftGroupbox("HITBOX", "scan")
local AutomationLeft  = SurvivorTab:AddLeftGroupbox("AUTOMATION", "cpu")
local SurvivorRight   = SurvivorTab:AddRightGroupbox("SURVIVOR", "user")

-- KILLER TAB
local TabBox      = KillerTab:AddLeftTabbox()
local KillerLeft  = TabBox:AddTab("HITBOX")
local KillerLeft2 = TabBox:AddTab("ATTACK")
local KillerRight = KillerTab:AddRightGroupbox("KILLER", "skull")
local KillerLeft3 = KillerTab:AddLeftGroupbox("AUTOMATION", "cpu")

-- VISUAL TAB
local ESPRight = EspTab:AddLeftGroupbox("ESP", "eye")

-- TROLL TAB
local TrollLeft  = TrollTab:AddLeftGroupbox("Troll", "flame")
local TrollRight = TrollTab:AddRightGroupbox("EMOTE", "laugh")

-- OVERPOWERED TAB
--[[
local OpLeft = TrollTab:AddLeftGroupbox("OVERPOWERED", "robot")
]]

-- TELEPORT TAB
local TeleportLeft  = TeleportTab:AddLeftGroupbox("LOBBY & INGAME", "refresh-ccw")
local TeleportRight = TeleportTab:AddRightGroupbox("ROLE TELEPORT", "refresh-ccw")

-- MISC TAB
local MiscLeft      = MiscTab:AddLeftGroupbox("MISC", "sun")
local ServerRight   = MiscTab:AddRightGroupbox("SERVER", "server")
local CrosshairLeft = MiscTab:AddLeftGroupbox("CROSSHAIR", "crosshair")

-- INFO TAB
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
-- KILLER TAB ELEMENTS
--================================================================--
KillerLeft:AddToggle("SurvivorHitbox", {
    Text = "Hitbox (Survivor)",
    Default = false,
    Callback = function(state)
        survivorHitboxEnabled = state
        Library:Notify({Title = "Survivor Hitbox", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

KillerLeft:AddSlider("SurvivorHitboxSize", {
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


KillerRight:AddToggle("KillerZoomToggle", {
	Text = "Third Person (Killer)",
	Default = false,
	Callback = function(v)
		zoomEnabled = v
		applyZoom()
		if v then setupBloodlustFrenzy() end
	end
})

KillerRight:AddToggle("KillerShiftLock", {
	Text = "ShiftLock",
	Default = false,
	Callback = function(v)
		shiftLockEnabled = v
		updateShiftLock()
	end
})

KillerRight:AddToggle("BlockFlashlightRemote", {
    Text = "Anti-Blind",
    Default = false,
    Callback = function(enabled)
        if enabled then EnableAntiBlind() else DisableAntiBlind() end
    end
})



KillerLeft3:AddToggle("TpOnCarry", {
    Text = "Auto Tp Lobby Carry",
    Default = false,
    Callback = function(v) getgenv().TpOnCarry = v end
})



KillerLeft2:AddToggle("ShowRapidAttackButton", {
    Text = "Show Rapid Attack Button",
    Default = false,
    Callback = function(enabled)
        if enabled then
            createRapidAttackUI()
        else
            if rapidAttackGui then
                rapidAttackGui:Destroy()
                rapidAttackGui = nil
            end
            rapidAttack = false
        end
    end
})

KillerLeft2:AddSlider("RapidAttackSpeed", {
    Text = "Rapid Attack Speed",
    Default = 1,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
    Suffix = " sec",
    Callback = function(v)
        attackDelay = v
    end
})

--================================================================--
-- SURVIVOR TAB ELEMENTS
--================================================================--
SurvivorLeft:AddToggle("KillerHitbox", {
    Text = "Hitbox (Killer)",
    Default = false,
    Callback = function(state)
        killerHitboxEnabled = state
        Library:Notify({Title = "Killer Hitbox", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

SurvivorLeft:AddSlider("KillerHitboxSize", {
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

SurvivorLeft:AddSlider("HitboxTransparency", {
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

-- Survivor Right
SurvivorRight:AddToggle("PerfectSkillCheck", {
    Text = "Perfect SkillCheck Gen",
    Default = false,
    Callback = function(enabled)
        if enabled then EnablePerfectSkillCheck() end
    end
})

SurvivorRight:AddToggle("BlockHealingRemotes", {
    Text = "Perfect SkillCheck Healing",
    Default = false,
    Callback = function(enabled)
        if enabled then EnableBlockHealingRemotes() else DisableBlockHealingRemotes() end
    end
})

SurvivorRight:AddButton({Text = "Instant Escape", Func = InstantEscape})

SurvivorRight:AddToggle("SpeedBoostToggle", {
    Text = "Speed Boost",
    Default = false,
    Callback = function(enabled)
        if enabled then 
            startBoost("speedboost", Options.SpeedLevel.Value, "Speed Boost") 
        else 
            stopBoost("speedboost", "Speed Boost") 
        end
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
        if enabled then 
            startBoost("repairboost", Options.RepairLevel.Value, "Repair Boost") 
        else 
            stopBoost("repairboost", "Repair Boost") 
        end
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
-- VISUAL TAB (ESP)
--================================================================--
ESPRight:AddToggle("KillersESP", {Text = "Killers ESP", Default = false, Callback = function(v) espSettings.Killers.Enabled = v end})
ESPRight:AddToggle("SurvivorsESP", {Text = "Survivors ESP", Default = false, Callback = function(v) espSettings.Survivors.Enabled = v end})
ESPRight:AddToggle("GeneratorsESP", {Text = "Generators ESP", Default = false, Callback = function(v) espSettings.Generators.Enabled = v end})
ESPRight:AddToggle("PalletsESP", {Text = "Pallets ESP", Default = false, Callback = function(v) espSettings.Pallets.Enabled = v end})
ESPRight:AddToggle("ExitGatesESP", {Text = "Exit Gates ESP", Default = false, Callback = function(v) espSettings.ExitGates.Enabled = v end})

--================================================================--
-- TROLL TAB
--================================================================--
TrollLeft:AddToggle("FlipUIToggle", {
    Text = "Show B-Flip & F-Flip Buttons",
    Default = false,
    Callback = function(enabled)
        if enabled then
            createFlipUI()
            Library:Notify({Title = "Flip UI", Description = "Draggable F-Flip & B-Flip buttons shown!", Time = 3})
        else
            if flipGui then
                flipGui:Destroy()
                flipGui = nil
                Library:Notify({Title = "Flip UI", Description = "Hidden!", Time = 2})
            end
        end
    end
})

TrollLeft:AddButton({Text = "Frontflip", Func = PerformFrontflip})
TrollLeft:AddButton({Text = "Backflip", Func = PerformBackflip})

local selectedEmote = nil
local emoteNames = {}
for name in pairs(emotes) do table.insert(emoteNames, name) end

TrollRight:AddDropdown("EmoteSelector", {
    Text = "Select Emote",
    Values = emoteNames,
    Default = emoteNames[1],
    Searchable = true,
    Callback = function(v) selectedEmote = v end
})

TrollRight:AddButton({Text = "Play Emote", Func = function() if selectedEmote then playEmote(selectedEmote) else warn("No emote selected.") end end})
TrollRight:AddButton({Text = "Stop Emote", Func = stopCurrentEmote})

--================================================================--
-- OVERPOWERED TAB
--================================================================--
TrollLeft:AddDivider()

TrollLeft:AddButton({
    Text = "Godmode (Beta)",
    Func = function()
        if hasTeleported then return end
        local success = fireSkillcheckTouch()
        if success then
            hasTeleported = true
            LP.CharacterAdded:Once(function()
                task.wait(0.5)
                teleportToSurvivorSpawn()
            end)
        elseif not hasSkillcheck() then
            teleportToSurvivorSpawn()
            hasTeleported = true
        end
    end
})

TrollLeft:AddToggle("FollowKillerToggle", {
    Text = "Block Killer View",
    Default = false,
    Callback = function(enabled) followKiller = enabled end
})



--================================================================--
-- TELEPORT TAB
--================================================================--
TeleportLeft:AddButton({Text = "TP to Lobby", Func = TeleportToLobby})
TeleportLeft:AddButton({Text = "TP to In-Game", Func = TeleportToInGame})
TeleportRight:AddButton({Text = "TP to Killer", Func = TeleportToKiller})
TeleportRight:AddButton({Text = "TP to Survivor", Func = TeleportToSurvivor})

--================================================================--
-- MISC TAB
--================================================================--
MiscLeft:AddButton({
    Text = "Full Brightness",
    Func = function()
        FullBright = not FullBright
        MonitorLighting()
        Library:Notify({Title = "Fullbright", Description = FullBright and "Enabled" or "Disabled", Time = 2})
    end
})

MiscLeft:AddToggle("LowGraphics", {
    Text = "Low Graphics (FPS Boost)",
    Default = false,
    Callback = function(enabled) if enabled then applyLowGraphics() else restoreGraphics() end end
})

-- CROSSHAIR
CrosshairLeft:AddToggle("CrosshairToggle", {
    Text = "Enable Crosshair",
    Default = false,
    Callback = function(state)
        crosshairEnabled = state
        for _, line in ipairs(lines) do line.Visible = state end
        dot.Visible = state
        Library:Notify({Title = "Crosshair", Description = state and "Enabled" or "Disabled", Time = 2})
    end
})

CrosshairLeft:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColor", {
    Default = lineColor,
    Title = "Pick Crosshair Color",
    Callback = function(value) lineColor = value end
})

-- SERVER
ServerRight:AddLabel("60% Accurate Not 100%")
ServerRight:AddDivider()

local selectedRegion = "US"
ServerRight:AddDropdown("RegionDropdown", {
    Text = "Choose Server Region",
    Values = {"US", "Japan", "Philippines/Asia", "China/HK"},
    Default = 1,
    Multi = false,
    Searchable = false,
    Callback = function(value) 
        selectedRegion = value 
        Library:Notify({Title = "Region", Description = "Selected: " .. value, Time = 2}) 
    end
})

ServerRight:AddButton({
    Text = "Join Selected Region",
    Func = function()
        if not request then
            Library:Notify({Title = "Error", Description = "HTTP not enabled!", Time = 3})
            return
        end
        Library:Notify({Title = "Searching", Description = "Finding " .. selectedRegion .. " server...", Time = 3})
        local regionPing = {["US"] = 150, ["Japan"] = 120, ["Philippines/Asia"] = 200, ["China/HK"] = 180}
        local maxPing = regionPing[selectedRegion] or 200
        local servers = {}
        local success, req = pcall(function()
            return request({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET"})
        end)
        if not success or not req then
            Library:Notify({Title = "Failed", Description = "Request error!", Time = 3})
            return
        end
        local body = game:GetService("HttpService"):JSONDecode(req.Body)
        if body and body.data then
            for _, v in pairs(body.data) do
                if v.playing and v.maxPlayers and v.id ~= game.JobId then
                    if v.playing < v.maxPlayers then
                        local ping = v.ping or 999
                        if ping <= maxPing then table.insert(servers, {id = v.id, ping = ping}) end
                    end
                end
            end
        end
        if #servers > 0 then
            table.sort(servers, function(a,b) return a.ping < b.ping end)
            local target = servers[1]
            Library:Notify({Title = "Joining", Description = selectedRegion .. " (Ping: " .. target.ping .. "ms)", Time = 3})
            task.delay(1, function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, target.id, LP) end)
        else
            Library:Notify({Title = "No Server", Description = "None found in " .. selectedRegion, Time = 3})
        end
    end
})

ServerRight:AddDivider()
ServerRight:AddButton({
    Text = "Server Hop (Random)",
    Func = function()
        Library:Notify({Title = "Server Hop", Description = "Searching for new server...", Time = 3})
        local servers = {}
        local req = request({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"})
        local body = game:GetService("HttpService"):JSONDecode(req.Body)
        if body and body.data then
            for _, v in pairs(body.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then table.insert(servers, 1, v.id) end
            end
        end
        if #servers > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LP)
        else
            Library:Notify({Title = "Server Hop", Description = "No servers found!", Time = 3})
        end
    end
})

ServerRight:AddButton({Text = "Rejoin", Func = function() Library:Notify({Title = "Rejoin", Description = "Rejoining current server...", Time = 2}) game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end})

ServerRight:AddLabel("Find Best Server For You")
ServerRight:AddDivider()
ServerRight:AddButton({
    Text = "Join LowPing Server",
    Func = function()
        Library:Notify({Title = "Searching", Description = "Finding best server...", Time = 2})
        task.spawn(function()
            local success, req = pcall(function()
                return request({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET"})
            end)
            if not success or not req then
                Library:Notify({Title = "Error", Description = "Failed to fetch servers", Time = 3})
                return
            end
            local body = game:GetService("HttpService"):JSONDecode(req.Body)
            local best = nil
            if body and body.data then
                for _, v in pairs(body.data) do
                    if v.playing and v.maxPlayers and v.id ~= game.JobId then
                        if v.playing < v.maxPlayers then
                            local ping = v.ping or 999
                            if not best or ping < (best.ping or 999) then best = v end
                        end
                    end
                end
            end
            if best then
                Library:Notify({Title = "Joining", Description = "Best ping: " .. best.ping .. "ms", Time = 3})
                task.delay(0.5, function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, best.id, LP) end)
            else
                Library:Notify({Title = "No Server", Description = "No available servers found", Time = 3})
            end
        end)
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
