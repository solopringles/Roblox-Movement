-- Shared/Classes/Gear5Joy.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Gear5Joy = {
	Name = "Gear 5 Joy",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Floor Ripple",
			CD = 8,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				for i = 1, 4 do
					task.wait(0.2)
					local dir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
					MovementUtil.CreateExplosionPush(hrp.Position + dir * 5, 5, 400000)
				end
			end
		},
		Active2 = {
			Name = "Gigant",
			CD = 14,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Size change simulation
				character:ScaleTo(1.3)
				hrp.AssemblyMass *= 1.3
				
				task.delay(5, function()
					character:ScaleTo(1)
				end)
			end
		}
	}
}

return Gear5Joy
