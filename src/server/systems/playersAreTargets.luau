local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.Shared.Components)

function playersAreTargets(world)
	for _, player in ipairs(Players:GetPlayers()) do
		for _, character in Matter.useEvent(player, "CharacterAdded") do
			world:spawn(
				Components.Target(),
				Components.Model({
					model = character,
				})
			)
		end
	end

	-- players can die
	for id in world:query(Components.Target):without(Components.Model) do
		world:despawn(id)
	end
end

return playersAreTargets
