-- [Rare] Gear Dasher | Gear 2nd vibes. Rapid punches and jet-assisted movement.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local GearDasher = {
	Name = "Gear Dasher",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Jet Punch",
			CD = 9,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Punch someone from across the room
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 20, {character})
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 50)
				end
			end
		},
		Active2 = {
			Name = "Jet Pull",
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Pull yourself to a wall or miss and get yanked back
				local result = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 15)
				if result then
					hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 65
				else
					-- Recoil if you whiff it
					hrp.AssemblyLinearVelocity = -hrp.CFrame.LookVector * 40
				end
			end
		}
	}
}

return GearDasher
