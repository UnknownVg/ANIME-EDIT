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

local TEvent = require(ReplicatedStorage.Shared.Core.TEvent)

local LootsWorld = workspace.GameSystem.Loots.World
local InteractiveItem = workspace.GameSystem.InteractiveItem
local NPCModels = workspace.GameSystem.NPCModels
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
    Player    = { Enabled = false, Color = Color3.new(1,1,1), Transparency = 0.7 },
    NPC       = { Enabled = false, Color = Color3.fromRGB(255, 165, 0), Transparency = 0.7 }
}



local INTERACTIVE_FOLDER = workspace:WaitForChild("GameSystem"):WaitForChild("InteractiveItem")
local LOOT_FOLDER        = workspace:WaitForChild("GameSystem"):WaitForChild("Loots"):WaitForChild("World")
local MONSTER_FOLDER     = workspace:WaitForChild("GameSystem"):WaitForChild("Monsters")
local NPC_FOLDER         = workspace:WaitForChild("GameSystem"):WaitForChild("NPCModels")

local TrackedObjects   = {}
local TrackedLoot      = {}
local TrackedMonsters  = {}
local TrackedNPCs      = {}

local function cleanName(name)
    return name:match("^[^_%d]+"):gsub("%s+$", "")
end

local function getObjectType(name)
    local prefix = cleanName(name)
    for objType,_ in pairs(ESP) do
        if prefix:lower() == objType:lower() then return objType end
    end
    return nil
end

local function getCleanNPCName(model)
    local name = model.Name
    name = name:match("^(.-)[_%d]") or name
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name ~= "" and name or "NPC"
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
    if root then
        local bg = root:FindFirstChild("OBJ_ESP_BILLBOARD")
        if bg then bg:Destroy() end
    end
end

local function trackInteractive(m) if m:IsA("Model") then local t = getObjectType(m.Name) if t then TrackedObjects[m] = t end end end
local function untrackInteractive(m) TrackedObjects[m] = nil removeESPVisuals(m) end
local function trackLoot(m) if m:IsA("Model") then TrackedLoot[m] = true end end
local function untrackLoot(m) TrackedLoot[m] = nil removeESPVisuals(m) end
local function trackMonster(m) if m:IsA("Model") then TrackedMonsters[m] = true end end
local function untrackMonster(m) TrackedMonsters[m] = nil removeESPVisuals(m) end
local function trackNPC(m) if m:IsA("Model") then TrackedNPCs[m] = true end end
local function untrackNPC(m) TrackedNPCs[m] = nil removeESPVisuals(m) end

for _,v in ipairs(INTERACTIVE_FOLDER:GetChildren()) do trackInteractive(v) end
for _,v in ipairs(LOOT_FOLDER:GetChildren()) do trackLoot(v) end
for _,v in ipairs(MONSTER_FOLDER:GetChildren()) do trackMonster(v) end
for _,v in ipairs(NPC_FOLDER:GetChildren()) do trackNPC(v) end

INTERACTIVE_FOLDER.ChildAdded:Connect(trackInteractive)
INTERACTIVE_FOLDER.ChildRemoved:Connect(untrackInteractive)
LOOT_FOLDER.ChildAdded:Connect(trackLoot)
LOOT_FOLDER.ChildRemoved:Connect(untrackLoot)
MONSTER_FOLDER.ChildAdded:Connect(trackMonster)
MONSTER_FOLDER.ChildRemoved:Connect(untrackMonster)
NPC_FOLDER.ChildAdded:Connect(trackNPC)
NPC_FOLDER.ChildRemoved:Connect(untrackNPC)

local function toggleESP(name, enabled)
    ESP[name].Enabled = enabled
    Library:Notify({Title = name.." ESP", Description = enabled and "Enabled" or "Disabled", Duration = 3})
end

