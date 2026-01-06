-- MovementService.lua | The main brain for all player abilities.
local MovementService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Find the shared folder in ReplicatedStorage
local MovementSystem = ReplicatedStorage:WaitForChild("MovementSystem")
local Classes = MovementSystem:WaitForChild("Classes")
local MovementUtil = require(MovementSystem:WaitForChild("MovementUtil"))

-- Events for the client to talk to us
local RemoteFolder = ReplicatedStorage:FindFirstChild("MovementRemotes") or Instance.new("Folder")
RemoteFolder.Name = "MovementRemotes"
RemoteFolder.Parent = ReplicatedStorage

local AbilityRemote = RemoteFolder:FindFirstChild("TriggerAbility") or Instance.new("RemoteEvent")
AbilityRemote.Name = "TriggerAbility"
AbilityRemote.Parent = RemoteFolder

local SetClassRemote = RemoteFolder:FindFirstChild("SetClass") or Instance.new("RemoteFunction")
SetClassRemote.Name = "SetClass"
SetClassRemote.Parent = RemoteFolder

-- Keep track of who's what and their CD status
local PlayerData = {}

function MovementService.Init()
	SetClassRemote.OnServerInvoke = MovementService.HandleSetClass
	AbilityRemote.OnServerEvent:Connect(MovementService.HandleAbility)
	
	-- Setup fresh data when someone joins
	Players.PlayerAdded:Connect(function(player)
		PlayerData[player] = {
			Class = nil,
			Cooldowns = {},
			Stamina = 100
		}
	end)
end

function MovementService.HandleSetClass(player, className)
	-- Grab the class module from the Shared folder
	local classModuleScript = Classes:FindFirstChild(className)
	if not classModuleScript then 
		warn("tried to set invalid class: " .. tostring(className))
		return false 
	end
	
	local classModule = require(classModuleScript)
	PlayerData[player].Class = classModule
	
	-- Update player stats (WalkSpeed, JumpPower, etc.)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Use class defaults or fall back to Roblox standard
	humanoid.WalkSpeed = classModule.BaseWalkSpeed or 16
    
    if classModule.Passives and classModule.Passives.JumpPowerMult then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50 * classModule.Passives.JumpPowerMult
    end
	
	print(player.Name .. " is now a " .. classModule.Name .. " [" .. classModule.Tier .. "]")
	return true
end

function MovementService.HandleAbility(player, abilityIdx) -- abilityIdx is "Active1" or "Active2"
	local data = PlayerData[player]
	if not data or not data.Class then return end
	
	local class = data.Class
	local abilityData = class.Abilities[abilityIdx]
	
	if not abilityData then return end
	
	-- Basic CD check so people don't spam
	local now = tick()
	if data.Cooldowns[abilityIdx] and now - data.Cooldowns[abilityIdx] < abilityData.CD then
		return
	end
	
	-- Fire off the server logic in the module
	if abilityData.ExecuteServer then
		abilityData.ExecuteServer(player, player.Character)
	end
	
	data.Cooldowns[abilityIdx] = now
end

return MovementService
