local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)
local Components = require(ReplicatedStorage.Shared.Components)

local function spawnEnemy(world)
	if Matter.useThrottle(10) then
		local enemy = world:spawn(
			Components.Enemy(),
			Components.Transform({
				cframe = CFrame.new(0, 11, 0),
			}),
			Components.DeleteTouched()
		)

		print(string.format("Spawned enemy with ID: %d", enemy))
	end
end

return spawnEnemy
