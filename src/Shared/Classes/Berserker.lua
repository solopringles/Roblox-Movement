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
			CD = 15,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Scream and push everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 12, 500000)
				MovementUtil.PlaySound(3413531338, hrp) 
			end
		},
		Active2 = {
			Name = "Frenzy Dash",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Dash forward and fling whoever you hit
				local forward = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, forward * 40, 0.25)
				
				task.delay(0.1, function()
					local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 5, {character})
					if target then
						MovementUtil.ApplyKnockback(target, forward, 70)
					end
				end)
			end
		}
	}
}

return Berserker
