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

-- Monitors all players each Heartbeat with a connection per player (keeps current behavior)
local function monitorPlayers()
    -- disconnect old connections if any
    for _, c in ipairs(hitboxConnections) do
        pcall(function() c:Disconnect() end)
    end
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

        -- color-cycle stroke
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

--================================================================--
-- ESP (BOMB) helpers
--================================================================--
local function createESP(part, text)
    if not part then return end
    if part:FindFirstChild("ESP_Label") then
        part.ESP_Label:Destroy()
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_Label"
    gui.Adornee = part
    gui.Size = UDim2.new(0, 100, 0, 40)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 25
end

local function destroyESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        local model = Workspace:FindFirstChild(plr.Name)
        if model then
            local bomb = model:FindFirstChild("Bomb")
            local hitbox = bomb and bomb:FindFirstChild("Hitbox")
            if hitbox and hitbox:FindFirstChild("ESP_Label") then
                hitbox.ESP_Label:Destroy()
            end
        end
    end
end

local function updateESP()
    -- clear previous connections
    for _, c in ipairs(espConnections) do
        pcall(function() c:Disconnect() end)
    end
    espConnections = {}

    for _, player in pairs(Players:GetPlayers()) do
        local con = RunService.Heartbeat:Connect(function()
            if not Options.ESPNameToggle or not Options.ESPNameToggle.Value then return end
            local model = Workspace:FindFirstChild(player.Name)
            if not model then return end
            local bomb = model:FindFirstChild("Bomb")
            local hitbox = bomb and bomb:FindFirstChild("Hitbox")
            if hitbox then
                if not hitbox:FindFirstChild("ESP_Label") then
                    createESP(hitbox, "BOMB")
                else
                    local label = hitbox.ESP_Label:FindFirstChildWhichIsA("TextLabel")
                    if label then
                        local t = tick() % 5 / 5
                        label.TextColor3 = Color3.fromHSV(t, 1, 1)
                    end
                end
            end
        end)
        table.insert(espConnections, con)
    end
end

--================================================================--
-- TRACER (Beam) helpers
--================================================================--
local function createTracer(part)
    if not part then return end
    if part:FindFirstChild("ESP_Tracer") then
        part.ESP_Tracer:Destroy()
    end
    local folder = Instance.new("Folder")
    folder.Name = "ESP_Tracer"
    folder.Parent = part

    local att0 = Instance.new("Attachment", part)
    att0.Name = "From"

    local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not head then return end

    local att1 = Instance.new("Attachment", head)
    att1.Name = "To"

    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(0)
    beam.Color = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(0, 1, 0))
    beam.Parent = folder
end

local function destroyTracer()
    for _, plr in ipairs(Players:GetPlayers()) do
        local model = Workspace:FindFirstChild(plr.Name)
        if model then
            local bomb = model:FindFirstChild("Bomb")
            local hitbox = bomb and bomb:FindFirstChild("Hitbox")
            if hitbox and hitbox:FindFirstChild("ESP_Tracer") then
                hitbox.ESP_Tracer:Destroy()
            end
        end
    end
end

local function updateTracer()
    for _, c in ipairs(tracerConnections) do
        pcall(function() c:Disconnect() end)
    end
    tracerConnections = {}

    for _, player in pairs(Players:GetPlayers()) do
        local con = RunService.Heartbeat:Connect(function()
            if not Options.ESPTracerToggle or not Options.ESPTracerToggle.Value then return end
            local model = Workspace:FindFirstChild(player.Name)
            if not model then return end
            local bomb = model:FindFirstChild("Bomb")
            local hitbox = bomb and bomb:FindFirstChild("Hitbox")
            if not hitbox then return end
            if not hitbox:FindFirstChild("ESP_Tracer") then
                createTracer(hitbox)
            else
                local beam = hitbox.ESP_Tracer:FindFirstChildWhichIsA("Beam")
                if beam then
                    local t = tick() % 5 / 5
                    beam.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(t, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV((t + 0.3) % 1, 1, 1))
                    }
                end
            end
        end)
        table.insert(tracerConnections, con)
    end
end

