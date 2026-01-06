-- DEBUG TESTER V3 (Paste into Command Bar)
-- This sets up the 'Init' scripts, Hotbar, AND a Dummy Spawner.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- 1. Create Server Init Script
local serverInit = Instance.new("Script")
serverInit.Name = "MovementSystem_Init"
serverInit.Source = [[
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementSystem = ServerScriptService:WaitForChild("MovementSystem")
local MovementService = require(MovementSystem:WaitForChild("MovementService"))

MovementService.Init()

-- Setup Dummy Spawner Remote
local spawnRemote = Instance.new("RemoteEvent")
spawnRemote.Name = "SpawnDummyRemote"
spawnRemote.Parent = ReplicatedStorage

spawnRemote.OnServerEvent:Connect(function(player)
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Create a simplified Dummy
    local dummy = Instance.new("Model")
    dummy.Name = "TrainingDummy"
    
    local dHrp = Instance.new("Part")
    dHrp.Name = "HumanoidRootPart"
    dHrp.Anchored = false
    dHrp.CanCollide = true
    dHrp.Size = Vector3.new(2, 2, 1)
    dHrp.Position = hrp.Position + hrp.CFrame.LookVector * 10 + Vector3.new(0, 3, 0)
    dHrp.Parent = dummy
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Position = dHrp.Position + Vector3.new(0, 2, 0)
    head.Parent = dummy
    
    local weld = Instance.new("Weld")
    weld.Part0 = dHrp
    weld.Part1 = head
    weld.C0 = CFrame.new(0, 1.5, 0)
    weld.Parent = head
    
    local hum = Instance.new("Humanoid")
    hum.Parent = dummy
    
    dummy.PrimaryPart = dHrp
    dummy.Parent = workspace
    
    print("🤖 Spawned a Dummy for " .. player.Name)
end)

print("✅ Movement Server Initialized + Dummy Spawner Ready")
]]
serverInit.Parent = ServerScriptService

-- 2. Create Client Init & UI Script
local clientInit = Instance.new("LocalScript")
clientInit.Name = "MovementSystem_TestUI"
clientInit.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local MovementSystem = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("MovementSystem")
local MovementController = require(MovementSystem:WaitForChild("MovementController"))

MovementController.Init()
print("✅ Movement Client Initialized")

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "MovementTestUI"

-- Side Menu (Class Selection)
local SideFrame = Instance.new("ScrollingFrame", ScreenGui)
SideFrame.Name = "SideMenu"
SideFrame.Size = UDim2.new(0, 180, 0, 300)
SideFrame.Position = UDim2.new(1, -200, 0.5, -150)
SideFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
SideFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SideFrame.BorderSizePixel = 0
SideFrame.ScrollBarThickness = 4

local UIList = Instance.new("UIListLayout", SideFrame)
UIList.Padding = UDim.new(0, 4)

-- Spawn Dummy Button
local SpawnBtn = Instance.new("TextButton", SideFrame)
SpawnBtn.Name = "SpawnDummy"
SpawnBtn.Size = UDim2.new(1, -10, 0, 40)
SpawnBtn.Text = "➕ SPAWN DUMMY"
SpawnBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
SpawnBtn.TextColor3 = Color3.new(1, 1, 1)
SpawnBtn.Font = Enum.Font.SourceSansBold
SpawnBtn.TextSize = 18

SpawnBtn.MouseButton1Click:Connect(function()
    local remote = ReplicatedStorage:WaitForChild("SpawnDummyRemote")
    remote:FireServer()
end)

-- Separator
local Sep = Instance.new("Frame", SideFrame)
Sep.Size = UDim2.new(1, 0, 0, 2)
Sep.BackgroundColor3 = Color3.new(1,1,1)
Sep.BackgroundTransparency = 0.5

-- Hotbar (Bottom)
local HotbarFrame = Instance.new("Frame", ScreenGui)
HotbarFrame.Name = "Hotbar"
HotbarFrame.Size = UDim2.new(0, 300, 0, 80)
HotbarFrame.Position = UDim2.new(0.5, -150, 1, -100)
HotbarFrame.BackgroundTransparency = 1

