-- [Mythic] Ultimate Gates | Might Guy's Limit. Walk on the sky and drop the Night Guy fist.
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
