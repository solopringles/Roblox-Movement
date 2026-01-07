-- [Rare] Trap Genius | Blue Lock Nagi vibes. Control your momentum like a pro.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local TrapGenius = {
	Name = "Trap Genius",
	Tier = "Rare",
	Abilities = {
		Active1 = {
			Name = "Momentum Kill",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Freeze burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(0.5, 0.8, 1), 0.3)
				
				-- Stop dead in your tracks
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		},
		Active2 = {
			Name = "Leap Burst",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Launch burst
				MovementUtil.ShowVisualFeedback(hrp.Position, 12, Color3.new(0.8, 1, 0.8), 0.4)
				
				-- Big jump toward cursor
				local aimDir = (targetPos - hrp.Position).Unit
				MovementUtil.ApplyVelocity(hrp, aimDir * 140, 0.4) -- Buffed from 75
			end
		}
	}
}

return TrapGenius
