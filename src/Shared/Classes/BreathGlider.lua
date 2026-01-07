-- [Rare] Breath Glider | Water Breathing style. Smooth movement and flow.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BreathGlider = {
	Name = "Breath Glider",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Riptide Surge",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Water burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 12, Color3.new(0.2, 0.6, 1), 0.4)
				
				-- Forceful surge forward, clearing all previous momentum
				local dashDir = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, dashDir * 180, 0.4)
				
				-- Fling anyone you pass through
				task.spawn(function()
					local start = tick()
					while tick() - start < 0.4 do
						local parts = workspace:GetPartBoundsInRadius(hrp.Position, 10)
						for _, part in pairs(parts) do
							local m = part:FindFirstAncestorOfClass("Model")
							if m and m:FindFirstChild("Humanoid") and m ~= character then
								MovementUtil.ApplyKnockback(m, dashDir + Vector3.new(0,0.5,0), 120)
							end
						end
						task.wait(0.05)
					end
				end)
			end
		},
		Active2 = {
			Name = "Abyssal Anchor",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Depth bubble
				MovementUtil.ShowVisualFeedback(hrp.Position, 30, Color3.new(0, 0, 0.5), 0.6)
				
				-- Weighted pull down
				MovementUtil.CreateExplosionPush(hrp.Position, 30, -900000, {character})
				
				local parts = workspace:GetPartBoundsInRadius(hrp.Position, 35)
				local seen = {}
				for _, part in pairs(parts) do
					local m = part:FindFirstAncestorOfClass("Model")
					if m and m:FindFirstChild("Humanoid") and m ~= character and not seen[m] then
						seen[m] = true
						local hum = m.Humanoid
						hum.PlatformStand = true
						task.delay(2, function() hum.PlatformStand = false end)
					end
				end
			end
		}
	}
}

return BreathGlider
