-- Shared/Classes/ShunpoGhost.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local ShunpoGhost = {
	Name = "Shunpo Ghost",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Blink",
			CD = 8,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				
				local result = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 10, rayParams)
				local targetPos = result and result.Position or (hrp.Position + hrp.CFrame.LookVector * 10)
				
				hrp.CFrame = CFrame.new(targetPos) * hrp.CFrame.Rotation
				MovementUtil.PlaySound(3413531338, hrp)
			end
		},
		Active2 = {
			Name = "Phase",
			CD = 14,
			ExecuteServer = function(player, character)
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0.6
						part.CanTouch = false -- Simulate phased
					end
				end
				
				task.delay(2, function()
					for _, part in pairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
							part.CanTouch = true
						end
					end
				end)
			end
		}
	}
}

return ShunpoGhost
