--================================================================--
--                    VGXMOD HUB - REWORKED (VIOLENCE DISTRICT STYLE)
--        Cleaned structure: Hitbox + ESP Bomb + Tracer + Misc + Player
--================================================================--

print("------------------------------------------------------------------")
print("Load ................................ Vgxmod Hub (Reworked)")
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
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--================================================================--
-- CONFIGURATION / STATE
--================================================================--
local currentHitboxSize = 5
local hitboxConnections = {}
local savedPositions = {}

local espConnections = {}
local tracerConnections = {}

--================================================================--
-- UTIL: Safe accessors
--================================================================--
local function safeGetPlayerGui()
    return LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

--================================================================--
-- HITBOX: resize / deactivate helpers (operate on CollisionPart)
--================================================================--
local function resizeCollisionPart(playerName)
    if playerName == LocalPlayer.Name then return end
    local playerModel = Workspace:FindFirstChild(playerName)
    if not playerModel then return end
    local collisionPart = playerModel:FindFirstChild("CollisionPart")
    if collisionPart and collisionPart:IsA("BasePart") then
        collisionPart.Size = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)
        collisionPart.Color = Color3.fromRGB(0, 0, 0)
        collisionPart.Transparency = 0.9
        collisionPart.CanCollide = true
    end
end

local function deactivateCollisionPart(playerName)
    if playerName == LocalPlayer.Name then return end
    local playerModel = Workspace:FindFirstChild(playerName)
    if not playerModel then return end
    local collisionPart = playerModel:FindFirstChild("CollisionPart")
    if collisionPart and collisionPart:IsA("BasePart") then
        collisionPart.Transparency = 1
        collisionPart.CanCollide = false
    end
end

local function monitorPlayers()
    for _, c in ipairs(hitboxConnections) do pcall(function() c:Disconnect() end) end
    hitboxConnections = {}

    for _, player in pairs(Players:GetPlayers()) do
        local con = RunService.Heartbeat:Connect(function()
            if Options.HitboxToggle and Options.HitboxToggle.Value then
                resizeCollisionPart(player.Name)
            else
                deactivateCollisionPart(player.Name)
            end
        end)
        table.insert(hitboxConnections, con)
    end

    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        local con = RunService.Heartbeat:Connect(function()
            if Options.HitboxToggle and Options.HitboxToggle.Value then
                resizeCollisionPart(player.Name)
            else
                deactivateCollisionPart(player.Name)
            end
        end)
        table.insert(hitboxConnections, con)
    end)
    table.insert(hitboxConnections, playerAddedConnection)
end

--================================================================--
-- HITBOX UI (movable on-screen buttons)
--================================================================--
local function createHitboxUI()
    local guip = safeGetPlayerGui()
    if guip:FindFirstChild("HitboxGui") then
        guip.HitboxGui:Destroy()
    end

    local ui = Instance.new("ScreenGui")
    ui.Name = "HitboxGui"
    ui.ResetOnSpawn = false
    ui.Parent = guip

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
        btn.Draggable = true
        btn.Parent = ui

        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(1, 0)
        local border = Instance.new("UIStroke", btn)
        border.Thickness = 2
        border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local hue = 0
        local rsCon
        rsCon = RunService.RenderStepped:Connect(function(dt)
            if not btn or not btn.Parent then
                if rsCon then pcall(function() rsCon:Disconnect() end) end
                return
            end
            hue = (hue + dt * 0.1) % 1
            border.Color = Color3.fromHSV(hue, 1, 1)
        end)

        btn.MouseButton1Click:Connect(onClick)
        btn:GetPropertyChangedSignal("Position"):Connect(function()
            savedPositions[id] = btn.Position
        end)
    end

    createButton("Hitbox1", "Hitbox 1", UDim2.new(0.5, -60, 0.5, 0), function() currentHitboxSize = 1 end)
    createButton("Hitbox5", "Hitbox 5", UDim2.new(0.5, 60, 0.5, 0), function() currentHitboxSize = 5 end)
end

