-- Shared/Classes/Skywalker.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Skywalker = {
	Name = "Skywalker",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		JumpPowerMult = 1.15,
		FallSpeedMult = 0.85
	},
	Abilities = {
		Active1 = {
			Name = "Air Jump",
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				hrp.AssemblyLinearVelocity += Vector3.new(0, 60, 0)
				MovementUtil.PlaySound(3413531338, hrp)
			end
		},
		Active2 = {
			Name = "Hover",
			CD = 15,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				local vf = Instance.new("VectorForce")
				vf.Force = Vector3.new(0, 4000, 0) -- Near neutral buoyancy for standard parts
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
