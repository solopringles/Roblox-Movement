-- [Common] Berserker | Pure aggression. The more you move, the faster you get.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Berserker = {
	Name = "Berserker",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		RampingSpeed = true -- You get faster as you hold W (handled in main loop)
	},
	Abilities = {
		Active1 = {
			Name = "Roar",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Red shockwave
				MovementUtil.ShowVisualFeedback(hrp.Position, 25, Color3.new(1, 0, 0), 0.5)
				
				-- Scream and push everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 25, 900000, {character}) -- Added immunity
			end
		},
		Active2 = {
			Name = "Frenzy Dash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Charging aura
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(1, 0.5, 0), 0.4)
				
				-- Dash forward and fling whoever you hit
				local forward = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, forward * 80, 0.4) -- Buffed from 40
				
				task.delay(0.1, function()
					local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 10, {character}) -- Buffed from 5
					if target then
						MovementUtil.ApplyKnockback(target, forward, 140) -- Buffed from 70
					end
				end)
			end
		}
	}
}

return Berserker
