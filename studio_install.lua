-- ROBLOX STUDIO COMMAND BAR SETUP SCRIPT
-- Paste this into your Command Bar (View > Command Bar) and press Enter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- 1. Utility: Cleanup existing folders to prevent dupes
local function Cleanup(name, parent)
	local existing = parent:FindFirstChild(name)
	while existing do
		existing:Destroy()
		existing = parent:FindFirstChild(name)
	end
end

Cleanup("MovementSystem", ReplicatedStorage)
Cleanup("MovementSystem", ServerScriptService)
Cleanup("MovementSystem", StarterPlayerScripts)
Cleanup("MovementRemotes", ReplicatedStorage)

-- 2. Create Structure
local MovementSystem = Instance.new("Folder")
MovementSystem.Name = "MovementSystem"
MovementSystem.Parent = ReplicatedStorage

local ClassesFolder = Instance.new("Folder")
ClassesFolder.Name = "Classes"
ClassesFolder.Parent = MovementSystem

local ServerSystem = Instance.new("Folder")
ServerSystem.Name = "MovementSystem"
ServerSystem.Parent = ServerScriptService

local ClientSystem = Instance.new("Folder")
ClientSystem.Name = "MovementSystem"
ClientSystem.Parent = StarterPlayerScripts

-- 2. Utility Function to Add Scripts
local function AddScript(name, parent, content, className)
	local s = Instance.new(className or "ModuleScript")
	s.Name = name
	s.Source = content
	s.Parent = parent
	return s
end

-- 3. Core Files
AddScript("MovementUtil", MovementSystem, [[-- Shared physics and movement helpers.
local MovementUtil = {}

-- Tag for when someone is dodging/invincible
MovementUtil.IFRAME_TAG = "IFrameActive"

-- Snap a part to a specific speed for a duration
-- Snap a part to a specific speed for a duration
function MovementUtil.ApplyVelocity(humanoidRootPart, velocity, duration)
	-- Clear existing velocity to prevent drifting
	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero 
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = humanoidRootPart
	
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = velocity
	linearVelocity.Attachment0 = attachment
	linearVelocity.Parent = humanoidRootPart
	
	-- ANTI-SPIN: Lock rotation during the dash/velocity movement
	-- This prevents "spinning wildly" if you hit a corner or player
	local angularVel = Instance.new("AngularVelocity")
	angularVel.AngularVelocity = Vector3.zero
	angularVel.MaxTorque = math.huge
	angularVel.Attachment0 = attachment
	angularVel.Parent = humanoidRootPart
	
	-- Clean up when done
	task.delay(duration, function()
		attachment:Destroy()
		linearVelocity:Destroy()
		angularVel:Destroy()
	end)
end

-- Forceful shove using Roblox's impulse system
function MovementUtil.ApplyImpulse(humanoidRootPart, impulse)
	humanoidRootPart:ApplyImpulse(impulse * humanoidRootPart.AssemblyMass)
end

-- Controlled Knockback with Ragdoll prevention
function MovementUtil.ApplyKnockback(targetCharacter, direction, force)
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	local hum = targetCharacter:FindFirstChild("Humanoid")
	
	if hrp and hum then
		-- 1. Stop them spinning wildly
		hrp.AssemblyAngularVelocity = Vector3.zero
		
		-- 2. Ragdoll momentarily (Standardized for all avatars)
		hum.PlatformStand = true
		hum:ChangeState(Enum.HumanoidStateType.Physics) -- Force physics engine takeover
		
		task.delay(0.6, function()
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
		
		-- 3. Apply controlled velocity
		hrp.AssemblyLinearVelocity = Vector3.zero 
		hrp:ApplyImpulse(direction * hrp.AssemblyMass * 2.5) -- Increased slightly
		hrp.AssemblyLinearVelocity = direction * force
		
		print("💨 Applied standardized ragdoll knockback to: " .. targetCharacter.Name)
	end
end

-- Tank Helper: Buffs health and adds resistance
function MovementUtil.ApplyTankBuff(character, duration, healthBoost, reduction)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	-- 1. Health Bump & Regen
	local originalMax = hum.MaxHealth
	hum.MaxHealth = originalMax + healthBoost
	hum.Health = math.min(hum.MaxHealth, hum.Health + healthBoost)
	
	-- 2. Damage Reduction Tag (Can be used by a separate damage system, or just visual for now)
	local tag = Instance.new("NumberValue")
	tag.Name = "DamageReduction"
	tag.Value = reduction
	tag.Parent = character
	
	-- 3. Temporary Regen loop
	local regenConnection
	regenConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if hum.Parent and hum.Health < hum.MaxHealth then
			hum.Health += 0.2 -- Passive regen during buff
		end
	end)
	
	task.delay(duration, function()
		if hum.Parent then
			hum.MaxHealth = originalMax
			hum.Health = math.min(hum.MaxHealth, hum.Health)
		end
		tag:Destroy()
		regenConnection:Disconnect()
	end)
end

-- Visual Feedback Helper: Spawns a temporary warning or indicator
function MovementUtil.ShowVisualFeedback(position, radius, color, duration, shape)
	local feedback = Instance.new("Part")
	feedback.Shape = shape or Enum.PartType.Ball
	feedback.Size = Vector3.new(0.5, 0.5, 0.5)
	feedback.Position = position
	feedback.Anchored = true
	feedback.CanCollide = false
	feedback.CanQuery = false
	feedback.Transparency = 0.4
	feedback.Color = color or Color3.new(1, 1, 1)
	feedback.Parent = workspace
	
	local targetSize = Vector3.new(radius * 2, radius * 2, radius * 2)
	-- Cylinders usually oriented for "Circles" on the ground (Note: cylinders grow on X axis in size)
	if feedback.Shape == Enum.PartType.Cylinder then
		feedback.Size = Vector3.new(0.2, 0.5, 0.5)
		targetSize = Vector3.new(0.2, radius * 2, radius * 2)
		feedback.Orientation = Vector3.new(0, 0, 90) -- Face upward
	end
	
	local tween = game:GetService("TweenService"):Create(feedback, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = targetSize,
		Transparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function() feedback:Destroy() end)
end

-- SFX helper (Safe)
function MovementUtil.PlaySound(soundId, parent)
	if not soundId or soundId == 0 then return end
	local success, err = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. tostring(soundId)
		sound.Parent = parent
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- Check if we can kick off a wall
function MovementUtil.IsNearWall(humanoidRootPart, distance)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {humanoidRootPart.Parent}

    local directions = {
        humanoidRootPart.CFrame.LookVector,
        -humanoidRootPart.CFrame.LookVector,
        humanoidRootPart.CFrame.RightVector,
        -humanoidRootPart.CFrame.RightVector
    }

    for _, dir in pairs(directions) do
        local result = workspace:Raycast(humanoidRootPart.Position, dir * distance, rayParams)
        if result then return result end
    end
    return nil
end

-- Find someone in front of us for pulls/kicks
function MovementUtil.GetNearestInRay(origin, direction, range, excludeList)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = excludeList or {}

	local result = workspace:Raycast(origin, direction * range, rayParams)
	if result and result.Instance then
		-- Search up the tree for a character model
		local char = result.Instance:FindFirstAncestorOfClass("Model")
		if char and char:FindFirstChildOfClass("Humanoid") then
			print("🎯 Target found: " .. char.Name)
			return char
		end
	end
	return nil
end

-- Big boom for knockback only (no damage)
-- Manual explosion logic to allow immunity
function MovementUtil.CreateExplosionPush(position, radius, pressure, ignoreList)
	-- Visual Only
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = 0 -- No physics from Roblox
	explosion.BlastPressure = 0
	explosion.Position = position
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	
	-- Manual Spatial Query
	-- Find parts in radius
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = ignoreList or {}
	
	local seenModels = {}
	
	local parts = workspace:GetPartBoundsInRadius(position, radius, overlapParams)
	for _, part in pairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChild("Humanoid") and not seenModels[model] then
			seenModels[model] = true
			
			local hrp = model:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dir = (hrp.Position - position).Unit
				-- Calculate falloff? No, max power asked by user!
				-- Convert pressure to velocity estimate roughly
				-- Pressure 500k is roughly Velocity 100ish in previous scaling
				local force = math.clamp(pressure / 5000, 50, 200) 
				if pressure < 0 then force = -force end -- Pull handling
				
				MovementUtil.ApplyKnockback(model, dir, force)
			end
		end
	end
end

return MovementUtil
]])

