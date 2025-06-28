local ReplicatedStorage = game:GetService("ReplicatedStorage")
local start = require(ReplicatedStorage.Shared.start)
local receiveReplication = require(ReplicatedStorage.Shared.receiveReplication)

local world, state = start({
	ReplicatedStorage.Shared.systems,
	ReplicatedStorage.Shared.clientSystems,
})

receiveReplication(world, state)
