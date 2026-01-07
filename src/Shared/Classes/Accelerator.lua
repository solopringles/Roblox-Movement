-- [Common] Accelerator | Naruto body flicker. Fast as hell but you'll overheat.
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
