-- [Common] Quick Step | Dash like a ninja. Simple, but it gets the job done.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local QuickStep = {
	Name = "Quick Step",
	Tier = "Common",
	BaseWalkSpeed = 16 * 1.1, -- Extra zip in your step
	Passives = {
		KnockbackReceivedMult = 1.2 -- You get tossed around easier
	},
	Abilities = {
		Active1 = {
			Name = "Dash",
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Simple forward dash
				local dashDir = hrp.CFrame.LookVector
				hrp.AssemblyLinearVelocity = dashDir * 75
				MovementUtil.PlaySound(3413531338, hrp) 
			end
		},
		Active2 = {
			Name = "Slash Wave",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Poke someone from a distance
				local forward = hrp.CFrame.LookVector
				local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 12, {character})
				
				if target then
					MovementUtil.ApplyKnockback(target, forward, 60)
					MovementUtil.PlaySound(3413531338, target:FindFirstChild("HumanoidRootPart"))
				end
			end
		}
	}
}

return QuickStep
