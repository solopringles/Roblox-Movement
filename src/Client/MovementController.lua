-- Client/MovementController.lua | Handles inputs and talks to the server.
local MovementController = {}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteFolder = ReplicatedStorage:WaitForChild("MovementRemotes")
local AbilityRemote = RemoteFolder:WaitForChild("TriggerAbility")
local SetClassRemote = RemoteFolder:WaitForChild("SetClass")

local LocalPlayer = Players.LocalPlayer

function MovementController.Init()
	-- Watch for key presses
	UserInputService.InputBegan:Connect(MovementController.OnInput)
end

function MovementController.SetCurrentClass(className)
	-- Switch up our archetype on the server
	local success = SetClassRemote:InvokeServer(className)
	if success then
		print("Successfully swapped to: " .. className)
	end
end

function MovementController.OnInput(input, gameProcessed)
	-- Ignore if typing in chat
	if gameProcessed then return end
	
	-- Q/E for abilities
	if input.KeyCode == Enum.KeyCode.Q then
		AbilityRemote:FireServer("Active1")
	elseif input.KeyCode == Enum.KeyCode.E then
		AbilityRemote:FireServer("Active2")
	end
end

return MovementController
