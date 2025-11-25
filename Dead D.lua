--================================================================--
--                             VGXMOD HUB
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
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--================================================================--
-- ESP SYSTEM 
--================================================================--


local MAX_DISTANCE = 99999

local ESP = {
    Crate     = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0.7 },
    Cabinet   = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0.7 },
    OilBucket = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 0.7 },
    Loot      = { Enabled = false, Color = Color3.fromRGB(0, 255, 0), Transparency = 0.7 },
    Monster   = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.7 },
    Player    = { Enabled = false, Color = Color3.new(1,1,1), Transparency = 0.5 }
}

local INTERACTIVE_FOLDER = Workspace:WaitForChild("GameSystem"):WaitForChild("InteractiveItem")
local LOOT_FOLDER        = Workspace:WaitForChild("GameSystem"):WaitForChild("Loots"):WaitForChild("World")
local MONSTER_FOLDER     = Workspace:WaitForChild("GameSystem"):WaitForChild("Monsters")

local TrackedObjects   = {}
local TrackedLoot      = {}
local TrackedMonsters  = {}

local function cleanName(name)
    local prefix = name:match("^[^_%d]+")
    if prefix then
        prefix = prefix:gsub("%s+$", "")
    end
    return prefix
end

local function getObjectType(name)
    local prefix = cleanName(name)
    if not prefix then return nil end
    for objType,_ in pairs(ESP) do
        if prefix:lower() == objType:lower() then
            return objType
        end
    end
    return nil
end

local function createESP(model, fillColor, fillTrans, text)
    if not model or not model.Parent then return end
    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    local hl = model:FindFirstChild("OBJ_ESP_HL") or Instance.new("Highlight", model)
    hl.Name = "OBJ_ESP_HL"
    hl.Adornee = model
    hl.FillColor = fillColor
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = fillTrans
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local bg = root:FindFirstChild("OBJ_ESP_BILLBOARD") or Instance.new("BillboardGui", root)
    bg.Name = "OBJ_ESP_BILLBOARD"
    bg.Adornee = root
    bg.Size = UDim2.new(0, 240, 0, 50)
    bg.StudsOffset = Vector3.new(0, 4, 0)
    bg.AlwaysOnTop = true
    bg.MaxDistance = MAX_DISTANCE

    local label = bg:FindFirstChild("Label") or Instance.new("TextLabel", bg)
    label.Name = "Label"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.RichText = true
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.FontFace = Font.new("rbxassetid://12187362578")
    label.TextSize = 10
end

local function removeESPVisuals(model)
    if not model then return end
    local hl = model:FindFirstChild("OBJ_ESP_HL")
    if hl then hl:Destroy() end
    local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if root and root:FindFirstChild("OBJ_ESP_BILLBOARD") then
        root.OBJ_ESP_BILLBOARD:Destroy()
    end
end

local function trackInteractive(model)
    if not model or not model:IsA("Model") then return end
    local objType = getObjectType(model.Name)
    if objType then
        TrackedObjects[model] = objType
        if not ESP[objType].Enabled then removeESPVisuals(model) end
    end
end

local function untrackInteractive(model)
    TrackedObjects[model] = nil
    removeESPVisuals(model)
end

local function trackLoot(model)
    if model and model:IsA("Model") then
        TrackedLoot[model] = true
        if not ESP.Loot.Enabled then removeESPVisuals(model) end
    end
end
local function untrackLoot(model) TrackedLoot[model] = nil removeESPVisuals(model) end

local function trackMonster(model)
    if model and model:IsA("Model") then
        TrackedMonsters[model] = true
        if not ESP.Monster.Enabled then removeESPVisuals(model) end
    end
end
local function untrackMonster(model) TrackedMonsters[model] = nil removeESPVisuals(model) end

for _, obj in ipairs(INTERACTIVE_FOLDER:GetChildren()) do trackInteractive(obj) end
for _, obj in ipairs(LOOT_FOLDER:GetChildren()) do trackLoot(obj) end
for _, obj in ipairs(MONSTER_FOLDER:GetChildren()) do trackMonster(obj) end