local QSlot = Instance.new("Frame", HotbarFrame)
QSlot.Name = "Q"
QSlot.Size = UDim2.new(0, 140, 1, 0)
QSlot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local ESlot = Instance.new("Frame", HotbarFrame)
ESlot.Name = "E"
ESlot.Size = UDim2.new(0, 140, 1, 0)
ESlot.Position = UDim2.new(1, -140, 0, 0)
ESlot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local QKey = Instance.new("TextLabel", QSlot)
QKey.Text = "[Q]"
QKey.Size = UDim2.new(0, 30, 0, 20)
QKey.BackgroundTransparency = 1
QKey.TextColor3 = Color3.new(1, 1, 1)

local QName = Instance.new("TextLabel", QSlot)
QName.Text = "Not Set"
QName.Size = UDim2.new(1, 0, 0.6, 0)
QName.Position = UDim2.new(0, 0, 0.4, 0)
QName.BackgroundTransparency = 1
QName.TextColor3 = Color3.new(0.8, 0.8, 0.8)
QName.TextScaled = true

local EKey = Instance.new("TextLabel", ESlot)
EKey.Text = "[E]"
EKey.Size = UDim2.new(0, 30, 0, 20)
EKey.BackgroundTransparency = 1
EKey.TextColor3 = Color3.new(1, 1, 1)

local EName = Instance.new("TextLabel", ESlot)
EName.Text = "Not Set"
EName.Size = UDim2.new(1, 0, 0.6, 0)
EName.Position = UDim2.new(0, 0, 0.4, 0)
EName.BackgroundTransparency = 1
EName.TextColor3 = Color3.new(0.8, 0.8, 0.8)
EName.TextScaled = true

-- Log Area (Bottom Left)
local LogFrame = Instance.new("ScrollingFrame", ScreenGui)
LogFrame.Name = "Logs"
LogFrame.Size = UDim2.new(0, 250, 0, 100)
LogFrame.Position = UDim2.new(0, 20, 1, -120)
LogFrame.BackgroundColor3 = Color3.new(0,0,0)
LogFrame.BackgroundTransparency = 0.5
LogFrame.BorderSizePixel = 0
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 2000)

local LogList = Instance.new("UIListLayout", LogFrame)
LogList.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function CreateLog(text, color)
    local l = Instance.new("TextLabel", LogFrame)
    l.Size = UDim2.new(1, 0, 0, 20)
    l.Text = text
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
end

CreateLog(">> System Ready", Color3.new(0, 1, 0))

local classes = {
    "QuickStep", "Skywalker", "Accelerator", "Guardian", "Illusionist", "Berserker",
    "GearDasher", "ShunpoGhost", "FloatMaster", "BreathGlider", "TrapGenius", "HakiScout",
    "FlowStriker", "DomainWarden", "BankaiBlade", "DevilPuller", "SmashPro",
    "InfinityGod", "Gear5Joy", "TrueBankai", "UltimateGates"
}

for _, name in pairs(classes) do
    local btn = Instance.new("TextButton", SideFrame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BorderSizePixel = 0
    
    btn.MouseButton1Click:Connect(function()
        CreateLog(">> Swapping to " .. name .. "...", Color3.new(1, 1, 0))
        
        local classModule = ReplicatedStorage:WaitForChild("MovementSystem"):WaitForChild("Classes"):FindFirstChild(name)
        if classModule then
            local success, data = pcall(require, classModule)
            if success then
                QName.Text = data.Abilities.Active1.Name
                EName.Text = data.Abilities.Active2.Name
                MovementController.SetCurrentClass(name)
                CreateLog("✅ Loaded " .. name, Color3.new(0, 1, 0))
            else
                CreateLog("❌ Require Error: " .. tostring(data), Color3.new(1, 0, 0))
            end
        else
            CreateLog("❌ Module MISSING: " .. name, Color3.new(1, 0, 0))
        end
    end)
end
]]
clientInit.Parent = StarterPlayerScripts

print("🧪 Tester V3 ready! Run in Studio. Click '+ SPAWN DUMMY' to create targets.")
