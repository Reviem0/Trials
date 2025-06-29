local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Matter = require(ReplicatedStorage.Packages.matter)

local COMPONENTS = {
	"Enemy",
	"Transform",
	"Model",
	"DeleteTouched",
	"Target",
	"HuntVision",
	"HuntListen",
}

local components = {}
for _, name in ipairs(COMPONENTS) do
	components[name] = Matter.component(name)
end

return components
--[[
    components.luau
    Defines the components used in the game.
    This file is part of the Matter ECS framework.
]]
