-- [Rare] Trap Genius | Blue Lock Nagi vibes. Control your momentum like a pro.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local TrapGenius = {
	Name = "Trap Genius",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Momentum Kill",
			CD = 10,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Stop dead in your tracks
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		},
		Active2 = {
			Name = "Leap Burst",
			CD = 13,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Big jump toward where you're looking
				hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 70
				MovementUtil.PlaySound(3413531338, hrp)
			end
		}
	}
}

return TrapGenius
