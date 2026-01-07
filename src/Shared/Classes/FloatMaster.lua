-- [Rare] Float Master | Gojo/Ochaco vibes. Control the gravity in the room.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local FloatMaster = {
	Name = "Float Master",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Attract",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Gravity well
				MovementUtil.ShowVisualFeedback(targetPos, 40, Color3.new(0.5, 0, 1), 0.5)
				
				-- Pull items/players in a radius (FIXED: Standardized logic)
				local parts = workspace:GetPartBoundsInRadius(targetPos, 40)
				local seen = {}
				for _, part in pairs(parts) do
					local m = part:FindFirstAncestorOfClass("Model")
					if m and m:FindFirstChild("Humanoid") and m ~= character and not seen[m] then
						seen[m] = true
						local tHrp = m:FindFirstChild("HumanoidRootPart")
						if tHrp then
							local pullDir = (hrp.Position - tHrp.Position).Unit
							MovementUtil.ApplyKnockback(m, pullDir, 120)
						end
					elseif part.Size.Magnitude < 20 and not part.Anchored then
						part.AssemblyLinearVelocity = (hrp.Position - part.Position).Unit * 60
					end
				end
			end
		},
		Active2 = {
			Name = "Push Bubble",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Pop bubble
				MovementUtil.ShowVisualFeedback(hrp.Position, 25, Color3.new(0.8, 0.4, 1), 0.5)
				
				-- Pop a bubble that pushes everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 25, 800000, {character})
			end
		}
	}
}

return FloatMaster
