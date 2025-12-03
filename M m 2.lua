--================================================================--
-- LOAD LIBRARY (Vgxmod UI)
--================================================================--
local repo = "https://raw.githubusercontent.com/UnknownVg/CUSTOM-LIB/refs/heads/main/"
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
-- CORE SERVICES & PLAYER (Cleaned)
--================================================================--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local LP = Players.LocalPlayer

local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum = Char:FindFirstChildOfClass("Humanoid")
local Root = Char and Char:FindFirstChild("HumanoidRootPart")

LP.CharacterAdded:Connect(function(newChar)
    Char = newChar
    Hum = newChar:FindFirstChildOfClass("Humanoid")
    Root = newChar:FindFirstChild("HumanoidRootPart")
end)

--================================================================--
-- ESP SYSTEM
--================================================================--
local UPDATE_SPEED = 0.25
local MAX_DISTANCE = 99999

local ESP = {
Murderer = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.7 },
Sheriff  = { Enabled = false, Color = Color3.fromRGB(0, 0, 255), Transparency = 0.7 },
Hero     = { Enabled = false, Color = Color3.fromRGB(255, 255, 0), Transparency = 0.7 },
Innocent = { Enabled = false, Color = Color3.fromRGB(0, 255, 0), Transparency = 0.7 }
}

local function toggleESP(roleGroup, value)
if roleGroup == "SheriffESP" then
ESP.Sheriff.Enabled = value
ESP.Hero.Enabled = value
elseif roleGroup == "MurdererESP" then
ESP.Murderer.Enabled = value
elseif roleGroup == "InnocentESP" then
ESP.Innocent.Enabled = value
end
end

local function getRoles()
local ok, data = pcall(function()
return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
end)
if not ok or typeof(data) ~= "table" then return {} end
local roles = {}
for plrName, plrData in pairs(data) do
if not plrData.Dead then
roles[plrName] = plrData.Role
end
end
return roles
end

local function addHighlight(char, role)
local config = ESP[role]
if not config or not config.Enabled then return end
local old = char:FindFirstChild("ROLE_HL")
if old then old:Destroy() end
local hl = Instance.new("Highlight")
hl.Name = "ROLE_HL"
hl.Adornee = char
hl.FillColor = config.Color
hl.OutlineColor = Color3.new(1,1,1)
hl.FillTransparency = config.Transparency
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.Parent = char
end

local function addBillboard(char, displayText, role)
local config = ESP[role]
if not config or not config.Enabled then return end
local head = char:FindFirstChild("Head")
if not head then return end
local bb = head:FindFirstChild("ROLE_BB") or Instance.new("BillboardGui", head)
bb.Name = "ROLE_BB"
bb.Adornee = head
bb.Size = UDim2.new(0, 220, 0, 60)
bb.StudsOffset = Vector3.new(0, 3.5, 0)
bb.AlwaysOnTop = true
bb.LightInfluence = 0
local label = bb:FindFirstChild("TEXT") or Instance.new("TextLabel", bb)
label.Name = "TEXT"
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.FontFace = Font.new("rbxassetid://12187362578")
label.TextSize = 7
label.TextColor3 = config.Color
label.TextStrokeTransparency = 1
label.RichText = true
label.Text = displayText
end

local function removeESP(char)
local hl = char:FindFirstChild("ROLE_HL")
if hl then hl:Destroy() end
local head = char:FindFirstChild("Head")
if head then
local bb = head:FindFirstChild("ROLE_BB")
if bb then bb:Destroy() end
end
end

-- ESP Update Loop (Moved outside Heartbeat for better performance control)
task.spawn(function()
while true do
if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
local roles = getRoles()
local lpPos = LP.Character.HumanoidRootPart.Position

for _, plr in Players:GetPlayers() do  
            if plr ~= LP and plr.Character then  
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")  
                if hrp then  
                    local role = roles[plr.Name]  
                      
                    if not role or not ESP[role] or not ESP[role].Enabled then  
                        removeESP(plr.Character)  
                        continue  
                    end  
                      
                    local dist = (hrp.Position - lpPos).Magnitude  
                    if dist > MAX_DISTANCE then  
                        removeESP(plr.Character)  
                        continue  
                    end  
                      
                    local text = string.format(  
                        "<font size='16'>%s</font>\n<font color='rgb(255, 255, 255)'>[%dm]</font> <font color='rgb(255,150,0)'>[%s]</font>",  
                        plr.DisplayName,  
                        math.floor(dist),  
                        role  
                    )  
                    addHighlight(plr.Character, role)  
                    addBillboard(plr.Character, text, role)  
                else  
                    removeESP(plr.Character)  
                end  
            else  
                if plr.Character then removeESP(plr.Character) end  
            end  
        end  
    end  
    task.wait(UPDATE_SPEED)  
end

end)

