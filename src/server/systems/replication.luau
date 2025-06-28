local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local components = require(ReplicatedStorage.Shared.Components)
local useEvent = require(ReplicatedStorage.Packages.matter).useEvent

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "ReplicationRemote"
RemoteEvent.Parent = ReplicatedStorage

local REPLICATED_COMPONENTS = {
	"Enemy",
	"Model",
}
local replicatedComponents = {}
for _, name in ipairs(REPLICATED_COMPONENTS) do
	replicatedComponents[components[name]] = true
end

local function replication(world)
	for _, player in useEvent(Players, "PlayerAdded") do
		local payload = {}

		for entityId, entityData in world do
			local entityPayload = {}

			for component, componentData in entityData do
				if replicatedComponents[component] then
					entityPayload[tostring(component)] = {
						data = componentData,
					}
				end
			end
		end
		RemoteEvent:FireAllClients(player, payload)
	end
	local changes = {}

	for component in replicatedComponents do
		for entityId, record in pairs(component) do
			local key = tostring(entityId)
			local name = tostring(component)
			-- If there aren't any changes from this entity in the buffer so far, create the table for it
			if changes[key] == nil then
				changes[key] = {}
			end
			if world:contains(entityId) then
				changes[key][name] = { data = record.new }
			end
		end
	end
	if next(changes) then
		RemoteEvent:FireAllClients(changes)
	end
end

return {
	system = replication,
	priority = math.huge,
}
