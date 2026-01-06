-- Server/MovementService.lua
local MovementService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Classes = script.Parent.Parent.Shared.Classes
local MovementUtil = require(script.Parent.Parent.Shared.MovementUtil)

-- Remotes
local RemoteFolder = ReplicatedStorage:FindFirstChild("MovementRemotes") or Instance.new("Folder")
RemoteFolder.Name = "MovementRemotes"
RemoteFolder.Parent = ReplicatedStorage

local AbilityRemote = RemoteFolder:FindFirstChild("TriggerAbility") or Instance.new("RemoteEvent")
AbilityRemote.Name = "TriggerAbility"
AbilityRemote.Parent = RemoteFolder

local SetClassRemote = RemoteFolder:FindFirstChild("SetClass") or Instance.new("RemoteFunction")
SetClassRemote.Name = "SetClass"
SetClassRemote.Parent = RemoteFolder

-- State
local PlayerData = {}

function MovementService.Init()
	SetClassRemote.OnServerInvoke = MovementService.HandleSetClass
	AbilityRemote.OnServerEvent:Connect(MovementService.HandleAbility)
	
	Players.PlayerAdded:Connect(function(player)
		PlayerData[player] = {
			Class = nil,
			Cooldowns = {},
			Stamina = 100
		}
	end)
end

function MovementService.HandleSetClass(player, className)
    -- We assume class modules are named correctly in the Classes folder
	local classModuleScript = Classes:FindFirstChild(className)
	if not classModuleScript then return false end
	
	local classModule = require(classModuleScript)
	PlayerData[player].Class = classModule
	
	-- Apply base stat changes
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	
    -- These are now based on the new spec
	humanoid.WalkSpeed = classModule.BaseWalkSpeed or 16
    
    if classModule.Passives and classModule.Passives.JumpPowerMult then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50 * classModule.Passives.JumpPowerMult
    end
	
	return true
end

function MovementService.HandleAbility(player, abilityIdx) -- abilityIdx: "Active1" or "Active2"
	local data = PlayerData[player]
	if not data or not data.Class then return end
	
	local class = data.Class
	local abilityData = class.Abilities[abilityIdx]
	
	if not abilityData then return end
	
	-- Cooldown check
	local now = tick()
	if data.Cooldowns[abilityIdx] and now - data.Cooldowns[abilityIdx] < abilityData.CD then
		return
	end
	
	-- Perform ability logic
	if abilityData.ExecuteServer then
		abilityData.ExecuteServer(player, player.Character)
	end
	
	data.Cooldowns[abilityIdx] = now
end

return MovementService