AddScript("MovementService", ServerSystem, [[-- MovementService.lua | The main brain for all player abilities.
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

function MovementService.ApplyClassStats(player, character, classModule)
	if not character or not classModule then return end
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	
	humanoid.WalkSpeed = classModule.BaseWalkSpeed or 16
	
	if classModule.Passives and classModule.Passives.JumpPowerMult then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = 50 * classModule.Passives.JumpPowerMult
	end
	
	print("📊 Applied " .. classModule.Name .. " stats to " .. player.Name)
end

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
		
		player.CharacterAdded:Connect(function(character)
			local data = PlayerData[player]
			if data and data.Class then
				MovementService.ApplyClassStats(player, character, data.Class)
			end
		end)
	end)
end

function MovementService.HandleSetClass(player, className)
	print("🛠 [" .. player.Name .. "] attempting to set class: " .. tostring(className))
	
	-- Grab the class module script
	local classModuleScript = Classes:FindFirstChild(className)
	if not classModuleScript then 
		warn("❌ [" .. player.Name .. "] Class module script NOT FOUND: " .. tostring(className))
		return false 
	end
	
	-- Safely require the module
	local success, classModule = pcall(require, classModuleScript)
	if not success then
		warn("❌ [" .. player.Name .. "] FAILED to require class " .. className .. ": " .. tostring(classModule))
		return false
	end

	PlayerData[player].Class = classModule
	
	-- Update player stats immediately
	local character = player.Character
	if character then
		MovementService.ApplyClassStats(player, character, classModule)
	end
	
	print("✨ [" .. player.Name .. "] is now: " .. classModule.Name .. " (" .. classModule.Tier .. ")")
	return true
end

function MovementService.HandleAbility(player, abilityIdx, targetPos) -- abilityIdx is "Active1" or "Active2"
	local data = PlayerData[player]
	if not data or not data.Class then 
		warn("⚠️ [" .. player.Name .. "] triggered ability without a class set!")
		return 
	end
	
	local class = data.Class
	local abilityData = class.Abilities[abilityIdx]
	
	if not abilityData then 
		warn("⚠️ [" .. player.Name .. "] triggered invalid ability index: " .. tostring(abilityIdx))
		return 
	end
	
	-- Basic CD check so people don't spam
	local now = tick()
	if data.Cooldowns[abilityIdx] and now - data.Cooldowns[abilityIdx] < (abilityData.CD or 0) then
		return
	end
	
	-- Fire off the server logic in the module
	if abilityData.ExecuteServer then
		local success, err = pcall(abilityData.ExecuteServer, player, player.Character, targetPos)
		if not success then
			warn("🔥 [" .. player.Name .. "] ERROR executing " .. (abilityData.Name or abilityIdx) .. ": " .. tostring(err))
		else
			print("⚡ [" .. player.Name .. "] used: " .. (abilityData.Name or abilityIdx))
		end
	end
	
	data.Cooldowns[abilityIdx] = now
end

return MovementService
]], nil)