INTERACTIVE_FOLDER.ChildAdded:Connect(function(obj) task.wait() trackInteractive(obj) end)
INTERACTIVE_FOLDER.ChildRemoved:Connect(untrackInteractive)
LOOT_FOLDER.ChildAdded:Connect(trackLoot)
LOOT_FOLDER.ChildRemoved:Connect(untrackLoot)
MONSTER_FOLDER.ChildAdded:Connect(trackMonster)
MONSTER_FOLDER.ChildRemoved:Connect(untrackMonster)

local function toggleESP(name, enabled)
    ESP[name].Enabled = enabled
    Library:Notify({
        Title = name .. " ESP",
        Description = enabled and "Enabled" or "Disabled",
        Time = 4
    })
    -- remove visuals immediately if toggled off
    if not enabled then
        if name == "Player" then
            for _, plr in pairs(Players:GetPlayers()) do
                removeESPVisuals(plr.Character)
            end
        elseif name == "Monster" then
            for model,_ in pairs(TrackedMonsters) do
                removeESPVisuals(model)
            end
        elseif name == "Loot" then
            for model,_ in pairs(TrackedLoot) do
                removeESPVisuals(model)
            end
        else
            for model,objType in pairs(TrackedObjects) do
                if objType == name then
                    removeESPVisuals(model)
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LP.Character.HumanoidRootPart.Position

    for model, objType in pairs(TrackedObjects) do
        if not ESP[objType].Enabled then
            removeESPVisuals(model)
        elseif model and model.Parent then
            local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist <= MAX_DISTANCE then
                    local FILL_COLOR = ESP[objType].Color
                    local FILL_TRANS = ESP[objType].Transparency
                    local text = string.format("<font color='rgb(%d,%d,%d)'>%s</font>\n[%dm]",
                        FILL_COLOR.R*255, FILL_COLOR.G*255, FILL_COLOR.B*255,
                        objType, math.floor(dist))
                    createESP(model, FILL_COLOR, FILL_TRANS, text)
                else
                    removeESPVisuals(model)
                end
            end
        else
            removeESPVisuals(model)
        end
    end

    if ESP.Loot.Enabled then
        for model,_ in pairs(TrackedLoot) do
            if model and model.Parent then
                local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist <= MAX_DISTANCE then
                        local lootName, price = "Unknown", "0"
                        local lootUI = model:FindFirstChild("Folder") and model.Folder:FindFirstChild("Interactable") and model.Folder.Interactable:FindFirstChild("LootUI")
                        if lootUI and lootUI:FindFirstChild("Frame") then
                            local frame = lootUI.Frame
                            if frame:FindFirstChild("ItemName") then lootName = frame.ItemName.Text end
                            if frame:FindFirstChild("Price") then price = frame.Price.Text end
                        end
                        if lootName == "Unknown" then lootName = "Money"; price = "" end
                        local text = string.format("<font color='rgb(%d,%d,%d)'>%s\n%s</font>\n[%dm]",
                            ESP.Loot.Color.R*255, ESP.Loot.Color.G*255, ESP.Loot.Color.B*255,
                            lootName, price, math.floor(dist))
                        createESP(model, ESP.Loot.Color, ESP.Loot.Transparency, text)
                    else removeESPVisuals(model) end
                end
            else removeESPVisuals(model) end
        end
    else
        for model,_ in pairs(TrackedLoot) do removeESPVisuals(model) end
    end

    if ESP.Monster.Enabled then
        for model,_ in pairs(TrackedMonsters) do
            if model and model.Parent then
                local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist <= MAX_DISTANCE then
                        local text = string.format("<font color='rgb(%d,%d,%d)'>%s</font>\n[%dm]",
                            ESP.Monster.Color.R*255, ESP.Monster.Color.G*255, ESP.Monster.Color.B*255,
                            "Monster", math.floor(dist))
                        createESP(model, ESP.Monster.Color, ESP.Monster.Transparency, text)
                    else removeESPVisuals(model) end
                end
            else removeESPVisuals(model) end
        end
    else
        for model,_ in pairs(TrackedMonsters) do removeESPVisuals(model) end
    end

    if ESP.Player.Enabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                local dist = math.floor((hrp.Position - myPos).Magnitude)
                if dist <= MAX_DISTANCE then
                    local text = string.format("<font color='rgb(255,255,255)'>%s\n[Player]</font>\n[%dm]", plr.DisplayName, dist)
                    createESP(plr.Character, ESP.Player.Color, ESP.Player.Transparency, text)
                else removeESPVisuals(plr.Character) end
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            removeESPVisuals(plr.Character)
        end
    end
