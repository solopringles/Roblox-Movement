-- Shared/Classes/DomainWarden.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local DomainWarden = {
	Name = "Domain Warden",
	Tier = "Legendary",
	Passives = {
		MassResist = 1.25
	},
	Abilities = {
		Active1 = {
			Name = "Ice Zone",
			CD = 18,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				local ice = Instance.new("Part")
				ice.Size = Vector3.new(24, 0.2, 24)
				ice.Position = hrp.Position - Vector3.new(0, 2.9, 0)
				ice.Transparency = 0.5
				ice.Color = Color3.fromRGB(100, 200, 255)
				ice.Material = Enum.Material.Ice
				ice.Anchored = true
				ice.CanCollide = true
				ice.Parent = workspace
				game:GetService("Debris"):AddItem(ice, 5)
			end
		},
		Active2 = {
			Name = "Cleave Line",
			CD = 16,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Simulation of floor holes
				local rayRes = workspace:Raycast(hrp.Position + hrp.CFrame.LookVector * 5, Vector3.new(0, -10, 0))
				if rayRes and rayRes.Instance then
					local originalCollide = rayRes.Instance.CanCollide
					rayRes.Instance.CanCollide = false
					task.delay(3, function()
						rayRes.Instance.CanCollide = originalCollide
					end)
				end
			end
		}
	}
}

return DomainWarden
