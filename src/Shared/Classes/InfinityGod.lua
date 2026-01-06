-- [Mythic] Infinity God | Gojo vibes. Infinite gravity at your fingertips. Lapse and Red.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local InfinityGod = {
	Name = "Infinity God",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Lapse Pull",
			CD = 7,
			ExecuteServer = function(player, character)
				-- Pull everything to a point in front of you
				local targetPos = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 15
				MovementUtil.CreateExplosionPush(targetPos, 8, -400000) 
			end
		},
		Active2 = {
			Name = "Red Blast",
			CD = 13,
			ExecuteServer = function(player, character)
				-- High-pressure blast at your cursor center 
				local targetPos = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 8
				MovementUtil.CreateExplosionPush(targetPos, 8, 700000)
			end
		}
	}
}

return InfinityGod
