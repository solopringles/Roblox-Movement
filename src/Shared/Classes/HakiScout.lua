-- Shared/Classes/HakiScout.lua
local MovementUtil = require(script.Parent.Parent.MovementUtil)

local HakiScout = {
	Name = "Haki Scout",
	Tier = "Rare",
	BaseWalkSpeed = 16 * 0.9, -- -10% WalkSpeed
	Abilities = {
		Active1 = {
			Name = "Observe Dodge",
			CD = 10,
			ExecuteServer = function(player, character)
				-- Simulation: Apply a brief state that reduces next KB
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
				-- KB reduction simulation
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