RunService.Heartbeat:Connect(function()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LP.Character.HumanoidRootPart.Position

    for model, objType in pairs(TrackedObjects) do
        if ESP[objType].Enabled and model and model.Parent then
            local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist <= MAX_DISTANCE then
                    local text = string.format("<font color='rgb(%d,%d,%d)'>%s</font>\n[%dm]",
                        ESP[objType].Color.R*255, ESP[objType].Color.G*255, ESP[objType].Color.B*255,
                        objType, math.floor(dist))
                    createESP(model, ESP[objType].Color, ESP[objType].Transparency, text)
                else removeESPVisuals(model) end
            end
        else removeESPVisuals(model) end
    end

    if ESP.Loot.Enabled then
        for model,_ in pairs(TrackedLoot) do
            if model and model.Parent then
                local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist <= MAX_DISTANCE then
                        local name, price = "Unknown", ""
                        local ui = model:FindFirstChild("Folder") and model.Folder:FindFirstChild("Interactable") and model.Folder.Interactable:FindFirstChild("LootUI")
                        if ui and ui:FindFirstChild("Frame") then
                            local f = ui.Frame
                            if f:FindFirstChild("ItemName") then name = f.ItemName.Text end
                            if f:FindFirstChild("Price") then price = f.Price.Text end
                        end
                        if name == "Unknown" then name = "Money" end
                        local text = string.format("<font color='rgb(0,255,0)'>%s\n%s</font>\n[%dm]", name, price, math.floor(dist))
                        createESP(model, ESP.Loot.Color, ESP.Loot.Transparency, text)
                    else removeESPVisuals(model) end
                end
            else removeESPVisuals(model) end
        end
    end

    if ESP.Monster.Enabled then
        for model,_ in pairs(TrackedMonsters) do
            if model and model.Parent then
                local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = math.floor((root.Position - myPos).Magnitude)
                    if dist <= MAX_DISTANCE then
                        local text = string.format("<font color='rgb(255,0,0)'>Monster</font>\n[%dm]", dist)
                        createESP(model, ESP.Monster.Color, ESP.Monster.Transparency, text)
                    else removeESPVisuals(model) end
                end
            else removeESPVisuals(model) end
        end
    end

    if ESP.NPC.Enabled then
        for model,_ in pairs(TrackedNPCs) do
            if model and model.Parent then
                local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = math.floor((root.Position - myPos).Magnitude)
                    if dist <= MAX_DISTANCE then
                        local cleanName = getCleanNPCName(model)
                        local text = string.format("<font color='rgb(255,165,0)'>%s</font>\n[%dm]", cleanName, dist)
                        createESP(model, ESP.NPC.Color, ESP.NPC.Transparency, text)
                    else removeESPVisuals(model) end
                end
            else removeESPVisuals(model) end
        end
    end

    if ESP.Player.Enabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((plr.Character.HumanoidRootPart.Position - myPos).Magnitude)
                if dist <= MAX_DISTANCE then
                    local text = string.format("<font color='rgb(255,255,255)'>%s\n[Player]</font>\n[%dm]", plr.DisplayName, dist)
                    createESP(plr.Character, ESP.Player.Color, ESP.Player.Transparency, text)
                else removeESPVisuals(plr.Character) end
            end
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


local AutoPickEnabled = false
local AutoOpenEnabled = false
local AutoGearEnabled = false
local PickLoop
local OpenConnection
local GearLoop

local BLOCKED_ITEMS = {"Flashlight","Bandage","Box","Bloxy Cola","Hourglass","Revive Syringe","Baseball Bat","Teleporter","Z-Ray Gun","Double Barrel"}
local BLOCKED_SET = {}
for _,v in BLOCKED_ITEMS do BLOCKED_SET[v:lower()] = true end

local GEAR_ONLY = {"Flashlight","Bandage","Box","Bloxy Cola","Hourglass","Revive Syringe","Baseball Bat","Teleporter","Z-Ray Gun","Double Barrel"}
local GEAR_SET = {}
for _,v in GEAR_ONLY do GEAR_SET[v:lower()] = true end

local function fireInteract(obj,force)
	TEvent.FireRemote("Interactable",obj,force==true)
end

local function isBlocked(obj)
	local lbl = obj:FindFirstChild("LootUI",true)
	if lbl then lbl = lbl:FindFirstChild("Frame",true) end
	if lbl then lbl = lbl:FindFirstChild("ItemName") end
	return lbl and BLOCKED_SET[lbl.Text:lower()] or false
end

local function isGear(obj)
	local lbl = obj:FindFirstChild("LootUI",true)
	if lbl then lbl = lbl:FindFirstChild("Frame",true) end
	if lbl then lbl = lbl:FindFirstChild("ItemName") end
	return lbl and GEAR_SET[lbl.Text:lower()] or false
end

local function toggleAutoPick(state)
	AutoPickEnabled = state
	if PickLoop then task.cancel(PickLoop) PickLoop = nil end
	if state then
		PickLoop = task.spawn(function()
			while AutoPickEnabled do
				for _,obj in LootsWorld:GetDescendants() do
					if obj:HasTag("Interactable") and obj:GetAttribute("en") and not isBlocked(obj) then
						fireInteract(obj,true)
					end
				end
				task.wait(0.15)
			end
		end)
	end
end

local function toggleAutoOpen(state)
	AutoOpenEnabled = state
	if OpenConnection then OpenConnection:Disconnect() OpenConnection = nil end
	if state then
		for _,obj in InteractiveItem:GetDescendants() do
			if obj:HasTag("Interactable") then task.defer(fireInteract,obj,true) end
		end
		OpenConnection = InteractiveItem.DescendantAdded:Connect(function(obj)
			if obj:HasTag("Interactable") then task.defer(fireInteract,obj,true) end
		end)
	end
end

local function toggleAutoGear(state)
	AutoGearEnabled = state
	if GearLoop then task.cancel(GearLoop) GearLoop = nil end
	if state then
		GearLoop = task.spawn(function()
			while AutoGearEnabled do
				for _,obj in LootsWorld:GetDescendants() do
					if obj:HasTag("Interactable") and obj:GetAttribute("en") and isGear(obj) then
						fireInteract(obj,true)
					end
				end
				task.wait(0.15)
			end
		end)
	end
end

local oldFire
oldFire = hookfunction(TEvent.FireRemote,function(name,obj,forced)
	if name=="Interactable" and (LootsWorld:IsAncestorOf(obj) or InteractiveItem:IsAncestorOf(obj)) then
		return oldFire(name,obj,true)
	end
	return oldFire(name,obj,forced)
end)





--================================================================--
-- AUTO FARM SYSTEM 
--================================================================--
local AutoLootTPEnabled = false
local FarmLoop = nil

local BLACKLIST = {
	["Flashlight"]=true,["Bandage"]=true,["Box"]=true,["Bloxy Cola"]=true,
	["Hourglass"]=true,["Revive Syringe"]=true,["Baseball Bat"]=true,
	["Teleporter"]=true,["Z-Ray Gun"]=true,["Double Barrel"]=true,
	["Cash"]=true,["Unknown"]=true
}

local LP = game.Players.LocalPlayer
local RunService = game:GetService("RunService")

local function teleportToElevator()
	pcall(function()
		local elev = workspace:FindFirstChild("电梯")
		if elev and elev:FindFirstChild("Left4") then
			local target = elev.Left4.DoorController.DT
			local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if hrp and target then
				hrp.CFrame = target.CFrame + Vector3.new(0,5,0)
			end
		end
	end)
end

local function getValidLoot()
	local loot = {}
	for _, obj in workspace.GameSystem.Loots.World:GetChildren() do
		local interact = obj:FindFirstChild("Folder", true) and obj.Folder:FindFirstChild("Interactable", true)
		local itemName = interact and interact:FindFirstChild("LootUI", true) 
			and interact.LootUI:FindFirstChild("Frame", true) 
			and interact.LootUI.Frame:FindFirstChild("ItemName")
		if itemName and not BLACKLIST[itemName.Text] then
			local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
			if part then table.insert(loot, part) end
		end
	end
	return loot
end

local function startFarming()
	if FarmLoop then return end
	FarmLoop = task.spawn(function()
		while AutoLootTPEnabled do
			local lootList = getValidLoot()
			if #lootList == 0 then
				task.wait(1)
				continue
			end

			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.PlatformStand = true end

			for i = 1, math.min(4, #lootList) do
				if not AutoLootTPEnabled then break end
				local target = lootList[i]
				if target and target.Parent and LP.Character then
					local hrp = LP.Character.HumanoidRootPart
					local pos = target.Position + Vector3.new(0, 8, 0)
					hrp.CFrame = CFrame.new(pos, target.Position)
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end
				task.wait(0.1)
			end

			if hum then hum.PlatformStand = false end
			teleportToElevator()
			task.wait(1.5)
		end
		FarmLoop = nil
	end)
end

local function toggleAutoLootTP(state)
	AutoLootTPEnabled = state

	if not state then
		if FarmLoop then task.cancel(FarmLoop) FarmLoop = nil end
		pcall(function()
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.PlatformStand = false end
		end)
		return
	end

	RunService.Heartbeat:Connect(function()
		if not AutoLootTPEnabled then return end
		if #getValidLoot() > 0 and not FarmLoop then
			startFarming()
		end
	end)
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
-- AUTO RESCUE NPC SYSTEM 
--================================================================--
local AutoRescueNPCEnabled = false

local function TryFireNPC(obj)
	if not obj or not AutoRescueNPCEnabled then return end
	
	local model = obj:FindFirstAncestorWhichIsA("Model") or (obj:IsA("Model") and obj)
	if not model then return end
	
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	
	if model:HasTag("NPC") and model:GetAttribute("en") then
		TEvent.FireRemote("NPCDetected", model)
	end
end

local function toggleAutoRescueNPC(state)
	AutoRescueNPCEnabled = state
	
	if state then
		for _, obj in NPCModels:GetDescendants() do
			task.defer(TryFireNPC, obj)
		end
	end
end

local connection
connection = NPCModels.DescendantAdded:Connect(function(obj)
	if AutoRescueNPCEnabled then
		task.defer(TryFireNPC, obj)
	end
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


AutoLeft:AddToggle("AutoLootTP",{
	Text = "Auto Farm",
	Default = false,
	Callback = toggleAutoLootTP
})

AutoLeft:AddToggle("AutoOpenItems",{
	Text = "Auto Open (Crate + More)",
	Default = false,
	Callback = toggleAutoOpen
})

AutoLeft:AddToggle("AutoPickItem",{
	Text = "Auto Loot (Item)",
	Default = false,
	Callback = toggleAutoPick
})

AutoLeft:AddToggle("AutoPickGear",{
	Text = "Auto Loot (Gear)",
	Default = false,
	Callback = toggleAutoGear
})








AutoLeft:AddToggle("AutoRescueNPC", {
	Text = "Auto Rescue NPC",
	Default = false,
	Callback = toggleAutoRescueNPC
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

ESPRight:AddToggle("Crate_ESP", {
    Text = "Crate ESP",
    Default = false,
    Callback = function(v) toggleESP("Crate", v) end
})

ESPRight:AddToggle("Cabinet_ESP", {
    Text = "Cabinet ESP",
    Default = false,
    Callback = function(v) toggleESP("Cabinet", v) end
})

ESPRight:AddToggle("OilBucket_ESP", {
    Text = "Oil Bucket ESP",
    Default = false,
    Callback = function(v) toggleESP("OilBucket", v) end
})

ESPRight:AddToggle("Loot_ESP", {
    Text = "Loot ESP",
    Default = false,
    Callback = function(v) toggleESP("Loot", v) end
})

ESPRight:AddToggle("Monster_ESP", {
    Text = "Monster ESP",
    Default = false,
    Callback = function(v) toggleESP("Monster", v) end
})

ESPRight:AddToggle("Player_ESP", {
    Text = "Player ESP",
    Default = false,
    Callback = function(v) toggleESP("Player", v) end
})

ESPRight:AddToggle("NPC_ESP", {
    Text = "NPC ESP",
    Default = false,
    Callback = function(v) toggleESP("NPC", v) end
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
