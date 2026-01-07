-- [Rare] Shunpo Ghost | Bleach vibes. Now you see me, now you're dead. 
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local ShunpoGhost = {
	Name = "Shunpo Ghost",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Blink",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Blink start
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.2, 0.2, 0.2), 0.3)
				
				-- Blink toward cursor (Max 40 studs)
				local aimDir = (targetPos - hrp.Position).Unit
				if (targetPos - hrp.Position).Magnitude > 40 then 
					targetPos = hrp.Position + aimDir * 40
				end
				
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				
				local result = workspace:Raycast(hrp.Position, (targetPos - hrp.Position), rayParams)
				local finalPos = result and result.Position or targetPos
				
				hrp.CFrame = CFrame.new(finalPos) * hrp.CFrame.Rotation
				
				-- Visual Feedback: Blink end
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.2, 0.2, 0.2), 0.3)
			end
		},
		Active2 = {
			Name = "Phase",
			CD = 1,
			ExecuteServer = function(player, character)
				-- FULL INVISIBILITY
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanTouch = false 
					elseif part:IsA("Decal") then
						part.Transparency = 1
					end
				end
				
				task.delay(4, function()
					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
							part.CanTouch = true
						elseif part:IsA("Decal") then
							part.Transparency = 0
						end
					end
				end)
			end
		}
	}
}

return ShunpoGhost
