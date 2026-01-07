-- [Legendary] Flow Striker | Blue Lock vibes. Complete control over the ball and the field.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local FlowStriker = {
	Name = "Flow Striker",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Curve Shot",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Golden curve line
				MovementUtil.ShowVisualFeedback(hrp.Position + hrp.CFrame.LookVector * 10, 15, Color3.new(1, 0.8, 0), 0.4, Enum.PartType.Cylinder)
				
				-- Fire a shot that curves toward the nearest target
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 80, {character}) -- Buffed from 30
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 90) -- Buffed from 40
				end
			end
		},
		Active2 = {
			Name = "String Yank",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Blue tether
				MovementUtil.ShowVisualFeedback(targetPos, 8, Color3.new(0.2, 0.4, 1), 0.5)
				
				-- Aim with cursor, range 70
				local aimDir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 70, {character}) -- Buffed from 25
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						local pullDir = (hrp.Position - tHrp.Position).Unit
						MovementUtil.ApplyKnockback(target, pullDir, 160) -- Buffed from 75
					end
				end
			end
		}
	}
}

return FlowStriker
