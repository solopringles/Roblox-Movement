-- [Legendary] Devil Puller | Chainsaw Man vibes. Rip and tear? No, pull and pulse.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local DevilPuller = {
	Name = "Devil Puller",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Chain Pull",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Chain tether
				MovementUtil.ShowVisualFeedback(targetPos, 8, Color3.new(0.1, 0.1, 0.1), 0.5)
				
				-- Aim with cursor, range 80
				local aimDir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 80, {character}) -- Buffed from 30
				if target then
					local pullDir = (hrp.Position - target.PrimaryPart.Position).Unit
					MovementUtil.ApplyKnockback(target, pullDir, 160) -- Buffed from 80
				end
			end
		},
		Active2 = {
			Name = "Latch Pulse",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Pulse area
				MovementUtil.ShowVisualFeedback(targetPos, 20, Color3.new(0.3, 0.1, 0.1), 1.2)
				
				-- Pulses toward cursor
				local aimDir = (targetPos - hrp.Position).Unit
				for i = 1, 2 do
					task.wait(0.6)
					local target = MovementUtil.GetNearestInRay(hrp.Position, aimDir, 50, {character}) -- Buffed from 20
					if target then
						MovementUtil.ApplyKnockback(target, aimDir, 100) -- Buffed from 45
					end
				end
			end
		}
	}
}

return DevilPuller
