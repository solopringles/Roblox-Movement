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
local MAX_TARGET_DISTANCE = 120
local TIER_COOLDOWN_FLOOR = {
	Common = 1.5,
	Rare = 1.75,
	Legendary = 2,
	Mythic = 2.5,
}

local function IsNaN(value)
	return value ~= value
end

local function EnsurePlayerData(player)
	PlayerData[player] = PlayerData[player] or {
		Class = nil,
		Cooldowns = {},
		Stamina = 100
	}

	return PlayerData[player]
end

local function SanitizeTargetPosition(character, targetPos)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	if typeof(targetPos) ~= "Vector3" then
		return hrp.Position + hrp.CFrame.LookVector * 40
	end

	if IsNaN(targetPos.X) or IsNaN(targetPos.Y) or IsNaN(targetPos.Z) then
		return hrp.Position + hrp.CFrame.LookVector * 40
	end

	local offset = targetPos - hrp.Position
	if offset.Magnitude < 1 then
		return hrp.Position + hrp.CFrame.LookVector * 8
	end

	if offset.Magnitude > MAX_TARGET_DISTANCE then
		return hrp.Position + offset.Unit * MAX_TARGET_DISTANCE
	end

	return targetPos
end

function MovementService.Init()
	SetClassRemote.OnServerInvoke = MovementService.HandleSetClass
	AbilityRemote.OnServerEvent:Connect(MovementService.HandleAbility)
	
	-- Setup fresh data when someone joins
	for _, player in ipairs(Players:GetPlayers()) do
		EnsurePlayerData(player)
	end

	Players.PlayerAdded:Connect(EnsurePlayerData)
	Players.PlayerRemoving:Connect(function(player)
		PlayerData[player] = nil
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
	local data = EnsurePlayerData(player)
	data.Class = classModule
	data.Cooldowns = {}
	
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

function MovementService.HandleAbility(player, abilityIdx, targetPos) -- abilityIdx is "Active1" or "Active2"
	local data = EnsurePlayerData(player)
	if not data or not data.Class then return end
	
	local class = data.Class
	local abilityData = class.Abilities[abilityIdx]
	
	if not abilityData then return end
	
	-- Basic CD check so people don't spam
	local now = tick()
	local cooldown = math.max(abilityData.CD or 0, TIER_COOLDOWN_FLOOR[class.Tier] or 1)
	if data.Cooldowns[abilityIdx] and now - data.Cooldowns[abilityIdx] < cooldown then
		return
	end
	
	-- Fire off the server logic in the module
	local character = player.Character
	if not character or not character.Parent then
		return
	end

	if abilityData.ExecuteServer then
		local sanitizedTargetPos = SanitizeTargetPosition(character, targetPos)
		if not sanitizedTargetPos then
			return
		end

		local ok, err = pcall(abilityData.ExecuteServer, player, character, sanitizedTargetPos)
		if not ok then
			warn(("Ability %s for class %s failed: %s"):format(tostring(abilityIdx), tostring(class.Name), tostring(err)))
			return
		end
	end
	
	data.Cooldowns[abilityIdx] = now
end

return MovementService
