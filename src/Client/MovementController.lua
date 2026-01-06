-- Client/MovementController.lua
local MovementController = {}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteFolder = ReplicatedStorage:WaitForChild("MovementRemotes")
local AbilityRemote = RemoteFolder:WaitForChild("TriggerAbility")
local SetClassRemote = RemoteFolder:WaitForChild("SetClass")

local LocalPlayer = Players.LocalPlayer

function MovementController.Init()
	UserInputService.InputBegan:Connect(MovementController.OnInput)
end

function MovementController.SetCurrentClass(className)
	local success = SetClassRemote:InvokeServer(className)
	if success then
		print("Class set to:", className)
	end
end

function MovementController.OnInput(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Q then
		AbilityRemote:FireServer("Active1")
	elseif input.KeyCode == Enum.KeyCode.E then
		AbilityRemote:FireServer("Active2")
	end
end

return MovementController
