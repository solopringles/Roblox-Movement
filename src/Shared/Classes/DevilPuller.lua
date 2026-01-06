-- [Legendary] Devil Puller | Chainsaw Man vibes. Rip and tear? No, pull and pulse.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local DevilPuller = {
	Name = "Devil Puller",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Chain Pull",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Drag someone toward you from 15 studs away
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 15, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						local dir = (hrp.Position - tHrp.Position).Unit
						tHrp.AssemblyLinearVelocity = dir * 50
					end
				end
			end
		},
		Active2 = {
			Name = "Latch Pulse",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Send out rhythmic pulses to keep 'em in check
				for i = 1, 2 do
					task.wait(0.6)
					local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 10, {character})
					if target then
						MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 35)
					end
				end
			end
		}
	}
}

return DevilPuller