--================================================================--
-- GUN ESP SYSTEM (NEW)
--================================================================--

local function RemoveGunEsp(gun)
    if gun and gun:FindFirstChild("GunHighlight") then
        gun:FindFirstChild("GunHighlight"):Destroy()
    end
    if gun and gun:FindFirstChild("GunEsp") then
        gun:FindFirstChild("GunEsp"):Destroy()
    end
end

local function AddGunEsp(gun)
    if not gun:FindFirstChild("GunHighlight") then
        local gunh = Instance.new("Highlight", gun)
        gunh.Name = "GunHighlight"
        gunh.FillColor = Color3.new(1, 1, 0)
        gunh.OutlineColor = Color3.new(1, 1, 1)
        gunh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        gunh.FillTransparency = 0.4
        gunh.OutlineTransparency = 0.5
    end
    if not gun:FindFirstChild("GunEsp") then
        local esp = Instance.new("BillboardGui")
        esp.Name = "GunEsp"
        esp.Adornee = gun
        esp.Size = UDim2.new(5, 0, 5, 0)
        esp.AlwaysOnTop = true
        esp.Parent = gun

        local text = Instance.new("TextLabel", esp)
        text.Name = "GunLabel"
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 1 -- no stroke
        text.TextColor3 = Color3.fromRGB(255, 255, 0)
        text.FontFace = Font.new("rbxassetid://12187362578")
        text.TextSize = 16
        text.Text = "Gun Drop"
    end
end

local function ToggleGunEsp(Value)
    _G.GunEsp = Value
    task.spawn(function()
        while _G.GunEsp do
            local gun = Workspace:FindFirstChild("GunDrop", true)
            if gun then
                AddGunEsp(gun)
            else
                RemoveGunEsp(gun) 
            end
            task.wait(0.1)
        end                
        local gun = Workspace:FindFirstChild("GunDrop", true)
        RemoveGunEsp(gun)
    end)
end
--================================================================--
-- SHOOT MURDER BUTTON SYSTEM 
--================================================================--

local BUTTON_WIDTH = 130
local BUTTON_HEIGHT = 90
local BUTTON_TEXT_SIZE = 20

local function getMurdererTarget()
    local data = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    for plr, plrData in pairs(data) do
        if plrData.Role == "Murderer" then
            local player = Players:FindFirstChild(plr)
            if player then
                if player == LP then return nil, true end
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then return hrp.Position, false end
                    local head = char:FindFirstChild("Head")
                    if head then return head.Position, false end
                end
            end
        end
    end
    return nil, false
end

local function ToggleShootMurderButton(Value)
    local guip, CoreGui = nil, game:FindService("CoreGui")
    
    if gethui then
        guip = gethui()
    elseif CoreGui and CoreGui:FindFirstChild("RobloxGui") then
        guip = CoreGui.RobloxGui
    elseif CoreGui then
        guip = CoreGui
    else
        guip = LP:FindFirstChild("PlayerGui")
    end

    if Value then
        if not guip:FindFirstChild("GunW") then
            local GunGui = Instance.new("ScreenGui", guip)
            GunGui.Name = "GunW"

            local TextButton = Instance.new("TextButton", GunGui)
            TextButton.Draggable = true
            TextButton.Position = UDim2.new(0.5, 250, 0.5, -130)
            TextButton.Size = UDim2.new(0, BUTTON_WIDTH, 0, BUTTON_HEIGHT)
            TextButton.TextStrokeTransparency = 0
            TextButton.BackgroundTransparency = 0.2
            TextButton.BackgroundColor3 = Color3.fromRGB(64, 0, 64)
            TextButton.BorderColor3 = Color3.new(1, 1, 1)
            TextButton.Text = "Shoot"
            TextButton.TextColor3 = Color3.new(1, 1, 1)
            TextButton.TextSize = BUTTON_TEXT_SIZE
            TextButton.Visible = true
            TextButton.AnchorPoint = Vector2.new(0.4, 0.2)
            TextButton.Active = true
            TextButton.TextWrapped = true

            local corner = Instance.new("UICorner", TextButton)
            local UIStroke = Instance.new("UIStroke", TextButton)
            UIStroke.Color = Color3.new(0, 0, 0)
            UIStroke.Thickness = 0
            UIStroke.Transparency = 0.8
            local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint", TextButton)
            UIAspectRatioConstraint.AspectRatio = 1.5

            TextButton.MouseButton1Click:Connect(function()
                if Char and Char:FindFirstChild("Gun") then
                    pcall(function()
                        Char.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, (getMurdererTarget()), "AH2")
                    end)
                end
            end)
        end
    else
        if guip:FindFirstChild("GunW") then
            guip:FindFirstChild("GunW"):Destroy()
        end
    end
