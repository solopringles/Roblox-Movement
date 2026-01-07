-- DEBUG TESTER V5 (Paste into Command Bar)
-- Robust R6 Dummies & Zone-based Pushers for 100% reliability.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- 0. Cleanup
local function Cleanup(name, parent)
	local existing = parent:FindFirstChild(name)
	while existing do
		existing:Destroy()
		existing = parent:FindFirstChild(name)
	end
end

Cleanup("MovementSystem_Init", ServerScriptService)
Cleanup("MovementSystem_TestUI", StarterPlayerScripts)
Cleanup("InfraRemote", ReplicatedStorage)

-- 1. Create Server Init Script
local serverInit = Instance.new("Script")
serverInit.Name = "MovementSystem_Init"
serverInit.Source = [[
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local MovementSystem = ServerScriptService:WaitForChild("MovementSystem")
local MovementService = require(MovementSystem:WaitForChild("MovementService"))

MovementService.Init()

-- Setup Infrastructure Remotes
local infraRemote = Instance.new("RemoteEvent")
infraRemote.Name = "InfraRemote"
infraRemote.Parent = ReplicatedStorage

local function CreateWeld(p0, p1, c0)
    local weld = Instance.new("Weld")
    weld.Part0 = p0
    weld.Part1 = p1
    weld.C0 = c0 or CFrame.new()
    weld.Parent = p0
    return weld
end

infraRemote.OnServerEvent:Connect(function(player, actionType)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local forward = hrp.CFrame.LookVector
    local spawnPos = hrp.Position + forward * 10

    if actionType == "Dummy" then
        local dummy = Instance.new("Model")
        dummy.Name = "TrainingDummy"
        
        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 2, 1)
        torso.CFrame = CFrame.new(spawnPos + Vector3.new(0, 3, 0))
        torso.Parent = dummy
        
        local dHrp = Instance.new("Part")
        dHrp.Name = "HumanoidRootPart"
        dHrp.Size = Vector3.new(2, 2, 1)
        dHrp.Transparency = 1
        dHrp.CanCollide = false
        dHrp.CFrame = torso.CFrame
        dHrp.Parent = dummy
        CreateWeld(torso, dHrp)

        local head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(1.2, 1.2, 1.2)
        head.Parent = dummy
        CreateWeld(torso, head, CFrame.new(0, 1.5, 0))

        -- Legs (Basic)
        local rl = Instance.new("Part")
        rl.Name = "Right Leg"
        rl.Size = Vector3.new(1, 2, 1)
        rl.Parent = dummy
        CreateWeld(torso, rl, CFrame.new(0.5, -2, 0))

        local ll = Instance.new("Part")
        ll.Name = "Left Leg"
        ll.Size = Vector3.new(1, 2, 1)
        ll.Parent = dummy
        CreateWeld(torso, ll, CFrame.new(-0.5, -2, 0))
        
        local hum = Instance.new("Humanoid")
        hum.Parent = dummy
        dummy.PrimaryPart = dHrp
        dummy.Parent = workspace
        
        print("🤖 Spawned R6 Dummy")
        
    elseif actionType == "Wall" then
        local wall = Instance.new("Part")
        wall.Name = "TestWall"
        wall.Size = Vector3.new(20, 15, 2)
        wall.CFrame = CFrame.new(spawnPos, spawnPos + forward)
        wall.Anchored = true
        wall.Material = Enum.Material.Concrete
        wall.Parent = workspace
        Debris:AddItem(wall, 60)
        print("🧱 Spawned Wall")
        
    elseif actionType == "Pusher" then
        local pusher = Instance.new("Part")
        pusher.Name = "Pusher"
        pusher.Size = Vector3.new(8, 8, 8)
        pusher.CFrame = CFrame.new(spawnPos + Vector3.new(0, 4, 0))
        pusher.Transparency = 0.5
        pusher.Color = Color3.fromRGB(255, 50, 50)
        pusher.Anchored = true
        pusher.CanCollide = false
        pusher.Parent = workspace
        
        -- High-frequency zone check for 100% reliability
        task.spawn(function()
            local duration = 15
            local start = tick()
            while tick() - start < duration do
                local parts = workspace:GetPartsInPart(pusher)
                for _, part in pairs(parts) do
                    local hitHrp = part.Parent:FindFirstChild("HumanoidRootPart")
                    if hitHrp then
                        local dir = (hitHrp.Position - pusher.Position).Unit + Vector3.new(0, 0.4, 0)
                        hitHrp.AssemblyLinearVelocity = dir.Unit * 130
                    end
                end
                task.wait(0.1)
            end
            pusher:Destroy()
        end)
        print("💥 Active Pusher Zone created (15s)")
    end
end)
]]
serverInit.Parent = ServerScriptService

