--================================================================--
--                    VGXMOD HUB 
--        
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
-- BYPASS
--================================================================--
local g = getinfo or debug.getinfo
local d = true
local h = {}

local x, y

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
    
        if typeof(a) == "function" and not x then
            x = a
            
            local o; o = hookfunction(x, function(c, f, n)
                if c ~= "_" and d then
                    warn(`Adonis AntiCheat flagged\nMethod: {c}\nInfo: {f}`)
                end
                return true
            end)

            table.insert(h, x)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b

            local o; o = hookfunction(y, function(f)
                if d then
                    warn(`Adonis AntiCheat tried to kill (fallback): {f}`)
                end
            end)

            table.insert(h, y)
        end
    end
end

local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...

    if x and a == x then
        if d then
            warn(`Bypass Gay AntiCheat`)
        end
        return coroutine.yield(coroutine.running())
    end
    
    return o(...)
end))

setthreadidentity(7)
--================================================================--
-- Auto Lock
--================================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRoot = character:WaitForChild("HumanoidRootPart")

local autoLockEnabled = false
local lockDistance = 50

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = lockDistance
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = player.Character.HumanoidRootPart.Position
            local distance = (targetPos - humanoidRoot.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if autoLockEnabled and humanoidRoot and humanoidRoot.Parent then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Character.HumanoidRootPart.Position
            local direction = (Vector3.new(targetPos.X, humanoidRoot.Position.Y, targetPos.Z) - humanoidRoot.Position).Unit
            humanoidRoot.CFrame = CFrame.new(humanoidRoot.Position, humanoidRoot.Position + direction)
        end
    end
end)

localPlayer.CharacterAdded:Connect(function(char)
    character = char
    humanoidRoot = character:WaitForChild("HumanoidRootPart")
end)

--================================================================--
-- GUI
--================================================================--
local Window = Library:CreateWindow({
    Title = "Vgxmod Hub",
    Footer = "Time Bomb Duel",
    Icon = 94858886314945,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- INFO TAB
local InfoTab = Window:AddTab("Info", "info")
local InfoLeft = InfoTab:AddLeftGroupbox("Credits", "users")
local InfoLeft2 = InfoTab:AddLeftGroupbox("Discord", "discord")
local InfoRight = InfoTab:AddRightGroupbox("Reminder", "lucide-book-a")

InfoLeft:AddLabel("Made By: Pkgx1")
InfoLeft:AddLabel("Discord: https://discord.gg/n9gtmefsjc")
InfoLeft:AddDivider()
InfoLeft:AddLabel("You Can Request Script")
InfoLeft:AddLabel("On Discord!")
InfoLeft:AddDivider()


InfoLeft2:AddLabel("Discord Link")
InfoLeft2:AddButton({
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

----------------------------------------------------------------
-- MAIN TAB (4 GROUPBOX CLEAN ORGANIZATION)
----------------------------------------------------------------
local MainTab = Window:AddTab("Main", "house")
local AutoLeft     = MainTab:AddLeftGroupbox("Aim Lock", "lock")
local BypassRight    = MainTab:AddRightGroupbox("Protection","shield")
----------------------------------------------------------------
-- HITBOX SECTION
----------------------------------------------------------------


AutoLeft:AddToggle("AutoLockToggle", {
    Text = "Auto Lock",
    Default = false,
    Callback = function(state)
        autoLockEnabled = state
    end
})

AutoLeft:AddInput("AutoLockDistanceInput", {
    Default = tostring(lockDistance),
    Numeric = true,
    ClearTextOnFocus = true,
    Text = "Lock Distance",
    Placeholder = "Enter max distance",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            lockDistance = num
            Library:Notify({Title = "Auto Lock", Description = "Lock distance set to "..num, Time = 2})
        end
    end
})

----------------------------------------------------------------
-- PROTECTION SECTION (Adonis Bypass)
----------------------------------------------------------------
BypassRight:AddToggle("AdonisBypassToggle", {
    Text = "Bypass (AntiCheat)",
    Default = true,
    Callback = function(Value)
        d = Value
        if Value then
            Library:Notify({ Title = "Bypass", Description = "Enabled", Time = 2 })
        else
            Library:Notify({ Title = "Bypass", Description = "Disabled", Time = 2 })
        end
    end,
})


----------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------
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
