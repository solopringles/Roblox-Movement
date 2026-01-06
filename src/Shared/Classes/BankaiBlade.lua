-- [Legendary] Bankai Blade | Ichigo vibes. Blink faster than they can see and nuke 'em.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BankaiBlade = {
	Name = "Bankai Blade",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Chain Flash",
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- 3 rapid dashes in a row
				for i = 1, 3 do
					MovementUtil.ApplyVelocity(hrp, hrp.CFrame.LookVector * 30, 0.1)
					task.wait(0.25)
				end
			end
		},
		Active2 = {
			Name = "Nuke Wave",
			CD = 20,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Wide wave of force to clear the area
				local p = Instance.new("Part")
				p.Size = Vector3.new(20, 5, 2)
				p.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
				p.Transparency = 1
				p.CanCollide = false
				p.Parent = workspace
				
				p.Touched:Connect(function(hit)
					local char = hit:FindFirstAncestorOfClass("Model")
					if char and char ~= character then
						MovementUtil.ApplyKnockback(char, hrp.CFrame.LookVector, 65)
					end
				end)
				
				local vel = Instance.new("LinearVelocity")
				vel.VectorVelocity = hrp.CFrame.LookVector * 50
				vel.MaxForce = math.huge
				vel.Attachment0 = Instance.new("Attachment", p)
				vel.Parent = p
				
				game:GetService("Debris"):AddItem(p, 1)
			end
		}
	}
}

return BankaiBlade