AddScript("MovementController", ClientSystem, [[-- Client/MovementController.lua | Handles inputs and talks to the server.
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
	
	-- Grab cursor position for targeted abilities
	local mouse = LocalPlayer:GetMouse()
	local targetPos = mouse.Hit.p
	
	-- Q/E for abilities
	if input.KeyCode == Enum.KeyCode.Q then
		AbilityRemote:FireServer("Active1", targetPos)
	elseif input.KeyCode == Enum.KeyCode.E then
		AbilityRemote:FireServer("Active2", targetPos)
	end
end

return MovementController
]], nil)

-- 4. Classes (21)
local classes = {
	["QuickStep"] = [[-- [Common] Quick Step | Dash like a ninja. Simple, but it gets the job done.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local QuickStep = {
	Name = "Quick Step",
	Tier = "Common",
	BaseWalkSpeed = 16 * 1.1, -- Extra zip in your step
	Passives = {
		KnockbackReceivedMult = 1.2 -- You get tossed around easier
	},
	Abilities = {
		Active1 = {
			Name = "Dash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Wind burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(1, 1, 1), 0.3)
				
				-- Use the reliable ApplyVelocity helper instead of raw velocity
				local dashDir = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, dashDir * 150, 0.25) -- Buffed from 80
			end
		},
		Active2 = {
			Name = "Slash Wave",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Slash line
				MovementUtil.ShowVisualFeedback(hrp.Position + hrp.CFrame.LookVector * 10, 15, Color3.new(1, 0.8, 0.8), 0.4, Enum.PartType.Cylinder)
				
				-- Increased range and impact
				local forward = hrp.CFrame.LookVector
				local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 60, {character}) -- Buffed from 20
				
				if target then
					MovementUtil.ApplyKnockback(target, forward, 150) -- Buffed from 75
				end
			end
		}
	}
}

return QuickStep
]],
	["Skywalker"] = [[-- [Common] Skywalker | One Piece Geppo vibes. Don't touch the floor.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Skywalker = {
	Name = "Skywalker",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		JumpPowerMult = 1.15, -- Jump higher than the peasants
		FallSpeedMult = 0.85 -- Float like a feather
	},
	Abilities = {
		Active1 = {
			Name = "Air Jump",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Halt vertical velocity immediately (Fixes flying away bug)
				hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
				
				-- Visual Feedback: Upward gust
				MovementUtil.ShowVisualFeedback(hrp.Position - Vector3.new(0, 3, 0), 10, Color3.new(0.8, 0.9, 1), 0.4, Enum.PartType.Cylinder)
				
				-- Kick the air to go up
				MovementUtil.ApplyVelocity(hrp, Vector3.new(0, 120, 0), 0.2)
			end
		},
		Active2 = {
			Name = "Hover",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Halt ALL velocity immediately
				hrp.AssemblyLinearVelocity = Vector3.zero
				
				-- Visual Feedback: Concentration field
				MovementUtil.ShowVisualFeedback(hrp.Position, 15, Color3.new(0.5, 0.7, 1), 2.5)
				
				-- Hold your position mid-air
				local vf = Instance.new("VectorForce")
				vf.Force = Vector3.new(0, 4000, 0)
				vf.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				vf.RelativeTo = Enum.ActuatorRelativeTo.World
				vf.Parent = hrp
				
				task.delay(2.5, function()
					vf:Destroy()
				end)
			end
		}
	}
}