-- 2. Create Client Init & UI Script
local clientInit = Instance.new("LocalScript")
clientInit.Name = "MovementSystem_TestUI"
clientInit.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local MovementSystem = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("MovementSystem")
local MovementController = require(MovementSystem:WaitForChild("MovementController"))

MovementController.Init()

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "MovementTestUI"

local SideFrame = Instance.new("ScrollingFrame", ScreenGui)
SideFrame.Name = "SideMenu"
SideFrame.Size = UDim2.new(0, 260, 0, 450) -- Wider menu
SideFrame.Position = UDim2.new(1, -280, 0.5, -225)
SideFrame.CanvasSize = UDim2.new(0, 0, 0, 1300)
SideFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SideFrame.BorderSizePixel = 0
SideFrame.ScrollBarThickness = 12 -- Thicker scrollbar

local UIList = Instance.new("UIListLayout", SideFrame)
UIList.Padding = UDim.new(0, 5)

local function CreateHeader(text)
    local l = Instance.new("TextLabel", SideFrame)
    l.Size = UDim2.new(1, 0, 0, 30)
    l.Text = text
    l.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 20 -- Larger header text
end

CreateHeader("TEST TOOLS")
local function CreateInfraBtn(text, color, action)
    local btn = Instance.new("TextButton", SideFrame)
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.MouseButton1Click:Connect(function()
        ReplicatedStorage:WaitForChild("InfraRemote"):FireServer(action)
    end)
end

CreateInfraBtn("SPAWN DUMMY (R6)", Color3.fromRGB(0, 120, 0), "Dummy")
CreateInfraBtn("SPAWN WALL", Color3.fromRGB(100, 100, 100), "Wall")
CreateInfraBtn("SPAWN PUSHER (ZONE)", Color3.fromRGB(180, 0, 0), "Pusher")

local Sep = Instance.new("Frame", SideFrame)
Sep.Size = UDim2.new(1, 0, 0, 2)
Sep.BackgroundColor3 = Color3.new(1,1,1)
Sep.BackgroundTransparency = 0.5

CreateHeader("MOVEMENT CLASSES")
local classes = {
    "QuickStep", "Skywalker", "Accelerator", "Guardian", "Illusionist", "Berserker",
    "GearDasher", "ShunpoGhost", "FloatMaster", "BreathGlider", "TrapGenius", "HakiScout",
    "FlowStriker", "DomainWarden", "BankaiBlade", "DevilPuller", "SmashPro",
    "InfinityGod", "Gear5Joy", "TrueBankai", "UltimateGates"
}

local QName, EName

for _, name in pairs(classes) do
    local btn = Instance.new("TextButton", SideFrame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextSize = 14
    btn.TextScaled = true
    btn.MouseButton1Click:Connect(function()
        local classModule = ReplicatedStorage:WaitForChild("MovementSystem"):WaitForChild("Classes"):FindFirstChild(name)
        if classModule then
            local success, data = pcall(require, classModule)
            if success then
                if QName then QName.Text = data.Abilities.Active1.Name end
                if EName then EName.Text = data.Abilities.Active2.Name end
                MovementController.SetCurrentClass(name)
            end
        end
    end)
end

-- Hotbar (Bottom)
local HotbarFrame = Instance.new("Frame", ScreenGui)
HotbarFrame.Size = UDim2.new(0, 400, 0, 110) -- Larger hotbar
HotbarFrame.Position = UDim2.new(0.5, -200, 1, -130)
HotbarFrame.BackgroundTransparency = 1

local function CreateSlot(keyText, pos)
    local slot = Instance.new("Frame", HotbarFrame)
    slot.Size = UDim2.new(0, 180, 1, 0) -- Larger slots
    slot.Position = pos
    slot.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    slot.BorderSizePixel = 2
    slot.BorderColor3 = Color3.fromRGB(60, 60, 60)
    
    local key = Instance.new("TextLabel", slot)
    key.Text = "[" .. keyText .. "]"
    key.Size = UDim2.new(1, 0, 0, 30)
    key.BackgroundTransparency = 1
    key.TextColor3 = Color3.new(1, 1, 1)
    key.Font = Enum.Font.SourceSansBold
    key.TextSize = 22 -- Larger key hint
    
    local name = Instance.new("TextLabel", slot)
    name.Text = "None"
    name.Size = UDim2.new(1, -10, 0.5, 0)
    name.Position = UDim2.new(0, 5, 0.4, 0)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.new(0, 1, 1)
    name.TextScaled = true
    name.Font = Enum.Font.SourceSansBold -- Bolder ability names
    return name
end

QName = CreateSlot("Q", UDim2.new(0, 0, 0, 0))
EName = CreateSlot("E", UDim2.new(1, -180, 0, 0))
]]
clientInit.Parent = StarterPlayerScripts

print("🧪 Tester V5 ready! Improved Dummies & Reliable Pusher Zone. Run in Studio now.")
