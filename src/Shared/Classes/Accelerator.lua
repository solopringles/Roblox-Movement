-- Shared/Classes/Accelerator.lua
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
				
				humanoid.WalkSpeed = 16 * 1.6
				task.delay(3, function()
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
				
				local wall = MovementUtil.IsNearWall(hrp, 5)
				if wall then
					local reflection = (hrp.CFrame.LookVector - 2 * hrp.CFrame.LookVector:Dot(wall.Normal) * wall.Normal).Unit
					hrp.AssemblyLinearVelocity = wall.Normal * 55 + Vector3.new(0, 20, 0)
					MovementUtil.PlaySound(3413531338, hrp)
				end
			end
		}
	}
}

return Accelerator