return Skywalker
]],
	["Accelerator"] = [[-- [Common] Accelerator | Naruto body flicker. Fast as hell but you'll overheat.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Accelerator = {
	Name = "Accelerator",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Abilities = {
		Active1 = {
			Name = "Speed Burst",
			CD = 1,
			ExecuteServer = function(player, character)
				local humanoid = character:FindFirstChild("Humanoid")
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not humanoid or not hrp then return end
				
				-- Visual Feedback: Red gear sparks
				MovementUtil.ShowVisualFeedback(hrp.Position, 12, Color3.new(1, 0.2, 0.2), 0.5)
				
				-- Go fast for a bit
				humanoid.WalkSpeed = 16 * 2.5 -- Buffed from 1.6
				task.delay(3, function()
					-- Now you're tired
					humanoid.WalkSpeed = 16 * 0.6
					task.delay(2, function()
						humanoid.WalkSpeed = 16
					end)
				end)
			end
		},
		Active2 = {
			Name = "Wall Kick",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Kick off a wall to go flying
				local wall = MovementUtil.IsNearWall(hrp, 8) -- Buffed from 5
				if wall then
					-- Visual Feedback: Impact burst
					MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(1, 1, 0), 0.4)
					
					local jumpDir = (wall.Normal * 1.5 + Vector3.new(0, 1.2, 0)).Unit
					MovementUtil.ApplyVelocity(hrp, jumpDir * 130, 0.4) -- Buffed from 65
				end
			end
		}
	}
}

return Accelerator
]],
	["Guardian"] = [[-- [Common] Guardian | Absolute unit. Unpushable and annoying.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Guardian = {
	Name = "Guardian",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		MassResist = 1.3 -- You're a heavy boy
	},
	Abilities = {
		Active1 = {
			Name = "Iron Body",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Golden shield aura
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(1, 0.8, 0), 4)
				
				-- Lock yourself in place (FIXED: Uses Velocity Clamp instead of Spring force)
				local doc = Instance.new("LinearVelocity")
				doc.VectorVelocity = Vector3.new(0, 0, 0) -- Don't move.
				doc.MaxForce = math.huge -- I said, DON'T MOVE.
				doc.RelativeTo = Enum.ActuatorRelativeTo.World
				doc.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				doc.Parent = hrp
				
				-- Stop spinning too
				local av = Instance.new("AngularVelocity")
				av.AngularVelocity = Vector3.new(0, 0, 0)
				av.MaxTorque = math.huge
				av.Attachment0 = doc.Attachment0
				av.Parent = hrp
				
				-- Apply TANK BUFF: 50 Health, 30% reduction, for 4s
				MovementUtil.ApplyTankBuff(character, 4, 50, 0.3)
				
				task.delay(4, function()
					doc:Destroy()
					av:Destroy()
				end)
			end
		},
		Active2 = {
			Name = "Magnetize",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Magnetic pull line
				MovementUtil.ShowVisualFeedback(targetPos, 5, Color3.new(0, 1, 1), 0.5)
				
				-- Use cursor position if possible, otherwise look vector
				local dir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, dir, 80, {character}) -- Buffed from 30
				
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						-- Pull TOWARDS the player
						local pullDir = (hrp.Position - tHrp.Position).Unit
						MovementUtil.ApplyKnockback(target, pullDir, 120) -- Buffed from 50
					end
				end
			end
		}
	}
}

return Guardian
]],
	["Illusionist"] = [[-- [Common] Illusionist | Prank 'em. Use decoys and swap positions.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Illusionist = {
	Name = "Illusionist",
	Tier = "Common",
	BaseWalkSpeed = 16 * 1.08, -- A bit ghosty
	Abilities = {
		Active1 = {
			Name = "Decoy Dash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Send out a fake version of yourself (LARGER)
				local decoy = Instance.new("Part")
				decoy.Size = character:GetExtentsSize() * 1.5 -- 50% larger
				decoy.CFrame = hrp.CFrame
				decoy.Transparency = 0.5
				decoy.CanCollide = false
				decoy.Anchored = false
				decoy.Parent = workspace
				
				local vel = Instance.new("LinearVelocity")
				vel.MaxForce = math.huge
				vel.VectorVelocity = hrp.CFrame.LookVector * 100 -- Faster
				vel.Attachment0 = Instance.new("Attachment", decoy)
				vel.Parent = decoy
				
				-- EXPLODING DECOY: Blows up on contact with CHARACTERS only
				decoy.Touched:Connect(function(hit)
					if hit:IsDescendantOf(character) then return end
					local targetChar = hit:FindFirstAncestorOfClass("Model")
					if targetChar and targetChar:FindFirstChild("Humanoid") then
						MovementUtil.CreateExplosionPush(decoy.Position, 15, 600000, {character})
						decoy:Destroy()
					end
				end)
				
				-- Visual Feedback: Small burst on dash
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.5, 0, 0.5), 0.4)
				
				task.delay(1.5, function()
					humanoid.WalkSpeed = 16 * 1.08
					if decoy.Parent then decoy:Destroy() end
				end)
			end
		},
		Active2 = {
			Name = "Swap",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- RESTRICTION: Can only swap if relatively still (Not falling off map cheaply)
				if hrp.AssemblyLinearVelocity.Magnitude > 10 then
					warn("🚫 Cannot swap while moving too fast!")
					return
				end
				
				-- Visual Feedback: Swap energy
				MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(0.5, 0, 0.5), 0.4)
				MovementUtil.ShowVisualFeedback(targetPos, 8, Color3.new(0.5, 0, 0.5), 0.4)
				
				-- Aim with your cursor! Range 100
				local aimDir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 100, {character})
				
				if target then
					local targetHrp = target:FindFirstChild("HumanoidRootPart")
					if targetHrp then
						local myCF = hrp.CFrame
						local targetCF = targetHrp.CFrame
						
						hrp.CFrame = targetCF
						targetHrp.CFrame = myCF
						print("🌀 Swapped with " .. target.Name)
					end
				end
			end
		}
	}
}

