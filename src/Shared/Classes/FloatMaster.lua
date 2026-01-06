-- [Rare] Float Master | Gojo/Ochaco vibes. Control the gravity in the room.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local FloatMaster = {
	Name = "Float Master",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Push Bubble",
			CD = 11,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pop a bubble that pushes everyone away
				MovementUtil.CreateExplosionPush(hrp.Position, 8, 400000)
			end
		},
		Active2 = {
			Name = "Attract",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pull the 2 nearest people into your face
				local found = 0
				for _, p in pairs(game.Players:GetPlayers()) do
					if p ~= player and p.Character and found < 2 then
						local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
						if tHrp and (tHrp.Position - hrp.Position).Magnitude < 8 then
							local dir = (hrp.Position - tHrp.Position).Unit
							tHrp.AssemblyLinearVelocity = dir * 40
							found += 1
						end
					end
				end
			end
		}
	}
}

return FloatMaster
