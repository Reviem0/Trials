local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.Shared.Components)

local function spawnEnemyModel(world)
	for id, _ in world:query(Components.Transform, Components.Enemy):without(Components.Model) do
		local model: Model = ReplicatedStorage.Assets.Enemy:Clone()
		model.Parent = workspace
		model.PrimaryPart:SetNetworkOwner(nil)

		world:insert(
			id,
			Components.Model({
				model = model,
				primaryPart = model.PrimaryPart,
			})
		)
	end
end

return spawnEnemyModel
