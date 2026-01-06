-- [Legendary] Flow Striker | Blue Lock vibes. Complete control over the ball and the field.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local FlowStriker = {
	Name = "Flow Striker",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Curve Shot",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Fire a shot that curves toward the nearest target
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 30, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 40)
				end
			end
		},
		Active2 = {
			Name = "String Yank",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Yank a foe right to your feet
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 15, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						local dir = (hrp.Position - tHrp.Position).Unit
						tHrp.AssemblyLinearVelocity = dir * 60
					end
				end
			end
		}
	}
}

return FlowStriker
