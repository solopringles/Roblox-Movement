-- DEBUG TESTER SCRIPT (Paste into Command Bar)
-- This sets up the 'Init' scripts and a Class Swapper UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- 1. Create Server Init Script
local serverInit = Instance.new("Script")
serverInit.Name = "MovementSystem_Init"
serverInit.Source = [[
local MovementService = require(game.ReplicatedStorage.MovementSystem.MovementService)
MovementService.Init()
print("✅ Movement Server Initialized")
]]
serverInit.Parent = ServerScriptService

-- 2. Create Client Init & UI Script
local clientInit = Instance.new("LocalScript")
clientInit.Name = "MovementSystem_TestUI"
clientInit.Source = [[
local MovementController = require(game.StarterPlayer.StarterPlayerScripts.MovementSystem.MovementController)
MovementController.Init()
print("✅ Movement Client Initialized")

-- Simple UI for Swapping
local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "MovementTestUI"

local Frame = Instance.new("ScrollingFrame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 400)
Frame.Position = UDim2.new(1, -220, 0.5, -200)
Frame.CanvasSize = UDim2.new(0, 0, 0, 1000)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local UIList = Instance.new("UIListLayout", Frame)
UIList.Padding = UDim.new(0, 5)

local classes = {
    "QuickStep", "Skywalker", "Accelerator", "Guardian", "Illusionist", "Berserker",
    "GearDasher", "ShunpoGhost", "FloatMaster", "BreathGlider", "TrapGenius", "HakiScout",
    "FlowStriker", "DomainWarden", "BankaiBlade", "DevilPuller", "SmashPro",
    "InfinityGod", "Gear5Joy", "TrueBankai", "UltimateGates"
}

for _, name in pairs(classes) do
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    
    btn.MouseButton1Click:Connect(function()
        MovementController.SetCurrentClass(name)
        print("Swapped to: " .. name)
    end)
end

print("💡 Press Q and E to use abilities once a class is selected!")
]]
clientInit.Parent = StarterPlayerScripts

print("🧪 Testing Framework Ready! Press Play to test.")
