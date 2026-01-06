-- Shared/Classes/BreathGlider.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BreathGlider = {
	Name = "Breath Glider",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Forward Glide",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				local vf = Instance.new("VectorForce")
				vf.Force = Vector3.new(0, 4000, 0) -- Bias to lock Y
				vf.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				vf.Parent = hrp
				
				local hb = game:GetService("RunService").Heartbeat:Connect(function()
					if vf.Parent then
						hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
					end
				end)
				
				task.delay(3, function()
					vf:Destroy()
					hb:Disconnect()
				end)
			end
		},
		Active2 = {
			Name = "Slippery Puddles",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				for i = 1, 6 do
					task.wait(0.2)
					local puddle = Instance.new("Part")
					puddle.Size = Vector3.new(4, 0.2, 4)
					puddle.Position = hrp.Position - Vector3.new(0, 2.8, 0)
					puddle.CanCollide = false
					puddle.Transparency = 0.5
					puddle.Color = Color3.fromRGB(150, 200, 255)
					puddle.Material = Enum.Material.Ice -- Low friction
					puddle.Parent = workspace
					game:GetService("Debris"):AddItem(puddle, 4)
				end
			end
		}
	}
}

return BreathGlider
