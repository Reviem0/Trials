local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.Shared.Components)

local VIEW_DISTANCE = 100
local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local function findTarget(world)
	-- A list of all enemy models to ignore in raycasts so they don't block each other's view
	local enemyModels = {}
	for _, model in world:query(Components.Enemy, Components.Model) do
		table.insert(enemyModels, model.model)
	end
	RAYCAST_PARAMS.FilterDescendantsInstances = enemyModels

	for enemyId, enemyModel in world:query(Components.Enemy, Components.Model):without(Components.Target) do
		local enemyRoot = enemyModel.model:FindFirstChild("HumanoidRootPart")
		if not enemyRoot then
			continue
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character then
				continue
			end

			local characterRoot = character:FindFirstChild("HumanoidRootPart")
			if not characterRoot then
				continue
			end

			local enemyPosition = enemyRoot.Position
			local characterPosition = characterRoot.Position

			-- Use the head for a more realistic line-of-sight check
			local enemyHead = enemyModel.model:FindFirstChild("Head") or enemyRoot
			local characterHead = character:FindFirstChild("Head") or characterRoot

			local origin = enemyHead.Position
			local direction = characterHead.Position - origin

			if direction.Magnitude > VIEW_DISTANCE then
				continue
			end

			local result = workspace:Raycast(origin, direction.Unit * VIEW_DISTANCE, RAYCAST_PARAMS)

			if result and result.Instance:IsDescendantOf(character) then
				-- We have line of sight to the player's character
				world:insert(enemyId, Components.Target({ character = character }))
				-- This enemy has found a target, move to the next enemy
				break
			end
		end
	end
end

return findTarget