return Illusionist
]],
	["Berserker"] = [[-- [Common] Berserker | Pure aggression. The more you move, the faster you get.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Berserker = {
	Name = "Berserker",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		RampingSpeed = true -- You get faster as you hold W (handled in main loop)
	},
	Abilities = {
		Active1 = {
			Name = "Roar",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Red shockwave
				MovementUtil.ShowVisualFeedback(hrp.Position, 25, Color3.new(1, 0, 0), 0.5)
				
				-- Scream and push everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 25, 900000, {character}) -- Added immunity
			end
		},
		Active2 = {
			Name = "Frenzy Dash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Charging aura
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(1, 0.5, 0), 0.4)
				
				-- Dash forward and fling whoever you hit
				local forward = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, forward * 80, 0.4) -- Buffed from 40
				
				task.delay(0.1, function()
					local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 10, {character}) -- Buffed from 5
					if target then
						MovementUtil.ApplyKnockback(target, forward, 140) -- Buffed from 70
					end
				end)
			end
		}
	}
}

return Berserker
]],
	["GearDasher"] = [[-- [Rare] Gear Dasher | Gear 2nd vibes. Rapid punches and jet-assisted movement.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local GearDasher = {
	Name = "Gear Dasher",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Jet Punch",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Jet burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(1, 0.5, 0), 0.3)
				
				-- Punch someone from across the room
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 60, {character}) -- Buffed from 20
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 100) -- Buffed from 50
				end
			end
		},
		Active2 = {
			Name = "Jet Pull",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Blue jet pull path
				MovementUtil.ShowVisualFeedback(targetPos, 5, Color3.new(0.4, 0.6, 1), 0.5)
				
				-- Aim with cursor!
				local aimDir = (targetPos - hrp.Position).Unit
				local result = workspace:Raycast(hrp.Position, aimDir * 80) -- Buffed from 25
				
				if result then
					MovementUtil.ApplyVelocity(hrp, aimDir * 140, 0.3) -- Buffed from 70
				else
					-- Recoil if you whiff it
					MovementUtil.ApplyVelocity(hrp, -aimDir * 70, 0.2) -- Buffed from 40
				end
			end
		}
	}
}

return GearDasher
]],
	["ShunpoGhost"] = [[-- [Rare] Shunpo Ghost | Bleach vibes. Now you see me, now you're dead. 
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local ShunpoGhost = {
	Name = "Shunpo Ghost",
	Tier = "Rare",
		Active1 = {
			Name = "Blink",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Blink start
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.2, 0.2, 0.2), 0.3)
				
				-- Blink toward cursor (Max 40 studs)
				local aimDir = (targetPos - hrp.Position).Unit
				if (targetPos - hrp.Position).Magnitude > 40 then 
					targetPos = hrp.Position + aimDir * 40
				end
				
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				
				local result = workspace:Raycast(hrp.Position, (targetPos - hrp.Position), rayParams)
				local finalPos = result and result.Position or targetPos
				
				hrp.CFrame = CFrame.new(finalPos) * hrp.CFrame.Rotation
				
				-- Visual Feedback: Blink end
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.2, 0.2, 0.2), 0.3)
			end
		},
		Active2 = {
			Name = "Phase",
			CD = 1,
			ExecuteServer = function(player, character)
				-- FULL INVISIBILITY
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanTouch = false 
					elseif part:IsA("Decal") then
						part.Transparency = 1
					end
				end
				
				task.delay(4, function()
					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
							part.CanTouch = true
						elseif part:IsA("Decal") then
							part.Transparency = 0
						end
					end
				end)
			end
		}
	}
}

return ShunpoGhost
]],
	["FloatMaster"] = [[-- [Rare] Float Master | Gojo/Ochaco vibes. Control the gravity in the room.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local FloatMaster = {
	Name = "Float Master",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Attract",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Gravity well
				MovementUtil.ShowVisualFeedback(targetPos, 40, Color3.new(0.5, 0, 1), 0.5)
				
				-- Pull items/players in a radius (FIXED: Standardized logic)
				local parts = workspace:GetPartBoundsInRadius(targetPos, 40)
				local seen = {}
				for _, part in pairs(parts) do
					local m = part:FindFirstAncestorOfClass("Model")
					if m and m:FindFirstChild("Humanoid") and m ~= character and not seen[m] then
						seen[m] = true
						local tHrp = m:FindFirstChild("HumanoidRootPart")
						if tHrp then
							local pullDir = (hrp.Position - tHrp.Position).Unit
							MovementUtil.ApplyKnockback(m, pullDir, 120)
						end
					elseif part.Size.Magnitude < 20 and not part.Anchored then
						part.AssemblyLinearVelocity = (hrp.Position - part.Position).Unit * 60
					end
				end
			end
		},
		Active2 = {
			Name = "Push Bubble",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Pop bubble
				MovementUtil.ShowVisualFeedback(hrp.Position, 25, Color3.new(0.8, 0.4, 1), 0.5)
				
				-- Pop a bubble that pushes everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 25, 800000, {character})
			end
		}
	}
}