end)

--================================================================--
-- ANTI TRAP SYSTEM 
--================================================================--
local RemoveHitboxEnabled = false

local function removeMonsterHitboxes()
    for _, monster in pairs(workspace.GameSystem.Monsters:GetChildren()) do
        for _, part in pairs(monster:GetDescendants()) do
            if part:IsA("TouchTransmitter") then
                part:Destroy()
            end
        end
    end
end

workspace.GameSystem.Monsters.ChildAdded:Connect(function(monster)
    if RemoveHitboxEnabled then
        task.wait()
        for _, part in pairs(monster:GetDescendants()) do
            if part:IsA("TouchTransmitter") then
                part:Destroy()
            end
        end
    end
end)

local function toggleRemoveHitbox(value)
    RemoveHitboxEnabled = value
    if RemoveHitboxEnabled then
        removeMonsterHitboxes()
    end
    Library:Notify({
        Title = "Anti Trap Monster",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end

--================================================================--
-- TELEPORT ELEVATOR SYSTEM 
--================================================================--
local function teleportToElevator()
    local targetPart = workspace["\231\148\181\230\162\175"].Left4.DoorController.DT
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
end
--================================================================--
-- AUTO LOOT SYSTEM 
--================================================================--
local AutoOpenEnabled = false
local AutoPickItemEnabled = false
local AutoPickGearEnabled = false

local RunService = game:GetService("RunService")
local LP = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TEvent = require(ReplicatedStorage.Shared.Core.TEvent)

local blacklistItems = {
    ["Flashlight"] = true,
    ["Bandage"] = true,
    ["Box"] = true,
    ["Bloxy Cola"] = true,
    ["Hourglass"] = true,
    ["Revive Syringe"] = true,
    ["Baseball Bat"] = true,
    ["Teleporter"] = true,
    ["Z-Ray Gun"] = true,
    ["Double Barrel"] = true,
}

-- single heartbeat for all auto functions
RunService.Heartbeat:Connect(function()
    local chr = LP.Character or LP.CharacterAdded:Wait()
    local hrp = chr:WaitForChild("HumanoidRootPart")

    if AutoOpenEnabled then
        for _, obj in pairs(workspace.GameSystem.InteractiveItem:GetDescendants()) do
            if obj:HasTag("Interactable") and obj:GetAttribute("en") then
                local dst = obj:GetAttribute("sz") or 20
                local prt = obj:IsA("Model") and obj.PrimaryPart or obj:IsA("BasePart") and obj
                if prt and (hrp.Position - prt.Position).Magnitude <= dst then
                    TEvent.FireRemote("Interactable", obj)
                end
            end
        end
    end

    if AutoPickItemEnabled or AutoPickGearEnabled then
        for _, obj in pairs(workspace.GameSystem.Loots.World:GetDescendants()) do
            if obj:HasTag("Interactable") and obj:GetAttribute("en") then
                local prt = obj:IsA("Model") and obj.PrimaryPart or obj:IsA("BasePart") and obj
                if prt and (hrp.Position - prt.Position).Magnitude <= (obj:GetAttribute("sz") or 20) then
                    local lootName = nil
                    local lootUI = obj:FindFirstChild("Folder") and obj.Folder:FindFirstChild("Interactable") and obj.Folder.Interactable:FindFirstChild("LootUI")
                    if lootUI and lootUI:FindFirstChild("Frame") and lootUI.Frame:FindFirstChild("ItemName") then
                        lootName = lootUI.Frame.ItemName.Text
                    end

                    if AutoPickItemEnabled and lootName and not blacklistItems[lootName] then
                        TEvent.FireRemote("Interactable", obj)
                    elseif AutoPickGearEnabled and lootName and blacklistItems[lootName] then
                        TEvent.FireRemote("Interactable", obj)
                    end
                end
            end
        end
    end
end)

-- toggles
local function toggleAutoOpen(value)
    AutoOpenEnabled = value
    Library:Notify({Title = "Auto Open", Description = value and "Enabled" or "Disabled", Time = 3})
end

local function toggleAutoPickItem(value)
    AutoPickItemEnabled = value
    Library:Notify({Title = "Auto Pick Up (Item)", Description = value and "Enabled" or "Disabled", Time = 3})
end

local function toggleAutoPickGear(value)
    AutoPickGearEnabled = value
    Library:Notify({Title = "Auto Pick Up (Gear)", Description = value and "Enabled" or "Disabled", Time = 3})
end





--================================================================--
-- AUTO FARM SYSTEM 
--================================================================--
local AutoLootTPEnabled = false
local tpConnection = nil
local visitedInteractive = {}
local visitedLoot = {}

local BLACKLIST = {
    ["Flashlight"]=true, ["Bandage"]=true, ["Box"]=true, ["Bloxy Cola"]=true,
    ["Hourglass"]=true, ["Revive Syringe"]=true, ["Baseball Bat"]=true,
    ["Teleporter"]=true, ["Z-Ray Gun"]=true, ["Double Barrel"]=true,
    ["Cash"]=true, ["Unknown"]=true
}

local function getRandomPart(obj)
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
    elseif obj:IsA("BasePart") then
        return obj
    end
end

local function teleportTo(target)
    if not target then return end
    local targetPart = getRandomPart(target)
    if not targetPart then return end
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = targetPart.CFrame + Vector3.new(0,2,0)
end

local function teleportToElevator()
    local targetPart = workspace["\231\148\181\230\162\175"].Left4.DoorController.DT
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = targetPart.CFrame + Vector3.new(0,2,0)
end

local function getValidLoot()
    local lootFolder = workspace.GameSystem.Loots.World:GetChildren()
    local validLoot = {}
    for _, obj in ipairs(lootFolder) do
        local lootName = obj:FindFirstChild("Folder") and obj.Folder:FindFirstChild("Interactable") and obj.Folder.Interactable:FindFirstChild("LootUI") and obj.Folder.Interactable.LootUI.Frame.ItemName
        if lootName and not BLACKLIST[lootName.Text] then
            table.insert(validLoot, obj)
        end
    end
    return validLoot
end

local function autoLootTP()
    while AutoLootTPEnabled do
        visitedInteractive = {}
        local interactFolder = workspace.GameSystem.InteractiveItem:GetChildren()
        for _, obj in ipairs(interactFolder) do
            if not visitedInteractive[obj] then
                teleportTo(obj)
                visitedInteractive[obj] = true
                task.wait(0.1)
            end
        end

        visitedLoot = {}
        local validLoot = getValidLoot()
        for _, obj in ipairs(validLoot) do
            if not visitedLoot[obj] then
                teleportTo(obj)
                visitedLoot[obj] = true
                task.wait(0.2)
            end
        end

        task.wait(1)
        teleportToElevator()
        task.wait(2)

        -- Instead of breaking, keep waiting and checking for new loot
        while AutoLootTPEnabled and #getValidLoot() == 0 do
            task.wait(1) -- wait until new loot spawns
        end
    end
end

local function toggleAutoLootTP(value)
    AutoLootTPEnabled = value

    if tpConnection then
        tpConnection:Disconnect()
        tpConnection = nil
    end

    if AutoLootTPEnabled then
        tpConnection = RunService.Heartbeat:Connect(function()
            tpConnection:Disconnect()
            task.spawn(autoLootTP)
        end)
    end

    Library:Notify({
        Title = "Auto Farm",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end

--================================================================--
-- SPEED WALK
--================================================================--
local WALK_SPEED = 18
local WalkSpeedEnabled = false
local speedConnection

local function applySpeed()
	if not LP.Character then return end
	local hum = LP.Character:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = WALK_SPEED
	end
end

local function startSpeedLock()
	if speedConnection then speedConnection:Disconnect() end
	speedConnection = RunService.Heartbeat:Connect(function()
		if WalkSpeedEnabled then
			applySpeed()
		end
	end)
end

startSpeedLock()

LP.CharacterAdded:Connect(function()
	task.wait(0.2)
	applySpeed()
end)
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
-- MAIN TAB
--================================================================--
local MainTab = Window:AddTab("Main", "house")
local AutoLeft = MainTab:AddLeftGroupbox("AUTOMATION", "cpu")
local PlayerLeft = MainTab:AddLeftGroupbox("PLAYER", "user")
local TeleportRight = MainTab:AddRightGroupbox("TELEPORT", "refresh-ccw")
local ESPRight = MainTab:AddRightGroupbox("ESP", "eye")

--================================================================--
-- AUTOMATION 
--================================================================--
AutoLeft:AddToggle("AutoLootTP", {
    Text = "Auto Farm",
    Default = false,
    Callback = toggleAutoLootTP
})

AutoLeft:AddToggle("AutoOpen", {
    Text = "Auto Open",
    Default = false,
    Callback = toggleAutoOpen
})

AutoLeft:AddToggle("AutoPickItem", {
    Text = "Auto Pick Up (Item)",
    Default = false,
    Callback = toggleAutoPickItem
})

AutoLeft:AddToggle("AutoPickGear", {
    Text = "Auto Pick Up (Gear)",
    Default = false,
    Callback = toggleAutoPickGear
})
--================================================================--
-- PLAYER
--================================================================--
PlayerLeft:AddToggle("WalkSpeedToggle", {
	Text = "Walk Speed",
	Default = false,
	Callback = function(Value)
		WalkSpeedEnabled = Value
		setSpeed(WALK_SPEED)
	end,
})

PlayerLeft:AddSlider("WalkSpeedSlider", {
	Text = "Value",
	Default = 18,
	Min = 12,
	Max = 100,
	Rounding = 1,
	Callback = function(Value)
		WALK_SPEED = Value
		setSpeed(WALK_SPEED)
	end,
})

PlayerLeft:AddToggle("RemoveMonsterHitbox", {
    Text = "Anti Trap (Monster)",
    Default = false,
    Callback = toggleRemoveHitbox
})

--================================================================--
-- TELEPORT 
--================================================================--
TeleportRight:AddButton({
    Text = "TP Elevator",
    Func = function()
        teleportToElevator()
    end,
})
--================================================================--
-- ESP
--================================================================--

ESPRight:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false,
    Callback = function(Value)
        toggleESP("Player", Value)
    end,
})

ESPRight:AddToggle("MonsterESP", {
    Text = "Monster ESP",
    Default = false,
    Callback = function(Value)
        toggleESP("Monster", Value)
    end,
})

ESPRight:AddToggle("LootESP", {
    Text = "Loot ESP",
    Default = false,
    Callback = function(Value)
        toggleESP("Loot", Value)
    end,
})

ESPRight:AddToggle("CrateESP", {
    Text = "Crate ESP",
    Default = false,
    Callback = function(Value)
        toggleESP("Crate", Value)
    end,
})

ESPRight:AddToggle("CabinetESP", {
    Text = "Cabinet ESP",
    Default = false,
    Callback = function(Value)
        toggleESP("Cabinet", Value)
    end,
})

ESPRight:AddToggle("OilBucketESP", {
    Text = "Oil Bucket ESP",
    Default = false,
    Callback = function(Value)
        toggleESP("OilBucket", Value)
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
