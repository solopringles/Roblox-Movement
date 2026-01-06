-- ROBLOX STUDIO COMMAND BAR SETUP SCRIPT
-- Paste this into your Command Bar (View > Command Bar) and press Enter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- 1. Create Structure
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
function MovementUtil.ApplyVelocity(humanoidRootPart, velocity, duration)
	local attachment = Instance.new("Attachment")
	attachment.Parent = humanoidRootPart
	
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = velocity
	linearVelocity.Attachment0 = attachment
	linearVelocity.Parent = humanoidRootPart
	
	-- Clean up when done
	task.delay(duration, function()
		attachment:Destroy()
		linearVelocity:Destroy()
	end)
end

-- Forceful shove using Roblox's impulse system
function MovementUtil.ApplyImpulse(humanoidRootPart, impulse)
	humanoidRootPart:ApplyImpulse(impulse * humanoidRootPart.AssemblyMass)
end

-- Quick 'n dirty knockback
function MovementUtil.ApplyKnockback(targetCharacter, direction, force)
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = direction * force
	end
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
	if result and result.Instance:IsDescendantOf(workspace) then
		local char = result.Instance:FindFirstAncestorOfClass("Model")
		if char and char:FindFirstChild("Humanoid") then
			return char
		end
	end
	return nil
end

-- Big boom for knockback only (no damage)
function MovementUtil.CreateExplosionPush(position, radius, pressure)
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = radius
	explosion.BlastPressure = pressure
	explosion.Position = position
	explosion.DestroyJointRadiusPercent = 0 -- Important: don't kill everyone
	explosion.Parent = workspace
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
	
	-- Update player stats (WalkSpeed, JumpPower, etc.)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Use class defaults or fall back to Roblox standard
	humanoid.WalkSpeed = classModule.BaseWalkSpeed or 16
    
    if classModule.Passives and classModule.Passives.JumpPowerMult then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50 * classModule.Passives.JumpPowerMult
    end
	
	print("✨ [" .. player.Name .. "] is now: " .. classModule.Name .. " (" .. classModule.Tier .. ")")
	return true
end

