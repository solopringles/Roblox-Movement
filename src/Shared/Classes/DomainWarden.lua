-- [Legendary] Domain Warden | Sukuna vibes. Control the battlefield, slip 'em up, or open the floor.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local DomainWarden = {
	Name = "Domain Warden",
	Tier = "Legendary",
	Passives = {
		MassResist = 1.25 -- Heavy footing, harder to shove
	},
	Abilities = {
		Active1 = {
			Name = "Flash Zone",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Flash Zone (Purple/Black)
				MovementUtil.ShowVisualFeedback(hrp.Position, 25, Color3.new(0.5, 0, 0.5), 1.5)
				
				-- STUN / FLASH: Blind everyone nearby momentarily
				-- Standardized Ragdoll effect
				local parts = workspace:GetPartBoundsInRadius(hrp.Position, 25)
				local seen = {}
				for _, part in pairs(parts) do
					local m = part:FindFirstAncestorOfClass("Model")
					if m and m:FindFirstChild("Humanoid") and m ~= character and not seen[m] then
						seen[m] = true
						local hum = m.Humanoid
						hum.PlatformStand = true
						task.delay(1.5, function() hum.PlatformStand = false end)
					end
				end
				
				-- TANK BUFF: While in the zone, you are sturdy
				MovementUtil.ApplyTankBuff(character, 5, 40, 0.4)
			end
		},
		Active2 = {
			Name = "Cleave Line",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Dark cleave path
				MovementUtil.ShowVisualFeedback(hrp.Position + hrp.CFrame.LookVector * 20, 30, Color3.new(0, 0, 0), 0.4, Enum.PartType.Cylinder)
				
				-- Deletes parts in a line (SAFETY ADDED: Ignore floors/large parts)
				local parts = workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0,0,-20), Vector3.new(10, 5, 40))
				for _, part in pairs(parts) do
					if part.Size.X > 50 or part.Size.Z > 50 then continue end
					if part.Name:lower():find("baseplate") or part.Name:lower():find("floor") then continue end
					
					if not part:FindFirstAncestorOfClass("Model") then
						part:Destroy()
					end
				end
			end
		}
	}
}

return DomainWarden
