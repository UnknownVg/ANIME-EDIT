--================================================================--
--                    VGXMOD X AMONG US (RAINBOW DEAD BODY ESP)
--================================================================--

print("------------------------------------------------------------------")
print("Load ................................ Among Us")
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
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local LP               = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

--================================================================--
-- STATE & CONNECTIONS
--================================================================--
local connections = {}
local esp = {}
local espBodies = {}
local noclipConnection = nil
local brightnessConnection = nil
local MAX_ZOOM = 500
local emergencyCooldown = 0

--================================================================--
-- GET PLAYER ROLE (SAFE)
--================================================================--
local function getRole(plr)
    if not plr or not plr:FindFirstChild("PublicStates") then
        return {role = "Unknown", subrole = "", alive = false}
    end
    local s = plr.PublicStates
    return {
        role    = (s:FindFirstChild("Role") and s.Role.Value) or "Unknown",
        subrole = (s:FindFirstChild("SubRole") and s.SubRole.Value) or "",
        alive   = (s:FindFirstChild("Alive") and s.Alive.Value ~= false)
    }
end

--================================================================--
-- CREATE ESP (Drawing)
--================================================================--
local function createESP()
    local e = {}
    e.text   = Drawing.new("Text")
    e.box    = Drawing.new("Square")
    e.tracer = Drawing.new("Line")
    e.text.Size = 13; e.text.Center = true; e.text.Outline = true; e.text.Font = 2
    e.box.Thickness = 1.5; e.box.Filled = false
    e.tracer.Thickness = 1.5
    return e
end
local function removeESP(plr)
    if esp[plr] then
        for _,v in pairs(esp[plr]) do if v and v.Remove then v:Remove() end end
        esp[plr] = nil
    end
end

--================================================================--
-- CREATE BODY ESP
--================================================================--
local function createBodyLabel()
    local t = Drawing.new("Text")
    t.Size = 14; t.Center = true; t.Outline = true; t.Text = "Dead"
    return t
end

--================================================================--
-- GUI: CREATE WINDOW
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "by Pkgx1 | Fixed",
    Icon = 94858886314945,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

--================================================================--
-- INFO TAB
--================================================================--
local InfoTab = Window:AddTab("Info", "info")
local InfoL = InfoTab:AddLeftGroupbox("Credits")
local InfoR = InfoTab:AddRightGroupbox("Discord")

InfoL:AddLabel("Made By: Pkgx1")
InfoL:AddLabel("Discord: https://discord.gg/n9gtmefsjc")
InfoL:AddDivider()
InfoL:AddLabel("You Can Request Script")
InfoL:AddLabel("On Discord!")

InfoR:AddLabel("Discord Link")
InfoR:AddButton({Text="Copy",Func=function()
    setclipboard("https://discord.gg/n9gtmefsjc")
    Library:Notify({Title="Copied!",Description="Paste it on your browser",Time=4})
end})

--================================================================--
-- MAIN TAB
--================================================================--
local MainTab = Window:AddTab("Main", "house")

local ESPR    = MainTab:AddRightGroupbox("ESP FEATURE", "eye") -- make this left
local MoveL   = MainTab:AddLeftGroupbox("MOVEMENT FEATURE", "zap") -- make this right
local MiscR   = MainTab:AddRightGroupbox("MISC FEATURE", "settings") -- make this left

--================================================================--
-- NOCLIP TOGGLE
--================================================================--
MoveL:AddToggle("Noclip",{Text="Noclip",Default=false,Callback=function(enabled)
    if enabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = LP.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local character = LP.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end})
--================================================================--
-- ESP TOGGLES
--================================================================--
ESPR:AddToggle("PlayersESP",{Text="Role ESP",Default=false,Callback=function(v)
    if v then
        connections.PlayersESP = RunService.RenderStepped:Connect(function()
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local char = plr.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        if not esp[plr] then esp[plr] = createESP() end
                        local data = getRole(plr)
                        local screenPos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                        local color = data.role=="Imposter" and Color3.new(1,0,0) or Color3.fromRGB(50,255,50)
                        if onScreen and data.alive then
                            local top = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position + Vector3.new(0,3/2,0))
                            local bottom = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position - Vector3.new(0,3/2,0))
                            local boxHeight = math.abs(top.Y-bottom.Y)
                            local boxWidth = boxHeight/1.5
                            local boxPos = Vector2.new(screenPos.X-boxWidth/2, screenPos.Y-boxHeight/2)
                            esp[plr].box.Size = Vector2.new(boxWidth, boxHeight)
                            esp[plr].box.Position = boxPos
                            esp[plr].box.Color = color
                            esp[plr].box.Visible = true
                            esp[plr].text.Text = data.subrole~="" and string.format("%s [%s | %s]",plr.Name,data.role,data.subrole) or string.format("%s [%s]",plr.Name,data.role)
                            esp[plr].text.Position = Vector2.new(screenPos.X, boxPos.Y-16)
                            esp[plr].text.Color = color
                            esp[plr].text.Visible = true
                            esp[plr].tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            esp[plr].tracer.To = Vector2.new(screenPos.X,screenPos.Y)
                            esp[plr].tracer.Color = color
                            esp[plr].tracer.Visible = true
                        else
                            esp[plr].text.Visible = false
                            esp[plr].box.Visible = false
                            esp[plr].tracer.Visible = false
                        end
                    else removeESP(plr) end
                end
            end
        end)
    else
        if connections.PlayersESP then connections.PlayersESP:Disconnect() connections.PlayersESP=nil end
        for _,v in pairs(esp) do for _,d in pairs(v) do if d.Remove then d:Remove() end end end
        esp={}
    end