return FloatMaster
]],
	["BreathGlider"] = [[-- [Rare] Breath Glider | Water Breathing style. Smooth movement and flow.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BreathGlider = {
	Name = "Breath Glider",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Riptide Surge",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Water burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 12, Color3.new(0.2, 0.6, 1), 0.4)
				
				-- Forceful surge forward, clearing all previous momentum
				local dashDir = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, dashDir * 180, 0.4)
				
				-- Fling anyone you pass through
				task.spawn(function()
					local start = tick()
					while tick() - start < 0.4 do
						local parts = workspace:GetPartBoundsInRadius(hrp.Position, 10)
						for _, part in pairs(parts) do
							local m = part:FindFirstAncestorOfClass("Model")
							if m and m:FindFirstChild("Humanoid") and m ~= character then
								MovementUtil.ApplyKnockback(m, dashDir + Vector3.new(0,0.5,0), 120)
							end
						end
						task.wait(0.05)
					end
				end)
			end
		},
		Active2 = {
			Name = "Abyssal Anchor",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Depth bubble
				MovementUtil.ShowVisualFeedback(hrp.Position, 30, Color3.new(0, 0, 0.5), 0.6)
				
				-- Weighted pull down
				MovementUtil.CreateExplosionPush(hrp.Position, 30, -900000, {character})
				
				local parts = workspace:GetPartBoundsInRadius(hrp.Position, 35)
				local seen = {}
				for _, part in pairs(parts) do
					local m = part:FindFirstAncestorOfClass("Model")
					if m and m:FindFirstChild("Humanoid") and m ~= character and not seen[m] then
						seen[m] = true
						local hum = m.Humanoid
						hum.PlatformStand = true
						task.delay(2, function() hum.PlatformStand = false end)
					end
				end
			end
		}
	}
}

return BreathGlider
]],
	["TrapGenius"] = [[-- [Rare] Trap Genius | Blue Lock Nagi vibes. Control your momentum like a pro.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local TrapGenius = {
	Name = "Trap Genius",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Momentum Kill",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Freeze burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.5, 0.8, 1), 0.3)
				
				-- Stop dead in your tracks
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		},
		Active2 = {
			Name = "Leap Burst",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Launch burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 12, Color3.new(0.8, 1, 0.8), 0.4)
				
				-- Big jump toward cursor
				local aimDir = (targetPos - hrp.Position).Unit
				MovementUtil.ApplyVelocity(hrp, aimDir * 140, 0.4) -- Buffed from 75
			end
		}
	}
}

return TrapGenius
]],
	["HakiScout"] = [[-- [Rare] Haki Scout | One Piece vibes. See it coming before it happens.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local HakiScout = {
	Name = "Haki Scout",
	Tier = "Rare",
	BaseWalkSpeed = 16 * 0.9, -- You move slower because you're focused
	Abilities = {
		Active1 = {
			Name = "Observe Dodge",
			CD = 1,
			ExecuteServer = function(player, character)
				-- Visual Feedback: Focus aura
				MovementUtil.ShowVisualFeedback(character:GetPrimaryPartCFrame().Position, 10, Color3.new(1, 1, 0.8), 2)
				
				-- Mark player as 'observing' to dodge next incoming hit
				local tag = Instance.new("BoolValue")
				tag.Name = "ObservationActive"
				tag.Parent = character
				task.delay(2, function() tag:Destroy() end)
			end
		},
		Active2 = {
			Name = "Harden",
			CD = 1,
			ExecuteServer = function(player, character)
				-- Visual Feedback: Metallic shine
				MovementUtil.ShowVisualFeedback(character:GetPrimaryPartCFrame().Position, 12, Color3.new(0.2, 0.2, 0.2), 4)
				
				-- Reduce incoming knockback (Armament style)
				local tag = Instance.new("NumberValue")
				tag.Name = "KBMultiplier"
				tag.Value = 0.5
				tag.Parent = character
				task.delay(4, function() tag:Destroy() end)
			end
		}
	}
}

return HakiScout
]],
	["FlowStriker"] = [[-- [Legendary] Flow Striker | Blue Lock vibes. Complete control over the ball and the field.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local FlowStriker = {
	Name = "Flow Striker",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Curve Shot",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Golden curve line
				MovementUtil.ShowVisualFeedback(hrp.Position + hrp.CFrame.LookVector * 10, 15, Color3.new(1, 0.8, 0), 0.4, Enum.PartType.Cylinder)
				
				-- Fire a shot that curves toward the nearest target
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 80, {character}) -- Buffed from 30
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 90) -- Buffed from 40
				end
			end
		},
		Active2 = {
			Name = "String Yank",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Blue tether
				MovementUtil.ShowVisualFeedback(targetPos, 8, Color3.new(0.2, 0.4, 1), 0.5)
				
				-- Aim with cursor, range 70
				local aimDir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 70, {character}) -- Buffed from 25
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						local pullDir = (hrp.Position - tHrp.Position).Unit
						MovementUtil.ApplyKnockback(target, pullDir, 160) -- Buffed from 75
					end
				end
			end
		}
	}
}

