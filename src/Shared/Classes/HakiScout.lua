-- [Rare] Haki Scout | One Piece vibes. See it coming before it happens.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local HakiScout = {
	Name = "Haki Scout",
	Tier = "Rare",
	BaseWalkSpeed = 16 * 0.9, -- You move slower because you're focused
	Abilities = {
		Active1 = {
			Name = "Observe Dodge",
			CD = 1,
			ExecuteServer = function(player, character)
				-- Visual Feedback: Focus aura
				MovementUtil.ShowVisualFeedback(character:GetPrimaryPartCFrame().Position, 10, Color3.new(1, 1, 0.8), 2)
				
				-- Mark player as 'observing' to dodge next incoming hit
				local tag = Instance.new("BoolValue")
				tag.Name = "ObservationActive"
				tag.Parent = character
				task.delay(2, function() tag:Destroy() end)
			end
		},
		Active2 = {
			Name = "Harden",
			CD = 1,
			ExecuteServer = function(player, character)
				-- Visual Feedback: Metallic shine
				MovementUtil.ShowVisualFeedback(character:GetPrimaryPartCFrame().Position, 12, Color3.new(0.2, 0.2, 0.2), 4)
				
				-- Reduce incoming knockback (Armament style)
				local tag = Instance.new("NumberValue")
				tag.Name = "KBMultiplier"
				tag.Value = 0.5
				tag.Parent = character
				task.delay(4, function() tag:Destroy() end)
			end
		}
	}
}

return HakiScout