end})

--================================================================--
-- DEAD BODIES ESP (RAINBOW)
--================================================================--
ESPR:AddToggle("BodiesESP",{Text="Dead Bodies ESP",Default=false,Callback=function(v)
    if connections.BodiesESP then connections.BodiesESP:Disconnect() end
    espBodies={}
    if v then
        local hue = 0
        connections.BodiesESP = RunService.RenderStepped:Connect(function(delta)
            hue = (hue + 0.5 * delta) % 1
            local BodiesFolder = Workspace:FindFirstChild("Bodies")
            if not BodiesFolder then return end
            for _,body in pairs(BodiesFolder:GetChildren()) do
                if not espBodies[body] then
                    espBodies[body] = createBodyLabel()
                    pcall(function()
                        local bodyName = body.Name or "Unknown"
                        StarterGui:SetCore("SendNotification",{
                            Title="Dead Body Detected",
                            Text=bodyName .. " has been found!",
                            Duration=4
                        })
                    end)
                end
            end
            for body,label in pairs(espBodies) do
                if not body or not body:IsDescendantOf(Workspace) then
                    label:Remove(); espBodies[body]=nil
                else
                    local pos = body:FindFirstChild("DeadPart") and body.DeadPart.Position or (body.PrimaryPart and body.PrimaryPart.Position)
                    if pos then
                        local screenPos,onScreen = Camera:WorldToViewportPoint(pos)
                        if onScreen then 
                            label.Position=Vector2.new(screenPos.X,screenPos.Y-20)
                            label.Visible=true
                            label.Color = Color3.fromHSV(hue,1,1)
                        else label.Visible=false end
                    else label.Visible=false end
                end
            end
        end)
    end
end})

--================================================================--
-- MISC FEATURES
--================================================================--
MiscR:AddToggle("FullVision",{Text="Full Vision",Default=false,Callback=function(v)
    local states = LP:FindFirstChild("States")
    local view   = states and states:FindFirstChild("SpectateView")
    if view then view.Value = v; Library:Notify({Title="Full Vision",Description=v and "ON" or "OFF",Time=2})
    else Library:Notify({Title="Error",Description="SpectateView not found!",Time=3}) end
end})

MiscR:AddToggle("MaxZoom",{Text="Max Zoom Distance",Default=false,Callback=function(v)
    LP.CameraMaxZoomDistance = v and MAX_ZOOM or 20
    LP.CameraMinZoomDistance = 0.5
    Library:Notify({Title="Max Zoom",Description=v and "500 studs" or "20 studs",Time=2})
end})

MiscR:AddToggle("FullBrightness",{Text="Full Brightness",Default=false,Callback=function(v)
    if brightnessConnection then brightnessConnection:Disconnect() end
    local eff = LP.PlayerGui:FindFirstChild("EffectsM")
    if v then
        Lighting.FogStart = 1e10; Lighting.FogEnd = 1e10
        if eff then eff.Enabled=false end
        brightnessConnection = RunService.Heartbeat:Connect(function()
            Lighting.FogStart = 1e10; Lighting.FogEnd = 1e10
            if eff then eff.Enabled=false end
        end)
    else
        Lighting.FogStart = 0; Lighting.FogEnd = 1000
        if eff then eff.Enabled=true end
    end
    Library:Notify({Title="Brightness",Description=v and "ON – No fog!" or "OFF",Time=2})
end})

MiscR:AddButton({Text="Emergency Meeting",Func=function()
    if tick() < emergencyCooldown then
        Library:Notify({Title="Emergency",Description="Cooldown active!",Time=2})
        return
    end
    local mapNames = {"Nova Corp","Big Skeld","Polus"}; local found=false
    for _,name in ipairs(mapNames) do
        local map = Workspace:FindFirstChild(name)
        if map then
            local btn = map:FindFirstChild("DiscussButton")
            if btn and btn:FindFirstChild("Interact") then
                btn.Interact:InvokeServer(btn)
                Library:Notify({Title="Emergency",Description="Meeting called!",Time=3})
                emergencyCooldown = tick() + 5
                found = true
                break
            end
        end
    end
    if not found then Library:Notify({Title="Failed",Description="No button found",Time=3}) end
end})

--================================================================--
-- SETTINGS TAB
--================================================================--
local SettingsTab = Window:AddTab("Settings","cog")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Vgxmod")
SaveManager:SetFolder("Vgxmod")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:LoadAutoloadConfig()
