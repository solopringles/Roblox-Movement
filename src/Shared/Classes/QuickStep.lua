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
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Wind burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(1, 1, 1), 0.3)
				
				-- Use the reliable ApplyVelocity helper instead of raw velocity
				local dashDir = hrp.CFrame.LookVector
				MovementUtil.ApplyVelocity(hrp, dashDir * 150, 0.25) -- Buffed from 80
			end
		},
		Active2 = {
			Name = "Slash Wave",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Slash line
				MovementUtil.ShowVisualFeedback(hrp.Position + hrp.CFrame.LookVector * 10, 15, Color3.new(1, 0.8, 0.8), 0.4, Enum.PartType.Cylinder)
				
				-- Increased range and impact
				local forward = hrp.CFrame.LookVector
				local target = MovementUtil.GetNearestInRay(hrp.Position, forward, 60, {character}) -- Buffed from 20
				
				if target then
					MovementUtil.ApplyKnockback(target, forward, 150) -- Buffed from 75
				end
			end
		}
	}
}

return QuickStep