local function setupHitboxUIOrNotify()
    if UserInputService.TouchEnabled then
        createHitboxUI()
    else
        Library:Notify({
            Title = "Hitbox",
            Description = "Press R for hitbox size 7, Press E for hitbox size 1",
            Time = 5,
        })
    end
end

-- Keybind logic for PC
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not Options.HitboxToggle or not Options.HitboxToggle.Value then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.R then
            currentHitboxSize = 7
        elseif input.KeyCode == Enum.KeyCode.E then
            currentHitboxSize = 1
        end
    end
end)

--================================================================--
-- GUI / Hitbox toggle
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "version: 1.6",
    Icon = 94858886314945,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local MainTab = Window:AddTab("Main", "sword")
local MainLeft = MainTab:AddLeftGroupbox("Hitbox Control")

MainLeft:AddToggle("HitboxToggle", {
    Text = "Enable Hitbox",
    Default = false,
    Callback = function(Value)
        Options.HitboxToggle = { Value = Value }
        if Value then
            monitorPlayers()
        else
            for _, connection in ipairs(hitboxConnections) do
                pcall(function() connection:Disconnect() end)
            end
            hitboxConnections = {}
            for _, pl in pairs(Players:GetPlayers()) do deactivateCollisionPart(pl.Name) end
        end
    end,
})

MainLeft:AddToggle("ShowHitboxButtons", {
    Text = "Show Hitbox Buttons",
    Default = false,
    Callback = function(Value)
        if Value then
            setupHitboxUIOrNotify()
            if UserInputService.TouchEnabled then
                LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(1)
                    createHitboxUI()
                end)
            end
        else
            local gui = safeGetPlayerGui():FindFirstChild("HitboxGui")
            if gui then gui:Destroy() end
        end
    end,
})

MainLeft:AddInput("HitboxSizeInput", {
    Default = "",
    Numeric = true,
    ClearTextOnFocus = true,
    Text = "Hitbox Size",
    Placeholder = "Enter size (max 15)",
    Callback = function(Value)
        local newSize = math.clamp(tonumber(Value) or currentHitboxSize, 0, 15)
        currentHitboxSize = newSize
        for _, pl in pairs(Players:GetPlayers()) do
            if pl.Name ~= LocalPlayer.Name then
                local pm = Workspace:FindFirstChild(pl.Name)
                if pm then
                    local c = pm:FindFirstChild("CollisionPart")
                    if c and c:IsA("BasePart") then
                        c.Size = Vector3.new(newSize, newSize, newSize)
                    end
                end
            end
        end
    end,
})

-- (Rest of your ESP, Tracer, Player movement, Animation, Settings tabs remain unchanged)
MainLeft:AddInput("HitboxSizeInput", {
    Default = "",
    Numeric = true,
    ClearTextOnFocus = true,
    Text = "Hitbox Size",
    Placeholder = "Enter size (max 15)",
    Callback = function(Value)
        local maxHitboxSize = 15
        local newSize = tonumber(Value)
        if newSize then
            if newSize > maxHitboxSize then newSize = maxHitboxSize end
            if newSize < 0 then newSize = 0 end
            currentHitboxSize = newSize
            for _, pl in pairs(Players:GetPlayers()) do
                if pl.Name ~= LocalPlayer.Name then
                    local pm = Workspace:FindFirstChild(pl.Name)
                    if pm then
                        local c = pm:FindFirstChild("CollisionPart")
                        if c and c:IsA("BasePart") then
                            c.Size = Vector3.new(newSize, newSize, newSize)
                        end
                    end
                end
            end
            Library:Notify({ Title = "Hitbox Size", Description = "Set to " .. tostring(newSize), Time = 2 })
        end
    end,
})

MainLeft:AddToggle("ShowHitboxButtons", {
    Text = "Show Hitbox Buttons",
    Default = false,
    Callback = function(Value)
        if Value then
            createHitboxUI()
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                createHitboxUI()
            end)
            Library:Notify({ Title = "Hitbox UI", Description = "Shown", Time = 2 })
        else
            local gui = safeGetPlayerGui():FindFirstChild("HitboxGui")
            if gui then gui:Destroy() end
            Library:Notify({ Title = "Hitbox UI", Description = "Hidden", Time = 2 })
        end
    end,
})