end

--================================================================--
-- GRAB GUN & AUTO GRAB
--================================================================--

-- Consolidated GrabGun logic
local function GrabGun()
    if not Char or not Root then
        return false, "Character not loaded yet"
    end

    local gun = Workspace:FindFirstChild("GunDrop", true)
    if gun then
        if firetouchinterest then
            firetouchinterest(Root, gun, 0)
            firetouchinterest(Root, gun, 1)
        else
            gun.CFrame = Root.CFrame
        end
        return true, "Gun grabbed successfully!"
    else
        return false, "Gun is not dropped yet!"
    end
end

local function ToggleAutoGrabGun(Value)
    _G.AGG = Value
    task.spawn(function()
        while _G.AGG do
            local success, message = GrabGun()
            task.wait(0.2)
        end
    end)
end

--================================================================--
-- SPEED WALK
--================================================================--
local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_POWER = 50

local WALK_SPEED = 16
local JUMP_POWER = 50
local WalkSpeedEnabled = false
local JumpPowerEnabled = false
local speedConnection
local jumpConnection

local function applySpeed()
	if not LP.Character then return end
	local hum = LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		if WalkSpeedEnabled then
			hum.WalkSpeed = WALK_SPEED
		else
			hum.WalkSpeed = DEFAULT_WALK_SPEED
		end
	end
end

local function applyJumpPower()
	if not LP.Character then return end
	local hum = LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		if JumpPowerEnabled then
			hum.JumpPower = JUMP_POWER
		else
			hum.JumpPower = DEFAULT_JUMP_POWER
		end
	end
end

local function startSpeedLock()
	if speedConnection then speedConnection:Disconnect() end
	speedConnection = RunService.Heartbeat:Connect(applySpeed)
end

local function startJumpLock()
	if jumpConnection then jumpConnection:Disconnect() end
	jumpConnection = RunService.Heartbeat:Connect(applyJumpPower)
end

startSpeedLock()
startJumpLock()

LP.CharacterAdded:Connect(function()
	task.wait(0.2)
	applySpeed()
	applyJumpPower()
end)



--================================================================--
-- NOCLIP
--================================================================--
local NoclipEnabled = false
local ncConnection

