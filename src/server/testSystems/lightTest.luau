local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lightDetector = require(ReplicatedStorage.Shared.lightDetection)
local Matter = require(ReplicatedStorage.Packages.matter)
local Players = game:GetService("Players")

function lightTest(_)
	if Matter.useThrottle(1) then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local lightObj = lightDetector:DetectLightAtObject(player.Character.HumanoidRootPart)
				local Data = lightObj:Update()
				print(player.Name .. " Light Level: " .. Data["LightLevel"])
			end
		end
	end
end

return lightTest