function MovementService.HandleAbility(player, abilityIdx) -- abilityIdx is "Active1" or "Active2"
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
		local success, err = pcall(abilityData.ExecuteServer, player, player.Character)
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
	
	-- Q/E for abilities
	if input.KeyCode == Enum.KeyCode.Q then
		AbilityRemote:FireServer("Active1")
	elseif input.KeyCode == Enum.KeyCode.E then
		AbilityRemote:FireServer("Active2")
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
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Use the reliable ApplyVelocity helper instead of raw velocity
				local dashDir = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, dashDir * 80, 0.25)
				-- Sound removed to fix 403 error
			end
		},
		Active2 = {
			Name = "Slash Wave",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Increased range and impact
				local forward = hrp.CFrame.LookVector
				local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 20, {character})
				
				if target then
					MovementUtil.ApplyKnockback(target, forward, 75)
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
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Kick the air to go up
				MovementUtil.ApplyVelocity(hrp, Vector3.new(0, 60, 0), 0.2)
			end
		},
		Active2 = {
			Name = "Hover",
			CD = 15,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
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
			CD = 15,
			ExecuteServer = function(player, character)
				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then return end
				
				-- Go fast for a bit
				humanoid.WalkSpeed = 16 * 1.6
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
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Kick off a wall to go flying
				local wall = MovementUtil.IsNearWall(hrp, 5)
				if wall then
					local jumpDir = (wall.Normal * 1.5 + Vector3.new(0, 1.2, 0)).Unit
					MovementUtil.ApplyVelocity(hrp, jumpDir * 65, 0.3)
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
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Lock yourself in place
				local vf = Instance.new("VectorForce")
				vf.Force = Vector3.zero
				vf.RelativeTo = Enum.ActuatorRelativeTo.World
				vf.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				vf.Parent = hrp
				
				local anchorPos = hrp.Position
				local hb = game:GetService("RunService").Heartbeat:Connect(function()
					if vf.Parent then
						local dist = (anchorPos - hrp.Position)
						vf.Force = dist * 8000
					end
				end)
				
				task.delay(2.5, function()
					vf:Destroy()
					hb:Disconnect()
				end)
			end
		},
		Active2 = {
			Name = "Magnetize",
			CD = 15,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Drag someone closer to you
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 10, {character})
				if target then
					local targetHrp = target:FindFirstChild("HumanoidRootPart")
					if targetHrp then
						local dir = (hrp.Position - targetHrp.Position).Unit
						targetHrp.AssemblyLinearVelocity = dir * 45
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
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Send out a fake version of yourself
				local decoy = Instance.new("Part")
				decoy.Size = character:GetExtentsSize()
				decoy.CFrame = hrp.CFrame
				decoy.Transparency = 0.5
				decoy.CanCollide = false
				decoy.Anchored = false
				decoy.Parent = workspace
				
				local vel = Instance.new("LinearVelocity")
				vel.MaxForce = math.huge
				vel.VectorVelocity = hrp.CFrame.LookVector * 40
				vel.Attachment0 = Instance.new("Attachment", decoy)
				vel.Parent = decoy
				
				humanoid.WalkSpeed = 16 * 1.4
				
				task.delay(1, function()
					humanoid.WalkSpeed = 16 * 1.08
					decoy:Destroy()
				end)
			end
		},
		Active2 = {
			Name = "Swap",
			CD = 20,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Swap spots with some poor guy
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 8, {character})
				if target then
					local targetHrp = target:FindFirstChild("HumanoidRootPart")
					if targetHrp then
						local myPos = hrp.CFrame
						local targetPos = targetHrp.CFrame
						
						hrp.CFrame = targetPos
						targetHrp.CFrame = myPos
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
			CD = 15,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Scream and push everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 12, 500000)
			end
		},
		Active2 = {
			Name = "Frenzy Dash",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Dash forward and fling whoever you hit
				local forward = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, forward * 40, 0.25)
				
				task.delay(0.1, function()
					local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 5, {character})
					if target then
						MovementUtil.ApplyKnockback(target, forward, 70)
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
			CD = 9,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Punch someone from across the room
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 20, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 50)
				end
			end
		},
		Active2 = {
			Name = "Jet Pull",
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pull yourself to a wall or miss and get yanked back
				local result = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15)
				if result then
					hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 65
				else
					-- Recoil if you whiff it
					hrp.AssemblyLinearVelocity = -hrp.CFrame.LookVector * 40
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
	Abilities = {
		Active1 = {
			Name = "Blink",
			CD = 8,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Instant teleport 10 studs ahead
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				
				local result = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 10, rayParams)
				local targetPos = result and result.Position or (hrp.Position + hrp.CFrame.LookVector * 10)
				
				hrp.CFrame = CFrame.new(targetPos) * hrp.CFrame.Rotation
				MovementUtil.PlaySound(3413531338, hrp)
			end
		},
		Active2 = {
			Name = "Phase",
			CD = 14,
			ExecuteServer = function(player, character)
				-- Go ghost mode to avoid hits
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0.6
						part.CanTouch = false 
					end
				end
				
				task.delay(2, function()
					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
							part.CanTouch = true
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
			Name = "Push Bubble",
			CD = 11,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pop a bubble that pushes everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 8, 400000)
			end
		},
		Active2 = {
			Name = "Attract",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pull the 2 nearest people into your face
				local found = 0
				for _, p in pairs(game.Players:GetPlayers()) do
					if p ~= player and p.Character and found < 2 then
						local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
						if tHrp and (tHrp.Position - hrp.Position).Magnitude < 8 then
							local dir = (hrp.Position - tHrp.Position).Unit
							tHrp.AssemblyLinearVelocity = dir * 40
							found += 1
						end
					end
				end
			end
		}
	}
}

