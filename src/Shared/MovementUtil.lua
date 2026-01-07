-- Shared physics and movement helpers.
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
