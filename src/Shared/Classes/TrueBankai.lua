-- [Mythic] True Bankai | Ichigo's final form. Teleport behind and drop 'em, or clear the map.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local TrueBankai = {
	Name = "True Bankai",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Flash Spike",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Blink behind the nearest foe and spike them down
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 60, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						-- Visual Feedback: Black flash start
						MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(0, 0, 0), 0.3)
						
						hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
						
						-- Visual Feedback: Strike burst
						MovementUtil.ShowVisualFeedback(tHrp.Position, 12, Color3.new(0, 0, 0), 0.4)
						
						MovementUtil.ApplyKnockback(target, Vector3.new(0, -1, 0), 200)
					end
				end
			end
		},
		Active2 = {
			Name = "Mugetsu",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- One final push to clear the arena
				MovementUtil.ShowVisualFeedback(hrp.Position, 80, Color3.new(0, 0, 0), 1.5, Enum.PartType.Ball)
				MovementUtil.CreateExplosionPush(hrp.Position, 80, 1000000, {character})
			end
		}
	}
}

return TrueBankai