return FloatMaster
]],
	["BreathGlider"] = [[-- [Rare] Breath Glider | Water Breathing style. Smooth movement and slippery traps.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BreathGlider = {
	Name = "Breath Glider",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Forward Glide",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Float forward without losing height
				local vf = Instance.new("VectorForce")
				vf.Force = Vector3.new(0, 4000, 0)
				vf.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				vf.Parent = hrp
				
				local hb = game:GetService("RunService").Heartbeat:Connect(function()
					if vf.Parent then
						hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
					end
				end)
				
				task.delay(3, function()
					vf:Destroy()
					hb:Disconnect()
				end)
			end
		},
		Active2 = {
			Name = "Slippery Puddles",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Leave a trail of ice for people to slip on
				for i = 1, 6 do
					task.wait(0.2)
					local puddle = Instance.new("Part")
					puddle.Size = Vector3.new(4, 0.2, 4)
					puddle.Position = hrp.Position - Vector3.new(0, 2.8, 0)
					puddle.CanCollide = false
					puddle.Transparency = 0.5
					puddle.Color = Color3.fromRGB(150, 200, 255)
					puddle.Material = Enum.Material.Ice 
					puddle.Parent = workspace
					game:GetService("Debris"):AddItem(puddle, 4)
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
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Stop dead in your tracks
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		},
		Active2 = {
			Name = "Leap Burst",
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Big jump toward where you're looking
				hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 70
				MovementUtil.PlaySound(3413531338, hrp)
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
			CD = 10,
			ExecuteServer = function(player, character)
				-- Mark player as 'observing' to dodge next incoming hit
				local tag = Instance.new("BoolValue")
				tag.Name = "ObservationActive"
				tag.Parent = character
				task.delay(2, function() tag:Destroy() end)
			end
		},
		Active2 = {
			Name = "Harden",
			CD = 14,
			ExecuteServer = function(player, character)
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
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Fire a shot that curves toward the nearest target
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 30, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 40)
				end
			end
		},
		Active2 = {
			Name = "String Yank",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Yank a foe right to your feet
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 15, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						local dir = (hrp.Position - tHrp.Position).Unit
						tHrp.AssemblyLinearVelocity = dir * 60
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
			Name = "Ice Zone",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Turn the floor beneath you into ice
				local ice = Instance.new("Part")
				ice.Size = Vector3.new(24, 0.2, 24)
				ice.Position = hrp.Position - Vector3.new(0, 2.9, 0)
				ice.Transparency = 0.5
				ice.Color = Color3.fromRGB(100, 200, 255)
				ice.Material = Enum.Material.Ice
				ice.Anchored = true
				ice.CanCollide = true
				ice.Parent = workspace
				game:GetService("Debris"):AddItem(ice, 5)
			end
		},
		Active2 = {
			Name = "Cleave Line",
			CD = 16,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Temporary "hole" in the floor by disabling collision
				local rayRes = workspace:Raycast(hrp.Position + hrp.CFrame.LookVector * 5, Vector3.new(0, -10, 0))
				if rayRes and rayRes.Instance then
					local originalCollide = rayRes.Instance.CanCollide
					rayRes.Instance.CanCollide = false
					task.delay(3, function()
						rayRes.Instance.CanCollide = originalCollide
					end)
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
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- 3 rapid dashes in a row
				for i = 1, 3 do
					MovementUtil.ApplyVelocity(hrp, hrp.CFrame.LookVector * 30, 0.1)
					task.wait(0.25)
				end
			end
		},
		Active2 = {
			Name = "Nuke Wave",
			CD = 20,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Wide wave of force to clear the area
				local p = Instance.new("Part")
				p.Size = Vector3.new(20, 5, 2)
				p.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
				p.Transparency = 1
				p.CanCollide = false
				p.Parent = workspace
				
				p.Touched:Connect(function(hit)
					local char = hit:FindFirstAncestorOfClass("Model")
					if char and char ~= character then
						MovementUtil.ApplyKnockback(char, hrp.CFrame.LookVector, 65)
					end
				end)
				
				local vel = Instance.new("LinearVelocity")
				vel.VectorVelocity = hrp.CFrame.LookVector * 50
				vel.MaxForce = math.huge
				vel.Attachment0 = Instance.new("Attachment", p)
				vel.Parent = p
				
				game:GetService("Debris"):AddItem(p, 1)
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
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Drag someone toward you from 15 studs away
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 15, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						local dir = (hrp.Position - tHrp.Position).Unit
						tHrp.AssemblyLinearVelocity = dir * 50
					end
				end
			end
		},
		Active2 = {
			Name = "Latch Pulse",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Send out rhythmic pulses to keep 'em in check
				for i = 1, 2 do
					task.wait(0.6)
					local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 10, {character})
					if target then
						MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 35)
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
			CD = 16,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Huge area-of-effect push downward (simulated ground pound)
				MovementUtil.CreateExplosionPush(hrp.Position, 10, 600000)
				humanoid.WalkSpeed = 16 * 0.5
				task.delay(1.5, function() humanoid.WalkSpeed = 16 end)
			end
		},
		Active2 = {
			Name = "Delaware Flick",
			CD = 11,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- High-speed finger flick from 15 studs away
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 15, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 75)
				end
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
			CD = 7,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pull everything to a point in front of you
				local targetPos = hrp.Position + hrp.CFrame.LookVector * 15
				MovementUtil.CreateExplosionPush(targetPos, 8, -400000) 
			end
		},
		Active2 = {
			Name = "Red Blast",
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- High-pressure blast at your cursor center 
				local targetPos = hrp.Position + hrp.CFrame.LookVector * 8
				MovementUtil.CreateExplosionPush(targetPos, 8, 700000)
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
			CD = 8,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- The floor turns to rubber and starts bouncing everyone
				for i = 1, 4 do
					task.wait(0.2)
					local dir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
					MovementUtil.CreateExplosionPush(hrp.Position + dir * 5, 5, 400000)
				end
			end
		},
		Active2 = {
			Name = "Gigant",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Grow massive for 5 seconds
				character:ScaleTo(1.3)
				hrp.AssemblyMass *= 1.3
				
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
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Blink behind the nearest foe and spike them down
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 20, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 2)
						MovementUtil.ApplyKnockback(target, Vector3.new(0, -1, 0), 50)
					end
				end
			end
		},
		Active2 = {
			Name = "Mugetsu",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- One final push to clear the arena
				MovementUtil.CreateExplosionPush(hrp.Position, 30, 450000)
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
			CD = 9,
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
					task.wait(0.2)
				end
			end
		},
		Active2 = {
			Name = "Night Guy Fist",
			CD = 20,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Mega fling your target, but you'll be tired after
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 20, {character})
				if target then
					local tHum = target:FindFirstChild("Humanoid")
					if tHum then
						tHum.PlatformStand = true
						task.delay(1, function() tHum.PlatformStand = false end)
						MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 500)
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
