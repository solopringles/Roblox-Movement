-- [Mythic] True Bankai | Ichigo's final form. Teleport behind and drop 'em, or clear the map.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local TrueBankai = {
	Name = "True Bankai",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Flash Spike",
			CD = 12,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Blink behind the nearest foe and spike them down
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 20, {character})
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 2)
						MovementUtil.ApplyKnockback(target, Vector3.new(0, -1, 0), 50)
					end
				end
			end
		},
		Active2 = {
			Name = "Mugetsu",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- One final push to clear the arena
				MovementUtil.CreateExplosionPush(hrp.Position, 30, 450000)
			end
		}
	}
}

return TrueBankai
