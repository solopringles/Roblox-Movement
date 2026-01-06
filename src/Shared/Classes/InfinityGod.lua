-- Shared/Classes/InfinityGod.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local InfinityGod = {
	Name = "Infinity God",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Lapse Pull",
			CD = 7,
			ExecuteServer = function(player, character)
				-- Simulation: Pull to mouse pos (usually passed via remote, 
				-- but for this generic module we use a point 15 studs ahead)
				local targetPos = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 15
				MovementUtil.CreateExplosionPush(targetPos, 8, -400000) -- Negative pressure pulls
			end
		},
		Active2 = {
			Name = "Red Blast",
			CD = 13,
			ExecuteServer = function(player, character)
				local targetPos = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 8
				MovementUtil.CreateExplosionPush(targetPos, 8, 700000)
				-- Screen shake/flash usually handled on client
			end
		}
	}
}

return InfinityGod
