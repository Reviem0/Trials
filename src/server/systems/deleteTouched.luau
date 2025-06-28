local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.Shared.Components)

function deleteTouched(world)
	for id, _ in world:query(Components.DeleteTouched, Components.Model) do
		-- print(world:get(id, Components.Model)["model"])
		for _, hit in Matter.useEvent(world:get(id, Components.Model)["model"].PrimaryPart, "Touched") do
			local character = hit:FindFirstAncestorOfClass("Model")
			if character then
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					-- Check if entity still exists before despawning
					if world:contains(id) then
						world:despawn(id)
					end
				end
			end
		end
	end
end
return deleteTouched
--[[
    deleteTouched.luau
    Handles the deletion of entities when they are touched.
    This file is part of the Matter ECS framework.
]]
