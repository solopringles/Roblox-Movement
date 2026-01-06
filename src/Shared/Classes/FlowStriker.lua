-- Shared/Classes/FlowStriker.lua
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
				
				-- Simulation of homing proj
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 30, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 40)
					-- Homing logic usually requires a Part with BodyPosition
				end
			end
		},
		Active2 = {
			Name = "String Yank",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
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
