local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)
local components = require(ReplicatedStorage.Shared.Components)

local function start(containers)
	local world = Matter.World.new()
	local state = {}

	-- Register components
	for _, component in ipairs(components) do
		world:registerComponent(component)
	end

	-- Create a loop for the world
	local loop = Matter.Loop.new(world, state)

	local systems = {}

	-- Load systems from the systems folder
	for _, container: Folder in containers do
		for _, module in container:GetChildren() do
			if module:IsA("ModuleScript") then
				table.insert(systems, require(module))
			end
		end
	end

	loop:scheduleSystems(systems)

	-- Begin the loop with the specified containers
	loop:begin({
		default = RunService.Heartbeat,
		Stepped = RunService.Stepped,
	})

	return world, state
end

return start
--[[
This function initializes the Matter world, registers components, and schedules systems.
]]
