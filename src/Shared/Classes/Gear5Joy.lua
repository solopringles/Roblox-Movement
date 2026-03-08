-- [Mythic] Gear 5 Joy | Luffy vibes. The most ridiculous power. Rubbery chaos.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Gear5Joy = {
	Name = "Gear 5 Joy",
	Tier = "Mythic",
	Abilities = {
		Active1 = {
			Name = "Floor Ripple",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- The floor turns to rubber and starts bouncing everyone
				for i = 1, 4 do
					task.wait(0.2)
					local randomOffset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
					local dir = MovementUtil.SafeUnit(randomOffset, hrp.CFrame.LookVector)
					local pos = hrp.Position + dir * 5
					
					-- Visual Feedback: Rubber ripple
					MovementUtil.ShowVisualFeedback(pos, 8, Color3.new(1, 1, 1), 0.4, Enum.PartType.Ball)
					
					MovementUtil.CreateExplosionPush(pos, 5, 400000, {character}) -- Added immunity
				end
			end
		},
		Active2 = {
			Name = "Gigant",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp or character:GetAttribute("Gear5GigantActive") then return end
				
				-- Grow 20% larger for 4 seconds
				character:SetAttribute("Gear5GigantActive", true)
				character:ScaleTo(1.2)
				
				-- Visual Feedback: Transformation burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 15, Color3.new(1, 1, 1), 0.5)
				
				task.delay(4, function()
					character:ScaleTo(1)
					character:SetAttribute("Gear5GigantActive", nil)
				end)
			end
		}
	}
}

return Gear5Joy
