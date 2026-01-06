-- [Common] Illusionist | Prank 'em. Use decoys and swap positions.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Illusionist = {
	Name = "Illusionist",
	Tier = "Common",
	BaseWalkSpeed = 16 * 1.08, -- A bit ghosty
	Abilities = {
		Active1 = {
			Name = "Decoy Dash",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Send out a fake version of yourself
				local decoy = Instance.new("Part")
				decoy.Size = character:GetExtentsSize()
				decoy.CFrame = hrp.CFrame
				decoy.Transparency = 0.5
				decoy.CanCollide = false
				decoy.Anchored = false
				decoy.Parent = workspace
				
				local vel = Instance.new("LinearVelocity")
				vel.MaxForce = math.huge
				vel.VectorVelocity = hrp.CFrame.LookVector * 40
				vel.Attachment0 = Instance.new("Attachment", decoy)
				vel.Parent = decoy
				
				humanoid.WalkSpeed = 16 * 1.4
				
				task.delay(1, function()
					humanoid.WalkSpeed = 16 * 1.08
					decoy:Destroy()
				end)
			end
		},
		Active2 = {
			Name = "Swap",
			CD = 20,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Swap spots with some poor guy
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 8, {character})
				if target then
					local targetHrp = target:FindFirstChild("HumanoidRootPart")
					if targetHrp then
						local myPos = hrp.CFrame
						local targetPos = targetHrp.CFrame
						
						hrp.CFrame = targetPos
						targetHrp.CFrame = myPos
						
						MovementUtil.PlaySound(3413531338, hrp)
					end
				end
			end
		}
	}
}

return Illusionist