return FlowStriker
]],
	["DomainWarden"] = [[-- [Legendary] Domain Warden | Sukuna vibes. Control the battlefield, slip 'em up, or open the floor.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local DomainWarden = {
	Name = "Domain Warden",
	Tier = "Legendary",
	Passives = {
		MassResist = 1.25 -- Heavy footing, harder to shove
	},
	Abilities = {
		Active1 = {
			Name = "Flash Zone",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Flash Zone (Purple/Black)
				MovementUtil.ShowVisualFeedback(hrp.Position, 25, Color3.new(0.5, 0, 0.5), 1.5)
				
				-- STUN / FLASH: Blind everyone nearby momentarily
				-- Standardized Ragdoll effect
				local parts = workspace:GetPartBoundsInRadius(hrp.Position, 25)
				local seen = {}
				for _, part in pairs(parts) do
					local m = part:FindFirstAncestorOfClass("Model")
					if m and m:FindFirstChild("Humanoid") and m ~= character and not seen[m] then
						seen[m] = true
						local hum = m.Humanoid
						hum.PlatformStand = true
						task.delay(1.5, function() hum.PlatformStand = false end)
					end
				end
				
				-- TANK BUFF: While in the zone, you are sturdy
				MovementUtil.ApplyTankBuff(character, 5, 40, 0.4)
			end
		},
		Active2 = {
			Name = "Cleave Line",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Dark cleave path
				MovementUtil.ShowVisualFeedback(hrp.Position + hrp.CFrame.LookVector * 20, 30, Color3.new(0, 0, 0), 0.4, Enum.PartType.Cylinder)
				
				-- Deletes parts in a line (SAFETY ADDED: Ignore floors/large parts)
				local parts = workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0,0,-20), Vector3.new(10, 5, 40))
				for _, part in pairs(parts) do
					if part.Size.X > 50 or part.Size.Z > 50 then continue end
					if part.Name:lower():find("baseplate") or part.Name:lower():find("floor") then continue end
					
					if not part:FindFirstAncestorOfClass("Model") then
						part:Destroy()
					end
				end
			end
		}
	}
}

return DomainWarden
]],
	["BankaiBlade"] = [[-- [Legendary] Bankai Blade | Ichigo vibes. Blink faster than they can see and nuke 'em.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BankaiBlade = {
	Name = "Bankai Blade",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Chain Flash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Rapid black flashes
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0, 0, 0), 0.6)
				
				-- 4 rapid dashes toward cursor or look vector (Standardized)
				for i = 1, 4 do
					MovementUtil.ApplyVelocity(hrp, hrp.CFrame.LookVector * 100, 0.1)
					task.wait(0.15)
				end
			end
		},
		Active2 = {
			Name = "Nuke Wave",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Massive dark sphere
				MovementUtil.ShowVisualFeedback(hrp.Position, 40, Color3.new(0.2, 0, 0.2), 0.8)
				
				-- Wide wave of sheer force
				MovementUtil.CreateExplosionPush(hrp.Position, 40, 1500000, {character})
			end
		}
	}
}

return BankaiBlade
]],
	["DevilPuller"] = [[-- [Legendary] Devil Puller | Chainsaw Man vibes. Rip and tear? No, pull and pulse.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local DevilPuller = {
	Name = "Devil Puller",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Chain Pull",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Chain tether
				MovementUtil.ShowVisualFeedback(targetPos, 8, Color3.new(0.1, 0.1, 0.1), 0.5)
				
				-- Aim with cursor, range 80
				local aimDir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 80, {character}) -- Buffed from 30
				if target then
					local pullDir = (hrp.Position - target.PrimaryPart.Position).Unit
					MovementUtil.ApplyKnockback(target, pullDir, 160) -- Buffed from 80
				end
			end
		},
		Active2 = {
			Name = "Latch Pulse",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Pulse area
				MovementUtil.ShowVisualFeedback(targetPos, 20, Color3.new(0.3, 0.1, 0.1), 1.2)
				
				-- Pulses toward cursor
				local aimDir = (targetPos - hrp.Position).Unit
				for i = 1, 2 do
					task.wait(0.6)
					local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 50, {character}) -- Buffed from 20
					if target then
						MovementUtil.ApplyKnockback(target, aimDir, 100) -- Buffed from 45
					end
				end
			end
		}
	}
}

return DevilPuller
]],
	["SmashPro"] = [[-- [Legendary] Smash Pro | Deku vibes. High pressure, high impact. Don't break your arms.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local SmashPro = {
	Name = "Smash Pro",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Detroit Smash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Huge area-of-effect push downward (simulated ground pound)
				MovementUtil.CreateExplosionPush(hrp.Position, 10, 600000, {character}) -- Added immunity
				humanoid.WalkSpeed = 16 * 0.5
				task.delay(1.5, function() humanoid.WalkSpeed = 16 end)
			end
		},
		Active2 = {
			Name = "Delaware Flick",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Air pressure pulse
				MovementUtil.ShowVisualFeedback(hrp.Position + (targetPos - hrp.Position).Unit * 10, 15, Color3.new(0.9, 0.9, 1), 0.4)
				
				-- CONSISTENT PRESSURE: High speed flick toward CURSOR
				local aimDir = (targetPos - hrp.Position).Unit
				MovementUtil.CreateExplosionPush(hrp.Position + aimDir * 8, 15, 900000, {character})
			end
		}
	}
}

