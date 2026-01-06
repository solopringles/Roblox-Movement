-- [Rare] Haki Scout | One Piece vibes. See it coming before it happens.
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local HakiScout = {
	Name = "Haki Scout",
	Tier = "Rare",
	BaseWalkSpeed = 16 * 0.9, -- You move slower because you're focused
	Abilities = {
		Active1 = {
			Name = "Observe Dodge",
			CD = 10,
			ExecuteServer = function(player, character)
				-- Mark player as 'observing' to dodge next incoming hit
				local tag = Instance.new("BoolValue")
				tag.Name = "ObservationActive"
				tag.Parent = character
				task.delay(2, function() tag:Destroy() end)
			end
		},
		Active2 = {
			Name = "Harden",
			CD = 14,
			ExecuteServer = function(player, character)
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
