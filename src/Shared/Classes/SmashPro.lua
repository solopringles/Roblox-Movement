-- [Legendary] Smash Pro | Deku vibes. High pressure, high impact. Don't break your arms.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local SmashPro = {
	Name = "Smash Pro",
	Tier = "Legendary",
	Abilities = {
		Active1 = {
			Name = "Detroit Smash",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if not hrp or not humanoid then return end
				
				-- Huge area-of-effect push downward (simulated ground pound)
				MovementUtil.CreateExplosionPush(hrp.Position, 10, 600000, {character}) -- Added immunity
				humanoid.WalkSpeed = 16 * 0.5
				task.delay(1.5, function() humanoid.WalkSpeed = 16 end)
			end
		},
		Active2 = {
			Name = "Delaware Flick",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Air pressure pulse
				MovementUtil.ShowVisualFeedback(hrp.Position + (targetPos - hrp.Position).Unit * 10, 15, Color3.new(0.9, 0.9, 1), 0.4)
				
				-- CONSISTENT PRESSURE: High speed flick toward CURSOR
				local aimDir = (targetPos - hrp.Position).Unit
				MovementUtil.CreateExplosionPush(hrp.Position + aimDir * 8, 15, 900000, {character})
			end
		}
	}
}

return SmashPro