--================================================================--
-- MISC UTIL: Shiftlock, Max View, Remove Explosion
--================================================================--
local function enableShiftLockMobile()
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer

    local ShiftLockScreenGui = Instance.new("ScreenGui")
    ShiftLockScreenGui.Name = "Shiftlock (CoreGui)"
    ShiftLockScreenGui.Parent = CoreGui
    ShiftLockScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ShiftLockScreenGui.ResetOnSpawn = false

    local ShiftLockButton = Instance.new("ImageButton", ShiftLockScreenGui)
    local States = {
        Off = "rbxasset://textures/ui/mouseLock_off@2x.png",
        On = "rbxasset://textures/ui/mouseLock_on@2x.png"
    }

    local MaxLength = 900000
    local EnabledOffset = CFrame.new(1.7, 0, 0)
    local DisabledOffset = CFrame.new(-1.7, 0, 0)
    local Active

    ShiftLockButton.BackgroundTransparency = 1
    ShiftLockButton.Position = UDim2.new(0.7, 0, 0.75, 0)
    ShiftLockButton.Size = UDim2.new(0.0636, 0, 0.0661, 0)
    ShiftLockButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
    ShiftLockButton.Image = States.Off

    ShiftLockButton.MouseButton1Click:Connect(function()
        if not Active then
            Active = RunService.RenderStepped:Connect(function()
                if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") then
                    Player.Character.Humanoid.AutoRotate = false
                    ShiftLockButton.Image = States.On
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(
                        Player.Character.HumanoidRootPart.Position,
                        Vector3.new(
                            workspace.CurrentCamera.CFrame.LookVector.X * MaxLength,
                            Player.Character.HumanoidRootPart.Position.Y,
                            workspace.CurrentCamera.CFrame.LookVector.Z * MaxLength
                        )
                    )
                    workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * EnabledOffset
                    workspace.CurrentCamera.Focus = CFrame.fromMatrix(
                        workspace.CurrentCamera.Focus.Position,
                        workspace.CurrentCamera.CFrame.RightVector,
                        workspace.CurrentCamera.CFrame.UpVector
                    ) * EnabledOffset
                end
            end)
        else
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid.AutoRotate = true
            end
            ShiftLockButton.Image = States.Off
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * DisabledOffset
            pcall(function()
                Active:Disconnect()
            end)
            Active = nil
        end
    end)
end

--================================================================--
-- GUI: CREATE WINDOW (keep your original Info tab unchanged)
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "version: 1.6",
    Icon = 94858886314945,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- Info tab (kept identical to your original)
local InfoTab = Window:AddTab("Info", "info")
local InfoLeft = InfoTab:AddLeftGroupbox("Credits")
local InfoRight = InfoTab:AddRightGroupbox("Discord")

InfoLeft:AddLabel("Made By : Pkgx1")
InfoLeft:AddLabel("Discord : https://discord.gg/n9gtmefsjc")
InfoLeft:AddDivider()
InfoLeft:AddLabel("You Can Request Script")
InfoLeft:AddLabel("On Discord !!!!!!!!?????")
InfoLeft:AddDivider()

InfoRight:AddLabel("Discord Link")
InfoRight:AddButton({
    Text = "Copy",
    Func = function()
        setclipboard("https://discord.gg/n9gtmefsjc")
        Library:Notify({
            Title = "Copied!",
            Description = "Paste it on your browser",
            Time = 4,
        })
    end,
})

-- Main tab and groupboxes (matching VD-style organization)
local MainTab = Window:AddTab("Main", "sword")
local MainLeft = MainTab:AddLeftGroupbox("Hitbox Control")
local MiscLeft = MainTab:AddLeftGroupbox("Misc Control")
local MainRight = MainTab:AddRightGroupbox("Esp Control")

--=== Hitbox toggles & inputs (keeps same names/options)
MainLeft:AddToggle("HitboxToggle", {
    Text = "Enable Hitbox",
    Default = false,
    Callback = function(Value)
        if Value then
            Options.HitboxToggle = { Value = true }
            monitorPlayers()
            Library:Notify({ Title = "Hitbox", Description = "Enabled", Time = 2 })
        else
            Options.HitboxToggle = { Value = false }
            for _, connection in ipairs(hitboxConnections) do
                pcall(function() connection:Disconnect() end)
            end
            hitboxConnections = {}
            for _, pl in pairs(Players:GetPlayers()) do deactivateCollisionPart(pl.Name) end
            Library:Notify({ Title = "Hitbox", Description = "Disabled", Time = 2 })
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
