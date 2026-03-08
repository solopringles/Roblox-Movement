-- [Rare] Gear Dasher | Gear 2nd vibes. Rapid punches and jet-assisted movement.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local GearDasher = {
	Name = "Gear Dasher",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Jet Punch",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Jet burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 8, Color3.new(1, 0.5, 0), 0.3)
				
				-- Punch someone from across the room
				local target = MovementUtil.GetNearestInRay(hrp.Position, hrp.CFrame.LookVector, 60, {character}) -- Buffed from 20
				if target then
					MovementUtil.ApplyKnockback(target, hrp.CFrame.LookVector, 100) -- Buffed from 50
				end
			end
		},
		Active2 = {
			Name = "Jet Pull",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Blue jet pull path
				MovementUtil.ShowVisualFeedback(targetPos, 5, Color3.new(0.4, 0.6, 1), 0.5)
				
				-- Aim with cursor!
				local aimDir = (targetPos - hrp.Position).Unit
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				local result = workspace:Raycast(hrp.Position, aimDir * 80, rayParams) -- Buffed from 25
				
				if result then
					MovementUtil.ApplyVelocity(hrp, aimDir * 120, 0.3)
				else
					-- Recoil if you whiff it
					MovementUtil.ApplyVelocity(hrp, -aimDir * 55, 0.2)
				end
			end
		}
	}
}

return GearDasher
