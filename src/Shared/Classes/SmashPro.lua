-- [Legendary] Smash Pro | Deku vibes. High pressure, high impact. Don't break your arms.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local SmashPro = {
	Name = "Smash Pro",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Detroit Smash",
			CD = 16,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Huge area-of-effect push downward (simulated ground pound)
				MovementUtil.CreateExplosionPush(hrp.Position, 10, 600000)
				humanoid.WalkSpeed = 16 * 0.5
				task.delay(1.5, function() humanoid.WalkSpeed = 16 end)
			end
		},
		Active2 = {
			Name = "Delaware Flick",
			CD = 11,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- High-speed finger flick from 15 studs away
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 15, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 75)
				end
			end
		}
	}
}

return SmashPro
