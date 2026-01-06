-- Shared/Classes/Guardian.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Guardian = {
	Name = "Guardian",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		MassResist = 1.3
	},
	Abilities = {
		Active1 = {
			Name = "Iron Body",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				local vf = Instance.new("VectorForce")
				vf.Force = Vector3.zero
				vf.RelativeTo = Enum.ActuatorRelativeTo.World
				vf.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				vf.Parent = hrp
				
				-- Lock position simulation
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
			Name = "Taunt Pull",
			CD = 15,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
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