--=== ESP Controls (Bomb + Tracer)
MainRight:AddToggle("ESPNameToggle", {
    Text = "ESP Bomb",
    Default = false,
    Callback = function(Value)
        if Value then
            Options.ESPNameToggle = { Value = true }
            updateESP()
            Library:Notify({ Title = "ESP Bomb", Description = "Enabled", Time = 2 })
        else
            Options.ESPNameToggle = { Value = false }
            for _, c in ipairs(espConnections) do pcall(function() c:Disconnect() end) end
            espConnections = {}
            destroyESP()
            Library:Notify({ Title = "ESP Bomb", Description = "Disabled", Time = 2 })
        end
    end,
})

MainRight:AddToggle("ESPTracerToggle", {
    Text = "Tracer Bomb",
    Default = false,
    Callback = function(Value)
        if Value then
            Options.ESPTracerToggle = { Value = true }
            updateTracer()
            Library:Notify({ Title = "ESP Tracer", Description = "Enabled", Time = 2 })
        else
            Options.ESPTracerToggle = { Value = false }
            for _, c in ipairs(tracerConnections) do pcall(function() c:Disconnect() end) end
            tracerConnections = {}
            destroyTracer()
            Library:Notify({ Title = "ESP Tracer", Description = "Disabled", Time = 2 })
        end
    end,
})

--=== Misc Buttons
MiscLeft:AddButton({
    Text = "Max View",
    Func = function()
        LocalPlayer.CameraMaxZoomDistance = 500
        LocalPlayer.CameraMinZoomDistance = 0.5
        Library:Notify({ Title = "Camera", Description = "Max view set", Time = 2 })
    end,
})

MiscLeft:AddButton({
    Text = "Remove Explosion",
    Func = function()
        local debris = Workspace:FindFirstChild("DebrisFolder")
        if debris then debris:Destroy() end
        Library:Notify({ Title = "Debris", Description = "Removed", Time = 2 })
    end,
})

MiscLeft:AddButton({
    Text = "Shiftlock Mobile",
    Func = function()
        enableShiftLockMobile()
        Library:Notify({ Title = "Shiftlock", Description = "Enabled (mobile UI)", Time = 2 })
    end,
})

--================================================================--
-- PLAYER TAB (Movement / Animation)
--================================================================--
local PlayerTab = Window:AddTab("Player", "user")
local PlayerLeft = PlayerTab:AddLeftGroupbox("Movement Control")
local PlayerRight = PlayerTab:AddRightGroupbox("Animation Control")

PlayerLeft:AddLabel("Movement Like a Pro")

PlayerLeft:AddToggle("WalkToggle", {
    Text = "Speed Boost",
    Default = false,
    Callback = function(Value)
        walkEnabled = Value
        if Value then
            walkConnection = RunService.Heartbeat:Connect(updateSpeed)
            Library:Notify({ Title = "Speed Boost", Description = "Enabled", Time = 2 })
        else
            if walkConnection then pcall(function() walkConnection:Disconnect() end) end
            walkConnection = nil
            if humanoid then humanoid.WalkSpeed = normalSpeed end
            Library:Notify({ Title = "Speed Boost", Description = "Disabled", Time = 2 })
        end
    end,
})

PlayerLeft:AddSlider("WalkSpeedSlider", {
    Text = "Speed Level",
    Default = 3,
    Min = 1,
    Max = 3,
    Rounding = 0,
    Callback = function(Value)
        sliderValue = Value
        if walkEnabled and humanoid then updateSpeed() end
        Library:Notify({ Title = "Speed Level", Description = "Level " .. tostring(Value), Time = 1 })
    end,
})

PlayerRight:AddButton({
    Text = "Animation",
    Func = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/BeemTZy/Motiona/refs/heads/main/source.lua"))()
    end,
})

--================================================================--
-- SETTINGS TAB: Save/Load Config (kept behavior)
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