return SmashPro
]],
	["InfinityGod"] = [[-- [Mythic] Infinity God | Gojo vibes. Infinite gravity at your fingertips. Lapse and Red.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local InfinityGod = {
	Name = "Infinity God",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Lapse Pull",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Lapse Pull (Blue)
				MovementUtil.ShowVisualFeedback(targetPos, 40, Color3.new(0, 0, 1), 0.5)
				
				task.delay(0.5, function()
					MovementUtil.CreateExplosionPush(targetPos, 40, -1500000, {character})
				end)
			end
		},
		Active2 = {
			Name = "Red Blast",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Red Blast
				MovementUtil.ShowVisualFeedback(targetPos, 40, Color3.new(1, 0, 0), 0.5)
				
				task.delay(0.5, function()
					MovementUtil.CreateExplosionPush(targetPos, 40, 2500000, {character})
				end)
			end
		}
	}
}

return InfinityGod
]],
	["Gear5Joy"] = [[-- [Mythic] Gear 5 Joy | Luffy vibes. The most ridiculous power. Rubbery chaos.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Gear5Joy = {
	Name = "Gear 5 Joy",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Floor Ripple",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- The floor turns to rubber and starts bouncing everyone
				for i = 1, 4 do
					task.wait(0.2)
					local dir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
					local pos = hrp.Position + dir * 5
					
					-- Visual Feedback: Rubber ripple
					MovementUtil.ShowVisualFeedback(pos, 8, Color3.new(1, 1, 1), 0.4, Enum.PartType.Ball)
					
					MovementUtil.CreateExplosionPush(pos, 5, 400000, {character}) -- Added immunity
				end
			end
		},
		Active2 = {
			Name = "Gigant",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Grow massive for 5 seconds
				character:ScaleTo(1.3)
				hrp.AssemblyMass *= 1.3
				
				-- Visual Feedback: Transformation burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 15, Color3.new(1, 1, 1), 0.5)
				
				task.delay(5, function()
					character:ScaleTo(1)
				end)
			end
		}
	}
}

return Gear5Joy
]],
	["TrueBankai"] = [[-- [Mythic] True Bankai | Ichigo's final form. Teleport behind and drop 'em, or clear the map.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local TrueBankai = {
	Name = "True Bankai",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Flash Spike",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Blink behind the nearest foe and spike them down
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 60, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						-- Visual Feedback: Black flash start
						MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(0, 0, 0), 0.3)
						
						hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
						
						-- Visual Feedback: Strike burst
						MovementUtil.ShowVisualFeedback(tHrp.Position, 12, Color3.new(0, 0, 0), 0.4)
						
						MovementUtil.ApplyKnockback(target, Vector3.new(0, -1, 0), 200)
					end
				end
			end
		},
		Active2 = {
			Name = "Mugetsu",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- One final push to clear the arena
				MovementUtil.ShowVisualFeedback(hrp.Position, 80, Color3.new(0, 0, 0), 1.5, Enum.PartType.Ball)
				MovementUtil.CreateExplosionPush(hrp.Position, 80, 1000000, {character})
			end
		}
	}
}

return TrueBankai
]],
	["UltimateGates"] = [[-- [Mythic] Ultimate Gates | Might Guy's Limit. Walk on the sky and drop the Night Guy fist.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local UltimateGates = {
	Name = "Ultimate Gates",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Air Walk",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Spawn temporary platforms under your feet
				for i = 1, 10 do
					local plat = Instance.new("Part")
					plat.Size = Vector3.new(4, 0.5, 4)
					plat.CFrame = hrp.CFrame * CFrame.new(0, -3, -2)
					plat.Anchored = true
					plat.Transparency = 1
					plat.Parent = workspace
					game:GetService("Debris"):AddItem(plat, 0.5)
					
					-- Visual Feedback: Red air ripple
					MovementUtil.ShowVisualFeedback(plat.Position, 4, Color3.new(1, 0.2, 0.2), 0.3, Enum.PartType.Cylinder)
					
					task.wait(0.2)
				end
			end
		},
		Active2 = {
			Name = "Night Guy Fist",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Mega fling your target, but you'll be tired after
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 60, {character}) -- Buffed from 20
				if target then
					local tHum = target:FindFirstChild("Humanoid")
					if tHum then
						-- Visual Feedback: Crimson impact
						MovementUtil.ShowVisualFeedback(tHum.Parent.PrimaryPart.Position, 30, Color3.new(0.5, 0, 0), 0.8)
						
						tHum.PlatformStand = true
						task.delay(1, function() tHum.PlatformStand = false end)
						MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 2500) -- Buffed from 500
					end
				end
				
				local hum = character:FindFirstChild("Humanoid")
				if hum then
					hum.PlatformStand = true
					task.delay(3, function() hum.PlatformStand = false end)
				end
			end
		}
	}
}

return UltimateGates
]]
}

for name, content in pairs(classes) do
	AddScript(name, ClassesFolder, content)
end

print("🎉 Movement System Setup Complete! All 21 classes generated.")
