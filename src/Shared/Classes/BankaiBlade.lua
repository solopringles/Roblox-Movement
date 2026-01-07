-- [Legendary] Bankai Blade | Ichigo vibes. Blink faster than they can see and nuke 'em.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local BankaiBlade = {
	Name = "Bankai Blade",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Chain Flash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Rapid black flashes
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0, 0, 0), 0.6)
				
				-- 4 rapid dashes toward cursor or look vector (Standardized)
				for i = 1, 4 do
					MovementUtil.ApplyVelocity(hrp, hrp.CFrame.LookVector * 100, 0.1)
					task.wait(0.15)
				end
			end
		},
		Active2 = {
			Name = "Nuke Wave",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Massive dark sphere
				MovementUtil.ShowVisualFeedback(hrp.Position, 40, Color3.new(0.2, 0, 0.2), 0.8)
				
				-- Wide wave of sheer force
				MovementUtil.CreateExplosionPush(hrp.Position, 40, 1500000, {character})
			end
		}
	}
}

return BankaiBlade
