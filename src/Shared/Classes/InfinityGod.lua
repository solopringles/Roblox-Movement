-- [Mythic] Infinity God | Gojo vibes. Infinite gravity at your fingertips. Lapse and Red.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local InfinityGod = {
	Name = "Infinity God",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Lapse Pull",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Lapse Pull (Blue)
				MovementUtil.ShowVisualFeedback(targetPos, 40, Color3.new(0, 0, 1), 0.5)
				
				task.delay(0.5, function()
					MovementUtil.CreateExplosionPush(targetPos, 40, -1500000, {character})
				end)
			end
		},
		Active2 = {
			Name = "Red Blast",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Red Blast
				MovementUtil.ShowVisualFeedback(targetPos, 40, Color3.new(1, 0, 0), 0.5)
				
				task.delay(0.5, function()
					MovementUtil.CreateExplosionPush(targetPos, 40, 2500000, {character})
				end)
			end
		}
	}
}

return InfinityGod
