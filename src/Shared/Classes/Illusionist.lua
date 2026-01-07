-- [Common] Illusionist | Prank 'em. Use decoys and swap positions.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Illusionist = {
	Name = "Illusionist",
	Tier = "Common",
	BaseWalkSpeed = 16 * 1.08, -- A bit ghosty
	Abilities = {
		Active1 = {
			Name = "Decoy Dash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Send out a fake version of yourself (LARGER)
				local decoy = Instance.new("Part")
				decoy.Size = character:GetExtentsSize() * 1.5 -- 50% larger
				decoy.CFrame = hrp.CFrame
				decoy.Transparency = 0.5
				decoy.CanCollide = false
				decoy.Anchored = false
				decoy.Parent = workspace
				
				local vel = Instance.new("LinearVelocity")
				vel.MaxForce = math.huge
				vel.VectorVelocity = hrp.CFrame.LookVector * 100 -- Faster
				vel.Attachment0 = Instance.new("Attachment", decoy)
				vel.Parent = decoy
				
				-- EXPLODING DECOY: Blows up on contact with CHARACTERS only
				decoy.Touched:Connect(function(hit)
					if hit:IsDescendantOf(character) then return end
					local targetChar = hit:FindFirstAncestorOfClass("Model")
					if targetChar and targetChar:FindFirstChild("Humanoid") then
						MovementUtil.CreateExplosionPush(decoy.Position, 15, 600000, {character})
						decoy:Destroy()
					end
				end)
				
				-- Visual Feedback: Small burst on dash
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.5, 0, 0.5), 0.4)
				
				task.delay(1.5, function()
					humanoid.WalkSpeed = 16 * 1.08
					if decoy.Parent then decoy:Destroy() end
				end)
			end
		},
		Active2 = {
			Name = "Swap",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- RESTRICTION: Can only swap if relatively still (Not falling off map cheaply)
				if hrp.AssemblyLinearVelocity.Magnitude > 10 then
					warn("🚫 Cannot swap while moving too fast!")
					return
				end
				
				-- Visual Feedback: Swap energy
				MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(0.5, 0, 0.5), 0.4)
				MovementUtil.ShowVisualFeedback(targetPos, 8, Color3.new(0.5, 0, 0.5), 0.4)
				
				-- Aim with your cursor! Range 100
				local aimDir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 100, {character})
				
				if target then
					local targetHrp = target:FindFirstChild("HumanoidRootPart")
					if targetHrp then
						local myCF = hrp.CFrame
						local targetCF = targetHrp.CFrame
						
						hrp.CFrame = targetCF
						targetHrp.CFrame = myCF
						print("🌀 Swapped with " .. target.Name)
					end
				end
			end
		}
	}
}

return Illusionist
