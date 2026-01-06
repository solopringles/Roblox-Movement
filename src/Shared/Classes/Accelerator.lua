-- [Common] Accelerator | Naruto body flicker. Fast as hell but you'll overheat.
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
					hrp.AssemblyLinearVelocity = wall.Normal * 55 + Vector3.new(0, 20, 0)
					MovementUtil.PlaySound(3413531338, hrp)
				end
			end
		}
	}
}

return Accelerator