local function EnableNoclip()
    if ncConnection then ncConnection:Disconnect() end
    ncConnection = RunService.Stepped:Connect(function()
        if NoclipEnabled and Char then
            for _, part in pairs(Char:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoclip()
    if ncConnection then ncConnection:Disconnect() end
    if Char then
        for _, part in pairs(Char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function ToggleNoclip(Value)
    NoclipEnabled = Value
    if Value then
        EnableNoclip()
    else
        DisableNoclip()
    end
end


--================================================================--
-- XRAY
--================================================================--
LP.CharacterAdded:Connect(function(newChar)
    Char = newChar
end)

local XRayEnabled = false
local originalTransparency = {}

local function EnableXRay()
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Skip all player characters
            local isPlayerPart = false
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and part:IsDescendantOf(player.Character) then
                    isPlayerPart = true
                    break
                end
            end
            if not isPlayerPart then
                if originalTransparency[part] == nil then
                    originalTransparency[part] = part.Transparency
                end
                part.Transparency = 0.8
            end
        end
    end
end

local function DisableXRay()
    for part, trans in pairs(originalTransparency) do
        if part and part.Parent then
            part.Transparency = trans
        end
    end
    originalTransparency = {}
end

local function ToggleXRay(Value)
    XRayEnabled = Value
    if Value then
        EnableXRay()
    else
        DisableXRay()
    end
end


--================================================================--
-- KNIFE AURA (FIXED & STANDALONE)
--================================================================--

--================================================================--


--================================================================--
-- GUI: CREATE WINDOW
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "Deadly Delivery",
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
-- TABS & GROUPS
--================================================================--

local MainTab = Window:AddTab("Main", "house")
local PlayerLeft = MainTab:AddLeftGroupbox("PLAYER", "user")
local PlayerRight = MainTab:AddRightGroupbox("OTHER", "layers")

local CombatTab = Window:AddTab("Combat", "target")
local AimbotLeft = CombatTab:AddLeftGroupbox("Gun", "crosshair")
local KnifeRight = CombatTab:AddRightGroupbox("Knife", "sword")

local VisualTab = Window:AddTab("Visual", "eye")
local EspLeft = VisualTab:AddLeftGroupbox("ROLE & ESP", "eye")
local EspRight = VisualTab:AddRightGroupbox("GUN & ESP", "radar")
--[[
local MiscTab = Window:AddTab("Misc", "settings")
local MiscLeft = MiscTab:AddLeftGroupbox("GAME SETTINGS", "sun")
]]
--================================================================--
-- PLAYER
--================================================================--
PlayerLeft:AddToggle("WalkSpeedToggle", {
	Text = "Walk Speed",
	Default = false,
	Callback = function(Value)
		WalkSpeedEnabled = Value
		applySpeed()
	end,
})

PlayerLeft:AddInput("WalkSpeedInput", {
	Default = tostring(WALK_SPEED),
	Numeric = true,
	ClearTextOnFocus = true,
	Text = "Walk Speed Value",
	Placeholder = "Enter speed",
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			WALK_SPEED = num
			applySpeed()
		end
	end,
})

PlayerLeft:AddToggle("JumpPowerToggle", {
	Text = "Jump Power",
	Default = false,
	Callback = function(Value)
		JumpPowerEnabled = Value
		applyJumpPower()
	end,
})

PlayerLeft:AddInput("JumpPowerInput", {
	Default = tostring(JUMP_POWER),
	Numeric = true,
	ClearTextOnFocus = true,
	Text = "Jump Power Value",
	Placeholder = "Enter jump power",
	Callback = function(Value)
		local num = tonumber(Value)
		if num then
			JUMP_POWER = num
			applyJumpPower()
		end
	end,
})



PlayerRight:AddToggle("NoclipToggle", {
    Text = "Noclip",
    Default = false,
    Callback = function(Value)
        ToggleNoclip(Value)
    end,
})



PlayerRight:AddToggle("XRayToggle", {
    Text = "X-Ray",
    Default = false,
    Callback = function(Value)
        ToggleXRay(Value)
    end,
})

--================================================================--
-- COMBAT
--================================================================--
AimbotLeft:AddToggle("ShootMurderButton", {
    Text = "Shoot Murder Button",
    Default = false,
    Callback = function(Value)
        ToggleShootMurderButton(Value)
    end
})

--[[
AimbotLeft:AddToggle("AutoGrabGun", {
    Text = "Auto Grab Gun",
    Default = false,
    Callback = function(Value)
        ToggleAutoGrabGun(Value)
    end
})

AimbotLeft:AddButton({
    Text = "Grab Gun",
    Func = function()
        local success, message = GrabGun()
        Library:Notify({
            Title = success and "Success!" or "Error!",
            Description = message,
            Time = 3
        })
    end,
})
]]



--================================================================--
-- ESP TOGGLES
--================================================================--
EspLeft:AddToggle("SheriffESP", {Text = "Sheriff/Hero ESP", Default = false, Callback = function(Value) toggleESP("SheriffESP", Value) end})
EspLeft:AddToggle("MurdererESP", {Text = "Murderer ESP", Default = false, Callback = function(Value) toggleESP("MurdererESP", Value) end})
EspLeft:AddToggle("InnocentESP", {Text = "Innocent ESP", Default = false, Callback = function(Value) toggleESP("InnocentESP", Value) end})


--[[
EspRight:AddToggle("GunESP", {
    Text = "Gun Drop ESP",
    Default = false,
    Callback = function(Value)
        ToggleGunEsp(Value)
    end
})
]]
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
