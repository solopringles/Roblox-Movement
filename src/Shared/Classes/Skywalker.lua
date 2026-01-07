-- [Common] Skywalker | One Piece Geppo vibes. Don't touch the floor.
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
