-- [Common] Guardian | Absolute unit. Unpushable and annoying.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local Guardian = {
	Name = "Guardian",
	Tier = "Common",
	BaseWalkSpeed = 16,
	Passives = {
		MassResist = 1.3 -- You're a heavy boy
	},
	Abilities = {
		Active1 = {
			Name = "Iron Body",
			CD = 1,
			ExecuteServer = function(player, character)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Golden shield aura
				MovementUtil.ShowVisualFeedback(hrp.Position, 10, Color3.new(1, 0.8, 0), 4)
				
				-- Lock yourself in place (FIXED: Uses Velocity Clamp instead of Spring force)
				local doc = Instance.new("LinearVelocity")
				doc.VectorVelocity = Vector3.new(0, 0, 0) -- Don't move.
				doc.MaxForce = math.huge -- I said, DON'T MOVE.
				doc.RelativeTo = Enum.ActuatorRelativeTo.World
				doc.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
				doc.Parent = hrp
				
				-- Stop spinning too
				local av = Instance.new("AngularVelocity")
				av.AngularVelocity = Vector3.new(0, 0, 0)
				av.MaxTorque = math.huge
				av.Attachment0 = doc.Attachment0
				av.Parent = hrp
				
				-- Apply TANK BUFF: 50 Health, 30% reduction, for 4s
				MovementUtil.ApplyTankBuff(character, 4, 50, 0.3)
				
				task.delay(4, function()
					doc:Destroy()
					av:Destroy()
				end)
			end
		},
		Active2 = {
			Name = "Magnetize",
			CD = 1,
			ExecuteServer = function(player, character, targetPos)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Visual Feedback: Magnetic pull line
				MovementUtil.ShowVisualFeedback(targetPos, 5, Color3.new(0, 1, 1), 0.5)
				
				-- Use cursor position if possible, otherwise look vector
				local dir = (targetPos - hrp.Position).Unit
				local target = MovementUtil.GetNearestInRay(hrp.Position, dir, 80, {character}) -- Buffed from 30
				
				if target then
					local tHrp = target:FindFirstChild("HumanoidRootPart")
					if tHrp then
						-- Pull TOWARDS the player
						local pullDir = (hrp.Position - tHrp.Position).Unit
						MovementUtil.ApplyKnockback(target, pullDir, 120) -- Buffed from 50
					end
				end
			end
		}
	}
}

return Guardian
