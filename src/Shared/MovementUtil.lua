-- Shared physics and movement helpers.
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

-- SFX helper
function MovementUtil.PlaySound(soundId, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
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
