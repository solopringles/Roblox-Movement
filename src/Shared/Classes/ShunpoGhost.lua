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
				local offset = targetPos - hrp.Position
				local aimDir = offset.Unit
				local travelDistance = math.min(offset.Magnitude, 40)
				
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				
				local result = workspace:Raycast(hrp.Position, aimDir * travelDistance, rayParams)
				local finalPos = result and (result.Position - aimDir * 3) or (hrp.Position + aimDir * travelDistance)
				local groundCheck = workspace:Raycast(finalPos + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
				if groundCheck then
					finalPos = groundCheck.Position + Vector3.new(0, 3, 0)
				end
				
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
						part:SetAttribute("ShunpoOriginalTransparency", part.Transparency)
						part:SetAttribute("ShunpoOriginalCanTouch", part.CanTouch)
						part.Transparency = 1
						part.CanTouch = false 
					elseif part:IsA("Decal") then
						part:SetAttribute("ShunpoOriginalTransparency", part.Transparency)
						part.Transparency = 1
					end
				end
				
				task.delay(4, function()
					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							local originalTransparency = part:GetAttribute("ShunpoOriginalTransparency")
							local originalCanTouch = part:GetAttribute("ShunpoOriginalCanTouch")
							part.Transparency = typeof(originalTransparency) == "number" and originalTransparency or part.Transparency
							part.CanTouch = typeof(originalCanTouch) == "boolean" and originalCanTouch or true
							part:SetAttribute("ShunpoOriginalTransparency", nil)
							part:SetAttribute("ShunpoOriginalCanTouch", nil)
						elseif part:IsA("Decal") then
							local originalTransparency = part:GetAttribute("ShunpoOriginalTransparency")
							part.Transparency = typeof(originalTransparency) == "number" and originalTransparency or part.Transparency
							part:SetAttribute("ShunpoOriginalTransparency", nil)
						end
					end
				end)
			end
		}
	}
}

return ShunpoGhost
