-- Shared/MovementUtil.lua
local MovementUtil = {}

-- Constant for i-frame tag
MovementUtil.IFRAME_TAG = "IFrameActive"

function MovementUtil.ApplyVelocity(humanoidRootPart, velocity, duration)
	local attachment = Instance.new("Attachment")
	attachment.Parent = humanoidRootPart
	
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = velocity
	linearVelocity.Attachment0 = attachment
	linearVelocity.Parent = humanoidRootPart
	
	task.delay(duration, function()
		attachment:Destroy()
		linearVelocity:Destroy()
	end)
end

function MovementUtil.ApplyImpulse(humanoidRootPart, impulse)
	humanoidRootPart:ApplyImpulse(impulse * humanoidRootPart.AssemblyMass)
end

function MovementUtil.ApplyKnockback(targetCharacter, direction, force)
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = direction * force
	end
end

function MovementUtil.PlaySound(soundId, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

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

function MovementUtil.CreateExplosionPush(position, radius, pressure)
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = radius
	explosion.BlastPressure = pressure
	explosion.Position = position
	explosion.DestroyJointRadiusPercent = 0 -- No damage
	explosion.Parent = workspace
end

return MovementUtil
